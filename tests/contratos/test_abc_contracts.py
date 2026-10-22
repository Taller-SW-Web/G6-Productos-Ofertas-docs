from pathlib import Path
import unittest,re,json,hashlib
import yaml
ROOT=Path(__file__).resolve().parents[2]
class ContractChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.o=yaml.safe_load((ROOT/'contratos/http/openapi.yaml').read_text(encoding='utf-8'))
        cls.a=yaml.safe_load((ROOT/'contratos/eventos/asyncapi.yaml').read_text(encoding='utf-8'))
    def test_references(self):
        for d in (self.o,self.a):
            def walk(v):
                if isinstance(v,dict):
                    ref=v.get('$ref')
                    if isinstance(ref,str) and ref.startswith('#/'):
                        cur=d
                        for part in ref[2:].split('/'):
                            key=part.replace('~1','/').replace('~0','~');self.assertIn(key,cur,ref);cur=cur[key]
                    for x in v.values():walk(x)
                elif isinstance(v,list):
                    for x in v:walk(x)
            walk(d)
    def test_versions(self):
        self.assertEqual(self.o['info']['version'],'0.6.0-rc.1')
        self.assertEqual(self.a['info']['version'],'0.6.0-rc.3')
    def test_reservation_result_mapping(self):
        op=self.o['paths']['/inventario/reservas']['post']
        self.assertIn('inventory.reservation.rejected',op['x-async-result-events'])
        self.assertNotIn('inventory.consumption.rejected',op['x-async-result-events'])
    def test_result_envelopes_have_schema_version_2(self):
        names=('InventoryReservationCreated','InventoryReservationRejected','InventoryReservationConsumed','InventoryReservationReleased','InventoryReservationExpired','InventoryConsumptionCompleted','InventoryConsumptionRejected','PromotionsCouponConsumptionCompleted','PromotionsCouponConsumptionRejected','PromotionsCouponConsumptionRequested','PromotionsCouponRestorationRequested','PromotionsCouponRestorationCompleted','PromotionsCouponRestorationRejected')
        for name in names:
            obj=self.a['components']['messages'][name]['payload']['allOf'][1]
            self.assertEqual(obj['properties']['schema_version']['const'],2,name)
            self.assertIn('schema_version',obj['required'],name)
            self.assertIn('operation_id',obj['required'],name)
            self.assertIn('causation_id',obj['required'],name)
    def test_migrations_are_transaction_free(self):
        for p in ('datos/inventory-svc/migrations/0001_inventory_initial.sql','datos/inventory-svc/migrations/0002_order_id_operaciones_disponibilidad.sql','datos/promotions/migrations/0004_coupon_idempotency_receipts.sql'):
            s=(ROOT/p).read_text(encoding='utf-8')
            self.assertIsNone(re.search(r'^(BEGIN|COMMIT);\s*$',s,re.M),p)
    def test_migration_paths(self):
        self.assertTrue((ROOT/'datos/inventory-svc/migrations/0001_inventory_initial.sql').exists())
        self.assertTrue((ROOT/'datos/inventory-svc/migrations/0002_order_id_operaciones_disponibilidad.sql').exists())
    def test_coupon_permissions(self):
        s=(ROOT/'datos/promotions/migrations/0004_coupon_idempotency_receipts.sql').read_text(encoding='utf-8')
        self.assertIn('GRANT SELECT, INSERT',s)
        self.assertIn('po_promotions_runtime',s)
    def test_legacy_inventory_immutable(self):
        s=(ROOT/'datos/inventory-svc/migration.sql').read_text(encoding='utf-8')
        self.assertIn('order_id        uuid',s)
        self.assertIn('order_id           uuid',s)
    def test_validation_isolated(self):
        s=(ROOT/'datos/inventory-svc/validation.sql').read_text(encoding='utf-8')
        self.assertIn('BEGIN;',s)
        self.assertTrue(s.rstrip().endswith('ROLLBACK;'))
        self.assertNotIn('DELETE FROM inventory.stock_threshold_override',s)
    def test_commercial_channel_restriction(self):
        self.assertEqual(self.o['info']['version'],'0.6.0-rc.1')
        self.assertEqual(self.o['components']['schemas']['Canal']['enum'],['MARKETPLACE','CHATBOT','RETAIL','VENTAS'])
        self.assertEqual(self.o['components']['schemas']['CanalComercial']['enum'],['MARKETPLACE','CHATBOT','RETAIL'])
        # GET /inventario/disponibilidad/comercial
        get_op=self.o['paths']['/inventario/disponibilidad/comercial']['get']
        get_canal_param=next(p for p in get_op['parameters'] if p.get('name')=='canal')
        self.assertEqual(get_canal_param['schema']['$ref'],'#/components/schemas/CanalComercial')
        self.assertEqual(get_op['x-allowed-client-ids'],['modulo-marketplace','modulo-chatbot','modulo-retail'])
        self.assertEqual(get_op['x-required-scope'],'inventario:disponibilidad:leer')
        self.assertIn('400',get_op['responses'])
        self.assertIn('403',get_op['responses'])
        self.assertIn('VALIDACION',get_op['x-error-codes']['400'])
        self.assertIn('SCOPE_INSUFICIENTE',get_op['x-error-codes']['403'])
        # POST /inventario/disponibilidad/comercial/verificar
        post_op=self.o['paths']['/inventario/disponibilidad/comercial/verificar']['post']
        post_body_schema=self.o['components']['schemas']['VerificarCantidadComercialRequest']
        self.assertEqual(post_body_schema['properties']['channel_id']['$ref'],'#/components/schemas/CanalComercial')
        self.assertEqual(post_op['x-allowed-client-ids'],['modulo-marketplace','modulo-chatbot','modulo-retail'])
        self.assertEqual(post_op['x-required-scope'],'inventario:disponibilidad:leer')
        self.assertIn('400',post_op['responses'])
        self.assertIn('403',post_op['responses'])
        self.assertIn('VALIDACION',post_op['x-error-codes']['400'])
        self.assertIn('SCOPE_INSUFICIENTE',post_op['x-error-codes']['403'])
        # Distinción explícita en documentación contractual
        desc=self.o['components']['schemas']['CanalComercial']['description']
        self.assertIn('400 + VALIDACION',desc)
        self.assertIn('403 + SCOPE_INSUFICIENTE',desc)
        self.assertIn('modulo-marketplace -> MARKETPLACE',desc)
        self.assertIn('modulo-chatbot -> CHATBOT',desc)
        self.assertIn('modulo-retail -> RETAIL',desc)
    def test_single_location_policy_documented(self):
        desc=self.o['paths']['/inventario/disponibilidad/comercial/verificar']['post']['description']
        self.assertIn('D-INV-01',desc)
        self.assertIn('única ubicación',desc)
        self.assertIn('prohibido sumar existencias',desc)
        self.assertIn('INDETERMINADO',desc)
        self.assertIn('binding=false',desc)
        self.assertNotIn('salvo que exista una modalidad de abastecimiento explícita y ejecutable para atender conjuntamente',desc)
    def test_offline_reconciliation_candidate_operation(self):
        self.assertEqual(self.o['info']['version'],'0.6.0-rc.1')
        op=self.o['paths']['/inventario/conciliaciones-offline']['post']
        self.assertEqual(op['operationId'],'conciliarVentaOffline')
        self.assertEqual(op['x-status'],'provisional')
        self.assertEqual(op['x-allowed-client-ids'],['modulo-ventas'])
        self.assertEqual(op['x-required-scope'],'inventario:conciliar-offline')
        self.assertEqual(op['x-scope-registration-status'],'pending-security-registration')
        self.assertEqual(op['security'],[{'serviceBearer':[]}])
        self.assertTrue(op['requestBody']['required'])
        request=op['requestBody']['content']['application/json']['schema']
        self.assertEqual(request['$ref'],'#/components/schemas/ConciliacionOfflineRequest')
        response=op['responses']['200']['content']['application/json']['schema']
        self.assertEqual(response['$ref'],'#/components/schemas/ConciliacionOfflineResponse')
        conflict=op['responses']['409']
        self.assertIn('IDEMPOTENCY_CONFLICT',op['x-error-codes']['409'])
        conflict_schema=conflict['content']['application/problem+json']['schema']
        self.assertEqual(conflict_schema['allOf'][1]['properties']['status']['const'],409)
        self.assertEqual(conflict_schema['allOf'][1]['properties']['status']['type'],'integer')
        self.assertIn('status',conflict_schema['allOf'][1]['required'])
        self.assertIn('code',conflict_schema['allOf'][1]['required'])
        self.assertEqual(conflict_schema['allOf'][1]['properties']['code']['enum'],['IDEMPOTENCY_CONFLICT'])
    def test_offline_reconciliation_request_candidate_shape(self):
        request=self.o['components']['schemas']['ConciliacionOfflineRequest']
        props=request['properties']
        self.assertEqual(props['operation_id']['type'],'string')
        self.assertEqual(props['operation_id']['format'],'uuid')
        self.assertEqual(props['order_id']['type'],'string')
        self.assertEqual(props['order_id']['minLength'],1)
        self.assertNotIn('format',props['order_id'])
        self.assertEqual(props['offline_sale_id']['type'],'string')
        self.assertEqual(props['offline_sale_id']['minLength'],1)
        self.assertEqual(props['offline_sale_id']['maxLength'],128)
        self.assertNotIn('format',props['offline_sale_id'])
        self.assertIn('order_id',props)
        self.assertIn('offline_sale_id',props)
        self.assertEqual(props['channel_id']['const'],'RETAIL')
        self.assertEqual(props['occurred_at']['format'],'date-time')
        self.assertEqual(props['lines']['type'],'array')
        self.assertEqual(props['lines']['minItems'],1)
        self.assertEqual(props['lines']['items']['$ref'],'#/components/schemas/LineaInventarioUbicada')
        self.assertEqual(set(request['required']),{'operation_id','order_id','offline_sale_id','channel_id','occurred_at','lines'})
        line=self.o['components']['schemas']['LineaInventarioUbicada']
        self.assertEqual(line['properties']['sku']['type'],'string')
        self.assertEqual(line['properties']['quantity']['type'],'integer')
        self.assertEqual(line['properties']['quantity']['minimum'],1)
        self.assertEqual(line['properties']['location_id']['type'],'string')
        self.assertEqual(set(line['required']),{'sku','quantity','location_id'})
        # Current-candidate snapshot only: required location_id conflicts with DEC-F-014.
    def test_offline_reconciliation_response_candidate_shape(self):
        response=self.o['components']['schemas']['ConciliacionOfflineResponse']
        props=response['properties']
        self.assertEqual(props['status']['enum'],['COMPLETED','REQUIRES_REVIEW'])
        self.assertEqual(set(response['required']),{'operation_id','order_id','offline_sale_id','status','lines','completed_at'})
        line_ref=props['lines']['items']['$ref']
        self.assertEqual(line_ref,'#/components/schemas/ConciliacionOfflineLineaResultado')
        line=self.o['components']['schemas']['ConciliacionOfflineLineaResultado']
        expected={'requested_quantity':1,'applied_quantity':0,'unresolved_quantity':0}
        for field,minimum in expected.items():
            self.assertEqual(line['properties'][field]['type'],'integer')
            self.assertEqual(line['properties'][field]['minimum'],minimum)
            self.assertIn(field,line['required'])
        for field in ('location_id','on_hand','reserved','blocked','available','stock_version'):
            self.assertIn(field,line['properties'])
            self.assertIn(field,line['required'])
        # Current-candidate snapshot only: internal fields conflict with DEC-F-015 minimization intent for Retail.
    def test_offline_reconciliation_conflict_and_status_responses(self):
        op=self.o['paths']['/inventario/conciliaciones-offline']['post']
        self.assertIn('200',op['responses'])
        self.assertIn('409',op['responses'])
        self.assertEqual(op['responses']['409']['description'],'Conflicto de idempotencia')
        self.assertIn('IDEMPOTENCY_CONFLICT',op['x-error-codes']['409'])
        conflict_schema=op['responses']['409']['content']['application/problem+json']['schema']['allOf'][1]
        self.assertEqual(conflict_schema['properties']['status']['const'],409)
        self.assertIn('status',conflict_schema['required'])
        self.assertIn('code',conflict_schema['required'])
    def test_postventa_detailed_availability_contract(self):
        op=self.o['paths']['/inventario/disponibilidad']['get']
        self.assertEqual(set(op['x-allowed-client-ids']),{'modulo-ventas','modulo-postventa'})
        self.assertEqual(op['x-required-scope'],'inventario:disponibilidad:leer')
        self.assertEqual(op['x-scope-registration-status'],'pending-security-registration')
        self.assertEqual(op['x-service-audience'],'api-productos')
        self.assertEqual(op['security'],[{'userBearer':[]},{'serviceBearer':[]}])

    def test_postventa_f3_reintegration_contract(self):
        op=self.o['paths']['/inventario/reintegros']['post']
        self.assertEqual(set(op['x-allowed-client-ids']),{'modulo-ventas','modulo-postventa'})
        self.assertEqual(op['x-required-scope'],'inventario:reintegrar')
        self.assertEqual(op['x-service-audience'],'api-productos')
        self.assertEqual(op['x-scope-registration-status'],'pending-security-registration')
        self.assertEqual(op['security'],[{'serviceBearer':[]}])
        self.assertIn('G7',op['description'])
        self.assertIn('location_id',op['description'])
        self.assertEqual(op['requestBody']['content']['application/json']['schema']['$ref'],'#/components/schemas/ReintegroInventarioRequest')
        response=op['responses']['200']['content']['application/json']['schema']['$ref']
        self.assertEqual(response,'#/components/schemas/ReintegroInventarioResponse')
        response_schema=self.o['components']['schemas']['ReintegroInventarioResponse']
        self.assertEqual(response_schema['properties']['status']['enum'],['COMPLETED'])
        self.assertEqual(set(response_schema['required']),{'operation_id','order_id','source_ref','status','lines','completed_at'})

    def test_reintegration_request_canonical_schema(self):
        schema=self.o['components']['schemas']['ReintegroInventarioRequest']
        self.assertEqual(set(schema['required']),{'operation_id','order_id','source_ref','reason','lines'})
        props=schema['properties']
        self.assertEqual(props['operation_id']['type'],'string')
        self.assertEqual(props['operation_id']['format'],'uuid')
        self.assertEqual(props['order_id']['type'],'string')
        self.assertNotIn('format',props['order_id'])
        self.assertEqual(props['source_ref']['type'],'string')
        self.assertEqual(props['source_ref']['minLength'],1)
        self.assertEqual(props['reason']['$ref'],'#/components/schemas/MotivoReintegroInventario')
        self.assertIn('DEVOLUCION_ACEPTADA',self.o['components']['schemas']['MotivoReintegroInventario']['enum'])
        self.assertEqual(props['lines']['type'],'array')
        self.assertEqual(props['lines']['items']['$ref'],'#/components/schemas/LineaInventarioUbicada')
        line=self.o['components']['schemas']['LineaInventarioUbicada']
        self.assertEqual(set(line['required']),{'sku','quantity','location_id'})
        self.assertEqual(line['properties']['sku']['type'],'string')
        self.assertEqual(line['properties']['quantity']['type'],'integer')
        self.assertEqual(line['properties']['location_id']['type'],'string')

    def test_postventa_cannot_mutate_reservations_or_read_operations(self):
        paths=self.o['paths']
        forbidden=(('/inventario/reservas','post'),('/inventario/reservas/{reservaId}/confirmar','post'),('/inventario/reservas/{reservaId}/liberar','post'),('/inventario/conciliaciones-offline','post'),('/inventario/operaciones/{operationId}','get'))
        for path,method in forbidden:
            self.assertNotIn('modulo-postventa',paths[path][method]['x-allowed-client-ids'],path)
        self.assertEqual(paths['/inventario/operaciones/{operationId}']['get']['x-allowed-client-ids'],['modulo-ventas'])

    def test_postventa_does_not_inherit_channel_endpoints(self):
        paths=self.o['paths']
        commercial=(('/inventario/disponibilidad/comercial','get'),('/inventario/disponibilidad/comercial/verificar','post'))
        expected={'modulo-marketplace','modulo-chatbot','modulo-retail'}
        for path,method in commercial:
            clients=paths[path][method]['x-allowed-client-ids']
            self.assertEqual(set(clients),expected,path)
            self.assertNotIn('modulo-postventa',clients,path)
        detailed=set(paths['/inventario/disponibilidad']['get']['x-allowed-client-ids'])
        self.assertNotIn('modulo-marketplace',detailed)
        self.assertNotIn('modulo-chatbot',detailed)
        self.assertNotIn('modulo-retail',detailed)


class MarketplaceCatalogContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.o=yaml.safe_load((ROOT/'contratos/http/openapi.yaml').read_text(encoding='utf-8'))
        cls.paths=cls.o['paths']
        cls.schemas=cls.o['components']['schemas']

    def test_marketplace_operation_security_allowlists_and_audience(self):
        # CT-MKT-14: service identity, audience, scope, pending registration and clients.
        allowed={'modulo-marketplace','modulo-chatbot','modulo-retail'}
        operations=(
            ('/categorias','listarCategorias'),
            ('/productos','listarProductos'),
            ('/productos/por-slug/{slug}','obtenerProductoPorSlug'),
        )
        self.assertEqual(self.o['servers'][0]['url'],'/api/v1')
        for path,operation_id in operations:
            op=self.paths[path]['get']
            self.assertEqual(op['operationId'],operation_id,path)
            self.assertEqual(op['x-required-scope'],'catalogo:leer',path)
            self.assertEqual(op['x-service-audience'],'api-productos',path)
            self.assertEqual(op['x-scope-registration-status'],'pending-security-registration',path)
            self.assertEqual(set(op['x-allowed-client-ids']),allowed,path)
        self.assertEqual(set(self.o['x-security-contract']['service_scopes_pending_registration']['catalogo:leer']['clients']),allowed)

        schemes=self.o['components']['securitySchemes']
        self.assertEqual(schemes['serviceBearer']['type'],'http')
        self.assertEqual(schemes['serviceBearer']['scheme'],'bearer')
        self.assertEqual(schemes['serviceBearer']['bearerFormat'],'JWT')
        self.assertEqual(schemes['userBearer']['type'],'http')
        self.assertEqual(schemes['userBearer']['scheme'],'bearer')
        self.assertEqual(self.paths['/categorias']['get']['security'],[{'serviceBearer':[]}])
        self.assertEqual({next(iter(choice)) for choice in self.paths['/productos']['get']['security']},{'serviceBearer','userBearer'})
        self.assertEqual({next(iter(choice)) for choice in self.paths['/productos/por-slug/{slug}']['get']['security']},{'serviceBearer','userBearer'})

    def test_marketplace_product_query_and_pagination_parameters(self):
        # CT-MKT-18: G6 parameters are distinct from G1's BFF validation limits.
        op=self.paths['/productos']['get']
        params={(p.get('name'),p.get('in')):p for p in op['parameters'] if '$ref' not in p}
        self.assertEqual(params[('q','query')]['schema']['type'],'string')
        self.assertFalse(params[('q','query')].get('required',False))
        canal=params[('canal','query')]
        self.assertEqual(canal['schema']['$ref'],'#/components/schemas/Canal')
        self.assertIn('Obligatorio semánticamente',canal['description'])
        pagina=params[('pagina','query')]['schema']
        self.assertEqual((pagina['type'],pagina['minimum'],pagina['default']),('integer',1,1))
        tamanio=params[('tamanio','query')]['schema']
        self.assertEqual((tamanio['type'],tamanio['minimum'],tamanio['maximum'],tamanio['default']),('integer',1,100,20))
        self.assertIn('comercialmente activos',op['summary'])
        estado=params[('estado','query')]
        self.assertIn('no pueden usarlo para ampliar visibilidad',estado['description'])
        # OpenAPI G6 does not inherit F-007's q length/pageSize bounds.
        self.assertNotIn('minLength',params[('q','query')]['schema'])
        self.assertNotIn('maxLength',params[('q','query')]['schema'])

    def test_marketplace_detail_requires_slug_and_channel(self):
        # CT-MKT-21: conditional path and mandatory channel context.
        op=self.paths['/productos/por-slug/{slug}']['get']
        params={(p.get('name'),p.get('in')):p for p in op['parameters'] if '$ref' not in p}
        self.assertTrue(params[('slug','path')]['required'])
        self.assertTrue(params[('canal','query')]['required'])
        self.assertEqual(params[('canal','query')]['schema']['$ref'],'#/components/schemas/Canal')

    def test_marketplace_success_response_shapes_and_category_status(self):
        # CT-MKT-15, CT-MKT-18, CT-MKT-21: verify declared response schemas only.
        categories=self.paths['/categorias']['get']['responses']['200']['content']['application/json']['schema']
        self.assertEqual(categories['type'],'object')
        self.assertEqual(categories['required'],['categories'])
        category_array=categories['properties']['categories']
        self.assertEqual(category_array['type'],'array')
        self.assertNotIn('minItems',category_array)
        self.assertEqual(category_array['items']['$ref'],'#/components/schemas/Categoria')

        category=self.schemas['Categoria']
        self.assertEqual(set(category['required']),{'categoria_id','name','status'})
        self.assertEqual(category['properties']['status']['enum'],['ACTIVA','INACTIVA'])
        self.assertIn('activas',self.paths['/categorias']['get']['summary'].lower())

        product_response=self.paths['/productos']['get']['responses']['200']['content']['application/json']['schema']
        self.assertEqual(product_response['$ref'],'#/components/schemas/PaginaProductosComercial')
        page=self.schemas['PaginaProductosComercial']
        self.assertEqual(set(page['properties']),{'items','pagina','tamanio','total'})
        self.assertEqual(set(page['required']),{'items','pagina','tamanio','total'})
        self.assertEqual(page['properties']['items']['type'],'array')
        self.assertNotIn('minItems',page['properties']['items'])
        self.assertEqual(page['properties']['items']['items']['$ref'],'#/components/schemas/ProductoResumenComercial')

        detail_response=self.paths['/productos/por-slug/{slug}']['get']['responses']['200']['content']['application/json']['schema']
        self.assertEqual(detail_response['$ref'],'#/components/schemas/ProductoDetalleComercial')
        detail=self.schemas['ProductoDetalleComercial']
        self.assertEqual(detail['allOf'][0]['$ref'],'#/components/schemas/ProductoResumenComercial')
        self.assertEqual(set(detail['allOf'][1]['required']),{'marca','variants'})
        self.assertEqual(detail['allOf'][1]['properties']['variants']['items']['$ref'],'#/components/schemas/VarianteComercial')

    def test_marketplace_product_and_variant_identity_semantics(self):
        # CT-MKT-22/23: SKU base is nullable/optional; variants have no BFF status field.
        product=self.schemas['ProductoResumenComercial']
        self.assertEqual(product['properties']['sku_base']['type'],['string','null'])
        self.assertNotIn('sku_base',product['required'])
        variant=self.schemas['VarianteComercial']
        self.assertIn('variant_id',variant['properties'])
        self.assertIn('sku',variant['properties'])
        self.assertEqual(set(variant['required']),{'variant_id','sku'})
        self.assertNotIn('status',variant['properties'])

    def test_marketplace_errors_correlation_and_commercial_field_surface(self):
        # CT-MKT-17/20/24: status codes, optional correlation and declared properties.
        for path in ('/categorias','/productos','/productos/por-slug/{slug}'):
            op=self.paths[path]['get']
            for status in ('401','403','503','429'):
                self.assertIn(status,op['responses'],(path,status))
            self.assertEqual(op['responses']['429']['$ref'],'#/components/responses/RateLimitExceeded',path)
            expected_codes={'401':'TOKEN_INVALIDO','403':'SCOPE_INSUFICIENTE','503':'SERVICIO_NO_DISPONIBLE'}
            for status,code in expected_codes.items():
                error_schema=op['responses'][status]['content']['application/problem+json']['schema']['allOf'][1]
                self.assertEqual(error_schema['properties']['code']['enum'],[code],(path,status))
            correlation_refs=[p['$ref'] for p in op['parameters'] if '$ref' in p]
            self.assertIn('#/components/parameters/CorrelationId',correlation_refs,path)
        correlation=self.o['components']['parameters']['CorrelationId']
        self.assertEqual(correlation['name'],'X-Correlation-Id')
        self.assertEqual(correlation['in'],'header')
        self.assertFalse(correlation['required'])
        self.assertEqual(correlation['schema']['format'],'uuid')
        rate_limit=self.o['components']['responses']['RateLimitExceeded']
        self.assertIn('Retry-After',rate_limit['headers'])
        self.assertEqual(rate_limit['headers']['Retry-After']['$ref'],'#/components/headers/RetryAfter')
        rate_code=rate_limit['content']['application/problem+json']['schema']['allOf'][1]['properties']['code']['enum']
        self.assertEqual(rate_code,['RATE_LIMIT_EXCEDIDO'])

        detail_404=self.paths['/productos/por-slug/{slug}']['get']['responses']['404']['content']['application/problem+json']['schema']['allOf'][1]
        self.assertEqual(detail_404['properties']['code']['enum'],['PRODUCTO_NO_ENCONTRADO'])
        self.assertNotIn('404',self.paths['/productos']['get']['responses'])

        excluded={'catalog_version','pricing_preparado','inventario_inicializado','perfil_fisico','physical_profile',
                  'on_hand','reserved','blocked','available','location_id','stock_version','threshold'}
        commercial=(self.schemas['Categoria'],self.schemas['ProductoResumenComercial'],self.schemas['PaginaProductosComercial'],self.schemas['VarianteComercial'],self.schemas['MarcaComercial'])
        for schema in commercial:
            self.assertTrue(excluded.isdisjoint(schema.get('properties',{})))
        detail_props=self.schemas['ProductoDetalleComercial']['allOf'][1].get('properties',{})
        self.assertTrue(excluded.isdisjoint(detail_props))

if __name__=='__main__':unittest.main()

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
        self.assertEqual(self.a['info']['version'],'0.6.0-rc.1')
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

if __name__=='__main__':unittest.main()

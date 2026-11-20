from __future__ import annotations

import hashlib
import json
import unittest
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = Path(__file__).resolve().parents[2]


def verify_claim_check_bytes(received_bytes, expected_reference, document_validator):
    """Validación determinista local de bytes contra una referencia independiente."""
    if len(received_bytes) != expected_reference["byte_length"]:
        return "BYTE_LENGTH_MISMATCH"
    if hashlib.sha256(received_bytes).hexdigest() != expected_reference["sha256"]:
        return "SHA256_MISMATCH"
    try:
        document = json.loads(received_bytes)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return "INVALID_JSON"
    if not isinstance(document, dict):
        return "DOCUMENT_NOT_OBJECT"
    if not document_validator.is_valid(document):
        return "INVALID_ROWS"
    return "ACCEPTED"


class H5SemifinalContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.openapi = yaml.safe_load((ROOT / "contratos/http/openapi.yaml").read_text(encoding="utf-8"))
        cls.asyncapi = yaml.safe_load((ROOT / "contratos/eventos/asyncapi.yaml").read_text(encoding="utf-8"))
        cls.fixtures = json.loads((ROOT / "tests/contratos/fixtures/asyncapi-0.6.0-rc.4-h4-events.json").read_text(encoding="utf-8"))
        cls.axel = json.loads((ROOT / "tests/contratos/fixtures/g5-g6-h5-axel-examples.json").read_text(encoding="utf-8"))
        cls.async_path = ROOT / "contratos/eventos/asyncapi.yaml"
        cls.openapi_path = ROOT / "contratos/http/openapi.yaml"
        cls.registry = (
            Registry()
            .with_resource(cls.async_path.resolve().as_uri(), Resource.from_contents(cls.asyncapi, default_specification=DRAFT202012))
            .with_resource(cls.openapi_path.resolve().as_uri(), Resource.from_contents(cls.openapi, default_specification=DRAFT202012))
        )

    def message_validator(self, name):
        return Draft202012Validator(
            {"$ref": f"{self.async_path.resolve().as_uri()}#/components/messages/{name}/payload"},
            registry=self.registry,
            format_checker=Draft202012Validator.FORMAT_CHECKER,
        )

    def schema_validator(self, name):
        return Draft202012Validator(
            {"$ref": f"{self.openapi_path.resolve().as_uri()}#/components/schemas/{name}"},
            registry=self.registry,
            format_checker=Draft202012Validator.FORMAT_CHECKER,
        )

    def test_openapi_semifinal_version_and_operation_baseline(self):
        self.assertEqual(self.openapi["openapi"], "3.1.0")
        self.assertEqual(self.openapi["info"]["version"], "0.7.0-rc.2")
        old = yaml.safe_load((ROOT / "contratos/historico/h4/http/openapi.yaml").read_text(encoding="utf-8"))
        old_ids = {op["operationId"] for item in old["paths"].values() for method, op in item.items() if method in {"get", "post", "put", "patch", "delete"}}
        new_ops = [(path, method, op) for path, item in self.openapi["paths"].items() for method, op in item.items() if method in {"get", "post", "put", "patch", "delete"}]
        ids = [op["operationId"] for _, _, op in new_ops]
        self.assertEqual(len(old_ids), 143)
        self.assertTrue(old_ids <= set(ids))
        historical_operations = {
            (path, method): operation
            for path, item in old["paths"].items()
            for method, operation in item.items()
            if method in {"get", "post", "put", "patch", "delete"}
        }
        for (path, method), historical_operation in historical_operations.items():
            if (path, method) == ("/inventario/dashboard", "get"):
                # SPEC-016 runtime only supports these two filters; rc.2 narrows the contract accordingly.
                dashboard = self.openapi["paths"][path][method]
                names = {parameter.get("name") for parameter in dashboard.get("parameters", [])}
                self.assertTrue({"sku", "locationId"}.issubset(names))
                self.assertTrue({"productoId", "categoriaId", "marcaId"}.isdisjoint(names))
                continue
            self.assertEqual(self.openapi["paths"][path][method], historical_operation, f"H4 operation changed: {method.upper()} {path}")
        self.assertEqual(len(new_ops), 153)
        self.assertEqual(len(set(ids)), 153)
        added = [(p, m) for p, m, op in new_ops if op["operationId"] not in old_ids]
        self.assertEqual(set(added), {("/cupones/consumos", "post"), ("/cupones/restauraciones", "post"), ("/cupones/operaciones/{operationId}", "get"), ("/inventario/reservas/{reservaId}/estado", "get"), ("/interno/carga-masiva/contenidos/{contentId}", "get"), ("/inventario/administracion/saldos", "get"), ("/inventario/alertas", "get"), ("/inventario/ubicaciones", "get"), ("/interno/productos/skus/filtrar", "post"), ("/interno/inventario/reservas/{reservaId}/evidencia-cupon", "get")})
        for path in ("/inventario/reservas", "/inventario/reservas/{reservaId}/confirmar", "/inventario/reservas/{reservaId}/liberar", "/inventario/operaciones/{operationId}", "/inventario/disponibilidad", "/inventario/reintegros", "/inventario/conciliaciones-offline", "/cupones/validar"):
            for method in ("get", "post", "put", "patch", "delete"):
                if method in old["paths"].get(path, {}) and method in self.openapi["paths"].get(path, {}):
                    self.assertEqual(old["paths"][path][method], self.openapi["paths"][path][method], f"{method.upper()} {path}")
        self.assertEqual(self.openapi["paths"]["/cupones/validar"]["post"]["x-allowed-client-ids"], old["paths"]["/cupones/validar"]["post"]["x-allowed-client-ids"])

    def test_coupon_idempotency_and_snapshot_constraints(self):
        consumption = self.openapi["components"]["schemas"]["CouponConsumptionRequest"]
        restoration = self.openapi["components"]["schemas"]["CouponRestorationRequest"]
        consumption_validator = Draft202012Validator(consumption, format_checker=Draft202012Validator.FORMAT_CHECKER)
        restoration_validator = Draft202012Validator(restoration, format_checker=Draft202012Validator.FORMAT_CHECKER)
        consume_body = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "order_id": "order-x", "coupon_code": "SAVE10", "channel_id": "MARKETPLACE", "effective_at": "2026-11-18T10:00:00Z", "reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "commercial_snapshot_ref": "snapshot-x", "customer_ref": None}
        self.assertTrue(consumption_validator.is_valid(consume_body))
        self.assertEqual("12b85ba4-a5b4-44fa-8c06-e554f5026100", consume_body["operation_id"])  # same value is sent in Idempotency-Key
        invalid_consume = dict(consume_body, channel_id="UNKNOWN")
        self.assertFalse(consumption_validator.is_valid(invalid_consume))
        restore_body = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "order_id": "order-x", "consumption_operation_id": "5af9c13f-c44e-41f6-97b9-0e971562b641", "cancellation_reason": "pedido cancelado", "cancelled_at": "2026-11-18T10:00:00Z"}
        self.assertTrue(restoration_validator.is_valid(restore_body))
        invalid_restore = dict(restore_body)
        del invalid_restore["consumption_operation_id"]
        self.assertFalse(restoration_validator.is_valid(invalid_restore))
        for path, schema in (("/cupones/consumos", "CouponConsumptionRequest"), ("/cupones/restauraciones", "CouponRestorationRequest")):
            operation = self.openapi["paths"][path]["post"]
            self.assertEqual(operation["responses"].keys() & {"200", "202", "409"}, {"200", "202", "409"})
            self.assertIn("Idempotency-Key", [p["name"] for p in operation["parameters"]])
            self.assertEqual(operation["security"][0]["serviceBearer"], [])
            self.assertEqual(operation["x-service-audience"], "api-productos")
            self.assertTrue(operation["x-required-scope"])
            self.assertTrue(operation["x-allowed-client-ids"])
            self.assertIn("operation_id", self.openapi["components"]["schemas"][schema]["required"])
        restore = self.openapi["components"]["schemas"]["CouponRestorationRequest"]
        self.assertIn("consumption_operation_id", restore["required"])
        self.assertNotIn("null", str(restore["properties"]["consumption_operation_id"]))
        validator = self.schema_validator("CouponOperationSnapshot")
        pending = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "operation_type": "CONSUMIR_CUPON", "status": "ACCEPTED", "order_id": "pedido-x", "accepted_at": "2026-11-18T10:00:00Z", "updated_at": "2026-11-18T10:00:00Z", "completed_at": None, "result": None}
        self.assertTrue(validator.is_valid(pending))
        processing = dict(pending, status="PROCESSING")
        self.assertTrue(validator.is_valid(processing))
        consume_completed = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "operation_type": "CONSUMIR_CUPON", "status": "COMPLETED", "order_id": "pedido-x", "accepted_at": "2026-11-18T10:00:00Z", "updated_at": "2026-11-18T10:00:02Z", "completed_at": "2026-11-18T10:00:02Z", "result": {"order_id": "pedido-x", "coupon_code": "SAVE10", "reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "commercial_snapshot_ref": "pedido-x", "decided_at": "2026-11-18T10:00:02Z"}}
        self.assertTrue(validator.is_valid(consume_completed))
        restore_completed = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "operation_type": "RESTAURAR_CUPON", "status": "COMPLETED", "order_id": "pedido-x", "accepted_at": "2026-11-18T10:00:00Z", "updated_at": "2026-11-18T10:00:02Z", "completed_at": "2026-11-18T10:00:02Z", "result": {"order_id": "pedido-x", "consumption_operation_id": "5af9c13f-c44e-41f6-97b9-0e971562b641", "restored": True, "outcome": "RESTORED", "completed_at": "2026-11-18T10:00:02Z"}}
        self.assertTrue(validator.is_valid(restore_completed))
        rejected = dict(consume_completed, status="REJECTED", result=dict(consume_completed["result"], result_code="COUPON_EXPIRED"))
        self.assertTrue(validator.is_valid(rejected))
        invalid = dict(consume_completed, completed_at=None)
        self.assertFalse(validator.is_valid(invalid))
        invalid = json.loads(json.dumps(consume_completed))
        invalid["result"].pop("coupon_code")
        self.assertFalse(validator.is_valid(invalid))
        invalid = dict(consume_completed, operation_id="not-a-uuid")
        self.assertFalse(validator.is_valid(invalid))
        invalid = dict(pending, status="REJECTED", completed_at="2026-11-18T10:00:02Z", result={"order_id": "pedido-x"})
        self.assertFalse(validator.is_valid(invalid))

    def test_reservation_read_semantics_and_bulk_private_integrity(self):
        reserve = self.openapi["components"]["schemas"]["ReservationStatusSnapshot"]
        validator = self.schema_validator("ReservationStatusSnapshot")
        active = {"reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "order_id": "order-x", "estado_persistido": "ACTIVA", "expires_at": "2026-11-18T10:00:00Z", "observed_at": "2026-11-18T10:00:00Z", "vigencia_efectiva": "VENCIDA", "permite_pago": False, "permite_consumo_cupon": False}
        self.assertTrue(validator.is_valid(active))
        valid = dict(active, expires_at="2026-11-18T10:00:01Z", vigencia_efectiva="VIGENTE", permite_pago=True, permite_consumo_cupon=True)
        self.assertTrue(validator.is_valid(valid))
        invalid_active = dict(active, vigencia_efectiva="VIGENTE", permite_pago=False, permite_consumo_cupon=False)
        self.assertFalse(validator.is_valid(invalid_active))
        terminal = dict(active, estado_persistido="LIBERADA", vigencia_efectiva="NO_APLICA")
        self.assertTrue(validator.is_valid(terminal))
        terminal["permite_pago"] = True
        self.assertFalse(validator.is_valid(terminal))
        endpoint = self.openapi["paths"]["/interno/carga-masiva/contenidos/{contentId}"]["get"]
        self.assertTrue(endpoint["x-internal"])
        self.assertEqual(endpoint["x-allowed-client-ids"], ["catalog-svc"])
        self.assertIn("X-Content-SHA256", endpoint["responses"]["200"]["headers"])
        self.assertIn("Content-Length", endpoint["responses"]["200"]["headers"])
        self.assertIn("30 días", endpoint["description"])
        content_schema = endpoint["responses"]["200"]["content"]["application/json"]["schema"]
        self.assertEqual(content_schema["$ref"], "#/components/schemas/BulkContentDocument")
        self.assertNotIn("contentEncoding", str(endpoint["responses"]["200"]["content"]["application/json"]))
        document_validator = self.schema_validator("BulkContentDocument")
        row = json.loads(json.dumps(self.fixtures["catalogBulkUpsertRequestedAlta"]["data"]["rows"][0]))
        valid_document = {"rows": [row]}
        self.assertTrue(document_validator.is_valid(valid_document))
        update_row = json.loads(json.dumps(self.fixtures["catalogBulkUpsertRequestedActualizacion"]["data"]["rows"][0]))
        self.assertTrue(document_validator.is_valid({"rows": [update_row]}))
        self.assertFalse(document_validator.is_valid({"rows": []}))
        self.assertFalse(document_validator.is_valid({"rows": "not-an-array"}))
        invalid_row = dict(row, row_number=1)
        self.assertFalse(document_validator.is_valid({"rows": [invalid_row]}))
        invalid_row = dict(row, row_operation_id="not-a-uuid")
        self.assertFalse(document_validator.is_valid({"rows": [invalid_row]}))
        payload = json.dumps(valid_document, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        # Referencia fija e independiente del cálculo sobre los bytes recibidos.
        expected = {"byte_length": 388, "sha256": "203d228ae221ed440635c9a9a67e008ba7a22abc0f3b5015ba23efc80b8adbe9"}
        self.assertEqual(verify_claim_check_bytes(payload, expected, document_validator), "ACCEPTED")

        altered_same_length = bytearray(payload)
        altered_same_length[-2] ^= 1
        self.assertEqual(len(altered_same_length), expected["byte_length"])
        self.assertEqual(verify_claim_check_bytes(bytes(altered_same_length), expected, document_validator), "SHA256_MISMATCH")
        self.assertEqual(verify_claim_check_bytes(payload + b" ", expected, document_validator), "BYTE_LENGTH_MISMATCH")
        wrong_hash = dict(expected, sha256="0" * 64)
        self.assertEqual(verify_claim_check_bytes(payload, wrong_hash, document_validator), "SHA256_MISMATCH")

        invalid_rows = b'{"rows":[]} '
        invalid_rows_reference = {"byte_length": 12, "sha256": "b83067ed019cdf39a294f608caa862713b59c6de22a0c0d9947bfc4c8bcc5c25"}
        self.assertEqual(verify_claim_check_bytes(invalid_rows, invalid_rows_reference, document_validator), "INVALID_ROWS")
        json_string = b'"{\\"rows\\":[{}]}"'
        string_reference = {"byte_length": 17, "sha256": "e7961c0507b98ed11224d3b315e94689074525201b1c7bffbef0ad040490a7a4"}
        self.assertEqual(verify_claim_check_bytes(json_string, string_reference, document_validator), "DOCUMENT_NOT_OBJECT")

        equivalent_but_different = b'{ "rows": [' + payload[len(b'{"rows":['):]
        self.assertEqual(json.loads(equivalent_but_different), valid_document)
        self.assertNotEqual(equivalent_but_different, payload)
        self.assertNotEqual(verify_claim_check_bytes(equivalent_but_different, expected, document_validator), "ACCEPTED")
        self.assertEqual(set(endpoint["responses"]["200"]["content"]), {"application/json"})

    def test_coupon_header_and_body_idempotency_error_partition(self):
        body_validator = self.schema_validator("CouponConsumptionRequest")
        valid_body = self.axel["coupon_consumption_request"]
        self.assertTrue(body_validator.is_valid(valid_body))
        missing = dict(valid_body)
        missing.pop("operation_id")
        self.assertFalse(body_validator.is_valid(missing))
        malformed = dict(valid_body, operation_id="not-a-uuid")
        self.assertFalse(body_validator.is_valid(malformed))
        parameter = self.openapi["paths"]["/cupones/consumos"]["post"]["parameters"][0]
        self.assertTrue(parameter["required"])
        key_validator = Draft202012Validator(parameter["schema"], format_checker=Draft202012Validator.FORMAT_CHECKER)
        self.assertFalse(key_validator.is_valid("not-a-uuid"))
        self.assertEqual([case["status"] for case in self.axel["idempotency_cases"]], [400, 400, 409, 409])
        self.assertEqual([case["code"] for case in self.axel["idempotency_cases"]], ["VALIDACION", "VALIDACION", "IDEMPOTENCY_CONFLICT", "IDEMPOTENCY_CONFLICT"])
        for route in ("/cupones/consumos", "/cupones/restauraciones"):
            operation = self.openapi["paths"][route]["post"]
            self.assertIn("distintos", operation["description"].lower())
            self.assertIn("UUID requerido", operation["parameters"][0]["description"])
            self.assertEqual(operation["x-required-scope"], "cupones:consumir" if route.endswith("consumos") else "cupones:restaurar")
            self.assertEqual(operation["x-allowed-client-ids"], ["modulo-ventas"])
        self.assertIn("exactamente el mismo texto opaco que order_id", self.openapi["components"]["schemas"]["CouponConsumptionRequest"]["properties"]["commercial_snapshot_ref"]["description"])

    def test_four_g5_routes_have_separate_security_scope_and_assumption_states(self):
        expected = {
            ("/cupones/consumos", "post"): "cupones:consumir",
            ("/cupones/restauraciones", "post"): "cupones:restaurar",
            ("/cupones/operaciones/{operationId}", "get"): "cupones:operaciones:leer",
            ("/inventario/reservas/{reservaId}/estado", "get"): "inventario:reservas:estado:leer",
        }
        for (path, method), scope in expected.items():
            with self.subTest(path=path):
                operation = self.openapi["paths"][path][method]
                self.assertEqual(operation["x-required-scope"], scope)
                self.assertEqual(operation["x-service-audience"], "api-productos")
                self.assertEqual(operation["x-allowed-client-ids"], ["modulo-ventas"])
                self.assertEqual(operation["x-contract-status"], "SEMIFINAL_G6")
                self.assertEqual(operation["x-acceptance-assumption"], "ACEPTACION_G5_ASUMIDA_PARA_PLANIFICACION")
                self.assertEqual(operation["x-external-homologation"], "PENDIENTE_HOMOLOGACION_EXTERNA")
                self.assertEqual(operation["x-grant-status"], "PENDIENTE_VERIFICACION_G7")
        for path in ("/cupones/operaciones/{operationId}", "/inventario/reservas/{reservaId}/estado"):
            operation = self.openapi["paths"][path]["get"]
            self.assertIn("order_id", [parameter["name"] for parameter in operation["parameters"]])
            self.assertIn("404", operation["responses"])
        bulk = self.openapi["paths"]["/interno/carga-masiva/contenidos/{contentId}"]["get"]
        self.assertEqual(bulk["x-allowed-client-ids"], ["catalog-svc"])
        self.assertNotIn("x-acceptance-assumption", bulk)
        self.assertEqual(bulk["x-required-scope"], "carga-masiva:contenidos:leer")
        self.assertTrue(bulk["x-internal"])
        self.assertEqual(bulk["x-owner"], "bulk-svc")
        self.assertEqual(bulk["x-consumer"], "catalog-svc")
        self.assertNotIn("modulo-ventas", bulk["x-allowed-client-ids"])
        self.assertNotIn("modulo-postventa", bulk["x-allowed-client-ids"])
        self.assertNotIn("x-external-homologation", bulk)
        self.assertEqual(bulk["x-authorization-status"], "PENDIENTE_AUTORIZACION_G7")
        self.assertEqual(bulk["x-grant-status"], "PENDIENTE_VERIFICACION_G7")
        self.assertEqual(bulk["x-runtime-status"], "PENDIENTE_IMPLEMENTACION")
        self.assertNotIn("PENDIENTE_HOMOLOGACION_EXTERNA", bulk.get("x-integration-decisions", []))
        external_g5_paths = {
            "/cupones/consumos",
            "/cupones/restauraciones",
            "/cupones/operaciones/{operationId}",
            "/inventario/reservas/{reservaId}/estado",
        }
        self.assertNotIn("/interno/carga-masiva/contenidos/{contentId}", external_g5_paths)

    def test_axel_coupon_and_reservation_examples_validate_against_published_schemas(self):
        self.assertTrue(self.schema_validator("CouponConsumptionRequest").is_valid(self.axel["coupon_consumption_request"]))
        self.assertTrue(self.schema_validator("CouponRestorationRequest").is_valid(self.axel["coupon_restoration_request"]))
        snapshot_validator = self.schema_validator("CouponOperationSnapshot")
        self.assertTrue(snapshot_validator.is_valid(self.axel["coupon_operation_pending"]))
        self.assertTrue(snapshot_validator.is_valid(self.axel["coupon_operation_completed"]))
        reservation_validator = self.schema_validator("ReservationStatusSnapshot")
        self.assertTrue(reservation_validator.is_valid(self.axel["reservation_active"]))
        self.assertTrue(reservation_validator.is_valid(self.axel["reservation_expired"]))
        self.assertEqual(self.axel["coupon_consumption_request"]["commercial_snapshot_ref"], self.axel["coupon_consumption_request"]["order_id"])
        self.assertEqual(self.axel["coupon_restoration_request"]["consumption_operation_id"], self.axel["coupon_operation_completed"]["operation_id"])

    def test_asyncapi_internal_basic_topology_and_claim_check(self):
        api = self.asyncapi
        self.assertEqual(api["asyncapi"], "3.0.0")
        self.assertEqual(api["info"]["version"], "0.7.0-rc.2")
        self.assertEqual(len(api["channels"]), 19)
        self.assertEqual(len(api["components"]["messages"]), 29)
        self.assertNotIn("servers", api)
        self.assertNotIn("x-rabbitmq-topology", api)
        self.assertIn("g6.promotions.commands", [channel["address"] for channel in api["channels"].values()])
        self.assertEqual(set(api["x-blocked-contracts"]), {"pricing.bulk.price.apply.requested"})
        self.assertIn("message_id", api["x-delivery-model"]["inbox"]["deduplication_key"])
        self.assertFalse(api["x-delivery-model"]["exactly_once"])
        for blocked in api["x-blocked-contracts"]:
            message = next(m for m in api["components"]["messages"].values() if m["name"] == blocked)
            self.assertEqual(message["x-runtime-status"], "RESERVADO_NO_APLICA_BULK_V2")
            channel = next(c for c in api["channels"].values() if any(ref["$ref"].endswith("/" + next(k for k, v in api["components"]["messages"].items() if v is message)) for ref in c["messages"].values()))
            self.assertEqual(channel["x-runtime-status"], "RESERVADO_NO_APLICA_BULK_V2")
        self.assertEqual(api["components"]["messages"]["InventoryBulkStockAdjustRequested"]["x-runtime-status"], "PENDIENTE_IMPLEMENTACION")
        self.assertEqual(api["components"]["messages"]["InventoryBulkStockAdjustRequested"]["payload"]["allOf"][1]["properties"]["data"]["$ref"], "#/components/schemas/InventoryBulkStockAdjustRequestedData")
        self.assertEqual(api["x-transport"]["max_complete_message_size_bytes"], 262144)
        bulk = api["components"]["schemas"]["CatalogBulkUpsertRequestedDataV3"]
        self.assertIn("content_ref", bulk["required"])
        self.assertNotIn("rows", bulk["properties"])
        self.assertTrue({"batch_id", "batch_operation_id", "template_version", "mode"}.issubset(bulk["required"]))
        for channel in api["channels"].values():
            self.assertNotIn("modulo-ventas", str(channel.get("x-consumer", "")))
            self.assertNotIn("api-gateway/bff", str(channel.get("x-consumer", "")))
        for message in api["components"]["messages"].values():
            self.assertNotIn("modulo-ventas", message.get("x-consumers", []))
            self.assertNotIn("api-gateway/bff", message.get("x-consumers", []))

        requested = api["components"]["messages"]["CatalogBulkUpsertRequested"]
        self.assertEqual(requested["x-deduplication-key"], "message_id")
        self.assertEqual(requested["x-business-idempotency-key"], "batch_operation_id")
        description = requested["description"].lower()
        self.assertIn("v1 y v2 conservan rows inline", description)
        self.assertIn("v3 usa content_ref", description)
        self.assertIn("message_id identifica la entrega", description)
        self.assertIn("batch_operation_id identifica la operación masiva", description)
        self.assertIn("verificar su byte_length y sha-256", description)
        self.assertIn("catalog debe soportar v3", description)
        self.assertNotRegex(description, r"routing\s*key|exchange")
        business_description = requested["x-business-idempotency-description"].lower()
        self.assertIn("v1, v2 y v3", business_description)
        self.assertIn("row_operation_id", business_description)

    def test_h5_internal_instances_preserve_payload_rules_and_claim_check_version(self):
        cases = {
            "pricingPriceChanged": "PricingPriceChanged",
            "catalogProductDeactivated": "CatalogProductDeactivated",
            "catalogSkuDeactivated": "CatalogSkuDeactivated",
            "inventoryStockChanged": "InventoryStockChanged",
            "catalogBulkUpsertRequestedAlta": "CatalogBulkUpsertRequested",
            "catalogBulkUpsertRequestedActualizacion": "CatalogBulkUpsertRequested",
            "catalogBulkUpsertCompleted": "CatalogBulkUpsertCompleted",
            "catalogBulkUpsertRejected": "CatalogBulkUpsertRejected",
        }
        for fixture, message in cases.items():
            with self.subTest(fixture=fixture):
                self.assertTrue(self.message_validator(message).is_valid(self.fixtures[fixture]))
        inline = self.fixtures["catalogBulkUpsertRequestedAlta"]
        referenced = json.loads(json.dumps(inline))
        referenced["schema_version"] = 3
        referenced["data"].pop("rows")
        referenced["data"]["content_ref"] = {"content_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "sha256": "a" * 64, "byte_length": 42, "content_type": "application/json"}
        validator = self.message_validator("CatalogBulkUpsertRequested")
        # Los fixtures históricos V1 se validan sin modificar sus schemas o payloads.
        self.assertEqual(inline["schema_version"], 1)
        self.assertTrue(validator.is_valid(inline))
        self.assertTrue(validator.is_valid(self.fixtures["catalogBulkUpsertRequestedActualizacion"]))

        # V2 mantiene rows inline y la compatibilidad semántica del fixture previo.
        inline_v2 = json.loads(json.dumps(inline))
        inline_v2["schema_version"] = 2
        self.assertTrue(validator.is_valid(inline_v2))
        self.assertIn("rows", inline_v2["data"])
        self.assertNotIn("content_ref", inline_v2["data"])

        self.assertTrue(validator.is_valid(referenced))
        self.assertIn("content_ref", referenced["data"])
        self.assertNotIn("rows", referenced["data"])
        missing_content_ref = json.loads(json.dumps(referenced))
        missing_content_ref["data"].pop("content_ref")
        self.assertFalse(validator.is_valid(missing_content_ref))
        inline_rows_in_v3 = json.loads(json.dumps(referenced))
        inline_rows_in_v3["data"]["rows"] = []
        self.assertFalse(validator.is_valid(inline_rows_in_v3))
        referenced["data"]["content_ref"]["sha256"] = "not-a-sha256"
        self.assertFalse(validator.is_valid(referenced))
        for name, message_name, data in (
            ("PromotionsCouponConsumptionRequested", "promotions.coupon.consumption.requested", {"order_id": "order-x", "coupon_code": "SAVE10", "customer_ref": None, "channel_id": "MARKETPLACE", "reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "commercial_snapshot_ref": "snapshot-x", "effective_at": "2026-11-18T10:00:00Z"}),
            ("PromotionsCouponRestorationRequested", "promotions.coupon.restoration.requested", {"order_id": "order-x", "consumption_operation_id": "5af9c13f-c44e-41f6-97b9-0e971562b641", "cancellation_reason": "cancelled", "cancelled_at": "2026-11-18T10:00:00Z"}),
        ):
            command = {"message_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "correlation_id": "5af9c13f-c44e-41f6-97b9-0e971562b641", "schema_version": 2, "occurred_at": "2026-11-18T10:00:00Z", "operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "producer": "promotions-svc", "kind": "command", "name": message_name, "data": data}
            self.assertTrue(self.message_validator(name).is_valid(command))
            command["producer"] = "modulo-ventas"
            self.assertFalse(self.message_validator(name).is_valid(command))

    def test_h4_snapshots_are_byte_identical_and_hash_listed(self):
        expected_hashes = {
            "contratos/historico/h4/http/openapi.yaml": "5f5aec5053fdc65a9dceb82c010fc0082c486145533e623158426c61bfcc1ed4",
            "contratos/historico/h4/eventos/asyncapi.yaml": "ef7177d34e33c858a70b97acd3ad21c3b6dff97ecbd0785d77f3d2f0dcb28029",
        }
        sums = {}
        for line in (ROOT / "contratos/historico/h4/SHA256SUMS").read_text(encoding="utf-8").splitlines():
            digest, path = line.split(maxsplit=1)
            sums[path.strip().lstrip("*./")] = digest.lower()
        for path, expected in expected_hashes.items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), expected)
            self.assertEqual(sums.get(path), expected)
        historical_openapi = yaml.safe_load((ROOT / "contratos/historico/h4/http/openapi.yaml").read_text(encoding="utf-8"))
        historical_asyncapi = yaml.safe_load((ROOT / "contratos/historico/h4/eventos/asyncapi.yaml").read_text(encoding="utf-8"))
        self.assertEqual(historical_openapi["info"]["version"], "0.6.0-rc.5")
        self.assertEqual(historical_asyncapi["info"]["version"], "0.6.0-rc.4")
        self.assertEqual(len(historical_asyncapi["channels"]), 40)
        inventory = (ROOT / "contratos/eventos/INVENTARIO-40-MENSAJES-H5.md").read_text(encoding="utf-8")
        message_names = {message["name"] for message in historical_asyncapi["components"]["messages"].values()}
        self.assertEqual(len(message_names), 40)
        self.assertTrue(all(f"`{name}`" in inventory for name in message_names))
        self.assertIn("api-gateway/bff", inventory)

    def test_external_g5_thirteen_message_allocations_remain_complete(self):
        matrix = (ROOT / "integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md").read_text(encoding="utf-8")
        expected = {
            "promotions.coupon.consumption.requested": "POST /api/v1/cupones/consumos",
            "promotions.coupon.restoration.requested": "POST /api/v1/cupones/restauraciones",
            "promotions.coupon.consumption.completed": "GET /api/v1/cupones/operaciones/{operationId}",
            "promotions.coupon.consumption.rejected": "GET /api/v1/cupones/operaciones/{operationId}",
            "promotions.coupon.restoration.completed": "GET /api/v1/cupones/operaciones/{operationId}",
            "promotions.coupon.restoration.rejected": "GET /api/v1/cupones/operaciones/{operationId}",
            "inventory.reservation.created": "GET /api/v1/inventario/operaciones/{operationId}",
            "inventory.reservation.rejected": "GET /api/v1/inventario/operaciones/{operationId}",
            "inventory.reservation.consumed": "GET /api/v1/inventario/operaciones/{operationId}",
            "inventory.reservation.released": "GET /api/v1/inventario/operaciones/{operationId}",
            "inventory.reservation.expired": "GET /api/v1/inventario/reservas/{reservaId}/estado",
            "inventory.consumption.completed": "GET /api/v1/inventario/operaciones/{operationId}",
            "inventory.consumption.rejected": "GET /api/v1/inventario/operaciones/{operationId}",
        }
        self.assertEqual(len(expected), 13)
        for message, route in expected.items():
            with self.subTest(message=message):
                row = next(line for line in matrix.splitlines() if line.startswith("|") and f"`{message}`" in line)
                self.assertEqual(row.count(f"`{message}`"), 1)
                if route not in row:
                    self.assertIn("mismo GET", row)
                    self.assertIn(route, matrix)
        self.assertIn("conciliación durable", matrix)
        self.assertIn("api-gateway/bff", matrix)
        self.assertNotIn("g5.ventas.commands", str(self.asyncapi["channels"]))


if __name__ == "__main__":
    unittest.main()

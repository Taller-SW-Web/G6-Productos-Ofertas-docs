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


class H5SemifinalContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.openapi = yaml.safe_load((ROOT / "contratos/http/openapi.yaml").read_text(encoding="utf-8"))
        cls.asyncapi = yaml.safe_load((ROOT / "contratos/eventos/asyncapi.yaml").read_text(encoding="utf-8"))
        cls.fixtures = json.loads((ROOT / "tests/contratos/fixtures/asyncapi-0.6.0-rc.4-h4-events.json").read_text(encoding="utf-8"))
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

    def test_openapi_semifinal_version_and_operation_baseline(self):
        self.assertEqual(self.openapi["openapi"], "3.1.0")
        self.assertEqual(self.openapi["info"]["version"], "0.7.0-rc.1")
        old = yaml.safe_load((ROOT / "contratos/historico/h4/http/openapi.yaml").read_text(encoding="utf-8"))
        old_ids = {op["operationId"] for item in old["paths"].values() for method, op in item.items() if method in {"get", "post", "put", "patch", "delete"}}
        new_ops = [(path, method, op) for path, item in self.openapi["paths"].items() for method, op in item.items() if method in {"get", "post", "put", "patch", "delete"}]
        ids = [op["operationId"] for _, _, op in new_ops]
        self.assertEqual(len(old_ids), 143)
        self.assertTrue(old_ids <= set(ids))
        self.assertEqual(len(new_ops), 148)
        self.assertEqual(len(set(ids)), 148)
        added = [(p, m) for p, m, op in new_ops if op["operationId"] not in old_ids]
        self.assertEqual(set(added), {("/cupones/consumos", "post"), ("/cupones/restauraciones", "post"), ("/cupones/operaciones/{operationId}", "get"), ("/inventario/reservas/{reservaId}/estado", "get"), ("/interno/carga-masiva/contenidos/{contentId}", "get")})

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
        snapshot = self.openapi["components"]["schemas"]["CouponOperationSnapshot"]
        snapshot_for_validation = json.loads(json.dumps(snapshot))
        snapshot_for_validation["properties"]["result"]["oneOf"][1] = self.openapi["components"]["schemas"]["CouponOperationResult"]
        snapshot_for_validation["allOf"][1]["then"]["properties"]["result"] = self.openapi["components"]["schemas"]["CouponOperationResult"]
        snapshot_for_validation["allOf"][4]["then"]["properties"]["result"]["required"] = ["order_id", "consumption_operation_id"]
        snapshot_for_validation["allOf"][4]["then"]["properties"]["result"]["properties"] = {"consumption_operation_id": {"type": "string", "format": "uuid"}}
        validator = Draft202012Validator(snapshot_for_validation)
        pending = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "operation_type": "CONSUMIR_CUPON", "status": "ACCEPTED", "order_id": "pedido-x", "accepted_at": "2026-11-18T10:00:00Z", "updated_at": "2026-11-18T10:00:00Z", "completed_at": None, "result": None}
        self.assertTrue(validator.is_valid(pending))
        pending["completed_at"] = "2026-11-18T10:00:01Z"
        self.assertFalse(validator.is_valid(pending))
        completed = {"operation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "operation_type": "CONSUMIR_CUPON", "status": "COMPLETED", "order_id": "pedido-x", "accepted_at": "2026-11-18T10:00:00Z", "updated_at": "2026-11-18T10:00:02Z", "completed_at": "2026-11-18T10:00:02Z", "result": {"order_id": "pedido-x", "coupon_code": "SAVE10", "reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "commercial_snapshot_ref": "snapshot-x", "decided_at": "2026-11-18T10:00:02Z"}}
        self.assertTrue(validator.is_valid(completed))
        rejected = json.loads(json.dumps(completed))
        rejected["status"] = "REJECTED"
        rejected["result"]["result_code"] = "COUPON_EXPIRED"
        self.assertTrue(validator.is_valid(rejected))
        rejected["result"].pop("result_code")
        self.assertFalse(validator.is_valid(rejected))

    def test_reservation_read_semantics_and_bulk_private_integrity(self):
        reserve = self.openapi["components"]["schemas"]["ReservationStatusSnapshot"]
        validator = Draft202012Validator(reserve)
        active = {"reservation_id": "12b85ba4-a5b4-44fa-8c06-e554f5026100", "order_id": "order-x", "estado_persistido": "ACTIVA", "expires_at": "2026-11-18T10:00:00Z", "observed_at": "2026-11-18T10:00:00Z", "vigencia_efectiva": "VENCIDA", "permite_pago": False, "permite_consumo_cupon": False}
        self.assertTrue(validator.is_valid(active))
        invalid_active = dict(active, vigencia_efectiva="VIGENTE", permite_pago=False, permite_consumo_cupon=False)
        self.assertFalse(validator.is_valid(invalid_active))
        terminal = dict(active, estado_persistido="LIBERADA", vigencia_efectiva="NO_APLICA")
        self.assertTrue(validator.is_valid(terminal))
        terminal["permite_pago"] = True
        self.assertFalse(validator.is_valid(terminal))
        endpoint = self.openapi["paths"]["/interno/carga-masiva/contenidos/{contentId}"]["get"]
        self.assertTrue(endpoint["x-internal"])
        self.assertIn("X-Content-SHA256", endpoint["responses"]["200"]["headers"])
        self.assertIn("30 días", endpoint["description"])

    def test_asyncapi_internal_basic_topology_and_claim_check(self):
        api = self.asyncapi
        self.assertEqual(api["asyncapi"], "3.0.0")
        self.assertEqual(api["info"]["version"], "0.7.0-rc.1")
        self.assertEqual(len(api["channels"]), 19)
        self.assertEqual(len(api["components"]["messages"]), 29)
        self.assertNotIn("servers", api)
        self.assertNotIn("x-rabbitmq-topology", api)
        self.assertIn("g6.promotions.commands", [channel["address"] for channel in api["channels"].values()])
        self.assertEqual(set(api["x-blocked-contracts"]), {"inventory.bulk.stock.adjust.requested", "pricing.bulk.price.apply.requested"})
        self.assertIn("message_id", api["x-delivery-model"]["inbox"]["deduplication_key"])
        self.assertFalse(api["x-delivery-model"]["exactly_once"])
        for blocked in api["x-blocked-contracts"]:
            message = next(m for m in api["components"]["messages"].values() if m["name"] == blocked)
            self.assertEqual(message["x-runtime-status"], "BLOCKED_CONTRACT")
            channel = next(c for c in api["channels"].values() if any(ref["$ref"].endswith("/" + next(k for k, v in api["components"]["messages"].items() if v is message)) for ref in c["messages"].values()))
            self.assertEqual(channel["x-runtime-status"], "BLOCKED_CONTRACT")
        self.assertEqual(api["x-transport"]["max_complete_message_size_bytes"], 262144)
        bulk = api["components"]["schemas"]["CatalogBulkUpsertRequestedDataV3"]
        self.assertIn("content_ref", bulk["required"])
        self.assertNotIn("rows", bulk["properties"])
        for channel in api["channels"].values():
            self.assertNotIn("modulo-ventas", str(channel.get("x-consumer", "")))
            self.assertNotIn("api-gateway/bff", str(channel.get("x-consumer", "")))
        for message in api["components"]["messages"].values():
            self.assertNotIn("modulo-ventas", message.get("x-consumers", []))
            self.assertNotIn("api-gateway/bff", message.get("x-consumers", []))

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
        self.assertTrue(validator.is_valid(referenced))
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
        sums = (ROOT / "contratos/historico/h4/SHA256SUMS").read_text(encoding="utf-8")
        for path in ("contratos/historico/h4/http/openapi.yaml", "contratos/historico/h4/eventos/asyncapi.yaml"):
            digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
            self.assertIn(digest, sums)
        historical_openapi = yaml.safe_load((ROOT / "contratos/historico/h4/http/openapi.yaml").read_text(encoding="utf-8"))
        historical_asyncapi = yaml.safe_load((ROOT / "contratos/historico/h4/eventos/asyncapi.yaml").read_text(encoding="utf-8"))
        self.assertEqual(historical_openapi["info"]["version"], "0.6.0-rc.5")
        self.assertEqual(historical_asyncapi["info"]["version"], "0.6.0-rc.4")
        self.assertEqual(len(historical_asyncapi["channels"]), 40)


if __name__ == "__main__":
    unittest.main()

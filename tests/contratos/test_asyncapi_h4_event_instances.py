"""Full-message contract checks for the seven H4 typed AsyncAPI events.

Inventory's fixture follows the current OutboxService/stock-changed.spec.ts
snapshot. Pricing's envelope version follows pricing-mutations.ts, while its
payload factory remains pending in Backend. The current Backend worktree has no
Catalog deactivation/Bulk upsert event publishers; those instances exercise the
approved candidate contract only and do not claim runtime producer evidence.
"""

from copy import deepcopy
import json
from pathlib import Path
import unittest

import jsonschema
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012
import yaml

ROOT = Path(__file__).resolve().parents[2]
ASYNCAPI_FILE = ROOT / "contratos/eventos/asyncapi.yaml"
OPENAPI_FILE = ROOT / "contratos/http/openapi.yaml"
FIXTURE_FILE = ROOT / "tests/contratos/fixtures/asyncapi-0.6.0-rc.4-h4-events.json"


class AsyncApiH4EventInstanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asyncapi = yaml.safe_load(ASYNCAPI_FILE.read_text(encoding="utf-8"))
        cls.openapi = yaml.safe_load(OPENAPI_FILE.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(FIXTURE_FILE.read_text(encoding="utf-8"))
        cls.registry = (
            Registry()
            .with_resource(
                ASYNCAPI_FILE.resolve().as_uri(),
                Resource.from_contents(cls.asyncapi, default_specification=DRAFT202012),
            )
            .with_resource(
                OPENAPI_FILE.resolve().as_uri(),
                Resource.from_contents(cls.openapi, default_specification=DRAFT202012),
            )
        )

    @classmethod
    def validator_for(cls, message_name):
        return jsonschema.Draft202012Validator(
            {"$ref": f"{ASYNCAPI_FILE.resolve().as_uri()}#/components/messages/{message_name}/payload"},
            registry=cls.registry,
            format_checker=jsonschema.Draft202012Validator.FORMAT_CHECKER,
        )

    @classmethod
    def openapi_validator_for(cls, schema_name):
        return jsonschema.Draft202012Validator(
            {"$ref": f"{OPENAPI_FILE.resolve().as_uri()}#/components/schemas/{schema_name}"},
            registry=cls.registry,
            format_checker=jsonschema.Draft202012Validator.FORMAT_CHECKER,
        )

    def assert_valid(self, message_name, instance):
        errors = list(self.validator_for(message_name).iter_errors(instance))
        self.assertEqual(errors, [], f"{message_name}: {errors}")

    def assert_invalid(self, message_name, instance):
        self.assertFalse(self.validator_for(message_name).is_valid(instance), message_name)

    def test_complete_h4_typed_messages_validate_with_external_dto_refs(self):
        cases = {
            "catalogProductDeactivated": "CatalogProductDeactivated",
            "catalogSkuDeactivated": "CatalogSkuDeactivated",
            "pricingPriceChanged": "PricingPriceChanged",
            "inventoryStockChanged": "InventoryStockChanged",
            "catalogBulkUpsertRequestedAlta": "CatalogBulkUpsertRequested",
            "catalogBulkUpsertRequestedActualizacion": "CatalogBulkUpsertRequested",
            "catalogBulkUpsertCompleted": "CatalogBulkUpsertCompleted",
            "catalogBulkUpsertRejected": "CatalogBulkUpsertRejected",
        }
        for fixture_name, message_name in cases.items():
            with self.subTest(fixture=fixture_name, message=message_name):
                self.assert_valid(message_name, self.fixtures[fixture_name])

    def test_bulk_mode_selects_exclusive_product_and_variant_dtos(self):
        alta = self.fixtures["catalogBulkUpsertRequestedAlta"]
        self.assertEqual(alta["data"]["mode"], "ALTA")
        self.assertIsNone(alta["data"]["rows"][0]["variant"])
        self.assertEqual(alta["data"]["rows"][1]["variant"]["sku"], "SKU-VARIANT-001-M")

        actualizacion = self.fixtures["catalogBulkUpsertRequestedActualizacion"]
        self.assertEqual(actualizacion["data"]["mode"], "ACTUALIZACION")
        self.assertEqual(actualizacion["data"]["rows"][0]["variant_id"], "variant-123")

        invalid_alta = deepcopy(alta)
        invalid_alta["data"]["rows"][1]["product"] = {"nombre": "sin campos obligatorios de alta"}
        self.assert_invalid("CatalogBulkUpsertRequested", invalid_alta)

        invalid_update = deepcopy(actualizacion)
        invalid_update["data"]["rows"][0]["producto_id"] = None
        self.assert_invalid("CatalogBulkUpsertRequested", invalid_update)

        invalid_variant_update = deepcopy(actualizacion)
        invalid_variant_update["data"]["rows"][0]["variant_id"] = None
        self.assert_invalid("CatalogBulkUpsertRequested", invalid_variant_update)

        invalid_update_dto_for_alta = deepcopy(alta)
        invalid_update_dto_for_alta["data"]["rows"][0]["product"] = {"catalogVersion": 1}
        self.assert_invalid("CatalogBulkUpsertRequested", invalid_update_dto_for_alta)

    def test_inventory_v2_snapshot_is_location_scoped_and_not_a_commercial_decision(self):
        message = self.fixtures["inventoryStockChanged"]
        self.assertEqual(message["schema_version"], 2)
        self.assertEqual(message["data"]["stock_version"], 8)
        self.assertEqual(message["data"]["location_id"], "9129b578-631e-1735-8427-b683fb524380")
        schema = self.asyncapi["components"]["schemas"]["InventoryStockChangedData"]
        self.assertEqual(schema["properties"]["stock_version"]["minimum"], 1)
        self.assertIn("(sku, location_id)", schema["properties"]["stock_version"]["description"])
        self.assertIn("no existe una versión global por SKU", schema["properties"]["stock_version"]["description"])
        self.assertIn("invalidan sus proyecciones", schema["description"])
        self.assertIn("disponibilidad comercial autoritativa", schema["description"])

        wrong_envelope_version = deepcopy(message)
        wrong_envelope_version["schema_version"] = 1
        self.assert_invalid("InventoryStockChanged", wrong_envelope_version)
        invented_global_version = deepcopy(message)
        invented_global_version["data"]["sku_version"] = 8
        self.assert_invalid("InventoryStockChanged", invented_global_version)
        missing_location = deepcopy(message)
        del missing_location["data"]["location_id"]
        self.assert_invalid("InventoryStockChanged", missing_location)

    def test_negative_full_messages_are_rejected_for_all_seven_event_types(self):
        invalid = deepcopy(self.fixtures)
        invalid["catalogProductDeactivated"]["data"].pop("product_version")
        invalid["catalogSkuDeactivated"]["data"].pop("product_id")
        invalid["pricingPriceChanged"]["data"]["sku"] = None
        invalid["inventoryStockChanged"]["data"]["updated_at"] = "not-a-date"
        invalid["catalogBulkUpsertRequestedAlta"]["data"]["mode"] = "OTHER"
        invalid["catalogBulkUpsertCompleted"]["data"]["results"][0]["status"] = "SUCCESS"
        invalid["catalogBulkUpsertRejected"]["data"].pop("detail")

        cases = {
            "catalogProductDeactivated": "CatalogProductDeactivated",
            "catalogSkuDeactivated": "CatalogSkuDeactivated",
            "pricingPriceChanged": "PricingPriceChanged",
            "inventoryStockChanged": "InventoryStockChanged",
            "catalogBulkUpsertRequestedAlta": "CatalogBulkUpsertRequested",
            "catalogBulkUpsertCompleted": "CatalogBulkUpsertCompleted",
            "catalogBulkUpsertRejected": "CatalogBulkUpsertRejected",
        }
        for fixture_name, message_name in cases.items():
            with self.subTest(fixture=fixture_name, message=message_name):
                self.assert_invalid(message_name, invalid[fixture_name])

    def test_recommendation_and_combo_dtos_retain_existing_compatibility(self):
        recommendation = self.openapi["components"]["schemas"]["Recomendacion"]
        self.assertEqual(recommendation["properties"]["current_price"]["type"], ["number", "null"])
        self.assertNotIn("current_price", recommendation["required"])
        self.assertIn("precio efectivo mínimo", self.openapi["paths"]["/recomendaciones"]["get"]["description"])
        legacy_recommendation = {
            "product_id": "product-123",
            "type": "CROSS_SELL",
            "rule_priority": 1,
            "presentation_order": 1,
            "availability": "DISPONIBLE",
        }
        recommendation_validator = self.openapi_validator_for("Recomendacion")
        self.assertTrue(recommendation_validator.is_valid(legacy_recommendation))
        self.assertTrue(
            recommendation_validator.is_valid({**legacy_recommendation, "current_price": None})
        )

        combo = self.openapi["components"]["schemas"]["DisponibilidadCombo"]
        self.assertTrue(combo["additionalProperties"])
        self.assertNotIn("cantidadInformativa", combo["required"])
        self.assertIn("cantidadInformativa=null", self.openapi["paths"]["/combos/{comboId}/disponibilidad"]["get"]["description"])
        legacy_combo = {
            "comboId": "combo-123",
            "verificable": False,
            "calculated_at": "2026-11-01T10:00:00Z",
            "estadoActualizacion": "INCOMPLETA",
            "legacyMetadata": {"source": "older-provider"},
        }
        self.assertTrue(self.openapi_validator_for("DisponibilidadCombo").is_valid(legacy_combo))


if __name__ == "__main__":
    unittest.main()

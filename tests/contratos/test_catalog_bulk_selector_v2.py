"""Approved Bulk command v2, legacy v1 and unchanged result versions."""
from copy import deepcopy
import unittest
import test_asyncapi_h4_event_instances as h4


class CatalogBulkSelectorVersionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        h4.AsyncApiH4EventInstanceTests.setUpClass()
        cls.contract = h4.AsyncApiH4EventInstanceTests

    def message(self, version=2, alta=False):
        name = "catalogBulkUpsertRequestedAlta" if alta else "catalogBulkUpsertRequestedActualizacion"
        msg = deepcopy(self.contract.fixtures[name])
        msg["schema_version"] = version
        return msg

    def valid(self, msg):
        return self.contract.validator_for("CatalogBulkUpsertRequested").is_valid(msg)

    def test_both_versions_keep_alta_and_legacy_variant_updates(self):
        for version in (1, 2):
            self.assertTrue(self.valid(self.message(version, alta=True)))
            self.assertTrue(self.valid(self.message(version)))

    def test_v2_selectors_are_alternatives_and_opaque(self):
        for selector in ({"sku_variante": "000,/ñ SKU"}, {"variant_id": "variant-123"},
                         {"variant_id": "variant-123", "sku_variante": "000,/ñ SKU"}):
            msg = self.message()
            row = msg["data"]["rows"][0]
            row.pop("variant_id", None)
            row.update(selector)
            self.assertTrue(self.valid(msg), selector)
        msg["data"]["rows"][0]["variant_id"] = None
        self.assertTrue(self.valid(msg))

    def test_v1_rejects_new_field_and_v2_rejects_missing_invalid_selectors(self):
        legacy = self.message(1)
        legacy["data"]["rows"][0]["sku_variante"] = "SKU"
        self.assertFalse(self.valid(legacy))
        for selectors in ({}, {"variant_id": None}, {"sku_variante": None},
                          {"variant_id": ""}, {"sku_variante": ""}, {"sku_variante": 10},
                          {"variant_id": "", "sku_variante": "valid"}):
            msg = self.message()
            row = msg["data"]["rows"][0]
            row.pop("variant_id", None)
            row.update(selectors)
            self.assertFalse(self.valid(msg), selectors)

    def test_simple_update_needs_no_selectors_and_cannot_supply_a_variant_selector(self):
        msg = self.message()
        row = msg["data"]["rows"][0]
        row["variant"] = None
        row.pop("variant_id")
        self.assertTrue(self.valid(msg))
        for key in ("variant_id", "sku_variante"):
            invalid = deepcopy(msg)
            invalid["data"]["rows"][0][key] = "not-a-simple-selector"
            self.assertFalse(self.valid(invalid))

    def test_versions_remain_independent_and_cannot_be_omitted_in_v2_updates(self):
        for field in ("product", "variant"):
            for value in (None, -1, 0.5):
                msg = self.message()
                msg["data"]["rows"][0][field]["catalogVersion"] = value
                self.assertFalse(self.valid(msg))
            msg = self.message()
            msg["data"]["rows"][0][field].pop("catalogVersion")
            self.assertFalse(self.valid(msg))

    def test_version_discriminator_and_other_messages_are_unchanged(self):
        for version in (0, 3, "2"):
            msg = self.message()
            msg["schema_version"] = version
            self.assertFalse(self.valid(msg))
        for fixture, message in (("catalogBulkUpsertCompleted", "CatalogBulkUpsertCompleted"),
                                 ("catalogBulkUpsertRejected", "CatalogBulkUpsertRejected")):
            msg = deepcopy(self.contract.fixtures[fixture])
            validator = self.contract.validator_for(message)
            self.assertTrue(validator.is_valid(msg))
            msg["schema_version"] = 2
            self.assertFalse(validator.is_valid(msg))
        msg = self.message(alta=True)
        msg["data"]["rows"][0]["sku_variante"] = "not-an-update"
        self.assertFalse(self.valid(msg))
        msg = self.message()
        msg["data"]["rows"][0]["unknown"] = True
        self.assertFalse(self.valid(msg))


if __name__ == "__main__":
    unittest.main()

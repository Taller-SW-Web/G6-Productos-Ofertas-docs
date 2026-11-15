from __future__ import annotations

import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
OPENAPI = yaml.safe_load((ROOT / "contratos/http/openapi.yaml").read_text(encoding="utf-8"))


class G6OptimizationContractTests(unittest.TestCase):
    def test_candidate_version_and_operation_ids_are_unique(self):
        self.assertEqual(OPENAPI["info"]["version"], "0.6.0-rc.5")
        ids = [
            operation["operationId"]
            for path in OPENAPI["paths"].values()
            for method, operation in path.items()
            if method.lower() in {"get", "post", "put", "patch", "delete", "options", "head", "trace"}
            and isinstance(operation, dict)
            and "operationId" in operation
        ]
        self.assertEqual(len(ids), len(set(ids)))

    def test_catalog_sku_batch_security_and_bounded_opaque_inputs(self):
        paths = OPENAPI["paths"]
        admin = paths["/productos/administracion/skus/resolver"]["post"]
        private = paths["/productos/skus/contexto/lote"]["post"]
        self.assertEqual(admin["security"], [{"userBearer": []}])
        self.assertEqual(admin["x-required-role"], "GESTOR_COMERCIAL")
        self.assertEqual(private["security"], [{"serviceBearer": []}])
        self.assertTrue(private["x-internal"])
        self.assertEqual(private["x-required-scope"], "catalogo:leer")
        self.assertEqual(private["x-allowed-client-ids"], ["modulo-productos"])
        for operation in (admin, private):
            items = operation["requestBody"]["content"]["application/json"]["schema"]["properties"]["skus"]
            self.assertEqual((items["minItems"], items["maxItems"]), (1, 100))
            self.assertEqual((items["items"]["minLength"], items["items"]["maxLength"]), (1, 256))
        self.assertEqual(
            admin["responses"]["200"]["content"]["application/json"]["schema"]["properties"]["items"]["items"]["properties"]["resultado"]["enum"],
            ["ELEGIBLE", "INACTIVO", "NO_ELEGIBLE", "NO_ENCONTRADO"],
        )

    def test_type_filters_are_repeatable_arrays_and_price_filter_is_documented(self):
        operation = OPENAPI["paths"]["/productos"]["get"]
        params = {p["name"]: p for p in operation["parameters"] if isinstance(p, dict) and "name" in p}
        for name in ("tipoProductoIdsIncluidos", "tipoProductoIdsExcluidos"):
            self.assertEqual(params[name]["schema"]["type"], "array")
            self.assertTrue(params[name]["schema"]["uniqueItems"])
            self.assertTrue(params[name]["explode"])
        self.assertIn("antes de total", str(params["tipoProductoIdsExcluidos"]["description"]).lower())
        self.assertIn("precio efectivo vigente", params["precioMin"]["description"])
        admin = OPENAPI["paths"]["/productos/administracion"]["get"]
        admin_params = {p["name"]: p for p in admin["parameters"] if isinstance(p, dict) and "name" in p}
        self.assertEqual(admin["security"], [{"userBearer": []}])
        self.assertEqual(admin["x-required-role"], "GESTOR_COMERCIAL")
        self.assertIn("tipoProductoIdsIncluidos", admin_params)
        self.assertIn("tipoProductoIdsExcluidos", admin_params)

    def test_admin_audit_nullable_schema_and_combo_idempotency(self):
        paths = OPENAPI["paths"]
        admin_audit = paths["/auditoria-precios/administracion"]["get"]
        self.assertEqual(admin_audit["security"], [{"userBearer": []}])
        self.assertEqual(admin_audit["x-required-role"], "GESTOR_COMERCIAL")
        audit_schema = OPENAPI["components"]["schemas"]["RegistroAuditoriaPrecioAdministracion"]["properties"]
        self.assertEqual(audit_schema["sku"]["type"], ["string", "null"])
        self.assertEqual(audit_schema["canal_origen"]["type"], ["string", "null"])
        combo = paths["/combos/administracion"]["post"]
        self.assertEqual(combo["security"], [{"userBearer": []}])
        self.assertEqual(combo["x-required-role"], "GESTOR_COMERCIAL")
        key = OPENAPI["components"]["parameters"]["IdempotencyKey"]["schema"]
        self.assertEqual((key["minLength"], key["maxLength"]), (1, 128))
        self.assertEqual(key["pattern"], "^[A-Za-z0-9._:-]+$")
        self.assertIn("201", combo["responses"])
        self.assertIn("409", combo["responses"])


if __name__ == "__main__":
    unittest.main()


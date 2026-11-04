from __future__ import annotations

import unittest
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator, RefResolver

ROOT = Path(__file__).resolve().parents[2]
OPENAPI_PATH = ROOT / "contratos/http/openapi.yaml"


class G2PhysicalContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.openapi = yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))
        cls.operation = cls.openapi["paths"]["/productos/datos-fisicos/consulta"]["post"]

    def test_openapi_local_refs_resolve_and_operation_ids_are_unique(self):
        operation_ids = []

        def walk(value):
            if isinstance(value, dict):
                ref = value.get("$ref")
                if ref and ref.startswith("#/"):
                    node = self.openapi
                    for token in ref[2:].split("/"):
                        key = token.replace("~1", "/").replace("~0", "~")
                        node = node[int(key)] if isinstance(node, list) else node[key]
                for child in value.values():
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)

        walk(self.openapi)
        for path_item in self.openapi["paths"].values():
            if not isinstance(path_item, dict):
                continue
            for method, operation in path_item.items():
                if method.lower() in {"get", "post", "put", "patch", "delete", "options", "head", "trace"} and isinstance(operation, dict):
                    if "operationId" in operation:
                        operation_ids.append(operation["operationId"])
        self.assertEqual(len(operation_ids), len(set(operation_ids)))

    def test_physical_request_and_state_enum(self):
        request = self.openapi["components"]["schemas"]["ConsultaDatosFisicosRequest"]
        self.assertEqual((request["properties"]["skus"]["minItems"], request["properties"]["skus"]["maxItems"]), (1, 100))
        self.assertTrue(request["properties"]["skus"]["uniqueItems"])
        self.assertEqual(
            self.openapi["components"]["schemas"]["DatosFisicosSku"]["properties"]["estado"]["enum"],
            ["ACTIVO", "INACTIVO", "BORRADOR"],
        )

    def test_422_examples_match_code_specific_schemas(self):
        response = self.operation["responses"]["422"]["content"]["application/problem+json"]
        schema = response["schema"]
        resolver = RefResolver.from_schema(self.openapi)
        validator = Draft202012Validator(schema, resolver=resolver)
        for example in response["examples"].values():
            validator.validate(example["value"])

        incomplete = response["examples"]["datos_fisicos_incompletos"]["value"]
        invalid_sku = response["examples"]["sku_invalido"]["value"]
        base_sku = response["examples"]["sku_base_no_fisico"]["value"]
        self.assertIn("skusAfectados", incomplete["details"])
        self.assertNotIn("details", invalid_sku)
        self.assertIn("skusAfectados", base_sku["details"])
        details_schema = self.openapi["components"]["schemas"]["DetallesDatosFisicosIncompletos"]["properties"]["skusAfectados"]
        self.assertEqual(details_schema["type"], "array")
        self.assertEqual(details_schema["items"]["type"], "string")
        self.assertEqual(details_schema["minItems"], 1)
        self.assertTrue(details_schema["uniqueItems"])
        self.assertEqual(base_sku["details"]["skusAfectados"], ["BASE-001", "000BASE"])
        self.assertEqual(incomplete["details"]["skusAfectados"], ["SKU-001", "000ABC"])

    def test_physical_semantics_and_error_precedence_are_contractually_documented(self):
        description = self.operation["description"]
        self.assertIn("estado efectivo del SKU", description)
        self.assertIn("sku_base", description)
        self.assertIn("errores estructurales ordinarios SKU_INVALIDO no requieren ese detalle", description)
        self.assertIn("SKU_INVALIDO", description)
        self.assertIn("DATOS_FISICOS_INCOMPLETOS", description)
        self.assertIn("en orden de solicitud", description)
        self.assertIn("No se garantiza detectar fallos técnicos que el proveedor no pueda observar", description)

    def test_security_identity_and_scope_pending_status_remain_fixed(self):
        self.assertEqual(self.operation["security"], [{"serviceBearer": []}])
        self.assertEqual(self.operation["x-allowed-client-ids"], ["modulo-despacho"])
        self.assertEqual(self.operation["x-service-audience"], "api-productos")
        self.assertEqual(self.operation["x-required-scope"], "productos:fisicos:leer")
        self.assertEqual(self.operation["x-scope-registration-status"], "pending-security-registration")
        codes = self.operation["x-error-codes"]["422"]
        self.assertEqual(codes, ["SKU_INVALIDO", "DATOS_FISICOS_INCOMPLETOS"])


if __name__ == "__main__":
    unittest.main()

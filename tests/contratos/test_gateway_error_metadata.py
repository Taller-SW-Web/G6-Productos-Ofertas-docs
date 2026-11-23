from pathlib import Path

import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
    'listarSaldosFisicosAdministracion': {
        '400': ['VALIDACION'],
        '401': ['TOKEN_INVALIDO'],
        '403': ['SCOPE_INSUFICIENTE'],
        '429': ['RATE_LIMIT_EXCEDIDO'],
        '500': ['ERROR_INTERNO'],
        '503': ['SERVICIO_NO_DISPONIBLE'],
    },
    'listarAlertasOperativasInventario': {
        '400': ['VALIDACION'],
        '401': ['TOKEN_INVALIDO'],
        '403': ['SCOPE_INSUFICIENTE'],
        '429': ['RATE_LIMIT_EXCEDIDO'],
        '500': ['ERROR_INTERNO'],
        '503': ['SERVICIO_NO_DISPONIBLE'],
    },
    'listarUbicacionesInventario': {
        '400': ['VALIDACION'],
        '401': ['TOKEN_INVALIDO'],
        '403': ['SCOPE_INSUFICIENTE'],
        '429': ['RATE_LIMIT_EXCEDIDO'],
        '500': ['ERROR_INTERNO'],
        '503': ['SERVICIO_NO_DISPONIBLE'],
    },
    'listarTrasladosInventario': {
        '401': ['TOKEN_INVALIDO'],
        '403': ['SCOPE_INSUFICIENTE'],
        '500': ['ERROR_INTERNO'],
        '503': ['SERVICIO_NO_DISPONIBLE'],
    },
    'obtenerTrasladoInventario': {
        '401': ['TOKEN_INVALIDO'],
        '403': ['SCOPE_INSUFICIENTE'],
        '404': ['TRASLADO_NO_ENCONTRADO'],
        '500': ['ERROR_INTERNO'],
        '503': ['SERVICIO_NO_DISPONIBLE'],
    },
    'crearComboAdministracion': {
        '422': [
            'COMBO_ANIDADO_NO_PERMITIDO',
            'COMBO_COMPONENTES_INSUFICIENTES',
            'COMBO_COMPONENTE_DUPLICADO',
            'COMBO_PRECIO_INVALIDO',
        ],
    },
    'obtenerOperacionCuponH5': {'400': ['VALIDACION']},
    'obtenerEstadoReservaH5': {'400': ['VALIDACION']},
}


class GatewayErrorMetadataContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.openapi = yaml.safe_load(
            (ROOT / 'contratos/http/openapi.yaml').read_text(encoding='utf-8')
        )
        cls.operations = {
            operation['operationId']: {**operation, '_path': path_name}
            for path_name, path in cls.openapi['paths'].items()
            for operation in path.values()
            if isinstance(operation, dict) and 'operationId' in operation
        }

    def test_gateway_provider_error_codes_match_contract_and_problem_responses(self):
        for operation_id, expected in EXPECTED.items():
            with self.subTest(operation_id=operation_id):
                operation = self.operations[operation_id]
                actual = operation['x-error-codes']
                for status, codes in expected.items():
                    self.assertEqual(actual.get(status), codes, status)
                    response = operation['responses'][status]
                    if '$ref' in response:
                        target = response['$ref'].removeprefix('#/').split('/')
                        response = self.openapi
                        for part in target:
                            response = response[part]
                    self.assertIn(
                        'application/problem+json', response.get('content', {})
                    )
                    self.assertTrue(codes)

    def test_combo_422_is_a_typed_contract_response(self):
        response = self.operations['crearComboAdministracion']['responses']['422']
        schema = response['content']['application/problem+json']['schema']
        code_enum = schema['allOf'][1]['properties']['code']['enum']
        self.assertEqual(code_enum, EXPECTED['crearComboAdministracion']['422'])
        self.assertEqual(schema['allOf'][1]['properties']['status']['const'], 422)

    def test_unimplemented_internal_operations_remain_private_and_unclassified(self):
        for operation_id in (
            'filtrarSkusVendiblesInterno',
            'obtenerEvidenciaReservaCuponInterno',
        ):
            with self.subTest(operation_id=operation_id):
                operation = self.operations[operation_id]
                self.assertTrue(operation['_path'].startswith('/interno/'))
                self.assertTrue(operation.get('x-runtime-status', '').startswith('PENDIENTE'))
                self.assertNotIn('x-error-codes', operation)


    def test_problem_responses_are_classified_except_the_exact_pending_internal_set(self):
        allowed = {
            'filtrarSkusVendiblesInterno': {'400', '401', '403', '429', '500', '503'},
            'obtenerEvidenciaReservaCuponInterno': {
                '400', '401', '403', '404', '429', '500', '503'
            },
            'obtenerContenidoCargaMasivaInternoH5': {'400'},
        }
        missing = {}
        for operation_id, operation in self.operations.items():
            for status, response in operation['responses'].items():
                while '$ref' in response:
                    target = response['$ref'].removeprefix('#/').split('/')
                    response = self.openapi
                    for part in target:
                        response = response[part]
                if (
                    'application/problem+json' in response.get('content', {})
                    and status not in operation.get('x-error-codes', {})
                ):
                    self.assertTrue(operation.get('x-internal'))
                    self.assertTrue(operation.get('x-runtime-status', '').startswith('PENDIENTE'))
                    self.assertTrue(operation['_path'].startswith('/interno/'))
                    missing.setdefault(operation_id, set()).add(status)
        self.assertEqual(missing, allowed)

    def test_no_other_operation_is_missing_error_code_metadata(self):
        excluded = {
            'filtrarSkusVendiblesInterno',
            'obtenerEvidenciaReservaCuponInterno',
        }
        missing = {
            operation_id
            for operation_id, operation in self.operations.items()
            if 'x-error-codes' not in operation
        }
        self.assertEqual(missing, excluded)


if __name__ == '__main__':
    unittest.main()

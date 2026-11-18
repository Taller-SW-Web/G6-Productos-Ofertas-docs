"""Static consistency checks for the non-canonical H5 documentation proposal."""

import json
import re
from pathlib import Path
import unittest

import jsonschema


ROOT = Path(__file__).resolve().parents[2]
PROPOSAL = ROOT / "contratos/http/PROPUESTA-OPERACIONES-CUPONES-H5.md"


def schema_from_heading(heading: str) -> dict:
    text = PROPOSAL.read_text(encoding="utf-8")
    match = re.search(
        rf"^### .*`{re.escape(heading)}`\s*$\s*```json\s*(.*?)\s*```",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise AssertionError(f"No se encontró el schema candidato {heading}")
    schema = json.loads(match.group(1))
    jsonschema.Draft202012Validator.check_schema(schema)
    return schema


def validator(name: str) -> jsonschema.Draft202012Validator:
    return jsonschema.Draft202012Validator(
        schema_from_heading(name), format_checker=jsonschema.FormatChecker()
    )


class TestServiceBusH5Documentation(unittest.TestCase):
    def test_reservation_reconciliation_and_commercial_sequence_are_explicit(self):
        adr = (ROOT / "arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md").read_text(
            encoding="utf-8"
        )
        proposal = PROPOSAL.read_text(encoding="utf-8")
        matrix = (ROOT / "integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md").read_text(
            encoding="utf-8"
        )
        migration = (ROOT / "integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md").read_text(
            encoding="utf-8"
        )
        for text in (adr, proposal, matrix, migration):
            self.assertRegex(text, r"periódic[oa]")
            self.assertIn("no está implementado ni aceptado por G5", text)
            self.assertIn("G6 no administra estados de pedido", text)
        for text in (adr, proposal, matrix, migration):
            self.assertIn("inventory.reservation.created", text)
            self.assertIn("resultado durable", text)
            self.assertIn("/inventario/reservas/{reservaId}/confirmar", text)
        for invariant in (
            "lease/claim durable",
            "reanudación tras caída",
            "backoff",
            "clave idempotente",
            "workers concurrentes",
            "no retroceder el estado",
        ):
            self.assertIn(invariant, adr)
        for text in (adr, proposal, matrix, migration):
            self.assertIn("`ACTIVA`", text)
            self.assertIn("`EXPIRADA` persistida", text)
            self.assertIn("HTTP", text)
        self.assertIn("no es prerrequisito de la propuesta HTTP", adr)
        self.assertIn("RabbitMQ H4 `inventory.reservation.created`", adr)
        self.assertIn("resultado durable `COMPLETED` de la operación que creó la reserva", adr)
        self.assertIn("`EXPIRADA` solo se excluye cuando G5 ya registró durablemente", adr)
        self.assertIn("Una lectura HTTP exitosa de Inventory solo aporta observación", adr)
        self.assertIn("no cierra el seguimiento", proposal)
        test_plan = (ROOT / "tests/contratos/PLAN-VERIFICACION-SERVICE-BUS-H5.md").read_text(
            encoding="utf-8"
        ).lower()
        self.assertIn("pasa de `activa` a `expirada`", test_plan)
        self.assertIn("antes del siguiente barrido g5", test_plan)
        self.assertIn("resultado http durable `completed`", test_plan)
        self.assertIn("solo entonces cierra el seguimiento", test_plan)
        sequence_section = proposal.split(
            "Para checkout de Marketplace con cupón", 1
        )[1].split("No se llama a `/confirmar`", 1)[0]
        sequence = (
            "1. Crear pedido conforme al flujo G5",
            "2. Consultar/validar que la reserva siga vigente",
            "3. Admitir consumo del cupón",
            "4. Procesar el pago",
            "5. Tras pago exitoso",
            "POST /api/v1/inventario/reservas/{reservaId}/confirmar",
        )
        positions = [sequence_section.index(token) for token in sequence]
        self.assertEqual(positions, sorted(positions))
        for text in (proposal, matrix, migration):
            self.assertIn("Chatbot", text)
            self.assertIn("reemplazo", text.lower())
            self.assertIn("despacho", text.lower())

    def test_promotions_http_queue_is_new_and_scoped_to_its_worker(self):
        topology = (ROOT / "contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md").read_text(
            encoding="utf-8"
        )
        adr = (ROOT / "arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("`g6.promotions.commands`", topology)
        self.assertIn("Adaptador HTTP", topology)
        self.assertIn("Consumidor exclusivo", topology)
        self.assertIn("Inbox", topology)
        self.assertIn("resultado", topology)
        self.assertIn("no son el inventario ni el límite máximo de colas de H5", topology)
        self.assertIn("`g6.promotions.commands`", adr)
        self.assertIn("Outbox", adr)

    def test_coupon_requests_preserve_business_identifiers(self):
        consume = validator("CouponConsumptionRequest")
        consume.validate(
            {
                "operation_id": "11111111-1111-4111-8111-111111111111",
                "order_id": "PED-opaque-01",
                "coupon_code": "SALE10",
                "channel_id": "MARKETPLACE",
                "effective_at": "2026-11-14T10:00:00Z",
                "reservation_id": "22222222-2222-4222-8222-222222222222",
                "commercial_snapshot_ref": "snapshot-order-01",
            }
        )
        invalid_consume = {
            "operation_id": "11111111-1111-4111-8111-111111111111",
            "order_id": "PED-opaque-01",
            "coupon_code": "SALE10",
            "channel_id": "MARKETPLACE",
            "effective_at": "2026-11-14T10:00:00Z",
            "commercial_snapshot_ref": "snapshot-order-01",
        }
        self.assertFalse(consume.is_valid(invalid_consume))

        restore = validator("CouponRestorationRequest")
        restore.validate(
            {
                "operation_id": "33333333-3333-4333-8333-333333333333",
                "order_id": "PED-opaque-01",
                "consumption_operation_id": "11111111-1111-4111-8111-111111111111",
                "cancellation_reason": "pedido_cancelado",
                "cancelled_at": "2026-11-14T10:01:00Z",
            }
        )
        self.assertFalse(
            restore.is_valid(
                {
                    "operation_id": "33333333-3333-4333-8333-333333333333",
                    "order_id": "PED-opaque-01",
                    "cancellation_reason": "pedido_cancelado",
                    "cancelled_at": "2026-11-14T10:01:00Z",
                }
            )
        )

    def test_operation_snapshot_encodes_terminal_and_pending_states(self):
        operation = validator("CouponOperationSnapshot")
        pending = {
            "operation_id": "11111111-1111-4111-8111-111111111111",
            "operation_type": "CONSUMIR_CUPON",
            "status": "ACCEPTED",
            "order_id": "PED-opaque-01",
            "accepted_at": "2026-11-14T10:00:00Z",
            "updated_at": "2026-11-14T10:00:00Z",
            "completed_at": None,
            "result": None,
        }
        operation.validate(pending)
        rejected = {
            **pending,
            "status": "REJECTED",
            "updated_at": "2026-11-14T10:00:02Z",
            "completed_at": "2026-11-14T10:00:02Z",
            "result": {
                "order_id": "PED-opaque-01",
                "result_code": "CUPON_NO_ELEGIBLE",
                "reservation_id": "22222222-2222-4222-8222-222222222222",
                "commercial_snapshot_ref": "snapshot-order-01",
                "coupon_code": "SALE10",
                "decided_at": "2026-11-14T10:00:02Z",
            },
        }
        operation.validate(rejected)
        invalid_rejected = {**rejected, "result": {"decided_at": "2026-11-14T10:00:02Z"}}
        self.assertFalse(operation.is_valid(invalid_rejected))
        restored = {
            **pending,
            "operation_type": "RESTAURAR_CUPON",
            "status": "COMPLETED",
            "updated_at": "2026-11-14T10:03:00Z",
            "completed_at": "2026-11-14T10:03:00Z",
            "result": {
                "order_id": "PED-opaque-01",
                "consumption_operation_id": "11111111-1111-4111-8111-111111111111",
                "restored": True,
                "outcome": "RESTORED",
                "completed_at": "2026-11-14T10:03:00Z",
            },
        }
        operation.validate(restored)

    def test_error_schema_uses_explicit_candidate_code(self):
        problem = validator("CouponApiProblem")
        problem.validate(
            {
                "type": "about:blank",
                "title": "Operación no encontrada",
                "status": 404,
                "code": "OPERACION_CUPON_NO_ENCONTRADA",
                "correlationId": "corr-123",
            }
        )
        text = PROPOSAL.read_text(encoding="utf-8")
        self.assertIn("está registrado en el catálogo de errores y sigue sujeto a homologación", text)

    def test_http_idempotency_and_replay_policy_are_explicit(self):
        text = PROPOSAL.read_text(encoding="utf-8")
        self.assertIn("debe contener exactamente el mismo UUID", text)
        self.assertIn("si es un replay del POST, `200`", text)
        self.assertIn("`409 IDEMPOTENCY_CONFLICT`", text)
        self.assertIn("`Retry-After: 2`", text)
        self.assertIn("repetir la misma solicitud y `Idempotency-Key`", text)
        self.assertIn("`cancelled_at` es el instante original", text)

    def test_reservation_response_keeps_persisted_and_effective_state_separate(self):
        response = validator("ReservationStatusSnapshot")
        response.validate(
            {
                "reservation_id": "22222222-2222-4222-8222-222222222222",
                "order_id": "PED-opaque-01",
                "estado_persistido": "ACTIVA",
                "expires_at": "2026-11-14T10:00:00Z",
                "observed_at": "2026-11-14T10:01:00Z",
                "vigencia_efectiva": "VENCIDA",
                "permite_pago": False,
                "permite_consumo_cupon": False,
            }
        )
        self.assertFalse(
            response.is_valid(
                {
                    "reservation_id": "22222222-2222-4222-8222-222222222222",
                    "order_id": "PED-opaque-01",
                    "estado_persistido": "RESERVADA",
                    "expires_at": "2026-11-14T10:00:00Z",
                    "observed_at": "2026-11-14T10:01:00Z",
                    "vigencia_efectiva": "VENCIDA",
                    "permite_pago": True,
                    "permite_consumo_cupon": True,
                }
            )
        )
        text = PROPOSAL.read_text(encoding="utf-8")
        for state in ("ACTIVA", "CONSUMIDA", "LIBERADA", "EXPIRADA"):
            self.assertIn(state, text)
        self.assertIn("ReservationExpirationService", text)
        self.assertIn("no se crea un worker de expiración paralelo", text)
        self.assertIn("/api/v1/inventario/reservas/{reservaId}/estado", text)

    def test_basic_ttl_and_long_outage_recovery_are_consistent(self):
        paths = [
            "arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md",
            "contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md",
            "arquitectura/operacion-service-bus-basic-h5.md",
            "arquitectura/COSTOS-LIMITES-AZURE-H5.md",
            "tests/contratos/PLAN-VERIFICACION-SERVICE-BUS-H5.md",
        ]
        for relative in paths:
            text = (ROOT / relative).read_text(encoding="utf-8")
            with self.subTest(document=relative):
                self.assertIn("DefaultMessageTimeToLive", text)
                self.assertIn("14 días", text)
        operations = (ROOT / "arquitectura/operacion-service-bus-basic-h5.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("reconciliar", operations.lower())
        self.assertIn("misma", operations)
        self.assertIn("idempotencia", operations.lower())


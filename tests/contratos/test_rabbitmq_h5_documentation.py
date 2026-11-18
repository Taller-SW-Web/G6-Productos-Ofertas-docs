"""Prevent operational RabbitMQ instructions from returning to H5 guidance."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
EXCEPTIONS = ROOT / "tests/contratos/rabbitmq-h4-excepciones.txt"
ACTIVE_DOCS = ["AGENTS.md", "README.md", "arquitectura/Arquitectura.md",
               "arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md",
               "arquitectura/operacion-service-bus-basic-h5.md",
               "contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md",
               "integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md"]
FORBIDDEN = re.compile(
    r"docker\s+compose\s+up[^\n]*rabbitmq|"
    r"RABBITMQ_URL\s*(?:=|:)|"
    r"(?:instalar|configurar|aprovisionar|crear|levantar)\s+(?:un\s+)?(?:nuevo\s+)?rabbitmq[^\n]*h5|"
    r"h5[^\n]{0,100}(?:amqplib|rabbitmq como broker|rabbitmq como infraestructura)",
    re.IGNORECASE)

class TestRabbitMqH5Documentation(unittest.TestCase):
    def test_h5_adoption_and_pending_states_are_unambiguous(self):
        adr = (ROOT / "arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md").read_text(encoding="utf-8")
        for state in ("ADOPTADA_G6", "PENDIENTE_APROVISIONAMIENTO_AZURE",
                      "PENDIENTE_IMPLEMENTACION", "PENDIENTE_HOMOLOGACION_G5",
                      "PENDIENTE_AUTORIZACION_G7"):
            self.assertIn(state, adr)
        for rel in ("AGENTS.md", "README.md", "arquitectura/Arquitectura.md"):
            text = (ROOT / rel).read_text(encoding="utf-8")
            self.assertIn("Azure Service Bus Basic", text)
            self.assertIn("H4", text)

    def test_active_h5_guidance_has_no_rabbitmq_setup_instructions(self):
        for rel in ACTIVE_DOCS:
            text = (ROOT / rel).read_text(encoding="utf-8")
            for line in text.splitlines():
                match = FORBIDDEN.search(line)
                if match and not re.search(r"LEGADO_H4|H4 legado|histórico H4", line, re.IGNORECASE):
                    self.fail(f"Instrucción RabbitMQ activa en {rel}: {match.group(0)}")

    def test_historical_exceptions_are_explicit_and_resolvable(self):
        rows = [line for line in EXCEPTIONS.read_text(encoding="utf-8").splitlines()
                if line.strip() and not line.startswith("#")]
        self.assertTrue(rows)
        for row in rows:
            rel, separator, reason = row.partition(" | ")
            self.assertTrue(separator and reason.strip(), f"Excepción sin justificación: {row}")
            self.assertTrue((ROOT / rel).is_file(), f"Ruta de excepción inexistente: {rel}")

    def test_contract_h4_and_transition_index_are_preserved_as_reference(self):
        index = (ROOT / "integraciones/INDICE-TRANSICION-MENSAJERIA-H4-H5.md").read_text(encoding="utf-8")
        asyncapi = (ROOT / "contratos/eventos/asyncapi.yaml").read_text(encoding="utf-8")
        self.assertIn("no autorizan implementación H5", index)
        self.assertIn("rabbitmq:", asyncapi)
        self.assertTrue((ROOT / "tests/contratos/test_asyncapi_oracle_topology.py").is_file())

if __name__ == "__main__":
    unittest.main()

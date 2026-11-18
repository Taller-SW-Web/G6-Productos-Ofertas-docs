"""Regresión de instrucciones RabbitMQ residuales en el corpus H5/H4."""
from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "integraciones/INDICE-TRANSICION-MENSAJERIA-H4-H5.md"
EXCEPTIONS = ROOT / "tests/contratos/rabbitmq-h4-excepciones.txt"
SCAN_ROOTS = ("arquitectura", "contratos", "integraciones", "requisitos",
              "datos", "ops", "tests", "ux", "swagger")
EXTENSIONS = {".md", ".yaml", ".yml", ".json", ".sh", ".ps1",
              ".js", ".mjs", ".py"}
TRANSPORT = re.compile(r"rabbit.?mq|amqplib|RABBITMQ_|\bamqp\b|amqps?://", re.I)
OPERATIONAL = re.compile(
    r"RABBITMQ_[A-Z0-9_]+|amqplib|amqps?://|docker\s+compose|"
    r"\b(?:5671|5672)\b|\b(?:ssh|tunnel|t[uú]nel)\b|\bdocker\b|exchange(?:s)?|"
    r"routing.?keys?|publisher confirms?|consumer ack|\b(?:ACK|NACK)\b|"
    r"basic\.(?:consume|ack|nack)|\bDLQ\b|dead.?letter|retries?|reintentos?|"
    r"publish(?:er|ed|ing)?|public(?:a|an|ar|ación|aciones)|consum(?:e|er|idor|ir|en)|"
    r"confirm(?:a|ar|ación|aciones)|(?:aprovisiona|configura|instala|crea|levanta|"
    r"conecta|subscribe|suscripc|settlement|outbox|inbox)\b|\bH5\b|Hito 5", re.I)

def is_operational_line(line: str) -> bool:
    return bool(TRANSPORT.search(line) and OPERATIONAL.search(line))

def scan_paths() -> set[str]:
    paths = {"AGENTS.md", "README.md"}
    for folder in SCAN_ROOTS:
        for path in (ROOT / folder).rglob("*"):
            if (path.is_file() and path.suffix.lower() in EXTENSIONS
                    and not {"node_modules", "dist", "reports", "test-results", "playwright-report"}.intersection(path.parts):
                relative = path.relative_to(ROOT).as_posix()
                if relative != "tests/contratos/test_rabbitmq_h5_documentation.py":
                    paths.add(relative)
    return paths

def load_exceptions() -> dict[tuple[str, str], str]:
    result = {}
    for number, raw in enumerate(EXCEPTIONS.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.startswith("#"):
            continue
        entry = json.loads(raw)
        path = entry["path"]
        fragment = entry["fragment"]
        reason = entry["reason"]
        if not fragment:
            raise AssertionError(f"Excepción vacía en línea {number}: {entry}")
        if not reason.strip() or not (ROOT / path).is_file():
            raise AssertionError(f"Excepción incompleta/no resoluble en línea {number}: {entry}")
        result[(path, fragment)] = reason
    return result

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

    def test_scans_inventory_and_all_normative_operational_documentation(self):
        exceptions = load_exceptions()
        paths = scan_paths()
        inventory = INDEX.read_text(encoding="utf-8")
        inventory_paths = set(re.findall(r"^- `([^`]+)`$", inventory, re.M))
        self.assertEqual(len(inventory_paths), 75, "El inventario base auditado debe conservar sus 75 rutas")
        scanner_source = "tests/contratos/test_rabbitmq_h5_documentation.py"
        # The scanner implementation is inventoried but its literal negative fixtures are tested separately below.
        scanned_inventory = inventory_paths - {scanner_source}
        self.assertTrue(scanned_inventory <= paths, "El escáner dejó fuera una ruta del inventario base")
        violations = []
        seen_transport = set()
        for relative in sorted(paths):
            path = ROOT / relative
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (UnicodeDecodeError, OSError):
                continue
            for number, line in enumerate(lines, 1):
                if not TRANSPORT.search(line):
                    continue
                seen_transport.add(relative)
                if is_operational_line(line):
                    fragment = line.strip()
                    if (relative, fragment) not in exceptions:
                        violations.append(f"{relative}:{number}: {fragment}")
        self.assertEqual(violations, [], "Instrucciones RabbitMQ operativas sin excepción literal: " + "\n".join(violations))

    def test_exceptions_are_exact_fragments_not_file_or_line_bypasses(self):
        exceptions = load_exceptions()
        self.assertGreater(len(exceptions), 0)
        for (relative, fragment), reason in exceptions.items():
            source_lines = {line.strip() for line in (ROOT / relative).read_text(encoding="utf-8").splitlines()}
            self.assertIn(fragment, source_lines,
                          f"La excepción no coincide con una línea literal exacta: {relative}")
            self.assertTrue(any(token in reason.lower() for token in ("h4", "histór", "ux")),
                            f"Excepción sin justificación histórica: {relative}: {reason}")
        # An H4 label never makes a contradictory instruction safe by itself.
        contradictory = "LEGADO_H4; para H5 instalar RabbitMQ y definir RABBITMQ_URL=amqp://broker"
        self.assertTrue(is_operational_line(contradictory))
        self.assertNotIn(("README.md", contradictory), exceptions)
        allowed_fragment = "RabbitMQ H4; el ACK manual se conserva como antecedente"
        self.assertTrue(is_operational_line(allowed_fragment))
        self.assertNotIn(("README.md", allowed_fragment + "; en H5 instalar RabbitMQ"), exceptions)

    def test_real_contradictory_examples_are_detected(self):
        for text in (
            "Para H5, instalar RabbitMQ y conectar G6 mediante amqplib.",
            "docker compose up -d rabbitmq para implementar mensajería H5",
            "RABBITMQ_URL=amqps://host:5671 es la variable H5 obligatoria",
        ):
            with self.subTest(text=text):
                self.assertTrue(is_operational_line(text))

    def test_historical_h4_and_contract_invariants_remain_referenced(self):
        index = INDEX.read_text(encoding="utf-8")
        asyncapi = (ROOT / "contratos/eventos/asyncapi.yaml").read_text(encoding="utf-8")
        self.assertIn("no autorizan implementación H5", index)
        self.assertIn("rabbitmq:", asyncapi)
        self.assertTrue((ROOT / "tests/contratos/test_asyncapi_oracle_topology.py").is_file())

if __name__ == "__main__":
    unittest.main()

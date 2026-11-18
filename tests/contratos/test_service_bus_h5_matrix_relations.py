"""Verify that the H5 execution matrix covers exact AsyncAPI consumers."""

import csv
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MATRIX = ROOT / "integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md"
TOPOLOGY = ROOT / "contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md"
INVENTORY = ROOT / "contratos/eventos/inventario-40-mensajes-h5.csv"
WORKFLOW = ROOT / ".github/workflows/swagger-docs.yml"
CONTEXTS = {
    "Taxonomy": "taxonomy-svc",
    "Catalog": "catalog-svc",
    "Pricing": "pricing-svc",
    "Price Audit": "price-audit-svc",
    "Promotions": "promotions-svc",
    "Combos": "combos-svc",
    "Inventory": "inventory-svc",
    "Bulk": "bulk-svc",
}


def topology_relations():
    text = TOPOLOGY.read_text(encoding="utf-8")
    section = text.split("## Relaciones internas heredadas de H4", 1)[1].split(
        "## Cola nueva para operaciones HTTP de Promotions", 1
    )[0]
    relations = {}
    for line in section.splitlines():
        if not line.startswith("|") or "g6." not in line:
            continue
        columns = [column.strip() for column in line.strip("|").split("|")]
        destination, producer, queue = columns[:3]
        queue = queue.strip(chr(96))
        relations[(CONTEXTS[producer], CONTEXTS[destination])] = queue
    return relations


def inventory_messages():
    messages = {}
    with INVENTORY.open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            if not row["h5_classification"].startswith("INTERNO"):
                continue
            producer = row["producer_h4"]
            for consumer in row["consumers_h4"].split(";"):
                consumer = consumer.strip()
                if consumer in {"api-gateway/bff", "modulo-ventas"}:
                    continue
                messages.setdefault((producer, consumer), set()).add(
                    row["message_name"]
                )
        return messages


def matrix_relations():
    text = MATRIX.read_text(encoding="utf-8")
    section = text.split("## Relaciones internas: 18 registros independientes", 1)[
        1
    ].split("## Flujo H5 nuevo Promotions", 1)[0]
    rows = {}
    for line in section.splitlines():
        if not re.match(r"\|\s*R\d{2}\s*\|", line):
            continue
        columns = [column.strip() for column in line.strip("|").split("|")]
        relation_id, owners, raw_messages, queue = columns[:4]
        producer, consumer = [
            CONTEXTS[owner.strip()] for owner in owners.split("→")
        ]
        key = (producer, consumer)
        if key in rows:
            raise AssertionError(f"Relación duplicada: {key}")
        rows[key] = {
            "id": relation_id,
            "messages": {message.strip() for message in raw_messages.split(";")},
            "queue": queue,
            "details": columns[4:],
        }
    return rows


class TestServiceBusH5MatrixRelations(unittest.TestCase):
    def test_exactly_18_topology_relations_and_consumer_messages(self):
        expected_queues = topology_relations()
        expected_messages = inventory_messages()
        actual = matrix_relations()

        self.assertEqual(len(expected_queues), 18)
        self.assertEqual(set(expected_queues), set(expected_messages))
        self.assertEqual(set(actual), set(expected_queues))
        self.assertEqual(
            {row["id"] for row in actual.values()},
            {f"R{index:02d}" for index in range(1, 19)},
        )

        for relation, queue in expected_queues.items():
            with self.subTest(relation=relation):
                self.assertEqual(actual[relation]["queue"], queue)
                self.assertEqual(actual[relation]["messages"], expected_messages[relation])
                self.assertEqual(len(actual[relation]["details"]), 4)
                self.assertTrue(all(actual[relation]["details"]))

    def test_normative_document_changes_trigger_swagger_contract_workflow(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        pull_request = re.search(
            r"(?ms)^  pull_request:\s*\n(.*?)(?=^  workflow_dispatch:)",
            text,
        )
        self.assertIsNotNone(pull_request)
        paths = re.search(r"(?ms)^    paths:\s*\n((?:      - .*\n)+)", pull_request.group(1))
        self.assertIsNotNone(paths)
        configured = set(re.findall(r"- '([^']+)'", paths.group(1)))
        self.assertTrue({"AGENTS.md", "README.md", "integraciones/**"} <= configured)
        self.assertIn("tests/contratos/**", configured)


if __name__ == "__main__":
    unittest.main()

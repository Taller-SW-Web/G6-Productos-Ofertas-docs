import hashlib
import json
from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_FILE = ROOT / "contratos/eventos/asyncapi.yaml"
FIXTURE_FILE = ROOT / "tests/contratos/fixtures/asyncapi-0.6.0-rc.2-invariants.json"
EXPECTED_EXCHANGES = {
    "po.comandos.x": "topic",
    "po.eventos.x": "topic",
    "po.resultados.x": "topic",
    "po.sin-ruta.x": "fanout",
}
EXPECTED_QUEUES = {
    "po.catalogo.q", "po.pasarela.q", "po.promociones.q", "po.combos.q",
    "po.inventario.q", "po.precios.q", "po.auditoria-precios.q", "po.ventas.q",
    "po.taxonomia.q", "po.masivos.q",
}
EXPECTED_PHYSICAL_QUEUES = EXPECTED_QUEUES | {"po.sin-ruta.q"}
LEGACY_BASE_NAMES = {
    "po.commands.x", "po.events.x", "po.results.x", "po.unrouted.x",
    "po.catalog.q", "po.gateway.q", "po.promotions.q", "po.inventory.q",
    "po.pricing.q", "po.price-audit.q", "po.sales.q", "po.taxonomy.q",
    "po.bulk.q", "po.unrouted.q",
}


def walk_refs(value):
    if isinstance(value, dict):
        if isinstance(value.get("$ref"), str):
            yield value["$ref"]
        for child in value.values():
            yield from walk_refs(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_refs(child)


def without_keys(value, keys):
    if isinstance(value, dict):
        return {k: without_keys(v, keys) for k, v in value.items() if k not in keys}
    if isinstance(value, list):
        return [without_keys(v, keys) for v in value]
    return value


def canonical_hash(value):
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def logical_snapshot(document):
    channels = without_keys(document["channels"], {"x-exchange", "x-binding-status"})
    messages = without_keys(document["components"]["messages"], {"x-exchange"})
    schemas = document["components"]["schemas"]
    operations = document["operations"]
    producers_consumers = {
        name: {"producer": msg.get("x-producer"), "consumers": msg.get("x-consumers", [])}
        for name, msg in sorted(document["components"]["messages"].items())
    }
    routing_keys = {
        name: channel["x-routing-key"]
        for name, channel in sorted(document["channels"].items())
    }
    return {
        "counts": {
            "channels": len(channels),
            "messages": len(messages),
            "operations": len(operations),
        },
        "sha256": {
            "channels": canonical_hash(channels),
            "messages": canonical_hash(messages),
            "payloads_and_message_metadata": canonical_hash(messages),
            "schemas": canonical_hash(schemas),
            "operations": canonical_hash(operations),
            "producers_and_consumers": canonical_hash(producers_consumers),
            "commercial_routing_keys": canonical_hash(routing_keys),
        },
    }


class AsyncApiOracleTopologyRegression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.current = yaml.safe_load(CONTRACT_FILE.read_text(encoding="utf-8"))
        cls.fixture = json.loads(FIXTURE_FILE.read_text(encoding="utf-8"))

    def test_asyncapi_version_and_local_references(self):
        self.assertEqual(self.current["asyncapi"], "3.0.0")
        self.assertEqual(self.current["info"]["version"], "0.6.0-rc.3")
        for ref in walk_refs(self.current):
            if not ref.startswith("#/"):
                continue
            node = self.current
            for token in ref[2:].split("/"):
                token = token.replace("~1", "/").replace("~0", "~")
                self.assertIn(token, node, ref)
                node = node[token]

    def test_observed_base_exchanges_and_queues(self):
        topology = self.current["x-rabbitmq-topology"]
        self.assertEqual(topology["vhost"], "g6-productos-ofertas")
        self.assertEqual(self.current["servers"]["rabbitmq"]["x-vhost"], "g6-productos-ofertas")
        exchanges = topology["exchanges"]
        for name, kind in EXPECTED_EXCHANGES.items():
            self.assertEqual(exchanges[name]["type"], kind)
            self.assertIs(exchanges[name]["durable"], True)
            self.assertEqual(exchanges[name]["status"], "base-observed-not-homologated")
        observed_queues = {
            name for name, value in topology["queues"].items()
            if value.get("status") == "base-observed-not-homologated"
        }
        self.assertEqual(observed_queues, EXPECTED_PHYSICAL_QUEUES)
        self.assertEqual(
            {name for name in observed_queues if name != "po.sin-ruta.q"}, EXPECTED_QUEUES
        )
        for name in observed_queues:
            self.assertEqual(topology["queues"][name]["type"], "quorum", name)
            self.assertIs(topology["queues"][name]["durable"], True, name)
        unrouted = topology["queues"]["po.sin-ruta.q"]
        self.assertEqual(unrouted["consumer"], "platform/operations")
        self.assertIn("no es una cola de negocio", unrouted["purpose"])

    def test_channel_message_exchange_and_binding_references(self):
        topology = self.current["x-rabbitmq-topology"]
        exchanges = topology["exchanges"]
        base_exchanges = set(EXPECTED_EXCHANGES)
        for channel in self.current["channels"].values():
            self.assertIn(channel["x-exchange"], base_exchanges)
            self.assertEqual(channel["x-binding-status"], "pending-verification")
        for message in self.current["components"]["messages"].values():
            self.assertIn(message["x-exchange"], base_exchanges)
        for queue_name, queue in topology["queues"].items():
            bindings = list(queue.get("bindings", []))
            if queue.get("binding"):
                bindings.append(queue["binding"])
            for binding in bindings:
                self.assertIn(binding["exchange"], exchanges, queue_name)
        for name, kind in (("po.retry.x", "direct"), ("po.dlx.x", "direct")):
            self.assertEqual(exchanges[name]["type"], kind)
            self.assertEqual(exchanges[name]["status"], "candidate-not-approved")
            self.assertIs(exchanges[name]["provisioned"], False)
        observation = topology["observation"]
        self.assertEqual(observation["observed_binding_count"], 57)
        self.assertEqual(observation["exact_binding_mapping_status"], "PENDIENTE_VERIFICACION")

    def test_contractual_bindings_total_56_main_plus_one_operational(self):
        topology = self.current["x-rabbitmq-topology"]
        queues = topology["queues"]
        main_bindings = sum(
            len(queues[name].get("bindings", [])) for name in EXPECTED_QUEUES
        )
        operational_binding = queues["po.sin-ruta.q"]["binding"]
        self.assertEqual(
            operational_binding,
            {"exchange": "po.sin-ruta.x", "routing_key": "#"},
        )
        self.assertEqual(main_bindings, 56)
        self.assertEqual(main_bindings + 1, 57)

    def test_old_english_names_are_absent_from_active_base_topology(self):
        topology = self.current["x-rabbitmq-topology"]
        exchanges = set(topology["exchanges"])
        self.assertTrue(LEGACY_BASE_NAMES.isdisjoint(exchanges))
        actual_physical_queues = {
            name for name, value in topology["queues"].items()
            if value.get("status") == "base-observed-not-homologated"
        }
        self.assertTrue(LEGACY_BASE_NAMES.isdisjoint(actual_physical_queues))
        for name in actual_physical_queues:
            for binding in topology["queues"][name].get("bindings", []):
                self.assertTrue(LEGACY_BASE_NAMES.isdisjoint({binding["exchange"]}))

    def test_retry_dlx_is_blocked_not_provisioned(self):
        self.assertEqual(self.current["x-retry-dlx-status"], "blocked-not-provisioned")
        self.assertEqual(self.current["x-external-homologation-status"], "pending")
        self.assertEqual(self.current["x-physical-topology-status"], "base-observed-not-homologated")
        topology = self.current["x-rabbitmq-topology"]
        for name, queue in topology["queues"].items():
            if name.endswith((".retry", ".dlq")):
                self.assertEqual(queue["status"], "candidate-not-provisioned", name)
        policy = self.current["x-rabbitmq-policy"]
        self.assertEqual(policy["retry_dlx_status"], "blocked-not-provisioned")
        self.assertEqual(policy["retry_dlx_approval"], "not-approved")

    def test_logical_invariants_match_immutable_rc2_fixture(self):
        snapshot = logical_snapshot(self.current)
        self.assertEqual(snapshot["counts"], self.fixture["counts"])
        self.assertEqual(snapshot["counts"], {"channels": 40, "messages": 40, "operations": 80})
        self.assertEqual(snapshot["sha256"], self.fixture["sha256"])

    def test_nomenclature_mappings_are_unique(self):
        self.assertEqual(len(EXPECTED_EXCHANGES), 4)
        self.assertEqual(len(EXPECTED_QUEUES), 10)
        self.assertEqual(len(EXPECTED_PHYSICAL_QUEUES), 11)


if __name__ == "__main__":
    unittest.main()

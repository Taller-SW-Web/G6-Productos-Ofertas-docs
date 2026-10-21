from copy import deepcopy
from pathlib import Path
import subprocess
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[2]
BASE_SHA = "c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b"
BASE_FILE = "contratos/eventos/asyncapi.yaml"
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


class AsyncApiOracleTopologyRegression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.current = yaml.safe_load((ROOT / BASE_FILE).read_text(encoding="utf-8"))
        raw = subprocess.check_output(
            ["git", "show", f"{BASE_SHA}:{BASE_FILE}"], cwd=ROOT, text=True, encoding="utf-8"
        )
        cls.baseline = yaml.safe_load(raw)

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
        self.assertEqual(topology["queues"]["po.sin-ruta.q"]["consumer"], "platform/operations")
        self.assertIn("no es una cola de negocio", topology["queues"]["po.sin-ruta.q"]["purpose"])

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
            for binding in queue.get("bindings", []):
                self.assertIn(binding["exchange"], exchanges, queue_name)
        for name, kind in (("po.retry.x", "direct"), ("po.dlx.x", "direct")):
            self.assertEqual(exchanges[name]["type"], kind)
            self.assertEqual(exchanges[name]["status"], "candidate-not-approved")
            self.assertIs(exchanges[name]["provisioned"], False)
        self.assertEqual(topology["observation"]["observed_binding_count"], 57)
        self.assertEqual(topology["observation"]["exact_binding_mapping_status"], "PENDIENTE_VERIFICACION")

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

    def test_logical_contract_messages_routes_payloads_and_operations_are_unchanged(self):
        baseline, current = self.baseline, self.current
        self.assertEqual(set(current["channels"]), set(baseline["channels"]))
        self.assertEqual(len(current["channels"]), 40)
        for name in baseline["channels"]:
            before, after = baseline["channels"][name], current["channels"][name]
            self.assertEqual(after["address"], before["address"], name)
            self.assertEqual(after["messages"], before["messages"], name)
            self.assertEqual(after["x-routing-key"], before["x-routing-key"], name)
        self.assertEqual(
            without_keys(current["channels"], {"x-exchange", "x-binding-status"}),
            without_keys(baseline["channels"], {"x-exchange", "x-binding-status"}),
        )
        self.assertEqual(set(current["components"]["messages"]), set(baseline["components"]["messages"]))
        self.assertEqual(len(current["components"]["messages"]), 40)
        for name, before in baseline["components"]["messages"].items():
            after = current["components"]["messages"][name]
            self.assertEqual(after["payload"], before["payload"], name)
            self.assertEqual(after["x-routing-key"], before["x-routing-key"], name)
            self.assertEqual(
                without_keys(after, {"x-exchange"}), without_keys(before, {"x-exchange"}), name
            )
        self.assertEqual(current["components"]["schemas"], baseline["components"]["schemas"])
        self.assertEqual(current["operations"], baseline["operations"])

    def test_nomenclature_mappings_are_unique(self):
        self.assertEqual(len(EXPECTED_EXCHANGES), 4)
        self.assertEqual(len(EXPECTED_QUEUES), 10)
        self.assertEqual(len(EXPECTED_PHYSICAL_QUEUES), 11)


if __name__ == "__main__":
    unittest.main()

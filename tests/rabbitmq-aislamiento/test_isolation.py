"""Isolated executable checks for candidate RabbitMQ isolation A (not contract adoption)."""
import os
import json
import re
import time
import uuid
import unittest

import pika
import requests


HOST = os.environ["AMQP_HOST"]
PORT = int(os.environ["AMQP_PORT"])
VHOST = os.environ["AMQP_VHOST"]
BOOTSTRAP = (os.environ["BOOTSTRAP_USER"], os.environ["BOOTSTRAP_PASSWORD"])
RUNTIMES = {
    "inventory": {
        "user": os.environ["INVENTORY_USER"],
        "password": os.environ["INVENTORY_PASSWORD"],
        "main": "po.inventory.q",
        "retry": "po.inventory.q.retry",
        "dlq": "po.inventory.q.dlq",
    },
    "catalog": {
        "user": os.environ["CATALOG_USER"],
        "password": os.environ["CATALOG_PASSWORD"],
        "main": "po.catalog.q",
        "retry": "po.catalog.q.retry",
        "dlq": "po.catalog.q.dlq",
    },
}
RETRY_EXCHANGE = "po.retry.x"
DLX = "po.dlx.x"


class RecoveryInconclusive(AssertionError):
    """A recovery gate precondition or observation could not be established."""


def confirmed_publish(channel, exchange, routing_key, body):
    channel.confirm_delivery()
    return channel.basic_publish(
        exchange=exchange,
        routing_key=routing_key,
        body=body,
        mandatory=True,
    )


def connection(user, password):
    credentials = pika.PlainCredentials(user, password)
    params = pika.ConnectionParameters(
        host=HOST,
        port=PORT,
        virtual_host=VHOST,
        credentials=credentials,
        # The suite intentionally waits through 30s TTLs while polling; RabbitMQ
        # heartbeats cannot be serviced during a blocking call on these test clients.
        heartbeat=0,
        blocked_connection_timeout=15,
        connection_attempts=20,
        retry_delay=1,
        socket_timeout=5,
    )
    return pika.BlockingConnection(params)


def get_one(channel, queue, timeout=0):
    deadline = time.monotonic() + timeout
    while True:
        method, properties, body = channel.basic_get(queue=queue, auto_ack=False)
        if method:
            return method, properties, body
        if time.monotonic() >= deadline:
            return None
        time.sleep(0.25)


def queue_snapshot(queue):
    response = requests.get(
        f"http://{HOST}:15672/api/queues/{VHOST}/{queue}",
        auth=BOOTSTRAP,
        params={"disable_stats": "false"},
        timeout=5,
    )
    if response.status_code != 200:
        raise AssertionError(f"queue diagnostics unavailable for {queue}: {response.status_code}")
    data = response.json()
    required_fields = {
        "type", "policy", "operator_policy", "effective_policy_definition", "arguments", "messages"
    }
    if not required_fields.issubset(data) or data.get("policy") is None or data.get("messages") is None:
        # RabbitMQ 4.2 can return reduced per-queue metrics. The vhost listing
        # exposes the detailed queue view without changing queue state.
        listing = requests.get(
            f"http://{HOST}:15672/api/queues/{VHOST}",
            auth=BOOTSTRAP,
            params={"disable_stats": "false"},
            timeout=5,
        )
        if listing.status_code == 200:
            data = next((item for item in listing.json() if item.get("name") == queue), data)
    snapshot = {
        key: data.get(key)
        for key in (
            "name",
            "type",
            "policy",
            "operator_policy",
            "effective_policy_definition",
            "arguments",
            "messages",
            "messages_ready",
            "messages_unacknowledged",
        )
    }
    snapshot["_api_fields"] = sorted(required_fields.intersection(data))
    return snapshot


def effective_policy(queue, expected_policy, expected_definition):
    observed = queue_snapshot(queue)
    if observed["type"] != "quorum":
        raise RecoveryInconclusive(f"INCONCLUSO: {queue} effective type is not quorum: {observed}")
    # RabbitMQ 4.2.9's queue listing may omit the assigned policy name while
    # still exposing the effective definition. Validate the matching policy,
    # its priority and the queue's effective definition below; reject a
    # conflicting assigned name when the API does expose one.
    if observed["policy"] is not None and observed["policy"] != expected_policy:
        raise RecoveryInconclusive(
            f"INCONCLUSO: {queue} has assigned policy {observed['policy']!r}, expected {expected_policy!r}"
        )
    if not isinstance(observed["arguments"], dict):
        raise RecoveryInconclusive(f"INCONCLUSO: {queue} queue arguments are not exposed by the API")

    response = requests.get(f"http://{HOST}:15672/api/policies/{VHOST}", auth=BOOTSTRAP, timeout=5)
    if response.status_code != 200:
        raise RecoveryInconclusive(f"INCONCLUSO: policies could not be read ({response.status_code})")
    matching = [item for item in response.json() if item.get("name") == expected_policy]
    if len(matching) != 1:
        raise RecoveryInconclusive(f"INCONCLUSO: expected exactly one {expected_policy} policy")
    policy = matching[0]
    try:
        expected_matches = re.fullmatch(policy.get("pattern", "(?!)"), queue)
    except re.error as error:
        raise RecoveryInconclusive(f"INCONCLUSO: invalid {expected_policy} pattern returned by broker: {error}") from error
    if policy.get("apply-to") != "quorum_queues" or not expected_matches:
        raise RecoveryInconclusive(f"INCONCLUSO: {expected_policy} does not target {queue} as a quorum queue")

    try:
        matching_policies = [
            item for item in response.json()
            if item.get("apply-to") in ("all", "queues", "quorum_queues")
            and re.fullmatch(item.get("pattern", "(?!)"), queue)
        ]
    except re.error as error:
        raise RecoveryInconclusive(f"INCONCLUSO: invalid policy pattern returned by broker: {error}") from error
    highest_priority = max((item.get("priority", 0) for item in matching_policies), default=None)
    highest_policies = [item for item in matching_policies if item.get("priority", 0) == highest_priority]
    if len(highest_policies) != 1 or highest_policies[0].get("name") != expected_policy:
        raise RecoveryInconclusive(
            f"INCONCLUSO: matching queue policies have an ambiguous or different highest priority: {matching_policies}"
        )

    actual = policy.get("definition") or {}
    effective = observed["effective_policy_definition"]
    arguments = observed["arguments"]
    effective_deadline = time.monotonic() + 20
    while not isinstance(effective, dict) or any(
        effective.get(key) != value for key, value in expected_definition.items()
    ):
        if time.monotonic() >= effective_deadline:
            break
        # Management statistics and resolved queue policy fields can appear
        # after the initial API response. Poll at the documented development
        # monitoring interval and keep missing/zero values as observations.
        time.sleep(min(5, max(0, effective_deadline - time.monotonic())))
        observed = queue_snapshot(queue)
        effective = observed["effective_policy_definition"]
        arguments = observed["arguments"]
    if observed["policy"] is not None and observed["policy"] != expected_policy:
        raise RecoveryInconclusive(
            f"INCONCLUSO: {queue} has assigned policy {observed['policy']!r}, expected {expected_policy!r}"
        )
    if not isinstance(effective, dict):
        raise RecoveryInconclusive(f"INCONCLUSO: {queue} has no effective policy definition after bounded polling: {observed}")
    for key, value in expected_definition.items():
        if actual.get(key) != value:
            raise RecoveryInconclusive(
                f"INCONCLUSO: {queue} effective policy key {key!r} is {actual.get(key)!r}, expected {value!r}"
            )
        if effective.get(key) != value:
            raise RecoveryInconclusive(
                f"INCONCLUSO: {queue} resolved policy key {key!r} is {effective.get(key)!r}, expected {value!r}"
            )
        argument_key = f"x-{key}"
        if argument_key in arguments and arguments[argument_key] != value:
            raise RecoveryInconclusive(
                f"INCONCLUSO: {queue} queue argument {argument_key!r}={arguments[argument_key]!r} "
                f"can alter the expected policy value {value!r}"
            )

    operator_policy_name = observed["operator_policy"]
    if operator_policy_name is not None:
        operator_response = requests.get(
            f"http://{HOST}:15672/api/operator-policies/{VHOST}", auth=BOOTSTRAP, timeout=5
        )
        if operator_response.status_code != 200:
            raise RecoveryInconclusive(
                f"INCONCLUSO: operator policies could not be read ({operator_response.status_code})"
            )
        operator_policies = [item for item in operator_response.json() if item.get("name") == operator_policy_name]
        if len(operator_policies) != 1:
            raise RecoveryInconclusive(
                f"INCONCLUSO: assigned operator policy {operator_policy_name!r} has no unique definition"
            )
        operator = operator_policies[0]
        try:
            matching_operator_policies = [
                item for item in operator_response.json()
                if item.get("apply-to") in ("all", "queues", "quorum_queues")
                and re.fullmatch(item.get("pattern", "(?!)"), queue)
            ]
        except re.error as error:
            raise RecoveryInconclusive(f"INCONCLUSO: invalid operator-policy pattern returned by broker: {error}") from error
        highest_operator_priority = max(
            (item.get("priority", 0) for item in matching_operator_policies), default=None
        )
        highest_operator_policies = [
            item for item in matching_operator_policies if item.get("priority", 0) == highest_operator_priority
        ]
        if (
            operator.get("apply-to") not in ("all", "queues", "quorum_queues")
            or not re.fullmatch(operator.get("pattern", "(?!)"), queue)
            or len(highest_operator_policies) != 1
            or highest_operator_policies[0].get("name") != operator_policy_name
        ):
            raise RecoveryInconclusive(
                f"INCONCLUSO: assigned operator policy {operator_policy_name!r} does not match {queue}"
            )
        operator_definition = operator.get("definition") or {}
        for key, value in expected_definition.items():
            if key in operator_definition and effective.get(key) != value:
                raise RecoveryInconclusive(
                    f"INCONCLUSO: operator policy {operator_policy_name!r} changes effective {key!r} "
                    f"to {effective.get(key)!r}, expected {value!r}"
                )

    observed["matched_policy_definition"] = actual
    return observed


def ready_count(channel, queue):
    return channel.queue_declare(queue=queue, passive=True).method.message_count


def publish_retry(runtime, headers):
    with connection(runtime["user"], runtime["password"]) as conn:
        channel = conn.channel()
        channel.confirm_delivery()
        props = pika.BasicProperties(
            message_id="isolation-message-001",
            correlation_id="isolation-correlation-001",
            headers=headers,
            delivery_mode=2,
            content_type="application/json",
        )
        accepted = channel.basic_publish(
            exchange=RETRY_EXCHANGE,
            routing_key=runtime["main"],
            body=b'{"kind":"retry-test"}',
            properties=props,
            mandatory=True,
        )
        if accepted is False:
            raise AssertionError("publisher confirm rejected the routed retry message")


class RabbitMQIsolation(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.admin_connection = connection(*BOOTSTRAP)
        cls.admin = cls.admin_connection.channel()
        policies = {
            "main-inventory-dlx": (
                r"^po\.inventory\.q$",
                {"dead-letter-exchange": "po.dlx.x", "dead-letter-routing-key": "po.inventory.q"},
            ),
            "retry-inventory-dlx": (
                r"^po\.inventory\.q\.retry$",
                {"dead-letter-exchange": "", "dead-letter-routing-key": "po.inventory.q", "message-ttl": 30000},
            ),
            "main-catalog-dlx": (
                r"^po\.catalog\.q$",
                {"dead-letter-exchange": "po.dlx.x", "dead-letter-routing-key": "po.catalog.q"},
            ),
            "retry-catalog-dlx": (
                r"^po\.catalog\.q\.retry$",
                {"dead-letter-exchange": "", "dead-letter-routing-key": "po.catalog.q", "message-ttl": 30000},
            ),
        }
        for name, (pattern, definition) in policies.items():
            definition.update({"dead-letter-strategy": "at-least-once", "overflow": "reject-publish"})
            policy_response = requests.put(
                f"http://{HOST}:15672/api/policies/{VHOST}/{name}",
                auth=BOOTSTRAP,
                json={"pattern": pattern, "definition": definition, "priority": 7, "apply-to": "quorum_queues"},
                timeout=5,
            )
            if policy_response.status_code not in (201, 204):
                raise AssertionError(f"could not apply test policy {name}: {policy_response.status_code} {policy_response.text[:500]}")

    @classmethod
    def tearDownClass(cls):
        if cls.admin_connection and cls.admin_connection.is_open:
            cls.admin_connection.close()

    def setUp(self):
        if os.environ.get("RABBITMQ_TEST_PROFILE", "essential") == "recovery":
            # Each focused recovery experiment has a fresh disposable broker.
            # Do not purge any queue in this evidence-sensitive scenario.
            return
        for runtime in RUNTIMES.values():
            for queue in (runtime["main"], runtime["retry"], runtime["dlq"]):
                self.admin.queue_purge(queue=queue)

    def test_smoke_01_inventory_and_catalog_can_publish_only_their_own_retry_route(self):
        for runtime in RUNTIMES.values():
            publish_retry(runtime, {"x-retry-count": 1})
            message = get_one(self.admin, runtime["retry"])
            self.assertIsNotNone(message)
            self.assertEqual(message[1].headers["x-retry-count"], 1)
            self.admin.basic_ack(message[0].delivery_tag)
            self.assertIsNone(get_one(self.admin, runtime["main"]))

    def test_smoke_02_exact_anchored_topic_permissions_reject_cross_and_near_match(self):
        inventory = RUNTIMES["inventory"]
        for routing_key in ("po.catalog.q", "po.inventoryXq"):
            with self.subTest(routing_key=routing_key):
                with connection(inventory["user"], inventory["password"]) as conn:
                    channel = conn.channel()
                    channel.confirm_delivery()
                    with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                        channel.basic_publish(
                            exchange=RETRY_EXCHANGE,
                            routing_key=routing_key,
                            body=b"denied",
                            mandatory=True,
                        )
                    self.assertEqual(error.exception.reply_code, 403)

    def test_smoke_03_catalog_cannot_consume_inventory_queue(self):
        catalog = RUNTIMES["catalog"]
        with connection(catalog["user"], catalog["password"]) as conn:
            with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                conn.channel().basic_get(queue=RUNTIMES["inventory"]["main"])
            self.assertEqual(error.exception.reply_code, 403)

    def test_smoke_04_runtime_cannot_declare_bind_delete_or_manage_policy(self):
        inventory = RUNTIMES["inventory"]
        operations = (
            lambda ch: ch.exchange_declare(exchange=RETRY_EXCHANGE, exchange_type="topic", durable=True),
            lambda ch: ch.queue_declare(queue=inventory["main"], durable=True, arguments={"x-queue-type": "quorum"}),
            lambda ch: ch.queue_bind(queue=inventory["main"], exchange=RETRY_EXCHANGE, routing_key=inventory["main"]),
            lambda ch: ch.queue_delete(queue=inventory["main"]),
        )
        for operation in operations:
            with self.subTest(operation=operation):
                with connection(inventory["user"], inventory["password"]) as conn:
                    with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                        operation(conn.channel())
                    self.assertEqual(error.exception.reply_code, 403)

        response = requests.put(
            f"http://{HOST}:15672/api/policies/{VHOST}/runtime-deny-canary",
            auth=(inventory["user"], inventory["password"]),
            json={"pattern": "^canary$", "definition": {}, "priority": 1, "apply-to": "queues"},
            timeout=5,
        )
        self.assertIn(response.status_code, (401, 403), response.text[:500])

    def test_smoke_05_retry_queue_ttl_returns_to_main_with_counter(self):
        inventory = RUNTIMES["inventory"]
        started = time.monotonic()
        publish_retry(inventory, {"x-retry-count": 1})
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=45)
            self.assertIsNotNone(message, "retry message did not return after its 30s TTL")
            self.assertGreaterEqual(time.monotonic() - started, 29)
            self.assertEqual(message[1].headers["x-retry-count"], 1)
            self.assertEqual(message[1].message_id, "isolation-message-001")
            channel.basic_ack(message[0].delivery_tag)

    def test_smoke_06_final_reject_routes_to_own_dlq_without_retry_return(self):
        inventory = RUNTIMES["inventory"]
        policy = requests.get(
            f"http://{HOST}:15672/api/policies/{VHOST}/main-inventory-dlx",
            auth=BOOTSTRAP,
            timeout=5,
        )
        self.assertEqual(policy.status_code, 200, policy.text[:500])
        self.assertEqual(policy.json()["definition"]["dead-letter-strategy"], "at-least-once")
        self.assertEqual(policy.json()["apply-to"], "quorum_queues")
        self.admin.basic_publish("", inventory["main"], b"final-reject")
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=5)
            self.assertIsNotNone(message)
            channel.basic_reject(message[0].delivery_tag, requeue=False)
        dlq = get_one(self.admin, inventory["dlq"], timeout=10)
        self.assertIsNotNone(dlq)
        self.assertEqual(dlq[2], b"final-reject")
        self.admin.basic_ack(dlq[0].delivery_tag)
        self.assertIsNone(get_one(self.admin, inventory["main"]))

    def test_extended_01_historical_saturated_dlq_recovery_incident(self):
        """Focused saturation/recovery gate; reports only what the broker demonstrates."""
        inventory = RUNTIMES["inventory"]
        case_id = uuid.uuid4().hex
        original_id = f"dlq-recovery-{case_id}"
        filler_id = f"dlq-filler-{case_id}"
        probe_id = f"dlq-reject-probe-{case_id}"
        diagnostics = {
            "status": "INCONCLUSO",
            "queue_purge_used": False,
            "broker_version": None,
            "policies": {},
            "confirms": [],
            "source": [],
            "destination": [],
            "original_message_id": original_id,
            "observed_message_ids": [],
            "duplicates": None,
        }
        held = []
        publisher_connection = None
        try:
            policy_response = requests.put(
                f"http://{HOST}:15672/api/policies/{VHOST}/inventory-dlq-capacity",
                auth=BOOTSTRAP,
                json={
                    "pattern": r"^po\.inventory\.q\.dlq$",
                    "definition": {"max-length": 1, "overflow": "reject-publish"},
                    "priority": 7,
                    "apply-to": "quorum_queues",
                },
                timeout=5,
            )
            if policy_response.status_code not in (201, 204):
                raise RecoveryInconclusive(
                    f"INCONCLUSO: capacity policy could not be prepared ({policy_response.status_code})"
                )
            policy_listing = requests.get(
                f"http://{HOST}:15672/api/policies/{VHOST}", auth=BOOTSTRAP, timeout=5
            )
            diagnostics["configured_policies"] = (
                policy_listing.json() if policy_listing.status_code == 200 else {"http_status": policy_listing.status_code}
            )

            overview = requests.get(f"http://{HOST}:15672/api/overview", auth=BOOTSTRAP, timeout=5)
            if overview.status_code == 200:
                diagnostics["broker_version"] = overview.json().get("rabbitmq_version")

            source_policy = effective_policy(
                inventory["main"],
                "main-inventory-dlx",
                {
                    "dead-letter-strategy": "at-least-once",
                    "overflow": "reject-publish",
                    "dead-letter-exchange": DLX,
                    "dead-letter-routing-key": inventory["main"],
                },
            )
            target_policy = effective_policy(
                inventory["dlq"],
                "inventory-dlq-capacity",
                {"max-length": 1, "overflow": "reject-publish"},
            )
            diagnostics["policies"] = {"source": source_policy, "destination": target_policy}
            source_start = queue_snapshot(inventory["main"])
            destination_start = queue_snapshot(inventory["dlq"])
            diagnostics["source"].append({"phase": "fixture_start", **source_start})
            diagnostics["destination"].append({"phase": "fixture_start", **destination_start})
            if any(source_start.get(key) != 0 for key in ("messages", "messages_ready", "messages_unacknowledged")):
                raise RecoveryInconclusive(
                    f"INCONCLUSO: source queue counters were not all zero at scenario start: {source_start}"
                )
            if any(destination_start.get(key) != 0 for key in ("messages", "messages_ready", "messages_unacknowledged")):
                raise RecoveryInconclusive("INCONCLUSO: recovery queues were not empty at scenario start")

            publisher_connection = connection(*BOOTSTRAP)
            publisher_channel = publisher_connection.channel()
            publisher_channel.confirm_delivery()

            def publish_confirmed(queue, message_id, body, purpose):
                try:
                    publisher_channel.basic_publish(
                        "", queue, body,
                        properties=pika.BasicProperties(
                            message_id=message_id,
                            delivery_mode=2,
                            content_type="application/octet-stream",
                        ),
                        mandatory=True,
                    )
                except pika.exceptions.NackError:
                    diagnostics["confirms"].append(
                        {"queue": queue, "message_id": message_id, "purpose": purpose, "result": "NACK"}
                    )
                    return False
                # BlockingChannel.basic_publish returns None on a successful
                # publisher confirm in the pinned Pika API; only NackError
                # denotes a broker NACK here.
                diagnostics["confirms"].append(
                    {"queue": queue, "message_id": message_id, "purpose": purpose, "result": "ACK"}
                )
                return True

            self.assertTrue(publish_confirmed(inventory["dlq"], filler_id, b"capacity-filler", "normal_filler"))
            full = queue_snapshot(inventory["dlq"])
            diagnostics["destination"].append({"phase": "after_filler", **full})
            if ready_count(self.admin, inventory["dlq"]) != 1:
                raise RecoveryInconclusive("INCONCLUSO: the one-message filler did not establish a full destination")

            # Quorum queues can accept a bounded number of in-flight/overshoot
            # publications. Probe serially on one confirmed channel; stop at the
            # first NACK and never retry without a finite bound.
            capacity_message_ids = {filler_id}
            rejection_observed = False
            for probe_index in range(8):
                current_probe_id = f"{probe_id}-{probe_index}"
                if not publish_confirmed(
                    inventory["dlq"], current_probe_id, b"capacity-rejection-probe", "normal_capacity_probe"
                ):
                    rejection_observed = True
                    break
                capacity_message_ids.add(current_probe_id)
            diagnostics["destination"].append(
                {"phase": "capacity_probe", "ready_count": ready_count(self.admin, inventory["dlq"]),
                 "confirmed_fillers": sorted(capacity_message_ids), "rejection_observed": rejection_observed}
            )
            if not rejection_observed:
                raise RecoveryInconclusive("INCONCLUSO: destination accepted all bounded probes; capacity rejection was not proven")
            diagnostics["destination"].append({"phase": "probe_nack", **queue_snapshot(inventory["dlq"])})

            self.assertTrue(
                publish_confirmed(
                    inventory["main"], original_id, original_id.encode("ascii"), "original_source_publish"
                )
            )
            with connection(inventory["user"], inventory["password"]) as conn:
                channel = conn.channel()
                message = get_one(channel, inventory["main"], timeout=5)
                self.assertIsNotNone(message, "FAIL: confirmed original message was not available on source")
                self.assertEqual(message[1].message_id, original_id)
                diagnostics["source"].append(
                    {
                        "phase": "original_rejected_requeue_false",
                        "message_id": message[1].message_id,
                        "body_matches_id": message[2] == original_id.encode("ascii"),
                        "delivery_tag": message[0].delivery_tag,
                        "requeue": False,
                    }
                )
                channel.basic_reject(message[0].delivery_tag, requeue=False)

            # Do not basic.get the source here: at-least-once quorum DLX uses
            # an internal consumer that checks out discarded messages directly
            # from the quorum queue, outside the AMQP consumer interface.
            # Management counters can lag the reject, so sample both zero and
            # non-zero values on a bounded schedule before releasing the DLQ.
            source_evidence_window_seconds = 20
            source_metric_poll_seconds = 5
            source_evidence_deadline = time.monotonic() + source_evidence_window_seconds
            source_samples = []
            source_held = False
            while time.monotonic() < source_evidence_deadline:
                source_snapshot = queue_snapshot(inventory["main"])
                source_sample = {
                    "elapsed_seconds": round(
                        source_evidence_window_seconds
                        - max(0, source_evidence_deadline - time.monotonic()),
                        3,
                    ),
                    **source_snapshot,
                }
                source_samples.append(source_sample)
                # The isolated fixture starts empty, publishes only this unique
                # original to the source, confirms it, receives that exact id,
                # and rejects it. No later source publishes/consumers run.
                # Therefore a total count of one with zero ready and zero
                # ordinary unacknowledged messages is the same message retained
                # in the quorum dead-letter worker, not an identity guess from
                # a shared queue's aggregate counter.
                if (
                    source_snapshot["messages"] == 1
                    and source_snapshot["messages_ready"] == 0
                    and source_snapshot["messages_unacknowledged"] == 0
                ):
                    source_held = True
                    break
                time.sleep(min(source_metric_poll_seconds, max(0, source_evidence_deadline - time.monotonic())))
            diagnostics["source"].append(
                {
                    "phase": "destination_rejected_before_capacity_release",
                    "identity_basis": {
                        "source_counters_all_zero_at_start": True,
                        "unique_original_message_id_published_confirmed": original_id,
                        "only_source_publish_in_scenario": True,
                        "exact_id_received_and_rejected_requeue_false": original_id,
                        "source_basic_get_after_reject_used": False,
                    },
                    "retained_pending_observed": source_held,
                    "metric_poll_interval_seconds": source_metric_poll_seconds,
                    "metric_observation_window_seconds": source_evidence_window_seconds,
                    "samples": source_samples,
                    "poll_count": len(source_samples),
                }
            )
            diagnostics["source_retention_observed_before_recovery"] = source_held

            # Release capacity by acknowledging only identified filler/probe
            # messages. Never purge the destination or touch the original ID.
            while ready_count(self.admin, inventory["dlq"]) > 0:
                filler = get_one(self.admin, inventory["dlq"], timeout=5)
                if not filler or filler[1].message_id not in capacity_message_ids:
                    if filler:
                        self.admin.basic_nack(filler[0].delivery_tag, requeue=True)
                    raise RecoveryInconclusive("INCONCLUSO: destination contained an unexpected message; capacity was preserved")
                self.admin.basic_ack(filler[0].delivery_tag)
                capacity_message_ids.remove(filler[1].message_id)
            if capacity_message_ids:
                raise RecoveryInconclusive("INCONCLUSO: not all confirmed filler identities could be observed and acknowledged")
            capacity_released_at = time.monotonic()
            diagnostics["destination"].append({
                "phase": "identified_fillers_acknowledged",
                "capacity_released_monotonic": capacity_released_at,
                **queue_snapshot(inventory["dlq"]),
            })
            diagnostics["source"].append(
                {"phase": "immediately_after_capacity_release", **queue_snapshot(inventory["main"])}
            )

            observation_seconds = int(os.environ.get("RABBITMQ_RECOVERY_OBSERVATION_SECONDS", "60"))
            if not 1 <= observation_seconds <= 900:
                raise RecoveryInconclusive("INCONCLUSO: recovery observation must be between 1 and 900 seconds")
            diagnostics["observation_seconds"] = observation_seconds
            deadline = time.monotonic() + observation_seconds
            first_original_seen_at = None
            recovery_polls = 0
            while time.monotonic() < deadline:
                recovery_polls += 1
                while True:
                    delivered = get_one(self.admin, inventory["dlq"])
                    if not delivered:
                        break
                    if delivered[1].message_id == original_id and first_original_seen_at is None:
                        first_original_seen_at = time.monotonic()
                        diagnostics["recovery_elapsed_seconds"] = round(
                            first_original_seen_at - capacity_released_at, 3
                        )
                    if delivered[1].message_id == original_id:
                        diagnostics["observed_message_ids"].append(delivered[1].message_id)
                        self.admin.basic_ack(delivered[0].delivery_tag)
                    else:
                        held.append(delivered)
                        diagnostics["observed_message_ids"].append(delivered[1].message_id)
                time.sleep(0.25)

            unexpected = [m for m in held if m[1].message_id != original_id]
            matches = [message_id for message_id in diagnostics["observed_message_ids"] if message_id == original_id]
            diagnostics["duplicates"] = max(0, len(matches) - 1)
            diagnostics["source"].append(
                {"phase": "recovery_complete", "polls": recovery_polls, **queue_snapshot(inventory["main"])}
            )
            diagnostics["destination"].append({"phase": "recovery_complete", **queue_snapshot(inventory["dlq"])})
            if unexpected:
                raise RecoveryInconclusive("INCONCLUSO: destination contained an unexpected message; it was requeued")
            if not diagnostics.get("source_retention_observed_before_recovery"):
                diagnostics["status"] = "INCONCLUSO"
                raise RecoveryInconclusive(
                    "INCONCLUSO: source retention was not observable before recovery capacity was released"
                )
            if not matches:
                diagnostics["status"] = "FAIL"
                self.fail(
                    f"FAIL: the retained original did not reach the destination within the "
                    f"{observation_seconds}s experimental window"
                )
            for method, _, _ in held:
                self.admin.basic_ack(method.delivery_tag)
            diagnostics["status"] = "PASS"
        except RecoveryInconclusive:
            diagnostics["status"] = "INCONCLUSO"
            raise
        except AssertionError:
            diagnostics["status"] = "FAIL"
            raise
        finally:
            # Do not delete observed messages. On a non-PASS path, return any
            # delivery held only for duplicate accounting to the DLQ unchanged.
            if diagnostics["status"] != "PASS":
                for method, _, _ in held:
                    try:
                        self.admin.basic_nack(method.delivery_tag, requeue=True)
                    except pika.exceptions.AMQPError:
                        pass
            if publisher_connection and publisher_connection.is_open:
                publisher_connection.close()
            print("RECOVERY_DIAGNOSTIC=" + json.dumps(diagnostics, sort_keys=True, default=str))
            print(f"RECOVERY_STATUS={diagnostics['status']}")

    def test_smoke_07_runtime_cannot_publish_to_dlx_but_broker_can_dead_letter(self):
        inventory = RUNTIMES["inventory"]
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            channel.confirm_delivery()
            with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                channel.basic_publish(exchange=DLX, routing_key=inventory["main"], body=b"denied")
            self.assertEqual(error.exception.reply_code, 403)
        self.admin.basic_publish("", inventory["main"], b"broker-managed-dlx")
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=5)
            self.assertIsNotNone(message)
            channel.basic_reject(message[0].delivery_tag, requeue=False)
        dead = get_one(self.admin, inventory["dlq"], timeout=10)
        self.assertIsNotNone(dead)
        self.assertEqual(dead[2], b"broker-managed-dlx")
        self.admin.basic_ack(dead[0].delivery_tag)

    def test_extended_02_business_rejection_ack_does_not_reach_dlq(self):
        inventory = RUNTIMES["inventory"]
        self.admin.basic_publish("", inventory["main"], b"business-rejected")
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=5)
            self.assertIsNotNone(message)
            channel.basic_ack(message[0].delivery_tag)
        self.assertIsNone(get_one(self.admin, inventory["dlq"], timeout=2))

    def test_extended_03_three_synthetic_retry_cycles_preserve_transport_metadata(self):
        """Uses test messages; does not execute inventory-svc or Outbox/Inbox."""
        inventory = RUNTIMES["inventory"]
        metadata = {
            "x-retry-count": 0,
            "causation_id": "causation-001",
            "operation_id": "operation-001",
        }
        observed_counts = []
        for retry_count in range(1, 4):
            metadata["x-retry-count"] = retry_count
            started = time.monotonic()
            publish_retry(inventory, metadata.copy())
            with connection(inventory["user"], inventory["password"]) as conn:
                app_channel = conn.channel()
                delivered = get_one(app_channel, inventory["main"], timeout=45)
                self.assertIsNotNone(delivered, f"retry {retry_count} did not return after 30s")
                self.assertGreaterEqual(time.monotonic() - started, 29)
                method, props, body = delivered
                self.assertEqual(props.headers["x-retry-count"], retry_count)
                self.assertEqual(props.headers["causation_id"], "causation-001")
                self.assertEqual(props.headers["operation_id"], "operation-001")
                self.assertEqual(props.message_id, "isolation-message-001")
                self.assertEqual(props.correlation_id, "isolation-correlation-001")
                observed_counts.append(props.headers["x-retry-count"])
                if retry_count < 3:
                    metadata = {
                        key: props.headers[key]
                        for key in ("x-retry-count", "causation_id", "operation_id")
                    }
                    app_channel.basic_ack(method.delivery_tag)
                else:
                    app_channel.basic_reject(method.delivery_tag, requeue=False)
        self.assertEqual(observed_counts, [1, 2, 3])
        dead = get_one(self.admin, inventory["dlq"], timeout=10)
        self.assertIsNotNone(dead, "exhausted delivery did not arrive in the DLQ")
        self.assertEqual(dead[1].headers["x-retry-count"], 3)
        self.admin.basic_ack(dead[0].delivery_tag)
        self.assertIsNone(get_one(self.admin, inventory["main"]))

    def test_smoke_08_default_exchange_and_non_owned_queues_are_denied(self):
        inventory = RUNTIMES["inventory"]
        denied = (
            lambda ch: confirmed_publish(ch, "", inventory["main"], b"default-exchange"),
            lambda ch: ch.basic_get(queue=RUNTIMES["catalog"]["main"]),
            lambda ch: ch.basic_get(queue=inventory["retry"]),
            lambda ch: ch.basic_get(queue=inventory["dlq"]),
            lambda ch: ch.basic_get(queue="po.unrouted.q"),
        )
        for operation in denied:
            with self.subTest(operation=operation):
                with connection(inventory["user"], inventory["password"]) as conn:
                    with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                        operation(conn.channel())
                    self.assertEqual(error.exception.reply_code, 403)

    def test_extended_04_alternate_exchange_and_mandatory_return(self):
        # Broker behaviour for mandatory is distinct from runtime ACL checks:
        # an AE binding captures a publish; no AE route causes basic.return.
        with connection(*BOOTSTRAP) as conn:
            channel = conn.channel()
            channel.confirm_delivery()
            returned = []
            channel.add_on_return_callback(lambda method, props, body: returned.append((method, props, body)))
            channel.basic_publish(
                exchange="po.events.x",
                routing_key="inventory.unbound.test",
                body=b"alternate-capture",
                mandatory=True,
            )
            self.assertEqual(returned, [], "alternate-routed publish must not produce basic.return")

            with self.assertRaises(pika.exceptions.UnroutableError) as unroutable:
                channel.basic_publish(
                    exchange="po.no-route.x",
                    routing_key="no.binding",
                    body=b"mandatory-return",
                    mandatory=True,
                )
            self.assertEqual(len(unroutable.exception.messages), 1)
            self.assertEqual(unroutable.exception.messages[0].body, b"mandatory-return")

        captured = get_one(self.admin, "po.unrouted.q", timeout=5)
        self.assertIsNotNone(captured)
        self.assertEqual(captured[2], b"alternate-capture")
        self.admin.basic_ack(captured[0].delivery_tag)


def load_tests(loader, standard_tests, pattern):
    profile = os.environ.get("RABBITMQ_TEST_PROFILE", "essential")
    if profile not in {"essential", "extended", "recovery", "all"}:
        raise ValueError("RABBITMQ_TEST_PROFILE must be essential, extended, recovery, or all")
    cases = [case for suite in standard_tests for case in suite]
    if profile == "all":
        return unittest.TestSuite(cases)
    if profile == "recovery":
        return unittest.TestSuite(
            case for case in cases if case._testMethodName == "test_extended_01_historical_saturated_dlq_recovery_incident"
        )
    prefix = "test_smoke_" if profile == "essential" else "test_extended_"
    return unittest.TestSuite(case for case in cases if case._testMethodName.startswith(prefix))

"""Isolated executable checks for candidate RabbitMQ isolation A (not contract adoption)."""
import os
import time
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
            "inventory-dlq-capacity": (
                r"^po\.inventory\.q\.dlq$",
                {"max-length": 1, "overflow": "reject-publish"},
            ),
        }
        for name, (pattern, definition) in policies.items():
            if name != "inventory-dlq-capacity":
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
        for runtime in RUNTIMES.values():
            for queue in (runtime["main"], runtime["retry"], runtime["dlq"]):
                self.admin.queue_purge(queue=queue)

    def test_01_inventory_and_catalog_can_publish_only_their_own_retry_route(self):
        for runtime in RUNTIMES.values():
            publish_retry(runtime, {"x-retry-count": 1})
            message = get_one(self.admin, runtime["retry"])
            self.assertIsNotNone(message)
            self.assertEqual(message[1].headers["x-retry-count"], 1)
            self.admin.basic_ack(message[0].delivery_tag)
            self.assertIsNone(get_one(self.admin, runtime["main"]))

    def test_02_exact_anchored_topic_permissions_reject_cross_and_near_match(self):
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

    def test_03_catalog_cannot_consume_inventory_queue(self):
        catalog = RUNTIMES["catalog"]
        with connection(catalog["user"], catalog["password"]) as conn:
            with self.assertRaises(pika.exceptions.ChannelClosedByBroker) as error:
                conn.channel().basic_get(queue=RUNTIMES["inventory"]["main"])
            self.assertEqual(error.exception.reply_code, 403)

    def test_04_runtime_cannot_declare_bind_delete_or_manage_policy(self):
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

    def test_05_retry_queue_ttl_returns_to_main_with_counter(self):
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

    def test_06_final_reject_routes_to_own_dlq_without_retry_return(self):
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

        # Rejecting at the destination simulates unavailable capacity while
        # preserving its binding; after capacity returns, the worker must retry.
        self.admin.basic_publish("", inventory["dlq"], b"capacity-filler")
        self.admin.basic_publish("", inventory["main"], b"dlq-target-outage")
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=5)
            self.assertIsNotNone(message)
            channel.basic_reject(message[0].delivery_tag, requeue=False)
        time.sleep(2)
        self.admin.queue_purge(queue=inventory["dlq"])
        recovered = get_one(self.admin, inventory["dlq"], timeout=60)
        self.assertIsNotNone(recovered, "retained dead letter was not delivered after target recovery")
        self.assertEqual(recovered[2], b"dlq-target-outage")
        self.admin.basic_ack(recovered[0].delivery_tag)

    def test_07_runtime_cannot_publish_to_dlx_but_broker_can_dead_letter(self):
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

    def test_08_business_rejection_ack_does_not_reach_dlq(self):
        inventory = RUNTIMES["inventory"]
        self.admin.basic_publish("", inventory["main"], b"business-rejected")
        with connection(inventory["user"], inventory["password"]) as conn:
            channel = conn.channel()
            message = get_one(channel, inventory["main"], timeout=5)
            self.assertIsNotNone(message)
            channel.basic_ack(message[0].delivery_tag)
        self.assertIsNone(get_one(self.admin, inventory["dlq"], timeout=2))

    def test_09_three_counted_retries_preserve_transport_identity_and_finally_dlq(self):
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

    def test_10_default_exchange_alternate_exchange_and_foreign_queue_are_denied(self):
        inventory = RUNTIMES["inventory"]
        denied = (
            lambda ch: confirmed_publish(ch, "", inventory["main"], b"default-exchange"),
            lambda ch: confirmed_publish(ch, "po.unrouted.x", "", b"alternate-exchange"),
            lambda ch: confirmed_publish(ch, "po.dlx.x", inventory["main"], b"dlx"),
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

        # Broker behaviour for mandatory is distinct from runtime ACL checks:
        # an AE binding captures the first publish; no AE route causes basic.return.
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

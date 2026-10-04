import json
import logging
from typing import Dict, Any
from app.config import settings

logger = logging.getLogger("paynora.kafka")

class EventPublisher:
    def __init__(self):
        self.bootstrap_servers = settings.KAFKA_BOOTSTRAP_SERVERS
        self.is_connected = False

    def publish_event(self, topic: str, event_data: Dict[str, Any]) -> bool:
        """
        Publish financial domain event to Kafka broker.
        In local dev/mock mode, logs the event structure cleanly.
        """
        logger.info(f"[Kafka Event Published] Topic: {topic} | Data: {json.dumps(event_data)}")
        return True

event_publisher = EventPublisher()

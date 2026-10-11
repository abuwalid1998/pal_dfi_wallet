"""
PAL-DFI Event Bus Module (Microservices Event Mesh)
Handles asynchronous inter-service domain event publication and dispatching.
"""

import json
import time
import os
import threading
from typing import Callable, Dict, List

EVENT_LOG_FILE = os.path.join(os.path.dirname(__file__), "event_log.json")

class EventBus:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(EventBus, cls).__new__(cls)
                cls._instance._subscribers: Dict[str, List[Callable]] = {}
                cls._instance._history: List[dict] = []
                cls._instance._load_history()
            return cls._instance

    def _load_history(self):
        if os.path.exists(EVENT_LOG_FILE):
            try:
                with open(EVENT_LOG_FILE, "r", encoding="utf-8") as f:
                    self._history = json.load(f)
            except Exception:
                self._history = []

    def _save_history(self):
        try:
            with open(EVENT_LOG_FILE, "w", encoding="utf-8") as f:
                json.dump(self._history[-200:], f, indent=2)
        except Exception:
            pass

    def subscribe(self, event_type: str, handler: Callable):
        with self._lock:
            if event_type not in self._subscribers:
                self._subscribers[event_type] = []
            self._subscribers[event_type].append(handler)

    def publish(self, event_type: str, payload: dict, source_service: str = "unknown"):
        event_record = {
            "eventId": f"evt_{int(time.time()*1000)}_{os.urandom(3).hex()}",
            "type": event_type,
            "source": source_service,
            "timestamp": time.time(),
            "isoTime": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "payload": payload
        }

        with self._lock:
            self._history.append(event_record)
            self._save_history()
            handlers = list(self._subscribers.get(event_type, []))
            wildcard_handlers = list(self._subscribers.get("*", []))

        # Asynchronously dispatch to handlers
        for h in handlers + wildcard_handlers:
            try:
                threading.Thread(target=h, args=(event_record,), daemon=True).start()
            except Exception as e:
                print(f"[EventBus] Error dispatching event {event_type} to handler: {e}")

        return event_record

    def get_recent_events(self, limit: int = 50) -> List[dict]:
        with self._lock:
            return self._history[-limit:]

# Singleton instance
event_bus = EventBus()

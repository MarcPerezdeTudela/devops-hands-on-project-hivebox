"""Fixtures that exercise HiveBox and openSenseMap over real HTTP."""

import json
import socket
import threading
import time
from collections.abc import Iterator
from datetime import UTC, datetime
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import cast
from unittest.mock import patch

import httpx
import pytest
import uvicorn

from src import opensensemap
from src.config import SENSEBOX_IDS
from src.main import app

SERVER_START_TIMEOUT_SECONDS = 5.0
SERVER_STOP_TIMEOUT_SECONDS = 10
HTTP_CLIENT_TIMEOUT_SECONDS = 5.0
TEMPERATURES_BY_BOX_ID = dict(zip(SENSEBOX_IDS, (10.0, 20.0, 33.0), strict=True))


class OpenSenseMapRequestHandler(BaseHTTPRequestHandler):
    """Return controlled openSenseMap responses for configured senseBoxes."""

    def do_GET(self) -> None:  # pylint: disable=invalid-name
        """Serve one deterministic ambient-temperature measurement."""
        path_prefix = "/boxes/"
        if not self.path.startswith(path_prefix):
            self._send_json(HTTPStatus.NOT_FOUND, {"detail": "Not found"})
            return

        box_id = self.path.removeprefix(path_prefix)
        temperature = TEMPERATURES_BY_BOX_ID.get(box_id)
        if temperature is None:
            self._send_json(HTTPStatus.NOT_FOUND, {"detail": "Unknown senseBox"})
            return

        measurement: dict[str, str] = {
            "createdAt": datetime.now(UTC).isoformat(),
            "value": str(temperature),
        }
        sensor: dict[str, object] = {
            "title": "Temperatur",
            "unit": "°C",
            "lastMeasurement": measurement,
        }
        payload: dict[str, object] = {"sensors": [sensor]}

        self._send_json(HTTPStatus.OK, payload)

    def log_message(  # pylint: disable=redefined-builtin
        self,
        format: str,
        *args: object,
    ) -> None:
        """Keep successful integration-test output free from server logs."""

    def _send_json(self, status_code: HTTPStatus, payload: object) -> None:
        """Serialize and send one JSON response."""
        response_body = json.dumps(payload).encode()
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)


@pytest.fixture(scope="module")
def fake_opensensemap_url() -> Iterator[str]:
    """Run a controlled openSenseMap substitute on an ephemeral port."""
    server = ThreadingHTTPServer(
        ("127.0.0.1", 0),
        OpenSenseMapRequestHandler,
    )
    server.daemon_threads = True
    thread = threading.Thread(
        target=server.serve_forever,
        name="fake-opensensemap",
        daemon=True,
    )
    thread.start()
    host, port = cast(tuple[str, int], server.server_address)

    try:
        yield f"http://{host}:{port}/boxes/{{box_id}}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=SERVER_STOP_TIMEOUT_SECONDS)
        if thread.is_alive():
            pytest.fail("The fake openSenseMap server did not stop cleanly")


@pytest.fixture(scope="module")
# Pytest resolves fixtures by matching parameter and fixture function names.
# pylint: disable=redefined-outer-name
def live_hivebox_url(fake_opensensemap_url: str) -> Iterator[str]:
    """Run HiveBox through Uvicorn on an ephemeral TCP port."""
    listening_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listening_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listening_socket.bind(("127.0.0.1", 0))
    listening_socket.listen()
    host, port = listening_socket.getsockname()

    config = uvicorn.Config(
        app,
        log_level="warning",
        timeout_graceful_shutdown=SERVER_STOP_TIMEOUT_SECONDS,
    )
    server = uvicorn.Server(config)
    thread = threading.Thread(
        target=server.run,
        kwargs={"sockets": [listening_socket]},
        name="live-hivebox",
        daemon=True,
    )

    with patch.object(
        opensensemap,
        "OPEN_SENSE_MAP_BOX_URL",
        fake_opensensemap_url,
    ):
        thread.start()
        try:
            startup_deadline = time.monotonic() + SERVER_START_TIMEOUT_SECONDS
            while not server.started:
                if not thread.is_alive():
                    pytest.fail("The HiveBox server stopped during startup")
                if time.monotonic() >= startup_deadline:
                    pytest.fail("The HiveBox server did not start within 5 seconds")
                time.sleep(0.01)

            yield f"http://{host}:{port}"
        finally:
            server.should_exit = True
            thread.join(timeout=SERVER_STOP_TIMEOUT_SECONDS)
            listening_socket.close()
            if thread.is_alive():
                pytest.fail("The HiveBox server did not stop cleanly")


@pytest.fixture(scope="module")
# Pytest resolves fixtures by matching parameter and fixture function names.
# pylint: disable=redefined-outer-name
def live_api_client(live_hivebox_url: str) -> Iterator[httpx.Client]:
    """Provide a client that reaches HiveBox through a real TCP connection."""
    with httpx.Client(
        base_url=live_hivebox_url,
        timeout=HTTP_CLIENT_TIMEOUT_SECONDS,
    ) as client:
        yield client

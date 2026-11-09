"""Thuta mobile-app bridge for Raspberry Pi.

Run this file from the existing Thuta-Code-Updated directory so it can import
config and core_brain.inferencing. The AI model is loaded once at startup.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect

THUTA_DIR = Path(os.environ.get("THUTA_CODE_DIR", Path.cwd())).resolve()
if str(THUTA_DIR) not in sys.path:
    sys.path.insert(0, str(THUTA_DIR))

app = FastAPI(title="Thuta AI Mobile Bridge", version="0.1.0")

brain: Any = None
serial_port: Any = None
state: dict[str, Any] = {
    "type": "state",
    "status": "Starting",
    "emotion": "calm",
    "action": "idle_wait",
    "energy": 0,
    "tracking": False,
}


def _load_hardware() -> None:
    global brain, serial_port
    from core_brain.inferencing import ThutaStateMachine

    model_path = os.environ.get(
        "THUTA_MODEL_PATH", str(THUTA_DIR / "models/llm/thuta_model_q4_k_m.gguf")
    )
    brain = ThutaStateMachine(model_path=model_path)
    state.update(status="Online", energy=brain.energy)

    try:
        import serial

        serial_port = serial.Serial(
            port=os.environ.get("THUTA_UART", "/dev/ttyAMA2"),
            baudrate=int(os.environ.get("THUTA_UART_BAUD", "9600")),
            timeout=1,
        )
    except Exception as exc:  # Keep chat available if the ESP32 is offline.
        serial_port = None
        print(f"UART unavailable: {exc}", flush=True)


@app.on_event("startup")
async def startup() -> None:
    await asyncio.to_thread(_load_hardware)


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": brain is not None, "uart": serial_port is not None, **state}


def _send_uart(payload: dict[str, Any]) -> None:
    if serial_port is None:
        return
    data = json.dumps(payload, separators=(",", ":")) + "\n"
    serial_port.write(data.encode("utf-8"))
    serial_port.flush()


def _process_chat(text: str) -> dict[str, Any]:
    state["status"] = "Thinking"
    response = brain.process_turn(text)
    state.update(
        status="Online",
        emotion=brain.emotion,
        action=brain.current_action,
        energy=brain.energy,
    )
    _send_uart(
        {
            "type": "state",
            "intent": response.get("intent", "idle_response"),
            "emotion": brain.emotion,
            "action": brain.current_action,
            "energy": brain.energy,
        }
    )
    return {"type": "chat_response", "reply": response.get("reply", "..."), **state}


@app.websocket("/ws")
async def websocket_endpoint(socket: WebSocket) -> None:
    await socket.accept()
    await socket.send_json(state)
    try:
        while True:
            message = await socket.receive_json()
            message_type = message.get("type")
            if message_type == "get_state":
                await socket.send_json(state)
            elif message_type == "chat":
                text = str(message.get("text", "")).strip()
                if not text:
                    await socket.send_json({"type": "error", "message": "Message is empty."})
                    continue
                await socket.send_json({"type": "state", **state, "status": "Thinking"})
                result = await asyncio.to_thread(_process_chat, text)
                await socket.send_json(result)
            elif message_type == "emergency_stop":
                _send_uart(
                    {
                        "type": "state",
                        "intent": "command",
                        "emotion": state["emotion"],
                        "action": "stop_move",
                        "energy": state["energy"],
                    }
                )
                state["action"] = "stop_move"
                await socket.send_json(state)
            else:
                await socket.send_json(
                    {"type": "error", "message": f"Unsupported message type: {message_type}"}
                )
    except WebSocketDisconnect:
        pass


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

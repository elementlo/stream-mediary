#!/usr/bin/env python3
"""Capture a Flutter app screenshot via the VM service `_flutter.screenshot`
extension. The engine renders the frame internally, so this needs NO macOS
screen-recording permission (unlike screencapture / ScreenCaptureKit).

Usage: vm_screenshot.py <vm-service-http-url> <out.png>
"""
import asyncio
import base64
import json
import re
import sys

import websockets


def to_ws_url(http_url: str) -> str:
    # http://127.0.0.1:PORT/AUTH=/  ->  ws://127.0.0.1:PORT/AUTH=/ws
    u = http_url.strip()
    u = re.sub(r"^http", "ws", u)
    if not u.endswith("/ws"):
        u = u.rstrip("/") + "/ws"
    return u


async def main() -> int:
    if len(sys.argv) < 3:
        print("usage: vm_screenshot.py <vm-url> <out.png>", file=sys.stderr)
        return 1
    ws_url = to_ws_url(sys.argv[1])
    out = sys.argv[2]

    async with websockets.connect(ws_url, max_size=None) as ws:
        async def call(method, params=None, _id=[0]):
            _id[0] += 1
            msg = {"jsonrpc": "2.0", "id": str(_id[0]), "method": method}
            if params:
                msg["params"] = params
            await ws.send(json.dumps(msg))
            while True:
                resp = json.loads(await ws.recv())
                if resp.get("id") == msg["id"]:
                    if "error" in resp:
                        raise RuntimeError(f"{method}: {resp['error']}")
                    return resp["result"]

        vm = await call("getVM")
        isolates = vm.get("isolates", [])
        if not isolates:
            print("ERR no isolates", file=sys.stderr)
            return 2
        iso = isolates[0]["id"]

        # Wait for the frame to settle.
        await asyncio.sleep(2)

        res = await call("_flutter.screenshot", {"isolateId": iso})
        b64 = res.get("screenshot")
        if not b64:
            print(f"ERR no screenshot in response: {list(res.keys())}", file=sys.stderr)
            return 3
        with open(out, "wb") as f:
            f.write(base64.b64decode(b64))
        print(f"saved {out}")
        return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))

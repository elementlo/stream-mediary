#!/usr/bin/env python3
"""Mock Waline server for manually exercising the in-app community board.

Serves the two REST endpoints the app uses on http://127.0.0.1:8788:
  GET  /api/comment   -> one page of seeded comments (incl. one reply)
  POST /api/comment   -> appends a comment and echoes it back

Usage:
  python3 tool/mock_waline.py

Then point the app at it (Settings -> Community server URL):
  Android device:   adb reverse tcp:8788 tcp:8788, then http://127.0.0.1:8788
  iOS simulator:    http://127.0.0.1:8788  (shares host network)
  macOS desktop:    http://127.0.0.1:8788
"""
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

comments = [
    {"objectId": "c1", "comment": "<p>欢迎使用 Mediary 留言板！</p>", "nick": "作者",
     "insertedAt": "2026-09-18T03:00:00.000Z", "rid": None, "link": None, "avatar": None},
    {"objectId": "c2", "comment": "<p>测试回复：支持楼中楼。</p>", "nick": "路人甲",
     "insertedAt": "2026-09-18T04:30:00.000Z", "rid": "c1", "link": None, "avatar": None},
]
counter = [2]


class Handler(BaseHTTPRequestHandler):
    def _send(self, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/api/comment"):
            # Mirror the real Waline: replies are nested under their parent's
            # `children` array rather than returned flat.
            by_id = {c["objectId"]: dict(c, children=[]) for c in comments}
            roots = []
            for c in comments:
                node = by_id[c["objectId"]]
                parent = by_id.get(c["rid"]) if c["rid"] else None
                if parent is not None:
                    parent["children"].append(node)
                else:
                    roots.append(node)
            self._send({"code": 0, "errno": 0,
                        "data": {"data": roots, "page": 1, "totalPages": 1}})
        else:
            self._send({"code": 1, "errno": 1, "msg": "not found"})

    def do_POST(self):
        if self.path.startswith("/api/comment"):
            n = int(self.headers.get("Content-Length", 0))
            payload = json.loads(self.rfile.read(n) or b"{}")
            counter[0] += 1
            obj = {
                "objectId": f"c{counter[0]}",
                "comment": f"<p>{payload.get('comment', '')}</p>",
                "nick": payload.get("nick", "anonymous"),
                "insertedAt": "2026-09-18T05:00:00.000Z",
                "rid": payload.get("rid"),
                "link": None,
                "avatar": None,
            }
            comments.append(obj)
            self._send({"code": 0, "data": obj})
        else:
            self._send({"code": 1, "msg": "not found"})

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print("mock Waline listening on http://127.0.0.1:8788")
    HTTPServer(("127.0.0.1", 8788), Handler).serve_forever()

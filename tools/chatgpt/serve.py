# Serves the repo on 127.0.0.1:18923 (only this machine), so the built-in browser pane can carry
# local pictures into the ChatGPT tab (skill chatgpt-review). Run in the background:
#   python tools/chatgpt/serve.py
# Port 8765 is blocked on this PC (WinError 10013); 18923 works.
# POST /save?name=<file> stores the request body under art/inbox/ (receive.html brings ChatGPT's
# pictures back this way); only plain file names, only into that folder.
import functools
import http.server
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
INBOX = os.path.join(ROOT, "art", "inbox")


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_POST(self):
        query = self.path.split("?", 1)[1] if "?" in self.path else ""
        name = dict(p.split("=", 1) for p in query.split("&") if "=" in p).get("name", "")
        if not self.path.startswith("/save?") or not re.fullmatch(r"[A-Za-z0-9_.-]{1,80}\.(png|webp|jpg)", name):
            self.send_error(400)
            return
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        os.makedirs(INBOX, exist_ok=True)
        with open(os.path.join(INBOX, name), "wb") as f:
            f.write(body)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"saved")


http.server.ThreadingHTTPServer(("127.0.0.1", 18923), functools.partial(Handler, directory=ROOT)).serve_forever()

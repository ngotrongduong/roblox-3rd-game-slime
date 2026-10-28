# Serves the repo on 127.0.0.1:18923 (only this machine), so the built-in browser pane can carry
# local pictures into the ChatGPT tab (skill chatgpt-review). Run in the background:
#   python tools/chatgpt/serve.py
# Port 8765 is blocked on this PC (WinError 10013); 18923 works.
import functools
import http.server
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


http.server.ThreadingHTTPServer(("127.0.0.1", 18923), functools.partial(Handler, directory=ROOT)).serve_forever()

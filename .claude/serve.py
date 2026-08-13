"""Static file server for _site/ with caching disabled.

Plain `python3 -m http.server` sends no Cache-Control header, so browsers apply
heuristic caching and keep serving an old styles.css after a re-render — a CSS
change lands on disk, is served correctly over HTTP, and still does not appear
in the page. This sends `no-store` on every response so what you see is always
what was last rendered.

Usage: python3 serve.py <port> <directory>
"""

import functools
import http.server
import socketserver
import sys


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):  # quieter console
        sys.stderr.write("%s %s\n" % (self.command, self.path))


if __name__ == "__main__":
    port = int(sys.argv[1])
    directory = sys.argv[2]
    handler = functools.partial(NoCacheHandler, directory=directory)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        print(f"serving {directory} on http://127.0.0.1:{port} (no-store)")
        httpd.serve_forever()

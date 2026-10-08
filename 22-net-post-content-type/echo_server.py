# Answers every request with the Content-Type it was sent, as JSON.
#   python3 echo_server.py   # listens on 127.0.0.1:18765
import json, http.server
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        out = json.dumps({"contentType": self.headers.get('Content-Type'),
                          "body": self.rfile.read(n).decode()}).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(out)))
        self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer(('127.0.0.1', 18765), H).serve_forever()

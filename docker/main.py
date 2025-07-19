from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {"status": "ok", "message": "My ✨Flamboyant✨ app v2🥈"}
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps(response, ensure_ascii=False).encode("utf-8"))

PORT = 8888
print(f"Starting server on port {PORT}")
HTTPServer(("", PORT), MyHandler).serve_forever()
# This code sets up a simple HTTP server that responds with a JSON message

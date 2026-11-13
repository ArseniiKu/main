from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os


class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {
            "message": "Hello from Kosgos CI/CD Pipeline!",
            "version": os.environ.get("APP_VERSION", "1.0.0"),
            "hostname": os.uname().nodename
        }
        self.wfile.write(json.dumps(response).encode())

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    server = HTTPServer(('0.0.0.0', port), AppHandler)
    print(f"Server running on port {port}")
    server.serve_forever()

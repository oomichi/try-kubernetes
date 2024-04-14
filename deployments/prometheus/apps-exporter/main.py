import http.server
import socketserver

metrics = {}
flag = False

class MyHTTPRequestHandler(http.server.BaseHTTPRequestHandler):
    global metrics
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()

        self.wfile.write(b"# HELP deployment_status The status of deployments.\n")
        self.wfile.write(b"# TYPE deployment_status gauge\n")
        #v = str(metrics["tmp_files"]).encode()
        #self.wfile.write(b'tmp_files ' + v + b"\n")
        self.wfile.write(b'deployment_status{namespace="namespace-app-1"} 1' + b"\n")


if __name__ == "__main__":
    print("starting server")
    Handler = MyHTTPRequestHandler
    with socketserver.TCPServer(("0.0.0.0", 8000), Handler) as httpd:
        print("serving at http://0.0.0.0:8000")
        httpd.serve_forever()
    flag = True

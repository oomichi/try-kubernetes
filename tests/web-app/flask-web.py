from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    pod_name = os.environ.get('MY_POD_NAME', 'NO_POD_NAME')
    return pod_name

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)

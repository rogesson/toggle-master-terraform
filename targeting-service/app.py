import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify(service="targeting-service", status="ok")


@app.get("/")
def index():
    return jsonify(service="targeting-service")


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",  # nosec B104 - required for Kubernetes traffic
        port=int(os.getenv("PORT", "8003")),
    )

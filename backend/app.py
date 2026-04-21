import os
from datetime import datetime, timezone

import psycopg2
from flask import Flask, jsonify


def get_required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def get_connection():
    return psycopg2.connect(
        host=get_required_env("DB_HOST"),
        port=get_required_env("DB_PORT"),
        dbname=get_required_env("DB_NAME"),
        user=get_required_env("DB_USER"),
        password=get_required_env("DB_PASSWORD"),
        sslmode=os.getenv("DB_SSLMODE", "require"),
    )


app = Flask(__name__)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}, 200


@app.get("/api/state")
def api_state():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version, updated_at FROM app_state WHERE id = 1")
            row = cur.fetchone()

    if not row:
        return jsonify({"message": "Hello Lab-commit", "version": "unknown"}), 200

    version, updated_at = row
    if isinstance(updated_at, datetime):
        updated_at = updated_at.astimezone(timezone.utc).isoformat()

    return (
        jsonify(
            {
                "message": "Hello Lab-commit",
                "version": version,
                "updated_at": updated_at,
            }
        ),
        200,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

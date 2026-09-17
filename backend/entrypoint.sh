#!/usr/bin/env sh

set -e

uv run manage.py migrate
uv run uvicorn swordfish.asgi:application --host 0.0.0.0 --port 8000

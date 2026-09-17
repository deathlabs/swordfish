FROM alpine:3.24
LABEL image.authors="Victor Fernandez III, @cyberphor"
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
WORKDIR /home/backend/
COPY checkpoints/ checkpoints/
COPY entrypoint.sh entrypoint.sh
COPY manage.py manage.py
COPY memories/ memories/
COPY swordfish/ swordfish/
COPY pyproject.toml pyproject.toml
COPY uv.lock uv.lock
ENV UV_PYTHON_INSTALL_DIR=/home/backend/.uv-python
RUN apk add --no-cache python3 uv && \
    apk upgrade --no-cache libcrypto3 libssl3 &&\
    uv sync --frozen --python /usr/bin/python3 && \
    uv run python -m pip uninstall pip -y || true &&\
    (apk del wget || true) &&\
    adduser -D swordfish -h /home/backend/ &&\
    chmod u+x /home/backend/entrypoint.sh &&\
    chown -R swordfish:swordfish /home/backend/
ENV PATH="/home/backend/.venv/bin:$PATH"
USER swordfish
EXPOSE 8000
CMD [ "./entrypoint.sh" ]

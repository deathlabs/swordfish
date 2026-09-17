FROM alpine:3.24
LABEL image.authors="Victor Fernandez III, @cyberphor"
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
WORKDIR /home/inference/
COPY swordfish/ swordfish/
COPY pyproject.toml pyproject.toml
COPY uv.lock uv.lock
ENV UV_PYTHON_INSTALL_DIR=/home/inference/.uv-python
RUN apk add --no-cache python3 uv && \
    apk upgrade --no-cache libcrypto3 libssl3 &&\
    uv sync --frozen --python /usr/bin/python3 && \
    uv run python -m pip uninstall pip -y || true &&\
    (apk del wget || true) &&\
    addgroup -g 1000 swordfish &&\
    adduser -D -G swordfish -u 1000 swordfish -h /home/inference/ &&\
    mkdir -p /home/inference/downloads &&\
    chmod ug+rwx,o+rx,g+s /home/inference/downloads &&\
    chown -R swordfish:swordfish /home/inference/
ENV PATH="/home/inference/.venv/bin:$PATH"
USER swordfish
CMD [ "python", "-m", "swordfish.main" ]

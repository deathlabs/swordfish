FROM alpine:3.24 AS stage_1
WORKDIR /home/tools/
RUN apk add --no-cache --update curl &&\
    curl -kL --output emu "https://github.com/deathlabs/emu/releases/download/v4.0.0/emu-linux-amd64" &&\
    chmod +x emu

FROM alpine:3.24
LABEL image.authors="Vic Fernandez III <@cyberphor>"
WORKDIR /home/tools/
COPY --from=stage_1 /home/tools/emu /usr/local/bin/emu
COPY pyproject.toml pyproject.toml
COPY uv.lock uv.lock
ENV UV_PYTHON_INSTALL_DIR=/home/tools/.uv-python
RUN apk add --no-cache python3 git uv && \
    apk upgrade --no-cache libcrypto3 libssl3 &&\
    uv sync --frozen --python /usr/bin/python3 && \
    uv run python -m pip uninstall pip -y || true &&\
    (apk del wget || true) &&\
    addgroup -g 1000 swordfish &&\
    adduser -D -G swordfish -u 1000 swordfish -h /home/tools/ &&\
    mkdir -p /home/tools/downloads &&\
    chmod ug+rwx,o+rx,g+s /home/tools/downloads &&\
    chown -R swordfish:swordfish /home/tools/
ENV PATH="/home/tools/.venv/bin:$PATH"
USER swordfish
EXPOSE 8002
CMD [ "python", "-m", "swordfish.main" ]

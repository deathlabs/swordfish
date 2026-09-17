# Standard library imports.
from base64 import b64decode
from os import environ, path
from ssl import PROTOCOL_TLS_CLIENT, SSLContext
from tempfile import NamedTemporaryFile
from urllib.request import Request, urlopen

from fastmcp.dependencies import CurrentHeaders

# Third party imports.
from fastmcp.tools import tool

# Set and check environment variables.
EMASS_API_URL = environ["EMASS_API_URL"]
DOD_CERTS_PATH = environ["DOD_CERTS_PATH"]
if not path.exists(DOD_CERTS_PATH):
    raise RuntimeError(f"DOD_CERTS_PATH not found: {DOD_CERTS_PATH}")


# Builds SSL context for HTTPS requests made by the FastMCP server.
def _build_ssl_context(public_cert_pem: bytes, private_key_pem: bytes) -> SSLContext:
    ctx = SSLContext(PROTOCOL_TLS_CLIENT)
    ctx.load_verify_locations(DOD_CERTS_PATH)
    with (
        NamedTemporaryFile("wb", delete=False, suffix=".pem") as cert_file,
        NamedTemporaryFile("wb", delete=False, suffix=".pem") as key_file,
    ):
        cert_file.write(public_cert_pem)
        cert_file.flush()
        cert_path = cert_file.name
        key_file.write(private_key_pem)
        key_file.flush()
        key_path = key_file.name
        ctx.load_cert_chain(certfile=cert_path, keyfile=key_path)
    return ctx


# Parses HTTP headers by name.
def _get_headers(headers: dict[str, str], name: str) -> str:
    value = headers.get(name)
    if not value:
        raise ValueError(f"missing required header: {name}")
    return value


# Sends an HTTP GET request to eMASS.
def _emass_get_request(path: str, headers: dict[str, str]) -> dict:
    # api_key = _get_headers(headers, "x-emass-api-key")
    # user_uid = _get_headers(headers, "x-emass-user-uid")
    public_cert_pem = b64decode(_get_headers(headers, "x-emass-public-cert"))
    private_key_pem = b64decode(_get_headers(headers, "x-emass-private-key"))
    ctx = _build_ssl_context(public_cert_pem, private_key_pem)
    request = Request(
        url=f"{EMASS_API_URL}{path}",
        headers={
            # "api-key": api_key,
            # "user-uid": user_uid,
            "accept": "application/json",
            "content-type": "application/json",
        },
    )
    with urlopen(request, context=ctx, timeout=240) as response:
        output = response.read().decode("UTF-8")
        print(output)
        return output


@tool(description="Test connectivity to eMASS.")
def test_connection(
    headers: dict[str, str] | None = None,
) -> dict:
    if headers is None:
        headers = CurrentHeaders()
    response = _emass_get_request("/api", headers)
    return response

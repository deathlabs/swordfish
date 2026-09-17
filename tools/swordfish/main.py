# Local imports.
from swordfish.config import FASTMCP_PORT
from swordfish.server import get_mcp_server


def main():
    """Start the Swordfish MCP server."""
    mcp = get_mcp_server()
    mcp.run(
        transport="streamable-http",
        host="0.0.0.0",
        port=FASTMCP_PORT,
    )


if __name__ == "__main__":
    main()

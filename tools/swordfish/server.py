# Third party imports.
from fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse

# Local imports.
from swordfish.tools import TOOLS


def get_mcp_server() -> FastMCP:
    """Create, config, and return a FastMCP server.

    Returns:
        A FastMCP server instance that is configured with tools.
    """

    # Init a MCP server.
    mcp = FastMCP(name="swordfish")

    # Register tools with the MCP server.
    for tool in TOOLS:
        mcp.add_tool(tool)

    @mcp.custom_route("/api/v1/healthcheck", methods=["GET"])
    async def health_check(request: Request) -> JSONResponse:
        """Respond to service health checks.

        Returns:
            A JSON-based response that indicates the service is running.
        """
        return JSONResponse(content={"status": "ok"})

    return mcp

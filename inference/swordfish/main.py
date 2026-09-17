# Standard library imports.
from contextlib import asynccontextmanager
from os import environ

# Third party imports.
from ag_ui_langgraph import add_langgraph_fastapi_endpoint
from copilotkit import LangGraphAGUIAgent
from fastapi import FastAPI
from langchain.agents import create_agent

# Local imports.
from memory.long_term import DjangoStore
from memory.short_term import DjangoCheckpointSaver
from models import get_model_client
from prompts.system_prompt import get_system_prompt

from tools import get_environment_tools, get_memory_tools

# Get environment variables.
MODEL_PROVIDER = environ["MODEL_PROVIDER"]
TOOLS_ENDPOINT = environ["TOOLS_ENDPOINT"]

# Init a FastAPI server.
api = FastAPI()


@asynccontextmanager
async def lifespan(app: FastAPI):
    memory_tools = get_memory_tools()
    environment_tools = await get_environment_tools(url=TOOLS_ENDPOINT)
    agent = create_agent(
        model=get_model_client(model_provider=MODEL_PROVIDER),
        tools=memory_tools + environment_tools,
        system_prompt=get_system_prompt(),
        # context_schema=ContextSchema,
        checkpointer=DjangoCheckpointSaver(),
        store=DjangoStore(),
    )
    add_langgraph_fastapi_endpoint(
        app=app,
        agent=LangGraphAGUIAgent(
            name="swordfish",
            description="An agent.",
            graph=agent,
        ),
        path="/api/v1",
    )
    yield


api.router.lifespan_context = lifespan

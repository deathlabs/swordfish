# Agents
 
## Azure GPT-4o
```bash
export AZURE_TENANT_ID="<INSERT_VALUE>"
export AZURE_CLIENT_ID="<INSERT_VALUE>"
export AZURE_CLIENT_SECRET="<INSERT_VALUE>"
 
export AZURE_CLOUD="<INSERT_VALUE>"
export AZURE_TOKEN_SCOPES="https://cognitiveservices.azure.us/.default"
 
export AZURE_OPENAI_ENDPOINT="https://<INSERT_VALUE>.openai.azure.us/"
export AZURE_OPENAI_API_VERSION="<INSERT_VALUE>"
export AZURE_OPENAI_DEPLOYMENT="swordfish"
export MCP_SERVER_ENDPOINT="http://swordfish-tools:8282/sse"
```

# Architecture
Swordfish is composed of three components: a frontend, backend, and MCP server.

## Frontend

The frontend container serves the user-facing interface. It is the entry point for all user interaction — queries are composed here and results are rendered here. It communicates exclusively with the backend; it has no direct knowledge of the LLM or eMASS.

## Backend

The backend container is the core of the system. It receives requests from the frontend, manages sessions, and acts as the broker between the user and the external LLM. It is responsible for:

- Forwarding user queries to the configured LLM provider
- Passing LLM tool calls through to the MCP server
- Returning structured results back to the frontend

The backend does not query eMASS directly — all eMASS I/O is delegated to the MCP server.

## MCP Server

The MCP server exposes eMASS as a set of tools that the LLM can call. When the LLM determines that a user's request requires reading or writing data in eMASS, it issues a tool call which the backend routes to the MCP server. The MCP server translates that call into the appropriate eMASS API request, then returns the result back up the chain.

This design keeps eMASS credentials and API logic isolated in a single container and makes the tool surface independently testable.

# Data Flow

A typical request follows this path:

1. The user types a question in the frontend
2. The frontend sends it to the backend
3. The backend forwards it to the external LLM with the available MCP tools in context
4. The LLM responds - either with a direct answer, or with one or more tool calls
5. Tool calls are routed to the MCP server, which reads from or writes to eMASS
6. Results are returned to the LLM to complete its response
7. The final answer is passed back through the backend to the frontend

# Design Principles

**Separation of concerns.**  
Each container has a single, well-defined responsibility. The frontend knows about the user. The backend knows about the LLM. The MCP server knows about eMASS.

**LLM-agnostic backend.**  
The backend is not coupled to a specific LLM provider. The external LLM is a configuration concern, not an architectural one.

**eMASS as a tool surface.**  
Rather than building bespoke query logic, swordfish exposes eMASS operations as MCP tools. This means the LLM drives what gets read or written based on user intent, without the backend needing to anticipate every possible query shape.

# Infrastructure

## Azure
 
**Step 1.** Deploy cloud resources using Infrastructure-as-Code. Said resources must ensure there is an Azure OpenAI (AOAI) service with a deployment specific for your project.
 
**Step 2.** Activate your Owner role on the AOAI service and then, login to Azure via CLI.
```bash
az login --use-device-code
```
 
**Step 3.** Get the client ID and client secret for your Service Principal and then add them as environment variables to your project.
 
**Step 4.** Get the object ID of service principal.
```bash
export OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query id -o tsv)
```
 
**Step 5.** Get the resource ID of Azure OpenAI service.
```bash
export RESOURCE_ID=$(az cognitiveservices account show \
  --name $AOAI_SERVICE_NAME \
  --resource-group $AOAI_SERVICE_RESOURCE_GROUP \
  --query id -o tsv)
```
 
**Step 6.** Assign the service principal the "Cognitive Services OpenAI User" role on the object ID.
```bash
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Cognitive Services OpenAI User" \
  --scope $RESOURCE_ID
```
 
**Step 7.** Assign the service principal the "Cognitive Services OpenAI Contributor" role on the object ID.
```bash
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Cognitive Services OpenAI Contributor" \
  --scope $RESOURCE_ID
```
 
**Step 8.** Run your project. Running your project should include executing code that authenticates with the AOAI service as your Service Principal.
 
## References
* [Compare Azure Government and global Azure](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure)
* [How to switch between OpenAI and Azure OpenAI endpoints](https://learn.microsoft.com/en-us/azure/developer/ai/how-to/switching-endpoints?tabs=azure-openai&pivots=python)

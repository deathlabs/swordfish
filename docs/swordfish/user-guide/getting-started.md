# Getting Started

This guide walks you through running `swordfish` locally. You will need an eMASS API key, and credentials for a supported LLM provider. 

## Agent
```bash
export AZURE_TENANT_ID="<REPLACE_ME>"
export AZURE_CLIENT_ID="<REPLACE_ME>"
export AZURE_CLIENT_SECRET="<REPLACE_ME>"

export AZURE_CLOUD="<REPLACE_ME>"
export AZURE_AUTHORITY_HOSTS="<REPLACE_ME>"
export AZURE_TOKEN_SCOPES="https://cognitiveservices.azure.<REPLACE_ME>/.default"

export AZURE_OPENAI_ENDPOINT="https://<REPLACE_ME>.openai.azure.<REPLACE_ME>/"
export AZURE_OPENAI_API_VERSION="<REPLACE_ME>"
export AZURE_OPENAI_DEPLOYMENT="swordfish"
export MCP_SERVER_ENDPOINT="http://swordfish-tools:8282/mcp"
```

## Tools
```bash
export EMASS_API_URL="<REPLACE_ME>"
export EMASS_API_KEY="<REPLACE_ME>"
export EMASS_API_UID="<REPLACE_ME>"
export SERPER_API_KEY="<REPLACE_ME>"
```

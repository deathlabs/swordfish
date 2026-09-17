# Standard library imports.

# Third party imports.
from ninja import Query, Router

# Local imports.
from memories.models import Memory
from memories.schemas import MemoryCreateSchema, MemorySchema, NotFoundResponseSchema

# Init the memories API.
memories_router = Router(tags=["references"])


@memories_router.get("/", response={200: MemorySchema, 404: NotFoundResponseSchema})
def get_memory(request, namespace: list[str], key: str):
    try:
        return 200, Memory.objects.get(namespace=namespace, key=key)
    except Memory.DoesNotExist:
        return 404, {"message": "memory not found"}


@memories_router.get("/search/", response=list[MemorySchema])
def search_memories(
    request,
    namespace_prefix: list[str] = Query(...),
    query: str | None = None,
    limit: int = 10,
    offset: int = 0,
):
    memories = Memory.objects.filter(namespace__0=namespace_prefix[0])
    return memories.order_by("-updated_at")[offset : offset + limit]


@memories_router.post("/", response={201: MemoryCreateSchema})
def create_memory(request, payload: MemoryCreateSchema):
    memory, _ = Memory.objects.update_or_create(
        namespace=payload.namespace,
        key=payload.key,
        defaults={"value": payload.value},
    )
    return 201, memory


@memories_router.delete("/", response={204: None, 404: NotFoundResponseSchema})
def delete_memory(request, namespace: list[str], key: str):
    try:
        Memory.objects.get(namespace=namespace, key=key).delete()
        return 204, None
    except Memory.DoesNotExist:
        return 404, {"message": "memory not found"}

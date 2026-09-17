# Standard library imports.

# Third party imports.
from ninja import Router

# Local imports.
from checkpoints.models import Checkpoint
from checkpoints.schemas import (
    CheckpointSchema,
    NotFoundResponseSchema,
)

# Init the references router.
checkpoints_router = Router(tags=["checkpoints"])


@checkpoints_router.get(
    "/{thread_id}/", response={200: CheckpointSchema, 404: NotFoundResponseSchema}
)
def get_chat(request, thread_id: str, checkpoint_id: str | None = None):
    try:
        checkpoints = Checkpoint.objects.filter(thread_id=thread_id)
        if checkpoint_id:
            checkpoints = checkpoints.filter(checkpoint_id=checkpoint_id)
        return 200, checkpoints.latest("updated_at")
    except Checkpoint.DoesNotExist:
        return 404, {"message": "chat not found"}


@checkpoints_router.get("/", response=list[CheckpointSchema])
def list_chats(request, thread_id: str | None = None):
    checkpoints = Checkpoint.objects.all()
    if thread_id:
        checkpoints = checkpoints.filter(thread_id=thread_id)
    return checkpoints.order_by("-updated_at")


@checkpoints_router.post("/", response={201: CheckpointSchema})
def create_chat(request, payload: CheckpointSchema):
    checkpoint, _ = Checkpoint.objects.update_or_create(
        checkpoint_id=payload.checkpoint_id,
        defaults=payload.dict(exclude={"checkpoint_id"}),
    )
    return 201, checkpoint

# Standard library imports.
# Local imports.
from django.urls import path
from ninja import NinjaAPI

from checkpoints.router import checkpoints_router
from memories.router import memories_router

from .health import api as health_api

api = NinjaAPI()
api.add_router("/health/", health_api)
api.add_router("/checkpoints/", checkpoints_router)
api.add_router("/memories", memories_router)


urlpatterns = [
    path("api/v1/", api.urls),
]

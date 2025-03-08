# app/core/api_response.py
from fastapi.responses import JSONResponse
from fastapi import status
from typing import Any, Dict, List, Optional, Union
from ..utils.json_utils import MongoJSONEncoder
import json

class CustomJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder that handles MongoDB types."""
    def default(self, obj):
        return MongoJSONEncoder.encode_mongo_data(obj)

class MongoJSONResponse(JSONResponse):
    """Custom API response that handles MongoDB types."""
    def render(self, content: Any) -> bytes:
        """Override render to use custom JSON encoder."""
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(",", ":"),
            cls=CustomJSONEncoder,
        ).encode("utf-8")

def success_response(
    data: Any = None,
    message: str = "Success",
    status_code: int = status.HTTP_200_OK,
) -> MongoJSONResponse:
    """Create a standardized success response."""
    content = {
        "status": "success",
        "message": message,
        "data": data
    }
    return MongoJSONResponse(content=content, status_code=status_code)

def error_response(
    message: str = "An error occurred",
    status_code: int = status.HTTP_400_BAD_REQUEST,
    errors: Optional[List[Dict[str, Any]]] = None,
) -> MongoJSONResponse:
    """Create a standardized error response."""
    content = {
        "status": "error",
        "message": message,
    }
    if errors:
        content["errors"] = errors
    return MongoJSONResponse(content=content, status_code=status_code)
---
paths: "**/*.py"
---

# Python Rules

## Style

- Python 3.11+ features encouraged
- Type hints required for function signatures
- Use `ruff` for linting and formatting
- Follow PEP 8 conventions

---

## Type Hints

```python
from typing import Optional, TypeVar, Generic
from collections.abc import Callable, Sequence

def process_items(
    items: Sequence[str],
    transformer: Callable[[str], str] | None = None,
) -> list[str]:
    ...
```

---

## Validation with Pydantic

```python
from pydantic import BaseModel, EmailStr, Field

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=0, le=150)

    model_config = {"strict": True}
```

---

## FastAPI Patterns

```python
from fastapi import FastAPI, HTTPException, Depends

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: Database = Depends(get_db),
) -> UserResponse:
    user = await db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)
```

---

## Error Handling

```python
# Custom exceptions
class UserNotFoundError(Exception):
    def __init__(self, user_id: int):
        self.user_id = user_id
        super().__init__(f"User {user_id} not found")

# Context managers for cleanup
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_connection():
    conn = await create_connection()
    try:
        yield conn
    finally:
        await conn.close()
```

---

## Testing with pytest

```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client(app):
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.mark.asyncio
async def test_get_user(client: AsyncClient):
    response = await client.get("/users/1")
    assert response.status_code == 200
    assert response.json()["id"] == 1
```

---

## Async Best Practices

- Use `asyncio.gather` for concurrent operations
- Avoid mixing sync and async code
- Use `httpx` over `requests` for async HTTP
- Prefer `asyncio.TaskGroup` (Python 3.11+)

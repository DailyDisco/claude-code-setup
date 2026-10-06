---
name: stack-python
description: Set up Python project with FastAPI, Pydantic, and modern tooling. Use when bootstrapping Python services or APIs.
allowed-tools: Read, Write, Edit, Bash(python:*), Bash(pip:*), Bash(uv:*), Bash(ruff:*), Bash(pytest:*), Glob
context-files:
  - ~/.config/agent-config/rules/python.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Python Stack Setup

Configure Python projects with modern, production-ready patterns.

## When to Use

- New Python API/service setup
- Adding FastAPI to existing project
- Configuring Pydantic validation
- Setting up testing with pytest
- Modernizing Python project structure

## Hard Rules

1. ALWAYS use type hints for function signatures
2. ALWAYS validate external data with Pydantic
3. NEVER use mutable default arguments
4. ALWAYS use async for I/O-bound operations in FastAPI
5. ALWAYS use dependency injection for testability
6. PREFER `uv` or `poetry` over raw pip

## Process

### Phase 1: Initialize Project

```bash
# Using uv (recommended)
uv init myapp
cd myapp
uv venv
source .venv/bin/activate

# Or using pip
python -m venv .venv
source .venv/bin/activate
pip install -U pip
```

### Phase 2: Project Structure

```
myapp/
├── src/
│   └── app/
│       ├── __init__.py
│       ├── main.py               # FastAPI app entry
│       ├── config.py             # Settings with Pydantic
│       ├── dependencies.py       # FastAPI dependencies
│       ├── models/
│       │   ├── __init__.py
│       │   ├── user.py           # Pydantic models
│       │   └── database.py       # SQLAlchemy models
│       ├── routes/
│       │   ├── __init__.py
│       │   ├── users.py
│       │   └── health.py
│       ├── services/
│       │   └── user_service.py
│       └── repositories/
│           └── user_repository.py
├── tests/
│   ├── conftest.py
│   └── test_users.py
├── migrations/
├── pyproject.toml
├── Dockerfile
└── .env.example
```

### Phase 3: pyproject.toml

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn[standard]>=0.27.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "sqlalchemy>=2.0.0",
    "asyncpg>=0.29.0",
    "alembic>=1.13.0",
    "httpx>=0.26.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "ruff>=0.1.0",
    "mypy>=1.8.0",
]

[tool.ruff]
target-version = "py311"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "ASYNC"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[tool.mypy]
python_version = "3.11"
strict = true
```

### Phase 4: Core Patterns

#### Configuration (src/app/config.py)

```python
from functools import lru_cache
from pydantic import PostgresDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "MyApp"
    debug: bool = False
    database_url: PostgresDsn
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 30

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        return v


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

#### Main Application (src/app/main.py)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routes import health, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield  # startup / shutdown


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(title=settings.app_name, debug=settings.debug, lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if settings.debug else ["https://myapp.com"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router, tags=["Health"])
    app.include_router(users.router, prefix="/api/v1", tags=["Users"])

    return app


app = create_app()
```

#### Pydantic Models (src/app/models/user.py)

```python
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, ConfigDict


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str = Field(min_length=1, max_length=100)


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    created_at: datetime
```

#### SQLAlchemy Models (src/app/models/database.py)

```python
from datetime import datetime
from sqlalchemy import String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    hashed_password: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
```

#### Dependencies (src/app/dependencies.py)

```python
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings, Settings
from app.database import get_db


security = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
):
    # Verify token and return user
    ...


CurrentUser = Annotated[..., Depends(get_current_user)]
DbSession = Annotated[AsyncSession, Depends(get_db)]
```

#### Routes (src/app/routes/users.py)

```python
from fastapi import APIRouter, HTTPException, status

from app.dependencies import DbSession
from app.models.user import UserCreate, UserResponse
from app.services.user_service import UserService


router = APIRouter(prefix="/users")


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(data: UserCreate, db: DbSession) -> UserResponse:
    service = UserService(db)

    existing = await service.get_by_email(data.email)
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")

    return await service.create(data)
```

### Phase 5: Testing

#### Fixtures (tests/conftest.py)

```python
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db
from app.models.database import Base


@pytest.fixture
async def db_session():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session

    await engine.dispose()


@pytest.fixture
async def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
```

#### Tests (tests/test_users.py)

```python
import pytest


@pytest.mark.asyncio
async def test_create_user(client):
    response = await client.post(
        "/api/v1/users",
        json={"email": "test@example.com", "password": "password123", "name": "Test"},
    )
    assert response.status_code == 201
    assert response.json()["email"] == "test@example.com"
```

### Phase 6: Dockerfile

```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
RUN pip install uv
COPY pyproject.toml ./
RUN uv pip install --system --no-cache .
COPY src/ ./src/

FROM python:3.11-slim
WORKDIR /app
RUN addgroup --gid 1001 app && adduser --uid 1001 --gid 1001 app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app/src ./src
USER app
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Output Format

```markdown
## Python Project Setup: [name]

### Created Structure
- src/app/ - Application package
- src/app/routes/ - API endpoints
- src/app/models/ - Pydantic & SQLAlchemy models
- src/app/services/ - Business logic
- tests/ - Pytest test suite

### Available Commands

| Command | Description |
|---------|-------------|
| uvicorn app.main:app --reload | Start dev server |
| pytest | Run tests |
| ruff check . | Lint code |
| mypy src | Type check |

### Next Steps
1. Copy .env.example to .env
2. Set DATABASE_URL
3. Run `alembic upgrade head`
4. Run `uvicorn app.main:app --reload`
```

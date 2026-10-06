---
name: stack-go
description: Set up Go project structure and patterns. Use when bootstrapping Go services or reviewing Go architecture.
allowed-tools: Read, Write, Edit, Bash(go:*), Bash(make:*), Glob
context-files:
  - ~/.config/agent-config/rules/go.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Go Stack Setup

Configure Go projects with production-ready patterns.

## When to Use

- New Go service/API setup
- Reviewing project structure
- Adding standard patterns (error handling, logging, config)
- Setting up Chi router with middleware
- Configuring GORM with PostgreSQL

## Hard Rules

1. ALWAYS use `internal/` for private packages
2. ALWAYS wrap errors with context using `fmt.Errorf("context: %w", err)`
3. NEVER ignore errors — handle or explicitly ignore with `_`
4. ALWAYS use structured logging (slog or zerolog)
5. ALWAYS validate config at startup, fail fast
6. PREFER composition over inheritance

## Process

### Phase 1: Initialize Project

```bash
# Create module
mkdir myapp && cd myapp
go mod init github.com/user/myapp

# Install core dependencies
go get github.com/go-chi/chi/v5
go get github.com/go-chi/chi/v5/middleware
go get gorm.io/gorm
go get gorm.io/driver/postgres
go get github.com/go-playground/validator/v10
```

### Phase 2: Project Structure

```
myapp/
├── cmd/
│   └── api/
│       └── main.go              # Entry point, minimal logic
├── internal/
│   ├── config/
│   │   └── config.go            # Configuration loading
│   ├── database/
│   │   └── database.go          # DB connection & migrations
│   ├── handlers/
│   │   ├── handlers.go          # HTTP handlers
│   │   └── middleware.go        # Custom middleware
│   ├── models/
│   │   └── user.go              # Domain models (GORM)
│   ├── repository/
│   │   └── user_repository.go   # Data access layer
│   └── services/
│       └── user_service.go      # Business logic
├── pkg/                          # Public, reusable packages
│   └── response/
│       └── json.go              # HTTP response helpers
├── migrations/
│   └── 001_create_users.up.sql
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
└── .env.example
```

### Phase 3: Core Patterns

#### Configuration (internal/config/config.go)

```go
package config

import (
    "fmt"
    "os"
    "strconv"
)

type Config struct {
    Port        int
    DatabaseURL string
    JWTSecret   string
    Environment string
}

func Load() (*Config, error) {
    port, err := strconv.Atoi(getEnv("PORT", "8080"))
    if err != nil {
        return nil, fmt.Errorf("invalid PORT: %w", err)
    }

    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        return nil, fmt.Errorf("DATABASE_URL is required")
    }

    return &Config{
        Port:        port,
        DatabaseURL: dbURL,
        JWTSecret:   mustGetEnv("JWT_SECRET"),
        Environment: getEnv("ENVIRONMENT", "development"),
    }, nil
}

func getEnv(key, fallback string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return fallback
}

func mustGetEnv(key string) string {
    value := os.Getenv(key)
    if value == "" {
        panic(fmt.Sprintf("%s is required", key))
    }
    return value
}
```

#### Main Entry Point (cmd/api/main.go)

```go
package main

import (
    "context"
    "fmt"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"

    "github.com/user/myapp/internal/config"
    "github.com/user/myapp/internal/database"
    "github.com/user/myapp/internal/handlers"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    slog.SetDefault(logger)

    cfg, err := config.Load()
    if err != nil {
        slog.Error("failed to load config", "error", err)
        os.Exit(1)
    }

    db, err := database.Connect(cfg.DatabaseURL)
    if err != nil {
        slog.Error("failed to connect database", "error", err)
        os.Exit(1)
    }

    r := chi.NewRouter()
    r.Use(middleware.RequestID)
    r.Use(middleware.RealIP)
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(middleware.Timeout(30 * time.Second))

    handlers.Register(r, db)

    srv := &http.Server{
        Addr:         fmt.Sprintf(":%d", cfg.Port),
        Handler:      r,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    go func() {
        slog.Info("server starting", "port", cfg.Port)
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            slog.Error("server error", "error", err)
            os.Exit(1)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    slog.Info("shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        slog.Error("server shutdown error", "error", err)
    }
    slog.Info("server stopped")
}
```

#### Error Handling Pattern

```go
package apperror

import "fmt"

type AppError struct {
    Code    string
    Message string
    Err     error
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

func (e *AppError) Unwrap() error {
    return e.Err
}

var (
    ErrNotFound     = &AppError{Code: "NOT_FOUND", Message: "resource not found"}
    ErrUnauthorized = &AppError{Code: "UNAUTHORIZED", Message: "unauthorized"}
)

func Wrap(err error, message string) *AppError {
    return &AppError{Code: "INTERNAL", Message: message, Err: err}
}
```

#### HTTP Response Helpers

```go
package response

import (
    "encoding/json"
    "net/http"
)

func JSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func Error(w http.ResponseWriter, status int, code, message string) {
    JSON(w, status, map[string]any{
        "error": map[string]string{"code": code, "message": message},
    })
}
```

#### Repository Pattern

```go
package repository

import (
    "context"
    "errors"

    "gorm.io/gorm"
    "github.com/user/myapp/internal/models"
)

type UserRepository struct {
    db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
    return r.db.WithContext(ctx).Create(user).Error
}

func (r *UserRepository) FindByID(ctx context.Context, id uint) (*models.User, error) {
    var user models.User
    err := r.db.WithContext(ctx).First(&user, id).Error
    if errors.Is(err, gorm.ErrRecordNotFound) {
        return nil, nil
    }
    return &user, err
}
```

### Phase 4: Makefile

```makefile
.PHONY: run build test lint migrate clean

run:
	go run cmd/api/main.go

build:
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/api cmd/api/main.go

test:
	go test -race -v ./...

test-cover:
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint:
	golangci-lint run

migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

migrate-create:
	migrate create -ext sql -dir migrations -seq $(name)

docker-build:
	docker build -t myapp:latest .

clean:
	rm -rf bin/ coverage.out coverage.html
```

### Phase 5: Dockerfile

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /api cmd/api/main.go

FROM alpine:3.19
RUN addgroup -g 1001 app && adduser -u 1001 -G app -s /bin/sh -D app
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /api /api
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
ENTRYPOINT ["/api"]
```

## Testing Patterns

```go
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        wantCode int
    }{
        {"valid", `{"email":"test@example.com"}`, http.StatusCreated},
        {"invalid", `{"email":"bad"}`, http.StatusBadRequest},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest(http.MethodPost, "/users", strings.NewReader(tt.input))
            req.Header.Set("Content-Type", "application/json")
            rec := httptest.NewRecorder()
            handler.ServeHTTP(rec, req)
            assert.Equal(t, tt.wantCode, rec.Code)
        })
    }
}
```

## Output Format

```markdown
## Go Project Setup: [name]

### Created Structure
- cmd/api/main.go - Entry point with graceful shutdown
- internal/config/ - Environment-based configuration
- internal/handlers/ - HTTP handlers with Chi
- internal/models/ - GORM models
- internal/repository/ - Data access layer

### Available Commands

| Command | Description |
|---------|-------------|
| make run | Start development server |
| make test | Run tests with race detection |
| make lint | Run golangci-lint |
| make migrate-up | Apply migrations |

### Next Steps
1. Copy .env.example to .env
2. Set DATABASE_URL and JWT_SECRET
3. Run `make migrate-up`
4. Run `make run`
```

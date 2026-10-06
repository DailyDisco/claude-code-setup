---
paths: "**/*.go"
---

# Go Rules

Apply these rules when working with Go code.

---

## Project Structure

```
project/
├── cmd/                    # Application entrypoints
│   └── api/
│       └── main.go
├── internal/               # Private application code
│   ├── handler/            # HTTP handlers
│   ├── service/            # Business logic
│   ├── repository/         # Data access
│   └── middleware/         # HTTP middleware
├── pkg/                    # Public reusable packages
├── migrations/             # Database migrations
├── config/                 # Configuration loading
└── go.mod
```

---

## Error Handling

- **Always handle errors explicitly** - never ignore with `_`
- Wrap errors with context using `fmt.Errorf("context: %w", err)`
- Use sentinel errors for expected conditions
- Return errors, don't panic (except truly unrecoverable)

```go
// Good
if err != nil {
    return fmt.Errorf("failed to fetch user %d: %w", userID, err)
}

// Bad
result, _ := doSomething()  // Never ignore errors
```

### Error Types

```go
// Sentinel errors for expected conditions
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrValidation   = errors.New("validation failed")
)

// Check with errors.Is
if errors.Is(err, ErrNotFound) {
    return c.JSON(404, map[string]string{"error": "not found"})
}
```

---

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Packages | lowercase, short, no underscores | `handler`, `userservice` |
| Interfaces | `-er` suffix when single method | `Reader`, `UserService` |
| Unexported | camelCase | `userID`, `maxRetries` |
| Exported | PascalCase | `UserID`, `MaxRetries` |
| Constants | PascalCase (not SCREAMING_CASE) | `DefaultTimeout` |
| Acronyms | All caps or all lower | `userID`, `HTTPClient` |

---

## HTTP Handlers (Chi)

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    userID := chi.URLParam(r, "id")

    user, err := h.userService.GetByID(ctx, userID)
    if err != nil {
        if errors.Is(err, service.ErrNotFound) {
            http.Error(w, "user not found", http.StatusNotFound)
            return
        }
        h.logger.Error().Err(err).Str("user_id", userID).Msg("failed to get user")
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### Route Organization

```go
func (h *Handler) Routes() chi.Router {
    r := chi.NewRouter()

    r.Use(middleware.RequestID)
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)

    r.Route("/api/v1", func(r chi.Router) {
        r.Route("/users", func(r chi.Router) {
            r.Get("/", h.ListUsers)
            r.Post("/", h.CreateUser)
            r.Route("/{id}", func(r chi.Router) {
                r.Get("/", h.GetUser)
                r.Put("/", h.UpdateUser)
                r.Delete("/", h.DeleteUser)
            })
        })
    })

    return r
}
```

---

## Database (GORM)

### Model Definition

```go
type User struct {
    ID        uint           `gorm:"primaryKey"`
    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt gorm.DeletedAt `gorm:"index"`

    Email     string `gorm:"uniqueIndex;not null"`
    Name      string `gorm:"not null"`
    Role      string `gorm:"default:user"`
}
```

### Repository Pattern

```go
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id uint) (*User, error)
    GetByEmail(ctx context.Context, email string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id uint) error
}

type userRepository struct {
    db *gorm.DB
}

func (r *userRepository) GetByID(ctx context.Context, id uint) (*User, error) {
    var user User
    if err := r.db.WithContext(ctx).First(&user, id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("get user by id: %w", err)
    }
    return &user, nil
}
```

### Transaction Handling

```go
func (s *Service) TransferFunds(ctx context.Context, fromID, toID uint, amount int64) error {
    return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
        if err := tx.Model(&Account{}).Where("id = ?", fromID).
            Update("balance", gorm.Expr("balance - ?", amount)).Error; err != nil {
            return err
        }

        if err := tx.Model(&Account{}).Where("id = ?", toID).
            Update("balance", gorm.Expr("balance + ?", amount)).Error; err != nil {
            return err
        }

        return nil
    })
}
```

---

## Context Usage

- Pass `context.Context` as first parameter
- Use for cancellation, timeouts, and request-scoped values
- Don't store context in structs

```go
// Good
func (s *Service) Process(ctx context.Context, data *Data) error {
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()

    return s.repo.Save(ctx, data)
}
```

---

## Concurrency

### Goroutines with Error Handling

```go
func ProcessItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item  // Capture loop variable
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}
```

---

## Configuration

Use `envconfig` for environment-based configuration:

```go
type Config struct {
    Port        int           `envconfig:"PORT" default:"8080"`
    DatabaseURL string        `envconfig:"DATABASE_URL" required:"true"`
    LogLevel    string        `envconfig:"LOG_LEVEL" default:"info"`
    Timeout     time.Duration `envconfig:"TIMEOUT" default:"30s"`
}

func LoadConfig() (*Config, error) {
    var cfg Config
    if err := envconfig.Process("", &cfg); err != nil {
        return nil, fmt.Errorf("load config: %w", err)
    }
    return &cfg, nil
}
```

---

## Logging (zerolog)

```go
import "github.com/rs/zerolog/log"

// Structured logging
log.Info().
    Str("user_id", userID).
    Str("action", "login").
    Msg("user logged in")

// Error logging with context
log.Error().
    Err(err).
    Str("user_id", userID).
    Str("operation", "create_order").
    Msg("failed to create order")
```

---

## Testing

### Table-Driven Tests

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"missing @", "userexample.com", true},
        {"empty", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidateEmail(%q) error = %v, wantErr %v", tt.email, err, tt.wantErr)
            }
        })
    }
}
```

### Using testify

```go
func TestUserService_Create(t *testing.T) {
    repo := &mockUserRepository{}
    svc := NewUserService(repo)

    user := &User{Email: "test@example.com", Name: "Test"}
    err := svc.Create(context.Background(), user)

    require.NoError(t, err)
    assert.NotZero(t, user.ID)
    assert.Equal(t, "test@example.com", user.Email)
}
```

---

## Validation

Use `go-playground/validator`:

```go
type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required,min=8"`
    Name     string `json:"name" validate:"required,min=2,max=100"`
    Age      int    `json:"age" validate:"omitempty,gte=0,lte=150"`
}
```

---

## Performance Tips

- Use `sync.Pool` for frequently allocated objects
- Preallocate slices when size is known: `make([]T, 0, capacity)`
- Use `strings.Builder` for string concatenation
- Profile before optimizing: `go test -bench=. -cpuprofile=cpu.out`
- Use `go vet` and `staticcheck` in CI

---

## Common Anti-Patterns

| Anti-Pattern | Better Alternative |
|--------------|-------------------|
| `panic` for errors | Return `error` |
| Naked goroutines | Use `errgroup` or track with `WaitGroup` |
| Global state | Dependency injection |
| `interface{}` everywhere | Generics or specific types |
| Ignoring context cancellation | Check `ctx.Done()` in loops |
| Large interfaces | Small, focused interfaces |

---
paths: "**/{Dockerfile*,docker-compose*,*.dockerfile,compose.{yml,yaml}}"
---

# Docker Rules

Apply these rules when building containers and orchestrating services.

---

## Multi-Stage Builds

Always use multi-stage builds to minimize image size and attack surface.

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production
WORKDIR /app
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER appuser
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## Layer Caching

Order instructions from least to most frequently changing:

```dockerfile
# 1. Base image (rarely changes)
FROM node:20-alpine

# 2. System dependencies (rarely changes)
RUN apk add --no-cache git

# 3. Application dependencies (changes sometimes)
COPY package*.json ./
RUN npm ci

# 4. Application code (changes frequently)
COPY . .
RUN npm run build
```

---

## Security Scanning

- Scan images in CI/CD before pushing
- Use minimal base images (`alpine`, `distroless`, `scratch`)
- Never run as root in production
- Don't store secrets in images

```dockerfile
# Create non-root user
RUN addgroup -g 1001 app && adduser -u 1001 -G app -s /bin/sh -D app
USER app

# Pin specific version (not latest)
FROM node:20.10.0-alpine
```

### Scanning Commands

```bash
trivy image myapp:latest
docker scout cves myapp:latest
snyk container test myapp:latest
```

---

## Image Size Optimization

| Technique | Impact |
|-----------|--------|
| Multi-stage builds | High |
| Alpine/distroless base | High |
| .dockerignore | Medium |
| Remove dev dependencies | Medium |

### .dockerignore

```
node_modules
.git
.env*
*.md
tests
coverage
Dockerfile*
docker-compose*
```

---

## Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
```

---

## Compose Best Practices

```yaml
services:
  app:
    build:
      context: .
      target: production
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: 512M

  db:
    image: postgres:16-alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]

volumes:
  db_data:
```

---

## Production Checklist

- [ ] Multi-stage build
- [ ] Non-root user
- [ ] Pinned base image version
- [ ] Health check defined
- [ ] .dockerignore configured
- [ ] No secrets in image
- [ ] Security scan passed
- [ ] Resource limits set

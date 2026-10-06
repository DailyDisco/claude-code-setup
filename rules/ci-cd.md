---
paths: ".github/workflows/*.yml"
---

# CI/CD Rules

## GitHub Actions Best Practices

### Workflow Structure

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

# Cancel in-progress runs for the same branch
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run linters
        run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint  # Run after lint passes
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]  # Run after both pass
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: npm run build
```

---

## Caching

### Node.js
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

# Or manual caching for more control
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Go
```yaml
- uses: actions/setup-go@v5
  with:
    go-version: '1.22'
    cache: true
```

### Python
```yaml
- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'
```

### Docker layers
```yaml
- uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## Secrets Management

```yaml
# Use GitHub Secrets (Settings > Secrets)
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  API_KEY: ${{ secrets.API_KEY }}

# Use OIDC for cloud providers (no long-lived secrets)
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-arn: arn:aws:iam::123456789:role/GitHubActionsRole
    aws-region: us-east-1
```

**Rules:**
- Never hardcode secrets in workflows
- Use environment-specific secrets (`PROD_API_KEY`, `STAGING_API_KEY`)
- Rotate secrets regularly
- Use OIDC where supported (AWS, GCP, Azure)

---

## Environment Protection

```yaml
jobs:
  deploy-staging:
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - run: deploy-to-staging.sh

  deploy-production:
    environment: production  # Requires approval
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      - run: deploy-to-production.sh
```

Configure in Settings > Environments:
- Required reviewers for production
- Wait timer before deployment
- Branch restrictions

---

## Matrix Builds

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false  # Continue other jobs if one fails
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node-version: [18, 20, 22]
        exclude:
          - os: windows-latest
            node-version: 18
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
```

---

## Reusable Workflows

```yaml
# .github/workflows/reusable-build.yml
name: Reusable Build

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building for ${{ inputs.environment }}"
```

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-build.yml
    with:
      environment: staging
    secrets:
      deploy_key: ${{ secrets.STAGING_KEY }}
```

---

## Deployment Strategies

### Blue-Green
```yaml
deploy:
  steps:
    - name: Deploy to green
      run: |
        deploy-to-green.sh
        health-check.sh green

    - name: Switch traffic
      run: switch-traffic.sh green

    - name: Cleanup blue
      run: cleanup-blue.sh
```

### Canary
```yaml
deploy:
  steps:
    - name: Deploy canary (10%)
      run: deploy-canary.sh 10

    - name: Monitor metrics
      run: |
        sleep 300
        check-error-rates.sh

    - name: Full rollout
      run: deploy-canary.sh 100
```

### Rolling
```yaml
deploy:
  strategy:
    matrix:
      region: [us-east, us-west, eu-west]
    max-parallel: 1  # Deploy one region at a time
  steps:
    - run: deploy-to-region.sh ${{ matrix.region }}
```

---

## Docker Build & Push

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch
            type=semver,pattern={{version}}

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## Database Migrations

```yaml
migrate:
  runs-on: ubuntu-latest
  environment: production
  steps:
    - uses: actions/checkout@v4

    # Backup before migration
    - name: Backup database
      run: |
        pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql
      env:
        DATABASE_URL: ${{ secrets.DATABASE_URL }}

    - name: Run migrations
      run: npm run migrate
      env:
        DATABASE_URL: ${{ secrets.DATABASE_URL }}

    # Verify migration
    - name: Health check
      run: curl -f https://api.example.com/health
```

---

## Release Automation

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        run: |
          # Generate changelog from commits since last tag
          git log $(git describe --tags --abbrev=0 HEAD^)..HEAD --pretty=format:"- %s" > CHANGELOG.md

      - uses: softprops/action-gh-release@v1
        with:
          body_path: CHANGELOG.md
          files: |
            dist/*
```

---

## Notifications

```yaml
notify:
  needs: [deploy]
  if: always()
  runs-on: ubuntu-latest
  steps:
    - uses: slackapi/slack-github-action@v1
      with:
        payload: |
          {
            "text": "Deploy ${{ needs.deploy.result }}: ${{ github.repository }}",
            "blocks": [
              {
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "*${{ github.repository }}*\nStatus: ${{ needs.deploy.result }}\nBranch: ${{ github.ref_name }}"
                }
              }
            ]
          }
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Security Scanning

```yaml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    # Dependency scanning
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

    # Container scanning
    - name: Run Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'myapp:${{ github.sha }}'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'

    # SAST
    - name: CodeQL Analysis
      uses: github/codeql-action/analyze@v3
```

---

## Workflow Checklist

- [ ] Concurrency control to prevent duplicate runs
- [ ] Proper caching for dependencies
- [ ] Secrets stored in GitHub Secrets, not hardcoded
- [ ] Environment protection for production
- [ ] Status checks required for PRs
- [ ] Notifications for failures
- [ ] Security scanning enabled
- [ ] Artifacts uploaded for debugging
- [ ] Timeouts set for jobs

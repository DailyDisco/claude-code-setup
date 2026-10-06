# Testing Principles

Apply these rules when writing or reviewing tests.

---

## Universal Standards

- Test **behavior and outcomes**, not implementation details
- Cover critical paths, error states, and edge cases
- Tests must be **deterministic** — no flaky tests
- Fast feedback loop — tests complete in seconds, not minutes
- Use test data factories/builders for consistent fixtures
- Mock external dependencies (APIs, databases, file systems)

---

## Testing Pyramid

| Level | Speed | Scope | When |
|-------|-------|-------|------|
| Unit | Fast (<50ms) | Single function/module | Business logic, utils, transformations |
| Integration | Medium (<2s) | Multiple modules + DB/API | API endpoints, service layer, data access |
| E2E | Slow (<30s) | Full user flow | Critical paths (login, checkout, signup) |

**Balance**: Many unit tests, some integration tests, few E2E tests. Don't test implementation details at any level.

---

## When to Write Tests

- **Always**: Business logic, utility functions, data transformations
- **Usually**: API endpoints, user flows, integration points
- **Selectively**: UI components (focus on logic, not styling)
- **Never**: Third-party library wrappers (trust the library's tests)

---

## Test Structure

Follow AAA pattern:

```
// Arrange — Set up test data and conditions
const user = createTestUser({ role: 'admin' });

// Act — Execute the code under test
const result = await getPermissions(user);

// Assert — Verify the expected outcome
expect(result).toContain('manage_users');
```

---

## Naming Conventions

Use descriptive test names that explain:
- What is being tested
- Under what conditions
- Expected outcome

```
// Good
"returns empty array when no users match filter"
"throws ValidationError when email format is invalid"
"redirects to login when session expires"

// Bad
"test1"
"should work"
"handles error"
```

---

## Test Isolation

- Each test must be independent — no shared mutable state
- Reset database/mocks between tests (use transactions + rollback)
- Don't rely on test execution order
- Use factories/builders, not shared fixtures that tests mutate

---

## Mocking Guidelines

- Mock at boundaries (network, database, file system)
- Don't mock the code under test
- Prefer dependency injection over global mocks
- Reset mocks between tests

### Good vs Bad Test

```
// BAD — testing implementation (fragile, breaks on refactor)
expect(fetchUser).toHaveBeenCalledWith('/api/users/1');
expect(setState).toHaveBeenCalledWith({ loading: false });

// GOOD — testing behavior (resilient, tests what users see)
render(<UserProfile id="1" />);
expect(await screen.findByText('Jane Doe')).toBeInTheDocument();
```

---

## Snapshot Testing

- **Yes**: Serialized data structures, API response shapes, config objects
- **No**: Full component trees (too brittle, large diffs that get rubber-stamped)
- Review snapshot diffs carefully — don't blindly update

---

## Flaky Test Debugging

When a test fails intermittently:
1. Check for **timing dependencies** (race conditions, missing `await`)
2. Check for **shared state** (global variables, database records from other tests)
3. Check for **environment assumptions** (timezone, locale, file system paths)
4. Check for **non-deterministic data** (random values, `Date.now()`, UUIDs)

---

## Coverage Goals

- Focus on critical path coverage, not arbitrary percentages
- 100% coverage doesn't mean bug-free code
- Untested edge cases are more dangerous than uncovered lines

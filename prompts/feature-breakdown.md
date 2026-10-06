# Feature Breakdown

## Context
Use this prompt when breaking down a feature request into implementable tasks. Helps with estimation, planning, and ensuring nothing is missed.

## Methodology

### Phase 1: Understand Requirements
1. Clarify the user story / feature request
2. Identify the personas affected
3. Define acceptance criteria
4. List out-of-scope items explicitly

### Phase 2: Technical Discovery
1. Identify affected systems/components
2. Map dependencies (internal and external)
3. Identify required API changes
4. Determine data model changes
5. List integration points

### Phase 3: Break Down Tasks
Categories of work:
1. **Backend** - API endpoints, business logic, data access
2. **Frontend** - UI components, state management, routing
3. **Database** - Schema changes, migrations, indexes
4. **Infrastructure** - Config, deployments, monitoring
5. **Testing** - Unit, integration, e2e tests
6. **Documentation** - API docs, user guides, ADRs

### Phase 4: Order and Dependencies
1. Identify task dependencies
2. Find parallelizable work
3. Identify the critical path
4. Note blockers and risks

### Phase 5: Define Done
For each task:
1. Clear deliverable
2. Testable acceptance criteria
3. Definition of done

## Questions to Answer
- What is the MVP version of this feature?
- What can be deferred to a follow-up?
- What are the riskiest parts?
- What needs to be done first to unblock others?
- Are there any unknowns that need spikes?

## Output Format

### Feature Summary
One paragraph describing the feature

### User Stories
```
As a [persona]
I want [capability]
So that [benefit]
```

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

### Task Breakdown

#### Epic: [Feature Name]

**Phase 1: Foundation**
| Task | Type | Dependencies | Size |
|------|------|--------------|------|
| Design database schema | DB | None | S |
| Create migration | DB | Schema design | S |

**Phase 2: Backend**
| Task | Type | Dependencies | Size |
|------|------|--------------|------|

**Phase 3: Frontend**
| Task | Type | Dependencies | Size |
|------|------|--------------|------|

**Phase 4: Testing & Polish**
| Task | Type | Dependencies | Size |
|------|------|--------------|------|

### Dependency Graph
```
[Task A] --> [Task B] --> [Task C]
                    \--> [Task D]
```

### Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### Out of Scope
Items explicitly not included in this feature

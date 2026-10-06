# Architecture Review

## Context
Use this prompt when evaluating the overall architecture of a codebase, planning major refactors, or onboarding to a new project.

## Methodology

### Phase 1: Structural Analysis
1. Map the directory structure and identify patterns
2. Identify entry points (main, index, app files)
3. Trace the dependency graph between modules
4. Document the layering strategy (if any)

### Phase 2: Pattern Recognition
1. Identify architectural patterns in use (MVC, Clean Architecture, Hexagonal, etc.)
2. Check for consistency in pattern application
3. Note deviations and their justifications
4. Identify anti-patterns or code smells

### Phase 3: Dependency Analysis
1. Review external dependencies and their purposes
2. Check for dependency injection patterns
3. Identify tightly coupled components
4. Evaluate testability of the architecture

### Phase 4: Data Flow
1. Trace how data enters the system
2. Map data transformations through layers
3. Identify state management patterns
4. Document data persistence strategies

### Phase 5: Cross-Cutting Concerns
1. Error handling strategy
2. Logging and observability
3. Authentication/authorization flow
4. Configuration management

## Questions to Answer
- What is the primary architectural pattern?
- Are boundaries between layers/modules clear?
- How does data flow through the system?
- What are the extension points?
- Where are the coupling hotspots?
- How testable is each component in isolation?
- What would break if X component changed?

## Output Format

### Architecture Overview
Brief description of the architecture style and key decisions

### Component Map
```
[Layer/Module] --> [Layer/Module] --> [Layer/Module]
```

### Strengths
- What the architecture does well

### Concerns
- Areas that need attention (prioritized)

### Recommendations
- Specific, actionable improvements

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

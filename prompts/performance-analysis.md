# Performance Analysis

## Context
Use this prompt when investigating performance issues, optimizing slow code, or establishing performance baselines.

## Methodology

### Phase 1: Establish Baseline
1. Define what "slow" means (metrics, thresholds)
2. Measure current performance (response times, throughput)
3. Identify the performance goal
4. Document the test conditions (data size, concurrency)

### Phase 2: Profile
1. Use appropriate profiling tools
   - Backend: pprof (Go), cProfile (Python), clinic (Node.js)
   - Frontend: Chrome DevTools, Lighthouse
   - Database: EXPLAIN ANALYZE, slow query logs
2. Identify the hot paths (where time is spent)
3. Measure memory usage patterns
4. Check I/O wait times

### Phase 3: Identify Bottlenecks
Common bottleneck categories:
1. **CPU-bound** - Heavy computation, inefficient algorithms
2. **Memory-bound** - Large allocations, GC pressure
3. **I/O-bound** - Database queries, network calls, file operations
4. **Concurrency** - Lock contention, thread pool exhaustion

### Phase 4: Analyze Root Causes
For each bottleneck:
1. Trace the code path
2. Identify the specific operation causing slowness
3. Understand why it's slow
4. Research optimization strategies

### Phase 5: Optimize
Optimization priority order:
1. **Eliminate** - Remove unnecessary work
2. **Cache** - Store computed results
3. **Batch** - Combine multiple operations
4. **Parallelize** - Use concurrency
5. **Optimize** - Improve algorithm/data structure

### Phase 6: Verify
1. Measure after optimization
2. Compare against baseline
3. Check for regressions in other areas
4. Validate under realistic load

## Questions to Answer
- What is the acceptable performance target?
- Where is time actually being spent?
- Is this CPU, memory, or I/O bound?
- What's the simplest fix that meets the target?
- Are there caching opportunities?

## Output Format

### Performance Report

#### Summary
- Current: Xms/request (or relevant metric)
- Target: Yms/request
- Gap: Z%

#### Profiling Results
| Operation | Time (ms) | % of Total | Category |
|-----------|-----------|------------|----------|

#### Bottleneck Analysis
1. **Primary Bottleneck**
   - Location: file:function
   - Cause: Why it's slow
   - Impact: X% of total time

2. **Secondary Bottleneck**
   - ...

#### Optimization Plan
| Optimization | Expected Gain | Effort | Risk |
|--------------|---------------|--------|------|

#### Recommended Actions
1. Quick wins (low effort, high impact)
2. Medium-term improvements
3. Long-term architectural changes

#### Verification Plan
How to measure success after optimization

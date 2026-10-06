---
name: benchmark
description: Quick performance comparison between code snippets or approaches.
allowed-tools: Bash(node:*), Bash(go:*), Bash(python:*), Read, Write
---

# Benchmark Command

Run quick performance benchmarks to compare approaches.

## Usage

```
/benchmark [description]
```

## Examples

- `/benchmark map vs forEach for this array operation`
- `/benchmark current vs proposed implementation`
- `/benchmark JSON.parse vs manual parsing`

## Benchmark Types

### JavaScript/TypeScript
```javascript
const iterations = 100000;

console.time('Approach A');
for (let i = 0; i < iterations; i++) {
  // Approach A
}
console.timeEnd('Approach A');

console.time('Approach B');
for (let i = 0; i < iterations; i++) {
  // Approach B
}
console.timeEnd('Approach B');
```

### Go
```go
func BenchmarkA(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // Approach A
    }
}

func BenchmarkB(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // Approach B
    }
}
```

## Output Format

```
═══════════════════════════════════════════════════════════════
                    Benchmark Results
═══════════════════════════════════════════════════════════════

Test: [description]
Iterations: [N]

Approach A:     [time]ms ([ops]/sec)
Approach B:     [time]ms ([ops]/sec)

Winner: Approach [X] is [N]x faster

Note: [any caveats about the benchmark]
═══════════════════════════════════════════════════════════════
```

## Hard Rules
- Run multiple iterations for accuracy
- Note if results are within noise threshold
- Consider memory usage, not just speed
- Include warm-up runs where relevant
- Note any caveats (JIT, GC, cold start)

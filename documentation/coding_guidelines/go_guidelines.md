# Go Coding Guidelines

> These guidelines target performance-critical Go services and libraries. The primary concern
> is minimising allocations, reducing GC pressure, and writing clear, idiomatic code that the
> compiler and runtime can optimise well.

---

## 1. Philosophy

- Go's GC has low latency (sub-millisecond pauses) but **allocation rate** still matters.
  More allocations → more GC work → more pauses.
- Prefer **value semantics** for small data; use pointers only when you need shared mutation
  or when the struct is large enough that copying is expensive.
- Write **pure functions** wherever possible — a function that takes inputs and returns outputs
  with no side effects is easy to test and reason about.
- Treat goroutines and channels as tools for **data parallelism** and **pipeline decomposition**,
  not as a default for all concurrency.
- Interfaces are satisfied implicitly — keep them **small** (1–3 methods). The smaller the
  interface, the more implementations can satisfy it.

---

## 2. Minimising Allocations

### 2.1 Understand Escape Analysis

A value **escapes to the heap** if the compiler cannot prove it has a shorter lifetime than
the function call. Use `go build -gcflags="-m"` to inspect escape decisions.

```go
// Does NOT escape — compiler allocates on stack
func sum(a, b int) int {
    result := a + b   // stays on stack
    return result
}

// ESCAPES — returned pointer forces heap allocation
func newInt(v int) *int {
    return &v  // v escapes because its address outlives the function
}
```

### 2.2 Pre-allocate Slices and Maps

```go
// AVOID — grows by doubling, many intermediate allocations
var results []int
for _, v := range data {
    results = append(results, v*2)
}

// PREFER — single allocation, exact capacity
results := make([]int, 0, len(data))
for _, v := range data {
    results = append(results, v*2)
}

// PREFER for maps — pre-size to avoid rehashing
m := make(map[string]int, expectedSize)
```

### 2.3 sync.Pool for Object Reuse

```go
var bufPool = sync.Pool{
    New: func() any { return make([]byte, 0, 4096) },
}

func processRequest(data []byte) {
    buf := bufPool.Get().([]byte)
    buf = buf[:0]  // reset length, keep capacity
    defer bufPool.Put(buf)

    // use buf without allocating
    buf = append(buf, data...)
    encode(buf)
}
```

`sync.Pool` objects may be collected by the GC between any two calls. Do not store state
that must survive across GC cycles.

### 2.4 Avoid String Conversions in Hot Paths

```go
// AVOID — allocates a new string every call
key := string(byteSlice)
m[key]++

// PREFER — avoid allocation with unsafe conversion (read-only!)
// Only safe if the string is never stored or mutated
key := unsafe.String(unsafe.SliceData(byteSlice), len(byteSlice))
m[key]++
```

---

## 3. Pure Functions

```go
// Pure — deterministic, no side effects, no global state
func lerp(a, b, t float64) float64 {
    return a + t*(b-a)
}

// Pure transformation on a slice (returns new slice, does not mutate input)
func normalise(values []float64) []float64 {
    if len(values) == 0 {
        return nil
    }
    max := values[0]
    for _, v := range values[1:] {
        if v > max {
            max = v
        }
    }
    out := make([]float64, len(values))
    for i, v := range values {
        out[i] = v / max
    }
    return out
}
```

Guidelines:
- Package-level functions that do not touch package-level variables are effectively pure.
- Avoid **method receivers** for pure computations — a free function is cleaner and makes
  the absence of side effects obvious.
- Pass context explicitly (`context.Context`) rather than storing it in a struct.

---

## 4. Data Type Selection

| Scenario | Preferred Type |
|---|---|
| Loop counter, index | `int` (native word size) |
| Bit flags | `uint32` or `uint64` |
| Small integer set | `[N]bool` array (index lookup) |
| Float computation | `float64` (Go's default); `float32` only for SIMD or large arrays |
| Byte buffer | `[]byte` rented from `sync.Pool` |
| Fixed-size data carrier | Struct by value |
| Optional value | Pointer or `(T, bool)` return |
| Ordered lookup (small N) | `[]struct{key, val}` linear scan |
| Ordered lookup (large N) | `sort.Search` on sorted slice |
| Arbitrary key-value | `map[K]V` with known initial size |

Avoid `interface{}` / `any` in hot paths — it allocates a two-word header and may trigger
an allocation for values that don't fit in a pointer.

---

## 5. Struct Design for Cache Efficiency

```go
// AVOID — padding between fields wastes cache lines
type Bad struct {
    flag  bool     // 1 byte + 7 padding
    value float64  // 8 bytes
    id    int32    // 4 bytes + 4 padding
}  // 24 bytes actual

// PREFER — largest fields first, minimal padding
type Good struct {
    value float64  // 8 bytes
    id    int32    // 4 bytes
    flag  bool     // 1 byte + 3 padding
}  // 16 bytes actual

// Verify with unsafe.Sizeof / go vet -composites
```

For hot structs accessed across goroutines, pad to avoid **false sharing**:

```go
type PaddedCounter struct {
    value int64
    _     [56]byte  // pad to 64-byte cache line
}
```

---

## 6. Reducing Branches

```go
// AVOID — branch per case
func category(score int) string {
    if score >= 90 { return "A" }
    if score >= 80 { return "B" }
    if score >= 70 { return "C" }
    return "D"
}

// PREFER — lookup table, branch-free
var gradeTable = [101]string{ /* precomputed */ }

func category(score int) string {
    if uint(score) > 100 { return "D" }
    return gradeTable[score]
}

// Branchless min/max for integers
func minInt(a, b int) int {
    diff := a - b
    return b + (diff & (diff >> 63))  // arithmetic right shift
}
```

---

## 7. Avoiding Defer in Hot Paths

`defer` has a measurable cost per call (stack frame manipulation). In hot paths, use explicit
cleanup:

```go
// AVOID in a tight loop — defer overhead per iteration
for _, item := range items {
    mu.Lock()
    defer mu.Unlock()  // deferred, but paid every iteration
    process(item)
}

// PREFER — explicit unlock
for _, item := range items {
    mu.Lock()
    process(item)
    mu.Unlock()
}
```

`defer` is fine in non-hot code paths for correctness guarantees (file close, mutex unlock
in functions called once).

---

## 8. Goroutines and Channels

- A goroutine costs ~2–8 KB of initial stack. Spawning thousands is fine; spawning millions
  needs a worker pool.
- Use **buffered channels** to decouple producers from consumers and avoid unnecessary
  scheduling overhead.
- Prefer **`sync.WaitGroup`** + a fixed worker pool over spawning a goroutine per item:

```go
func processParallel(items []Item) {
    const workers = 8
    ch := make(chan Item, workers*2)

    var wg sync.WaitGroup
    for range workers {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for item := range ch {
                process(item)
            }
        }()
    }

    for _, item := range items {
        ch <- item
    }
    close(ch)
    wg.Wait()
}
```

- Use `context.Context` for cancellation — never poll a `done` channel manually.
- Prefer **message passing** over shared state; when shared state is required, prefer
  `sync.Mutex` over `sync.RWMutex` unless reads genuinely dominate (3:1 or more).

---

## 9. Interfaces: Keep Them Small

```go
// AVOID — fat interface, hard to satisfy, hard to mock
type Storage interface {
    Get(key string) ([]byte, error)
    Put(key string, value []byte) error
    Delete(key string) error
    List(prefix string) ([]string, error)
    Stats() StorageStats
    Close() error
}

// PREFER — split by use case; compose at the boundary
type Getter  interface { Get(key string) ([]byte, error) }
type Putter  interface { Put(key string, value []byte) error }
type ReadWriter interface { Getter; Putter }
```

Do not define an interface in the **same** package as the concrete type. Define it in the
consuming package — this is idiomatic Go and enables the implicit satisfaction rule.

---

## 10. Error Handling

```go
// AVOID — discarding errors
result, _ := compute()

// AVOID — fmt.Errorf everywhere without context
return fmt.Errorf("failed")

// PREFER — wrap with context using %w (enables errors.Is / errors.As)
result, err := compute()
if err != nil {
    return fmt.Errorf("compute stage failed for id=%d: %w", id, err)
}

// PREFER sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")

// Check with errors.Is (works through wrapping chains)
if errors.Is(err, ErrNotFound) { ... }
```

- Never use `panic` for expected errors. Reserve `panic` for programming errors (nil pointer
  dereference, impossible state). Recover only at top-level goroutine boundaries.
- Return `(T, error)` from all fallible functions. Do not return a zero-value T on error
  when T is a pointer — return `nil, err`.

---

## 11. Unsafe Package

Use `unsafe` only when:
1. A benchmark confirms the safe alternative is a bottleneck.
2. The unsafe code is small, isolated, and thoroughly documented.

```go
import "unsafe"

// Reinterpret a float64 as its IEEE 754 bit pattern — zero allocation
func floatBits(f float64) uint64 {
    return *(*uint64)(unsafe.Pointer(&f))
}
```

Document the invariant that makes the unsafe code safe (e.g., "the byte slice is at least
8 bytes long and aligned to 8 bytes").

---

## 12. Benchmarking and Profiling

```go
// table-driven benchmark
func BenchmarkNormalise(b *testing.B) {
    data := generateData(1024)
    b.ReportAllocs()
    b.ResetTimer()
    for b.Loop() {   // Go 1.24+; pre-1.24: range b.N
        normalise(data)
    }
}
```

Profiling workflow:
```bash
go test -bench=. -benchmem -cpuprofile=cpu.prof ./...
go tool pprof -http=:8080 cpu.prof

# Allocation profile
go test -bench=. -memprofile=mem.prof ./...
go tool pprof -alloc_objects mem.prof

# Trace for goroutine and GC analysis
go test -bench=. -trace=trace.out ./...
go tool trace trace.out
```

---

## 13. Naming and Style

- Packages: short, lowercase, no underscores: `bufio`, `nethttp`, `algo`.
- Exported names: `PascalCase`. Unexported: `camelCase`.
- Interfaces: noun or adjective — `Reader`, `Stringer`, `Closer`, `ReadWriter`.
- Error variables: `ErrXxx`.
- Pure utility functions: package-level functions, not methods.
- Test files: `*_test.go`. Benchmark files: same, with `Benchmark` prefix.

---

## 14. Project Layout

```
cmd/
  myapp/
    main.go           — entry point only, wires dependencies
internal/
  algo/               — pure algorithms, no I/O
  domain/             — domain types, pure business logic
  transport/          — HTTP, gRPC handlers (side-effectful)
  store/              — database, cache (side-effectful)
pkg/                  — shared, exported libraries
go.mod
go.sum
```

Keep `internal/algo` and `internal/domain` free of I/O. Test them without mocks.

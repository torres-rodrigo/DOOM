# C / C++ Coding Guidelines

> These guidelines target performance-critical systems software. The default style is C-first:
> use C++ features only when they provide a clear, zero-cost benefit. Favour explicit, low-level
> control over convenience abstractions.

---

## 1. Philosophy

- Write code that compiles to the fewest CPU instructions necessary.
- Prefer **predictable** code over clever code. Compilers optimise predictable patterns better.
- Every allocation, branch, and indirection has a cost — make those costs visible.
- Blend imperative/procedural structure with **pure functions** wherever possible. A pure function
  (same input → same output, no side effects) is easier to reason about, test, and optimise.
- Treat the OOP layer (if any) as a thin organisational shell; keep business logic in pure,
  free-standing functions.

---

## 2. Data Layout and Memory

### 2.1 Prefer Structure of Arrays (SoA) over Array of Structures (AoS)

```c
// AVOID (AoS) — poor cache utilisation when only one field is accessed at a time
typedef struct {
    float x, y, z;
    float vx, vy, vz;
    uint32_t flags;
} Particle;
Particle particles[MAX_PARTICLES];

// PREFER (SoA) — sequential access patterns load full cache lines
typedef struct {
    float x[MAX_PARTICLES];
    float y[MAX_PARTICLES];
    float z[MAX_PARTICLES];
    float vx[MAX_PARTICLES];
    float vy[MAX_PARTICLES];
    float vz[MAX_PARTICLES];
    uint32_t flags[MAX_PARTICLES];
} ParticleSystem;
```

### 2.2 Memory Alignment

- Align hot structures to cache-line boundaries (typically 64 bytes).
- Use `alignas(64)` (C++11) or `__attribute__((aligned(64)))` (GCC/Clang) or `_Alignas(64)` (C11).
- Order struct fields from largest to smallest to minimise padding.

```c
// Good — no hidden padding, aligned to cache line
typedef struct __attribute__((aligned(64))) {
    double  value;      // 8
    int64_t timestamp;  // 8
    int32_t id;         // 4
    uint16_t flags;     // 2
    uint8_t  type;      // 1
    uint8_t  _pad;      // 1  (explicit padding is better than implicit)
} HotRecord;
```

### 2.3 Stack vs Heap

- Prefer **stack allocation** for small, fixed-size data. Stack access is effectively free.
- Use `alloca` / VLAs only when the size is truly dynamic and small (< a few KB). VLAs are
  optional in C11+, avoid them in C++.
- For large or variable-length data, use a **custom allocator** (arena, pool) rather than
  `malloc`/`free` directly in hot paths.

### 2.4 Avoid Aliasing; Use `restrict`

```c
// Allow the compiler to assume p and q do not alias — enables vectorisation
void add_arrays(float* restrict dst, const float* restrict a, const float* restrict b, size_t n) {
    for (size_t i = 0; i < n; i++)
        dst[i] = a[i] + b[i];
}
```

---

## 3. Reducing Branches

Branch mispredictions stall the CPU pipeline (typically 10–20 cycles each). Minimise them.

### 3.1 Branchless Arithmetic

```c
// AVOID
int abs_val = (x < 0) ? -x : x;

// PREFER (single instruction on most architectures)
int abs_val = (x ^ (x >> 31)) - (x >> 31);  // arithmetic right shift trick

// Or let the compiler figure it out — this is usually branchless:
int abs_val = abs(x);  // <stdlib.h> — check the disassembly
```

### 3.2 Replace Conditionals with Lookup Tables

```c
// AVOID — branch per character category
bool is_alnum(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
}

// PREFER — single array lookup, branch-free
static const uint8_t ALNUM_TABLE[256] = { /* precomputed */ };
bool is_alnum(char c) { return ALNUM_TABLE[(uint8_t)c]; }
```

### 3.3 Sort Hot Branches First

Place the most likely branch first so the CPU's static branch predictor (and branch-target buffer)
defaults to the common case:

```c
if (__builtin_expect(common_case, 1)) {
    // fast path
} else {
    // rare slow path
}
```

### 3.4 Prefer Data-Driven Dispatch over `if`/`switch` Chains

Use **function pointer tables** or **jump tables** for polymorphic dispatch with many cases.

```c
typedef void (*Handler)(Event*);
static const Handler HANDLERS[EVENT_COUNT] = {
    [EVENT_CONNECT]    = handle_connect,
    [EVENT_DATA]       = handle_data,
    [EVENT_DISCONNECT] = handle_disconnect,
};

// One indirect call, no branch chain
HANDLERS[event->type](event);
```

---

## 4. Choosing the Right Data Types

- Use the **smallest integer type that covers the range** to increase data density per cache line.
  In array hot paths: `uint8_t`, `uint16_t`, `uint32_t` over `int`/`long`.
- Use `uint32_t` for loop counters that fit in 32 bits — avoids sign-extension overhead on some
  architectures.
- Use `float` instead of `double` when precision allows — twice the SIMD throughput.
- Avoid `bool` arrays — use `uint8_t` bit arrays or bitsets for dense flag storage.
- Use `size_t` for sizes/offsets; `ptrdiff_t` for signed differences between pointers.
- Avoid `long` — its size is platform-dependent. Prefer `int32_t`/`int64_t` from `<stdint.h>`.

---

## 5. Pure Functions and Determinism

```c
// Pure function — no global state, no I/O, no mutation of arguments
// Same input ALWAYS produces same output. Easy to test, cache, parallelize.
static float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

// AVOID — hidden state via global/static local variable
static float lerp_bad(float a, float b, float t) {
    static float last;  // hidden state — impure
    last = a + t * (b - a);
    return last;
}
```

Guidelines:
- Mark pure functions `static` (internal linkage) unless exported in a public API.
- Pass large inputs as `const T*` — never modify inputs inside a pure function.
- Return values rather than mutating output parameters where code clarity allows.
- For hot pure functions, annotate with `__attribute__((pure))` or `__attribute__((const))`
  so the compiler can CSE (common subexpression eliminate) or hoist calls:
  - `pure`: function reads global/argument state but has no side effects.
  - `const`: stricter — function doesn't even read global state.

```c
__attribute__((const)) float fast_inv_sqrt(float x);
```

---

## 6. SIMD / Vectorisation

- Write loops that the compiler **can** auto-vectorise:
  - Fixed-length arrays with known stride.
  - No pointer aliasing (use `restrict`).
  - Simple arithmetic operations.
  - No function calls inside the loop.
- Check vectorisation with `-fopt-info-vec-optimized` (GCC) or `-Rpass=loop-vectorize` (Clang).
- Use SIMD intrinsics explicitly for critical inner loops when the compiler fails:
  ```c
  #include <immintrin.h>  // AVX2

  void dot_product_avx(const float* a, const float* b, float* result, size_t n) {
      __m256 sum = _mm256_setzero_ps();
      for (size_t i = 0; i < n; i += 8) {
          __m256 va = _mm256_loadu_ps(a + i);
          __m256 vb = _mm256_loadu_ps(b + i);
          sum = _mm256_fmadd_ps(va, vb, sum);
      }
      // horizontal sum of 8 floats
      *result = /* reduce sum */;
  }
  ```
- Prefer aligned loads (`_mm256_load_ps`) over unaligned (`_mm256_loadu_ps`) when data is
  guaranteed 32-byte aligned.

---

## 7. Algorithms and Complexity

- Know the **cache-aware** alternative to every classic algorithm:
  - Cache-oblivious merge sort over classic merge sort for large datasets.
  - B-tree / B+-tree over red-black tree for data that doesn't fit in L1/L2.
  - Robin Hood hashing over chained hash maps (better cache locality).
- Prefer **linear scan** over binary search for small N (typically N < 32) — branch predictor and
  cache effects dominate.
- **Sort before searching** when you will search the same dataset many times.
- Batch operations: process data in chunks that fit in L1 cache (typically 32 KB) to maximise
  temporal locality.

---

## 8. C++ Feature Usage (Minimal and Zero-Cost Only)

Since the style is C-first, use C++ features only when they are:
1. Zero-cost at runtime (no virtual dispatch, no exceptions, no RTTI overhead).
2. Genuinely improve correctness or reduce boilerplate.

**Allowed:**
- `constexpr` / `consteval` — move computation to compile time.
- Templates (non-virtual) — monomorphisation produces the same code as hand-written specialisations.
- `inline` free functions in headers for type-safe macros.
- `enum class` for strongly typed enumerations.
- References (`T&`) as a safe alternative to pointers in function parameters.
- `[[nodiscard]]`, `[[likely]]`, `[[unlikely]]` attributes.
- `std::array<T, N>` — zero overhead, knows its size.
- `alignas`, `static_assert`.
- RAII wrappers for resources (destructor-only, no virtual, no inheritance).

**Avoid / Use Sparingly:**
- `virtual` — indirect call + vtable pointer in every object. Use only at true hot boundaries.
- Exceptions — unpredictable cost, bloated binaries. Disable with `-fno-exceptions`.
- RTTI (`dynamic_cast`, `typeid`) — disable with `-fno-rtti`.
- `std::shared_ptr` — atomic reference count on every copy. Prefer `std::unique_ptr` or raw
  pointer with a clear ownership model.
- `std::function` — heap allocation + type erasure. Prefer templates or raw function pointers.
- `std::variant` / `std::any` in hot paths — potential heap allocation and branch overhead.
- STL containers in hot paths (especially `std::map`, `std::unordered_map`) — prefer
  flat/open-addressing containers.

---

## 9. Compiler and Build Configuration

```cmake
# Release flags (GCC/Clang)
target_compile_options(my_target PRIVATE
    -O3
    -march=native          # tune for host CPU; use -march=x86-64-v3 for portable AVX2
    -fno-exceptions
    -fno-rtti
    -fvisibility=hidden
    -ffunction-sections
    -fdata-sections
    -Wall -Wextra -Wpedantic
    -Wconversion
    -Wshadow
)
target_link_options(my_target PRIVATE -Wl,--gc-sections)
```

- Enable **Link-Time Optimisation** (LTO): `-flto=thin` (Clang) or `-flto` (GCC).
- Use **Profile-Guided Optimisation** (PGO) for long-lived binaries:
  1. Compile with `-fprofile-generate`.
  2. Run representative workload.
  3. Recompile with `-fprofile-use`.

---

## 10. Error Handling

- Avoid exceptions entirely in performance-critical code.
- Use **error codes** or a simple `Result`-style struct:

```c
typedef struct { int32_t code; const char* msg; } Error;
typedef struct { float   value; Error err; } FloatResult;

FloatResult safe_divide(float a, float b) {
    if (b == 0.0f) return (FloatResult){ .err = { .code = -1, .msg = "division by zero" } };
    return (FloatResult){ .value = a / b };
}
```

- Use `assert()` only for invariants that must hold in debug builds; strip with `-DNDEBUG`.
- Never use `assert()` for input validation in release code.

---

## 11. Concurrency

- Prefer **data parallelism** over task parallelism: partition data, process each partition
  independently, merge results.
- Use **lock-free** data structures (ring buffers, MPSC queues) instead of mutexes in hot paths.
- Align shared mutable state to cache lines to prevent **false sharing**:

```c
typedef struct {
    alignas(64) _Atomic(int64_t) counter;   // occupies its own cache line
} PaddedCounter;
```

- Prefer `memory_order_relaxed` for counters that don't need sequential consistency.
- Consider **thread-local storage** (`_Thread_local` / `thread_local`) for per-thread state to
  eliminate synchronisation entirely.

---

## 12. Tooling and Profiling Workflow

1. **Measure first** — never optimise without data. Use `perf`, `VTune`, or `Instruments`.
2. Profile at the **instruction level** — identify stalls, cache misses, branch mispredictions.
3. Check generated assembly regularly (`godbolt.org`, `objdump -d`, `-save-temps`).
4. Use `valgrind --tool=cachegrind` or `perf stat -e cache-misses,branch-misses`.
5. Sanitisers during development: `-fsanitize=address,undefined` (never ship these builds).
6. Static analysis: `clang-tidy`, `cppcheck`.

---

## 13. Naming and Style

- Functions: `snake_case` — matches the C standard library.
- Types/Structs: `PascalCase` or `snake_case_t` (pick one per project, be consistent).
- Constants/Macros: `UPPER_SNAKE_CASE`.
- Local variables: `snake_case`, short in tight loops (`i`, `n`, `ptr`).
- Prefix module/library name to avoid symbol collisions: `net_send()`, `arena_alloc()`.
- File layout per translation unit:
  1. License / module doc comment.
  2. `#include` — system headers, then project headers (alphabetical within groups).
  3. Compile-time constants and macros.
  4. Type definitions.
  5. Static (private) function declarations.
  6. Static (private) function definitions.
  7. Public function definitions.

---

## 14. Header Discipline

- Every header is **self-contained** and **idempotent** (`#pragma once` or include guards).
- Headers declare; translation units define.
- Minimise `#include` in headers — use forward declarations wherever possible.
- Never `#include` a `.c`/`.cpp` file.
- Never expose internal implementation types in public headers.

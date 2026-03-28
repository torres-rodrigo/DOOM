# Rust Coding Guidelines

> These guidelines target performance-critical Rust code. Rust's ownership model and
> zero-cost abstractions make it uniquely suited for writing high-performance, memory-safe
> systems code. The goal is to write code that is fast, correct, and expressed at the right
> level of abstraction.

---

## 1. Philosophy

- **Zero-cost abstractions**: if you don't use it, you don't pay for it; if you do use it,
  you couldn't write it faster by hand.
- The ownership system naturally encourages **pure, side-effect-free** functions — a function
  that takes `&T` references and returns a new value is inherently pure.
- **Measure before optimising**. Rust's safe code is often already very fast. Profile first,
  then reach for `unsafe`, SIMD, or manual memory management only when justified.
- Minimise allocations. Prefer stack values, slices, and iterators over `Vec`, `Box`, and
  heap-allocated types in hot paths.
- Avoid **dynamic dispatch** (`dyn Trait`) in hot paths. Prefer generics (monomorphisation)
  for zero-cost polymorphism.

---

## 2. Pure Functions and Ownership

Rust's type system enforces purity through ownership:

```rust
// Pure — takes immutable references, returns a new value. No hidden state.
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}

// Pure transformation — borrows input, returns owned output
pub fn normalise(values: &[f32]) -> Vec<f32> {
    let max = values.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    if max == 0.0 { return vec![0.0; values.len()]; }
    values.iter().map(|&v| v / max).collect()
}

// In-place pure mutation — takes exclusive reference, mutates in place (no allocation)
pub fn normalise_in_place(values: &mut [f32]) {
    let max = values.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    if max == 0.0 { return; }
    for v in values.iter_mut() { *v /= max; }
}
```

Guidelines:
- Prefer `fn foo(input: &T) -> U` over `fn foo(input: &T, output: &mut U)` for clarity.
- Use `&mut` only when in-place mutation is genuinely more efficient (avoids an allocation).
- Mark functions that truly have no side effects with `#[must_use]` to prevent callers from
  discarding their output silently.

---

## 3. Minimising Allocations

### 3.1 Prefer Slices over Owned Containers in Function Signatures

```rust
// AVOID — forces the caller to heap-allocate
pub fn process(data: Vec<u8>) -> Vec<u8>

// PREFER — works with any contiguous memory: Vec, array, stack buffer
pub fn process(data: &[u8]) -> Vec<u8>

// BEST when output size is known — write into caller-provided buffer (zero allocation)
pub fn process(data: &[u8], out: &mut Vec<u8>)
```

### 3.2 Use `&str` over `String` in Function Parameters

```rust
// AVOID — forces heap allocation at every call site
pub fn greet(name: String) { ... }

// PREFER — accepts &String, &str, string literals without allocation
pub fn greet(name: &str) { ... }
```

### 3.3 Avoid `clone()` in Hot Paths

```rust
// AVOID — clones the entire string
let key = map.get(&owned_string).cloned().unwrap_or(default.clone());

// PREFER — borrow, don't clone
let key = map.get(owned_string.as_str()).unwrap_or(&default);
```

### 3.4 Use `Cow<str>` to Avoid Unnecessary Copies

```rust
use std::borrow::Cow;

// Returns a borrowed str when no transformation is needed,
// allocates only when it must.
pub fn normalise_path(path: &str) -> Cow<str> {
    if path.contains("//") {
        Cow::Owned(path.replace("//", "/"))
    } else {
        Cow::Borrowed(path)
    }
}
```

### 3.5 Stack-Allocated Buffers with ArrayVec

For small, bounded collections, use `arrayvec::ArrayVec` (stack-allocated, no heap):

```rust
use arrayvec::ArrayVec;

let mut buf: ArrayVec<u8, 64> = ArrayVec::new();
buf.push(b'H'); buf.push(b'i');
// No heap allocation; falls back to a compile-time error if > 64 elements
```

---

## 4. Iterators and Lazy Pipelines

Rust's iterators are **lazy** and **zero-cost** — they compile to tight loops with no
intermediate allocations.

```rust
// This pipeline allocates no intermediate Vecs
let result: Vec<f64> = data
    .iter()
    .filter(|&&v| v > 0.0)
    .map(|&v| v.sqrt())
    .take(100)
    .collect();

// Reduce without collecting
let sum: f64 = data.iter().copied().sum();
let max: f64 = data.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
```

Prefer:
- `iter()` (borrows), `iter_mut()` (mutable borrows), `into_iter()` (consumes).
- `fold` / `reduce` over manual accumulator loops.
- `chain`, `zip`, `flat_map` for combining iterators.
- `.collect::<Vec<_>>()` only at the final step.

---

## 5. Choosing the Right Data Types

| Scenario | Type |
|---|---|
| Loop index / count | `usize` |
| Signed integer | `i32` / `i64` depending on range |
| Float (performance) | `f32` (double SIMD throughput) |
| Float (precision) | `f64` |
| Optional value | `Option<T>` |
| Fallible result | `Result<T, E>` |
| Small fixed-size array | `[T; N]` (stack, zero overhead) |
| Dynamic array | `Vec<T>` |
| String slice (borrow) | `&str` |
| Owned string | `String` |
| Byte buffer (borrow) | `&[u8]` |
| Shared ownership | `Arc<T>` (prefer message passing instead) |
| Interior mutability | `Cell<T>` (single-threaded), `Mutex<T>` (multi-threaded) |

Avoid `Rc<RefCell<T>>` in hot paths — prefer restructuring to eliminate shared mutable state.

---

## 6. Generics vs Dynamic Dispatch

### Prefer Generics (Static Dispatch) in Hot Paths

```rust
// Static dispatch — monomorphised at compile time, zero overhead
pub fn process<T: Processor>(processor: &T, data: &[u8]) -> Vec<u8> {
    processor.run(data)
}

// Dynamic dispatch — virtual call overhead per invocation, no inlining
pub fn process(processor: &dyn Processor, data: &[u8]) -> Vec<u8> {
    processor.run(data)
}
```

Use `dyn Trait` when:
- The concrete type is not known until runtime (plugin systems, heterogeneous collections).
- Code size matters more than speed (avoid monomorphisation bloat).

### Bounded Type Parameters

```rust
// Be specific about bounds — avoid over-constraining
pub fn sum<T>(values: &[T]) -> T
where
    T: Copy + std::ops::Add<Output = T> + Default,
{
    values.iter().copied().fold(T::default(), |acc, v| acc + v)
}
```

---

## 7. Struct Layout and Cache Efficiency

```rust
// Check layout with `std::mem::size_of::<T>()`

// AVOID — compiler may add padding
struct Bloated {
    flag:  bool,    // 1 + 7 padding
    value: f64,     // 8
    id:    i32,     // 4 + 4 padding
}  // 24 bytes

// PREFER — order largest to smallest
struct Compact {
    value: f64,  // 8
    id:    i32,  // 4
    flag:  bool, // 1 + 3 padding
}  // 16 bytes

// EXPLICIT control with repr
#[repr(C)]          // C-compatible layout for FFI
#[repr(packed)]     // no padding (be careful with alignment)
#[repr(align(64))]  // align to cache line
struct HotStruct { ... }
```

For hot data processed in SIMD loops, use SoA layout:

```rust
struct ParticleSystem {
    x: Vec<f32>,
    y: Vec<f32>,
    z: Vec<f32>,
    vx: Vec<f32>,
    vy: Vec<f32>,
    vz: Vec<f32>,
}
```

---

## 8. SIMD

### Auto-Vectorisation

Write loops the compiler can vectorise:
- Use slices with known-length iteration.
- Use `copy` and `clone_from_slice` for bulk copies.
- Avoid branches inside tight loops; separate `filter` and `map` steps.
- Check with `RUSTFLAGS="-C target-cpu=native"` and inspect IR/assembly.

### Explicit SIMD with `std::arch` or `std::simd`

```rust
#[cfg(target_arch = "x86_64")]
use std::arch::x86_64::*;

#[target_feature(enable = "avx2")]
unsafe fn dot_product_avx(a: &[f32], b: &[f32]) -> f32 {
    assert_eq!(a.len(), b.len());
    let mut sum = _mm256_setzero_ps();
    let chunks = a.len() / 8;
    for i in 0..chunks {
        let va = _mm256_loadu_ps(a.as_ptr().add(i * 8));
        let vb = _mm256_loadu_ps(b.as_ptr().add(i * 8));
        sum = _mm256_fmadd_ps(va, vb, sum);
    }
    // horizontal reduce + scalar tail omitted for brevity
    hsum_avx(sum)
}
```

Use `std::simd` (portable SIMD, stabilising) for cross-platform SIMD:

```rust
use std::simd::f32x8;

pub fn add_slices(a: &[f32], b: &[f32], out: &mut [f32]) {
    let (a_chunks, a_tail) = a.as_chunks::<8>();
    let (b_chunks, b_tail) = b.as_chunks::<8>();
    for ((ac, bc), oc) in a_chunks.iter().zip(b_chunks).zip(out.array_chunks_mut::<8>()) {
        let va = f32x8::from_array(*ac);
        let vb = f32x8::from_array(*bc);
        *oc = (va + vb).to_array();
    }
    // handle tail...
}
```

---

## 9. Unsafe Code

Use `unsafe` only when:
1. Profiling confirms the safe alternative is a bottleneck.
2. You are calling an FFI function.
3. You need a specific memory layout or alignment guarantee.

Rules for every `unsafe` block:
- Write a `// SAFETY:` comment explaining why the invariants hold.
- Keep `unsafe` blocks **as small as possible**.
- Never expose `unsafe` in a public API without a safe wrapper.

```rust
/// Returns a mutable slice over the buffer.
///
/// # Safety
/// `ptr` must be valid for `len` elements and aligned to `T`.
/// The caller ensures no other references to this memory exist.
pub unsafe fn raw_slice<T>(ptr: *mut T, len: usize) -> &'static mut [T] {
    // SAFETY: caller upholds validity and uniqueness invariants.
    std::slice::from_raw_parts_mut(ptr, len)
}
```

---

## 10. Error Handling

```rust
// Define a domain error type
#[derive(Debug, thiserror::Error)]
pub enum ProcessError {
    #[error("input is empty")]
    EmptyInput,
    #[error("value {value} out of range [{min}, {max}]")]
    OutOfRange { value: i64, min: i64, max: i64 },
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
}

// Use ? operator for clean propagation
pub fn parse(raw: &str) -> Result<i64, ProcessError> {
    if raw.is_empty() { return Err(ProcessError::EmptyInput); }
    let n: i64 = raw.parse().map_err(|_| ProcessError::OutOfRange { value: 0, min: 0, max: 0 })?;
    if n < 0 || n > 1000 {
        return Err(ProcessError::OutOfRange { value: n, min: 0, max: 1000 });
    }
    Ok(n)
}
```

- Use `thiserror` for library error types (implements `std::error::Error`).
- Use `anyhow` for application-level error propagation where type specificity is unimportant.
- Never use `unwrap()` or `expect()` in library code. Reserve `expect()` in application code
  only for truly unrecoverable states with a clear message.
- Avoid `panic!` in library code — libraries must never crash the caller.

---

## 11. Inlining

```rust
#[inline]         // suggest inlining (cross-crate requires this)
pub fn fast_path(x: f32) -> f32 { x * x }

#[inline(always)] // force inlining (use sparingly — can cause code bloat)
fn tiny_hot_fn(x: u8) -> u8 { x ^ 0xFF }

#[inline(never)]  // prevent inlining (useful for profiling, error paths)
#[cold]           // hint that this function is rarely called
fn handle_error(e: Error) { ... }
```

---

## 12. Concurrency

- Prefer **message passing** via `std::sync::mpsc` or `crossbeam-channel` over shared state.
- Use `Arc<Mutex<T>>` only when shared mutation is truly necessary and the lock is held
  briefly. Prefer lock-free structures (`crossbeam`, `dashmap`) for high-contention data.
- Prefer **Rayon** for data parallelism — it automatically partitions work across threads:

```rust
use rayon::prelude::*;

// Parallel map over a large slice — same semantics as sequential, automatic work-stealing
let results: Vec<f64> = data.par_iter().map(|&v| heavy_compute(v)).collect();
```

- For async I/O, use **Tokio** or **async-std**. Keep CPU-bound work out of async tasks —
  spawn blocking work with `tokio::task::spawn_blocking`.

---

## 13. Benchmarking and Profiling

```rust
// Cargo.toml
// [dev-dependencies]
// criterion = { version = "0.5", features = ["html_reports"] }

use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_normalise(c: &mut Criterion) {
    let data: Vec<f32> = (0..10_000).map(|i| i as f32).collect();
    c.bench_function("normalise_10k", |b| {
        b.iter(|| normalise(black_box(&data)))
    });
}

criterion_group!(benches, benchmark_normalise);
criterion_main!(benches);
```

```bash
cargo bench
# Flame graph
cargo install flamegraph
cargo flamegraph --bench my_bench

# Assembly inspection
cargo asm my_crate::my_module::hot_fn

# Check for missed optimisations
RUSTFLAGS="-C target-cpu=native" cargo build --release
```

---

## 14. Naming and Style

- Types, traits, enums, variants: `PascalCase`.
- Functions, methods, variables, modules: `snake_case`.
- Constants and statics: `UPPER_SNAKE_CASE`.
- Type parameters: `T`, `U`, `E`, or descriptive `Item`, `Key`, `Val`.
- Lifetime parameters: short lowercase: `'a`, `'buf`, `'ctx`.
- Predicate methods: prefix `is_` or `has_`: `is_empty()`, `has_value()`.
- Builder methods: `with_*`: `with_capacity(n)`.

---

## 15. Project Layout

```
src/
  lib.rs              — public API surface
  domain/
    mod.rs
    types.rs          — domain types (pure data)
    algorithms.rs     — pure algorithms
  io/
    mod.rs
    network.rs        — I/O (side-effectful)
    storage.rs
  bin/
    main.rs           — entry point, thin orchestration
benches/
  my_bench.rs
tests/
  integration_test.rs
```

- Pure functions in `domain/algorithms.rs` are tested without any mocking.
- `unsafe` code is isolated in dedicated modules with a `// Safety:` module-level comment.

# C# Coding Guidelines

> These guidelines target performance-critical .NET applications. Emphasis is on zero-allocation
> hot paths, value semantics, pure functional design, and modern C# features that have zero or
> near-zero runtime cost.

---

## 1. Philosophy

- .NET's GC is powerful but **GC pressure is the enemy of consistent latency**. Measure and
  minimise allocations in hot paths.
- Prefer **value types** (`struct`, `record struct`) for small, short-lived data to keep it on
  the stack and in contiguous memory.
- Embrace **pure static methods** — same input, same output, no side effects. They are easier to
  test, inline, and reason about.
- Use OOP (classes, interfaces) as the architectural shell; push logic into pure static or
  extension methods.
- Lean into modern C# features (Span, ref structs, unsafe, intrinsics) only when profiling
  justifies it.

---

## 2. Minimising Allocations

### 2.1 Span<T> and Memory<T>

Use `Span<T>` for **stack-allocated or array-backed slices** with zero allocation:

```csharp
// AVOID — allocates a new array
public static int[] Slice(int[] source, int start, int length)
    => source[start..(start + length)];

// PREFER — no allocation, stack-friendly
public static ReadOnlySpan<int> Slice(ReadOnlySpan<int> source, int start, int length)
    => source.Slice(start, length);
```

- `Span<T>` cannot be stored on the heap — it is a `ref struct`. Use `Memory<T>` when you need
  to store the slice in a field or pass it across async boundaries.
- Use `MemoryMarshal` to reinterpret raw byte spans: `MemoryMarshal.Cast<byte, float>(bytes)`.

### 2.2 stackalloc

```csharp
// Zero-heap allocation for small, fixed-size temporary buffers
Span<byte> buffer = stackalloc byte[256];
```

- Limit `stackalloc` to **small sizes** (< 1 KB typical; stack is ~1 MB per thread).
- Combine with `ArrayPool<T>` for larger buffers:

```csharp
byte[] rented = ArrayPool<byte>.Shared.Rent(requiredSize);
try {
    Span<byte> span = rented.AsSpan(0, requiredSize);
    Process(span);
} finally {
    ArrayPool<byte>.Shared.Return(rented);
}
```

### 2.3 Avoid Boxing

Boxing converts a value type to `object`, causing a heap allocation.

```csharp
// AVOID — boxes the int
object boxed = 42;
Console.WriteLine(boxed);  // unboxed on retrieval

// AVOID — non-generic collection boxes
ArrayList list = new();
list.Add(42);  // boxes

// PREFER — generic collections never box
List<int> list = new();
list.Add(42);
```

Common boxing traps:
- Passing a struct to a parameter typed `object` or a non-generic interface.
- String interpolation with structs (use `.ToString()` explicitly or `ref struct` interpolation handlers).
- `Enum` in non-generic comparisons.

### 2.4 Avoid Closures in Hot Paths

Lambda captures cause heap allocations for the closure object:

```csharp
// AVOID in a tight loop — allocates a closure every call
int threshold = 42;
var filtered = items.Where(x => x > threshold).ToList();

// PREFER — static local function, no closure, no allocation
static bool IsAboveThreshold(int x, int threshold) => x > threshold;
filtered = items.Where(x => IsAboveThreshold(x, threshold)).ToList();

// BEST in truly hot paths — avoid LINQ entirely, use a manual loop
var filtered = new List<int>(items.Count);
foreach (var x in items) {
    if (x > threshold) filtered.Add(x);
}
```

---

## 3. Value Types and Structs

### 3.1 readonly struct

Mark structs `readonly` when all fields are immutable. The compiler elides defensive copies:

```csharp
// Without readonly — compiler may copy the struct before calling methods
public struct Vector3 { public float X, Y, Z; }

// With readonly — no defensive copies, method calls on in-parameters are direct
public readonly struct Vector3 {
    public float X { get; init; }
    public float Y { get; init; }
    public float Z { get; init; }

    // Pure function — no side effects
    public readonly float Dot(in Vector3 other)
        => X * other.X + Y * other.Y + Z * other.Z;

    public readonly Vector3 Normalised() {
        float len = MathF.Sqrt(X * X + Y * Y + Z * Z);
        return new(X / len, Y / len, Z / len);
    }
}
```

### 3.2 in / ref / out Parameters for Large Structs

Passing a large struct by value copies it. Use `in` (readonly ref) to avoid the copy:

```csharp
public static float ComputeScore(in LargeStruct data) { ... }
```

Use `ref` when the method must mutate the struct in-place:

```csharp
public static void Normalise(ref Vector3 v) {
    float len = MathF.Sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z);
    v.X /= len; v.Y /= len; v.Z /= len;
}
```

### 3.3 record struct vs record class

```csharp
// record struct — value semantics, stack-allocated, equality by value, zero heap allocation
public readonly record struct Point(float X, float Y);

// record class — reference semantics, heap-allocated, equality by value
public record class Entity(int Id, string Name);
```

Prefer `record struct` for small data carriers used in collections or hot paths.

### 3.4 ref struct

`ref struct` types can never be placed on the heap (no boxing, no async capture):

```csharp
public ref struct Parser {
    private ReadOnlySpan<char> _remaining;
    // ... zero-allocation text parsing
}
```

---

## 4. Pure Functions and Functional Style

```csharp
// Pure static method — deterministic, no side effects, trivially testable
public static class MathUtils {
    public static float Lerp(float a, float b, float t) => a + t * (b - a);

    public static float Clamp(float value, float min, float max)
        => MathF.Max(min, MathF.Min(max, value));

    // Pure transformation pipeline using spans (zero allocation)
    public static void NormaliseInPlace(Span<float> values) {
        float max = 0f;
        foreach (float v in values) if (v > max) max = v;
        if (max == 0f) return;
        for (int i = 0; i < values.Length; i++) values[i] /= max;
    }
}
```

### Pipelines with Spans (Zero Allocation)

```csharp
// Chain pure transforms without intermediate allocations
ReadOnlySpan<byte> raw = GetRawData();
Span<float> decoded = MemoryMarshal.Cast<byte, float>(MemoryMarshal.AsMemory(raw).Span);
NormaliseInPlace(decoded);
```

### Use `ImmutableArray<T>` for Shared Read-Only Collections

```csharp
// Immutable, struct-backed — no heap allocation for the wrapper, safe to share
ImmutableArray<int> lookup = ImmutableArray.Create(1, 2, 3, 4, 5);
```

---

## 5. Avoiding Allocations in Hot Paths — LINQ

LINQ uses `IEnumerable<T>` iterators which allocate state machine objects and closures.

In hot paths:
- Replace `Where` + `Select` with manual `for`/`foreach` loops.
- Replace `FirstOrDefault` with a manual scan.
- Replace `OrderBy` with `Array.Sort` on a pre-allocated buffer.
- Use `System.Linq.Enumerable` alternatives from `System.Collections.Generic.CollectionsMarshal`
  where applicable.

For **non-hot paths**, LINQ is acceptable and improves readability.

---

## 6. Unsafe Code and Intrinsics

Use `unsafe` blocks only when proven necessary by profiling.

### 6.1 Direct Pointer Manipulation

```csharp
unsafe static void ZeroFill(byte* ptr, int length) {
    Unsafe.InitBlockUnaligned(ptr, 0, (uint)length);
}
```

### 6.2 SIMD with System.Runtime.Intrinsics

```csharp
using System.Runtime.Intrinsics;
using System.Runtime.Intrinsics.X86;

public static void AddVectors(ReadOnlySpan<float> a, ReadOnlySpan<float> b, Span<float> dst) {
    if (Avx.IsSupported) {
        int i = 0;
        for (; i <= a.Length - 8; i += 8) {
            var va = Vector256.Create(a[i..]);
            var vb = Vector256.Create(b[i..]);
            Avx.Store(ref dst[i], Avx.Add(va, vb));
        }
        // scalar tail
        for (; i < a.Length; i++) dst[i] = a[i] + b[i];
    } else {
        for (int i = 0; i < a.Length; i++) dst[i] = a[i] + b[i];
    }
}
```

### 6.3 Unsafe.As for Reinterpretation

```csharp
// Reinterpret bytes as a struct without copying — be sure about endianness and alignment
ref MyHeader header = ref Unsafe.As<byte, MyHeader>(ref buffer[0]);
```

---

## 7. Async and Task

- Prefer **`ValueTask`** over `Task` for methods that frequently complete synchronously — avoids
  heap allocation in the common path.
- Avoid `async` in tight loops. Prefer synchronous paths guarded by a check:

```csharp
public ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken ct) {
    if (_buffer.Length > 0) {
        // Synchronous fast path — ValueTask wraps a struct, no heap alloc
        int n = ReadFromBuffer(buffer.Span);
        return ValueTask.FromResult(n);
    }
    return SlowReadAsync(buffer, ct);  // only allocates when truly async
}
```

- Never use `Task.Result` or `.Wait()` — deadlocks on synchronisation contexts.
- Use `ConfigureAwait(false)` in library code to avoid context switching overhead.

---

## 8. Data Type Selection

| Scenario | Preferred Type |
|---|---|
| Integer counter (loop, index) | `int` (32-bit is fastest on most platforms) |
| Large counts / offsets | `long` / `nint` |
| Floating point (single precision) | `float` / `MathF` |
| Floating point (double precision) | `double` / `Math` |
| Flags / bit fields | `uint` or custom `[Flags] enum` |
| Dense boolean array | `BitArray` or `uint[]` bitset |
| Immutable small data carrier | `readonly record struct` |
| Key-value with ~N < 10 | `(TKey, TValue)[]` linear scan |
| Key-value with N ≥ 10 | `Dictionary<TKey, TValue>` |
| Ordered unique keys | `SortedSet<T>` / custom B-tree |
| Byte buffers | `byte[]` rented from `ArrayPool<byte>` |

---

## 9. Collections and Data Structures

- Use `List<T>` with a capacity hint when the count is known: `new List<T>(expectedCount)`.
- Use `Dictionary<TKey, TValue>` with an initial capacity to avoid rehashing.
- Use `CollectionsMarshal.AsSpan(list)` to get a `Span<T>` over a `List<T>`'s backing array
  without copying (only safe if the list is not modified during the span's lifetime).
- For concurrent access, prefer **channel** (`System.Threading.Channels`) over `ConcurrentQueue`
  in producer/consumer scenarios — better backpressure and ergonomics.
- Use `FrozenDictionary<TKey, TValue>` (NET 8+) for read-only lookup tables built once at startup.

---

## 10. Struct Memory Layout

```csharp
[StructLayout(LayoutKind.Sequential, Pack = 1)]
public struct PackedRecord {
    public long  Timestamp;  // 8
    public int   Id;         // 4
    public short Flags;      // 2
    public byte  Type;       // 1
    public byte  Padding;    // 1 (explicit)
}
```

- Always specify `[StructLayout(LayoutKind.Sequential)]` for structs that cross native boundaries
  or are serialised to/from binary formats.
- Order fields largest to smallest to minimise padding in `Sequential` layout (CLR re-orders in
  `Auto` layout, which is the default for managed structs).

---

## 11. Benchmarking

- Use **BenchmarkDotNet** for all micro-benchmarks. Never use `Stopwatch` in isolation — JIT
  warm-up, GC, and OS scheduling invalidate results.

```csharp
[MemoryDiagnoser]      // shows allocations
[DisassemblyDiagnoser] // shows JIT-compiled assembly
[HardwareCounters(HardwareCounter.BranchMispredictions, HardwareCounter.CacheMisses)]
public class MyBenchmark {
    [Benchmark(Baseline = true)]
    public int Original() => OriginalImpl(_data);

    [Benchmark]
    public int Optimised() => OptimisedImpl(_data);
}
```

---

## 12. Naming and Style

- Types, methods, properties, events: `PascalCase`.
- Local variables, parameters: `camelCase`.
- Private fields: `_camelCase` (leading underscore).
- Constants: `PascalCase` (C# convention) or `UPPER_SNAKE` (for interop / matching C constants).
- Pure static methods should live in `static class` utility types: `MathUtils`, `BufferHelpers`.
- Extension methods for domain-specific pipelines: `value.Clamp(min, max).Lerp(target, t)`.

---

## 13. File and Project Organisation

```
src/
  Core/
    Domain/          — pure domain types (structs, record structs, enums)
    Algorithms/      — pure static algorithm classes
    Extensions/      — extension methods
  Infrastructure/    — I/O, network, DB (side-effectful, OOP)
  Application/       — thin orchestration layer
tests/
  Core.Tests/
  Benchmarks/
```

- One type per file. File name matches type name.
- Separate pure logic from I/O at the boundary level — test pure logic without any mocking.

---

## 14. Safety and Correctness

- Treat `null` as a bug at internal boundaries — use nullable reference types (`#nullable enable`)
  and enforce at compile time.
- Validate only at **system boundaries** (API controllers, CLI argument parsers, deserialisers).
- Use `ArgumentOutOfRangeException.ThrowIfNegative()` and similar throw helpers (NET 8+) to keep
  hot paths branch-free for the common valid case.
- Use `Debug.Assert()` for invariants that must hold internally — stripped in Release builds.

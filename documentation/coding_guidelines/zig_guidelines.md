# Zig Coding Guidelines

> These guidelines target performance-critical Zig programs. Zig is a systems language with
> explicit control over memory, comptime evaluation, and no hidden control flow. The goal is
> to write code that is correct, fast, and readable — with zero hidden cost.

---

## 1. Philosophy

- **No hidden control flow**: no exceptions, no implicit allocations, no operator overloading,
  no implicit type coercions. Every cost is visible.
- **Comptime is the primary abstraction tool**: move work to compile time wherever possible.
  Type-safe generics, specialised implementations, and zero-overhead abstractions are all
  expressed via `comptime`.
- **Explicit allocators**: every function that allocates receives an `Allocator`. This makes
  allocation strategies swappable and testable.
- **Pure functions** are idiomatic Zig: a function that takes inputs and returns outputs with
  no allocator argument and no pointer mutation is trivially pure.
- Errors are values — use Zig's error union types (`!T`) rather than sentinel values or
  out-parameters.

---

## 2. Pure Functions

```zig
// Pure — no side effects, no allocation, deterministic
pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + t * (b - a);
}

// Pure with comptime specialisation — single definition for all numeric types
pub fn lerpGeneric(comptime T: type, a: T, b: T, t: T) T {
    return a + t * (b - a);
}

// Pure slice transformation — caller owns the output slice (no allocation here)
pub fn normaliseInto(src: []const f32, dst: []f32) void {
    std.debug.assert(src.len == dst.len);
    var max: f32 = 0.0;
    for (src) |v| if (v > max) { max = v; };
    if (max == 0.0) { @memcpy(dst, src); return; }
    for (src, dst) |v, *d| d.* = v / max;
}
```

Guidelines:
- Functions that do not take an `std.mem.Allocator` and do not reference global mutable state
  are effectively pure. Prefer this form.
- Pass `[]const T` (const slice) for read-only inputs; `[]T` for in-place mutation.
- Return values rather than mutating output parameters when the output size is fixed and small.
- Use `comptime` parameters to specialise for types without runtime overhead.

---

## 3. Explicit Allocators

Zig does not allocate behind your back. Every allocation requires an explicit `Allocator`.

```zig
// CORRECT — allocator is explicit, caller chooses the strategy
pub fn buildList(allocator: std.mem.Allocator, count: usize) ![]u32 {
    const list = try allocator.alloc(u32, count);
    for (list, 0..) |*item, i| item.* = @intCast(i);
    return list;
}

// At the call site, choose the allocator for the job:
// - std.heap.ArenaAllocator — bulk free, great for request-scoped data
// - std.heap.FixedBufferAllocator — stack-backed, zero heap
// - std.heap.GeneralPurposeAllocator — debug allocator with leak detection
// - std.heap.page_allocator — OS pages, large allocations
// - std.testing.allocator — detects leaks in tests

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const list = try buildList(arena.allocator(), 1024);
// No need to free list — arena.deinit() frees everything at once
```

### Stack-Backed Allocator for Small, Bounded Allocations

```zig
var buf: [4096]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buf);
const allocator = fba.allocator();
// Allocates from the stack buffer — zero heap pressure
const tmp = try allocator.alloc(u8, 128);
```

---

## 4. Comptime

`comptime` is Zig's primary tool for zero-overhead abstractions. Use it to:
- Define type-safe generics.
- Specialise functions for known types.
- Compute lookup tables at compile time.
- Validate invariants that are known at compile time.

```zig
// Type-safe generic — monomorphised at compile time, no runtime overhead
pub fn Stack(comptime T: type) type {
    return struct {
        data: []T,
        top: usize,

        pub fn push(self: *@This(), value: T) void {
            self.data[self.top] = value;
            self.top += 1;
        }

        pub fn pop(self: *@This()) ?T {
            if (self.top == 0) return null;
            self.top -= 1;
            return self.data[self.top];
        }
    };
}

// Compile-time lookup table — computed once, zero runtime cost
const SIN_TABLE: [256]f32 = blk: {
    @setEvalBranchQuota(10_000);
    var table: [256]f32 = undefined;
    for (&table, 0..) |*entry, i| {
        const angle = @as(f32, @floatFromInt(i)) * std.math.tau / 256.0;
        entry.* = @sin(angle);
    }
    break :blk table;
};

// Comptime assertion — catches bugs at compile time, free at runtime
pub fn Vector(comptime T: type, comptime N: usize) type {
    comptime {
        if (N == 0) @compileError("Vector length must be > 0");
        if (@typeInfo(T) != .Float) @compileError("Vector requires a float type");
    }
    return [N]T;
}
```

---

## 5. Error Handling

Zig's **error unions** (`!T`) make errors explicit and propagatable with `try`:

```zig
const ParseError = error{
    EmptyInput,
    InvalidChar,
    OutOfRange,
};

pub fn parseU8(raw: []const u8) ParseError!u8 {
    if (raw.len == 0) return error.EmptyInput;
    var result: u16 = 0;
    for (raw) |c| {
        if (c < '0' or c > '9') return error.InvalidChar;
        result = result * 10 + (c - '0');
        if (result > 255) return error.OutOfRange;
    }
    return @intCast(result);
}

// Propagate with try — equivalent to if (err) return err
const value = try parseU8(input);

// Catch specific errors
const value = parseU8(input) catch |err| switch (err) {
    error.EmptyInput  => 0,
    error.OutOfRange  => 255,
    error.InvalidChar => return err,
};
```

- Never use sentinel values (`-1`, `null`, `""`) to signal errors.
- Prefer **inferred error sets** (`!T`) in function signatures; name error sets only when
  the set is part of a public API.
- Use `try` for propagation; `catch` for local handling or providing defaults.

---

## 6. Memory Layout Control

Zig gives precise control over struct layout:

```zig
// Default layout — compiler may reorder and pad fields
const Default = struct {
    x: f64,
    flag: bool,
    id: u32,
};

// extern layout — C-ABI compatible, no reordering
const Extern = extern struct {
    x: f64,   // 8
    id: u32,  // 4
    flag: u8, // 1 + 3 padding
};

// packed layout — no padding, bit-exact (use with care; unaligned access on some platforms)
const Flags = packed struct(u8) {
    read:  bool,
    write: bool,
    exec:  bool,
    _pad:  u5,
};

// Explicit alignment
const Aligned = struct {
    data: f32 align(64),  // aligned to cache line
};
```

Use `@sizeOf(T)` and `@offsetOf(T, "field")` to verify layout at comptime:

```zig
comptime {
    std.debug.assert(@sizeOf(Extern) == 16);
    std.debug.assert(@offsetOf(Extern, "id") == 8);
}
```

---

## 7. SIMD with @Vector

```zig
const Vec8f = @Vector(8, f32);

pub fn addVectors(a: []const f32, b: []const f32, out: []f32) void {
    std.debug.assert(a.len == b.len and b.len == out.len);
    const n = a.len;
    var i: usize = 0;

    // SIMD path — process 8 floats at a time
    while (i + 8 <= n) : (i += 8) {
        const va: Vec8f = a[i..][0..8].*;
        const vb: Vec8f = b[i..][0..8].*;
        out[i..][0..8].* = va + vb;
    }

    // Scalar tail
    while (i < n) : (i += 1) {
        out[i] = a[i] + b[i];
    }
}

// Reduction
pub fn horizontalSum(v: @Vector(8, f32)) f32 {
    return @reduce(.Add, v);
}
```

- Zig's `@Vector` is portable — the compiler maps it to the best available instruction set.
- Use `@splat` to broadcast a scalar to all lanes: `const ones: Vec8f = @splat(1.0)`.
- Use `@shuffle` for permutations and `@select` for blend operations.

---

## 8. Reducing Branches

```zig
// Branchless absolute value (integer)
pub fn absInt(x: i32) i32 {
    const mask = x >> 31;        // -1 if negative, 0 if positive
    return (x ^ mask) - mask;
}

// Lookup table dispatch — no branch chain
const HandlerFn = *const fn (event: *Event) void;
const handlers = [EventType.count]HandlerFn{
    handleConnect,
    handleData,
    handleDisconnect,
};
handlers[@intFromEnum(event.type)](event);

// Use std.math.clamp for branchless clamping
const clamped = std.math.clamp(value, min, max);
```

---

## 9. defer and errdefer for Resource Management

```zig
pub fn processFile(path: []const u8, allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();   // runs on all exit paths (normal and error)

    const buf = try allocator.alloc(u8, 4096);
    errdefer allocator.free(buf);  // runs ONLY on error exit

    try process(file, buf);
    // On success, caller is responsible for buf
}
```

- `defer` is zero-cost — compiled to code at each exit point, not a runtime mechanism.
- Prefer `errdefer` for cleanup that should only happen on failure.
- Avoid `defer` inside tight loops — the deferred call is emitted at every exit of the block,
  which in a loop means once per iteration.

---

## 10. Algorithms and Data Structures

- Prefer `[]T` (slices) over linked lists — better cache locality, simpler ownership.
- Use `std.ArrayList(T)` for dynamic arrays (equivalent to `Vec<T>` in Rust).
- Use `std.ArrayHashMap` for ordered insertion with O(1) lookup.
- Use `std.HashMap` for unordered O(1) lookup (requires a hash context).
- Use `std.BoundedArray(T, N)` for stack-allocated arrays with runtime-known length up to N.
- For sorting: `std.sort.pdq` (pattern-defeating quicksort) is the default. Provide a
  `lessThan` function for custom ordering.

```zig
std.sort.pdq(u32, slice, {}, comptime std.sort.asc(u32));
```

---

## 11. Build System

```zig
// build.zig — define release optimisation targets
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});

const exe = b.addExecutable(.{
    .name = "myapp",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,  // ReleaseFast, ReleaseSafe, ReleaseSmall, Debug
});

// CPU feature targeting
const cpu = std.Target.Cpu.baseline(.x86_64);
const features = std.Target.Cpu.Feature.Set.empty;
// Enable AVX2
const target_cpu = std.Target.Cpu{ .model = cpu.model, .features = cpu.features.add(avx2) };
```

Build modes:
- `Debug` — bounds checks, safety checks, no optimisation. Use during development.
- `ReleaseSafe` — optimised + bounds/overflow checks. Good default for production.
- `ReleaseFast` — maximum optimisation, no safety checks. Use only for proven hot paths.
- `ReleaseSmall` — optimise for binary size.

---

## 12. Testing

```zig
const std = @import("std");
const testing = std.testing;

test "lerp midpoint" {
    try testing.expectApproxEqRel(lerp(0.0, 10.0, 0.5), 5.0, 1e-6);
}

test "normalise empty slice" {
    var dst: [0]f32 = .{};
    normaliseInto(&.{}, &dst);  // must not crash
}

test "parse out of range returns error" {
    const result = parseU8("300");
    try testing.expectError(error.OutOfRange, result);
}
```

- Use `std.testing.allocator` in tests — it detects memory leaks.
- Write tests for pure functions without any mocking.
- Use `comptime` to generate table-driven tests:

```zig
test "lerp parametric" {
    const cases = [_]struct { a: f32, b: f32, t: f32, expected: f32 }{
        .{ .a = 0, .b = 10, .t = 0.0, .expected = 0.0 },
        .{ .a = 0, .b = 10, .t = 0.5, .expected = 5.0 },
        .{ .a = 0, .b = 10, .t = 1.0, .expected = 10.0 },
    };
    for (cases) |c| {
        try testing.expectApproxEqRel(lerp(c.a, c.b, c.t), c.expected, 1e-6);
    }
}
```

---

## 13. Naming Conventions

- Types (structs, enums, unions, error sets): `PascalCase` — `ByteBuffer`, `ParseError`.
- Functions, variables, fields: `camelCase` — `parseU8`, `totalCount`.
- Constants (comptime-known): `UPPER_SNAKE_CASE` — `MAX_CONNECTIONS`, `SIN_TABLE`.
- Namespaces (files/modules used as namespaces): `snake_case` — `std.mem.Allocator`.
- Boolean variables/fields: prefix `is_` or `has_` — `is_valid`, `has_data`.
- Generic type parameters: single uppercase letter or `PascalCase` — `T`, `Key`, `Value`.

---

## 14. Project Layout

```
src/
  main.zig          — entry point, argument parsing, top-level wiring
  root.zig          — library root (for libraries)
  algo/
    sort.zig        — pure sorting algorithms
    hash.zig        — pure hash functions
    math.zig        — pure math utilities
  domain/
    types.zig       — domain types
    logic.zig       — pure business logic
  io/
    file.zig        — file I/O (side-effectful)
    net.zig         — network I/O (side-effectful)
build.zig
build.zig.zon
```

- `algo/` and `domain/` contain only pure functions and comptime code — no I/O, no
  allocators (or explicit `Allocator` parameters only).
- `io/` contains all side-effectful code.
- Each file is a Zig module; import with `@import("algo/math.zig")` or via the build system.

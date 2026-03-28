# Gleam Coding Guidelines

> These guidelines target performant, correct Gleam programs. Gleam is a statically typed,
> purely functional language that compiles to Erlang and JavaScript. Correctness through the
> type system, pure transformations, and well-structured pipelines are the primary tools.

---

## 1. Philosophy

- Gleam is **functional first** — pure functions are the natural and idiomatic choice.
  Side effects are explicit and isolated.
- The **type system is your primary correctness tool**. Use it aggressively — model your
  domain with custom types so illegal states are unrepresentable.
- Use **`Result` and `Option`** for all fallible and optional values. Never rely on
  runtime exceptions for control flow.
- Pipeline operator (`|>`) is the preferred way to compose data transformations.
- Performance on the BEAM (Erlang) comes from process-level parallelism and tail-call
  optimisation, not low-level micro-optimisation.

---

## 2. Pure Functions

```gleam
// Pure function — deterministic, no side effects
pub fn lerp(a: Float, b: Float, t: Float) -> Float {
  a +. t *. (b -. a)
}

// Pure transformation on a list
pub fn normalise(values: List(Float)) -> List(Float) {
  let max =
    values
    |> list.fold(0.0, fn(acc, v) { float.max(acc, v) })
  values
  |> list.map(fn(v) { v /. max })
}
```

Guidelines:
- A function is pure if it has no side effects and returns the same output for the same input.
- All `pub fn` functions in `algo`, `domain`, and `math` modules should be pure.
- Side effects (file I/O, HTTP calls, database writes) belong exclusively in dedicated modules
  and must return `Result` or use a task/process abstraction.
- Prefer `fn` (anonymous functions) over named helpers when a transform is used once and is
  self-evident in context.

---

## 3. Custom Types: Model the Domain Precisely

```gleam
// AVOID — using primitives for everything
pub fn process_order(id: Int, amount: Float, status: String) -> Result(Order, String)

// PREFER — domain types make invalid states unrepresentable
pub type OrderId { OrderId(Int) }
pub type Amount  { Amount(Float) }
pub type OrderStatus {
  Pending
  Confirmed
  Shipped
  Cancelled(reason: String)
}

pub fn process_order(
  id: OrderId,
  amount: Amount,
  status: OrderStatus,
) -> Result(Order, ProcessError)
```

### Opaque Types for Encapsulation

```gleam
// Only code in this module can construct or decompose an Email
pub opaque type Email { Email(String) }

pub fn parse_email(raw: String) -> Result(Email, String) {
  case string.contains(raw, "@") {
    True  -> Ok(Email(raw))
    False -> Error("invalid email: " <> raw)
  }
}
```

---

## 4. Result and Option

Every fallible operation returns `Result(value, error)`. Every optional value is
`Option(value)` (`Some(v)` / `None`). Never return a sentinel value (`-1`, `""`, `nil`).

```gleam
import gleam/result
import gleam/option.{type Option, None, Some}

// Chain fallible operations with result.try
pub fn parse_and_compute(raw: String) -> Result(Float, String) {
  use n <- result.try(int.parse(raw))
  use validated <- result.try(validate_range(n))
  Ok(compute(validated))
}

// Map over Option without explicit pattern matching
pub fn double_if_present(opt: Option(Int)) -> Option(Int) {
  option.map(opt, fn(n) { n * 2 })
}

// Provide a default
let value = option.unwrap(opt, default: 0)
```

### Prefer `use` for Monadic Chains

```gleam
// Without use — nested pattern matching
pub fn pipeline(input: String) -> Result(Output, Error) {
  case parse(input) {
    Error(e) -> Error(e)
    Ok(parsed) ->
      case validate(parsed) {
        Error(e) -> Error(e)
        Ok(valid) -> Ok(transform(valid))
      }
  }
}

// With use — flat, readable pipeline
pub fn pipeline(input: String) -> Result(Output, Error) {
  use parsed <- result.try(parse(input))
  use valid  <- result.try(validate(parsed))
  Ok(transform(valid))
}
```

---

## 5. Pattern Matching

Pattern matching is the preferred control flow mechanism — exhaustive, compiler-checked,
and more expressive than `if`/`switch`.

```gleam
pub fn describe(status: OrderStatus) -> String {
  case status {
    Pending            -> "waiting for confirmation"
    Confirmed          -> "order confirmed"
    Shipped            -> "on its way"
    Cancelled(reason)  -> "cancelled: " <> reason
  }
}

// Nested pattern matching
pub fn process(event: Event) -> Result(Response, Error) {
  case event {
    Click(Button(id), position) if id == "submit" -> handle_submit(position)
    Click(_, _)    -> Ok(Ignored)
    Scroll(delta)  -> handle_scroll(delta)
    Resize(w, h)   -> handle_resize(w, h)
  }
}
```

- Use **guards** (`if`) in patterns to express conditions that depend on the matched value.
- Prefer exhaustive matches — the compiler will warn about non-exhaustive patterns.
- Destructure tuples and records directly in the `case` arm for clarity.

---

## 6. Pipeline Operator

The `|>` operator is the primary composition tool. Prefer it over nesting function calls:

```gleam
// AVOID — nested, reads inside-out
let result = list.filter(list.map(parse(raw), transform), is_valid)

// PREFER — reads top to bottom, each step is clear
let result =
  raw
  |> parse
  |> list.map(transform)
  |> list.filter(is_valid)

// Chain with Result/Option using result.map, result.try
raw
|> parse
|> result.try(validate)
|> result.map(transform)
```

---

## 7. Tail Recursion

Gleam (on the BEAM) optimises **tail calls** — a recursive function whose last expression
is the recursive call uses O(1) stack space.

```gleam
// AVOID — not tail-recursive; stack grows with list length
pub fn sum(nums: List(Int)) -> Int {
  case nums {
    [] -> 0
    [head, ..tail] -> head + sum(tail)   // + happens after recursion
  }
}

// PREFER — tail-recursive accumulator pattern
pub fn sum(nums: List(Int)) -> Int {
  do_sum(nums, 0)
}

fn do_sum(nums: List(Int), acc: Int) -> Int {
  case nums {
    [] -> acc
    [head, ..tail] -> do_sum(tail, acc + head)  // tail call
  }
}
```

Prefer `list.fold` over manual recursion for common patterns:

```gleam
pub fn sum(nums: List(Int)) -> Int {
  list.fold(nums, 0, fn(acc, n) { acc + n })
}
```

---

## 8. Algorithms and Data Structures

Gleam's standard library provides:
- `list` — linked list. O(1) prepend; O(n) access by index.
- `dict` — hash map. O(1) average lookup.
- `set` — hash set.
- `queue` — double-ended queue for O(1) amortised push/pop from both ends.

Choosing the right structure:

| Use Case | Type |
|---|---|
| Sequential ordered data | `List(T)` |
| Key-value lookup | `Dict(K, V)` |
| Unique members | `Set(T)` |
| FIFO queue | `queue.Queue(T)` |
| Fixed tuple of known types | Tuple `#(A, B, C)` |
| Named fields, pattern match | Custom type / record |

### Prefer `list.map` / `list.filter` / `list.fold` over Manual Recursion

```gleam
// Prefer standard combinators — they are tail-call safe and readable
let doubled   = list.map(nums, fn(n) { n * 2 })
let evens     = list.filter(nums, fn(n) { n % 2 == 0 })
let total     = list.fold(nums, 0, fn(acc, n) { acc + n })
let flattened = list.flat_map(nested, fn(xs) { xs })
```

---

## 9. Concurrency (BEAM)

On the Erlang target, concurrency is via **lightweight processes** and **message passing**.

```gleam
import gleam/erlang/process
import gleam/otp/actor

// Actor pattern — encapsulate mutable state in a process
pub type Message {
  Increment
  GetCount(reply_to: process.Subject(Int))
}

pub fn start() -> Result(process.Subject(Message), actor.StartError) {
  actor.start(0, fn(msg, count) {
    case msg {
      Increment ->
        actor.continue(count + 1)
      GetCount(client) -> {
        process.send(client, count)
        actor.continue(count)
      }
    }
  })
}
```

- Treat each process as an isolated unit with its own state — no shared memory.
- Use OTP actors (`gleam_otp`) for long-lived stateful processes with supervision.
- Use `process.Subject` for typed message channels.

---

## 10. Module and Namespace Organisation

```
src/
  my_app/
    domain/
      order.gleam       — Order type, pure transformations
      user.gleam        — User type, pure transformations
    algo/
      stats.gleam       — Pure statistical functions
      search.gleam      — Pure search algorithms
    io/
      http.gleam        — HTTP handlers (side effects)
      db.gleam          — Database (side effects)
    main.gleam          — Entry point, wires everything
```

- `domain/` and `algo/` modules must be **purely functional** — no I/O.
- `io/` modules are the only place where side effects are allowed.
- Expose only necessary functions with `pub`. Internal helpers are module-private.

---

## 11. Naming Conventions

- Modules: `snake_case` file names; accessed as `module_name.function_name`.
- Types: `PascalCase` — `OrderStatus`, `ParseError`.
- Type constructors: `PascalCase` — `Pending`, `Cancelled(reason)`.
- Functions and variables: `snake_case` — `parse_email`, `total_amount`.
- Predicate functions: suffix `_is` or prefix `is_`: `is_valid`, `is_empty`.
- Opaque types: module name reflects what it models, not internal representation.

---

## 12. Error Types

Define a custom error type per module rather than using `String`:

```gleam
pub type ParseError {
  EmptyInput
  InvalidFormat(got: String)
  OutOfRange(value: Int, min: Int, max: Int)
}

pub fn parse(raw: String) -> Result(Int, ParseError) {
  case raw {
    "" -> Error(EmptyInput)
    _  ->
      case int.parse(raw) {
        Error(_)    -> Error(InvalidFormat(raw))
        Ok(n) if n >= 0 && n <= 100 -> Ok(n)
        Ok(n) -> Error(OutOfRange(n, 0, 100))
      }
  }
}
```

---

## 13. Testing

```gleam
import gleeunit
import gleeunit/should

pub fn lerp_test() {
  lerp(0.0, 10.0, 0.5)
  |> should.equal(5.0)
}

pub fn normalise_handles_empty_test() {
  normalise([])
  |> should.equal([])
}
```

- Test pure functions directly — no mocks, no setup.
- Name tests `<function>_<scenario>_test`.
- Group related tests in the same test module mirroring the source module name.
- Use property-based testing (`glychee` or equivalent) for algorithmic functions.

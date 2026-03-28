# Clojure Coding Guidelines

> These guidelines target performance-critical Clojure programs. Pure functions and immutable
> data are the defaults. Performance is achieved through transducers, transient collections,
> type hints, and careful use of the JVM.

---

## 1. Philosophy

- Pure functions are the **natural default** in Clojure. Side effects should be isolated at
  the edges of the system (I/O, state transitions).
- Prefer **data transformations** over stateful mutation. A pipeline of pure functions on
  immutable data is composable, testable, and parallelisable.
- The JVM is capable of very high performance — the obstacles are **reflection**, **boxing**,
  and **unnecessary allocation**. Know which constructs cause these and avoid them in hot paths.
- Use `atom`, `ref`, and `agent` sparingly — they are coordination primitives, not a substitute
  for functional design.

---

## 2. Pure Functions

```clojure
;; Pure function — deterministic, no side effects, no external state
(defn lerp
  ^double [^double a ^double b ^double t]
  (+ a (* t (- b a))))

;; Impure — avoid this pattern; prefer threading state explicitly
(def last-value (atom nil))
(defn lerp-bad [a b t]
  (let [result (+ a (* t (- b a)))]
    (reset! last-value result)   ;; side effect — impure
    result))
```

Guidelines:
- A function is pure if: given the same arguments, it always returns the same value,
  and it produces no observable side effects.
- Name pure data-transformation functions as verbs on data: `normalise-scores`,
  `partition-events`, `compute-delta`.
- Use `defn-` (private) for internal pure helpers.
- Co-locate pure functions in `*.core` or `*.algo` namespaces, separate from I/O namespaces.

---

## 3. Avoiding Reflection

Reflection is the biggest single-function performance killer in Clojure. Always eliminate it
in hot paths.

```clojure
;; Check for reflection warnings at the REPL or in build
(set! *warn-on-reflection* true)

;; AVOID — reflection on every call
(defn bad [x] (.length x))

;; PREFER — type hint eliminates reflection
(defn good [^String x] (.length x))

;; For numeric return types, hint the return too
(defn ^long count-chars [^String s] (.length s))
```

### Common Type Hints

```clojure
^String  ^long  ^double  ^int  ^boolean  ^bytes
^java.util.List  ^java.util.Map
^"[B"    ; byte array
^"[D"    ; double array
```

---

## 4. Avoiding Boxing in Numeric Code

Clojure boxes numbers into objects by default. In tight numeric loops use **primitive hints**
and `loop`/`recur`:

```clojure
;; AVOID — every iteration boxes and unboxes
(reduce + (map #(* % %) (range 1000000)))

;; PREFER — no boxing, primitive arithmetic
(loop [i 0 acc 0.0]
  (if (< i 1000000)
    (recur (inc i) (+ acc (* (double i) (double i))))
    acc))

;; Or use areduce on a primitive array
(let [arr (double-array 1000000 (fn [i] (double i)))]
  (areduce arr i acc 0.0 (+ acc (* (aget arr i) (aget arr i)))))
```

### Unchecked Arithmetic

When you know overflow cannot occur, use unchecked operations:

```clojure
(unchecked-add x y)
(unchecked-multiply x y)
(unchecked-inc x)

;; Or set globally for a namespace (use with care)
(set! *unchecked-math* true)
```

---

## 5. Transducers

Transducers are **composable, allocation-free** transformation pipelines. They separate the
transformation logic from the source and destination, and avoid intermediate collections.

```clojure
;; AVOID — creates intermediate lazy seqs and vectors
(->> data
     (filter odd?)
     (map #(* % %))
     (take 100)
     vec)

;; PREFER — single pass, no intermediate collections
(into []
      (comp (filter odd?)
            (map #(* % %))
            (take 100))
      data)

;; Reuse the transducer across different contexts
(def xf (comp (filter odd?) (map #(* % %)) (take 100)))
(into [] xf data)
(transduce xf + data)  ;; reduce with xf
(sequence xf data)     ;; lazy seq when needed
```

Transducers work with `into`, `transduce`, `sequence`, `eduction`, and `core.async` channels.

---

## 6. Transient Collections

For performance-critical code that builds a large collection locally, use **transient**
collections to avoid copying on every `conj`:

```clojure
;; AVOID — each conj! on a persistent vector allocates a new path in the trie
(defn build-vector [n]
  (loop [i 0 v []]
    (if (< i n)
      (recur (inc i) (conj v i))
      v)))

;; PREFER — transient: O(1) amortised conj!, converted to persistent at the end
(defn build-vector [n]
  (loop [i 0 v (transient [])]
    (if (< i n)
      (recur (inc i) (conj! v i))
      (persistent! v))))
```

Rules:
- Transients must not be shared across threads.
- Always call `persistent!` before returning or sharing the collection.
- Use `transient`, `conj!`, `assoc!`, `dissoc!`, `persistent!`.

---

## 7. Primitive Arrays

When working with large numeric datasets, use **Java primitive arrays** for maximum
performance and minimal GC pressure:

```clojure
(let [data (double-array 1000000)]
  ;; Fill with aset — no boxing for primitive arrays
  (dotimes [i 1000000]
    (aset data i (Math/random)))

  ;; Access with aget — no boxing
  (aget data 42))

;; Type-hinted array operations
(defn sum-doubles [^doubles arr]
  (areduce arr i acc 0.0 (+ acc (aget arr i))))
```

Available: `boolean-array`, `byte-array`, `char-array`, `short-array`, `int-array`,
`long-array`, `float-array`, `double-array`, `object-array`.

---

## 8. Laziness: When to Force Evaluation

Clojure sequences are lazy by default. Laziness avoids unnecessary computation but has
overhead (thunks, chunking, realisation).

```clojure
;; AVOID retaining the head of a lazy seq — causes memory leaks
(def data (range 1e8))
(last data)   ;; holds the entire seq in memory while realising

;; PREFER reducers or transducers over lazy seqs for large datasets
(transduce (map inc) + (range 1e8))

;; Force evaluation eagerly when you know you need all results
(vec (map inc small-data))  ;; ok for small collections
```

When to use laziness:
- Infinite or very large sequences where only a prefix is consumed.
- I/O-backed sequences (lines of a file).

When to avoid laziness:
- Numeric pipelines where you need all results — use transducers.
- When the seq would be fully realised anyway.

---

## 9. Protocols for Polymorphism

Prefer **protocols** over multimethods when dispatch is on a single type and performance
matters. Protocols dispatch via JVM interface dispatch (effectively free):

```clojure
(defprotocol Serialisable
  (serialise [this buffer])
  (byte-size [this]))

(defrecord Point [^double x ^double y]
  Serialisable
  (byte-size [_] 16)
  (serialise [_ ^java.nio.ByteBuffer buf]
    (.putDouble buf x)
    (.putDouble buf y)))
```

Use **multimethods** only when you need open dispatch on arbitrary values (not just type).

---

## 10. Concurrency Primitives

| Primitive | Use Case |
|---|---|
| `atom` | Single value, synchronous compare-and-swap |
| `ref` + `dosync` | Coordinated state across multiple refs (STM) |
| `agent` | Asynchronous single-value updates, fire-and-forget |
| `core.async` channel | Producer/consumer pipelines, backpressure |

```clojure
;; atom — correct pattern: swap! with a pure function
(def counter (atom 0))
(swap! counter inc)             ;; pure update fn
(swap! counter + 5)             ;; pure update with extra args

;; AVOID — reset! without coordination loses concurrent updates
(reset! counter (inc @counter)) ;; race condition!

;; core.async — prefer over raw threads
(require '[clojure.core.async :as a])
(let [ch (a/chan 1024)]         ;; buffered channel
  (a/go-loop []
    (when-let [item (a/<! ch)]
      (process item)
      (recur))))
```

---

## 11. Data-Oriented Design with Maps and Records

- Use **plain maps** for flexible, open data at system boundaries (parsed JSON, config).
- Use **records** (`defrecord`) for closed, typed domain entities — they are faster to
  construct and access than maps (direct field access, not hash lookup).

```clojure
;; Record — fixed fields, faster field access, participates in protocols
(defrecord Order [^long id ^double amount status])
(def o (->Order 1 99.99 :pending))
(:amount o)       ;; direct field access, no hash lookup

;; Destructure records as maps
(let [{:keys [id amount]} o] ...)
```

---

## 12. Namespace Organisation

```clojure
;; my.system.core — pure domain logic
(ns my.system.core
  (:require [clojure.spec.alpha :as s]))

;; my.system.algo — pure algorithms, no I/O
(ns my.system.algo)

;; my.system.io — all side effects isolated here
(ns my.system.io
  (:require [my.system.core :as core]))

;; my.system.main — entry point, wires everything together
(ns my.system.main
  (:require [my.system.io :as io]))
```

---

## 13. Spec and Validation

Use `clojure.spec` at **system boundaries**, not inside pure functions:

```clojure
(require '[clojure.spec.alpha :as s])

(s/def ::amount (s/and double? pos?))
(s/def ::order  (s/keys :req-un [::id ::amount ::status]))

;; Validate at the edge (API handler, queue consumer)
(defn handle-order [raw-order]
  (when-not (s/valid? ::order raw-order)
    (throw (ex-info "Invalid order" (s/explain-data ::order raw-order))))
  (process-order raw-order))  ;; pure processing after validation
```

---

## 14. Naming Conventions

- Namespaces: `kebab-case`, hierarchical: `company.project.module`.
- Functions/vars: `kebab-case`. Predicates end in `?`: `valid?`, `empty?`.
- Destructive/side-effectful functions end in `!`: `reset!`, `swap!`, `send!`.
- Private vars/fns: `defn-` or `^:private`.
- Constants: `*earmuffs*` for dynamic vars; `kebab-case` for `def` constants.
- Record constructors: `->RecordName` (positional), `map->RecordName` (from map).

---

## 15. Tooling

- **deps.edn** (tools.deps) over Leiningen for new projects — simpler, composable.
- **criterium** for micro-benchmarks: `(criterium.core/bench (my-fn args))`.
- **clj-async-profiler** for flame graphs on running JVM code.
- **clj-java-decompiler** to inspect bytecode generated by hot functions.
- Enable `*warn-on-reflection*` in development profiles; fail the build if warnings appear.
- Use **GraalVM native-image** for startup-critical CLI tools.

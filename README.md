# minitest-jruby-server

Boot JRuby once, run Minitest suites on demand from any Ruby client via DRb. A
persistent JRuby daemon loads your entire test suite into memory at startup and
holds it there. Any Ruby process — CRuby, JRuby, whatever — can then trigger a
run over a Unix socket in milliseconds. Because the JVM never restarts, the JIT
compiler observes your code across successive runs and compiles hot paths to
native code, driving per-run overhead from seconds down to single-digit
milliseconds after a handful of warm-up iterations.

---

## How It Works

```
  CRuby client                 JRuby daemon
  ─────────────                ────────────────────────────────────────
  mt-client          ──────►  Daemon#run_tests
    │                DRb/       │
    │                Unix       ├─ Runner#run
    │                socket     │    ├─ Minitest.run_all_suites
    │                           │    │    └─ Minitest::Runnable.runnables
    │                           │    │         (loaded once at boot, kept in memory)
    │                           │    └─ returns plain Hash
    │                ◄──────    └─ Hash travels back over DRb (marshal-safe)
    │
  ResultFormatter
  (prints to stdout)
```

Key design decisions:

- **Load once.** At startup `TestLoader` requires every test file. Each
  `Minitest::Test` subclass registers itself in `Minitest::Runnable.runnables`
  and stays there for the lifetime of the process.

- **Fresh instances per run.** `Minitest.run_all_suites` creates a new instance
  for each test method via `klass.new(method_name).run`, so there is no shared
  state between runs.

- **Marshal-safe results.** `Runner#run` returns a plain Ruby Hash (`seed`,
  `tests`, `failures`, `errors`, `time`, `output`, …). Plain hashes cross the
  DRb wire without requiring the client to have your application code loaded.

- **No forking.** Server and client are separate OS processes communicating
  solely through DRb over a Unix domain socket. The server writes its socket URI
  to `.minitest-jruby.uri`; the client reads it to connect.

---

## Quick Start

```sh
# Terminal 1: Start the JRuby server
jruby -Ilib exe/mt-server \
  --project-root example \
  --load-path app \
  --load-path test \
  --test-path "test/*_test.rb"

# Terminal 2: Run tests from CRuby
ruby -Ilib exe/mt-client --runs 10
```

The server keeps running. Every `mt-client` invocation triggers a fresh
Minitest run in the live JRuby process; you never pay the JVM startup cost
again.

---

## CLI Reference

### mt-server

| Flag | Argument | Default | Description |
|------|----------|---------|-------------|
| `--project-root` | `DIR` | `Dir.pwd` | Root of the project under test |
| `--load-path` | `PATH` | `lib`, `test` | Add to `$LOAD_PATH` (repeatable) |
| `--test-path` | `GLOB` | `test/**/*_test.rb` | Test file glob (repeatable) |
| `--uri-file` | `PATH` | `<project-root>/.minitest-jruby.uri` | Where to write the DRb URI |
| `-V`, `--version` | | | Print version and exit |
| `-h`, `--help` | | | Show help |

### mt-client

| Flag | Argument | Default | Description |
|------|----------|---------|-------------|
| `--uri-file` | `PATH` | `<pwd>/.minitest-jruby.uri` | URI file written by the server |
| `-s`, `--seed` | `SEED` | random | Random seed for test ordering |
| `-i`, `--include` | `PATTERN` | | Run only matching tests (`/regexp/` or string) |
| `-e`, `--exclude` | `PATTERN` | | Skip matching tests |
| `-r`, `--runs` | `N` | `1` | Repeat the run N times (useful for warmup benchmarking) |
| `-v`, `--verbose` | | | Print full Minitest output for each run |
| `--info` | | | Show server info and exit |
| `--shutdown` | | | Ask the server to stop |
| `-V`, `--version` | | | Print version and exit |
| `-h`, `--help` | | | Show help |

---

## Example

The repository includes a small example application under `example/` with four
test suites (`CalculatorTest`, `FibonacciTest`, `MatrixMathTest`,
`StringUtilsTest`).

```sh
# Terminal 1
jruby -Ilib exe/mt-server \
  --project-root example \
  --load-path app \
  --load-path test \
  --test-path "test/*_test.rb"
```

Expected server output:

```
[mt-server] Booting on jruby 10.0.4.0...
[mt-server] Boot complete in 0.0288s
[mt-server] 4 suites, 22 methods
[mt-server] Listening at drbunix:/tmp/minitest_jruby.12345
[mt-server] URI file: example/.minitest-jruby.uri
[mt-server] Ctrl-C to stop
```

```sh
# Terminal 2
ruby -Ilib exe/mt-client --runs 10 --project-root example
```

Expected client output:

```
Connected to test daemon
  Engine:  jruby 10.0.4.0
  PID:     12345
  Uptime:  3.2s
  Runs:    0

Run #1   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0314s
Run #2   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0562s
Run #3   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.1425s
...
Run #10  PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0173s

  Fastest: 0.0173s
  Slowest: 0.1425s
  Median:  0.0360s
  Mean:    0.0444s
  Trend:   last 3 runs 62.5% faster than first 3
```

---

## JVM Warmup

The JVM starts cold. Expect this rough progression:

| Run | Typical time | What is happening |
|-----|-------------|-------------------|
| 1 | 1–3 s | Interpreter mode; class loading, bytecode verification |
| 2–3 | 100–500 ms | Tiered compilation begins on hot methods |
| 4–6 | 5–50 ms | C1 compiled; inner loops promoted to C2 |
| 7+ | 2–10 ms | Fully JIT-compiled; overhead is now pure Ruby logic |

The `--runs N` flag exists precisely to let you observe this curve. For a
typical TDD workflow — running the suite many times per minute — runs 2 and
beyond are what matter. Once the JIT is warm the server can sustain sub-10 ms
turnaround indefinitely.

If your suite is substantially larger, the plateau will still be reached; it
just takes a few more runs. The shape of the curve (steep drop then flat) is
consistent across suite sizes.

---

## Ruby API

You can drive the server programmatically without the CLIs:

```ruby
require "minitest/jruby/server"

# Config defaults to reading .minitest-jruby.uri in the current directory
config = Minitest::JRuby::Server::Config.new(
  project_root: "/path/to/project",
  uri_file:     "/path/to/project/.minitest-jruby.uri",
)

client = Minitest::JRuby::Server::Client.new(config: config)
client.connect   # raises ServerNotRunning if the daemon is not up

# Run all tests with a fixed seed
result = client.run_tests(seed: 42)

# Run a subset
result = client.run_tests(seed: 42, include_filter: "/Calculator/")

puts result[:passed]     # => true
puts result[:tests]      # => 5
puts result[:time]       # => 0.0063
puts result[:output]     # => full Minitest text output

# Query the daemon
info = client.info       # => { engine:, pid:, runs_so_far:, uptime: }

# Graceful shutdown
client.shutdown_server
```

`run_tests` always returns a plain Hash — no Minitest objects cross the wire.
This means the client process does not need your application code on its load
path.

---

## How It Works Internally

`Minitest.run_all_suites` (added in Minitest 6) iterates
`Minitest::Runnable.runnables`, applies seed-based shuffling and include/exclude
filters, then calls `klass.runnable_methods.each { |m| klass.new(m).run(reporter) }`.

Every call to `run_tests` on the daemon goes through this path from scratch:
new instances, new shuffled order, independently reported. The daemon holds no
per-run state — only the loaded class objects and a monotonic run counter used
for display. This stateless design means:

- Runs are reproducible with the same seed.
- One flaky test does not poison subsequent runs.
- Filters work identically to native `ruby -Ilib -e "require 'minitest/autorun'"` runs.

The daemon wraps each run in a `Mutex` so concurrent clients (uncommon but
possible) do not interleave output.

---

## Requirements

- Ruby 3.1+ (client side)
- JRuby 10+ (server side)
- Minitest 6.0+ (both sides; `Minitest.run_all_suites` is a 6.0 addition)

The client can be any Ruby implementation — CRuby, TruffleRuby, etc. Only the
server must run on JRuby for the warmup benefit to apply.

---

## License

MIT. See [LICENSE.txt](LICENSE.txt).

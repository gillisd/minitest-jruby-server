# minitest-jruby-server

Boot JRuby once, run Minitest suites on demand from any Ruby client via DRb. A
persistent JRuby daemon loads your entire test suite into memory at startup and
holds it there. Any Ruby process — CRuby, JRuby, whatever — can then trigger a
run over a Unix socket in milliseconds. Because the JVM never restarts, the JIT
compiler observes your code across successive runs and compiles hot paths to
native code, driving per-run overhead from seconds down to single-digit
milliseconds after a handful of warm-up iterations.

---

## Installation

Add to your Gemfile:

```ruby
gem "minitest-jruby-server"
```

Then `bundle install`. This installs two executables: `mt-server` and `mt-client`.

---

## Quick Start

```sh
# Terminal 1: Start the server under JRuby
jruby -S bundle exec mt-server

# Terminal 2: Run tests from CRuby
bundle exec mt-client
```

That's it. The server loads tests from `test/**/*_test.rb`, boots once, and
waits. The client connects, triggers a run, and prints results. Run it again —
the JVM is already warm.

For repeated runs to observe JIT warmup:

```sh
bundle exec mt-client --runs 10
```

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

- **Load once.** `TestLoader` requires every test file at startup. Each
  `Minitest::Test` subclass registers itself in `Minitest::Runnable.runnables`
  and stays there for the lifetime of the process.

- **Fresh instances per run.** `Minitest.run_all_suites` creates a new instance
  for each test method via `klass.new(method_name).run` — no shared state
  between runs.

- **Marshal-safe results.** `Runner#run` returns a plain Ruby Hash. No Minitest
  objects cross the wire, so the client doesn't need your app code loaded.

- **No forking.** Server and client are separate OS processes communicating
  through DRb over a Unix domain socket.

---

## CLI Reference

### mt-server

Start under JRuby: `jruby -S bundle exec mt-server [options]`

| Flag | Argument | Default | Description |
|------|----------|---------|-------------|
| `--project-root` | `DIR` | `Dir.pwd` | Root of the project under test |
| `--load-path` | `PATH` | `lib`, `test` | Add to `$LOAD_PATH` (repeatable) |
| `--test-path` | `GLOB` | `test/**/*_test.rb` | Test file glob (repeatable) |
| `--uri-file` | `PATH` | `<root>/.minitest-jruby.uri` | Where to write the DRb URI |
| `-V`, `--version` | | | Print version and exit |
| `-h`, `--help` | | | Show help |

### mt-client

Run under any Ruby: `bundle exec mt-client [options]`

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
`StringUtilsTest`) — 22 test methods total.

```sh
# Terminal 1
jruby -S bundle exec mt-server \
  --project-root example \
  --load-path app \
  --load-path test \
  --test-path "test/*_test.rb"
```

```
[mt-server] Booting on jruby 10.0.4.0...
[mt-server] Boot complete in 0.0110s
[mt-server] 4 suites, 22 methods
[mt-server] Listening at drbunix:/tmp/minitest_jruby.12345
[mt-server] URI file: example/.minitest-jruby.uri
[mt-server] Ctrl-C to stop
```

```sh
# Terminal 2
bundle exec mt-client --uri-file example/.minitest-jruby.uri --runs 5
```

```
Connected to test daemon
  Engine:  jruby 10.0.4.0
  PID:     12345
  Uptime:  0.7s
  Runs:    0

Run #1   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0236s
Run #2   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0162s
Run #3   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0391s
Run #4   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0138s
Run #5   PASS  22 tests, 27 assertions, 0 failures, 0 errors in 0.0097s

  Fastest: 0.0097s
  Slowest: 0.0391s
  Median:  0.0162s
  Mean:    0.0205s
```

Filter to a single suite:

```sh
bundle exec mt-client --uri-file example/.minitest-jruby.uri --include "/MatrixMath/"
```

---

## JVM Warmup

The JVM starts cold. Expect this rough progression:

| Run | Typical time | What is happening |
|-----|-------------|-------------------|
| 1 | 20–40 ms | Interpreter mode; first pass through test code |
| 2–3 | 15–40 ms | Tiered compilation begins on hot methods |
| 4–5 | 10–15 ms | C1 compiled; inner loops promoted to C2 |
| 6+ | 3–10 ms | Fully JIT-compiled; overhead is pure Ruby logic |

The `--runs N` flag exists precisely to observe this curve. For a typical TDD
workflow — running the suite many times per minute — runs 2+ are what matter.
Once the JIT is warm the server sustains sub-10ms turnaround indefinitely.

---

## Ruby API

You can drive the server programmatically without the CLIs:

```ruby
require "minitest/jruby/server"

config = Minitest::JRuby::Server::Config.new
client = Minitest::JRuby::Server::Client.new(config: config)
client.connect   # raises ServerNotRunning if the daemon is not up

# Run all tests
result = client.run_tests(seed: 42)

# Run a subset
result = client.run_tests(include_filter: "/Calculator/")

result[:passed]     # => true
result[:tests]      # => 5
result[:time]       # => 0.0063
result[:output]     # => full Minitest text output

# Query the daemon
client.info         # => { engine:, pid:, runs_so_far:, uptime: }

# Graceful shutdown
client.shutdown_server
```

---

## How It Works Internally

`Minitest.run_all_suites` (added in Minitest 6) iterates
`Minitest::Runnable.runnables`, applies seed-based shuffling and include/exclude
filters, then runs each test method as `klass.new(method_name).run`.

Every `run_tests` call goes through this path from scratch: new instances, new
shuffled order, independently reported. The daemon holds no per-run state — only
the loaded class objects and a monotonic run counter. This means:

- Runs are reproducible with the same seed.
- One flaky test does not poison subsequent runs.
- Filters work identically to `ruby -e "require 'minitest/autorun'"` runs.

The daemon wraps each run in a `Mutex` so concurrent clients do not interleave.

---

## Requirements

- Ruby 3.1+ (client side)
- JRuby 10+ (server side)
- Minitest 6.0+ (both sides)

The client can be any Ruby implementation. Only the server must run on JRuby
for the warmup benefit.

---

## License

MIT. See [LICENSE.txt](LICENSE.txt).

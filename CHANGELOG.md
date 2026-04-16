# Changelog

## 0.1.0 — 2026-04-16

Initial release.

- Persistent JRuby test daemon with DRb over Unix sockets
- `exe/mt-server` — boots JRuby, loads tests, serves via DRb
- `exe/mt-client` — connects from any Ruby, triggers runs, displays results
- Zeitwerk autoloading under `Minitest::JRuby::Server`
- Include/exclude filters, seed control, multi-run benchmarking
- JVM JIT warmup: sub-10ms runs after 5-7 iterations
- Example app with matrix math for warmup demonstration

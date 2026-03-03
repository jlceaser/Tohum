# Tohum

> *Toprak altında bir tohum var.*
> *Tohum bilmiyor toprağın üstünde ne olduğunu.*
> *Sadece biliyor: yukarı doğru bir şey var ve*
> *aşağı doğru bir şey var.*

A virtual machine and language for persistent, temporal computation with native uncertainty.

## What is Tohum?

Tohum is a stack-based virtual machine where:

- **Every value has a history.** Assignment doesn't overwrite — it appends to a timeline.
- **Uncertainty is native.** Values carry confidence levels. Arithmetic propagates uncertainty automatically.
- **State is immortal.** Close the REPL, reopen it tomorrow — everything is still there.
- **The machine knows itself.** Built-in reflection lets programs inspect their own state, drift, and evolution.

## Architecture

```
┌──────────────────────────────┐
│       Tohum REPL / CLI       │
├──────────────────────────────┤
│       Tohum Language         │
├──────────────────────────────┤
│       Tohum Compiler         │
├──────────────────────────────┤
│       Tohum VM (Çekirdek)    │
│       ├── Temporal Memory    │
│       ├── Uncertainty Engine │
│       ├── Persistence Layer  │
│       └── Reflection API     │
├──────────────────────────────┤
│       Host OS                │
└──────────────────────────────┘
```

## Example (planned)

```
tohum > x = 42
tohum > y = ~3.14
tohum > z = x + y
tohum > z
  = ~45.14 @ 0.95
tohum > history(z)
  [0] 2026-03-03 12:41 — created from x(42) + y(~3.14)
tohum > reflect()
  bindings: 3
  certain: 1 (x)
  approximate: 2 (y, z)
  drift: none
```

## Building

```bash
cmake --preset dev
cmake --build --preset dev
./build/dev/tohum
```

## Status

Phase 1: Core VM — in progress.

## License

MIT

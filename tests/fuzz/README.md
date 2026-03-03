# Fuzzing for Amethe

This directory contains fuzzing configurations and targets for Amethe components.

## Strategy

We leverage Zig's built-in testing and custom fuzzing harnesses to ensure the robustness of our FFI and core logic.

## Running Fuzzers

Fuzzing is integrated into our quality assurance process. To run tests with fuzzing-like coverage:

```bash
just test
```

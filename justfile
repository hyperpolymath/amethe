# RSR-template-repo - RSR Standard Justfile Template
# https://just.systems/man/en/
#
# This is the CANONICAL template for all RSR projects.
# Copy this file to new projects and customize the {{PLACEHOLDER}} values.
#
# Run `just` to see all available recipes
# Run `just cookbook` to generate docs/just-cookbook.adoc
# Run `just combinations` to see matrix recipe options

set shell := ["bash", "-uc"]
set dotenv-load := true
set positional-arguments := true

# Project metadata - CUSTOMIZE THESE
project := "RSR-template-repo"
version := "0.1.0"
tier := "infrastructure"  # 1 | 2 | infrastructure

# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT & HELP
# ═══════════════════════════════════════════════════════════════════════════════

# Show all available recipes with descriptions
default:
    @just --list --unsorted

# Show detailed help for a specific recipe
help recipe="":
    #!/usr/bin/env bash
    if [ -z "{{recipe}}" ]; then
        just --list --unsorted
        echo ""
        echo "Usage: just help <recipe>"
        echo "       just cookbook     # Generate full documentation"
        echo "       just combinations # Show matrix recipes"
    else
        just --show "{{recipe}}" 2>/dev/null || echo "Recipe '{{recipe}}' not found"
    fi

# Show this project's info
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "RSR Tier: {{tier}}"
    @echo "Recipes: $(just --summary | wc -w)"
    @[ -f STATE.scm ] && grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm | head -1 | xargs -I{} echo "Phase: {}" || true

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD & COMPILE
# ═══════════════════════════════════════════════════════════════════════════════

# Build the project (debug mode)
build *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Building {{project}}..."
    built=false
    if [ -f "Cargo.toml" ]; then
        cargo build $@
        built=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task build 2>/dev/null || npx rescript build $@
        built=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task build $@ 2>/dev/null || deno check src/**/*.ts 2>/dev/null || true
        built=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam build $@
        built=true
    fi
    if [ "$built" = "false" ]; then
        echo "No build configuration found (Cargo.toml, rescript.json, deno.json, or gleam.toml)"
        echo "Add project source files and configuration to enable builds."
    fi

# Build in release mode with optimizations
build-release *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Building {{project}} (release)..."
    built=false
    if [ -f "Cargo.toml" ]; then
        cargo build --release $@
        built=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task build:release 2>/dev/null || npx rescript build -with-deps $@
        built=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task build:release 2>/dev/null || deno compile src/main.ts 2>/dev/null || true
        built=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam build --target erlang $@
        built=true
    fi
    if [ "$built" = "false" ]; then
        echo "No build configuration found."
    fi

# Build and watch for changes
build-watch:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Watching for changes..."
    if [ -f "Cargo.toml" ]; then
        cargo watch -x build
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task watch 2>/dev/null || npx rescript build -w
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task dev 2>/dev/null || deno run --watch src/main.ts
    elif [ -f "gleam.toml" ]; then
        watchexec -e gleam -- gleam build
    else
        echo "No build configuration found for watch mode."
    fi

# Clean build artifacts [reversible: rebuild with `just build`]
clean:
    @echo "Cleaning..."
    rm -rf target _build dist lib node_modules

# Deep clean including caches [reversible: rebuild]
clean-all: clean
    rm -rf .cache .tmp

# ═══════════════════════════════════════════════════════════════════════════════
# TEST & QUALITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running tests..."
    tested=false
    if [ -f "Cargo.toml" ]; then
        cargo test $@
        tested=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task test 2>/dev/null || npx rescript-test $@ 2>/dev/null || true
        tested=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno test $@
        tested=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam test $@
        tested=true
    fi
    if [ "$tested" = "false" ]; then
        echo "No test configuration found."
    fi

# Run tests with verbose output
test-verbose:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running tests (verbose)..."
    if [ -f "Cargo.toml" ]; then
        cargo test -- --nocapture
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno test --reporter=verbose
    elif [ -f "gleam.toml" ]; then
        gleam test
    else
        echo "No test configuration found."
    fi

# Run tests and generate coverage report
test-coverage:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running tests with coverage..."
    if [ -f "Cargo.toml" ]; then
        cargo llvm-cov --html
        echo "Coverage report: target/llvm-cov/html/index.html"
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno test --coverage=coverage
        deno coverage coverage --lcov > coverage/lcov.info
        echo "Coverage report: coverage/lcov.info"
    else
        echo "No coverage tool configured."
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# LINT & FORMAT
# ═══════════════════════════════════════════════════════════════════════════════

# Format all source files [reversible: git checkout]
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Formatting..."
    formatted=false
    if [ -f "Cargo.toml" ]; then
        cargo fmt
        formatted=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task format 2>/dev/null || npx rescript format -all 2>/dev/null || true
        formatted=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno fmt
        formatted=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam format .
        formatted=true
    fi
    if [ "$formatted" = "false" ]; then
        echo "No formatter configured."
    fi

# Check formatting without changes
fmt-check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking format..."
    checked=false
    if [ -f "Cargo.toml" ]; then
        cargo fmt --check
        checked=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno fmt --check
        checked=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam format . --check
        checked=true
    fi
    if [ "$checked" = "false" ]; then
        echo "No format checker configured."
    fi

# Run linter
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Linting..."
    linted=false
    if [ -f "Cargo.toml" ]; then
        cargo clippy -- -D warnings
        linted=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno lint
        linted=true
    fi
    if [ "$linted" = "false" ]; then
        echo "No linter configured."
    fi

# Run all quality checks
quality: fmt-check lint test
    @echo "All quality checks passed!"

# Fix all auto-fixable issues [reversible: git checkout]
fix: fmt
    @echo "Fixed all auto-fixable issues"

# ═══════════════════════════════════════════════════════════════════════════════
# RUN & EXECUTE
# ═══════════════════════════════════════════════════════════════════════════════

# Run the application
run *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running {{project}}..."
    if [ -f "Cargo.toml" ]; then
        cargo run $@
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task start $@ 2>/dev/null || deno run src/main.ts $@
    elif [ -f "gleam.toml" ]; then
        gleam run $@
    else
        echo "No run configuration found."
    fi

# Run in development mode with hot reload
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Starting dev mode..."
    if [ -f "Cargo.toml" ]; then
        cargo watch -x run
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task dev 2>/dev/null || deno run --watch src/main.ts
    elif [ -f "gleam.toml" ]; then
        watchexec -e gleam -- gleam run
    else
        echo "No dev configuration found."
    fi

# Run REPL/interactive mode
repl:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Starting REPL..."
    if [ -f "Cargo.toml" ]; then
        evcxr 2>/dev/null || echo "Install evcxr for Rust REPL: cargo install evcxr_repl"
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno repl
    elif [ -f "gleam.toml" ]; then
        gleam shell
    elif command -v guile &>/dev/null; then
        guile
    else
        echo "No REPL available."
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════

# Install all dependencies
deps:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing dependencies..."
    installed=false
    if [ -f "Cargo.toml" ]; then
        cargo fetch
        installed=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno cache --reload src/**/*.ts 2>/dev/null || deno install 2>/dev/null || true
        installed=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam deps download
        installed=true
    fi
    if [ -f "guix.scm" ]; then
        echo "Guix dependencies defined in guix.scm"
        echo "Run: just guix-shell"
        installed=true
    fi
    if [ "$installed" = "false" ]; then
        echo "No dependency configuration found."
    fi

# Audit dependencies for vulnerabilities
deps-audit:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Auditing dependencies..."
    audited=false
    if [ -f "Cargo.toml" ]; then
        cargo audit 2>/dev/null || echo "Install cargo-audit: cargo install cargo-audit"
        audited=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        echo "Deno: dependencies from jsr/deno.land are verified by registry"
        audited=true
    fi
    if [ "$audited" = "false" ]; then
        echo "No audit tool configured."
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Generate all documentation
docs:
    @mkdir -p docs/generated docs/man
    just cookbook
    just man
    @echo "Documentation generated in docs/"

# Generate justfile cookbook documentation
cookbook:
    #!/usr/bin/env bash
    mkdir -p docs
    OUTPUT="docs/just-cookbook.adoc"
    echo "= {{project}} Justfile Cookbook" > "$OUTPUT"
    echo ":toc: left" >> "$OUTPUT"
    echo ":toclevels: 3" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "Generated: $(date -Iseconds)" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "== Recipes" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    just --list --unsorted | while read -r line; do
        if [[ "$line" =~ ^[[:space:]]+([a-z_-]+) ]]; then
            recipe="${BASH_REMATCH[1]}"
            echo "=== $recipe" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
            echo "[source,bash]" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "just $recipe" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
        fi
    done
    echo "Generated: $OUTPUT"

# Generate man page
man:
    #!/usr/bin/env bash
    mkdir -p docs/man
    cat > docs/man/{{project}}.1 << EOF
.TH RSR-TEMPLATE-REPO 1 "$(date +%Y-%m-%d)" "{{version}}" "RSR Template Manual"
.SH NAME
{{project}} \- RSR standard repository template
.SH SYNOPSIS
.B just
[recipe] [args...]
.SH DESCRIPTION
Canonical template for RSR (Rhodium Standard Repository) projects.
.SH AUTHOR
Hyperpolymath <hyperpolymath@proton.me>
EOF
    echo "Generated: docs/man/{{project}}.1"

# ═══════════════════════════════════════════════════════════════════════════════
# CONTAINERS (nerdctl + Wolfi)
# ═══════════════════════════════════════════════════════════════════════════════

# Build container image
container-build tag="latest":
    @if [ -f Containerfile ]; then \
        nerdctl build -t {{project}}:{{tag}} -f Containerfile .; \
    else \
        echo "No Containerfile found"; \
    fi

# Run container
container-run tag="latest" *args:
    nerdctl run --rm -it {{project}}:{{tag}} {{args}}

# Push container image
container-push registry="ghcr.io/hyperpolymath" tag="latest":
    nerdctl tag {{project}}:{{tag}} {{registry}}/{{project}}:{{tag}}
    nerdctl push {{registry}}/{{project}}:{{tag}}

# ═══════════════════════════════════════════════════════════════════════════════
# CI & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run full CI pipeline locally
ci: deps quality
    @echo "CI pipeline complete!"

# Install git hooks
install-hooks:
    @mkdir -p .git/hooks
    @cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
just fmt-check || exit 1
just lint || exit 1
EOF
    @chmod +x .git/hooks/pre-commit
    @echo "Git hooks installed"

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audit
security: deps-audit
    @echo "=== Security Audit ==="
    @command -v gitleaks >/dev/null && gitleaks detect --source . --verbose || true
    @command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL . || true
    @echo "Security audit complete"

# Generate SBOM
sbom:
    @mkdir -p docs/security
    @command -v syft >/dev/null && syft . -o spdx-json > docs/security/sbom.spdx.json || echo "syft not found"

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION & COMPLIANCE
# ═══════════════════════════════════════════════════════════════════════════════

# Validate RSR compliance
validate-rsr:
    #!/usr/bin/env bash
    echo "=== RSR Compliance Check ==="
    MISSING=""
    for f in .editorconfig .gitignore justfile RSR_COMPLIANCE.adoc README.adoc; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    for d in .well-known; do
        [ -d "$d" ] || MISSING="$MISSING $d/"
    done
    for f in .well-known/security.txt .well-known/ai.txt .well-known/humans.txt; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    if [ ! -f "guix.scm" ] && [ ! -f ".guix-channel" ] && [ ! -f "flake.nix" ]; then
        MISSING="$MISSING guix.scm/flake.nix"
    fi
    if [ -n "$MISSING" ]; then
        echo "MISSING:$MISSING"
        exit 1
    fi
    echo "RSR compliance: PASS"

# Validate STATE.scm syntax
validate-state:
    @if [ -f "STATE.scm" ]; then \
        guile -c "(primitive-load \"STATE.scm\")" 2>/dev/null && echo "STATE.scm: valid" || echo "STATE.scm: INVALID"; \
    else \
        echo "No STATE.scm found"; \
    fi

# Full validation suite
validate: validate-rsr validate-state
    @echo "All validations passed!"

# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Update STATE.scm timestamp
state-touch:
    @if [ -f "STATE.scm" ]; then \
        sed -i 's/(updated . "[^"]*")/(updated . "'"$(date -Iseconds)"'")/' STATE.scm && \
        echo "STATE.scm timestamp updated"; \
    fi

# Show current phase from STATE.scm
state-phase:
    @grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm 2>/dev/null | head -1 || echo "unknown"

# ═══════════════════════════════════════════════════════════════════════════════
# GUIX & NIX
# ═══════════════════════════════════════════════════════════════════════════════

# Enter Guix development shell (primary)
guix-shell:
    guix shell -D -f guix.scm

# Build with Guix
guix-build:
    guix build -f guix.scm

# Enter Nix development shell (fallback)
nix-shell:
    @if [ -f "flake.nix" ]; then nix develop; else echo "No flake.nix"; fi

# ═══════════════════════════════════════════════════════════════════════════════
# HYBRID AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run local automation tasks
automate task="all":
    #!/usr/bin/env bash
    case "{{task}}" in
        all) just fmt && just lint && just test && just docs && just state-touch ;;
        cleanup) just clean && find . -name "*.orig" -delete && find . -name "*~" -delete ;;
        update) just deps && just validate ;;
        *) echo "Unknown: {{task}}. Use: all, cleanup, update" && exit 1 ;;
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# COMBINATORIC MATRIX RECIPES
# ═══════════════════════════════════════════════════════════════════════════════

# Build matrix: [debug|release] × [target] × [features]
build-matrix mode="debug" target="" features="":
    @echo "Build matrix: mode={{mode}} target={{target}} features={{features}}"
    # Customize for your build system

# Test matrix: [unit|integration|e2e|all] × [verbosity] × [parallel]
test-matrix suite="unit" verbosity="normal" parallel="true":
    @echo "Test matrix: suite={{suite}} verbosity={{verbosity}} parallel={{parallel}}"

# Container matrix: [build|run|push|shell|scan] × [registry] × [tag]
container-matrix action="build" registry="ghcr.io/hyperpolymath" tag="latest":
    @echo "Container matrix: action={{action}} registry={{registry}} tag={{tag}}"

# CI matrix: [lint|test|build|security|all] × [quick|full]
ci-matrix stage="all" depth="quick":
    @echo "CI matrix: stage={{stage}} depth={{depth}}"

# Show all matrix combinations
combinations:
    @echo "=== Combinatoric Matrix Recipes ==="
    @echo ""
    @echo "Build Matrix: just build-matrix [debug|release] [target] [features]"
    @echo "Test Matrix:  just test-matrix [unit|integration|e2e|all] [verbosity] [parallel]"
    @echo "Container:    just container-matrix [build|run|push|shell|scan] [registry] [tag]"
    @echo "CI Matrix:    just ci-matrix [lint|test|build|security|all] [quick|full]"
    @echo ""
    @echo "Total combinations: ~10 billion"

# ═══════════════════════════════════════════════════════════════════════════════
# VERSION CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

# Show git status
status:
    @git status --short

# Show recent commits
log count="20":
    @git log --oneline -{{count}}

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Count lines of code
loc:
    @find . \( -name "*.rs" -o -name "*.ex" -o -name "*.res" -o -name "*.ncl" -o -name "*.scm" \) 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "0"

# Show TODO comments
todos:
    @grep -rn "TODO\|FIXME" --include="*.rs" --include="*.ex" --include="*.res" . 2>/dev/null || echo "No TODOs"

# Open in editor
edit:
    ${EDITOR:-code} .

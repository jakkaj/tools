# Justfile for jk-tools development and build automation
# Requires: just, uv

# Default recipe - show available commands
default:
    @just --list

# Show this help message
help:
    @echo "JK-Tools Build and Development Commands"
    @echo ""
    @echo "Environment Setup:"
    @echo "  just setup         - Complete development environment setup"
    @echo "  just venv          - Create virtual environment"
    @echo "  just install       - Install package in editable mode"
    @echo "  just clean         - Remove build artifacts and venv"
    @echo ""
    @echo "Build & Distribution:"
    @echo "  just build         - Build distribution packages (wheel + sdist)"
    @echo "  just publish       - Publish to PyPI (requires credentials)"
    @echo "  just publish-test  - Publish to TestPyPI"
    @echo ""
    @echo "Testing & Quality:"
    @echo "  just test          - Run the CLI to verify it works"
    @echo "  just test-uvx      - Test uvx execution"
    @echo "  just test-install  - Test full installation flow"
    @echo "  just lint          - Run code quality checks"
    @echo ""
    @echo "Development:"
    @echo "  just dev           - Run in development mode"
    @echo "  just shell         - Activate development shell"
    @echo ""
    @echo "Skills (via npx skills):"
    @echo "  just install-skills              - Install all skills globally to every CLI (from jakkaj/tools remote)"
    @echo "  just install-skills-local        - Install all skills project-local to every CLI (from jakkaj/tools remote)"
    @echo "  just install-skills-from-source  - Install all skills globally to every CLI from THIS working tree (test local branch)"
    @echo ""
    @echo "Compound loop:"
    @echo "  just compound-value              - Render harness-3-retro --harvest --json output as a compact terminal view (reads JSON on stdin)"
    @echo ""
    @echo "Diagnostics:"
    @echo "  just doctor-skills               - Diagnose skill deployment (canonical store + symlinks + orphan legacy paths)"
    @echo ""

# Complete development environment setup
setup: venv install
    @echo "✅ Development environment ready!"
    @echo ""
    @echo "To activate the virtual environment:"
    @echo "  source .venv/bin/activate"
    @echo ""
    @echo "To run the CLI:"
    @echo "  just dev"
    @echo "  OR"
    @echo "  jk-tools-setup --dev-mode ."

# Create virtual environment with uv
venv:
    @echo "Creating virtual environment..."
    uv venv
    @echo "✅ Virtual environment created at .venv/"

# Install package in editable mode
install:
    @echo "Installing package in editable mode..."
    uv pip install -e .
    @echo "✅ Package installed"

# Clean build artifacts and virtual environment
clean:
    @echo "Cleaning build artifacts..."
    rm -rf build/ dist/ *.egg-info .venv/ __pycache__/ src/**/__pycache__/
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    find . -type f -name "*.pyo" -delete 2>/dev/null || true
    @echo "✅ Cleaned"

# Build distribution packages
build: clean
    @echo "Building distribution packages..."
    uv build
    @echo "✅ Built packages:"
    @ls -lh dist/

# Build and show contents
build-inspect: build
    @echo ""
    @echo "📦 Package contents:"
    @echo ""
    @unzip -l dist/*.whl | grep -E "(install/|scripts/|agents/|\.py)" || true

# Publish to PyPI
publish: build
    @echo "Publishing to PyPI..."
    uv publish
    @echo "✅ Published to PyPI"

# Publish to TestPyPI
publish-test: build
    @echo "Publishing to TestPyPI..."
    uv publish --index-url https://test.pypi.org/legacy/
    @echo "✅ Published to TestPyPI"

# Test the CLI help
test:
    @echo "Testing CLI..."
    @if [ -d ".venv" ]; then \
        source .venv/bin/activate && jk-tools-setup --help; \
    else \
        echo "❌ Virtual environment not found. Run: just setup"; \
        exit 1; \
    fi

# Test uvx execution from local directory
test-uvx:
    @echo "Testing uvx execution..."
    uvx --from . jk-tools-setup --help

# Test full installation flow (in dev mode)
test-install:
    @echo "Testing installation with dev mode..."
    @if [ -d ".venv" ]; then \
        source .venv/bin/activate && jk-tools-setup --dev-mode . --help; \
    else \
        uvx --from . jk-tools-setup --dev-mode . --help; \
    fi

# Run development version
dev *ARGS:
    @if [ -d ".venv" ]; then \
        source .venv/bin/activate && jk-tools-setup --dev-mode . {{ARGS}}; \
    else \
        echo "❌ Virtual environment not found. Run: just setup"; \
        exit 1; \
    fi

# Run with update flag in dev mode
dev-update:
    @just dev --update

# Activate development shell (shows instructions)
shell:
    @echo "To activate the development shell, run:"
    @echo "  source .venv/bin/activate"

# Run basic linting and checks
lint:
    @echo "Running code quality checks..."
    @echo ""
    @echo "📝 Checking Python syntax..."
    python3 -m py_compile src/jk_tools/*.py
    @echo "✅ Python syntax OK"
    @echo ""
    @echo "📝 Checking for common issues..."
    @grep -r "print(" src/jk_tools/ && echo "⚠️  Found print() statements (use console.print instead)" || echo "✅ No print() statements"
    @echo ""
    @echo "✅ Basic checks passed"

# Show package information
info:
    @echo "📦 Package Information"
    @echo ""
    @echo "Name: jk-tools"
    @echo "Location: $(pwd)"
    @echo ""
    @if [ -d ".venv" ]; then \
        echo "✅ Virtual environment: .venv/"; \
    else \
        echo "❌ Virtual environment: Not created (run: just setup)"; \
    fi
    @echo ""
    @if [ -d "dist" ]; then \
        echo "📦 Built distributions:"; \
        ls -lh dist/ 2>/dev/null || echo "  (none)"; \
    fi

# Check dependencies are available
check-deps:
    @echo "Checking dependencies..."
    @command -v uv >/dev/null 2>&1 && echo "✅ uv installed" || (echo "❌ uv not found - install from https://github.com/astral-sh/uv" && exit 1)
    @command -v just >/dev/null 2>&1 && echo "✅ just installed" || echo "ℹ️  just not required for basic usage"
    @command -v python3 >/dev/null 2>&1 && echo "✅ python3 installed" || (echo "❌ python3 not found" && exit 1)

# Quick start - setup and test
quick-start: check-deps setup test
    @echo ""
    @echo "✅ Quick start complete!"
    @echo ""
    @echo "Try running:"
    @echo "  just dev --help"

# Install from local build (test installation)
install-from-build: build
    @echo "Installing from built wheel..."
    uvx --from dist/*.whl jk-tools-setup --help

# Show what files will be packaged
show-package-files:
    @echo "Files that will be included in the package:"
    @echo ""
    @echo "📁 Python source:"
    @find src/jk_tools -type f -name "*.py"
    @echo ""
    @echo "📁 Data files (install/):"
    @find install -type f 2>/dev/null | head -20
    @echo ""
    @echo "📁 Data files (scripts/):"
    @find scripts -type f 2>/dev/null
    @echo ""
    @echo "📁 Data files (agents/):"
    @find agents -type f 2>/dev/null | head -20

# Development cycle: clean, rebuild, test
dev-cycle: clean setup test
    @echo "✅ Development cycle complete"

# CI/CD simulation - run all checks
ci: check-deps clean setup test test-uvx lint build
    @echo ""
    @echo "✅ All CI checks passed!"

# Install all skills globally to every supported CLI (Claude Code, Codex, OpenCode, Copilot CLI, Pi)
install-skills:
    @echo "Installing all skills globally to every supported CLI..."
    npx skills@latest add jakkaj/tools \
        -a claude-code -a codex -a opencode -a github-copilot -a pi -g
    @echo "✅ Skills installed globally"

# Install all skills project-local (writes to ./.claude/skills, ./.codex/skills, ./.opencode/skills, ./.agents/skills, ./.pi/skills)
install-skills-local:
    @echo "Installing all skills project-local to every supported CLI..."
    npx skills@latest add jakkaj/tools \
        -a claude-code -a codex -a opencode -a github-copilot -a pi
    @echo "✅ Skills installed project-local"

# Install all skills GLOBALLY from this working tree (use to test a local branch before publishing to jakkaj/tools)
install-skills-from-source:
    @echo "Installing all skills from $(pwd) globally to every supported CLI..."
    npx skills@latest add "$(pwd)" \
        -a claude-code -a codex -a opencode -a github-copilot -a pi -g -y
    @echo "✅ Skills installed globally from $(pwd)"

# Render harness-3-retro --harvest --json output as a compact terminal view (reads JSON on stdin)
# Usage: <json-source> | just compound-value
compound-value:
    @scripts/compound-value.sh

# Diagnose skill deployment: canonical store + symlink validity + orphan real-dir stores at legacy paths
# Run after any `npx skills` upgrade or when the same skill name surfaces twice in discovery.
doctor-skills:
    #!/usr/bin/env bash
    set -eu
    canonical="$HOME/.agents/skills"
    echo "🩺 Skills doctor"
    echo
    if [ -d "$canonical" ]; then
        count=$(ls "$canonical" | wc -l | tr -d ' ')
        echo "✅ Canonical store: $canonical ($count skills)"
    else
        echo "⚠️  Canonical store missing: $canonical — run 'just install-skills-from-source'"
    fi
    echo
    echo "Per-CLI views (entries should be symlinks into canonical; hand-installed real dirs allowed if not also in canonical):"
    for path in "$HOME/.claude/skills" "$HOME/.pi/skills"; do
        if [ -L "$path" ]; then
            echo "  ✅ $path → $(readlink "$path") (whole-dir symlink)"
        elif [ -d "$path" ]; then
            symlinks=$(find "$path" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
            real_dirs=$(find "$path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
            if [ "$real_dirs" -eq 0 ] && [ "$symlinks" -eq 0 ]; then
                echo "  ℹ️  $path is empty"
                continue
            fi
            if [ "$real_dirs" -eq 0 ]; then
                echo "  ✅ $path ($symlinks symlinked skills)"
                continue
            fi
            # Classify each real subdir as duplicate-of-canonical (bad) or hand-installed-only (fine)
            duplicates=""
            handlocal=""
            for d in $(find "$path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null); do
                slug=$(basename "$d")
                if [ -e "$canonical/$slug" ]; then
                    duplicates="$duplicates $slug"
                else
                    handlocal="$handlocal $slug"
                fi
            done
            echo "  ℹ️  $path: $symlinks symlinks + $real_dirs real subdirs"
            if [ -n "$duplicates" ]; then
                echo "      ⚠️  Duplicates of canonical (will drift):$duplicates"
                echo "         Fix per slug: rm -rf $path/<slug> && ln -s $canonical/<slug> $path/<slug>"
            fi
            if [ -n "$handlocal" ]; then
                echo "      ✅ Hand-installed local-only (not in canonical — harmless):$handlocal"
            fi
        else
            echo "  ℹ️  $path missing (CLI may not have initialized yet)"
        fi
    done
    echo
    echo "Orphan real-dir stores at legacy paths:"
    found=0
    for path in "$HOME/.copilot/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills"; do
        if [ -e "$path" ] && [ ! -L "$path" ] && [ -d "$path" ]; then
            count=$(ls "$path" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$count" -gt 0 ]; then
                echo "  ⚠️  $path ($count entries) — likely orphan from older npx skills"
                echo "      Fix: rm -rf $path  (or: rm -rf $path && ln -s $canonical $path)"
                found=1
            fi
        fi
    done
    [ "$found" -eq 0 ] && echo "  ✅ None found"
    echo
    echo "Dangling symlinks under $HOME/.claude/skills:"
    if [ -d "$HOME/.claude/skills" ]; then
        dangling=$(find "$HOME/.claude/skills" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null || true)
        if [ -n "$dangling" ]; then
            echo "$dangling" | sed 's/^/  ⚠️  /'
        else
            echo "  ✅ None"
        fi
    fi

# Report skills deployed in target dirs that are NOT in this repo's source skills/ (renamed/removed/stale). READ-ONLY — prints tidy commands, deletes nothing.
skills-orphans:
    #!/usr/bin/env bash
    set -eu
    repo_root="$(pwd)"
    src="$(find skills -mindepth 3 -maxdepth 3 -name SKILL.md 2>/dev/null | awk -F/ '{print $(NF-1)}' | sort -u)"
    echo "🧹 Skills orphan report (READ-ONLY) — source of truth: ${repo_root}/skills ($(echo "$src" | grep -c .) skills)"
    echo "   'orphan' = present in a deployed target but absent from source here (npx skills add never prunes these)."
    echo
    canonical="$HOME/.agents/skills"
    any=0
    for target in "$canonical" "$HOME/.claude/skills" "$HOME/.pi/skills" "$HOME/.copilot/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills"; do
        [ -e "$target" ] || continue
        if [ -L "$target" ]; then
            echo "  ↪ $target → $(readlink "$target") (whole-dir symlink — mirrors its target, skipped)"
            continue
        fi
        [ -d "$target" ] || continue
        dep="$(ls -1 "$target" 2>/dev/null | sort -u)"
        orphans="$(comm -13 <(echo "$src") <(echo "$dep") || true)"
        if [ -n "$orphans" ]; then
            any=1
            echo "  ⚠️  $target — $(echo "$orphans" | grep -c .) not in source:"
            echo "$orphans" | sed 's/^/        • /'
            echo "      tidy (review first!): for s in $(echo $orphans); do rm -rf \"$target/\$s\"; done"
            echo
        else
            echo "  ✅ $target — no orphans"
        fi
    done
    echo
    if [ "$any" -eq 0 ]; then
        echo "✅ No orphans anywhere — every deployed skill exists in source."
    else
        echo "ℹ️  Review the lists above, then paste a 'tidy:' line to remove. Nothing was deleted."
        echo "   NOTE: legitimately hand-installed local-only skills (e.g. pack-code) also appear here — only tidy what you recognise as stale/renamed."
    fi

# Create a release build with checks
release: ci
    @echo ""
    @echo "📦 Release build ready in dist/"
    @echo ""
    @echo "To publish to PyPI:"
    @echo "  just publish"
    @echo ""
    @echo "To publish to TestPyPI first:"
    @echo "  just publish-test"

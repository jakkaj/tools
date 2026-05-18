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

# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!-- 
Customize this template for your project:
1. Replace placeholder documentation paths with your actual docs
2. Update build tool commands with your project's tools
3. Add project-specific conventions and requirements
4. Include relevant architectural patterns for your codebase
-->




## Mermaid Diagram Guidelines

When creating Mermaid diagrams in documentation:
- Be careful of parentheses `()` in diagram syntax - they can break rendering
- Use clear, descriptive node labels
- Keep diagrams simple and focused

## Required Reading

**CRITICAL**: Always read these files before working on the codebase:

<!-- Example documentation structure - replace with your actual docs -->
- `README.md` - Project overview and setup instructions
- `docs/architecture.md` - System architecture and design patterns (if exists)
- `docs/contributing.md` - Contribution guidelines and code standards (if exists)
- `docs/api.md` - API documentation and usage examples (if exists)

<!-- Add your project-specific required reading here -->


## Project Rules and Workflow

### Core Principles
- **Expert autonomous software engineer** - Implement planned tasks accurately and efficiently

- **Build tools**: Use the project's established build system (check package.json, Makefile, build.gradle, etc.)
- **Scratch directory**: All temporary/experimental work goes in `scratch/` (not tracked by git)
- **File editing preference**: Use partial edits (Edit/MultiEdit) over complete rewrites
- **Architecture compliance**: Follow the project's documented architectural patterns and conventions


### Task Planning Protocol
1. **Plan Structure**: Organize into numbered Phases, break into numeric tasks
2. **Documentation**: Create clear documentation of planned changes before implementation
3. **Task tables** with Status, Task, Success Criteria, Notes columns
4. **Success criteria** must be explicit and testable
5. **No assumptions** - plans must be explicit about all requirements
6. **Test-first approach** - write tests, implement code, verify tests pass

### File Modification Logging When Following Plans
When implementing a plan and modifying files, use footnotes to track changes:

1. **In the task row**: Add a brief note about what was modified
2. **In the Notes column**: Write a one-line summary followed by a footnote tag (e.g., `[^1]`)
3. **At the bottom of the plan**: Add the detailed footnote with substrate node IDs
4. **Always mark steps complete as you do them**: But only once the tests pass!

#### Code Reference Format in Footnotes
Include specific references for code you modify, making them clickable links:

- **Method/Function**: `[method:path/to/file:functionName](path/to/file#L123)`
- **Class**: `[class:path/to/file:ClassName](path/to/file#L123)`
- **File**: `[file:path/to/file](path/to/file)`

Adapt the format to your project's language and conventions.

Note: Use appropriate relative paths based on your documentation structure.

Example footnotes with clickable references:
```markdown
| 2.1 | [x] | Update configuration logic | Config loads correctly | Added validation for settings [^1] |
| 2.2 | [x] | Add error handling | Errors are caught and logged | Updated main function [^2] |

...

[^1]: Modified [`function:src/config.js:validateSettings`](src/config.js#L45) – Added validation to ensure required fields are present before processing.

[^2]: Modified [`function:src/main.js:initialize`](src/main.js#L120) – Added try-catch blocks with appropriate error logging.
```

Keep footnote numbers sequential and unique throughout the plan.

### Updating GitHub Issues When Following Plans
When implementing a plan and updating progress:

1. **DO NOT change the issue title** to include phase numbers or progress indicators
2. **DO add progress comments** using `gh issue comment` to document phase completion
3. **DO update the issue body** to reflect progress and adjustments as needed
4. **DO reference the branch** in your progress comments

Example progress comment:
```bash
gh issue comment 123 --body "## Phase 1 Completed ✅
Successfully implemented [phase description]...
Branch: \`issue-123-phase-1\`"
```

### GitHub Workflow
- **Branch naming**: `issue-<num>-phase-<phase>` off `main`
- **Conventional Commits** (Angular style) with issue references (`Fixes #123`)
- **Command prefix**: Use `PAGER=cat` before raw `git`/`gh` commands
- **PR workflow**: feature → `main`, clear description, squash-and-merge
- **Never commit/push** without asking user first

### Testing Requirements
- **Prefer integration tests** over heavy mocking when possible
- **Test edge cases** - avoid only testing the happy path
- **Use test fixtures** appropriate to your project's testing framework
- **Quality assertions** - verify specific expected behavior and data
- **Follow project conventions** - use established test patterns and utilities


## Build and Development Commands

<!-- Update this section with your project's actual commands -->
Check the project's build tool configuration:
- **npm/yarn projects**: See `package.json` scripts section
- **Python projects**: Check `Makefile`, `setup.py`, or `pyproject.toml`
- **Java/Kotlin**: See `gradle` or `maven` configuration
- **Rust**: Use `cargo` commands
- **Go**: Use `go` commands or `Makefile`

Common commands to look for:
- Build/compile
- Test
- Lint/format
- Run/serve
- Deploy

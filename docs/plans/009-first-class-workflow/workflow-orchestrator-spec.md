# Enrichment Workflow Orchestrator Specification

**Version**: 1.0.0
**Status**: Draft
**Created**: 2026-01-18

---

## Overview

A **universal, prompt-agnostic workflow orchestrator** that treats LLM prompts as deterministic tasks with explicit inputs, outputs, and dependencies. The system enables:

1. **Any prompt** to be wrapped with declarative I/O contracts
2. **Automatic orchestration** based on dependency graphs
3. **Enrichment pipelines** where data flows through prompts progressively
4. **Runtime validation** of inputs/outputs via JSON Schema

---

## Design Principles

| Principle | Description |
|-----------|-------------|
| **Prompt Agnostic** | Works with any prompt, not just `/plan-*` commands |
| **Declarative I/O** | Inputs and outputs are first-class, typed, and validated |
| **DAG-based** | Workflows form directed acyclic graphs with explicit dependencies |
| **Fail-safe** | Retries, fallbacks, and error handling are built-in |
| **Observable** | Every execution is traceable with full audit trail |
| **Composable** | Workflows can embed other workflows |

---

## Configuration Format

### File Structure

```yaml
# workflow.yaml
version: "1.0"
metadata:
  name: string           # Workflow identifier
  description: string    # Human-readable description
  tags: [string]         # Categorization tags

defaults:
  retry: RetryPolicy     # Default retry behavior
  timeout: duration      # Default task timeout
  on_error: ErrorPolicy  # Default error handling

parameters:             # Workflow-level inputs
  - ParameterDef

outputs:                # Workflow-level outputs
  - OutputDef

tasks:                  # Task definitions
  - TaskDef

hooks:                  # Lifecycle hooks
  on_start: TaskRef
  on_complete: TaskRef
  on_failure: TaskRef
```

---

## Core Schema Definitions

### ParameterDef

Defines a workflow or task input parameter.

```yaml
ParameterDef:
  name: string                    # Parameter identifier (required)
  type: TypeSpec                  # JSON Schema type or $ref (required)
  required: boolean               # Is this parameter mandatory? (default: true)
  default: any                    # Default value if not provided
  description: string             # Human-readable description
  sensitive: boolean              # Mask in logs (default: false)
  validate: ValidationRule[]      # Additional validation rules
  source: SourceSpec              # Where to get the value (for task inputs)
```

### TypeSpec

Type specification using JSON Schema subset.

```yaml
TypeSpec:
  # Primitive types
  type: string | number | integer | boolean | array | object | null

  # String constraints
  minLength: integer
  maxLength: integer
  pattern: regex
  format: uri | email | date-time | uuid | ...
  enum: [any]

  # Numeric constraints
  minimum: number
  maximum: number
  exclusiveMinimum: number
  exclusiveMaximum: number
  multipleOf: number

  # Array constraints
  items: TypeSpec
  minItems: integer
  maxItems: integer
  uniqueItems: boolean

  # Object constraints
  properties: {string: TypeSpec}
  required: [string]
  additionalProperties: boolean | TypeSpec

  # Schema reference
  $ref: string                    # Reference to shared schema
```

### OutputDef

Defines a task or workflow output.

```yaml
OutputDef:
  name: string                    # Output identifier (required)
  type: TypeSpec                  # JSON Schema type (required)
  description: string             # Human-readable description
  source: string                  # JSONPath to extract from task result
  optional: boolean               # Can this output be missing? (default: false)
```

---

## First-Class Input Types

Inputs are composable "packages" submitted to workflow steps. Each input type has distinct semantics for sourcing, validation, caching, and reproducibility.

### Input Type Taxonomy

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INPUT TYPES                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  STATIC (Deterministic, Reproducible)                               │
│  ├── literal        - Hardcoded values in config                    │
│  ├── file           - Files from filesystem                         │
│  ├── artifact       - Binary blobs, images, PDFs                    │
│  ├── schema         - JSON Schema / output contract                 │
│  └── config         - Feature flags, settings                       │
│                                                                      │
│  DYNAMIC (Runtime-Resolved)                                         │
│  ├── parameter      - Workflow-level parameters                     │
│  ├── task_output    - Output from upstream task                     │
│  ├── expression     - Computed via JSONata/template                 │
│  └── environment    - Env vars, runtime context                     │
│                                                                      │
│  INTERACTIVE (Requires Human)                                       │
│  ├── user_prompt    - Ask user for input                            │
│  ├── user_choice    - Multiple choice selection                     │
│  ├── user_approval  - Yes/No gate                                   │
│  └── user_file      - User-provided file upload                     │
│                                                                      │
│  EXTERNAL (Fetched from Services)                                   │
│  ├── api_call       - REST/GraphQL endpoint                         │
│  ├── database       - SQL/NoSQL query result                        │
│  ├── webhook        - Event payload from trigger                    │
│  └── mcp_resource   - MCP server resource                           │
│                                                                      │
│  CODEBASE (Repository-Aware)                                        │
│  ├── git_state      - Branch, commit, diff                          │
│  ├── file_tree      - Directory listing, glob results               │
│  ├── code_search    - Grep/semantic search results                  │
│  ├── ast_query      - FlowSpace/TreeSitter query                    │
│  └── git_history    - Commits, blame, log                           │
│                                                                      │
│  MEMORY (Stateful/Accumulated)                                      │
│  ├── conversation   - Chat history, prior turns                     │
│  ├── scratchpad     - Working memory across tasks                   │
│  ├── cache          - Previously computed results                   │
│  └── vector_store   - RAG retrieval results                         │
│                                                                      │
│  SENSITIVE (Special Handling)                                       │
│  ├── secret         - API keys, credentials                         │
│  └── pii            - Personal data (audit logged)                  │
│                                                                      │
│  META (About the Workflow)                                          │
│  ├── prompt         - The LLM prompt template itself                │
│  ├── model_config   - Temperature, max_tokens, etc.                 │
│  ├── seed           - Random seed for reproducibility               │
│  └── run_context    - Workflow run metadata                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Detailed Input Type Definitions

#### Static Inputs

```yaml
# LITERAL - Hardcoded value
InputType:
  type: literal
  value: any                      # The actual value
  # Immutable, always reproducible

# FILE - Filesystem file
InputType:
  type: file
  path: string                    # Absolute or relative path (supports globs)
  encoding: utf-8 | base64 | binary
  required: boolean               # Fail if missing? (default: true)
  watch: boolean                  # Re-run if file changes? (default: false)
  checksum: string                # Expected SHA256 for reproducibility
  max_size: bytes                 # Fail if larger

# ARTIFACT - Binary blob (images, PDFs, compiled assets)
InputType:
  type: artifact
  uri: string                     # file://, s3://, http://, artifact://
  media_type: string              # MIME type (image/png, application/pdf)
  extract: text | vision | raw    # How to present to LLM
  cache_key: string               # For deduplication

# SCHEMA - JSON Schema for validation/guidance
InputType:
  type: schema
  inline: object                  # Inline schema definition
  ref: string                     # Or reference: "#/schemas/MySchema"
  file: string                    # Or load from file
  purpose: input | output | both  # What it validates

# CONFIG - Feature flags, settings
InputType:
  type: config
  namespace: string               # Config namespace (e.g., "feature_flags")
  keys: [string]                  # Specific keys to fetch
  defaults: object                # Fallback values
```

#### Dynamic Inputs

```yaml
# PARAMETER - Workflow-level parameter
InputType:
  type: parameter
  name: string                    # Parameter name
  path: string                    # JSONPath within parameter (optional)

# TASK_OUTPUT - Output from upstream task
InputType:
  type: task_output
  task: string                    # Task ID
  output: string                  # Output name
  path: string                    # JSONPath within output (optional)
  required: boolean               # Fail if task didn't run? (default: true)
  default: any                    # Value if task skipped/failed

# EXPRESSION - Computed dynamically
InputType:
  type: expression
  expr: string                    # JSONata expression
  context:                        # What's available in expression
    - parameters                  # Workflow parameters
    - tasks                       # Completed task outputs
    - env                         # Environment
    - run                         # Run metadata

# ENVIRONMENT - Runtime environment
InputType:
  type: environment
  var: string                     # Single env var
  vars: [string]                  # Multiple env vars as object
  prefix: string                  # All vars with prefix (e.g., "APP_")
  required: boolean               # Fail if missing?
```

#### Interactive Inputs (Human-in-the-Loop)

```yaml
# USER_PROMPT - Free-form text input
InputType:
  type: user_prompt
  message: string                 # Prompt to show user
  placeholder: string             # Input placeholder
  multiline: boolean              # Allow multiple lines?
  validation:                     # Input validation
    min_length: integer
    max_length: integer
    pattern: regex
  timeout: duration               # How long to wait
  default: string                 # Default if timeout

# USER_CHOICE - Multiple choice selection
InputType:
  type: user_choice
  message: string                 # Question to ask
  choices:
    - value: any                  # Value if selected
      label: string               # Display label
      description: string         # Help text
      default: boolean            # Pre-selected?
  multi_select: boolean           # Allow multiple? (default: false)
  required: boolean               # Must select at least one?

# USER_APPROVAL - Gate requiring human approval
InputType:
  type: user_approval
  message: string                 # What needs approval
  context: object                 # Data to show for decision
  actions:
    approve: string               # Approve button text
    reject: string                # Reject button text
    defer: string                 # Defer button text (optional)
  timeout: duration               # Auto-reject after timeout?
  notify: [channel]               # Where to send approval request

# USER_FILE - File upload from user
InputType:
  type: user_file
  message: string                 # Upload prompt
  accept: [string]                # Allowed MIME types
  max_size: bytes                 # Size limit
  multiple: boolean               # Allow multiple files?
```

#### External Inputs (Service Integration)

```yaml
# API_CALL - REST/GraphQL endpoint
InputType:
  type: api_call
  method: GET | POST | PUT | DELETE
  url: string                     # URL (supports templates)
  headers: object                 # Request headers
  body: object                    # Request body (for POST/PUT)
  auth:
    type: bearer | basic | api_key | oauth2
    secret_ref: string            # Reference to secret
  response:
    path: string                  # JSONPath to extract
    validate: TypeSpec            # Schema validation
  retry: RetryPolicy              # Retry on failure
  cache: duration                 # Cache response for

# DATABASE - SQL/NoSQL query
InputType:
  type: database
  connection: string              # Connection reference
  query: string                   # SQL query (supports templates)
  params: object                  # Query parameters (prevent injection)
  timeout: duration
  max_rows: integer               # Limit results

# WEBHOOK - Event payload from external trigger
InputType:
  type: webhook
  event_type: string              # Expected event type
  payload_path: string            # JSONPath to extract
  validate: TypeSpec              # Payload validation
  # Populated when workflow triggered by webhook

# MCP_RESOURCE - MCP server resource
InputType:
  type: mcp_resource
  server: string                  # MCP server name
  uri: string                     # Resource URI
  # Fetches via MCP protocol
```

#### Codebase Inputs (Repository-Aware)

```yaml
# GIT_STATE - Current git state
InputType:
  type: git_state
  include:
    - branch                      # Current branch name
    - commit                      # Current commit SHA
    - dirty                       # Has uncommitted changes?
    - diff                        # Uncommitted diff
    - remote                      # Remote URL
  base: string                    # Compare against (for diff)
  path: string                    # Repo path (default: cwd)

# FILE_TREE - Directory listing
InputType:
  type: file_tree
  path: string                    # Root path
  pattern: string                 # Glob pattern (e.g., "**/*.py")
  exclude: [string]               # Patterns to exclude
  include_content: boolean        # Include file contents?
  max_files: integer              # Limit number of files
  max_depth: integer              # Directory depth limit

# CODE_SEARCH - Search codebase
InputType:
  type: code_search
  query: string                   # Search query
  mode: text | regex | semantic   # Search mode
  path: string                    # Scope to path
  include: [string]               # File patterns to include
  exclude: [string]               # File patterns to exclude
  limit: integer                  # Max results
  context_lines: integer          # Lines of context around matches

# AST_QUERY - Structural code query (FlowSpace/TreeSitter)
InputType:
  type: ast_query
  tool: flowspace | treesitter    # Query tool
  query: string                   # Query (tree pattern or node_id)
  language: string                # For treesitter
  include:
    - node_id
    - source
    - location
    - relationships

# GIT_HISTORY - Repository history
InputType:
  type: git_history
  range: string                   # Commit range (e.g., "HEAD~10..HEAD")
  path: string                    # Filter to path
  author: string                  # Filter by author
  include:
    - commits                     # Commit list
    - diffs                       # Changes
    - blame                       # Line attribution
```

#### Memory Inputs (Stateful)

```yaml
# CONVERSATION - Chat history
InputType:
  type: conversation
  include: all | recent | summary
  max_turns: integer              # Limit to N most recent
  max_tokens: integer             # Limit by token count
  roles: [user, assistant, system]  # Which roles to include
  summarize_after: integer        # Summarize if more than N turns

# SCRATCHPAD - Working memory
InputType:
  type: scratchpad
  key: string                     # Scratchpad key
  scope: workflow | task | global # Scratchpad scope
  default: any                    # If key doesn't exist

# CACHE - Previously computed result
InputType:
  type: cache
  key: string                     # Cache key (supports templates)
  ttl: duration                   # Time-to-live
  stale_while_revalidate: boolean # Return stale while refreshing?
  fallback:                       # If cache miss
    type: InputType               # Compute via this input type

# VECTOR_STORE - RAG retrieval
InputType:
  type: vector_store
  store: string                   # Vector store reference
  query: string                   # Query text (supports templates)
  embedding_model: string         # Model for query embedding
  top_k: integer                  # Number of results
  threshold: number               # Minimum similarity score
  filter: object                  # Metadata filters
  include:
    - content                     # Chunk content
    - metadata                    # Chunk metadata
    - score                       # Similarity score
    - source                      # Source document
```

#### Sensitive Inputs

```yaml
# SECRET - Credentials, API keys
InputType:
  type: secret
  ref: string                     # Secret reference (e.g., "vault://api_key")
  provider: env | vault | aws_sm | azure_kv
  mask_in_logs: true              # Always true, cannot be disabled
  rotate_after: duration          # Auto-rotate hint

# PII - Personal data (special audit handling)
InputType:
  type: pii
  source: InputType               # Underlying input
  categories: [email, phone, ssn, name, address]
  retention: duration             # How long to retain in logs
  anonymize: boolean              # Replace with pseudonyms?
```

#### Meta Inputs

```yaml
# PROMPT - The LLM prompt template itself
InputType:
  type: prompt
  template: string                # Inline template
  template_file: string           # Or load from file
  format: jinja2 | mustache | f-string
  partials: object                # Reusable template fragments

# MODEL_CONFIG - LLM configuration
InputType:
  type: model_config
  model: string                   # Model identifier
  temperature: number             # 0.0 - 2.0
  max_tokens: integer             # Response limit
  top_p: number                   # Nucleus sampling
  stop_sequences: [string]        # Stop generation at
  response_format: text | json    # Output format hint

# SEED - Random seed for reproducibility
InputType:
  type: seed
  value: integer                  # Fixed seed
  source: run_id | timestamp | random
  # Same seed + same inputs → same stochastic behavior (within model limits)

# RUN_CONTEXT - Workflow execution metadata
InputType:
  type: run_context
  include:
    - run_id                      # Unique run identifier
    - workflow_name               # Workflow being executed
    - task_id                     # Current task
    - attempt                     # Retry attempt number
    - started_at                  # Run start time
    - parent_run                  # If nested workflow
    - trigger                     # What triggered the run
```

### Input Composition

Inputs can be composed to create complex packages:

```yaml
# Example: Composite input for a code review task
inputs:
  # Static context
  - name: review_guidelines
    type: file
    path: docs/project-rules/rules.md

  # Dynamic from upstream
  - name: implementation
    type: task_output
    task: implement
    output: code_changes

  # Codebase context
  - name: git_diff
    type: git_state
    include: [diff]
    base: main

  # Search for related tests
  - name: related_tests
    type: code_search
    query: "test.*{{implementation.function_name}}"
    mode: regex
    limit: 5

  # User approval gate
  - name: approval
    type: user_approval
    message: "Ready to review {{implementation.files | length}} changed files?"
    context:
      files: "{{implementation.files}}"

  # The prompt itself
  - name: prompt
    type: prompt
    template_file: prompts/code-review.md

  # Model settings
  - name: model
    type: model_config
    model: claude-opus
    temperature: 0.3
```

### Input Reproducibility Matrix

| Input Type | Reproducible | Cacheable | Requires Runtime | Side Effects |
|------------|--------------|-----------|------------------|--------------|
| literal | ✅ Always | ✅ | ❌ | ❌ |
| file | ✅ With checksum | ✅ | ❌ | ❌ |
| artifact | ✅ With checksum | ✅ | ❌ | ❌ |
| schema | ✅ Always | ✅ | ❌ | ❌ |
| config | ⚠️ If versioned | ✅ | ✅ | ❌ |
| parameter | ✅ If same params | ❌ | ✅ | ❌ |
| task_output | ✅ If same run | ❌ | ✅ | ❌ |
| expression | ⚠️ Depends on inputs | ❌ | ✅ | ❌ |
| environment | ❌ Runtime-dependent | ❌ | ✅ | ❌ |
| user_* | ❌ Human-dependent | ❌ | ✅ | ❌ |
| api_call | ❌ External state | ⚠️ TTL | ✅ | ⚠️ Possible |
| database | ❌ External state | ⚠️ TTL | ✅ | ⚠️ Possible |
| webhook | ❌ Event-driven | ❌ | ✅ | ❌ |
| git_state | ⚠️ If pinned commit | ✅ | ✅ | ❌ |
| code_search | ⚠️ If pinned commit | ✅ | ✅ | ❌ |
| conversation | ❌ Session-dependent | ❌ | ✅ | ❌ |
| cache | ✅ If cache hit | ✅ | ✅ | ❌ |
| vector_store | ⚠️ If store versioned | ✅ | ✅ | ❌ |
| secret | ❌ Rotates | ❌ | ✅ | ❌ |
| seed | ✅ Always | ✅ | ❌ | ❌ |

---

---

## First-Class Output Types

Outputs are what a task *produces* - data for downstream tasks, files written, state mutations, notifications sent. Like inputs, outputs are typed and validated.

### Output Type Taxonomy

```
┌─────────────────────────────────────────────────────────────────────┐
│                        OUTPUT TYPES                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DATA FLOW (Passed to Downstream Tasks)                             │
│  ├── data            - Structured data (JSON-serializable)          │
│  ├── stream          - Streaming chunks (for long-running)          │
│  └── reference       - Pointer to data stored elsewhere             │
│                                                                      │
│  FILE SYSTEM (Written to Disk)                                      │
│  ├── file            - Single file written                          │
│  ├── files           - Multiple files written                       │
│  ├── directory       - Directory created/modified                   │
│  └── artifact        - Binary blob (images, PDFs, archives)         │
│                                                                      │
│  STATE MUTATION (Side Effects)                                      │
│  ├── cache_entry     - Value written to cache                       │
│  ├── scratchpad_entry - Value written to working memory             │
│  ├── vector_embedding - Chunks added to vector store                │
│  ├── database_rows   - Rows inserted/updated                        │
│  └── git_change      - Commit, branch, tag created                  │
│                                                                      │
│  EXTERNAL COMMUNICATION                                             │
│  ├── api_response    - Response from API call made                  │
│  ├── webhook_sent    - Webhook delivery confirmation                │
│  ├── notification    - Message sent (Slack, email, etc.)            │
│  └── approval_request - Human approval requested                    │
│                                                                      │
│  OBSERVABILITY                                                      │
│  ├── log_entries     - Structured log records                       │
│  ├── metrics         - Numeric measurements                         │
│  ├── trace_span      - Distributed trace segment                    │
│  └── audit_record    - Compliance/audit trail entry                 │
│                                                                      │
│  CONTROL FLOW                                                       │
│  ├── signal          - Message to other workflows                   │
│  ├── event           - Event emitted (for event-driven)             │
│  ├── error           - Structured error information                 │
│  ├── skip            - Signal to skip downstream tasks              │
│  └── branch_decision - Which conditional path was taken             │
│                                                                      │
│  LLM-SPECIFIC                                                       │
│  ├── response        - Raw LLM response text                        │
│  ├── structured      - Parsed/validated structured output           │
│  ├── reasoning       - Chain-of-thought / thinking trace            │
│  ├── tool_calls      - Tool/function calls requested by LLM         │
│  ├── citations       - Sources cited by LLM                         │
│  └── usage           - Tokens used, cost, latency                   │
│                                                                      │
│  VALIDATION                                                         │
│  ├── schema_result   - Schema validation pass/fail                  │
│  ├── test_result     - Test execution results                       │
│  └── diff            - Before/after comparison                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Detailed Output Type Definitions

#### Data Flow Outputs

```yaml
# DATA - Structured data for downstream tasks
OutputType:
  type: data
  name: string                    # Output identifier
  schema: TypeSpec                # JSON Schema for validation
  required: boolean               # Must be present? (default: true)
  sensitive: boolean              # Mask in logs?
  ttl: duration                   # How long to retain

# STREAM - Streaming output (for long-running tasks)
OutputType:
  type: stream
  name: string
  chunk_schema: TypeSpec          # Schema for each chunk
  on_chunk: TaskRef               # Task to invoke per chunk (optional)
  buffer_size: integer            # Chunks to buffer before downstream
  complete_schema: TypeSpec       # Schema for final assembled output

# REFERENCE - Pointer to data stored elsewhere
OutputType:
  type: reference
  name: string
  target: file | artifact | cache | database | s3
  uri_pattern: string             # How to construct URI
  dereference: boolean            # Auto-fetch for downstream? (default: false)
```

#### File System Outputs

```yaml
# FILE - Single file written
OutputType:
  type: file
  name: string                    # Output identifier
  path: string                    # Where to write (supports templates)
  encoding: utf-8 | base64 | binary
  overwrite: boolean              # Overwrite if exists? (default: false)
  create_dirs: boolean            # Create parent directories? (default: true)
  mode: string                    # File permissions (e.g., "0644")
  checksum: boolean               # Include SHA256 in output? (default: true)

# FILES - Multiple files written
OutputType:
  type: files
  name: string
  base_path: string               # Base directory
  pattern: string                 # File pattern (for output listing)
  manifest: boolean               # Output list of files created?

# DIRECTORY - Directory created/modified
OutputType:
  type: directory
  name: string
  path: string                    # Directory path
  recursive: boolean              # Include subdirectories in output?
  include_contents: boolean       # Include file contents in output?

# ARTIFACT - Binary blob
OutputType:
  type: artifact
  name: string
  media_type: string              # MIME type
  storage: local | s3 | gcs | azure
  path: string                    # Storage path
  max_size: bytes                 # Fail if larger
  compress: boolean               # Compress before storing?
```

#### State Mutation Outputs

```yaml
# CACHE_ENTRY - Write to cache
OutputType:
  type: cache_entry
  name: string
  key: string                     # Cache key (supports templates)
  ttl: duration                   # Time-to-live
  tags: [string]                  # For bulk invalidation

# SCRATCHPAD_ENTRY - Write to working memory
OutputType:
  type: scratchpad_entry
  name: string
  key: string                     # Scratchpad key
  scope: workflow | task | global
  merge_strategy: replace | merge | append

# VECTOR_EMBEDDING - Add to vector store
OutputType:
  type: vector_embedding
  name: string
  store: string                   # Vector store reference
  chunks:                         # What to embed
    source: string                # Field containing text
    metadata: [string]            # Fields to include as metadata
  embedding_model: string         # Model for embedding

# DATABASE_ROWS - Write to database
OutputType:
  type: database_rows
  name: string
  connection: string              # Database connection
  table: string                   # Target table
  operation: insert | upsert | update
  on_conflict: error | ignore | update
  returning: [string]             # Columns to return

# GIT_CHANGE - Git operation
OutputType:
  type: git_change
  name: string
  operation: commit | branch | tag | push
  commit:
    message: string               # Commit message template
    files: [string]               # Files to stage (or "all")
    author: string                # Override author
  branch:
    name: string                  # Branch name
    from: string                  # Base ref
  tag:
    name: string                  # Tag name
    message: string               # Annotated tag message
  push:
    remote: string                # Remote name
    force: boolean                # Force push? (default: false)
```

#### External Communication Outputs

```yaml
# API_RESPONSE - Response from outbound API call
OutputType:
  type: api_response
  name: string
  request:                        # The request made
    method: string
    url: string
    body_hash: string             # Hash of body (not body itself for security)
  response:
    status: integer
    headers: object
    body: any                     # Response body
    latency_ms: integer

# WEBHOOK_SENT - Webhook delivery
OutputType:
  type: webhook_sent
  name: string
  url: string                     # Webhook URL
  payload_schema: TypeSpec        # What was sent
  delivery:
    status: delivered | failed | retrying
    attempts: integer
    response_code: integer

# NOTIFICATION - Message sent
OutputType:
  type: notification
  name: string
  channel: slack | email | sms | teams | discord
  recipients: [string]
  message_id: string              # For threading/replies
  delivery_status: sent | delivered | failed

# APPROVAL_REQUEST - Human approval requested
OutputType:
  type: approval_request
  name: string
  request_id: string              # For tracking
  approvers: [string]             # Who can approve
  deadline: datetime              # When it expires
  status: pending | approved | rejected | expired
  response:                       # When resolved
    decision: string
    approver: string
    timestamp: datetime
    comment: string
```

#### Observability Outputs

```yaml
# LOG_ENTRIES - Structured logs
OutputType:
  type: log_entries
  name: string
  entries:
    - level: debug | info | warn | error
      message: string
      timestamp: datetime
      context: object             # Structured context
  destination: stdout | file | service

# METRICS - Numeric measurements
OutputType:
  type: metrics
  name: string
  measurements:
    - name: string                # Metric name
      value: number               # Metric value
      type: counter | gauge | histogram
      tags: object                # Dimensional tags
      timestamp: datetime

# TRACE_SPAN - Distributed trace
OutputType:
  type: trace_span
  name: string
  trace_id: string                # Trace identifier
  span_id: string                 # Span identifier
  parent_span_id: string          # Parent span
  operation: string               # Operation name
  start_time: datetime
  end_time: datetime
  attributes: object              # Span attributes
  events: [object]                # Span events
  status: ok | error

# AUDIT_RECORD - Compliance audit trail
OutputType:
  type: audit_record
  name: string
  action: string                  # What was done
  actor: string                   # Who/what did it
  resource: string                # What was affected
  before: any                     # State before (optional)
  after: any                      # State after (optional)
  justification: string           # Why (optional)
  retention: duration             # How long to keep
```

#### Control Flow Outputs

```yaml
# SIGNAL - Message to other workflows
OutputType:
  type: signal
  name: string
  target:                         # Who receives the signal
    workflow: string              # Workflow name pattern
    run_id: string                # Specific run (optional)
  signal_name: string             # Signal identifier
  payload: any                    # Signal data

# EVENT - Event emitted
OutputType:
  type: event
  name: string
  event_type: string              # Event type identifier
  payload: any                    # Event data
  routing_key: string             # For event routing

# ERROR - Structured error
OutputType:
  type: error
  name: string
  code: string                    # Error code
  message: string                 # Human-readable message
  category: transient | permanent | validation | timeout
  details: any                    # Additional context
  recoverable: boolean            # Can retry help?
  suggested_action: string        # What to do

# SKIP - Signal to skip downstream
OutputType:
  type: skip
  name: string
  reason: string                  # Why skipping
  skip_tasks: [string]            # Which tasks to skip (or "all_downstream")

# BRANCH_DECISION - Which path was taken
OutputType:
  type: branch_decision
  name: string
  condition_evaluated: string     # The condition that matched
  branch_taken: string            # Which branch executed
  alternatives: [string]          # Other branches that didn't execute
```

#### LLM-Specific Outputs

```yaml
# RESPONSE - Raw LLM response
OutputType:
  type: response
  name: string
  text: string                    # Raw response text
  model: string                   # Model that generated it
  finish_reason: stop | length | tool_call | content_filter

# STRUCTURED - Parsed structured output
OutputType:
  type: structured
  name: string
  schema: TypeSpec                # Expected schema
  data: any                       # Parsed data
  validation:
    valid: boolean
    errors: [string]              # Validation errors if any
  raw_response: string            # Original text before parsing

# REASONING - Chain-of-thought trace
OutputType:
  type: reasoning
  name: string
  thinking: string                # <thinking> block content
  steps: [string]                 # Reasoning steps identified
  confidence: number              # Self-assessed confidence (0-1)
  include_in_context: boolean     # Pass to downstream?

# TOOL_CALLS - Tool calls requested by LLM
OutputType:
  type: tool_calls
  name: string
  calls:
    - tool: string                # Tool name
      arguments: object           # Tool arguments
      id: string                  # Call ID for matching results
  pending: boolean                # Awaiting tool results?

# CITATIONS - Sources cited
OutputType:
  type: citations
  name: string
  sources:
    - text: string                # Cited text
      source: string              # Source identifier
      location: string            # Location in source
      confidence: number          # Citation confidence

# USAGE - Resource usage
OutputType:
  type: usage
  name: string
  tokens:
    input: integer                # Input tokens
    output: integer               # Output tokens
    total: integer                # Total tokens
    cache_read: integer           # Tokens read from cache
    cache_write: integer          # Tokens written to cache
  cost:
    amount: number                # Cost in currency
    currency: string              # Currency code (USD, etc.)
  latency:
    total_ms: integer             # Total latency
    time_to_first_token_ms: integer
  model: string                   # Model used
```

#### Validation Outputs

```yaml
# SCHEMA_RESULT - Schema validation result
OutputType:
  type: schema_result
  name: string
  valid: boolean
  schema_ref: string              # Schema that was validated against
  errors:
    - path: string                # JSONPath to invalid field
      message: string             # Error message
      constraint: string          # Violated constraint

# TEST_RESULT - Test execution result
OutputType:
  type: test_result
  name: string
  passed: boolean
  tests:
    - name: string                # Test name
      status: passed | failed | skipped | error
      duration_ms: integer
      message: string             # Failure message
      assertion: string           # What was asserted
  summary:
    total: integer
    passed: integer
    failed: integer
    skipped: integer

# DIFF - Before/after comparison
OutputType:
  type: diff
  name: string
  format: unified | json | semantic
  before: any                     # State before
  after: any                      # State after
  changes:
    - path: string                # What changed
      type: added | removed | modified
      old_value: any
      new_value: any
```

### Output Declaration in Tasks

```yaml
# Example task with multiple output types
tasks:
  - id: implement-feature
    type: prompt

    outputs:
      # Primary structured output
      - name: implementation
        type: structured
        schema:
          type: object
          properties:
            files_created: {type: array, items: {type: string}}
            tests_written: {type: array, items: {type: string}}
            summary: {type: string}

      # Files actually written
      - name: source_files
        type: files
        base_path: "src/"
        pattern: "**/*.{ts,py}"
        manifest: true

      # Git commit created
      - name: commit
        type: git_change
        operation: commit
        commit:
          message: "feat: {{inputs.feature_name}}"
          files: all

      # Token usage
      - name: usage
        type: usage

      # Reasoning trace (for debugging)
      - name: reasoning
        type: reasoning
        include_in_context: false

      # Error output (only present on failure)
      - name: error
        type: error
        required: false
```

### Output Routing Matrix

| Output Type | Downstream Tasks | Persistence | Observability | Side Effect |
|-------------|------------------|-------------|---------------|-------------|
| data | ✅ Direct | ❌ | ✅ Logged | ❌ |
| stream | ✅ Chunked | ❌ | ✅ Logged | ❌ |
| reference | ✅ Via deref | ✅ External | ✅ Logged | ❌ |
| file | ✅ Via path | ✅ Filesystem | ✅ Logged | ✅ Write |
| artifact | ✅ Via URI | ✅ Object store | ✅ Logged | ✅ Write |
| cache_entry | ❌ | ✅ Cache | ❌ | ✅ Write |
| scratchpad_entry | ✅ Via key | ✅ Memory | ❌ | ✅ Write |
| database_rows | ✅ Via return | ✅ Database | ✅ Audit | ✅ Write |
| git_change | ✅ Commit info | ✅ Git | ✅ Logged | ✅ Write |
| api_response | ✅ Response | ❌ | ✅ Logged | ⚠️ Depends |
| notification | ❌ | ❌ | ✅ Logged | ✅ Send |
| approval_request | ✅ Decision | ✅ Until resolved | ✅ Audit | ✅ Request |
| signal | ❌ | ❌ | ✅ Traced | ✅ Signal |
| error | ✅ For handling | ❌ | ✅ Logged | ❌ |
| response | ✅ Direct | ❌ | ✅ Logged | ❌ |
| structured | ✅ Direct | ❌ | ✅ Logged | ❌ |
| usage | ❌ | ✅ Metrics | ✅ Metrics | ❌ |

---

### SourceSpec (Simplified Alias)

For common cases, SourceSpec provides shorthand syntax:

```yaml
SourceSpec:
  # Shorthand → Full InputType mapping

  # Reference task output
  task: string                    # → type: task_output
  output: string

  # Reference parameter
  parameter: string               # → type: parameter

  # Literal value
  value: any                      # → type: literal

  # Expression
  expression: string              # → type: expression

  # File
  file: string                    # → type: file
  encoding: utf-8 | base64

  # Full input type (when shorthand isn't enough)
  input: InputType                # Explicit full definition
```

**Example equivalences:**

```yaml
# Shorthand
source:
  task: analyze
  output: result

# Equivalent full form
source:
  input:
    type: task_output
    task: analyze
    output: result

# Shorthand
source:
  file: "docs/rules.md"

# Equivalent full form
source:
  input:
    type: file
    path: "docs/rules.md"
    encoding: utf-8
```

---

## Task Definition

### TaskDef

The core unit of work in a workflow.

```yaml
TaskDef:
  id: string                      # Unique task identifier (required)
  name: string                    # Human-readable name
  description: string             # What this task does

  # Task type (one of)
  type: prompt | function | workflow | conditional | parallel | map

  # Execution
  executor: ExecutorSpec          # How to run this task

  # I/O
  inputs: [ParameterDef]          # Task inputs with sources
  outputs: [OutputDef]            # Task outputs

  # Dependencies
  depends_on: [DependencySpec]    # Explicit dependencies

  # Conditions
  when: ConditionExpr             # Only run if condition is true
  skip_on: [string]               # Skip if these tasks failed/skipped

  # Error handling
  retry: RetryPolicy              # Retry configuration
  timeout: duration               # Maximum execution time
  on_error: ErrorPolicy           # What to do on failure

  # Metadata
  tags: [string]                  # Task tags for filtering
  metadata: object                # Custom metadata
```

### ExecutorSpec

Defines how a task is executed.

```yaml
ExecutorSpec:
  # For prompt tasks
  prompt:
    template: string              # Prompt template (Jinja2/Mustache)
    template_file: string         # Or load from file
    model: string                 # Model identifier
    system_prompt: string         # System prompt (optional)
    temperature: number           # Model temperature
    max_tokens: integer           # Token limit
    output_schema: TypeSpec       # Expected output structure
    parser: structured | text | json | markdown

  # For function tasks
  function:
    module: string                # Python module path
    name: string                  # Function name
    args: object                  # Static arguments

  # For workflow tasks (composition)
  workflow:
    ref: string                   # Reference to another workflow
    file: string                  # Or inline workflow file

  # For shell tasks
  shell:
    command: string               # Shell command (supports templates)
    working_dir: string           # Working directory
    env: object                   # Environment variables
```

### DependencySpec

Defines task dependencies.

```yaml
DependencySpec:
  task: string                    # Task ID to depend on (required)
  type: data | execution | optional
  # data: Wait for task AND use its output (implicit from input sources)
  # execution: Wait for task but don't use output
  # optional: Continue even if dependency fails

  condition: ConditionExpr        # Only depend if condition is true
  outputs: [string]               # Specific outputs needed (optimization)
```

---

## Control Flow Constructs

### Conditional Task

Execute based on runtime conditions.

```yaml
TaskDef:
  id: decide-next-step
  type: conditional

  inputs:
    - name: analysis_result
      source:
        task: analyze
        output: result

  branches:
    - when: "$.analysis_result.needs_clarification == true"
      then: clarify-requirements

    - when: "$.analysis_result.complexity > 3"
      then: full-planning-track

    - default: true
      then: simple-planning-track
```

### Parallel Task

Execute multiple tasks concurrently.

```yaml
TaskDef:
  id: parallel-research
  type: parallel

  branches:
    - task_ref: research-codebase
    - task_ref: research-patterns
    - task_ref: research-dependencies
    - task_ref: research-tests

  # How to combine results
  join:
    strategy: all | any | n_of_m
    n: integer                    # For n_of_m strategy
    timeout: duration             # Max wait time

  # Output aggregation
  outputs:
    - name: combined_research
      type: array
      aggregate: collect          # collect | merge | first | last
```

### Map Task

Execute a task for each item in an array.

```yaml
TaskDef:
  id: process-each-phase
  type: map

  inputs:
    - name: phases
      source:
        task: architect
        output: implementation_phases

  # Item variable available in iterator
  iterator:
    item_var: phase               # Access current item as $.phase
    index_var: phase_index        # Access index as $.phase_index

  # Task to execute for each item
  task:
    id: implement-phase-{{phase_index}}
    type: prompt
    executor:
      prompt:
        template: |
          Implement phase: {{phase.name}}
          Tasks: {{phase.tasks | json}}

  # Parallelism control
  concurrency: 3                  # Max parallel executions
  fail_fast: false                # Continue on individual failures
```

---

## Error Handling

### RetryPolicy

```yaml
RetryPolicy:
  max_attempts: integer           # Total attempts (default: 3)
  initial_delay: duration         # First retry delay (default: 1s)
  max_delay: duration             # Maximum delay (default: 60s)
  backoff_multiplier: number      # Exponential backoff (default: 2.0)
  jitter: boolean                 # Add randomness (default: true)

  # Retry only specific errors
  retry_on:
    - error_type: rate_limit | timeout | transient | validation
    - error_pattern: regex        # Match error message

  # Never retry these
  abort_on:
    - error_type: authentication | invalid_input | not_found
```

### ErrorPolicy

```yaml
ErrorPolicy:
  strategy: fail | continue | fallback | retry_with_modification

  # For fallback strategy
  fallback_task: string           # Task to run instead

  # For retry_with_modification
  modification:
    adjust_prompt: string         # Template modification
    reduce_complexity: boolean    # Simplify the request
    use_different_model: string   # Try different model

  # Notifications
  notify:
    - channel: slack | email | webhook
      on: [failure, retry, recovery]
```

---

## Workflow Examples

### Example 1: Simple Enrichment Pipeline

```yaml
version: "1.0"
metadata:
  name: simple-enrichment
  description: Basic three-stage enrichment pipeline

parameters:
  - name: raw_input
    type: {type: string}
    required: true
    description: Raw text to enrich

outputs:
  - name: enriched_output
    source: "$.tasks.transform.outputs.result"

tasks:
  - id: extract
    type: prompt
    executor:
      prompt:
        template: |
          Extract key entities from the following text:

          {{inputs.raw_input}}

          Return as JSON: {entities: [...], topics: [...]}
        model: claude-sonnet
        output_schema:
          type: object
          properties:
            entities: {type: array, items: {type: string}}
            topics: {type: array, items: {type: string}}
    inputs:
      - name: raw_input
        source: {parameter: raw_input}
    outputs:
      - name: entities
        source: "$.entities"
      - name: topics
        source: "$.topics"

  - id: enrich
    type: prompt
    depends_on:
      - task: extract
    executor:
      prompt:
        template: |
          Given these entities: {{inputs.entities | json}}
          And these topics: {{inputs.topics | json}}

          Provide detailed context and relationships.
        model: claude-sonnet
    inputs:
      - name: entities
        source: {task: extract, output: entities}
      - name: topics
        source: {task: extract, output: topics}
    outputs:
      - name: context
        source: "$"

  - id: transform
    type: prompt
    depends_on:
      - task: enrich
    executor:
      prompt:
        template: |
          Transform this enriched data into the final format:

          Original: {{inputs.raw_input}}
          Context: {{inputs.context | json}}
        model: claude-sonnet
    inputs:
      - name: raw_input
        source: {parameter: raw_input}
      - name: context
        source: {task: enrich, output: context}
    outputs:
      - name: result
        source: "$"
```

### Example 2: Planning Workflow (Based on /plan-* Commands)

```yaml
version: "1.0"
metadata:
  name: planning-workflow
  description: Full planning workflow with conditional paths
  tags: [planning, development]

defaults:
  retry:
    max_attempts: 2
    retry_on: [{error_type: rate_limit}]
  timeout: 5m

parameters:
  - name: feature_description
    type: {type: string, minLength: 10}
    required: true

  - name: mode
    type: {type: string, enum: [simple, full]}
    default: full

  - name: doctrine_path
    type: {type: string, format: uri}
    default: "docs/project-rules/"

outputs:
  - name: spec_file
    source: "$.tasks.specify.outputs.spec_path"
  - name: plan_file
    source: "$.tasks.architect.outputs.plan_path"
  - name: implementation_complete
    source: "$.tasks.implement.outputs.success"

# ============================================================
# TASK DEFINITIONS
# ============================================================

tasks:
  # ------------------------------------------------------------
  # STAGE 1: Research (Optional)
  # ------------------------------------------------------------
  - id: research
    name: Codebase Research
    type: prompt

    executor:
      prompt:
        template_file: prompts/plan-1a-explore.md
        model: claude-opus
        max_tokens: 8000

    inputs:
      - name: query
        source: {parameter: feature_description}
      - name: codebase_context
        source:
          expression: "flowspace.tree('.')"

    outputs:
      - name: research_dossier
        type: {type: object}
        source: "$"
      - name: dossier_path
        type: {type: string}
        source: "$.file_path"

    when: "$.parameters.mode == 'full'"

    retry:
      max_attempts: 3
      retry_on: [{error_type: transient}]

  # ------------------------------------------------------------
  # STAGE 2: Specification
  # ------------------------------------------------------------
  - id: specify
    name: Create Specification
    type: prompt

    depends_on:
      - task: research
        type: optional           # Run even if research skipped

    executor:
      prompt:
        template_file: prompts/plan-1b-specify.md
        model: claude-opus
        output_schema:
          $ref: "#/schemas/SpecificationOutput"

    inputs:
      - name: feature
        source: {parameter: feature_description}
      - name: research
        source: {task: research, output: research_dossier}
        required: false          # Optional input

    outputs:
      - name: spec
        source: "$.specification"
      - name: spec_path
        source: "$.file_path"

  # ------------------------------------------------------------
  # STAGE 3: Clarification
  # ------------------------------------------------------------
  - id: clarify
    name: Clarify Requirements
    type: prompt

    depends_on:
      - task: specify

    executor:
      prompt:
        template_file: prompts/plan-2-clarify.md
        model: claude-opus

    inputs:
      - name: spec
        source: {task: specify, output: spec}

    outputs:
      - name: clarified_spec
        source: "$.updated_specification"
      - name: testing_strategy
        source: "$.decisions.testing"
      - name: workflow_mode
        source: "$.decisions.mode"

  # ------------------------------------------------------------
  # STAGE 4: Architecture
  # ------------------------------------------------------------
  - id: architect
    name: Create Implementation Plan
    type: prompt

    depends_on:
      - task: clarify

    executor:
      prompt:
        template_file: prompts/plan-3-architect.md
        model: claude-opus
        max_tokens: 16000

    inputs:
      - name: spec
        source: {task: clarify, output: clarified_spec}
      - name: doctrine
        source:
          file: "{{parameters.doctrine_path}}/*.md"
          encoding: utf-8
      - name: research
        source: {task: research, output: research_dossier}
        required: false

    outputs:
      - name: plan
        source: "$.implementation_plan"
      - name: plan_path
        source: "$.file_path"
      - name: phases
        source: "$.implementation_plan.phases"
      - name: complexity_score
        source: "$.implementation_plan.complexity"

  # ------------------------------------------------------------
  # STAGE 5: Conditional Branch
  # ------------------------------------------------------------
  - id: route-by-complexity
    name: Route by Complexity
    type: conditional

    depends_on:
      - task: architect

    inputs:
      - name: complexity
        source: {task: architect, output: complexity_score}
      - name: mode
        source: {task: clarify, output: workflow_mode}

    branches:
      - when: "$.mode == 'simple' || $.complexity <= 2"
        then: implement-simple

      - when: "$.complexity >= 4"
        then: validate-plan

      - default: true
        then: expand-tasks

  # ------------------------------------------------------------
  # STAGE 6A: Simple Implementation Path
  # ------------------------------------------------------------
  - id: implement-simple
    name: Simple Implementation
    type: prompt

    executor:
      prompt:
        template_file: prompts/plan-6-implement.md
        model: claude-opus

    inputs:
      - name: plan
        source: {task: architect, output: plan}
      - name: spec
        source: {task: clarify, output: clarified_spec}

    outputs:
      - name: implementation
        source: "$"
      - name: success
        source: "$.success"

  # ------------------------------------------------------------
  # STAGE 6B: Full Validation Path
  # ------------------------------------------------------------
  - id: validate-plan
    name: Validate Plan Completeness
    type: prompt

    executor:
      prompt:
        template_file: prompts/plan-4-complete.md
        model: claude-opus

    inputs:
      - name: plan
        source: {task: architect, output: plan}
      - name: spec
        source: {task: clarify, output: clarified_spec}
      - name: doctrine
        source:
          file: "{{parameters.doctrine_path}}/*.md"

    outputs:
      - name: validation_result
        source: "$.verdict"
      - name: issues
        source: "$.issues"

    on_error:
      strategy: continue         # Continue even if validation finds issues

  # ------------------------------------------------------------
  # STAGE 6C: Task Expansion Path
  # ------------------------------------------------------------
  - id: expand-tasks
    name: Expand Phase Tasks
    type: map

    inputs:
      - name: phases
        source: {task: architect, output: phases}

    iterator:
      item_var: phase
      index_var: idx

    task:
      id: expand-phase-{{idx}}
      type: prompt
      executor:
        prompt:
          template_file: prompts/plan-5-tasks.md
          model: claude-opus
      inputs:
        - name: phase
          source: {value: "{{phase}}"}
        - name: plan
          source: {task: architect, output: plan}
      outputs:
        - name: tasks
          source: "$.task_table"

    concurrency: 1               # Sequential phase expansion

    outputs:
      - name: all_phase_tasks
        aggregate: collect

  # ------------------------------------------------------------
  # STAGE 7: Implementation (After Task Expansion)
  # ------------------------------------------------------------
  - id: implement-phases
    name: Implement All Phases
    type: map

    depends_on:
      - task: expand-tasks

    inputs:
      - name: phase_tasks
        source: {task: expand-tasks, output: all_phase_tasks}

    iterator:
      item_var: phase_task
      index_var: phase_idx

    task:
      id: implement-phase-{{phase_idx}}
      type: prompt
      executor:
        prompt:
          template_file: prompts/plan-6-implement.md
          model: claude-opus
      inputs:
        - name: tasks
          source: {value: "{{phase_task}}"}
        - name: testing_strategy
          source: {task: clarify, output: testing_strategy}
      outputs:
        - name: implementation
          source: "$"

    concurrency: 1               # Sequential implementation
    fail_fast: true              # Stop on first failure

    outputs:
      - name: implementations
        aggregate: collect
      - name: success
        source: "length($.implementations[?(@.success == false)]) == 0"

  # ------------------------------------------------------------
  # STAGE 8: Review
  # ------------------------------------------------------------
  - id: review
    name: Code Review
    type: prompt

    depends_on:
      - task: implement-phases
        type: optional
      - task: implement-simple
        type: optional

    when: "$.tasks['implement-phases'].success || $.tasks['implement-simple'].success"

    executor:
      prompt:
        template_file: prompts/plan-7-review.md
        model: claude-opus

    inputs:
      - name: plan
        source: {task: architect, output: plan}
      - name: implementation
        source:
          expression: |
            $.tasks['implement-phases'].outputs.implementations
            ?? $.tasks['implement-simple'].outputs.implementation

    outputs:
      - name: review_verdict
        source: "$.verdict"
      - name: review_report
        source: "$.report"

# ============================================================
# SHARED SCHEMAS
# ============================================================

schemas:
  SpecificationOutput:
    type: object
    required: [specification, file_path]
    properties:
      specification:
        type: object
        required: [goals, acceptance_criteria]
        properties:
          goals: {type: array, items: {type: string}}
          non_goals: {type: array, items: {type: string}}
          acceptance_criteria: {type: array, items: {type: string}}
          risks: {type: array, items: {type: string}}
      file_path:
        type: string
        format: uri
```

### Example 3: Generic Enrichment Workflow

```yaml
version: "1.0"
metadata:
  name: generic-enrichment
  description: |
    A generic enrichment pipeline that can be configured
    with any sequence of prompts.

parameters:
  - name: input_data
    type: {type: object}
    required: true
    description: Initial data to enrich

  - name: enrichment_stages
    type:
      type: array
      items:
        type: object
        required: [name, prompt]
        properties:
          name: {type: string}
          prompt: {type: string}
          model: {type: string}
          output_schema: {type: object}
    required: true
    description: List of enrichment stages to apply

outputs:
  - name: final_result
    source: "$.tasks.enrichment-pipeline.outputs.final"

tasks:
  - id: enrichment-pipeline
    name: Dynamic Enrichment Pipeline
    type: map

    inputs:
      - name: stages
        source: {parameter: enrichment_stages}
      - name: initial_data
        source: {parameter: input_data}

    iterator:
      item_var: stage
      index_var: stage_idx
      accumulator:
        name: enriched_data
        initial: "{{inputs.initial_data}}"
        update: "$.outputs.enriched"

    task:
      id: enrich-{{stage.name}}
      type: prompt
      executor:
        prompt:
          template: |
            {{stage.prompt}}

            Current data state:
            {{enriched_data | json}}
          model: "{{stage.model | default('claude-sonnet')}}"
          output_schema: "{{stage.output_schema}}"
      inputs:
        - name: current_data
          source: {value: "{{enriched_data}}"}
        - name: stage_config
          source: {value: "{{stage}}"}
      outputs:
        - name: enriched
          source: "$"

    concurrency: 1               # Must be sequential for accumulation

    outputs:
      - name: final
        source: "$.accumulator.enriched_data"
      - name: stage_results
        aggregate: collect
```

---

## Runtime Execution Model

### Execution States

```
┌─────────────┐
│   PENDING   │ ── Task defined but not yet ready
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   WAITING   │ ── Dependencies not yet satisfied
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    READY    │ ── All dependencies satisfied, queued
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   RUNNING   │ ── Currently executing
└──────┬──────┘
       │
       ├──────────────────────────────────┐
       ▼                                  ▼
┌─────────────┐                    ┌─────────────┐
│  COMPLETED  │                    │   FAILED    │
└─────────────┘                    └──────┬──────┘
                                          │
                                          ├─────────┐
                                          ▼         ▼
                                   ┌──────────┐ ┌─────────┐
                                   │ RETRYING │ │ ABORTED │
                                   └──────────┘ └─────────┘
```

### Dependency Resolution Algorithm

```
1. Build dependency graph from task definitions
2. Topologically sort tasks
3. For each task in order:
   a. Check explicit depends_on
   b. Check implicit data dependencies (input sources)
   c. Check conditional (when clause)
   d. If all satisfied → READY
   e. If any blocker → WAITING
   f. If condition false → SKIPPED
4. Execute READY tasks respecting concurrency limits
5. On task completion:
   a. Update outputs in context
   b. Re-evaluate dependent tasks
   c. Trigger downstream tasks
```

### Context Object

The runtime context available to templates and expressions:

```yaml
Context:
  # Workflow level
  workflow:
    name: string
    run_id: string
    started_at: datetime

  # Parameters
  parameters: {string: any}

  # Task outputs (populated as tasks complete)
  tasks:
    <task_id>:
      status: TaskStatus
      started_at: datetime
      completed_at: datetime
      outputs: {string: any}
      error: ErrorInfo | null

  # Current task (only during task execution)
  current:
    task_id: string
    attempt: integer
    inputs: {string: any}

  # Environment
  env:
    <var>: string
```

---

## Prompt Wrapper Contract

To integrate any prompt into this system, wrap it with this contract:

```yaml
# prompts/my-custom-prompt.yaml
prompt_contract:
  id: my-custom-prompt
  version: "1.0"

  # Metadata
  name: "My Custom Prompt"
  description: "What this prompt does"

  # Input schema
  inputs:
    - name: input_name
      type: {type: string}
      required: true
      description: "What this input is for"

  # Output schema
  outputs:
    - name: output_name
      type: {type: object}
      description: "What this output contains"

  # The actual prompt template
  template: |
    You are a helpful assistant.

    Given: {{inputs.input_name}}

    Provide a response in this JSON format:
    {
      "output_name": { ... }
    }

  # Execution hints
  hints:
    recommended_model: claude-opus
    expected_tokens: 2000
    temperature: 0.7

  # Validation
  output_validation:
    json_schema: true              # Validate output against output schema
    retry_on_validation_fail: true # Retry if output doesn't match schema
```

---

## Implementation Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Workflow Orchestrator                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Parser &   │  │  Dependency  │  │   Executor   │       │
│  │  Validator   │  │   Resolver   │  │   Manager    │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │               │
│         ▼                 ▼                 ▼               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   Runtime Context                    │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐ │    │
│  │  │ Params  │  │ Outputs │  │  State  │  │  Logs  │ │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
│         │                 │                 │               │
│         ▼                 ▼                 ▼               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Prompt     │  │  Function    │  │   Workflow   │       │
│  │   Executor   │  │   Executor   │  │   Executor   │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │               │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐
    │   LLM    │     │ Python   │     │ Sub-     │
    │   API    │     │ Runtime  │     │ Workflow │
    └──────────┘     └──────────┘     └──────────┘
```

### Key Interfaces

```python
# Core interfaces (pseudo-code)

class WorkflowDefinition:
    """Parsed and validated workflow configuration"""
    metadata: Metadata
    parameters: list[ParameterDef]
    outputs: list[OutputDef]
    tasks: list[TaskDef]

class WorkflowRun:
    """A single execution of a workflow"""
    workflow: WorkflowDefinition
    run_id: str
    status: RunStatus
    context: RuntimeContext

class TaskExecutor(Protocol):
    """Interface for task executors"""
    async def execute(
        self,
        task: TaskDef,
        inputs: dict[str, Any],
        context: RuntimeContext
    ) -> TaskResult

class PromptExecutor(TaskExecutor):
    """Executor for prompt tasks"""
    async def execute(self, task, inputs, context):
        # 1. Render prompt template with inputs
        # 2. Call LLM API
        # 3. Parse and validate output
        # 4. Return TaskResult

class DependencyResolver:
    """Resolves task execution order"""
    def resolve(self, workflow: WorkflowDefinition) -> list[list[TaskDef]]
        # Returns tasks grouped by execution wave
```

---

## CLI Interface

```bash
# Validate a workflow definition
wf validate workflow.yaml

# Execute a workflow
wf run workflow.yaml \
  --param feature_description="Add user authentication" \
  --param mode=full

# Execute with input file
wf run workflow.yaml --params params.json

# Dry run (show execution plan without running)
wf run workflow.yaml --dry-run

# Resume a failed workflow
wf resume <run-id> --from-task <task-id>

# List running workflows
wf list

# Get workflow status
wf status <run-id>

# Cancel a workflow
wf cancel <run-id>

# Export workflow as Mermaid diagram
wf visualize workflow.yaml --format mermaid > workflow.md
```

---

## Comparison with Existing Systems

| Feature | This Spec | Temporal | Step Functions | Airflow | Argo |
|---------|-----------|----------|----------------|---------|------|
| Config Format | YAML | Code | JSON (ASL) | Python | YAML |
| Input Validation | JSON Schema | Type hints | JSONPath | JSON Schema | K8s validation |
| Output Contracts | Explicit | Return types | ResultPath | XCom | Artifacts |
| Dependency Expression | Both implicit + explicit | Code order | Next field | Operators | DAGTemplate |
| Conditional Branching | when clause | Code | Choice state | @task.branch | when field |
| Parallel Execution | parallel task | Go routines | Parallel state | expand | parallelism |
| Map/Loop | map task | For loops | Map state | Dynamic tasks | withItems |
| Retry | RetryPolicy | RetryPolicy | Retry field | retries param | retryStrategy |
| Error Handling | on_error + fallback | try/catch | Catch field | trigger_rules | onExit |
| LLM Native | Yes | No | No | No | No |
| Prompt Templates | Built-in | N/A | N/A | N/A | N/A |
| Output Schema | JSON Schema | N/A | N/A | N/A | N/A |

---

## Migration from /plan-* Commands

To migrate existing `/plan-*` commands to this system:

1. **Create prompt contracts** for each command
2. **Extract I/O** from the workflow-graph.md analysis
3. **Define the workflow** using this YAML format
4. **Register executors** that invoke the original prompts

Example migration for `/plan-1b-specify`:

```yaml
# prompts/plan-1b-specify.yaml
prompt_contract:
  id: plan-1b-specify
  version: "1.0"

  inputs:
    - name: feature_description
      type: {type: string, minLength: 10}
      required: true

    - name: research_dossier
      type: {type: object}
      required: false
      description: "Output from /plan-1a-explore"

  outputs:
    - name: spec
      type:
        type: object
        properties:
          goals: {type: array}
          non_goals: {type: array}
          acceptance_criteria: {type: array}
          risks: {type: array}
          open_questions: {type: array}
      description: "Feature specification"

    - name: spec_path
      type: {type: string, format: uri}
      description: "Path to created spec file"

  template_file: agents/commands/plan-1b-specify.md

  hints:
    recommended_model: claude-opus
    expected_tokens: 4000
```

---

## Next Steps

1. **Implement core parser** - YAML → WorkflowDefinition
2. **Build dependency resolver** - Topological sort with condition evaluation
3. **Create prompt executor** - Template rendering + LLM invocation + output validation
4. **Build CLI** - `wf` command with run/validate/visualize
5. **Migrate /plan-* commands** - Create prompt contracts for existing commands
6. **Add observability** - Execution logging, tracing, metrics

---

**Document Version**: 1.0.0
**Last Updated**: 2026-01-18

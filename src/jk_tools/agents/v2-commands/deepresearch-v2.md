---
description: Craft structured, domain-aware research prompts to leverage deep research agents for solving coding challenges. V2 with domain boundary awareness.
---

Please deep think / ultrathink as this is a complex task.

# deepresearch-v2

Craft a **structured research prompt** to leverage a deep research agent for solving coding challenges. Domain-aware: surfaces boundary concerns and cross-domain impacts when relevant.

---

## Pre-flight: Load Domain Context

Before crafting the prompt, check for domain context:

- If `docs/domains/registry.md` exists → scan registered domains
- If `docs/domains/domain-map.md` exists → note domain relationships and contract edges
- For domains related to the problem → read `docs/domains/<slug>/domain.md` (concepts, contracts, composition)

If no domain system is present, skip this step and proceed normally.

---

## Crafting the Research Prompt

Please create a structured prompt with the following sections:

### 1. Clear Problem Definition

* Precisely define the issue we are facing.
* Include relevant error messages, stack traces, or problematic behaviors.
* Which domain(s) does this problem affect? Does it cross domain boundaries?
* If multi-domain: which domain owns the fix vs. which domains are impacted?

### 2. Contextual Information

* Specify the technology stack involved (languages, frameworks, libraries).
* Include exact versions of key dependencies and any recent updates.
* Mention any recent codebase changes potentially related to the problem.
* Note domain-specific dependencies: contracts consumed, contracts exposed, shared infrastructure.
* Flag domain separation concerns — is the problem caused by tight coupling across boundaries?

### 3. Key Research Questions

* Identify clear, actionable research questions to guide the deep research agent.
* Ensure these questions target resolving our current challenge directly.
* If domains are involved: Does the solution respect existing domain boundaries? Should a contract be introduced or modified?

### 4. Recommended Tools and Resources

* List specific tools, libraries, or methodologies we should investigate.
* Include any helpful links or references.

### 5. Practical Examples

* Request practical code examples demonstrating the recommended solutions.

### 6. Pitfalls and Mitigation

* Ask for common mistakes related to the identified issue and best practices to avoid them.

### 7. Integration Considerations

* Include any special considerations or potential impacts on our existing workflows and CI/CD pipelines.
* Domain boundary impacts: Will the solution require changes to domain contracts? New cross-domain dependencies?
* Cross-domain communication patterns: Does the solution need new events, shared types, or adapter layers between domains?
* If new infrastructure is needed, does it belong in a `_platform` domain or the feature domain?

Please ensure the prompt is detailed, clear, and actionable, facilitating precise and valuable insights from our deep research agent.
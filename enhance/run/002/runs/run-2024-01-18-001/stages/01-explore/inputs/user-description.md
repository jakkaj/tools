# Research Query

Research how the authentication system works in this codebase.

## Context

We're planning to add multi-factor authentication (MFA) support. Before we design the implementation, we need to understand:

1. How the current auth flow works
2. Where tokens/sessions are managed
3. What dependencies exist (external auth providers, database schemas)
4. How the auth middleware is structured
5. What patterns and conventions are used

## Specific Questions

- Where are the auth entry points (login, logout, token refresh)?
- How are user sessions stored and validated?
- What security measures are already in place?
- Are there any extension points designed for adding new auth methods?
- What would break if we modified the auth flow?

## Expected Output

A comprehensive research report that would help plan the MFA implementation without duplicating existing functionality or breaking current auth flows.

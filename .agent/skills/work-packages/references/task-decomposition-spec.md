# Task Decomposition Specification

This guide defines the standards for writing clean, atomic, single-sentence tasks for any project.

---

## 1. The One-Sentence Task Standard

Every task inside a Work Package must begin with **exactly one active-voice sentence** stating the concrete technical change.

### Quality Criteria:
- **Active Verb**: Start with words like *Implement*, *Add*, *Refactor*, *Migrate*, *Optimize*, *Extract*, *Deprecate*.
- **Clear Target**: Name the exact module, component, function, or schema entity being changed.
- **Bounded Scope**: The task should be executable in isolation without requiring simultaneous edits across unrelated domains.

### Examples:
- ✅ *"Add an exponential backoff retry mechanism to `fetchWithRetry` in `src/services/apiClient.ts` for handling 429 and 503 HTTP responses."*
- ✅ *"Extend the user database schema with an optional `timezone` column and generate a corresponding migration file."*
- ✅ *"Extract session validation logic from the request handler into a reusable middleware function."*
- ❌ *"Improve API client error handling and also update database schema and views."* (Violates atomicity and single-sentence rule)
- ❌ *"Work on the backend."* (Too vague, lacks technical specificity)

---

## 2. Technical Inference Guidelines

When communicating with skilled developers:
1. **Identify Architectural Ambiguities**: If a request has multiple valid implementations, clearly state the technical options (e.g. In-memory queue vs Redis PubSub; optimistic local state vs server confirmation).
2. **Be Rigorous**: Discuss cache invalidation, edge cases, error recovery, and data invariants.
3. **Ask Direct Questions**: Empower the developer to select the technical path or research alternatives.

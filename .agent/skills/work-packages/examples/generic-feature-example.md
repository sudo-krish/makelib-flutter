# Example: Decomposing a Complex Feature into Work Packages

## Scenario
A developer requests: *"We need to add live multiplayer collaboration with conflict-free state synchronization to our dashboard."*

---

## Agent Response Following `work-packages` Skill

### 🧠 Technical Ingestion & Inference Questions

Before planning implementation, there are key architectural trade-offs to decide:

1. **State Synchronization Mechanism**:
   - **Option 1 (CRDT - Conflict-free Replicated Data Types)**: Enables peer-to-peer or server-mediated convergent state with zero locking, but introduces bundle overhead and document structure complexity.
   - **Option 2 (Operational Transformation / Server Authority)**: Centralizes transformation logic on the backend; simpler client state model, but requires strict ordering guarantees from the server.
   - **Option 3 (Event Sourcing / Last-Write-Wins with Vector Clocks)**: Simpler to implement if data model is largely disjoint, but requires deterministic conflict resolution rules.
2. **Transport Layer**:
   - WebSockets vs Server-Sent Events (SSE) + HTTP POST: Do clients need bidirectional high-frequency streaming, or is server push with transactional HTTP updates sufficient?
3. **Local State Durability**:
   - In offline scenarios, should dirty operations queue in IndexedDB/local storage with replay capabilities on reconnect?

---

### 📦 Proposed Work Packages

#### 📦 Work Package WP-01: Protocol & Connection Lifecycle
**Scope**: Transport connection management and event serialization.  
**Dependencies**: None.

##### Tasks:
- [ ] **Task 01.1**: Implement a resilient WebSocket connection manager with heartbeat ping/pong and exponential reconnection backoff.
  - **Modules**: `src/transport/socketManager.ts`
  - **Technical Contract**: Exposes `connect()`, `disconnect()`, `send(event)`, and emits typed connection lifecycle states.
  - **Verification**: Test simulated connection loss and verify automatic reconnect with backoff.

- [ ] **Task 01.2**: Define shared TypeScript interfaces and payload schemas for all collaboration event types.
  - **Modules**: `src/types/collaboration.ts`
  - **Technical Contract**: Strongly typed discriminated union `CollaborationEvent` with Zod runtime validation schemas.
  - **Verification**: Run typecheck and schema unit tests.

---

#### 📦 Work Package WP-02: State Reconciliation & Local Queue
**Scope**: Client-side state synchronization and conflict handling.  
**Dependencies**: WP-01.

##### Tasks:
- [ ] **Task 02.1**: Create a state reconciliation hook that merges remote updates into local client state without losing active input focus.
  - **Modules**: `src/hooks/useCollaborativeState.ts`
  - **Technical Contract**: Accepts initial state and reducer; manages optimistic local updates with rollback on server rejection.
  - **Verification**: Unit test concurrent remote vs local edits asserting deterministic state convergence.

---

### 🚦 User Verification Request
1. Which synchronization strategy (**CRDT**, **Server-Authority**, or **LWW Vector Clocks**) fits your system design best?
2. Does the separation between WP-01 (Transport) and WP-02 (State Reconciliation) look solid to begin?

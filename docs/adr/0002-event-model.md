# CSLProcessor emits three synchronous, payload-carrying events

`CSLProcessor` exposes a minimal emitter (`on`/`off`) with three event types, delivered synchronously after each mutation, carrying the new output.

## Context

ADR 0001 made the processor stateful with eager recompute, so callers need to learn which output changed without recomputing by hand. Every Generated Processor pays for the event surface in bytes (Closure ADVANCED keeps it small only if the surface is small).

## Decision

- Events: `registry` (`{type: 'add'|'remove'|'clear', ids}`), `cluster` (`{id, output, missing}`, once per Cluster whose output changed, including shifted later Clusters), `bibliography` (full new entry list). No coarse `change` event.
- Payloads carry the new data; callers never need a getter to learn what changed. No replay on subscribe: getters give current state.
- `on(type, fn)` returns an unsubscribe function; `off(type, fn)` also exists. No built-in Observable interop; RxJS users wrap with `fromEventPattern` (documented recipe).
- `batch(fn)` defers recompute and emission until `fn` returns; each event fires at most once per affected Cluster. Outside a batch, emission is immediate and synchronous.
- One flush emits `registry`, then `cluster` events in document order, then `bibliography`.
- A throwing listener is caught, the remaining listeners still run, and the error is re-raised asynchronously (`setTimeout(() => { throw e })`). No logging. Mutators never throw because of a listener.
- Calling a mutator while dispatching throws. Reads stay allowed.
- Removing a reference that Clusters still cite is normal: the Cite stays as a Dangling Cite and its Cluster is re-emitted. A Dangling Cite renders a placeholder; it is ignored by disambiguation, numbering and collapsing, keeps its authored position in Cite sorting, but occupies its slot for position so it breaks `ibid` chains. Re-adding the same id restores output. The `cluster` payload flags missing Cites. Placeholder text per format is decided in the output-formats ticket.

## Considered options

- Id-only "dirty" events plus getters: rejected, pushes a pull step onto every caller.
- Built-in `subscribe`/`Symbol.observable`: rejected, bytes in every file for a one-line wrapper.
- Queueing mutations made from listeners: rejected, does not prevent infinite loops and hides them; throwing is reversible later, permitting is not.
- Rethrowing listener errors from the mutating call, or logging: rejected, the mutator's caller did not write the listener; logging adds a policy to every file.
- Removing a reference also deletes its Cites: rejected, the processor must not edit caller-owned Clusters.

## Consequences

Callers react to three events and never recompute. Listener-driven mutation must be deferred by the caller.

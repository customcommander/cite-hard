# CSLProcessor owns an ordered list of Clusters

`CSLProcessor` is stateful: besides the Registry it holds the Clusters in document order, and every mutation of either recomputes affected output eagerly and synchronously, then emits events.

## Context

The original plan made `citation(items)` a pure function. That cannot work: `ibid`/`subsequent`/`near-note` positions, note numbers, numbering and disambiguation of a Cluster all depend on the Clusters before it and on the whole Registry. Inserting a Cluster early in a document changes the output of later ones.

## Decision

- The processor stores Clusters; the caller supplies a Cluster id, its placement (`before`/`after` another Cluster, else appended) and its `noteIndex`. The processor derives positions.
- Registry membership is the disambiguation scope; year-suffix letters follow bibliography sort order.
- The Cluster call is an upsert by id. A new id is placed by `before`/`after` (else appended). An existing id replaces its Cites in place; it moves only if placement is given. `noteIndex` is optional on an existing id, so it can be changed without resubmitting Cites. Several Clusters may share a `noteIndex`.
- Without a bibliography sort, bibliography order, `citation-number` and year-suffix order follow first-cited order (document order of first appearance, including Clusters inserted later); uncited references follow, in Registry insertion order. The spec leaves unsorted bibliography order to the processor.
- Cluster/Registry mutations recompute eagerly and synchronously and emit events for what changed (names and payloads: see the event-model ticket).
- `cite(cites, opts)` remains as a stateless one-off render. The name `citation()` is dropped.

## Amendment (edit-sequence fixtures)

The 43 test-suite fixtures with `citations` (the `processCitationCluster` edit sequences, 35 of them multi-step) are replayed through this API by the harness: one `batch()` per step, the order set to `pre ++ [cluster] ++ post` with placement-only calls, `noteIndex` of the `post` Clusters updated, final-state `html` compared. See the edit-sequence ticket.

## Considered options

- Pure `citation(items, {before: [...]})` with the caller passing preceding Clusters each call: rejected, it cannot notify callers when an edit changes other Clusters' output.
- Explicit per-Cite positions supplied by the caller: rejected, it pushes CSL position logic onto every caller.

## Consequences

Callers get change notifications and never recompute by hand; the cost is state and an event surface in every Generated Processor, which the Closure ADVANCED pass must keep small.

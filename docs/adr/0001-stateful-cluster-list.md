# CSLProcessor owns an ordered list of Clusters

`CSLProcessor` is stateful: besides the Registry it holds the Clusters in document order, and every mutation of either recomputes affected output eagerly and synchronously, then emits events.

## Context

The original plan made `citation(items)` a pure function. That cannot work: `ibid`/`subsequent`/`near-note` positions, note numbers, numbering and disambiguation of a Cluster all depend on the Clusters before it and on the whole Registry. Inserting a Cluster early in a document changes the output of later ones.

## Decision

- The processor stores Clusters; the caller supplies a Cluster id, its placement (`before`/`after` another Cluster, else appended) and its `noteIndex`. The processor derives positions.
- Registry membership is the disambiguation scope; year-suffix letters follow bibliography sort order.
- Cluster/Registry mutations recompute eagerly and synchronously and emit events for what changed (names and payloads: see the event-model ticket).
- `cite(cites, opts)` remains as a stateless one-off render. The name `citation()` is dropped.

## Considered options

- Pure `citation(items, {before: [...]})` with the caller passing preceding Clusters each call: rejected, it cannot notify callers when an edit changes other Clusters' output.
- Explicit per-Cite positions supplied by the caller: rejected, it pushes CSL position logic onto every caller.

## Consequences

Callers get change notifications and never recompute by hand; the cost is state and an event surface in every Generated Processor, which the Closure ADVANCED pass must keep small.

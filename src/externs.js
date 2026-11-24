/** @externs */

// CSLProcessor API surface (spec section 4).
function Processor(){}
Processor.prototype.add = function(){};
Processor.prototype.remove = function(){};
Processor.prototype.has = function(){};
Processor.prototype.get = function(){};
Processor.prototype.clear = function(){};
Processor.prototype.cluster = function(){};
Processor.prototype.batch = function(){};
Processor.prototype.cite = function(){};
Processor.prototype.citation = function(){};
Processor.prototype.bibliography = function(){};
Processor.prototype.on = function(){};
Processor.prototype.off = function(){};
/** @type {!Map} */
Processor.prototype.registry;

// Result keys: Output pair, bibliography result, events (ADR 0002, 0003, 0009).
function Output(){}
Output.prototype.html;
Output.prototype.text;
Output.prototype.output;
Output.prototype.entries;
Output.prototype.layout;
Output.prototype.id;
Output.prototype.ids;
Output.prototype.type;
Output.prototype.missing;

// Layout record (ADR 0003, 0009).
function Layout(){}
Layout.prototype.hangingIndent;
Layout.prototype.secondFieldAlign;
Layout.prototype.entrySpacing;
Layout.prototype.lineSpacing;

// Cluster placement (ADR 0001, 0002).
function ClusterOpts(){}
ClusterOpts.prototype.before;
ClusterOpts.prototype.after;
ClusterOpts.prototype.noteIndex;

// Cite fields (CONTEXT.md).
function Cite(){}
Cite.prototype.id;
Cite.prototype.locator;
Cite.prototype.label;
Cite.prototype.prefix;
Cite.prototype.suffix;

// The ctx record built per render: Cite data, Cluster context, Disambiguation Overrides (ADR 0004, 0007).
// Fields are added as the Compiler spine (slice 2) settles them.
function Ctx(){}
Ctx.prototype.cite;
Ctx.prototype.cluster;
Ctx.prototype.overrides;

// Collapse items (ADR 0008).
function CollapseItem(){}
CollapseItem.prototype.refId;
CollapseItem.prototype.overrides;
CollapseItem.prototype.names;
CollapseItem.prototype.date;
CollapseItem.prototype.suffix;
CollapseItem.prototype.number;
CollapseItem.prototype.rest;

// Stage parameter names (ADR 0007, 0008); `target` is render()'s third argument.
function StageArgs(){}
StageArgs.prototype.refIds;
StageArgs.prototype.render;
StageArgs.prototype.bibOrder;
StageArgs.prototype.items;
StageArgs.prototype.target;

goog.module('citehard.lib');

// --- IR node ---
//
// Every element-rendering function returns one node:
//   {raw: string, styled: StyledNode, variable: boolean}
//
// StyledNode is either:
//   {text: string, format: Format}            (leaf)
//   {children: StyledNode[], format: Format}  (branch, entries can nest arbitrarily deep)

/**
 * @record
 */
function Format() {}
/** @type {string|undefined} */
Format.prototype.fontStyle;
/** @type {string|undefined} */
Format.prototype.fontWeight;
/** @type {string|undefined} */
Format.prototype.fontVariant;
/** @type {string|undefined} */
Format.prototype.textDecoration;
/** @type {string|undefined} */
Format.prototype.verticalAlign;

/**
 * @record
 */
function StyledNode() {}
/** @type {string|undefined} */
StyledNode.prototype.text;
/** @type {!Array<!StyledNode>|undefined} */
StyledNode.prototype.children;
/** @type {!Format} */
StyledNode.prototype.format;

/**
 * @record
 * @struct
 */
function IRNode() {}
/** @type {string} */
IRNode.prototype.raw;
/** @type {!StyledNode} */
IRNode.prototype.styled;
/** @type {boolean} */
IRNode.prototype.variable;

/**
 * @param {string} raw
 * @param {!Format=} format
 * @return {!IRNode}
 */
function leaf(raw, format = {}) {
  return {
    raw,
    styled: {
      text: raw,
      format
    },
    variable: false
  };
}

/**
 * @param {!Array<!IRNode>} nodes
 * @param {!Format=} format
 * @return {!IRNode}
 */
function branch(nodes, format = {}) {
  return {
    raw: nodes.map(n => n.raw).join(''),
    styled: {
      children: nodes.map(n => n.styled),
      format
    },
    variable: nodes.some(n => n.variable),
  };
}

function escape_html(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// formatting that doesn't flip-flop: wrap whatever the children rendered to
const WRAPPERS = [
  ['fontWeight', 'bold', s => `<b>${s}</b>`],
  ['verticalAlign', 'sup', s => `<sup>${s}</sup>`],
  ['verticalAlign', 'sub', s => `<sub>${s}</sub>`],
  ['fontVariant', 'small-caps', s => `<span style="font-variant:small-caps;">${s}</span>`],
  ['textDecoration', 'underline', s => `<span style="text-decoration:underline;">${s}</span>`],
];

// walks a StyledNode top-down, carrying whether an ancestor already opened
// italics, so a nested font-style:italic request flips to normal instead of
// nesting <i> inside <i>
/**
 * @param {!StyledNode} node
 * @param {{italic: boolean}=} ctx
 * @return {string}
 */
function render(node, ctx = {italic: false}) {
  const wantsItalic = node.format.fontStyle === 'italic';
  const flip = wantsItalic && ctx.italic;
  const open = wantsItalic && !ctx.italic;
  const childCtx = wantsItalic
    ? /** @type {{italic: boolean}} */ ({...ctx, italic: !ctx.italic})
    : ctx;

  let out = 'text' in node
    ? escape_html(node.text)
    : node.children.map(child => render(child, childCtx)).join('');

  for (const [key, value, wrapFn] of WRAPPERS) {
    if (node.format[key] === value) {
      out = wrapFn(out);
    }
  }

  if (open) return `<i>${out}</i>`;
  if (flip) return `<span style="font-style:normal;">${out}</span>`;
  return out;
}


/**
 * @param {string} prefix
 * @param {string} suffix
 * @return {IRNode}
 */
function wrap(prefix, suffix, out) {
  return out.raw === '' ? out : branch([leaf(prefix), out, leaf(suffix)]);
}

/**
 * @param {!Object} ctx
 * @param {string|undefined} value
 */
function value(ctx, value) {
  return leaf(value ?? '');
}

function number_numeric(value) {
  return leaf(value ?? '');
}

function number_ordinal(value) {
  return leaf(value ?? '');
}

function number_long_ordinal(value) {
  return leaf(value ?? '');
}

function number_roman(value) {
  return leaf(value ?? '');
}

/**
 * @param {!Object} ctx
 * @param {!Object} reference
 * @param {string} name
 * @param {string=} fallback Variable read when `name` is unset (short forms).
 */
function variable(ctx, reference, name, fallback) {
  const out = leaf(reference[name] ?? reference[fallback] ?? '');
  out.variable = true;
  return out;
}

/**
 * @param {!Object} ctx
 * @param {?} value
 */
function term(ctx, value) {
  return leaf(value);
}

/**
 * @param {!Array<!IRNode>} nodes
 * @param {string=} delimiter
 * @return {IRNode}
 */
function group(nodes, delimiter = '') {

  // cs:group's implicit conditional: if it has at least one variable-bearing
  // direct child, and every one of those rendered blank, the whole group
  // (including any literal text siblings) is discarded
  const variableChildren = nodes.filter(n => n.variable);
  if (variableChildren.length > 0 && variableChildren.every(n => n.raw === '')) {
    const out = leaf('');
    out.variable = true;
    return out;
  }

  // The delimiter separates rendered (non-empty) children only
  const rendered = nodes.filter(n => n.raw !== '');
  const delimited = rendered.flatMap((n, i) => i === 0 || delimiter === '' ? [n] : [leaf(delimiter), n]);
  return branch(delimited);
}

/**
 * @param {string} val
 * @return {IRNode}
 */
function label(val) {
  return leaf(val);
}

/**
 * @param {Array} things
 * @param {string=} delimiter
 */
function names(things, delimiter) {
  return 'TODO';
}

function name() {
  return 'TODO';
}

function substitute() {
  return 'TODO';
}

function date(tmp /** string */) {
  return 'TODO';
}

function date_part() {
  return 'TODO';
}

/**
 * @param {?IRNode} out The rendered branch that matched, or null when none did.
 * @return {!IRNode}
 */
function choose(out) {
  return out ?? leaf('');
}

/**
 * @param {?} value
 * @return {boolean}
 */
function test_variable(value) {
  return Array.isArray(value) ? value.length > 0 : value != null && value !== '';
}

/**
 * @param {!Object} reference
 * @param {string} type
 * @return {boolean}
 */
function test_type(reference, type) {
  return reference['type'] === type;
}

/**
 * True for numbers and for strings made solely of numbers with optional letter affixes,
 * joined by commas, ampersands or dashes: "2", "D2", "2b", "2-4", "2, 3", "2 & 3".
 * @param {?} value
 * @return {boolean}
 */
function test_is_numeric(value) {
  if (typeof value === 'number') return true;
  return typeof value === 'string'
    && value.split(/\s*[,&\-\u2013]\s*/).every(part => /^[A-Za-z]*\d+[A-Za-z]*$/.test(part));
}

/**
 * @param {?} value A date variable.
 * @return {boolean}
 */
function test_is_uncertain_date(value) {
  return !!value && !!value['circa'];
}

/**
 * A locator is only tested when the Cite has one; its label defaults to "page".
 * @param {!Object} ctx
 * @param {string} label
 * @return {boolean}
 */
function test_locator(ctx, label) {
  return test_variable(ctx.cite?.locator) && (ctx.cite.label ?? 'page') === label;
}

function T() {
  return true;
}

function layout(reference, _, children) {
  const nodes = children.map(([fn, opts, rest]) => fn(reference, opts, rest));
  return nodes.length === 1 ? nodes[0] : branch(nodes);
}

function case_title(out) {
  return out;
}

function case_capitalize_first(out) {
  return out;
}

/**
 * @param {!IRNode} out
 * @return {!IRNode}
 */
function case_lowercase(out) {
  if (typeof out.raw == 'string') {
    out.raw = out.raw.toLowerCase();
  }
  return out;
}

/**
 * @param {!IRNode} out
 * @return {!IRNode}
 */
function case_uppercase(out) {
  if (typeof out.raw == 'string') {
    out.raw = out.raw.toUpperCase();
  }
  return out;
}

/**
 * @constructor
 * @struct
 * @param {string} display
 */
function DisplayAttrs(display) {
  this.display = display;
}

/**
 * @param {DisplayAttrs} attrs
 * @param {IRNode} out
 */
function display(attrs, out) {
  return out;
}

/**
 * @param {string} font_style
 * @param {string} font_variant
 * @param {string} font_weight
 * @param {string} text_decoration
 * @param {string} vertical_align
 * @param {IRNode} out
 * @return {IRNode}
 */
function format(font_style, font_variant, font_weight, text_decoration, vertical_align, out) {
  return out;
}

/**
 * @param {!IRNode} out
 * @return {!IRNode}
 */
function strip_periods(out) {
  if (typeof out.raw == 'string') {
    out.raw = out.raw.replaceAll('.', '');
  }
  return out;
}

exports = {
  T,
  branch,
  case_capitalize_first,
  case_lowercase,
  case_title,
  choose,
  date,
  date_part,
  display,
  DisplayAttrs,
  format,
  group,
  label,
  layout,
  leaf,
  name,
  names,
  number_long_ordinal,
  number_numeric,
  number_ordinal,
  number_roman,
  render,
  strip_periods,
  substitute,
  term,
  test_is_numeric,
  test_is_uncertain_date,
  test_locator,
  test_type,
  test_variable,
  value,
  variable,
  wrap,
};


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
 * @param {string|undefined} value
 */
function value(value) {
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

function variable(value) {
  const out = leaf(value ?? '');
  out.variable = true;
  return out;
}

function term(value) {
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

  return branch(nodes);
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

function choose(things /** ? */) {

}

function test(reference, {mode = 'all', tests}) {
  for (let i = 0; i < tests.length; i++) {
    const [pred, str] = tests[i];
    const parts = str.split(' ');

    for (let j = 0; j < parts.length; j++) {
      if (mode == 'all' && !pred(reference, parts[j])) {
        return false;
      } else if (mode == 'any' && pred(reference, parts[j])) {
        return true;
      } else if (mode == 'none' && pred(reference, parts[j])) {
        return false;
      }
    }
  }

  return mode !== 'any';
}

function test_variable(reference) {
  return function (varname) {
    return reference[varname] != null && reference[varname] !== '';
  };
}

function test_type(reference) {
  return function (type) {
    return reference['type'] = type;
  };
}

function test_is_numeric(reference) {
  return function (varname) {
    // TODO: actual check
    return reference[varname] != null;
  };
}

function test_is_uncertain_date(reference) {
  return function (varname) {
    // TODO: actual check
    return reference[varname] != null;
  };
}

function test_locator(any /** ? */) {
  return true;
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

/**
 * @param {function(string):boolean} pred
 * @param {string} str_vals
 * @return {boolean}
 */
function test_any(pred, str_vals) {
  return str_vals.split(' ').some(val => pred(val));
}

/**
 * @param {function(string):boolean} pred
 * @param {string} str_vals
 * @return {boolean}
 */
function test_all(pred, str_vals) {
  return str_vals.split(' ').every(val => pred(val));
}

/**
 * @param {function(string):boolean} pred
 * @param {string} str_vals
 * @return {boolean}
 */
function test_none(pred, str_vals) {
  return str_vals.split(' ').every(val => !pred(val));
}

function concat(nodes /** Array<IRNode>*/) {
  return nodes;
}

exports = {
  T,
  concat,
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
  test,
  test_any,
  test_all,
  test_none,
  test_is_numeric,
  test_is_uncertain_date,
  test_locator,
  test_type,
  test_variable,
  value,
  variable,
  wrap,
};


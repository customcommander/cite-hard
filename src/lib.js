goog.module('citehard.lib');

function join(_reference, {delimiter}, ...children) {
  return 'TODO';
}

function wrap(_reference, {prefix, suffix}, ...children) {
  return 'TODO';
}

// <csl:text value="..."/>
function value(_reference, {value}) {
  return value;
}

function number_numeric() {
  return 'TODO';
}

function number_ordinal() {
  return 'TODO';
}

function number_long_ordinal() {
  return 'TODO';
}

function number_roman() {
  return 'TODO';
}

// <csl:text variable="..."/>
function variable(reference, {name}) {
  return {
    raw: reference[name],
  };
}

function term() {
  return 'TODO';
}

function group(reference, options) {
  return 'TODO';
}

function label() {
  return 'TODO';
}

function names() {
  return 'TODO';
}

function name() {
  return 'TODO';
}

function substitute() {
  return 'TODO';
}

function date() {
  return 'TODO';
}

function date_part() {
  return 'TODO';
}

function test(reference, {mode, tests}) {
  for (let i = 0; i < tests.length; i++) {
    const [pred, str] = tests[i];
    const parts = str.split(' ');

    for (let j = 0; j < parts.length; j++) {
      if (mode == 'all' && pred(reference, parts[j])) {
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

function choose(reference, _options, branches) {
  for (let i = 0; i < branches.length; i++) {
    const [pred, options, ...children] = branches[i];

    if (pred(reference, options)) {
      return children.map((g, opts, ...rest) => g(reference, opts, ...rest));
    }
  }
}

function test_variable(reference, {name}) {
  return reference[name] != null;
}

function test_type(reference, {type}) {
  return reference.type == type;
}

function test_is_numeric(reference, {name}) {
  let content = reference[name];
  if (content == null) {
    return false;
  }
}

function test_is_uncertain_date() {
  return true;
}

function test_locator() {
  return true;
}

function T() {
  return true;
}

exports = {
  T,
  choose,
  date,
  date_part,
  group,
  join,
  label,
  name,
  names,
  number_long_ordinal,
  number_numeric,
  number_ordinal,
  number_roman,
  substitute,
  term,
  test,
  test_is_numeric,
  test_is_uncertain_date,
  test_locator,
  test_type,
  test_variable,
  value,
  variable,
  wrap,
};


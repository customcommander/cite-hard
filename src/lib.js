goog.module('citehard.lib');

function join(reference, {delimiter}, [fn, opts, children]) {
  return fn(reference, opts, children);
}

function wrap(reference, {prefix, suffix}, [fn, opts, children]) {
  const ret = [];
  ret.push({prefix});
  ret.push(fn(reference, opts, children));
  ret.push({suffix});
  return ret;
}

// <csl:text value="..."/>
function value(_, {value}) {
  return {raw: value};
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

function group(reference, options, children) {
  return children.map(([fn, opts, rest]) => fn(reference, opts, rest));
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

function choose(reference, _, branches) {
  for (let i = 0; i < branches.length; i++) {
    const [pred, options, children] = branches[i];

    if (pred(reference, options)) {
      return children.map(([g, opts, rest]) => g(reference, opts, rest));
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

function interpret(reference, body) {
  return body.map(([fn, opts, children]) => fn(reference, opts, children));
}

exports = {
  T,
  choose,
  date,
  date_part,
  group,
  interpret,
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


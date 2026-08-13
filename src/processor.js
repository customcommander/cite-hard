goog.module('citehard.Processor');

class Processor {

  /** @param {{cite: function(Object, Object),citation: function(Object)}} opts */
  constructor({cite, citation}) {
    this.registry = new Map();
    this._cite = cite;
    this._citation = citation;
  }

  cite(reference) {
    return this._cite(reference, {});
  }

  citation(references) {
    return this._citation(references);
  }
}

exports = Processor;


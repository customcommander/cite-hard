TEST_SUITE_REV = 6eefc5b07c6969ab8999e48542acbcc131cba864

SPECS = $(wildcard vendor/test-suite/*.json)
TESTS = $(patsubst vendor/test-suite/%.json,test/%.test.js,$(SPECS))

STYLES = $(patsubst vendor/styles/%.csl,out/styles/%.cljs,$(wildcard vendor/styles/*.csl))

# all: | vendor test
all: | vendor

vendor: vendor/schema vendor/styles vendor/locales vendor/test-suite
vendor:; mkdir -p $@

# test: $(TESTS)
# test:; mkdir -p $@

# .SECONDARY:
# test/%.test.js: vendor/test-suite/%.json compile.xsl lib.js
# 	./compile-test.sh $* $<

vendor/schema:
	mkdir -p $@
	curl --silent -L "https://github.com/citation-style-language/schema/archive/refs/tags/v1.0.2.tar.gz" -o $@.tar.gz
	tar -xzf $@.tar.gz -C $@ --strip-components=2 schema-1.0.2/schemas

vendor/styles:
	mkdir -p $@
	curl --silent -L "https://github.com/citation-style-language/styles/archive/refs/tags/v0.1.94.tar.gz" -o $@.tar.gz
	tar -xzf $@.tar.gz -C $@ --strip-components=1

vendor/locales:
	mkdir -p $@
	curl --silent -L "https://github.com/citation-style-language/locales/archive/refs/tags/v0.0.97.tar.gz" -o $@.tar.gz
	tar -xzf $@.tar.gz -C $@ --strip-components=1

vendor/test-suite:
	mkdir -p $@
	curl --silent -L "https://github.com/citation-style-language/test-suite/archive/$(TEST_SUITE_REV).tar.gz" -o $@.tar.gz
	tar -xzf $@.tar.gz -C $@ --strip-components=3 test-suite-$(TEST_SUITE_REV)/processor-tests/machines

# clean:; rm -rf vendor test
clean:; rm -rf vendor/schema vendor/styles vendor/locales vendor/test-suite

src/uncompiled/%.js: src/transform.xsl
	mkdir -p $(@D)
	xsltproc --stringparam stylename $* $^ vendor/styles/$*.csl > $@

dist/%.js: src/uncompiled/%.js src/lib.js src/processor.js src/externs.js
	closure-compiler -O ADVANCED \
                   --js=vendor/base.js \
	                 --js=src/lib.js \
                   --js=src/processor.js \
                   --js=src/externs.js \
                   --js=$< \
                   --entry_point=goog:citehard.styles.uncompiled \
                   --isolation_mode=IIFE \
	                 --hide_warnings_for=vendor/base.js \
                   --js_output_file=$@

# One Generated Processor per fixture, named after it.
# A fixture whose style fails to compile is logged in <fixture>.compile.log next to it and does not stop the run.
FIXTURES = $(patsubst vendor/test-suite/%.json,%,$(SPECS))

vendor/test-suite-extracted/%.csl: vendor/test-suite/%.json
	@mkdir -p $(@D)
	@jq -j '.csl' $< > $@

# Items lacking an id get "ITEM--GENERATED--ID-<position>" (1-based), a name no fixture uses.
vendor/test-suite-extracted/%.items.json: vendor/test-suite/%.json
	@mkdir -p $(@D)
	@jq '.input | [range(length) as $$i | .[$$i] | .id //= "ITEM--GENERATED--ID-\($$i + 1)"]' $< > $@

vendor/test-suite-extracted/%.expected.txt: vendor/test-suite/%.json
	@mkdir -p $(@D)
	@jq -j '.result' $< > $@

process-test-suite: $(patsubst %,vendor/test-suite-extracted/%.csl,$(FIXTURES)) \
                    $(patsubst %,vendor/test-suite-extracted/%.items.json,$(FIXTURES)) \
                    $(patsubst %,vendor/test-suite-extracted/%.expected.txt,$(FIXTURES)) \
                    $(patsubst %,vendor/test-suite-extracted/%.js,$(FIXTURES))

vendor/test-suite-extracted/%.js: vendor/test-suite-extracted/%.csl src/transform.xsl src/lib.js src/processor.js src/externs.js
	@rm -f vendor/test-suite-extracted/$*.compile.log
	@xsltproc --stringparam stylename $* src/transform.xsl $< > vendor/test-suite-extracted/$*.uncompiled.js 2> vendor/test-suite-extracted/$*.compile.log \
	&& closure-compiler -O ADVANCED \
	                    --js=vendor/base.js \
	                    --js=src/lib.js \
	                    --js=src/processor.js \
	                    --js=src/externs.js \
	                    --js=vendor/test-suite-extracted/$*.uncompiled.js \
	                    --entry_point=goog:citehard.styles.uncompiled \
	                    --isolation_mode=IIFE \
	                    --hide_warnings_for=vendor/base.js \
	                    --js_output_file=$@ >> vendor/test-suite-extracted/$*.compile.log 2>&1 \
	&& rm -f vendor/test-suite-extracted/$*.compile.log \
	|| { rm -f $@; echo "FAILED $*" | tee -a vendor/test-suite-extracted/$*.compile.log; }

# .PHONY: vendor test
.PHONY: vendor locales process-test-suite

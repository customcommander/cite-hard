TEST_SUITE_REV = 6eefc5b07c6969ab8999e48542acbcc131cba864

SPECS = $(wildcard vendor/test-suite/*.json)
TESTS = $(patsubst vendor/test-suite/%.json,test-suite/%.test.js,$(SPECS))

STYLES = $(patsubst vendor/styles/%.csl,out/styles/%.cljs,$(wildcard vendor/styles/*.csl))

# all: | vendor test
all: | vendor

vendor: vendor/schema vendor/styles vendor/locales vendor/test-suite
vendor:; mkdir -p $@

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
clean:; rm -rf vendor/schema vendor/styles vendor/locales vendor/test-suite test-suite

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

# One Generated Processor per fixture, compiled from the CSL inlined in the fixture.
# A style that fails to compile leaves a stub that records the compiler log, so the fixture's test throws it and the run goes on.
test-suite/%.compiled.js: vendor/test-suite/%.json src/transform.xsl src/lib.js src/processor.js src/externs.js
	@mkdir -p $(@D)
	@log=$$( { jq -j '.csl' $< | xsltproc --stringparam stylename $* src/transform.xsl - > test-suite/$*.uncompiled.js \
	  && closure-compiler -O ADVANCED \
	                      --js=vendor/base.js \
	                      --js=src/lib.js \
	                      --js=src/processor.js \
	                      --js=src/externs.js \
	                      --js=test-suite/$*.uncompiled.js \
	                      --entry_point=goog:citehard.styles.uncompiled \
	                      --isolation_mode=IIFE \
	                      --hide_warnings_for=vendor/base.js \
	                      --js_output_file=$@; } 2>&1 ) \
	|| { echo "FAILED $*"; jq -nr --arg name $* --arg log "$$log" '"globalThis[\("cite-hard.compile-error." + $$name | tojson)] = \($$log | tojson);"' > $@; }

# Self-contained test: the processor, the items, the clusters and the expected string are all inlined.
test-suite/%.test.js: vendor/test-suite/%.json test-suite/%.compiled.js src/fixture-test.jq passing.txt
	@jq -r --arg name $* --rawfile processor test-suite/$*.compiled.js --rawfile passing passing.txt -f src/fixture-test.jq $< > $@

# Builds every fixture test. Run them with `node --test test-suite/*.test.js` (see `pnpm test`).
# Fixtures not listed in passing.txt are generated with expectFailure: an unexpected pass fails the run like an unexpected fail.
test-suite: $(TESTS)

# Keep the compiled processors: they are intermediates of the tests but slow to rebuild.
.SECONDARY:

.PHONY: vendor locales test-suite

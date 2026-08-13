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
	curl --silent -L "https://github.com/citation-style-language/test-suite/archive/refs/heads/master.tar.gz" -o $@.tar.gz
	tar -xzf $@.tar.gz -C $@ --strip-components=3 test-suite-master/processor-tests/machines

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

# .PHONY: vendor test
.PHONY: vendor locales

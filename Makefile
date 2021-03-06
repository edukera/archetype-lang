# -*- Makefile -*-

# --------------------------------------------------------------------
.PHONY: all merlin build build-deps run clean

# --------------------------------------------------------------------
all: build compiler # plugin

build:
	@dune build

plugin:
	$(MAKE) -C src plugin
	cp -f _build/default/src/archetype_plugin.cmxs ./why3/

compiler:
	$(MAKE) -C src compiler.exe
	ln -fs _build/default/src/compiler.exe archetype.exe

js:
	$(MAKE) -C src compiler.bc.js
	ln -fs _build/default/src/compiler.bc.js archetype.js

mlw:
	$(MAKE) -C src mlw.exe
	cp -f _build/default/src/mlw.exe .

extract:
	$(MAKE) -C src/liq extract.exe

merlin:
	$(MAKE) -C src merlin

run:
	$(MAKE) -C src run

install:
	@dune install

clean:
	@dune clean
	$(MAKE) -C src clean
	rm -f archetype.exe

check:
	./extra/script/check_pp.sh && ./extra/script/check_contracts.sh

_opam:
	opam switch create . 4.10.2 --no-install
	eval $$(opam env)

build-deps: _opam
	opam install . --deps-only --working-dir -y

build-deps-dev: build-deps
	opam install merlin ocp-indent why3.1.4.0 -y

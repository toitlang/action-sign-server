# Copyright (C) 2025 Toit language
# Use of this source code is governed by an MIT-style license that can be
# found in the LICENSE file.

ifeq ($(OS),Windows_NT)
	EXE := .exe
endif

.PHONY: all
all: build/client build/server

.PHONY: install-pkgs
install-pkgs:
	toit pkg install

build/client: client/main.toit install-pkgs
	mkdir -p build
	toit compile -o build/client$(EXE) client/main.toit

build/server: server/main.toit install-pkgs
	mkdir -p build
	toit compile -o build/server$(EXE) server/main.toit

.PHONY: test
test:
	@for test in tests/*-test.toit; do \
		echo "--  Running test $$test  --"; \
		toit run $$test $$(command -v toit); \
	done

.PHONY: clean
clean:
	rm -rf build

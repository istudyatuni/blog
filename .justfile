port := "3000"
out-dir := "dist"
source-dir := "content"

[private]
@default:
	just --list --unsorted

[private]
@mkoutput-dir path:
	mkdir -p $(dirname {{ replace(path, source-dir, out-dir) }})

[private]
typ cmd path *args:
	typst {{cmd}} \
		--features html \
		--root . \
		{{ args }} \
		{{ path }} \
		{{ replace(replace(path, source-dir, out-dir), ".typ", ".html") }}

watch path="content/index.typ": (mkoutput-dir path) (typ "watch" path  "--port" port)
build path="content/index.typ": (mkoutput-dir path) (typ "compile" path)

build-all:
	#!/usr/bin/env sh
	set -euo pipefail
	for path in $(fd .typ content); do
		echo Building $path
		just build "$path"
	done

serve: build-wasm build-all
	@echo Serving at http://localhost:{{ port }}
	static-web-server -d {{ out-dir }} -p {{ port }}

build-wasm:
	cd syntect-plugin && cargo build --release --target wasm32-unknown-unknown

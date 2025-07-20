port := "3000"
out-dir := "dist"
source-dir := "content"
public-dir := "public"
font-url := "https://gwfh.mranftl.com/api/fonts/nunito?download=zip&subsets=cyrillic,latin&variants=200,300,500,600,700,800,900,200italic,300italic,regular,italic,500italic,600italic,700italic,800italic,900italic&formats=woff2"
font-file-name := "nunito.zip"
font-file-dir := public-dir / "fonts"
font-file := font-file-dir / font-file-name

[private]
@default:
	just --list --unsorted

[private]
@mkoutput-dir path:
	mkdir -p $(dirname {{ replace(path, source-dir, out-dir) }})

[private]
download-fonts:
	#!/usr/bin/env sh
	if [[ -e "{{ font-file }}" ]]; then exit 0; fi
	mkdir -p "{{public-dir}}/fonts"
	wget "{{ font-url }}" -O "{{ font-file }}"
	cd "{{ font-file-dir }}" && unzip "{{ font-file-name }}"

[private]
copy-fonts:
	mkdir -p "{{out-dir}}/fonts"
	cp {{ public-dir }}/fonts/*.woff2 "{{out-dir}}/fonts"

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

build-all: && download-fonts copy-fonts
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

# to be able to get $serve_base in build-all
set export

port := "3000"
serve_base := ""
out-dir-base := "dist"
out-dir := join(out-dir-base, serve_base)
source-dir := "content"
public-dir := "public"
font-url := "https://gwfh.mranftl.com/api/fonts/nunito?download=zip&subsets=cyrillic,latin&variants=200,300,500,600,700,800,900,200italic,300italic,regular,italic,500italic,600italic,700italic,800italic,900italic&formats=woff2"
font-file-name := "nunito.zip"
font-file-dir := join(public-dir, "fonts")
out-font-file-dir := join(out-dir, "fonts")
font-file := join(font-file-dir, font-file-name)

[private]
@default:
	just --list --unsorted

[private]
mkoutput-dir path:
	mkdir -p $(dirname {{ replace(path, source-dir, out-dir) }})

[private]
download-fonts:
	#!/usr/bin/env bash
	set -euo pipefail
	if [[ -e "{{ font-file }}" ]]; then exit 0; fi
	mkdir -p "{{public-dir}}/fonts"
	wget "{{ font-url }}" -O "{{ font-file }}"
	cd "{{ font-file-dir }}" && unzip "{{ font-file-name }}"

[private]
copy-static:
	mkdir -p "{{ out-font-file-dir }}"
	cp {{ public-dir }}/*.png "{{ out-dir }}"
	cp {{ public-dir }}/fonts/*.woff2 "{{ out-font-file-dir }}"

[private]
typ cmd path *args:
	typst {{cmd}} \
		--features html \
		--root . \
		{{ args }} \
		{{ path }} \
		{{ replace(replace(path, source-dir, out-dir), ".typ", ".html") }}

watch path: (mkoutput-dir path) (typ "watch" path  "--port" port "--input" ("base=" + serve_base))
build path: (mkoutput-dir path) (typ "compile" path "--input" ("base=" + serve_base))

watch-root: (watch "content/index.typ")
watch-go: (watch "content/why-i-dont-like-go.typ")
watch-blog: (watch "content/about-blog.typ")
watch-blog-ru: (watch "content/about-blog.ru.typ")
watch-notes: (watch "content/notes/index.typ")
watch-nixpkgs: (watch "content/notes/local-nixpkgs-build.typ")

build-all: build-wasm && download-fonts copy-static
	#!/usr/bin/env bash
	set -euo pipefail
	for path in $(fd .typ content); do
		echo Building $path
		just serve_base="$serve_base" build "$path"
	done

serve: build-all
	@echo Serving at http://localhost:{{ port }}/{{ serve_base }}
	static-web-server -d {{ out-dir-base }} -p {{ port }}

serve-prod:
	just serve_base=blog serve

build-wasm:
	cd syntect-plugin && cargo build --release --target wasm32-unknown-unknown

clean:
	rm -r {{ out-dir-base }}

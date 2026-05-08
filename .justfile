export TYPST_FEATURES := "html,bundle"

port := "3000"
entry_point := "main.typ"
serve_base := ""
serve_base_prod := "blog"
out-dir-base := "dist"
out-dir := join(out-dir-base, serve_base)
source-dir := "content"
public-dir := "public"
font-url := "https://gwfh.mranftl.com/api/fonts/nunito?download=zip&subsets=cyrillic,latin&variants=200,300,500,600,700,800,900,200italic,300italic,regular,italic,500italic,600italic,700italic,800italic,900italic&formats=woff2"
font-file-name := "nunito.zip"
font-file-dir := join(public-dir, "fonts")
out-font-file-dir := join(out-dir, "fonts")
font-file := join(font-file-dir, font-file-name)

typst-exe := "typst"

[private]
@default:
	just --list --unsorted

[private]
download-fonts:
	#!/usr/bin/env bash
	set -euo pipefail
	if [[ -e "{{ font-file }}" ]]; then exit 0; fi
	mkdir -p "{{public-dir}}/fonts"
	wget "{{ font-url }}" -O "{{ font-file }}"
	pushd "{{ font-file-dir }}"
	unzip "{{ font-file-name }}"
	popd
	# remove version from filenames
	for path in $(fd -I .woff2 public/fonts); do
		newpath="$(echo "$path" | sed -E 's/nunito-v[0-9]+-/nunito-/g')"
		mv "$path" "$newpath"
	done

[private]
typ cmd *args:
	{{ typst-exe }} {{cmd}} {{ args }} \
		--format=bundle \
		--input {{ "base=" + serve_base }} \
		'{{ entry_point }}' '{{ out-dir }}'

# pin devshell derivation
shell:
	@# run user shell inside
	nix develop --profile flake.drv --command bash -c "SHELL=$SHELL $SHELL"

# build static dir
build: download-fonts (typ "compile")
# start dev server
watch: (typ "watch" "--port" port)

# build static dir with prod base
build-prod: clean
	just serve_base={{ serve_base_prod }} build

[private]
serve: build
	@echo Serving at http://localhost:{{ port }}/{{ serve_base }}
	static-web-server -d {{ out-dir-base }} -p {{ port }}

# build static dir with prod base and serve
serve-prod: clean
	just serve_base={{ serve_base_prod }} serve

clean:
	rm -rf {{ out-dir-base }}

#import "/lib.typ": get-meta, join-paths, real-path, nunito-font-variants, font-path, is-lsp

#let content-dir = "content"
#let public-dir = "public"

// relative to content-dir
#let files = (
    notes: (
        index: none,
        local-nixpkgs-build: none,
    ),
    index: none,
    about-blog: none,
    why-i-dont-like-go: none,
)

#let add-files(files, base: "") = {
    for (name, nested) in files.pairs() {
        if nested == none {
            let p = join-paths((base, name))
            if is-lsp { continue }
            document(p + ".html")[
                #include content-dir + "/" + p + ".typ"
            ]
        } else if type(nested) == dictionary {
            add-files(nested, base: join-paths((base, name)))
        } else {
            panic("unhandled file", name, nested)
        }
    }
}

#let add-asset(path, base: public-dir) = {
    let real = join-paths((base, path))
    if is-lsp { return }
    asset(path, read(real, encoding: none))
}

#add-files(files)
#add-asset("favicon.png")
#for (style, weight) in nunito-font-variants {
    let path = font-path(style, weight)
    if is-lsp { continue }
    add-asset(path)
}

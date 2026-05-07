#import "/lib.typ": (
    get-meta, join-paths, real-path, nunito-font-variants,
    font-path, is-lsp, get-meta, resolve-translation, maybe-array
)

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
            let translations = maybe-array(get-meta(name, dir: base).at("translations", default: "en"))
            if "en" not in translations {
                translations.push("en")
            }
            for tr in translations {
                let id = resolve-translation(name, tr)
                let p = join-paths((base, id))
                if is-lsp { continue }
                document(p + ".html")[
                    // workaround: using labels to limit which headings appear in outline
                    #metadata("start") #label("__meta_doc_start_" + id)
                    #include content-dir + "/" + p + ".typ"
                    #metadata("end") #label("__meta_doc_end_" + id)
                ]
            }
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

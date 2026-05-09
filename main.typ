#import "/lib/lib.typ": (
    get-meta, join-paths, real-path, nunito-font-variants,
    font-path, is-lsp, get-meta, resolve-translation, maybe-array,
    folders, folder-paths, template, posts-list
)

#let content-dir = "content"
#let public-dir = "public"

// relative to content-dir
#let files = (
    notes: (
        local-nixpkgs-build: none,
        run-zsh-nix-develop: none,
    ),
    about-blog: none,
    why-i-dont-like-go: none,
)

#let add-index(folder-name, files-map) = {
    let folder = folders.at(folder-name, default: folders.blog)
    let folder-path = folder-paths.at(folder)
    let posts = files-map.pairs().filter(((_, v)) => v == none).map(((k, _)) => k)
    if is-lsp { return }
    document(folder-path + "/index.html")[
        #show: template.with(folder: folder, index: true)
        #posts-list(posts, dir: folder-path + "/")
    ]
}

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
            let path = join-paths((base, name))
            add-index(name, nested)
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

#add-index("blog", files)
#add-files(files)
#add-asset("favicon.png")
#for (style, weight) in nunito-font-variants {
    let path = font-path(style, weight)
    add-asset(path)
}

#import "/lib.typ": get-meta, join-paths

#let content-dir = "content"
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

#add-files(files)

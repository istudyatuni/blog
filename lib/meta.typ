#import "path.typ": join-paths, real-path

#let get-meta(path, dir: "") = {
    import "/content/" + join-paths((dir, path)) + ".typ": meta
    meta
}

#let collect-meta(posts, dir: "") = {
    for path in posts {
        ((path): get-meta(path, dir: dir))
    }
}

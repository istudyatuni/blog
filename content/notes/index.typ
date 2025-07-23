#import "/lib.typ": template, posts-list, folders

#let meta = (
    folder: folders.notes,
    index: true,
)

#show: template.with(folder: meta.folder, index: true)

#let posts = (
    "local-nixpkgs-build",
)

#posts-list(posts, dir: "notes/")

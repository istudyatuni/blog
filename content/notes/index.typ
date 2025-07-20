#import "/lib.typ": template, posts-list, folders

#let meta = (
    folder: folders.notes,
)

#show: template.with(folder: meta.folder, index: true)

#let posts = (
    "local-nixpkgs-build",
)

#posts-list(posts, dir: "notes/")

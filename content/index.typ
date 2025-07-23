#import "/lib.typ": template, posts-list, folders

#let meta = (
    folder: folders.blog,
)

#show: template.with(folder: meta.folder, index: true)

#let posts = (
    "about-blog.ru",
    "why-i-dont-like-go",
)

#posts-list(posts)

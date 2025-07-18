#import "/lib.typ": template, sanitize-content

#show: template.with(title: "My notes", title-as-heading: false)

// each post should contain importable "title" which are either content or string. it will be used as
// import "post.typ": title
#let posts = (
    "why-i-dont-like-go",
    "local-nixpkgs-build",
)

#for path in posts [
    #let title = {
        import path + ".typ": title
        let title = if type(title) == content {
            sanitize-content(title)
        } else if type(title) == str {
            title
        } else {
            show: html.span.with(style: "color: red")
            [unexpected title type #type(title), expected on of #(type([]), type(""))]
        }
        title
    }
    #[
        #show: html.span.with(class: "list")
        #link(path + ".html", title)
    ]
    // spacing
    #html.br()
    #html.br()
]

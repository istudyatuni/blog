#import "constants.typ": folders, folder-names
#import "path.typ": real-folder-path

#let switch_theme_button = html.elem("button", attrs: ("onclick": "switch_theme()"))[Change theme]
#let wip = [_*Work in progress*_]
#let wip-draft = [_Draft_]

#let navbar(title, dest: "..", as-link: true, folder: none) = {
    let folders-links = if folder != none {
        folders.keys()
            .filter(k => k != folder)
            .map(k => link(real-folder-path(k), folder-names.at(k)))
    } else {
        ()
    }
    html.header[
        #html.p[
            #html.span(class: "header-links")[
                #if as-link {
                    link(dest)[#title]
                } else {
                    title
                }
                #for l in folders-links {
                    html.span(class: "other", l)
                }
            ]
        ]
        #switch_theme_button
    ]
}

#let note(title, body) = {
    show: html.div.with(class: "note")
    html.p(class: "title", emph(title))
    body
}

#import "syntect-plugin/lib.typ" as syntect

// #let content-to-string

// remove markup from content
// currently removes:
// - links
#let sanitize-content(it) = {
    assert.eq(type(it), content)
    it.children.map(c => {
        if c.func() == link {
            c.body
        } else {
            c
        }
    })
    .join()
}

#let switch_theme_button = html.elem("button", attrs: ("onclick": "switch_theme()"))[Change theme]

#let navbar() = {
    html.header[
        #link("/")[My notes]
        #switch_theme_button
    ]
}

#let og(name, value) = {
    if type(value) == array {
        for e in value {
            og(name, e)
        }
    } else {
        html.elem("meta", attrs: (property: "og:" + name, content: value))
    }
}

#let template(
    title: none,
    title-as-heading: true,
    show-header: true,
    it,
) = {
    // fix lsp can't sample values because of usage of html
    if sys.inputs.at("lsp", default: "false") == "true" {
        return it
    }

    show: html.elem.with("html")
    html.meta(charset: "utf-8")
    html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
    html.elem("meta", attrs: (name: "color-scheme", content: "dark"))
    if type(title) == content {
        html.title(sanitize-content(title))
    } else {
        html.title(title)
    }
    // todo: convert content to str
    if type(title) == str {
        og("title", title)
    }
    html.style(read("public/main.css"))
    html.script(read("public/main.js"))

    show: html.body.with()
    html.script("restore_theme()")

    show: html.elem.with("main")

    if show-header {
        navbar()
    }

    show raw: it => {
        if it.lang == none or ("typ", "typc").contains(it.lang) {
            return it
        }
        let render-code(it, class-name) = {
            let render = syntect.highlight-html(
                it.lang,
                block: it.block,
                variant: class-name,
                it.text,
            )
            if not it.block {
                box(render)
            } else {
                render
            }
        }
        render-code(it, "dark")
        render-code(it, "light")
    }

    show heading: it => {
        if target() != "html" or not it.has("label") { return it }
        let label-name = repr(it.label).replace(regex("^<|>$"), "")
        let html-level = calc.min(it.level + 1, 6)
        set html.elem("h" + str(html-level), attrs: (
            id: label-name,
            class: "pointer heading-id",
            onclick: ```js set_heading("```.text + label-name + ```js ")```.text,
        ))
        it
    }

    if title != none and title-as-heading {
        if type(title) == str or (type(title) == content and title.func() != heading) {
            [= #title]
        } else if type(title) == content {
            title
        }
    }

    it
}

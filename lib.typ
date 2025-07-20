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

#let gen-css-fonts(
    name,
    format: "woff2",
    variants: (("normal", 200)),
    path-fn: (style, weight) => style + weight + ".ttf",
) = {
    let attr(name, value) = "  " + name + ": " + str(value) + ";\n"
    let string(value) = "'" + value + "'"
    let url(value) = "url(" + string(value) + ")"
    let format-value(value) = "format(" + string(value) + ")"

    let res = ""
    for (style, weight) in variants {
        let face = "@font-face {\n";
        // https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face/font-display
        face += attr("font-display", "swap")
        face += attr("font-family", string(name))
        face += attr("font-style", style)
        face += attr("font-weight", weight)
        // Chrome 36+, Opera 23+, Firefox 39+, Safari 12+, iOS 10+
        face += attr("src", url(path-fn(style, weight)) + " " + format-value(format))
        res += face + "}\n"
    }
    res
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
    html.style(gen-css-fonts(
        "Nunito",
        // from google-webfonts-helper: https://gwfh.mranftl.com/fonts/nunito?subsets=cyrillic,latin
        variants: {
            let weights = array.range(200, 901, step: 100)
            weights.map(w => ("normal", w))
            weights.map(w => ("italic", w))
        },
        path-fn: (style, weight) => {
            let res = "/fonts/nunito-v31-cyrillic_latin-"
            if weight != 400 {
                res += str(weight)
                if style != "normal" {
                    res += style
                }
            } else {
                res += if style == "normal" { "regular" } else { "italic" }
            }
            res + ".woff2"
        },
    ))
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

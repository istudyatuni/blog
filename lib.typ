#import "syntect-plugin/lib.typ" as syntect

#let folders = (
    blog: "blog",
    notes: "notes",
)

#let root-folder = folders.blog

#let folder-names = (
    blog: "My blog",
    notes: "My notes",
)

#let folder-paths = (
    blog: "",
    notes: "notes",
)

#let base = sys.inputs.at("base", default: "")

#let months-long = (
    ru: (
        January: "Января",
        February: "Февраля",
        March: "Марта",
        April: "Апреля",
        May: "Мая",
        June: "Июня",
        July: "Июля",
        August: "Августа",
        September: "Сентября",
        October: "Октября",
        November: "Ноября",
        December: "Декабря",
    ),
)

#let translation-link-text = (
    ru: "Читать на русском",
    en: "Read in English",
)

#let default-lang = "en"

#let link-translation(id, lang) = {
    if lang == default-lang {
        return id + ".html"
    }
    id + "." + lang + ".html"
}

#let join-paths(parts) = {
    let res = parts.filter(p => p != "")
    if res.len() == 0 {
        return ""
    }
    res.join("/").replace("//", "/")
}

#let path-dest(path) = {
    "/" + join-paths((base, path))
}

#let folder-dest(folder) = {
    path-dest(folder-paths.at(folder))
}

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
#let wip = [_*Work in progress*_]
#let wip-draft = [_Draft_]

#let navbar(title, dest: "..", as-link: true, folder: none) = {
    let folders-links = if folder != none {
        folders.keys()
            .filter(k => k != folder)
            .map(k => link(folder-dest(k), folder-names.at(k)))
    } else {
        ()
    }
    html.header[
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

#let show-title(title, index) = {
    if title != none and not index {
        if type(title) == str or (type(title) == content and title.func() != heading) {
            [= #title]
        } else if type(title) == content {
            title
        }
    }
}

#let show-date(date) = context {
    let res = date.display("[day] [month repr:long] [year]")
    if text.lang == "en" {
        res
    } else if text.lang == "ru" {
        let (m, replaced) = months-long.ru.pairs().at(date.month() - 1)
        show m: replaced
        res
    } else {
        [Unknown lang for date]
    }
}

#let pdf-template(
    title: none,
    index: false,
    it,
) = {
    show link: set text(fill: blue)

    show-title(title, index)

    it
}

#let template(
    // name of file without .typ/.ru.typ, required when translations is set
    id: none,
    // in which folder template is applied
    folder: none,
    // if it's a folder's index file
    index: false,
    // title of page. leave none if in index
    title: none,
    // text to be written under title
    subtitle: none,
    // language of text
    lang: default-lang,
    // available translations for this post
    translations: (),
    // whether to write "work in progress" under title
    draft: false,
    // creation date
    created: none,
    it,
) = {
    assert(not (draft and created != none), message: "can't be draft and has creation date")
    assert(folder != none, message: "folder should be set")
    assert(("en", "ru").contains(lang), message: "language should be on of (en, ru)")
    assert(folder != none, message: "folder should be set")

    let translations = if type(translations) == str {
        (translations,)
    } else {
        translations
    }

    assert((str, array).contains(type(translations)), message: "translations should be either string or array")
    assert(not translations.contains(lang), message: "translations should not contain lang")
    assert(not (id == none and translations.len() != 0), message: "id should be set when translations is set")

    set text(lang: lang)

    context if target() == "paged" {
        return pdf-template(index: index, title: title, it)
    }
    // fix lsp can't sample values because of usage of html
    if sys.inputs.at("lsp", default: "false") == "true" {
        return it
    }

    let title = if index {
        folder-names.at(folder)
    } else if type(title) == content {
        sanitize-content(title)
    } else {
        title
    }

    show: html.html.with(lang: lang)
    html.meta(charset: "utf-8")
    html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
    html.meta(name: "color-scheme", content: "dark")

    html.title(title)
    // todo: convert content
    if type(title) == str {
        if subtitle != none and type(subtitle) == str {
            og("title", title + " " + subtitle)
        } else {
            og("title", title)
        }
    }

    // https://icons8.com/icon/L0iBlZCZtM8q/blog
    html.link(type: "image/png", sizes: ((32, 32),), rel: "icon", href: path-dest("favicon.png"))

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

    show: html.body.with(class: "dark")
    html.script("restore_theme()")

    show: html.main

    navbar(
        folder-names.at(folder),
        dest: folder-dest(folder),
        as-link: not index,
        folder: folder,
    )

    show raw: it => {
        if (none, "typc",).contains(it.lang) {
            return it
        }
        let render-code(it, class-name) = {
            let render = syntect.highlight-html(
                it.lang,
                block: it.block,
                variant: class-name,
                it.text,
            )
            render
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

    set quote(quotes: false)
    show quote: it => {
        show: html.blockquote
        it
    }

    [
        #show-title(title, index)

        #subtitle

        #if draft {
            wip
        }

        #if created != none {
            show: emph
            show-date(created)
        }

        #if translations.len() != 0 {
            for tr in translations {
                link(link-translation(id, tr), translation-link-text.at(tr))
            }
        }
    ]

    it
}

// each post should contain importable "title" which are either content or string. it will be used as
// import "post.typ": title
#let posts-list(posts, dir: "") = {
    for path in posts [
        #import "content/" + dir + path + ".typ": meta
        #let title = {
            let title = meta.title
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
        #let draft = meta.at("draft", default: false)
        #let created = meta.at("created", default: none)
        #[
            #show: html.span.with(class: "list")
            #link(path + ".html", title)
            #if draft [
                #html.br()
                #wip-draft
            ]
            #if created != none [
                #html.br()
                #show: emph
                #show-date(created)
            ]
        ]
        // spacing
        #html.br()
        #html.br()
    ]
}

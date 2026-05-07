// todo: unhardcode
#let deploy-url = "istudyatuni.github.io"

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

#let css-root-theme-selector = (
    dark: "body.dark",
    light: "body.light",
)
#let palettes = (
    light: yaml("assets/themes/github.yaml").palette,
    dark: yaml("assets/themes/harmonic16-dark.yaml").palette,
)

// from google-webfonts-helper: https://gwfh.mranftl.com/fonts/nunito?subsets=cyrillic,latin
#let nunito-font-variants = {
    let weights = array.range(200, 901, step: 100)
    weights.map(w => ("normal", w))
    weights.map(w => ("italic", w))
}

#let hex-int = array.range(0, 10).map(str) + ("a", "b", "c", "d", "e", "f")

#let base = sys.inputs.at("base", default: "")
#let is-lsp = sys.inputs.at("lsp", default: "false") == "true"

#let months-long = (
    ru: (
        January: "января",
        February: "февраля",
        March: "марта",
        April: "апреля",
        May: "мая",
        June: "июня",
        July: "июля",
        August: "августа",
        September: "сентября",
        October: "октября",
        November: "ноября",
        December: "декабря",
    ),
)

#let translation-link-text = (
    ru: "Читать на русском",
    en: "Read in English",
)

#let toc-text = (
    ru: "Содержание",
    en: "Table of Contents",
)

#let default-lang = "en"

#let tags-display-joiner = [ #sym.dot.c ]
#let tags-default-display(tags) = tags.map(t => "#" + t).map(html.span.with(class: "tag")).join(tags-display-joiner)

#let resolve-translation(id, lang) = {
    if lang == default-lang {
        return id
    }
    id + "." + lang
}

#let link-translation(id, lang) = {
    resolve-translation(id, lang) + ".html"
}

// Join paths with /
#let join-paths(parts) = {
    let res = parts.filter(p => p != "")
    if res.len() == 0 {
        return ""
    }
    res.join("/").replace(regex("//+"), "/")
}

// Absolute path
#let real-path(path) = {
    ("/" + join-paths((base, path))).replace(regex("//+"), "/")
}

// Absolute folder path
#let real-folder-path(folder) = {
    real-path(folder-paths.at(folder))
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

#let font-path(style, weight) = {
    let res = "/fonts/nunito-cyrillic_latin-"
    if weight != 400 {
        res += str(weight)
        if style != "normal" {
            res += style
        }
    } else {
        res += if style == "normal" { "regular" } else { "italic" }
    }
    res + ".woff2"
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

#let css-for-theme(selector, palette) = {
    palette
        .pairs()
        .sorted()
        .map(((_, c)) => c).enumerate().map(((n, c)) => {
            selector + " .b" + hex-int.at(n) + "{color:" + c + "}"
        })
        .join()
}

#let fixup-theme(palette) = {
    let theme = read("assets/base16.tmTheme")
    for i in hex-int {
        let dec = str(int(i, base: 16))
        if dec.len() == 1 {
            dec = "0" + dec
        }
        theme = theme.replace("#0000" + dec, palette.at("base0" + upper(i)))
    }
    theme
}

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
        set heading(outlined: false)
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

// Put value in array if it's not array. It `ty` is not `auto`, return array
// only if `type(value)` is equal to `ty`
#let maybe-array(value, ty: auto) = {
    if ty != auto {
        if type(value) == ty {
            (value,)
        } else {
            value
        }
    } else if type(value) != array {
        (value,)
    } else {
        value
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
    // required
    // todo: this is required only to set og:url
    // old description:
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
    // tag or list of tags
    tags: (),
    // whether to write "work in progress" under title
    draft: false,
    // creation date
    created: none,
    // whether to show table of contents
    toc: true,
    it,
) = {
    assert(not (draft and created != none), message: "can't be draft and has creation date")
    assert(folder != none, message: "folder should be set")
    assert(("en", "ru").contains(lang), message: "language should be one of (en, ru)")
    assert(folder != none, message: "folder should be set")

    assert((str, array).contains(type(translations)), message: "translations should be either string or array")
    assert(not translations.contains(lang), message: "translations should not contain lang")
    assert((str, array).contains(type(tags)), message: "tags should be either string or array")

    let translations = maybe-array(translations)
    let tags = maybe-array(tags)

    // todo: see comment about id
    assert(index or id != none, message: "id should be set when non-index")
    // assert(not (id == none and translations.len() != 0), message: "id should be set when translations is set")

    set text(lang: lang)

    context if target() == "paged" {
        return pdf-template(index: index, title: title, it)
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
    og("type", "article")
    og("image", real-path("favicon.png"))
    og("image:width", "32")
    og("image:height", "32")
    let url-path = join-paths((
        if folder != none { real-folder-path(folder) } else { "" },
        if id != none { id + ".html" } else { "" },
    ))
    og("url", "https://" + deploy-url + url-path)

    // https://icons8.com/icon/L0iBlZCZtM8q/blog
    html.link(type: "image/png", sizes: ((32, 32),), rel: "icon", href: real-path("favicon.png"))

    html.style(gen-css-fonts(
        "Nunito",
        variants: nunito-font-variants,
        path-fn: (style, weight) => real-path(font-path(style, weight)),
    ))
    html.style(read("public/main.css"))
    html.script(read("public/main.js"))
    // html.style(css-for-theme(css-root-theme-selector.dark, palettes.dark))
    // html.style(css-for-theme(css-root-theme-selector.light, palettes.light))

    show: html.body.with(class: "dark")
    html.script("restore_theme()")

    show: html.main

    navbar(
        folder-names.at(folder),
        dest: real-folder-path(folder),
        as-link: not index,
        folder: folder,
    )

    // dark palette looks ok in light theme
    set raw(theme: bytes(fixup-theme(palettes.dark)))

    // doesn't work in latest typst
    /*// to recognize different tokens
    set raw(theme: "assets/base16.tmTheme")
    show raw: it => {
        show: if it.block {
            html.pre
        } else {
            html.code
        }
        show html.elem.where(tag: "span"): it => {
            let color-css-prefix = "color:"
            // not work, attrs now empty, and body contains styled(...)
            if not "style" in it.attrs or not it.attrs.style.contains(color-css-prefix) {
                return it
            }

            // overengineered to not remove possible extra attributes
            let styles = it.attrs.style.split(";").map(s => s.trim())
            let color = styles.find(s => s.starts-with(color-css-prefix))

            // remove inline color from attrs
            let attrs = it.attrs
            attrs.style = styles.filter(s => not s.starts-with(color-css-prefix)).join("; ")
            if attrs.style == none {
                attrs.remove("style")
            }

            let hex-number = hex-int.at(int(color.trim("color: #0000")))
            html.elem("span", attrs: (class: "b" + hex-number, ..attrs), it.body)
        }
        for line in it.lines {
            line.body
            if it.block {
                html.br()
            }
        }
    }*/

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

    // content block is used to separated each part in its own <p>
    [
        #show-title(title, index)

        #show heading.where(level: 1): it => panic("content should not have headings with level 1")

        #subtitle

        #if created != none {
            show: emph
            show-date(created)
        } else if draft {
            wip
        }
        #if created != none or draft {
            html.span(style: "margin-left: 1.5em", tags-default-display(tags))
        } else {
            tags-default-display(tags)
        }

        #if translations.len() != 0 {
            for tr in translations {
                link(link-translation(id, tr), translation-link-text.at(tr))
            }
        }

        #if not index and toc {
            show outline: it => {
                show: html.div.with(class: "toc-list")
                it
            }
            show outline.entry: it => {
                // 2 is minimal heading.level inside page, decrease it so
                // outline doesn't have extra indent on left side
                let level = (it.level - 2)
                html.span(style: "padding-left: " + str(level) + "em", it)
            }
            context heading(level: 2, outlined: false, toc-text.at(text.lang))
            let id = resolve-translation(id, lang)
            outline(
                // workaround while outline show headings from all documents in bundle
                target: selector(heading.where(outlined: true))
                    .after(label("__meta_doc_start_" + id))
                    .before(label("__meta_doc_end_" + id)),
                title: none,
            )
        }
    ]

    it
}

#let get-meta(path, dir: "") = {
    import "content/" + join-paths((dir, path)) + ".typ": meta
    meta
}

#let collect-meta(posts, dir: "") = {
    for path in posts {
        ((path): get-meta(path, dir: dir))
    }
}

// each post should contain importable "meta" dict with the same values as
// passed to `template()`. it will be used as import "post.typ": meta
#let posts-list(posts, dir: "") = {
    let meta = collect-meta(posts, dir: dir)

    // all tags
    // deduplicate
    let tags = meta
        .values()
        .map(m => m.at("tags", default: ()))
        .flatten()
        .map(t => (t, none))
        .to-dict()
        .keys()
        .sorted()
    // using "~=" can break if one tag is part of other tag, e.g. "ta" and "tag"
    let tag-filter-css = ```css
    body[data-tag-filter = "TAG"] [data-tags]:not([data-tags ~= "TAG"]) {
        display: none;
    }
    body[data-tag-filter = "TAG"] .tag[data-tag = "TAG"] {
        color: var(--secondary);
    }
    ```.text
    html.style(tags.map(t => tag-filter-css.replace("TAG", t)).join("\n"))
    {
        show: html.p.with(class: "tags-top-block")
        [Tags: ]
        tags
            .map(t => html.elem(
                "span",
                attrs: (
                    class: ("tag", "pointer").join(" "),
                    title: "Click to filter by #" + t,
                    onclick: "set_tag_filter(this)",
                    data-tag: t,
                ),
                "#" + t,
            ))
            .join(tags-display-joiner)
    }

    let posts = posts.sorted(key: p => meta.at(p).at("created", default: datetime.today())).rev()
    for path in posts {
        let meta = meta.at(path)
        let title = {
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

        let draft = meta.at("draft", default: false)
        let created = meta.at("created", default: none)
        let tags = maybe-array(meta.at("tags", default: ()), ty: str)

        show: html.elem.with("div", attrs: (
            class: ("list", "index-post-item").join(" "),
            data-tags: if tags != () { tags.join(" ") } else { "" },
        ))
        link(path + ".html", title)
        if draft {
            html.br()
            wip-draft
        }
        if created != none {
            html.br()
            show: emph
            show-date(created)
        }
        show: html.span.with(style: "margin-left: 1.5em")
        tags-default-display(tags)
    }
}

#let note(title, body) = {
    show: html.div.with(class: "note")
    html.p(class: "title", emph(title))
    body
}

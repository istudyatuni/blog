#import "constants.typ": date-created-format, months-long, toc-text
#import "state.typ": doc-name
#import "resolve.typ": resolve-translation

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
    let res = date.display(date-created-format.at(text.lang))
    if text.lang == "en" {
        return res
    }
    let (m, replaced) = months-long.at(text.lang).pairs().at(date.month() - 1)
    show m: replaced
    res
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

// workaround while outline show headings from all documents in bundle
#let workaround-outline-wrap(id, body) = [
    #metadata("start") #label("__meta_doc_start_" + id)
    #body
    #metadata("end") #label("__meta_doc_end_" + id)
]

#let workaround-outline(title: "Contents") = context {
    let lang = text.lang
    let id = doc-name.at(here())
    let id = resolve-translation(id, lang)
    let target = selector(heading.where(outlined: true))
        .after(label("__meta_doc_start_" + id))
        .before(label("__meta_doc_end_" + id))
    if query(target).len() > 0 {
        heading(outlined: false, title)
    }
    outline(target: target, title: none)
}

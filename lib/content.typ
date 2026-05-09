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

// https://sitandr.github.io/typst-examples-book/book/typstonomicon/extract_plain_text.html
#let content-to-text(it) = {
    if type(it) == str {
        it
    } else if it == [ ] {
        " "
    } else if it.has("children") {
        it.children.map(content-to-text).join()
    } else if it.has("body") {
        content-to-text(it.body)
    } else if it.has("text") {
        if type(it.text) == str {
            it.text
        } else {
            content-to-text(it.text)
        }
    }
}

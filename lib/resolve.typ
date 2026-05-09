#import "constants.typ": default-lang

#let resolve-translation(id, lang) = {
    if lang == default-lang {
        return id
    }
    id + "." + lang
}

#let link-translation(id, lang) = {
    resolve-translation(id, lang) + ".html"
}

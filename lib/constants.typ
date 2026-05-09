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
    light: yaml("/assets/themes/github.yaml").palette,
    dark: yaml("/assets/themes/harmonic16-dark.yaml").palette,
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

#let date-format = (
    en: "[day] [month repr:short]. [year]",
)
#let date-created-format = (
    en: "[month repr:short] [day], [year]",
    ru: "[day] [month repr:long] [year]",
)

#let default-lang = "en"

#let tags-display-joiner = [ #sym.dot.c ]
#let tags-default-display(tags) = tags.map(t => "#" + t).map(html.span.with(class: "tag")).join(tags-display-joiner)

#let _plugin = plugin("target/wasm32-unknown-unknown/release/syntect_plugin.wasm")
#let _plugin = plugin.transition(_plugin.init)

#let themes = (
    "github": "InspiredGitHub",
    "base16-ocean-dark": "base16-ocean.dark",
    "base16-ocean-light": "base16-ocean.light",
    "solarized-dark": "Solarized (dark)",
    "solarized-light": "Solarized (light)",
    "base16-eighties-dark": "base16-eighties.dark",
    "base16-mocha-dark": "base16-mocha.dark",
)

#let ext-scope = (
    typc: "source.typst",
)

#let is-theme-light(theme) = {
    (themes.github, themes.base16-ocean-light, themes.solarized-light).contains(theme)
}

#let default-dark-theme = themes.base16-mocha-dark
#let default-light-theme = themes.github

#let default-theme(variant) = {
    (
        dark: default-dark-theme,
        light: default-light-theme,
    )
}

#let highlight-html(
    lang,
    block: false,
    // theme variant
    variant: "dark",
    // override default themes
    theme: none,
    text,
) = {
    let args = (
        extension: lang,
        scope: ext-scope.at(lang, default: none),
        text: text,
        theme: if theme == none { default-theme(variant) } else { theme },
        selector: (
            dark: "body.dark",
            light: "body.light",
        ),
    )
    let res = cbor(_plugin.highlight_html(cbor.encode(args)))

    let convert(block: false) = {
        let func = if block { html.pre } else { html.code }
        let res = func(
            class: variant,
            for (css_class, text) in res.items {
                html.span(class: css_class, text)
            }
        )
        res
    }
    (
        content: convert(block: block),
        css: res.css,
    )
}

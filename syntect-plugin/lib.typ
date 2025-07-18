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

#let is-theme-light(theme) = {
    (themes.github, themes.base16-ocean-light, themes.solarized-light).contains(theme)
}

#let default-dark-theme = themes.base16-mocha-dark
#let default-light-theme = themes.github

#let default-theme(variant) = {
    if variant == "dark" {
        default-dark-theme
    } else {
        default-light-theme
    }
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
        text: text,
        theme: if theme == none { default-theme(variant) } else { theme },
    )
    let res = cbor(_plugin.highlight_html(cbor.encode(args)))

    let convert(block: false) = {
        let func = if block { html.pre } else { html.code }
        let res = func(
            class: variant,
            for (color: c, text) in res {
                let rgb = (c.r, c.g, c.b).map(str).join(", ")
                html.span(style: "color: rgb(" + rgb + ")", text)
            }
        )
        if block {
            res
        } else {
            show: html.span.with(style: "display: inline-block")
            res
        }
    }
    convert(block: block)
}

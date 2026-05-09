#import "constants.typ": hex-int

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

#let fill-theme-colors(palette) = {
    let theme = read("/assets/base16.tmTheme")
    for i in hex-int {
        let dec = str(int(i, base: 16))
        if dec.len() == 1 {
            dec = "0" + dec
        }
        theme = theme.replace("#0000" + dec, palette.at("base0" + upper(i)))
    }
    theme
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

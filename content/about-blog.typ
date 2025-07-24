#import "/lib.typ": template, wip, folders

#let meta = (
    id: "about-blog",
    folder: folders.blog,
    title: "How I made blog in Typst",
    subtitle: "and a bit of Rust",
    translations: "ru",
    created: datetime(day: 23, month: 7, year: 2025),
)

#let css(name) = raw(lang: "css", name)

#show: template.with(..meta)

#link("https://github.com/istudyatuni/blog")[Source code]

In Typst 0.13 (released February 19) experimental HTML export has been added, development also continued in June and July, for example, #link("https://github.com/typst/typst/pull/6476")[typed API] has been added:

```typ
// instead
#html.elem("div", attrs: (class: "block"))
// you can now write
#html.div(class: "block")
```

As a result, I used the latest version at that time

== Syntax highlighting <syntax-highlighting>

Since highlighting the code by splitting it into separate #css("span")s with the required classes wasn't supported, I initially did it by embedding SVG:

```typ
#show raw: it => {
    let render-code(it, text-color, class-name) = {
        set text(fill: text-color)
        let render = html.frame(it)
        if not it.block { box(render) } else { render }
    }
    // to suport dark/light theme switching
    render-code(it, text-dark, "dark")
    render-code(it, text-light, "light")
}
```

But with this approach text selection doesn't work, because now Typst rasterises text (#link("https://github.com/typst/typst/issues/4702")[feature request exists] to insert text as-is) when exporting to SVG, and ```typ #html.frame()``` just renders some content in SVG

_this is not recorded in git history because I squashed everything and left only the final version_

Switching between blocks for dark/light theme is done using CSS depending on the #css("body")'s class:

```css
body:not(.light) span.light {
    display: none;
}
body.light span.dark {
    display: none;
}
```

=== Highlighting with the plugin <syntax-plugin-highlighting>

I wrote a small plugin in Rust for code highlighting using #link("https://github.com/trishume/syntect")[syntect] library (Typst uses the same) + #link("https://github.com/cosmichorrordev/two-face")[two-face] (additional syntaxes)

==== Plugin initializing <plugin-init>

Initializing is required to use #link("https://typst.app/docs/reference/foundations/plugin/#definitions-transition")[plugin transition API]. Data is saved in ```rs static```:

```rs
pub struct SyntectData {
    syntaxes: SyntaxSet,
    themes: ThemeSet,
}
struct Context(Option<SyntectData>);
static DATA: Mutex<Context> = Mutex::new(Context(None));
```

when ```rs init()``` is called data is saved in ```rs DATA```:

```rs
#[wasm_func]
pub fn init() -> Vec<u8> {
    DATA.lock().unwrap().0.replace(SyntectData {
        syntaxes: two_face::syntax::extra_newlines(),
        themes: ThemeSet::load_defaults(),
    });
    "ok".to_string().into_bytes()
}
```

and plugin is created on the Typst side like this:

```typ
#let _plugin = plugin("syntect_plugin.wasm")
#let _plugin = plugin.transition(_plugin.init)
```

_The way data is stored is inspired by #link("https://github.com/lublak/typst-ctxjs-package/blob/15f7e7f5c81856bdeef64d01d7b01424312ec39d/src/lib.rs#L18")[typst-ctxjs-package]_

==== Generation <syntax-highlighting-generation>

_Error handling is omited below_:

- instead of ```rs f().map_err(/* error handling */)?``` - ```rs f()?```
- instead of ```rs f().ok_or_else(/* none handling */)?``` - ```rs f().ok()?```

Function is simple:

```rs
#[wasm_func]
pub fn highlight_html(args: &[u8]) -> Result<Vec<u8>, String> {
    let args: HighlightInput = ciborium::from_reader(args)?;
    let data = /* get DATA */;
    let mut result = vec![];
    // ...
    let mut out = vec![];
    ciborium::into_writer(&result, &mut out)?;
    Ok(out)
}
```

It takes `cbor` encoded parameters:

```rs
#[derive(Debug, Deserialize)]
struct HighlightInput {
    extension: String,
    text: String,
    #[serde(default = "default_theme")]
    theme: String,
}
fn default_theme() -> String {
    "base16-ocean.dark".to_string()
}
```

Searches syntax by extension and color scheme by name:

```rs
let syntax = data
    .syntaxes
    .find_syntax_by_extension(&args.extension)
    .ok()?;
let theme = data.themes.themes.get(&args.theme).ok()?;
let mut highlighter = HighlightLines::new(syntax, theme);
```

Collects resulting colors and texts:

```rs
let mut result = vec![];
for line in LinesWithEndings::from(&args.text) {
    let ranges = highlighter
        .highlight_line(line, &data.syntaxes)?;
    for (color, s) in ranges {
        result.push(HighlightOutput::new(color.foreground, s));
    }
}
```

And returns `cbor` encoded list of elements with respective colors:

```rs
#[derive(Debug, Serialize)]
struct HighlightOutput {
    color: syntect::highlighting::Color,
    text: String,
}
```

==== Converting result to HTML on the Typst side <convert-highlighting-to-html>

For every element create #css("span") with respective color:

```typ
#let highlight-html(lang, theme: none, text) = {
    let args = (/* construct arguments */)
    let res = cbor(_plugin.highlight_html(cbor.encode(args)))
    html.pre(
        for (color: c, text) in res {
            let rgb = (c.r, c.g, c.b).map(str).join(", ")
            html.span(style: "color: rgb(" + rgb + ")", text)
        }
    )
}
```

_Code is actually a bit more complicated, it handles generation for dark/light theme, is #css("pre") or #css("code") required, and sets a default theme_

== Fonts <fonts>

I wanted to use font directly from Google Fonts, something like this:

```css
@import url('https://fonts.googleapis.com/css2?family=Nunito&display=swap');
```

but with this approach the moment when font is changing from default was noticeable. I decided to download it separately, but I didn't want to store it in Git. But Google Fonts doesn't provide an API for font downloading. I found a #link("https://gwfh.mranftl.com")[google-webfonts-helper], you can download from there

In the result archive with fonts is downloading when building, unpacked, and Typst generates CSS. Function takes parameters:

```typ
#let gen-css-fonts(
    name,
    format: "woff2",
    variants: (("normal", 200)),
    path-fn: (style, weight) => style + weight + ".ttf",
) = {
    // attr, string, url, format-value ...

    // ...
}
```

and ```css @font-face``` is created for each variant:

```typ
#let res = ""
#for (style, weight) in variants {
    let face = "@font-face {\n";
    face += attr("font-display", "swap")
    face += attr("font-family", string(name))
    face += attr("font-style", style)
    face += attr("font-weight", weight)
    // Chrome 36+, Opera 23+, Firefox 39+, Safari 12+, iOS 10+
    face += attr(
        "src",
        url(path-fn(style, weight)) + " "
        + format-value(format),
    )
    res += face + "}\n"
}
#res
```

== Deploying with GitHub Workflows <gh-workflows>

I'm writing this section only because I found an easy way to install apps on CI without the need to use any other actions for each specific app or to install it manually

=== Installing apps with Nix <gh-workflows-nix>

We need 2 actions, that are enabled like this:

```yaml
steps:
  - uses: DeterminateSystems/nix-installer-action@main
  - uses: DeterminateSystems/magic-nix-cache-action@main
```

and after this we can install any app that available in #link("https://search.nixos.org/packages")[Nix packages repository]:

```yaml
- name: install tools
  run: |
    nix profile add "nixpkgs#just" && just -V
    nix profile add "nixpkgs#fd" && fd -V
```

or any app that has `flake.nix`, for example, Typst:

```yaml
- name: install typst
  run: |
    nix profile add "github:typst/typst?rev=b790c6d59ceaf"
    typst -V
```

=== Publish to GitHub Pages <gh-workflows-pages>

For this we need in repository setting in "Pages" choose Source - GitHub Actions and add this:

```yaml
- uses: actions/configure-pages@v5
- uses: actions/upload-pages-artifact@v3
  with:
    path: ./dist/blog
- uses: actions/deploy-pages@v4
```

Thats all! See #link("https://github.com/istudyatuni/blog")[source code] for details

#import "/lib.typ": template, folders, show-date, note

#let meta = (
    id: "about-blog",
    folder: folders.blog,
    title: "Как я сделал блог на Typst",
    subtitle: "и немного Rust",
    lang: "ru",
    translations: "en",
    created: datetime(day: 23, month: 7, year: 2025),
)

#let css(name) = raw(lang: "css", name)

#show: template.with(..meta)

#link("https://github.com/istudyatuni/blog")[Исходный код]

В Typst 0.13 (релиз 19 февраля) добавили экспериментальный экспорт в HTML, также в июне и июле продолжалась разработка, например, добавили #link("https://github.com/typst/typst/pull/6476")[типизированное API]:

```typ
// вместо
#html.elem("div", attrs: (class: "block"))
// можно писать
#html.div(class: "block")
```

По итогу я использовал самую последнюю версию на тот момент

== Подсветка синтаксиса <syntax-highlighting>

Т.к. не было поддержки преобразования блоков кода с разбиением на отдельные #css("span") с нужными классами, сначала я сделал через встраивание SVG:

```typ
#show raw: it => {
    let render-code(it, text-color, class-name) = {
        set text(fill: text-color)
        let render = html.frame(it)
        if not it.block { box(render) } else { render }
    }
    // для поддержки переключения темной и светлой темы
    render-code(it, text-dark, "dark")
    render-code(it, text-light, "light")
}
```

Но с таким подходом не работает выделение текста, потому что пока что Typst растеризует текст (#link("https://github.com/typst/typst/issues/4702")[есть запрос], чтобы текст вставлялся как есть), когда экспортирует в SVG, а ```typ #html.frame()``` как раз рендерит контент в SVG

_этого кода нет в истории т.к. я все схлопнул и оставил только итоговую версию_

Переключение блоков светлой/темной темы сделано через CSS в зависимости от того, какой класс стоит у #css("body"):

```css
body:not(.light) span.light {
    display: none;
}
body.light span.dark {
    display: none;
}
```

=== Подсветка через плагин <syntax-plugin-highlighting>

Я сделал небольшой плагин на Rust, который бы подсвечивал код, используя библиотеку #link("https://github.com/trishume/syntect")[syntect] (Typst использует ту же библиотеку) + #link("https://github.com/cosmichorrordev/two-face")[two-face] (дополнительные синтаксисы)

#note[Обновление от #show-date(datetime(year: 2025, month: 7, day: 26))][
    В библиотеке #link("https://github.com/hongjr03/typst-zebraw")[zebraw] я обнаружил, что можно это #link("https://github.com/hongjr03/typst-zebraw/commit/5a73df5b8999fbb0bf2bbe4c81123fb84f2ec96e#diff-47933f66e50e5610666b617688cd00cd736e80c9f9678f52292b5a64f6f44161R89-R103")[делать нативно]. Typst уже знает, какого цвета должны быть элементы, надо просто экспортировать их в HTML:

    ```typc
    show raw: it => {
        show text: it => context {
            html.span(style: "color:" + text.fill.to-hex(), it)
        }
        show: html.pre
        for line in it.lines {
            line.body
        }
    }
    ```

    И плагин больше не нужен
]

==== Инициализация плагина <plugin-init>

Инициализация нужна, чтобы можно было использовать #link("https://typst.app/docs/reference/foundations/plugin/#definitions-transition")[plugin transition API]. Данные нужно хранить в ```rs static```:

```rs
pub struct SyntectData {
    syntaxes: SyntaxSet,
    themes: ThemeSet,
}
struct Context(Option<SyntectData>);
static DATA: Mutex<Context> = Mutex::new(Context(None));
```

при вызове ```rs init()``` данные сохраняются в ```rs DATA```:

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

а плагин на стороне Typst создается так:

```typ
#let _plugin = plugin("syntect_plugin.wasm")
#let _plugin = plugin.transition(_plugin.init)
```

_Идея, как хранить данные, подсмотрена в #link("https://github.com/lublak/typst-ctxjs-package/blob/15f7e7f5c81856bdeef64d01d7b01424312ec39d/src/lib.rs#L18")[typst-ctxjs-package]_

==== Генерация <syntax-highlighting-generation>

_В коде ниже опущена обработка ошибок_:

- вместо ```rs f().map_err(/* обработка ошибки */)?``` - ```rs f()?```
- вместо ```rs f().ok_or_else(/* обработка none */)?``` - ```rs f().ok()?```

Сигнатура простая:

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

Принимает на вход закодированный через `cbor` набор параметров:

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

Ищет синтаксис по расширению и цветовую схему по названию:

```rs
let syntax = data
    .syntaxes
    .find_syntax_by_extension(&args.extension)
    .ok()?;
let theme = data.themes.themes.get(&args.theme).ok()?;
let mut highlighter = HighlightLines::new(syntax, theme);
```

Собирает получившийся набор цветов и текста:

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

Возвращает закодированный через `cbor` массив элементов с их цветом:

```rs
#[derive(Debug, Serialize)]
struct HighlightOutput {
    color: syntect::highlighting::Color,
    text: String,
}
```

==== Конвертация результата в HTML на стороне Typst <convert-highlighting-to-html>

Для каждого элемента создаем #css("span") с нужным цветом:

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

_Код на самом деле немного сложнее, т.к. он еще обрабатывает генерацию для светлой/темной темы, нужно ли использовать #css("pre") или #css("code"), и ставит тему по умолчанию_

== Шрифты <fonts>

Поначалу я хотел использовать шрифт напрямую с Google Fonts, примерно так:

```css
@import url('https://fonts.googleapis.com/css2?family=Nunito&display=swap');
```

но с таким подходом был заметен момент изменения шрифтов с дефолтного на этот. Решил скачивать их локально, но при этом не хотелось их добавлять в Git. А в Google Fonts нет API для скачивания шрифтов. Нашёл #link("https://gwfh.mranftl.com")[google-webfonts-helper], оттуда можно скачивать

В результате скачивается архив со шрифтами при сборке, распаковывается, и Typst генерирует CSS. В функцию передаются параметры генерации:

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

и для каждого варианта создается ```css @font-face```:

```typc
let res = ""
for (style, weight) in variants {
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
res
```

== Деплой через GitHub Workflows <gh-workflows>

Пишу эту секцию только потому, что нашел классный и простой способ установки приложений в CI без необходимости использовать сторонние actions для установки конкретных приложений, или устанавливать вручную

=== Установка приложений через Nix <gh-workflows-nix>

Нам нужны 2 action-а, которые включаются так:

```yaml
steps:
  - uses: DeterminateSystems/nix-installer-action@main
  - uses: DeterminateSystems/magic-nix-cache-action@main
```

и после этого можно установить любое приложение, которое доступно в #link("https://search.nixos.org/packages")[репозитории пакетов Nix]:

```yaml
- name: install tools
  run: |
    nix profile add "nixpkgs#just" && just -V
    nix profile add "nixpkgs#fd" && fd -V
```

или любое, у которого есть `flake.nix`, например, Typst:

```yaml
- name: install typst
  run: |
    nix profile add "github:typst/typst?rev=b790c6d59ceaf"
    typst -V
```

=== Публикация в GitHub Pages <gh-workflows-pages>

Для этого способа надо в настройках репозитория в "Pages" выбрать Source - GitHub Actions и добавить это:

```yaml
- uses: actions/configure-pages@v5
- uses: actions/upload-pages-artifact@v3
  with:
    path: ./dist/blog
- uses: actions/deploy-pages@v4
```

На этом все! Смотрите #link("https://github.com/istudyatuni/blog")[исходный код] для деталей

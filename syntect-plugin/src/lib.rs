use std::{collections::HashMap, sync::Mutex};

use ciborium::{from_reader, into_writer};
use serde::{Deserialize, Serialize};
use syntect::{
    easy::HighlightLines,
    highlighting::{Color, ThemeSet},
    parsing::{Scope, SyntaxReference, SyntaxSet},
    util::LinesWithEndings,
};
use wasm_minimal_protocol::*;

initiate_protocol!();

// can't clone ThemeSet
// #[derive(Clone)]
pub struct SyntectData {
    syntaxes: SyntaxSet,
    themes: ThemeSet,
}

struct Context(Option<SyntectData>);

static DATA: Mutex<Context> = Mutex::new(Context(None));

#[wasm_func]
pub fn init() -> Vec<u8> {
    DATA.lock().unwrap().0.replace(SyntectData {
        syntaxes: two_face::syntax::extra_newlines(),
        themes: ThemeSet::load_defaults(),
    });
    "ok".to_string().into_bytes()
}

// can't make ref (probably not tried hard enough)
/*pub fn data() -> Result<SyntectData, String> {
    DATA.lock()
        .map_err(|_| "failed to lock arc")?
        .0
        .as_ref()
        .clone()
        .ok_or_else(|| "plugin wasn't initialized".to_string())
}*/

#[wasm_func]
pub fn highlight_html(args: &[u8]) -> Result<Vec<u8>, String> {
    let args: HighlightInput =
        from_reader(args).map_err(|e| format!("failed to parse cbor: {e}"))?;

    let data = DATA.lock().map_err(|_| "failed to lock mutex")?;
    let data = data
        .0
        .as_ref()
        .ok_or_else(|| "plugin wasn't initialized".to_string())?;

    let scope = args
        .scope
        .map(|s| Scope::new(&s))
        .transpose()
        .map_err(|e| format!("failed to parse scope: {e}"))?;

    let syntax = data
        .syntaxes
        .find_syntax_by_extension(&args.extension)
        .or_else(|| scope.and_then(|scope| data.syntaxes.find_syntax_by_scope(scope)))
        .ok_or_else(|| {
            format!(
                "failed to find syntax for {}{scope}, number of syntaxes: {}{}",
                args.extension,
                data.syntaxes.syntaxes().len(),
                if scope.is_some() {
                    format!(
                        ", all syntaxes scopes: {:?}",
                        data.syntaxes
                            .syntaxes()
                            .iter()
                            .map(|s| s.scope.to_string())
                            .collect::<Vec<_>>(),
                    )
                } else {
                    "".to_string()
                },
                scope = scope.map(|s| format!(" (scope: {s})")).unwrap_or_default(),
            )
        })?;

    let mut highlighter = DarkLight {
        dark: get_highlighter(data, syntax, &args.theme.dark)?,
        light: get_highlighter(data, syntax, &args.theme.light)?,
    };
    let mut result = vec![];
    let mut classes: HashMap<String, DarkLight<Color>> = HashMap::new();
    for line in LinesWithEndings::from(&args.text) {
        let ranges_dark = highlighter
            .dark
            .highlight_line(line, &data.syntaxes)
            .map_err(|e| format!("failed to highlight line: {e}"))?;
        let ranges_light = highlighter
            .light
            .highlight_line(line, &data.syntaxes)
            .map_err(|e| format!("failed to highlight line: {e}"))?;

        for (color, s) in ranges_dark.iter().zip(ranges_light.iter()).map(
            |((style_dark, text), (style_light, _))| {
                (
                    DarkLight {
                        dark: style_dark.foreground,
                        light: style_light.foreground,
                    },
                    text,
                )
            },
        ) {
            let class = color2class("h", color.dark);
            classes.insert(
                class.clone(),
                DarkLight {
                    dark: color.dark,
                    light: color.light,
                },
            );
            result.push(HighlightedItem::new(&class, s));
        }
    }

    let result = HighlightOutput {
        items: result,
        css: classes_map_to_css(args.selector, &classes),
    };
    let mut out = vec![];
    into_writer(&result, &mut out).map_err(|e| format!("failed to serialize response: {e}"))?;
    Ok(out)
}

fn get_highlighter<'a>(
    data: &'a SyntectData,
    syntax: &SyntaxReference,
    theme: &str,
) -> Result<HighlightLines<'a>, String> {
    Ok(HighlightLines::new(
        syntax,
        data.themes.themes.get(theme).ok_or_else(|| {
            let themes = data
                .themes
                .themes
                .keys()
                .map(|k| k.as_str())
                .collect::<Vec<&str>>();
            format!("theme {theme} not found, available themes: {themes:?}")
        })?,
    ))
}

#[derive(Debug, Deserialize)]
struct HighlightInput {
    extension: String,
    // fallback when extension not found
    scope: Option<String>,
    text: String,

    #[serde(default = "default_theme")]
    theme: DarkLight<String>,
    selector: DarkLight<String>,
}

#[derive(Debug, Serialize)]
struct HighlightOutput {
    items: Vec<HighlightedItem>,
    css: String,
}

#[derive(Debug, Serialize)]
struct HighlightedItem {
    css_class: String,
    text: String,
}

impl HighlightedItem {
    fn new(css_class: &str, text: &str) -> Self {
        Self {
            css_class: css_class.to_owned(),
            text: text.to_owned(),
        }
    }
}

fn default_theme() -> DarkLight<String> {
    DarkLight {
        dark: "base16-ocean.dark".to_string(),
        light: "base16-ocean.light".to_string(),
    }
}

#[derive(Debug, Deserialize, Serialize)]
struct DarkLight<T> {
    dark: T,
    light: T,
}

fn color2class(prefix: &str, color: Color) -> String {
    format!("{prefix}{}", color2rgb(color))
}

fn color2rgb(color: Color) -> String {
    format!("{:02x}{:02x}{:02x}", color.r, color.g, color.b)
}

fn classes_map_to_css(
    selector: DarkLight<String>,
    classes: &HashMap<String, DarkLight<Color>>,
) -> String {
    let mut res = String::with_capacity(
        ((selector.dark.len() + selector.light.len()) / 2 + 25) * classes.len(),
    );
    for (class, DarkLight { dark, light }) in classes.iter() {
        res += &format!(
            "{} .{class}{{color: #{};}}",
            selector.dark,
            color2rgb(*dark)
        );
        res += &format!(
            "{} .{class}{{color: #{};}}",
            selector.light,
            color2rgb(*light)
        );
    }

    res
}

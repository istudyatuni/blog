use std::sync::Mutex;

use ciborium::{from_reader, into_writer};
use serde::{Deserialize, Serialize};
use syntect::{
    easy::HighlightLines,
    highlighting::{Color, ThemeSet},
    parsing::SyntaxSet,
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

    let data = DATA.lock().map_err(|_| "failed to lock arc")?;
    let data = data
        .0
        .as_ref()
        .ok_or_else(|| "plugin wasn't initialized".to_string())?;

    let syntax = data
        .syntaxes
        .find_syntax_by_extension(&args.extension)
        .ok_or_else(|| {
            format!(
                "failed to find syntax for {}, number of syntaxes: {}",
                args.extension,
                data.syntaxes.syntaxes().len()
            )
        })?;

    let mut highlighter = HighlightLines::new(
        syntax,
        data.themes.themes.get(&args.theme).ok_or_else(|| {
            let themes = data
                .themes
                .themes
                .keys()
                .map(|k| k.as_str())
                .collect::<Vec<&str>>();
            format!(
                "theme {} not found, available themes: {themes:?}",
                args.theme
            )
        })?,
    );
    let mut result = vec![];
    for line in LinesWithEndings::from(&args.text) {
        let ranges = highlighter
            .highlight_line(line, &data.syntaxes)
            .map_err(|e| format!("failed to highlight line: {e}"))?;
        for (color, s) in ranges {
            result.push(HighlightOutput::new(color.foreground, s));
        }
    }

    let mut out = vec![];
    into_writer(&result, &mut out).map_err(|e| format!("failed to serialize response: {e}"))?;
    Ok(out)
}

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

#[derive(Debug, Serialize)]
struct HighlightOutput {
    color: Color,
    text: String,
}

impl HighlightOutput {
    fn new(color: Color, text: &str) -> Self {
        Self {
            color,
            text: text.to_owned(),
        }
    }
}

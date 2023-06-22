///
/// ( Dev Environment (
///   Shell (
///     Tool,
///     Lsp,
///     Editor
///
///   )
/// )
struct Shell {
    name: String,
    version: String,
    hash: String,
    completions_dir: Vec<String>,
    function_dir: Vec<String>,
    tools_to_load: Vec<String>,
}

struct Tool {}

struct Lsp {}

struct Editor {}

fn main() {
    println!("Hello, world!");
}

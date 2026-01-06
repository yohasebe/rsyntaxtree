<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree.png?raw=true' style='width: 256px;' />

**RSyntaxTree** is a graphical syntax tree generator for linguistic research.

<p>
  <a href="https://yohasebe.com/rsyntaxtree"><strong>Web App</strong></a> ·
  <a href="https://yohasebe.github.io/rsyntaxtree/examples"><strong>Example Gallery</strong></a> ·
  <a href="https://yohasebe.github.io/rsyntaxtree/documentation"><strong>Documentation</strong></a>
</p>

## Features

RSyntaxTree provides a rich set of features for creating publication-quality syntax trees:

### Basic Syntax

Use bracket notation to define tree structures:

```text
[S [NP the cat] [VP [V sleeps]]]
```

### Text Decoration

Apply various text styles to node labels:

- **Bold**: `**text**`
- *Italic*: `*text*`
- Subscript: `_text_`
- Superscript: `__text__`
- Overline/Underline/Strikethrough: `=text=`, `-text-`, `~text~`

### Per-Node Coloring

Apply custom colors to individual nodes using `@color:` syntax:

```text
[S [@red:NP the cat] [@blue:VP sleeps]]
```

Supports named colors (`red`, `blue`, `green`, etc.) and hex colors (`@#FF5733:`).

### Enclosures and Triangles

- **Brackets**: `[#NP text]` → draws brackets around the node
- **Rectangle**: `[##NP text]` → draws a rectangle around the node
- **Triangle**: `[^NP the quick fox]` → draws a triangle connector

Combine with colors: `[#@red:NP text]`, `[^@blue:VP phrase]`

### Path Drawing

Connect nodes with lines or arrows:

```text
[S [NP+1 text] [VP [V+>1 connects]]]
```

### Multiple Output Formats

Generate trees in PNG, SVG, PDF, JPG, or GIF format.

## Web Interface

<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree-web-screenshot.png?raw=true' width='700px'/>

A working web interface is available at <https://yohasebe.com/rsyntaxtree>.

You can also run RSyntaxTree's web interface on your local machine using Docker Desktop. See [RSyntaxTree Web UI](https://github.com/yohasebe/rsyntaxtree_web).

## Examples

See [RSyntaxTree Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples) for examples covering:

- Generative Grammar
- Combinatory Categorial Grammar
- Head-Driven Phrase Structure Grammar
- Cognitive Grammar
- Construction Grammar
- Pragmatics
- Phonology
- and more

**Input text**

```text
[S
  [NP |R|<>SyntaxTree]
  [VP
    [V generates]
    [NP
      [Adj #\+multilingual\
            \+beautiful]
      [NP syntax\
          trees]
    ]
  ]
]
```

**Output (PNG or SVG)**

<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/sample.png?raw=true' width='600' />

## Installation

```bash
gem install rsyntaxtree
```

### macOS Installation Notice

**Important for macOS users:** If you encounter build errors for native extensions (`gobject-introspection`, `cairo-gobject`, `gio2`), run the following commands before installing RSyntaxTree:

```bash
gem install gobject-introspection -- --with-ldflags="-Wl,-undefined,dynamic_lookup"
gem install cairo-gobject -- --with-ldflags="-Wl,-undefined,dynamic_lookup"
gem install gio2 -- --with-ldflags="-Wl,-undefined,dynamic_lookup"
```

Then install RSyntaxTree:

```bash
gem install rsyntaxtree
```

Alternatively, use the [Docker image](https://hub.docker.com/r/yohasebe/rsyntaxtree) or the [web interface](https://yohasebe.com/rsyntaxtree).

## Usage

### Command Line

```text
Usage:
       1) rsyntaxtree [options] "[S [NP text] [VP here]]"
       2) rsyntaxtree [options] "(S (NP text) (VP here))"  # Penn Treebank format
       3) rsyntaxtree [options] "/path/to/text/file"
       4) echo "[S [NP text] [VP here]]" | rsyntaxtree [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --outdir` | Output directory | `./` |
| `-f, --format` | Output format: png, gif, jpg, pdf, svg | `png` |
| `-l, --leafstyle` | Leaf style: auto, triangle, bar, nothing | `auto` |
| `-n, --fontstyle` | Font style: sans, serif, cjk, mono | `sans` |
| `-s, --fontsize` | Font size: 8-26 | `16` |
| `-c, --color` | Color mode: modern, traditional, off | `modern` |
| `-y, --symmetrize` | Symmetrical tree: on, off | `off` |
| `-p, --polyline` | Polyline connectors: on, off | `off` |

Run `rsyntaxtree -h` for the full list of options.

### Input Formats

- **Bracket notation**: `[S [NP text] [VP here]]`
- **Penn Treebank format**: `(S (NP text) (VP here))` - automatically converted
- **Standard input**: `echo "[S [NP text]]" | rsyntaxtree`

### Configuration File

RSyntaxTree supports configuration files (`.rsyntaxtreerc`) in YAML format. Place the file in your home directory or current working directory.

```yaml
# ~/.rsyntaxtreerc
format: svg
color: modern
fontsize: 18
```

CLI options override config file settings.

## Documentation

For detailed documentation on syntax and markup:

- [Documentation in English](https://yohasebe.github.io/rsyntaxtree/documentation)
- [日本語ドキュメント](https://yohasebe.github.io/rsyntaxtree/documentation_ja)
- [Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples)

## References

Please use the following BibTeX entry when citing RSyntaxTree:

```bibtex
@misc{rsyntaxtree,
  author = {Yoichiro Hasebe},
  title = {RSyntaxTree: A graphical syntax tree image generator},
  url = {https://yohasebe.com/rsyntaxtree},
  year = {2026}
}
```

## Author

Yoichiro Hasebe (<yohasebe@gmail.com>)

## License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).

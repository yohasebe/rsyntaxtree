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

### Region Shade

Shade the whole subtree a node governs with a semi-transparent plane — useful for c-command/binding domains and cognitive grammar dominions. Prefix the node with `%`; the color reuses the `@color:` syntax (bare `%` is gray):

```text
[TP [DP everyone] [%@lightblue:T' [T will] [VP praise it]]]
```

### Path Drawing

Connect nodes with lines or arrows:

```text
[S [NP+1 text] [VP [V+>1 connects]]]
```

### Multiple Output Formats

Generate trees in PNG, SVG, PDF, JPG, GIF, or LSIF (JSON) format.

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

## System Fonts

RSyntaxTree resolves fonts by family name through fontconfig (measurement via Pango, rendering via librsvg), so the fonts must be installed on the machine that generates the images. As of v1.8.0 the gem no longer bundles font files; they were not used at runtime.

- Debian/Ubuntu: `apt install fonts-noto-core fonts-noto-cjk`
- Alpine: `apk add font-noto font-noto-cjk font-noto-cjk-extra` (the `-extra` package carries Noto Serif CJK)
- macOS: install [Noto Sans/Serif](https://fonts.google.com/noto), plus Noto Sans/Serif JP for Japanese and Noto Sans CJK for Hangul and simplified Han

The family chains name the Latin and CJK families, and since v1.8.1 also Arabic (`Noto Sans Arabic`, and `Noto Naskh Arabic` for the serif style), Hebrew, Devanagari, Thai and Khmer. A script whose family is missing does not turn into tofu — fontconfig falls back to anything else that covers the codepoints, which is where machines start to disagree. On Alpine, Arabic was picked up that way by Noto Sans Math, which has the glyphs but no joining rules, so the letters came out unjoined. Install the packages for the scripts you use:

- Debian/Ubuntu: `fonts-noto-core` covers them; on minimal images add `fonts-noto` for the full set
- Alpine: `apk add font-noto-arabic font-noto-naskh-arabic font-noto-hebrew font-noto-devanagari font-noto-thai font-noto-khmer`

Emoji need the **monochrome** [Noto Emoji](https://fonts.google.com/noto/specimen/Noto+Emoji). Colour emoji fonts (`NotoColorEmoji`, from Alpine's `font-noto-emoji` or Debian's `fonts-noto-color-emoji`) are measured by Pango but not drawn by librsvg, so emoji fall back to whatever outline font covers them.

Mathematical alphanumerics (U+1D400–, such as the italic *v* of *v*P) are not named in the chains yet, so they still resolve differently from one machine to the next.

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
| `-f, --format` | Output format: png, gif, jpg, pdf, svg, lsif | `png` |
| `-l, --leafstyle` | Leaf style: auto, triangle, bar, nothing | `auto` |
| `-n, --fontstyle` | Font style: sans, serif, cjk, mono | `sans` |
| `-s, --fontsize` | Font size: 8-26 | `16` |
| `-c, --color` | Color mode: modern, traditional, off | `modern` |
| `-p, --polyline` | Polyline connectors: on, off | `off` |
| `-d, --direction` | Tree layout direction: ttb, ltr | `ttb` |
| `--tidy` | Layout scale: off, symmetric, low, medium, high | `off` |
| `--hspacing` | Horizontal spacing factor, all layout modes (0.5-3.0) | `1.0` |
| `-m, --mirror` | Flip the tree horizontally (RTL convention): on, off | `off` |

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

## How to Cite

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21916150.svg?v=1)](https://doi.org/10.5281/zenodo.21916150)

If you use RSyntaxTree in your research, please cite it. You can use the "Cite this repository" button on GitHub (powered by [CITATION.cff](CITATION.cff)), or the following BibTeX entry (adjust `version` to the one you used):

```bibtex
@software{hasebe_rsyntaxtree,
  author  = {Hasebe, Yoichiro},
  title   = {RSyntaxTree: A graphical syntax tree image generator},
  url     = {https://yohasebe.com/rsyntaxtree},
  doi     = {10.5281/zenodo.21916150},
  version = {1.8.0},
  year    = {2026}
}
```

## Related Blog Posts

- [RSyntaxTree tag on yohasebe.com](https://yohasebe.com/tags/rsyntaxtree/)

## Author

Yoichiro Hasebe (<yohasebe@gmail.com>)

## License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).

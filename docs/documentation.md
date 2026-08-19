---
title: RSyntaxTree
layout: default
---

# Documentation
{:.no_toc}

[English](https://yohasebe.github.io/rsyntaxtree/documentation) | 
[日本語](https://yohasebe.github.io/rsyntaxtree/documentation_ja)

### Table of Contents
{:.no_toc}

1. toc
{:toc}

### Basic Usage

Type your text in the editor area using labeled bracket notation and click the Draw PNG or Draw SVG button. 

Every branch or leaf of the syntax tree must belong to a node. To create a node, place the label text right next to the start bracket. Any number of branches may follow, separated by a whitespace. (Node labels containing whitespaces can be created using the `<>` symbol. For example, `Modal<>Aux` will be rendered as `Modal Aux`).

There are three different types of `connector` drawn between a terminal node and its leaves (`auto`, `bar` and `none`). `auto` draws a triangle for leaves containing one or more whitespaces (= phrases).  If the leaf does not contain any spaces (= single word), a straight bar is drawn instead (unless the leaf contains a `^` symbol at the beginning, which specifies the leaf to be a phrase). The connectors can be made transparent using the `Hide default connectors` option.

The newline character `\n` can be used within the text of both node lables and leaves.

RSyntaxTree can generate `PNG` and `SVG`, SVG can be used with third party vector graphics software such as Adobe Illustrator, Microsoft Visio, [BOXY SVG](https://boxy-svg.com/), etc. It is very useful if you want to modify the output image.

The command line tool also outputs `PDF`, `JPG`, and `GIF`. **JPG and GIF are deprecated and will be removed in 2.0** — JPEG blurs line art and GIF has no use case here; use `PNG` instead.

The options `Font style`, `Font size`, `Connector height`, and `Color` need no explanation. By changing the values of these options, you can change the appearance of the resulting image.

`Color` offers `Modern` and `Traditional`, which colour node and leaf labels, `None`, which draws everything in black, and `Gray lines`, which keeps the labels black but draws the connectors and movement paths in grey. The last is for diagrams whose links outnumber their labels — an ontology, a network of constructions — where a page of black lines buries the text.

### Tree Direction

The `Direction` option controls the orientation of the tree layout:

- **Top to Bottom** (`ttb`): The default. Root node at the top, leaves at the bottom.
- **Left to Right** (`ltr`): Root node at the left, leaves expand to the right. Useful for classification trees, taxonomies, and other hierarchical structures where horizontal layout is preferred.

In left-to-right mode, connectors, triangles, movement paths, and line-type connections are all adapted to the horizontal orientation. The `Connector Height` option controls the horizontal depth between tree levels in LTR mode.

### Tidy Layout

The `Tidy layout` option (`tidy`, CLI `--tidy`) selects the layout mode, on one scale from the most spacious to the most dense:

- **Symmetric** (`symmetric`): radical symmetrization — every subtree is centered in a uniform slot, giving a wide, fully balanced figure. (Formerly the separate `Radical symmetrization` option, which remains as a legacy alias.)
- **Off** (`off`): the traditional layout.
- **Low** (`low`): adjacent subtrees are pulled toward each other wherever their outlines leave unused space, typically reducing overall width by about 30%. Every leaf keeps its strict left-to-right position, so the terminal string still reads in surface (word) order across the whole figure — choose this for figures whose point is word order, such as cross-linguistic comparisons.
- **Medium** (`medium`): compresses further by letting a shallow subtree tuck into the empty space above the deep tail of its neighbor (e.g. a specifier NP moving toward the head) — but never so far that two leaves swap their left-right order. Leaf boxes may overlap across rows while the words still read in surface order.
- **High** (`high`): free tucking, and the only mode that lets branch angles differ sharply between levels if that buys width. Leaf order is guaranteed only among leaves on the same row — choose this for figures whose point is constituent structure, such as X-bar trees or morphological derivations.

The two ends of the scale are for figures that ask for them. `symmetric` gives a balanced diagram wider than any linguistic tree needs, and `high` gives the densest one at the cost of even branch angles; deeply lopsided trees gain the most from it, and on a well-balanced tree it often lands close to `medium`. `off`, `low` and `medium` cover ordinary work.

Connector heights adjust automatically: tidy mode spends a small height budget (about 5% of the tree's height) on the levels whose branches spread widest, evening out branch angles without making the figure noticeably taller. Connector height needs no manual adjustment in tidy mode.

Tidy layout never produces overlapping labels: if a compaction step would cause a collision, it is rolled back to the last safe arrangement. It works in both top-to-bottom and left-to-right layouts and can be combined with `Mirror`. Most figures in the [example gallery](https://yohasebe.github.io/rsyntaxtree/examples) are drawn with `low`. The X-bar and morphology examples use `high`, and one (a Japanese causative-passive tree) uses `medium`.

`Horizontal spacing` (`hspacing`, default 1.0, range 0.5–3.0) scales every horizontal gap in the figure the way `Connector height` scales the vertical rhythm. It applies in every layout mode, tidy or not. (`tidy_spacing` remains as a legacy alias.)

### Mirrored Layout for RTL Scripts

Syntax trees for right-to-left scripts such as Arabic and Hebrew are conventionally drawn expanding from right to left, with the first word of the sentence at the right edge. The `Mirror` option (`mirror: on`, CLI `--mirror`) reflects the entire finished layout horizontally to follow this convention: the structure is unchanged, but the leaf order is reversed so the sentence reads in its natural direction.

`Mirror` composes with `Direction`: `ttb` + mirror gives the standard RTL tree, and `ltr` + mirror places the root at the right with leaves expanding leftward. Every drawn element follows the mirrored positions automatically. See the Arabic example in the [Multilingual gallery](https://yohasebe.github.io/rsyntaxtree/examples) for a demonstration.

### Fonts Used to Generate PNG

The web interface offers three font styles:

- `Noto Sans` (`sans`): latin and other basic Unicode characters in a sans serif face.
- `Noto Serif` (`serif`): the same range in a serif face.
- `Noto Sans Mono` (`mono`): the same range in a mono-spaced face.

All three fall back to Noto CJK for Han, Hangul and kana, so any of them renders CJK text. A fourth style, `cjk`, puts Noto Sans CJK first instead; it is available from the command line and the library (`-n cjk`) but not from the web interface.

### Install Fonts for SVG

SVG images are dependent on the fonts installed locally on your computer. In order for the images to display as intended, the following fonts should be installed beforehand (click on the links). If these fonts are not installed, other available fonts will be used, resulting in a somewhat unbalanced display of the text.

- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans): for latin and other basic Unicode characters in sans serif
- [Noto Sans JP](https://fonts.google.com/noto/specimen/Noto+Sans+JP): for Japanese characters in sans serif
- [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif): for latin and other basic Unicode characters in serif
- [Noto Serif JP](https://fonts.google.com/noto/specimen/Noto+Serif+JP): for Japanese characters in serif
- [Noto Sans CJK / Noto Serif CJK](https://github.com/notofonts/noto-cjk): for the full CJK range, including Hangul and simplified Han (the JP families above cover Japanese only)
- [Noto Sans Mono](https://fonts.google.com/noto/specimen/Noto+Sans+Mono): for latin and other basic Unicode characters in sans serif mono (semi-condensed)
- [Noto Emoji](https://fonts.google.com/noto/specimen/Noto+Emoji): for emoji characters (the monochrome build; colour emoji fonts are not rendered by the PNG/PDF pipeline)

Since 1.8.1, the scripts the gallery covers are named explicitly rather than left to the system's generic fallback: `Noto Sans Arabic` / `Noto Naskh Arabic`, `Noto Sans Hebrew` / `Noto Serif Hebrew`, and the Devanagari, Thai and Khmer faces of Noto Sans and Noto Serif. Where those fonts are installed, the same input renders the same way from one machine to the next. Mathematical alphanumerics (U+1D400–, such as the italic *v* of *v*P) are not named yet and still depend on what the system offers.

### Using a Font of Your Own

The family chains above take precedence over whatever your system would pick by itself, which also means an Arabic or Devanagari font you prefer will lose to Noto. You can override any entry with a fontconfig alias — no change to RSyntaxTree is needed. For example, to render Arabic with Amiri, put this in `~/.config/fontconfig/fonts.conf` and run `fc-cache -f`:

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias binding="strong">
    <family>Noto Sans Arabic</family>
    <prefer><family>Amiri</family></prefer>
  </alias>
</fontconfig>
```

Because measurement and rendering both resolve through fontconfig, the substituted font is measured as well as drawn, so the layout stays correct.

This applies to systems where Pango resolves fonts through fontconfig, which means Linux and the Docker image. On macOS, Pango goes through CoreText instead and ignores fontconfig, so an alias has no effect there; name the font you want in the input's font style instead. CoreText also answers every emoji codepoint with Apple Color Emoji, whose colour glyphs librsvg does not draw, so trees containing emoji are best generated on Linux or in the Docker image.


### Font Styles, Text Decoration, and Sub/Superscripts

You can apply font styles (italic/bold/bold-italic), text decoration (overline/underline/line-through), subscript/superscript font rendering, and more. These markups can be nested within each other.

#### Font Styles

|Style      |Symbol      |Sample Input       |Output           |
|-----------|------------|-------------------|-----------------|
|Italic     |`*TEXT*`    |`*italic*`         |*italic*         |
|Bold       |`**TEXT**`  |`**bold**`         |**bold**         |
|Italic+bold|`***TEXT***`|`***italic bold***`|***italic bold***|

#### Text Decoration

|Decoration  |Symbol  |Sample Input   |Output                                                       |
|------------|--------|---------------|-------------------------------------------------------------|
|Overline    |`=TEXT=`|`=overline=`   |<span style='text-decoration:overline'>overline</span>       |
|Underline   |`-TEXT-`|`-underline-`  |<span style='text-decoration:underline'>underline</span>     |
|Line-through|`~TEXT~`|`~linethrough~`|<span style='text-decoration:line-through'>linethrough</span>|

Note: Currently, overline is displayed in SVG, but not in PNG.

#### Subscript and Superscript

|Sample Input           |Output                      |
|-----------------------|----------------------------|
|`normal_subscript_`    |normal<sub>subscript</sub>  |
|`normal__superscript__`|normal<sup>superscript</sup>|

#### Small Capitals

There is no small-caps markup. CSS `font-variant` is honoured by the SVG renderer but ignored by the measurement engine, so a label would be measured at one width and drawn at another — off-centre by up to a third of its width. Attribute names in an attribute-value matrix are conventionally set in small caps; plain capitals read the same way and are what the gallery's HPSG examples use. Where the distinction matters, `___` gives a passable imitation: `H___EAD___` draws a full-size H followed by a smaller EAD.

#### Box, Circle, Bar, and Arrow

{% include box_and_circle_table.html %}

#### Whitespace inside Label

|Sample Input|Output  |
|------------|--------|
|`X<>Y`      |X&nbsp;Y|

A node whose label is *only* `<>` renders as an invisible pass-through joint: the connector runs continuously through it without a break. Chaining such nodes (e.g. `[the [<> ði]]`) pushes a shallow leaf down so it aligns with deeper leaves — useful when every terminal should sit on the same row.

#### Columns

`\t` cuts a line into cells. Every line of the label is cut at the same points, and each column is drawn at the width of its widest cell, so the parts line up down the label instead of starting wherever the text before them happened to end. This is what an attribute-value matrix asks for — the attributes in one column, their values in the next:

```text
[#HEAD\tnoun\
  SPR\t〈<>〉\
  COMPS\t〈<>NP<>〉
  Kim
]
```

A label with more than two columns works the same way; each is as wide as it needs to be. See the [Head-Driven Phrase Structure Grammar example](https://yohasebe.github.io/rsyntaxtree/examples#example-013) in the gallery.

#### Nested matrices

The value of an attribute can be another matrix, written between `#(` and `#)`. It draws its own brackets and lays out its own columns, and the rows that follow it clear its full height:

```text
[#*word*\
  PHON\t〈<>*Kim*<>〉\
  SYNSEM\t#(LOCAL\t#(CAT\t#(HEAD\t#(*noun*\
    CASE\t*nom*#)\
    SPR\t〈<>〉#)#)#)
]
```

Matrices nest to any depth, which is what a feature path such as SYNSEM | LOCAL | CATEGORY | HEAD needs. Bare brackets would be read as tree structure and bare parentheses appear in labels too often to be claimed, hence `#(` and `#)`.

#### Hyphens

A hyphen opens and closes an underline, so a literal one is written `\-`. Feature names in HPSG and its relatives are full of hyphens — HEAD-DTR, RELIED-ON — and escaping each one is a poor trade for a rule that work never uses. `Hyphen` (`hyphen`, CLI `--hyphen`) swaps the two readings: with `literal`, a bare hyphen is a hyphen and `\-underlined\-` underlines instead. Two hyphens are structure rather than markup and are left alone either way: a line of nothing but hyphens is still the horizontal rule, and the one in a path suffix (`+-1`) still marks that path dashed.

#### Newline

|Sample Input                   |Output              |
|-------------------------------|--------------------|
|`str1\`<br />`str2`            |str1<br />str2      |
|`str1\`<br />`   \`<br />`str2`|str1<br /><br />str2|
|`str1\ str2`                   |str1<br />str2      |
|`str1\ \ str2`                 |str1<br /><br />str2|
|`str1\nstr2`                   |str1<br />str2      |
|`str1\n\nstr2`                 |str1<br /><br />str2|

#### Horizontal Line

|Sample Input                   |Output                |
|-------------------------------|----------------------|
|`str1\`<br />`---\`<br />`str2`|str1<br />——<br />str2|
|`str1\ ---\ str2`              |str1<br />——<br />str2|
|`str1\n---\nstr2`              |str1<br />——<br />str2|

Here, `---` represents `-` repeated three times or more consecutively.

### Triangle, Square Brackets, Rectangle

In `auto` mode, the triangle connector shape is applied when the terminal node contains words separated by whitespace. In `bar` and `none` modes, triangles are drawn for the nodes with `^` at the beginning of the leaf text, lie `[NP ^syntax-trees]`.

If a `#` character is placed at the beginning of a label or leaf text (right after `^` if there is one), the text is enclosed in a pair of square brackets (e.g. `[#NP text]`, `[NP #text]`, `[NP ^#text]`).

If `##` is placed at the beginning of the leaf text, a rectangle is drawn instead of brackets.

If `###` is placed at the beginning of the leaf text, a rectangle with thicker lines is drawn.

### Per-Node Styling (Color)

You can specify a custom color for individual nodes using the `@color:` prefix. Both named colors and hex color codes are supported.

|Sample Input|Description|
|------------|-----------|
|`@red:NP`|Named color (red)|
|`@blue:VP`|Named color (blue)|
|`@#FF5500:NP`|Hex color code|
|`@#0A0:VP`|Short hex color code|

**Markup Order**: When combining with other prefixes, use this order: `^` (triangle) → `#` (enclosure) → `%` (region shade) → `@color:` (color)

|Sample Input|Description|
|------------|-----------|
|`^@blue:NP`|Triangle connector + blue color|
|`#@red:NP`|Square brackets + red color|
|`^#@green:NP`|Triangle + brackets + green color|

### Region Shade

While `#`, `##`, and `###` enclose a single node label, a region shade paints a
semi-transparent plane behind the **whole subtree** that a node governs. This is
useful for marking spans such as c-command domains, binding domains, or the
dominion of a reference point in cognitive grammar.

Put a `%` at the beginning of a node label (after `^`/`#` if present). The plane
covers the bounding box of that node together with all of its descendants and is
drawn behind the tree lines and labels. The shade color reuses the same
`@color:` syntax; `%` on its own uses a light gray.

|Sample Input|Description|
|------------|-----------|
|`%VP`|Region shade in the default light gray|
|`%@yellow:VP`|Region shade in yellow (named color)|
|`%@#ffcc00:VP`|Region shade with a hex color|
|`%@yellow:@blue:VP`|Yellow shade plane **and** blue node label (the two colors are independent)|

Each plane is drawn with a border in a darker shade of its own fill color, so
the region stays clearly bounded even on a white background. An explicit shade
color is always honored (just like the `@color:` node-text color), so for a
black-and-white figure use bare `%` (gray) rather than a colored shade.

Overlapping or nested regions blend naturally because the planes are
semi-transparent. Region shade works in both top-to-bottom and left-to-right
(`-d ltr`) layouts, and applies to all raster/vector outputs (SVG, PNG, PDF,
JPG, GIF).

### Escape Special Characters

The backslash character `\` must be used to print certain characters used in the markup. If you do not have the `\` key on your keyboard, you can also use the yen/yuan character `¥` to escape.

{% include escape_char_table.html %}

**Note:** A newline character `↩️` is treated just as a whitespace. Thus 1) `\n`, 2) `\↩️`, and 3) `\` followed by a whitespace character are all rendered as a newline `↩️` in the resulting image. Note also that a `↩️` or a whitespace repeated more than once is reduced to a single whitespace.

**Note:** A straight ASCII apostrophe (`'`) in a label is automatically rendered as a typographic (curly) apostrophe `’`, which looks smarter in serif fonts and suits X-bar primes such as `T'`. This also applies to apostrophes in ordinary words (e.g. *John's*).

### Draw Paths between Nodes (experimental)

You can draw any number of paths of three different types:

- Non-directional (rendered as dashed line `- - -`)
- Directional (rendered as solid line `----▶`)
- Bidirectional (rendered as solid line `◀----▶`)

Each path is distinguished by a unique ID number. The ID is specified by putting a plus sign and a number (e.g. `+7`) at the end of the node text. If a greater-than `>` or less-than `<` symbol is placed between the plus sign and the number (e.g. `+>7` or `+<7`), an arrowhead will appear at the end of the path. Note that it makes no difference whether `+>` or `+<` is used. The arrow is always directed to the element with one of these ID symbols.

A node can have any number of IDs. The same ID must appear in the text of the *two* nodes between which the path is rendered. The same ID number cannot appear in more than two places.

### Draw Extra Connectors between Nodes (experimental)

You can also add extra connector between nodes in the same fasion as you draw paths between nodes. Extra connectors are drawn as straigt lines (not as `polyline`s). You may enable the `Hide default connectors` option when drawing extra connectors.

- Non-directional (rendered as solid line `-----`)
- Directional (rendered as solid line `--▶--`)
- Bidirectional (rendered as solid line `-◀-▶-`)

Each additional connectors is distinguished by an ID number. The ID is specified by putting a a number after a sequence of a plus and a minus symbols (e.g. `+-8`) at the end of the node text. If a greater-than `>` or less-than `<` symbol is placed between the minus sign and the number (e.g. `+->8`), an arrowhead will appear at the end of the connector. Note that it makes no difference whether `+->` or `+-<` is used. The arrow is always directed to the element with one of these ID symbols.

A node can have any number of IDs. The same ID must appear in the text of the *two* nodes between which the additional connector is rendered. The same ID number cannot appear in more than two places.

### Command Line Interface Features

The following features are available only in the command-line interface.

#### Penn Treebank Format

RSyntaxTree automatically detects and converts Penn Treebank format to bracket notation:

```
# Penn Treebank format
(S (NP the dog) (VP runs))

# Equivalent bracket notation
[S [NP the dog] [VP runs]]
```

**Escaping special characters in Penn Treebank format:**

| Input | Displayed as |
|-------|--------------|
| `\(` `\)` | Parentheses `()` as literal text |
| `\[` `\]` | Square brackets `[]` as literal text |

Example:
```
(S (NP hello\(world\)) (VP test))
→ [S [NP hello(world)] [VP test]]
```

#### Standard Input Support

You can pipe tree data via standard input:

```bash
echo "[S [NP hello] [VP world]]" | rsyntaxtree -f svg -o ./
cat tree.txt | rsyntaxtree -f png -o ./
```

#### Configuration File

Create a `.rsyntaxtreerc` file in your home directory or current directory to set default options:

```yaml
# ~/.rsyntaxtreerc
format: svg
color: modern
fontsize: 18
leafstyle: auto
symmetrize: off
```

CLI arguments override configuration file settings. Unknown options in the config file will generate warnings, and invalid values will cause errors with helpful messages.

#### TikZ Output

RSyntaxTree can generate TikZ/forest code for LaTeX documents using the `-f tikz` option. The output can be used directly in LaTeX with the `forest` package.

**Limitations:** The TikZ output focuses on tree structure and does not support the following visual features:

| Feature | TikZ Support |
|---------|--------------|
| Per-node coloring (`@color:`) | Not supported |
| Enclosures (`#`, `##`) | Not supported |
| Triangle connectors (`^`) | Not supported |
| Text decoration (bold, italic) | Not supported |
| Subscript/superscript (`_x_`, `__x__`) | Not supported |
| Path drawing (`+1`, `+>1`) | Not supported |
| Region shade (`%`) | Supported (via `forest` `fit to=tree`) |
| Column alignment (`\t`) | Cells run together on one line |
| Nested matrix (`#(` … `#)`) | Contents kept, brackets not drawn |
| Grey line scheme (`color: gray`) | Not supported |

Users familiar with LaTeX can manually add these features to the generated TikZ code using standard LaTeX commands (e.g., `\textcolor{red}{NP}`, `\textbf{...}`).

**Note on region shade:** The generated `forest` code draws each region plane on the TikZ background layer. When you embed non-standalone output in your own document, load the required libraries with `\usetikzlibrary{backgrounds,fit}` (the standalone output adds this automatically). Region colors (named or hex) are emitted as explicit RGB values, so SVG/CSS color names that xcolor does not define (e.g. `lightblue`) still compile.

<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lightbox2@2.11.3/src/js/lightbox.js"></script>

---

<script>
  function copyToClipBoard(id){
    var copyText =  document.getElementById(id).innerText;
    document.addEventListener('copy', function(e) {
        e.clipboardData.setData('text/plain', copyText);
        e.preventDefault();
      }, true);
    document.execCommand('copy');
    alert('copied');
  }
</script>

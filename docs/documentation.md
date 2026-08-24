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

The `Connector shape` option (`leafstyle`, CLI `--leafstyle`) chooses what is drawn between a terminal node and its leaves; the three settings are described under [Connectors](#connectors). Whichever is chosen, the connectors can be made transparent with the `Hide connectors` option.

The newline character `\n` can be used within the text of both node labels and leaves (a backslash followed by a space or a line break works too).

RSyntaxTree can generate `PNG` and `SVG`, SVG can be used with third party vector graphics software such as Adobe Illustrator, Microsoft Visio, [BOXY SVG](https://boxy-svg.com/), etc. It is very useful if you want to modify the output image.


The options `Font`, `Size`, `V spacing`, and `Color` need no explanation. By changing the values of these options, you can change the appearance of the resulting image.

`Color` offers `Modern` and `Traditional`, which colour node and leaf labels, `None`, which draws everything in black, and `Gray lines`, which keeps the labels black but draws the connectors and movement paths in grey.

`Line width` sets the thickness of every line in the figure — connectors, brackets, enclosures — as a ratio of the font size. `1` is 5% of it (the weight of an ordinary text rule), each 0.5 step adds another 2.5%, and the scale runs from `0.5` (a hairline) to `3.0` (15%, the heaviest). Because the lines follow the font size, text and lines keep the same balance at any font size.

### Tree Direction

The `Direction` option controls the orientation of the tree layout:

- **Top to Bottom** (`ttb`): The default. Root node at the top, leaves at the bottom.
- **Left to Right** (`ltr`): Root node at the left, leaves expand to the right. Useful for classification trees, taxonomies, and other hierarchical structures where horizontal layout is preferred.
- **Bottom to Top** (`btt`): Leaves at the top, root at the bottom. This is how a derivation is written, with the words first and the result last: see [Derivations](#derivations).

In left-to-right mode, connectors, triangles, movement paths, and line-type connections are all adapted to the horizontal orientation. The `V spacing` option controls the horizontal depth between tree levels in LTR mode.

### Tidy Layout

The `Tidy layout` option (`tidy`, CLI `--tidy`) selects the layout mode, on one scale from the most spacious to the most dense:

- **Symmetric** (`symmetric`): radical symmetrization — every subtree is centered in a uniform slot, giving a wide, fully balanced figure. Linguistic trees do not normally call for it.
- **Off** (`off`): the plainest layout. If it looks unbalanced, try one of the tidy modes.
- **Low** (`low`): adjacent subtrees are pulled toward each other wherever their outlines leave unused space. Every leaf keeps its strict left-to-right position, so word order is preserved across the whole figure.
- **Medium** (`medium`): compresses further by letting a shallow subtree tuck into the empty space above the deep tail of its neighbor (e.g. a specifier NP moving toward the head). Two leaves never swap their left-right order.
- **High** (`high`): the densest mode, tucking without limit and allowing branch angles to differ sharply between levels if that buys width. Leaf order is guaranteed only among leaves on the same row, so the linear order of the sentence may be broken locally along the horizontal axis of the figure.

`high` pays off on deeply lopsided trees; on a well-balanced one it often lands close to `medium`. `off`, `low` and `medium` cover ordinary work.

Connector heights adjust automatically in tidy mode. `H spacing` (`hspacing`, default 1.0, range 0.5–3.0) and `V spacing` (`vheight`) scale the horizontal and vertical gaps, and both apply in every layout mode, tidy or not.

### Mirrored Layout for RTL Scripts

Trees for right-to-left scripts such as Arabic and Hebrew can be drawn expanding from right to left. The `Mirror (RTL)` option (`mirror: on`, CLI `--mirror`) reflects the entire finished layout horizontally: the structure is unchanged, but the leaf order is reversed so the sentence reads in its natural direction.

`Mirror` composes with `Direction`. See the Arabic example in the [Multilingual gallery](https://yohasebe.github.io/rsyntaxtree/examples) for a demonstration.

### Fonts Used to Generate PNG

The web interface offers three font styles:

- `Noto Sans` (`sans`): latin and other basic Unicode characters in a sans serif face.
- `Noto Serif` (`serif`): the same range in a serif face.
- `Noto Sans Mono` (`mono`): the same range in a mono-spaced face.

All three fall back to Noto CJK for Han, Hangul and kana, so any of them renders CJK text.

### Install Fonts for SVG

SVG images are dependent on the fonts installed locally on your computer. In order for the images to display as intended, the following fonts should be installed beforehand (click on the links). If these fonts are not installed, other available fonts will be used, resulting in a somewhat unbalanced display of the text.

- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans): for latin and other basic Unicode characters in sans serif
- [Noto Sans JP](https://fonts.google.com/noto/specimen/Noto+Sans+JP): for Japanese characters in sans serif
- [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif): for latin and other basic Unicode characters in serif
- [Noto Serif JP](https://fonts.google.com/noto/specimen/Noto+Serif+JP): for Japanese characters in serif
- [Noto Sans CJK / Noto Serif CJK](https://github.com/notofonts/noto-cjk): for the full CJK range, including Hangul and simplified Han (the JP families above cover Japanese only)
- [Noto Sans Mono](https://fonts.google.com/noto/specimen/Noto+Sans+Mono): for latin and other basic Unicode characters in sans serif mono (semi-condensed)
- [Noto Emoji](https://fonts.google.com/noto/specimen/Noto+Emoji): for emoji characters (the monochrome build; colour emoji fonts are not rendered by the PNG/PDF pipeline)

The scripts the gallery covers are named explicitly rather than left to the system's generic fallback: `Noto Sans Arabic` / `Noto Naskh Arabic`, `Noto Sans Hebrew` / `Noto Serif Hebrew`, and the Devanagari, Thai and Khmer faces of Noto Sans and Noto Serif. Where those fonts are installed, the same input renders the same way from one machine to the next. Mathematical alphanumerics (U+1D400–, such as the italic *v* of *v*P) are not named yet and still depend on what the system offers.

### Drawing Text

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

#### Subscript and Superscript

|Sample Input           |Output                      |
|-----------------------|----------------------------|
|`normal_subscript_`    |normal<sub>subscript</sub>  |
|`normal__superscript__`|normal<sup>superscript</sup>|

### Whitespace and Line Breaks

#### Whitespace inside a Label

|Sample Input|Output  |
|------------|--------|
|`X<>Y`      |X&nbsp;Y|

A label that is *only* `<>` is a special case with its own use: see [Levelling the Terminals](#levelling-the-terminals) below.

#### Levelling the Terminals

A node whose label is *only* `<>` renders as an invisible pass-through joint: the connector runs continuously through it without a break. Chaining such nodes pushes a shallow leaf down so it aligns with deeper leaves — useful when every terminal should sit on the same row.

```text
[S
  [NP [D [<> [<> the]]] [N [<> [<> cat]]]]
  [VP
    [V [<> [<> sat]]]
    [PP [P [<> on]] [NP [D the] [N mat]]]]]
```

Without the joints, *the*, *cat* and *sat* sit two rows above *the* and *mat*, and *on* one row above. Each leaf takes as many joints as it needs to reach the deepest row, so all six words end up on the bottom row. The [Animal ontology example](https://yohasebe.github.io/rsyntaxtree/examples#example-029) in the gallery uses `<>`-only joints the same way.

#### Newline

|Sample Input                   |Output              |
|-------------------------------|--------------------|
|`str1\`<br />`str2`            |str1<br />str2      |
|`str1\`<br />`   \`<br />`str2`|str1<br /><br />str2|
|`str1\ str2`                   |str1<br />str2      |
|`str1\ \ str2`                 |str1<br /><br />str2|
|`str1\nstr2`                   |str1<br />str2      |
|`str1\n\nstr2`                 |str1<br /><br />str2|

### Drawing Non-Text Elements

Circles, boxes and rules can be drawn around or alongside the text.

#### Small Capitals

Attribute names in a feature structure are conventionally set in small caps, and the look can be imitated without a small-caps font. Leave the capital as it is and wrap the rest in `___`: `H___EAD___` draws a full-size H followed by a smaller EAD.

#### Box, Circle, Bar, and Arrow

{% include box_and_circle_table.html %}

#### Horizontal Line

|Sample Input                   |Output                |
|-------------------------------|----------------------|
|`str1\`<br />`---\`<br />`str2`|str1<br />——<br />str2|
|`str1\ ---\ str2`              |str1<br />——<br />str2|
|`str1\n---\nstr2`              |str1<br />——<br />str2|

Here, `---` represents `-` repeated three times or more consecutively.

### Connectors

`Connector shape` offers three settings for what is drawn between a terminal node and its leaves (`auto`, `bar` and `none`). `auto` draws a triangle for leaves containing one or more whitespaces (= phrases). If the leaf does not contain any spaces (= single word), a straight bar is drawn instead. A `^` at the beginning of a leaf declares it to be a phrase, so a triangle is always drawn for it. `bar` draws a straight bar for every leaf. `none` draws no connector between a terminal node and its leaves.

### Brackets and Rectangles around a Leaf

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

### Feature Structures

An attribute-value matrix is a label of several lines, cut into columns so the
attributes line up down one side and their values down the other, with brackets
around the whole. Nothing about it is a notation of its own: it is ordinary label
markup, and each piece below is useful by itself.

| To draw | Write | Explained under |
|---------|-------|-----------------|
| the brackets around the matrix | `#` at the start of the label | [Brackets and Rectangles around a Leaf](#brackets-and-rectangles-around-a-leaf) |
| attributes and values in columns | `\t` between them | [Columns](#columns) |
| a matrix as the value of an attribute | `#(` … `#)` | [Nested matrices](#nested-matrices) |
| a boxed tag, for structure sharing | `|1|` | [Box, Circle, Bar, and Arrow](#box-circle-bar-and-arrow) |
| angle brackets around a list | `⟨` and `⟩`, typed as themselves | — |
| a hyphen in a feature name | `Hyphen: literal` | [Hyphens](#hyphens) |

Put together:

```text
[#*word*\
  PHON\t⟨<>*Kim*<>⟩\
  SYNSEM\t#(LOCAL\t#(CAT\t#(HEAD\t#(*noun*\
    CASE\t*nom*#)\
    SPR\t⟨<>|1|<>⟩#)#)#)
]
```

The gallery has three: an [HPSG feature structure](https://yohasebe.github.io/rsyntaxtree/examples#example-013), a [nested one](https://yohasebe.github.io/rsyntaxtree/examples#example-076), and an [f-structure](https://yohasebe.github.io/rsyntaxtree/examples#example-078).

A matrix can also stand at a node of a tree, which is what HPSG does with them,
and can be the category of a step in a [derivation](#derivations).

#### Columns

`\t` cuts a line into cells. Every line of the label is cut at the same points, and each column is drawn at the width of its widest cell, so the parts line up down the label instead of starting wherever the text before them happened to end. This is what an attribute-value matrix asks for — the attributes in one column, their values in the next:

```text
[#HEAD\tnoun\
  SPR\t⟨<>⟩\
  COMPS\t⟨<>NP<>⟩
  Kim
]
```

A label with more than two columns works the same way; each is as wide as it needs to be. See the [Head-Driven Phrase Structure Grammar example](https://yohasebe.github.io/rsyntaxtree/examples#example-013) in the gallery.

#### Nested matrices

The value of an attribute can be another matrix, written between `#(` and `#)`. It draws its own brackets and lays out its own columns, and the rows that follow it clear its full height:

```text
[#*word*\
  PHON\t⟨<>*Kim*<>⟩\
  SYNSEM\t#(LOCAL\t#(CAT\t#(HEAD\t#(*noun*\
    CASE\t*nom*#)\
    SPR\t⟨<>⟩#)#)#)
]
```

Matrices nest to any depth, which is what a feature path such as `SYNSEM | LOCAL | CATEGORY | HEAD` needs. Bare brackets would be read as tree structure and bare parentheses appear in labels too often to be claimed, hence `#(` and `#)`.

#### Hyphens

A hyphen opens and closes an underline, so a literal one is written `\-`. Feature names in HPSG and its relatives are full of hyphens — HEAD-DTR, RELIED-ON — and escaping each one is a poor trade for a rule that work never uses. `Hyphen` (`hyphen`, CLI `--hyphen`) swaps the two readings: with `literal`, a bare hyphen is a hyphen and `\-underlined\-` underlines instead. Two hyphens are structure rather than markup and are left alone either way: a line of nothing but hyphens is still the horizontal rule, and the one in a path suffix (`+-1`) still marks that path dashed.

### Derivations

A derivation is written differently from a tree. The words come first, at the
top; each step draws a rule across everything it combines and writes the result
under it; and what the whole thing arrives at stands at the bottom. Categorial
grammar is written this way, and so are diagrams of constituent spans.

Turn `Derivation` on and every node is joined to its daughters by one rule
across all of them, instead of by a line to each. Set `Direction` to `btt` as
well and the tree is turned over, so the words come first:

```text
[S\t< [NP\t> [NP/N the] [N dog]] [S\\NP\t> [(S\\NP)/NP bit] [NP John]]]
```

The structure is the ordinary bracket notation; nothing about it is special to
derivations. Two things are worth knowing.

**The name of each step goes after a column break.** `[S\t<` means the label is
`S` and the step that produced it is `<`. The name is set beside the end of its
own rule, small, where a derivation puts it. Anything can go there — `>`, `<`,
`>B`, `>T`, `<Φ>` — and none of it needs escaping, because the name is taken out
of the label before the label is read as markup.

**A backslash in a category is written `\\`.** `S\\NP` draws as `S\NP`. A single
backslash starts a line break, which is why the doubling is needed.

A category may be a feature structure rather than a plain label, which is how a
derivation is written where the categories carry features. The breaks inside the
matrix are its own columns; the one that names the rule is the break outside it:

```text
[#(CAT\tS#)\t< [#(CAT\tNP#) Kim] [#(CAT\tVP#) sleeps]]
```

Leave `Direction` at `ttb` and the same option draws the spans of a tree from
the top instead, each constituent's extent marked by a rule:

```text
[S [NP [D the] [N dog]] [VP [V bit] [NP John]]]
```

Set `Connector shape` to `none` so that no bar is drawn between a word and its
category, and use a small `V spacing` — the gallery's derivations are set at
`0.5`, the smallest there is: a derivation is set tight down the page.

Across the page, use `Tidy layout: low` with a wide `H spacing`. A derivation is
set as a table, each column as wide as the widest thing standing in it, and that
is what `low` does: it pulls the columns together and keeps the words in order.
`H spacing` then opens every column by the same amount, so the figure grows
wider without the rules and the words losing their proportions — the gallery's
derivations are set at `2.0`. What not to reach for is `Tidy layout: off`, which
gives each subtree the width the tree layout allots it: the gaps land wherever
the branching happens to put them rather than where the table wants them, and
one of them can be several times another.

Three things a derivation cannot be. `Direction: ltr` is refused, because a rule
across the premises needs them side by side. `Hide default connectors` is refused
too: it draws the connectors in the background colour rather than skipping them,
and a derivation's rules are the figure itself, not something added to it — hide
them and the categories are left in rows with nothing joining them. TikZ output
is refused as well: `forest` joins each daughter to its mother with an edge of
its own and puts the root at the top, so what it would produce is a correct tree
of the same structure rather than this figure. Use PNG, SVG or PDF.

### Draw Paths between Nodes (experimental)

You can draw any number of paths of three different types:

- Non-directional (rendered as dashed line `- - -`)
- Directional (rendered as solid line `----▶`)
- Bidirectional (rendered as solid line `◀----▶`)

Each path is distinguished by a unique ID number. The ID is specified by putting a plus sign and a number (e.g. `+7`) at the end of the node text. If a greater-than `>` or less-than `<` symbol is placed between the plus sign and the number (e.g. `+>7` or `+<7`), an arrowhead will appear at the end of the path. Note that it makes no difference whether `+>` or `+<` is used. The arrow is always directed to the element with one of these ID symbols.

A node can have any number of IDs. The same ID must appear in the text of the *two* nodes between which the path is rendered. The same ID number cannot appear in more than two places.

### Draw Extra Connectors between Nodes (experimental)

You can also add extra connector between nodes in the same fasion as you draw paths between nodes. Extra connectors are drawn as straigt lines (not as `polyline`s). You may enable the `Hide connectors` option when drawing extra connectors.

- Non-directional (rendered as solid line `-----`)
- Directional (rendered as solid line `--▶--`)
- Bidirectional (rendered as solid line `-◀-▶-`)

Each additional connectors is distinguished by an ID number. The ID is specified by putting a a number after a sequence of a plus and a minus symbols (e.g. `+-8`) at the end of the node text. If a greater-than `>` or less-than `<` symbol is placed between the minus sign and the number (e.g. `+->8`), an arrowhead will appear at the end of the connector. Note that it makes no difference whether `+->` or `+-<` is used. The arrow is always directed to the element with one of these ID symbols.

A node can have any number of IDs. The same ID must appear in the text of the *two* nodes between which the additional connector is rendered. The same ID number cannot appear in more than two places.

### Penn Treebank Format

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

### Running RSyntaxTree Yourself (advanced)

The following are not offered by the web app. They are available when you run RSyntaxTree on your own machine, as the gem or as the Docker image.

#### Using a Font of Your Own

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

#### Checking Input Without Drawing

`--validate` reports whether the input would draw. Nothing is drawn and no
file is written: the diagnosis goes to standard output as JSON, and the exit
code is 0 when the input is accepted and 1 when it is not.

```bash
rsyntaxtree --validate "[S [NP the cat] [VP sat]]"
```

Options are taken into account, so an input that depends on one is judged
with it:

```bash
rsyntaxtree --validate --hyphen literal "[X V-bar]"
```

The same input without the option is rejected, with the diagnosis naming
what is wrong and where:

```bash
$ rsyntaxtree --validate "[X V-bar]"
{
  "schema": "rsyntaxtree.error/1",
  "ok": false,
  "errors": [
    {
      "code": "bare_hyphen",
      "message": "Error: input text contains an invalid string\n > V-bar",
      "label": "V-bar",
      "position": 1,
      "hint": "A hyphen opens an underline. Escape it (e.g. f\\-structure, V\\-bar) or set the hyphen option to literal.",
      "retryable": true
    }
  ]
}
```

This is one observed answer, not a contract: the fields may change between
releases, and the exit code is the stable part of the answer.

#### Notation Reference

`--notation` prints a short reference for the notation to standard output.
`--examples` prints every published example with the options it was drawn
with. Both write and exit without reading any input.

```bash
rsyntaxtree --notation
rsyntaxtree --examples
```

The same material is on the site as plain text, for a reader that can fetch a
URL but cannot run a command: [llms.txt](https://yohasebe.github.io/rsyntaxtree/llms.txt)
is an index, and [llms-full.txt](https://yohasebe.github.io/rsyntaxtree/llms-full.txt)
holds the reference, this manual and every example in one file. Both are
generated from the sources they describe.

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

- Per-node coloring (`@color:`)
- Enclosures (`#`, `##`)
- Triangle connectors (`^`)
- Text decoration (bold, italic)
- Subscript/superscript (`_x_`, `__x__`)
- Path drawing (`+1`, `+>1`)
- Column alignment (`\t`) — cells run together on one line
- Nested matrix (`#(` … `#)`)
- Grey line scheme (`color: gray`)

<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lightbox2@2.11.3/src/js/lightbox.js"></script>

---

<script>
  // Copy the notation for one example. This used to add a `copy` listener to
  // the document and leave it there, so every later Cmd+C on the page
  // returned that same notation however much the reader had selected by
  // hand. The clipboard is written directly instead, and nothing is left
  // behind to intercept a selection.
  function copyToClipBoard(id){
    var text = document.getElementById(id).innerText;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text);
      return;
    }
    var area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.top = '-1000px';
    document.body.appendChild(area);
    area.select();
    document.execCommand('copy');
    document.body.removeChild(area);
  }
</script>

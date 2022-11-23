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

There are three different types of `connector` drawn between a terminal node and its leaves (`auto`, `bar` and `none`). `auto` draws a triangle for leaves containing one or more whitespaces (= phrases).  If the leaf does not contain any spaces (= single word), a straight bar is drawn instead (unless the leaf contains a `^` symbol at the beginning, which specifies the leaf to be a phrase).

The newline character `\n` can be used within the text of both node lables and leaves.

RSyntaxTree can generate `PNG` and `SVG`, SVG can be used with third party vector graphics software such as Adobe Illustrator, Microsoft Visio, [BOXY SVG](https://boxy-svg.com/), etc. It is very useful if you want to modify the output image.

The `Radical symmetrization` option affects the way branch nodes are drawn. The options `Font style`, `Font size`, `Connector height`, and `Color` need no explanation. By changing the values of these options, you can change the appearance of the resulting image.

### Fonts Used to Generate PNG

Currently, you can choose between the font styles `Noto Sans`, `Noto Serif`, and `WQY Zen Hei`.

- `Noto Sans` can display basic Unicode characters (including Japanese hiragana/katakana/kanji).
- `Noto Serif` can display basic Unicode characters (including Japanese hiragana/katakana/kanji).
- `WQY Zen Hei` can display a wide range of Chinese/Japanese/Korean (CJK) characters.


### Install Fonts for SVG

SVG images are dependent on the fonts installed locally on your computer. In order for the images to display as intended, the following fonts should be installed beforehand (click on the links). If these fonts are not installed, other available fonts will be used, resulting in a somewhat unbalanced display of the text.

- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans): for latin and other basic Unicode characters in sans serif
- [Noto Sans JP](https://fonts.google.com/noto/specimen/Noto+Sans+JP): for Japanese characters in sans serif
- [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif): for latin and other basic Unicode characters in serif
- [Noto Serif JP](https://fonts.google.com/noto/specimen/Noto+Serif+JP): for Japanese characters in serif
- [WQY Zen Hei](https://packages.ubuntu.com/bionic/fonts/fonts-wqy-zenhei): for CJK characters
- [OpenMoji](https://openmoji.org/): for emoji characters.


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

#### Box and Circle

{% include box_and_circle_table.html %}

#### Whitespace inside Label

|Sample Input|Output  |
|------------|--------|
|`X<>Y`      |X&nbsp;Y|

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

If a `#` character is placed at the beginning of the leaf text (right after `^` if there is one), the leaf text is enclosed in a paire of square brackets (e.g. `[NP #text]` or `[NP ^#text]`). If `##` is placed at the beginning of the leaf text, a rectangle is drawn instead of brackets.

### Escape Special Characters

The backslash character `\` must be used to print certain characters used in the markup. If you do not have the `\` key on your keyboard, you can also use the yen/yuan character `¥` to escape.

{% include escape_char_table.html %}

**Note:** A newline character `↩️` is treated just as a whitespace. Thus 1) `\n`, 2) `\↩️`, and 3) `\` followed by a whitespace character are all rendered as a newline `↩️` in the resulting image. Note also that a `↩️` or a whitespace repeated more than once is reduced to a single whitespace.

### Draw Paths between Nodes (experimental)

You can draw any number of paths of three different types:

- Non-directional (rendered `- - -`)
- Directional (rendered `----->`)
- Bidirectional (rendered `<----->`)

Each path is distinguished by a path ID number. The path ID is specified by putting a plus sign and a number (e.g. `+7`) at the end of the node text. If a greater-than sign is placed between the plus sign and the number (e.g. `+>7`), an arrowhead will appear at the end of the path.
A node can have any number of path IDs. The same path ID must appear in the text of the *two* nodes between which the path is rendered. The same ID number cannot appear in more than two places.

<script src="https://cdn.jsdelivr.net/npm/jquery@3.5.0/dist/jquery.min.js"></script>
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

RSyntaxTree notation, on one page.

A tree is labeled brackets: [S [NP the cat] [VP sat]]. The label follows the
opening bracket; children follow the label. Parentheses are read as Penn
Treebank notation and converted: (S (NP the cat) (VP sat)) draws the same tree.

## What already means something

The characters that bite, first. A mistake the tool can see is refused with a
hint; everything below is taken silently, and the figure that draws is not the
figure that was meant.

- `<>` is one space and `<3>` is three, everywhere — never angle brackets.
  Where linguistics wants the brackets themselves, write ⟨ and ⟩ (U+27E8/9):
  SPR\t⟨<>NP<>⟩, 'hand⟨SUBJ,OBJ⟩'. A label written <NP> is refused with this
  advice; a stray <3> simply draws three spaces.
- A pair of hyphens underlines what stands between them: well-made-word draws
  "made" underlined. (A lone hyphen is refused with a hint.) Write `\-` for a
  hyphen — V\-bar, HEAD\-DTR — or set the hyphen option to literal.
- A raw space is safe in a one-line label and unreliable in a label that has
  `\n` or `\t` in it: there it can split a value that carries markup, and it
  breaks a nested #( ... #) matrix. Inside any label with columns, write a
  space as `<>`: 'a<>toy', not 'a toy'.
- A straight apostrophe is typeset as the curly ’ (U+2019).
- A backslash takes the character after it, whatever it is: \q draws q, and
  C:\path draws C:path. A backslash itself is \\.
- The prefixes of a label compose in one order, and only this one:
  `^` → `#`/`##`/`###` → `%` → `@color:`. So ^#%@red:NP is read whole, while
  @red:%NP leaves the % as a literal character and silently drops the shade.
- A rule name (for derivations) is written after the label's last `\t`, as in
  [S/NP\t>B ...], and needs the derivation option ON — with it off the name is
  drawn as a column. The name is taken out before markup runs, so `>` and `<`
  need no escaping there and `\>` would put the backslash in the figure. A
  label that also carries `\n` keeps all its columns instead.

## What there is

Structure:

| what                                   | how it is written |
|----------------------------------------|-------------------|
| a node with children                   | [S [NP the cat] [VP sat]] |
| a phrase under one leaf (triangle)     | [NP a toy] — one word, forced: [NP ^cats] |
| an invisible joint, to align leaves    | a label of only <>, as in [X [<> [Y y]] [Z z]] |
| a movement path (dashed)               | [S [NP a+1] [VP [V b] [NP c+1]]] |
| the same, with an arrowhead            | write +>1 on the end the arrow points at |
| an extra straight connector            | +-1 on two nodes; +->1 for an arrowhead |

Inside a label:

| what                                   | how it is written |
|----------------------------------------|-------------------|
| italic, bold, both                     | *x*, **x**, ***x*** |
| subscript, superscript                 | x_i_, x__2__ |
| small capitals                         | H___EAD___ |
| overline, underline, strikethrough     | =x=, -x-, ~x~ |
| a line break; a blank line             | a\nb (or a\ b); \n\n |
| columns, aligned down the label        | HEAD\t*verb*\nSPR\t⟨<>⟩ |
| a horizontal rule across the label     | a line of --- (or === for a double rule) |
| boxed, circled text                    | |1|, {2} — more than one character draws a capsule |
| empty and hatched boxes and circles    | ||, {}, |/|, {/} |
| bar and arrows as symbols              | --, ->, <-, <-> — bold with *...*, as in *->* |

Around a label:

| what                                   | how it is written |
|----------------------------------------|-------------------|
| square brackets, rectangle, bold       | #NP, ##NP, ###NP |
| a feature matrix as a value            | #(HEAD\tnoun#), nested to any depth |
| a whole label that is one matrix       | [#(CAT\tS#) [#(CAT\tNP#) Kim] [#(CAT\tVP#) sleeps]] |
| a region shade behind the subtree      | %NP, coloured: %@blue:NP |
| a colour                               | @red:NP, @#3af:NP, @#33aaff:NP (3 or 6 hex digits) |

An attribute-value matrix is columns plus an enclosure, and a value can be
another matrix — nested with #( ... #), never with square brackets, which are
read as tree structure:

    [#PRED\t'hand⟨SUBJ,OBJ⟩'\
      TENSE\tpast\
      SUBJ\t#(PRED\t'David'#)
    ]

Options (the command line spells them --like-this):

| option     | what it decides |
|------------|-----------------|
| format     | png, svg, pdf, gif, jpg, tikz, lsif |
| fontstyle  | sans, serif, mono, cjk |
| fontsize   | 6–26 |
| color      | modern, traditional, off, gray |
| linewidth  | every line's weight, 0.5–3.0, as a ratio of the font size |
| leafstyle  | auto, bar, nothing — what joins a node to its leaf |
| direction  | ttb, ltr, btt |
| mirror     | flip the finished layout, for RTL scripts |
| tidy       | off, symmetric, low, medium, high — how tightly subtrees pack |
| hspacing   | horizontal spacing factor, 0.5–3.0 (tidy_spacing is its old name) |
| vheight    | vertical spacing factor, 0.5–5.0 |
| derivation | one rule across the daughters, categorial-grammar style |
| hyphen     | markup (hyphens underline) or literal (hyphens are hyphens) |

The full manual explains each of these with figures, and every example in the
gallery is written out beside the figure it draws:

    https://yohasebe.github.io/rsyntaxtree/documentation
    https://yohasebe.github.io/rsyntaxtree/examples

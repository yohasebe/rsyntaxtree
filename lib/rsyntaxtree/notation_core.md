RSyntaxTree notation, in brief.

A tree is labeled brackets: [S [NP the cat] [VP sat]]. The label follows the
opening bracket; children follow the label.

Within a label:
- `\n` breaks a line; `\t` separates columns, and every line is cut at the
  same points, so the columns line up down the label. (`\t` is the two
  characters backslash and t, not a real tab.)
- `#label` draws square brackets around the whole label; `##label` a
  rectangle. `#( ... #)` nests a matrix inside a label, to any depth.
- `*italic*`, `**bold**`, `x_sub_`, `x__super__`, `|x|` in a box, `{x}` in a
  circle, `---` a horizontal rule.
- `+n` on two nodes links them with a movement arrow; `+>n` puts the
  arrowhead on that end.

Four traps, because these characters already mean something:
- `<` and `>` are never angle brackets in this notation: `<>` is one space,
  `<3>` is three. Wherever linguistics uses angle brackets — a list 〈NP〉,
  an argument structure like 'hand〈SUBJ,OBJ〉', anything — write the
  characters 〈 and 〉 themselves (U+27E8 and U+27E9):
  SPR\t〈<>NP<>〉    PRED\t'hand〈SUBJ,OBJ〉'
- `-` opens and closes an underline, so a bare hyphen in ANY word is an
  error: V-bar, f-structure, HEAD-DTR. Write `V'`, or escape the hyphen:
  `V\-bar`, `f\-structure`, `HEAD\-DTR`.
- A raw space is safe in a one-line label, and unreliable in a label that
  has `\n` or `\t` in it: there it splits a value that carries markup, and
  it breaks a matrix nested with `#( ... #)`. Since matrices are exactly the
  multi-line case, write a space as `<>` inside any label with columns:
  'a<>toy', not 'a toy'.
- Parentheses are not brackets, and this is silent: `(S (NP ...))` raises no
  error and draws one leaf with that text in it. Convert it first.

An attribute-value matrix is columns plus an enclosure:

    [#*word*\
      HEAD\t*verb*\
      SPR\t〈<>NP<>〉\
      COMPS\t〈<>〉
    ]

A value can be another matrix. Nest it with `#( ... #)`, never with square
brackets — those are read as tree structure:

    [#PRED\t'hand〈SUBJ,OBJ〉'\
      TENSE\tpast\
      SUBJ\t#(PRED\t'David'#)
    ]

A movement arrow links the two nodes that carry the same number:

    [S [NP what+>1] [VP [V see] [NP+1 t]]]

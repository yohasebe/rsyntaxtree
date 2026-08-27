# Changelog

## [Unreleased]

### Fixed
- Turning `derivation` on no longer deletes a column from a node that has no
  daughters. A rule name is written after a column break and names the step
  that produced a node from its daughters, so a node with none names no rule —
  but the label is read before the tree is built, and the name was taken out
  anyway and then had no rule to be drawn beside. `[A\tfoo]` drew "A foo" with
  the option off and "A" with it on. The label is put back once the tree is
  known.
- A mistake inside a node's label keeps the name of what is wrong with it. The
  first raw space splits a token into a label and its children, and when the
  label would not parse, every cause but one was relabelled "a raw space split
  this" — so the message named an unknown colour while the code and the hint
  talked about spaces, and a caller acting on the code was sent to fix what was
  not wrong. Which story is right is now asked of the parser rather than
  guessed: the token is put back together with its spaces written as the
  notation writes them, and if it reads, the space was the cause.
- A hex colour is three digits or six, which is what every message about colour
  here already said. The grammar asked for three to six, so four and five
  parsed, passed the validator — which does not look at a value beginning with
  `#` — and reached librsvg, which cannot read them and draws the label black
  without reporting it.

## [1.13.2] - 2026-08

### Fixed
- A movement path is drawn as one stroke with its corners eased, in place of
  three lines meeting at right angles. The dash of a non-directional path now
  runs round each turn instead of restarting at it, and the arrowhead is the end
  of the stroke rather than a marker on whichever line finished last. The radius
  is held down to half of each run it joins, so a short leg cannot be swallowed
  by its own turn, and to the length of an arrowhead where there is one, so the
  head is never drawn onto the curve. Three gallery figures carry paths and
  change with it.
- Digits are set in the text face again on machines that have a colour emoji
  font. The font chains named emoji families by name, and asking fontconfig for
  one is asking for the generic `emoji` family, whose preference list fontconfig
  then prepends to the whole pattern with a strong binding — so the emoji face
  arrived ahead of the Noto text faces rather than behind them. A colour emoji
  font carries the ASCII digits, for keycap sequences, so on an ordinary Linux
  desktop `[N 20]` came out in the emoji face at more than twice the width.
  Measurement and drawing read the same chain, so the figure held together; it
  was simply not the figure the same input gives elsewhere. No emoji family is
  named now: a codepoint no named family covers reaches fontconfig's own
  fallback, which is the path this was duplicating. Emoji draw as before, and
  the gallery is unchanged to the pixel — every raster figure is byte-identical
  and the SVGs differ only in the family list they carry.

## [1.13.1] - 2026-08

### Fixed
- `^` at the head of a leaf draws the triangle it asks for. The mark may be
  written on the node's label or on the leaf's own text — `[^NP cats]` and
  `[NP ^cats]` — and the documentation, the notation reference and the gallery
  all use both, but only the first was drawn: the second lost its caret to the
  parser and then a bar was drawn under it. The two now produce the same figure
  in every connector style, and LSIF records the edge as a triangle. Three
  gallery figures change accordingly, each toward what it was written to show.
- An option given as an empty string is read as an option not given, rather
  than as a value no list contains. An HTML form posts a field for every
  control it carries, and a control with nothing selected posts the empty
  string, so a form that has outlived one of its own controls sends that field
  empty alongside the rest. Since option validation arrived in 1.11.0 that
  failed the whole request: the web UI's Download buttons answered 500 for
  every input, because the form still read a `format` select the page no longer
  had. A value that is actually wrong is still rejected.

## [1.13.0] - 2026-08

### Added
- Derivations. A derivation puts the words first and the result last, and
  joins what each step combines with one rule drawn across all of it rather
  than with a line to each daughter. `derivation` draws the rules and
  `direction: btt` turns the tree over; together they give the format
  categorial grammar is written in, and `derivation` on its own marks the
  spans of an ordinary tree. The name of each step rides in the label after a
  column break and is set beside the end of its rule. A derivation runs down
  the page and is drawn with its rules, so `direction: ltr` and hiding the
  default connectors are refused rather than approximated.
- `direction: btt`, the layout turned over, leaves first.

### Fixed
- Connectors follow the tree when it is turned over. They kept the ends they
  have when the root is at the top, so every line ran from above the daughter,
  through its label and the mother's, to below the mother.

## [1.12.0] - 2026-08

Everything needed to write this notation is now available as text, built from
the files the tool itself reads, and a refusal says where that text is.

### Added
- `--examples` prints every published example with the options it was drawn
  with. The gallery examples are checked against the parser that draws them,
  so each one is known to be accepted.
- The site carries the same material as plain text for a reader that can fetch
  a URL but cannot run a command: `llms.txt` and `llms-full.txt`, the second
  holding the reference, the manual and every example in one file. Both are
  generated from their sources, and a test fails if they fall behind.
- A refusal names where the notation is written down, once, alongside the
  cause and the fix. A hint repairs the mistake in front of it and says
  nothing about the rest, which is not enough for a caller that was guessing.

### Changed
- The angle bracket the reference recommends is U+27E8 and U+27E9, which it
  had always named while writing U+3008 and U+3009 in its own examples. The
  East Asian pair draws a full em wide, wider than a capital, and had spread
  through the gallery and into the repair that corrects ASCII brackets. Both
  pairs still parse; documents written before this are unaffected.
- Two feature-structure figures are redrawn at the narrower bracket.

### Fixed
- `--notation` and `--examples` answer before the input is read. Reading first
  meant waiting on a pipe that never closes when stdin is not a terminal,
  which is how a script reaches them.

## [1.11.0] - 2026-08

Every input the tool accepts now draws, and every input it refuses says why.
Line thickness follows the type size, so figures drawn at any font size keep
the same balance between text and rules — existing figures come out about a
fifth lighter than before.

### Added
- `--validate` checks input without drawing or writing a file, reporting a
  machine-readable diagnosis on stdout and the verdict in the exit code.
- `--notation` prints a short reference for the notation, which now ships
  with the gem.
- Errors carry a code, the offending label and an offset inside it, a
  one-line fix, and whether rewriting the input could help. The message text
  is unchanged. Each cause is confirmed by applying its fix and parsing
  again, so a named cause is one whose fix is known to work.
- A label may be nothing but a matrix: `[#(HEAD\tnoun#)]` had no spelling
  before, since the enclosure rule took the `#` first.
- `-f tikz` on the command line, which the documentation had offered while
  the CLI rejected it. TikZ output also carries the line width, which it
  had been accepting and dropping.
- A gallery figure and a heading of its own for levelling the terminals with
  `<>` joints.

### Changed
- Line width is a fraction of the font size rather than an absolute number.
  `1` is five per cent of the type size at any size, and the scale runs from
  `0.5` to `3.0` in halves where it ran `1` to `5` and meant `2` to `6`.
  Lines were two units wide whatever the type size, which read as heavily as
  a serif stem at 16 point and heavier still below that, and nothing thinner
  was available.
- On/off options accept every spelling of off. `mirror: "no"` reversed the
  tree and `transparent: "0"` cut the background away, because anything but
  `"off"` and `"false"` was read as on.
- Option values are checked against the values the option takes. A value
  nobody defines was taken and read as something else — `direction:
  "left-to-right"` laid the tree out top to bottom. The CLI has always
  refused these; the library did not, which left the web interface and other
  programmatic callers unguarded.
- Colour names are checked against the CSS colour names. A name nobody
  defines passed validation and drew black.
- Penn Treebank input converts in the library, not only in the CLI. Other
  callers got no conversion and no error: `(S (NP the dog))` drew as one
  leaf containing that text.
- Font sizes go down to 6, which the web interface has always offered while
  the documentation said 8.

### Fixed
- Validation accepted input that drawing then refused: a movement path with
  one end, a tree too wide for a raster surface, a colour spec that fails
  only when the label is parsed. It now generates the drawing and discards
  it, going as far as the requested format can still refuse.
- A malformed colour was reported as an unclosed enclosure, sending the
  writer to fix a `#` that was never the problem.
- A left-to-right matrix drew its brackets on top of the attribute names.
- Text in front of a tree crashed symmetrization, and an empty argument was
  read as a path to the current directory.
- Overline was documented as missing from PNG output. It has been there.

## [1.10.0] - 2026-08

A transitional release ahead of 2.0, which drops JPG/GIF output and the
RMagick dependency.

### Deprecated
- JPG and GIF output: the CLI prints a warning to stderr when either is
  requested, and the documentation marks both as deprecated. JPEG blurs
  line art and GIF has no use case here — use PNG. Both formats are
  removed in 2.0.

### Changed
- The library no longer loads RMagick at require time. SVG, PNG, PDF,
  TikZ and LSIF work without ImageMagick installed; only a JPG or GIF
  request needs RMagick, and a request without it reports the missing
  dependency as a regular input error instead of a bare `LoadError`.

### Fixed
- `RSTError` mutated the message it was given, so raising one with a plain
  string literal crashed inside the error class with a `FrozenError`. Every
  file here carries `frozen_string_literal`, which made the working form the
  unobvious one.

## [1.9.0] - 2026-08

### Added
- `hyphen: literal`, which trades the two readings of a hyphen: a bare one is
  a hyphen and `\-underlined\-` underlines. Feature names in HPSG and its
  relatives are full of hyphens, and escaping each one is a poor trade for a
  rule that work never uses.
- A matrix nested in a label, written between `#(` and `#)`. The value of an
  attribute can be another attribute-value matrix, to any depth, which is what
  a feature path such as SYNSEM | LOCAL | CATEGORY | HEAD needs and what HPSG,
  SBCG and LFG are written in. The nested matrix draws its own brackets and
  lays out its own columns, and the rows after it clear its full height.
- `\t` in a label cuts the line into cells. Every line is cut at the same
  points and each column is drawn at the width of its widest cell, so the
  parts line up down the label. Together with the bracket enclosure and the
  horizontal rule this gives attribute-value matrices — the feature structures
  of HPSG, SBCG and LFG — without spacing each row by hand, which is how the
  gallery's HPSG example used to do it.
- `color: gray`, a scheme that keeps node and leaf labels black and draws the
  connectors, triangles and movement paths in grey. It is for diagrams whose
  links outnumber their labels — an ontology, a network of constructions —
  where a page of black lines buries the text. `grey` is accepted too.
- Gallery examples for two more frameworks: LFG (an annotated c-structure and
  the f-structure it maps to, after Kaplan & Bresnan 1982 and Bresnan 2001)
  and DRT (a discourse representation structure, after Kamp 1981).
- The example gallery scales each figure by its own width rather than by one
  factor for all of them, so a small tree and a wide one are read at a similar
  apparent size; a figure now fits its row instead of scrolling, loads lazily,
  and carries an anchor of its own.

### Changed
- Every box and circle in a figure is drawn at one size and on one centre
  line. The size used to come from the line's height, which left a box
  standing a head taller than the numeral inside it, and each shape was
  centred on its own glyph, so the box around `s` sat lower than the one
  around `G`. A shape is now drawn at a fixed fraction of the font size,
  centred on a capital, and grows only for content that will not fit. Every
  figure with a boxed or circled label is redrawn.
- The SVG's declared width and height agree with its viewBox. They did not,
  so every figure was scaled down by a few percent and letterboxed inside
  its own canvas.

### Fixed
- TikZ export dropped everything inside a nested matrix: a feature structure
  came out as its outermost attribute names and nothing else. The export still
  cannot draw the brackets, but it keeps what they hold. The documented list of
  what TikZ does not carry now names column alignment, nested matrices and the
  grey line scheme.
- LSIF records which of the two readings of a hyphen the input was parsed
  under. It records the input verbatim, and the same string means different
  things under the two, so a reader could not re-parse it.
- A line-type connection with only one end raised a NoMethodError from inside
  the drawing instead of being reported as the input error it is.
- A line-type connection between two nodes was anchored a full inter-node gap
  outside each of them, so the link fell short of both boxes where the gap was
  wide and reached inside them where it was narrow. It now runs between the
  boxes' own edges, a quarter of a gap short of each. The double arrowhead
  keeps the shape it had but is sized to the link, instead of one fixed size
  that spilled over both boxes on a short link. The same anchors are used in
  left-to-right layout, where a link between siblings had been drawn diagonally
  from the movement-path anchors and now runs straight between the facing
  edges.
- Two nodes joined by a line-type connection are laid out far enough apart for
  a full-size arrowhead between them. Where the layout had packed them closer
  than the arrow is wide — the two leaves at the foot of the quicksort figure —
  the arrow was drawn small to fit; now the pair is spread and the arrow keeps
  its size. Only pairs that carry a link move, and only when they need to.

## [1.8.2] - 2026-08

### Changed
- `tidy: high` now compresses as far as its name promises. The level-balance
  floor added in 1.8.0, which keeps a pair of siblings from being tucked
  narrower than the level below it, applied to `medium` and `high` alike and
  bound first in nearly every tree: across the 75 gallery examples the two
  modes produced identical figures 70 times. The floor now applies to `medium`
  only, leaving `high` free to trade even branch angles for width — 29 of the
  75 examples now differ, by up to 19%. `off`, `low` and `medium` are
  unchanged; `high`, like `symmetric` at the other end of the scale, is for
  figures that ask for it.
- Mathematical alphanumerics (U+1D400–, such as the little *v* of *v*P) are
  named in the family chains. Neither Noto Sans nor Noto Serif covers the
  block, so the glyphs came from whatever the machine offered: Noto Sans Math
  on Alpine, DejaVu Serif on Debian/Ubuntu, STIX Two Math on macOS. The serif
  style now asks for a serif source first, so a serif tree no longer shows a
  sans *v*. The Docker images install `font-dejavu` for it.

### Fixed
- The CLI printed parse errors to stdout and exited 0, so a script generating
  figures in bulk could not tell a rejected input from a drawn one. Errors go
  to stderr and the exit status is 1.
- Dropped `Noto Sans Mono SemiCondensed` from the mono chain. It is a width
  style of the variable Noto Sans Mono rather than a family of its own, and
  resolved nowhere on macOS, Debian/Ubuntu or Alpine; the chain fell through
  to `Noto Sans Mono`, which it now names directly.

## [1.8.1] - 2026-08

### Fixed
- Arabic rendered as isolated, unjoined letterforms in some environments.
  Scripts outside Latin and CJK were left to the system's generic font
  fallback, which is not the same font on every machine: on Alpine the Arabic
  block was claimed by Noto Sans Math, which has the glyphs but no joining
  rules, while on Debian/Ubuntu the same text fell to DejaVu Sans. The family
  chains now name the scripts the gallery covers — Arabic (`Noto Sans Arabic`,
  with `Noto Naskh Arabic` for the serif style), Hebrew, Devanagari, Thai and
  Khmer — so machines that have those fonts installed produce the same shapes.
  Mathematical alphanumerics (U+1D400–) are not named yet and still vary by
  environment. Gallery example 067 (Arabic) was affected and has been
  regenerated.
- Emoji were measured with one font and drawn with another where a colour
  emoji font was installed: Pango selects `Noto Color Emoji`, but the
  librsvg/Cairo pipeline does not rasterise its bitmap glyphs, so the drawing
  fell back to whatever outline font happened to cover the codepoint. The
  project's Docker images now install the monochrome Noto Emoji and leave the
  colour build out.

### Changed
- The Docker images install the Noto packages for Arabic (including Naskh),
  Hebrew, Devanagari, Thai and Khmer, and carry a fontconfig rule that removes
  the Arabic ranges from Noto Sans Math while keeping its mathematical
  alphanumerics (used for the little *v* of *v*P).
- Documentation records how to override any of the named families with a
  fontconfig alias, for users who prefer their own script fonts.

## [1.8.0] - 2026-08

### Added
- `tidy` layout scale, one option covering every layout mode from the most
  spacious to the most dense: `symmetric` (radical symmetrization) | `off` |
  `low` (contour packing, strict leaf positions) | `medium` (packing with
  cross-row tucking that never lets two leaves swap their left-right order) |
  `high` (free tucking; leaf order kept per row only). Connector heights
  adjust automatically: a small height budget (5% of the tree's height) is
  spent on the levels whose branches spread widest, evening out branch
  angles. Tidy never produces overlapping labels (collisions roll back).
- `mirror` option: flips the finished layout horizontally for the
  right-to-left tree convention of Arabic/Hebrew syntax (composes with
  `direction`).
- `hspacing` option: scales every horizontal gap in every layout mode — the
  horizontal counterpart of `vheight`/connector height.
- Pass-through empty nodes: a node labeled only `<>` renders as an invisible
  joint with the connector running continuously through it, so a `<>` chain
  aligns a shallow leaf with deeper leaves without a broken line.
- Full CJK coverage in every font style: the family chains fall back to
  Noto Sans/Serif/Mono CJK, so Hangul and simplified/traditional Han render
  in all styles (the standalone Noto JP faces carry no Hangul).
- Example gallery: Multilingual category (the same UD-PUD sentence in nine
  languages, constituency derived mechanically from the dependency
  annotation; the Arabic example demonstrates `mirror`), a Morphology
  category, and per-figure tidy settings across the whole gallery.
- CI on GitHub Actions (Ruby 3.2/3.4).

### Changed
- LSIF output records the layout settings a reader cannot recover from the
  coordinates: `geometry.mirror`, and `tidy`, `mirror`, `direction` and
  `horizontal_spacing` under `meta.source.params`.
- The standalone `symmetrize` option and `-y` flag are deprecated aliases of
  `tidy: symmetric`; `tidy_spacing` is a deprecated alias of `hspacing`.
- `--direction` now owns the `-d` short flag (it had been auto-assigned to
  `--hide-default-connectors`, so the documented `-d ltr` silently did
  nothing). Every published short flag is now declared explicitly rather
  than derived from the option set. One undocumented auto-assignment moved
  as a result: `-e` was `--direction` in 1.7.0 and is `--version` here.
- The gem no longer bundles font files (38MB that were never opened at
  runtime since the Pango migration): fonts resolve by family name through
  fontconfig. See README for the system font packages. The dead `--font`
  CLI option (its value was never read) is gone.

### Fixed
- Boolean options left at their defaults are no longer misread as enabled
  when the caller passes only a partial parameter set (e.g. `tidy: off`
  rendered as `symmetric` in the web UI).

## [1.7.0] - 2026-08

### Changed
- Text measurement now uses Pango, the same engine (and the same fontconfig
  font-fallback resolution) librsvg uses to render the output, instead of
  RMagick with the bundled font files. Labels in any script are measured with
  the font that actually draws them, which fixes off-center labels for scripts
  the bundled fonts do not cover (e.g. Khmer, #14) without bundling per-script
  fonts. Horizontal dimensions of the output may change slightly.
- Vertical rhythm is now derived deterministically from the font size
  (1.4 x size, matching the previous Latin line height) and is identical
  across scripts; the old engine spaced Japanese text 1.5x and WenQuanYi
  1.25x, so mixed-language documents had inconsistent spacing.
- The font-family lists used in the SVG output and in measurement are now
  defined in a single place (`FONT_FAMILIES` / `FontFamily`).

### Added
- Runtime dependency on the `pango` gem (ruby-gnome). No new system
  requirements: librsvg already depends on Pango.

## [1.6.3] - 2026-07

### Fixed
- Packaged files no longer carry owner-only permissions. `gem build` preserves
  on-disk modes, so gems built from a checkout with `0600`/`0700` files shipped
  a library unreadable — and a `rsyntaxtree` CLI unexecutable — by anyone but
  the owner after `sudo gem install`. File modes are now normalized before the
  gem is built: `0755` for commands (`bin/`, `exe/`) and shebang scripts, `0644`
  for everything else. This also drops stray executable bits that the working
  tree had picked up on data files (images, fonts, Markdown, CSS, library
  sources).

## [1.6.2] - 2026-06

### Fixed
- Region shade no longer touches the image edge when its padded bounds reach
  past the tree's natural extent (e.g. a deep enclosed/multi-line node): the
  canvas now grows with a margin around the shaded plane.

## [1.6.1] - 2026-06

### Improved
- Region shade rendering wraps the subtree more cleanly: wider, balanced
  padding; bracket/rectangle enclosures are kept inside the plane; the incoming
  parent connector stops just short of the plane (no overlap or touching); and
  the margin is consistent between root and non-root regions. Works in both
  top-to-bottom and left-to-right layouts (the connector-facing edge is the top
  in TTB and the left in LTR, with symmetric padding on the other sides).

### Added
- Example 065: nested (overlapping) region shades, shown as progressively
  darker gray.

## [1.6.0] - 2026-06

### Added
- Region shade (`%` prefix): paints a semi-transparent plane behind the whole
  subtree a node governs, for marking c-command/binding domains and cognitive
  grammar dominions. Color reuses the `@color:` syntax; bare `%` uses light gray.
  Each plane has a darker same-color border for visibility on white. An explicit
  shade color is always honored (consistent with `@color:` node text); use bare
  `%` for a gray monochrome shade. Works in both TTB and LTR layouts and across
  SVG/PNG/PDF/JPG/GIF.
- Region shade support in TikZ export (via `forest` `fit to=tree`) and in LSIF
  node `style.region`. TikZ region colors (names and hex, including SVG/CSS
  names like `lightblue` that xcolor lacks) are emitted as explicit RGB so the
  output compiles.
- `\%` escape for a literal leading percent sign.
- Typographic apostrophe: a straight ASCII apostrophe (`'`) in a label is now
  rendered as a curly apostrophe (`’`, U+2019) for smarter typography, e.g. the
  X-bar prime in `T'`. Applied to all fonts and measured before layout so
  spacing stays correct.
- Example 064: region shade for a c-command domain.

### Changed
- LSIF output version bumped to `0.3.0` (adds node `style.region`).

### Fixed
- Region shade on the root/topmost node no longer clipped by the canvas: the
  SVG viewBox now grows to include region planes that extend past the tree.

## [1.5.0] - 2026-04

### Added
- Left-to-right tree layout (`-d ltr` / `--direction ltr`)
- LSIF `geometry.direction` field for layout direction
- LTR-aware path drawing (movement arrows route rightward in ⊃ shape)
- LTR-aware line-type connections (direct lines between nodes)
- Examples 058-063: LTR versions of classification trees and vP-shell with paths

### Fixed
- Node label overlap when adjacent subtrees have long labels

### Improved
- TTB path bulge proportional to endpoint distance (reduced excess)

## [1.4.0] - 2026-01

### Added
- LSIF (Linguistic Structure Interchange Format) JSON output (`-f lsif`)
- Per-node coloring with `@color:` syntax (named colors and hex colors)
- Penn Treebank format support with escaped parentheses (`\(`, `\)`)
- Standard input support for piping tree data
- Configuration file support (`.rsyntaxtreerc`)
- Config file validation with helpful error messages

### Documentation
- Added TikZ output limitations section
- Improved README with Features section
- Added examples for per-node coloring (054, 055, 056)
- Added example 057: Subscript and superscript demo

## [1.3.2] - 2024

- Garbage collection friendly implementation

## [1.3.1] - 2024

- Bug fixes and improvements

## [1.3.0] - 2024

- TikZ/forest LaTeX output support

## Previous versions

See commit history for earlier changes.

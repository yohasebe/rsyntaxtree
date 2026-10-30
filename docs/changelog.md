---
title: RSyntaxTree
layout: default
---

# Changelog
{:.no_toc}

[Documentation](https://yohasebe.github.io/rsyntaxtree/documentation) |
[Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples) |
[Web App](https://yohasebe.com/rsyntaxtree)

## [2.4.1] - 2026-09-02

### Fixed
- Connectors from a short node start at its own bottom, not below a taller label in the same row

## [2.4.0] - 2026-09-02

### Added
- `RSyntaxTree.escape(text, as:, hyphen:, apostrophe:)`: notation that draws as the given text
- `\'` for a straight apostrophe and `\@` for an at sign

### Fixed
- `\+` before digits is a plus sign (labels such as "C++11" no longer start a movement path)
- Labels containing a backslash could lose characters in the drawing
- Unknown escapes (`\'`, `\@`) lost their backslash before markup was read

## [2.3.0] - 2026-09-01

### Added
- `RSTError::CODES`: the complete list of error codes (codes are only ever added)

### Fixed
- Whitespace-only input reported as empty input instead of `internal_error`
- A single character without brackets draws as one leaf

## [2.2.0] - 2026-09-01

### Changed
- Validation reports every error in a stage, not only the first (up to 20; schema unchanged)

### Added
- `RSGenerator.diagnose(text, options)` returns the full diagnosis as a hash

## [2.1.0] - 2026-08-29

### Changed
- JSON output renamed from `lsif` to `json` (`-f json`, `syntree.json`); `lsif` remains an alias until 3.0
- JSON documents carry a top-level `format` object (`rsyntaxtree-json`, schema 0.4.0) in place of `lsif`

### Added
- Feature matrices in the JSON output carry their rows and cells

## [2.0.0] - 2026-08-28

### Removed
- JPG and GIF output, and with them the RMagick and ImageMagick dependency
- Deprecated aliases `symmetrize` (`-y`), `tidy_spacing`, `tidy_nest` and `leafstyle: none`
- `symmetrize` from the LSIF `meta.source.params` block

### Added
- `shear` and `shear_plane`: tilt the figure and draw the plane it lies on
- `vmargin`: clearance between a label and its connectors (0.1–1.0)
- Gallery examples: Indo-European family tree, type-driven semantic composition, typed feature structures

### Changed
- A removed option is refused with its replacement named
- Every option listed in the README and the notation reference
- Manuals describe what TikZ output drops

### Fixed
- Triangles pointed the wrong way in bottom-to-top trees
- Labels keep the same space above as below
- Movement rails cut off at the right edge of left-to-right figures
- `---` and `===` rules refused inside `#( … #)` matrices
- Matrix bracket drawn over the content before it in the same cell
- `hspacing` and `vheight` both changed the width of left-to-right trees
- Misspelled `storoke-width` in SVG text styles

### Migration
- `format: "jpg"` / `"gif"` → `"png"`
- `symmetrize: "on"` → `tidy: "symmetric"`
- `tidy_spacing: n` → `hspacing: n`
- `leafstyle: "none"` → `"nothing"`

## [1.14.0] - 2026-08-27

### Added
- One-page notation reference (`--notation`), with the same feature list at the top of both manuals
- Changelog page on the documentation site (/changelog)

### Changed
- Changelog dates taken from the git tags
- Pitfalls section limited to inputs that draw differently from what was meant
- Arrow-marker dimensions rounded in SVG output

### Fixed
- `derivation` dropped the second column of a childless node's label
- Errors in a label split by a raw space now name the actual cause
- Hex colours accept three or six digits only

## [1.13.2] - 2026-08-27

### Fixed
- Movement paths drawn as one stroke with rounded corners
- Digits drawn in a colour emoji font on systems that have one

## [1.13.1] - 2026-08-27

### Fixed
- `^` on a leaf's own text (`[NP ^cats]`) draws a triangle, as `[^NP cats]` does
- Options given as empty strings treated as not given (fixes the web UI's Download buttons)

## [1.13.0] - 2026-08-24

### Added
- `derivation`: one rule across each node's daughters, with rule names (CCG style with `direction: btt`)
- `direction: btt`: bottom-to-top layout

### Fixed
- Connectors in bottom-to-top layout

## [1.12.0] - 2026-08-22

### Added
- `--examples` prints every gallery example with its options
- `llms.txt` and `llms-full.txt` on the documentation site
- Error messages point to the notation reference

### Changed
- Recommended angle brackets are U+27E8/U+27E9 (U+3008/U+3009 still parse)
- Two feature-structure figures redrawn with the narrower bracket

### Fixed
- `--notation` and `--examples` no longer wait on stdin

## [1.11.0] - 2026-08-21

### Added
- `--validate`: check input without drawing (JSON diagnosis on stdout, verdict in the exit code)
- `--notation`: short notation reference, shipped with the gem
- Errors carry a code, location, one-line fix and retryable flag
- A label may be a matrix alone (`[#(HEAD\tnoun#)]`)
- `-f tikz` in the CLI; TikZ output carries the line width
- Gallery figure for levelling terminals with `<>` joints

### Changed
- Line width relative to font size (`0.5`–`3.0`, `1` = 5% of the font size); figures about a fifth lighter
- On/off options accept every spelling of off (`no`, `0`, …)
- Option values validated in the library, not only in the CLI
- Colour names checked against the CSS colour names
- Penn Treebank conversion in the library
- Minimum font size 6

### Fixed
- Validation passed input that drawing then refused
- Malformed colour reported as an unclosed enclosure
- Matrix brackets over attribute names in left-to-right trees
- Crash on text before a tree; empty argument read as a path
- Documentation said overline was missing from PNG output

## [1.10.0] - 2026-08-19

### Deprecated
- JPG and GIF output (removed in 2.0)

### Changed
- RMagick loaded only when JPG or GIF is requested

### Fixed
- `FrozenError` when raising `RSTError` with a string literal

## [1.9.0] - 2026-08-19

### Added
- `hyphen: literal`: a bare hyphen is a hyphen and `\-…\-` underlines
- Nested matrices with `#(` … `#)`
- `\t` splits a label into aligned columns, for attribute-value matrices
- `color: gray` (or `grey`): black labels with grey connectors and paths
- Gallery examples for LFG and DRT
- Gallery figures scaled by their own width and loaded lazily, each with an anchor

### Changed
- Boxes and circles drawn at one size on one centre line
- SVG width and height match the viewBox

### Fixed
- TikZ export dropped the contents of nested matrices
- LSIF records the hyphen mode
- A one-ended line connection raised `NoMethodError`
- Line connections anchored to the facing box edges, with arrowheads sized to the link
- Nodes joined by a line connection spaced for a full-size arrowhead

## [1.8.2] - 2026-08-17

### Changed
- `tidy: high` compresses further than `medium`
- Mathematical alphanumerics (U+1D400–) named in the font chains; serif trees use a serif source

### Fixed
- CLI errors go to stderr with exit status 1
- `Noto Sans Mono SemiCondensed` removed from the mono chain

## [1.8.1] - 2026-08-15

### Fixed
- Arabic drawn as unjoined letterforms on some systems
- Emoji measured and drawn with different fonts where a colour emoji font was installed

### Changed
- Font chains name Arabic, Hebrew, Devanagari, Thai and Khmer families
- Docker images install Noto fonts for those scripts, with a fontconfig rule for Noto Sans Math
- Documentation on overriding font families with fontconfig

## [1.8.0] - 2026-08-15

### Added
- `tidy` layout scale: `symmetric` | `off` | `low` | `medium` | `high`
- `mirror` option for right-to-left trees
- `hspacing` option for horizontal gaps
- Pass-through `<>` nodes for levelling leaves
- CJK coverage in every font style
- Gallery: Multilingual and Morphology categories
- CI on GitHub Actions (Ruby 3.2/3.4)

### Changed
- LSIF records `geometry.mirror` and the layout settings in `meta.source.params`
- `symmetrize` (`-y`) and `tidy_spacing` deprecated
- `-d` is `--direction` (it had been taken by `--hide-default-connectors`)
- Font files no longer bundled; fonts resolve through fontconfig; `--font` removed

### Fixed
- Boolean options left at their defaults misread as on with a partial parameter set

## [1.7.0] - 2026-08-13

### Changed
- Text measured with Pango instead of RMagick (fixes off-centre Khmer labels, #14)
- Line height fixed at 1.4 × font size for every script
- Font family lists defined in one place

### Added
- Runtime dependency on the `pango` gem

## [1.6.3] - 2026-07-19

### Fixed
- Packaged files no longer carry owner-only permissions

## [1.6.2] - 2026-06-26

### Fixed
- Region shade no longer touches the image edge

## [1.6.1] - 2026-06-26

### Improved
- Cleaner padding and connector clearance around region shades

### Added
- Example 065: nested region shades

## [1.6.0] - 2026-06-25

### Added
- Region shade (`%` prefix), coloured with `%@color:`
- Region shade in TikZ export and in LSIF (`style.region`)
- `\%` for a literal leading percent sign
- Straight apostrophes drawn as curly apostrophes (`’`)
- Example 064: region shade for a c-command domain

### Changed
- LSIF version 0.3.0

### Fixed
- Region shade on the root clipped by the canvas

## [1.5.0] - 2026-04-06

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

## [1.4.0] - 2026-01-06

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

## [1.3.2] - 2025-03-03

- Garbage collection friendly implementation

## [1.3.1] - 2024-10-24

- Square brackets can be escaped with `\[` and `\]`
- Bug fixes and improvements

## [1.3.0] - 2024-08-27

- TikZ/forest LaTeX output support

## Earlier releases (2018–2023)

Before this file was kept, the web interface carried the release notes. Moved
here so the history has one home.

- 2023-09 — Cross-hatch rendering issue fixed
- 2023-02 — PDF download; improved line edges; `Line width` option;
  `Traditional` colour option; `Hide connectors` option; extra connectors
  between nodes
- 2023-01 — `Noto Sans Mono` font option
- 2022-11 — `¥` accepted in place of the backslash for escapes; documentation
  in Japanese
- 2022-06 — RSyntaxTree on the Web: the UI as a source package, runnable
  locally with Docker
- 2022-02 — `Polyline connector` option
- 2022-01 — comprehensive rewrite; path drawing (non-directional, directional,
  bidirectional); more flexible text markup; new markup patterns (newlines,
  brackets, horizontal lines, boxed text); triangles in every connector mode;
  improved error display and image zoom in the UI
- 2021-12 — subscript `_text_` and superscript `__text__`; `\n` inside
  terminal nodes
- 2021-11 — label-less terminal nodes (`[A [B] [C]]`); auto bracket close;
  math symbol rendering; better image quality; some decoration symbols altered
- 2019-11 — SVG download error fixed
- 2019-04 — SVG colour on/off fixed
- 2018-06 — whitespace in labels with `<>` (`Modal<>AUX`)
- 2018-03 — `V spacing` option (then called Connector height); syntax
  highlighting of the input; text styles (italic, bold) and decoration
  (underline, overline, line-through); refined site design
- 2018-02 — margins around the image; better editor (Ace)

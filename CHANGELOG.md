# Changelog

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

# Changelog

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
- The standalone `symmetrize` option and `-y` flag are deprecated aliases of
  `tidy: symmetric`; `tidy_spacing` is a deprecated alias of `hspacing`.
- `--direction` now owns the `-d` short flag (it had been auto-assigned to
  `--hide-default-connectors`, so the documented `-d ltr` silently did
  nothing).
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

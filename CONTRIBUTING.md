# Contributing to RSyntaxTree

This page explains how to report a problem, propose a change, and get a
development environment running.

## Reporting bugs

Open an issue at <https://github.com/yohasebe/rsyntaxtree/issues> with:

- the input text (the bracket notation) and the options you used
- what you expected and what you got — for drawing problems, attach the image
- your platform and how you run RSyntaxTree (gem, Docker, or the
  [web interface](https://yohasebe.com/rsyntaxtree))

If the input fails to draw, include the output of:

```bash
rsyntaxtree --validate "your input here"
```

It reports the problem in a structured form that is usually enough to
diagnose the issue.

## Suggesting features

Open an issue describing what you want to draw and, ideally, a hand-drawn or
published example of the intended output. The
[gallery](https://yohasebe.github.io/rsyntaxtree/examples) shows the range of
figures the notation covers today; a suggestion that names the linguistic
framework it serves is easier to evaluate than one described purely in terms
of graphics.

Not every good idea belongs in RSyntaxTree. The project deliberately keeps
the notation small, so proposals are weighed against what they add for
users who do not need them.

## Setting up for development

System libraries first (Pango for text measurement, librsvg for rasterizing):

```bash
# Debian/Ubuntu
apt install libpango1.0-dev librsvg2-dev libgirepository1.0-dev gobject-introspection

# macOS
brew install pkg-config pango librsvg gobject-introspection
```

The tests measure text with the Noto fonts, so install them too — the
[Fonts](https://yohasebe.github.io/rsyntaxtree/documentation#fonts) section
of the manual lists the package names for each platform.

Then:

```bash
git clone https://github.com/yohasebe/rsyntaxtree.git
cd rsyntaxtree
bundle install
bundle exec rake test
```

The tests should pass before and after your change.

## Making changes

- Every behavioral change needs a test that fails without it.
- The committed gallery figures are generated inside Docker
  (`rake docker_build && rake docker_generate`) so that font differences
  between machines do not rewrite them. Do not regenerate them with a local
  `rake generate`; if your change intentionally alters figures, say so in
  the pull request and the maintainer will regenerate them.
- The manual lives in `docs/documentation.md` (English) and
  `docs/documentation_ja.md` (Japanese). If your change affects the
  notation or an option, update at least the English manual; the reference
  the gem installs (`lib/rsyntaxtree/notation_core.md`) and the LLM payload
  (`rake llm_payload`) must be regenerated when examples or the manual
  change — the test suite tells you when they are stale.

## Pull requests

Fork, branch, and open a pull request against `master`. A good pull request
explains the problem before the solution and stays small enough to review.
CI runs the test suite on Linux and an installation check on macOS; both
must pass.

## Questions

For anything that does not fit an issue, contact the maintainer:
Yoichiro Hasebe <yohasebe@gmail.com>.

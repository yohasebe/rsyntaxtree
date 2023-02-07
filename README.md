<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree.png?raw=true' style='width: 256px;' />

**RSyntaxTree** is a graphical syntax tree generator written in the Ruby programming language. 

## Documentation

Documentation is currently available in the following languages:

- [Documentation in English](https://yohasebe.github.io/rsyntaxtree/documentation)
- [日本語ドキュメント](https://yohasebe.github.io/rsyntaxtree/documentation_ja)

- [Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples)
## Web Interface

<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree-web-screenshot.png?raw=true' width='700px'/>

See updates and a working web interface available at <https://yohasebe.com/rsyntaxtree>.

You can run RSyntaxTree's web interface on your local machine using Docker Desktop. See [RSyntaxTree Web UI](https://github.com/yohasebe/rsyntaxtree_web)

## Examples

See [RSyntaxTree Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples) page for examples for

- Generative Grammar
- Combinatory Categorial Grammar
- Head-Driven Phrase Structure Grammar
- Cognitive Grammar
- Construction Grammar
- Pragmatics
- Phonology
- etc.

**NOTE**: Some tree structures in the example gallery are experimental in the sense that they are not drawn according to conventions of the field.

**Input text**

```text
[S
  [NP |R|<>SyntaxTree]
  [VP
    [V generates]
    [NP
      [Adj #\+multilingual\
            \+beautiful]
      [NP syntax\
          trees]
    ]
  ]
]
```

**Output (PNG or SVG)**

<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/sample.png?raw=true' width='600' />

## Installation

`# gem install rsyntaxtree`

## Usage

For the web interface, see Usage section of <https://yohasebe.com/rsyntaxtree>.

For the command-line interface, type `$rsyntaxtree -h` after installation. Here's what you get:

```text
RSyntaxTree, (linguistic) syntax tree generator written in Ruby.

Usage:
       1) rsyntaxtree [options] "[VP [VP [V set] [NP bracket notation]] [ADV here]]"
       2) rsyntaxtree [options] "/path/to/text/file"
where [options] are:
  -o, --outdir=<s>                     Output directory (default: ./)
  -f, --format=<s>                     Output format: png, gif, jpg, pdf, or svg (default: png)
  -l, --leafstyle=<s>                  visual style of tree leaves: auto, triangle, bar, or nothing (default: auto)
  -n, --fontstyle=<s>                  Font style (available when ttf font is specified): sans, serif, cjk, mono (default: sans)
  -t, --font=<s>                       Path to a ttf font used to generate tree (optional)
  -s, --fontsize=<i>                   Size: 8-26 (default: 16)
  -i, --linewidth=<i>                  Size: 1-5 (default: 1)
  -v, --vheight=<f>                    Connector Height: 0.5-5.0 (default: 2.0)
  -c, --color=<s>                      Color text and bars: modern, traditional, or off (default: modern)
  -y, --symmetrize=<s>                 Generate radically symmetrical, balanced tree: on or off (default: off)
  -r, --transparent=<s>                Make background transparent: on or off (default: off)
  -p, --polyline=<s>                   draw polyline connectors: on or off (default: off)
  -d, --hide-default-connectors=<s>    make default connectors transparent: on or off (default: off)
  -h, --help                           This is a custom help message
  -e, --version                        Print version and exit
```

See the [documentation](https://yohasebe.github.io/rsyntaxtree/documentation) for more detailed info about the syntax.

## References

Please use the following BibTeX entry when referring to RSyntaxTree.

```
@misc{rsyntaxtree_2023,
  author = {Yoichiro Hasebe},
  title = {RSyntaxTree: A graphical syntax tree image generator}
  url = {https://yohasebe.com/rsyntaxtree},
  year = {2023}
}
```

## Development

For the latest updates and downloads please visit <http://github.com/yohasebe/rsyntaxtree>

## Author

Yoichiro Hasebe <yohasebe@gmail.com>

## License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).


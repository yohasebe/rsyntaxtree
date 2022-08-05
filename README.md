<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree.png?raw=true' style='width: 256px;' />

**RSyntaxTree** is a graphical syntax tree generator written in the Ruby programming language. 

---

### Web Interface

<img src='https://github.com/yohasebe/rsyntaxtree/blob/master/img/rsyntaxtree-web-screenshot.png?raw=true' width='700px'/>

See updates and a working web interface available at <https://yohasebe.com/rsyntaxtree>.

> You can run RSyntaxTree's web interface on your local machine using Docker Desktop. See [RSyntaxTree Web UI](https://github.com/yohasebe/rsyntaxtree_web)

---

### Installation

`# gem install rsyntaxtree`

---

### Usage

For the web interface, see Usage section of <https://yohasebe.com/rsyntaxtree>.

For the command-line interface, type `$rsyntaxtree -h` after installation. Here's what you get:

```text
RSyntaxTree, (linguistic) syntax tree generator written in Ruby.

Usage:
       rsyntaxtree [options] "[VP [VP [V set] [NP bracket notation]] [ADV here]]"
where [options] are:
  -o, --outdir=<s>         Output directory (default: ./)
  -f, --format=<s>         Output format: png, gif, jpg, pdf, or svg (default: png)
  -l, --leafstyle=<s>      visual style of tree leaves: auto, triangle, bar, or nothing (default: auto)
  -n, --fontstyle=<s>      Font style (available when ttf font is specified): sans, serif, cjk (default: sans)
  -t, --font=<s>           Path to a ttf font used to generate tree (optional)
  -s, --fontsize=<i>       Size: 8-26 (default: 16)
  -m, --margin=<i>         Margin: 0-10 (default: 1)
  -v, --vheight=<f>        Connector Height: 0.5-5.0 (default: 2.0)
  -c, --color=<s>          Color text and bars: on or off (default: on)
  -y, --symmetrize=<s>     Generate radically symmetrical, balanced tree: on or off (default: off)
  -r, --transparent=<s>    Make background transparent: on or off (default: off)
  -p, --polyline=<s>       draw polyline connectors: on or off (default: off)
  -e, --version            Print version and exit
  -h, --help               Show this message```
```

See [the documentation](https://yohasebe.com/rsyntaxtree/#documentation) for more detailed info about the syntax.

---

### Examples

See [RSyntaxTree Examples](https://yohasebe.github.io/rsyntaxtree/examples).

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

---

### Development

For the latest updates and downloads please visit <http://github.com/yohasebe/rsyntaxtree>

---

### Author

Yoichiro Hasebe <yohasebe@gmail.com>

---

### License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).


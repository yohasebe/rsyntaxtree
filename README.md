# RSyntaxTree: yet another syntax tree generator in Ruby

**RSyntaxTree** is a graphical syntax tree generator written in the Ruby programming language inspired by [phpSyntaxTree](http://ironcreek.net/phpsyntaxtree/). 

### Web Interface

See updates and a working web interface available at <https://yohasebe.com/rsyntaxtree>.

### Installation

`# gem install rsyntaxtree`

### Usage

For the web interface, see Usage section of <https://yohasebe.com/rsyntaxtree>.

For the command-line interface, type `$rsyntaxtree -h` after installation. Here's what you get:

```text
RSyntaxTree, (linguistic) syntax tree generator written in Ruby.

Usage:
       rsyntaxtree [options] "[VP [VP [V set] [NP bracket notation]] [ADV here]]"
where [options] are:
      -o, --outdir=<s>        Output directory (default: ./)
      -f, --format=<s>        Output format: png, pdf, or svg (default: png)
      -l, --leafstyle=<s>     visual style of tree leaves: auto, triangle, bar, or nothing (default: auto)
      -n, --fontstyle=<s>     Font style: sans, serif, cjk, math (default: sans)
      -t, --font=<s>          Path to a ttf font used to generate tree (optional)
      -s, --fontsize=<i>      Size: 8-26 (default: 16)
      -c, --color=<s>         Color text and bars: on or off (default: on)
      -y, --symmetrize=<s>    Generate symmetrical, balanced tree: on or off (default: on)
      -a, --autosub=<s>       Put subscript numbers to nodes: on or off (default: off)
      -m, --margin=<i>        Margin: 0-120 (default: 0)
      -v, --vheight=<f>       Connector Height: 0.5-2.0 (default: 1.0)
      -e, --version           Print version and exit
      -h, --help              Show this message
```

### Tips

Every branch or leaf of a tree must belong to a node. To create a node, place a label right next to the opening bracket. Arbitrary number of branches can follow with a preceding space.

There are several modes in which the connectors between terminal nodes and their leaves are drawn differently (auto, triangle, bar, and nothing). In auto mode, a triangle is used if the leaf contains one or more spaces inside (i.e. if it&#8217;s a phrase), but if it contains no spaces (i.e. if it is just a word), a straight bar will be drawn instead (unless the leaf contains a "^" symbol at the end which makes it a single-word phrase).

You can put a subscript to any node by putting the _ character between the main label and the subscript. For example, NP_TOP will be rendered as NP<sub>TOP</sub>. Or you can select the &#8220;Auto subscript&#8221; option so that nodes of the same label will be automatically numbered. (e.g. NP<sub>1</sub>, NP<sub>2</sub>)</p>

See https://yohasebe.com/rsyntaxtree for more detailed info about the syntax.

### Example

Bracket notation (auto-subscript-on):

```text
[S [NP RSyntaxTree^][VP [V generates][NP [Adj multilingual] [NP syntax trees]]]]
```

Resulting PNG

![RSyntaxTree generates multilingual syntax trees](https://i.gyazo.com/6bb68b0bdb35d7a10c4a11d5788d484f.png)

### Development

For the latest updates and downloads please visit http://github.com/yohasebe/rsyntaxtree

### Author

Yoichiro Hasebe <yohasebe@gmail.com>

### License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).


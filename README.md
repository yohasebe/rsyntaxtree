# RSyntaxTree: yet another syntax tree generator in Ruby

RSyntaxTree is a graphical syntax tree generator written in the Ruby programming language. It is basically a port of  [phpSyntaxTree](http://ironcreek.net/phpsyntaxtree/) created by André Eisenbach.

While phpSyntaxTree does not accept **multi-byte characters** as those in Chinese, Japanese, and Korean, RSyntaxTree handles text of any language as long as encoded in UTF-8 and fonts have been installed. Additionally, RSyntaxTree can output **symmetrized** tree diagrams, a functionality that is not implemented in phpSyntaxTree.

RSyntaxTree consists of an easy-to-use command-line app and a web-based interface made with  [Sinatra](http://www.sinatrarb.com) web framework.

### Web Interface

Working web interface of a previous version of RSyntaxTree is available at http://yohasebe.com/rsyntaxtree .  New version will be deployed soon.

### Installation

`# gem install rsyntaxtree`

### Usage

For the web interface, see Usage section in http://yohasebe.com/rsyntaxtree .

For the command-line interface, type `$rsyntaxtree -h` after installation. Here's what you get:
    
    RSyntaxTree, (linguistic) syntax tree generator written in Ruby.
    
    Usage:
           rsyntaxtree [options] "[VP [VP [V set] [NP bracket notation]] [ADV here]]"
    where [options] are:
          --outdir, -o <s>:   Output directory (default: present working directory) (default: ./)
          --format, -f <s>:   Output format: png, pdf, or svg (default: png)
       --leafstyle, -l <s>:   visual style of tree leaves: triangle, bar, or nothing (default: triangle)
       --fontstyle, -n <s>:   Font style: sans-serif, serif, jp-gothic, jp-mincho, cjk (default: cjk)
            --font, -t <s>:   Path to a ttf font used to generate tree
        --fontsize, -s <i>:   Font size: 8-20 (default: 16)
           --color, -c <s>:   Color text and bars: on or off (default: on)
      --symmetrize, -y <s>:   Generate symmetrical, balanced tree: on or off (default: on)
         --autosub, -a <s>:   Put subscript numbers to nodes: on or off (default: off)
             --version, -v:   Print version and exit
                --help, -h:   Show this message

### Tips

Every branch or leaf of a tree must belong to a node. To create a node, place a label right next to the opening bracket. Arbitrary number of branches can follow with a preceding space. When a node has one and only one leaf and the leaf contains more than one space characters, the node is treated as a phrase and a triangle (not just a vertical bar) will be between the node label and the leaf).

You can put a subscript to any node by putting the _ character between the main label and the subscript. For example, NP_TOP will be rendered as NP<sub>TOP</sub>. Or you can select the &#8220;Auto subscript&#8221; option so that nodes of the same label will be automatically numbered. (e.g. NP<sub>1</sub>, NP<sub>2</sub>)</p>

### Example

Bracket notation (auto-subscript-on):

    [NP [NP [ART a] [N table]] [PP [P near] [NP [ART the] [N door]]]]

Resulting PNG

![a table near the door](http://yohasebe.com/img/rsyntaxtree_example.png)

### Development

For the latest updates and downloads please visit http://github.com/yohasebe/rsyntaxtree

### Author

Yoichiro Hasebe yohasebe@gmail.com

### License

RSyntaxTree is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).


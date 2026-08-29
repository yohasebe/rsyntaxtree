---
title: RSyntaxTree
layout: default
---

# ドキュメンテーション
{:.no_toc}

[English](https://yohasebe.github.io/rsyntaxtree/documentation) | 
[日本語](https://yohasebe.github.io/rsyntaxtree/documentation_ja) | 
[Changelog](https://yohasebe.github.io/rsyntaxtree/changelog)

### 目次
{:.no_toc}

1. toc
{:toc}

### 基本的な使い方

エディターエリアにラベル付き括弧表記でテキストを入力し，`Draw PNG`または`Draw SVG`ボタンをクリックします．

樹形図のすべてのブランチ（枝）やリーフ（葉）は，ノード（節点）に属します．ノードを作成するには，ラベルテキストを開始括弧の直後に配置します．ブランチは，空白で区切っていくつでも設定できます．リーフのテキストに1つ以上の空白が含まれているとき，空白はそのまま表示されます．ノードのラベルに空白を含めたいときには `<>` 記号を使って表します．例えば `Modal<>Aux` とすれば `Modal Aux` と表示されます．

終端ノードとリーフの間に何を描くかは `コネクタ形状`（`leafstyle`，CLI では `--leafstyle`）オプションで選びます．3種の設定については[コネクター](#コネクター)を参照してください．どれを選んだ場合も，`コネクタを隠す` オプションをオンにすればコネクターを非表示（透明）にできます．

ノードを表すテキストやリーフを表すテキストの中で改行を行たい場合，改行文字 `\n` を用いることができます（`\`の後にスペースまたは改行でも可）．

RSyntaxTreeではPNG形式またはSVG形式で画像を生成します．どちらもMicrosoft Wordで作った書類などに貼り付けることができます．PNG形式の方が一般的ですが，SVG形式の画像は拡大しても描画品質が変わらないため，高品質なグラフィックが必要な場合に便利です．SVG形式の画像は，Adobe Illustratorや[BOXY SVG](https://boxy-svg.com/) などのソフトウェアで読み込んで編集することができます．その他、PDF形式の画像をダウンロードすることも可能です。

`フォント` ， `サイズ` ，`縦間隔` ，`カラー`  の各オプションについては説明の必要はないでしょう．これらのオプションの値を変更することで，樹形図の外観を変えることができます．

`カラー` には，ノードとリーフのラベルに色をつける `Modern`・`Traditional`，すべて黒で描く `なし` のほかに，`線を灰色に` があります．これはラベルを黒のまま残し，コネクタと移動パスだけを灰色で描くものです．

`線幅`（`linewidth`，CLI では `--linewidth`）は，コネクタ・括弧・囲みなど図中のすべての線の太さを，文字サイズに対する比で指定します．`1` は文字サイズの5%（本文の罫線と同じ太さ）で，0.5 刻みで 2.5% ずつ増え，`0.5`（最細）から `3.0`（15%，最太）まで選べます．線は文字サイズに追随するため，どの文字サイズでも文字と線の釣り合いが変わりません．

<div class="grid {{ site.data.doc_figure_sizes['doc-532ffe07'].layout }}" markdown="1">

```text
[S
  [NP
    [D The]
    [N cat]
  ]
  [VP
    [V sat]
    [PP
      [P on]
      [NP
        [D the]
        [N mat]
      ]
    ]
  ]
]
```

{% include doc_figure.html name="doc-532ffe07" alt="ラベル付き括弧表記から描かれた樹形図" %}

</div>

### 記法の一覧

この記法で描けるものを 1 行ずつ、説明のある節への案内つきで挙げます。
サンプルは生きています。テストがそれぞれを実際に描くので、機能より長生きする
行はここにはありません。

**構造**

- `[S [NP the cat] [VP sat]]` — ノードとその子 → [基本的な使い方](#基本的な使い方)
- `(S (NP the cat) (VP sat))` — Penn Treebank 形式。自動で変換されます → [Penn Treebank形式](#penn-treebank形式)
- `^cats` — リーフ 1 語に三角を強制（空白を含むリーフは自動で三角）→ [コネクター](#コネクター)
- ラベルが `<>` だけのノード — 不可視の中継点。終端の高さを揃える → [終端の高さを揃える](#終端の高さを揃える)
- 2 つのノードに `+1`、矢じり側に `+>1` — 移動パス → [パスの描画](#ノードからノードへのパスの描画)
- `+-1`、矢じりは `+->1` — 追加の直線コネクタ → [追加的なコネクター](#ノードからノードへの追加的なコネクターの描画)

**ラベルの中**

- `*x*`、`**x**`、`***x***` — イタリック・ボールド・両方 → [テキストの描画](#テキストの描画)
- `x_i_`、`x__2__` — 下付き・上付き → [上付き文字と下付き文字](#上付き文字と下付き文字)
- `H___EAD___` — スモールキャピタル → [スモールキャピタル](#スモールキャピタル)
- `=x=`、`-x-`、`~x~` — 上線・下線・取り消し線 → [テキスト装飾](#テキスト装飾)
- `\n`（または行末のバックスラッシュ）— 改行。2 つ続けると空行 → [改行](#改行)
- `\t` — 桁。ラベル全体で位置が揃います → [桁揃え](#桁揃え)
- 単独の行の `---` — ラベルを横切る罫。`===` は二重罫 → [水平線](#水平線)
- `|1|`、`{2}` — 四角囲み・丸囲み（2 文字以上はカプセル型）→ [ボックス・サークル・水平線・矢印](#ボックスサークル水平線矢印)
- `||`、`{}`、`|/|`、`{/}` — 空・斜線入りの四角と丸 → [ボックス・サークル・水平線・矢印](#ボックスサークル水平線矢印)
- `--`、`->`、`<-`、`<->` — 記号としての線と矢印。`*...*` で太く（例 `*->*`）→ [ボックス・サークル・水平線・矢印](#ボックスサークル水平線矢印)

**ラベルの外**

- `#NP`、`##NP`、`###NP` — 角括弧・矩形・太い矩形の囲み → [括弧と矩形](#リーフを囲む括弧と矩形の描画)
- `#(HEAD\tnoun#)` — 値としての素性行列。何段でも入れ子に → [行列の入れ子](#行列の入れ子)
- `[#(CAT\tS#) ...]` — ラベル全体が 1 つの行列 → [素性構造](#素性構造)
- `%NP`、`%@blue:NP` — 部分木の背後の領域シェード → [領域シェード](#領域シェード)
- `@red:NP`、`@#3af:NP` — 色。名前か 16 進 3 桁/6 桁 → [ノードごとの色指定](#ノードごとの色指定)

**オプション** — いずれも [Web インターフェイス](https://yohasebe.com/rsyntaxtree)の項目であり、コマンドラインのフラグでもあります: `format`（png・svg・pdf ほか）、`fontstyle` と `fontsize`、`color`、`linewidth`、`leafstyle`（ノードとリーフの間に何を描くか）、`direction`（ttb・ltr・btt）、RTL 用の `mirror`、詰め方と間隔の `tidy`・`hspacing`・`vheight`、直角のコネクタにする `polyline`、既定のコネクタを引かない `hide_default_connectors`、背景を塗らない `transparent`、圏論的な図のための `derivation`、`hyphen`（ハイフンをマークアップと読むか文字と読むか）、そして仕上がった図を傾ける `shear` と `shear_plane`。図全体が指定の角度（度数、正で上辺が右）だけ傾き、背後に平面が敷かれるので、傾きは誤りではなく面を斜めから見た図として読めます。`shear_plane` はその平面を消すか、色を与えます。詳細はそれぞれの節にあります。

### ツリーの方向

`方向`（`direction`，CLI では `--direction`）オプションでツリーのレイアウト方向を制御できます：

- **上から下** (`ttb`)：デフォルト．ルートノードが上，リーフが下に配置されます．
- **左から右** (`ltr`)：ルートノードが左，リーフが右に展開されます．分類ツリーや階層構造を横方向に表示したい場合に便利です．
- **下から上** (`btt`)：リーフが上，ルートが下に配置されます．語が先で結果が最後という導出の書き方です．[導出図](#導出図)を参照してください．

左から右のモードでは，コネクタ，三角形，移動パス，ノード間直線接続のすべてが水平方向に適応されます．`縦間隔` オプションは LTR モードではツリーのレベル間の水平距離を制御します．

<div class="grid {{ site.data.doc_figure_sizes['doc-8671daca'].layout }}" markdown="1">

<!-- figure: direction=ltr -->
```text
[Noun
  [Common
    [Count *cat*]
    [Mass *water*]
  ]
  [Proper *Tokyo*]
]
```

{% include doc_figure.html name="doc-8671daca" alt="同じ構造を左から右へ展開した図" %}

</div>

### Tidy レイアウト

`Tidy レイアウト` オプション（`tidy`，CLI では `--tidy`）はレイアウト方式を選ぶオプションで，最も広いものから最も密なものまで一つの尺度になっています：

- **Symmetric**（`symmetric`）：radical symmetrization．すべての部分木を均等なスロットの中央に配置し，幅は広いものの完全に左右対称な図になります．言語学の樹形図を作成する際は通常は使用しません。
- **オフ**（`off`）：最も基本的なレイアウトです。バランスが良くないと感じる場合は、いずれかのTidyレイアウトオプションを選択してください。
- **Low**（`low`）：隣り合う部分木の輪郭の間に余白がある場合，互いに引き寄せて幅を詰めます．すべてのリーフの左右位置＝語順は図全体で厳密に保たれます。
- **Medium**（`medium`）：浅い部分木を隣の深い部分木の上の空白に入れ込んで，さらに圧縮します（例：指定部の NP が主要部側に寄る）．2つのリーフの左右順序が入れ替わることはありません。
- **High**（`high`）：入れ込みを制限なく行う最も密なオプションです，幅が詰まるならレベル間で枝の角度が大きく食い違うことも許容します．リーフの順序保証は同じ段の中のみに限定されるので、文の線形順序が図の中の表示の水平軸において、部分的に入れ替わることがあり得ます。

同じ木を 5 つの設定で描いたものです．段階を追って幅が詰まります．最後の 2 つは差が
最も分かりにくいので横に並べました．`high` は *sell* を名詞側に寄せ，`medium` は枝の
位置のまま残します．

<div class="grid grid-figures" markdown="1">

<!-- figure: tidy=symmetric | tidy=off | tidy=low | tidy=medium | tidy=high -->
```text
[S
  [NP
    [AP
      [Deg less]
      [A expensive]
    ]
    [N electric\-cars]
  ]
  [V sell]
]
```

{% include doc_figure.html name="doc-23080864" alt="Tidy symmetric の木" %}
Symmetric

<div class="figure-break"></div>

{% include doc_figure.html name="doc-6c1c9fed" alt="Tidy オフの木" %}
オフ

{% include doc_figure.html name="doc-84af9266" alt="Tidy low の木" %}
Low

<div class="figure-break"></div>

{% include doc_figure.html name="doc-daf326ff" alt="Tidy medium の木" %}
Medium

{% include doc_figure.html name="doc-1471e588" alt="Tidy high の木" %}
High

</div>

`high` の効果が得られるのは深く偏った木に限定され，均整のとれた木では `medium` と大差ない結果になることもあります．通常の用途は `off`・`low`・`medium` で足ります．

Tidy モードではコネクタの高さも自動調整されます．`横間隔`（`hspacing`，デフォルト 1.0，目安 0.5〜3.0）と`縦間隔`（`vheight`）はそれぞれ横方向と縦方向の間隔倍率で，tidy の有無に関わらずすべてのレイアウトモードで有効です．

### RTL 文字体系のための鏡像レイアウト

アラビア語やヘブライ語など右から左に書く文字体系のため，樹形図を右から左に展開させることができます．`左右反転（RTL）` オプション（`mirror: on`，CLI では `--mirror`）は，レイアウト確定後の樹全体を水平方向に反転します．構造は変わらず，リーフの並び順だけが逆転して，文が自然な方向に読めるようになります．

`左右反転（RTL）` は `方向` と組み合わせられます．

<div class="grid {{ site.data.doc_figure_sizes['doc-02bc5fec'].layout }}" markdown="1">

<!-- figure: mirror=on vheight=1.0 -->
```text
[S
  [NP الطالب]
  [VP
    [V قرأ]
    [NP الكتاب]
  ]
]
```

{% include doc_figure.html name="doc-02bc5fec" alt="反転した木．アラビア語の文が右から左に読める" %}

</div>

### フォント

図は 3 種類の書体のいずれかで描かれます．`フォント` で選びます．

- `Noto Sans`（`sans`）：ラテン文字と基本的なUnicode文字をゴシック体に近い書体で表示します．
- `Noto Serif`（`serif`）：同じ範囲を明朝体に近い書体で表示します．
- `Noto Sans Mono`（`mono`）：同じ範囲を等幅の書体で表示します．

いずれも漢字・ハングル・かなは Noto CJK にフォールバックするため，どれを選んでも
CJK のテキストを描画できます．

同じ木を 3 種類の書体で描いたものです．

<div class="grid grid-figures" markdown="1">

<!-- figure: fontstyle=sans | fontstyle=serif | fontstyle=mono -->
```text
[Digits
  [Even 02468]
  [Odd 13579]
]
```

{% include doc_figure.html name="doc-695a9afc" alt="Noto Sans で組んだ木" %}
Sans

{% include doc_figure.html name="doc-9171f7d9" alt="Noto Serif で組んだ木" %}
Serif

{% include doc_figure.html name="doc-91363c37" alt="Noto Sans Mono で組んだ木" %}
Mono

</div>

どの機械にフォントが要るかは形式によって変わります．PNG・PDF はこちらで
描いて絵として届くので，見るだけなら何も導入する必要はありません．SVG は字形ではなく
書体の名前を持ち運び，開いた側がそれを用意します．そのため下記のフォントが無い機械では
別の書体で代替され，文字の釣り合いをやや欠いた表示になります．

- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans): ラテン文字と基本的なUnicode文字（サンセリフ）の表示
- [Noto Sans JP](https://fonts.google.com/noto/specimen/Noto+Sans+JP): 日本語のひらがな／カタカナ／漢字（サンセリフ）の表示
- [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif): ラテン文字と基本的なUnicode文字（セリフ） の表示
- [Noto Serif JP](https://fonts.google.com/noto/specimen/Noto+Serif+JP):日本語のひらがな／カタカナ／漢字（セリフ）の表示
- [Noto Sans CJK / Noto Serif CJK](https://github.com/notofonts/noto-cjk): ハングルや簡体字を含む CJK 全域の表示（上記の JP のフォントは日本語のみ）
- [Noto Emoji](https://fonts.google.com/noto/specimen/Noto+Emoji): 絵文字の表示（モノクロ版．カラー絵文字フォントは PNG／PDF の描画経路では出力されません）

### テキストの描画

フォントのスタイルとしてイタリック／ボールド／ボールド+イタリックを指定できます．テキスト装飾としては，上線，下線，取り消し線を指定できます．また上付き文字と下付き文字を指定できます．これらは組み合わせて使用することもできます．

<div class="grid {{ site.data.doc_figure_sizes['doc-94889119'].layout }}" markdown="1">

<!-- figure: direction=ltr polyline=on leafstyle=bar -->
```text
[Styles
  [Emphasis *italic* **bold**]
  [Lines =overline= -underline- ~struck~]
  [Scripts X_i_ Y__j__]
]
```

{% include doc_figure.html name="doc-94889119" alt="文字装飾の一覧．左から右に，直角のコネクタで描いたもの" %}

</div>

#### フォント・スタイル

|Style      |Symbol      |Sample Input       |Output           |
|-----------|------------|-------------------|-----------------|
|Italic     |`*TEXT*`    |`*italic*`         |*italic*         |
|Bold       |`**TEXT**`  |`**bold**`         |**bold**         |
|Italic+bold|`***TEXT***`|`***italic bold***`|***italic bold***|

#### テキスト装飾

|Decoration  |Symbol  |Sample Input   |Output                                                       |
|------------|--------|---------------|-------------------------------------------------------------|
|Overline    |`=TEXT=`|`=overline=`   |<span style='text-decoration:overline'>overline</span>       |
|Underline   |`-TEXT-`|`-underline-`  |<span style='text-decoration:underline'>underline</span>     |
|Line-through|`~TEXT~`|`~linethrough~`|<span style='text-decoration:line-through'>linethrough</span>|

#### 上付き文字と下付き文字

|Sample Input           |Output                      |
|-----------------------|----------------------------|
|`normal_subscript_`    |normal<sub>subscript</sub>  |
|`normal__superscript__`|normal<sup>superscript</sup>|


### スペースと改行

#### ラベル内のスペース

|Sample Input|Output  |
|------------|--------|
|`X<>Y`      |X&nbsp;Y|

リーフのテキスト中の半角スペースはそのままスペースとして表示されます．`<>`は基本的にはラベル内でスペースを表示したいときに使いますが，リーフ内のテキストでも有効です．

なおラベルが `<>` **のみ**のノードは特別な使われ方をします．後述の[終端の高さを揃える](#終端の高さを揃える)を参照してください．

#### 終端の高さを揃える

ラベルが `<>` **のみ**のノードは不可視の中継点として描画され，コネクタの線は途切れずに貫通します．これを連ねると浅いリーフを下の段に送れるため，すべての終端要素を同じ高さに揃えたい場合に便利です．

<div class="grid {{ site.data.doc_figure_sizes['doc-e5062caa'].layout }}" markdown="1">

<!-- figure: vheight=0.6 -->
```text
[S
  [NP
    [D
      [<>
        [<> the]
      ]
    ]
    [N
      [<>
        [<> cat]
      ]
    ]
  ]
  [VP
    [V
      [<>
        [<> sat]
      ]
    ]
    [PP
      [P
        [<> on]
      ]
      [NP
        [D the]
        [N mat]
      ]
    ]
  ]
]
```

{% include doc_figure.html name="doc-e5062caa" alt="継手ですべての語を最下段に揃えた図" %}

</div>

中継点がなければ，*the*・*cat*・*sat* は *the*・*mat* より2段上に，*on* は1段上に浮きます．各リーフは最も深い段に届くのに必要な数だけ中継点を重ねるので，6語すべてが最下段に並びます．ギャラリーの [Terminals levelled with pass-through joints](https://yohasebe.github.io/rsyntaxtree/examples#example-080) の例をご覧ください．

#### 改行

ラベルの改行は 3 通りの書き方があり，どれも同じ意味です．行末のバックスラッシュ，
バックスラッシュと空白，そして `\n` です．2 つ続けると 1 行空きます．バックスラッシュは
エスケープ文字なので，文字としてのバックスラッシュは `\\` と書きます（[一部の文字を表示するためのエスケープ](#一部の文字を表示するためのエスケープ)を参照）．

|Sample Input                   |Output              |
|-------------------------------|--------------------|
|`str1\`<br />`str2`            |str1<br />str2      |
|`str1\`<br />`   \`<br />`str2`|str1<br /><br />str2|
|`str1\ str2`                   |str1<br />str2      |
|`str1\ \ str2`                 |str1<br /><br />str2|
|`str1\nstr2`                   |str1<br />str2      |
|`str1\n\nstr2`                 |str1<br /><br />str2|

### テキスト以外の要素の描画

テキストと組み合わせてサークル○，ボックス□，水平線などを描画することができます．
フォントが持つ文字であればラベルにそのまま書けます．絵文字も同様で，モノクロの
Noto Emoji で描かれるため，色は付かず輪郭で表示されます．

<div class="grid {{ site.data.doc_figure_sizes['doc-e31ee644'].layout }}" markdown="1">

```text
[Shapes
  [#Brackets |1| {2}]
  [##Rectangle {capsuled}]
  [Emoji 🌱 🐛 ✅]
]
```

{% include doc_figure.html name="doc-e31ee644" alt="四角と丸のタグ，括弧と矩形の囲み" %}

</div>

#### スモールキャピタル

HPSGなどの素性構造の素性名は慣例としてスモールキャピタルで組まれますが，これを見た目上、実現することができます（フォント自体はスモールキャピタルフォントを使いません）。大文字は通常通り表示し、スモールキャピタルの部分は `___` で囲んでください．例えば、`H___EAD___` と書くと，通常の大きさの H に続いて小さめの EAD が描かれます．

<div class="grid {{ site.data.doc_figure_sizes['doc-978d14e0'].layout }}" markdown="1">

```text
[#H___EAD___\tnoun\
  C___ASE___\tnom
  Kim
]
```

{% include doc_figure.html name="doc-978d14e0" alt="スモールキャピタル風に組まれた素性名" %}

</div>

#### ボックス・サークル・水平線・矢印

{% include box_and_circle_table.html %}

#### 水平線

|Sample Input                   |Output                |
|-------------------------------|----------------------|
|`str1\`<br />`---\`<br />`str2`|str1<br />——<br />str2|
|`str1\ ---\ str2`              |str1<br />——<br />str2|
|`str1\n---\nstr2`              |str1<br />——<br />str2|

ここで `---` は `-` の3つ以上の連続を意味します.

### コネクター

`コネクタ形状` では終端ノードとリーフの間に何を描くかを3種の中から選べます（`auto`，`bar`，`none`）．`auto` では，1つ以上の空白を含むリーフ（要するに「句」）に対しては終端ノードを頂点とした三角形を描画します．リーフが空白を含まない場合（つまり「単語」の場合)，垂直の直線が描かれます ．なお，リーフの先頭に `^` をつけると，そのリーフが句であると宣言することになります．したがって必ず三角形が描かれます．`^` はノードのラベルの先頭に置いても構いません．`[NP ^cats]` と `[^NP cats]` は同じ意味です． `bar` では，すべてのリーフに関して垂直の直線が描かれます． `none` では終端ノードとリーフの間にコネクターは描かれません．

<div class="grid {{ site.data.doc_figure_sizes['doc-c235812c'].layout }}" markdown="1">

```text
[S
  [NP a phrase]
  [VP
    [V word]
    [NP ^forced\-triangle]
  ]
]
```

{% include doc_figure.html name="doc-c235812c" alt="句には三角，単語には縦線．先頭の ^ で三角を指定した例" %}

</div>

### リーフを囲む括弧と矩形の描画

ラベルまたはリーフとなるテキストの最初に（`^` が存在する場合はその直後に） `#` を付けると，そのテキスト全体を角括弧（［ ］）で囲みます（例：`[#NP text]`, `[NP #text]`, `[NP ^#text]`）．

テキストの最初に `##` を付けると，テキスト全体を矩形（ボックス）で囲みます．

テキストの最初に `###` を付けると，テキスト全体を太い線の矩形（ボックス）で囲みます．

<div class="grid {{ site.data.doc_figure_sizes['doc-49f323a8'].layout }}" markdown="1">

<!-- figure: direction=ltr polyline=on leafstyle=bar -->
```text
[Enclosures
  [#Brackets one]
  [##Rectangle two]
  [###Bold three]
]
```

{% include doc_figure.html name="doc-49f323a8" alt="角括弧・矩形・太線の矩形" %}

</div>

### ノードごとの色指定

`@color:` プレフィックスを使用して，個々のノードにカスタムカラーを指定できます．色名とHEXカラーコードの両方がサポートされています．

|入力例|説明|
|------------|-----------|
|`@red:NP`|色名（赤）|
|`@blue:VP`|色名（青）|
|`@#FF5500:NP`|HEXカラーコード|
|`@#0A0:VP`|短縮形HEXカラーコード|

**マークアップの順序**：他のプレフィックスと組み合わせる場合は，次の順序を使用してください：`^`（三角形）→ `#`（囲み）→ `%`（領域シェード）→ `@color:`（色）

|入力例|説明|
|------------|-----------|
|`^@blue:NP`|三角形コネクター＋青色|
|`#@red:NP`|角括弧＋赤色|
|`^#@green:NP`|三角形＋角括弧＋緑色|

<div class="grid {{ site.data.doc_figure_sizes['doc-02b248ba'].layout }}" markdown="1">

```text
[S
  [@blue:NP
    [D the]
    [N @blue:dog]
  ]
  [@red:VP
    [V @red:chased]
    [NP a cat]
  ]
]
```

{% include doc_figure.html name="doc-02b248ba" alt="2 つのノードに個別の色を与えた図" %}

</div>

### 領域シェード

`#`，`##`，`###` が単一のノードラベルを囲むのに対し，領域シェードはあるノードが支配する**部分木全体**の背後に半透明の面（プレーン）を描きます．c-command 領域や束縛領域など，「範囲」を面で示したい場合に役立ちます．

ノードラベルの先頭（`^`/`#` がある場合はその直後）に `%` を付けます．面はそのノードと
その全子孫を含むバウンディングボックスを覆い，ツリーの線やラベルの背後に描かれます．
シェードの色は既存の `@color:` 記法をそのまま流用します．`%` 単独では薄いグレーに
なります．

|入力例|説明|
|------------|-----------|
|`%VP`|既定の薄いグレーの領域シェード|
|`%@yellow:VP`|黄色の領域シェード（色名）|
|`%@#ffcc00:VP`|HEX カラーの領域シェード|
|`%@yellow:@blue:VP`|黄色のシェード面**かつ**青色のノードラベル（2つの色は独立）|

各面には，塗りと同系色で少し濃いボーダーが描かれるため，白背景でも領域の境界が
明瞭に区別できます．明示的に指定したシェード色は（`@color:` の文字色と同様に）常に
尊重されます．白黒の図にしたい場合は，色付きのシェードではなく素の `%`（グレー）を
使ってください．

重なり合う（入れ子の）領域は，面が半透明なので自然に混色されます．領域シェードは
上下方向・左右方向（`-d ltr`）の両レイアウトで機能し，すべての出力タイプ（SVG，PNG，PDF）に適用されます．

<div class="grid {{ site.data.doc_figure_sizes['doc-0050a108'].layout }}" markdown="1">

```text
[S
  [%NP
    [D the]
    [N dog]
  ]
  [%@blue:VP
    [V chased]
    [%@red:NP a cat]
  ]
]
```

{% include doc_figure.html name="doc-0050a108" alt="2 つの部分木を網掛けし、一方に色を付けた図" %}

</div>

### 一部の文字を表示するためのエスケープ

文字装飾などのマークアップに使用される一部の文字をテキストとして表示するためには `\` によってエスケープする必要があります．使用している環境で `\` が使えない場合は `¥` で代用することができます．

{% include escape_char_table.html %}

**注意：** 単なる改行 `↩️` はスペースとして扱われます．`↩️` を1つ以上連続させた場合も1つのスペースとして扱われます．

テキスト中で改行したいときには，1） `\n`，2） `\↩️`，3） `\ + whitespace ` のいずれかを用いてください．そうすると出力される画像の中で改行 `↩️` が行われます．

**注意：** ラベル中の直線アポストロフィ（`'`）は，自動的にタイポグラフィ的な（曲線の）アポストロフィ `’` として描画されます．`T'` のような X-bar のプライムや、通常の文中のアポストロフィ（例：*John's*）にも適用されます．

### 素性構造

素性属性行列は，複数行のラベルを桁で切って，属性を片側に，値をもう片側に揃えて並べ，
全体を括弧で囲んだものです．そのための特別な記法があるわけではなく，どれも普通の
ラベルのマークアップで，一つ一つは単独でも使えます．

| 描きたいもの | 書き方 | 説明のある場所 |
|---|---|---|
| 行列を囲む括弧 | ラベルの先頭に `#` | [リーフを囲む括弧と矩形の描画](#リーフを囲む括弧と矩形の描画) |
| 属性と値の桁揃え | 間に `\t` | [桁揃え](#桁揃え) |
| 値としての行列 | `#(` … `#)` | [行列の入れ子](#行列の入れ子) |
| 構造共有のタグ | `|1|` | [ボックス・サークル・水平線・矢印](#ボックスサークル水平線矢印) |
| リストを囲む山括弧 | `⟨` と `⟩` をそのまま入力 | — |
| 素性名の中のハイフン | `ハイフン: literal` | [ハイフン](#ハイフン) |

組み合わせると次のようになります．

<div class="grid {{ site.data.doc_figure_sizes['doc-41e0b789'].layout }}" markdown="1">

```text
[#*word*\
  PHON\t⟨<>*Kim*<>⟩\
  SYNSEM\t#(LOCAL\t#(CAT\t#(HEAD\t#(*noun*\
    CASE\t*nom*#)\
    SPR\t⟨<>|1|<>⟩#)#)#)
]
```

{% include doc_figure.html name="doc-41e0b789" alt="桁揃え・入れ子の行列・タグを含む素性構造" %}

</div>

行列は木のノードに置くこともでき（HPSG がそうします），[導出図](#導出図)のステップの
範疇にすることもできます．

#### 桁揃え

`\t` は行をセルに区切ります．ラベルの各行が同じ位置で区切られ，各列はその列の最大幅で描画されるため，直前のテキストの長さに関係なく縦に揃います．HPSGなどで属性値行列（AVM）を記述する時などに便利です．

<div class="grid {{ site.data.doc_figure_sizes['doc-94998461'].layout }}" markdown="1">

```text
[#HEAD\tnoun\
  SPR\t⟨<>⟩\
  COMPS\t⟨<>NP<>⟩
  Kim
]
```

{% include doc_figure.html name="doc-94998461" alt="属性と値が桁で揃った行列" %}

</div>

3列以上でも同様に動作し，各列は必要な幅を取ります．ギャラリーの [HPSG sample](https://yohasebe.github.io/rsyntaxtree/examples#example-013) の例などをご覧ください．

#### 行列の入れ子

属性の値として別の行列を書けます．`#(` と `#)` で囲むと，その行列は自前の角括弧と桁揃えを持ち，後続の行はその高さ全体を避けて配置されます．

<div class="grid {{ site.data.doc_figure_sizes['doc-31d502b2'].layout }}" markdown="1">

```text
[#*word*\
  PHON\t⟨<>*Kim*<>⟩\
  SYNSEM\t#(LOCAL\t#(CAT\t#(HEAD\t#(*noun*\
    CASE\t*nom*#)\
    SPR\t⟨<>⟩#)#)#)
]
```

{% include doc_figure.html name="doc-31d502b2" alt="四重に入れ子になった行列" %}

</div>

入れ子は何段でも可能です．`SYNSEM | LOCAL | CATEGORY | HEAD` のような素性パスを書くために必要な機能です．素の角括弧は樹形図の構造として解釈され，素の丸括弧はラベル本文でよく使われるため，区切りには `#(` と `#)` を用いています．ギャラリーの [Nested feature structure](https://yohasebe.github.io/rsyntaxtree/examples#example-076) の例などをご覧ください。

#### ハイフン

ハイフンは下線の開始と終了を表すため，文字としてのハイフンは `\-` と書きます．HPSG やその周辺の枠組みでは HEAD-DTR や RELIED-ON のように素性名にハイフンが頻出し，そのすべてをエスケープするのが大変になります．そこで、`ハイフン`（`hyphen`，CLI では `--hyphen`）オプションを使って2つの記法を入れ替えられます．`literal` を指定すると，素のハイフンは文字として扱われ，下線は `\-下線\-` と書きます．ハイフンのうち2つは記法ではなく構造なので，どちらの設定でもそのまま働きます．なお、ハイフンだけの行は横罫線のままで，パス記法の `+-1` のハイフンも破線の指定のままです．

### 導出図

導出は木とは違う書き方をします．語が先に上に来て，各ステップは結びつける範囲いっぱいに
横罫を引いてその下に結果を書き，全体が到達したものが最後に下に来ます．範疇文法はこの書式で
書かれますし，構成素の広がりを示す図も同じ形です．

`導出`（`derivation`）をオンにすると，各ノードと娘を結ぶ線が，娘全体をまたぐ 1 本の罫に
置き換わります．あわせて `方向` を `btt` にすると木が上下逆になり，語が先に来ます．

<div class="grid {{ site.data.doc_figure_sizes['doc-f4320d2c'].layout }}" markdown="1">

```text
[S\t<
  [NP\t>
    [NP/N the]
    [N dog]
  ]
  [S\\NP\t>
    [(S\\NP)/NP bit]
    [NP John]
  ]
]
```

{% include doc_figure.html name="doc-f4320d2c" alt="語が先で結果が最後に来る範疇文法の導出図" %}

</div>

構造は普通の括弧表記で，導出のための特別な記法はありません．知っておくとよいのは 2 点です．

**各ステップの名前は桁区切りの後ろに書きます．**`[S\t<` は「ラベルが `S`，それを導いた
ステップが `<`」という意味です．名前はその罫の右端に小さく置かれます．`>`・`<`・`>B`・
`>T`・`<Φ>` など何でも書け，エスケープは要りません．名前はラベルがマークアップとして
読まれる前に切り離されるからです．

**範疇の中のバックスラッシュは `\\` と書きます．**`S\\NP` が `S\NP` として描かれます．
バックスラッシュ 1 つは改行の開始なので，二重にする必要があります．

範疇は素のラベルでなく素性構造でも構いません．範疇が素性を担う流儀の導出はこの形で
書きます．行列の中の桁区切りは行列自身の列で，規則を名づけるのは行列の外にある区切りです：

<div class="grid {{ site.data.doc_figure_sizes['doc-e9eada7a'].layout }}" markdown="1">

```text
[#(CAT\tS#)\t<
  [#(CAT\tNP#) Kim]
  [#(CAT\tVP#) sleeps]
]
```

{% include doc_figure.html name="doc-e9eada7a" alt="範疇を素性構造にした導出図" %}

</div>

`方向` を `ttb` のままにすると，同じオプションで構成素の広がりを上から示す図になります．
各構成素の範囲が罫で示されます．

<div class="grid {{ site.data.doc_figure_sizes['doc-2ea8675a'].layout }}" markdown="1">

<!-- figure: derivation=on leafstyle=nothing vheight=0.5 hspacing=2.0 -->
```text
[S
  [NP
    [D the]
    [N dog]
  ]
  [VP
    [V bit]
    [NP John]
  ]
]
```

{% include doc_figure.html name="doc-2ea8675a" alt="同じオプションで，通常の木の構成素の広がりを示した図" %}

</div>

<div class="aside" markdown="1">

**組みかた．** `コネクタ形状` を `none` にすると語と範疇の間に縦線が入りません．`縦間隔`
は小さめが縦に詰まった図に合います．ギャラリーの導出図は最小の `0.5` です．

横方向は `Tidy レイアウト: low` に `横間隔` を広めにするとうまく収まります．導出は各桁を
そこに立つ最も広いものの幅にとった表として組むもので，`low` がまさにそれを行い，桁を
寄せつつ語順を保ちます．そのうえで `横間隔` が全桁を同じだけ開きます．ギャラリーの
導出図は `2.0` です．避けたいのは `Tidy レイアウト: off` で，各部分木に木のレイアウトが
割り当てた幅をそのまま与えるため，空きが表の求める場所ではなく枝分かれの都合で入ります．

</div>

<div class="aside" markdown="1">

**導出でできないこと．** `方向: ltr` は拒否されます．前提をまたぐ罫は，前提が横に並んで
いなければ引けないからです．`既定のコネクタを隠す` も拒否されます．このオプションは
コネクタを描かないのではなく背景色で描くもので，導出の罫は図そのものです．隠すと範疇が
段に並ぶだけで何も結ばれていない図になります．TikZ 出力も拒否されます．`forest` は娘
それぞれに辺を引いて根を上に置くので，出てくるのは同じ構造の正しい木であって，この図では
ありません．PNG・SVG・PDF をお使いください．

</div>

### ノードからノードへのパスの描画

下の3種類の形式でノードからノードへのパスを表示することができます．

- 方向（矢印）のないパス（`- - -`）
- 方向（矢印）のあるパス（`----▶`）
- 両方向の矢印のあるパス（`◀---▶`）

樹形図の中でパスを表示したいとき，パスの両端を数字のIDで指定します．数字をプラス（`+`）記号と共にノードのテキストの最後で指定してください（例：`+7`）．
プラス記号とID番号の間に `>` 記号または `<` 記号を入れると（例：`+>7`），パスの終端に矢印が付きます．その際，`+>` と `+<` のどちらを用いるかで結果は変わりません．矢印の先は常にこれらのいずれかを用いたIDが指定された要素に向けられます．

IDにはどのような数字を用いても構いませんが，必ず **2箇所** で同じIDを指定することが必要です．同じIDを3箇所以上で指定することはできません．

<div class="grid {{ site.data.doc_figure_sizes['doc-c05567af'].layout }}" markdown="1">

```text
[CP
  [NP What+>1]
  [C'
    [C does]
    [IP
      [NP John]
      [VP
        [V like]
        [NP t+1]
      ]
    ]
  ]
]
```

{% include doc_figure.html name="doc-c05567af" alt="痕跡から移動した語へ向かう，矢印つきのパス" %}

</div>

### ノードからノードへの追加的なコネクターの描画

パスの指定と類似した方式でノードからノードへのコネクターを追加することができます．追加的なコネクターは直線で描画されます（`polyline`にはなりません）．追加的なコネクターを描画する際，デフォルトのコネクターを非表示（透明）にしたいときには `コネクタを隠す` オプションをオンにすると良いでしょう．

追加のコネクターは数字のIDで指定します，プラスとマイナスを連続させた（`+-`）後にIDを指定してください（例：`+-8`）．マイナス記号とID番号の間に `>` 記号または `<` 記号を入れると（例：`+->8`），コネクターの終端に矢印が付きます．その際，`+->` と `+-<` のどちらを用いるかで結果は変わりません．矢印の先は常にこれらのいずれかを用いたIDが指定された要素に向けられます．

- 方向（矢印）のないコネクター（`-----`）
- 方向（矢印）のあるコネクター（`--▶--`）
- 両方向の矢印のあるコネクター（`-◀-▶-`）

IDにはどのような数字を用いても構いませんが，必ず **2箇所** で同じIDを指定することが必要です．同じIDを3箇所以上で指定することはできません．

<div class="grid {{ site.data.doc_figure_sizes['doc-0f4a4bf1'].layout }}" markdown="1">

```text
[S
  [NP+-1 The dogs]
  [VP+->1 bark]
]
```

{% include doc_figure.html name="doc-0f4a4bf1" alt="同じ段の 2 つのノードを直線で結ぶ追加のコネクタ" %}

</div>

### Penn Treebank形式

RSyntaxTreeはPenn Treebank形式を自動的に検出し，括弧表記に変換します：

```
# Penn Treebank形式
(S (NP the dog) (VP runs))

# 同等の括弧表記
[S [NP the dog] [VP runs]]
```

**Penn Treebank形式での特殊文字のエスケープ：**

| 入力 | 表示 |
|------|------|
| `\(` `\)` | 丸括弧 `()` をそのまま表示 |
| `\[` `\]` | 角括弧 `[]` をそのまま表示 |

例：
```
(S (NP hello\(world\)) (VP test))
→ [S [NP hello(world)] [VP test]]
```

### 自分の環境で動かす（上級者向け）

以下の機能はウェブアプリでは提供されません．RSyntaxTreeをgemまたはDockerイメージとして自分の環境で動かす場合に利用できます．

#### 好みのフォントを使う

ギャラリーで扱うスクリプトはシステム任せのフォールバックではなくフォント名を明示して解決します（`Noto Sans Arabic` ／ `Noto Naskh Arabic`，`Noto Sans Hebrew` ／ `Noto Serif Hebrew`，およびデーヴァナーガリー・タイ・クメールの Noto Sans／Noto Serif）．これらのフォントが導入されている環境どうしであれば，同じ入力が同じ字形で描画されます．数学用英数字（U+1D400 以降．例えば *v*P のイタリック体の *v*）は，環境によって字形が変わることがあります．

上記のフォント指定はシステムの既定より優先されるため，お使いのアラビア語フォントなどがあっても Noto が優先されます．RSyntaxTree 側を変更しなくても，fontconfig の alias で上書きできます．たとえばアラビア語を Amiri で描画するには，`~/.config/fontconfig/fonts.conf` に次を書いて `fc-cache -f` を実行します．

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias binding="strong">
    <family>Noto Sans Arabic</family>
    <prefer><family>Amiri</family></prefer>
  </alias>
</fontconfig>
```

計測と描画は同じ fontconfig をたどるため，置き換えたあとのフォントで計測されます．レイアウトが崩れることはありません．

<div class="aside" markdown="1">

**macOS では．** 以上は Pango が fontconfig でフォントを解決する環境，つまり Linux と
Docker イメージでの話です．macOS の Pango は CoreText を使い fontconfig を参照しないため，
alias を書いても効きません．描きたいフォントは入力のフォント指定で選んでください．また
CoreText は絵文字のコードポイントに必ず Apple Color Emoji を返し，そのカラーグリフを
librsvg が描画しないため，絵文字を含む図は Linux か Docker イメージで生成することを
おすすめします．

</div>

#### 描画せずに入力を検査する

`--validate` は，入力が描画できるかどうかだけを報告します．描画も出力ファイルの
書き出しも行いません．診断結果はJSONとして標準出力に出力され，入力が受理された
場合は終了コード0，されなかった場合は1を返します．

```bash
rsyntaxtree --validate "[S [NP the cat] [VP sat]]"
```

オプションは考慮されるので，オプションに依存する入力はそのオプションのもとで
判定されます：

```bash
rsyntaxtree --validate --hyphen literal "[X V-bar]"
```

同じ入力をオプションなしで検査すると拒否され，何がどこで誤っているかが
診断に示されます：

```bash
$ rsyntaxtree --validate "[X V-bar]"
{
  "schema": "rsyntaxtree.error/1",
  "ok": false,
  "errors": [
    {
      "code": "bare_hyphen",
      "message": "Error: input text contains an invalid string\n > V-bar",
      "label": "V-bar",
      "position": 1,
      "hint": "A hyphen opens an underline. Escape it (e.g. f\\-structure, V\\-bar) or set the hyphen option to literal.",
      "retryable": true
    }
  ]
}
```

#### 記法リファレンス

`--notation` は，1 ページのリファレンス — 特別な意味を持つ文字，全機能の一覧，オプション — を標準出力に出力します．LLM に作図を依頼するときに渡す資料として想定しています．`--examples` は，公開されている全事例を，それぞれが描画された際のオプションとともに出力します．どちらも入力を読まずに出力して終了します．

```bash
rsyntaxtree --notation
rsyntaxtree --examples
```

同じ内容はプレーンテキストとしてサイトにも置いてあります．コマンドを実行できないが URL は取得できる読み手のためのものです．[llms.txt](https://yohasebe.github.io/rsyntaxtree/llms.txt) が目次，[notation.txt](https://yohasebe.github.io/rsyntaxtree/notation.txt) が 1 ページのリファレンス単体，[llms-full.txt](https://yohasebe.github.io/rsyntaxtree/llms-full.txt) にはリファレンス・本マニュアル・全事例が一つのファイルに入っています．いずれも元の資料から生成されます．

#### 標準入力のサポート

パイプを使って標準入力からツリーデータを渡すことができます：

```bash
echo "[S [NP hello] [VP world]]" | rsyntaxtree -f svg -o ./
cat tree.txt | rsyntaxtree -f png -o ./
```

#### 設定ファイル

ホームディレクトリまたはカレントディレクトリに `.rsyntaxtreerc` ファイルを作成して，デフォルトオプションを設定できます：

```yaml
# ~/.rsyntaxtreerc
format: svg
color: modern
fontsize: 18
leafstyle: auto
symmetrize: off
```

コマンドライン引数は設定ファイルの設定を上書きします．設定ファイル内の不明なオプションは警告を生成し，無効な値はエラーメッセージを表示します．

#### TikZ出力

RSyntaxTreeは`-f tikz`オプションを使用してLaTeXドキュメント用のTikZ/forestコードを生成できます．出力は`forest`パッケージを使用してLaTeXで直接使用できます．

**制限事項：** TikZ出力はツリー構造に焦点を当てており，下記の視覚的機能はサポートされていません：

- ノード別カラー指定（`@color:`）
- 囲み（`#`，`##`）
- 三角形コネクタ（`^`）
- テキスト装飾（太字，斜体）
- 下付き・上付き文字（`_x_`，`__x__`）
- パス描画（`+1`，`+>1`）
- 桁揃え（`\t`）
- 入れ子行列（`#(` … `#)`）
- 配色（`color: gray`）

いずれも拒否されるのではなく，落とされたうえで木が書き出されます．行列のラベルは
セルが 1 行に連なった形で出てくるので，`forest` のコードは図と見比べてから使ってください．

<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lightbox2@2.11.3/src/js/lightbox.js"></script>

---

<script>
  // Copy the notation for one example. This used to add a `copy` listener to
  // the document and leave it there, so every later Cmd+C on the page
  // returned that same notation however much the reader had selected by
  // hand. The clipboard is written directly instead, and nothing is left
  // behind to intercept a selection.
  function copyToClipBoard(id){
    var text = document.getElementById(id).innerText;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text);
      return;
    }
    var area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.top = '-1000px';
    document.body.appendChild(area);
    area.select();
    document.execCommand('copy');
    document.body.removeChild(area);
  }
</script>

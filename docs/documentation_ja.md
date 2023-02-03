---
title: RSyntaxTree
layout: default
---

# ドキュメンテーション
{:.no_toc}

[English](https://yohasebe.github.io/rsyntaxtree/documentation) | 
[日本語](https://yohasebe.github.io/rsyntaxtree/documentation_ja)

### 目次
{:.no_toc}

1. toc
{:toc}

### 基本的な使い方

エディターエリアにラベル付き括弧表記でテキストを入力し，`Draw PNG`または`Draw SVG`ボタンをクリックします．

樹形図のすべてのブランチ（枝）やリーフ（葉）は，ノード（節点）に属します．ノードを作成するには，ラベルテキストを開始括弧の直後に配置します．ブランチは，空白で区切っていくつでも設定できます．リーフのテキストに1つ以上の空白が含まれているとき，空白はそのまま表示されます．ノードのラベルに空白を含めたいときには `<>` 記号を使って表します．例えば `Modal<>Aux` とすれば `Modal Aux` と表示されます．

終端ノードとリーフの間に描かれるコネクターの描画方法は3種の中から選べます（`auto`，`bar`，`none`）．`auto` では，1つ以上の空白を含むリーフ（要するに「句」）に対しては終端ノードを頂点とした三角形を描画します．リーフが空白を含まない場合（つまり「単語」の場合)，垂直線が描かれます ．なお，リーフの先頭に `^` をつけると，そのリーフが句であると宣言することになります．したがって必ず三角形が描かれます． `bar` では，すべてのリーフに関して垂直線が描かれます． `none` では終端ノードとリーフの間にコネクターは描かれません．これらのコネクターは `Hide default connectors` オプションをオンにすると非表示（透明）にすることができます．

ノードを表すテキストやリーフを表すテキストの中で改行を行たい場合，改行文字 `\n` を用いることができます．

RSyntaxTreeではPNG形式またはSVG形式で画像を生成します．どちらもMicrosoft Wordで作った書類などに貼り付けることができます．PNG形式の方が一般的ですが，SVG形式の画像は拡大しても描画品質が変わらないため，高品質なグラフィックが必要な場合に便利です．SVG形式の画像は，Adobe Illustrator，Microsoft Visio， [BOXY SVG](https://boxy-svg.com/) などのソフトウェアで読み込んで編集することができます．

`Radical symmetrization` オプションは，ブランチ（枝）の描画方法に影響します．`Font style` ， `Font size` ，`Connector height` ，`Color`  の各オプションについては説明の必要はないでしょう．これらのオプションの値を変更することで，樹形図の外観を変えることができます．

### PNG形式を用いる場合

PNG形式の場合，`Noto Sans`，`Noto Serif`，`WQY Zen Hei` のいずれかを選ぶと，そのフォントを使って樹形図が描画されます．

- `Noto Sans` は基本的なUnicode文字をゴシック体に近い書体で表示します（日本語のひらがな／カタカナ／漢字を含む）．
- `Noto Serif` は基本的なUnicode文字を明朝体に近い書体で表示します（日本語のひらがな／カタカナ／漢字を含む）．
- `WQY Zen Hei` は中国語／日本語／コリア語（CJK）の幅広い文字を表示可能です．

### SVG形式を用いる場合

SVG形式を用いる場合，期待通りの表示を得るためには，ご使用のコンピュータに適切なフォントがインストールされている必要があります．下記のフォントをあらかじめインストールしておいてください．必要なフォントがインストールされていない場合は，別のフォントで表示されるため，見た目のバランスをやや欠くことがあります．

- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans): ラテン文字と基本的なUnicode文字（サンセリフ）の表示
- [Noto Sans JP](https://fonts.google.com/noto/specimen/Noto+Sans+JP): 日本語のひらがな／カタカナ／漢字（サンセリフ）の表示
- [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif): ラテン文字と基本的なUnicode文字（セリフ） の表示
- [Noto Serif JP](https://fonts.google.com/noto/specimen/Noto+Serif+JP):日本語のひらがな／カタカナ／漢字（セリフ）の表示
- [WQY Zen Hei](https://packages.ubuntu.com/bionic/fonts/fonts-wqy-zenhei): 中国語／日本語／コリア語（CJK）の文字の表示
- [OpenMoji](https://openmoji.org/): 様々な絵文字の表示

### テキストの描画

フォントのスタイルとしてイタリック／ボールド／ボールド+イタリックを指定できます．テキスト装飾としては，上線，下線，取り消し線を指定できます．また上付き文字と下付き文字を指定できます．これらは組み合わせて使用することもできます．

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

**注意：** 上線はSVGでは使用できますがPNG形式の画像では表示されません.

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

#### 改行

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

#### ボックスとサークル

{% include box_and_circle_table.html %}

#### 水平線

|Sample Input                   |Output                |
|-------------------------------|----------------------|
|`str1\`<br />`---\`<br />`str2`|str1<br />——<br />str2|
|`str1\ ---\ str2`              |str1<br />——<br />str2|
|`str1\n---\nstr2`              |str1<br />——<br />str2|

ここで `---` は `-` の3つ以上の連続を意味します.

### コネクター

終端ノードとリーフの間に描かれるコネクターの描画方法は3種の中から選べます（`auto`，`bar`，`none`）．`auto` では，1つ以上の空白を含むリーフ（要するに「句」）に対しては終端ノードを頂点とした三角形を描画します．リーフが空白を含まない場合（つまり「単語」の場合)，垂直の直線が描かれます ．なお，リーフの先頭に `^` をつけると，そのリーフが句であると宣言することになります．したがって必ず三角形が描かれます． `bar` では，すべてのリーフに関して垂直の直線が描かれます． `none` では終端ノードとリーフの間にコネクターは描かれません．

### リーフを囲む括弧と矩形の描画

ラベルまたはリーフとなるテキストの最初に（`^` が存在する場合はその直後に） `#` を付けると，そのテキスト全体を角括弧（［ ］）で囲みます（例：`[#NP text]`, `[NP #text]`, `[NP ^#text]`）． テキストの最初に `##` を付けると，テキスト全体を矩形（ボックス）で囲みます．

### 一部の文字を表示するためのエスケープ

文字装飾などのマークアップに使用される一部の文字をテキストとして表示するためには `\` によってエスケープする必要があります．使用している環境で `\` が使えない場合は `¥` で代用することができます．

{% include escape_char_table.html %}

**注意：** 単なる改行 `↩️` はスペースとして扱われます．`↩️` を1つ以上連続させた場合も1つのスペースとして扱われます．

テキスト中で改行したいときには，1） `\n`，2） `\↩️`，3） `\ + whitespace ` のいずれかを用いてください．そうすると出力される画像の中で改行 `↩️` が行われます．

### ノードからノードへのパスの描画（試験的機能）

下の3種類の形式でノードからノードへのパスを表示することができます．

- 方向（矢印）のないパス（`- - -`）
- 方向（矢印）のあるパス（`----->`）
- 両方向の矢印のあるパス（`<----->`）

樹形図の中でパスを表示したいとき，パスの両端を数字のIDで指定します．数字をプラス（`+`）記号と共にノードのテキストの最後で指定してください（例：`+7`）．
プラス記号とID番号の間に `>` 記号を入れると（例：`+>7`），パスの終端に矢印が付きます．その際、`+>` と `+<` のどちらを用いるかで結果は変わりません。矢印の先は常にこれらのいずれかを用いたIDが指定された要素に向けられます。

IDにはどのような数字を用いても構いませんが，必ず **2箇所** で同じIDを指定することが必要です．同じIDを3箇所以上で指定することはできません．

### ノードからノードへの追加的なコネクターの描画（試験的機能）

パスの指定と類似した方式でノードからノードへのコネクターを追加することができます．追加的なコネクターは直線で描画されます（`polyline`にはなりません）．追加的なコネクターを描画する際，デフォルトのコネクターを非表示（透明）にしたいときには `Hide default connectors`オプションをオンにすると良いでしょう．

追加のコネクターは数字のIDで指定します，プラスとマイナスを連続させた（`+-`）後にIDを指定してください（例：`+-8`）．マイナス記号とID番号の間に `>` 記号を入れると（例：`+->8`），コネクターの終端に矢印が付きます．その際、`+->` と `+-<` のどちらを用いるかで結果は変わりません。矢印の先は常にこれらのいずれかを用いたIDが指定された要素に向けられます。

- 方向（矢印）のないコネクター（`-----`）
- 方向（矢印）のあるコネクター（`--▶--`）
- 両方向の矢印のあるコネクター（`-◀-▶-`）

IDにはどのような数字を用いても構いませんが，必ず **2箇所** で同じIDを指定することが必要です．同じIDを3箇所以上で指定することはできません．

<script src="https://cdn.jsdelivr.net/npm/jquery@3.5.0/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lightbox2@2.11.3/src/js/lightbox.js"></script>

---

<script>
  function copyToClipBoard(id){
    var copyText =  document.getElementById(id).innerText;
    document.addEventListener('copy', function(e) {
        e.clipboardData.setData('text/plain', copyText);
        e.preventDefault();
      }, true);
    document.execCommand('copy');
    alert('copied');
  }
</script>

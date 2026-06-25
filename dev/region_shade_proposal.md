# 提案：領域シェード（部分木をまたぐ網掛け）機能

作成: 2026-06-25 / 動機: 容認度研究プロジェクト（2026-accdeptability）で、c-command 領域・束縛領域・認知文法の dominion を「面」で示したい。現状の囲み（`#`/`##`/`###`）は**ノードのラベルのみ**で、部分木全体を囲めない。

## 現行マークアップ仕様の要約（1.5.0、`markup_parser.rb` の `lines` 規則より）

ノードラベルの構造（順序固定）:
`^`(三角) → 囲み `#`|`##`|`###` → `@色:` → 本文(装飾) … → 末尾に移動パス `+1`/`+>1`/`+<1`

- 囲み: `#`角括弧 / `##`矩形 / `###`二重矩形（**ノードのみ**）
- 色: `@name:` / `@#hex:`
- 移動パス: `+` `-`? (`>`|`<`)? digits（複数可）
- インライン装飾: `**bold**` `*italic*` `***bi***` / `=overline=` `-underline-` `~through~` / `__sup__` `_sub_` `___small___` / 図形 `|box|` `{circle}` `||` `{}` `|/|` `{/}` `--` `->` `<-` `<->` / 太線囲み `*〈shape〉*` / 区切り線 `---` `===` / `\n` / エスケープ `\`

使用済み記号: `# ^ @ : + - > < * = ~ _ | { } [ ] ( ) \` ＋数字。
**未使用（衝突なし）: `% & ! ? $ ;`**

## 設計（決定: 案A、`%` を採用）

- **記法**: `[%@yellow:VP …]` → `%` が「領域シェード ON」、色は既存 `@色:` を流用。
  - `lines` 規則に region 用プレフィックス（`%`）を `triangle`/`enclosure` と並べて追加（`%`.maybe.as(:region)）。
  - 色は既存 color_spec を再利用（重複文法を作らない）。`%` 単独なら既定色（薄いグレー）。
- **意味論**: 当該ノードが支配する**部分木全体**の背後に半透明矩形を描く。
  - 範囲: x = ノードの left 〜 left+width（element は支配範囲幅 `@width` を保持）、y = ノードの y 〜 子孫の最大 y。
  - z-order: 最背面（ツリー線・ラベルの下）。
- **バックエンド**: `svg_graph.rb`（rect fill-opacity）、`tikz_generator.rb`（\fill[opacity]）、png 経路（rmagick）。の3つに描画を追加。

## 触るファイル（見積り: 中）
- `markup_parser.rb`: `region` トークン追加、`parse` の results に `:region` 追加。
- `element.rb`: `region`/`region_color` 属性、子孫の y/x 範囲（bounding box）算出ヘルパ。
- `base_graph.rb` / `svg_graph.rb` / `tikz_generator.rb`: 最背面シェード描画。
- `string_parser.rb`: ノード属性として region を伝播（必要なら）。
- ドキュメント（`docs/documentation.md` ほか）・examples 追加。

## 注意
- 隣接シェードが重なる場合の色合成（複数領域の入れ子）。半透明なら自然に重なる。
- LTR レイアウトでも bounding box 算出が成立するか確認。
- 実装は容認度研究のノート群が一段落してから着手（研究が主）。

---

## 実装記録（2026-06-25 完了）

実装済み。設計（案A、`%` 採用）どおり。主な判断と差分:

- **色の意味論を明確化**: `%@色:` の色は**領域シェードの色**に束縛し、ノードのテキスト/線色とは独立させた。文法上は `region = '%' >> color_spec?` とし、その後ろに従来の `color_spec?` を別途残した。よって `%@yellow:@blue:VP` = 黄色の面＋青のラベル。`%` 単独は既定の薄いグレー（`#888888` / opacity 0.18）。
- **PNG/PDF/JPG/GIF は SVG 由来**（`rsyntaxtree.rb` の `draw_png`/`draw_pdf` は `draw_svg` を経由、JPG/GIF は PNG 経由）。よって SVG に rect を入れるだけで全ラスタ/ベクタ形式に波及。提案の「png 経路（rmagick）に描画追加」は現状実装と乖離していたため**不要**と判断し、rmagick への直接描画は行っていない。
- **z-order**: 白背景 rect の直後・`@tree_data` の前に挿入（`@region_shades` バッファ）。transparent モードでも先頭に挿入。
- **bounding box**: `base_graph.rb#subtree_bounds(id)` を新設。レイアウト確定後（`finalize_ltr` 後）の `horizontal_indent`/`vertical_indent`/`content_*` を再帰で集約。node の `content_height` は `draw_element` 内で再計算されるため、シェード収集は `parse_list` 完了後（`svg_data` 内 `collect_region_shades`）に実行。TTB/LTR 両対応を確認済み。
- **TikZ**: `forest` の `fit to=tree` を背景レイヤー（`\scoped[on background layer]`）で使用。standalone 出力時のみ `\usetikzlibrary{backgrounds,fit}` を自動付加。HEX 色は `{rgb,255:...}` へ変換。**未確定事項**: 当環境に LaTeX 未インストールのため `fit to=tree` の実コンパイル検証は未実施。要、実機での確認。
- **LSIF**: node の `style.region`（`{color: ...}` または `null`）を追加。指定色の意図を記録し、白黒化（下記）は描画側のみ。
- **視認性改良（追加要望対応）**: 白地で薄い面が見にくい問題に対し、各面へ**同色だが不透明度を上げたボーダー**を付与（fill-opacity 0.2 / stroke-opacity 0.55、stroke-width=線幅+LINE_SCALING）。色名・HEX 問わず「濃い同系色ボーダー」になり暗色計算不要。TikZ も `draw=色, draw opacity` を付与。
- **白黒モードの色の扱い**: 当初「color オフ時はグレー強制」としたが、シェードも色指定可能で `@color:`（文字色は白黒でも色を honor）と非対称になるため、ユーザー判断で**「明示色は常に尊重・素の % のみ既定グレー・モード依存なし」**に確定。白黒図にしたい場合は素の % を使う。

## 懸念対応（concerns 反映、2回目）

`/concerns` レビューで挙げた点を全て対応（TDD）。

- **TikZ 色名互換**: SVG は任意の CSS 色名を解釈できるが xcolor は限定的（`lightblue` 等が未定義→コンパイル不可）。`tikz_generator.rb` に **CSS 拡張色名148色テーブル `CSS_COLORS`** を追加し、色名・hex（3桁短縮含む）を**インライン rgb 式 `{rgb,255:...}` に解決**。未知名のみ素通し（best effort）。例064の `lightblue` も解決される。
- **上辺クリップ**: ルート/最上位ノードに領域を付けると面の上辺が viewBox（miny=0）外で切れていた。`collect_region_shades` で領域の和集合境界 `@region_bounds`（pad＋ストローク半分込み）を記録し、`svg_data` で **viewBox/背景 rect/幅高さを領域込みに拡張**。
- **LSIF version**: `0.2.0`→`0.3.0`（`style.region` 追加の additive 変更を明示）。
- **`\%` エスケープ**: `markup_parser` の `escaped` 文字クラスに `%` 追加＋`string_parser#get_next_token` の特殊文字 regex に `%` を追加（`\%` を `\%` のまま保持）。先頭リテラル `%` が出せるように。escape 表（`escape_char_table.html`）も更新。
- **未対応のまま**: TikZ `fit to=tree` の実 LaTeX コンパイル検証（環境に LaTeX 無し）。O(n²)（全ノード region 時のみ、実害なし）。symmetrize モードの明示テストは無し。
- テスト: 240 runs / 0 failures。
- **後方互換**: 先頭 `%` を予約。既存 examples に先頭 `%` の使用はなく破壊なし。`%` のエスケープ（`\%`）は未対応（必要になれば `escaped` ルールに `%` を追加）。
- **触ったファイル**: `markup_parser.rb`, `element.rb`, `base_graph.rb`, `svg_graph.rb`, `tikz_generator.rb`, `lsif_graph.rb`, tests（`markup_parser_test`/`node_styling_test`/`tikz_test`）, `docs/_examples/064.md`, `docs/documentation.md`, `docs/documentation_ja.md`, `CHANGELOG.md`。`string_parser.rb` は変更不要だった（`%` は通常文字として透過）。

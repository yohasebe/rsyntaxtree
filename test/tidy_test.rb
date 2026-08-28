# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class TidyTest < Minitest::Test
  # The 9-language PUD brackets, embedded so the test suite is
  # self-contained.
  UD_TREES = {
    "English" => ["[S [NP [PRON Its] [NOUN importance]] [VP [VERB resides] [PP [ADP in] [NP [NUM two] [NOUN facts]]]]]", "sans"],
    "Arabic" => ["[S [VP [VERB تكمن] [NP [NOUN أهميت] [PRON ه]]] [PP [ADP في] [NOUN حقيقتين]]]", "sans"],
    "Hindi" => ["[AP [NP [PRON इसका] [NOUN महत्व]] [AP [PP [NP [NUM दो] [NOUN तथ्यों]] [ADP में]] [AP [ADJ निहित] [AUX है]]]]", "sans"],
    "Thai" => ["[S [ADJ ความสำคัญ] [VP [VERB อยู่] [NP [NP [PP [ADP ใน] [NOUN ข้อ]] [ADJ เท็จจริง]] [NumP [NUM สอง] [NOUN ประการ]]]]]", "sans"],
    "Japanese" => ["[S [NP [PP [NP [NUM 2] [NOUN つ]] [ADP の]] [PP [NOUN 事実] [ADP が]]] [VP [AP [ADJ 重要] [AUX に]] [VP [VERB なり] [AUX ます]]]]", "cjk"],
    "Korean" => ["[S [NP [DET 그] [NOUN 중요성이]] [VP [VP [NP [NP [DET 두] [NOUN 가지]] [NOUN 사실에]] [VERB 숨어]] [AUX 있다]]]", "cjk"],
    "Russian" => ["[S [NOUN Важность] [VP [VERB заключается] [PP [ADP в] [NP [NUM двух] [NOUN фактах]]]]]", "sans"],
    "Turkish" => ["[AP [AP [NP [NP [NUM İki] [NOUN olgu]] [NOUN bakımından]] [ADJ önemli]] [AUX dir]]", "sans"],
    "Chinese" => ["[S [AP [PRON 其] [ADJ 重要性]] [VP [PP [ADP 在] [PP [NP [NP [NUM 兩] [NOUN 個]] [NOUN 事實]] [ADP 中]]] [VP [VERB 反應] [VERB 出來]]]]", "cjk"]
  }.freeze

  SIMPLE = "[S [NP [Det the] [N cat]] [VP [V sat] [PP [P on] [NP [Det the] [N mat]]]]]"
  SHADED = "[TP [DP everyone] [%@lightblue:T' [T will] [VP [V praise] [DP his_i_ friend]]]]"

  def generator(data, extra = {})
    opts = DEFAULT_OPTS.dup
    opts[:data] = data
    extra.each { |k, v| opts[k] = v }
    RSyntaxTree::RSGenerator.new(opts)
  end

  def lsif(data, extra = {})
    JSON.parse(generator(data, extra).draw_lsif)
  end

  # => [[y0, y1, x0, x1, id], ...]
  def rects(nodes)
    nodes.map do |n|
      p = n["position"]
      [p["y"], p["y"] + p["content_height"], p["x"], p["x"] + p["content_width"], n["id"]]
    end
  end

  def assert_no_overlaps(nodes, label)
    rects(nodes).combination(2) do |a, b|
      separated = a[3] <= b[2] + 0.01 || b[3] <= a[2] + 0.01 || a[1] <= b[0] + 0.01 || b[1] <= a[0] + 0.01
      assert separated, "#{label}: nodes ##{a[4]} and ##{b[4]} overlap"
    end
  end

  # Minimum horizontal clearance among label rects that share a y band
  def min_label_gap(nodes)
    gaps = []
    rects(nodes).combination(2) do |a, b|
      next unless a[0] < b[1] - 0.01 && b[0] < a[1] - 0.01

      lo, hi = a[2] < b[2] ? [a, b] : [b, a]
      gaps << hi[2] - lo[3]
    end
    gaps.min
  end

  def leaf_centers(nodes)
    nodes.select { |n| n["type"] == "leaf" }
         .sort_by { |n| n["id"] }
         .map { |n| n["position"]["x"] + n["position"]["content_width"] / 2.0 }
  end

  # tidy: on never produces overlapping labels (9 languages, ttb and ltr)
  def test_tidy_on_no_overlaps_nine_languages
    UD_TREES.each do |lang, (bracket, fontstyle)|
      assert_no_overlaps lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "low")["nodes"], "#{lang}/ttb"
      assert_no_overlaps lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "low", direction: "ltr")["nodes"], "#{lang}/ltr"
    end
  end

  # tidy: on preserves the global leaf order (left to right)
  def test_tidy_preserves_leaf_order
    UD_TREES.each do |lang, (bracket, fontstyle)|
      centers = leaf_centers(lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "low")["nodes"])
      assert centers.each_cons(2).all? { |x, y| x <= y + 0.01 }, "#{lang}: leaf order changed"
    end
  end

  # hspacing: larger spacing => wider minimum label gap (tidy mode)
  def test_hspacing_monotonic_tidy
    bracket, fontstyle = UD_TREES["Chinese"]
    gaps = [0.5, 1.0, 2.0].map do |sp|
      min_label_gap(lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "low", hspacing: sp)["nodes"])
    end
    assert gaps[0] < gaps[1] && gaps[1] < gaps[2], "min label gap should grow with hspacing: #{gaps.inspect}"
  end

  # hspacing also widens the traditional (tidy: off) layout
  def test_hspacing_monotonic_off
    bracket, fontstyle = UD_TREES["Chinese"]
    widths = [0.5, 1.0, 2.0].map do |sp|
      lsif(bracket, fontstyle: fontstyle, vheight: 1.2, hspacing: sp)["geometry"]["width"]
    end
    assert widths[0] < widths[1] && widths[1] < widths[2], "off-layout width should grow with hspacing: #{widths.inspect}"
  end

  # medium: leaf centers keep global order while width shrinks below low
  def test_tidy_medium_ordered_nesting
    data = "[CP [John] [TP [T [V [V cause] [V fall]] [T]] [VP [V t] [CP [books] [t]]]]]"
    w_low = lsif(data, tidy: "low")["geometry"]["width"]
    w_medium = lsif(data, tidy: "medium")["geometry"]["width"]
    w_high = lsif(data, tidy: "high")["geometry"]["width"]
    # Cross-environment Pango metrics differ by a pixel or two, so the
    # monotonicity is asserted with a small tolerance (cf. OverlapTest).
    tolerance = 2.0
    assert w_medium <= w_low + tolerance, "medium (#{w_medium}) should be no wider than low (#{w_low})"
    assert w_high <= w_medium + tolerance, "high (#{w_high}) should be no wider than medium (#{w_medium})"
    centers = leaf_centers(lsif(data, tidy: "medium")["nodes"])
    assert centers.each_cons(2).all? { |x, y| x <= y + 0.01 },
           "medium must keep global leaf-center order: #{centers.inspect}"
    assert_no_overlaps lsif(data, tidy: "medium")["nodes"], "medium"
  end

  # tidy height budget: the tidy tree is never much taller than off
  # (the automatic budget replaces the old tidy_slope knob)
  def test_tidy_height_budget
    bracket, fontstyle = UD_TREES["Chinese"]
    h_off = lsif(bracket, fontstyle: fontstyle, vheight: 1.2)["geometry"]["height"]
    h_on = lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "low")["geometry"]["height"]
    assert h_on <= h_off * 1.10, "tidy height #{h_on} should stay within 10% of off height #{h_off}"
  end

  # tidy: compact nests across rows => at least as narrow as plain tidy
  def test_tidy_high_no_wider
    data = "[CP [John] [TP [T [V [V cause] [V fall]] [T]] [VP [V t] [CP [books] [t]]]]]"
    w_on = lsif(data, tidy: "low")["geometry"]["width"]
    w_high = lsif(data, tidy: "high")["geometry"]["width"]
    assert w_high <= w_on, "compact (#{w_high}) should not be wider than on (#{w_on})"
    assert_no_overlaps lsif(data, tidy: "high")["nodes"], "compact"
  end

  # hspacing 1.0 is the identity (backward compatibility)
  def test_hspacing_default_identity
    plain = generator(SIMPLE).draw_svg
    with_default = generator(SIMPLE, hspacing: 1.0).draw_svg
    assert_equal plain, with_default
  end

  # tidy + mirror: no overlaps, leaf order reversed relative to tidy alone
  def test_tidy_plus_mirror
    tidy_nodes = lsif(SIMPLE, tidy: "low")["nodes"]
    mirror_nodes = lsif(SIMPLE, tidy: "low", mirror: "on")["nodes"]
    assert_no_overlaps mirror_nodes, "tidy+mirror"

    tidy_leaves = leaf_centers(tidy_nodes)
    mirror_leaves = leaf_centers(mirror_nodes)
    assert tidy_leaves.each_cons(2).all? { |x, y| x <= y + 0.01 }
    assert mirror_leaves.each_cons(2).all? { |x, y| x >= y - 0.01 }, "mirror should reverse leaf order"
  end

  # tidy + ltr: no crash, no overlaps, root stays at the left edge
  def test_tidy_plus_ltr
    nodes = lsif(SIMPLE, tidy: "low", direction: "ltr")["nodes"]
    assert_no_overlaps nodes, "tidy+ltr"
    root = nodes.find { |n| n["parent"].nil? }
    leaves = nodes.select { |n| n["type"] == "leaf" }
    assert leaves.all? { |leaf| root["position"]["x"] < leaf["position"]["x"] }, "ltr: root should be leftmost"
  end

  # tidy + region shade: the shade rect still contains the shaded subtree
  def test_tidy_plus_region_shade
    svg = generator(SHADED, tidy: "low", fontstyle: "serif").draw_svg
    shade = svg.scan(/<rect [^>]*>/).map do |tag|
      { x: tag[/x='(-?[\d.]+)'/, 1].to_f,
        w: tag[/width='(-?[\d.]+)'/, 1].to_f,
        opacity: tag[/fill-opacity='([\d.]+)'/, 1]&.to_f }
    end.find { |r| r[:opacity] && (r[:opacity] - 0.2).abs < 0.001 }
    refute_nil shade, "region shade rect should exist"

    tspans = svg.scan(%r{<tspan x='(-?[\d.]+)' y='(-?[\d.]+)'[^>]*>(.*?)</tspan>}m)
    %w[will praise].each do |w|
      t = tspans.find { |s| s[2] == w }
      refute_nil t, "#{w} tspan should exist"
      assert t[0].to_f >= shade[:x] && t[0].to_f <= shade[:x] + shade[:w],
             "#{w} should be inside the shade x-range"
    end
  end

  # Left to right, the tree turns but the options do not: hspacing is what
  # separates sisters, which now stand one above another, so it is the height
  # that answers to it. The layout replaces the sister gap with one of its own
  # and has to scale that by hspacing too — without it both options pushed the
  # width and a left-to-right figure could be made wider but never shorter,
  # which is a thing no test noticed.
  def test_hspacing_moves_the_height_of_a_left_to_right_tree
    heights = %w[0.5 1.0 3.0].map do |hs|
      generator(SIMPLE, direction: "ltr", hspacing: hs).draw_svg[/height="([\d.]+)"/, 1].to_f
    end
    assert_equal heights.sort, heights, "hspacing must not shrink the height"
    assert_operator heights.last, :>, heights.first * 1.5,
                    "hspacing barely moved the height: #{heights.inspect}"

    widths = %w[0.5 1.0 3.0].map do |hs|
      generator(SIMPLE, direction: "ltr", hspacing: hs).draw_svg[/width="([\d.]+)"/, 1].to_f
    end
    refute_equal widths.first, widths.last, "hspacing still has to move the margins"
  end

  # The options removed in 2.0 are refused, and refused with the name of what
  # replaced them. Being ignored would be worse than being rejected: a caller
  # that still asks for symmetrize was given that layout in 1.x, and silence
  # would hand it a different figure without a word.
  def test_options_removed_in_2_0_are_refused_with_a_way_forward
    { symmetrize: "on", tidy_nest: "on", tidy_spacing: 2.0 }.each do |gone, value|
      e = assert_raises(RSTError, "#{gone} was accepted") do
        generator(SIMPLE, gone => value).draw_svg
      end
      assert_equal :invalid_option, e.code
      refute_nil e.hint, "#{gone}: refused with no way forward"
    end
  end
  # Legacy values keep working: on == medium, compact == high
  def test_tidy_legacy_value_aliases
    assert_equal generator(SIMPLE, tidy: "low").draw_svg, generator(SIMPLE, tidy: "on").draw_svg
    assert_equal generator(SIMPLE, tidy: "high").draw_svg, generator(SIMPLE, tidy: "compact").draw_svg
  end
  # Regression: partial params (defaults not passing through normalization)
  # must not turn string defaults like symmetrize: "off" into truthy flags.
  def test_partial_params_off_is_really_off
    minimal = RSyntaxTree::RSGenerator.new({ data: SIMPLE, fontstyle: "sans" }).draw_svg
    explicit = generator(SIMPLE).draw_svg
    symmetric = generator(SIMPLE, tidy: "symmetric").draw_svg
    assert_equal explicit, minimal, "partial params must render like explicit defaults"
    refute_equal symmetric, minimal, "off must differ from symmetric"
  end
end

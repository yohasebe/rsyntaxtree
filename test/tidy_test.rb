# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class TidyTest < Minitest::Test
  # The 9-language PUD brackets (identical to /tmp/ud_bin.json at the time of
  # writing; embedded so the test suite is self-contained).
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
      assert_no_overlaps lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "medium")["nodes"], "#{lang}/ttb"
      assert_no_overlaps lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "medium", direction: "ltr")["nodes"], "#{lang}/ltr"
    end
  end

  # tidy: on preserves the global leaf order (left to right)
  def test_tidy_preserves_leaf_order
    UD_TREES.each do |lang, (bracket, fontstyle)|
      centers = leaf_centers(lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "medium")["nodes"])
      assert centers.each_cons(2).all? { |x, y| x <= y + 0.01 }, "#{lang}: leaf order changed"
    end
  end

  # tidy_spacing: larger spacing => wider minimum label gap
  def test_tidy_spacing_monotonic
    bracket, fontstyle = UD_TREES["Chinese"]
    gaps = [0.5, 1.0, 2.0].map do |sp|
      min_label_gap(lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "medium", tidy_spacing: sp)["nodes"])
    end
    assert gaps[0] < gaps[1] && gaps[1] < gaps[2], "min label gap should grow with spacing: #{gaps.inspect}"
  end

  # tidy height budget: the tidy tree is never much taller than off
  # (the automatic budget replaces the old tidy_slope knob)
  def test_tidy_height_budget
    bracket, fontstyle = UD_TREES["Chinese"]
    h_off = lsif(bracket, fontstyle: fontstyle, vheight: 1.2)["geometry"]["height"]
    h_on = lsif(bracket, fontstyle: fontstyle, vheight: 1.2, tidy: "medium")["geometry"]["height"]
    assert h_on <= h_off * 1.10, "tidy height #{h_on} should stay within 10% of off height #{h_off}"
  end

  # tidy: compact nests across rows => at least as narrow as plain tidy
  def test_tidy_high_no_wider
    data = "[CP [John] [TP [T [V [V cause] [V fall]] [T]] [VP [V t] [CP [books] [t]]]]]"
    w_on = lsif(data, tidy: "medium")["geometry"]["width"]
    w_high = lsif(data, tidy: "high")["geometry"]["width"]
    assert w_high <= w_on, "compact (#{w_high}) should not be wider than on (#{w_on})"
    assert_no_overlaps lsif(data, tidy: "high")["nodes"], "compact"
  end

  # Knobs are inert when tidy is off (backward compatibility)
  def test_knobs_inert_when_tidy_off
    plain = generator(SIMPLE).draw_svg
    with_knobs = generator(SIMPLE, tidy_spacing: 2.0).draw_svg
    assert_equal plain, with_knobs
  end

  # tidy + mirror: no overlaps, leaf order reversed relative to tidy alone
  def test_tidy_plus_mirror
    tidy_nodes = lsif(SIMPLE, tidy: "medium")["nodes"]
    mirror_nodes = lsif(SIMPLE, tidy: "medium", mirror: "on")["nodes"]
    assert_no_overlaps mirror_nodes, "tidy+mirror"

    tidy_leaves = leaf_centers(tidy_nodes)
    mirror_leaves = leaf_centers(mirror_nodes)
    assert tidy_leaves.each_cons(2).all? { |x, y| x <= y + 0.01 }
    assert mirror_leaves.each_cons(2).all? { |x, y| x >= y - 0.01 }, "mirror should reverse leaf order"
  end

  # tidy + ltr: no crash, no overlaps, root stays at the left edge
  def test_tidy_plus_ltr
    nodes = lsif(SIMPLE, tidy: "medium", direction: "ltr")["nodes"]
    assert_no_overlaps nodes, "tidy+ltr"
    root = nodes.find { |n| n["parent"].nil? }
    leaves = nodes.select { |n| n["type"] == "leaf" }
    assert leaves.all? { |leaf| root["position"]["x"] < leaf["position"]["x"] }, "ltr: root should be leftmost"
  end

  # tidy + region shade: the shade rect still contains the shaded subtree
  def test_tidy_plus_region_shade
    svg = generator(SHADED, tidy: "medium", fontstyle: "serif").draw_svg
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

  # tidy + symmetrize: meaningless combination; tidy wins (no crash)
  def test_tidy_plus_symmetrize_does_not_crash
    svg = generator(SIMPLE, tidy: "medium", symmetrize: "on").draw_svg
    assert svg.include?("<svg")
    assert_no_overlaps lsif(SIMPLE, tidy: "medium", symmetrize: "on")["nodes"], "tidy+symmetrize"
  end
  # Legacy values keep working: on == medium, compact == high
  def test_tidy_legacy_value_aliases
    assert_equal generator(SIMPLE, tidy: "medium").draw_svg, generator(SIMPLE, tidy: "on").draw_svg
    assert_equal generator(SIMPLE, tidy: "high").draw_svg, generator(SIMPLE, tidy: "compact").draw_svg
  end
  # symmetric level == the legacy standalone symmetrize option
  def test_tidy_symmetric_equals_legacy_symmetrize
    assert_equal generator(SIMPLE, tidy: "symmetric").draw_svg,
                 generator(SIMPLE, symmetrize: "on").draw_svg
  end
end

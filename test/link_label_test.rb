# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/rsyntaxtree"

# A link carries a short text written in double quotes after its number on one
# of its ends. The text sits across the link's run outside the tree, the line
# broken under it, where that run is long enough; beside the run otherwise.
class LinkLabelTest < Minitest::Test
  LONG = "[CP [NP what+>1\"*\"] [C' [C did] [TP [DP you] [VP [V buy] [NP t+1]]]]]"
  SHORT = "[S [NP a+>1\"too<>long<>to<>fit\"] [VP b+1]]"

  def svg(data, **opts)
    RSyntaxTree::RSGenerator.new(data: data, format: "svg", **opts).draw_svg
  end

  def link_paths(doc)
    doc.scan(/<path d='([^']+)' style='fill: none; stroke: #CC79A7/).flatten
  end

  # The link text: its position, size and content.
  def text(doc)
    m = doc.match(%r{<text x='([-\d.]+)' y='([-\d.]+)' text-anchor='middle'[^>]*font-size: ([\d.]+)px'>([^<]*)</text>})
    m && { x: m[1].to_f, y: m[2].to_f, size: m[3].to_f, content: m[4] }
  end

  # The y of the link's rail: the run outside the tree, the lowest one drawn.
  def rail_y(paths)
    paths.flat_map { |d| d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).map(&:last) }.max
  end

  def test_the_text_is_set_smaller_than_a_label
    doc = svg(LONG)
    label_size = doc[/font-size: ([\d.]+)px/, 1].to_f

    assert_equal "*", text(svg(LONG))[:content]
    assert_operator text(doc)[:size], :<, label_size
    refute_includes doc, "\"*\""
  end

  def test_on_a_long_run_the_line_is_broken_under_the_text
    doc = svg(LONG)
    paths = link_paths(doc)

    assert_equal 2, paths.size
    xs = paths.map { |d| d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).map(&:first) }
    gap = [xs[0].max, xs[1].min].sort
    assert_operator gap.first, :<, text(doc)[:x]
    assert_operator text(doc)[:x], :<, gap.last
  end

  def test_on_a_short_run_the_text_sits_outside_it
    doc = svg(SHORT)
    paths = link_paths(doc)

    assert_equal 1, paths.size
    assert_operator text(doc)[:y], :>, rail_y(paths)
  end

  def test_the_canvas_holds_the_text
    [{}, { direction: "btt" }, { direction: "ltr" }].each do |opts|
      [LONG, SHORT].each do |data|
        doc = svg(data, **opts)
        left, top, width, height = doc[/viewBox="([^"]+)"/, 1].split(/[ ,]+/).map(&:to_f)
        t = text(doc)

        refute_nil t, "#{data} #{opts}"
        assert_operator t[:x], :>, left, opts.inspect
        assert_operator t[:x], :<, left + width, opts.inspect
        assert_operator t[:y], :>, top, opts.inspect
        assert_operator t[:y], :<, top + height, opts.inspect
      end
    end
  end

  # Two links with texts keep their texts apart and off the labels.
  def test_texts_keep_clear_of_each_other
    data = "[CP [NP what+>1\"1\"] [C' [C did] [TP [DP you+>2\"2\"] [VP [DP t+2] [VP [V buy] [NP t+1]]]]]]"
    doc = svg(data)
    texts = doc.scan(%r{<text x='([-\d.]+)' y='([-\d.]+)' text-anchor='middle'[^>]*>([^<]*)</text>})

    assert_equal %w[1 2], texts.map(&:last).sort
    a, b = texts.map { |x, y, _| [x.to_f, y.to_f] }
    refute(((a[0] - b[0]).abs < 5) && ((a[1] - b[1]).abs < 5), "the two texts sit on each other")
  end

  def test_a_text_may_hold_a_plus_and_a_space
    doc = svg("[S [NP a+1\"x+y<>z\"] [VP b+1]]")

    assert_equal "x+y z", text(doc)[:content]
  end

  def test_json_records_the_text
    links = JSON.parse(RSyntaxTree::RSGenerator.new(data: LONG, format: "json").draw_json)["links"]

    assert_equal ["*"], links.map { |l| l["label"] }
  end

  def error(data)
    svg(data)
    nil
  rescue RSTError => e
    e
  end

  def test_only_a_link_carries_a_text_and_on_one_end
    assert_equal :link_label, error("[S [NP a+=1\"*\"] [VP b+=1]]").code
    assert_equal :link_label, error("[S [NP a+-1\"*\"] [VP b+-1]]").code
    assert_equal :link_label, error("[S [NP a+1\"*\"] [VP b+1\"x\"]]").code
  end

  # Quotes that follow no marker are part of the label, as before.
  def test_quotes_in_a_label_are_text
    doc = svg("[S [NP \"a\"] [VP b]]")

    assert_includes doc, "\"a\""
    assert_nil text(doc)
  end

  # A text wider than the tree is not cut off at either edge.
  def test_a_wide_text_stays_inside_the_canvas
    gen = RSyntaxTree::RSGenerator.new(data: "[S [A a+1\"WWWWWWWWWWWWWWWWWWWW\"] [B b+1]]", format: "svg")
    doc = gen.draw_svg
    left, _, width, = doc[/viewBox="([^"]+)"/, 1].split(/[ ,]+/).map(&:to_f)
    t = text(doc)
    family = gen.instance_variable_get(:@params)[:fontset][:family]
    half = FontMetrics.get_metrics("WWWWWWWWWWWWWWWWWWWW", family, t[:size], :normal, :normal).width / 2.0

    assert_operator t[:x] - half, :>, left
    assert_operator t[:x] + half, :<, left + width
  end

  # The text is drawn in the face it was measured in, and measured as it
  # reads: an ampersand is one character.
  def test_the_text_is_set_in_the_label_face
    doc = svg("[S [A a+1\"&\"] [M mid] [B b+1]]", fontstyle: "mono")

    assert_match(/<text [^>]*font-family="[^"]*Mono[^"]*"[^>]*>&amp;</, doc)
  end

  def test_a_backslash_n_inside_the_text_is_kept
    links = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S [A a+1\"x\\\\name\"] [B b+1]]", format: "json").draw_json)["links"]

    assert_equal ["x\\name"], links.map { |l| l["label"] }
  end

  def test_the_dashes_carry_on_past_the_text
    doc = svg("[S [A a+1\"*\"] [M middlemiddlemiddle] [B b+1]]")

    assert_match(/stroke-dashoffset='[\d.]+'/, doc)
  end

  def test_an_unclosed_text_is_named
    e = begin
      svg("[S [A a+1\"bad] [B b+1]]")
      nil
    rescue RSTError => err
      err
    end

    assert_equal :incomplete_marker, e.code
    assert_includes e.hint, "closing double quote"
  end

  # However many links crowd one short rail, no line runs through a text.
  def test_no_line_runs_through_a_text
    data = "[S [A a+1\"AAAAAAAA\"+2\"BBBBBBBB\"+3\"CCCCCCCC\"+4\"DDDDDDDD\"+5\"EEEEEEEE\"] [B b+1+2+3+4+5]]"
    [{}, { direction: "btt" }, { direction: "ltr" }].each do |opts|
      gen = RSyntaxTree::RSGenerator.new(data: data, format: "svg", **opts)
      doc = gen.draw_svg
      family = gen.instance_variable_get(:@params)[:fontset][:family]
      segments = link_paths(doc).flat_map do |d|
        d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).each_cons(2).to_a
      end
      texts = doc.scan(%r{<text x='([-\d.]+)' y='([-\d.]+)' text-anchor='middle'[^>]*font-size: ([\d.]+)px'>([^<]*)</text>})

      assert_equal 5, texts.size, opts.inspect
      texts.each do |x, y, size, content|
        half = FontMetrics.get_metrics(content, family, size.to_f, :normal, :normal).width / 2.0
        x0 = x.to_f - half
        x1 = x.to_f + half
        y0 = y.to_f - (size.to_f * 0.7)
        y1 = y.to_f
        crossed = segments.any? do |(ax, ay), (bx, by)|
          [ax, bx].max > x0 && [ax, bx].min < x1 && [ay, by].max > y0 && [ay, by].min < y1
        end
        refute crossed, "#{opts}: a line runs through #{content}"
      end
    end
  end

  # A text stays with its own link: beside the link's own ends before any
  # farther place, and clear of the tree's own lines.
  def test_a_text_stays_with_its_own_link_and_off_the_tree
    doc = svg("[S [A a+1\"subject\"+2\"object\"] [B b+1+2] [M middlemiddle] [C c+3\"*\"] [D d+3]]")
    texts = doc.scan(%r{<text x='([-\d.]+)' y='[-\d.]+' text-anchor='middle'[^>]*>([^<]*)</text>}).to_h { |x, t| [t, x.to_f] }
    middle = doc[/<tspan x='([-\d.]+)'[^>]*>middlemiddle</, 1].to_f

    assert_operator texts["subject"], :<, middle
    assert_operator texts["object"], :<, middle

    tall = svg("[S [A a+1\"long-distance<>movement\"] [B b+1] [C [D [E e]]]]", vheight: 3)
    x = tall[/<text x='([-\d.]+)' y='[-\d.]+' text-anchor='middle'/, 1].to_f
    edge = tall.scan(/<line[^>]*?x1='([-\d.]+)' y1='[-\d.]+' x2='([-\d.]+)'/).map { |a, b| [a.to_f, b.to_f] }
                .select { |a, b| (a - b).abs < 0.01 }.map(&:first).max
    half = FontMetrics.get_metrics("long-distance movement", "sans-serif", 27.2, :normal, :normal).width / 2.0

    refute_operator (x - edge).abs, :<, half, "the text runs over the tree's rightmost line"
  end

  # A straight connector between two nodes (+-N) stays off the text too.
  def test_a_straight_connector_stays_off_the_text
    gen = RSyntaxTree::RSGenerator.new(data: "[TP [DP Pat+1\"agreement\"+-2] [T will+1] [vP [VP [V win+-2]]]]", format: "svg")
    doc = gen.draw_svg
    family = gen.instance_variable_get(:@params)[:fontset][:family]
    t = text(doc)
    half = FontMetrics.get_metrics(t[:content], family, t[:size], :normal, :normal).width / 2.0
    x1, y1, x2, y2 = doc[/<line x1='[^>]*stroke: #CC79A7/].scan(/[xy][12]='([-\d.]+)'/).flatten.map(&:to_f)
    crossed = (0..200).any? do |i|
      px = x1 + ((x2 - x1) * i / 200.0)
      py = y1 + ((y2 - y1) * i / 200.0)
      px > t[:x] - half && px < t[:x] + half && py > t[:y] - (t[:size] * 0.7) && py < t[:y]
    end

    refute crossed
  end
end

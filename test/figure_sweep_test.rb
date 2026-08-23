# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"
require "nokogiri"

require_relative "../lib/rsyntaxtree"

# The figures that are hardest to lay out are the ones drawn with something
# outside an ordinary label: a derivation, whose rules and rule names reach
# past every box the layout measures, and a feature matrix, whose brackets and
# columns are sized from the text inside them. Both were built against a
# handful of inputs at the default settings, and both have already been caught
# putting ink outside the image at other settings.
#
# So rather than more inputs at one size, this sweeps the settings a reader
# actually changes over the figures those settings are hardest on, and asks of
# each drawing the questions that do not depend on what was drawn: is it well
# formed, is every mark inside the image, do labels on a row stay off each
# other, and — for a derivation — are the premises still in one row.
class FigureSweepTest < Minitest::Test
  # Two of these come from the gallery, where they are checked at one setting.
  DERIVATIONS = {
    application: ['[S\t< [NP\t> [NP/N the] [N dog]] ' \
                 '[S\\\\NP\t> [(S\\\\NP)/NP bit] [NP John]]]', 4],
    raising: ['[S\t> [S/NP\t>B [S/(S\\\\NP)\t>T [NP\t> [NP/N the] [N dog]]] ' \
             '[(S\\\\NP)/NP bit]] [NP John]]', 4],
    relative: ['[NP\t> [NP/N the] [N\t< [N man] [N\\\\N\t> [(N\\\\N)/(S/NP) that] ' \
              '[S/NP\t>B [S/(S\\\\NP)\t>T [NP Mary]] [(S\\\\NP)/NP saw]]]]]', 5],
    coordination: ['[S\t> [S/NP\t<Φ> [S/NP\t>B [S/(S\\\\NP)\t>T [NP Mary]] ' \
                  '[(S\\\\NP)/NP likes]] [conj and] ' \
                  '[S/NP\t>B [S/(S\\\\NP)\t>T [NP Bill]] [(S\\\\NP)/NP hates]]] [NP London]]', 6],
    # A step with a name long enough that the room kept for it is not lost in
    # the padding, which is how the name came to be cut off at the image edge.
    long_name: ['[S\t>B-forward-composition [NP the cat] [VP sat]]', 2],
    # One word, one step: the smallest derivation there is.
    single_step: ['[NP\t>T [N dog]]', 1]
  }.freeze

  # The two deepest matrices in the gallery, read from the gallery itself so
  # that the sweep is over the figures that are actually published and cannot
  # drift from them, and one of what HPSG does with matrices that the gallery
  # has no example of: matrices as the nodes of a tree.
  def self.from_gallery(name)
    File.read(File.expand_path("../docs/_examples/#{name}.md", __dir__))
        .scan(/```([^`]+)```/m).last.first
  end

  MATRICES = {
    nested: from_gallery("076"),
    f_structure: from_gallery("078"),
    in_a_tree: '[#(CAT\tS\nVAL\t⟨⟩#) [#(CAT\tNP#) Kim] ' \
               '[#(CAT\tVP\nVAL\t⟨|1|⟩#) [#(CAT\tV#) sleeps]]]',
    # A label that is nothing but a matrix, which is measured as a decoration
    # on the run rather than as the node's own enclosure and so goes down a
    # different path from the two above. Kept flat on purpose: a matrix nested
    # inside brings padding of its own, which covered the shortfall that a
    # plain one exposes.
    whole_label: '[#(CAT\tS\nVAL\t⟨⟩#)]'
  }.freeze

  # A hyphen opens an underline, and the deepest of these has RELIED-ON in it,
  # so they are drawn the way the gallery draws them.
  MATRIX_BASE = { hyphen: "literal" }.freeze

  # One setting moved at a time from the default, so a drawing that fails says
  # which setting it failed at. The cross of size and face is swept separately
  # below, because those two together are what text measurement turns on.
  def self.settings
    sets = { "default" => {} }
    [6, 10, 16, 22, 26].each { |s| sets["fontsize #{s}"] = { fontsize: s } }
    %w[sans serif mono cjk].each { |f| sets["font #{f}"] = { fontstyle: f } }
    %w[off low medium high symmetric].each { |t| sets["tidy #{t}"] = { tidy: t } }
    [0.5, 1.0, 3.0].each { |h| sets["hspacing #{h}"] = { hspacing: h } }
    [0.5, 1.0, 5.0].each { |v| sets["vheight #{v}"] = { vheight: v } }
    [0.5, 3.0].each { |w| sets["linewidth #{w}"] = { linewidth: w } }
    %w[on off].each { |p| sets["polyline #{p}"] = { polyline: p } }
    %w[modern traditional gray off].each { |c| sets["color #{c}"] = { color: c } }
    sets["mirror"] = { mirror: "on" }
    sets["symmetrize"] = { symmetrize: "on" }
    sets
  end
  SETTINGS = settings.freeze

  # Ink may sit this far outside the image before it counts as outside it. Text
  # is measured through the host's fontconfig, so a boundary is good to about a
  # pixel; the same reasoning as OverlapTest's tolerance.
  MARGIN = 2.0

  def test_derivations_survive_every_setting
    DERIVATIONS.each do |name, (data, words)|
      SETTINGS.each do |label, opts|
        where = "#{name} at #{label}"
        svg = draw(data, derivation: "on", direction: "btt", leafstyle: "nothing", **opts)
        assert_well_formed svg, where
        assert_everything_inside_the_image svg, where
        assert_the_premises_are_in_one_row svg, words, where
      end
    end
  end

  # A derivation drawn the other way up is the same figure with the result on
  # top, so it has to hold up under the same sweep.
  def test_derivations_survive_every_setting_the_other_way_up
    DERIVATIONS.each do |name, (data, _words)|
      SETTINGS.each do |label, opts|
        svg = draw(data, derivation: "on", direction: "ttb", leafstyle: "nothing", **opts)
        assert_everything_inside_the_image svg, "#{name} ttb at #{label}"
      end
    end
  end

  def test_matrices_survive_every_setting
    MATRICES.each do |name, data|
      SETTINGS.each do |label, opts|
        where = "#{name} at #{label}"
        svg = draw(data, **MATRIX_BASE, **opts)
        assert_well_formed svg, where
        assert_everything_inside_the_image svg, where
        assert_no_connector_crosses_a_label svg, where
      end
    end
  end

  # Size and face together are what every measurement turns on, so those two
  # are swept against each other rather than one at a time.
  def test_every_size_in_every_face
    [6, 10, 16, 22, 26].each do |size|
      %w[sans serif mono cjk].each do |face|
        opts = { fontsize: size, fontstyle: face }
        DERIVATIONS.each do |name, (data, words)|
          svg = draw(data, derivation: "on", direction: "btt", leafstyle: "nothing", **opts)
          assert_everything_inside_the_image svg, "#{name} at #{size}px #{face}"
          assert_the_premises_are_in_one_row svg, words, "#{name} at #{size}px #{face}"
        end
        MATRICES.each do |name, data|
          assert_everything_inside_the_image draw(data, **MATRIX_BASE, **opts),
                                            "#{name} at #{size}px #{face}"
        end
      end
    end
  end

  # Labels on one row of a matrix-bearing tree must stay off each other however
  # wide the settings make them. Read from the interchange format, which is
  # where the layout says where it put things.
  def test_matrix_nodes_do_not_run_into_each_other
    SETTINGS.each do |label, opts|
      next if opts[:fontstyle] == "cjk" # measured wider; the tree is Latin

      lsif = JSON.parse(
        RSyntaxTree::RSGenerator.new(
          DEFAULT_OPTS.merge(data: MATRICES[:in_a_tree], format: "lsif").merge(MATRIX_BASE).merge(opts)
        ).draw_lsif
      )
      rows = lsif["nodes"].group_by { |n| n["level"] }
      rows.each_value do |row|
        row.sort_by { |n| n["position"]["x"] }.each_cons(2) do |a, b|
          gap = b["position"]["x"] - (a["position"]["x"] + a["position"]["content_width"])
          assert_operator gap, :>=, -MARGIN,
                          "at #{label}: '#{a["label"]["raw"]}' runs into '#{b["label"]["raw"]}'"
        end
      end
    end
  end

  # A node is as tall as what is written in it. The tree places the next level
  # by that height, so a node measured short of its own contents pulls its
  # daughters up into them — which is what a feature matrix did: every row of a
  # label is given a margin above it that holds the text clear of the connector
  # coming down, and the row holding a matrix was measured without it.
  #
  # Drawn alone, all the ink in the figure belongs to the one node, so the two
  # can be compared without having to work out which mark belongs to whom.
  def test_a_node_is_as_tall_as_what_is_written_in_it
    %i[nested f_structure whole_label].each do |name|
      SETTINGS.each do |label, opts|
        data = MATRICES[name]
        where = "#{name} at #{label}"
        lsif = JSON.parse(
          RSyntaxTree::RSGenerator.new(
            DEFAULT_OPTS.merge(data: data, format: "lsif").merge(MATRIX_BASE).merge(opts)
          ).draw_lsif
        )
        node = lsif["nodes"].first
        bottom = node["position"]["y"] + node["position"]["content_height"]
        ink = ink_bottom(draw(data, **MATRIX_BASE, **opts))
        next unless ink

        assert_operator bottom, :>=, ink - MARGIN,
                        "#{where}: the node is #{(ink - bottom).round(1)} shorter than " \
                        "what is written in it"
      end
    end
  end

  private

  # The distance from the bottom of each mother to the top of each daughter,
  # read from the interchange format, which is where the layout says where it
  # put things.
  def parent_to_daughter_gaps(data, **opts)
    lsif = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: data, format: "lsif").merge(opts)
      ).draw_lsif
    )
    by_id = lsif["nodes"].to_h { |n| [n["id"], n] }
    lsif["edges"].map do |e|
      mother = by_id[e["from"]]
      daughter = by_id[e["to"]]
      next unless mother && daughter

      (daughter["position"]["y"] -
        (mother["position"]["y"] + mother["position"]["content_height"])).round(2)
    end.compact
  end

  # How far down the page the ink of a drawing reaches.
  def ink_bottom(svg)
    doc = Nokogiri::XML(svg)
    doc.css("tspan").reject { |t| t.ancestors("defs").any? }.filter_map do |t|
      next unless t["x"] && t["y"] && !t.text.strip.empty?

      metrics = FontMetrics.get_metrics(t.text, text_family(t), font_size(t), :normal, :normal)
      t["y"].to_f - metrics.ink_above + metrics.ink_height
    end.max
  end

  def draw(data, **opts)
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: data).merge(opts)).draw_svg
  end

  def assert_well_formed(svg, where)
    doc = Nokogiri::XML(svg) { |c| c.strict.nonet }
    assert_empty doc.errors, "#{where}: the drawing is not well-formed XML"
    refute_match(/NaN|Infinity/, svg, "#{where}: the drawing has a number that is not one")
  end

  # Everything drawn belongs inside the image. Anything that reaches past the
  # edge is cut off there, and the reader is given a figure with a piece
  # missing rather than an error — which is how a long rule name was lost.
  def assert_everything_inside_the_image(svg, where)
    doc = Nokogiri::XML(svg)
    box = doc.root["viewBox"].split(/[\s,]+/).map(&:to_f)
    left = box[0]
    top = box[1]
    right = left + box[2]
    bottom = top + box[3]

    each_mark(doc) do |what, x1, y1, x2, y2|
      assert_operator x1, :>=, left - MARGIN, "#{where}: a #{what} starts left of the image"
      assert_operator x2, :<=, right + MARGIN, "#{where}: a #{what} reaches past the right edge"
      assert_operator y1, :>=, top - MARGIN, "#{where}: a #{what} sits above the image"
      assert_operator y2, :<=, bottom + MARGIN, "#{where}: a #{what} reaches below the image"
    end
  end

  # The extent of every mark the drawing makes, skipping the markers and
  # patterns in <defs>, which are drawn in their own coordinates wherever they
  # are referenced.
  def each_mark(doc)
    doc.css("line, polyline, rect, path, circle, ellipse, text, tspan").each do |el|
      next if el.ancestors("defs").any?

      case el.name
      when "line"
        xs = [el["x1"], el["x2"]].map(&:to_f)
        ys = [el["y1"], el["y2"]].map(&:to_f)
        yield "line", xs.min, ys.min, xs.max, ys.max
      when "rect"
        x = el["x"].to_f
        y = el["y"].to_f
        yield "rect", x, y, x + el["width"].to_f, y + el["height"].to_f
      when "polyline", "path"
        # A path's numbers are its points in order, which is enough to bound it
        # — a curve stays inside the hull of the points that draw it, so a hull
        # inside the image puts the curve inside it too.
        source = el.name == "path" ? el["d"] : el["points"]
        pts = source.to_s.scan(/-?[\d.]+/).map(&:to_f).each_slice(2).to_a
        next if pts.empty? || pts.last.size < 2

        yield el.name, pts.map(&:first).min, pts.map(&:last).min,
              pts.map(&:first).max, pts.map(&:last).max
      when "circle", "ellipse"
        cx = el["cx"].to_f
        cy = el["cy"].to_f
        rx = (el["r"] || el["rx"]).to_f
        ry = (el["r"] || el["ry"]).to_f
        yield el.name, cx - rx, cy - ry, cx + rx, cy + ry
      else
        # A tspan carries its own x when it is placed; otherwise it runs on
        # from its text. Only the placed ones locate anything by themselves.
        next unless el["x"] && el["y"]

        x = el["x"].to_f
        y = el["y"].to_f
        # Measured with the engine that laid the text out, so this is the width
        # the drawing itself used, not an estimate of it.
        w = text_width(el)
        # y is the baseline. What rises above it is at most the line, and what
        # falls below it is a descender; both are inside one line height.
        line = font_size(el) * FontMetrics::LINE_HEIGHT_FACTOR
        yield "text", x, y - line, x + w, y + line / 2
      end
    end
  end

  def font_size(el)
    style = [el["style"], el.parent && el.parent["style"]].compact.join(";")
    (style[/font-size:\s*([\d.]+)px/, 1] || DEFAULT_OPTS[:fontsize]).to_f
  end

  # Measured in the weight and slant it is drawn in: bold text is wider than
  # the same string set normal, so measuring everything normal would let a bold
  # label reach past the edge unnoticed.
  # The family list the run is drawn with, in the form Pango takes, so a string
  # is measured with the faces it was set in.
  def text_family(el)
    style = [el["style"], el.parent && el.parent["style"]].compact.join(";")
    family = style[/font-family:\s*([^;]+)/, 1].to_s.tr("'\"", "").strip
    family.empty? ? FontFamily.for_pango(:sans) : family
  end

  def text_width(el)
    style = [el["style"], el.parent && el.parent["style"]].compact.join(";")
    family = text_family(el)
    weight = style.include?("font-weight: bold") ? :bold : :normal
    slant = style.include?("font-style: italic") ? :italic : :normal
    FontMetrics.get_metrics(el.text, family, font_size(el), weight, slant).width
  end

  # A connector joins one label to another and belongs in the space between
  # them. A label that is one whole feature matrix keeps its text inside the
  # matrix and left none of it at the top level, so the node read as an empty
  # one — a pass-through joint, the kind a `<>` chain makes — and the lines
  # were run to the middle of it, straight through the rows written there.
  def assert_no_connector_crosses_a_label(svg, where)
    doc = Nokogiri::XML(svg)
    boxes = doc.css("tspan").reject { |t| t.ancestors("defs").any? }.filter_map do |t|
      next unless t["x"] && t["y"] && !t.text.strip.empty?

      size = font_size(t)
      x = t["x"].to_f
      y = t["y"].to_f
      # Kept to the ink rather than the line box: a connector may pass through
      # the leading above a label without touching what is written there.
      [t.text, x, y - size * 0.72, x + text_width(t), y + size * 0.05]
    end
    doc.css("line").reject { |l| l.ancestors("defs").any? }.each do |l|
      x1 = l["x1"].to_f
      y1 = l["y1"].to_f
      x2 = l["x2"].to_f
      y2 = l["y2"].to_f
      boxes.each do |text, bx1, by1, bx2, by2|
        refute segment_enters?(x1, y1, x2, y2, bx1, by1, bx2, by2),
               "#{where}: a connector runs through '#{text}'"
      end
    end
  end

  # Walked rather than solved: a segment that enters a rectangle at all has a
  # point well inside it, and stepping along it finds that point without a
  # clipping routine to get wrong.
  def segment_enters?(x1, y1, x2, y2, bx1, by1, bx2, by2)
    40.times do |i|
      t = i / 39.0
      x = x1 + (x2 - x1) * t
      y = y1 + (y2 - y1) * t
      return true if x > bx1 + 0.5 && x < bx2 - 0.5 && y > by1 + 0.5 && y < by2 - 0.5
    end
    false
  end

  # However many steps each premise takes to combine, all of them are given at
  # the start, so every word stands in the top row — all of them, counted.
  #
  # Asking instead that no row below be fuller than the top one lets a figure
  # through whose top row merely ties with another: a derivation of four words
  # in which two of them have slipped down passes that reading while looking
  # like a staircase. Counting against the number of words is what closes it,
  # and a one-word derivation, which no arrangement can spread over two rows,
  # is then checked rather than trivially passed.
  def assert_the_premises_are_in_one_row(svg, words, where)
    doc = Nokogiri::XML(svg)
    ys = doc.css("tspan").reject { |t| t.ancestors("defs").any? }
            .filter_map { |t| t["y"]&.to_f }
    refute_empty ys, "#{where}: nothing was drawn"

    top = ys.min
    assert_equal words, ys.count { |y| (y - top).abs < 1.0 },
                 "#{where}: the premises are not all in one row"
  end
end

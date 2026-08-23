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
    single_step: ['[NP\t>T [N dog]]', 1],
    # A pass-through joint in a derivation: a node with nothing written in it,
    # which the drawing runs the connectors straight through.
    joint: ['[S\t< [NP\t> [<> [N deep]]] [VP sat]]', 2],
    # Six premises under one rule, which is what the rule has to reach across.
    wide: ['[S\t<Φ> [A a] [B b] [C c] [D d] [E e] [F f]]', 6],
    # Categories written as feature structures, which is where the rows, the
    # bands the rules are placed from, the packing and the turn all meet: a
    # matrix is taller than the categories beside it, so it is the label that
    # finds out whether a row is a row.
    with_matrices: ['[S\t< [#(CAT\tNP\nNUM\tsg#)\t> [NP/N the] [N dog]] ' \
                    '[S\\\\NP\t> [(S\\\\NP)/NP bit] [NP John]]]', 4]
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

  # Ordinary trees whose drawing reaches outside the labels: a region shaded
  # behind a whole subtree, which is drawn with a padding of its own and has to
  # be counted into the canvas, and a chain of joints, which the connectors run
  # straight through.
  TREES = {
    region: "[S [%NP [D the] [N dog]] [VP sat]]",
    region_coloured: "[S [%@blue:NP [D the] [N dog]] [%@red:VP sat]]",
    joints: "[S [NP [<> [<> [N deep]]]] [VP sat]]",
    wide: "[S [A a] [B b] [C c] [D d] [E e] [F f]]"
  }.freeze

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
        svg = draw(data, derivation: "on", direction: "btt", leafstyle: "nothing",
                   **MATRIX_BASE, **opts)
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
        svg = draw(data, derivation: "on", direction: "ttb", leafstyle: "nothing",
                   **MATRIX_BASE, **opts)
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

  def test_trees_survive_every_setting
    TREES.each do |name, data|
      SETTINGS.each do |label, opts|
        where = "#{name} at #{label}"
        svg = draw(data, **opts)
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
          svg = draw(data, derivation: "on", direction: "btt", leafstyle: "nothing",
                     **MATRIX_BASE, **opts)
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

  # The height a label is measured at and the height it is drawn at are worked
  # out by two pieces of code, and two pieces of code that answer one question
  # drift. They differ here by a fixed amount — the drawing reckons from the
  # top of the bracket, the tree from the top edge of the node — and that
  # amount is the same for every kind of label there is. A label kind that
  # comes out at some other figure is one the two have stopped agreeing about,
  # which is how a feature matrix went a whole margin astray.
  def test_the_two_reckonings_of_a_label_differ_by_one_fixed_amount
    kinds = MATRICES.values + [
      "[S [NP Kim] [VP [V sleeps]]]",
      "[#S [#NP Kim] [##VP z]]",
      '[S [NP ^triangle] [VP |1| [V {2}]]]',
      '[S [NP a\nb] [VP *bold* [V _sub_]]]',
      "[S [NP <> ] [VP z]]"
    ]
    [10, 16, 26].each do |size|
      ratios = kinds.flat_map { |data| measured_to_drawn_ratios(data, fontsize: size) }
      assert_equal 1, ratios.uniq.size,
                   "at #{size}px the two reckonings differ by #{ratios.uniq.sort.inspect} " \
                   "of a connector gap, not by one amount"
    end
  end

  # A label is measured by what is written in it, not by what is written
  # elsewhere in the figure. Measurement used to put the CJK face first for the
  # whole figure as soon as any character outside ASCII turned up anywhere in
  # it — a Greek letter, an angle bracket, an accented vowel — while the drawing
  # went on using the ordinary one. Latin text was then measured in a face it
  # was not set in, and in the monospaced style, where the two differ most, the
  # run after it was drawn on top of it.
  def test_a_label_is_measured_by_itself_and_not_by_its_neighbours
    %w[sans serif mono cjk].each do |face|
      [16, 26].each do |size|
        opts = { fontstyle: face, fontsize: size }
        alone = label_width("[S [NP relies]]", **opts)
        ["θ", "⟨⟩", "é", "−"].each do |mark|
          beside = label_width("[S [NP relies] [VP #{mark}]]", **opts)
          assert_in_delta alone, beside, 0.01,
                          "#{face} #{size}px: '#{mark}' elsewhere in the figure changed " \
                          "how 'relies' was measured"
        end
      end
    end
  end

  # Mirroring turns the figure over, and turning it over is all it does: every
  # label ends up as far from the right edge as it stood from the left. The
  # packing runs before the turn, so the two must not depend on each other —
  # a contour read after the turn, or a turn that moved a subtree instead of
  # reflecting it, would show here as the figures failing to line up.
  def test_mirroring_reflects_the_figure_whatever_the_packing
    %w[off low medium high symmetric].each do |tidy|
      TREES.each_value do |data|
        plain = node_extents(data, tidy: tidy)
        turned = node_extents(data, tidy: tidy, mirror: "on")
        # Reflection about any axis leaves this sum the same for every node,
        # so it is read off the figures rather than assumed.
        sums = plain.filter_map do |id, (x, _)|
          turned[id] && (turned[id].sum + x).round(3)
        end
        refute_empty sums
        assert_in_delta sums.min, sums.max, 0.5,
                        "tidy #{tidy}: mirroring did not reflect the figure"
      end
    end
  end

  # A region covers the subtree it is put on: all of it, and none of what
  # stands beside it. The shade is drawn behind the tree with a padding of its
  # own, so the packing has to leave room for it however tightly it packs.
  def test_a_region_covers_its_subtree_and_no_more
    %w[off low medium high symmetric].each do |tidy|
      { "[S [%NP [D the] [N dog]] [VP [V chased] [NP [D a] [N cat]]]]" => 5,
        "[S [%A [B [C [D deep]]]] [E e]]" => 5,
        "[%S [NP a] [VP b]]" => 5,
        "[S [%A [a1 x] [a2 y] [a3 z]] [B b]]" => 7 }.each do |data, labels|
        doc = Nokogiri::XML(draw(data, tidy: tidy))
        canvas = doc.root["viewBox"].split(/[\s,]+/).map(&:to_f)[2]
        shades = doc.css("rect").reject do |r|
          r.ancestors("defs").any? || r["width"].to_f >= canvas - 1
        end
        assert_equal 1, shades.size, "tidy #{tidy}: expected one region"

        inside, touching = region_tally(doc, shades.first)
        assert_equal labels, inside,
                     "tidy #{tidy}: the region covers #{inside} labels of #{labels}"
        assert_equal inside, touching,
                     "tidy #{tidy}: the region cuts across a label beside it"
      end
    end
  end

  private

  # The width the layout gave the label 'relies', read from the interchange
  # format, which reports what the measuring — not the drawing — arrived at.
  def label_width(data, **opts)
    lsif = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: data, format: "lsif").merge(opts)
      ).draw_lsif
    )
    node = lsif["nodes"].find { |n| n["label"]["raw"].to_s.include?("relies") }
    refute_nil node
    node["position"]["content_width"]
  end

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

  # Where each node sits and how wide it is, read from the interchange format.
  def node_extents(data, **opts)
    lsif = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: data, format: "lsif").merge(opts)
      ).draw_lsif
    )
    lsif["nodes"].to_h { |n| [n["id"], [n["position"]["x"], n["position"]["content_width"]]] }
  end

  # How many labels a shade holds, and how many it reaches at all. The two are
  # the same when it covers whole labels and cuts across none.
  def region_tally(doc, shade)
    x1 = shade["x"].to_f
    y1 = shade["y"].to_f
    x2 = x1 + shade["width"].to_f
    y2 = y1 + shade["height"].to_f
    inside = 0
    touching = 0
    doc.css("tspan").reject { |t| t.ancestors("defs").any? }.each do |t|
      next unless t["x"] && t["y"] && inked?(t.text)

      metrics = run_metrics(t)
      left = t["x"].to_f
      right = left + metrics.width
      top = t["y"].to_f - metrics.ink_above
      bottom = top + metrics.ink_height
      next unless left < x2 && right > x1 && top < y2 && bottom > y1

      touching += 1
      inside += 1 if left >= x1 - 1 && right <= x2 + 1 && top >= y1 - 1 && bottom <= y2 + 1
    end
    [inside, touching]
  end

  # Whether a run puts any ink on the page. A `<>` in the input becomes a run of
  # the whitespace block, which stands for the space it asks for and is drawn
  # with nothing in it — a node made only of those is the pass-through joint
  # that connectors are meant to run straight through.
  def inked?(text)
    !text.gsub(WHITESPACE_BLOCK, "").strip.empty?
  end

  # How far down the page the ink of a drawing reaches.
  def ink_bottom(svg)
    doc = Nokogiri::XML(svg)
    doc.css("tspan").reject { |t| t.ancestors("defs").any? }.filter_map do |t|
      next unless t["x"] && t["y"] && inked?(t.text)

      metrics = run_metrics(t)
      t["y"].to_f - metrics.ink_above + metrics.ink_height
    end.max
  end

  # For every node: how far the drawn height sits from the measured one, in
  # connector gaps. Reached through the parser and the drawing directly, since
  # the measured height is what the tree lays out with and the drawn one is
  # only known once the label has been drawn.
  def measured_to_drawn_ratios(data, **opts)
    params = DEFAULT_OPTS.merge(data: data, hyphen: "literal").merge(opts)
    generator = RSyntaxTree::RSGenerator.new(params)
    global = generator.instance_variable_get(:@global)
    resolved = generator.instance_variable_get(:@params)
    parser = RSyntaxTree::StringParser.new(resolved[:data].clone, resolved[:fontset],
                                           resolved[:fontsize], global)
    parser.parse
    elements = parser.get_elementlist
    measured = elements.get_elements.map(&:content_height)
    RSyntaxTree::SVGGraph.new(elements, resolved, global).svg_data
    gap = global[:height_connector_to_text]
    elements.get_elements.map.with_index do |element, i|
      ((element.content_height - measured[i]) / gap).round(3)
    end
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

  # A run set smaller than the line — a subscript, a superscript — is given its
  # size as a percentage of the size around it rather than in pixels, and a
  # reading that knows only pixels measured those at full size.
  def font_size(el)
    own = el["style"].to_s
    around = (el.parent && el.parent["style"]).to_s
    outer = (around[/font-size:\s*([\d.]+)px/, 1] || DEFAULT_OPTS[:fontsize] * FONT_SCALING).to_f
    if (share = own[/font-size:\s*([\d.]+)%/, 1])
      outer * share.to_f / 100
    else
      (own[/font-size:\s*([\d.]+)px/, 1] || outer).to_f
    end
  end

  # Measured in the weight and slant it is drawn in: bold text is wider than
  # the same string set normal, so measuring everything normal would let a bold
  # label reach past the edge unnoticed.
  # The family list the run is drawn with, in the form Pango takes, so a string
  # is measured with the faces it was set in.
  def text_family(el)
    # The drawing sets the family as an attribute of its own, not inside the
    # style, and only looking in the style measured every face as the sans one:
    # a monospaced label came out wider than it is drawn, which reads as marks
    # running into each other that never touch.
    found = [el, el.parent].compact.filter_map do |node|
      node["font-family"] || node["style"].to_s[/font-family:\s*([^;]+)/, 1]
    end.first.to_s.tr("'\"", "").strip
    found.empty? ? FontFamily.for_pango(:sans) : found
  end

  # Every measurement of a run goes through here, in the face, size, weight and
  # slant it is drawn in. Three places used to measure, and only one of them
  # read the weight and the slant — one rule, three implementations, two of
  # them quietly narrower than what is on the page.
  def run_metrics(el)
    style = [el["style"], el.parent && el.parent["style"]].compact.join(";")
    FontMetrics.get_metrics(el.text, text_family(el), font_size(el),
                            style.include?("font-weight: bold") ? :bold : :normal,
                            style.include?("font-style: italic") ? :italic : :normal)
  end

  def text_width(el)
    run_metrics(el).width
  end

  # A connector joins one label to another and belongs in the space between
  # them. A label that is one whole feature matrix keeps its text inside the
  # matrix and left none of it at the top level, so the node read as an empty
  # one — a pass-through joint, the kind a `<>` chain makes — and the lines
  # were run to the middle of it, straight through the rows written there.
  def assert_no_connector_crosses_a_label(svg, where)
    doc = Nokogiri::XML(svg)
    boxes = doc.css("tspan").reject { |t| t.ancestors("defs").any? }.filter_map do |t|
      next unless t["x"] && t["y"] && inked?(t.text)

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

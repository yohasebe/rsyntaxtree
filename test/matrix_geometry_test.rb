# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# A matrix is drawn from sizes measured somewhere else, so a block can be put
# where there is no room for it and nothing complains: the figure is produced,
# and two pieces of ink stand on the same spot. That is how the bracket of a
# nested matrix came to be drawn over the tag before it — `AGR |1| [ ... ]`,
# which is how a shared value is written, put the two on the same coordinate
# exactly.
#
# Reading the drawn shapes back out of the SVG is what notices. It asks the
# one question a measurement mistake always answers wrongly: does anything
# overlap anything else?
class MatrixGeometryTest < Minitest::Test
  # The shapes whose boxes are meant to stay clear of one another. Text is
  # left out: glyphs are allowed to sit inside a bracket or a box, and their
  # boxes overlap by design.
  FIGURES = {
    "a tag before a nested matrix" => '[#(HEAD\t|1|#(verb\n---\nAGR\t|2|#)#)]',
    "a tag at the end of a row" => '[#(HEAD\tverb\nAGR\t|1|#)]',
    "two blocks in one cell" => '[#(A\t#(B\tc#)#(D\te#)#)]',
    "a matrix opening a column" => '[#(SYN\t#(HEAD\tnoun\n---\nAGR\tsg#)#)]',
    "matrices down a tree" => '[#(phrase\n---\nCAT\tS#) [#(word\n---\nCAT\tNP\nAGR\t|1|#(agr\n---\nNUM\tsg#)#) a]]'
  }.freeze

  # x1, y1, x2, y2 of every box and every bracket the SVG draws.
  def drawn_shapes(svg)
    boxes = svg.scan(/<rect style='[^']*stroke:[^']*'\s*x='([\d.]+)'\s*y='([\d.]+)'\s*width='([\d.]+)'\s*height='([\d.]+)'/m)
               .map { |x, y, w, h| [x.to_f, y.to_f, x.to_f + w.to_f, y.to_f + h.to_f] }
    brackets = svg.scan(/<polyline[^>]*points='([^']+)'/).flatten.map do |points|
      n = points.split(/[\s,]+/).map(&:to_f)
      xs = n.each_slice(2).map(&:first)
      ys = n.each_slice(2).map(&:last)
      [xs.min, ys.min, xs.max, ys.max]
    end
    boxes + brackets
  end

  # Touching counts, and so does all but touching. The defect this was
  # written for put the right edge of a box and the left edge of a bracket
  # on the same coordinate — ink that never overlaps and still reads as one
  # smudge. Whether the arithmetic lands on the same float or a hair apart
  # is not something a figure should depend on, so anything closer than this
  # is read as a shared edge.
  CLEARANCE = 0.001

  def overlap?(a, b)
    a[0] - b[2] <= CLEARANCE && b[0] - a[2] <= CLEARANCE &&
      a[1] - b[3] <= CLEARANCE && b[1] - a[3] <= CLEARANCE
  end

  def test_nothing_drawn_in_a_matrix_lands_on_anything_else
    FIGURES.each do |what, data|
      svg = RSyntaxTree::RSGenerator.new(data: data, format: "svg",
                                         fontstyle: "noto-serif", fontsize: "16",
                                         color: "none").draw_svg
      shapes = drawn_shapes(svg)
      refute_empty shapes, "#{what}: nothing was drawn to check"

      collisions = shapes.combination(2).select { |a, b| overlap?(a, b) }
      assert_empty collisions,
                   "#{what}: #{collisions.size} pair(s) of shapes drawn on top of each other"
    end
  end
end

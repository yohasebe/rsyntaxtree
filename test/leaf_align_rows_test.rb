# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"

# Aligned leaves share a depth, and every depth is drawn as one row: a label
# of two lines, a leaf pulled up under leafstyle nothing, or — drawn left to
# right — a level as wide as its widest label leaves no word out of line.
class LeafAlignRowsTest < Minitest::Test
  TREES = {
    "a moved phrase" => ["[CP [DP what+>1] [C' [C did] [TP [DP [D the] [NP [N child]]] [T' [T t] [VP [V find] [DP t+1]]]]]]", {}],
    "a label of two lines" => ['[S [A\nX a] [B [C c]]]', {}],
    "leaves pulled up" => ["[S [A a] [B [b] [c]]]", { leafstyle: "nothing" }]
  }.freeze

  def nodes(tree, options)
    json = RSyntaxTree::RSGenerator.new({ data: tree, format: "json" }.merge(options)).draw_json
    JSON.parse(json)["nodes"]
  end

  TREES.each do |what, (tree, extra)|
    %w[ttb btt ltr].each do |direction|
      %w[words subtrees].each do |mode|
        define_method "test_#{what.tr(" ", "_")}_#{direction}_#{mode}" do
          all = nodes(tree, extra.merge(direction: direction, leaf_align: mode))
          axis = direction == "ltr" ? "x" : "y"
          leaves = all.select { |n| n["type"] == "leaf" }

          assert_operator leaves.size, :>, 1
          assert_equal 1, leaves.map { |n| n["position"][axis] }.uniq.size

          # Turned over, a row is set against its labels' lower edges.
          edge = if direction == "btt"
                   ->(n) { (n["position"]["y"] + n["position"]["content_height"]).round(3) }
                 else
                   ->(n) { n["position"][axis] }
                 end
          all.group_by { |n| n["level"] }.each do |level, row|
            assert_equal 1, row.map(&edge).uniq.size, "level #{level}"
          end
        end
      end
    end
  end

  # A word set lower than the rest of its row leaves room beside a tall label
  # on the rows above, and packing by the labels alone set a neighbour's
  # branch through it: here the one down to the preposition, beside the
  # verb's matrix.
  MATRICES = "[S [NP [#(pos\\tADJ\\nCase\\tNom\\nDegree\\tPos\\nGender\\tMasc\\nNumber\\tSing#) Старый] " \
             "[#(pos\\tNOUN\\nAnimacy\\tAnim\\nCase\\tNom\\nGender\\tMasc\\nNumber\\tSing#) профессор]] " \
             "[#(pos\\tVERB\\nAspect\\tImp\\nGender\\tMasc\\nMood\\tInd\\nNumber\\tSing\\nTense\\tPast\\nVerbForm\\tFin\\nVoice\\tAct#) читал] " \
             "[NP [#(pos\\tADP#) в] [#(pos\\tNOUN\\nAnimacy\\tInan\\nCase\\tLoc\\nGender\\tFem\\nNumber\\tSing#) библиотеке]] " \
             "[NP [#(pos\\tADJ\\nCase\\tAcc\\nDegree\\tPos\\nGender\\tFem\\nNumber\\tSing#) интересную] " \
             "[#(pos\\tNOUN\\nAnimacy\\tInan\\nCase\\tAcc\\nGender\\tFem\\nNumber\\tSing#) книгу]]]"

  def test_a_branch_keeps_out_of_a_tall_label_beside_it
    %w[low medium high].each do |tidy|
      svg = RSyntaxTree::RSGenerator.new(data: MATRICES, format: "svg", polyline: "on", tidy: tidy,
                                         leaf_align: "words").draw_svg
      shapes = svg.scan(/<polyline[^>]*points='([^']*)'/).map do |(points)|
        points.scan(/-?[\d.]+/).map(&:to_f).each_slice(2).to_a
      end
      # A branch turns down, across and down; a bracket across, down and
      # across, and a matrix has its left bracket drawn and then its right.
      branches, brackets = shapes.select { |s| s.size == 4 }.partition { |s| s[0][0] == s[1][0] }
      boxes = brackets.each_slice(2).map do |pair|
        xs, ys = pair.flatten(1).transpose
        [xs.min, xs.max, ys.min, ys.max]
      end
      assert_equal 7, boxes.size, "#{tidy}: one pair of brackets per matrix"
      # The branch down to the preposition, the one matrix of a single row,
      # ends above it.
      adp = boxes.min_by { |_, _, top, bottom| bottom - top }
      assert(branches.any? { |(x, y), *| x.between?(adp[0], adp[1]) && y <= adp[2] },
             "#{tidy}: the branch to the preposition")

      branches.each do |branch|
        branch.each_cons(2) do |(ax, ay), (bx, by)|
          boxes.each do |left, right, top, bottom|
            inside = [ax, bx].max > left + 1 && [ax, bx].min < right - 1 &&
                     [ay, by].max > top + 1 && [ay, by].min < bottom - 1
            refute inside, "#{tidy}: a branch runs through the matrix at #{left.round}..#{right.round}"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# Packing keeps the column below an end of a movement path clear, and in the
# high mode no pair of branches is closed far narrower than the pairs below it.
class TidyPathColumnTest < Minitest::Test
  # Words placed directly under phrases, so that a short word sits beside a
  # deep phrase: the shape packing tucks under a path's end.
  TREES = [
    "[S [NP the man [RC [NP who+>1] [S I [VP read [NP a statement [RC which [VP was [PP about [NP ∅+1]]]]]]]]] [VP is sick]]",
    "[S [NP Which spy+>1] [S [NP ∅+1] [VP [VP killed John] [PP before [S anybody [VP could [VP speak to [NP ∅]]]]]]]]",
    "[S Mike [VP [VP [VP [VP talked [PP to [NP ∅+1]]] [PP about politics]] yesterday] [NP my friends+>1]]]"
  ].freeze

  def laid_out(data, extra = {})
    gen = RSyntaxTree::RSGenerator.new({ data: data, format: "svg", vheight: 0.8, hspacing: 0.8,
                                         vmargin: 0.2, fontstyle: "serif", fontsize: 14 }.merge(extra))
    list = gen.send(:parsed_element_list)
    RSyntaxTree::SVGGraph.new(list, gen.instance_variable_get(:@params), gen.instance_variable_get(:@global)).svg_data
    list
  end

  def descendant?(list, node, of)
    while node.parent.positive?
      node = list.get_id(node.parent)
      return true if node.id == of.id
    end
    false
  end

  # Labels that stand in the way of the line from +end_node+ to the rail:
  # past it on the side the words are on, across the line it runs down.
  def in_the_way(list, end_node, direction)
    list.get_elements.select do |e|
      next false if e.id == end_node.id || descendant?(list, e, end_node) || e.content.empty?

      if direction == "ltr"
        y = end_node.vertical_indent + end_node.content_height / 2.0
        e.horizontal_indent > end_node.horizontal_indent + end_node.content_width &&
          e.vertical_indent < y && y < e.vertical_indent + e.content_height
      else
        x = end_node.horizontal_indent + end_node.content_width / 2.0
        beyond = if direction == "btt"
                   e.vertical_indent + e.content_height < end_node.vertical_indent
                 else
                   e.vertical_indent > end_node.vertical_indent + end_node.content_height
                 end
        beyond && e.horizontal_indent < x && x < e.horizontal_indent + e.content_width
      end
    end
  end

  TREES.each_with_index do |tree, i|
    %w[low medium high].each do |tidy|
      %w[ttb btt ltr].each do |direction|
        define_method "test_tree_#{i}_#{tidy}_#{direction}_keeps_the_path_column_clear" do
          list = laid_out(tree, tidy: tidy, direction: direction)
          ends = list.get_elements.select { |e| e.path.any? { |m| !m.start_with?("-") } }

          refute_empty ends
          ends.each do |end_node|
            assert_empty in_the_way(list, end_node, direction).map(&:raw_content),
                         "labels under the path end #{end_node.raw_content}"
          end
        end
      end
    end

    define_method "test_tree_#{i}_high_closes_no_pair_far_narrower_than_below" do
      list = laid_out(tree.gsub(/\+>?\d/, ""), tidy: "high")
      spread = lambda do |node|
        kids = node.children.map { |c| list.get_id(c) }
        next nil if kids.size < 2

        centers = kids.map { |k| k.horizontal_indent + k.content_width / 2.0 }
        centers.max - centers.min
      end

      list.get_elements.each do |parent|
        own = spread.call(parent)
        below = parent.children.map { |c| spread.call(list.get_id(c)) }.compact.max
        next unless own && below

        assert_operator own, :>=, below * RSyntaxTree::BaseGraph::TIDY_LEVEL_BALANCE_FREE - 0.5,
                        "#{parent.raw_content}: #{own.round(1)} against #{below.round(1)} below"
      end
    end
  end
end

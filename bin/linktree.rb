require 'linkparser'
require 'rsyntaxtree'

dict = LinkParser::Dictionary.new
sent = dict.parse( "I wonder if Tom knows Jill sneezed her handkerchief off the table" )
sent.subject        # => "people"
sent.verb           # => "use"
sent.object         # => "Ruby"
bracketed = sent.constituent_tree_string(2)
bracketed = bracketed.chomp.gsub(/ [A-Z]+\]/){"]"}
bracketed = bracketed.gsub(/VP (.+?) \[NP/) do |text|
  "VP [V #{$1}] [NP"
end

p bracketed
opts = {}
opts["data"] = bracketed
rsg = RSGenerator.new(opts)
outfile = File.new(File.expand_path("~/Desktop/test.png"), "wb")
outfile.write rsg.draw_png

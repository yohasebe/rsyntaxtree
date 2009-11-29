#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
# Copyright (c) 2007-2009 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

$LOAD_PATH << File.join( File.dirname(__FILE__), 'rsyntaxtree')

require 'imgutils'
require 'element'
require 'elementlist'
require 'string_parser'
require 'tree_graph'
require 'svg_graph'
require 'error_message'

module RSyntaxTree
  VERSION = "0.2.0"
end

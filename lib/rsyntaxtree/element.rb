#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
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

ETYPE_UNDEFINED = 0
ETYPE_NODE = 1
ETYPE_LEAF = 2

class Element

    attr_accessor :id, :parent, :type, :content, :level, :width, :indent
    def initialize(id = 0, parent = 0, content = NULL, level = 0, type = ETYPE_LEAF)
      @id = id                 # Unique element id
      @parent = parent         # Parent element id
      @type = type             # Element type
      @content = content.strip # The actual element content
      @level = level           # Element level in the tree (0=top etc...)
      @width = 0               # Width of the element in pixels
      @indent = 0              # Drawing offset
    end
    
    # Debug helper function
    def dump
      printf( "ID      : %d\n", @id );
      printf( "Parent  : %d\n", @parent );
      printf( "Level   : %d\n", @level );
      printf( "Type    : %d\n", @type );
      printf( "Width   : %d\n", @width );
      printf( "Indent  : %d\n", @indent );
      printf( "Content : %s\n\n", @content );
    end

end

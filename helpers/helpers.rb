#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Helpers
  def link_to(name, location, alternative = false)
    if alternative and alternative[:condition]
      "<a href=#{alternative[:location]}>#{alternative[:name]}</a>"
    else
      "<a href=#{location}>#{name}</a>"
    end
  end
  
  def multibyte?(text)
    result = false
    text.strip.split(//).each do |chr|
      unless /([!-~]|\s)/ =~ chr
        result = true; break
      end
    end
    return result
  end  
end
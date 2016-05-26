#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module XMLService
    module_function
    def hash_tree_to_XML(klass, tree_root, enc=lambda{|e|e},*args)
      l = lambda { |e| "<div class=\"XML-#{ klass }-node\">#{ enc.call e }</div>" }
      f = lambda { |hsh|
        k, a = hsh.to_a[0]
        structure = "<div class=\"XML-#{ klass }-structure\">"
        if k == :root
          head = "<div class=\"XML-#{ klass }-root\">"
          ch = cf = celf = foot = ""
        else
          head = structure
          celf = l.call k
          ch = "<div class=\"XML-#{ klass }-children\">"
          cf = foot = "</div>"
        end
        body = a.collect{|e|
          next f.call e if e.is_a? Hash
          next structure + l.call(e) + "</div>" if e.is_a? String
        }.join
        return head + celf + ch + body + cf + foot
      }
      return HtmlBeautifier.beautify f.call root:tree_root
    end
    def array_list_to_XML(klass, list_array, enc=lambda{|e|e}, *args)
      sh = "<div class=\"XML-#{ klass }-structure\">"
      l  = lambda { |e| "<div class=\"XML-#{ klass }-node\">#{ enc.call e }</div>\n" }
      sf = "</div>"
      r = sh + list_array.collect{ |e| l.call e }.join("\n") + sf
      return HtmlBeautifier.beautify r
    end
  end
end

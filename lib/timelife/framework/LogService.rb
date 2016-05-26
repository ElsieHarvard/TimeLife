#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  class UniversalLogger
    attr_accessor :path
    def initialize(path)
      @path = path
    end
    def write(str)
      File.open(@path,'a:utf-8') do |f|
        f.write Time.now.to_f.to_s + ':' + str.gsub(/[[:cntrl:]]/){|c|
          c == "\r" || c == "\n" ? c : c.inspect }
      end
      return str
    end
  end
  ULogger = UniversalLogger
end

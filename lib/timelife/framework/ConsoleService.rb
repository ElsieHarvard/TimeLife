#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module UniversalConsoleLayout
    def text_style(color, bold=false)
      "\e[" + (bold ? '1;' : '0;') + (color + 30).to_s + "m"
    end
    def dt; "\e[0m"; end
    def rn; "\r\n"; end
    def universal_time_stamp; g '['+ts+']'; end
    alias kp p
    alias ts universal_time_stamp
    alias txs text_style
    # Make Color List
    ['k','r','g','y','b','m','c','w'].each_with_index{|v,i|
      define_method v do |s|
        txs(i) + s + (/\e\[0m\Z/.match(s) ? '' : dt)
      end
      define_method v+'b' do |s|
        txs(i,true) + s + (/\e\[0m\Z/.match(s) ? '' : dt)
      end
    }
    def p(str)
      Kernel.print str + rn
      log str + rn
    end
    def print(str)
      Kernel.print str
      log str
    end
    def msg
      print uts + yield + rn
    end
  end
  UCL = UniversalConsoleLayout
  class ConsoleService
    include UniversalConsoleLayout
    def hello
      p ( wb("TimeLife") + ' ' + cb(APP_VERSION) )
    end
    def log(str)
      begin
        ( @logger || ULogger.new(Config::LOGFILE) ).write str
      rescue NameError => e
        Kernel.p "!UNABLE TO LOG! Please check your Config."
        Kernel.p e.inspect
      end
    end
    def print(str)
      Kernel.print str.to_s
      log str.to_s
    end
  end
  module SysService
    define_method :conhost, TimeLife::ConsoleService.new.method(:instance_exec).to_proc
  end
end

#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  KERNEL_VERSION                  = '2'
  API_VERSION                     = '0'
  module Algorithm
    ALGORITHM_VERSION             = '1'
  end
  module SysKernel
    module_function
    def load_from_folder(path, prepath = Config::LIBRARY)
      Dir.glob("#{ prepath }#{ path }/*.rb") { |f| require f }
    end
    def load
      load_from_folder 'algorithm'
      load_from_folder 'framework'
      load_from_folder 'helper'
      load_from_folder 'profile', Config::LOCAL
      load_from_folder 'application'
      load_from_folder 'client/app'
    end
  end
  module DeployKit
    def define_with_touch(name, &block)
      define_method "touch_#{name}", &block
      define_method name do |*args|
        self.method(:touch).call
        method("touch_#{name}").call(*args)
      end
    end
    def easy_instance_variable(name, default=nil)
      define_method(name){
        instance_variable_get("@#{name}") || instance_variable_set("@#{name}", default)
      }
    end
    alias dwt define_with_touch
    alias eiv easy_instance_variable
  end
  module SysApplicationService
    include DeployKit
    def function(name, help_message, block)
      argv = block.parameters
      define_method "do_#{ name }", &block
      define_method "func_#{ name }" do |arg, hlp_msg=false|
        next help_message if hlp_msg
        method("do_#{name}").call(arg)
      end
    end
  end
  SysFileWallService = {
    :hsh => lambda { |io|
      if /\A\h{32}\Z/.match io
        return io
      else
        raise ArgumentError.new( 'Bad Argument: ' + io )
      end
    },
  }
  module SysService
    def AL(*args)
      ApplicationLibrary.function(*args)
    end
    def HL(*args)
      HttpLibrary.set_handle(*args)
    end
    def HAL(*args)
      [AL(*args), HL(*args)]
    end
    def XML(*args)
      return XMLService.hash_tree_to_XML(*args) if args.include? :hash
      return XMLService.array_list_to_XML(*args) if args.include? :array
    end
    def catch_application_form_argument(arg)
      begin
        return ApplicationLibrary.new.method("func_#{ ( arg.shift rescue nil ) || 'help' }")
      rescue NameError => e
        return ApplicationLibrary.new.method('func_help')
      end
    end
    def db
      return DataService.data
    end
    def decode_http_request(str)
      hsh = Hash.new do |h,k|
        fault "Unable to get argument: '#{k}'.", nil
        raise ArgumentError.new "`#{k}' was not found!"
      end
      str.split('&').each{|w|
        k,v = w.split('=',2)
        hsh[k] = v
      } if str
      return hsh
    end
    def fault(str = 'Runtime Error', e = RuntimeError.new)
      conhost {
        begin
          p rb str.to_s
          p e.to_s if e
        rescue Exception => esc
          Kernel.p esc
        end
      }
    end
    def firewall(hsh)
      type, source = hsh.to_a[0]
      return SysFileWallService[type].call source
    end
    def interactive_ruby
      Kernel.require 'IRB' unless ( IRB rescue nil )
      IRB.start
      exit unless ( $DEBUG rescue nil )
    end
    def secure_full_duplicate(obj)
      return Marshal.load Marshal.dump obj
    end
    def time_stamp
      [Time.now.to_f, rand].pack("d*").unpack("H*")[0].to_s
    end
    alias cafa catch_application_form_argument
    alias dhr decode_http_request
    alias fw firewall
    alias sfd secure_full_duplicate
    alias ts time_stamp
  end
  class ApplicationLibrary
    extend SysApplicationService
    include SysService
    function :help, 'Show help message.', lambda{|args|
      conhost { p gb 'Available Arguments:' }
      methods.grep(/func_.*/).each { |k|
        lhlpmsg = method(k).call(nil, true)
        conhost { p b(k.to_s.gsub(/\Afunc_/,'')) + ' ' + lhlpmsg }
      }
    }
    function :eval, 'Run input script for DEBUG.', lambda{|args|
      conhost { p yb args.grep(/\A[^_]/)[0].inspect }
      Kernel.require 'pp'
      pp Kernel.eval args.grep(/\A[^_]/)[0]
    }
  end
  AS = SysApplicationService
  DK = DeployKit
end

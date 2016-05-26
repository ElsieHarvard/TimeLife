#!/usr/bin/env ruby
#coding:utf-8

##
# Load Configure and Kernel
require "../local/config.rb"
require "../lib/timelife/sys_kernel.rb"

##
# Load Client Side Application for Syntax Checking
require "../lib/timelife/client/app.rb"

##
# Load All Components
TimeLife::SysKernel.load

##
# This is the Booster of the application.
class APP
  include TimeLife
  include SysService
  # Check Compatibility
  def version_check
    kernel_version, api_version, local_version = APP_VERSION.split('.')
    raise 'kernel_version != KERNEL_VERSION ' if kernel_version != KERNEL_VERSION
    raise 'api_version != API_VERSION' if api_version != API_VERSION
    raise 'APP_VERSION_CODE != CLIENT_VERSION_CODE' if APP_VERSION_CODE != CLIENT_VERSION_CODE
  end
  # Main Entry Point
  def start( argv = ARGV )
    version_check
    begin
      DataService.load
    rescue Exception => e
      DataService.reset
      DataService.rebootdb
    end
    conhost { hello }
    begin
      cafa(argv).call( argv + ["_AL"] )
    rescue Exception => e
      $DEBUG ? irb : raise(e)
    end
    DataService.save
  end
end

#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module DataService
    extend SysService
    include SysService
    def self.load
      begin
        File.open(TimeLife::Config::DBFILE, "rb") { |f|
          @data = Marshal.load(f)
        }
      rescue Exception => e
        fault "!UNABLE TO LOAD DATABASE!", e
        irb
      end
    end
    def self.save
      begin
        File.open(TimeLife::Config::DBFILE, "wb") { |f|
          Marshal.dump(@data,f)
        }
      rescue Exception => e
        fault "!UNABLE TO SAVE DATABASE!", e
        irb
      end
    end
    def self.backup
      begin
        File.open(TimeLife::Config::DBFILEBAK, "wb") { |f|
          Marshal.dump(@data,f)
        }
      rescue Exception => e
        fault "!UNABLE TO BACKUP DATABASE!", e
      end
    end
    def self.reset
      fault "!DATABASE RESETED!", false
      @data = Hash.new
    end
    # Data
    def self.data
      @data
    end
    # Always Reboot Database After Any Modification
    def self.rebootdb
      self.save
      self.load
    end
  end
  DS = DataService
end

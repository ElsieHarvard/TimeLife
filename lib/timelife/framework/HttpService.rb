#!/usr/bin/env ruby
#coding:utf-8

require 'webrick'
require 'zlib'
require 'stringio'
require 'nokogiri'
require 'erb'
require 'sass'
require 'htmlbeautifier'

module TimeLife
  module HttpService
    MSG = "Start local HTTP server on #{Config::SERVERIP}:#{Config::SERVERPORT}."
    extend SysService
    def file_from_path(path, extension='.html')
      File.read Config::HTTPROOT + path + extension + '.erb'
    end
    def render(f, bind)
      ERB.new(f).result(bind)
    end
    alias ffp file_from_path
    AL 'http.server', HttpService::MSG, lambda{|arg|
      conhost { p bb HttpService::MSG }
      HttpLibrary.new(arg).start
    }
    AL 'http.handle', "Show HTTP Handle", lambda { |args|
      conhost {
        p gb "All HTTP Handles:"
        HttpLibrary.handle.each{|key, (block, info)|
          p b(key) + ' ' + info
        }
      }
    }
  end
  ##
  # HTTP Library
  class HttpLibrary
    include HttpService
    class << self
      extend DK
      extend SysService
      attr_reader :handle
      eiv :handle, Hash.new {|h,k|
        fault "Unable to get application: '#{k}'.", nil
        raise ArgumentError.new "`#{k}' was not found!"
      }
      def set_handle(key, info, lamb)
        handle[key] = [lamb, info]
      end
    end
    def initialize(args)
      @server = WEBrick::HTTPServer.new({
        :BindAddress              => Config::SERVERIP,
        :Port                     => Config::SERVERPORT,
        :AccessLog                => [[$stderr,Config::SERVERLOG]]
      })
      @server.mount '/io'         , WebIO
      @server.mount '/shell/'     , WebShell
      @server.mount '/css/'       , WebSASS
      @server.mount '/static/'    , WEBrick::HTTPServlet::FileHandler, Config::HTTPSTATIC
      Signal.trap 'INT' do @server.shutdown end
    end
    def mount(path, klass)
      @server.mount(path, klass)
    end
    def start
      @server.start
    end
    class HTTPNotFound < StandardError
    end
    class HTTPSeeOther < StandardError
      attr_accessor :addr
      def initialize(addr)
        @addr = addr
      end
    end
    class HTTPTextMsg < StandardError
      def initialize(msg)
        @msg = msg
      end
      def to_s
        @msg
      end
    end
    ##
    # UniversalServlet
    class UniversalServlet < WEBrick::HTTPServlet::AbstractServlet
      include HttpService
      def initialize(*args)
        super
        @eojs = ''
        @head = {}
      end
      # Apply extra JavaScripts at the end of the document
      def exjs(str)
        @eojs.concat str
      end
      def decode_request(req)
        begin
          sio = ( StringIO.new(req.body) rescue
            raise Zlib::GzipFile::Error.new)
          str = Zlib::GzipReader.new(sio).read
          sio.close
        rescue Zlib::GzipFile::Error => e
          str = req.body && !req.body.empty ? req.body : ''
        end
        hsh = {}
        str.split('&').each{|w|
          k,v = w.split('=',2)
          hsh[k] = v
        }
        return hsh
      end
      def html_writer(src, res, http_code=200, header=@head)
        src = HtmlBeautifier.beautify src
        sio = StringIO.new(res.body)
        gz = Zlib::GzipWriter.new(sio)
        gz.write src
        gz.close
        res.status = http_code
        Config::HTTPHEADER.each{|k,v| res[k] = v }
        header.each{|k,v| res[k] = v }
      end
      def catch_route(*args)
        p self.inspect
        raise 'Empty Route'
      end
      def process(req, res)
        @params = decode_request(req)
        catch_route(req.path).call(req, res) unless @error >= 400
        html_writer @main_body, res , @error
        DataService.rebootdb
      end
      def do_GET(req, res, bind=binding)
        process req, res
      end
      def do_POST(req, res, bind=binding)
        process req, res
      end
    end
    # Web SASS Router
    class WebSASS < UniversalServlet
      # HTTP/GET
      def do_GET req, res
        body = ''
        ary = Dir[Config::HTTPCSS+'/*.scss'].select{|pth|
          req.path ==
            pth.gsub(Config::HTTPROOT,'').gsub('.css','.scss')
        }
        if ary[0]
          scss = File.read(ary[0])
          body = Sass::Engine.new(scss, :syntax => :scss).render
          res.content_type = 'text/css'
          res.body = body
        else
          @error = 404
          @main_body = render ffp('/sys/404'), binding
          super
        end
      end
    end
    # Web Shell
    class WebShell < UniversalServlet
      ERB_index = lambda { |req, res|
        rbapp = File.read('../lib/timelife/client/app.rb')
        Dir['../local/profile/*.rb'].each{|pth|rbapp.concat File.read pth}
        Dir['../lib/timelife/client/app/*.rb'].each{|pth|rbapp.concat File.read pth}
        rbapp.concat "\nTimeLife::Terminal.start\n"
        jsapp = File.read('../lib/timelife/client/app.js')
        res.body = render 'index', binding
      }
      # Render
      def self.render pth, b
        ERB.new(File.read('../lib/timelife/client/' +
          pth+'.html.erb')).result(b)
      end
      # Catch Route
      def catch_route(pth)
        case pth
        when /\A\/shell\//
          return ERB_index
        end
      end
      # HTTP/GET
      def do_GET req, res
        catch_route(req.path).call(req, res)
      end
      def do_POST(req, res, bind=binding)
        @error = 403
        @main_body = render ffp('/sys/403'), binding
        super
      end
    end
    ##
    # Web Shell Interface
    class WebIO < UniversalServlet
      def do_GET req, res
        @error = 403
        @main_body = render ffp('/sys/403'), binding
        super
      end
      def do_POST req, res
        act, *params = req.body.split(";\n")
        begin
          if h = HttpLibrary.handle[act]
            ans, result = h[0].call(params + ["_HL"])
          else
            ans = 'ArgumentError'
            result = '404'
          end
        rescue ArgumentError => e
          ans = 'ArgumentError'
          result = e.inspect
        end
        dat = result.is_a?(String) ? result : result.inspect
        res.body = ans + ";\n" + dat
      end
    end
  end
end

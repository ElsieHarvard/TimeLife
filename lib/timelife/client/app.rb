#!/usr/bin/env ruby
#coding:utf-8

#======================================================================#
#                               TimeLife                               #
#----------------------------------------------------------------------#
# Main Author: Rain Arthur                                             #
# This work is licensed under the                                      #
# Creative Commons Attribution-ShareAlike 4.0 International License.   #
#======================================================================#
module TimeLife
  ENVIRONMENT = :client unless (ENVIRONMENT rescue nil)
  CLIENT_VERSION_CODE = 'Renne'
  ##
  # Terminal Scripts
  module Terminal
    ##
    # Shell
    def Terminal.app
      $app
    end
    ##
    # DOMService
    module DOMService
      $btn_count = 0
      # Compile Simple DOM
      def quick_DOM(name, head='', body=inner_dom, foot=true)
        s = "<#{ name } #{ head }>#{ body }"
        r =  foot ? s + "</#{ name }>" : s
        return r
      end
      # Quick Define DIVKs
      def QDIVK(*args)
        # Opal.eval does not accept binding
        args.each { |name| eval "class #{ name } < TimeLife::Terminal::DIVK; end" }
      end
      # Compile Quick Button
      def quick_Button(hsh, &block)
        p hsh
        identifier = hsh[:key]
        hsh[:klass] = to_css hsh[:klass] if hsh[:klass]
        if block && !identifier
          if hsh[:klass]
            identifier = '.'
          elsif hsh[:kid]
            identifier = '#'
          else
            hsh[:kid] = "btn-#{ $btn_count }"
            identifier = '#'
            $btn_count += 1
          end
        end
        identifier = '.' + hsh[:klass] if identifier == '.'
        identifier = '#' + hsh[:kid]   if identifier == '#'
        btn = Button.new identifier, hsh[:body], &block
        btn.kid = hsh[:kid]
        btn.klass.push hsh[:klass] if hsh[:klass]
        return btn
      end
      alias qB quick_Button
      # Compile Quick Printed String
      define_method(:pstr) {|s| P.new STR.new s }
      define_method(:str) {|s| STR.new s }
    end
    ##
    # Define DOM, Basically an Array
    class DOM
      include DOMService
      extend DOMService
      attr_accessor :ary
      define_method(:initialize){ |*args| @ary = args.select{ |e| e.is_a? DOM } }
      # Convert Object to CSS object
      define_method(:to_css){ |obj| obj.to_s.downcase.gsub('_', '-') }
      define_method(:css_hash){ |hsh| hsh.collect{|k,v| "#{ k }='#{ v }'" }.join(' ') }
      # self.class.to_css
      define_method(:self_klass){ to_css(self.class) }
      # Compile Inner DOM
      def inner_dom
        return '' if @ary.empty?
        result = @ary.collect{|e| e.compile }.join("\n")
        return @ary.size == 1 ? result : "\n#{ result }\n"
      end
      # Compile, DOMs must have this method, Basically head + inner_dom + foot
      def compile
        p self.inspect
        raise 'Empty DOM'
      end
    end
    # String DOM
    class STR < DOM
      attr_accessor :str
      define_method(:initialize){ |str| @str = str }
      define_method(:compile){ @str }
    end
    # $('div')
    class DIV < DOM
      attr_accessor :kid
      attr_accessor :klass
      attr_accessor :attrs
      define_method(:initialize){ @kid = nil; @klass = []; @attrs = {}; super }
      define_method(:compile){ quick_DOM 'div', css_hash(attrs) }
      def attrs
        result = {}
        @attrs.each{|k,v| result[k] = v }
        result['id'] = @kid if @kid
        result['class'] = @klass.join(' ') unless @klass.empty?
        return result
      end
    end
    class DIVK < DIV
      define_method(:initialize){ super; @klass.push self_klass }
    end
    # $('div.inline-block')
    class InlineBlock < DIV
      define_method(:initialize){ super; @klass.push 'inline-block' }
    end
    # $('p')
    class P < DIV
      define_method(:compile){ quick_DOM 'p', css_hash(attrs) }
    end
    class Button < DIV
      attr_reader :identifier
      # Catch a Block who return the script on this.click()
      # Identifier is needed if a Block was given
      def initialize(*args)
        @identifier = args.select{|e| e.is_a? String }[0]
        if block_given?
          $app_proc.push proc{
            Terminal::SceneManager.this_click @identifier, "#{ yield };"
          }
        end
        args.select{|e| e.is_a? Proc }.each do |block|
          $app_proc.push proc{
            Terminal::SceneManager.this_click @identifier, "#{ block.call };"
          }
        end
        super
      end
      define_method(:compile){ quick_DOM 'button', css_hash(attrs) }
    end
    ##
    # This is the Booster of the Terminal application.
    class APP
      include Terminal
      attr_accessor :scene
      attr_accessor :status
      attr_accessor :handle
      attr_accessor :menu
      attr_accessor :str # Current String
      attr_accessor :sel # Current Selector
      attr_accessor :thread_lock
      # Initialize
      def initialize
        @str = ''
        @sel = ''
        @menu = []
        @req = {}
        @res = {
          'ArgumentError' => lambda { |args|
            $app.str = params
            `console.warn('ArgumentError: ' + app.str)`
            $app.str = nil
            return proc{ true }
          },
        }
        @ref = {}
        @thread_lock = false
        @handle = {}
      end
      define_method(:set_listener){ `window.appReady();` }
      define_method(:creq){ @req }; define_method(:cres){ @res }; define_method(:cref){ @ref }
      # Controller
      def req(str)
        key, params = str.split(";\n")
        if @thread_lock
          `console.warn("Thread Locked @ " + app.thread_lock )`
          return nil
        end
        @thread_lock = str
        @req[key].call(params)
      end
      def res(str)
        key, params = str.split(";\n")
        @res[key].call(params)
        @thread_lock = false #if /#{ key }/.match @thread_lock
      end
      def ref(str)
        key, params = str.split(";\n")
        @ref[key].call params
      end
      def ajax(k, a='')
        $app.str = "$.ajax({" +
          "type: 'POST', "+
          "url: '/io', " +
          'data: "'+ (k.downcase) +';\n'+ a +'",' +
          'success: function(res){app.$res(res)}'+
        '});'
        `eval(app.str)`
        $app.str = nil
      end
      def refresh_dom(selector, dom)
        $app.sel = selector
        $app.str = dom
        `$(app.sel).html(app.str)`
        #`console.log("DOM Refreshed for $('"+app.sel+"')")`
        $app.str = nil
        $app.sel = nil
      end
      def set_menu
        @menu.each{|hsh|
          $app.str = "$.contextMenu({" +
            "selector: '#{ hsh[:sel] }'," +
            "callback: function(key, options){#{
              hsh[:k].each.collect{ |k, v|
                "if (key=='#{ k }'){#{ v }}; "
              }.join
            }}," +
            "items: { #{
              hsh[:k].each.collect{ |k, v|
                "'#{ k }': {name: '#{ k }'},"
              }.join
            }}" +
          '});'
          `eval(app.str);`
          $app.str = ''
        }
      end
      ##
      # This is the Main Entry Point.
      def start(key='#main')
        # Show Debug information
        printf "TimeLife #{ CLIENT_VERSION_CODE } #{ ENVIRONMENT }"
        # Load scene
        @scene = Scene_Main.new
        @status = 'main'
        compile(@scene)
        # Set listener
        set_listener
        while $app_proc[0]
          $app_proc.shift.call
        end
        # Goto action
        SceneManager.goto key || '#main'
      end
      def compile(obj)
        Element.find('.cd-app').append obj.compile
      end
    end
    # Boost Terminal
    def Terminal.start
      if ENVIRONMENT == :client
        $app_proc = []
        $app = APP.new
        `app = Opal.TimeLife.Terminal.$app();`
        `scene_manager = Opal.TimeLife.Terminal.SceneManager;`
        $app.start(`window.location.href`.split('/shell/')[1])
        $app.set_menu
        SceneManager.this_click('a',
          'scene_manager.$goto(this.name);')
      end
    end
  end
end

#======================================================================#

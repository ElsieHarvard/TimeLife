#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module ActiveDataRecordService
    Struct = {
      :tree => lambda { |control|
        # UNFINISHED #
        # control isn't finished
        ActiveDataRecordObject::Tree
      },
      :obj => lambda { |control|
        ActiveDataRecordObject
      },
    }
    def ADR(args)
      return Struct[args[:struct]].call(args[:control])
    end
    KEYWORD = [ :tree, :tree_leaf, :prefix, :inherit, :obj, ]
    KEYWORD.each{|key_word| define_method key_word do key_word end }
  end
  class ActiveDataRecordObject
    extend SysService
    include SysService
    class Exclusive_Boolean
      def initialize(positive, negative, state=nil)
        @ihsh = {
          positive  => true,
          negative  => false,
          true      => true,
          false     => false,
        }
        @ohsh = {
          true      => positive,
          false     => negative,
        }
        turn state
      end
      def turn(pos)
        @state = @ihsh[pos]
      end
      def express
        return @ohsh[@state]
      end
      def to_s
        return express
      end
      def inspect
        "#<ADRO::Exclusive{#{ @ohsh[true] }|#{ @ohsh[false] }} @state=#{ @state.inspect }>"
      end
    end
    ## Basic
    class << self
      include DK
      extend SysService
      extend DK
      ActiveDataRecordService::KEYWORD.each{|key_word|
        define_method key_word do key_word end
      }
      def elements;   @elements   || @elements   = {}; end
      def attributes; @attributes || @attributes = {}; end
      def foreigns;   @foreigns   || @foreigns   = {}; end
      # Define content
      def element(hsh)
        key = hsh.keys.grep(/\A[^_]/)[0]
        #p self
        elements[key] = hsh
        kif = hsh[:_if]
        if kif
          define_method(key.to_s+'=', lambda{|*args|
            return nil unless method(kif).call
            return instance_variable_set "@#{key}", hsh[key].call(*args)
          })
          define_method(key, lambda{
            return nil unless method(kif).call
            return instance_variable_get "@#{key}"
          })
        else
          define_method(key.to_s+'=',lambda{|*args|
            return instance_variable_set "@#{key}", hsh[key].call(*args)
          })
          attr_reader key
        end
      end
      def attribute(hsh)
        key = hsh.keys.grep(/\A[^_]/)[0]
        attributes[key] = begin
          hsh[key].call
        rescue ArgumentError => e
          nil
        end
      end
      def foreign(hsh)
        key = hsh.keys.grep(/\A[^_]/)[0]
        foreigns[key] = [] if hsh[key] == :obj
      end
      # Define element structure
      def boolean(t=true, f=false)
        lambda{|i| return ( i==t || i.to_s==t.to_s || i==true )  ? true :
                          ( i==f || i.to_s==f.to_s || i==false ) ? false : nil }
      end
      def integer(arg)
        return lambda{|i|   [i.to_i, 1].max } if arg == :positive
        return lambda{|i=0| [i.to_i, 0].max } if arg == :natural
      end
      def string(default="")
        lambda{|str=default| String.new str.gsub('+',' ') }
      end
      def time
        lambda{|t| Time.new t[0..3],t[5..6],t[8..9],t[11..12],t[16..17] }
      end
      def exclusive(t, f)
        lambda{|i=nil|
          r = ( i==t || i.to_s==t.to_s || i==true )  ? true :
              ( i==f || i.to_s==f.to_s || i==false ) ? false : nil
          Exclusive_Boolean.new t, f, r
        }
      end
      def array
        lambda { |a|
          return a.split(';') if a.is_a? String
          return a if a.is_a? Array
        }
      end
      # Define Touch Methods
      def touch
        db[self] || db[self] = {}
      end
      dwt(:all   ){               db[self].values                     }
      dwt(:[]    ){ |hsh|         db[self][hsh]                       }
      dwt(:[]=   ){ |hsh, obj|    db[self][hsh] = obj                 }
      dwt(:delete){ |hsh|         db[self][hsh].delete                }
      def each
        block_given? ? self.all.each {|w| yield w } : self.all.each
      end
      # IO Interface
      dwt(:update){ |hsh|
        h = hsh['#tshsh']
        obj = h.empty? ? self.new : self[fw hsh:h]
        setit = lambda {|key, eh|
          v = hsh["q-#{key}"]
          if v.empty?
            fault "Empty argument: 'q-#{key}'.", nil
            raise ArgumentError.new "`q-#{key}' was empty!"
          else
            obj.method("#{key}=").call(v)
          end
        }
        elements.each{|key, eh| setit.call key, eh unless eh[:_if] }
        elements.each{|key, eh| setit.call key, eh if eh[:_if] && obj.method(eh[:_if]).call() }
        obj.save
      }
      def list(args, &block)
        klass = self.to_s.split('::')[-1].downcase
        r = self.all
        l = block || proc{|e|e}
        x = XML klass, r, l, :array
        conhost{ p x } if args.include? '_AL'
        return x
      end
    end
    attr_reader :tshsh
    def initialize(*args)
      @tshsh = ts
      init
      yield args if block_given?
    end
    def touch
      db[self.class] || db[self.class] = {}
    end
    dwt :save do
      db[self.class][self.tshsh] = self
    end
    dwt :delete do
      db[self.class].delete self.tshsh
    end
    def set_attr()
    end
    def get_attr()
    end
    private
    def oth(obj)
      return nil if obj.nil?
      return obj.is_a?(String) ? obj :
        obj.is_a?(self.class) ? obj.tshsh : ( raise TypeError )
    end
    def init
      @attributes = sfd self.class.attributes
      @foreigns   = sfd self.class.foreigns
      self.class.elements.each{|k,v|
        instance_variable_set "@"+k.to_s, begin
          v[k].call
        rescue ArgumentError => e
          nil
        end
      }
    end
    alias origin_init init
    alias delete_self delete
    class Tree < ActiveDataRecordObject
      def initialize(*args, &block)
        @_parent = nil
        @_children = []
        super(*args, &block)
      end
      dwt(:parent) { self.class[@_parent] }
      dwt(:children) { self.method(self.class.leaf).call ? false : @_children }
      def parent=(obj)
        self.parent.remove_child self if @_parent
        _parent = oth obj
        @_parent = _parent && self.class[_parent].add_child(self) ? _parent : nil
      end
      def add_child(obj)
        return nil unless _child = oth(obj)
        return false if self.method(self.class.leaf).call
        return @_children.push(_child) if self.class[_child]
      end
      def remove_child(obj)
        return nil unless _child = oth(obj)
        return false if self.method(self.class.leaf).call
        return @_children.delete(_child) if self.class[_child]
      end
      alias basic_delete delete
      def delete
        self.parent = nil
        while e = @_children[0]
          db[self.class][e].parent = nil
        end
        basic_delete
      end
      def tree
        return @tshsh if self.method(self.class.leaf).call
        return { @tshsh => @_children.collect { |e| self.class[e].tree } }
      end
      class << self
        alias basic_element element
        eiv :leaf
        def element(*args, &block)
          hsh = args[0]
          key = hsh.keys.grep(/\A[^_]/)[0]
          kctrl = hsh[:_control]
          @leaf = key if kctrl == :tree_leaf
          basic_element(*args, &block)
        end
        # IO Interface
        def tree(args, &block)
          klass = self.to_s.split('::')[-1].downcase
          r = self.all.select{|e|e.parent.nil?}.collect{|e| e.tree }
          l = block || proc{|e|e}
          x = XML klass, r, l, :hash
          conhost{ p x } if args.include? '_AL'
          return x
        end
      end
    end
  end
  ADRS = ActiveDataRecordService
end

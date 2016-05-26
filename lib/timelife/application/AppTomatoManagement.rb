#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  class TomatoManagement
    include Profile::AppTomatoManagement
    include AS
    extend SysService
    include SysService
    extend ActiveDataRecordService

    class TomatoList < ADR struct:obj

      element   name:             string
      element   breakpoints:      array

      class << self
        def format_output
          lambda{|e|
            t = self[e] if e.is_a? String
            t = e if e.is_a? TomatoList
            return "<div class=\"XML-tomatolist-obj\" q-tshsh=\"#{ e.tshsh }\"" +
                      " q-ary=\"#{ e.breakpoints.join(';') }\">" +
                      "<p><span class=\"XML-tomatolist-obj-name\">#{ e.name }</span></p>"+
                      "<div class=\"XML-tomatolist-obj-bar\"></div>" +
                   "</div>"
          }
        end

        def list(args)
          super(args, &format_output)
        end
      end
    end

    class Tomato < ADR struct:obj

    end

    def check(args)
      TomatoList.all.empty? ? 'empty' : 'ok'
    end

    HAL 'tomato.check', 'Check the schedule', lambda { |args|
      conhost { p bb "TomatoManagement.check" }
      return 'Index.init.tomato', TomatoManagement.new.check(args)
    }

    HAL 'tomato.show', 'List all tomatoes', lambda { |args|
      conhost {
        p bb "TomatoList.list"
      }
      return 'Tomato.refresh', TomatoList.list(args)
    }

    HAL 'tomato.update', 'Save a tomato.', lambda { |args|
      conhost {
        p bb "TomatoList.update"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      r = TomatoList.update dhr args.grep(/\A[^_]/)[0]
      conhost { p g r.inspect }
      return 'Tomato.checkout', r.tshsh + ';=' + TomatoList.list(args)
    }

    HAL 'tomato.delete', 'Delete a tomato.', lambda { |args|
      conhost {
        p bb "TomatoList.delete"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      r = TomatoList.delete fw hsh:args.grep(/\A[^_]/)[0]
      conhost { p g r.inspect }
      return 'Tomato.refresh', TomatoList.list(args)
    }

  end
end

#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  ##
  # Goal Quantification Module
  class GoalQuantification
    include Profile::AppGoalManagement
    include AS
    extend SysService
    include SysService
    extend ActiveDataRecordService
    ##
    # Goal Object
    class Goal < ADR struct:tree, control:prefix
      include Profile::AppGoalManagement::Goal

      element   subject:          string
      element   verb:             string
      element   object:           string
      element   deadline:         time,                               _can:inherit

      element   specific:         boolean(:specific, :abstract),      _control:tree_leaf

      element   scalar:           integer(:positive),                 _if: :specific
      element   finished:         integer(:natural),                  _if: :specific
      element   quantifier:       string,                             _if: :specific
      element   duration:         integer(:positive),                 _if: :specific

      attribute important:        exclusive(:important, :avocation),  _can:inherit
      attribute emergency:        exclusive(:emergency, :entertain),  _can:inherit

      foreign   potato:           obj,                                _if: :specific

      ##
      # Assess a Goal Basically Following the Four Quadrant Principles
      # 1) Emergency & Important -> The First Thing
      # 2) Important &!Emergency -> Avoid being Emergency
      # 3) Emergency &!Important -> Avoid being disturbed by them
      # 4)!Important &!Emergency -> Do them in Spare Time

      def basic_assess
      end

      class << self
        def format_output(hsh=nil)
          l = proc{|e|
            goal = self[e] if e.is_a? String
            goal = e if e.is_a? Goal
            ft = proc{|t|
              t.strftime '%Y-%m-%dT%H:%M'
            }
            h = "<div class='XML-goal-obj' q-tshsh='#{ goal.tshsh }' #{
              elements.collect{ |k, h|
                v = goal.method(k).call
                v = v ? 'specific' : 'abstract' if k == :specific
                v.to_s.empty? ? nil : "q-#{ k }=\"#{ v.is_a?(Time) ? ft.call(v) : v.to_s }\""
              }.compact.join(' ')
            }>"
            b = "<span class=\"XML-goal-obj-general\">"
            b += "<span class=\"XML-goal-obj-verb\">#{ goal.verb }</span> "
            if goal.method(self.leaf).call
              b += "<span class=\"XML-goal-obj-scalar\">#{ goal.scalar }</span> " +
                   "<span class=\"XML-goal-obj-quantifier\">#{ goal.quantifier }</span> " +
                   "<span class=\"XML-goal-obj-preposition\">of</span> "
            end
            b += "<span class=\"XML-goal-obj-object\">#{ goal.object }</span>" + "</span>" +
                 "<small class=\"XML-goal-obj-deadline\">"
            if goal.method(self.leaf).call
              b += "#{ goal.duration * goal.scalar } minute before "
            end
            b += goal.deadline.strftime "%Y-%m-%d %H:%M"
            b += "</small>"
            f = "</div>"
            r = h + b + f
          }
          return hsh ? l.call(hsh) : l
        end
        def tree(*args)
          super *args, &format_output
        end
        def show(args)
          x = format_output fw hsh:args.grep(/\A[^_]/)[0]
          conhost{ p x } if args.include? '_AL'
          return x
        end
      end
    end
    ##
    # Potato Object
    class Potato < ADR struct:obj

    end

    ##
    def basically_sort(ary)
      ary.sort_by{|e| e.basic_assess e }
    end

    # Check To-Do-List
    def check_to_do_list(args)
      ary = Goal.all.select { |e| e.children && e.children.empty? }
      result = "#{ ary.size };=" + ary.collect{ |e| Goal.format_output e }.join("\n")
      result = '0' if args.include?('ignore_abstract')
      result = 'empty' if Goal.all.empty?
      conhost {
        if ary.empty? || args.include?('ignore_abstract')
          p g 'Pass.'
        else
          p y 'Not Pass. '
          ary.each { |e|
            p e.tshsh
          }
        end
      } if args.include? '_AL'
      return result
    end

    AL 'goal.show', 'Show a Goal.', lambda { |args|
      conhost {
        p bb "Goal.show"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      Goal.show args
    }
    HAL 'goal.update', 'Save a Goal.', lambda { |args|
      conhost {
        p bb "Goal.update"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      r = Goal.update dhr args.grep(/\A[^_]/)[0]
      conhost { p g r.inspect }
      return 'Goal.checkout', r.tshsh + ';=' + Goal.tree(args)
    }
    HAL 'goal.show', 'Show Goal tree.', lambda { |args|
      conhost {
        p bb "Goal.tree"
      }
      return 'Goal.refresh', Goal.tree(args)
    }
    HAL 'goal.move', "Set `Goal[args[1]].parent=args[2]'. ", lambda { |args|
      conhost {
        p bb "Goal.move"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      f, t = args.grep(/\A[^_]/)[0].split(':')
      Goal[fw(hsh:f)].parent = fw(hsh:t)
      return 'Goal.refresh', Goal.tree(args)
    }
    HAL 'goal.delete', 'Delete a Goal.', lambda { |args|
      conhost {
        p bb "Goal.delete"
        p y args.grep(/\A[^_]/)[0].inspect
      }
      r = Goal.delete fw hsh:args.grep(/\A[^_]/)[0]
      return 'Goal.refresh', Goal.tree(args)
    }
    HAL 'goal.check', 'Check To-Do-List, specific goal only.', lambda { |args|
      conhost {
        p bb "GoalQuantification.check_to_do_list"
      }
      result = GoalQuantification.new.check_to_do_list(args)
      return 'Index.init.goal', result
    }
  end
end

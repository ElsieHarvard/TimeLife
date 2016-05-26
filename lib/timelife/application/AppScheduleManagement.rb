#!/usr/bin/env ruby
#coding:utf-8

__END__

module TimeLife
  # Schedule Design Module
  class AppScheduleManagement
    include SysApplicationService
    include SysHttpService
    # Schedule Object
    class Schedule
      # initialize
      def initialize(date, hash_pair={})
        @date = date
        @hash_pair = @hash_pair
      end
    end
    ##
    # Make Event List
    def self.mkevent_list
      return '<a href="#" id="a-addgoal">You have\'nt set any goal yet! ' +
      'Click here to add one!</a>'
    end
    # Mark time -> goal
    def mark_tp(t,p)
      mark = Math::E
      klass = AppGoalManagement::Goal
      rsym = klass::SymbolTable
      goal = klass[p[0]]
      t[1].each{|sym|
        goal.is_attr?(sym) ? (mark *= 2) : (mark /= 2)
        goal.is_attr?(rsym[sym]) ? (mark /= 2) : (mark *= 2)
      }
      goal.is_attr?(:emergency) ? (mark *= 2) : (mark /= 2)
      mark = Math.log mark
      mark = 0.88 * mark + 0.12 * (1-p[1])
      return mark
    end
    # Mark goal -> time
    def mark_pt(p,t)
      klass = AppGoalManagement::Goal
      goal = klass[p[0]]
      mark = goal.is_attr?(:important) ?
        ( t[1].include?(:important) ? 0.75 : 0.6) :
        ( t[1].include?(:important) ? 0.25 : 0.4)
      mark += t[2] if goal.is_attr?(:entertain)
      if goal.is_attr?(:emergency)
        mark += 1
        mark -= t[2]
      end
      return mark
    end
    # Ext Generate
    def ext_generate(parameters)
      date = parameters['q-date']
      tomato = parameters['q-hsh'].split('-').each.collect{|e|
        t, *a = e.split('_')
        t = Time.new date[0..3],date[5..6],date[8..9],t[0..1],t[2..3]
        a.map!{|w|w.to_sym}
        [t, a]
      }
      tomato.sort!
      tomato.map!.each_with_index{|v,k| v.push 1.0*k/tomato.size }
      potato = AppGoalManagement.new.potato
      mt = method(:mark_tp)
      mp = method(:mark_pt)
      env = Algorithm::DeferredAcceptance.new tomato, potato, mt, mp
      x,y = env.prepare
      r = env.main
      @res = r.each.collect{|(t,p)|
        next nil unless t && p
        [t[0],p[0]]
      }.compact
      @res.sort!
    end
    #
    # Generate Schedule
    # Out of Date
    def func_generate(parameters, hlpmsg = nil)
      return "Generate Schedule, parameters in HTTP format." if hlpmsg
      date = parameters['q-date']
      tomato = parameters['q-hsh'].split('-').each.collect{|e|
        t, *a = e.split('_')
        t = Time.new date[0..3],date[5..6],date[8..9],t[0..1],t[2..3]
        a.map!{|w|w.to_sym}
        [t, a]
      }
      tomato.sort!
      tomato.map!.each_with_index{|v,k| v.push 1.0*k/tomato.size }
      potato = AppGoalManagement.new.potato
      mt = method(:mark_tp)
      mp = method(:mark_pt)
      env = Algorithm::DeferredAcceptance.new tomato, potato, mt, mp
      x,y = env.prepare
      r = env.main
      @res = r.each.collect{|(t,p)|
        next nil unless t && p
        [t[0],p[0]]
      }.compact
      @res.sort!
      render apf('schedule/result'), binding
    end
    ##
    # Servlet
    class Servlet
      include SysHttpService
      # Initialize
      def initialize(path,server,parameters={})
        @req_path = path
        @req_parameters = parameters
        @server = server
      end
      # Run App
      def run
        case @req_path
        when ''
          render apf('schedule'), binding
        when '/'
          render apf('schedule'), binding
        when '/new'
          render apf('schedule/new'), binding
        when '/generate'
          AppScheduleManagement.new.send :func_generate, @req_parameters
        else
          raise SysHttpLibrary::HTTPNotFound.new
        end
      end
    end
  end
  class SysHttpLibrary
    # Route for AppGoalManagement
    HTTPApp[:schedule] = ['/schedule', AppScheduleManagement]
  end
  class ApplicationLibrary
    # Registe for class SysHttpLibrary
    def func_schedule(arg,hlpmsg=nil)
      return "AppScheduleManagement" if hlpmsg
      AppScheduleManagement.new.run arg
    end
  end
end

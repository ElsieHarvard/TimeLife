#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module Terminal
    module SceneManager
      module_function
      def goto(str='#main')
        case str
        when '#main'
          goto_main
        when '#add-goal'
          $app.req 'Goal.show'
          $app.ref 'Goal.new'
          goto_goal
        when '#list-goal'
          $app.req 'Goal.show'
          goto_goal
        when '#init-ignabstract'
          goto_main(:ignore_abstract)
        when '#list-schedule'
          $app.req 'Tomato.show'
          goto_tomato
        when '#add-schedule'
          $app.req 'Tomato.show'
          goto_tomato
        end
      end
      def goto_main(*args)
        Element.find('.cd-mainscreen').css('margin-top','0')
        $app.handle['Index'].refresh(*args)
        $app.status = 'main'
      end
      def goto_menu
        Element.find('.cd-mainscreen').css('margin-top','calc( -4em - 1px )')
        $app.status = 'menu'
      end
      def goto_amos
        Element.find('.cd-mainscreen').css('margin-top','calc( -4em - 100vh - 2px )')
      end
      def goto_goal
        goto_amos
        Element.find('.cd-aftermenuobjs').css('margin-left','0')
        $app.status = 'goal'
      end
      def goto_tomato
        goto_amos
        Element.find('.cd-aftermenuobjs').css('margin-left','calc( -100vw )')
        $app.status = 'schedule'
      end
      def slide_left
        case $app.status
        when 'schedule'
          goto '#list-goal'
        end
      end
      def slide_right
        case $app.status
        when 'goal'
          goto '#list-schedule'
        end
      end
      def slide_up
        case $app.status
        when 'main'
          # nothing
        when 'menu'
          goto '#main'
        else
          goto '#main'
        end
      end
      def slide_down
        case $app.status
        when 'main'
          goto_menu
        when 'menu'
          # nothing
        end
      end
      def keydown(key_code)
        slide = true
        if slide
          case key_code
          when 37 # left
            slide_left
          when 38 # down
            slide_up
          when 39 # right
            slide_right
          when 40 # up
            slide_down
          when 27 # Escape
            `$$('.XML-goal-root .XML-goal-obj').removeClass('catch')`
          end
        end
      end
      def this_click(selector, command)
        # for JQuery
        #str1 = "$('#{ selector }').click( function() {#{ command }} );"
        # for Quo.js
        str2 = "$$('#{ selector }').touch( function() {#{ command }} );"
        #p str1
        #p str2
        #`eval(#{str1})`
        `eval(#{str2})`
      end
    end
  end
end

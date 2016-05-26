#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module Terminal
    ##
    # Basic Scene
    class Scene_Base < DIVK
      def initialize
        super; @klass.push 'scene-base'; @attrs['onselectstart'] = "return false;"
      end
    end
    ##
    # Main Scene
    class Scene_Main < Scene_Base
      attr_accessor :status
      ##
      # TopBar
      # Include the Main Clock a Menu Button
      class CD_TopBar < DIVK
        ##
        # Main Clock
        # Display Time Remaining or Local Time
        # Find it in Native Code
        CD_MainClock = str '<span id="main-clock">88:88:88</span>'
        def initialize
          super(
            qB(klass: 'BTN_Avatar'),
            CD_MainClock,
            qB(klass: 'BTN_MainMenu'){ 'scene_manager.$goto_menu()' },
          )
        end
      end
      ##
      # Main Panel
      class CD_Current < DIVK
        ##
        # Panels
        class Panel < DIVK
          define_method(:initialize){ super; @klass.push 'cd-main-panel' }
        end
        ##
        # Initialize Panel
        class CD_Init < Panel
          CD_Init1 = str "<div class='cd-init1'><p>You haven't set any goal yet!</p>" +
            "<a name='#add-goal'> &gt; <small>Click Here to Add One</small> &lt; </a></div>"
          CD_Init2 = str "<div class='cd-init2'>" +
            "<p>The following goals do not have any Specific Goals as its child.</p>" +
            "<a name='#init-ignabstract'> &gt; <small>Click Here to Ignore.</small> &lt; </a>" +
            "<div class='cd-init2-list'></div>" +
            "</div>"
          CD_Init3 = str "<div class='cd-init3'><p>You haven't set any schedule yet!</p>" +
            "<a name='#add-schedule'> &gt; <small>Click Here to Add One</small> &lt; </a></div>"
          CD_Init4 = str "<div class='cd-init4'><p>You haven't set any schedule yet!</p>" +
            "<a name='#add-schedule'> &gt; <small>Click Here to Add One</small> &lt; </a></div>"
          def initialize
            super CD_Init1, CD_Init2, CD_Init3
          end
          def compile
            $app.creq['Index.init.goal'] = lambda { |arg|
              $app.ajax 'goal.check'
            }
            $app.creq['Index.init.goal.ignore_abstract'] = lambda { |arg|
              $app.ajax 'goal.check', 'ignore_abstract'
            }
            $app.creq['Index.init.tomato'] = lambda { |arg|
              $app.ajax 'tomato.check'
            }
            $app.cres["Index.init.goal"] = lambda {|params|
              i, a = params.split(";=")
              `$('.cd-init > div').removeClass('visible');`
              if i == '0'
                $app.thread_lock = false if /Index.init.goal/.match $app.thread_lock
                $app.req('Index.init.tomato')
              else
                if i == 'empty'
                  `$('.cd-init1').addClass('visible');`
                else
                  `$('.cd-init2').addClass('visible');`
                  Element.find('.cd-init2-list').html a
                end
              end
            }
            $app.cres["Index.init.tomato"] = lambda {|params|
              i, a = params.split(":@\n")
              if i == 'empty'
                `$('.cd-init3').addClass('visible');`
              else
                `$('.cd-init4').addClass('visible');`
              end
            }
            super
          end
        end
        ##
        # Check Out Today's or Tomorrow's work-flow
        class CD_CheckOut < Panel
        end
        ##
        # Work-flow running
        class CD_WorkFlow < Panel
        end
        ##
        # Review
        class CD_Review < Panel
        end
        def refresh(*args)
          if args.include? :ignore_abstract
            $app.req 'Index.init.goal.ignore_abstract'
          else
            $app.req 'Index.init.goal'
          end
        end
        def initialize
          super CD_Init.new, CD_CheckOut.new, CD_WorkFlow.new, CD_Review.new
        end
        define_method(:compile){ $app.handle['Index'] = self; super }
      end
      ##
      # BottomBar
      # Empty for Default
      class CD_BottomBar < DIVK
      end
      ##
      # Main Menu
      class CD_Menu < DIVK
        # initialize
        def initialize
          super(
            qB(body:str('Goal')){ 'scene_manager.$goto("#list-goal")' },
            qB(body:str('Schedule')){ 'scene_manager.$goto("#list-schedule")' },
            qB(body: str("Setting")),
          )
        end
      end
      ##
      # All Objects After Menu
      # Horizontal Arrangement
      class CD_AfterMenuObjs < DIVK
        # Template
        class AMOS < DIVK
          define_method(:initialize){ super; @klass.push 'cd-amos' }
          QDIVK :CD_Title, :CD_SpliterLR, :CD_SpliterTB
          class List < DOM
            define_method(:initialize){ |hsh| super; @hsh = hsh }
            def compile
              @hsh.each.collect{|k,v| "<datalist id=\"#{k}\">#{
                v.each.collect{|a|"<option value='#{a}'>"}.join("\n")
              }</datalist>" }.join("\n")
            end
          end
          define_method(:title){|s| CD_Title.new pstr s }
        end
        ##
        # Data Exchange with ADRS
        module Exchangeable
          define_method(:tshsh){ @tshsh }
          def checkout(ts, dom_tree=nil)
            refresh_dom(dom_tree) if dom_tree
            refresh_element @tshsh = ts
          end
          define_method(:refresh_dom){|dom_tree| raise 'Empty Exchangeable!'}
          define_method(:refresh_element){|ts|   raise 'Empty Exchangeable!'}
          define_method(:require_new){           raise 'Empty Exchangeable!'}
          define_method(:serialize){             raise 'Empty Exchangeable!'}
          def exchange(name)
            # Bind Respond
            $app.creq["#{name}.update"] = lambda {|arg|
              $app.ajax "#{name}.update", "#tshsh=#{ @tshsh }&" + serialize
            }
            $app.creq["#{name}.delete"] = lambda {|ts| $app.ajax "#{name}.delete", ts }
            $app.creq["#{name}.show"] = lambda {|arg| $app.ajax "#{name}.show"}
            $app.cres["#{name}.refresh"] = lambda {|dom_tree| refresh_dom dom_tree }
            $app.cres["#{name}.checkout"] = lambda {|pkg| checkout *(pkg.split(';=')) }
            $app.cref["#{name}.checkout"] = lambda {|ts| checkout ts }
            $app.cref["#{name}.new"] = lambda {|arg| require_new  }
          end
        end
        ##
        # Goal Management
        class CD_Goal < AMOS
          QDIVK :CD_GoalTree, :CD_GoalEdit, :CD_GoalTreeRoot, :CD_Goal_InfoGroup
          # exchange
          include Exchangeable
          define_method(:name){'Goal'}
          def refresh_dom(dom_tree)
            $app.refresh_dom '.cd-goaltreeroot', dom_tree
            `$$('.XML-goal-root .XML-goal-obj').touch(function(){
              if($(this).hasClass('catch')){
                app.$req("Goal.move;\n"+$(this).attr('q-tshsh'))
              }
            })`
          end
          def refresh_element(ts)
            Element.find('#scr-goal-tshsh').html( ts || 'New Goal' )
            `$('.cd-goaledit input').val(function(){
              return $('.XML-goal-root .XML-goal-obj[q-tshsh='+#{ts}+']').attr(this.name)
            });` if ts
          end
          def require_new
            refresh_element @tshsh = nil
          end
          def serialize
            `$('.cd-goaledit input').serialize()`
          end
          # compile
          def i(string)
            suggestion = Profile::AppGoalManagement::Suggestion
            a = "placeholder=\"#{string}\""
            b = ''
            s = suggestion[string.to_sym]
            a += "list=\"#{string}\"" if s
            case string
            when 'scalar'
              a += 'type="number" min="1" step="1"'
            when 'duration'
              a += 'type="number" min="1" step="1"'
            when 'deadline'
              a += 'type="datetime-local"'
            when 'finished'
              a += 'type="number" min="0" step="1"'
            end
            # Input DOM is Defined Here
            r = "<input #{a} name=\"q-#{string}\">#{b}</input>"
            return r
          end
          def initialize
            @tshsh = nil
            super(
              title('Goal Management'),
              CD_SpliterLR.new(
                CD_GoalTree.new(
                  title('Goal Tree'),
                  CD_GoalTreeRoot.new,
                ),
                CD_GoalEdit.new(
                  title('Goal Detail'),
                  List.new(Profile::AppGoalManagement::Suggestion),
                  CD_Goal_InfoGroup.new(
                    pstr("Hash: <span id='scr-goal-tshsh'>#{ @tshsh || 'New Goal'}")
                  ),
                  CD_Goal_InfoGroup.new(
                    pstr("Type: #{i 'specific'}"),
                    qB(body:str('specific')){
                      "$('.cd-goaledit input[name=q-specific]').val('specific')"},
                    qB(body:str('abstract')){
                      "$('.cd-goaledit input[name=q-specific]').val('abstract')"},
                  ),
                  CD_Goal_InfoGroup.new(
                    pstr("Subject: #{i 'subject'}"),
                    qB(body:str('I')){
                      "$('.cd-goaledit input[name=q-subject]').val('I')"},
                    pstr("Verb: #{i 'verb'}"),
                    pstr("Scalar: #{i 'scalar'}"),
                    pstr("Quantifier: #{i 'quantifier'}"),
                    pstr("Object: #{i 'object'}"),
                    pstr("Deadline: #{i 'deadline'}")
                  ),
                  CD_Goal_InfoGroup.new(
                    pstr("Duration per scalar: #{i 'duration'}minute.")
                  ),
                  CD_Goal_InfoGroup.new(
                    pstr("Progress: #{i 'finished'}/all.")
                  ),
                  qB(body:pstr("New Goal")){
                    'app.$ref("Goal.new")'},
                  qB(body:pstr("Save Changes")){
                    'app.$req("Goal.update")'},
                  qB(body:pstr("Clear")){
                    "$('.cd-goaledit input').val('')"},
                )
              )
            )
          end
          def compile
            $app.handle['Goal'] = self
            exchange('Goal')
            $app.cref["#{name}.move"] = lambda { |ts|
              checkout ts
              `$$('.XML-goal-root .XML-goal-obj').addClass('catch')`
            }
            $app.cref["#{name}.caught"] = lambda { |ts|
              checkout ts
              `$$('.XML-goal-root .XML-goal-obj').addClass('catch')`
            }
            $app.creq["#{name}.move"] = lambda { |ts|
              $app.ajax "#{name}.move", @tshsh + ':' + ts
            }
            $app.menu.push({
              sel:'.XML-goal-root .XML-goal-obj',
              k:{
                edit: 'app.$ref("Goal.checkout;\n" + $(this).attr("q-tshsh"));',
                move: 'app.$ref("Goal.move;\n" + $(this).attr("q-tshsh"));',
                delete: 'app.$req("Goal.delete;\n" + $(this).attr("q-tshsh"));',
              }
            })
            super
          end
        end
        ##
        # Tomato Management
        class CD_Tomato < AMOS
          include Exchangeable
          attr_accessor :cur
          QDIVK :CD_TomatoList, :CD_TomatoListC, :CD_TomatoEdit,
                :CD_TomatoBarV, :CD_TomatoBarVC, :CD_TomatoBarVLabelC,
                :CD_TomatoBarEdit, :CD_TomatoBarEditGroup
          def refresh_dom(dom_tree)
            $app.refresh_dom '.cd-tomatolistc', dom_tree
            Element['.XML-tomatolist-obj'].each{|e|
              ary = e.method(:attr).call('q-ary').split(';')
              ts = e.method(:attr).call('q-tshsh')
              r = []
              it1(ary,0,Proc.new{|h, m, h1, m1, pos, ppos, len, plen, ary, i|
                r.push "<div style='width: #{ plen * 100 }%;'></div>"
              })
              Element[".XML-tomatolist-obj[q-tshsh=#{ts}] > div.XML-tomatolist-obj-bar"].html r
            }
          end
          def refresh_element(ts)
            Element.find('#scr-tomato-tshsh').html( ts || 'New' )
            if ts
              e = Element[".XML-tomatolist-obj[q-tshsh=#{ts}]"]
              @cur = e.method(:attr).call('q-ary').split(';')
              refreshR
            end
          end
          def require_new
            refresh_element @tshsh = nil
          end
          def serialize
            "#tshsh="+ @tshsh.to_s + "&q-name=" +
            `$('.cd-tomatobaredit input[name=q-tname]').val()` +
            "&q-breakpoints=" + @cur.join(';')
          end
          def it1(ary, stf, enc)
            (stf...ary.size-1).each.collect{|i|
              h, m = ary[i].split(':')
              h1, m1 = ary[i+1].split(':')
              pos = h.to_i * 60 + m.to_i
              len = h1.to_i * 60 + m1.to_i - pos
              ppos = pos / 1440.0
              plen = len / 1440.0
              enc.call(h, m, h1, m1, pos, ppos, len, plen, ary, i)
            }
          end
          def refreshR
            c = []
            r = []
            l = []
            it1(@cur,0,Proc.new{|h, m, h1, m1, pos, ppos, len, plen, ary, i|
              c.push len
              r.push "<div style='height: #{ plen * 100 }%;'></div>"
              l.push "<div style='top: calc( #{ ppos * 100 }% - 0.5em );'>#{ ary[i] }</div>" if i != 0
            })
            s = 0
            c.each_with_index{|o, i| s += o if i % 2 == 1 }
            Element['.cd-tomatobarv'].html r
            Element['.cd-tomatobarvlabelc'].html l
            `$$('.cd-tomatobarvlabelc > div').touch(function(){
              $('.cd-tomatobaredit input[name=q-add]').val(this.innerText);
            });`
            `$('#scr-tomato-total').html(#{ s.to_s })`
          end
          def initialize
            @cur = ['00:00','24:00']
            @tshsh = nil
            @templates = Profile::AppTomatoManagement::Template
            templates = [ pstr('Templates:')]
            templates += @templates.collect{|k, ary|
              qB(body:str(k.to_s)){'app.$ref("Tomato.template;\n'+k+'")'}
            }
            super(
              title('Schedule Management'),
              CD_SpliterLR.new(
                CD_TomatoList.new(
                  title('Tomato List'),
                  CD_TomatoListC.new(),
                ),
                CD_TomatoEdit.new(
                  title('Tomato Edit'),
                  CD_TomatoBarVC.new(
                    CD_TomatoBarVLabelC.new,
                    CD_TomatoBarV.new
                  ),
                  CD_TomatoBarEdit.new(
                    CD_TomatoBarEditGroup.new(
                      pstr("Hash: <span id='scr-tomato-tshsh'>#{ @tshsh || 'New'}")
                    ),
                    CD_TomatoBarEditGroup.new(
                      str('Name: '),
                      str('<input name="q-tname"></input>'),
                      qB(body:str('New')){"app.$ref('Tomato.new');"},
                      qB(body:str('Save')){"app.$req('Tomato.update');"},
                    ),
                    CD_TomatoBarEditGroup.new(
                      pstr('<span id="scr-tomato-total">0</span> minutes available in total.'),
                    ),
                    CD_TomatoBarEditGroup.new(
                      str('<input name="q-add" type="time"></input>'),
                      qB(body:str('Add')){"app.$ref('Tomato.edit.add');"},
                      qB(body:str('Remove')){"app.$ref('Tomato.edit.remove');"},
                    ),
                    CD_TomatoBarEditGroup.new(*templates),
                  ),
                ),
              ),
            )
          end
          def compile
            $app.handle['Tomato'] = self
            exchange('Tomato')
            $app.cref['Tomato.template'] = lambda { |k| @cur = @templates[k]; refreshR }
            $app.cref['Tomato.edit.add'] = lambda {
              v = `$('.cd-tomatobaredit input[name=q-add]').val()`
              @cur.push v unless v.empty? || @cur.include?(v)
              @cur.sort!
              refreshR }
            $app.cref['Tomato.edit.remove'] = lambda {
              @cur.delete `$('.cd-tomatobaredit input[name=q-add]').val()`
              refreshR }
            $app.menu.push({
              sel:'.cd-tomatolist .XML-tomatolist-obj',
              k:{
                edit: 'app.$ref("Tomato.checkout;\n" + $(this).attr("q-tshsh"));',
                delete: 'app.$req("Tomato.delete;\n" + $(this).attr("q-tshsh"));',
              }
            })
            super
          end
        end
        def initialize
          super CD_Goal.new, CD_Tomato.new
        end
      end
      ##
      # Main Screen
      class CD_MainScreen < DIVK
        # Initialize
        def initialize
          super CD_TopBar.new, CD_Current.new, CD_BottomBar.new
        end
      end
      # Initialize
      def initialize
        super CD_MainScreen.new, CD_Menu.new, CD_AfterMenuObjs.new
        @status = :ready
      end
    end
  end
end

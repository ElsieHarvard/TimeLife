#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module Algorithm
    # Gale-Shapley Deferred Acceptance
    class DeferredAcceptance
      # initialize
      def initialize(arya, aryb, proca, procb)
        @ary_A = arya
        @ary_B = aryb
        @marker_A = proca
        @marker_B = procb
      end
      # prepare
      def prepare
        @score_A = \
          @ary_A.collect {|obj_a|
            @ary_B.collect {|obj_b|
              @marker_A.call obj_a, obj_b
            }
          }
        @score_B = \
          @ary_B.collect {|obj_b|
            @ary_A.collect {|obj_a|
              @marker_B.call obj_b, obj_a
            }
          }
        @table_A = @score_A.collect {|ary_a|
          @ary_B.each_index.collect {|ib|
            [ib, ary_a[ib]]
          }.sort_by{|e|e[1]}.reverse
        }
        return @score_A, @score_B
      end
      # main
      def main
        zt = @ary_A.each_index.collect {|i| [i, -1, false] }
        zp = @ary_B.collect {|obj| false }
        until zt.all? {|e| e[2] } or zp.all? {|e| e }
          zt.rotate! while zt[0][2]
          cidx = zt[0][0]
          until zt[0][2]
            zt[0][1] += 1
            cnp = @table_A[cidx][zt[0][1]][0]
            if !zp[cnp] ||
              @score_B[cnp][cidx] > @score_B[cnp][zp[cnp]]
              zt[zp[cnp]-cidx][2] = false if zp[cnp]
              zp[cnp] = cidx
              zt[0][2] = cnp
            end
          end
        end
        hsh = []
        zt.each {|(idx, _, icp)|
          hsh.push [
            idx ? @ary_A[idx] : false,
            icp ? @ary_B[icp] : false,
          ]
        }
        zp.each_with_index{|w,i| hsh.push [false, @ary_B[i]] unless w }
=begin
        zt.each{|(idx,_,icp)|
          next unless icp
          maxa = @marker_A.call @ary_A[idx],@ary_B[icp]
          zp.each_with_index{|ozp,izp|
            next unless ozp
            cura = @marker_A.call @ary_A[idx],@ary_B[izp]
            curb = @marker_B.call @ary_B[izp],@ary_A[idx]
            maxb = @marker_B.call @ary_B[izp],@ary_A[ozp]
            raise if cura > maxa && curb > maxb
          }
        }
=end
        return hsh
      end
    end
  end
end

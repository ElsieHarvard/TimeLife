#!/usr/bin/env ruby
#coding:utf-8

#======================================================================#
#                               TimeLife                               #
#----------------------------------------------------------------------#
# Main Author: Rain Arthur                                             #
# This work is licensed under the                                      #
# Creative Commons Attribution-ShareAlike 4.0 International License.   #
#======================================================================#

##
# Main Working Space of the full application
module TimeLife
  APP_VERSION                     = '2.0.0'
  APP_VERSION_CODE                = 'Renne'
  ENVIRONMENT                     = :server
end

##
# Load Server Side Application Booster to Boot
require "../bin/TimeLife_Booster.rb"

##
# Boost Application
APP.new.start

#======================================================================#

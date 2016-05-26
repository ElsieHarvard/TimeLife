#!/usr/bin/env ruby
#coding:utf-8

##
# Load Application Environment & Get Interactive Ruby Shell

require "./TimeLife.rb"
require "IRB"
include TimeLife
IRB.start(__FILE__)

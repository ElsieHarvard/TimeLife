#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  # Profile Module
  module Profile
    # Application Schedule Design
    module AppTomatoManagement
      Template = {
        :freeday => [
          '00:00',
          '09:00', '11:00',
          '12:00', '13:00',
          '13:45', '14:10',
          '15:30', '16:30',
          '19:00', '19:30',
          '20:30', '21:30',
          '24:00',
        ],
        :busyday => [
          '00:00',
          '07:00', '10:30',
          '11:00', '12:30',
          '13:00', '13:30',
          '14:00', '17:00',
          '18:30', '20:30',
          '21:00', '22:00',
          '24:00',
        ],
        :schoolday => [
          '00:00',
          '06:20', '07:15',
          '12:10', '12:30',
          '13:00', '13:40',
          '17:30', '22:00',
          '24:00',
        ],
      }
    end
  end
end

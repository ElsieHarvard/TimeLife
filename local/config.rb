#!/usr/bin/env ruby
#coding:utf-8

module TimeLife
  module Config
    # path
    LIBRARY                       = "../lib/timelife/"
    CMDPATH                       = "../lib/timelife/sys/command/"
    LOCAL                         = "../local/"
    LOGFILE                       = "../local/AppData/timelife/app.log"
    DBFILE                        = "../local/AppData/timelife/db.bin"
    DBFILEBAK                     = "../local/AppData/timelife/db.bin.bak"
    # ERB Render
    HTTPROOT                      = "../lib/timelife/server"
    HTTPSTATIC                    = "../lib/timelife/server/static/"
    HTTPCSS                       = "../lib/timelife/server/css"
    # server
    SERVERIP                      = '127.0.0.1'
    SERVERPORT                    = 12802
    SERVERLOG                     = "[%{%Y-%m-%d %H:%M:%S %z}t] %m %a %s %b %D %U"
    # HTTP response
    HTTPHEADER = {
        'X-Frame-Options'         => 'DENY',
        'X-Xss-Protection'        => '1; mode=block',
        'X-Content-Type-Options'  => 'nosniff',
        'Content-Type'            => 'text/html; charset=utf-8',
        'Content-Encoding'        => 'gzip',
        'Cache-Control'           => 'max-age=0, private, must-revalidate',
        'Vary'                    => 'Accept-Encoding',
    }
  end
end

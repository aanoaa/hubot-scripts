# Description:
#   Shorten URLs with bit.ly
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_BITLY_USERNAME
#   HUBOT_BITLY_API_KEY
#
# Commands:
#   hubot (bitly|shorten) (me) <url> - Shorten the URL using bit.ly
#
# Author:
#   sleekslush

select     = require("soupselect").select
htmlparser = require "htmlparser"
Buffer     = require('buffer').Buffer
Iconv      = require('iconv').Iconv

handler = new htmlparser.DefaultHandler()
parser  = new htmlparser.Parser handler

module.exports = (robot) ->
  robot.hear /(http(s?)\:\/\/\S+)/, (msg) ->
    return if msg.match[1].match(/twitter/) # twitter.coffee 에서 알아서 할거임

    msg
      .http(msg.match[1])
      .get() (err, res, body) ->
        if res.statusCode isnt 200
          return msg.send err

        title = 'no title'
        try
          parser.parseComplete body
          titles = select handler.dom, 'title'
          if titles[0] then title = titles[0].children[0].raw
        catch error
          console.log error

        matched = body.match(/charset ?= ?\"?[\'\"]?([^\'\"\/>]+)/)
        if matched and matched[1] != undefined
          if matched[1].match(/kr$/i) or matched[1].match(/^ks_c/i)
            try
              iconv  = new Iconv('CP949', 'UTF-8')
              buffer = iconv.convert(title)
              title  = buffer.toString()
            catch error
              console.log error

        msg
          .http("http://api.bitly.com/v3/shorten")
          .query
            login: process.env.HUBOT_BITLY_USERNAME
            apiKey: process.env.HUBOT_BITLY_API_KEY
            longUrl: msg.match[1]
            format: "json"
          .get() (err, res, body) ->
            try
              response = JSON.parse body
              msg.send if response.status_code is 200 then "[#{title}] - #{response.data.url}" else response.status_txt
            catch error
              msg.send "failed url shorten for `#{msg.match[1]}`"

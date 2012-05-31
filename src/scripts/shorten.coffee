# Shorten URLs with bit.ly
#
# <url> - Shorten the URL using bit.ly

select     = require("soupselect").select
htmlparser = require "htmlparser"

handler = new htmlparser.DefaultHandler()
parser  = new htmlparser.Parser handler

module.exports = (robot) ->
  robot.hear /(http(s?)\:\/\/\S+)/, (msg) ->
    return if msg.match[1].match(/twitter/)
    msg
      .http(msg.match[1])
      .get() (err, res, body) ->
        parser.parseComplete body
        titles = select handler.dom, 'title'
        title = if titles then titles[0].children[0].raw else 'no title'
        msg
          .http("http://api.bitly.com/v3/shorten")
          .query
            login: process.env.HUBOT_BITLY_USERNAME
            apiKey: process.env.HUBOT_BITLY_API_KEY
            longUrl: msg.match[1]
            format: "json"
          .get() (err, res, body) ->
            response = JSON.parse body
            msg.send if response.status_code is 200 then "[#{title}] - #{response.data.url}" else response.status_txt

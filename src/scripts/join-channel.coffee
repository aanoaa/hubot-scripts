# Description:
#   push a bot to irc channel
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot join <channel> - bot will join to <channel>
#   hubot part <channel> - bot will part from <channel>
#
# Author:
#   aanoaa

module.exports = (robot) ->
  isIrc = /irc/i.test(robot.adapter.constructor.toString())
  ## http://www.irchelp.org/irchelp/rfc/chapter1.html#c1_3
  robot.respond /join \#?([a-zA-Z0-9]{1,200})/i, (msg) ->
    robot.adapter.join("##{msg.match[1]}") if isIrc
  robot.respond /part \#?([a-zA-Z0-9]{1,200})/i, (msg) ->
    robot.adapter.part("##{msg.match[1]}") if isIrc

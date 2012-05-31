# evaluate code.
#
# eval <code> - evaluate perl <code> and show the result.

module.exports = (robot) ->
  robot.hear /^eval (.+)/i, (msg) ->
    msg
      .http("http://api.dan.co.jp/lleval.cgi")
      .query(s: "#!/usr/bin/perl\n#{msg.match[1]}")
      .get() (err, res, body) ->
        out = JSON.parse(body)
        msg.send if out.stderr then out.stderr else out.stdout

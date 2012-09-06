# Description:
#   logging all conversation
#
# Dependencies:
#   mysql  : 2.0.0-alpha3
#   express: 3.0
#
# Configuration:
#   mysql> create database irclog;
#   mysql> create user 'irclog'@'localhost' identified by 'irclog';
#   mysql> grant all privileges on `irclog`.* to 'irclog'@'localhost' with grant option;
#   mysql> use irclog;
#   mysql> DROP TABLE IF EXISTS `log`;
#   mysql> CREATE TABLE `log` (
#     `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
#     `channel`    VARCHAR(255) NOT NULL,
#     `nickname`   VARCHAR(255) NOT NULL,
#     `message`    TEXT NOT NULL,
#     `created_at` INT UNSIGNED NOT NULL,
#     PRIMARY KEY (`id`)
#   ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#
# Commands:
#   http://hostname:8888/channels/
#   http://hostname:8888/channels/:channel/
#   http://hostname:8888/channels/:channel/yyyy-mm-dd/
#
# Author:
#   aanoaa

module.exports = (robot) ->
  logger = new Logger()
  new Router(logger)
  robot.hear /(.+)/i, (msg) ->
    logger.save(msg.message)

mysql   = require 'mysql'
express = require 'express'

class Router
  constructor: (@logger) ->
    http = express.createServer { host: 'localhost', port: 8888 }
    http.set "jsonp callback", true
    http.listen 8888
    http.get '/channels', (req, res) =>
      res.json process.env.HUBOT_IRC_ROOMS.split(',')
    http.get '/channels/:channel', (req, res) =>
      dt = new Date()
      if req.query["callback"]
        res.redirect("/channels/#{req.params.channel}/#{dt.getFullYear()}-#{dt.getMonth() + 1}-#{dt.getDate()}?callback=#{req.query['callback']}")
      else
        res.redirect("/channels/#{req.params.channel}/#{dt.getFullYear()}-#{dt.getMonth() + 1}-#{dt.getDate()}")
    http.get '/channels/:channel/:date', (req, res) =>
      dt = req.params.date.split('-')
      from = new Date(dt[0], (dt[1] - 1), dt[2]).getTime()
      to = from + (86399 * 1000)

      @logger.logs(req.params.channel, from, to, (err, rows, fields) ->
        throw err if err
        logs = ''
        for row in rows
          logs += """
          <tr>
            <td>#{row.nickname}</td>
            <td>#{row.message}</td>
            <td>#{new Date(new Date(0).setUTCSeconds(row.created_at)).toISOString()}</td>
          </tr>
          """
          html = """
          <html>
            <head>
              <title>Log Viewer</title>
              <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/css/bootstrap-combined.min.css" rel="stylesheet">
            </head>
            <body>
              <table class="table table-bordered table-striped table-condensed">
                <tr>
                  <th>nickname</th>
                  <th>message</th>
                  <th>time</th>
                </tr>
                #{logs}
              </table>
            </body>
          </html>
          """
        res.send html
      )

class Logger
  constructor: ->
    @conn = mysql.createConnection
      host: 'localhost'
      user: 'irclog'
      password: 'irclog'
    @conn.connect()
    @conn.query('use irclog')
  save: (msg) ->
    @conn.query(
      """
      INSERT INTO log (`channel`,`nickname`,`message`,`created_at`)
      VALUES ('#{msg.user.room}','#{msg.user.name}','#{msg.text}',#{new Date().getTime()/1000})
      """
    , (err, rows, fields) ->
      throw err if err
    )
  logs: (channel, from, to, cb) ->
    @conn.query(
      "SELECT * FROM log WHERE `channel` = '##{channel}' AND (`created_at` >= #{from/1000} AND `created_at` <= #{to/1000})"
    , cb)

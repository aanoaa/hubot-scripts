# logging.
#
# save messages in this channel - http://example.com/

_ = require "underscore"
http = require 'http'
mongoose = require 'mongoose'

class Log
  constructor: (mongoose, opts) ->
    @connect opts.host, opts.db
    @model = {}
    Schema = mongoose.Schema
    _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
      mongoose.model channel, new Schema
        nickName: String
        message: String
        timestamp: { type: Date, default: new Date().toJSON() }
      @model[channel] = mongoose.model channel
    http.createServer (req, res) =>
      # /channel/perl-kr/date/2012-02-10/ => 오늘꺼 주고, 이후는 계속해서주자
      res.writeHead 200, { "Content-Type": "text/plain" }
      res.write 'hello world'
      res.end()
    .listen(8888)
  connect: (host, db) =>
    @db = mongoose.connect "mongodb://#{host}/#{db}"
  save: (msg) =>
    log = new @model[msg.user.room]
    log.nickName = msg.user.name
    log.message = msg.text.toString 'utf8'
    log.save() # TODO: error handling function(err)
  dump: =>
    _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
      @model[channel].find({}).each (err, log) ->
        if log
          console.log log.nickName
          console.log log.message
          console.log log.timestamp

log = new Log mongoose,
  host: process.env.HUBOT_LOG_DBHOST or 'localhost'
  db: 'irc_log'

module.exports = (robot) ->
  robot.hear /(.+)/, (msg) ->
    log.save msg.message

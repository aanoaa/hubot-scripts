# logging.
#
# logging HUBOT_IRC_ROOMS messages and view to JSON on http://HUBOT_LOG_HOST:HUBOT_LOG_PORT

_ = require 'underscore'
express = require 'express'
mongoose = require 'mongoose'
http = express.createServer(express.logger())
http.set("jsonp callback", true)

class Router
  constructor: (@logger, opts) ->
    http.listen(opts.port)
    http.get '/channel', (req, res) =>
      res.json process.env.HUBOT_IRC_ROOMS.split(',')
    http.get '/channel/:channel', (req, res) =>
      dt = new Date()
      if req.query["callback"]
        res.redirect("/channel/#{req.params.channel}/#{dt.getFullYear()}-#{dt.getMonth() + 1}-#{dt.getDate()}?callback=#{req.query['callback']}")
      else
        res.redirect("/channel/#{req.params.channel}/#{dt.getFullYear()}-#{dt.getMonth() + 1}-#{dt.getDate()}")
    http.get '/channel/:channel/:date', (req, res) =>
      dt = req.params.date.split('-')
      from = new Date(dt[0], (dt[1] - 1), dt[2]).getTime()
      to = from + (86399 * 1000)
      @logger.model["##{req.params.channel}"].find { timestamp: { $gt: from, $lt: to } }, (err, logs) ->
        console.log err if err # TODO: better error handling
        msg = []
        _.each logs, (log) ->
          msg.push log if log
        res.json msg

class Logger
  constructor: (mongoose, opts) ->
    @connect opts.host, opts.db
    @model = {}
    Schema = mongoose.Schema
    _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
      mongoose.model channel, new Schema
        nickName: String
        message: String
        timestamp: { type: Number, default: new Date().getTime() }
      @model[channel] = mongoose.model channel
    new Router(@, opts)
  connect: (host, db) =>
    @db = mongoose.connect "mongodb://#{host}/#{db}"
  save: (msg) =>
    log = new @model[msg.user.room]
    log.nickName = msg.user.name
    log.message = msg.text
    log.timestamp = new Date().getTime()
    log.save() # TODO: error handling function(err)
  dump: =>
    _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
      @model[channel].find({}).each (err, log) ->
        if log
          console.log log.nickName
          console.log log.message
          console.log log.timestamp

logger = new Logger mongoose,
  host: process.env.HUBOT_LOG_HOST or 'localhost'
  port: process.env.HUBOT_LOG_PORT or 8888

module.exports = (robot) ->
  robot.hear /(.+)/, (msg) ->
    logger.save msg.message

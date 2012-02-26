# logging.
#
# logging HUBOT_IRC_ROOMS messages then toJSON via WEB - http://HUBOT_LOG_HOST:HUBOT_LOG_PORT

_ = require "underscore"
http = require('express').createServer()
mongoose = require 'mongoose'

class Router
  constructor: (@logger, opts) ->
    http.listen(opts.port)
    http.get '/', (req, res) =>
      msg = []
      _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
        msg.push "http://#{opts.host}:#{opts.port}/channel/#{channel.split('#')[1]}"
      res.send JSON.stringify(msg)
    http.get '/channel/:channel', (req, res) =>
      dt = new Date()
      res.redirect("/channel/#{req.params.channel}/date/#{dt.getFullYear()}-#{dt.getMonth()}-#{dt.getDate()}")
    http.get '/channel/:channel/date/:date', (req, res) =>
      dt = req.params.date.split('-')
      from = new Date(dt[0], dt[1], dt[2]).getTime()
      to = from + (86399 * 1000)
      @logger.model["##{req.params.channel}"].find { timestamp: { $gt: from, $lt: to } }, (err, logs) ->
        console.log err if err # TODO: better error handling
        msg = []
        _.each logs, (log) ->
          msg.push log if log
        res.send JSON.stringify(msg)
    http.get '/channel/:channel/date/:date/:epoch', (req, res) =>
      @logger.model["##{req.params.channel}"].find { timestamp: { $gt: req.params.epoch } }, (err, logs) ->
        console.log err if err # TODO: better error handling
        msg = []
        _.each logs, (log) ->
          msg.push log if log
        res.send JSON.stringify(msg)

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

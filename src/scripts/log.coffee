# logging.
#
# save messages in this channel - http://example.com/

_ = require "underscore"
http = require('express').createServer()
mongoose = require 'mongoose'

class Router
  constructor: (@logger) ->
    http.listen(8888)
    http.get '/', (req, res) ->
      res.sendfile("#{__dirname}/log.html")
    http.get '/channel/:channel', (req, res) =>
      dt = new Date()
      res.redirect("/channel/#{req.params.channel}/date/#{new Date().toString()}")
    http.get '/channel/:channel/date/:date', (req, res) =>
      dt = new Date "#{req.params.date}"
      from = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate()).getTime()
      to = from + (86399 * 1000)
      @logger.model["##{req.params.channel}"].find { timestamp: { $gt: from, $lt: to } }, (err, logs) ->
        console.log err if err # TODO: better error handling
        msg = []
        _.each logs, (log) ->
          msg.push log
        res.send JSON.stringify(msg)
    http.get '/channel/:channel/date/:date/:epoch', (req, res) =>
      @logger.model["##{req.params.channel}"].find { timestamp: { $gt: req.params.epoch } }, (err, logs) ->
        console.log err if err # TODO: better error handling
        msg = []
        _.each logs, (log) ->
          msg.push log
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
    new Router(@)
  connect: (host, db) =>
    @db = mongoose.connect "mongodb://#{host}/#{db}"
  save: (msg) =>
    log = new @model[msg.user.room]
    log.nickName = msg.user.name
    log.message = msg.text
    log.save() # TODO: error handling function(err)
  dump: =>
    _.each process.env.HUBOT_IRC_ROOMS.split(','), (channel) =>
      @model[channel].find({}).each (err, log) ->
        if log
          console.log log.nickName
          console.log log.message
          console.log log.timestamp

logger = new Logger mongoose,
  host: process.env.HUBOT_LOG_DBHOST or 'localhost'
  db: 'irc_log'

module.exports = (robot) ->
  robot.hear /(.+)/, (msg) ->
    logger.save msg.message

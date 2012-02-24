# logging.
#
# save messages in this channel - http://example.com/

class Log
  constructor: (mongoose, opts) ->
    @connect opts.host, opts.db
    Schema = mongoose.Schema
    mongoose.model opts.channel, new Schema
      nickName: String
      message: String
      timestamp: { type: Date, default: new Date().toJSON() }
    @model = mongoose.model opts.channel
  connect: (host, db) =>
    @db = mongoose.connect "mongodb://#{host}/#{db}"
  save: (msg) =>
    # msg.user.room: channel
      log = new @model
    log.nickName = msg.user.name
    log.message = msg.text.toString 'utf8'
    log.save() # TODO: error handling function(err)
  dump: =>
    @model.find({}).each (err, log) ->
      if log
        console.log log.nickName
        console.log log.message
        console.log log.timestamp

mongoose = require 'mongoose'
log = new Log mongoose, { host: 'localhost', db: 'irc_log', channel: '#perl-kr' }

module.exports = (robot) ->
  robot.hear /(.+)/, (msg) ->
    log.save msg.message

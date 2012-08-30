# Yet another bugzilla client.
#
# bug <number> - show the bug title.

module.exports = (robot) ->
  client = new JSONRPC
    url: "http://bugs.silex.kr/jsonrpc.cgi"
  robot.hear /^bug (.+)/i, (msg) ->
    client.call 'Bug.get', ids: [msg.match[1]], (self, res, body) ->
      bug = JSON.parse(body)['result']['bugs'][0]
      msg.send "\##{bug.id} #{bug.summary} - [#{bug.status}, #{bug.assigned_to}, #{priorityMap[bug.priority]}]"

priorityMap =
  Lowest : '★☆☆☆☆'
  Low    : '★★☆☆☆'
  Normal : '★★★☆☆'
  High   : '★★★★☆'
  Highest: '★★★★★'

class JSONRPC
  constructor: (settings) ->
    httpClient = require 'scoped-http-client'
    @url  = settings.url
    @http = httpClient.create(@url)
    @username = settings.username || process.env.HUBOT_BZ_USERNAME
    @password = settings.password || process.env.HUBOT_BZ_PASSWORD
    @login(@username, @password)
  call: (method, params, cb) ->
    params = JSON.stringify { method: method, params: params, version: '1.1' }
    @http
      .header('cookie', @cookie || '')
      .header("Accept", "application/json")
      .header("Content-Type", "application/json")
      .header("User-Agent", "hubot-bugzilla-script-jsonrpc-client")
      .post(params, (err, req) ->
        console.log err if err
      ) (err, res, body) =>
        switch res.statusCode
          when 200
            cb(@, res, body) if cb
            return body
          when 102
            return @login(@username, @password) and @call(method, params, cb)
          else
            return JSON.parse(body).error
  set_cookies: (res) ->
    if res.headers["set-cookie"]
      @cookie = "#{res.headers['set-cookie'][0].split(';')[0]}; #{res.headers['set-cookie'][1].split(';')[0]}"
  login: (username, password) ->
    @call 'User.login',
      login   : username
      password: password
    , (self, res, body) -> self.set_cookies(res)

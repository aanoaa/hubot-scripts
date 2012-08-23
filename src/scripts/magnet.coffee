# parse seed TITLE and send to channel from a magnet link
#
# magnet:?xt=urn:btih:d08ba6938048d60741e1e847c4e74c47fbe75d9f&dn=%28KoR%29%EA%B0%95%EB%82%A8%20%EC%8A%A4%ED%94%84%EB%A6%AC%EC%8A%A4%EB%A7%A4%EC%9E%A5%20%EC%95%8C%EB%B0%94%EC%83%9D%20%EA%B9%80%EC%9D%80%EC%A7%84.avi&tr=udp%3A%2F%2Ftracker.istole.it%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrentbox.com%3A2710%2Fannoun
# result: (KoR)강남 스프리스매장 알바생 김은진.avi

module.exports = (robot) ->
  robot.hear /^magnet:(.+)/i, (msg) ->
    matched = msg.match[1].match /dn=([^&]*)/
    if matched[1] then msg.send decodeURIComponent(matched[1])

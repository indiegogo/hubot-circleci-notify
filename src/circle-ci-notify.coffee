# Description:
#   Get notifications when your CircleCI builds finish
#
# Commands:
#   hubot ci[rcle] alert <repo> <branch> - Receive a DM when CircleCI completes a build for your branch
#   hubot ci[rcle] rm alert <repo> <branch> - Remove notifications for CircleCI builds of your branch
#   hubot ci[rcle] build alert <build number> - Receive a DM when CircleCI completes a specific build

CIRCLE_ALERT_PRE = 'circleci-alert'

class CircleCIAlert
  constructor: (@robot, msg) ->
    @repo = msg.match[1].toLowerCase()
    @branch = msg.match[2].toLowerCase()
    @user = msg.message.user.name
    @key = "#{CIRCLE_ALERT_PRE}-#{@repo}-#{@branch}"

  addWatcher: ->
    watchers = @robot.brain.get(@key) or []
    if @user in watchers
      @_dm 'You already receive alerts for this branch.'
    else
      watchers.push @user
      @_setWatchers watchers
      @_dm "You will receive alerts when builds for #{@repo} - #{@branch} finish."

  removeWatcher: ->
    watchers = @robot.brain.get(@key) or []
    if @user not in watchers
      @_dm 'You are not receiving alerts for this branch.'
    else
      @_setWatchers watchers.filter (u) => u isnt @user
      @_dm "You will no longer receive alerts when builds for #{@repo} - #{@branch} finish."

  # private

  _dm: (msg) -> @robot.send {room: @user}, msg

  _setWatchers: (watchers) ->
    @robot.brain.set @key, watchers
    @robot.brain.save

module.exports = (robot) ->
  robot.respond /(?:ci|circle) build alert (\d+)/i, (msg) ->
    user = msg.message.user.name
    build = msg.match[1]
    watchers = robot.brain.get("#{CIRCLE_ALERT_PRE}-#{build}") or []
    if user in watchers
      robot.send {room: user}, 'You are already watching this build.'
    else
      watchers.push user
      robot.brain.set "#{CIRCLE_ALERT_PRE}-#{build}", watchers
      robot.brain.save
      robot.send {room: user}, 'You will receive an alert when this build finishes.'

  robot.respond /(?:ci|circle) alert (\w+) ([\w\d\/\.\-]+)/i, (msg) ->
    alert = new CircleCIAlert robot, msg
    alert.addWatcher()

  robot.respond /(?:ci|circle) (?:rm|remove) alert (\w+) ([\w\d\/\.\-]+)/i, (msg) ->
    alert = new CircleCIAlert robot, msg
    alert.removeWatcher()

  robot.router.post '/hubot/circleci', (req, res) ->
    payload = req.body.payload
    branch = payload.branch.toLowerCase()
    repo = payload.reponame.toLowerCase()
    watchers = robot.brain.get("#{CIRCLE_ALERT_PRE}-#{repo}-#{branch}") or []

    buildWatchers = robot.brain.get "#{CIRCLE_ALERT_PRE}-#{payload.build_num}"
    if buildWatchers?
      watchers = watchers.concat buildWatchers
      robot.brain.remove "#{CIRCLE_ALERT_PRE}-#{payload.build_num}"
      robot.brain.save

    return res.send 'No users are watching this branch.' if watchers.length is 0
    message = "Build for #{repo} - #{branch}: #{payload.outcome.toUpperCase()}. See more at #{payload.build_url}"
    robot.send {room: user}, message for user in watchers
    res.send 'Users alerted of build status.'

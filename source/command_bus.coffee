
class Space.messaging.CommandBus extends Space.Object

  dependencies: {
    meteor: 'Meteor'
    api: 'Space.messaging.Api'
  }

  @mixin [
    Space.messaging.Hooks('Space.messaging.CommandBusHooks')
  ]

  _handlers: null
  _onSendCallbacks: null

  constructor: ->
    super
    @_handlers = {}
    @_onSendCallbacks = []

  send: (command, callback) ->
    if @meteor.isServer
      @_sendToServer(command, callback)
    else
      @_sendToClient(command, callback)

  _sendToServer: (command, callback) ->
    handler = @_handlers[command.typeName()]
    callback(command) for callback in @_onSendCallbacks
    if !handler?
      message = "Missing command handler for <#{command.typeName()}>."
      throw new Error message

    for beforeHook in @_getBeforeHooks(command)
      beforeHook(command, () -> )

    try
      result = handler(command)
      response = {error: undefined, result: result}
    catch e
      response = {error: e, result: undefined}

    for afterHook in @_getAfterHooks(command, response)
      afterHook(command, response, () -> )

    return result

  _sendToClient: (command, callback) ->
    apiCallback = (err, result) =>
      callback(err, result) if callback?
      response = {error: err, result: result}

      @_waterfall @_getAfterHooks(command, response), (command, response) =>

    @_waterfall @_getBeforeHooks(command), (command) =>
      @api.send(command, apiCallback)

  _getBeforeHooks: (command) ->
    ###
    TODO: should rules be fired before Api hooks or like in here - in between
    When here:
    + it let app validation first be done before any business rule is applied
    - and in same time it require to run whole app validation before business
      logic
    ###
    beforeHooks = [].concat(
      @getBeforeHooks(command.typeName()), @getRuleHooks(command.typeName())
    )

    if @meteor.isServer
      return beforeHooks
    else
      # First callback is passing appropriate arguments to rest of hooks
      return [(cb) -> cb(command)].concat(beforeHooks)

  _getAfterHooks: (command, response) ->
    afterHooks = @getAfterHooks(command.typeName())

    if @meteor.isServer
      return afterHooks
    else
      # First callback is passing appropriate arguments to rest of hooks
      return [(cb) -> cb(command, response)].concat(afterHooks)

  registerHandler: (typeName, handler, overrideExisting) ->
    if @_handlers[typeName]? and !overrideExisting
      throw new Error "There is already an handler for #{typeName} commands."
    @_handlers[typeName] = handler

  overrideHandler: (typeName, handler) ->
    @registerHandler typeName, handler, true

  getHandlerFor: (commandType) -> @_handlers[commandType]

  hasHandlerFor: (commandType) -> @getHandlerFor(commandType)?

  onSend: (handler) -> @_onSendCallbacks.push handler

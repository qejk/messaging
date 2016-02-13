
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

    wrappedHandler = (command, asyncCallback) =>
      bindEnv = Meteor.bindEnvironment

      @_waterfall @_getBeforeHooks(command), bindEnv (command) =>
        try
          result = handler(command)
          response = {error: undefined, result: result or undefined}
        catch e
          response = {error: e, result: undefined}

        @_waterfall(
          @_getAfterHooks(command, response), bindEnv (command, response) ->
            if response.error
              asyncCallback(response.error, undefined)
            else
              asyncCallback(undefined, result)
        )

    return Meteor.wrapAsync(wrappedHandler)(command)

  _sendToClient: (command, callback) ->
    apiCallback = (err, result, apiAfterHooks) =>
      response = {error: err, result: result}

      callback(err, result) if callback?

      # Fire Api after hooks in order
      @_waterfall apiAfterHooks, () =>
        # CommandBus after hooks
        afterHooks = @_getAfterHooks(command, response)
        @_waterfall(afterHooks, (command, response) =>)

    @_waterfall @_getBeforeHooks(command), (command) =>
      @api.send(command, apiCallback, true)

  _getBeforeHooks: (command) ->
    ###
    TODO: should rules be fired before Api hooks or like in here - in between
    When here:
    + it let app validation first be done before any business rule is applied
    - and in same time it require to run whole app validation before business
      logic
    ###

    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(command)].concat(
      @getBeforeHooks(command.typeName()), @getRuleHooks(command.typeName())
    )

  _getAfterHooks: (command, response) ->
    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(command, response)].concat(
      @getAfterHooks(command.typeName())
    )

  registerHandler: (typeName, handler, overrideExisting) ->
    if @_handlers[typeName]? and !overrideExisting
      throw new Error "There is already an handler for #{typeName} commands."
    @_handlers[typeName] = handler

  overrideHandler: (typeName, handler) ->
    @registerHandler typeName, handler, true

  getHandlerFor: (commandType) -> @_handlers[commandType]

  hasHandlerFor: (commandType) -> @getHandlerFor(commandType)?

  onSend: (handler) -> @_onSendCallbacks.push handler

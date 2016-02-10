
class Space.messaging.CommandBus extends Space.Object

  dependencies: {
    meteor: 'Meteor'
    api: 'Space.messaging.Api'
    _hooks: 'Space.messaging.HookRegistry'
  }

  _handlers: null
  _onSendCallbacks: null

  constructor: ->
    super
    @_handlers = {}
    @_onSendCallbacks = []

  send: (command, callback) ->
    if @meteor.isServer
      # ON THE SERVER

      # Ensure, that domain rules are testable on server side thus allowing
      # encapsulated tests of domain package
      for item in @_hooks.getRuleHooks(command.typeName())
        item.hook.apply(item.hook, arguments)

      handler = @_handlers[command.typeName()]
      callback(command) for callback in @_onSendCallbacks
      if !handler?
        message = "Missing command handler for <#{command.typeName()}>."
        throw new Error message
      handler(command)
    else
      # ON THE CLIENT
      @api.send command, callback

  registerHandler: (typeName, handler, overrideExisting) ->
    if @_handlers[typeName]? and !overrideExisting
      throw new Error "There is already an handler for #{typeName} commands."
    @_handlers[typeName] = handler

  overrideHandler: (typeName, handler) ->
    @registerHandler typeName, handler, true

  getHandlerFor: (commandType) -> @_handlers[commandType]

  hasHandlerFor: (commandType) -> @getHandlerFor(commandType)?

  onSend: (handler) -> @_onSendCallbacks.push handler

Space.messaging.StaticHandlers = {

  Dependencies: {
    underscore: 'underscore'
  }

  Static: {
    _handlers: null
    _setupHandler: (name, handler) ->
      @_handlers[name] = original: handler, bound: null
  }

  onMixinApplied: -> @_handlers ?= {}

  _getHandlerFor: (method) ->
    @constructor._handlers ?= {}
    @constructor._handlers[method]

  _bindHandlersToInstance: ->
    handlers = @constructor._handlers
    for name, handler of handlers
      boundHandler = @underscore.bind handler.original, this
      handlers[name].bound = boundHandler

}
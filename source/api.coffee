

class Space.messaging.Api extends Space.Object

  dependencies: {
    injector: 'Injector',
    meteor: 'Meteor'
    underscore: 'underscore'
  }

  @mixin [
    Space.messaging.DeclarativeMappings
    Space.messaging.StaticHandlers
    Space.messaging.CommandSending
    Space.messaging.EventPublishing
    Space.messaging.Hooks('Space.messaging.ApiHooks')
    {statics: Space.messaging.Hooks('Space.messaging.ApiHooks')}
  ]

  methods: -> []

  # Register a handler for a Meteor method and add it as
  # method to instance to simplify testing of methods.
  @method: (type, handler) ->
    @_setupHandler type, handler
    @_registerMethod type, @_setupMethod(type)


  # Sugar for sending messages to the server
  @send: (message, callback, isCalledFromCmdBus) ->
    # TODO: We could fake DDPCommon.MethodInvocation here so the context is
    # like Meteor's one (like what is happening in package 'ddp-client' on
    # 'livedata_connection.js' - Meteor.call()) however this can cause
    # confusion on long run
    context = {
      isSimulation: true
    }
    # Only when accounts package is present on application
    context.userId = Meteor.userId if Meteor.userId?

    meteorCallCallback = (err, result) =>
      response = {error: undefined, result: result or undefined}
      response.error = err if err?

      # TODO: would be nice to use here easier way to validate origination of
      # this.send() method invocation, however was having issues with stack
      # trace ((new Error).stack) - do to minifying

      afterHooks = @_getAfterHooks(context, message, response)
      # Pass Api hooks here down back to CommandBus if this.send()
      # invocation originates from CommandBus in first place order sake
      if isCalledFromCmdBus
        callback(err, result, afterHooks)
      else
        @_waterfallThrough(afterHooks, (context, message, response) =>
          callback(err, result) if callback
        )

    @_waterfallThrough @_getBeforeHooks(context, message), (context, message) =>
      Meteor.call(message.typeName(), message, meteorCallCallback)

  @_getBeforeHooks: (context, message) ->
    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(context, message)].concat(
      @getBeforeHooks(message.typeName())
    )

  @_getAfterHooks: (context, message, response) ->
    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(context, message, response)].concat(
      @getAfterHooks(message.typeName())
    )

  # Register the method statically, so that is done only once
  @_registerMethod: (name, body) ->
    method = {}
    method[name] = body
    Meteor.methods method

  @_setupMethod: (type) ->
    name = type.toString()
    @_handlers ?= {}
    handlers = @_handlers
    return (param) ->
      try type = Space.resolvePath(name)
      if type.isSerializable then check param, type
      # Provide the method context to bound handler
      args = [this].concat Array::slice.call(arguments)
      handlers[name].bound.apply null, args

  onDependenciesReady: ->
    @_setupDeclarativeMappings 'methods', @_setupDeclarativeHandler
    @_bindHandlersToInstance()

    @_setupBeforeHooks() if @beforeMap?
    @_setupAfterHooks() if @afterMap?
    @_setupMiddleware() if @middleware?

  _setupDeclarativeHandler: (handler, type) =>
    existingHandler = @_getHandlerFor type
    if existingHandler?
      @constructor._setupHandler type, handler
    else
      if @meteor.isClient
        @constructor.method type, handler
      else
        wrappedHandler = (context, message, asyncCallback) =>
          bindEnv = Meteor.bindEnvironment

          beforeHooks = @_getBeforeHooks(context, message)
          @_waterfallThrough beforeHooks, bindEnv (context, message) =>
            try
              # Don't throw error right away, let developer have freedom
              # to log error or behave accordingly
              result = handler.apply(@, [context, message])
              response = {error: undefined, result: result or undefined}
            catch e
              response = {error: e, result: undefined}

            afterHooks = @_getAfterHooks(context, message, response)
            @_waterfallThrough afterHooks, bindEnv (context, message, response) ->
              if response.error
                asyncCallback(response.error, undefined)
              else
                asyncCallback(undefined, result)
        # TODO: need clarification if Meteor.defer + context.unblock still work
        # as they should
        @constructor.method type, Meteor.wrapAsync(wrappedHandler)


  _getBeforeHooks: (context, message) ->
    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(context, message)].concat(
      @getBeforeHooks(message.typeName())
    )

  _getAfterHooks: (context, message, response) ->
    # First callback is passing appropriate arguments to rest of hooks
    return [(cb) -> cb(context, message, response)].concat(
      @getAfterHooks(message.typeName())
    )

  _setupBeforeHooks: ->
    @_setupDeclarativeMappings('beforeMap', (hook, methodName) =>
      @addBeforeHook(methodName, @, hook.bind(@))
    )

  _setupAfterHooks: ->
    @_setupDeclarativeMappings('afterMap', (hook, methodName) =>
      @addAfterHook(methodName, @, hook.bind(@))
    )

  _setupMiddleware:->
    for mw in @middleware().reverse()
      instance = new mw({isGlobal: false})
      @injector.injectInto(instance)

      if instance.before?
        @addHookToMethods((handler, methodName) =>
          @addBeforeHook(methodName, instance, instance.before.bind(instance))
        )

      if instance.beforeMap?
        @_setupDeclarativeMappings.call(
          instance, 'beforeMap', (hook, methodName) =>
            @addBeforeHook(methodName, instance, hook.bind(instance))
        )

      if instance.afterMap?
        @_setupDeclarativeMappings.call(
          instance, 'afterMap', (hook, methodName) =>
            @addAfterHook(methodName, instance, hook.bind(instance))
        )

      if instance.after?
        @addHookToMethods((handler, methodName) =>
          @addAfterHook(methodName, instance, instance.after.bind(instance))
        )

  addHookToMethods: (callback) ->
    methods = @methods()
    methods = [methods] unless @underscore.isArray(methods)

    for obj in methods
      callback(handler, methodName) for methodName, handler of obj

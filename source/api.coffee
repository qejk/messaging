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
    Space.messaging.Hooks
    {statics: Space.messaging.Hooks}
  ]

  methods: -> []

  # Register a handler for a Meteor method and add it as
  # method to instance to simplify testing of methods.
  @method: (type, handler) ->
    @_setupHandler type, handler
    @_registerMethod type, @_setupMethod(type)


  # Sugar for sending messages to the server
  @send: (message, callback) ->
    self = @
    # TODO: We could fake DDPCommon.MethodInvocation here so the context is
    # like Meteor's one (like what is happening in package 'ddp-client' on
    # 'livedata_connection.js' - Meteor.call()) however this can cause
    # confusion on long run
    methodContext = {}
    # First callback is passing appropriate arguments to rest of hooks
    beforeHooks = [(cb) -> cb(methodContext, message)].concat(
      @getBeforeHooks(message.typeName())
    )
    # TODO: should rules be fired before Api hooks or like in here - in between
    # When here:
    # + it let app validation first be done before any business rule is applied
    # - and in same time it require to run whole app validation before business
    #   logic
    rules = [(cb) -> cb(message)].concat(@getRuleHooks(message.typeName()))

    this.waterfall beforeHooks, (context, message) ->
      # For expressiveness while rule hooks are added on Api - I added this var
      command = message
      self.waterfall rules, (command) ->
        Meteor.call message.typeName(), message, (err, result) ->
          response = {error: err, result: result}
          afterHooks = [(cb) -> cb(methodContext, message, response)].concat(
            self.getAfterHooks(message.typeName())
          )
          self.waterfall afterHooks, (context, message, response) ->
            callback(err, result) if callback

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
    self = @

    existingHandler = @_getHandlerFor type
    if existingHandler?
      @constructor._setupHandler type, handler
    else
      if @meteor.isClient
        @constructor.method type, handler
      else
        # 3d argument of Meteor.wrapAsync will be here async callback
        wrappedHandler = (context, message, callback) =>
          # First callback is passing appropriate arguments to rest of hooks
          beforeHooks = [(cb) -> cb(context, message)].concat(
            self.getBeforeHooks(type)
          )

          self.waterfall beforeHooks, Meteor.bindEnvironment (context, message) ->
            try
              # Don't throw error right away, let developer have freedom
              # to log error or behave accordingly
              result = handler.apply(self, [context, message])
              response = {error: null, result: result}
            catch e
              response = {error: e, result: null}

            afterHooks = [(cb) -> cb(context, message, response)].concat(
              self.getAfterHooks(type)
            )
            self.waterfall afterHooks, (context, message, response) ->
              if response.error
                callback(response.error, null)
              else
                callback(null, result)
        # TODO: need clarification if Meteor.defer + context.unblock still work
        # as they should
        @constructor.method type, Meteor.wrapAsync(wrappedHandler)

  _setupBeforeHooks: ->
    @_setupDeclarativeMappings('beforeMap', (hook, methodName) =>
      @addBeforeHook(methodName, @constructor, hook.bind(@))
    )

  _setupAfterHooks: ->
    @_setupDeclarativeMappings('afterMap', (hook, methodName) =>
      @addAfterHook(methodName, @constructor, hook.bind(@))
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

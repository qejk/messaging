class Space.messaging.Api extends Space.Object

  dependencies: {
    injector: 'Injector',
    meteor: 'Meteor'
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
    # TODO: We could fake DDPCommon.MethodInvocation here so the context is
    # like Meteor's one (like what is happening in package 'ddp-client' on
    # 'livedata_connection.js' - Meteor.call()) however this can cause
    # confusion on long run
    args = [{}, message]

    for item in @getBeforeHooks(message.typeName())
      item.hook.apply(item.hook, args)

    ###
    Order-wise, we need to fire domain rules after 'before' hooks - however
    before firing Meteor method with Meteor.call(). This is because
    method on server and on client will be processed simultaneously
    (if method mapping is present on client (like shared on client and
    server Space.messaging.Api subclass))
    ###
    for item in @getRuleHooks(message.typeName())
      item.hook.call(item.hook, message)

    Meteor.call message.typeName(), message, callback

    for item in @getAfterHooks(message.typeName())
      item.hook.apply(item.hook, args)

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

  _setupDeclarativeHandler: (handler, type) =>
    existingHandler = @_getHandlerFor type
    if existingHandler?
      @constructor._setupHandler type, handler
    else
      if @meteor.isClient
        @constructor.method type, handler
      else
        @constructor.method type, () =>
          for item in @getBeforeHooks(type)
            item.hook.apply(item.hook, arguments)
          # Omit here domain rules - do that on Space.messaging.CommandBus
          # so rules can be tested on project:domain packages
          handler.apply(@, arguments)

          for item in @getAfterHooks(type)
            item.hook.apply(item.hook, arguments)


  onDependenciesReady: ->
    @_setupDeclarativeMappings 'methods', @_setupDeclarativeHandler
    @_bindHandlersToInstance()

    @_setupBeforeHooks() if @beforeMap?
    @_setupAfterHooks() if @afterMap?
    @_setupMiddleware() if @middleware?

  _setupBeforeHooks: ->
    @_setupDeclarativeMappings('beforeMap', (hook, methodName) =>
      @addBeforeHook(methodName, @constructor, hook)
    )

  _setupAfterHooks: ->
    @_setupDeclarativeMappings('afterMap', (hook, methodName) =>
      @addAfterHook(methodName, @constructor, hook)
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

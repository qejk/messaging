
class Space.messaging extends Space.Module

  @publish this, 'Space.messaging'

  onInitialize: ->
    @injector.map('Space.messaging.EventBus').asSingleton()
    @injector.map('Space.messaging.CommandBus').asSingleton()
    @injector.map('Space.messaging.ApiHooks').asSingleton(
      Space.messaging.HookRegistry
    )
    @injector.map('Space.messaging.CommandBusHooks').toSingleton(
      Space.messaging.HookRegistry
    )
    @injector.map('Space.messaging.Api').asStaticValue()

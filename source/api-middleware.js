Space.Object.extend('Space.messaging.ApiMiddleware', {

  dependencies: {
    underscore: 'underscore',
    hooks: 'Space.messaging.ApiHooks'
  },

  Constructor(options) {
    var isGlobal = true;
    if (options && options.isGlobal !== undefined) {
      isGlobal = options.isGlobal;
    }
    this._isGlobal = isGlobal;
  },

  isGlobal() {
    return this._isGlobal;
  },

  /*
  This hooks will be applied to each method that is fired trough
  Space.messaging.Api.send()

  This is quite useful if we want to log every message, more uses cases
  will probably arise.

  When object is constructed with {isGlobal: false} - this just object holder
  for 'before', 'beforeMap', 'after', 'afterMap' hooks methods.
  */
  onDependenciesReady() {
    if (this.isGlobal() === false) {
      return;
    }
    if (this.before !== undefined) {
      this._setupGlobalBeforeHooks();
    }
    if (this.after !== undefined) {
      this._setupGlobalAfterHooks();
    }
  },

  _setupGlobalBeforeHooks() {
    this.hooks.addGlobalBeforeHook(this, this.before.bind(this));
  },

  _setupGlobalAfterHooks() {
    this.hooks.addGlobalAfterHook(this, this.after.bind(this));
  },

});
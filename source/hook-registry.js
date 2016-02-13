Space.Object.extend('Space.messaging.HookRegistry', {

  dependencies: {
    underscore: 'underscore'
  },

  Constructor() {
    this._hooks = {};
    this._globalHooks = [];
  },

  addMessageHook(messageType, callback) {
    if (this._hooks[messageType] === undefined) this._hooks[messageType] = [];

    return callback(this._hooks[messageType]);
  },

  addBeforeHook(messageType, mwareInstance, hook, registeredVia) {
    let hookObj = this._createHookObject(
      mwareInstance, 'before', hook, registeredVia
    );
    return this.addMessageHook(messageType, function(hooks) {
      hooks.push(hookObj);
    });
  },

  addBeforeHookAsFirst(messageType, mwareInstance, hook, registeredVia) {
    let hookObj = this._createHookObject(
      mwareInstance, 'before', hook, registeredVia
    );
    return this.addMessageHook(messageType, function(hooks) {
      hooks.unshift(hookObj);
    });
  },

  addAfterHook(messageType, mwareInstance, hook, registeredVia) {
    let hookObj = this._createHookObject(
      mwareInstance, 'after', hook, registeredVia
    );
    return this.addMessageHook(messageType, function(hooks) {
      hooks.push(hookObj);
    });
  },

  addAfterHookAsFirst(messageType, mwareInstance, hook, registeredVia) {
    let hookObj = this._createHookObject(
      mwareInstance, 'after', hook, registeredVia
    );
    return this.addMessageHook(messageType, function(hooks) {
      hooks.unshift(hookObj);
    });
  },

  addRuleHook(messageType, mwareInstance, hook) {
    let hookObj = this._createHookObject(mwareInstance, 'rule', hook);

    return this.addMessageHook(messageType, function(hooks) {
      hooks.push(hookObj);
    });
  },

  addGlobalHook(callback) {
    return callback(this._globalHooks);
  },

  addGlobalBeforeHook(mwareInstance, hook) {
    let hookObj = this._createHookObject(mwareInstance, 'before', hook);
    return this.addGlobalHook(function(hooks) {
      hooks.push(hookObj);
    });
  },

  addGlobalAfterHook(mwareInstance, hook) {
    let hookObj = this._createHookObject(mwareInstance, 'after', hook);
    return this.addGlobalHook(function(hooks) {
      hooks.push(hookObj);
    });
  },

  getHooks(messageType, hookType) {
    if (this._hooks[messageType] === undefined) return [];

    let hooks = [];
    this.underscore.each(this._hooks[messageType], function(hookObj){
      if (hookObj.type === hookType) {
        if (hookObj.type === 'rule') {
          hooks.push(function() {
            try {
              return hookObj.hook.apply(hookObj.middlewareInstance, arguments);
            } catch (error) {
              if (error instanceof Space.Error) {
                return hookObj.middlewareInstance.publish(
                  new Space.domain.Exception({
                    thrower: hookObj.middlewareInstance.toString(),
                    error: error
                  })
                );
              } else {
                throw error;
              }
            }
          });
        } else {
          hooks.push(hookObj.hook.bind(hookObj.middlewareInstance))
        }
      }
    });

    let hooksWithGlobal = this._applyGlobalHooksToHooksByType(hooks, hookType);
    return hooksWithGlobal;
  },

  _applyGlobalHooksToHooksByType(hooks, hookType) {
    this.underscore.each(this._globalHooks, function(hookObj){
      if (hookObj.type === hookType) {
        hooks.unshift(hookObj.hook.bind(hookObj.middlewareInstance))
      }
    });
    return hooks;
  },

  getBeforeHooks(messageType) {
    return this.getHooks(messageType, 'before');
  },

  getAfterHooks(messageType) {
    return this.getHooks(messageType, 'after');
  },

  getRuleHooks(messageType) {
    return this.getHooks(messageType, 'rule');
  },

  _createHookObject(mwareInstance, hookType, hook, registeredVia) {
    obj = {
      middlewareInstance: mwareInstance,
      hook: hook,
      type: hookType,
    };

    if (registeredVia !== undefined) {
      obj.registeredVia = registeredVia;
      obj.isGlobal = false;
    } else {
      obj.isGlobal = true;
    }
    return obj;
  }

});

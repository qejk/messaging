var _setImmediate = typeof setImmediate === 'function' && setImmediate;

var _delay = _setImmediate ? function(fn) {
    // not a direct alias for IE10 compatibility
    _setImmediate(fn);
} : function(fn) {
    setTimeout(fn, 0);
};

if (typeof process === 'object' && typeof process.nextTick === 'function') {
    nextTick = process.nextTick;
} else {
    nextTick = _delay;
}
setImmediate = _setImmediate ? _delay : nextTick;



function ensureAsync(fn) {
  return _restParam(function (args) {
    var callback = args.pop();
    args.push(function () {
      var innerArgs = arguments;
      if (sync) {
        setImmediate(function () {
          callback.apply(null, innerArgs);
        });
      } else {
        callback.apply(null, innerArgs);
      }
    });
    var sync = true;
    fn.apply(this, args);
    sync = false;
  });
}

function _once(fn) {
  return function() {
    if (fn === null) return;
    fn.apply(this, arguments);
    fn = null;
  };
}

// Similar to ES6's rest param (http://ariya.ofilabs.com/2013/03/es6-and-rest-parameter.html)
// This accumulates the arguments passed into an array, after a given index.
// From underscore.js (https://github.com/jashkenas/underscore/pull/2140).
function _restParam(func, startIndex) {
    startIndex = startIndex == null ? func.length - 1 : +startIndex;
    return function() {
        var length = Math.max(arguments.length - startIndex, 0);
        var rest = Array(length);
        for (var index = 0; index < length; index++) {
            rest[index] = arguments[index + startIndex];
        }
        switch (startIndex) {
            case 0: return func.call(this, rest);
            case 1: return func.call(this, arguments[0], rest);
        }
        // Currently unused but handle cases outside of the switch statement:
        // var args = Array(startIndex + 1);
        // for (index = 0; index < startIndex; index++) {
        //     args[index] = arguments[index];
        // }
        // args[startIndex] = rest;
        // return func.apply(this, args);
    };
}

iterator = function (tasks) {
  function makeCallback(index) {
    function fn() {
      if (tasks.length) {
        tasks[index].apply(null, arguments);
      }
      return fn.next();
    }
    fn.next = function () {
      return (index < tasks.length - 1) ? makeCallback(index + 1): null;
    };
    return fn;
  }
  return makeCallback(0);
};


Space.messaging.Hooks = {

  dependencies: {
    _hooks: 'Space.messaging.HookRegistry',
    underscore: 'underscore'
  },

  waterfall(tasks, callback) {
    callback = _once(callback || noop);
    if (!this.underscore.isArray(tasks)) {
      var err = new Error('First argument to waterfall must be an array of functions');
      return callback(err);
    }
    if (!tasks.length) {
      return callback();
    }
    function wrapIterator(iterator) {
      return _restParam(function (args) {
        var next = iterator.next();
        if (next) {
          args.push(wrapIterator(next));
        }
        else {
          args.push(callback);
        }
        ensureAsync(iterator).apply(null, args);
      });
    }
    wrapIterator(iterator(tasks))();
  },

  addBeforeHook(messageType, hookClass, hook) {
    return this._hooks.addBeforeHook(
      messageType, hookClass, hook, this
    );
  },

  addBeforeHookAsFirst(messageType, hookClass, hook) {
    return this._hooks.addBeforeHookAsFirst(
      messageType, hookClass, hook, this
    );
  },

  addAfterHook(messageType, hookClass, hook) {
    return this._hooks.addAfterHook(
      messageType, hookClass, hook, this
    );
  },

  addAfterHookAsFirst(messageType, hookClass, hook) {
    return this._hooks.addAfterHookAsFirst(
      messageType, hookClass, hook, this
    );
  },
  // TODO: Keep getter syntax or more natural expressive hooks(), beforeHooks(),
  // afterHooks(), ruleHooks()
  getHooks(messageType, hookType) {
    return this._hooks.getHooks(messageType, hookType);
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

}

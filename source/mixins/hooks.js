Space.messaging.Hooks = function(registryMapping) {
  return {
    dependencies: {
      hooks: registryMapping,
      underscore: 'underscore'
    },

    _waterfall(tasks, callback) {
      self = this;
      callback = _once(callback || noop);

      if (!this.underscore.isArray(tasks)) {
        throw new Error('First argument must be an array of functions');
      }
      if (!tasks.length) return callback();

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
      return this.hooks.addBeforeHook(
        messageType, hookClass, hook, this
      );
    },

    addBeforeHookAsFirst(messageType, hookClass, hook) {
      return this.hooks.addBeforeHookAsFirst(
        messageType, hookClass, hook, this
      );
    },

    addAfterHook(messageType, hookClass, hook) {
      return this.hooks.addAfterHook(
        messageType, hookClass, hook, this
      );
    },

    addAfterHookAsFirst(messageType, hookClass, hook) {
      return this.hooks.addAfterHookAsFirst(
        messageType, hookClass, hook, this
      );
    },
    // TODO: Keep getter syntax or more natural expressive hooks(), beforeHooks(),
    // afterHooks(), ruleHooks()
    getHooks(messageType, hookType) {
      return this.hooks.getHooks(messageType, hookType);
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
};
/*
From async.js: https://github.com/caolan/async
Copyright (c) 2010-2016 Caolan McMahon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 */

//// exported async module functions ////
//// nextTick implementation with browser-compatible fallback ////
// capture the global reference to guard against fakeTimer mocks
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

function _once(fn) {
  return function() {
    if (fn === null) return;
    fn.apply(this, arguments);
    fn = null;
  };
};

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
      case 0:
        return func.call(this, rest);
      case 1:
        return func.call(this, arguments[0], rest);
    }
  };
};

function ensureAsync(fn) {
  return _restParam(function(args) {
    var callback = args.pop();
    args.push(function() {
      var innerArgs = arguments;
      if (sync) {
        setImmediate(function() {
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

iterator = function(tasks) {
  function makeCallback(index) {
    function fn() {
      if (tasks.length) {
        tasks[index].apply(null, arguments);
      }
      return fn.next();
    }
    fn.next = function() {
      return (index < tasks.length - 1) ? makeCallback(index + 1) : null;
    };
    return fn;
  }
  return makeCallback(0);
};
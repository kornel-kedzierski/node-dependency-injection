// Generated by CoffeeScript 1.6.3
(function() {
  var Helpers;

  Helpers = (function() {
    function Helpers() {}

    Helpers.clone = function(obj) {
      var key, result, value, _i, _len, _ref, _ref1, _type;
      _type = Object.prototype.toString;
      switch (_type.call(obj)) {
        case '[object Array]':
          result = [];
          for (key = _i = 0, _len = obj.length; _i < _len; key = ++_i) {
            value = obj[key];
            if ((_ref = _type.call(value)) === '[object Array]' || _ref === '[object Object]') {
              result[key] = Helpers.clone(value);
            } else {
              result[key] = value;
            }
          }
          break;
        case '[object Object]':
          result = {};
          for (key in obj) {
            value = obj[key];
            if ((_ref1 = _type.call(value)) === '[object Array]' || _ref1 === '[object Object]') {
              result[key] = Helpers.clone(value);
            } else {
              result[key] = value;
            }
          }
          break;
        default:
          return obj;
      }
      return result;
    };

    Helpers.log = function(message) {
      if ((typeof console !== "undefined" && console !== null ? console.log : void 0) != null) {
        return console.log(message);
      }
    };

    Helpers.arrayIndexOf = function(array, search) {
      var element, i, _i, _len;
      if (typeof Array.prototype.indexOf !== 'undefined') {
        return array.indexOf(search);
      }
      if (array.length === 0) {
        return -1;
      }
      for (i = _i = 0, _len = array.length; _i < _len; i = ++_i) {
        element = array[i];
        if (element === search) {
          return i;
        }
      }
      return -1;
    };

    Helpers.createInstance = function(service, args, container) {
      var wrapper;
      if (args == null) {
        args = [];
      }
      wrapper = function(obj, args) {
        var f;
        if (args == null) {
          args = [];
        }
        f = function() {
          return obj.apply(this, args);
        };
        f.prototype = obj.prototype;
        return f;
      };
      return new (wrapper(service, Helpers.autowireArguments(service, args, container)));
    };

    Helpers.getArguments = function(method) {
      var args;
      method = method.toString();
      method = method.replace(/((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg, '');
      args = method.slice(method.indexOf('(') + 1, method.indexOf(')')).match(/([^\s,]+)/g);
      args = args === null ? [] : args;
      return args;
    };

    Helpers.autowireArguments = function(method, args, container) {
      var dots, factory, parameter, previousDots, result, service, _i, _len, _ref;
      if (args == null) {
        args = [];
      }
      result = [];
      factory = false;
      dots = false;
      previousDots = false;
      args = Helpers.clone(args);
      _ref = Helpers.getArguments(method);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        parameter = _ref[_i];
        if (typeof args[0] !== 'undefined' && args[0] === '...') {
          dots = true;
        }
        if (parameter.match(/Factory$/) !== null) {
          parameter = parameter.substring(0, parameter.length - 7);
          factory = true;
        }
        if (typeof args[0] === 'undefined' || dots || (container.hasDefinition(parameter) && previousDots)) {
          service = container.findDefinitionByName(parameter);
          if (service.autowired === false) {
            throw new Error("DI: Service '" + parameter + "' in not autowired.");
          }
          if (factory === true) {
            result.push(container.getFactory(parameter));
          } else {
            result.push(container.get(parameter));
          }
          if (dots) {
            args.shift();
          }
          previousDots = true;
        } else {
          if (args[0] !== null && typeof args[0] === 'string' && args[0].match(/^@/) !== null) {
            args[0] = args[0].substr(1);
            result.push(container.get(args[0]));
          } else {
            result.push(args[0]);
          }
          previousDots = false;
          args.shift();
        }
        factory = false;
        dots = false;
      }
      return result;
    };

    return Helpers;

  })();

  module.exports = Helpers;

}).call(this);
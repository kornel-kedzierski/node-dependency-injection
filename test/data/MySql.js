// Generated by CoffeeScript 1.7.1
(function() {
  var MySql;

  MySql = (function() {
    MySql.prototype.parameters = null;

    function MySql(parameters) {
      this.parameters = parameters;
    }

    MySql.create = function(parameters) {
      return new MySql(parameters);
    };

    return MySql;

  })();

  module.exports = MySql;

}).call(this);

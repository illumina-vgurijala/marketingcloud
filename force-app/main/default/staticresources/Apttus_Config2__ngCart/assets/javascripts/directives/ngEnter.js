(function() {
  var NGEnter, ngEnterLink;

  ngEnterLink = function(scope, elem, attrs) {
    return elem.on('keydown keypress', function(e) {
      if (e.which === 13) {
        scope.$apply(scope.$eval(attrs.ngEnter));
        return e.preventDefault();
      }
    });
  };

  NGEnter = function() {
    var directive;
    directive = {
      link: ngEnterLink
    };
    return directive;
  };

  angular.module('ngCPQ').directive('ngEnter', NGEnter);

}).call(this);

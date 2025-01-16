(function() {
  angular.module('ngCPQ').service('ApiUtils', [
    '$http', function($http) {
      this.getStaticJson = function(filename) {
        return $http.get("/staticapi/" + filename + ".json", {
          dataType: 'json',
          cache: true
        }).then(function(res) {
          return res;
        });
      };
      this.getStaticHTML = function(filename) {
        return $http.get("/staticapi/" + filename + ".html", {
          cache: true
        }).then(function(res) {
          return res.data;
        });
      };
      return this;
    }
  ]);

}).call(this);

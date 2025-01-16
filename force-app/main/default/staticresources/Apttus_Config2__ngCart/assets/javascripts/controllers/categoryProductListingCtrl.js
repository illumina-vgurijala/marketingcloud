(function() {
  var CategoryProductListingCtrl;

  CategoryProductListingCtrl = function(_, Category) {
    this.category = Category;
    return this;
  };

  CategoryProductListingCtrl.$inject = ['lodash', 'CategoryService'];

  angular.module('ngCPQ').controller('categoryProductListingCtrl', CategoryProductListingCtrl);

}).call(this);

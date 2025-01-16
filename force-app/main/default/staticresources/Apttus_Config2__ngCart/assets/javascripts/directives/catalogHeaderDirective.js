(function() {
  var CatalogHeader, catalogHeaderCtrl, catalogHeaderLink;

  catalogHeaderCtrl = function(CatalogService, ngCPQLabels) {
    return this.labels = ngCPQLabels.labels;
  };

  catalogHeaderCtrl.$inject = ['CatalogService', 'ngCPQLabels'];

  catalogHeaderLink = function(scope, elem, attr) {
    var catalog, header, scrollHandler;
    header = elem[0];
    catalog = document.querySelector('.main-product-block');
    scrollHandler = function(ev) {
      var catalogHeight, catalogTop, catalogWidth, fixedClass, headerHeight, opacity;
      fixedClass = '.is--header-fixed';
      catalogHeight = catalog.getBoundingClientRect().height;
      catalogTop = catalog.getBoundingClientRect().top;
      catalogWidth = catalog.getBoundingClientRect().width;
      headerHeight = header.getBoundingClientRect().height;
      if (catalog.getBoundingClientRect().top <= 0) {
        angular.element(header).css({
          'width': (catalogWidth - 1) + 'px'
        });
        angular.element(catalog).addClass('is--header-fixed');
        angular.element(catalog).css({
          'padding-top': headerHeight + 'px'
        });
        if (catalogHeight - Math.abs(catalogTop) <= headerHeight * 2) {
          angular.element(header).css({
            'top': catalogHeight - Math.abs(catalogTop) - headerHeight * 2 + 'px'
          });
          opacity = 1 - Math.abs(catalogHeight - Math.abs(catalogTop) - headerHeight * 2) / headerHeight;
          if (opacity >= 0) {
            return angular.element(header).css({
              'opacity': opacity * 2
            });
          }
        } else {
          angular.element(header).css({
            'top': '0'
          });
          return angular.element(header).css({
            'opacity': '1'
          });
        }
      } else {
        angular.element(catalog).removeClass('is--header-fixed');
        angular.element(catalog).css({
          'padding-top': '0'
        });
        return angular.element(header).css({
          'opacity': '1'
        });
      }
    };
    return window.addEventListener('scroll', scrollHandler);
  };

  CatalogHeader = function(baseUrl) {
    var directive;
    directive = {
      link: catalogHeaderLink,
      templateUrl: baseUrl + '/templates/directives/catalog-header.html',
      controller: catalogHeaderCtrl,
      controllerAs: 'catalogHeader',
      bindToController: true
    };
    return directive;
  };

  CatalogHeader.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('catalogHeader', CatalogHeader);

}).call(this);

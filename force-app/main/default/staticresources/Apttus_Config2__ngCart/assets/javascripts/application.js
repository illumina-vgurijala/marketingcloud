
/* global angular */

(function() {
  'use strict';
  angular.module('ngCPQ', ['ui.router', 'angularUtils.directives.dirPagination', 'angular.filter', 'ngLodash', 'ng-sortable', 'pikaday']).constant('moment', moment).config([
    '$urlRouterProvider', '$stateProvider', '$locationProvider', 'baseUrl', 'paginationTemplateProvider', 'pikadayConfigProvider', function($urlRouterProvider, $stateProvider, $locationProvider, baseUrl, paginationTemplateProvider, pikaday) {
      pikaday.setConfig({
        format: 'MM/DD/YYYY'
      });
      paginationTemplateProvider.setPath(baseUrl + '/templates/layouts/pagination.html');
      $urlRouterProvider.otherwise('/catalog');
      return $stateProvider.state('catalog', {
        url: '/catalog',
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@catalog': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'miniCart@catalog': {
            templateUrl: baseUrl + '/templates/blocks/block-mini-cart.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-steps.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-left-col.html'
          },
          'sidebarLeft@catalog': {
            templateUrl: baseUrl + '/templates/layouts/sidebar-catalog.html'
          },
          'mainContent@catalog': {
            templateUrl: baseUrl + '/templates/blocks/main-product-catalog.html',
            controller: 'catalogCtrl',
            controllerAs: 'catalog'
          }
        }
      }).state('category', {
        url: '/category/{catID}?compare',
        resolve: {
          initCategoryService: [
            '$stateParams', 'CategoryService', function($stateParams, CategoryService) {
              return CategoryService.setCurrentCategory($stateParams.catID);
            }
          ]
        },
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@category': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'miniCart@category': {
            templateUrl: baseUrl + '/templates/blocks/block-mini-cart.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-steps.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-left-col.html'
          },
          'sidebarLeft@category': {
            templateUrl: baseUrl + '/templates/layouts/sidebar-products.html'
          },
          'mainContent@category': {
            templateUrl: baseUrl + '/templates/blocks/main-product-listings.html',
            controller: 'categoryProductListingCtrl',
            controllerAs: 'productList'
          }
        }
      }).state('search', {
        url: '/search/{term}?category',
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@search': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'miniCart@search': {
            templateUrl: baseUrl + '/templates/blocks/block-mini-cart.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-search.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-left-col.html',
            controller: 'searchProductListingCtrl',
            controllerAs: 'search'
          },
          'sidebarLeft@search': {
            templateUrl: baseUrl + '/templates/layouts/sidebar-search.html'
          },
          'mainContent@search': {
            templateUrl: baseUrl + '/templates/blocks/main-search-listings.html'
          }
        }
      }).state('cart', {
        url: '/cart',
        params: {
          view: 'detail'
        },
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@cart': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-steps.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-single-col.html'
          },
          'layoutSingle@cart': {
            templateUrl: baseUrl + '/templates/blocks/main-cart-table.html'
          }
        }
      }).state('configure', {
        resolve: {
          initConfigureService: [
            '$stateParams', 'ConfigureService', function($stateParams, Configure) {
              return Configure.setLineitemToConfigure($stateParams.txnPrimaryLineNumber);
            }
          ]
        },
        url: '/configure/{txnPrimaryLineNumber}?step',
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@configure': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'miniCart@configure': {
            templateUrl: baseUrl + '/templates/blocks/block-mini-cart.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-steps.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-right-col.html'
          },
          'sidebarRight@configure': {
            templateUrl: baseUrl + '/templates/layouts/sidebar-configure.html'
          },
          'mainContent@configure': {
            templateUrl: baseUrl + '/templates/blocks/main-configure-product.html'
          }
        }
      }).state('assets', {
        url: '/assets',
        views: {
          'globalHeader@': {
            templateUrl: baseUrl + '/templates/blocks/header-global.html'
          },
          'proposalSelector@cart': {
            templateUrl: baseUrl + '/templates/blocks/block-proposal-sel.html'
          },
          'processTrail@': {
            templateUrl: baseUrl + '/templates/blocks/process-steps.html'
          },
          'systemNotification@': {
            templateUrl: baseUrl + '/templates/blocks/system-notification.html'
          },
          'displayActions@': {
            templateUrl: baseUrl + '/templates/blocks/display-actions.html'
          },
          'layout@': {
            templateUrl: baseUrl + '/templates/layouts/layout-left-col.html'
          },
          'sidebarLeft@assets': {
            templateUrl: baseUrl + '/templates/layouts/sidebar-assets.html'
          },
          'mainContent@assets': {
            templateUrl: baseUrl + '/templates/blocks/main-assets-table.html',
          }
        }
      });
    }
  ]);

}).call(this);

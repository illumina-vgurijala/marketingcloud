(function() {
  var FilterSearchResults, filterSearchResultsCtrl;

  filterSearchResultsCtrl = function(CatalogService, $state, $stateParams, $q, $rootScope) {
    var _getAllNodeIds, searchCategory, searchedTerm, self;
    searchedTerm = $stateParams.term;
    searchCategory = $stateParams.category;
    self = this;
    self.checkChildrenForResults = function(childCats) {
      var cat, ref, remaining;
      if (!(childCats != null ? (ref = childCats.childCategories) != null ? ref.length : void 0 : void 0)) {
        return false;
      }
      cat = childCats.childCategories[0];
      remaining = childCats.childCategories.slice(1);
      if (self.isSearchResult(cat.nodeId)) {
        return true;
      } else if (remaining.length > 0) {
        return self.checkChildrenForResults(remaining);
      } else {
        return false;
      }
    };
    _getAllNodeIds = function(lineage) {
      var leaves;
      leaves = lineage.map(function(elem) {
        return elem.nodeId;
      }, lineage);
      return leaves;
    };
    self.isSearchResult = function(nodeId) {
      return self.searchResultCategoryIds.indexOf(nodeId) > -1;
    };
    self.isExpanded = function(nodeId) {
      if (self.openLeaves) {
        return self.openLeaves.indexOf(nodeId) > -1;
      } else {
        return false;
      }
    };
    self.viewAll = searchCategory;
    self.term = $stateParams.term;
    return CatalogService.getProductFilters().then((function(_this) {
      return function(filters) {
        var filter, filterParam, i, j, k, len, len1, len2, ref, selected, selectedFilters, value;
        if ($stateParams.filterBy) {
          filterParam = $stateParams.filterBy.split(',');
          selectedFilters = _.collect(filterParam, function(entry) {
            return decodeURIComponent(entry);
          });
          for (i = 0, len = filters.length; i < len; i++) {
            filter = filters[i];
            ref = filter.filterFieldValues;
            for (j = 0, len1 = ref.length; j < len1; j++) {
              value = ref[j];
              for (k = 0, len2 = selectedFilters.length; k < len2; k++) {
                selected = selectedFilters[k];
                if (value.value === selected) {
                  value.isSelected = true;
                }
              }
            }
          }
          self.filters = filters;
        }
        return $q.all([CatalogService.getCategories(), CatalogService.searchProducts(null, searchedTerm, self.filters)]).then(function(res) {
          self.categories = res[0];
          self.products = res[1].products;
          self.resultCategoryIds = res[1].resultCategoryIds;
          self.allFoundProductCount = res[1].products.length;
          return CatalogService.getCategoryIdsForLeaves(self.resultCategoryIds).then(function(res) {
            var categoryLineage;
            self.topLevelCats = res.ancestorIds;
            self.resultCategories = res.resultCategories;
            self.searchResultCategoryIds = Object.keys(self.resultCategories);
            if (searchCategory) {
              categoryLineage = CatalogService.getAncestors(searchCategory, self.categories);
              self.openLeaves = _getAllNodeIds(categoryLineage);
            }
            if (searchCategory && categoryLineage.length > 0) {
              return self.categoryTree = categoryLineage;
            } else {
              return self.categoryTree = self.categories;
            }
          });
        });
      };
    })(this));
  };

  filterSearchResultsCtrl.$inject = ['CatalogService', '$state', '$stateParams', '$q', '$rootScope'];

  FilterSearchResults = function(baseUrl) {
    var directive;
    directive = {
      templateUrl: baseUrl + '/templates/directives/filter-search-block.html',
      controller: filterSearchResultsCtrl,
      controllerAs: 'searchedTerm',
      bindToController: true
    };
    return directive;
  };

  FilterSearchResults.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('filterSearchResults', FilterSearchResults);

}).call(this);

(function() {
  var hasProp = {}.hasOwnProperty;

  angular.module('ngCPQ').service('CatalogService', [
    '$http', '$q', 'CategoryDataService','CatalogDataService', 'ProductDataService', 'SFCache', 'messenger', 'ApiUtils',
    function($http, $q, CategoryData, CatalogDataService, ProductData, SFCache, Messenger, ApiUtils) {
      return CatalogDataService;
      var cache, _categoryFromTree, _getResultObjects, _getRuleMessage, _sortTreeLeaves;
      cache = SFCache;
      this.getCategories = function() {
        return CategoryData.getCategories();
      };
      this.getBreadcrumb = function(parentId) {
        return this.getCategories().then((function(_this) {
          return function(results) {
            return _this.getAncestors(parentId, results);
          };
        })(this));
      };
      this.sortProducts = function(filters) {
        var deferred, sorted;
        deferred = $q.defer();
        if (sorted = cache.get('sortedProducts')) {
          deferred.resolve(sorted);
        } else {
          ProductData.searchProducts(null, null, filters).then(function(res) {
            var k, product, sortedProducts;
            sortedProducts = [];
            for (k in res) {
              if (!hasProp.call(res, k)) continue;
              product = res[k];
              if (sortedProducts[product.productSO.Family]) {
                sortedProducts[product.productSO.Family].push(product);
              } else {
                sortedProducts[product.productSO.Family] = [];
                sortedProducts[product.productSO.Family].push(product);
              }
            }
            cache.put('sortedProducts', sortedProducts);
            return deferred.resolve(sortedProducts);
          });
        }
        return deferred.promise;
      };
      this.getProductsForCategory = function(category, filters) {
        var _productsFromFamily, currentProducts;
        currentProducts = [];
        _productsFromFamily = function(productGroup, category) {
          var i, k, len, product, ref, ref1, subcat;
          if (productGroup[category.label]) {
            ref = productGroup[category.label];
            for (i = 0, len = ref.length; i < len; i++) {
              product = ref[i];
              currentProducts.push(product);
            }
          }
          if (category.childCategories) {
            ref1 = category.childCategories;
            for (k in ref1) {
              if (!hasProp.call(ref1, k)) continue;
              subcat = ref1[k];
              _productsFromFamily(productGroup, subcat);
            }
          }
          return currentProducts;
        };
        return this.sortProducts(filters).then(function(sortedProducts) {
          return _productsFromFamily(sortedProducts, category);
        });
      };
      this.getCatById = function(nodeId) {
        return this.getCategories().then(function(categories) {
          var currentCat;
          return currentCat = _categoryFromTree(nodeId, categories);
        });
      };
      this.getAncestors = function(nodeId, categoryTree) {
        var _loopTreeForCats, breadcrumbTrail, matches, topLevelCat;
        breadcrumbTrail = [];
        topLevelCat = categoryTree;
        matches = [];
        _loopTreeForCats = function(parentNodeId, categories) {
          var category, i, j, len, len1, ref, subcat;
          for (i = 0, len = categories.length; i < len; i++) {
            category = categories[i];
            if (category.nodeId === parentNodeId && matches.indexOf(category.label) < 0) {
              breadcrumbTrail.unshift(category);
              matches.push(category.label);
              if (category.nodeLevel > 0) {
                _loopTreeForCats(category.parentId, topLevelCat);
              }
            }
            if (category.childCategories) {
              ref = category.childCategories;
              for (j = 0, len1 = ref.length; j < len1; j++) {
                subcat = ref[j];
                _loopTreeForCats(parentNodeId, category.childCategories);
              }
            }
          }
          return breadcrumbTrail;
        };
        _loopTreeForCats(nodeId, topLevelCat);
        return breadcrumbTrail;
      };
      this.getCategoryIdsForLeaves = function(ids) {
        var ancestorIds, deferred, resultCategories, sampleResponse;
        deferred = $q.defer();
        resultCategories = {
          "a0Ei0000001hwDWEAY": true,
          "a0Ei0000001hwDREAY": true,
          "a0Ei0000001hwDYEAY": true,
          "a0Ei0000001hwDHEAY": true,
          "a0Ei0000001hwDBEAY": true,
          "a0Ei0000001hwDXEAY": true
        };
        ancestorIds = {
          "a0Ei0000001hwDREAY": true,
          "a0Ei0000001hwDYEAY": true
        };
        sampleResponse = {
          resultCategories: resultCategories,
          ancestorIds: ancestorIds,
          ancestorIds: ancestorIds
        };
        deferred.resolve(sampleResponse);
        return deferred.promise;
      };
      this.getCategoryTreeForLeaves = function(leafIds, products) {
        var deferred;
        deferred = $q.defer();
        this.getCategories().then(function(categories) {
          var treeLeaves;
          treeLeaves = leafIds.map(function(currentValue, index, currArray) {
            var category;
            category = _categoryFromTree(currentValue, categories);
            return category;
          }, categories, products);
          return deferred.resolve(treeLeaves);
        });
        return deferred.promise;
      };
      _getRuleMessage = function() {
        return ApiUtils.getStaticJson('rule_message').then(function(res) {
          return res.data.ruleActions;
        });
      };
      _getResultObjects = function(catIds) {
        var category, remaining, results;
        this.catObjs = [];
        category = this.getCatById(catIds[0]);
        remaining = catIds.slice(1);
        this.catObjs.push(category);
        if (remaining.length > 0) {
          return _getResultObjects(remaining);
        } else {
          results = this.catObjs;
          this.catObjs = [];
          return results;
        }
      };
      _sortTreeLeaves = function(treeLeaves) {
        var leaf, remainingLeaves, sortedLeaves;
        leaf = treeLeaves[0];
        remainingLeaves = treeLeaves.slice(1);
        this.groupedByRoot = this.groupedByRoot || [];
        this.grouped = this.grouped || [];
        if (!this.groupedByRoot[leaf.rootId]) {
          this.groupedByRoot[leaf.rootId] = [];
        }
        this.groupedByRoot[leaf.rootId].push(leaf);
        if (remainingLeaves.length > 0) {
          return _sortTreeLeaves(remainingLeaves);
        } else {
          sortedLeaves = this.groupedByRoot;
          this.groupedByRoot = [];
          return sortedLeaves;
        }
      };
      _categoryFromTree = function(nodeId, categories) {
        var category, childCategory, i, len;
        for (i = 0, len = categories.length; i < len; i++) {
          category = categories[i];
          if (category.nodeId === nodeId) {
            return category;
          }
          if ((category.childCategories != null) && ((childCategory = _categoryFromTree(nodeId, category.childCategories)) != null)) {
            return childCategory;
          }
        }
      };
      return this;
    }
  ]);

}).call(this);

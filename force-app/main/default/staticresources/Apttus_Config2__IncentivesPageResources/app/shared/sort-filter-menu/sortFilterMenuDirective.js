;(function() {
    var _views = {
        sorting: 1,
        filtering: 2
    };

    var defaultSettings = {
        show: false,
        view: _views.filtering,
        uniqueValues: [],
        allValuesSelected: true,
        appliedAllSelection: true,
        sorting: {
            ascending: null,
            columnName: ""
        },
        onFilterChange: function() {},
        onSelectSort: function() {}
    };

    var applySelection = function(uniqueValues) {
        for(var i = 0; i < uniqueValues.length; i++) {
            uniqueValues[i].appliedSelection = uniqueValues[i].selected;
        }
    }

    var setAll = function(uniqueValues, selected) {
        // default all values to selected
        for(var i = 0; i < uniqueValues.length; i++) {
            uniqueValues[i].selected = selected;
        }
    };

    var allItemsSelectionStatus = function(uniqueValues, selection) {
        var allMatchSelection = true;

        // default all values to selected
        for(var i = 0; i < uniqueValues.length; i++) {
            if(uniqueValues[i].selected !== selection) {
                allMatchSelection = false;
                break;
            }
        }

        return allMatchSelection;
    };

    var _isFilteringApplied = function(settings) {
        return !(!settings.uniqueValues || settings.allValuesSelected);
    }

    angular.module('sharedWidgetsApp').directive('sortFilterMenu', sortFilterMenuDirective);

    sortFilterMenuDirective.$inject = ['appConfig','resourceUrls', '$window'];

    function sortFilterMenuDirective(appConfig, resourceUrls, $window) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                onFilterChange: '&',
                onSelectSort: '&'
            },
            templateUrl: resourceUrls.templateBase + '/sort-filter-menu/sortFilterMenuView.html',
            replace: true,
            controller: function($scope) { },
            compile: sortFilterMenuCompileFunc
        };

        function sortFilterMenuCompileFunc() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);

                    scope.views = _views;
                    scope.labels = appConfig.labels;

                    // default all values to selected
                    setAll(scope.settings.uniqueValues, true);

                    scope.showView = function(selectedView) {
                        scope.settings.view = selectedView;
                    };

                    scope.toggleSelectAll = function () {
                        scope.settings.allValuesSelected = !scope.settings.allValuesSelected;
                        // set all values to current selection in "Select All" checkbox
                        setAll(scope.settings.uniqueValues, scope.settings.allValuesSelected);
                    };

                    scope.toggleFilterValue = function(filterItem) {
                        // reverse selection
                        filterItem.selected = !filterItem.selected;

                        // update all selection checkbox to reflect current status of selected values in list
                        if(!filterItem.selected && scope.settings.allValuesSelected) {
                            scope.settings.allValuesSelected = false;
                        } else if(allItemsSelectionStatus(scope.settings.uniqueValues, true)) { // all values are selected
                            scope.settings.allValuesSelected = true;
                        }
                    };

                    scope.onApplyFilterEvent = function() {
                        // determine if filters applied
                        scope.settings.filteringApplied = _isFilteringApplied(scope.settings);

                        // apply selections
                        applySelection(scope.settings.uniqueValues);
                        scope.settings.appliedAllSelection = scope.settings.allValuesSelected;

                        scope.onFilterChange();
                        scope.settings.show = false;
                    };

                    scope.onClearFilterEvent = function() {
                        // determine if filters applied
                        scope.settings.filteringApplied = _isFilteringApplied(scope.settings);

                        // reset all selections if filtering is applied
                        if(scope.settings.filteringApplied) {
                            scope.settings.allValuesSelected = true;

                            // set all values to current selection in "Select All" checkbox
                            setAll(scope.settings.uniqueValues, scope.settings.allValuesSelected);
                        }

                        // apply selections
                        applySelection(scope.settings.uniqueValues);
                        scope.settings.appliedAllSelection = scope.settings.allValuesSelected;

                        scope.settings.filteringApplied = false;

                        scope.settings.show = false;

                        scope.onFilterChange();

                    };

                    scope.onSortClick = function() {
                        scope.onSelectSort();
                    };
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();
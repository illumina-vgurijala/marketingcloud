;(function() {
    var _views = {
        available: "available",
        selected: "selected"
    };

    var defaultSettings = {
        show: false,
        enableFiltering: true,
        isSingleSelect: false,
        selectedItemsOnlyView: false,
        singleSelectItem: null,
        currentPage: 1,
        isModal: true,
        pageSize: 25,
        columns: [],
        query: {},
        selectedValues: [],
        selectedRecords: [],
        cancelled: false,
        headerTitle: "Advanced Search",
        view: _views.available,
        useServerSideQuery: false,
        searchMethod: function(){},
        sort: null
    };

    // get scrollbar width
    var _rowHeight;

    var _updateSelectedList = function(results,
            selectedRecordList, 
            value, 
            selected, 
            dataKeyColumn) {

        var recordIndex;

        // get location of record in selected list
        recordIndex = Apttus.utils.elementIndex(selectedRecordList, value, dataKeyColumn);

        // reapply state of selected results
        if(recordIndex > -1 && !selected) { // exists in array and is not selected
            // remove from array of selected
            selectedRecordList.splice(recordIndex, 1);
            let index = Apttus.utils.elementIndex(results, value, dataKeyColumn);
            if(index > -1) {
                results[index].selected = false;
            }
        } else if(recordIndex === -1 && selected) { // does not exist and is selected
            // get index of record in results list
            recordIndex = Apttus.utils.elementIndex(results, value, dataKeyColumn);

            // add to selected list
            selectedRecordList.push(results[recordIndex]);
        }
    };

    var _getSortExpression = function(sort) {
        if(sort === undefined){
            return null;
        }

        return (sort.ascending ? '+' : '-' ) + sort.columnName;
    };

    var _valuePassesFiltering = function(value, filters) {
        if(!filters.uniqueValues || filters.appliedAllSelection) return true;

        for(var i = 0; i < filters.uniqueValues.length; i++) {
            if(filters.uniqueValues[i].appliedSelection
                && filters.uniqueValues[i].value === value) {
                return true;
            }
        }

        return false;
    };

    angular.module('sharedWidgetsApp').directive('advancedSearch', advancedSearchDir);

    advancedSearchDir.$inject = ['appConfig','resourceUrls', '$window', 'lodash'];

    function advancedSearchDir(appConfig, resourceUrls, $window, _) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                isModal: '=',
                uniqueId: '@',
                search: '&',
                onAdvancedSearchClose: '&',
                views: '='
            },
            templateUrl: resourceUrls.templateBase + '/advanced-search/advancedSearchView.html',
            controller: function($scope) { },
            compile: advancedSearchCompileFunc
        };

        function advancedSearchCompileFunc() {
                return {
                    pre: function(scope, el, attrs) {
                        scope.settings = angular.merge({}, defaultSettings, scope.settings);

                        if(scope.settings.sort !== null) {
                            scope.settings.sortExpression = _getSortExpression(scope.settings.sort);
                        }

                        if(scope.settings.selectedItemsOnlyView && scope.settings.selectedRecords) {
                            scope.settings.results = scope.settings.selectedRecords;
                        }

                        if(scope.settings.isSingleSelect) {
                            if(scope.settings.singleSelectItem !== null) {
                                // single selected item already set by user, simply use this as the selected item
                                scope.settings.singleSelectItem = scope.settings.singleSelectItem;
                                scope.settings.singleSelectItemValue = scope.settings.singleSelectItem[scope.settings.dataKeyColumn];
                            } else {
                                // iterate over selected records and set selected item
                                for(var i = 0; i < scope.settings.selectedRecords.length; i++) {
                                    if(scope.settings.selectedRecords[i].selected) {
                                        scope.settings.singleSelectItem = scope.settings.selectedRecords[i];
                                        scope.settings.singleSelectItemValue = scope.settings.selectedRecords[i][scope.settings.dataKeyColumn];
                                    }
                                }
                            }
                        }

                        scope.views = _views;
                        scope.recordSelectionChanged = false;
                        scope.allSelected = false;

                        if(scope.settings.results !== undefined) {
                            scope.filtered = scope.settings.results;
                        }

                        if(scope.settings === undefined  || scope.settings === null) {
                            console.error("advanced-search directive 'settings' attribute not set.");
                            return;
                        }

                        scope.toggleSeletedRow = function(value, isSelected) {
                            if(scope.settings.isSingleSelect) {
                                scope.settings.selectedRecords = [value];
                                scope.settings.singleSelectItem = value;
                                scope.settings.singleSelectItemValue = value[scope.settings.dataKeyColumn];
                            } else {
                                _updateSelectedList(scope.settings.results,
                                    scope.settings.selectedRecords,
                                    value,
                                    isSelected,
                                    scope.settings.dataKeyColumn);
                            }

                            scope.recordSelectionChanged = true;
                        };

                        scope.closeAdvancedSearch = function() {
                            scope.settings.cancelled = true;
                            scope.settings.show = !scope.settings.show;
                            scope.onAdvancedSearchClose();
                        };

                        scope.selectItems = function() {
                            if (scope.recordSelectionChanged) { // has selected values?
                                scope.settings.cancelled = false; // signify was not cancelled
                                scope.settings.show = !scope.settings.show;
                                scope.onAdvancedSearchClose();
                            }
                        };

                        scope.selectAll = function(begin, end, allSelected) {
                            for(var i = begin - 1; i < end; i++) {
                                var currentRecord = scope.filtered[i];
                                currentRecord.selected = allSelected;

                                // may need to manually trigger update to selected records list
                                scope.toggleSeletedRow(currentRecord[scope.settings.dataKeyColumn], allSelected)
                            }
                        };

                        scope.beginRecordNumber = function() {
                            return ((scope.settings.currentPage * scope.settings.pageSize) - (scope.settings.pageSize - 1));
                        };

                        scope.endRecordNumber = function() {
                            if (scope.filtered) {
                                var recordsLength = scope.filtered.length;
                                return (scope.settings.currentPage * scope.settings.pageSize > recordsLength ?
                                    recordsLength :
                                    scope.settings.currentPage * scope.settings.pageSize);
                            }
                            return 0;
                        };

                        scope.labels = appConfig.labels;

                        scope.pageChangeHandler = function(num) {
                            // reset all check box to unchecked when page changed
                            scope.allSelected = false;
                        };

                        scope.resultsFilter = function (item) {
                            if(scope.settings.selectedItemsOnlyView) return true;

                            if(scope.settings.isSingleSelect
                                && scope.settings.view == scope.views.selected) return false;

                            var matched = false,
                                    passedFilters = true,
                                    performFiltering = (scope.settings.view != scope.views.selected && scope.settings.enableFiltering),
                                    hasSearchTerm = !Apttus.utils.isNullOrEmpty(scope.settings.query.searchTerm);

                            if(performFiltering) {
                                // compare search value to each column
                                for(var i = 0; i < scope.settings.columns.length; i++) {
                                    // get string representation of the value
                                    var currentCol = scope.settings.columns[i];

                                    if (currentCol.sortAndFilterSettings && !_valuePassesFiltering(item[currentCol.name], currentCol.sortAndFilterSettings)) {
                                        passedFilters = false;
                                        break;
                                    }
                                }
                            }

                            if(passedFilters || !performFiltering) {
                                // compare search value to each column
                                for(var i = 0; i < scope.settings.columns.length; i++) {
                                    // get string representation of the value
                                    var currentCol = scope.settings.columns[i];
                                    var currentVal = String(item[currentCol.name]);

                                    if((hasSearchTerm && currentVal.toLowerCase().indexOf(scope.settings.query.searchTerm.toLowerCase()) > -1 ||
                                        !hasSearchTerm)) {

                                        matched = true;
                                        break;
                                    }
                                }
                            }

                            if(scope.settings.view === _views.selected) {
                                // check if exists in selected records array
                                var index = _.findIndex(scope.settings.selectedRecords, function(selectedRecord) {
                                    return selectedRecord[scope.settings.dataKeyColumn] === item[scope.settings.dataKeyColumn];
                                });
                                return (matched && index > -1);
                            } else {
                                return matched;
                            }

                        };

                        // filtering and sorting menu callback handlers
                        scope.onFilterChangeHandler = function(col) { };

                        scope.onSearchTextChange = function() {
                            if(scope.settings.useServerSideQuery) {
                                scope.settings.searchMethod(scope.settings.query);
                            }
                        };

                        scope.selectSortHandler = function(col) {
                            scope.settings.sort.columnName = col.sortAndFilterSettings.sorting.columnName;
                            scope.settings.sort.ascending = col.sortAndFilterSettings.sorting.ascending;

                            // clear sorting on other columns
                            for(var i = 0; i < scope.settings.columns.length; i++) {
                                var currentCol = scope.settings.columns[i];

                                if(currentCol.isVisible
                                    && currentCol.sortAndFilterSettings
                                    && currentCol.name !== col.sortAndFilterSettings.sorting.columnName) {
                                    // clear sorting for every other column
                                    currentCol.sortAndFilterSettings.sorting.ascending = null;
                                }
                            }

                            scope.settings.sortExpression = _getSortExpression(col.sortAndFilterSettings.sorting);
                        };

                        scope.switchView = function(view) {
                            scope.allSelected = false;
                            scope.settings.currentPage = 1;
                            scope.settings.view = view;
                            if (view === _views.selected && !Apttus.utils.isNullOrEmpty(scope.settings.query.searchTerm)) {
                                // Clear search text when selected tab is clicked
                                scope.settings.query.searchTerm = '';
                                scope.onSearchTextChange();
                            }
                            
                        };

                        scope.onClickColumnHeader = function(column) {
                            if(scope.settings.isSingleSelect && scope.settings.view == _views.selected) {
                                return;
                            }

                            if(column.sortAndFilterSettings && scope.settings.view != _views.selected) {
                                column.sortAndFilterSettings.show = !column.sortAndFilterSettings.show;

                                for(var i = 0; i < scope.settings.columns.length; i++) {
                                    var currentCol = scope.settings.columns[i];

                                    // for any other column where filter settings are specified
                                    // make sure and hide the sort/filter menu
                                    if(currentCol.isVisible
                                        && currentCol.sortAndFilterSettings
                                        && currentCol.name !== column.name) {
                                        // hide sorting and filtering menu
                                        currentCol.sortAndFilterSettings.show = false;
                                    }
                                }
                            } else {
                                if(scope.settings.sort.columnName === column.name){
                                // if column already sorted then flip sort order
                                scope.settings.sort.ascending = !scope.settings.sort.ascending;
                            } else {
                                scope.settings.sort.ascending = true;
                            }

                                scope.settings.sort.columnName = column.name;

                            scope.settings.sortExpression = _getSortExpression(scope.settings.sort);
                            }

                        };

                        scope.$watch('settings.show', function(value) {
                            scope.recordSelectionChanged = false;

                            if(value) {
                                if(scope.settings.results !== undefined) {
                                    scope.filtered = scope.settings.results;
                                }

                                if(scope.settings.enableFiltering && !scope.settings.selectedItemsOnlyView) {
                                    // setup filter menu
                                    for(var i = 0; i < scope.settings.columns.length; i++) {
                                        var currentCol = scope.settings.columns[i];

                                        if(currentCol.isVisible &&
                                            !currentCol.sortAndFilterSettings) {

                                            currentCol.sortAndFilterSettings = {
                                                sorting: {
                                                    ascending: (scope.settings.sort != null 
                                                                && scope.settings.sort.columnName === currentCol.name ? 
                                                                    scope.settings.sort.ascending : 
                                                                    null),
                                                    columnName: currentCol.name
                                                }
                                            };

                                        }

                                        if(currentCol.isVisible &&
                                            (currentCol.sortAndFilterSettings.uniqueValues === undefined
                                            ||  currentCol.sortAndFilterSettings.uniqueValues.length == 0)) {
                                            if(scope.settings.results) {
                                                var tempUniqueValuesArray = [],
                                                    uniqueValuesArray = [];

                                                // create list of unique filter values
                                                tempUniqueValuesArray = Apttus.utils.getUniqueValueArray( scope.settings.results, currentCol.name);

                                                for(var c = 0; c < tempUniqueValuesArray.length; c++) {
                                                    uniqueValuesArray.push({
                                                        value: tempUniqueValuesArray[c],
                                                        selected: true
                                                    });
                                                }

                                                currentCol.sortAndFilterSettings.uniqueValues = uniqueValuesArray;
                                            }
                                        }
                                    }
                                }
                            }

                        });

                        scope.isLongTextColumn = function (dataType) {
                            return (dataType === 'textarea');
                        };

                        scope.longTextHoverOver = function($event) {
                            var $this=angular.element($event.currentTarget);

                            $this.css({"height" : ""});
                            $this.css("white-space", "normal");
                        };

                        scope.longTextHoverLeave = function($event) {
                            var $this=angular.element($event.currentTarget);

                            $this.height(_rowHeight);
                            $this.css("white-space", "nowrap");
                        };
                    },
                    post: function(scope, el) {
                    }
                };
            }
    }


})();
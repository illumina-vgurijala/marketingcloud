/**
 * Created by Ian on 7/26/2015.
 */
/*
 *  Project: Incentives
 *  Description: allows for auto complete search as well as multi pick feature
 *  allowing the user to choose multiple options at a time.
 *  Dependencies: jQuery, jQuery-UI  
 *  Author: Ian Gallagher - Apttus
 *  License:
 */

// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ( $, window, document, undefined ) {

    // undefined is used here as the undefined global variable in ECMAScript 3 is
    // mutable (ie. it can be changed by someone else). undefined isn't really being
    // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
    // can no longer be modified.

    // window is passed through as local variable rather than global
    // as this (slightly) quickens the resolution process and can be more efficiently
    // minified (especially when both are regularly referenced in your plugin).
    // Create the defaults once
    var pluginName = 'multipickSearch',
        defaults = {},
        constants = {
            itemDataAttributeName: "item"
        };

    // The actual plugin constructor
    function multipickSearch( element, options ) {
        this.element = element;

        // jQuery has an extend method which merges the contents of two or
        // more objects, storing the result in the first object. The first object
        // is generally empty as we don't want to alter the default options for
        // future instances of the plugin

        this.options = $.extend({
            data: [],
            onDelete: function (item) {},
            onItemSelected: function (settings, item) {},
            onCancel: function (settings) {},
            multipick: true,
            selectionCountLimit: undefined,
            propNameLabel: "label",
            propNameValue: "value",
            disallowDuplicate: true,
            defaultResults: null,
            cssClassMultipickSearch: "multi-select-widget",
            // built-in simple search algorithm in the case of hard coded array of data set in "data" property
            resultsSearch: function (searchTerm, fieldOptions) {
                var fieldOptionsTemp = [];

                for (i = 0; i < fieldOptions.length; i++) {
                    var fieldOption = fieldOptions[i].label.toLowerCase();

                    if (fieldOption.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1) {
                        fieldOptionsTemp.push(fieldOptions[i]);
                    }
                }

                return fieldOptionsTemp;
            },
            lblResultsItemsTitle:"Available Items",
            lblSelectedItemsTitle:"Selected Items",
            lblClose:"Close",
            lblNoResults:"No Results Available",
            lblHeaderLink: "Header Link",
            lblShowDetails: "Show Details",
            showMenu : false ,
            showRecentItems : false,
            defaultAvailableView : true,
            decodeValue: false,
            showHeaderLink: false,
            onHeaderLinkClick: function() {},
            lblShowDetailsLink: "Show Details",
            includeShowDetailsLink: false,
            onShowDetailsLink: function() {},
            selectedListSortable: false
        }, options);

        this._defaults = defaults;
        this.info = {
            queryTerm: null,
            isDefaultSearch: false,
            data:[],
            sourceData: []
        };

        this.init();
    }

    /** @constructor */
    multipickSearch.prototype.init = function () {

        var widget = this,
            selected,
            $uiAutoCompleteHndl,
            $headerLink,
            searchControlMarkup = "<div class='control-counter-container'><span class='circle-btn cancel-btn' style='display:none;'><i class='fa fa-times'></i></span>"
                + (widget.options.multipick ? "<span class='counter'></span>" : "" ) + "</div>";

        // setup clickable header link
        if(widget.options.showHeaderLink) {
            $headerLink = $("<div/>").attr("class", "header-link")
                .append("<span>" + widget.options.lblHeaderLink + "</span>");

        }

        widget.info.$searchInput = $(widget.element);

        // surround input control with widget markup
        widget.info.$searchInput.wrap( "<div class='" + widget.options.cssClassMultipickSearch + "'></div>").after(searchControlMarkup)
            .before("<span class='search-container'><i class='fa fa-search'></i></span>");

        var $multiWidgetWrapper = widget.info.$searchInput.closest('.' + widget.options.cssClassMultipickSearch),
            $iconSearchCancel = $multiWidgetWrapper.find('.cancel-btn'),
            searchActive = function() {
                $iconSearchCancel.attr("style", "display:inline-block");
            },
            searchInactive = function() {
                $iconSearchCancel.hide();
            },
            textChangeEvent = function() {
                $this = $(this);
                if($this.val() !== "") {
                    searchActive.call(widget, $this);
                } else {
                    searchInactive.call(widget, $this);
                }
            },
            onResponseCallback = function(response, data) {
                if (data === null || !data.length) {
                    var item = {};

                    item.label = widget.options.lblNoResults;
                    item.value = null;

                    response([item]);
                } else {
                    response(data);
                }
            };

        widget.$counter = $multiWidgetWrapper.find(".counter");

        // on click of the link to open list of selected items
        widget.$counter.bind("click", function() {
            _buildSelectedList(widget.info.data);

            widget.info.$resultsMenuElement.hide();

            widget.$selectedItemsList.addClass("open");
        });

        /* search icon events */
        // user starts typing in search text box
        widget.info.$searchInput.on("keyup", textChangeEvent);
        widget.info.$searchInput.on("change", textChangeEvent);

        widget.info.$searchInput.on("focus", function() {
            if(widget.info.data.length == 1 && widget.options.multipick) {
                widget.info.$searchInput.val("");
            }
            
            if($(this).val() !== "") {
                searchActive.call(widget);
            }
        });

        // widget loses focus
        widget.info.$searchInput.on("blur", function() {
            if($(this).val() === "") {
                searchInactive.call(widget, $(this));
            }

            // if only one item selected then show it in input control
            if(widget.info.data.length == 1
                && widget.options.multipick) {
                widget.info.$searchInput.val(widget.info.data[0].label);
            }
        });

        // cancel icon click event
        $iconSearchCancel.bind("click", function() {
            var $this = $(this);

            widget.options.onCancel(widget.options);

            widget.info.$searchInput.val("");
            searchInactive.call(widget, $this);

            // if single pick then remove only selected item
            if(!widget.options.multipick && widget.info.data.length == 1) {
                // if single pick and item is selected then unselect/remove it
                _deleteItem(widget, widget.info.data[0], false);
            }

            if(widget.options.showMenu) {
                if(widget.info.$resultsMenuElement.has(".fa-check-circle").length > 0) {
                    widget.info.$resultsMenuElement.remove(".fa-check-circle");
                }
            }
            
        }); 

        widget.$selectedItemsList = $("<div class='selected-list'></div>");
        $("body").append(widget.$selectedItemsList);

        /* instantiate jquery-ui auto complete widget */
        var $autoCompleteCtrl = widget.info.$searchInput.autocomplete({
            source: function(request, response) {
                _source(request, response);
            },
            search: function() {
                widget.$selectedItemsList.removeClass("open");
            },
            messages: {
                noResults: '',
                results: function() {}
            },
            select: function(event, ui) {
                if (!widget.options.multipick) {

                    widget.options.onItemSelected(widget.options, ui.item);
                    
                    ui.item.label = (widget.options.decodeValue ? _decodeValue(ui.item.label) : ui.item.label);

                    widget.info.$searchInput.val(ui.item.label);

                    if(widget.options.showMenu) {
                        $itemEle = $(_getItemElement(event.originalEvent));

                        if($itemEle.has(".fa-check-circle").length === 0) {
                            $itemEle.append("<i class='fa fa-check-circle'></i>");
                        }
                    }

                    if (widget.options.multipick) {
                        // add item to list
                        widget.info.data = [];
                        widget.info.data.push(ui.item);
                    } else {
                        widget.info.data = [ui.item];
                    }

                } else {
                    $itemEle = $(_getItemElement(event.originalEvent));

                    if($itemEle.has(".fa-check-circle").length === 0) { // item NOT already selected
                        _addSelectedItem(ui.item, event, undefined, widget, $itemEle);
                    } else if($itemEle.has(".fa-check-circle").length > 0) { // item already selected so unselect
                        _deleteItem(widget, ui.item, true, $itemEle);
                    }

                    if(widget.info.data.length == 1 && widget.options.multipick) {
                        widget.info.$searchInput.val(ui.item.label);
                    } else if(widget.info.data.length > 1) {
                        widget.info.$searchInput.val("");
                    }

                    return false;
                }
            },
            focus: function (event, ui) {
                ui.item.label = (widget.options.decodeValue ? _decodeValue(ui.item.label) : ui.item.label);
                this.value = ui.item.label;
                event.preventDefault(); // Prevent the default focus behavior.
            },
            open: function(event, ui) { // search complete

                if(widget.options.isDefaultSearch) widget.options.isDefaultSearch = false;

                var pos = $multiWidgetWrapper.offset(),
                    h = $multiWidgetWrapper.height(),
                    ow = $multiWidgetWrapper.outerWidth(),
                    vph = Math.max(document.documentElement.clientHeight, window.innerHeight || 0),
                    $firstLiElement = widget.info.$resultsMenuElement.find("li").first(),
                    scrollW = Apttus.utils.getScrollbarSize().width,
                    scrollTop = Apttus.utils.getScrollTop(),
                    elTop = (pos.top + h),
                    listHeight = "auto";

                // remove height limit for proper measuring
                widget.info.$resultsMenuElement.css({ height: listHeight });

                if((elTop - scrollTop) + widget.info.$resultsMenuElement.height()  > vph) {
                    listHeight = ((vph - elTop) - scrollW + scrollTop) + "px";
                }

                $firstLiElement.append("<i class='fa fa-check-circle'></i>");
                var cw = $firstLiElement.find(".fa.fa-check-circle").width();
                $firstLiElement.find(".fa-check-circle").remove();

                widget.info.$resultsMenuElement.css({
                    "min-width":$multiWidgetWrapper.outerWidth() + "px",
                    left: pos.left,
                    top: pos.top + h,
                    height: listHeight,
                    width: (ow + scrollW + cw) + "px"
                });

                if(!widget.options.multipick && !widget.options.showMenu) return;

                widget.info.$resultsMenuElement.find("li").first().removeClass('ui-menu-item');

                if(widget.options.showMenu) {
                    if(widget.options.defaultAvailableView) {
                        $(".available-item").addClass("active-menu-item");
                        $(".recent-item").removeClass("active-menu-item");
                    } else {
                        $(".available-item").removeClass("active-menu-item");
                        $(".recent-item").addClass("active-menu-item");
                    }
                }
               
                // find selected item in list and remove check icon
                $.each(widget.info.$resultsMenuElement.find("li.ui-menu-item"), function(index, item) {
                    $item = $(item);
                    for (i = 0; i < widget.info.data.length; i++) {
                        if($item.data("autocomplete.item").value === widget.info.data[i].value) {
                            $item.append("<i class='fa fa-check-circle'></i>");
                        }
                    }
                });

                // bind the click events
                $(".available-item").bind("click" , function() {
                    $(this).addClass("active-menu-item");
                    $(".recent-item").removeClass("active-menu-item");
                    widget.options.defaultAvailableView = true;
                    
                    widget.info.$resultsMenuElement.hide();
                    widget.options.isDefaultSearch = false;
                    widget.info.$searchInput.click();

                });

                $(".recent-item").bind("click" , function() {
                    $(this).addClass("active-menu-item");
                    $(".available-item").removeClass("active-menu-item");
                    widget.options.defaultAvailableView = false;
                    widget.info.$resultsMenuElement.hide();
                    widget.options.isDefaultSearch = false;
                    widget.info.$searchInput.click();

                });

            }
        });

        $uiAutoCompleteHndl = $autoCompleteCtrl.data("ui-autocomplete");
        widget.info.$resultsMenuElement = $uiAutoCompleteHndl.menu.element;

        // override close event if multipick
        if(widget.options.multipick) {
            $uiAutoCompleteHndl._close = function(event, b) { };
        } else {
            var originalCloseMethod = $uiAutoCompleteHndl.close;
            $uiAutoCompleteHndl.close = function(event) {
                originalCloseMethod.apply( this, arguments );
                var entry;

                if(widget.info.data.length == 1) {
                    widget.info.$searchInput.val(widget.info.data[0].label);
                }
                
                // show the cross icon
                if(widget.options.showMenu) {
                    $iconSearchCancel.show();
                }
            };
        }

        $uiAutoCompleteHndl._renderItem = function(ul, item) {
            var entry, isDataItem = (item.value !== null);

            if(!widget.options.isDefaultSearch && isDataItem) {
                entry = "<a>" + item.label.replace(new RegExp("(" + _preg_quote(widget.info.queryTerm) + ")", 'gi'), "<b>$1</b>") + "</a>";
            } else {
                if(!isDataItem) {
                    entry = "<span>" + item.label + "</span>";
                } else {
                    entry = "<a>" + item.label + "</a>";
                }
            }
            if (isDataItem) {
                entry = "<div>" + entry;
                if (item.extraParams) {
                    Object.keys(item.extraParams).forEach(function (key) {
                        entry += "<a class='display-block'>" + item.extraParams[key].replace(new RegExp("(" + _preg_quote(widget.info.queryTerm) + ")", 'gi'), "<b>$1</b>") + "</a>";
                    });
                }
                entry += "</div>";
            }

            return $("<li></li>").attr("class", (!isDataItem ? "ui-menu-item-status" : "ui-menu-item"))
                .data("autocomplete.item", item)
                .append(entry)
                .appendTo(ul);
        };

        $uiAutoCompleteHndl._renderMenu = function(ul, items) {
            if (widget.options.multipick && !(items.length === 1 && items[0].value === null)) {
                widget.info._$resultsCloseBtn = _closeButton(_resultsOnClose);
                var $initialDiv = _initialElement(widget.options.lblResultsItemsTitle, widget.info._$resultsCloseBtn);

                $("<li/>").attr("class", "initial-menu-item").append($initialDiv).appendTo(ul);
                
            } 

            if(widget.options.showMenu) {
                var $initialDiv = _initialElement(widget.options.lblResultsItemsTitle, widget.info._$resultsCloseBtn);

                if(widget.options.showRecentItems) {
                    $initialDiv = $initialDiv.append("<span class='recent-item'> " + 'Recent Items' + "</span>");
                }

                $("<li/>").attr("class", "initial-menu-item").append($initialDiv).appendTo(ul);
            }
            
            if(widget.options.showHeaderLink){
                $("<li/>").attr("class", "initial-menu-item").append($headerLink)
                    .bind("click", function(){ 
                        widget.options.onHeaderLinkClick.call(widget);
                    })
                    .appendTo(ul);
            }

            var that = this;

            $.each(items, function(index, item) {
                that._renderItemData(ul, item);
            });
        };

        var _resultsOnClose = function() { // on click of close button for search results menu
                this.info.$searchInput.val('');

                this.info.$searchInput.change();

                if(this.info.data.length == 1 && this.options.multipick) {
                    this.info.$searchInput.val(this.info.data[0].label);
                }

                this.info.$resultsMenuElement.hide();
            },
            _selectedItemsOnClose = function() {
                this.$selectedItemsList.removeClass("open");
            },
            _deleteItem = function(widget, item, updateUi, $itemEle) {
                widget.options.onDelete(widget.options, item);

                if($itemEle) $itemEle.find(".fa-check-circle").remove();

                if(widget.info.data.length == 1 && widget.options.multipick) {
                    widget.info.$searchInput.val("");
                }

                // remove element from in-memory data store
                widget.info.data = jQuery.grep(widget.info.data, function(n) {
                    return (n.value !== item.value);
                });

                if(widget.options.multipick && (updateUi === undefined || updateUi)) {
                    // rebuild selected list
                    _buildSelectedList(widget.info.data);

                    // update count on UI
                    _updateCount(widget);
                }
            },
            deleteEvent = function() { // when user clicks the X icon next to a selected item in the list
                $this = $(this);

                var $liToRemove = $this.closest("li"),
                    item = $liToRemove.data(constants.itemDataAttributeName);

                _deleteItem(widget, item);

                $liToRemove.remove();
                $this.parent().remove();
                $this.remove();
            },
            _decodeValue = function(strValue) { // removes HTML encoding from value
                return $('<textarea />').html(strValue).text();
            };

        // if default results specified handle display of default results when search control focused
        if(widget.options.defaultResults !== null){
            var performDefaultSearch = function() {
                // if no search value entered and results not currently displayed then perform default search
                if(!widget.options.isDefaultSearch 
                    && widget.info.$resultsMenuElement.css("display") === "none") {
                    widget.options.isDefaultSearch = true;

                    // option minLength set to 0 to display all available search items (works in all web browsers)
                    widget.info.$searchInput.autocomplete("option", "minLength", 0);
                    widget.info.$searchInput.autocomplete("search", "");
                }
            };

            // default search events
            widget.info.$searchInput.bind("focus", function() { performDefaultSearch.call(this); });
            widget.info.$searchInput.bind("click", function() { performDefaultSearch.call(this); });

            widget.info.$searchInput.bind("keyup", function() {
                // if no search value entered and results not currently displayed then perform default search
                if($(this).val() === "") {
                    widget.options.isDefaultSearch = true;
                    
                    // option minLength set to 0 to display all available search items (works in all web browsers)
                    widget.info.$searchInput.autocomplete("option", "minLength", 0);
                    widget.info.$searchInput.autocomplete("search", "");
                }
            });
        }

        /* private methods */
        var _preg_quote = function(str) {
                return (str + '').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
            },
            _itemExists = function(inArr, value) {
                for (i = 0; i < inArr.length; i++) {
                    if (inArr[i].value == value) return true;
                }
            },
            _closeButton = function(onCloseClick) {
                return $('<span></span>').attr("class", "close")
                    .html(widget.options.lblClose)
                    .bind("click", function(){ onCloseClick.call(widget); });
            },
            _getShowDetailsLink = function() {
                return $('<span></span>').attr("class", "close")
                    .html(widget.options.lblShowDetailsLink)
                    .bind("click", function(){
                        // hide menu
                        widget.$selectedItemsList.removeClass("open");

                        // call event handler for show details link
                        widget.options.onShowDetailsLink.call(widget);
                    });
            },
            _initialElement = function(text, $closeBtn, $showDetailsLink, includeShowDetailsLink) {
                var $initElement = $("<div/>").attr("class", "initial-item")
                    .append("<span class='available-item'>" + text + "</span>");

                if(includeShowDetailsLink && $showDetailsLink) {
                    $initElement.append($showDetailsLink);
                }

                return $initElement.append($closeBtn);
            },
            _updateCount = function(widget) {
                if (!widget.options.multipick) return;

                // counter number of selected items
                var counter = widget.info.data.length;

                if (counter === 0) {
                    widget.$counter.text('');
                    widget.$selectedItemsList.removeClass("open");
                } else {
                    widget.$counter.text(counter);
                }
            },
            _buildSelectedList = function(currentData) {
                var pos = $multiWidgetWrapper.offset(),
                    h = $multiWidgetWrapper.height(),
                    vph = Math.max(document.documentElement.clientHeight, window.innerHeight || 0),
                    scrollW = Apttus.utils.getScrollbarSize().width
                    scrollTop = Apttus.utils.getScrollTop(),
                    elTop = (pos.top + h),
                    listHeight = "auto";

                widget.$selectedItemsList.css({ height: listHeight });

                if((elTop - scrollTop) + widget.$selectedItemsList.height()  > vph) {
                    listHeight = ((vph - elTop) - scrollW + scrollTop) + "px";
                }

                widget.$selectedItemsList.css({
                    left: pos.left,
                    top: pos.top + h,
                    "min-width":$multiWidgetWrapper.outerWidth() + "px",
                    height: listHeight,
                    width: "auto"
                });

                // clear ul list to be refreshed with elements
                var $t = widget.$selectedItemsList.find("ul"),
                    c = '<ul></ul>',
                    ul;

                if ($t.length > 0) {
                    ul = widget.$selectedItemsList.html(c).find("ul");
                } else {
                    ul = $(c);
                    widget.$selectedItemsList.append(ul);
                }

                widget.info._$selectedItemsCloseBtn = _closeButton(_selectedItemsOnClose);

                _initialElement(widget.options.lblSelectedItemsTitle,
                    widget.info._$selectedItemsCloseBtn,
                    _getShowDetailsLink,
                    widget.options.includeShowDetailsLink).insertBefore(ul);

                for (var i = 0; i < currentData.length; i++) {
                    var $deleteBtn = $('<div/>')
                        .attr('class', 'circle-btn cancel-btn delete')
                        .append($('<i/>').attr('class', 'fa fa-times'));

                    // on click of delete button
                    $deleteBtn.on("click", deleteEvent);

                    // newly added item
                    var $newItem = $("<li/>").attr('class', 'selected-item').data(constants.itemDataAttributeName, currentData[i]);

                    var itemContainerClsName = "item-container";

                    if(widget.options.selectedListSortable && widget.info.data.length > 1) {
                        itemContainerClsName = "item-container-draggable";
                    }

                    var $liCont = $("<div/>").attr("class", itemContainerClsName);

                    if(widget.options.selectedListSortable && widget.info.data.length > 1) {
                        var $selectorHndl = $("<span/>").addClass("sort-handle")
                            .append("<i class='fa fa-ellipsis-v' aria-hidden='true'></i>")
                            .append("<i class='fa fa-ellipsis-v' aria-hidden='true'></i>");

                        $newItem.append($selectorHndl);
                    }

                    $liCont.append("<span data-value='" + currentData[i].value + "'>" + currentData[i].label + "</span>")
                        .append($deleteBtn);

                    $newItem.append($liCont).appendTo(ul);
                }

                if(widget.options.selectedListSortable && widget.info.data.length > 1) {
                    ul.sortable({
                        stop: function( event, ui ) {
                            var reorderedData = [];
                            // build new list of data
                            ul.find("li").each(function(index){
                                var currentItem = $(this).data(constants.itemDataAttributeName);

                                reorderedData.push(currentItem);
                            });

                            // set list of selected items
                            _setSelectedItems(reorderedData, true, widget, false);
                        }
                    });
                }

                // calculate container width
                var ow = widget.$selectedItemsList.outerWidth();
                widget.$selectedItemsList.css({ width: (ow + scrollW) + "px"});

            },
            _getItemElement = function(originalEvent){
                var returnItem;
                if(originalEvent.srcElement !== undefined && originalEvent.srcElement !== null){
                    if(originalEvent.srcElement.tagName === "LI"){
                        returnItem = originalEvent.srcElement;
                    } else {
                        returnItem = $(originalEvent.srcElement).closest("li");
                    }
                }

                return returnItem;
            },
            /**
             * Called upon an item being selected from the results list
             * @param {object} item                 object containing selected item label and value
             * @param {object} uiEvent              jQuery UI event object
             * @param {boolean} triggerOnSelectEvent indicates whether or not to trigger onSelect event
             * @param {object} widget               instance of the multipick widget
             * @param {object} $itemEle             current selected item li DOM jquery wrapped element
             * @param {boolean} massSelection       boolean value indicating whether calling method is performing
             * a mass selection of multiple items or not.
             */
            _addSelectedItem = function(item, uiEvent, triggerOnSelectEvent, widget, $itemEle, massSelection) {
                triggerOnSelectEvent = (triggerOnSelectEvent === undefined ?  true : triggerOnSelectEvent);

                // if multi-pick enabled and dissallowDuplicate option turned on then verify is not duplicate selection
                if (widget.options.multipick 
                    && widget.options.disallowDuplicate 
                    && _itemExists(widget.info.data, item.value)) {
                    return
                }

                // if a selection limit set then verify it has not been reached before adding item
                if(widget.options.selectionCountLimit) {
                    if(widget.info.data.length >= widget.options.selectionCountLimit) {
                        return;
                    }
                }

                // if jQuery wrapped li DOM element present in current context then add circled check icon
                if($itemEle) $itemEle.append("<i class='fa fa-check-circle'></i>");

                if(triggerOnSelectEvent) widget.options.onItemSelected(widget.options, item);

                if (widget.options.multipick) {
                    // add item to list
                    widget.info.data.push(item);
                } else {
                    widget.info.data = [item];
                }
                
                if(!massSelection) {
                    _updateWidgetSelectionUi(widget, item);
                }
                
            },
            _updateWidgetSelectionUi = function(widget, item) {
                // build UI DOM elements for list of selected items
                _buildSelectedList(widget.info.data);

                // count and display updated count on UI
                _updateCount(widget);

                // update displayed search term in text input
                if(!widget.options.multipick) {
                    widget.info.$searchInput.val(item.label);
                } else if(widget.info.data.length == 1) { // 
                    widget.info.$searchInput.val(widget.info.data[0].label);
                } else if(widget.info.data.length > 1) {
                    widget.info.$searchInput.val("");
                }
            },
            _clearAllItems = function(widget, updateUI) {
                // clear list of selected items
                for (var i = widget.info.data.length - 1; i >= 0; i--) {
                    // delete item one by one triggering delete event
                    // pass in third param as false indicating to not update the UI
                    // since this is handled below
                    _deleteItem(widget, widget.info.data[i], false);
                }

                if(updateUI === undefined || updateUI) {
                    // rebuild selected list
                    _buildSelectedList(widget.info.data);

                    // update count on UI
                    _updateCount(widget);
                }

            },
            _setSelectedItems = function(items, triggerOnSelectEvent, widget, updateUI) {
                // clear list of selected items
                _clearAllItems(widget, updateUI);

                // populate with new list
                for (var i = 0; i < items.length; i++) {
                    _addSelectedItem(items[i], undefined, 
                        triggerOnSelectEvent, 
                        widget, 
                        undefined, 
                        true);

                    // last item? then perform UI update
                    if(i == items.length - 1) _updateWidgetSelectionUi(widget, items[i]);
                }



            },
            _source = function(request,response){

                widget.info.queryTerm = request.term;

                $uiAutoCompleteHndl.menu.element.hide();

                // check which button is clicked based on which decide which data source function to be called
                var showAvailableItems = $(".available-item:visible").length > 0 ? $(".available-item").hasClass("active-menu-item") : widget.options.defaultAvailableView;

                // if default search specified use default results for data source
                if(widget.options.recentItemsDataSourceFunction !== undefined && !showAvailableItems){
                   
                    widget.options.recentItemsDataSourceFunction(request, function(data){
                        onResponseCallback(response, data);
                        widget.info.sourceData = data;
                    });

                } else if(widget.options.isDefaultSearch){
                    
                    widget.options.defaultResults(request, function(data){
                        onResponseCallback(response, data);
                         widget.info.sourceData = data;
                    });

                } else { 
                    
                    if(widget.options.dataSourceFunction !== undefined && showAvailableItems){
                        
                        widget.options.dataSourceFunction(request, function(data){
                            onResponseCallback(response, data);
                             widget.info.sourceData = data;
                        });

                    }  else {
                       
                        onResponseCallback(response, widget.resultsSearch(request.term, widget.options.data));
                    }
                }
            };

        multipickSearch.prototype._onDocumentClick = function(e){
            if (!this.info.$searchInput.is(e.target)
                && !this.info.$resultsMenuElement.is(e.target) // if the target of the click isn't the container...
                && !this.$selectedItemsList.is(e.target)
                && this.info.$resultsMenuElement.has(e.target).length === 0 // ... nor a descendant of the container
                && this.$selectedItemsList.has(e.target).length === 0) {

                var isOpen = this.info.$resultsMenuElement.css("display") !== "none";

                if ((this.info._$resultsCloseBtn !== undefined && this.info._$resultsCloseBtn.length === 1) || isOpen) {
                    _resultsOnClose.call(this);
                }

                if(this.info._$selectedItemsCloseBtn !== undefined && this.info._$selectedItemsCloseBtn.length === 1) {
                    _selectedItemsOnClose.call(this)
                }
            }
        };

        // user clicks anywhere on page outside of menu
        $(document).mouseup(function (e) { widget._onDocumentClick.call(widget, e); });

        multipickSearch.prototype.settings = function() {
            return widget.options;
        };

        multipickSearch.prototype.uiAutoCompleteHndl = function() {
            return $uiAutoCompleteHndl;
        };

        multipickSearch.prototype.addSelectedItem = function(item) {
            _addSelectedItem(item, null, true, this);
        };

        multipickSearch.prototype.removeSelectedItem = function(item) {
            _deleteItem(this, item);
        };

        multipickSearch.prototype.getSelectedItems = function() {
            return this.info.data;
        };

        multipickSearch.prototype.setSelectedItems = function(items, triggerOnSelectEvent) {
            _setSelectedItems(items, triggerOnSelectEvent, this);
        };

        multipickSearch.prototype.findItem = function(itemValue) {
            $.each(widget.info.sourceData , function(index,item) {
                if(item.value === itemValue) {
                    return item;
                }
            });

            ;
        };

        multipickSearch.prototype.resultsSearch = function(searchTerm, fieldOptions) {
            var fieldOptionsTemp = [];

            for (i = 0; i < fieldOptions.length; i++) {
                var fieldOption = fieldOptions[i].label.toLowerCase();

                if (fieldOption.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1) {
                    fieldOptionsTemp.push(fieldOptions[i]);
                }
            }

            return fieldOptionsTemp;
        };

    };

    // Constructor preventing against multiple instantiations and allowing any
    // public function (ie. a function whose name doesn't start
    // with an underscore) to be called via the jQuery plugin,
    // e.g. $(element).multipickSearch('functionName', arg1, arg2)
    $.fn[pluginName] = function ( options ) {
        var args = arguments;

        // Is the first parameter an object (options), or was omitted,
        // instantiate a new instance of the plugin.
        if (options === undefined || typeof options === 'object') {
            return this.each(function () {

                // Only allow the plugin to be instantiated once,
                // so we check that the element has no plugin instantiation yet
                if (!$.data(this, 'plugin_' + pluginName)) {

                    // if it has no instance, create a new one,
                    // pass options to our plugin constructor,
                    // and store the plugin instance
                    // in the elements jQuery data object.
                    $.data(this, 'plugin_' + pluginName, new multipickSearch( this, options ));
                }
            });

            // If the first parameter is a string and it doesn't start
            // with an underscore or "contains" the `init`-function,
            // treat this as a call to a public method.
        } else if (typeof options === 'string' && options[0] !== '_' && options !== 'init') {

            // Cache the method call
            // to make it possible
            // to return a value
            var returns;

            this.each(function () {
                var instance = $.data(this, 'plugin_' + pluginName);

                // Tests that there's already a plugin-instance
                // and checks that the requested public method exists
                if (instance instanceof multipickSearch && typeof instance[options] === 'function') {

                    // Call the method of our plugin instance,
                    // and pass it the supplied arguments.
                    returns = instance[options].apply( instance, Array.prototype.slice.call( args, 1 ) );
                }

                // Allow instances to be destroyed via the 'destroy' method
                if (options === 'destroy') {
                    $.data(this, 'plugin_' + pluginName, null);
                }
            });

            // If the earlier cached method
            // gives a value back return the value,
            // otherwise return this to preserve chainability.
            return returns !== undefined ? returns : this;
        }
    };

}(jQuery, window, document, undefined));
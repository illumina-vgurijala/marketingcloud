function CustomAutoCompleteControl(j$, options) {
  var settings = j$.extend({
    onDelete: function(item) {},
    onItemSelected:function(settings, item) {},
    multipick: true,
    propNameLabel: "label",
    propNameValue: "value",
    initialItems: null,
    disallowDuplicate: true,
    isDefaultSearch:false,
    defaultResults:null,
    lblResultsItemsTitle:"Available Items",
    lblSelectedItemsTitle:"Selected Items",
    lblClose:"Close",
    lblNoResults:"No Results Available"
  }, options);

  var $searchInput = j$(settings.inputControlSelector),
      $selectedItemsInput = j$(settings.selectedItemInputSelector),
      $currentWidget = $searchInput.closest(".multi-select-widget"),
      $counter = $currentWidget.find(".counter"),
      $selectList = j$(".selected-list"),
      currentData = [],
      queryTerm,
      thisInstance,
      selectedItem,
      selecting = false,
      $uiAutoCompleteHndl,
      $resultsMenuElement;

  // add a selected list div if none already
  if ($selectList.length === 0) {
    $selectList = j$("<div class=\"selected-list\"></div>");
    j$("body").append($selectList);
  }

  var onResponseCallback = function(response, data) {

    if (data === null || !data.length) {
        var item = {};

        item[settings.propNameLabel] = settings.lblNoResults;
        item[settings.propNameValue] = null;

        response([item]);
    } else {
        // normalize data from server if inconsistent
        for(i = 0;i < data.length; i++) {
            if(typeof data[i] === 'string'){
                var item = {};

                // use same value for value and name since is simple array of values
                item[settings.propNameLabel] = data[i];
                item[settings.propNameValue] = data[i];

                // populate with new object
                data[i] = item;
            }
          
        }
        
        response(data);
    }
  }

  $autoCompleteCtrl = $searchInput.autocomplete({
    source: function(request, response) {
      queryTerm = request.term;

      $uiAutoCompleteHndl.menu.element.hide();

      // if default search specified use default results for data source
      if(settings.isDefaultSearch){
          settings.defaultResults(request, function(data){
            onResponseCallback(response, data);
          });
      } else {
          settings.dataSourceFunction(request, function(data){
            onResponseCallback(response, data);
          });
      }
    },
    search: function(event, ui) {
      j$(".selected-list").removeClass("open");
    },
    messages: {
      noResults: '',
      results: function() {}
    },
    select: function(event, ui) {
      $selectList = j$(".selected-list");

      if (!settings.multipick) {
        selectedItem = ui.item;

        var entry;

        // handle nested property name
        if(settings.propNameLabel.indexOf('.') > 0){
          labelSplit = settings.propNameLabel.split('.');
          entry = selectedItem[labelSplit[labelSplit.length - 1]];
        }else{
          entry = selectedItem[settings.propNameLabel];
        }

        settings.onItemSelected(settings, selectedItem);

        $searchInput.val(entry);

        if($selectedItemsInput != undefined){
          $selectedItemsInput.val(selectedItem[settings.propNameValue]);
        }
      } else {
        thisInstance.addSelectedItem(ui.item);
        $searchInput.val('');
        return false;
      }
    },
    open: function(event, ui) { // search complete
      if(settings.isDefaultSearch) settings.isDefaultSearch = false;      
      if(!settings.multipick) return;

      $resultsMenuElement.find("li").first().removeClass('ui-menu-item');
    }
  });

  $uiAutoCompleteHndl = $autoCompleteCtrl.data("ui-autocomplete");
  $resultsMenuElement = $uiAutoCompleteHndl.menu.element;

  // override close event if multipick
  if(settings.multipick) {
    $uiAutoCompleteHndl._close = function(event, b) {  };
  } else {
    var originalCloseMethod = $uiAutoCompleteHndl.close;
    $uiAutoCompleteHndl.close = function(event) {
      originalCloseMethod.apply( this, arguments );
      var entry;
      if(selectedItem != undefined){
        if(settings.propNameLabel.indexOf('.') > 0){
          labelSplit = settings.propNameLabel.split('.');
          entry = selectedItem[labelSplit[labelSplit.length - 1]];
        } else {
          entry = selectedItem[settings.propNameLabel];
        }
      }
      $searchInput.val(entry);
    };
  }

  $uiAutoCompleteHndl._renderItem = function(ul, item) {
    var entry, itemText, isDataItem = (item[settings.propNameValue] !== null);

    // handle single level nested property name (e.g. { "itemObj.value" : "value" } )
    if(settings.propNameLabel.indexOf('.') > 0){
      labelSplit = settings.propNameLabel.split('.');
      itemText = item[labelSplit[labelSplit.length - 1]];
    } else {
      itemText = item[settings.propNameLabel];
    }

    if(!settings.isDefaultSearch && isDataItem) {
      entry = "<a>" + itemText.replace(new RegExp("(" + preg_quote(queryTerm) + ")", 'gi'), "<b>$1</b>") + "</a>";
    } else {
      if(!isDataItem) {
        entry = "<span>" + itemText + "</span>";
      } else {
        entry = "<a>" + itemText + "</a>";
      }
    }

    return j$("<li></li>", { class:(!isDataItem ? "ui-menu-item-status" : "ui-menu-item") })
        .data("autocomplete.item", item)
        .append(entry)
        .appendTo(ul);
  };

  // on click of close button for search results menu
  var _resultsOnClose = function() {
          $searchInput.val('');
          $searchInput.change();
          $resultsMenuElement.hide();
      },
      _selectedItemsOnClose = function() {
          $selectList.removeClass("open");
      },
      _$resultsCloseBtn,
      _$selectedItemsCloseBtn;

  $uiAutoCompleteHndl._renderMenu = function(ul, items) {
    if (settings.multipick) {
      _$resultsCloseBtn = closeButton(_resultsOnClose);
      var $initialDiv = initialElement(settings.lblResultsItemsTitle, _$resultsCloseBtn);

      j$("<li/>", {
        class: "initial-menu-item"
      }).append($initialDiv).appendTo(ul);
    }

    var that = this;

    j$.each(items, function(index, item) {
      that._renderItemData(ul, item);
    });
  };

  // if default results specified handle display of default results when search control focused
  if(settings.defaultResults !== null){

    $searchInput.bind("focus", function() {
      // if no search value entered and results not currently displayed then perform default search
      if(j$(this).val() === "" && $resultsMenuElement.css("display") === "none") {
        settings.isDefaultSearch = true;
        $searchInput.autocomplete("search", "a");
      }
    });

  }

  // user clicks anywhere on page outside of menu
  j$(document).mouseup(function (e)
  {
      if (!$searchInput.is(e.target)
          && !$resultsMenuElement.is(e.target) // if the target of the click isn't the container...
          && !$selectList.is(e.target)
          && $resultsMenuElement.has(e.target).length === 0 // ... nor a descendant of the container
          && $selectList.has(e.target).length === 0)
      {
          if(_$resultsCloseBtn !== undefined && _$resultsCloseBtn.length === 1) _resultsOnClose.call(_$resultsCloseBtn[0]);
          if(_$selectedItemsCloseBtn !== undefined && _$selectedItemsCloseBtn.length === 1) _selectedItemsOnClose.call(_$selectedItemsCloseBtn[0]);
      }
  });

  var deleteEvent = function() {
    $this = j$(this);

    var $liToRemove = $this.closest("li"),
        item = $liToRemove.data("item"),
        data = getData();

    settings.onDelete(item);

    // remove element from in-memory data store
    data = jQuery.grep(data, function(n, i) {
      return (n[settings.propNameValue] !== item[settings.propNameValue]);
    });

    setData(data);

    $liToRemove.remove();
    $this.parent().remove();
    $this.remove();

    updateCount($counter, $selectList);
  };

  thisInstance = {
    addSelectedItem: function(item) {

      var data = getData();

      // if multi-pick enabled and dissallowDuplicate option turned on then verify is not duplicate selection
      if(settings.multipick && settings.disallowDuplicate && itemExists(data, item[settings.propNameValue])) return;

      settings.onItemSelected(settings, item);

      // add item to list
      data.push(item);

      // update data source
      setData(data);

      buildSelectedList(data);

      // count and display updated count on UI
      updateCount($counter, $selectList);

      var currentValue = $selectedItemsInput.val();
      if (currentValue == 'All' || currentValue == '') {
        $selectedItemsInput.val(item[settings.propNameValue]);
      } else {
        $selectedItemsInput.val(currentValue + '; ' + item[settings.propNameValue]);
      }
    },
    clearSelectedItems: function() {
      // clear cached data
      $searchInput.data("items", null);
    },
    settings:settings,
    uiAutoCompleteHndl: $uiAutoCompleteHndl
  };

  // add initially selected items
  if(settings.initialItems !== null && settings.multipick) {
    for (i = 0; i < settings.initialItems.length; i++) {
      thisInstance.addSelectedItem(settings.initialItems[i]);
    }
  }

  function itemExists(inArr, value) {
    for (i = 0; i < inArr.length; i++)
    {
      if (inArr[i][settings.propNameValue] == value) return true;
    }
  }

  function preg_quote(str) {
    return (str + '').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
  }

  function getData() {
    var data = $searchInput.data("items");

    if (data === null || data === undefined) return [];

    return data;
  }

  function setData(data) {
    $searchInput.data("items", data);
  }

  // on click of the link to open list of selected items
  $counter.click(function() {
    buildSelectedList(getData());

    $resultsMenuElement.hide();

    $selectList.addClass("open");
  });

  function buildSelectedList(currentData) {

    var pos = $searchInput.offset(),
        h = $searchInput.height(),
        w = $searchInput.width();

    $selectList.css({
      left: pos.left,
      top: pos.top + h
    }).width($searchInput.width());

    // clear ul list to be refreshed with elements
    var $t = $selectList.find("ul"),
        c = '<ul></ul>';

    if ($t.length > 0) {
      ul = $selectList.html(c).find("ul");
    } else {
      ul = j$('<ul></ul>')
      $selectList.append(ul);
    }
    
    _$selectedItemsCloseBtn = closeButton(_selectedItemsOnClose);
    var $initialDiv = initialElement(settings.lblSelectedItemsTitle, _$selectedItemsCloseBtn).insertBefore(ul);

    for (var i = 0; i < currentData.length; i++) {
      var $deleteBtn = j$('<div/>', {
        class: 'circle-btn cancel-btn delete'
      }).append(j$('<i/>', {
        class: 'fa fa-times'
      }));

      // on click of delete button
      $deleteBtn.on("click", deleteEvent);

      // newly added item
      var $newItem = j$("<li/>", {
        class: 'selected-item'
      }).data("item", currentData[i]);

      var $liCont = j$("<div/>", {
        class: "item-container"
      })
          .append("<span data-value='" + currentData[i][settings.propNameValue] + "'>" + currentData[i][settings.propNameLabel] + "</span>")
          .append($deleteBtn);

      $newItem.append($liCont).appendTo(ul);
    }
  }

  function closeButton(onCloseClick) {
      return j$('<span></span>', { class: "close" })
                .html(settings.lblClose)
                .bind("click", onCloseClick);
  }

  function initialElement(text, $closeBtn) {
    var $initialItemInner = j$("<div/>", {
      class: "initial-item"
    })
        .append("<span>" + text + "</span>")
        .append($closeBtn);

    return $initialItemInner;
  }

  function updateCount($counter, $selectList) {
    if (!settings.multipick) return;

    // counter number of selected items
    var counter = $selectList.find("ul li.selected-item").length;
    if (counter === 0) {
      $counter.text('');
      $selectList.removeClass("open");
    } else {
      $counter.text(counter);
    }
  }

  return thisInstance;

}
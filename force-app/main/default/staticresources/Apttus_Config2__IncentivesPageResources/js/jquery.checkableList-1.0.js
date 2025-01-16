/*
 *  Project: Incentives
 *  Description: can be applied to list of checkable items tracking checked state as well as the values of the checked items
 *  Dependencies: jQuery 
 *  Author: Ian Gallagher - Apttus
 *  License:
 */
;
(function($, window, document, undefined) {

  "use strict";

  var pluginName = "checkableList",
    defaults = {
      onSomeChecked: function(checkedCheckBox, $checkBoxContainers) {},
      onNoneChecked: function($checkBoxContainers) {},
      onAllChecked: function($checkBoxContainers) {},
      dataSourceType: null,
      dataElementSelector: null
    };

  // The actual plugin constructor
  function checkableList(element, options) {
    this.element = element;
    // jQuery has an extend method which merges the contents of two or
    // more objects, storing the result in the first object. The first object
    // is generally empty as we don't want to alter the default options for
    // future instances of the plugin
    this.settings = $.extend({}, defaults, options);
    this._defaults = defaults;
    this._name = pluginName;
    this.data = { checkedItems: [] };
    this.init();
  }

  $.extend(checkableList.prototype, {
    init: function() {
      var $allCheck = $(this.element),
        opts = this.settings,
        $checkBoxContainers = $allCheck.closest(opts.parentContainer).find(opts.checkBoxListSelector),
        _instance = this;

      // update data in case any checkboxes are already checked on load.
      _instance._updateData(_instance, $checkBoxContainers.find(":checkbox:checked"));

      $allCheck.on("change", function() {
        if ($allCheck.is(':checked')) {
          $checkBoxContainers.find(":checkbox").prop('checked', true);
          opts.onAllChecked($checkBoxContainers);

        } else { // deselect all check boxes
          $checkBoxContainers.find(":checkbox").prop('checked', false);
          opts.onNoneChecked($checkBoxContainers);

        }
        
        _instance._updateData(_instance, $checkBoxContainers.find(":checkbox:checked"));

      });

      $checkBoxContainers.find(":checkbox").on("change", function() {

        var $checkedCheckBoxes = $checkBoxContainers.find(":checkbox:checked");
        
        // if all unchecked then disable button
        if ($checkedCheckBoxes.length === 0) {
          // no checkboxes checked
          $allCheck.prop("checked", false);
          opts.onNoneChecked($checkBoxContainers);
        } else {
          if ($checkBoxContainers.find(":checkbox").length === $checkedCheckBoxes.length) {
            // all checkboxes checked
            $allCheck.prop("checked", true);
            opts.onAllChecked($checkBoxContainers);
            _instance._updateData(_instance, $checkedCheckBoxes);
            return;
          }

          // some checkboxes checked
          $allCheck.prop("checked", false);
          opts.onSomeChecked(this, $checkBoxContainers);
        }
        
        _instance._updateData(_instance, $checkedCheckBoxes);
      });
    },
    _updateData: function(_instance, $checkedCheckBoxes) {

      _instance.data.checkedItems = [];
      
      if(_instance.settings.dataSourceType === null) return;
      
      $checkedCheckBoxes.each(function(index) {
        // clear data
        var data,
          opts = _instance.settings;
  
        switch (opts.dataSourceType) {
          case "HiddenInput":
            data = $(this).closest(opts.checkBoxListSelector).find(opts.dataElementSelector).val();
            break;
          case "DataAttribute":
            data = $(this).data(opts.dataElementSelector);
            break;
          case "HTMLContent":
            data = $(this).closest(opts.checkBoxListSelector).find(opts.dataElementSelector).html();
            break;
          default:
        }

        _instance.data.checkedItems.push(data);
      });
      
    },
    getData: function() {
      return this.data.checkedItems; 
    }
  });

  // A really lightweight plugin wrapper around the constructor,
  // preventing against multiple instantiations
  $.fn[pluginName] = function(options) {
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
                    $.data(this, 'plugin_' + pluginName, new checkableList( this, options ));
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
                if (instance instanceof checkableList && typeof instance[options] === 'function') {

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

})(jQuery, window, document);
var j$ = jQuery.noConflict();
var openingPopup = false;

var getFieldValues = function(list, separator) {
	    list = (list.indexOf("[") > -1 ? list.substring(1, list.length - 1) : list);
	    return (list === '' || list === '[]' ? [] : list.split(separator));
	},
	updateFieldOptions = function(list, value, separator, select, includeBrackets) {
	    var values = getFieldValues(list, separator),
	        separator = (separator === undefined ? "," : separator ),
            includeBrackets = (includeBrackets === undefined ? true : includeBrackets ),
            lb = (includeBrackets ? "[" : "" ),
            rb = (includeBrackets ? "]" : "" );

	    if(!select) {
	        for(var i = 0 ; i < values.length ; i++) {
	            if(values[i] == value) {
	                values.splice(i, 1);
	                return lb + values.join(separator) + rb;
	            }
	        }
	    } else {
	        values.push(value);
	        return lb + values.join(separator) + rb
	    }
	    
	    return lb + values.join(separator) + rb;
	},
	// scan an array of values for matching results and return to caller
	searchItems = function(searchTerm, fieldOptions){
		var fieldOptionsTemp = [];

		for(var i = 0; i < fieldOptions.length; i++){
		    var fieldOption = fieldOptions[i].value.toLowerCase();

		    if(fieldOption.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1){
		        fieldOptionsTemp.push(fieldOptions[i]);
		    }
		}

		return fieldOptionsTemp;
	},
	normalizeData = function(data, lblLabel, lblValue) {
        var newData = [];

        // normalize data from server if inconsistent
        for(var i = 0;i < data.length; i++) {
            var item = {};

            if(typeof data[i] === 'string'){
                // use same value for value and name since is simple array of values
                item.label = data[i];
                item.value = data[i];
            } else {
                // handle single level nested property name (e.g. { "itemObj.value" : "value" } )
                if(lblLabel.indexOf('.') > 0){
                    labelSplit = lblLabel.split('.');
                    item.label = data[i][labelSplit[labelSplit.length - 1]];
                } else {
                    item.label = data[i][lblLabel];
                }

                item.value = data[i].Id;
            }

            newData.push(item);
        }

        return newData;
    },
    populateMultiPickSearchControl = function(searchWidget, picklistItems, selectedItems, separator) {
        if(selectedItems === null || selectedItems === "") return;
        
        separator = (separator === undefined ? ";" : separator ),
            selectedValues = selectedItems.split(separator);

        for(var i = 0; i < selectedValues.length; i++) {
            var value = selectedValues[i];
            var currentItem = findItem(value, picklistItems);

            if(currentItem !== null && currentItem !== undefined){
                searchWidget.multipickSearch("addSelectedItem", { label: decodeHtml(currentItem.label), value: decodeHtml(value) } );
            }
        }
        
    },
    findItem = function(itemValue, items) {
        for (var i = 0, len = items.length; i < len; i++) {
            if (items[i].value === itemValue)
                return items[i]; // Return as soon as the object is found
        }
        return null; // The object was not found
    };

var esc = function(myid) {
    return '#' + myid.replace(/(:|\.)/g,'\\\\$1');
};

var instantiatePicklistWidget = function(options) {
    var $pickWidget = options.$multipickCtrl.multipickSearch({
        lblResultsItemsTitle: options.customLabels.lblAvailableItems,
        lblSelectedItemsTitle: options.customLabels.lblSelectedItems,
        lblClose: options.customLabels.lblClose,
        lblNoResults: options.customLabels.lblNoResultsAvailable,
        multipick: options.isMultiPick,
        dataSourceFunction: options.dataSourceFunction,
        defaultResults: options.defaultResults,
        decodeValue: true,
        onItemSelected: function(settings, item) {
            if (options.isMultiPick){
                options.$multpickDataBoundInput.val(
                    updateFieldOptions(options.$multpickDataBoundInput.val(), 
                        item.value, 
                        options.multiPickValueSeparator, 
                        true, 
                        false)
                );
            } else {
                options.$multpickDataBoundInput.val(item.value);
            }
        },
        onDelete: function(settings, item) {
             if (options.isMultiPick){
                options.$multpickDataBoundInput.val(
                    updateFieldOptions(options.$multpickDataBoundInput.val(), 
                        item.value, 
                        options.multiPickValueSeparator, 
                        false, 
                        false)
                );
            } else {
                options.$multpickDataBoundInput.val(item.value);
            }

            
        }
    });

    if(options.isMultiPick) {
        options.$multpickDataBoundInput.val("");
    } else {
        options.$multipickCtrl.val(options.value);
    }

    return $pickWidget;
};

// removal of items from multi-pick widget.
var onDeleteEvent = function(itemValue, hiddenControlID) {
    var $hdnSelectedItems = j$("[id$="+ hiddenControlID + "]"),
        currentValues = $hdnSelectedItems.val(),
        updatedList = removeValue(currentValues, itemValue, "; ");

    $hdnSelectedItems.val((updatedList === "" ? "All" : updatedList));
};

var removeValue = function(list, value, separator) {
  value = decodeHtml(value);
  list = decodeHtml(list);
  
  separator = separator || ",";
  var values = list.split(separator);
  for(var i = 0 ; i < values.length ; i++) {
    if(values[i] == value) {
      values.splice(i, 1);
      return values.join(separator);
    }
  }
  return list;
};

function decodeHtml(html) {
    var txt = document.createElement("textarea");
    txt.innerHTML = html;
    return txt.value;
}

var onAddSelectedItem = function($hiddenInput, itemValue){
	var currentValue = $hiddenInput.val();
	if (currentValue === 'All' || currentValue === '') {
		$hiddenInput.val(itemValue);
	} else {
		$hiddenInput.val(currentValue + '; ' + itemValue);
	}
}

var openAdvancedSearch = function(searchDialogInstance, 
	advancedSearchContainerId, 
	advancedSearchIframeId) {
    
    if(searchDialogInstance !== undefined) {
        searchDialogInstance.dialog( "destroy" );
    }

    var theIFrame = j$("[id$=" + advancedSearchIframeId + "]")[0];

    searchDialogInstance = j$("[id$=" + advancedSearchContainerId + "]").dialog({
        autoOpen: true,
        modal: true,
        resizable: true,
        width: .8 * j$(window).width(),
        height: .8 * j$(window).height(),
        open: function(){ 
            resizeIframe(theIFrame); 
        }
    });

    searchDialogInstance.find(".modal-dialog-close").on("click", function() {
        searchDialogInstance.dialog('close');
    });

    openingPopup = true;
    searchDialogInstance.dialog("open");
    return searchDialogInstance;
};

function resizeIframe(obj) {
    if(openingPopup) {
        obj.style.height = .8 * j$(window).height() + 'px';
        
        resizeScrollableData(j$("[id$=" + obj.id + "]")[0], 
                                        .8 * j$(window).height());
        openingPopup = false;
    }
}

function resizeScrollableData(iframe, dialogHeight) {
	/*
		total heights of following:
			.advanced-search-container
			.data-controls
			.product-search-header

		Subtract total heights from height of dialog and set height on class "scrollable-data"
	*/
	var form = iframe.contentWindow.document.body.getElementsByTagName("form"),
		$iframeForm = j$(form),
		height1 = $iframeForm.find(".advanced-search-container").outerHeight(true),
		height2 = 0,
		height3 = $iframeForm.find(".product-search-header").outerHeight(true);

	$iframeForm.find(".data-controls").each(function() { 
		height2 += j$(this).outerHeight(true);
	});

	scrollableAreaHeight = (dialogHeight - (height1 + height2 + height3 + 39));

	$iframeForm.find(".scrollable-data").height(scrollableAreaHeight);

	iframe.style.height = dialogHeight + "px";
}

(function() {

	j$(document).ready(function() {
		optionController(j$, ".option-search-control");
		cardControl(j$, ".card .cancel-btn");

		j$('.section .collapsible').click(function() {
			var $head = j$(this);
			j$(this).next().toggle(300, function() {
				var isVisible = j$(this).is(':visible');

				// animation complete
				if(isVisible) {
					// is hidden, on animation completion change font awesome arrow icon to facing down
					$head.find(".fa").attr('class', 'fa fa-caret-down');
				} else {
					// is visible, on animation completion change font awesome arrow icon to facing right
					$head.find(".fa").attr('class', 'fa fa-caret-right');
				}
			});
			return false;
		});

		/* START advanced search popup */

		// advanced products search
		j$('.advanced-search-products').click(function() {
        	var dialog = j$("#dialog").dialog({
	            autoOpen: false,
	            modal: true,
	            open: function(ev, ui) {
	            	
	            	resizeScrollableData(document.getElementById("myIframe"), 
	            						.8 * j$(window).height());
	            }
	        });

			j$('#myIframe').attr('src','apex/promotionsproductssearch');
			openingPopup = true;
        });

        /* END advanced search popup */

	});

	function optionController(j$, parentController) {
		var jqController = j$(parentController);

		jqController.each(function() {
			j$(this).find('.controller select').on("change", function() { 
				// display viewDiv
				viewDiv = j$(this).closest(parentController).children('.view');

				var selectedOptionText = j$(this).find("option:selected").text();
				viewDiv.find("input").attr("placeholder", "Search and Add " + selectedOptionText);
				viewDiv.show();

			});
		});
	}

	function cardControl(j$, cardCancelBtnSelector) {
		j$(cardCancelBtnSelector).on("click", function() {
			var $card = j$(this).parent();
			alert("removing card: " + $card.data("accountValue"));
			$card.remove();
		});
	}

}());

function searchControl(j$, searchController) {
	var jqSearchController = j$(searchController);
	jqSearchController.each(function() {
		
		$currentControl = j$(this).find('input');
		
		var searchActive = function($this) {
			$this.closest('.search').find('i.fa-search').hide();
			$this.closest('.search').find('.spy-glass .cancel-btn').attr("style", "display:inline-block");
		};

		var searchInactive = function($this) {
			$this.closest('.search').find('.spy-glass .cancel-btn').hide();
			$this.closest('.search').find('i.fa-search').show();
		};

		var textChangeEvent = function() {
			$this = j$(this);
			if($this.val() !== "") {
				searchActive($this);
			} else {
				searchInactive($this);
			}
		};

		// user starts typing in search text box
		$currentControl.on("keyup", textChangeEvent);
		$currentControl.on("change", textChangeEvent);

		$currentControl.on("focus", function() {
			var $this = j$(this);
			if($this.closest('.search').find('input').val() !== "") {
				searchActive($this);
			}
		});

		$currentControl.on("blur", function() {
			var $this = j$(this);
			if($this.closest('.search').find('input').val() === "") {
				searchInactive($this);
			}
		});

		// cancel icon click event
		j$(this).find('.spy-glass .cancel-btn').on("click", function() {
			var $this = j$(this);
			$this.closest('.search').find('input').val("");
			searchInactive($this);
		});
	});
}

/*
 *  Project: Incentives
 *  Description: Validates expression criteria ensuring that all row numbers are included
 *  and that correct syntax is used.
 *  Dependencies: jQuery 
 *  Author: Apttus - Ian Gallagher
 *  License: Copyright Apttus 2016
 */

;(function ( $, window, document, undefined ) {

    var pluginName = 'criteriaExprValidator';

    // The actual plugin constructor
    function criteriaExprValidator( element, options ) {
        this.element = element;

        // jQuery has an extend method which merges the contents of two or
        // more objects, storing the result in the first object. The first object
        // is generally empty as we don't want to alter the default options for
        // future instances of the plugin

        this.options = $.extend({
            criteriaRulesCount: 1,
            renderErrors: true,
            errMsgMalformed: "Criteria expression is malformed",
            errMsgCriteriaRowDoesNotExist: "Criteria row number '{0}' does not exist",
            errMsgIncorrectParenthesisCount: "Incorrect number of parenthesis. Contains '{0}' left parenthesis and '{1}' right parenthesis.",
            errMsgIncorrectBracketCount: "Incorrect number of brackets. Contains '{0}' left brackest and '{1}' right brackets.",
            errMsgIncorrectCurlyCount: "Incorrect number of curly braces. Contains '{0}' left curly braces and '{1}' right curly braces.",
            errMsgRowNumberMissing: "Criteria row number '{0}' missing from expression.",
            errMsgContCssClass: "criteriaexprvalidator-error-msg-cont",
            criteriaExprInputCssClass: "criteriaexprvalidator-validationerror",
            onValidationComplete: function() {}
        }, options);

        this.init();
    }

    /** @constructor */
    criteriaExprValidator.prototype.init = function () {
        var widget = this,
            $inpCriteriaExpr = $(widget.element),
            errorMsgContMarkup = "<ul class='" + widget.options.errMsgContCssClass + "'></ul>";
            
        widget.$errorMsgCont = $(widget.element).after(errorMsgContMarkup).next();

        var _validateExprCriteria = function() {
            widget.validate();
        };
        
        $inpCriteriaExpr.on("keyup", _validateExprCriteria);

        widget.validate();
    };

    criteriaExprValidator.prototype.validate = function () {
        var errors = this._validateExpression($(this.element).val(), this.options.criteriaRulesCount);

        if(this.options.renderErrors) {
            this._handleResult(errors);
        }
        
        this.options.onValidationComplete.call(this, errors);

        return errors;
    };

    // validation method
    criteriaExprValidator.prototype._validateExpression = function(expr, numberOfRows) {
        var cleanedExpr = "",
            reg = /^\d+(?:\s+(?:AND|OR)\s+\d+)*\s*/gi,
            leftParen = 0,
            rightParen = 0,
            leftBracket = 0,
            rightBracket = 0,
            leftCurly = 0,
            rightCurly = 0,
            operand = "",
            operandValues = [],
            errors = [],
            requiredValues = [];
        
        for(var i = 1; i <= numberOfRows; i++) {
          requiredValues.push(i);
        }
        
        for (var i = 0; i < expr.length; i++) {
            var currentChar = expr.charAt(i);

            if(!isNaN(parseInt(currentChar))) {
                // is numeric character
                operand += currentChar;
            } else if(operand.length > 0) {
                // finished reading number, add to list
                operandValues.push(operand);
                operand = "";
            }
            
            switch(currentChar) {
              case '(': leftParen++; break;
              case ')': rightParen++; break;
              case '[': leftBracket++; break;
              case ']': rightBracket++; break;
              case '{': leftCurly++; break;
              case '}': rightCurly++; break;
              default: cleanedExpr = cleanedExpr.concat(currentChar);
            }
        }
        
        if(operand.length > 0) {
          operandValues.push(operand);
        }
        
        // duplicate check using jQuery? jQuery.inArray( 2, arr ) (returns -1 if not found)
        for(var i = 0; i < operandValues.length; i++) {
          var rowNumber = parseInt(operandValues[i]);
          if(rowNumber > numberOfRows || rowNumber <= 0) { // invalid row number
            errors.push({ code: 2, detail: operandValues[i] });
          }
          
          // remove value from required list of criteria expression values
          requiredValues = jQuery.grep(requiredValues, function( n, i ) { return ( n !== rowNumber ); });
        }
        
        // not all criteria values included in expression
        if(requiredValues.length > 0) {
            for(var i = 0; i < requiredValues.length; i++) {
                errors.push({ 
                    code: 6, 
                    detail: requiredValues[i]
                  });
            }
        }
        
        if(leftParen != rightParen) {
            errors.push({ 
                  code: 3, 
                  detail: { leftCount: leftParen, 
                            rightCount: rightParen } 
                  
                });
        }
        
        if(leftBracket != rightBracket) {
            errors.push({ 
                  code: 4, 
                  detail: { leftCount: leftBracket, 
                            rightCount: rightBracket } 
                  
                });
        }
        
        if(leftCurly != rightCurly) {
            errors.push({ 
                  code: 5, 
                  detail: { leftCount: leftCurly, 
                            rightCount: rightCurly } 
                  
                });
        }
        
        cleanedExpr = cleanedExpr.replace(reg, "");
        if (cleanedExpr.length) {
          errors.push({ 
              code: 1
            });
        }
        
        return errors;
    };

    criteriaExprValidator.prototype._addErrorMsg = function(errorMsg) {
        this.$errorMsgCont.append('<li>' + errorMsg + '</li>');
    };
    
    criteriaExprValidator.prototype._handleResult = function(errors) {
        
        this.$errorMsgCont.empty();
        
        if(errors.length > 0) {
            this.$errorMsgCont.show();
            $(this.element).addClass(this.options.criteriaExprInputCssClass);
        } else {
            this.$errorMsgCont.hide();
            $(this.element).removeClass(this.options.criteriaExprInputCssClass);
        }
                
        for (var i = 0; i < errors.length; i++) {
            switch(errors[i].code) {
                case 1:
                    this._addErrorMsg(this.options.errMsgMalformed);
                    break;
                case 2:
                    this._addErrorMsg(this.options.errMsgCriteriaRowDoesNotExist
                        .replace(/\{0\}/g, errors[i].detail));
                    break;
                case 3:
                    this._addErrorMsg(this.options.errMsgIncorrectParenthesisCount
                        .replace(/\{0\}/g, errors[i].detail.leftCount)
                        .replace(/\{1\}/g, errors[i].detail.rightCount));
                    break;
                case 4:
                    this._addErrorMsg(this.options.errMsgIncorrectBracketCount
                        .replace(/\{0\}/g, errors[i].detail.leftCount)
                        .replace(/\{1\}/g, errors[i].detail.rightCount));
                    break;
                case 5:
                    this._addErrorMsg(this.options.errMsgIncorrectCurlyCount
                        .replace(/\{0\}/g, errors[i].detail.leftCount)
                        .replace(/\{1\}/g, errors[i].detail.rightCount));
                    break;
                case 6:
                    this._addErrorMsg(this.options.errMsgRowNumberMissing
                        .replace(/\{0\}/g, errors[i].detail));
                    break;
            }
        }
        
        

    };

    // Constructor preventing against multiple instantiations and allowing any
    // public function (ie. a function whose name doesn't start
    // with an underscore) to be called via the jQuery plugin,
    // e.g. $(element).criteriaExprValidator('functionName', arg1, arg2)
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
                    $.data(this, 'plugin_' + pluginName, new criteriaExprValidator( this, options ));
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
                if (instance instanceof criteriaExprValidator && typeof instance[options] === 'function') {

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
/**
 *	Apttus Config & Pricing
 *	cpq.js
 *	 
 *	@2012-2013 Apttus Inc. All rights reserved.
 * 
 */

var j$ = jQuery.noConflict();
j$.APTTUS = {};
j$.APTTUS.cp_cERROR_UNKNOWN = "ERROR: Unknown error:\n";
if(typeof j$.APTTUS.currencyTemplate === 'undefined'){
	j$.APTTUS.currencyTemplate ='';
}

j$(function() {
	if(j$.aptActionFunctionQueue) {
	 // set global variables for behavior in queue
	 j$.aptActionFunctionQueue.setPrecedence(j$.APTTUS.showRulePrompt, -80);	// show rule prompt after all other processes have happend
	 j$.aptActionFunctionQueue.setSkipToEndOfQueue(j$.APTTUS.showRulePrompt);
	}
	
});


/**
 * Adjusts the currency/decimal fields, taking into account the Locale of the ORG
 * @return void
 */
j$.APTTUS.formatFields = function (currencyFieldPrecision, percentageFieldPrecision, quantityFieldPrecision){
	var currencyPrecision = parseInt(currencyFieldPrecision);
	var percentagePrecision = parseInt(percentageFieldPrecision);
	var quantityPrecision = parseInt(quantityFieldPrecision);

	if (currencyPrecision > 0) {
		currencyPrecision ++;

	} else if (currencyPrecision < 0) {
		currencyPrecision = 0;

	} 

	if (percentagePrecision > 0) {
		percentagePrecision ++;

	} else if (percentagePrecision < 0) {
		percentagePrecision = 0;

	}

	if (quantityPrecision > 0) {
		quantityPrecision ++;

	} else if (quantityPrecision < 0) {
		quantityPrecision = 0;

	}
	
	//remove extra decimal from percentage field
	j$("[class^=aptPercentage], [class*=aptPercentage]").each(function(){
	
		var re = new RegExp("\\.\\d{3,}%"); 
		var re2 = new RegExp("\\.\\d{3,}$"); 
		var re3 = new RegExp(",\\d{3,}%");
		var re4 = new RegExp(",\\d{3,}$"); 
		if (j$(this).is("input")) {
			var matches2 =re2.test(j$(this).val());
			var matches4 = re4.test(j$(this).val());
			if(!(j$(this).hasClass('formatted'))){
				if (matches2) {
					j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(".") + percentagePrecision));
					j$(this).addClass('formatted');

				} else if (matches4) {
					j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(",") + percentagePrecision));
					j$(this).addClass('formatted');

				}

				
			}
			
		} else {

			j$(this).children().each(function(){
				var matches =re.test(j$(this).html());
				var matches3 = re3.test(j$(this).html());
				var matches2 =re2.test(j$(this).html());
				var matches4 = re4.test(j$(this).html());
				if(!(j$(this).hasClass('formatted'))){
					if (matches) {
						j$(this).html(j$(this).html().replace("%",""));
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + percentagePrecision) + "%");
						j$(this).addClass('formatted');

					} else if (matches3) {
						j$(this).html(j$(this).html().replace("%",""));
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + percentagePrecision) + "%");
						j$(this).addClass('formatted');

					} else if (matches2) {
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + percentagePrecision));
						j$(this).addClass('formatted');

					} else if (matches4) {
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + percentagePrecision));
						j$(this).addClass('formatted');

					}

					
				}

			})

		}

	});

	// check if the decimal places are rendered on the dummy line item.
	// Introduced to fix a bug with Japanese currency where the decimal places
	// are not rendered in multicurrency orgs causing the formatting script 
	// to trim the values incorrectly.
	// Value of currencyTempalte set to "None" by CartHeader2.component		
	if(j$.APTTUS.currencyTemplate === "None" || j$.APTTUS.currencyTemplate.indexOf("56") !== -1){
		//remove extra decimal values from currency field
		j$("[class^=aptCurrency], [class*=aptCurrency]").each(function(){
			
			var re = new RegExp("\\.\\d{3,}$"); // currency at start of string and "."" is decimal separator
			var re2 = new RegExp("\\.\\d{3,} \\D+$"); // currency at end of string and "."" is decimal separator
			var re3 = new RegExp(",\\d{3,}$"); // currency at start of string and "," is decimal separator
			var re4 = new RegExp(",\\d{3,} \\D+$"); // currency at end of string and "," is decimal separator
			var negativeCurrency = false;
			var tempValue = j$(this).val();
			
			if (j$(this).is("input")) {
				if(!(j$(this).hasClass("formatted"))){
					if (tempValue.indexOf("(") == 0) {
						negativeCurrency = true ;
						tempValue = tempValue.replace("(","");
						tempValue = tempValue.replace(")","");
	
					} else if (tempValue.indexOf("(") != -1) {
						var multiCurrencySection = tempValue.substring(tempValue.indexOf("(")-1,tempValue.length);
						tempValue = tempValue.replace(multiCurrencySection,"");
	
					}
					
					var matches = re.test(tempValue);
		    		var matches2 = re2.test(tempValue);
		    		var matches3 = re3.test(tempValue);
		            var matches4 = re4.test(tempValue);
	
		            if (matches || matches2 || matches3 || matches4) {
		            	j$(this).val(tempValue);
		            	j$(this).addClass("formatted");
	
		            }
	
		    		//check if string matches a decimal format with currency symbol in the beginning 
		    		//and the decimal separator is .
		    		if (matches) {
		    			var matchedGroups = re.exec(j$(this).val());
		    			var filtered =  j$(this).val().replace(matchedGroups[0],"");
		    			var decimalPortion = matchedGroups[0].substring(0,currencyPrecision); 
		    			j$(this).val(filtered + decimalPortion);
		    			//check if value is a negative value the add closing parenthesis
						if(negativeCurrency){
		    				j$(this).val("(" + j$(this).val() + ")");
	
		    			}
	
		   			}
		   			//check if string matches a decimal format with currency symbol in the end
		   			//and the decimal separator is .
		   			else if (matches2){
		   				var currencySymbolRE = new RegExp("\\D+$");
		   				var matchedGroups = re2.exec(j$(this).val());
		    			var filtered =  j$(this).val().replace(matchedGroups[0],"");
		    			var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
		    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
		    			decimalPortion = decimalPortion.replace(currencySymbol[0], "");
		    			j$(this).val(filtered + decimalPortion + currencySymbol[0]);
		    			//check if value is a negative value the add closing parenthesis
						if(negativeCurrency){
		    				j$(this).val("(" + j$(this).val() + ")");
	
		    			}
	
		    		}
		    		//check if string matches a decimal format with currency symbol in the beginning 
		    		//and the decimal separator is ,
		   			else if (matches3){
		   				var matchedGroups = re3.exec(j$(this).val());
		    			var filtered =  j$(this).val().replace(matchedGroups[0],"");
		    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
		    			j$(this).val(filtered + decimalPortion);
		    			//check if value is a negative value the add closing parenthesis
						if(negativeCurrency) {
		    				j$(this).val("(" + j$(this).val() + ")");
	
		    			}
	
		   			}
		   			//check if string matches a decimal format with currency symbol in the end
		   			//and the decimal separator is ,
		   			else if (matches4) {
		   				var currencySymbolRE = new RegExp("\\D+$");
		   				var matchedGroups = re4.exec(j$(this).val());
		    			var filtered =  j$(this).val().replace(matchedGroups[0],"");
		    			var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
		    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
		    			decimalPortion = decimalPortion.replace(currencySymbol[0], "");
		    			j$(this).val(filtered + decimalPortion + currencySymbol[0]);
		    			//check if value is a negative value the add closing parenthesis
						if(negativeCurrency){
		    				j$(this).val("(" + j$(this).val() + ")");
	
		    			}
	
		    		}
	
		    	}
	
			} else {
				j$(this).children('span').each(function(){
					if(!(j$(this).hasClass("formatted"))){
		         		var negativeCurrency = false;
		         		var tempValue = j$(this).html();
	
		         		if(tempValue.indexOf("(") == 0) {
							negativeCurrency = true ;
							tempValue = tempValue.replace("(","");
							tempValue = tempValue.replace(")","");
	
						} else if (tempValue.indexOf("(") != -1) {
							var multiCurrencySection = tempValue.substring(tempValue.indexOf("(")-1, tempValue.length);
							tempValue = tempValue.replace(multiCurrencySection,"");
	
						}
						
		          		var matches = re.test(tempValue);
			    		var matches2 = re2.test(tempValue);
			    		var matches3 = re3.test(tempValue);
			            var matches4 = re4.test(tempValue);
	
			            if (matches || matches2 || matches3 || matches4) {
			            	j$(this).html(tempValue);
			            	j$(this).addClass("formatted");
	
			            }
	
			    		//check if string matches a decimal format
			    		if (matches) {
			    			var matchedGroups = re.exec(j$(this).html());
			    			var filtered =  j$(this).html().replace(matchedGroups[0],"");
			    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
			    			j$(this).html(filtered + decimalPortion);
			    			//check if value is a negative value the add closing parenthesis
							if(negativeCurrency){
			    				j$(this).html("(" + j$(this).html() + ")");
	
			    			} 
			    			
			   			} else if (matches2) {
			   				var currencySymbolRE = new RegExp("\\D+$");
			   				var matchedGroups = re2.exec(j$(this).html());
			    			var filtered =  j$(this).html().replace(matchedGroups[0],"");
			    			var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
			    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision);
			    			decimalPortion = decimalPortion.replace(currencySymbol[0], ""); 
			    			j$(this).html(filtered + decimalPortion + currencySymbol[0]);
			    			//check if value is a negative value the add closing parenthesis
							if (negativeCurrency){
			    				j$(this).html("(" + j$(this).html() + ")");
	
			    			}
	
			    		} else if (matches3) {
			   				var matchedGroups = re3.exec(j$(this).html());
			    			var filtered =  j$(this).html().replace(matchedGroups[0],"");
			    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
			    			j$(this).html(filtered + decimalPortion);
			    			//check if value is a negative value the add closing parenthesis
							if (negativeCurrency) {
			    				j$(this).html("(" + j$(this).html() + ")");
			    			
			    			}
	
			   			} else if (matches4) {
			   				var currencySymbolRE = new RegExp("\\D+$");
			   				var matchedGroups = re4.exec(j$(this).html());
			    			var filtered =  j$(this).html().replace(matchedGroups[0],"");
			    			var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
			    			var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
			    			decimalPortion = decimalPortion.replace(currencySymbol[0], "");
			    			j$(this).html(filtered + decimalPortion + currencySymbol[0]);
			    			//check if value is a negative value the add closing parenthesis
							if(negativeCurrency){
			    				j$(this).html("(" + j$(this).html() + ")");
	
			    			}
	
			    		}
	
			    	}
	
				})
	             	
			}
		});
	}
	//remove decimal values from quantity field
	j$("[class^=aptQuantity], [class*=aptQuantity]").each(function(){
       	var re = new RegExp("\\.\\d{3,}$");
		var re3 = new RegExp(",\\d{3,}$");
		
		if(j$(this).is("input")){
			var matches =re.test(j$(this).val());
			var matches3 = re3.test(j$(this).val());
       		if(!(j$(this).hasClass('formatted'))){
           		if (matches) {
					j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(".") + quantityPrecision));
					j$(this).addClass('formatted');

				} else if (matches3) {
					j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(",") + quantityPrecision));
					j$(this).addClass('formatted');

				}

				
       		
       		}
      	} else {
      		var matches =re.test(j$(this).html());
			var matches3 = re3.test(j$(this).html());
   			if(!(j$(this).hasClass('formatted'))){
   				if (matches) {
					j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + quantityPrecision));
					j$(this).addClass('formatted');

				} else if (matches3) {
					j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + quantityPrecision));
					j$(this).addClass('formatted');
					
				}
			
			}
      		
       		j$(this).children().each(function(){
       			var matches =re.test(j$(this).html());
				var matches3 = re3.test(j$(this).html());
       			if(!(j$(this).hasClass('formatted'))){
       				if (matches) {
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + quantityPrecision));
						j$(this).addClass('formatted');

					} else if (matches3) {
						j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + quantityPrecision));
						j$(this).addClass('formatted');
						
					}

                 }

       		})


       		

       	}

	}); 

}

/**
 * Appliesthe appropriate classe to the adjustment amount fields based on the adjustment type
 * @return void
 */
j$.APTTUS.applyDynamicClasses = function (JQueryObject){
	var selectorClass = JQueryObject.attr('class');
	var amountClass = selectorClass.replace("Type","");
	// clear previous classes
	j$('.' + amountClass).removeClass('aptPercentage');
	j$('.' + amountClass).removeClass('aptCurrency');
	j$('.' + amountClass).removeClass('aptQuantity');
	j$('.' + amountClass).removeClass('formatted');
	if (j$('.' + selectorClass).is("select")) {
		if (j$('.' + selectorClass + ' option:selected').val().indexOf('%') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptPercentage');

			})

		} else  if (j$('.' + selectorClass + ' option:selected').val().indexOf('Discount Amount') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptCurrency');

			})

		} else  if (j$('.' + selectorClass + ' option:selected').val().indexOf('Markup Amount') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptCurrency');

			})

		} else  if (j$('.' + selectorClass + ' option:selected').val().indexOf('Price Override') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptCurrency');

			})

		} else  if (j$('.' + selectorClass + ' option:selected').val().indexOf('Base Price Override') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptCurrency');

			})

		} else  if (j$('.' + selectorClass + ' option:selected').val().indexOf('Price Factor') !== -1) {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptQuantity');

			})

		} else {
			j$('.' + amountClass).each(function(){
				j$(this).addClass('aptCurrency');

			})

		}

	} else {
		selectionString = j$(j$('.' + selectorClass).children('span')[0]).html();
		if (selectionString != null) {
			if (selectionString.indexOf('%') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptPercentage');

				})

			} else if (selectionString.indexOf('Discount Amount') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptCurrency');

				})

			} else if (selectionString.indexOf('Markup Amount') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptCurrency');

				})

			} else if (selectionString.indexOf('Price Override') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptCurrency');

				})

			} else if (selectionString.indexOf('Base Price Override') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptCurrency');

				})

			} else if (selectionString.indexOf('Price Factor') !== -1) {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptQuantity');

				})

			} else {
				j$('.' + amountClass).each(function(){
					j$(this).addClass('aptCurrency');

				})

			}

		}
		

	}

}

/**
 * Update the price for the entire cart
 * Invoked via "Update Price" button.
 */
j$.APTTUS.invokeUpdatePriceForCart = function (button) {      
    if(button !== undefined) {
        startSpinner('.apt-button-action-spinner img', button); 
    }
    
    disableInputsAndButtons(true);
    doUpdatePriceForCart(j$.APTTUS.configurationId, function(){ disableInputsAndButtons(false);
                                                                    if(button !== undefined) {
                                                                           stopSpinner(button);
                                                              }
                                                                                
                                                    });
}

/**
 * Does click on given html element on press of enter button.
 * @param elem html element object
 * @return void
 */
j$.APTTUS.onPressEnterClickElement = function (event, elem){
	if(event.keyCode==13) {
		elem.trigger('click');
		
	}
}

/**
 * Handle the escape action for rule message
 * prompt
 * @param e the event
 */
 j$.APTTUS.rulePromptEscapHandler = function(e) {	 
	  if (e.keyCode == 27) { 

	  	if (e.stopPropagation) {
	        // In firefox, this is what keeps the escape key from canceling the history.back()
	        e.stopPropagation();
	        e.preventDefault();
	    }

	    // Hide message prompt
	    j$.APTTUS.hideRulePrompt();

	    // Invoke cancel action
	  	j$('.aptCancelButton').trigger('click');
     }
 };

 /**
  * Show choice dialog
  * @param lineNumber the line number to delete
  */
 j$.APTTUS.showRulePrompt = function () {

 	if(j$.APTTUS.rulePromptDialog && j$.APTTUS.rulePromptDialog.dialog("isOpen") ) {
 		return; // do nothing if already opened

 	}

 	if (j$.aptActionFunctionQueue) {
 		j$.aptActionFunctionQueue.updateSetting('isQueuePaused', true);
 	}
 	
 	// Create and open dialog window
 	j$.APTTUS.rulePromptDialog = 
	 	j$("#choicePanel").dialog({
	 		dialogClass: "no-close",
	 		autoOpen: true,
	 		width: 600,
	 		resizable: false,
	 		modal: true,
	 		position: 'center',
	 		draggable: true,
	 		title : j$.APTTUS.constraintRuleAlertLabel
	 	});
 	
 	// Hide dialog when escape key is pressed
 	j$(document).bind('keyup', j$.APTTUS.rulePromptEscapHandler);
 	
 	return false;
 	
 }
 
/**
 * Hide the rule prompt dialog
 */
j$.APTTUS.hideRulePrompt = function() {
	// close the choice dialog
	if (j$.aptActionFunctionQueue) {
 		if(j$.aptActionFunctionQueue.updateSetting('isQueuePaused', false)) { 
			j$.aptActionFunctionQueue.processNext(); // only process next if queue was paused
		}
 	}
 	
	if(typeof j$.APTTUS.rulePromptDialog !== 'undefined') {
		j$.APTTUS.rulePromptDialog.dialog("close");
	}

	// Unbind escape handler
	j$(document).unbind('keyup', j$.APTTUS.rulePromptEscapHandler);
	
}

/**
 * Show remove confirmation dialog
 * @param lineNumber the line number to delete
 */
j$.APTTUS.showRemoveConfirmation = function(lineNumber) { 	
  	// store the line number in the global namespace
  	j$.APTTUS.LineNumber = lineNumber;

  	// Create and open dialog window
  	j$.APTTUS.removeConfirmationDialog = 
	 	j$("#confirmationPanelJQuery").dialog({
	 		dialogClass: "no-close confirmationPanelJQuery",
	 		autoOpen: true,	 			 		
	 		resizable: false,
	 		modal: true,
	 		position: 'center',
	 		draggable: true,
	 		title : j$.APTTUS.removeConfirmationLabel,
	 		create : function(){
	 			j$('.confirmationPanelJQuery .ui-widget-header').css({border:"none",background:"none",borderBottom:"1px solid #aaaaaa"});
	 			j$('.confirmationPanelJQuery .ui-widget-header').removeClass("ui-corner-all");
	 		}
	 	});
  	
  	return false;
  	
 }

/**
 * Hide the remove confirmation dialog
 */
j$.APTTUS.hideRemoveConfirmation = function () {
	// close the confirmation dialog
	if(typeof j$.APTTUS.removeConfirmationDialog !== 'undefined') {
		j$('.aptRemoveLineItemSpinner').hide();
		j$.APTTUS.removeConfirmationDialog.dialog("close");
	}

}

/**
  * Show abandon choice dialog
  * @param lineNumber the line number to delete
  */
 j$.APTTUS.showAbandonConfirmationDialog = function () {
 	// Create and open dialog window
 	j$.APTTUS.abandonConfirmationDialog = 
	 	j$("#abandonConfirmationPanel").dialog({
	 		dialogClass: "no-close abandonConfirmationPanel",
	 		autoOpen: true,
	 		resizable: false,
	 		modal: true,
	 		position: 'center',
	 		draggable: true,
	 		title : j$.APTTUS.abandonConfirmationLabel,
	 		create : function(){
	 			j$('.abandonConfirmationPanel .ui-widget-header').css({border:"none",background:"none",borderBottom:"1px solid #aaaaaa"});
	 			j$('.abandonConfirmationPanel .ui-widget-header').removeClass("ui-corner-all");
	 		}
	 	});
 	
 	return false;

 	
 }
 
/**
 * Hide the rule prompt dialog
 */
j$.APTTUS.hideAbandonConfirmationDialog = function() {
	// close the choice dialog

	if(typeof j$.APTTUS.abandonConfirmationDialog !== 'undefined') {
		j$.APTTUS.abandonConfirmationDialog.dialog("close");
	}
	
}

j$.APTTUS.escapeId = function(myid) {
   return '#' + myid.replace(/(:|\.)/g,'\\\\$1');
}  

/**
 * create popup window
 * @param urlOrContent url address or embed content
 * @param header header text on popup window
 * @content content of the popup window, when this has value url should be blank
 */
j$.APTTUS.aptCreatePopup = function(urlOrContent, header, isEmbed) {
	if(urlOrContent=='' || urlOrContent=='null'){
		return false;
	}
	var url = isEmbed ? '' : urlOrContent;
	
	var pop1 = window.open(url, 'apttusPopup', 'menubar=1,resizable=1,width=712,height=500');
	if(isEmbed){
	  	pop1.document.write('<html><head><title>Apttus</title></head>');
	  	pop1.document.write('<body><center><h3>'+header+'</h3>');
	  	pop1.document.write(urlOrContent);
	  	pop1.document.write('</center></body></html>');
  	}
  	if(window.focus){
  		pop1.focus();
  	}
}


/**
 * Igonore enter key press
 */
j$.APTTUS.aptIgnoreEnterKey = function(event, callback){ 
	var keyCode; 
	if (event && event.which) { 
		// Use for Firefox and Chrome 
		keyCode = event.which; 

	} else { 
		// Use for IE 
	    keyCode = event.keyCode;

	}
	var tagName = (event.target || event.srcElement).tagName.toUpperCase(); //IE doesn't pass event.target
	if (keyCode == 13 && tagName != 'TEXTAREA') { 
		if(callback){
			callback();
		}

		return false; 
	}
	return true; 
}

j$.APTTUS.cp_erroralert = function(msg,exception) {    
	try {
        var emsg = null;
        var efld = null;
        var estc = null;
        var etid = null;

        try {
            var hasErrors = (exception.errors!=null);
            var hasFault = (exception.faultcode!=null);
            //alert("hasErrors="+hasErrors+"\nhasFault="+hasFault);

            if (hasErrors) {
                emsg = exception.errors.message;
                efld = exception.errors.fields;
                estc = exception.errors.statusCode;

            } else if (hasFault) {
                emsg = exception.faultcode;
                efld = exception.faultstring;
                
            } else {
                emsg = exception.message;
                efld = exception.fields;
                estc = exception.statusCode;
            }
            
        } catch(ex) {
            emsg = exception.errors.message;
            efld = exception.errors.fields;
            estc = exception.errors.statusCode;
        }

        var estr = msg;
        var estrdb = estr;
        
        if (emsg!=null && emsg!="") {
            estr += "\nmessage: "+emsg;
            estrdb += "<br>message: "+emsg;
        }
        if (efld!=null && efld!="") {
            estr += "\nfields: "+efld;
            estrdb += "<br>fields: "+efld;
        }
        if (estc!=null && estc!="") {
            estr += "\nstatusCode: "+estc;
            estrdb += "<br>statusCode: "+estc;
        }
        if (etid!=null && etid!="") {
            estr += "\ntargetObjectId: "+etid;
            estrdb += "<br>targetObjectId: "+etid;
        }
        
        alert(estr);
        
    } catch(ex) {
        alert(msg+"\n"+exception);
    }
    
}

/**
 * Escape SFDC style Id's
 *
 * @return escaped id
*/
j$.APTTUS.esc = function ( myid ) {
  return "#" + myid.replace( /(:|\.|\[|\])/g, "\\$1" );
}

/**
 * Pad page content from away 
 * from fixed header and footer 
*/
j$.APTTUS.padContent = function() {
	if(j$.APTTUS.isFixedButtonBar) {
		var h = j$(".apt-page-header").outerHeight();
	    var f = j$(".apt-page-footer").outerHeight();

	    j$('.apt-page-content').css('padding-top', h+5 + 'px');
	    j$('.apt-page-content').css('padding-bottom', f+5 + 'px');

	}
}

/**
 * on load js for fixed button bar 
*/
j$(function() {
	if(j$.APTTUS.isFixedButtonBar) {
		j$.APTTUS.padContent();
		// bind to page load and resize
        j$(window).bind("load resize", function() {
            j$.APTTUS.padContent();               
        }); 
    } 
    
    j$('select[multiple!="multiple"]').wrap('<span class="apt-select-wrap"></span>');
    	
});

/**
 * On PageSize change for dropdown arrow
*/
j$.APTTUS.wrapSpan = function() {
    j$('select').wrap('<span class="apt-select-wrap"></span>');
}

//hide message and call doHideMessage function to update the appliedActionInfo record HideMessage field
function aptHideMessage(ele, actionInfoId){
    if(ele.parentNode != undefined){
        ele.parentNode.style.visibility = "hidden";
    }
    invokeDoHideMessage(actionInfoId);
}   

function populatePageButtons(isFixedButtonBar){
	j$.APTTUS.listMenuItemsCount = 0;
                                            
    j$('#stepMenu, #apt-helpIcon').hide();
    
    j$('.aptListButton[aptdisabled=true]').attr('disabled','true').addClass("aptButtonDisabled");

    j$('.allButtons li').each(function() {
    	
    	if(j$(this).attr('id') != 'More' 
			&& j$(this).children('input, a').attr('displayas')
			&& j$(this).children('input, a').attr('displayas').indexOf('Action') >= 0){
    		j$(this).addClass('aptSpinnerBtn');
    	}
    	
        if(j$(this).attr('id') == 'aptMoreListItem'){
            j$('#More').html(j$(this).html());
            
        }else if(j$(this).attr('id') == 'aptAbandonListItem'){
            if(!isFixedButtonBar){
                j$('.cartTable #aptAbandonBtn').remove();
                j$('.apt-headerPlacement').before(j$('.allButtons #aptAbandonBtn'));
            }
            
        }else{
        
            if(j$(this).children('input, a').attr('displayas')
                && j$(this).children('input, a').attr('displayas').indexOf('Action') >= 0){
            
                //fixed actions 
                if (isFixedButtonBar) {
                    if(j$(this).children('input, a').attr('actionarea') == 'Left'){
                        j$(this).clone().appendTo(j$('.leftPageButtons'));
                        
                    }else if(j$(this).children('input, a').attr('actionarea') == 'Right'){
                        j$(this).clone().appendTo(j$('.rightPageButtons'));
                        
                    }else if(j$(this).children('input, a').attr('actionarea') == 'Center'){
                        j$(this).clone().appendTo(j$('.centerPageButtons'));
                        
                    }else if(j$(this).children('input, a').attr('actionarea') ==  'More'){
                        j$(this).clone().appendTo(j$('.apt-moreDropDown'));
                        
                    }
                
                //old actions
                }else{
                    if(j$(this).attr('id') == 'More'){
                        j$(this).html(j$('#aptMoreListItem').html());
                    
                    }
                    
                    if(j$(this).children('input, a').attr('actionarea') ==  'More'){
                        j$(this).clone().appendTo(j$('.apt-moreDropDown'));
                    }else if(j$(this).attr('id') != 'Abandon'){
                        j$(this).clone().appendTo(j$('.centerPageButtons'));
                        j$(this).clone().appendTo(j$('#aptTopButtons'));
                    }
                    
                }
                
            }
            if(j$(this).children('input, a').attr('displayas')
                && j$(this).children('input, a').attr('displayas').indexOf('Task') >= 0){
                
                j$.APTTUS.listMenuItemsCount++;
                j$(this).clone()
                    .appendTo(j$('.taskPageButtons'))
                    .children('a').prepend(j$.APTTUS.listMenuItemsCount + '. ');
                j$('.apt-hamburger-icon').show();
                
            }else if(j$(this).children('input, a').attr('displayas')
                && j$(this).children('input, a').attr('displayas').indexOf('Link') >= 0){
                
                j$(this).clone().appendTo(j$('#apt-catalogLinks'));
                
            }else if(j$(this).children('input, a').attr('displayas')
                && j$(this).children('input, a').attr('displayas').indexOf('Help') >= 0){
                
                j$(this).clone().appendTo(j$('.apt-helpDropDown'));
                j$('#apt-helpIcon').show();
                
            }
            
        }

    });
    
    //add empty item to prevent collapse
    if (isFixedButtonBar) {
    	if(j$('.rightPageButtons li').length > 0){
    		j$('.rightPageButtons').addClass('apt-bottom-btn-divider');
    	}
        j$('.leftPageButtons, .rightPageButtons, .centerPageButtons').append('<li>&nbsp;</li>');
    }
    
    j$('a.aptListButton').each(function(){j$(this).removeAttr('href');});
    
    j$('.aptSpinnerBtn a[onclick*="invoke"]').on('click',function() {
		startSpinner('.apt-button-action-spinner img', this);
		
	});
}
var genSpinnerCount = 0;
function showGeneralSpinner(loadingLabel){
	newSpinnerHtml = '<div id="genSpinner'+genSpinnerCount+'" class="apt-gen-spinner"><img src="/img/loading.gif" alt="'+loadingLabel+'"/><span>'+loadingLabel+'</span></div>';
	j$('#aptGeneralSpinner').append(newSpinnerHtml);
	genSpinnerCount++;
	return genSpinnerCount - 1;
}
function removeGeneralSpinner(index){
	j$('#genSpinner'+index).remove();
	
}
function startSpinner(spinnerImgSelector, clickedElm){
	if(!j$(clickedElm).hasClass('aptButtonDisabled')){
		var newSpinner = j$(spinnerImgSelector).first().clone();
		j$(clickedElm).prepend(newSpinner);
	}
}
function stopSpinner(thisElem){		
	j$(thisElem).children('img').remove();
}
function openIframe(customPageURL){
    j$("#dialog").html(j$("<iframe />").attr("src", customPageURL).attr("width", "100%").attr("height", "100%"));
    j$('#dialog').dialog({
        width: j$(window).width()*0.8,
        height: j$(window).height()*0.8
    });
}
function startTopSpinner(loadingLabel){
	if('noLoading' !== loadingLabel){
		j$('.apt-gen-spinner').remove();
		newSpinnerHtml = '<div class="apt-gen-spinner"><img src="/img/loading.gif" alt="'+loadingLabel+'"/><span>'+loadingLabel+'</span></div>';
		j$('#aptGeneralSpinner').append(newSpinnerHtml);
	}
	
}

/**
 * Disable/Enable buttons on configure action
 * 
 * @param 	disable
 *			flag indicating whether to disable
 *			related fields or enable them
 */
function disableInputsAndButtons(disable) {
	toggleInputs(disable);
	toggleButtonsAndLinks(disable);

}

/**
 * Disable/Enable buttons on configure action
 * 
 * @param 	disable
 *			flag indicating whether to disable
 *			related fields or not
 */
function toggleButtonsAndLinks(disable) {	
	//toggle tree flag
	j$.APTTUS.isTreeEnabled = !disable;

	// Disable all inputs
	j$('.aptListButton').addClass('aptAllowDisable');
	j$('.aptCommandLink').addClass('aptAllowDisable');
	//Don't disable special buttons -- ToDo: generalize this
	j$('#Abandon .aptListButton').removeClass('aptAllowDisable');
	j$('#ValidateBundle .aptListButton').removeClass('aptAllowDisable');
	j$('#RemoveItem .aptListButton').removeClass('aptAllowDisable');
	j$('#More .aptMoreButton').removeClass('aptAllowDisable');
	
	//Toggle disable state
	j$('.aptAllowDisable').attr("disabled",disable); 
	j$('.aptAllowDisable').removeClass("aptButtonDisabled");
	var onClickStr = "highlightValidateButton(); return false; replaceThis; "
	if(disable) {
		j$('.aptAllowDisable').addClass("aptButtonDisabled");
		
		//add return false to avoid onclick from firing functions
		j$('.aptAllowDisable').each(function( index ) {
			j$(this).attr("onClick", onClickStr + j$(this).attr("onClick"));
		});
	}else{
		//remove return false to allow onclick to fire functions
		j$('.aptAllowDisable').each(function( index ) {
			j$(this).attr("onClick", j$(this).attr("onClick").replace(new RegExp('highlightValidateButton(.*)replaceThis; ', 'g'),""));
		});
		
	}

}

/**
 * Disable/Enable inputs
 * 
 * @param 	disable
 *			flag indicating whether to disable
 *			related fields or not
 */
function toggleInputs(disable) {	
	j$(':text').attr("disabled",disable); 
	j$('select').attr("disabled",disable); 
	j$('.apt-disabled-input').attr("disabled",true); 

}

/**
 * Apply a slight animation to validate button
 */
function highlightValidateButton() {
	var buttonElement = j$("#ValidateBundle");
	if (!buttonElement 
				|| !buttonElement.queue() 
				|| buttonElement.queue().length > 0) {
		return;
	}
	buttonElement.fadeTo(400, .1,'easeInOutCubic',
			function(){
				buttonElement.addClass('aptHighlight');
			})
		.fadeTo(600, 1, 'easeInOutCubic')
		.fadeTo(600, .4, 'easeInOutCubic')
		.fadeTo(600, 1, 'easeInOutCubic')
		.fadeTo(400, .1, 'easeInOutCubic',
			function(){
				buttonElement.removeClass('aptHighlight');
			})
		.fadeTo(400, 1, 'easeInOutCubic');
}

/**
 * Load the recommended products list
 */
j$.APTTUS.loadRecommendedProducts = function(container, selectedProducts, labels) {
	if(selectedProducts != ''
		&& j$.APTTUS.RemoteController.getRecommendedProducts != '' ) {

		Visualforce.remoting.Manager.invokeAction(
	 	j$.APTTUS.RemoteController.getRecommendedProducts,  
	 	JSON.parse(selectedProducts),
	 	function(result, event){	 		
		    if (event.status) { // process results
		    	container.html('');

		    	var recommendedProductsHTML = '<div style="float: left; padding: 4px;">';
		    	if(!result.length) {	// no products found
		    		recommendedProductsHTML+= '<div><label>' + labels.NoRecordsToDisplay + '</label></div>';

		    	} else { // has recommended products
		    		
		    		recommendedProductsHTML+= '<ul class="aptRecommendedProductsList">';				    		
		    		j$.each(result, function() {
		    			recommendedProductsHTML+='<li>';
		    			if(this.iconURL !== undefined) {
		    				recommendedProductsHTML+='<img  class="aptCartLineItemIcon" src="' + this.iconURL +'"/>'; 
		    			}
		    			
		    			recommendedProductsHTML += '<br/>';
		    			recommendedProductsHTML += '<a href="/' + this.Id + '">' + this.Name + '</a>';
		    			recommendedProductsHTML += '<br/><br/>';
		    			recommendedProductsHTML += '<a onclick="j$(\'.' + this.Id + '-selected\').hide(); invokeDoAddProductToCart(\'' + this.Id + '\');  j$(\'.' + this.Id + '-load\').show(); return false;" class="' + this.Id + '-selected aptListButton">';
		    			recommendedProductsHTML += labels.AddToCart + '</a>';
		    			recommendedProductsHTML += '<img class="' + this.Id + '-load" style="display:none;" src="/img/loading.gif"/>';
		    			recommendedProductsHTML += '</li>';
		    		});

		    		recommendedProductsHTML+= '</ul>';				    		
		    	} 

		    	recommendedProductsHTML+='</div>';

		    	// populate container
		    	container.html(recommendedProductsHTML);
		    }			        
		}, 
		{buffer:false, escape:true});
	} 
}

/**
 * format date
 */
function aptFormatDate(date) {
	var hours = date.getHours();
  	var minutes = date.getMinutes();
  	minutes = minutes < 10 ? '0' + minutes: minutes;
  	var sec = date.getSeconds();
  	sec = sec < 10 ? '0' + sec : sec;
   
  	var strTime = hours + ':' + minutes + ':' + sec;
  	//return date.getFullYear() + "/" + date.getMonth()+1 + "/" + date.getDate() +  " : " + strTime;
  	return strTime;
}
 
/**
 * show timing logs
 */
function aptShowLogs() {
	j$("#timeLine").css("visibility", "visible");
	for(var i = 0; i < j$.APTTUS.timeLogs.length; i++){
		var info = j$.APTTUS.timeLogs[i];
		document.getElementById("timeRows").innerHTML = document.getElementById("timeRows").innerHTML + '<tr><td style="width: 80px; text-align: right;">'
													+ info.functionName +'</td><td style="width: 40px; text-align: right;">' + aptFormatDate(new Date(info.endTime)) +'</td>'
													+'<td style="width: 30px; text-align: right;">' + info.timeTaken +'</td></tr>';
	
	}
	document.getElementById("timeRows").innerHTML = document.getElementById("timeRows").innerHTML 
													+ '<tr><td style="width: 80px; text-align: right; color: red">'
													+ 'Total Time' +'</td><td style="width: 40px; text-align: right;"></td>'
													+'<td style="width: 30px; text-align: right; color: red; font-weight: bold;">' + (window.performance.timing.responseEnd - window.performance.timing.requestStart) +'</td></tr>';
	
	
}
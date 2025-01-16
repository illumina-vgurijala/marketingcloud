var j$ = jQuery.noConflict();

/**
 * Catch for IE browsers that dont have console.log defined, this way
 * the javascript could call that function and not break.
 */
var alertFallback = true;
if (typeof console === "undefined" || typeof console.log === "undefined") {
	console = {};
    if (alertFallback) {
    	console.log = function(msg) {
        	
        };
	} else {
    	console.log = function() {};
	}
}

//Implements the view cart function
function invokeDoViewCart (){
	if(j$.APTTUS.hasUserTiersErrors == 'true' || j$.APTTUS.hasPriceRampsErrors == 'true'){
		showErrorDialog(); return false;
	}
	sfdcInvokeDoViewCart();

}

/**
 * Configure line item
 * 
 * @param 	proceedLineItemId
 *			Id of LineItem to configure
 */
function invokeDoConfigure(proceedLineItemId) {
	//invoke add to cart
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoConfigure, [proceedLineItemId], {disableBuffering: true, loadingLabel:j$.APTTUS.configuringProductLabel})
							 .then(
							 	function() {							 		
							 		 if(!j$.aptActionFunctionQueue.isQueued(sfdcInvokeDoConfigure)) {
							 		 
								 	 }
								}, null, 
								function() {
								
								});
}

/**
 * Resume queueing
 */
function resumeQueue() {
	var wasPaused = j$.aptActionFunctionQueue.setIsQueuePaused(false);
	if(wasPaused) {
		j$.aptActionFunctionQueue.processNext();

	} 

	return wasPaused;

}


function processActionFunction(refreshOptions) {
	j$('.updateWarningIcon').show();
	// check if the next function is a selection function
	if(j$.APTTUS.actionFunctionQueue.length>0) {
		disableInputsAndButtons(true);
		
		//j$.APTTUS.hideRulePrompt();//when there are pending actions hide rules prompt
		j$('.spinnerImg-tree').show();
		if(j$.APTTUS.actionFunctionQueue[0].toString().indexOf("sfdcDoSelectOptionsAndOpenAttributes(") != -1 ){
			
			// check if there is data to go with the selection function
			// if there is, then process the first set of options (grouped by option group)
			// if there is not, then the data has already been processed ( just shift the function and move to the next)
			if (Object.keys(j$.APTTUS.groupSelectionMap).length > 0){
				var ctxGroupId = Object.keys(j$.APTTUS.groupSelectionMap)[0];
				var options = j$.APTTUS.groupSelectionMap[Object.keys(j$.APTTUS.groupSelectionMap)[0]];
				sfdcDoSelectOptionsAndOpenAttributes(ctxGroupId, options.toString());
				delete j$.APTTUS.groupSelectionMap[Object.keys(j$.APTTUS.groupSelectionMap)[0]];
				
			} else {
				j$.APTTUS.actionFunctionQueue.shift();
				processActionFunction();
				
			}
		} else if(j$.APTTUS.actionFunctionQueue[0].toString().indexOf("sfdcDoSelectOptions(") != -1 ){
			
			// check if there is data to go with the selection function
			// if there is, then process the first set of options (grouped by option group)
			// if there is not, then the data has already been processed ( just shift the function and move to the next)
			if (Object.keys(j$.APTTUS.groupSelectionMap).length > 0){
				var ctxGroupId = Object.keys(j$.APTTUS.groupSelectionMap)[0];
				var options = j$.APTTUS.groupSelectionMap[Object.keys(j$.APTTUS.groupSelectionMap)[0]];
				sfdcDoSelectOptions(ctxGroupId, options.toString());
				delete j$.APTTUS.groupSelectionMap[Object.keys(j$.APTTUS.groupSelectionMap)[0]];
				
			} else {
				j$.APTTUS.actionFunctionQueue.shift();
				processActionFunction();
				
			}
		} else {
			j$.APTTUS.actionFunctionQueue[0]();
	
		} 
	} else {
		j$('.aptListButton').attr("disabled",false); 
		j$(':text').attr("disabled",false); 
		j$('select').attr("disabled",false); 
		j$('.aptListButton').removeClass('aptButtonDisabled');
		if(refreshOptions && !j$.APTTUS.suspendOptionRerender) {
 			j$('.spinnerImg-tree').show();
			invokeRefreshOptions2();
 			return;
 		}
		
		j$('.spinnerImg-tree').hide();
	}
	

}

function addToDataMap(ctxOptionId, ctxGroupId, checkedStatus) {
	
	if (ctxGroupId in j$.APTTUS.groupSelectionMap){
	
		j$.APTTUS.groupSelectionMap[ctxGroupId].push(ctxOptionId+":"+checkedStatus);
		
	} else {
		j$.APTTUS.groupSelectionMap[ctxGroupId] = new Array();
		j$.APTTUS.groupSelectionMap[ctxGroupId].push(ctxOptionId+":"+checkedStatus);
	}
	
}

function processGroupErrors() {
	var keys  = Object.keys(j$.APTTUS.groupErrors);

	j$.each(keys, function(keyIndex, key){
		if (key != '') {
			var errors = j$.APTTUS.groupErrors[key];
			var errorFound = false;
			
			if (!j$.isEmptyObject(errors)) {
				var errorFound = false;
				var htmlList = '<ul>';
		  		j$(errors).each(function() {
		  			htmlList+='<li>'+this+'</li>';
		  			errorFound = true;
		  			
		  		});
		  		
		  		htmlList+='</ul>';
		  		
		  		if(errorFound){
		  			j$('.'+key+'-OptionGroupErrorMessage').html(htmlList);
		  			j$('.'+key+'-OptionGroupErrorContainer').show();
		  			
		  		} 
		  	
		  	}
		  	
		  	if (!errorFound) {
	  			j$('.'+key+'-OptionGroupErrorMessage').html('');
	  			j$('.'+key+'-OptionGroupErrorContainer').hide();
	
		  	}
		  	
	  	}	
  		
	});
}


function tiersTableSetup (optionId) {

	j$('.'+optionId+'-tierLevel:last .'+optionId+'-Add').show();

	j$('#'+optionId+'-Remove:first').remove();

	j$('.tiersTable th:first + th').addClass('no-border-left');
	j$('.tiersTable th:first').addClass('no-border-right');

	j$('.tiersTable tbody tr').off('click').on('click', function(){
		j$('.tiersTable tbody tr').closest('.aptActiveRampsRow').find('.actionsMenu').hide();
		j$('.tiersTable tbody tr').closest('.aptActiveRampsRow').removeClass('aptActiveRampsRow');
		j$(this).addClass('aptActiveRampsRow');
		j$(this).find('.actionsMenu').show();
	});

	j$('.actionsMenu').off('click').on('click', function(){
		var className = j$(this).attr('class').split(' ')[1];
		className = className.replace('Menu','');

		var dialogWidth = j$( '#'+className).width();
		var dialogHeight = j$( '#'+className).height()*1.2;
		
		j$( '#'+className).dialog({
			autoOpen: false,
			position: { my: "left top", at: "left middle", of: this },
			resizable: false,
			dialogClass: "no-close actionsMenuDialog",
			draggable: false,
			closeOnEscape: true,
			width: dialogWidth,
			height: dialogHeight,
			show: {
				effect: "fade",
				duration: 500
			},
			hide: {
				effect: "fade",
				duration: 250
			},
			open: function(event, ui){
				
				j$('.ui-dialog-content:visible').mouseleave(
					function(){
						
						
						
						j$('body').on('mouseup',function (e) {
				    
						    var container = j$('.actionsMenuDialog:visible');
						    if (container.has(e.target).length === 0)
						    {
						    	
						    	j$(".ui-dialog-content").dialog().dialog("close");
						    }
						    
						});
				});
				j$('.ui-dialog-content:visible').focus();
			},
			close: function(event, ui) {
				j$( '#'+className).removeAttr('style');
				j$(this).dialog('destroy');
			}

	    });

	    j$('#'+className ).dialog('open');
	});
}






/**
 * Sets up the ramp tables behaviour, with actions menu and
 * other javascript functionality
 * @param  optionId: the option Id
 */
j$.APTTUS.rampTableSetup = function(optionId) {

	j$('.'+optionId+'-rampLevel:last .'+optionId+'-Add').show();

	j$('#'+optionId+'-Remove:first').remove();

	j$('.'+optionId+'-rampsTable th:first + th').addClass('no-border-left');
	j$('.'+optionId+'-rampsTable th:first').addClass('no-border-right');

	j$('.'+optionId+'-rampsTable tbody tr:last').click();

	j$('.rampsTable tbody tr').off('click').on('click', function(){
		
		j$('.rampsTable tbody tr').closest('.aptActiveRampsRow').find('.actionsMenu').hide();
		j$('.rampsTable tbody tr').closest('.aptActiveRampsRow').removeClass('aptActiveRampsRow');
		j$(this).addClass('aptActiveRampsRow');
		
		j$(this).find('.actionsMenu').show();
	});

	j$('.actionsMenu').off('click').on('click', function(){
		var className = j$(this).attr('class').split(' ')[1];
		className = className.replace('Menu','');
		

		var dialogWidth = j$( '#'+className).width();
		var dialogHeight = j$( '#'+className).height()*1.2;

		
		
		j$( '#'+className).dialog({
			autoOpen: false,
			position: { my: "left top", at: "left middle", of: this },
			resizable: false,
			dialogClass: "no-close actionsMenuDialog",
			draggable: false,
			closeOnEscape: true,
			width: dialogWidth,
			height: dialogHeight,
			show: {
				effect: "fade",
				duration: 500
			},
			hide: {
				effect: "fade",
				duration: 250
			},
			open: function(event, ui){
				
				j$('.ui-dialog-content:visible').mouseleave(
					function(){
						
						
						
						j$('body').on('mouseup',function (e) {
				    
						    var container = j$('.actionsMenuDialog:visible');
						    
						    
						    if (container.has(e.target).length === 0)
						    {
						    	
						    	j$(".ui-dialog-content").dialog().dialog("close");
						        
						    }
						    
						});
				});
				
				

				
				j$('.ui-dialog-content:visible').focus();
			},
			close: function(event, ui) {
				
				j$( '#'+className).removeAttr('style');
				j$(this).dialog('destroy');
			}

	    });

	    j$('#'+className ).dialog('open');
	});
}

/**
 * Toggle the visibility of ramps for a particular option
 * @param  checkbox field
 */
function toggleTiers(checkbox,button) {

	var toggleTierCB = j$(checkbox);
	button = j$(button);
	if(toggleTierCB.prop('checked')) {
		toggleTierCB.prop('checked',false);
		
	}
	else {
		toggleTierCB.prop('checked',true);
		
	}
	
	toggleTierCB.click(); 
}

/**
 * Toggle the visibility of ramps for a particular option
 * @param  checkbox field
 */
function toggleRamps(checkbox,button) {

	var toggleRampCB = j$(checkbox);
	button = j$(button);
	if(toggleRampCB.prop('checked')) {
		toggleRampCB.prop('checked',false);
		
	}
	else {
		toggleRampCB.prop('checked',true);
		
	}
	
	toggleRampCB.click(); 
}

/**
 * Shows the remove ramp confirmation
 * @param  ramp row getting removed
 */
function showRemoveRampRowConfirmation(rowId) {
	j$("#rampsConfirmationPanelJQuery").dialog({
		autoOpen: false,
		draggable: true,
		modal: true,
		resizable: false,
		position: 'center',
		buttons: {
	        "Yes": function() {
	        	j$(rowId).click();
	          	j$( this ).dialog( "destroy" );
	        },
	        No: function() {
	          j$( this ).dialog( "destroy" );
	        }
	    }
		
	});

	j$("#rampsConfirmationPanelJQuery").dialog('open');
}

/**
 * Toggle open/close leaf
 * @param  {[type]} nodeId [description]
 * @return {[type]}        [description]
 */
function toggleLeaf(nodeId)
{
		
		var items = j$('#'+nodeId+'-items');
		var display;
		items.slideToggle(400,function(){
			j$.APTTUS[nodeId+'-items']  = items.css('display');
				
			});
		
		j$('#'+nodeId).find('h2').toggleClass('aptToggleOn');
		
		
}
	
/**
 * Get mouseover product information
 */
 function getProductDetail3(productId) { 	
 	document.getElementById('ctxProductDescription').innerHTML = '';        
	Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.getProductDescription, productId, function(result, event){
		    if (event.status) {
		    	j$('.productDetailPanel .ui-dialog-title').html(result.Name);
		        if(result.Description != undefined){
		        	document.getElementById('ctxProductDescription').innerHTML = result.Description;
				} else {
					document.getElementById('ctxProductDescription').innerHTML = '';
				}
			} else {
		    	document.getElementById('ctxProductDescription').innerHTML = event.message;
			}
       	}, {buffer:false, escape:true});
	
	showProductDetailPanel();
 	
 }
 
 /**
 * Callback when mouseover product information icon
 */
function showProductDetailPanel() {
	j$.APTTUS.productDetailDialog =  j$( "#productDetailPanel" ).dialog({
    	modal:true,
    	title:j$.APTTUS.LoadingPageLabel,
    	maxWidth:1000,
    	minWidth:500,
    	minHeight:110,
    	autoOpen:true,
    	dialogClass:'productDetailPanel',
    	height:"auto",
    	open : function(){
 			j$('.productDetailPanel .ui-widget-header').css({border:"none",background:"none",borderBottom:"1px solid #aaaaaa"});
 			j$('.productDetailPanel .ui-widget-header').removeClass("ui-corner-all");
 			
 		}
    });
    
} 
 
/**
 * Show detail panel dialog
 */
 function showProductDetailPanel3() {
 	
 	j$("#productDetailPanel").dialog({
 		height: 140,
 		width: 550,
 		modal: true
 	});
 	j$("#productDetailPanel").dialog("option", "position", "center");
    
    return false;
    
}	

/**
 * Launch doSelectGroupOption
 */
function invokeDoSelectOption(ctxOptionId, ctxGroupId, inputField, invokedFromPrompt) {
	if('{!mobileUser}'=='true') {
 		return false;

 	}
 	if (!j$.APTTUS.useButtonToSaveSelection) {
		j$('.spinnerImg-tree').show();

 	}
	var selectFunction = sfdcDoSelectOptions;
	if (invokedFromPrompt) {
		selectFunction = sfdcDoSelectOptionsFromPrompt;
		resumeQueue();

	}	
	var checkedStatus = inputField.checked;
	j$.aptActionFunctionQueue.execute(selectFunction, {'ctxGroupId': ctxGroupId, 'ctxOptionId':ctxOptionId, 'checkedStatus':checkedStatus}, {loadingLabel:j$.APTTUS.modifyingOptionsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});


	return false;
	
}

/**
 * Launch doSelectGroupOption
 */
function invokeDoReplaceOption(ctxOptionId, ctxGroupId, invokedFromPrompt) {
	if('{!mobileUser}'=='true') {
 		return false;

 	}
 	if (!j$.APTTUS.useButtonToSaveSelection) {
		j$('.spinnerImg-tree').show();

 	}
	var selectFunction = sfdcDoReplaceOption;
	if (invokedFromPrompt) {
		selectFunction = sfdcDoReplaceOptionFromPrompt;
		resumeQueue();

	}	
	var checkedStatus = true;		
	j$.aptActionFunctionQueue.execute(selectFunction, {'ctxGroupId': ctxGroupId, 'ctxOptionId':ctxOptionId, 'checkedStatus':checkedStatus}, {loadingLabel: j$.APTTUS.modifyingOptionsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();				
				
			});
	
}

/**
 * Launch doselectoptions and open attributes dialog
 */
function invokeDoSelectOptionFromAttribute(ctxOptionId, ctxGroupId) {
	if('{!mobileUser}'=='true') {
 		return false;
 	}

 	//j$.aptActionFunctionQueue.updateSetting('isQueuePaused', false); 

 	/*var checkedStatus = true;		
 	j$('.spinnerImg-tree').show();
 	var optionSelect = function(){sfdcDoSelectOptionsAndOpenAttributes(ctxGroupId, ctxOptionId+':'+checkedStatus);}
	j$.APTTUS.actionFunctionQueue.push(optionSelect);
	addToDataMap(ctxOptionId, ctxGroupId, checkedStatus);
	if(j$.APTTUS.actionFunctionQueue.length == 1) { //if there is only one item
		processActionFunction();
		
	}*/
	
	if (!j$.APTTUS.useButtonToSaveSelection) {
		j$('.spinnerImg-tree').show();

	}
	var checkedStatus = true;	
	j$.aptActionFunctionQueue.execute(sfdcDoSelectOptionsAndOpenAttributes, {'ctxGroupId': ctxGroupId, 'ctxOptionId':ctxOptionId, 'checkedStatus':checkedStatus}, {loadingLabel:j$.APTTUS.loadingAttributesLabel})
		.then(
			function() {
				// If selected optiond Id is non null we fire the attributes dialog
				 if(j$.APTTUS.selectedOptionId !== undefined) {
				 	invokeSetSelectedLineItemId(j$.APTTUS.selectedOptionId);
				 }
			},null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	
}

/**
 * Invoke option selection with refresh
 */
function invokeDoSelectOptionWithRefresh(ctxOptionId, ctxGroupId, inputField) {
	if('{!mobileUser}'=='true') {
 		return false;
 	}
 	
 	//j$.aptActionFunctionQueue.updateSetting('isQueuePaused', false); 
 	
 	/*var checkedStatus = inputField.checked;		
 	j$('.spinnerImg-tree').show();
 	var optionSelect = function(){sfdcDoSelectOption2(ctxGroupId,ctxOptionId+':'+checkedStatus);}
	j$.APTTUS.actionFunctionQueue.push(optionSelect);
	addToDataMap(ctxOptionId, ctxGroupId, checkedStatus);
	if(j$.APTTUS.actionFunctionQueue.length == 1) { //if there is only one item
		//console.log('invokeDoSelectOption 2');
		processActionFunction();
	}*/
	
	if (!j$.APTTUS.useButtonToSaveSelection) {
		j$('.spinnerImg-tree').show();

	}
	var checkedStatus = inputField.checked;	
	j$.aptActionFunctionQueue.execute(sfdcDoSelectOption2, {'ctxGroupId': ctxGroupId, 'ctxOptionId':ctxOptionId, 'checkedStatus':checkedStatus}, {loadingLabel:j$.APTTUS.modifyingOptionsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	
	
	
}

function tapClick(ctxOptionId, ctxGroupId,callback) {
	
	if('{!mobileUser}'=='true') {
		
		j$('.spinnerImg-'+ctxOptionId).show();
		
		
		sfdcDoSelectOption(ctxOptionId, ctxGroupId);
		callback();
		j$('.spinnerImg-'+ctxOptionId).hide();
	}
	
}

function tapClick(ctxOptionId, ctxGroupId, block, callback) {
	
	if('{!mobileUser}'=='true') {
		j$('.spinnerImg-'+ctxOptionId).show();

		

		if(block=='topGroup') {
			sfdcDoSelectOptionTopGroup(ctxOptionId, ctxGroupId);
			
			
		}
		if(block=='group') {
			sfdcDoSelectOptionGroup(ctxOptionId, ctxGroupId);
			
			
		}
		if(block=='childGroup') {
			sfdcDoSelectOptionChildGroup(ctxOptionId, ctxGroupId);
			
			
		}
		
	}
	
}



/**
 * Check Show Ramp checkbox action scenarios
 */
 function showRampCheckAction(showRamp,checked,ctxOptionId, ctxGroupId)
 {
	
	if(checked=='true' && showRamp=='false') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeShowRamp, [ctxOptionId, ctxGroupId],{disableBuffering: true, loadingLabel:j$.APTTUS.loadingRampsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
		
	}
	else if(checked=='false' && showRamp=='false') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeInsertAndShowRamp, [ctxOptionId, ctxGroupId,'true'],{disableBuffering: true, loadingLabel:j$.APTTUS.loadingRampsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
	else if(checked=='true' && showRamp=='true') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeHideRamp, [ctxOptionId, ctxGroupId],{disableBuffering: true, showLoadingLabel:false})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
	else if(checked=='false' && showRamp=='true') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeInsertAndShowRamp, [ctxOptionId, ctxGroupId, checked],{disableBuffering: true, loadingLabel:j$.APTTUS.loadingRampsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
}

/**
 * Check Show Ramp checkbox action scenarios
 */
 function showTierCheckAction(showTier,checked,ctxOptionId, ctxGroupId)
 {
	
	if(checked=='true' && showTier=='false') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeRefreshOptions, null ,{disableBuffering: true, showLoadingLabel:false})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
	else if(checked=='false' && showTier=='false') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(sfdcDoSelectOption2, {'ctxGroupId':ctxGroupId, 'ctxOptionId': ctxOptionId, 'checkedStatus':'true'}, {disableBuffering:false , loadingLabel:j$.APTTUS.modifyingOptionsLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
		
	}
	else if(checked=='true' && showTier=='true') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeRefreshOptions, null ,{disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
	else if(checked=='false' && showTier=='true') {
		j$('.spinnerImg-'+ctxOptionId).show();
		j$.aptActionFunctionQueue.execute(invokeRefreshOptions, null ,{disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
}

/**
 * toggle quantity locking
 */
function toggleQuantityLock(configId, primaryLineNumber, fieldExpressionSOId, button) {
	j$(button).hide();
	j$(button).prev('.lock-spinner').show();	
	Visualforce.remoting.Manager.invokeAction(j$.APTTUS.toggleQuantityLock, configId, primaryLineNumber, fieldExpressionSOId,
		function(result, event) {
			if(event.status) {				
				j$(button).removeClass('locked');
				if(result == true) {
					j$(button).addClass('locked');

				}
								
			}

			j$(button).show();
			j$(button).prev('.lock-spinner').hide();

		});

}


/**
 * Check Show Ramp checkbox action scenarios
 */
 function updateQuantityAction(checked, ctxOptionId, ctxGroupId)
 {
 	selectClass='.'+ctxOptionId+"-check";
 	if (!(j$(selectClass).is(':checked'))) {
		return; //do nothing
	} else {
		//j$('.spinnerImg-'+ctxOptionId).show('0',invokeDoUpdateQuantity(ctxOptionId, ctxGroupId));
		
		if (!j$.APTTUS.useButtonToSaveSelection) {
			j$('.spinnerImg-'+ctxOptionId).show();

		}
		j$.aptActionFunctionQueue.execute(invokeDoUpdateQuantity, [ctxOptionId, ctxGroupId],{disableBuffering:true,loadingLabel:j$.APTTUS.updatingQuantityLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
	}
	
	
	
	
}

/**
 * update the Attribute values on change
 */
 function updateAttributeValues(checked, ctxOptionId, ctxGroupId)
 {
 	selectClass='.'+ctxOptionId+"-check";
 	if (!(j$(selectClass).is(':checked'))) {
		return; //do nothing
		
	} else {
		//j$('.spinnerImg-'+ctxOptionId).show('0',invokeDoUpdateAttributeValues(ctxOptionId, ctxGroupId));
		if (!j$.APTTUS.useButtonToSaveSelection) {
			j$('.spinnerImg-'+ctxOptionId).show();
		}
		j$.aptActionFunctionQueue.execute(invokeDoUpdateAttributeValues, [ctxOptionId, ctxGroupId],{disableBuffering:true,loadingLabel:j$.APTTUS.updatingAttributesLabel})
		.then(
			null,null,
			function(){
				disableInputsAndButtons(true);
				j$('.spinnerImg-tree').show();
				
			});
		
	}
	
}

/**
 * invokes action function to delete line item
 */
 function invokeDoDeleteLineItem(){
 	if(j$.APTTUS.LineNumber != j$.APTTUS.contextLineNumber){
 		j$.APTTUS.hideRemoveConfirmation();
 	}
 	j$.aptActionFunctionQueue.execute(sfdcDoDeleteLineItem, [j$.APTTUS.LineNumber], {disableBuffering:true, loadingLabel:j$.APTTUS.deletingLineItemLabel});
 	
 }
 
 

function showErrorDialog(){
	
		j$("#idErrorChoicePanel").dialog({
			autoOpen: true,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			close: function( event, ui ) {
				j$( this ).dialog( "destroy" );
			},
			buttons: {
		        "Ok": function() {
		        	j$( this ).dialog( "destroy" );
		        }
		       
		    }
			
		});
}

function buildSelectedTreeHierarchy(arry) {
	var roots = [], children = {};
	
	// find the top level nodes and hash the children based on parent
	for (var i = 0, len = arry.length; i < len; ++i) {
	    var item = arry[i];
	    var p = item.parentId;
	    var target = !p ? roots : (children[p] || (children[p] = []));
	
	    target.push({ value: item });
	}
	
	// function to recursively build the tree
	var findChildren = function(parent) {
	    //if (children[parent.value.Id]) {
	        parent.children = children[parent.value.Id];
	        parent.data = {};
	        parent.data.title = parent.value.label;
	        parent.data.icon = parent.value.imageUrl;
	        hasImage = false;
        	if(parent.value.imageUrl != ""){
        		hasImage = true;
        	}
	        parent.attr = {
	        			"Id" : parent.value.Id, 
	        			"hasImage" : hasImage, 
	        			"Type" : parent.value.type, 
	        			"optionId" : parent.value.optionId, 
						"groupId" : parent.value.groupId, 
						"primaryLineNumber" : parent.value.primaryLineNumber, 
						"parentBundleNumber" : parent.value.parentBundleNumber,
						"hasError" : parent.value.hasError,
						"parentId" : parent.value.parentId,
						"isSelected" : parent.value.isSelected,
						"errorMessages" : parent.value.errorMessages,
						"netPrice" : parent.value.netPrice,
						"rootOptionGroupId" : parent.value.rootOptionGroupId
	        		};
	        if (children[parent.value.Id]) {
		        for (var i = 0, len = parent.children.length; i < len; ++i) {
		        	parent.children[i].data = {};
		        	if(i < parent.children.length - 1){
		        		//parent.children[i].data += "<img class='move-down' src='/img/arrow_dwn.gif' alt='"+parent.children[i].value.Id+"' />";
		        	}
		        	if(i > 0){
		        		//parent.children[i].data += "<img class='move-up' src='/img/arrow_up.gif' alt='"+parent.children[i].value.Id+"' />";
		        	}
		        	parent.children[i].data.title = parent.children[i].value.label;
		        	hasImage = false
		        	if(parent.children[i].value.imageUrl != ""){
		        		hasImage = true;
		        	}
		        	parent.children[i].data.icon = parent.children[i].value.imageUrl;
		        	parent.children[i].attr = {"Id" : parent.children[i].value.Id, 
		        								"optionId" : parent.children[i].value.optionId, 
		        								"groupId" : parent.children[i].value.groupId, 
		        								"primaryLineNumber" : parent.children[i].value.primaryLineNumber, 
		        								"parentBundleNumber" : parent.children[i].value.parentBundleNumber, 
		        								"hasImage" : hasImage, 
		        								"hasError" : parent.children[i].value.hasError,
		        								"isSelected" : parent.children[i].value.isSelected,
		        								"parentId" : parent.children[i].value.parentId,
		        								"errorMessages" : parent.children[i].value.errorMessages,
		        								"Type" : parent.children[i].value.type,
		        								"rootOptionGroupId" : parent.children[i].value.rootOptionGroupId,
												"netPrice" : parent.value.netPrice};
		            findChildren(parent.children[i]);
		        }
	        }
	    //}
	};
	
	// enumerate through to handle the case where there are multiple roots
	for (var i = 0, len = roots.length; i < len; ++i) {
	    findChildren(roots[i]);
	}
	
	return roots;
}

/**
* create the attributes Dialogs
*/
function setupAttributesPanel(url){
	j$('#idAttributesDialog').dialog({
		modal:true,
		width:675,
		height:625,
		dialogClass:'attributesDialog',
		resizable:false,
		create:function(){
			j$('.attributesDialog .ui-dialog-titlebar a span').html('');
			j$('.attributesDialog .ui-dialog-titlebar a span').removeClass('ui-icon ui-icon-closethick');
			j$('.attributesDialog .ui-dialog-titlebar a span').addClass('aptAttributesCloseDialogIcon');
			j$('#idAttributesDialog > iframe').attr('src', url);
		},
		close:function(){
			j$(this).dialog('destroy');
			j$('#idAttributesDialog > iframe').attr('src', '');	
			//invokeReinitializeOptions();
			j$.aptActionFunctionQueue.execute(invokeReinitializeOptions, null, {disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel})
			.then(
				null,null,
				function(){
					disableInputsAndButtons(true);
					j$('.spinnerImg-tree').show();
					
				});
			
		}
	});
	return false;
}

function closeAttributesDialog(){
	j$('#idAttributesDialog').dialog('destroy');
	j$.aptActionFunctionQueue.execute(invokeReinitializeOptions, null, {disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel})
			.then(
				null,null,
				function(){
					disableInputsAndButtons(true);
					j$('.spinnerImg-tree').show();
					
				});
	//invokeReinitializeOptions();
	
}

function setAttributeDialogHeader(dialogHeader){
	j$('.attributesDialog span[class="ui-dialog-title"]').html(dialogHeader);
}

// Create a namespace for our custom functions

// This to make sure jQuery doesn't conflict with any other JS libraries
var j$ = jQuery.noConflict();

j$(document).ready(function(){

	// setup namespace
	//j$.APTTUS = {};

	// setup the remove confirmation dialog
	j$("#confirmationPanel").dialog({
		autoOpen: false,
		draggable: false,
		modal: true,
		resizable: false,
		position: 'center'

	});

	// setup the remove confirmation dialog
	j$("#waitPanel").dialog({
		autoOpen: false,
		draggable: false,
		modal: true,
		resizable: false,
		position: 'center'

	});

	// setup the remove confirmation dialog
	j$("#productDetailPanel").dialog({
		autoOpen: false,
		draggable: false,
		modal: true,
		resizable: false,
		position: 'center'

	});

	//set scroll bar for line items block
	/*j$("input:text").change(function(){
		j$(this).closest("dataRow").next("input:checkbox").checked = true;

	});*/

});

/**
* create the attributes Dialog
*/
function setupAttributesPanel(){
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
		},
		close:function(){
			j$(this).dialog('destroy');
		}
	});
	return false;
}

/**
 * Show remove confirmation dialog
 * @param lineNumber the line number to delete
 */
function showRemoveConfirmation(lineNumber) {

	// store the line number in the global namespace
	j$.APTTUS.LineNumber = lineNumber;
	
	j$("#confirmationPanel").dialog("open");
	j$("#confirmationPanel").dialog("option" , "title" , aptRemoveHeader);
	j$("#confirmationPanel").dialog("option", "position", "center");
	
	return false;

}

/**
 * Hide the remove confirmation dialog
 */
function hideRemoveConfirmation(){
	// close the confirmation dialog
	j$("#confirmationPanel").dialog("close");

}

/**
 * Show remove confirmation dialog
 * @param lineNumber the line number to delete
 */
function showWaitPanel() {
	j$("#waitPanel").dialog("open");
	j$("#waitPanel").dialog({
	    height: 120,
	    width: 300,
	    modal: true
	});
	j$("#waitPanel").dialog("option", "position", "center");
	return false;

}

/**
 * Hide the remove confirmation dialog
 */
function hideWaitPanel(){
	if (true == j$.APTTUS.stopHide) {
		return;
	}
	// close the confirmation dialog
	j$("#waitPanel").dialog("close");

}

/**
 * Get mouseover product information
 */
function getProductDetail3(remoteFunction, productId) {
	document.getElementById('ctxProductDescription').innerHTML = '';
    showProductDetailPanel3();
    j$("#productDetailPanel").dialog("option", "title", aptLoadingPageHeader);

	Visualforce.remoting.Manager.invokeAction(remoteFunction, productId, function(result, event){
		    if (event.status) {
			j$("#productDetailPanel").dialog("option", "title", result.Name);
			if(result.Description != undefined){
				document.getElementById('ctxProductDescription').innerHTML = result.Description;
				j$('.hd').hide();
				j$('.container-close').hide();
				j$('.ui-dialog .ui-dialog-content').css('padding','0');
				}
			} else {
			document.getElementById('ctxProductDescription').innerHTML = event.message;
			}
	}, {buffer:false, escape:true});

}			

/**
 * Show detail panel dialog
 */
function showProductDetailPanel3() {
	j$("#productDetailPanel").dialog("open");
	j$("#productDetailPanel").dialog({
	    height: 140,
	    width: 500,
	    modal: true
	});
	j$("#productDetailPanel").dialog("option", "position", "center");
	
	return false;

}

/**
 * keep track of option selection based on radio buttons
 */
function aptsSelectRadio(primaryLineNumber, ctxGroupId, theField) {
	if (primaryLineNumber == aptNoneNumber) {
		emptyRadioGroups[ctxGroupId] = true;

	} else { 
		selectedRadioOptions[ctxGroupId] = primaryLineNumber;
		emptyRadioGroups[ctxGroupId] = false;

	}
	//console.log(selectedRadioOptions);

}

/**
 * keep track of option selection based on checkbox field
 */		
function aptsSelectCheckbox(primaryLineNumber, ctxGroupId, theField) {
	selectedCheckboxOptions[primaryLineNumber] = theField.checked;
}

/**
 * returns selected option ids and removed options ids in a 2-element array
 */		
function aptGetSelectedAndRemovedIds() {
	var selectedPrimaryNumbers = [];
	var removedPrimaryNumbers = [];
	var emptyGroupIds = [];
	for(var primaryLineNumber in selectedCheckboxOptions){
		if(selectedCheckboxOptions[primaryLineNumber] == true){
			selectedPrimaryNumbers.push(primaryLineNumber);

		} else {
			removedPrimaryNumbers.push(primaryLineNumber);

		}

	}

	for(var groupIdNumberKey in selectedRadioOptions){
		selectedPrimaryNumbers.push(selectedRadioOptions[groupIdNumberKey]);

	}
	for(var groupId in emptyRadioGroups){
		if(emptyRadioGroups[groupId] == true){
			emptyGroupIds.push(groupId);

		}

	}

	//alert('selectedPrimaryNumbers = ' + selectedPrimaryNumbers + ',  removedPrimaryNumbers = ' + removedPrimaryNumbers);
	var values = new Array(selectedPrimaryNumbers.toString(), removedPrimaryNumbers.toString(), emptyGroupIds.toString());

	selectedCheckboxOptions = {};
	selectedRadioOptions = {};
	emptyGroupIds = {};

	return values;

}

/**
 * invokes doUpdateBundle
 */
function invokeDoUpdateBundle(moveDirection){

	showWaitPanel();
	var selectedAndRemovedIds = aptGetSelectedAndRemovedIds();
	//invoke apex function
	sfdcDoUpdateBundle(selectedAndRemovedIds[0], selectedAndRemovedIds[1], selectedAndRemovedIds[2], moveDirection);	

	return false; //so that the command button do not submit the form by itself

}

/**
 * invokes doConfigureOption with parameters for opening the subbundle
 * @param optionId this is the primaryLineNumber
 * @param groupId the option group id to which the options belong
 * @param primaryLineNumber the primary line number of the option
 * @parantSequence the primary line number of the parent bundle 
 */
function invokeDoConfigureOption(optionId, groupId, primaryLineNumber, parentSequence, selectedTab){
	showWaitPanel();
	var selectedAndRemovedIds = aptGetSelectedAndRemovedIds();
	//invoke apex function
	sfdcDoConfigureOption(selectedAndRemovedIds[0], selectedAndRemovedIds[1], optionId, groupId, primaryLineNumber, parentSequence, selectedTab);	

	return false; //so that the command button does not submit the form by itself

}

/**
 * invokes doConfigureOption with parameters for opening the subbundle
 */
function invokeDoConfigureSystem(primaryLineNumber, selectedTab){
	showWaitPanel();
	var selectedAndRemovedIds = aptGetSelectedAndRemovedIds();
	//invoke apex function
	sfdcDoConfigureSystem(selectedAndRemovedIds[0], selectedAndRemovedIds[1], primaryLineNumber, selectedTab);	

	return false; //so that the command button does not submit the form by itself

}

/**
 * invokes action function to delete line item
 */
function invokeDoDeleteLineItem(){
	hideRemoveConfirmation();
	showWaitPanel();
	sfdcDoDeleteLineItem(j$.APTTUS.LineNumber);

}
/**************************************************************************************************************************************************************
 * Apttus CPQ Asset JS file
 * @2016-2017 Apttus Inc. All rights reserved.
 * CPQAssetJS
 *************************************************************************************************************************************************************/

var prompted = {};

j$(document).ready(function(){

	// Set queue precedence 
	// ******* ANYTHING WITH NO PRECEDENCE WILL BE PROCESSED FIRST *******

	j$.aptActionFunctionQueue.setPrecedence({
		sfdcInvokeDoAddProductToCart: 2,
	});

	j$.APTTUS.formatFields(j$.APTTUS.currencyFieldPrecision, j$.APTTUS.percentageFieldPrecision, j$.APTTUS.quantityFieldPrecision);

});

function togglePromptAddButton(noProductSelected) {
	// enable button
	if (noProductSelected) {
		j$('[id$=idPromptAddBtn]').addClass('aptButtonDisabled');
		j$('[id$=idPromptAddBtn]').attr("disabled", "disabled"); 
		
	} else {
		j$('[id$=idPromptAddBtn]').removeClass('aptButtonDisabled');
		j$('[id$=idPromptAddBtn]').removeAttr("disabled"); 
		
	}

}

/**
 * Pause queueing
 */
function pauseQueue() {
	// set queue paused param
	j$.aptActionFunctionQueue.updateSetting('isQueuePaused', true);
}

/**
 * Resume queueing
 */
function resumeQueue() {
	// un-pause queue and push along    
	if(j$.aptActionFunctionQueue.updateSetting('isQueuePaused', false)) {       
		j$.aptActionFunctionQueue.processNext(); // only process next if queue was paused
	}
}

 
/**
 * Invoke add product to cart -- from constraint choice dialog panel
 * @param   selectProductId Id of product to add to cart 
 * @param   ruleActionId Rule action id
 * @param   ruleId rule id
 * @param   rulePrimaryNumber rule primary line #
 */
function selectProduct(field, selectProductId, ruleActionId, ruleId, rulePrimaryNumber) {
	if (field.checked == false) {
		delete prompted[selectProductId+ruleActionId+ruleId+rulePrimaryNumber];
		
	} else {
		var params = {
			selectProductId: selectProductId,
			quantity: 1,
			ruleActionId: ruleActionId,
			ruleId: ruleId,
			rulePrimaryNumber: parseInt(rulePrimaryNumber)
	
		};
		prompted[selectProductId+ruleActionId+ruleId+rulePrimaryNumber] = params;
	}
	
	togglePromptAddButton(j$.isEmptyObject(prompted));
	
}

/**
 * Invoke add product to cart -- from constraint choice dialog panel
 * @param   selectProductId Id of product to add to cart 
 * @param   ruleActionId Rule action id
 * @param   ruleId rule id
 * @param   rulePrimaryNumber rule primary line #
 */
function addSelected(button, pageSpinner) {
	pauseQueue();
	// show button status spinner
	showConstraintRuleButtonSpinner(button);
		
	var keys = Object.keys(prompted);
	var selected = false;
	for (var i = 0; i < keys.length; i++) {
		var params = prompted[keys[i]];
		if (params == null) {
			continue;
		}
		
		prompted[keys[i]] = null; //cleanup 
		selected = true;
		
		//invoke select product
		j$.aptActionFunctionQueue.execute(sfdcInvokeDoAddProductToCart, params, {loadingLabel:j$.APTTUS.addingProductLabel})
			.then( function() {
				j$(document.getElementById(pageSpinner)).hide();
			});
		
		
	}
	
	if (selected) {
		j$(document.getElementById(pageSpinner)).show();
		// resume queue
		resumeQueue();
	}
	
}


/**
 * Invoke add product to cart -- from constraint
 * choice dialog panel
 *
 * @param   selectProductId
 *          Id of product to add to cart 
 * @param   ruleActionId
 *          Rule action id
 * @param   ruleId
 *          rule id
 * @param   rulePrimaryNumber
 *          rule primary line #
 * @param   button
 *          ctx button
 */
function invokeDoSelectProduct(selectProductId, ruleActionId, ruleId, rulePrimaryNumber, button, pageSpinner) {
	// show button status spinner
	showConstraintRuleButtonSpinner(button);
	// hide rule prompt
	j$.APTTUS.hideRulePrompt();

	var params = {
		selectProductId: selectProductId,
		quantity: 1,
		ruleActionId: ruleActionId,
		ruleId: ruleId,
		rulePrimaryNumber: parseInt(rulePrimaryNumber)

	};

	j$(document.getElementById(pageSpinner)).show();

	//invoke select product
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoAddProductToCart, params, {loadingLabel:j$.APTTUS.addingProductLabel})
		.then( function() {
			j$(document.getElementById(pageSpinner)).hide();
		});

	// resume queue
	resumeQueue();
}


/**
 * Invoke replace product -- from constraint
 * choice dialog panel
 *
 * @param   selectProductId
 *          Id of product to add to cart 
 * @param   ruleActionId
 *          Rule action id
 * @param   ruleId
 *          rule id
 * @param   rulePrimaryNumber
 *          rule primary line #
 * @param   button
 *          ctx button
 */
function invokeDoReplaceProduct(selectProductId, ruleActionId, ruleId, rulePrimaryNumber, button, pageSpinner) {
	// show button status spinner
	showConstraintRuleButtonSpinner(button);
	j$(document.getElementById(pageSpinner)).show();

	// hide rule prompt
	j$.APTTUS.hideRulePrompt();
	//invoke select product
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoReplaceProduct, [selectProductId, ruleActionId, ruleId, rulePrimaryNumber], {disableBuffering:true, loadingLabel:j$.APTTUS.replacingProductLabel})
							 .then(function() {
								j$(document.getElementById(pageSpinner)).hide();

							 });
	// resume queue
	resumeQueue();
}

/**
 * Invoke remove product -- from constraint
 * choice dialog panel
 * 
 *
 * @param   selectProductId
 *          Id of product to add to cart 
 * @param   ruleActionId
 *          Rule action id
 * @param   rulePrimaryNumber
 *          rule primary line #  
 * @param   button
 *          ctx button
 */
function invokeDoRemoveProduct(selectProductId, ruleActionId, rulePrimaryNumber, button, pageSpinner) {
	// show button status spinner
	showConstraintRuleButtonSpinner(button);    
	j$(document.getElementById(pageSpinner)).show();

	// hide rule prompt
	j$.APTTUS.hideRulePrompt();
	//invoke select product
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoRemoveProduct, [selectProductId, ruleActionId, rulePrimaryNumber], {disableBuffering:true, loadingLabel:j$.APTTUS.removingProductLabel})
		.then(function() {
			j$(document.getElementById(pageSpinner)).hide();
		});
	// resume queue
	resumeQueue();
}

/**
 * Show select product spinner image
 * and position it on top of button
 * 
 * @param   button
 *          reference button
 */
function showConstraintRuleButtonSpinner(button, isCancelButton) {
	posLeft = j$(button).position().left + (isCancelButton ? 13 : 5);
	posTop = j$(button).position().top + (isCancelButton ? 8: 5);
	j$('.' + (isCancelButton ? 'constraintRuleCancelStatus' : 'constraintRuleButtonStatus')).css({
					'position':'absolute',
					'top' : posTop + 'px',
					'left': posLeft + 'px'});

	// disable button
	j$(button).attr('disabled','disable').addClass('aptButtonDisabled'); 
}
							 
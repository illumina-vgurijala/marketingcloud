/**************************************************************************************************************************************************************
 * Apttus CPQ Catalog JS file
 * @2010-2014 Apttus Inc. All rights reserved.
 * CPQCatalogJS
 *************************************************************************************************************************************************************/

var clsNodes;
var selectedNodeId;
var selectedNodeType;
var numberOfRoots;
var theTree;
var isSelectedNodeLeaf;
var data;
var prompted = {};
var excludedProductIds = [];

j$(document).ready(function(){

	// j$('.jslider').resize();

	j$('#relocateChatter').html(j$('#cartHeaderDiv').html());
	j$('#cartHeaderDiv').html('');	
	
	j$('input[type="button"]').removeClass('btn');
		
	
	// bind enter key to search input
	j$('.apt-search-query').keydown(searchInputKeyPress);
	// bind reset search to its' toggle
	j$('#clearSearch').click(function() { resetSearch(true); });
	//show browse catalog header
	j$('.labelBrowse').show();
	j$('.labelNarrowYourSearch').hide();
	
	// setup the remove confirmation dialog
	j$("#productDetailPanel").dialog({
		autoOpen: false,
		draggable: false,
		modal: true,
		resizable: false,
		position: 'center'
		
	});	

	// only process calls to these functions once, i.e. process only the last call to it	
	j$.aptActionFunctionQueue.setSkipToEndOfQueue([
		sfdcInvokeDoGetClassificationProducts,
		sfdcInvokeDoProcessMoreRules,
		sfdcInvokeDoClearSearchResults,
		invokeDoCustomAction
	]);	

	// Set queue precedence 
	// ******* ANYTHING WITH NO PRECEDENCE WILL BE PROCESSED FIRST *******

	j$.aptActionFunctionQueue.setPrecedence({
		sfdcInvokeDoGetClassificationProducts: 99, //high preedence will be processed first
		sfdcInvokeDoAddProductToCart: 2,
		sfdcInvokeDoDeleteLineItem: 2,
		sfdcInvokeDoProcessMoreRules: 1,
		sfdcInvokeDoConfigure: 0,
		sfdcInvokeDoConfigureProduct: 0,
		invokeDoCustomAction: -999
	});

	j$.APTTUS.formatFields(j$.APTTUS.currencyFieldPrecision, j$.APTTUS.percentageFieldPrecision, j$.APTTUS.quantityFieldPrecision);

});


/**
 * Show the selected product indicator
 *
 * @param 	selectedProducts
 *			Id of selected products
 */
function showSelectedIndicator(selectedProducts) {
	j$("[class*='prodCheckedIndicator']").hide();
	for(var i=0; i < selectedProducts.length; i++) {		
		j$('.prodCheckedIndicator_' + selectedProducts[i]).show();

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
 * @param 	selectProductId Id of product to add to cart 
 * @param 	ruleActionId Rule action id
 * @param 	ruleId rule id
 * @param 	rulePrimaryNumber rule primary line #
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
 * @param 	selectProductId Id of product to add to cart 
 * @param 	ruleActionId Rule action id
 * @param 	ruleId rule id
 * @param 	rulePrimaryNumber rule primary line #
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
 * @param 	selectProductId
 *			Id of product to add to cart 
 * @param 	ruleActionId
 *			Rule action id
 * @param 	ruleId
 *			rule id
 * @param 	rulePrimaryNumber
 *			rule primary line #
 * @param 	button
 *			ctx button
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
 * @param 	selectProductId
 *			Id of product to add to cart 
 * @param 	ruleActionId
 *			Rule action id
 * @param 	ruleId
 *			rule id
 * @param 	rulePrimaryNumber
 *			rule primary line #
 * @param 	button
 *			ctx button
 */
function invokeDoReplaceProduct(selectProductId, ruleActionId, ruleId, rulePrimaryNumber, button, pageSpinner) {
	// show button status spinner
	showConstraintRuleButtonSpinner(button);
	j$(document.getElementById(pageSpinner)).show();

	// hide rule prompt
	j$.APTTUS.hideRulePrompt();
	//invoke select product
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoReplaceProduct, [selectProductId, ruleActionId, ruleId, rulePrimaryNumber], {disableBuffering:true, loadingLabel:j$.APTTUS.replaceingProductLabel})
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
 * @param 	selectProductId
 *			Id of product to add to cart 
 * @param 	ruleActionId
 *			Rule action id
 * @param 	rulePrimaryNumber
 *			rule primary line #  
 * @param 	button
 *			ctx button
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
 * Add product to cart
 *
 * @param 	productId
 *			Id of product to add to cart
 *
 * @param 	spinnerId
 *			Id of ctx product spinner
 */
function invokeDoAddProductToCart(productId, quantityId, spinnerButton, configureButton, isDisableOnClick) {
	var quantity = parseFloat(j$(document.getElementById(quantityId)).val());
	j$.APTTUS.valueChanged = true;	
	//add item to cart
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoAddProductToCart, 
									 {'selectProductId': productId, 'quantity':quantity },
									 { loadingLabel:j$.APTTUS.addingProductLabel, 
									 	spinners: {
									 		uniqueIdentifier:'AddProduct_' + productId,
									 		buttonSpinners:[
									 			{
											 		button:spinnerButton,
											 		buttonSpinnerImage:'.apt-button-action-spinner img',
											 		disableWhenProcessing: isDisableOnClick
											 	},
											 	{

											 		button:configureButton,
											 		//buttonSpinnerImage:'.apt-button-action-spinner img',
											 		disableWhenProcessing: isDisableOnClick
											 	}]
									 	}
									 });
}

/**
 * Remove line item from cart
 *
 * @param 	lineNumber
 *			the line number of the line item to be 
 *			removed
 */
function invokeDoDeleteLineItem(lineNumber) {	
	j$.APTTUS.valueChanged = true;
	//set line number
	if(lineNumber == undefined || lineNumber == null) {
		lineNumber = j$.APTTUS.LineNumber;
	}	
	
	//invoke delete line item
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoDeleteLineItem, [j$.APTTUS.LineNumber], 
									 {disableBuffering:true, 
									  loadingLabel:j$.APTTUS.deletingLineItemLabel,
									  spinners: {
									  	uniqueIdentifier:'DeleteLine_' + j$.APTTUS.lineItemNumber,
									  	rerenderOnProcessNext: true,
									 	actionSpinners:[{
											actionSpinner:'.aptActionStatus-'+j$.APTTUS.lineItemNumber												
										}]
									  }}).then(function() {		
											 		// Compute total price
											 		if (!j$.APTTUS.skipCartTotalsCalculation) {
										 				doComputeTotalPrice();
										 			}
										 		}
									);

	//hide confirmation dialog							 
	j$.APTTUS.hideRemoveConfirmation();
}

/**
 * Add product to cart and configure it
 *
 * @param 	productId
 *			Id of product to add to cart
 *
 * @param 	spinnerId
 *			Id of ctx product spinner
 */
function invokeDoConfigureProduct(productId, quantityId) {
	j$.APTTUS.valueChanged = true;
	//get quantity
	var quantity = parseFloat(j$(document.getElementById(quantityId)).val());
	
	//invoke add to cart
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoConfigureProduct, 
									 {'selectProductId': productId, 'quantity':quantity}, 
									 {loadingLabel:j$.APTTUS.configuringProductLabel});
}

/**
 * Configure line item
 * 
 * @param 	proceedLineItemId
 *			Id of LineItem to configure
 */
function invokeDoConfigure(proceedLineItemId) {
	// disable inputs
	disableInputsAndButtons(true);
	//invoke add to cart
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoConfigure, [proceedLineItemId], {disableBuffering:true, loadingLabel:j$.APTTUS.configuringProductLabel})
							 .then(
							 	function() {							 		
							 		 if(!j$.aptActionFunctionQueue.isQueued(sfdcInvokeDoConfigure)) {
							 		 
								 	 }
								}, null, 
								function() {
								
								});
}

/**
 * Save selected product so for compare.
 * 
 * @param 	prodSOId
 *			Id of product sObject to compare 
 *
 * @param 	isChecked
 *			Is selected to compare indicator
 */
function invokeSaveSelectedComparision(prodSOId, isChecked) {
	// add to action function queue
	j$.aptActionFunctionQueue.execute(sfdcSaveSelectedComparision, {'selectedId': prodSOId, 'isChecked': isChecked }, {loadingLabel:j$.APTTUS.savingForCompareLabel});
}

/**
 * Process pending constraint rules
 */
function invokeDoProcessMoreRules() {
	j$.APTTUS.valueChanged = true; //potential auto inclusion
	// queue up processing
	j$.aptActionFunctionQueue.execute(sfdcInvokeDoProcessMoreRules, null, {disableBuffering:true, loadingLabel:j$.APTTUS.processingConstraintRulesLabel});

}

/**
 * Show/Hide select (list) products spinner
 * 
 * @param 	onOff
 *			flag indicating whether to turn 
 *			the spinner on or off
 */
function toggleSelectProductsSpinner(onOff) {	
	if(onOff) {
		j$('[Id*="selectProductStatus.start"]').show();
	} else {
		j$('[Id*="selectProductStatus.start"]').hide();
	}

}

/**
 * Show select product spinner image
 * and position it on top of button
 * 
 * @param 	button
 *			reference button
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

//Implements the view cart function
function invokeDoViewCart (){
	sfdcInvokeDoViewCart();

}

/**
 * Reset search 
 */
function resetSearch(doServerRefresh) {
	// if(j$('.search-query').val() == '') {
	// 	return;
	// }
		
	// wipe search text
	j$('.apt-search-query').val(''); 
	// hide clear search text
	j$('#idClearSearchText').hide();	
	// Reset display categories
	j$.APTTUS.nav.aptBreadCrumb('option', 'treeOptions.displayIds', j$.APTTUS.nav.aptBreadCrumb('option', 'displayIds'));
	// Clear search results
	if(doServerRefresh) {
		j$.aptActionFunctionQueue.execute(sfdcInvokeDoClearSearchResults, null, {disableBuffering:true, loadingLabel:j$.APTTUS.loadingProductsLabel});
	}

	j$('.labelBrowse').show();
	j$('.labelNarrowYourSearch').hide();
	
}

/**
 * Handle keypress event for search input
 */
function searchInputKeyPress(event) {
	if(event.keyCode==13) {
    	//doSearch();
    	j$('.idDoSearchButton').trigger('click');
    	j$('.idDoSearchButton').focus();
		event.preventDefault();  
		return false;  	
    }

    return true;
}

/**
 * Callback which will move the search bar
 * into position on load of navigation	 
 */
function breadCrumbOnLoad( event, data ) {		
	
}	

/**
 * Callback update the products upon 
 * selection 
 */
function breadCrumbOnSelect( event, data ) {	
	if(!j$.APTTUS.searchButtonClicked) {
		// If browsing through carousel or through root menu		
		if(data.userSelect && !data.selectedFromTree && (j$.APTTUS.alwaysDisplayLeafProducts || data.isLeaf)) {			
			resetSearch();

		}

		if(data.selectedId != null 
				&& data.selectedId != '' && (j$.APTTUS.alwaysDisplayLeafProducts || data.isLeaf)) {
			// Get classification products. If search text filter within search results.
			j$.aptActionFunctionQueue.execute(sfdcInvokeDoGetClassificationProducts, [data.selectedId, (data.userSelect && !data.selectedFromTree)], 
																					  {disableBuffering:true, loadingLabel:j$.APTTUS.loadingProductsLabel});
		}
	}	
}	

/**
 * Callback to clear search and move search bar
 * out of the way to prevent destuction, during
 * navigation "selection"	 
 */
function breadCrumbBeforeSelect( event, data) {
	
}

/**
 * Refresh/Load Navigation
 */
function refreshNav() {	
	if(!j$.APTTUS.nav) {	
		loadNav();			
	} else {		
		j$.APTTUS.nav.aptBreadCrumb('option', 'treeOptions.displayIds', JSON.parse(j$.APTTUS.filteredProductClassificationIds));
		j$.APTTUS.nav.aptBreadCrumb('select', j$.APTTUS.contextCategoryId);
	}
}

/**
 * Load Navigation
 */
function loadNav() {	
	j$.APTTUS.nav = 
		j$('#breadCrumbContainer').aptBreadCrumb({
				breadCrumbs: JSON.parse(j$.APTTUS.jsonTree),
				selected: (typeof j$.APTTUS.contextCategoryId !== "undefined" && j$.APTTUS.contextCategoryId.length > 0) 
						? j$.APTTUS.contextCategoryId 
						: j$.APTTUS.defaultLandingCategoryId,
				maxIconHeightAndWidthStyle: j$.APTTUS.MaxIconHeightAndWidthStyle,				
				onLoad: breadCrumbOnLoad,
				onSelection: breadCrumbOnSelect,
				beforeSelect: breadCrumbBeforeSelect,		
				browseMenuContainer:j$.APTTUS.isFixedButtonBar ? '' : '.apt-browseCatalogDropDown',
				treeContainer: '#treeContainer',
				disableRootMenu:true,
				disableTabView: true,
				carouselContainer: '#carouselContainer',
				rootMenuContainer: '', //#rootMenuContainer
				treeOptions: {	
								displayInTree: j$.APTTUS.filteredProductClassifications, 
								displayIds:JSON.parse(j$.APTTUS.filteredProductClassificationIds), // displayed in tree	
								hideRootCategory: j$.APTTUS.isHideRootCategory											
				},
				carouselOptions: { 
									maxDepth: j$.APTTUS.maximumCarouselDepth, 
									noImagePlaceHolder: j$.APTTUS.NoCategoryImageFoundURL 
				},
				rootMenuOptions: { 
									placeHolder:j$.APTTUS.rootMenuPlaceHolder, 
									maxDepth:999 
				},
				disableBreadcrumb: j$.APTTUS.isHideBreadcrumb,
				disableCarouselView: (j$.APTTUS.maximumCarouselDepth && j$.APTTUS.maximumCarouselDepth < 0),
				expandAllLabel: j$.APTTUS.expandAllLabel,
				collapseAllLabel: j$.APTTUS.collapseAllLabel,
				displayIds: JSON.parse(j$.APTTUS.filteredProductClassificationIds) //global display ids's
		});
}

/**
 *
 */	
function toggleDescription(className,element) {
  var origHeight = j$('.'+className).data('origHeight');
    var button = j$('.'+element);
    ////console.log(button);
    if (origHeight) {
       j$('.'+className).removeData('origHeight');
       j$('.'+className).animate({height: origHeight});
       button.html('Show Less');
       ////console.log('Show Less');
    } else {
        origHeight = j$('.'+className).height();
        j$('.'+className).data('origHeight', origHeight);
        j$('.'+className).animate({height: '100px'});
        button.html('Show More');
        ////console.log('Show More');
    }
    
    //$(".arrow").addClass("minimized");
}
	
/**
 * process elements after section of the page is rerendered
 * remove disabled=false elements
 */
function processRenderedElements(){
	j$(document).ready(function(){
		j$("*[disabled=\"false\"]").removeAttr("disabled");
	
	});	
	
}
	
function showShoppingCart(elem) {
	////console.log(j$('.idSelectedProductsBlock'));
	if(j$('.idSelectedProductsBlock').is(':hidden'))
	{
		j$('.idSelectedProductsBlock').show();
	    var linkOffset = j$(elem).offset();
	    var xPos = linkOffset.left;
	    var yPos = linkOffset.top+15;
    	xPos = xPos - j$('.idSelectedProductsBlock').width()/2;
	    j$('.idSelectedProductsBlock').css('position', 'absolute');
	    j$('.idSelectedProductsBlock').css('min-width', '350px');
		j$('.idSelectedProductsBlock').offset({top:yPos,left:xPos});
	}
	else if(j$('.idSelectedProductsBlock').is(':visible'))
	{
		j$('.idSelectedProductsBlock').hide();	
	}
	else
	{
		j$('.idSelectedProductsBlock').hide();		
	}
}
	
function tapClick(element) {
	if(j$.APTTUS.mobileUser=='true') {
		selected = j$(element).parent().find('input[type="checkbox"]');
		selected.trigger('click');
	}

}

function buildHierarchy(data) {
	var arry = new Array(), roots = [], children = {};

	j$.each(data, function buildClsNodes (index) {
        if (this.label) {        	            

            var clsNode = new Object();
            clsNode.type = this.nodeType;
		  	clsNode.name = this.name;
		  	clsNode.label = this.label;
		  	clsNode.parentId = this.parentId;
  			clsNode.rootId = this.rootId;
		  	clsNode.Id = this.nodeId;
		  	clsNode.lvl = this.nodeLvl;
		  	clsNode.leaf = this.leaf;
		  	clsNode.expanded = this.expanded;
		  	clsNode.focus = this.focus;
  			clsNode.productCount = this.productCount;
  			clsNode.imageUrl = this.imageUrl;
		  	arry.push(clsNode);

            // if there are sub items, call the buildClsNodes function.
            if (this.childList && this.childList.length > 0) {                
                buildClsNodes(this.childList);
            }
        }
    });

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
	        parent.attr = {"Id" : parent.value.Id,
	        			 	"hasImage" : hasImage,
	        			 	"Type" : parent.value.type, 
	        			 	"Leaf" : parent.value.leaf, 
	        			 	"rootId" : parent.value.rootId, 
	        			 	"nodeLvl" : parent.value.lvl,
	        			 	"objId" : parent.value.Id};
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
		        								"Leaf" : parent.children[i].value.leaf, 
		        								"hasImage" : hasImage, 
		        								"Type" : parent.children[i].value.type,
		        								"rootId" : parent.value.rootId,
		        								"nodeLvl" : parent.value.lvl,
		        								"objId" : parent.value.Id};
		            findChildren(parent.children[i]);
		        }
	        }
	    //}
	};

	// enumerate through to handle the case where there are multiple roots
	for (var i = 0, len = roots.length; i < len; ++i) {
	    findChildren(roots[i]);
	}

	//console.log(roots);
	return roots;
}	
		


var YAHOO = { force :{ com :{ choicePanel:{ hide:function(){}, show:function(){} } } }};
var aptLoadingPageHeader = j$.APTTUS.loadingPageLabel;
var aptRuleAlertHeader = j$.APTTUS.constraintRuleAlertLabel;
var aptDialogBody = '<center><img src="'+j$.APTTUS.ImageLoadingPageURL+'" /></center>';

/**
 * override lib functions pointing to yahoo lib
 */ 	
function onActionClick2(){
	
}
	
/**
 * override lib functions pointing to yahoo lib
 */ 	
function onActionComplete2(){
	
}
	
// array contains function
Array.prototype.contains = function (element) {
	for (var i = 0; i < this.length; i++) {
		if (this[i] == element) {
			return true;
			
		}
		
	}
	
	return false;
	
}

// array of line numbers already priced by the previous pricing call
var alreadyPriced = new Array();

/**
 * Initializes the call to webservices api
 */
function initCall() {
	try {
    	sforce.connection.sessionId = j$.APTTUS.sessionID; //to avoid session timeout
                
    } catch(ex) {
    	cp_erroralert(cp_cERROR_UNKNOWN,ex);
                
	}
}


/**
 * Get product information and display in popup panel
 * using JavaScript remoting
 */
function getRemoteProductDetail(productId){
	getProductDetail(productId);
}

/**
 * Get mouseover product information
 */
function getProductDetail(productId) {
    document.getElementById('ctxProductDescription').innerHTML = '';        
	Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.getProductDescription, productId, function(result, event){
		    if (event.status) {
		    	j$('.productDetailPanel .ui-dialog-title').html(result.Name);
		        if(result.Description != undefined){
		        	j$('#ctxProductDescription:empty').html(result.Description);
				} else {
					j$('#ctxProductDescription:empty').html('');
				}
			} else {
				j$('#ctxProductDescription:empty').html(event.message);
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
 * disable product row when a product is disabled by exclusion rule
 */
function disableExcludedProducts(configId, productIds) {
	Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.getExcludedProductIds, configId, productIds, function(result, event){
			if (event.status) {
				var idList = result;//eval(result);
				var newExcludeIds = [];
				
				// remove reenabled products from excluded products list, if any
				for(var i=0; i<excludedProductIds.length; i++) {
					// check if the product should be reenabled, that is, if it isn't in idList
					if(idList.indexOf(excludedProductIds[i]) < 0) {
						var contextRow = ".apt-prod-row-" + excludedProductIds[i];
						
						j$(contextRow).css('color', '#222222');
						j$(".aptProductImgContainer", contextRow).removeClass('apt-disabled-product-img');
						j$(".apt-added-indicator", contextRow).removeClass('apt-disabled-product-img');
						j$(".apt-charge-list-label", contextRow).css('color', '#1644D8');
						j$(".apt-charge-list-value", contextRow).css('color', '#1644D8');
						j$(".aptProductButttons", contextRow).css('visibility', 'visible');
						j$("input[type=text]", contextRow).css('background-color', '#FFFFFF');
						//disable rule result prompt products
						j$("input[type=button]", ".apt-rule-prod-btn-"+idList[i]).removeAttr('disabled');//add to cart button
						j$(".apt-rule-prod-"+idList[i]).css('color', '#222222');//product name

					} else {
						newExcludeIds.push(excludedProductIds[i]);

					}
				}

				excludedProductIds = newExcludeIds;

				// disable what needs to be disabled
		    	for (var i=0; i<idList.length; i++) {
		    		// add excluded product id to list if it isn't already in the list
		    		if(excludedProductIds.indexOf(idList[i]) < 0) {
		    			excludedProductIds.push((idList[i]));

		    		}

		    		var contextRow = ".apt-prod-row-" + idList[i];
					j$(contextRow).css('color', 'lightgrey');
					j$(".aptProductImgContainer", contextRow).addClass('apt-disabled-product-img');
					j$(".apt-added-indicator", contextRow).addClass('apt-disabled-product-img');
					j$(".apt-charge-list-label", contextRow).css('color', 'lightgrey');
					j$(".apt-charge-list-value", contextRow).css('color', 'lightgrey');
					j$(".aptProductButttons", contextRow).css('visibility', 'hidden');
					//j$("input", contextRow).attr('disabled', 'disabled'); disabling input field causes binding problem
					j$("input[type=text]", contextRow).css('background-color', 'lightgrey');
					//disable rule result prompt products
					j$("input[type=button]", ".apt-rule-prod-btn-"+idList[i]).attr('disabled', 'disabled');//add to cart button
					j$(".apt-rule-prod-"+idList[i]).css('color', 'lightgrey');//product name
		    	}
		    	
			} else {
		    	//console.log(event.message);
			}
     	}, {buffer:false, escape:true});
	
}


var classificationId;// = "{!classificationId}";
	        				 
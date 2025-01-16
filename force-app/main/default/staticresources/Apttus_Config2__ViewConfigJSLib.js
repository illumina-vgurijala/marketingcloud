/**
 *	Apttus Config & Pricing
 *	viewconfig.js
 *	 
 *	@2012-2013 Apttus Inc. All rights reserved.
 * 
 */

/**
 * Initializes the call
 */
function initCall() {

	try {
		sforce.connection.sessionId = aptSessionId;//"{!$Api.Session_ID}"; //to avoid session timeout
	} catch(e) {
		cp_erroralert(cp_cERROR_UNKNOWN,e);
		
	}

}

// wait panel

/**
 * Builds the wait panel.
 */
YAHOO.force.com.buildWaitPanel = function() {
    document.body.className = document.body.className + " yui-skin-sam";
    YAHOO.force.com.waitPanel = new YAHOO.widget.Panel(
        "waitPanel",  // The id of our dialog container
        { 
                width           :   "300px", // You can play with this until it's right
                visible         :   false,   // Should be invisible when rendered
                draggable       :   false,   // Make the dialog draggable
                close           :   false,   // Don't include a close title button
                modal           :   true,    // Make it modal
                fixedCenter     :   true,    // Keep centered if window is scrolled
                zindex          :   40,      // Make sure it's on top of everything
                constraintoviewport: true,
                
                // This line adds the appear/disapper fade effect
                effect			:   {effect:YAHOO.widget.ContainerEffect.FADE,duration:0.25}
							
        }
    );
    
    // header
    YAHOO.force.com.waitPanel.setHeader(aptLoadingPageHeader);//"{!$Label.LoadingPage}");
	// set image
	YAHOO.force.com.waitPanel.setBody(aptLoadingPageBody);//'<center><img src="{!URLFOR($Resource.Image_LoadingPage)}" /></center>');
    // Render the dialog to the document.body level of the DOM
    YAHOO.force.com.waitPanel.render(document.body);
    
}

/**
 * Callback when the action button is clicked
 */
function onActionClick() {
	// show the modal panel
	YAHOO.force.com.waitPanel.show();
	// return false to allow the action to proceed
	return false;
	
}

/**
 * Callback when the action is completed
 */
function onActionComplete() {
	// hide the modal panel
	YAHOO.force.com.waitPanel.hide();
	
}

// confirmation panel

//YAHOO.force.com.myDialog = new Object();
//YAHOO.force.com.selectedLineNbr = new Object();
			
/**
 * Build remove confirmation panel
 */
YAHOO.force.com.buildConfirmationPanel = function() {

    document.body.className = document.body.className + " yui-skin-sam";
    YAHOO.force.com.confirmationPanel = new YAHOO.widget.Panel(
        "confirmationPanel",  // The id of our dialog container
        { 
                width           :   "300px", // You can play with this until it's right
                visible         :   false,   // Should be invisible when rendered
                draggable       :   true,    // Make the dialog draggable
                close           :   false,   // Don't include a close title button
                modal           :   true,    // Make it modal
                fixedCenter     :   true,    // Keep centered if window is scrolled
                zindex          :   40,      // Make sure it's on top of everything
                
                // This line adds the appear/disapper fade effect
                effect          :   {effect:YAHOO.widget.ContainerEffect.FADE,duration:0.25} 
        }
     );
    
    // Render the dialog to the document.body level of the DOM
    YAHOO.force.com.confirmationPanel.render(document.body);
    //YAHOO.force.com.confirmationPanel.render();
    
}

/**
 * Show remove confirmation dialog
 */
YAHOO.force.com.showRemoveConfirmation = function(lineNumber) {
	// save selected line item line number
	YAHOO.force.com.selectedLineNbr = lineNumber;
	YAHOO.force.com.selectedLineItemId = null;
	// show the confirmation panel
	document.getElementById("confirmationPanel").style.display = "block";
    YAHOO.force.com.confirmationPanel.show();
    
}

/**
 * Show remove confirmation dialog
 */
YAHOO.force.com.showRemoveConfirmation2 = function(lineItemId) {
	// save selected line item id
	YAHOO.force.com.selectedLineItemId = lineItemId;
	YAHOO.force.com.selectedLineNbr = null;
	// show the confirmation panel
	document.getElementById("confirmationPanel").style.display = "block";
    YAHOO.force.com.confirmationPanel.show();
    
}

/**
 * Handle remove product option group or product option component
 */
YAHOO.force.com.remove = function() {
	// hide the confirmation panel
    YAHOO.force.com.confirmationPanel.hide();
    // show modal panel
	YAHOO.force.com.waitPanel.show();
	// delete the line item
	if (YAHOO.force.com.selectedLineNbr) {
		doDeleteLineItem(YAHOO.force.com.selectedLineNbr);
	
	} else if (YAHOO.force.com.selectedLineItemId) {
		doDeleteCustomLineItem(YAHOO.force.com.selectedLineItemId);
		
	}
	    			
}

// miscellaneous line item panel
	
/**
 * Builds the miscellaneous item panel
 */
YAHOO.force.com.buildMiscItemPanel = function() {
	//document.body.className = document.body.className + " yui-skin-sam";
    
    YAHOO.force.com.miscItemPanel = new YAHOO.widget.Panel(
        "miscItemPanel",  // The id of our dialog container
        { 
                width           :   "400px", // You can play with this until it's right
                visible         :   false,   // Should be invisible when rendered
                draggable       :   true,    // Make the dialog draggable
                close           :   false,   // Don't include a close title button
                modal           :   true,    // Make it modal
                fixedCenter     :   true,    // Keep centered if window is scrolled
                zindex          :   40,      // Make sure it's on top of everything
                
                // This line adds the appear/disapper fade effect
                effect          :   {effect:YAHOO.widget.ContainerEffect.FADE,duration:0.25} 
        }
     );
    
    // Render the dialog to the document.body level of the DOM
    YAHOO.force.com.miscItemPanel.render(document.body);
   
}

/**
 * Callback when the add miscellaneous item button is clicked
 */
function onAddMiscItemClick() {
	
	// reset panel field values
	fldMiscChargeType.value = "";
	fldMiscDescription.value = "";
	fldMiscAmount.value = "";
	
	// show the modal panel
	document.getElementById("miscItemPanel").style.display = "block";
	YAHOO.force.com.miscItemPanel.show();
	
}		

/**
 * Callback when the ok action button is clicked
 */
function onOkActionClick() {
	// hide the miscellaneous line item panel
    YAHOO.force.com.miscItemPanel.hide();
    // show modal panel
	YAHOO.force.com.waitPanel.show();
	// return false to allow the action to proceed
	return false;
	
}

/**
 * Callback when the ok action is completed
 */
function onOkActionComplete() {
	// hide the modal panel
	YAHOO.force.com.waitPanel.hide();
	
}

// reprice wait panel

/**
 * Builds the reprice wait panel.
 */
YAHOO.force.com.buildRepriceWaitPanel = function() {
    document.body.className = document.body.className + " yui-skin-sam";
    YAHOO.force.com.repriceWaitPanel = new YAHOO.widget.Panel(
        "repriceWaitPanel",  // The id of our dialog container
        { 
                width           :   "300px", // You can play with this until it's right
                visible         :   false,   // Should be invisible when rendered
                draggable       :   false,   // Make the dialog draggable
                close           :   false,   // Don't include a close title button
                modal           :   true,    // Make it modal
                fixedCenter     :   true,    // Keep centered if window is scrolled
                zindex          :   40,      // Make sure it's on top of everything
                constraintoviewport: true,
                
                // This line adds the appear/disapper fade effect
                effect			:   {effect:YAHOO.widget.ContainerEffect.FADE,duration:0.25}
							
        }
    );
    
    // header
    YAHOO.force.com.repriceWaitPanel.setHeader(aptRepricingHeader);//"{!$Label.Repricing}");
	// set image
	YAHOO.force.com.repriceWaitPanel.setBody(aptLoadingPageBody);//'<center><img src="{!URLFOR($Resource.Image_LoadingPage)}" /></center>');
    // Render the dialog to the document.body level of the DOM
    YAHOO.force.com.repriceWaitPanel.render(document.body);
    
}

/**
 * Callback when the reprice action button is clicked
 */
function onRepriceAllClick() {
	// show the modal panel
	YAHOO.force.com.repriceWaitPanel.show();
	// return false to allow the action to proceed
	return false;
	
}

/**
 * Reprices all line items in the current configuration
 */
function doRepriceAll() {
	
	// get parameters
	// current configuration id
	var configId = aptConfigId;//"{!configurationId}";

	try {
		
		// STEP I - initialize the call
		initCall();
	
		// STEP II - get summary line items from the configuration
		var result = getSummaryLineItemsForConfiguration(configId);
		
		var numItems = result.length;
		
		// STEP III - Reprice each summary line item
		for (var i = 0; i < numItems; i++) {
			// compute base price
			computeBasePriceForItemColl(configId, result[i].LineNumber);
			
		}
		
		// STEP IV - Compute total price
		computeTotalPriceForCart(configId);
		
	} catch(ex) {
		// hide modal panel
		YAHOO.force.com.repriceWaitPanel.hide();
		// display the error
		cp_erroralert(cp_cERROR_UNKNOWN, ex);
		
	} finally {
		// reload the page
		doReload();
		
	}
	
}

/**
 * Reprices the given line item
 */
function doCheckAndRepriceLineItems() {
    
     // register to invoke the function after the page load
    var isItemPricePending = aptIsPricePending;//"{!IsPricePending}";
	var isAdjustmentsPending = aptIsAdjustmentsPending;//"{!IsAdjustmentsPending}";
	
    if (isItemPricePending.toLowerCase() == 'false' && 
    	isAdjustmentsPending.toLowerCase() == 'false') {
        // no pending price or adjustments. abort
        return;
        
    }
    
    // get parameters
    // current configuration id
    var configId = aptConfigId;//"{!configurationId}";

    try {
    	
    	if (isItemPricePending.toLowerCase() == 'true') {
            // STEP I - get summary line items from the configuration
            var numItems = aptNumItems;//"{!NumOfLineItemsAwaitingPrice}";
           
            // STEP II - Reprice the line item
            if (numItems > 0) {
                //alert(numItems);
                // show the modal panel
                YAHOO.force.com.repriceWaitPanel.show();
                // reprice line item
                doRepriceLineItem(configId, numItems, 0);
                
            } else if (isAdjustmentsPending.toLowerCase() == 'true') {
				// show the modal panel
                YAHOO.force.com.repriceWaitPanel.show();
                // apply adjustments
                doApplyAdjustments();
			
			} else {
             	// show the modal panel
            	YAHOO.force.com.repriceWaitPanel.show();
            	// compute total price
            	doComputeTotalPrice(configId);
            
            }
            
		} else if (isAdjustmentsPending.toLowerCase() == 'true') {
			// show the modal panel
            YAHOO.force.com.repriceWaitPanel.show();
            // apply adjustments
            doApplyAdjustments();
		
		}
		
    } catch(ex) {
        // hide modal panel
        YAHOO.force.com.repriceWaitPanel.hide();
        // display the error
        cp_erroralert(cp_cERROR_UNKNOWN, ex);
    
    } 
    
}

/**
 * Reprices the given line item
 */
function doRepriceLineItem(configId, numItems, currIndex) {
    
    try {
        
        if (currIndex < numItems) {
        
            // STEP I - initialize the call
        	aptClassName.doComputeBasePriceForNextItemColl(configId, function(result, event) {
            
                try {
                    // check response status
                    if (event.status) {
                        // ok response, increment the index
                        currIndex++;
                        // check if done
                        if (currIndex < numItems) {
                            // more to go
                            doRepriceLineItem(configId, numItems, currIndex);
                            
                        } else {
                            // compute total price
                            doComputeTotalPrice(configId);
                        
                        }
                        
                    } else {
                        // throw exception
                        alert(event.message);
                        // hide modal panel
        				YAHOO.force.com.repriceWaitPanel.hide();
                        // reload the page
                        //doReload();
                    
                    }
                    
                } catch(ex) {
                    // hide modal panel
                    YAHOO.force.com.repriceWaitPanel.hide();
                    // display the error
                    cp_erroralert(cp_cERROR_UNKNOWN, ex);
                    // reload the page
                    //doReload();
                      
                } 
                
            }, {escape:true});
          
         }
          
    } catch(ex) {
         // hide modal panel
        YAHOO.force.com.repriceWaitPanel.hide();
        // display the error
        cp_erroralert(cp_cERROR_UNKNOWN, ex);
        
    } 
    
}

/**
 * Reprices the given line item
 */
function doRepriceLineItemColl(configId, lineNumber) {
 
    // STEP I - initialize the call
	aptClassName.doComputeNetPriceForItemColl(configId, lineNumber, function(result, event) {
    
        try {
             // check response status
             if (event.status) {
                 // ok response (reload the page)
                 
             } else {
                 // throw exception
                 alert(event.message);
                 
             } 
         } catch(ex) {
                // display the error
                cp_erroralert(cp_cERROR_UNKNOWN, ex);
                
         } finally {
            // reload the page
            doReload();
                
         }    
        
    }, {escape:true});
           
}

/**
 * Computes the total price for the cart
 */
function doComputeTotalPrice(configId) {

    // STEP I - initialize the call
	aptClassName.doComputeTotalPriceForCart(configId, function(result, event) {
     
        try {
            // check response status
            if (event.status) {
                // ok response (reload the page)
                
            } else {
                // throw exception
                alert(event.message);
                
            } 
        } catch(ex) {
               // display the error
               cp_erroralert(cp_cERROR_UNKNOWN, ex);
               
        } finally {
           // reload the page
           doReload();
               
        }   
        
    }, {escape:true});
           
}

/**
 * Clones the given [rimary line item
 */
function doCopyLineItem(lineNumber) {
    
    try {
        
        // current configuration id
    	var configId = aptConfigId;//"{!configurationId}";
        // show the modal panel
        YAHOO.force.com.waitPanel.show();
            
        // STEP I - initialize the call
        aptClassName.doClonePrimaryItemColl(configId, lineNumber, function(result, event) {
        
            try {
                // check response status
                if (event.status) {
                    // ok response, compute total price
                    doRepriceLineItemColl(configId, event.result);
                    
                } else {
                    // throw exception
                    alert(event.message);
                    // hide modal panel
    				YAHOO.force.com.waitPanel.hide();
                    // reload the page
                    //doReload();
                
                }
                
            } catch(ex) {
                // hide modal panel
                YAHOO.force.com.waitPanel.hide();
                // display the error
                cp_erroralert(cp_cERROR_UNKNOWN, ex);
                // reload the page
                //doReload();
                  
            } 
            
        }, {escape:true});
          
    } catch(ex) {
         // hide modal panel
        YAHOO.force.com.waitPanel.hide();
        // display the error
        cp_erroralert(cp_cERROR_UNKNOWN, ex);
        
    } 
    
}

/**
 * Builds the product detail panel
 */
YAHOO.force.com.buildProductDetailPanel = function() {
	//document.body.className = document.body.className + " yui-skin-sam";
    
    YAHOO.force.com.productDetailPanel = new YAHOO.widget.Panel(
        "productDetailPanel",  // The id of our dialog container
        { 
            	width           :   "600px", // You can play with this until it's right
                fixedcenter 	:	"contained",
                visible         :   false,   // Should be invisible when rendered
                draggable       :   true,    // Make the dialog draggable
                modal           :   true,    // Make it modal
                close			:	true,
                zindex          :   40,      // Make sure it's on top of everything
                		                    
                // This line adds the appear/disapper fade effect
                effect          :   {effect:YAHOO.widget.ContainerEffect.FADE,duration:0.25} 
        }
     );
    
    // Render the dialog to the document.body level of the DOM
    YAHOO.force.com.productDetailPanel.render();
    
}		

/**
 * Get mouseover product information
 */
function getProductDetail(productId) {
	
	document.getElementById('ctxProductName').innerHTML = aptLoadingPageHeader;//"{!$Label.LoadingPage}";
    document.getElementById('ctxProductDescription').innerHTML = '';
        
    aptClassName.getProductDescription(productId, function(result, event){
	    if (event.status) {
	        document.getElementById('ctxProductName').innerHTML = result.Name;
	        if(result.Description != undefined){
	        	document.getElementById('ctxProductDescription').innerHTML = result.Description;
			}
		} else {
	    	document.getElementById('ctxProductDescription').innerHTML = event.message;
		}
   	}, {escape:true});
	
	showProductDetailPanel();
	
}			

/**
 * Callback when mouseover product information icon
 */
function showProductDetailPanel() {
	
	// show the modal panel
	document.getElementById("productDetailPanel").style.display = "block";				
	YAHOO.force.com.productDetailPanel.show();
	
}	
		
// Function called when the DOM is ready to create the dialog,
// render the dialog into the document body, add our dialog skin
// css to the body tag, and wire up the buttons on our dialog   
YAHOO.force.com.onDOMReady = function() {
	// build the confirmation panel
	YAHOO.force.com.buildConfirmationPanel();
	// build the misc item panel
	YAHOO.force.com.buildMiscItemPanel();
	// build the wait panel
	YAHOO.force.com.buildWaitPanel();
	// build the reprice wait panel
	YAHOO.force.com.buildRepriceWaitPanel();
	// build the product detail panel
	YAHOO.force.com.buildProductDetailPanel();
	// check and reprice pending line items
    doCheckAndRepriceLineItems();
	
}

//hide message and call doHideMessage function to update the appliedActionInfo record HideMessage field
function aptHideMessage(ele, actionInfoId){
	if(ele.parentNode != undefined){
		ele.parentNode.style.visibility = "hidden";
	}
	invokeDoHideMessage(actionInfoId);
}	

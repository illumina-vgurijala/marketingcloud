/**
 *	Apttus Config & Pricing
 *	CPQPricingJS.js
 *	 
 *	@2012-2013 Apttus Inc. All rights reserved.
 * 
 */

/**
 * Calculates price for all pending line items
 */

 j$(function() {
    if(j$.aptActionFunctionQueue) {
        // set global variables for behavior in queue
        j$.aptActionFunctionQueue.setSkipToEndOfQueue(sfdcInvokePageRefresh);
        j$.aptActionFunctionQueue.setPrecedence(sfdcInvokePageRefresh, -100);    // refresh page after pricing is complete
    }
 });

var isPricingOn = false; //keeps track of pricing queue

function doAutomaticPricing() {
    // current configuration id
    var configId = j$.APTTUS.configurationId;
    // console.log('start doAutomaticPricing configId = ' + configId);
    j$.aptActionFunctionQueue.execute(doUpdatePriceForCart, [configId], {disableBuffering: true, loadingLabel:j$.APTTUS.updatingPriceLabel});
    
}

/**
 * Updates the price for items in the given product configuration
 * Only line items in pending status are updated.
 * Total price is always computed
 * @param configId the product configuration id to update the price for
 * @param oncomplete callback function after the remote call is complete
 */
function doUpdatePriceForCart(configId, oncomplete) {
    //console.log('doUpdatePriceForCart configId = ' + configId + ', time :' + new Date() );
    if (isPricingOn == true) {
    	//console.log('doUpdatePriceForCart is invoked when pricing was on');
    	return;
    }

    var updatePriceCallback = 
        function(result, event) {
            try {
                isPricingOn = false;
                // check response status
                if (event.status) {
                    // ok response, check if done
                    //if (result.IsPricePending.toLowerCase() == 'true') {
                    if (result.IsPricePending == true) {
                        // more to go
                        doUpdatePriceForCart(configId, oncomplete);                        
                        
                    } else {
                        // reload the page                        
                        invokePageRefresh(oncomplete, true);                    
                    }
                    
                } else {
                    // throw exception
                    //alert(event.message);
                    // reload the page                    
                    invokePageRefresh(oncomplete, false);
                
                }
                
            } catch(ex) {
                // display the error
                cp_erroralert(cp_cERROR_UNKNOWN, ex);
                // reload the page                
                invokePageRefresh(oncomplete, false);
                  
            }

        }

    isPricingOn = true;
    try {
        if(typeof(j$.APTTUS.ctxBundleNumber) !== 'undefined') {//param passed by bundle page
            Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doUpdatePriceForCart, configId, j$.APTTUS.ctxBundleNumber, updatePriceCallback,
                                                      {buffer:false, escape:true, timeout:120000 });

        } else {
            Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doUpdatePriceForCart, configId, updatePriceCallback, 
                                                      {buffer:false, escape:true, timeout:120000 });
                                                                                                            
        }
    } catch(ex) {
        // display the error
        cp_erroralert(cp_cERROR_UNKNOWN, ex);
        // reload the page        
        invokePageRefresh(oncomplete, false);
        // Call process next on failure.
    } 
}



/**
 * Calculates price for all pending line items
 * @param contextLineNumber is passed only from attribute and options pages
 */
function doPricePendingLineItems(contextLineNumber) {
	alert('wrong function call doPricePendingLineItems');
    
}

/**
 * compute price for the given line item
 */
function computeBasePriceForItemColl(configId, lineNumbers, currIndex) {
	alert('wrong function call computeBasePriceForItemColl');
    
}

/**
 * compute price for the given line item
 * and compute total price
 */
function computeNetPriceForItemColl(configId, lineNumber) {
	alert('wrong function call computeNetPriceForItemColl');
    
}

/**
 * compute total price
 * doUpdatePriceForCart computes total price when there are no pending line items
 */
function doComputeTotalPrice() {
	// current configuration id
    var configId = j$.APTTUS.configurationId;
    j$.aptActionFunctionQueue.execute(doUpdatePriceForCart, [configId], {disableBuffering: true, loadingLabel:j$.APTTUS.updatingPriceLabel});
    
}

/**
 * Show pricing wait dialog
 */
j$.APTTUS.showPricingWaitPanel = function() { 	
  	// Create and open dialog window
  	j$.APTTUS.pricingWaitPanel = 
	 	j$("#pricingWaitPanel").dialog({
	 		dialogClass: "no-close pricingWaitPanel",
	 		autoOpen: true,	 			 		
	 		resizable: false,
	 		modal: true,
	 		position: 'center',
	 		draggable: true,
	 		height:110,
	 		title : j$.APTTUS.updatingPriceLabel,
	 		create:function(){
				j$('.pricingWaitPanel .ui-dialog-titlebar').remove();
			}
	 	});

  	return false;
  	
}

/**
 * Hide the pricing wait dialog
 */
j$.APTTUS.hidePricingWaitPanel = function () {
	if(typeof j$.APTTUS.pricingWaitPanel !== 'undefined') {
		j$.APTTUS.pricingWaitPanel.dialog("close");
	}

}

/**
 * Invoke page refresh after automatic pricing
 * accepts callback to execute after page refresh.
 */
function invokePageRefresh(doneCallback, success) {
	if(!j$.aptActionFunctionQueue.getIsQueuePaused()) {
		//invoke to page refresh
		if(j$.APTTUS.IsBypassShoppingCart) {
			j$.APTTUS.hidePricingWaitPanel();
			j$.aptActionFunctionQueue.execute(sfdcInvokePageRefresh, null, {disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel})
	        .then(
	            function() {
	                if(typeof doneCallback === 'function') {
	                    doneCallback(success);
	        
	                 }
	             }
	        );
        } else {
        	if(typeof doneCallback === 'function') {
				doneCallback(success);
			}
        }
	}

	j$.aptActionFunctionQueue.processNext();

}

function invokeRefreshMiniCart() {
    //invoke refresh mini cart
    if (sfdcInvokeRefreshMiniCart) {
        j$.aptActionFunctionQueue.execute(sfdcInvokeRefreshMiniCart, null, {disableBuffering:true, loadingLabel:j$.APTTUS.refreshingDataLabel});
    }
}

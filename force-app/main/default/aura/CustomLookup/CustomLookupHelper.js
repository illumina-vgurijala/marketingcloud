({
	searchHelper : function(component,event,getInputkeyWord) {
	 // call the apex class method 
   let action = component.get("c.fetchLookUpValues");
      // set param to method  
    action.setParams({
            'strSearchKeyWord': getInputkeyWord,
            'strObjectName' : component.get("v.strobjectAPIName")
                    });
    // set a callBack    
    action.setCallback(this, function(response) {
		$A.util.removeClass(component.find("mySpinner"), "slds-show");
    let state = response.getState();
        if (state === "SUCCESS") {
          let storeResponse = response.getReturnValue();
            // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
            if (storeResponse.length == 0) {
				component.set("v.strMessage", 'No Result Found...');
            }
			else {
                component.set("v.strMessage", '');
                }
                // set searchResult list with return value from server.
            component.set("v.lstListOfSearchRecords", storeResponse);
            }
 
        });
      // enqueue the Action  
      $A.enqueueAction(action);
    
	},
})
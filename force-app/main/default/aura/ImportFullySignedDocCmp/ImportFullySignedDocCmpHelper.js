({
    updateStatus: function(component, event) {
        // retrieve document id and name
        let uploadedFiles = event.getParam("files");
        let documentId = uploadedFiles[0].documentId;
        console.log('documentId: ' + documentId);
        
        // invoke apex controller method
        let action = component.get("c.processDocument");
        action.setParams({
            agreementId: component.get("v.recordId"),
            documentId: documentId,
        });
        
        // callback function to be executed when server response is received
        action.setCallback(this, function(response) {
            let state = response.getState();
            console.log('state: ' + state);
            let toastEvent = $A.get("e.force:showToast");
            
            if (state === "SUCCESS") {    
                let result = response.getReturnValue()
                console.log('response-->'+result);
                
                let spinner = component.find("mySpinner");
        		$A.util.toggleClass(spinner, "slds-hide");
                
                // show success message and close File Upload Panel
                if(result.isSuccess){
                    toastEvent.setParams({                    
                        "title": "Success!",
                        "type" : "success",
                        "duration" : 15000,
                        "mode" : "dismissible",
                        "message": "Document has been imported successfully!"
                    });
                    toastEvent.fire();                    
                    $A.get('e.force:refreshView').fire();       
				// show error message if server returned an error                    
                }else{
                    toastEvent.setParams({                    
                        "title": "Failure!",
                        "type" : "error",
                        "mode" : "sticky",
                        "message": "Import Fully Signed Document action couldn't be completed successfully due to an error: \n\n" + result.errorMsg
                    });
                    toastEvent.fire();  
                }                
            }else {
                let errors = response.getError();
                console.log('errors-->'+errors);
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log("Error message: " + errors[0].message);    
                    
                    toastEvent.setParams({                    
                        "title": "Failure!",
                        "type" : "error",
                        "mode" : "sticky",
                        "message": "Document couldn't be imported successfully due to an error: \n" + errors[0].message
                    });
                    toastEvent.fire(); 
                } else {
                    console.log("Unknown error");
                }
            }            
            // Close the action panel
            let navEvent = $A.get("e.force:navigateToSObject");
            navEvent.setParams({
                recordId: component.get("v.recordId"),
                slideDevName: "detail"
            });
            navEvent.fire();
            
        });
        $A.enqueueAction(action);
    },
})
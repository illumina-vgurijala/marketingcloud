({
    moveToExisitingCase: function(component) {
        
        //store the map keys
        let arrayOfMapKeys = [];
        //get the map which was set in the controller.
        let StoreResponse = component.get("v.caseIdToEmailMessageId");
        //show spinner
        component.set("v.spinner", true);
        //apex controller method linkage
        let action = component.get('c.moveToExisitingCase');
        //pass the javascript map to apex controller method map parameter
        action.setParams({
            "caseIdToEmailMessageId": component.get("v.caseIdToEmailMessageId")
        });
        
        //processing response back from server
        action.setCallback(this, function(response) {
            
            let state = response.getState(); // get the response state
            console.log('state ' + state);
            
            if (state == 'SUCCESS') {
                
                //store the response
                let responseBackMessage = response.getReturnValue();
				console.log('response back ' + JSON.stringify(response.getReturnValue()));
                
                //if there was no error in apex controller logic, move ahead.
                if (!responseBackMessage.includes('Error')) {
                    
					//show success toast
                    this.showToast(component, 'success', 'Email has been successfully copied.');
                    //hide spinner
                    component.set("v.spinner", false);
                    component.set("v.showSearchbox", false);
					//store the selected case id to be used to redirect.
                    for (let singlekey in StoreResponse) {
                        arrayOfMapKeys.push(singlekey);
                    }

                    //navigate to selected case.
                    let navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": arrayOfMapKeys[0]
                    });
                    //redirect using case id.
                    navEvt.fire();

                } else {
                    //show an error on the lightning component.
                    this.showNotification(component, 'error', 'Something went wrong.', response.getReturnValue());
                }

			component.set("v.spinner", false);
            } else {
                //var errors = response.getError();
                this.showNotification(component, 'error', 'Something went wrong.', response.getReturnValue());
            	component.set("v.spinner", false);
            }
        });
        $A.enqueueAction(action);

    },
    fetchRelatedToObjectName: function(component, type, message) {
    component.set("v.spinner", true);
    //apex controller method linkage
    let action = component.get('c.getRelatedToSobject');
        //pass the javascript map to apex controller method map parameter
        action.setParams({
            "emailMessageRecordId": component.get("v.recordId")
        });
        //processing response back from server
        action.setCallback(this, function(response) {
            
            let state = response.getState(); // get the response state
            console.log('state ' + state);
            
            if (state == 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.relatedToSobject",response.getReturnValue());
                console.log('response back ' + JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue() !== 'Case'){
                this.showNotification(component, 'error', 'Not allowed.', 'Email messages can only be copied to related Cases.');
               } else {
                component.set("v.showSearchbox",true);  
                   component.set("v.spinner", false);
                }
            } else {
                //var errors = response.getError();
                this.showNotification(component, 'error', 'Something went wrong.', response.getReturnValue());
            component.set("v.spinner", false);
            }
        });
        $A.enqueueAction(action);
    },
    showToast: function(component, type, message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    showNotification: function(component, type, header, message) {

        component.find('notifLib').showNotice({
            "variant": type,
            "header": header,
            "message": message,
            closeCallback: function() {
           
            if(component.get("v.relatedToSobject") != 'Case'){
                $A.get("e.force:closeQuickAction").fire();   
                }    
             
             }
        });

    }

})
({
    doinitHelper : function(component, event, helper) {
        let strRecordId = component.get("v.recordId");
        let action = component.get("c.updatePartnerRequestRecord");
        action.setParams({
            idRecord : strRecordId
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let res=  response.getReturnValue();
                let resultsToast = $A.get("e.force:showToast");
                if(res === 'success'){
                    resultsToast.setParams({
                        "title": "Saved",
                        "type": "success",
                        "message": "The record updated Successfully"
                    });
                }else{
                    console.log('res-->>'+ res);
                }
                resultsToast.fire();
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            }
            else if (state === "INCOMPLETE") {
                console.log('INCOMPLETE-->>'+ state);
            }
                else if (state === "ERROR") {
                    let errors = response.getError();
                    console.log('errors-->>', errors);
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    }   
})
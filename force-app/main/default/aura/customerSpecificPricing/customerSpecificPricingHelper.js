({
    checkTerritoryAccess : function(component, event, helper) {
        
        let actionn = component.get("c.getTerritoryAccess");
        
        let reccId = component.get("v.recordId");
        
        actionn.setParams({accId : reccId}); 
        
        actionn.setCallback(this, function(resp) {
            let state = resp.getState();
            if (state === "SUCCESS") 
            {
                let res = resp.getReturnValue();
                if(res == false)
                {
                    $A.get("e.force:closeQuickAction").fire();
                    this.showToast(component, event, helper,$A.get("$Label.c.Insufficent_access_Message_CSP"),'error','Error');                    
                    component.set("v.showSpinner",false);
                }
                else{   //Cmcp-13 Call the helper method to check the cp access  
                    
                    helper.checkCpDistributorAccount(component, event, helper);
                    component.set('v.showMultiSelect',true);
                }
                
            }  
        });
        $A.enqueueAction(actionn);
    },
    showToast : function(component, event, helper,messagetext,typetext,titletext) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": typetext,
            "title": titletext,
            "message": messagetext
        });
        toastEvent.fire();
    },

    /* 
*  @author Saddam Hussain 
*  @description Check if current user is CP and current Account record's ID=CP user's Account ID CMCP-13
 */
    checkCpDistributorAccount : function(component, event, helper) {
        
        let action = component.get("c.checkAccessCP");
        let recordId = component.get("v.recordId");
        action.setParams({accountId : recordId}); 
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") 
            {
                if(!resp.getReturnValue())
                {
                    $A.get("e.force:closeQuickAction").fire();
                    this.showToast(component, event, helper,$A.get("$Label.c.Insufficent_access_Message_CP"),'error','Error');                    
                }
                component.set("v.showSpinner",false);
            }  
        });
        $A.enqueueAction(action);
    }
})
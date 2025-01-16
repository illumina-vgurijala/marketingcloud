({
    recordUpdated : function(component, event, helper){
        
        let changeType = event.getParams().changeType;
        if (changeType === "LOADED")
        {
            let agreement = component.get("v.objTargetAgreement");
            if(agreement.Apttus_Approval__Approval_Status__c != 'Pending Approval'){
                $A.get("e.force:closeQuickAction").fire();
                helper.showErrorToast($A.get("$Label.c.UI_Error_Status_Message"));  
            }
            else
            {
                component.set('v.spinner',false);
            }
        }
    },
    
    recall : function(component, event, helper) {
        helper.recallAgreement(component, event, helper);
    },
     
    cancel : function(component, event, helper){
       let closeEvent = $A.get("e.force:closeQuickAction");
       if(closeEvent){
         closeEvent.fire();
       } else {
         alert($A.get("$Label.c.UI_Quick_Action_Not_Supported_Error"));
       }
    } 
})
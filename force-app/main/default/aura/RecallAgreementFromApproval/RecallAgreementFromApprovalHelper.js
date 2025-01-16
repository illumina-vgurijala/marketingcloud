({   
    recallAgreement : function(component,event,helper) {
        
        let agreement = component.get("v.objTargetAgreement");
        let recordId = component.get("v.recordId");
        helper.callServer(component,"c.recallAgreement",function(response){
            
            if(response == 'SUCCESS'){              
                $A.get('e.force:refreshView').fire(); 
                $A.get("e.force:closeQuickAction").fire();
            }
            else
            {
                helper.showErrorToast(response);
            }
        },{"agreementId": recordId},false,false);
    }
})
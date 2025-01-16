({
    doInit : function(component, event, helper){
        helper.initComponent(component,event,helper);
    },
    handleClick : function(component, event, helper) {  
        let partnerRequest = component.get("v.partnerRequest");
        let allValid = true;
        let howCanWeHelp = partnerRequest.How_Can_We_Help__c;
        
        if(howCanWeHelp.trim() == '' || howCanWeHelp == undefined || howCanWeHelp == null){
            allValid = false;
        }
        
        if(allValid){
            helper.callServer(component,"c.saveHelpRequest",function(response){
                if(response == ''){
                    helper.showToast("Saved","The record was saved successfully.","success","dismissible","200");
                    helper.initComponent(component,event,helper);
                }else{
                    helper.showErrorToast(response); 
                }
            },{
                "partnerRequest" : partnerRequest,
                "objectApiName" : "Partner_request__c",
                "recordTypeName" : "Help Request"
            }); 
        }else{            
           	component.find('help').focus();
            helper.showErrorToast("Please enter what you need help with before submitting the request.");
        }
    }
})
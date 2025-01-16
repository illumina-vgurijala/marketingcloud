({
    getDetails : function(component, helper) {
        let pageReference = component.get("v.pageReference");
        component.set("v.agreementId", pageReference.state.c__AgreementId);
        component.set("v.action", pageReference.state.c__Action);
        let aggAction = component.get("v.action");
        
        if(aggAction == $A.get("$Label.c.AgreementActionTerminate"))
        {
            component.set("v.isLoaded",true);
        }
        else
        {
            this.callController(component,helper,pageReference.state.c__Action,pageReference.state.c__AgreementId);
        }   
    },

    callTerminateMethod : function(component,helper)
    {
        this.callController(component,helper,'Terminate',component.get("v.agreementId"));
    },
    
    callController : function(component,helper,actionn,strAggId)
    {
        helper.callServer(component,"c.updateAgreementBeforeValidate",function(response) {

            if(!$A.util.isEmpty(response) && response.includes('Error-')){
                setTimeout(function(){
                    helper.showErrorToast(response.replace('Error-',''),'sticky');
                    helper.navigateToRecordPage(component, helper);
                }, '200')
            }else {                
                helper.callServer(component,"c.sendActionRequest",function(response) {            
                    if(response.toString().includes('error')){
						setTimeout(function(){
							helper.showErrorToast(response.toString());
							helper.navigateToRecordPage(component, helper);
						}, '200')
					}
					else{
						if(response.includes('Error-')){
							setTimeout(function(){
								helper.showErrorToast(response.replace('Error-',''),'sticky');
								helper.navigateToRecordPage(component, helper);
							}, '200')
						}
						else{
							setTimeout(function(){
								helper.showSuccessToast(response.toString(),'dismissible');
								window.location.replace("/lightning/r/Apttus__APTS_Agreement__c/"+component.get("v.agreementId")+"/view");
							}, '200')
						}
					}
                },{
                    "strAgreementId" : strAggId,
                    "action" : actionn,
                    "priorValidationStatus" : response
                });
            }
        },{
            "strAgreementId" : strAggId,
            "action" : actionn
        });
    },

    navigateToRecordPage : function(component, helper) {        
        let recId = component.get("v.agreementId");
        let objType = helper.getObjectType();
        let pageReference = {
            type : "standard__recordPage",
            attributes: {
            recordId: recId,
            objectApiName: objType,
            actionName: "view"
            }
        };
    
        let navService = component.find("navService");
        navService.navigate(pageReference, true);
    },
    
    getObjectType : function(component, helper) {
        return "Apttus__APTS_Agreement__c";
        
    }
})
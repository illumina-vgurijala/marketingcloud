({
    loadComponent:function(component,event,helper){
      let options=[
          {value:"",label:"None" },
          {value:"Product Quality Notification",label:"Product Quality Notification"},
          {value:"Product Change Notification",label:"Product Change Notification"},
          {value:"Product Obsolescence Notification",label:"Product Obsolescence Notification"},
      ] ;
           component.set("v.NotificationTypeValues", options);
    },
    validateAndSubmitForm : function(component, event, helper) {
		let validPQNData = component.find('PQNForm').reduce(function (validSoFar, inputCmp) {
            // Displays error messages for invalid fields
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        
        if(validPQNData){
            component.set("v.boolSpinnerIntegrationStatus",true);
            helper.SendPQNData(component,event);
        }
        
        
	},	
    HandleIntSucess:function(component,event,helper){
        console.log('we-'+component.get('v.objSelectedLookUpRecord'));
        helper.showSuccessToast("Data Submitted. You will be notified by Email","pester",100);
        component.set("v.strBatchJobStatus","Data Submitted. You will be notified by Email");

        helper.CreateCampaignMembership(component,event);
	},
    displayFileComponent:function(component,event,helper){
        let boolcampaignSelected = event.getParam("EventSelected");
        console.log("boolcampaignSelected-"+boolcampaignSelected);
        component.set("v.DisplayFileComp",boolcampaignSelected);
        
    },
    displayFormComponent:function(component,event,helper){
    let boolFileSelected = event.getParam("FileSelected");
        console.log("FileSelected-"+boolFileSelected);
        component.set("v.DisplayFormComp",boolFileSelected);
	}
})
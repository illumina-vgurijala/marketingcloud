({
	init : function(component, event, helper) {
		component.set("v.recordTypeId", helper.getURLQueryStringValues()['recordTypeId']);
        
        helper.retrieveProfilePageLayout(component,helper);
         
        
	},
    formPress: function(component, event, helper) {
		console.log('event.keyCode:'+event.keyCode);
		if (event.keyCode != undefined && event.keyCode === 13) {
			event.preventDefault();
			return;
		}
	},
	//Start: DCP-26543 changes
	onSuccess : function(component, event, helper) {
		let payload = event.getParams().response;
		let MDRrecordId=payload.id;
		component.set('v.recordId', MDRrecordId);
		component.set("v.MDRRecordId",MDRrecordId);
		if(!component.get("v.booIsSubmit")){
			component.set("v.UploadFiles",true);
			helper.toggleSpinner(component);
		}else{
			helper.showDismissableSuccess(helper,"Master Data Request Created");
			let pageReference = {
            	type: 'standard__recordPage',
                attributes: {
                    recordId: MDRrecordId,
                    objectApiName:'Master_Data_Request__c',
                    actionName:'view'
                },
            
        	}; 
			let navService = component.find("navService");
			navService.navigate(pageReference);
		}
        
	},

	onError : function(component, event, helper) {
		helper.toggleSpinner(component);
        helper.showDismissableError(helper, "Some error unexpected occured");
	},

	onSubmit : function(component, event, helper) {
		event.preventDefault();
		if(helper.canSave(component,event,helper)){
			helper.toggleSpinner(component);
			let eventFields = event.getParam("fields");
			if(component.get("v.booIsSubmit"))
				eventFields["Trigger_Email__c"] = true;
			
			component.find("MDGForm").submit(eventFields);
		}
	},

	save : function(component, event, helper) {
		component.set("v.booIsSubmit", false);
	},

	submit : function(component, event, helper) {
		component.set("v.booIsSubmit", true);
	},

	cancel : function(component, event, helper) {
		helper.redirectToPageURL('/'+component.get("v.strAccountId"));
	}
	//End: DCP-26543 changes
})
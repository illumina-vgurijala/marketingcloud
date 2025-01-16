({
	loadData : function(component) {
        //Doing server call to get page load info by passsing WO Id
        let action = component.get("c.getAssociatedCodes");
        action.setParams({
            "strWorkOrderId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            console.log("Response state: " + state);
            //Setting attributes based on server response
            if(state === "SUCCESS") {
                let objWrapObject = JSON.parse(response.getReturnValue());
                component.set('v.lstRecords',objWrapObject.lstAssociatedCodes);
                component.set('v.strParentCaseId',objWrapObject.strParentCaseId);
                component.set('v.isChannelPartner',objWrapObject.isChannelPartnerUser);
                if(objWrapObject.lstAssociatedCodes.length > 0)
                 component.set('v.intListSize', objWrapObject.lstAssociatedCodes.length);
            }else{
                this.showToast(component, 'error', 'AssociatedCodesRelatedListController.cls. Message : '+JSON.parse(response.getReturnValue()));
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
    createRecordcall : function(component, event) {
        let caseId; let woID;
        woID = component.get("v.recordId");
        caseId = component.get("v.strParentCaseId");
        
        //Calling the Create record interface
        let createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Associated_Codes__c",
            "defaultFieldValues":{
                "Case__c" : caseId,
                "Work_Order__c" : woID
            }
            
        });
        createRecordEvent.fire();
    },
    
    openRecordDetail : function(component, event) {
        //Capturing record Id from the event.
		let ctarget = event.currentTarget;
        let recordId = ctarget.dataset.record;
        //Firing event to launch OOTB record detail page.  
		 let navEvt = $A.get("e.force:navigateToSObject");
		    navEvt.setParams({
		      "recordId": recordId
		    });
		    navEvt.fire();
    },
    
    editRecordDetail : function(component, event) {
        //Capturing record Id from the event.
		let recordId = event.getSource().get("v.name");
        //Firing event to launch OOTB record edit page.  
		 let editEvt = $A.get("e.force:editRecord");
		    editEvt.setParams({
		      "recordId": recordId
		    });
		    editEvt.fire();
    }
})
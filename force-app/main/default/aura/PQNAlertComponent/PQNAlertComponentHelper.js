({
	SendPQNData : function(component, event) {
		let action = component.get("c.postDatatoPQN");
        //var PQN_Date=component.get("v.datPQNDate").toString();
        let PQN_Date='';
        let PQN_Url=component.get("v.strPQNUrl").toString();        
        let Notification_Name=component.get("v.SelectedNotificationType").toString();       
        let AllUploadedEmails=component.get("v.ProcessFileDataContents")['UploadedEmailIds'];
         console.log('Data is-'+PQN_Url+'@'+PQN_Date);
         action.setParams({ 
             strPQNNumber : component.get("v.strPQNNumber"),
             strPQNUrl:PQN_Url,
             strPQNDate:PQN_Date,
             strNotificationName:Notification_Name,
             strTostrAllUploadedEmails:AllUploadedEmails
         	});
        
        action.setCallback(this, function(response) {
 			let state = response.getState();
    		if (state === "SUCCESS") {
      			let statuscode=response.getReturnValue();
                console.log('status--',statuscode);
                if(statuscode===true){
                   component.set("v.strIntegrationStatus","");
                   var compEvent = component.getEvent("IntegrationSucess");
                   compEvent.fire();
                }
                else{
                  component.set("v.strIntegrationStatus","Integration Failed");
                  this.showErrorToast("Integration Failed","pester",100);
                }
    		component.set("v.boolSpinnerIntegrationStatus",false);
            } 
    		else {
      			console.log(state);
    		}
  		});
        $A.enqueueAction(action);
    },
    CreateCampaignMembership : function(component, event) {
        let action = component.get("c.createCampaignMembershipSaleforce");
		let ContactsDataMap=component.get("v.ProcessFileDataContents")['Contacts'];
        let LeadsDataMap=component.get("v.ProcessFileDataContents")['Leads']; 	
        console.log('contacts map-',ContactsDataMap);
        action.setParams({ 
             sobjCampaignRecord:component.get("v.objSelectedLookUpRecord"),
             emailToContactId:ContactsDataMap,
             emailToLeadId:LeadsDataMap
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
        });
        
  		$A.enqueueAction(action);
    }
})
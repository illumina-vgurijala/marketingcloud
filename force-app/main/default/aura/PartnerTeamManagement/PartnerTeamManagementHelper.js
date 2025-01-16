({
    getContacts : function(component, event, helper) {
        helper.callServer(component,"c.getContacts",function(response){
            component.set("v.data", response);
        },{
            "partnerPortalStatus" : component.get("v.currentListViewType")
        });
    },
    
    getRecordTypeId : function(component,event,helper){
        helper.callServer(component,"c.getRecordTypeId",function(response){
            let recTypeId = response;
            let createRecordEvent = $A.get("e.force:createRecord");
            
            createRecordEvent.setParams({ 
                "entityApiName" : "Partner_Request__c",
                "recordTypeId" : recTypeId
            });
            createRecordEvent.fire();
        },{
            objectApiName : "Partner_Request__c",
            recordTypeName : component.get("v.teamMemberRecordTypeName")
        })
    }
        
})
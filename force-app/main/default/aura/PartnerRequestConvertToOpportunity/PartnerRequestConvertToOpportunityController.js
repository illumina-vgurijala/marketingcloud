({
    init : function(component, event, helper) {
        //component.set("v.recordTypeId","c.getOppRecordTypeId");
        helper.retrieveOpportunityRecordTypeId(component,event,helper);
        //helper.retrievePartnerAccount(component,event,helper);
        //helper.retrieveProfilePageLayout(component,event,helper);
    },
    
    onsuccess : function(component, event, helper) {
        
        helper.onsuccess(component, event, helper);
        $A.get("e.force:closeQuickAction").fire();
        //$A.get('e.force:refreshView').fire();
		location.reload(true);
    },
    close: function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }
})
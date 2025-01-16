({
    doInit : function(component, event, helper) {
        component.set("v.currentListViewType","Active");        
        helper.getContacts(component, event,helper);
        
    },
    
    triggerListViewChange : function(component,event,helper){
        let listViewType = component.find('listViewType').get('v.value');
        component.set("v.currentListViewType",listViewType);
        helper.getContacts(component,event,helper);
    },
    
    openPartnerRequestForAddTeamMember : function (component, event, helper) {
        let partnerRequestRecordTypeName = $A.get("$Label.c.PartnerRequestRecordTypeAddTeamMember");
        component.set("v.teamMemberRecordTypeName",partnerRequestRecordTypeName);
        helper.getRecordTypeId(component,event,helper);
    },
    
    openPartnerRequestForRemoveTeamMember : function (component, event, helper) {
        let partnerRequestRecordTypeName = $A.get("$Label.c.PartnerRequestRecordTypeRemoveTeamMember");
        component.set("v.teamMemberRecordTypeName",partnerRequestRecordTypeName);
        helper.getRecordTypeId(component,event,helper);
    }
})
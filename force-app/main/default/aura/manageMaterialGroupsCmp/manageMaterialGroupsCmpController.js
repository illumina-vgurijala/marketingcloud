({
    init : function(component, event, helper) {
        try{
            let pageRef = component.get("v.pageReference");
            if(pageRef === null)
                return;
            component.set("v.agreementId", pageRef.state.c__AgreementID);
            component.set("v.opportunityId", pageRef.state.c__OpportunityID);
            component.set("v.showLwcModal", true);
        }
        
        catch(err){
            console.log('The error is '+err.message);
        }
    },
    refreshPage : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})
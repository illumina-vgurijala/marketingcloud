({
    init : function(component, event, helper) {
        try{
            let pageRef = component.get("v.pageReference");
            if(pageRef == null)
                return;
            component.set("v.agreementID", pageRef.state.c__AgreementID);
            component.set("v.agreementAccountId", pageRef.state.c__AccountID);
            component.set("v.agreementAccountName", pageRef.state.c__AccountName);
            component.set("v.agreementName", pageRef.state.c__AgreementName);
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
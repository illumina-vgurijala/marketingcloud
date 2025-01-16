({
    /*submit : function(component, event, helper) {
        helper.doSubmit(component,helper);//passing helper because using this in callback gives error
	},*/
    handleRecordUpdated : function(component, event, helper) {
        helper.checkRecordRetrieved(component,helper);
        $A.get("e.force:closeQuickAction").fire(); 
        //helper.toggleSpinner(component.getSuper());
    }
})
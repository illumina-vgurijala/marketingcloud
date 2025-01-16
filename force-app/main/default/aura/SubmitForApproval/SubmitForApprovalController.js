({
    init : function(component, event, helper) {
        helper.toggleSpinner(component.getSuper());        
        helper.loadRecord(component, helper);
    },
})
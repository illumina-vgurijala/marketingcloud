({
    init : function (component, event, helper) {
        console.log("Account id ---> "+ component.get("v.recordId"));
        helper.loadAccountDetails(component,helper);      
    },
    handleStatusChange : function (component, event , helper) {
        helper.indicatorStatusChange(component, event , helper); 
    }
})
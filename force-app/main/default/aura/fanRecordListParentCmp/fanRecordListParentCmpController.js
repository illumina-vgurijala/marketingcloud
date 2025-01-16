({
    onTabRefreshed : function(component, event, helper) {
        component.find("childlwc").extractRelatedFAN();
    }
})
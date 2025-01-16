({
    init : function(component, event, helper){
        let pageReference = component.get("v.pageReference");
        component.set("v.QSRId", pageReference.state.c__QSRId);
        component.set("v.boolHasId",true);
        }
})
({
    init : function (component, event, helper) {
    	console.log('In Init ---->');
        helper.loadRecordType(component,event,helper);

    },
    closeModal : function (component,event, helper){
    	component.set("v.setFirst",true);
    	component.set("v.Closed",true);
    	component.set("v.CheckLoad",false);
    }
})
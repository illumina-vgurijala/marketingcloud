({
	rerender : function(component, helper) {
    	this.superRerender();
    	if(component.get("v.Closed") && !component.get("v.setFirst")){
    		helper.loadRecordType(component,event,helper);
    	}
    	else if(component.get("v.Closed")){
    		component.set("v.setFirst",false);
    	}
	},
})
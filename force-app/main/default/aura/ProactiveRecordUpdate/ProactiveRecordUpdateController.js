({
	doinit : function(component, event, helper) {
		console.log('Aura Component Loaded');
        
	},

        getValueFromLwc : function(component, event, helper) {
		
                $A.get("e.force:closeQuickAction").fire(); 
                $A.get('e.force:refreshView').fire();
               
	}
})
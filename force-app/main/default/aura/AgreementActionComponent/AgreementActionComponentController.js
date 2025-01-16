({
	init : function(component, event, helper) 
    {
        helper.getDetails(component,helper);
    },
    terminateNow : function(component,event,helper)
    {
        helper.callTerminateMethod(component,helper);
    }
})
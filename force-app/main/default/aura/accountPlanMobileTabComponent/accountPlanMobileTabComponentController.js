({
    init : function(component, event, helper) {
       
        helper.callServer(component,"c.getSessionCache",function(response){
            helper.consoleLog('response: ' + response);
           component.set("v.objAccountPlan",response);
           
           
            
        });
        
    }
})
({
    doInit : function(component, event, helper) {
        
        let device = $A.get("$Browser.formFactor");
        if(device == 'DESKTOP')
        {
            component.set('v.desktopVersion',true);
        }
        else
        {
            component.set('v.desktopVersion',false);
        }
        
        let action = component.get("c.checkAccess");
        
        action.setParams({});
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") 
            {
                let res = response.getReturnValue();
                console.log('response --- ' + res);
                if(res == true)
                {
                    helper.checkTerritoryAccess(component, event, helper);
                    component.set('v.showMultiSelect',true);
                }
                else
                {
                    helper.showToast(component, event, helper,$A.get("$Label.c.Insufficent_access_Message_CSP"),'error','Error');
                    $A.get("e.force:closeQuickAction").fire();
                }

            }
        });
        $A.enqueueAction(action);
    }
})
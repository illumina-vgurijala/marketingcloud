({
    init : function(component, event, helper) {
        let device = $A.get("$Browser.formFactor");
        console.log('Device used -->'+device);
        if(device == "DESKTOP"){
            let dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Error",
                "message": "Funtionality not available on Desktop",
                "type":"error"
            });
            resultsToast.fire();
        }
        else{
        let recordid = component.get("v.recordId");
        if(!recordid)
            return;
        console.log('$%$%$%$--'+component.get("v.recordId"));
        let params = {
            recordId : recordid
            };
        helper.callServer(component,"c.checkSessionCache",function(response){
            response = JSON.parse(response);
            console.log('(()()(()'+response);
            helper.consoleLog('Result: ',false,response);
            let urlEvent = $A.get("e.force:navigateToURL");
            let urlToNav = '/lightning/n/Account_Plan_App_Page';
            urlEvent.setParams({
            "url": urlToNav
            });
            urlEvent.fire();
            
        },params);
        console.log('Record Id--->'+component.get("v.recordId"));
    }
    }
})
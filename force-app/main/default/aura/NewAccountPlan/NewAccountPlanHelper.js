({
    loadAccountDetails : function(component, helper){
        if(!component.get("v.recordId")){
            let value = helper.getParameterByName(component , event, 'inContextOfRef');
            let context = JSON.parse(window.atob(value));
            component.set("v.AccountId", context.attributes.recordId);
        }
        else{
            component.set("v.AccountId",component.get("v.recordId"));
        }
        // Logic added to handle new button click from Account Plan Tab.
        if(!component.get("v.AccountId")){
            let staticLabel = $A.get("$Label.c.UI_Error_Message_NAP_Account_Id_Missing");
            let dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Error",
                "message": staticLabel,
                "type":"error"
            });
            resultsToast.fire();
            let urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/o/Account_Plan__c/home"
            });
            urlEvent.fire();
        }
        else {
            let _self = this ;
            _self.getAccountDetails(component,helper);
        }
    },
    getAccountDetails : function(component,helper){
        let params = {
            accountId : component.get("v.AccountId"),            
        };
        helper.callServer(component,"c.getAccountDetails",function(response){
            console.log('^^^ '+response);
            let objAccountPlan = JSON.parse(response);
            component.set('v.AccountName',objAccountPlan.AccountName);
            component.set('v.TerritoryRegion',objAccountPlan.TerritoryRegion);
            let _self = this ;
            _self.triggerFlow(component,helper);
        },params);
    },
    triggerFlow : function(component, helper){
        let flow = component.find("flowData");
        let inputvariable = [
            {
                name : "AccountRecordId",
                type : "String",
                value : component.get("v.AccountId")
            },
            {
                name : "AccountName",
                type : "String",
                value : component.get('v.AccountName')
            },
            {
                name : "TerritoryRegion",
                type : "String",
                value : component.get('v.TerritoryRegion')
            }
        ];
        flow.startFlow("Account_Plan_New_Plan_Creation",inputvariable);
    },
    getParameterByName: function(component, event, name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        let url = window.location.href;
        let regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        let results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    indicatorStatusChange : function(component, event , helper){
        component.set("v.HasFieldError",false);
        component.set("v.currentStage", event.getParam("currentStage"));
        component.set("v.activeStages", event.getParam("activeStages"));
        let progressIndicator = component.find("progressIndicator");
        let body = [];
        for(let stage of component.get("v.activeStages")) {
            // For each stage in activeStages...
            $A.createComponent(
                "lightning:progressStep",
                {
                    // Create a progress step where label is the 
                    // stage label and value is the stage name
                    "aura:id": "step_" + stage.name,
                    "label": stage.label,
                    "value": stage.name
                },
                function(newProgressStep, status, errorMessage) {
                    //Add the new step to the progress array
                    if (status === "SUCCESS") {
                        body.push(newProgressStep);
                    }
                    else if (status === "INCOMPLETE") {
                        // Show offline error
                        console.log("No response from server or client is offline.")
                    }
                        else if (status === "ERROR") {
                            // Show error message
                            console.log("Error: " + errorMessage);
                        }
                }
            );
        }
        progressIndicator.set("v.body", body);
        helper.flowUpdate(component, event , helper);
    },
    flowUpdate : function(component, event , helper){
        let outputVariables = event.getParam("outputVariables");
        console.log('Outputvar--> '+event.getParam("outputVariables"));
        let outputVar;
        if(event.getParam("status") == "FINISHED") {
            for(let i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                console.log('Outputvarname--> '+outputVar.name);
                console.log('OutputvarValue--> '+outputVar.value);
                if(outputVar.name === "AccountPlanRecordId") {
                    if(outputVar.value != null){
                        let urlEvent = $A.get("e.force:navigateToSObject");
                        urlEvent.setParams({
                            "recordId": outputVar.value,
                            "isredirect": "true"
                        });
                        urlEvent.fire();
                    }
                    else{
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            }
        }
        else {
            for(let i = 0; i < outputVariables.length; i++){
                outputVar = outputVariables[i];
                console.log('---Status change--- '+ outputVar.name);
                console.log('---Status--- '+ outputVar.value);
                if(outputVar.name === "RequiredFieldError"){
                    if(outputVar.value != null){
                        component.set("v.HasFieldError",true);
                        component.set("v.FieldError",outputVar.value);
                    }
                }
            }
        }
    }
})
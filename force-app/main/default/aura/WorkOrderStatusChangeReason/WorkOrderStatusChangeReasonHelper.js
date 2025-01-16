({
	handleRecordUpdate : function(component, event) {
		let eventParams = event.getParams();
        // record is changed
        if(eventParams.changeType === "CHANGED") {
            console.debug("Record is changed successfully.");
            let changedFields = eventParams.changedFields;
            
            let setReasonStatus = new Set();
            let lstReasonStatus = component.get("v.lstReasonStatus");            
            lstReasonStatus.forEach(function(value,iIndex){
              setReasonStatus.add(value);
            });
			
            //debugger;
            console.debug(JSON.stringify(component.get("v.objTargetFields")));
            
            let setCompletedClosedStatus = new Set();
            let lstCompletedClosedStatus = component.get("v.lstCompletedClosedStatus");
            lstCompletedClosedStatus.forEach(function(value,iIndex){
              setCompletedClosedStatus.add(value);
            });
            
            let boolIsInstrumentDown = (component.get("v.objTargetFields.SVMXC__Customer_Down__c") == 'true');
            console.log('Line 25 - boolIsInstrumentDown: ' + boolIsInstrumentDown);
            console.log('Line 26 - changedFields.SVMXC__Customer_Down__c: ' + changedFields.SVMXC__Customer_Down__c);
            if(!$A.util.isUndefinedOrNull(changedFields.SVMXC__Customer_Down__c)){
                console.log('Line 28 - IF');
				boolIsInstrumentDown = (changedFields.SVMXC__Customer_Down__c.value == 'true');
                console.log('Line 30 - boolIsInstrumentDown: ' + boolIsInstrumentDown);
				localStorage.setItem(component.get("v.objTargetFields.Id") + "InstrumentDown", boolIsInstrumentDown);
                console.log('Line 32 - v.objTargetFields.Id: ' + component.get("v.objTargetFields.Id"));
                console.log('Line 33 - localStorage.InstrumentDown: ' + localStorage.getItem(component.get("v.objTargetFields.Id") + "InstrumentDown"));
            }else if(localStorage.getItem(component.get("v.objTargetFields.Id") + "InstrumentDown") != null){
            	console.log('Line 35 - ELSE IF');
                console.log('Line 36 - v.objTargetFields.Id: ' + component.get("v.objTargetFields.Id"));
                boolIsInstrumentDown = (localStorage.getItem(component.get("v.objTargetFields.Id") + "InstrumentDown") == 'true');
                console.log('Line 38 - boolIsInstrumentDown: ' + boolIsInstrumentDown);
            }
            
            console.log('Line 41 - boolIsInstrumentDown: ' + boolIsInstrumentDown);
            
            console.log(component.get("v.WorkOrderRecord").Number_of_Parts_and_Tools__c);
            let intCountPartsAndTools = component.get("v.WorkOrderRecord").Number_of_Parts_and_Tools__c;
            
            let strEstimateLineMismatch = component.get("v.WorkOrderRecord").Estimate_Debrief_Mismatch__c;
			let strWorkOrderRecordType = component.get("v.WorkOrderRecord").Record_Type__c;
            
            console.log('Line 49 - changedFields.SVMXC__Order_Status__c: ' + changedFields.SVMXC__Order_Status__c);
            console.log('Line 50 - isUndefinedOrNull changedFields.SVMXC__Order_Status__c: ' + $A.util.isUndefinedOrNull(changedFields.SVMXC__Order_Status__c));
            console.log('Line 51 - boolIsInstrumentDown: ' + boolIsInstrumentDown);
            console.log('Line 52 - Typeof boolIsInstrumentDown: ' + typeof boolIsInstrumentDown);
            
            //Turn on First Modal
            if(!$A.util.isUndefinedOrNull(changedFields.SVMXC__Order_Status__c)
                && setReasonStatus.has(changedFields.SVMXC__Order_Status__c.value)){
                console.debug('Value: '+JSON.stringify(changedFields));
                component.set("v.strNewOrderStatus",changedFields.SVMXC__Order_Status__c.value);
                component.set("v.strOldOrderStatus",changedFields.SVMXC__Order_Status__c.oldValue);
                component.set("v.strReason",'');
                component.set("v.boolShowModal",true);
            }//Else Turn on Second Modal
            else if(!$A.util.isUndefinedOrNull(changedFields.SVMXC__Order_Status__c)
                && setCompletedClosedStatus.has(changedFields.SVMXC__Order_Status__c.value)
                && boolIsInstrumentDown === true){
                console.log('Line 66 - INSIDE SECOND MODAL');
                component.set("v.strNewOrderStatus",changedFields.SVMXC__Order_Status__c.value);
                component.set("v.strOldOrderStatus",changedFields.SVMXC__Order_Status__c.oldValue);
                component.set("v.boolShowConfirmModal",true);
                component.set("v.confirmationModalMessage",$A.get("$Label.c.WorkOrderInstrumentDownConfirmationMessage"));
            }//Else turn on Modal if there is any mismatch in Estimates, Debrief line items.
            else if(!$A.util.isUndefinedOrNull(changedFields.SVMXC__Order_Status__c)
            && setCompletedClosedStatus.has(changedFields.SVMXC__Order_Status__c.value)
            && strEstimateLineMismatch){
                component.set("v.strNewOrderStatus",changedFields.SVMXC__Order_Status__c.value);
                component.set("v.strOldOrderStatus",changedFields.SVMXC__Order_Status__c.oldValue);
                component.set("v.boolShowConfirmModal",true);
                component.set("v.confirmationModalMessage",$A.get("$Label.c.WorkOrderEstimateLineMismatchConfirmationMessage"));
            } //Else Turn on Modal for Parts Order and Work order confirmation
            else if(!$A.util.isUndefinedOrNull(changedFields.SVMXC__Order_Status__c)
                && setCompletedClosedStatus.has(changedFields.SVMXC__Order_Status__c.value)
                && intCountPartsAndTools == 0
				&& strWorkOrderRecordType=='Field Service'){
                component.set("v.strNewOrderStatus",changedFields.SVMXC__Order_Status__c.value);
                component.set("v.strOldOrderStatus",changedFields.SVMXC__Order_Status__c.oldValue);
                component.set("v.boolShowConfirmModal",true);
                component.set("v.confirmationModalMessage",$A.get("$Label.c.WorkOrderNoPartOrderAndToolsConfirmationMessage"));
            }
                              
        } 
	},
    loadData : function(component) {
        console.debug('loadData-->' );
        console.debug(JSON.stringify(component.get("v.objTargetFields")));
        //debugger;
        //Doing server call to get page load info
        let action = component.get("c.loadPageData");
        action.setParams({
            "idWorkOrder" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            //Setting attributes based on server response
            if(state === "SUCCESS") {
                //debugger;
                let objResponse = JSON.parse(response.getReturnValue());
                console.debug('objResponse.lstReasonStatus: ',objResponse.lstReasonStatus);
                console.debug('objResponse.MapLabelError: ',objResponse.MapLabelError);
                component.set("v.labelsToTranslate",objResponse.MapLabelError);
                component.set("v.lstReasonStatus",objResponse.lstReasonStatus);
                component.set("v.lstCompletedClosedStatus",objResponse.lstCompletedClosed);
                component.set("v.boolLoaded",true);
                console.debug('v.WorkOrderRecord: ',objResponse.workOrderRecord);
                component.set("v.WorkOrderRecord", objResponse.workOrderRecord);
            }else{
                //Handling errors on server response
                alert('Error Loading Data');
            }
        });
        $A.enqueueAction(action);
    },
    saveData : function(component, helper) {
        //saving updated record using data service
        console.debug('saveData-->');
        console.debug(JSON.stringify(component.get("v.objTargetFields")));
        let strReason = component.get("v.strReason");
        if($A.util.isEmpty(strReason)){
            component.set("v.boolIsError",true);
            return;
        }
        console.debug(strReason);
        component.set("v.objTargetFields.Reason__c",strReason);
        let strNewOrderStatus = component.get("v.strNewOrderStatus");
        console.debug(strNewOrderStatus);
        component.set("v.objTargetFields.SVMXC__Order_Status__c",strNewOrderStatus);
        helper.fireSave(component,helper,false);
    },
    showToast : function(strTitle, strMessage, strMode, strType) {
        let resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": strTitle,
            "message": strMessage,
            "mode" : strMode,
            "type" : strType
        });
        resultsToast.fire();
    },
    hideConfirm : function(component, helper) {
        component.set("v.boolShowConfirmModal",false);
        let labelsToTranslate = component.get("v.labelsToTranslate");
        this.showToast(labelsToTranslate.Success,
                                labelsToTranslate.Save_Success,
                                "pester",
                                "success");
    },
    revertOldData : function(component, helper) {
        component.set("v.objTargetFields.SVMXC__Order_Status__c",
                        component.get("v.strOldOrderStatus"));
        component.set("v.objTargetFields.Is_Set_From_Lightning_Component__c",true);
        helper.fireSave(component,helper,true);
    },
    fireSave : function(component, helper, isRevert) {
        component.get("v.objTargetFields.Is_Set_From_Lightning_Component__c");
        let labelsToTranslate = component.get("v.labelsToTranslate");
        component.find("forceRecordUpdate").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.debug('Success');
                // Reload the view so components not using force:recordData
                // Are updated and show proper toast message
                $A.get("e.force:refreshView").fire();

                if(!isRevert){
                    helper.showToast(labelsToTranslate.Success,
                                    labelsToTranslate.Save_Success,
                                    "pester",
                                    "success");
                }else{
                    helper.showToast(labelsToTranslate.Success,
                                    labelsToTranslate.RecordSaveCancelled,
                                    "pester",
                                    "info");
                }
            }
            else if (saveResult.state === "INCOMPLETE") {
                helper.showToast(labelsToTranslate.Offline,
                                labelsToTranslate.User_offline,
                                "pester",
                                "info");
            }
            else if (saveResult.state === "ERROR") {
                helper.showToast(labelsToTranslate.Error,
                                labelsToTranslate.Problem_Saving+JSON.stringify(saveResult.error),
                                "pester",
                                "error");
                console.debug('Problem Saving, error: ' +
                             JSON.stringify(saveResult.error));
            }
            else {
                helper.showToast(labelsToTranslate.Error,
                                labelsToTranslate.Unknown_Problem,
                                "pester",
                                "error");
                console.debug('Unknown problem, state: ' + saveResult.state +
                            ', error: ' + JSON.stringify(saveResult.error));
            }
            //Close any open modal
            helper.turnOffModal(component);
        }));
    },
    turnOffModal : function(component){
        component.set("v.boolShowModal",false);
        component.set("v.boolShowConfirmModal",false);
        component.set("v.boolShowPartsNotUsedModal",false);
    },
    saveDataForPartsNotUsed : function(component, helper){
		let strNewOrderStatus = component.get("v.strNewOrderStatus");
        component.set("v.objTargetFields.SVMXC__Order_Status__c",strNewOrderStatus);
		component.set("v.objTargetFields.Is_Set_From_Lightning_Component__c",true);
        helper.fireSave(component,helper,false);
    }
})
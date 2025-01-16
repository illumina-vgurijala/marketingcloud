({
    handleRecordLoaded : function(component,event,helper){
         let record=component.get('v.recordId');
         let objAgreement = component.get("v.objTargetAgreement");
		 //DCP-39587 Added below check to stop user if batch is in progress for line items insertion.
        if(!objAgreement.Amend_Batch_Completed__c && !objAgreement.Agreement_Not_Amended__c){ 
            let errorMessage = $A.get("$Label.c.UI_AgreementLineItemUploadError");
            this.displayToast('Error', errorMessage, 'error', '', '');
            return false;         
        }
         helper.callServer(component,"c.agreementRevertToRequest",function(response){
            let responseVal = JSON.parse(response);
            let statusVal = responseVal.recordValidationStatus;
            let revertStatusMessage = responseVal.recordValidationLabel;
            if(statusVal != null && statusVal != undefined && statusVal != '' && statusVal == 'Error'){
            	helper.showErrorAndQuit(component,helper,revertStatusMessage);       
            }else if(statusVal != null && statusVal != undefined && statusVal != '' && statusVal == 'Success'){
             	helper.redirectToAgreementPage(component,helper);
                helper.consoleLog('Update successful.Do outbound call');   
            }
        },{
            agreementId : record
       });
    },
    redirectToAgreementPage : function(component,helper){
        let strAgreementId = component.get('v.recordId');
        helper.consoleLog('Redirecting...');   
        setTimeout(function(){
            helper.displaySuccessToast('Record Updated Successfully.');
        },'250')
        helper.redirectToPageURL('/'+strAgreementId);
    },
    showErrorAndQuit : function (component, helper,strErrorMessage){
        setTimeout(function(){
            helper.displayErrorToast(strErrorMessage);
        },'250')
        helper.redirectToPageURL('/'+component.get('v.recordId'));
     },
     displayErrorToast : function(strMessage,strMode,intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'dismissible';
        if($A.util.isEmpty(intDuration))
            intDuration = 300;
        this.displayToast('Error', strMessage, 'error', strMode, intDuration);
    }, 
    displaySuccessToast : function(strMessage,strMode,intDuration) {
        strMode = 'dismissible';
        if($A.util.isEmpty(intDuration))
            intDuration = 400;
        this.displayToast('Success', strMessage, 'success', strMode, intDuration);
    },
    displayToast : function(strTitle, strMessage, strType, strMode, intDuration) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : strTitle,
            message : strMessage,
            duration : 400,
            mode : 'dismissible',
            type: strType
        });
        toastEvent.fire();
    },
   })
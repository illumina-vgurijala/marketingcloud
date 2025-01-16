({  
    onLoad : function(component,event,helper){
       helper.toggleSpinner(component.getSuper());
    },
    save : function(component,event,helper){
        let objProposal = component.get("v.objTargetProposal");
        let reasonForRevertToDraft = objProposal.Reason_Revert_Quote_To_Draft__c;
        let statusDraft = $A.get("$Label.c.QuoteStageDraft");    
        let statusNone = $A.get("$Label.c.QuoteApprovalStatusNone");
        if(objProposal.Check_Quote_Is_Accepted_Opp_Is_Won__c && !$A.util.isEmpty(reasonForRevertToDraft)){
            helper.toggleSpinner(component.getSuper());
            objProposal.Apttus_Proposal__Approval_Stage__c = statusDraft;
            objProposal.Apttus_QPApprov__Approval_Status__c = statusNone; 
            objProposal.Is_Updated_By_System__c = true;
            component.find("proposalRecordHandler").saveRecord($A.getCallback(function(saveResult){ 
                helper.toggleSpinner(component.getSuper());
                if(saveResult.state === "SUCCESS" || saveResult.state === "DRAFT"){
                    helper.consoleLog('Update successful. Do outbound call');                
                    helper.redirectToProposalPage(component,helper);
                } else if(saveResult.state === "INCOMPLETE"){
                    helper.showErrorToast(component.getSuper(),"User is offline, device doesn't support drafts.",200);
                }else if(saveResult.state === "ERROR"){
                    helper.showErrorToast(component.getSuper(),'Problem saving record, error: ' + JSON.stringify(saveResult.error),200);
                }else {
                    helper.showErrorToast(component.getSuper(), saveResult.state + ', error: ' + JSON.stringify(saveResult.error),200);
                }
            }));     
        }  
    },   
    recordUpdated : function(component,event,helper){
        helper.toggleSpinner(component.getSuper());
        let boolPermissionSetFound;
        let boolOpportunityClosed;
        let strErrorMsgRevertToDraft = $A.get("$Label.c.UI_ErrorMessage_RevertToDraft");
        let strRecordId = component.get('v.recordId');
       	    helper.callServer(component,"c.checkRevertToDraftPermissionForUser",function(responseVar){
            let response = JSON.parse(responseVar);
                component.set("v.boolHasPermissionSet",response.hasRevertToDraftPermission);
                component.set("v.boolIsOpportunityStageClosed",response.boolIsOpportunityClosed);
                boolPermissionSetFound = component.get("v.boolHasPermissionSet");
                boolOpportunityClosed = component.get("v.boolIsOpportunityStageClosed");
                helper.consoleLog('@@@@boolPermissionSetFound '+boolPermissionSetFound); 
                if(boolOpportunityClosed && !boolPermissionSetFound){
                    helper.showErrorAndQuit(component,helper,strErrorMsgRevertToDraft);            
                    return;
                }
            let change = event.getParams().changeType;
            if(change === "LOADED"){
                let strError = component.get("v.strRecordError");
                let statusNone = $A.get("$Label.c.QuoteApprovalStatusNone");
                let objProposal = component.get("v.objTargetProposal"); 
                let statusDraft = $A.get("$Label.c.QuoteStageDraft");
                let statusApprovalRequired = $A.get("$Label.c.QuoteStageApprovalRequired");
                let statusInReview = $A.get("$Label.c.QuoteStageInReview");
                let statusGenerated = $A.get("$Label.c.QuoteStageGenerated");
                let statusPresented = $A.get("$Label.c.QuoteStagePresented");
                let statusAccepted = $A.get("$Label.c.QuoteStageAccepted");
                let statusDenied = $A.get("$Label.c.QuoteStageDenied");
                let strErrorMsg = $A.get("$Label.c.UI_ErrorMessage_RevertToDraft");
                if( !$A.util.isEmpty(strError)){
                    helper.showErrorToast(component.getSuper(),'An unexpected error has occured please contact your system administrator: '+strError);
                    return;
                } 

				// Moved statusApprovalRequired from if to else
                // Moved to enable Revert to Draft for Approval Required for Apttus Upgrade bug
                if(objProposal.Apttus_Proposal__Approval_Stage__c == statusDraft ||
                   objProposal.Apttus_Proposal__Approval_Stage__c == statusInReview || objProposal.Apttus_Proposal__Approval_Stage__c == statusGenerated ||
                   objProposal.Apttus_Proposal__Approval_Stage__c == statusPresented  || objProposal.Apttus_Proposal__Approval_Stage__c == statusDenied || 
                   (objProposal.Apttus_Proposal__Approval_Stage__c == statusAccepted && !objProposal.Check_Quote_Is_Accepted_Opp_Is_Won__c)){
                    helper.showErrorAndQuit(component,helper,strErrorMsg);            
                    return;
                }
                else{         
                    if(objProposal.Apttus_Proposal__Approval_Stage__c === "Approved" || objProposal.Apttus_Proposal__Approval_Stage__c == statusApprovalRequired ){                   
                        helper.toggleSpinner(component.getSuper());
                        objProposal.Apttus_Proposal__Approval_Stage__c = statusDraft;                    
                        objProposal.Apttus_QPApprov__Approval_Status__c = statusNone;                                                                                                                                                    
                        if(!objProposal.Is_Updated_By_System__c){
                            objProposal.Is_Updated_By_System__c = true; 
                        }
                            component.find("proposalRecordHandler").saveRecord($A.getCallback(function(saveResult) {
                            helper.toggleSpinner(component.getSuper());
                            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                                helper.consoleLog('Update successful. Do outbound call');  
                                helper.redirectToProposalPage(component,helper);                            
                            } else if (saveResult.state === "INCOMPLETE") {
                                helper.showErrorToast(component.getSuper(),"User is offline, device doesn't support drafts.",200);
                            } else if (saveResult.state === "ERROR") {
                                helper.showErrorToast(component.getSuper(),'Problem saving record, error: ' + JSON.stringify(saveResult.error),200);
                            } else {
                                helper.showErrorToast(component.getSuper(), saveResult.state + ', error: ' + JSON.stringify(saveResult.error),200);
                            }
                        })); 
                    }
                }
            }
	   	},{
            "strProposalId": strRecordId
        });		                   
    },    
    redirectToProposalPage : function(component,helper) {
        let strProposalId = component.get('v.recordId');
        helper.consoleLog('Redirecting..');   
        setTimeout(function(){
            helper.showSuccessToast('Record Updated Successfully');
        }, '200')
        helper.redirectToPageURL('/'+strProposalId);
    },     
    showErrorAndQuit : function (component, helper,strErrorMessage) {
        setTimeout(function(){
            helper.showErrorToast(strErrorMessage);
        }, '200')
        helper.redirectToPageURL('/'+component.get('v.recordId'));
    },
})
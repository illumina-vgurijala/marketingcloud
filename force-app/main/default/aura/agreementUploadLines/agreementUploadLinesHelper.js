({
  /*
   * top two methods are specific to this implementation
   * if using this as a template for a validation/pass-through
   * implement these two methods to fit business requirements
  */
  validateRecord : function(component, helper) {
    // validate required fields
    let requiredFieldsMessage = helper.validateRequiredFields(component, helper);
	//DCP-39587 Added below check to throw error if batch insertion is in progress.
        let rec = component.get("v.recordDetails"); 
        if(!rec.Amend_Batch_Completed__c && !rec.Agreement_Not_Amended__c){
            let errorMessage = $A.get("$Label.c.UI_AgreementLineItemUploadError");
            return errorMessage;          
        }
    if (requiredFieldsMessage) {
       let requiredSubmissionMessage = helper.validateRequiredSubmission(component, helper);
         if (requiredSubmissionMessage) {
      		let authorizedToSubmitMessage = helper.validateAuthorizedToSubmit(component, helper);
             if (authorizedToSubmitMessage) {
      				return authorizedToSubmitMessage;
    				}
         }else{
             let errorMessage = $A.get("$Label.c.UI_Error_Message_Upload_Lines_Items");
        		return errorMessage;
         }
    }else{
        //DCP-46181
        if(helper.isAgreementIndirectTender(component, helper)) {
          let errorMsg = $A.get("$Label.c.UI_IndirectAccountsNotallowedtoload");
          return errorMsg;
        }
        let errorMessage = $A.get("$Label.c.UI_LoadLinesRequiredValues");
        return errorMessage;
    }
  },

  validateRequiredFields : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

    let recordValid = false;
	//DCP-46169 For Discount Justification
    //DCP-54529 Added check for Open Offer Agreements
    if (rec.Apttus__Contract_Start_Date__c && rec.Apttus__Contract_End_Date__c && rec.Apttus__Subtype__c && ((rec.Discount_Justification__c && !helper.isAgreementIndirectTender(component, helper) && !helper.isAgreementOpenOffer(component, helper))||(helper.isAgreementOpenOffer(component, helper)))){
      recordValid = true;
    }
    helper.consoleLog('Required values present: ' + recordValid);
    return recordValid;
    // return error message if not valid
   /* if (recordValid) {
        return true;
    } else {
        var errorMessage = $A.get("$Label.c.UI_LoadLinesRequiredValues")
        return errorMessage;
    }*/
  },

  isAgreementOpenOffer : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

    let boolIsOpenOffer = false;
    if (rec.RecordType.DeveloperName === $A.get("$Label.c.AgreementRecordTypeOpenOffer") ){ //DCP-54529
      boolIsOpenOffer = true;  	
    }
    helper.consoleLog('Is Open Offer: ' + boolIsOpenOffer);
    return boolIsOpenOffer;
  },

  isAgreementIndirectTender : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

    let boolisIndirectTender = false;
    if (rec.RecordType.DeveloperName === $A.get("$Label.c.AgreementRecordTypeTender") && (rec.Apttus__Account__r.Account_Group__c === $A.get("$Label.c.AccountGroupDistributor") || (rec.Apttus__Account__r.Account_Group__c === $A.get("$Label.c.AccountProspect") && rec.Apttus__Account__r.Channel_Partner_Type__c != null && rec.Apttus__Account__r.ERP_Customer_Id__c != null)) ) { //DCP-46181
      boolisIndirectTender = true;  	
    }
    helper.consoleLog('Is Tender Indirect: ' + boolisIndirectTender);
    return boolisIndirectTender;
  },

  validateRequiredSubmission : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

    let acApproved =  $A.get("$Label.c.AgreementApprovalStatusApproved");
    let acNotSubmitted = $A.get("$Label.c.AgreementApprovalStatusNotSubmitted");      
    let acApprovalRequired = $A.get("$Label.c.AgreementApprovalStatusApprovalRequired");
    let aliOptional = $A.get("$Label.c.AgreementLineItemOptional"); 
    let aliRequired = $A.get("$Label.c.AgreementLineItemRequired"); 

    let recordValid = false;
    if ((rec.Line_Items_Required_Optional__c == aliOptional
        && (rec.Apttus_Approval__Approval_Status__c == acNotSubmitted
          ||rec.Apttus_Approval__Approval_Status__c == acApprovalRequired
          || rec.Apttus_Approval__Approval_Status__c == acApproved))
        || (rec.Line_Items_Required_Optional__c == aliRequired
            && (rec.Apttus_Approval__Approval_Status__c == acNotSubmitted
                || rec.Apttus_Approval__Approval_Status__c == acApprovalRequired
                || rec.Apttus_Approval__Approval_Status__c == acApproved))) {
     	recordValid = true;
    }
    helper.consoleLog('Required submission present: ' + recordValid);
	return recordValid;
    // return error message if not valid
   /* if (recordValid) {
        return true;
    } else {
        var errorMessage = $A.get("$Label.c.UI_Error_Message_Upload_Lines_Items")
        return errorMessage;
    }*/
  },

  validateAuthorizedToSubmit : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

	  let scInEffect = $A.get("$Label.c.UI_Label_Agreement_Status_In_Effect");
	  let scAmended = $A.get("$Label.c.UI_Label_Agreement_Status_Category_Amended");
    let scRenewed = $A.get("$Label.c.UI_Label_Agreement_Status_Category_Renewed");
    let scTerminated = $A.get("$Label.c.UI_Label_Agreement_Status_Category_Terminated");
    let scCancelled = $A.get("$Label.c.UI_Label_Agreement_Status_Category_Cancelled");
    let scExpired = $A.get("$Label.c.UI_Label_Agreement_Status_Category_Expired");
    let validStatus = $A.get("$Label.c.UI_Label_Agreement_Validation_Status_In_Progress");
    let rtOpenOffer = $A.get("$Label.c.AgreementRecordTypeOpenOffer");
    let acApproved =  $A.get("$Label.c.AgreementApprovalStatusApproved");

    let recordValid = true;
    //Added a check for 54529
    if (rec.Apttus__Status_Category__c == scInEffect
        || rec.Apttus__Status_Category__c == scAmended
        || rec.Apttus__Status_Category__c == scRenewed
        || rec.Apttus__Status_Category__c == scTerminated
        || rec.Apttus__Status_Category__c == scCancelled
        || rec.Apttus__Status_Category__c == scExpired
        || (rec.Validation_Status__c != null && rec.Validation_Status__c.toLowerCase().includes(validStatus))
        || (rec.RecordType.DeveloperName === rtOpenOffer && rec.Apttus_Approval__Approval_Status__c !== acApproved)) {
      recordValid = false;
    }
    helper.consoleLog('Authorized to submit at this stage: ' + recordValid);

    // return error message if not valid
    if (!recordValid) {
        let errorMessage = $A.get("$Label.c.UI_Error_Message_Upload_Lines_Items")
        return errorMessage;
    }

    // return error message if batch in process
    if (rec.Is_Updating_Line_Status__c) {
        let errorMessage = $A.get("$Label.c.UI_Error_Message_Agreement_Batch_Update_Running")
        return errorMessage;
    }

    return '';
  },

  constructUrl : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");
    let recId = component.get("v.recordId");
    let rtName = rec.RecordType.DeveloperName;
    helper.consoleLog('Agreement RT ' + rtName);

    // get configured record type names
    let rtChannelPartner = $A.get("$Label.c.AgreementRecordTypeChannelPartner")
    let rtMasterService = $A.get("$Label.c.AgreementRecordTypeMasterService")
    let rtOpenOffer = $A.get("$Label.c.AgreementRecordTypeOpenOffer")
    let acApproved =  $A.get("$Label.c.AgreementApprovalStatusApproved");

    // determine agreement "app" used to upload items from record type
    //54529 added check for Open Offer App and Record Type
    let appName = 'ContractManagement_AgreementLineItems';
    if (rtName === rtChannelPartner) {
        appName = 'ContractManagement_ALIs_ChannelPartner';
    } else if (rtName === rtMasterService) {
        appName = 'ContractManagement_ALIs_MSA';
    } else if(rtName === rtOpenOffer && rec.Apttus_Approval__Approval_Status__c === acApproved){
        appName ='ContractManagement_ALIs_OpenOffer';
    }
    helper.consoleLog('upload app name ' + appName);

    // construct URL
    let targetUrl = '/apex/Apttus_XApps__EditInExcelLaunch?parentRecordId=' + recId + '&appName=' + appName;
    return targetUrl;
  },

  /*
   * methods below this are generic for a validation/pass-through
   * if using this as a template, leave these be
   * these could be moved to a service component but the benefits didn't seem worth it
   */
  startTimeoutCounter : function(component, helper) {
    let timeoutDuration = component.get("v.recordLoadTimeout");
    helper.consoleLog('Timout in ms ' + timeoutDuration);

    // set a timeout which checks that the record was loaded
    // if not, display a "try again" error message to the user
    // NOTE: would like to make this syntax simpler but I forgot how
    window.setTimeout(
      $A.getCallback(function() {
        helper.timeoutHandler(component, helper);
      }), timeoutDuration
    );
  },

  timeoutHandler : function(component, helper) {
    helper.consoleLog('in timeout handler');

    try {
      helper.toggleSpinner(component.getSuper());

      let isRecordLoaded = component.get("v.recordDetailsLoaded");
      helper.consoleLog('isRecordLoaded ' + isRecordLoaded);
      if (typeof isRecordLoaded == "undefined") {
          // this means the component is already gone
          return;
      }

      if (!isRecordLoaded) {
        let timeoutMessage = $A.get("$Label.c.UI_RecordTimeout");
        helper.displayErrorAndClose(component, helper, timeoutMessage);
      }
    } catch(err) {
      // component is probably gone, don't worry about it 
      helper.consoleLog('some error happened ' + err);
    }
  },

  handleRecordLoaded : function(component, helper) {
    helper.consoleLog("Record loaded successfully.");

    // record is loaded, timout error will not fire
    component.set("v.recordDetailsLoaded", true);

    helper.toggleSpinner(component.getSuper());

    let errorMessage = helper.validateRecord(component, helper);
    if (errorMessage) {
      helper.displayErrorAndClose(component, helper, errorMessage);
    } else {
      helper.navigate(component, helper);
    }
  },

  navigate : function(component, helper) {
    let targetUrl = helper.constructUrl(component, helper);
    helper.consoleLog('navigating to ' + targetUrl);

    // this style of navigation still works but is depricated
    // there is no alternative yet
    let urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
        "url" : targetUrl
    });
    urlEvent.fire();
  },

  displayErrorAndClose : function(component, helper, errorMessage) {
    helper.consoleLog(errorMessage);
    helper.showErrorToast(errorMessage);

    // close the modal (the toast will persist)
    $A.get("e.force:closeQuickAction").fire();
  }
})
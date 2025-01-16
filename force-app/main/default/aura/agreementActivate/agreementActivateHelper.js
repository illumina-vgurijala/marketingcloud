({
  /*
   * top two methods are specific to this implementation
   * if using this as a template for a validation/pass-through
   * implement these two methods to fit business requirements
  */
  validateRecord : function(component, helper) {
    // get Agreement details
    let rec = component.get("v.recordDetails");

    let aliOptional = $A.get("$Label.c.AgreementLineItemOptional");
    // validate required fields
    let hasRequiredVals = false;
    if (rec.Line_Items_Required_Optional__c == aliOptional || (rec.Apttus__Contract_Start_Date__c && rec.Apttus__Contract_End_Date__c && rec.Apttus__Subtype__c)) {
      hasRequiredVals = true;
    }
    helper.consoleLog(rec.Apttus__Contract_Start_Date__c);
    helper.consoleLog(rec.Apttus__Contract_End_Date__c);
    helper.consoleLog(rec.Apttus__Subtype__c);
    helper.consoleLog('Required values present: ' + hasRequiredVals);

    // return error message if not valid
    if (hasRequiredVals) {
      return '';
    } else {
      let valuesBlankMessage = $A.get("$Label.c.UI_ActivateRequiredValues")
      return valuesBlankMessage;
    }
  },

  constructUrl : function(component, helper) {
    // get Agreement details
    let recId = component.get("v.recordId");
  
    // construct URL
    // TODO: use navigate service
    let targetUrl = '/lightning/cmp/c__AgreementActionComponent?c__AgreementId=' + recId + '&c__Action=Activate';
    return targetUrl;
  },

  getObjectType : function(component, helper) {
    return "Apttus__APTS_Agreement__c";
  },

  /*
   * methods below this are generic for a validation/pass-through
   * if using this as a template, leave these be
   * these could be moved to a service component but the benefits didn't seem worth it
   */
  loadRecord : function(component, helper) {
    // get record ID
    let recId = component.get("v.pageReference").state.c__recordId;
    component.set("v.recordId", recId);
    helper.consoleLog('record id is ' + recId);

    // reload recordData using ID
    let rec = component.find("recordLoader");
    rec.reloadRecord();
    helper.consoleLog('loading record...');
  },

  handleRecordLoaded : function(component, helper) {
    helper.consoleLog("Record loaded successfully.");

    let errorMessage = helper.validateRecord(component, helper);
    if (errorMessage) {
        // turn off spinner, display back button, and toast error
        helper.toggleSpinner(component.getSuper());
        component.set("v.displayErrorMessage", true);
        helper.displayError(component, helper, errorMessage);
    } else {
      // navigate directly to next page, leave spinner until gone
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

  displayError : function(component, helper, errorMessage) {
    helper.consoleLog(errorMessage);
    helper.showErrorToast(errorMessage);
  },

  goBack : function(component, helper) {
    // error message was toasted
    // now give user the option to go back and correct the data
    let recId = component.get("v.recordId");
    let objType = helper.getObjectType();
    let pageRef = {
      "type": "standard__recordPage",
      "attributes": {
        "recordId": recId,
        "objectApiName": objType,
        "actionName": "view"
      }
    };

    let btn = component.find("navLink");
    btn.navigate(pageRef, true);
  }

})
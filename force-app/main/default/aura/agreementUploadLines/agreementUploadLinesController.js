({
  initComponent : function(component, event, helper) {
    helper.toggleSpinner(component.getSuper());
    // NOTE: will be toggled off when record is loaded (helper.handleRecordLoaded)

    
    let recordid = component.get("v.recordId");
        helper.callServer(component,"c.getAgreementAura", function(response) 
        {
          console.log('agreement load'+JSON.stringify(response));
          component.set("v.recordDetails",response);
          component.set("v.recordDetailsLoaded",true);
          //method to stop Spinner 
          helper.handleRecordLoaded(component, helper);        },
        {
          agreementId: recordid
        }
        );
        helper.startTimeoutCounter(component, helper);
  },

 
})
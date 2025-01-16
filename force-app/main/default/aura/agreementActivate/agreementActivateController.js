({
  initComponent : function(component, event, helper) {
    helper.toggleSpinner(component.getSuper());
    // NOTE: will be toggled off when record is loaded (helper.handleRecordLoaded)

    helper.loadRecord(component, helper);
  },
  
  handleRecordUpdated : function(component, event, helper) {
    // logic will run only when record load is complete
    let eventParams = event.getParams();
    if (eventParams.changeType === "LOADED") {
      helper.handleRecordLoaded(component, helper);
    }
  },

  goBack : function(component, event, helper) {
    // back button
    helper.goBack(component, helper);
  }

})
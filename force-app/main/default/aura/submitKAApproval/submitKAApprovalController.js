({
  closeQA : function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },
  //INC0310817
  handleReload : function(component, event, helper) {
    let workspaceAPI = component.find("workspace");
    workspaceAPI.getFocusedTabInfo().then(function(response) {
        let focusedTabId = response.tabId;
        workspaceAPI.refreshTab({
                  tabId: focusedTabId,
                  includeAllSubtabs: true
         });
    })
    .catch(function(error) {
        //console.log(error);
        console.log(JSON.stringify(error));
    });
  }

})
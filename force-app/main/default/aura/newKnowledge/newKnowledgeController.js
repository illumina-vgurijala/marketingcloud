({
	init : function (component, event, helper) {
        console.log('In Init ---->');
        let workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isCon) {
            console.log('isCon => ', JSON.stringify(isCon));
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                let focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: "New Knowledge"
                });
                workspaceAPI.setTabIcon({
                    tabId: focusedTabId, 
                    icon: "standard:knowledge",
                    iconAlt: "New Knowledge"
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        });
        component.set("v.CurrentUserId",$A.get("$SObjectType.CurrentUser.Id"));
        component.set("v.CheckLoad",true);
    },
    
    handleclick: function(component, event) {

        let knowledgeid = event.getParam('value');           
        let workspaceAPI = component.find("workspace");
        
        workspaceAPI.isConsoleNavigation().then(function(response) {            
            if(response){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    let focusedTabId = response.tabId;           
                    if(knowledgeid) {               
                        workspaceAPI.openTab({
                            recordId: knowledgeid,
                            focus: true
                        }).then(function(response) {
                            workspaceAPI.closeTab({tabId: focusedTabId});                      
                        }).catch(function(error) {
                            console.log(error);
                        });
                    }else{
                        workspaceAPI.closeTab({tabId: focusedTabId});  
                    }           
                        
                }).catch(function(error) {
                    console.log(error);
                });
            }
            else{
                let navService = component.find("navService");
                // Uses the pageReference definition in the init handler  
                let pageReference; 
                if(knowledgeid) {  
                    pageReference = {
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: knowledgeid,
                            objectApiName: 'Knowledge__kav',
                            actionName: 'view'
                        }
                    };
                }
                else {
                    pageReference = {
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Knowledge__kav',
                            actionName: 'list'
                        }
                    };
                }          
                event.preventDefault();
                navService.navigate(pageReference);
            }          
           
        }).catch(function(error) {
            console.log(error);           
        });             
    }
})
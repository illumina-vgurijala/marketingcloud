({
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  get the result from Apex for data needed on the page
    * 
    */
    retrieveAllAssociatedUsers: function(component, event, helper) {
        let strAccountId = component.get("v.recordId");
        
        // set default sort UI
        component.set("v.booSortAsc", true);
        component.set("v.strSortField", "Territory2.Territory2Type.Priority");
        
        // add callback for Apex that passes result to view
        helper.callServer(component,"c.getUsers",function(response){
            response = JSON.parse(response);
            helper.consoleLog('lstUserAssociations',false,response.lstUserAssociations);
            helper.consoleLog('labelToValue',false,response.labelToValue);
            component.set('v.labelToValue',response.labelToValue);
            helper.parseData(component,response.lstUserAssociations);
            
        },{
            "strAccountId" : strAccountId
        });
        
    },
    
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  method to handle sorting of the lightning data table
    * 
    */
    updateColumnSorting: function (component, event, helper) {
        let strFieldName = event.getParam('fieldName');
        let strSortDirection = event.getParam('sortDirection');
            
        component.set("v.strSortField", strFieldName);
        component.set("v.strSortDirection", strSortDirection);
        helper.sortData(component, strFieldName, strSortDirection);
    }
})
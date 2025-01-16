({
	doInit : function(component, event, helper) {
        //Calling loadData of helper to fetch records.
        helper.loadData(component,helper);
	},
    
    getCodes : function(component, event, helper) {
		//Calling getCodes of helper to fetch code libraries to the matched search string.
		helper.getCodes(component,helper);
    },
    /*
    * @author KD
    * @date  20-May-2020
    * Story : DCP-37793 
    * @description  JS funtion to handle row action 
    * 
    */
    handleCodeSearchRowAction : function(component, event, helper) {
		//Calling getCodes of helper to fetch code libraries to the matched search string.
        let action = event.getParam('action');
        let row = event.getParam('row');
        if(action.name === 'Add_Record'){
            helper.addCode(component, event,helper,row.Id);
        }
        if(action.name === 'Remove_Record'){
            helper.removeCode(component, event,helper,row.Id,row.ParentURL,row.isActive);
        }
    },
    
    getCodeType: function(component,event,helper){
        let codeType = event.getSource().get("v.label");
        component.set("v.SelectedSearchOption" , codeType);
        helper.updateColumns(component,helper,codeType);
    },    
    checkEnter : function(component, event, helper) {
        //redirect if enter key is pressed
        if(event.keyCode == 13){
            //Calling getCodes of helper to fetch code libraries to the matched search string.
            helper.getCodes(component,helper);
        }
    },
     /*
    * @author Kushagra Desai
    * @date   14-May-2020
    * Story : DCP-37793
    * @description  method to handle sorting of the lightning data table
    * 
    */
    updateColumnSorting: function (component, event, helper) {
        let strFieldName = event.getParam('fieldName');
        let strSortDirection = event.getParam('sortDirection');
        let data = component.get("v.CodeLibraryList");
        component.set("v.strSortField", strFieldName);
        component.set("v.strSortDirection", strSortDirection);
        helper.sortData(component, strFieldName, strSortDirection,data,'CodeLibrary');
    },
    /*
    * @author Kushagra Desai
    * @date   14-May-2020
    * Story : DCP-37793
    * @description  method to handle sorting of the lightning data table
    * 
    */
    updateColumnSortingAssociatedCode: function (component, event, helper) {
        let strFieldName = event.getParam('fieldName');
        let strSortDirection = event.getParam('sortDirection');
        let data = component.get("v.AssociatedCodeList");
        component.set("v.strSortField", strFieldName);
        component.set("v.strSortDirection", strSortDirection);
        helper.sortData(component, strFieldName, strSortDirection,data,'AssociatedCode');
    }
})
({
    /*
	 * @author	Sarath Pullanikkatt
	 * @date	01-Nov-2018
	 * @description	Initialization and page load
	*/
    init : function(component, event, helper) {
        component.set('v.lstColumns', helper.getColumnDefinitions());
        helper.setFilterDefaults(component);
    },
    
    /*
	 * @author	Sarath Pullanikkatt
	 * @date	15-Nov-2018
	 * @description	Search functionality. Calls the helper to validate form and perform search.
	*/
    search : function(component, event, helper) {
        helper.validateAndSearch(component, event, helper);
    },
    
    /*
	 * @author	Sarath Pullanikkatt
	 * @date	07-Dec-2018
	 * @description	Reset the log viewer with defaults. Calls helper methods to set Aura attribute defaults and filter defaults.
	*/
    reset : function(component, event, helper) {
        helper.setAttributeDefaults(component);
        helper.setFilterDefaults(component);
    },
    
    /*
     * @author	Sarath Pullanikkatt 
     * @date	29-Nov-2018
     * @description	OnChange event for Sync Direction drop-down. Update Interface drop-downs.
    */
    changeSyncDirection : function(component, event, helper) {
        component.set('v.strSyncDirection', component.find('SyncDirection').get('v.value'));
        let mapDirToInterfacesList = component.get('v.mapDirToInterfacesList');
        helper.setInterfacePicklist(component, mapDirToInterfacesList, null);
    },
    
    /*
     * @author	Sarath Pullanikkatt 
     * @date	30-Nov-2018
     * @description	OnChange event for Interface drop-down.
    */
    changeInterface : function(component, event, helper) {
        component.set('v.strInterface', component.find('Interface').get('v.value'));
    },
    
    /*
     * @author	Sarath Pullanikkatt 
     * @date	03-Dec-2018
     * @description	OnRowAction event for displaying the JSON body.
    */
    handleRowAction : function(component, event, helper) {
        let action = event.getParam('action');
        let row = event.getParam('row');
        
        //User clicked the 'Show JSON' action.
        if(action.name == 'showJSON') {
            component.set('v.blnShowJSON', true);
            component.set('v.strActiveJSON', row.strJSONMessage);
        }
        //User clicked the 'Open Related Record' action.
        else if(action.name == 'openRelated') {
            if(row.strRelatedURL != null && row.strRelatedURL != '')
            	window.open(row.strRelatedURL, '_blank');
            else
                helper.showErrorToast('No Related Record URL found.', 'dismissible', 500);
        }
    },
    
    /*
     * @author	Sarath Pullanikkatt 
     * @date	11-Dec-2018
     * @description	Sort the search results.
    */
    updateColumnSorting : function(component, event, helper) {
        let strFieldName = event.getParam('fieldName');
        let strSortDirection = event.getParam('sortDirection');
        
        component.set('v.strSortedBy', strFieldName);
        component.set('v.strSortedDirection', strSortDirection);
        helper.sortData(component, strFieldName, strSortDirection);
    },
})
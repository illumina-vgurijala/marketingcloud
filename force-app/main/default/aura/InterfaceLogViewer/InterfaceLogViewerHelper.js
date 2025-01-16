({
    /*
	 * @author	Sarath Pullanikkatt
	 * @date	15-Nov-2018
	 * @description	Search functionality. Validate form and retrieve search results.
	*/
    validateAndSearch : function(component, event, helper) {
        
        //Validate Search Text
        let strSearchText = component.get('v.strSearchText').trim();//CodeScan Fix
        if(!($A.util.isEmpty(strSearchText)) && strSearchText.length < 2) {
            helper.showErrorToast('The search term should be at least 2 characters. Clear the search term for a simple search.', 'sticky');
            return false;
        }
        
        //Validate Sync Direction
        let strSyncDirection = component.get('v.strSyncDirection');//CodeScan Fix
        if($A.util.isEmpty(strSyncDirection) || strSyncDirection == 'Any')
            strSyncDirection = '';
        
        //Validate Interface
        let strInterface = component.get('v.strInterface');//CodeScan Fix
        if($A.util.isEmpty(strInterface))
            strInterface = '';
        
        //Fetch Start Date/Time
        let dtStartDateTime = component.get('v.dtStartDateTimePicker');//CodeScan Fix
        
        //Fetch End Date/Time
        let dtEndDateTime = component.get('v.dtEndDateTimePicker');//CodeScan Fix
        
		//Validate Start End/Time and End Date/Time
        if(dtEndDateTime <= dtStartDateTime) {
            helper.showErrorToast('End Date/Time cannot be before Start Date/Time.', 'sticky');
            return false;
        }
        console.log(strSearchText);
        console.log(strSyncDirection);
        console.log(strInterface);
        let lstInterfaceLogs = component.get("c.searchLogs");//CodeScan Fix
        lstInterfaceLogs.setParams({
            "strSearchText" : strSearchText,
            "strSyncDirection" : strSyncDirection,
            "strInterface" : strInterface,
            "dtStartDateTime" : dtStartDateTime,
            "dtEndDateTime" : dtEndDateTime
        });
        
        //Clear the current search results for new searches
        component.set('v.lstSearchResults', []);
        component.set('v.blnShowJSON', false);
		
        this.toggleSpinner(component, event);
        
        //Create a callback that is executed after the server-side action returns.
        lstInterfaceLogs.setCallback(this, function(action) {
            this.toggleSpinner(component, event);
            if(action.getState() === 'SUCCESS') {
                let currentResults = component.get('v.lstSearchResults');//CodeScan Fix
                component.set('v.lstSearchResults', currentResults.concat(action.getReturnValue()));
            }
            else {
                helper.showErrorToast(action.getState(), 'sticky');
            }
        });
        
        //Add the Apex action to the queue
        $A.enqueueAction(lstInterfaceLogs);
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	21-Nov-2018
     * @description	Get the data table column definitions.
    */
    getColumnDefinitions : function() {
        let actions = [//CodeScan Fix
            {label: 'Show JSON', name: 'showJSON'},
            {label: 'Open Related Record', name: 'openRelated'}
        ];
        
        let columns = [//CodeScan Fix
            {label: 'Log Name', fieldName: 'strURL', type: 'url', typeAttributes: {label : {fieldName: 'strName'}, target: '_blank'}, sortable: false},
            {label: 'Interface Name', fieldName: 'strInterfaceName', type: 'text', sortable: true},
            {label: 'Direction', fieldName: 'strDirection', type: 'text', sortable: true},
            {label: 'Timestamp', fieldName: 'dtLogTimeStamp', type: 'dateTime', sortable: true},
            {label: 'Result', fieldName: 'strResult', type: 'text', sortable: true},
            {label: 'Created By', fieldName: 'strCreatedBy', type: 'text', sortable: true},
            {type: 'action', typeAttributes: {rowActions: actions}}
        ];
        
        return columns;
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	29-Nov-2018
     * @description	Set the default filters for the search page.
    */
    setFilterDefaults : function(component) {
        let interfaceDetails = component.get("c.fetchInterfaceDetailsMetadata");//CodeScan Fix
        
        //Create a callback that is executed after the server-side action returns.
        interfaceDetails.setCallback(this, function(action) {
            if(action.getState() === 'SUCCESS') {
                let mapDirToInterfacesList = action.getReturnValue();//CodeScan Fix
                let lstSyncDirections = component.get('v.lstSyncDirections');//CodeScan Fix
                
                for(let key in mapDirToInterfacesList) {//CodeScan Fix
                    lstSyncDirections.push(key);
                }
                lstSyncDirections.sort();
                component.set('v.lstSyncDirections', lstSyncDirections);
                component.set('v.mapDirToInterfacesList', mapDirToInterfacesList);
                
                this.setInterfacePicklist(component, mapDirToInterfacesList, lstSyncDirections);
                this.setStartAndEndDateTimes(component);
            }
            else {
                helper.showErrorToast(action.getState(), 'sticky');
            }
        });
        
        //Add the Apex action to the queue
        $A.enqueueAction(interfaceDetails);
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	29-Nov-2018
     * @description	Set the drop-down values for Interface picklist.
    */
    setInterfacePicklist : function(component, mapDirToInterfacesList, lstSyncDirections) {
        let lstInterfaces = component.get('v.lstInterfaces');//CodeScan Fix
        let strSyncDirection = component.get('v.strSyncDirection');//CodeScan Fix
        
        if($A.util.isEmpty(strSyncDirection) && !($A.util.isEmpty(lstSyncDirections)))
            strSyncDirection = lstSyncDirections[0];
        
        lstInterfaces = mapDirToInterfacesList[strSyncDirection];
        lstInterfaces.sort();
        component.set('v.lstInterfaces', []);
        component.set('v.lstInterfaces', lstInterfaces);
        component.set('v.strInterface', '');
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	29-Nov-2018
     * @description	Set the Start Date/Time and End Date/Time fields.
    */
    setStartAndEndDateTimes : function(component) {
        let today = new Date();//CodeScan Fix
        component.set('v.dtStartDateTimePicker', ($A.localizationService.formatDateTime(today, 'yyyy-MM-ddT00:00:00.000Z')));
        let tomorrow = today.setDate(today.getDate() + 1);//CodeScan Fix
        component.set('v.dtEndDateTimePicker', ($A.localizationService.formatDateTime(tomorrow, 'yyyy-MM-ddT00:00:00.000Z')));
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	07-Dec-2018
     * @description	Set the Aura attribute defaults.
    */
    setAttributeDefaults : function(component) {
        component.set('v.lstSyncDirections', []);
        component.set('v.lstInterfaces', []);
        component.set('v.mapDirToInterfacesList', {});
        component.set('v.strSearchText', '');
        component.set('v.lstSearchResults', []);
        component.set('v.blnShowJSON', false);
        component.set('v.strActiveJSON', '');
        return false;
    },
    
    /*
     * @author	Sarath Pullanikkatt 
     * @date	11-Dec-2018
     * @description	Helper to sort the data table.
    */
    sortData : function(component, strFieldName, strSortDirection) {
        let dataToBeSorted = component.get('v.lstSearchResults');//CodeScan Fix
        let blnReverse = strSortDirection !== 'asc';//CodeScan Fix
        dataToBeSorted.sort(this.sortBy(strFieldName, blnReverse));
        component.set('v.lstSearchResults', dataToBeSorted);
    },
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	11-Dec-2018
     * @description	Loading spinner renderer
    */
    toggleSpinner : function(component, event) {
        $A.util.toggleClass(component.find('spinning-wheel'), 'slds-hide');
    }
})
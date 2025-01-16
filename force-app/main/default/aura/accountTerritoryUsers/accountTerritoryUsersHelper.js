({
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  parse the list returned into a JSON that can be passed to lightning data table
    * 
    */
    parseData: function(component, lstUserAssociations) {
        let lstWrapper =[];
        component.set('v.columns',[
            {label: 'Name', fieldName: 'userName', type: 'text', sortable: true},
            {label: 'Role In Territory', fieldName: 'roleName', type: 'text', sortable: true},
            {label: 'Territory Level', fieldName: 'territory', type: 'text', sortable: true},
            {label: 'Email', fieldName: 'email', type: 'email', sortable: true},
            {label: 'Last Modified', 
            fieldName: 'lastEdit', 
            type: 'date', 
            sortable: true,
            typeAttributes: {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }
            }
        ]);
        if(!$A.util.isEmpty(lstUserAssociations))
            lstUserAssociations.forEach(function(userAssociation){
                lstWrapper.push({userName: userAssociation.User.Name,
                                roleName: userAssociation.RoleInTerritory2,
                                territory: userAssociation.Territory2.Territory2Type.MasterLabel,
                                email: userAssociation.User.Email,
                                lastEdit: userAssociation.LastModifiedDate});
                });
        this.consoleLog('lstWrapper: ',false,lstWrapper);
        component.set('v.data',lstWrapper);
        if(!$A.util.isEmpty(lstWrapper))
        	this.sortData(component,component.get('v.strSortField'),component.get('v.strSortDirection'));
     },
    
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  sort the JSON list based on field and sort direction
    * 
    */
	 sortData: function (component, strFieldName, strSortDirection) {
        let data = component.get("v.data");
        let booReverse = strSortDirection !== 'asc';
        data.sort(this.sortBy(strFieldName, booReverse))
        component.set("v.data", data);
    }
})
export const columnContact = [
    {
        label: 'Name',
        fieldName: 'NameUrl',
        type: 'url',
        
        typeAttributes: {label: { fieldName: 'Name' }, 
        tooltip : {fieldName: 'Name'},
        target: '_blank'},
        sortable: true
    },
    {
        label : 'Title',
        fieldName : 'Title',
        sortable: true
        
    },
    {
        label: 'AccountName',
        fieldName: 'AccountUrl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'AccountName' },
        tooltip : {fieldName: 'AccountName'}, 
        target: '_blank'},
        sortable: true
        
    },
    {
        label : 'Role',
        fieldName : 'Roles',
        sortable: true
    },
    {
        label : 'Region',
        fieldName : 'Region',
        sortable: true
    },
    {
        label : 'Email',
        fieldName : 'Email',
        sortable: true
    },
    {
        type:  'button-icon',
        typeAttributes: 
        {
            iconName: 'utility:add',
            label: '', 
            variant : 'bare',
            name: 'Add Stakeholder ', 
            title: 'Add Stakeholder', 
            disabled: false, 
        }
    }
];
export const columnStakeholder = [
    {
        label: 'First Name',
        fieldName: 'stakeholderForFirstNameUrl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'Contact__r.FirstName' },
        tooltip : {fieldName: 'Name'}, 
        target: '_blank'},
        sortable: true
        
    },
    {
        label: 'Last Name',
        fieldName: 'stakeholderForLastNameUrl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'Contact__r.LastName' },
        tooltip : {fieldName: 'Name'}, 
        target: '_blank'},
        sortable: true
        
    }, 
    {
        label : 'Support Quotient',
        type:"number",
        sortable: true,
        fieldName : 'Support_Quotient__c'
    }, 
    {
        label : 'Ranking',
        type:"text",
        type:  'button',
        initialWidth: 131,
        sortable: true,
        fieldName: 'Ranking_in_Number__c',
        typeAttributes: 
        {
            label: {fieldName: 'Ranking_in_Number__c',}, 
            sortable: true,
            variant : 'bare',
            name: 'Rating', 
            title: 'Find Ranking & Support Quotient ',
            disabled: false
            
        }
    },
    {
        label : 'Influence',
        type:"Picklist",
        sortable: true,
        fieldName : 'Influence__c'
    },
    {
        label: 'Support',
        type:"Picklist",
        sortable: true,
        fieldName: 'Level_of_Support__c',
    },
    {
        label : 'Access',
        type:"Picklist",
        sortable: true,
        fieldName : 'Current_Access__c'
    },
    {
        label : 'Buying Role',
        type:"Picklist",
        sortable: true,
        fieldName : 'Buying_Role__c'
    },
    {
        label : 'Department',
        type:"text",
        sortable: true,
        fieldName : 'Department__c'
    },
    {
        type:  'button-icon',
        typeAttributes: 
        {
            iconName: 'utility:close',
            label: '', 
            variant : 'bare',
            name: 'Remove Stakeholder', 
            title: 'Remove Stakeholder',
            disabled: false
            
        }
    },
    {
        type:  'button-icon',
        typeAttributes: 
        {
            iconName: 'utility:edit',
            label: '', 
            variant : 'bare',
            name: 'Edit Stakeholder', 
            title: 'Edit Stakeholder',
            disabled: false
            
        }
    }
];
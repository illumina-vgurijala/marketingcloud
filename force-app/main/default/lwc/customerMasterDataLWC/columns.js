export const lstDirectColumns = [
    {
        label: 'Name', 
        fieldName: 'strName', 
        type: 'text', 
        sortable: true,
        cellAttributes: { iconName: { fieldName: 'strIcon' }, 
                            iconPosition: 'left' }
    },
    {
        label: '', 
        type: 'button',
        initialWidth: 35, 
        variant:'base',
        typeAttributes: { label:'',iconName: 'utility:info',variant:'base', title:  {fieldName: 'strName'}}
    },
    {
        label: 'Default Partner',                                                             //DCP-28541 Added column for default
        fieldName: 'strDefault', 
        type: 'boolean', 
        sortable: true
    },
    {label: 'Care Of', fieldName: 'strCareOf', type: 'text', sortable: true},
    {label: 'Street', fieldName: 'strAddress', type: 'text', sortable: true},
    {label: 'City', fieldName: 'strCity', type: 'text', sortable: true},
    {label: 'Zip/Postal', fieldName: 'strZip', type: 'text', sortable: true},
    {label: 'State/Province', fieldName: 'strState', type: 'text', sortable: true},
    {label: 'Country', fieldName: 'strCountry', type: 'text', sortable: true},
    {label: 'ERP Customer Id', fieldName: 'strERP', type: 'text', sortable: true},
    {label: 'Relationship', fieldName: 'strRelationship', type: 'text', sortable: true}
];

export const lstIndirectColumns = [
    {
        label: 'Name', 
        fieldName: 'strName', 
        type: 'text', 
        sortable: true,
        cellAttributes: { iconName: { fieldName: 'strIcon' }, 
                            iconPosition: 'left' }
    },
    {
        label: '', 
        type: 'button',
        initialWidth: 35, 
        variant:'base', 
        typeAttributes: { label:'',iconName: 'utility:info',variant:'base', title: {fieldName: 'strName'}}
    },
    {
        label: 'Default Partner',                                                               //DCP-28541 Added column for default
        fieldName: 'strDefault', 
        type: 'Boolean', 
        sortable: true
    },
    {label: 'Care Of', fieldName: 'strCareOf', type: 'text', sortable: true},
    {label: 'Street', fieldName: 'strAddress', type: 'text', sortable: true},
    {label: 'City', fieldName: 'strCity', type: 'text', sortable: true},
    {label: 'Zip/Postal', fieldName: 'strZip', type: 'text', sortable: true},
    {label: 'State/Province', fieldName: 'strState', type: 'text', sortable: true},
    {label: 'Country', fieldName: 'strCountry', type: 'text', sortable: true},
    {label: 'ERP Customer Id', fieldName: 'strERP', type: 'text', sortable: true},
    {label: 'Account Group', fieldName: 'strAccountGroup', type: 'text', sortable: true}
];
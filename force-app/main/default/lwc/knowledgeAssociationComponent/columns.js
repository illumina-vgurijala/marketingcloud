export const columns = [{
    label: 'Title',
    fieldName: 'strRelatedRecordId',
    type: 'url',

    typeAttributes: {
        label: {
            fieldName: 'strTitle'
        },
        tooltip: {
            fieldName: 'strTitle'
        },
        target: '_parent'
    },
    sortable: true,
    wrapText : true
},
{
    label: 'Source',
    fieldName: 'strSource',
    sortable: true,
    type: 'text'
},
{
    label: "Last Updated",
    fieldName: "strLastModifiedDate",
    sortable: true,
    type: "date",
    typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit"
    }
},
{
    label : 'Remove',
    type: 'button',
    fixedWidth: 60,
    typeAttributes: {
        iconName: 'action:close',
        name: 'Remove_Record', 
        title: 'Remove',
        variant: 'destructive',
        alternativeText: 'Remove',
        label: '',
    }
}
];
export const searchColumns = [{
    label: 'Title',
    fieldName: 'strRecordURL',
    type: 'url',

    typeAttributes: {
        label: {
            fieldName: 'strTitle'
        },
        tooltip: {
            fieldName: 'strTitle'
        },
        target: '_parent'
    },
    sortable: true,
    wrapText : true
},
{
    label: 'Source',
    fieldName: 'strSource',
    sortable: true,
    type: 'text'
},
{
    label: 'Type',
    fieldName: 'strRecordType',
    sortable: true,
    type: 'text'
},
{
    label: "Last Updated",
    fieldName: "strLastModifiedDate",
    sortable: true,
    type: "date",
    typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit"
    }
},
{
    label : 'Add',
    type: 'button',
    fixedWidth: 60,
    typeAttributes: {
        iconName: 'action:new',
        name: 'Add_Record', 
        title: 'Add',
        variant: 'success',
        alternativeText: 'Add',
        label: '',           
    }  
}
];
export const column = [{
    label: 'Account',
    fieldName: 'accountURL',
    type: 'url',

    typeAttributes: {
        label: {
            fieldName: 'accountName'
        },
        tooltip: {
            fieldName: 'accountName'
        },
        target: '_blank'
    },
    sortable: true
},
{
    label: "Owner",
    fieldName: "ownerName",
    sortable: true
},
{
    label: "ERP Number",
    fieldName: "erpNumber",
    sortable: true
},
{
    type: 'button-icon',
    fixedWidth: 50,
    typeAttributes: {
        iconName: 'utility:delete',
        label: '',
        variant: 'bare',
        name: 'Remove Account',
        title: 'Remove Account',
        disabled: false

    }
}
];
export const accountColumn = [{
    label: "Account Name",
    fieldName: "accountName",
    sortable: false
},
{
    label: "Owner",
    fieldName: "ownerName",
    sortable: false
},
{
    label: "ERP Number",
    fieldName: "erpNumber",
    sortable: false
},
{
    label: "City",
    fieldName: "city",
    sortable: false
},
{
    label: "Customer Type",
    fieldName: "customerType",
    sortable: false
}
];
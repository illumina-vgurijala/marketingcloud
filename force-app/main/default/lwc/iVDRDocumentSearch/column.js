const columns = [{
    label: 'Sales Order Number',
    fieldName: 'SalesOrder',
    type: 'text',
    sortable: true
},
{
    label: 'Delivery No.',
    fieldName: 'Delivery',
    type: 'text',
    sortable: true
},
{
    label: 'Quantity',
    fieldName: 'Quantity',
    type: 'text',
    sortable: true
},
{
    label: 'Material Description',
    fieldName: 'MatDescription',
    type: 'text',
    sortable: true
},
{ label: 'Download Document', type:  'button', 
        typeAttributes: { 
         label: 'Download', name: 'Download', variant: 'base',
        iconPosition: 'right' 
        },
        cellAttributes: { alignment: 'center' },
}

];
export {
     columns
}; 
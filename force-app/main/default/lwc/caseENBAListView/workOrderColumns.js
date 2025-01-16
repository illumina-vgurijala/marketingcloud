const woColumns = [
    { label: 'Name', fieldName: 'NameURL', type: 'url',
    typeAttributes: { label: { fieldName: 'Name' }, target: '_self'} },
    { label: 'Subject', fieldName: 'SVMX_PS_Subject__c' },
    { label: 'Created Date', fieldName: 'CreatedDate' , type: "date",
        typeAttributes: {day: 'numeric',month: 'numeric',year: 'numeric',hour: 'numeric',minute: 'numeric', hour12: true}      
    }
];
export {
    woColumns
};
const caseColumns =  [
    {label:'Case Number',fieldName:'CaseURL',type: 'url',
    typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_self'} }, 
    {label:'Owner Name',fieldName:'OwnerURL',type: 'url',
    typeAttributes: { label: { fieldName: 'OwnerName' }, target: '_self'} }, 
    { label: 'Status', fieldName: 'Status' },
    { label: 'Record Type', fieldName: 'Record_Type__c' },
    { label: 'Subject', fieldName: 'Subject' },
    {label:'Account Name',fieldName:'AccountURL',type: 'url',
    typeAttributes: { label: { fieldName: 'AccountName' }, target: '_self'} },
    {label:'Contact Name',fieldName:'ContactURL',type: 'url',
    typeAttributes: { label: { fieldName: 'ContactName' }, target: '_self'} },
    { label: 'Created Date', fieldName: 'CreatedDate', type: "date",
        typeAttributes: {day: 'numeric',month: 'numeric',year: 'numeric',hour: 'numeric',minute: 'numeric', hour12: true} 
    }

];
export {
    caseColumns
};
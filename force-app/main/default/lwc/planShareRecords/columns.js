export const columns = [{
    label: 'RowCause',
    fieldName: 'rowCause',
    sortable: true,
}, {
    label: 'Shared With',
    fieldName: 'userName',
    sortable: true,
    type: 'text'
}, {
    label: 'Access Level',
    fieldName: 'accessLevel',
    type: 'text',
    sortable: true
}, {
    label: 'Last Modified Date',
    fieldName: 'lastModifiedDate',
    type: 'date',
    sortable: true,
    typeAttributes:
    {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true
    }
},
];
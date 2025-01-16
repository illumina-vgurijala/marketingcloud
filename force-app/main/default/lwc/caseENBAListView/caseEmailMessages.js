const emailMessagesColumns = [
    
    { label: 'Subject', fieldName: 'SubjectURL', type: 'url',
    typeAttributes: { label: { fieldName: 'Subject' }, target: '_self'}, sortable: true },
    { label: 'From Address', fieldName: 'FromAddress', sortable: true },
    {label: 'To Address',  fieldName: 'ToAddress', sortable: true },
    {label: 'Message Date',  fieldName: 'MessageDate', type: "date", sortable: true,
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            hour12: true
        }},
    {
        label: 'Status',
        fieldName: 'Status',
        sortable: true
    },

    {
        label: 'Attachment',
        sortable: true,
        cellAttributes:{ 
                iconName: { 
                    fieldName: 'paperClipIcon' 
                },
                iconPosition: 'right', 
                iconAlternativeText: 'PaperClip Icon' 
            }
    }
    
    
];
export {
    emailMessagesColumns
};
const knowledgeArticlesColumns = [
    { label: 'Title', fieldName: 'TitleURL', type: 'url',
    typeAttributes: { label: { fieldName: 'Title' }, target: '_self'} },
    { label: 'Summary', fieldName: 'Summary' },
    { label: 'Article Number', fieldName: 'ArticleNumber' },
    {label: 'Language',  fieldName: 'Language' },
    {label: 'Knowledge Source',  fieldName: 'Knowledge_Source__c' },
    {label: 'Article Record Type',  fieldName: 'RecordTypeId' }
    
];
export {
    knowledgeArticlesColumns
};
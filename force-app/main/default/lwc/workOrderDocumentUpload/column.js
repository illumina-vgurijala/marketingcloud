const tableColumns=[     
    
    {
    label:'Document Number', 
    fieldName:'documentNumber', 
    type:'text'
    },
    {
        label:'Document Name', 
        fieldName:'documentName', type:'text'
        },
    {
        label:'Activity Type',
        fieldName:'ActivityType',
        type:'text'
    },
    {type: "button", label: 'Upload Document', typeAttributes: {  
        label: 'Click to attach',  
        name: 'Upload',  
        title: 'Upload',  
        disabled: false,  
        value: 'Upload',  
        iconPosition: 'left'  
    }}, 
    {
        label:'Uploaded',
        fieldName:'documentUploaded',
        type:'boolean'
    },   
 ];

 const tableColumnsforUploadedFiles = [     

    {
    label:'Document Number', 
    fieldName:'documentNumber', 
    type:'text'
    },
    {
        label:'Document Name', 
        fieldName:'documentName', type:'text'
        },
    {
        label:'Activity Type',
        fieldName:'ActivityType',
        type:'text'
    },
    {type: "button", label: 'Click to View', typeAttributes: {  
        label: 'Click to View',  
        name: 'View',  
        title: 'View',  
        disabled: false,  
        value: 'View',  
        iconPosition: 'left'  
    }}  
 ];

 export {
    tableColumns,
    tableColumnsforUploadedFiles
};
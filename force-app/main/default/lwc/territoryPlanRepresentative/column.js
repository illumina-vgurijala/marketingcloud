const portalColumns = [{
        label: "User",
        fieldName: "strUserName",
        sortable: true
    },
    {
        label: "Role in Territory",
        fieldName: "strRole",
        sortable: true
    }

];
const internalColumns = [{
            label: "User",
            fieldName: "strUserName",
            sortable: true
        },
        {
            label: "Role in Territory",
            fieldName: "strRole",
            sortable: true
        },
        // DCP-40041
        {
            type: 'button-icon',
            fixedWidth: 20,
            typeAttributes: {
                iconName: 'utility:email',
                label: '',
                variant: 'bare',
                name: 'Notify_User',
                title: 'Request Plan',
                disabled: {fieldName : 'boolHasOverlay'}
    
            }
        },
        {
            label: 'Overlay Plan',
            fieldName: 'strPlanURL',
            type: 'url',

            typeAttributes: {
                label: {
                    fieldName: 'strPlanName'
                },
                tooltip: {
                    fieldName: 'strPlanName'
                },
                target: '_blank'
            },
            sortable: true
        }
    ];

export {
    portalColumns,
    internalColumns
};
export const opportunityField = [
    {
        label: 'Opportunity',
        fieldName: 'strOpportunityURL',
        type: 'url',
    
        typeAttributes: {
            label: {
                fieldName: 'strOpportunityName'
            },
            tooltip: {
                fieldName: 'strOpportunityName'
            },
            target: '_blank'
        },
        sortable: true
    },
    {
        label: 'Owner',
        fieldName: 'strOwnerURL',
        type: 'url',
    
        typeAttributes: {
            label: {
                fieldName: 'strOwnerName'
            },
            tooltip: {
                fieldName: 'strOwnerName'
            },
            target: '_blank'
        },
        sortable: true
    },
    {
        label: "Record Type",
        fieldName: "strOpportunityRecordType",
        sortable: true
    },
    {
        label: "Close Date",
        fieldName: "strOpportunityCloseDate",
        sortable: true
    },
    {
        label: "Probability",
        fieldName: "strOpportunityProbability",
        sortable: true
    },
    {
        label: "Amount",
        fieldName: "strOpportunityAmount",
        sortable: true
    },
    {
        label: "Market Segment",
        fieldName: "strOpportunityMarketSegment",
        sortable: true
    },
    {
        label: "Product Type",
        fieldName: "strOpportunityProductType",
        sortable: true
    }
];

export const deleteIcon = [
    {
        type: 'button-icon',
        fixedWidth: 50,
        typeAttributes: {
            iconName: 'utility:delete',
            label: '',
            variant: 'bare',
            name: 'Remove Opportunity',
            title: 'Remove Opportunity',
            disabled: false
        }
    }
];


export const associatedOppoFields = [
    {
        label: "Opportunity Name",
        fieldName: "strOpportunityName",
        sortable: false
    },
    {
        label: "Opportunity Record Type",
        fieldName: "strOpportunityRecordType",
        sortable: false
    },
    {
        label: "Stage",
        fieldName: "strOpportunityStageName",
        sortable: false
    },
    {
        label: "Probability",
        fieldName: "strOpportunityProbability",
        sortable: false
    },
    {
        label: "Close Date",
        fieldName: "strOpportunityCloseDate",
        sortable: false
    },
    {
        label: "Amount",
        fieldName: "strOpportunityAmount",
        sortable: false
    },{
        label: "Market Segment",
        fieldName: "strOpportunityMarketSegment",
        sortable: false
    },
    {
        label: "Product Type",
        fieldName: "strOpportunityProductType",
        sortable: false
    }
];

export const ownerField = [
    {
        label: "Owner",
        fieldName: "strOwnerName",
        sortable: false
    }
];

export const accountFields = [    
    {
        label: "Account Name",
        fieldName: "strAccountName",
        sortable: false
    },
    {
        label: "ERP ID",
        fieldName: "erpId",
        sortable: false
    }
];



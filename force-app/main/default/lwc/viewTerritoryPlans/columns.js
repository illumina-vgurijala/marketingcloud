export const columns = [{
    label: 'Plan Name',
    fieldName: 'strPlanId',
    type: 'url',

    typeAttributes: {
        label: {
            fieldName: 'strPlanName'
        },
        tooltip: {
            fieldName: 'strPlanName'
        },
        target: '_blank'
    }
},
{
    label: 'Owner',
    fieldName: 'strOwnerName'
},
{
    label: "Plan Target",
    fieldName: "decPlanTarget",
    sortable: false,
    type: "currency"
}
];
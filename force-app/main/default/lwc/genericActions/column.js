const column_Large = [{
    label: "Action",
    fieldName: "subject",
    sortable: true,
    wrapText: true
},
{
    label: "Assigned To",
    fieldName: "assignedTo",
    sortable: true
},
{
    label: "Due Date",
    fieldName: "dueDate",
    sortable: true,
    type: "date",
    typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit"
    }
},
{
    label: "Priority",
    fieldName: "priority",
    sortable: true
},
{
    label: "Status",
    fieldName: "status",
    sortable: true
},
{
    type: 'button-icon',
    fixedWidth: 50,
    typeAttributes: {
        iconName: 'utility:delete',
        label: '',
        variant: 'bare',
        name: 'Delete Task',
        title: 'Delete Task',
        disabled: false

    }
},
{
    type: 'button-icon',
    fixedWidth: 50,
    typeAttributes: {
        iconName: 'utility:edit',
        label: '',
        variant: 'bare',
        name: 'Edit Task',
        title: 'Edit Task',
        disabled: false

    }
}

];
export {
    column_Large
};
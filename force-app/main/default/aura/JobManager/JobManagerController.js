({
    init: function (cmp, event, helper) {
        let actions = [
            { label: 'Run Now', name: 'run_job' }
        ];

        cmp.set('v.columns', [
            { label: 'Name', fieldName: 'scheduleName', type: 'text' },
            { label: 'Scheduled', fieldName: 'friendlyCron', type: 'text' },
            { label: 'Scheduler Class Name', fieldName: 'scheduleClassName', type: 'text' },
            { label: 'Batch Class Name', fieldName: 'batchClassName', type: 'text' },
            { label: 'Batch Size', fieldName: 'batchSize', type: 'number' },
            { label: 'Scheduled', fieldName: 'currentlyScheduled', type: 'boolean' },
            { type: 'action', typeAttributes: { rowActions: actions } }
        ]);

        helper.fetchData(cmp);
    },

    handleRowAction: function (cmp, event, helper) {
        let action = event.getParam('action');
        let row = event.getParam('row');
        if(action.name === 'run_job') {
            helper.runJob(cmp, row);
        }
    },

    scheduleJobs : function(component, event, helper) {
       helper.scheduleJobs(component);
	},

    unscheduleJobs : function(component, event, helper) {
       helper.unscheduleJobs(component);
	}
})
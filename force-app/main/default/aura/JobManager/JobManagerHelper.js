({
    fetchData : function (cmp) {
        let action = cmp.get("c.getJobDetails");

        let self = this;
        action.setCallback(this, function(response) { self.fetchDataCallback(response, cmp, self); });

        $A.enqueueAction(action);
    },

    fetchDataCallback : function(response, cmp, helper) {
        if (response.getState() == "SUCCESS") {
            cmp.set("v.data", response.getReturnValue());
            helper.consoleLog('Jobs Fetched', null, response.getReturnValue());
        } else {
            helper.showErrorToast('Unknown error loading jobs', 'sticky');
            helper.consoleLog('Error loading jobs', response);
        }
    },

    runJob : function (cmp, selectedRow) {
        let action = cmp.get("c.executeBatchNow");

        action.setParams({
            "strJson" : JSON.stringify(selectedRow)
        });
        this.consoleLog('Selected row', null, selectedRow);

        let self = this;
        action.setCallback(this, function(response) { self.runJobCallback(response, selectedRow.scheduleName); });

        $A.enqueueAction(action);
    },

    runJobCallback : function(response, jobName) {
        let state = response.getState();
        if (state == "SUCCESS") {
            this.showSuccessToast(jobName + ' queued to run', 'pester');
        } else {
            this.showErrorToast('Run attempt error ' + response, 'sticky');
	        this.consoleLog('Error running job', response);
        }
    },

    scheduleJobs : function(cmp) {
		this.updateJobs(cmp, cmp.get("c.scheduleJob"));
    },

    unscheduleJobs : function(cmp) {
		this.updateJobs(cmp, cmp.get("c.unscheduleJob"));
    },

    updateJobs : function(cmp, action) {
        let jobsTable = cmp.find("jobsTable");
        let selectedRows = jobsTable.getSelectedRows();
        this.consoleLog('Selected rows', null, selectedRows);

        // NOTE: may be a simpler way to format than this
        let selectedJobs;
        for (let i = 0; i < selectedRows.length; i++) {
            selectedJobs += JSON.stringify(selectedRows[i]);
            selectedJobs += ';';
        }
        action.setParams({
            "strJsonArray" : selectedJobs
        });

        let self = this;
        action.setCallback(this, function(response) { self.updateJobsCallback(response, cmp, self); });

        $A.enqueueAction(action);
    },

    updateJobsCallback : function(response, cmp, helper) {
        let state = response.getState();
        if (state == "SUCCESS") {
            let returnValue = response.getReturnValue();
	        this.consoleLog('Call Result', null, returnValue);

            if (returnValue == 'undefined' || returnValue == null) {
                helper.showErrorToast('Unknown error occurred', 'sticky');

            } else if (returnValue == false) {
                helper.showToast('Notice', 'Job already scheduled', 'info', 'sticky');

            } else {
                // clear selected rows
                cmp.set('v.selectedRows', []);

                // refresh page
                helper.fetchData(cmp);

                helper.showSuccessToast('Jobs updated', 'pester');
            }

        } else {
	        this.consoleLog('Error scheduling/unscheduling job', response);
        }
    }
})
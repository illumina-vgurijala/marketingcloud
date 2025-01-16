import {
    LightningElement,
    track
} from 'lwc';
import {
    consoleLog,
    showErrorToast,
    callServer,
    showSuccessToast
} from 'c/utils';
import reRunPlanSharingForRecords from '@salesforce/apex/PlanSharingConsoleController.reRunPlanSharingForRecords';
import reShareAllPlans from '@salesforce/apex/PlanSharingConsoleController.reShareAllPlans';
import checkRunningJob from '@salesforce/apex/PlanSharingConsoleController.checkRunningJob';

export default class PlanSharingConsole extends LightningElement {
    @track recordId;
    @track isValidInput;
    @track recordIds = [];
    @track errorSearchMsg;
    @track isLoaded = false;
    @track showShareRecords = false;
    @track boolReShareDisable = true;
    @track apexJobData;
    handleRecordId(event) {
        this.recordId = event.detail.value;
        console.log('-->' + this.recordId);
    }
    handleRerun() {
        this.validateSearchInputs();
        if (this.isValidInput) {
            this.isLoaded = !this.isLoaded;
            callServer(reRunPlanSharingForRecords, {
                recordIds: this.recordIds
            }, result => {
                this.showShareRecords = true;
                consoleLog(result);
                this.errorSearchMsg = '';
                this.isLoaded = !this.isLoaded;
            }, error => {
                consoleLog(JSON.stringify(error));
                this.errorSearchMsg = error.body.message;
                this.isLoaded = !this.isLoaded;
            });
        }
    }
    validateSearchInputs() {
        if (!this.recordId) {
            this.errorSearchMsg = 'Please enter Record Id or Ids.';
            showErrorToast('Please enter Record Id or Ids.');
            return this.isValidInput = false;
        }

        this.recordIds = this.recordId.split(',');
        consoleLog('-->', this.recordIds);
        if (!this.checkForIdMatch(this.recordIds)) {
            this.errorSearchMsg = 'Please enter matching Record Ids for the same Object.';
            showErrorToast('Please enter matching Record Ids for the same Object');
            return this.isValidInput = false;
        }
        this.isValidInput = true;
    }
    checkForIdMatch(recordIds) {
        const arrRecordIds = recordIds.map((recordId) => recordId[0] + recordId[1] + recordId[2]);
        const isSameRecordId = (currentValue) => currentValue === arrRecordIds[0];
        return arrRecordIds.every(isSameRecordId);
    }
    handlePlanShare() {
        this.isLoaded = !this.isLoaded;
        callServer(reShareAllPlans, {},
            result => {
                showSuccessToast(result);
                this.isLoaded = !this.isLoaded;
                this.checkJob();    
            }, error => {
                this.isLoaded = !this.isLoaded;
            });
    }
    checkJob(){
        this.isLoaded = !this.isLoaded;
        this.apexJobData = '';
        this.boolReShareDisable = true;
        callServer(checkRunningJob, {},
            result => {
                let data = JSON.parse(result);//CodeScan Fix
                this.boolReShareDisable = data.boolRunningClass;
                if(this.boolReShareDisable){
                    this.apexJobData = data.lstApexJobs[0];
                }
                this.isLoaded = !this.isLoaded;
            }, error => {
                this.isLoaded = !this.isLoaded;
            });
    }
}
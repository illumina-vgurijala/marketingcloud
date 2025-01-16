import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    consoleLog,
    isNotEmpty,
    consoleError,
    callServer
} from 'c/utils';
import {
    columns
} from './columns.js';
import UI_Label_No_Share_Records from '@salesforce/label/c.UI_Label_No_Share_Records';
import UI_Label_Sharing_Records from '@salesforce/label/c.UI_Label_Sharing_Records';
import initRecords from '@salesforce/apex/PlanShareRecordsController.initRecords';
export default class PlanShareRecords extends LightningElement {
    @api recordId;
    @track lstRecordId = [];
    @track lstPlanShare = [];
    @track column = columns;
    @track booLoaded = false;
    @track hasError = false;
    @track errorMessage;
    label = {
        UI_Label_Sharing_Records,
        UI_Label_No_Share_Records
    };
    connectedCallback(){
        this.lstRecordId = this.recordId.split(',');
        callServer(initRecords, {
            lstRecordId : this.lstRecordId
        }, result => {
            this.lstPlanShare = JSON.parse(result);
        }, error => {
            this.errorMessage = error;
            this.hasError = true;
        });
        this.booLoaded = true;
    }
    // getter to show table
    get showDataTable() {
        return isNotEmpty(this.lstPlanShare)
    }
}
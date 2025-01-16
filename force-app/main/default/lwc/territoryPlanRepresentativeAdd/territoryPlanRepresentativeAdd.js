import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    callServer,
    consoleLog,
    isEmpty,
    genericEvent,
    consoleError //DCP-56402 [CodeScan Issue Fix]
} from 'c/utils';
import getAddUsers from '@salesforce/apex/PlanRepresentativeController.getAddUsers';
import addUsers from '@salesforce/apex/PlanRepresentativeController.addUsers';


const columnRemove = [{
        label: "User",
        fieldName: "strUserName",
        sortable: true
    },
    {
        label: "Role in territory",
        fieldName: "strRole",
        sortable: true
    },
    {
        type: 'button-icon',
        fixedWidth: 50,
        typeAttributes: {
            iconName: 'utility:add',
            label: '',
            variant: 'bare',
            name: 'Add User',
            title: 'Add User',
            disabled: false

        }
    }
];
export default class TerritoryPlanRepresentativeAdd extends LightningElement {
    @api planId;
    @track booLoading = false;
    @track isLoaded = false;
    @track column = columnRemove;
    @track planRepresentativesAvailable;
    @track hasError = false;
    connectedCallback() {
        this.booLoading = true;
        callServer(getAddUsers, {
            recordId: this.planId
        }, result => {
            consoleLog('Add screens--->', result);
            this.planRepresentativesAvailable = JSON.parse(result);
            if (!isEmpty(this.planRepresentativesAvailable))
                this.isLoaded = true;
            this.booLoading = false;
        }, error => {
            consoleError('Error', error);
            this.booLoading = false;
        });
    }
    // Data Table funtionality
    handleRowAction(event) {
        this.booLoading = true;
        const rowDetail = event.detail.value;
        consoleLog('Action Row -->',JSON.stringify(rowDetail));//DCP-56402 [CodeScan Issue Fix]
        this.addPlanReps('[' + JSON.stringify(rowDetail) + ']');
    }
    // handler for multi row addition
    selectPlanRepresentative(event) {
        this.booLoading = true;
        let selectedRecords = this.template.querySelector('c-data-table-lazy-load').fetchSelectedRecord();
        consoleLog('Selected row --> ',JSON.stringify(selectedRecords));//DCP-56402 [CodeScan Issue Fix]
        this.addPlanReps(JSON.stringify(selectedRecords));
    }
    // method to call apex method for plan rep addition
    addPlanReps(strJSON) {
        callServer(addUsers, {
            strJSON: strJSON,
            strRecordId: this.planId
        }, result => {
            const objDetails = Object.create({});
            objDetails.value = result;
            genericEvent('showplanrepview', objDetails, this);
            this.booLoading = false;
        }, error => {
            this.hasError = true;
            this.errorMessage = JSON.stringify(error);
            consoleError(error);
            this.booLoading = false;
        });
    }
}
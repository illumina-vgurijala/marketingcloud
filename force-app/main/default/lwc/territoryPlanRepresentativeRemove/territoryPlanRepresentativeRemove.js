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
import removeUsers from '@salesforce/apex/PlanRepresentativeController.removeUsers';
const columnRemove = [{
        label: "User",
        fieldName: "strUserName"
    },
    {
        label: "Role in territory",
        fieldName: "strRole"
    },
    {
        type: 'button-icon',
        fixedWidth: 50,
        typeAttributes: {
            iconName: 'utility:delete',
            label: '',
            variant: 'bare',
            name: 'Remove User',
            title: 'Remove User',
            disabled: false

        }
    }
];
export default class TerritoryPlanRepresentativeRemove extends LightningElement {
    @api planId;
    @track booLoading = false;
    @track isLoaded = false;
    @track column = columnRemove;
    @api planReps;
    @track errorMessage = '';
    @track hasError = false;
    // Removing duplicate records using user id
    connectedCallback() {
        const filteredArr = this.planReps.reduce((acc, current) => {
            const x = acc.find(item => item.strUserId === current.strUserId);
            if (!x) {
                return acc.concat([current]);
            }
            return acc; //DCP-56402 [CodeScan Issue Fix]
        }, []);
        this.planReps = filteredArr;
        if (!isEmpty(this.planReps))
            this.isLoaded = true;
        consoleLog('Final--> ' + JSON.stringify(this.planReps));
    }
    // Data Table funtionality
    handleRowAction(event) {
        this.booLoading = true;
        const rowDetail = event.detail.value;
        this.removePlanReps('[' + JSON.stringify(rowDetail) + ']');
    }
    // handler for multi row removal
    selectPlanRepresentative() {
        let selectedRecords = this.template.querySelector('c-data-table-lazy-load').fetchSelectedRecord();
        this.removePlanReps(JSON.stringify(selectedRecords));
    }
    // Calls apex method
    removePlanReps(strJSON) {
        this.booLoading = true;
        callServer(removeUsers, {
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
import { LightningElement, track, api, wire } from 'lwc';
import initRecords from '@salesforce/apex/ViewActivePlansTerritoryController.initRecords';
import { refreshApex } from '@salesforce/apex';
import { genericEvent, isBlank, consoleLog } from 'c/utils';
const column = [
    {
        label: 'Account Plan Name',
        fieldName: 'AccountPlanId',
        type: 'url',
        
        typeAttributes: {label: { fieldName: 'AccountPlanName' }, 
        tooltip : {fieldName: 'AccountPlanName'},
        target: '_blank'},
        sortable: false
    },
    {
        label: 'Owner Name',
        fieldName: 'OwnerId',
        type: 'url',
        
        typeAttributes: {label: { fieldName: 'OwnerName' }, 
        tooltip : {fieldName: 'OwnerName'},
        target: '_blank'},
        sortable: false
    },
    {
        label: "Plan Target",
        fieldName: "PlanTarget",
        sortable: false,
        type: "currency"
    }
];
export default class ActiveAccountPlanTerritory extends LightningElement {
    @api recordId;
    @track showtable = false;
    @track columns = column;
    @track lstOfRecord;
    @track booLoading = true;
    @track mapUILabels = [];

    wiredsObjectData;
    // Wire method to fetch Strategy data
    @wire(
        initRecords,
        {
            recordId : '$recordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Data ',result.data);
            let data = JSON.parse(result.data)
            this.lstOfRecord = data.wrapAccountList;
            this.mapUILabels = data.mapLabels;
            this.booLoading = false;
            if(this.lstOfRecord.length > 0)
                this.showtable = true;
        }
        else if (result.error) {
            consoleLog('Error ->',result.error);
            this.booLoading = false;
            this.hasError = true;
        }
    }
}
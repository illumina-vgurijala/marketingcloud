import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    consoleLog,
    isNotEmpty,
    consoleError
} from 'c/utils';
const column = [{
        label: 'Plan Name',
        fieldName: 'planId',
        type: 'url',

        typeAttributes: {
            label: {
                fieldName: 'planName'
            },
            tooltip: {
                fieldName: 'planName'
            },
            target: '_blank'
        },
        sortable: false
    },
    {
        label: 'Owner',
        fieldName: 'ownerName'
    },
    {
        label: "Channel Partner",
        fieldName: "channelPartner"
    },
    {
        label: "Record Type",
        fieldName: "recordType"
    }
];
import UI_Label_Related_Active_TP from '@salesforce/label/c.UI_Label_Related_Active_TP';
import UI_Message_No_Active_TP from '@salesforce/label/c.UI_Message_No_Active_TP';
import initRecords from '@salesforce/apex/ViewRelatedActiveTerritoryPlanCtrl.initRecords';
export default class ViewRelatedActiveTerritoryPlan extends LightningElement {
    @api recordId;
    @api label = {
        UI_Label_Related_Active_TP,
        UI_Message_No_Active_TP
    };
    @track lstActiveTerritoryPlans = [];
    @track column = column;
    @track booLoaded = false;
    @track hasError = false;
    @track errorMessage;
    @track maplabels;
    wiredsObjectData;
    // Wire method to fetch Strategy data
    @wire(
        initRecords, {
            recordId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Data ', result.data);
            let returnData = JSON.parse(result.data);
            this.lstActiveTerritoryPlans = returnData.wrapPlanList;
            this.maplabels = returnData.mapLabels;
        } else if (result.error) {
            consoleError('Error ', result.error);
            this.errorMessage = result.error;
            this.hasError = true;
        }
        this.booLoaded = true;
    }
    get showDataTable() {
        return isNotEmpty(this.lstActiveTerritoryPlans)
    }
}
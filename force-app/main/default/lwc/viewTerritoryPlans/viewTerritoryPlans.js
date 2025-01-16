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
//DCP-41644 codescan changes
import {
    columns
} from './columns.js';
import initRecords from '@salesforce/apex/ViewTerritoryPlansController.initRecords';
import UI_Label_Active_TP from '@salesforce/label/c.UI_Label_Active_TP';
import UI_Message_No_Active_Plans from '@salesforce/label/c.UI_Message_No_Active_Plans';
export default class ViewTerritoryPlans extends LightningElement {
    @api recordId;
    @api label = {
        UI_Message_No_Active_Plans,
        UI_Label_Active_TP
    };
    @track lstTerritoryPlans = [];
    @track column = columns;//DCP-41644 changes
    @track booLoaded = false;
    @track hasError = false;
    @track errorMessage;
    @track maplabels;
    wiredsObjectData;
    // Wire method to fetch Plan data
    @wire(
        initRecords, {
            recordId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Data ', result.data);
            this.lstTerritoryPlans = JSON.parse(result.data);
        } else if (result.error) {
            consoleError('Error ', result.error);
            this.errorMessage = result.error;
            this.hasError = true;
        }
        this.booLoaded = true;
    }
    get showDataTable() {
        return isNotEmpty(this.lstTerritoryPlans)
    }
}
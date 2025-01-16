import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    refreshApex
} from '@salesforce/apex';
import {
    consoleLog,
    showErrorToast,
    showSuccessToast,
    consoleError
} from 'c/utils';
import NAME_FIELD from '@salesforce/schema/Plan_Strategy__c.Name';
import DUE_DATE from '@salesforce/schema/Plan_Strategy__c.Due_Date__c';
import DESCRIPTION from '@salesforce/schema/Plan_Strategy__c.Description__c';
import initRecord from '@salesforce/apex/TerritoryPlanStrategyController.initRecord';
export default class TerritoryPlanStrategyMaster extends LightningElement {
    @api recordId;
    @track lstStrategyId;
    @track showSaveView = false;
    @track maplabels;
    @track strategyFields = [NAME_FIELD, DUE_DATE, DESCRIPTION];
    @track booLoading = true;
    @track toastMessage;
    @track modalHeader;
    @track activeSection = '';

    wiredsObjectData;
    // Wire method to fetch all Strategy record of Territory plan
    @wire(
        initRecord, {
            recordId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.booLoading = true;
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Data', result.data);
            let returndata = JSON.parse(result.data);
            this.lstStrategyId = returndata.lstStrategyWrap;
            this.maplabels = returndata.mapLabels;
            this.booLoading = false;
        } else if (result.error) {
            consoleError('Error', result.error);
        }
    }
    // Method to handle toggle
    handleSectionToggle(event) {
        this.activeSection = event.detail.openSections;
    }
    // Handle of onclick event
    createNewStrategy(event) {
        this.DisplayEditField = this.strategyFields;
        this.ObjectAPi = this.maplabels.UI_Label_Strategy_API;
        this.modalHeader = this.maplabels.UI_Modal_Header_New_Strategy;
        this.toastMessage = this.maplabels.UI_Message_Strategy_Create;
        this.showSaveView = true;
    }
    closeModal() {
        this.showSaveView = false;
    }
    handleError(event) {
        showErrorToast(event.detail.value);
        this.booLoading = false;
    }
    handleSubmit(event) {
        this.booLoading = true;
        const field = event.detail.fields;
        if (event.detail.objectAPI == this.maplabels.UI_Label_Strategy_API && event.detail.mode == 'Create')
            field.Plan__c = this.recordId;
        console.log('Submit event', event.detail.template.submit(field));
    }
    handleSuccess() {
        showSuccessToast(this.toastMessage);
        refreshApex(this.wiredResults);
        this.booLoading = false;
        this.closeModal();
    }
    updateList() {
        refreshApex(this.wiredResults);
    }
}
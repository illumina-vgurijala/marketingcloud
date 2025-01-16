import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    refreshApex
} from '@salesforce/apex';
import {
    updateRecord
} from 'lightning/uiRecordApi';
import {
    consoleLog,
    showSuccessToast,
    genericEvent,
    isNull,
    consoleError
} from 'c/utils';
import NAME_FIELD from '@salesforce/schema/Plan_Strategy__c.Name';
import DUE_DATE from '@salesforce/schema/Plan_Strategy__c.Due_Date__c';
import DESCRIPTION from '@salesforce/schema/Plan_Strategy__c.Description__c';
import OB_NAME_FIELD from '@salesforce/schema/Plan_Objective__c.Name';
import STATUS from '@salesforce/schema/Plan_Objective__c.Objective_Status__c';
import PRIORITY from '@salesforce/schema/Plan_Objective__c.Priority__c';
import OB_DUE_DATE from '@salesforce/schema/Plan_Objective__c.Due_Date__c';
import CLOSED_STATUS from '@salesforce/schema/Plan_Objective__c.Closed_Status__c';
import MARKET_SEGMENT from '@salesforce/schema/Plan_Objective__c.Market_Segment__c';
import PRODUCT_TYPE from '@salesforce/schema/Plan_Objective__c.Product_Type__c';
import fetchStrategy from '@salesforce/apex/TerritoryPlanStrategyController.fetchStrategy';
export default class TerritoryPlanStrategyChild extends LightningElement {
    @api strategyId;
    @api maplabels;
    @api planId;
    @track strategyData;
    @track lstObjectiveId;
    @track showEditView = false;
    @track showSaveView = false;
    @track showConfirmation = false;
    @track toastMessage = '';
    @track booLoading = true;
    @track strategyFields = [NAME_FIELD, DUE_DATE, DESCRIPTION];
    @track objectiveFields = [OB_NAME_FIELD, STATUS, PRIORITY, OB_DUE_DATE, MARKET_SEGMENT,CLOSED_STATUS, PRODUCT_TYPE];
    @track confirmationMessage;
    @track activeSection = '';
    @track wiredResults;
    isOverlayPlan = false;
    wiredsObjectData;
    // Wire method to fetch Strategy data
    @wire(
        fetchStrategy, {
            strRecordid: '$strategyId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        consoleLog('Resulr', result);
        if (result.data) {
            let returnData = JSON.parse(result.data);
            this.strategyData = returnData.objPlanWrapper;
            this.lstObjectiveId = returnData.objPlanObjectiveWrapper
            if(returnData.planRecordType === this.maplabels.PlanOverlay) {
                this.isOverlayPlan = true;
            }

        } else if (result.error) {
            consoleError('Error ->', result.error);
        }
        this.booLoading = false;
    }
    // method called while editing Strategy
    editStrategy(event) {
        this.recordIdUpdate = this.strategyId;
        this.showEditView = true;
        this.DisplayEditField = this.strategyFields;
        this.ObjectAPi = this.maplabels.UI_Label_Strategy_API;
        this.ModalHeaders = this.maplabels.UI_Modal_Header_Edit_Strategy;
        this.toastMessage = this.maplabels.UI_Message_Strategy_Edit;
    }
    // Modal close
    closeModal() {
        this.showConfirmation = false;
        this.showEditView = false;
        this.showSaveView = false        
    }
    handleError(event) {
        const evt = new ShowToastEvent({
            title: "Error!",
            message: event.detail.value,
            variant: "error",
        });
        this.dispatchEvent(evt);
    }
    handleSubmit(event) {
        const field = event.detail.fields;
        if (event.detail.objectAPI == this.maplabels.UI_Label_Objective_API && event.detail.mode == 'Create')
            field.Plan_Strategy__c = this.strategyId;
        event.detail.template.submit(field);
    }
    handleSuccess() {
        showSuccessToast(this.toastMessage)        
        this.refreshData();
        this.closeModal();
    }
    deleteStrategyConfBox(event) {
        this.recordIdDelete = this.strategyId;
        this.confirmationMessage = this.maplabels.UI_Message_Deactivate_Confirmation.replace('{0}', 'strategy');
        this.showConfirmation = true;
        this.toastMessage = this.maplabels.UI_Message_Strategy_Deactivated;
    }
    deactivateRecords() {
        let record = {
            fields: {
                Id: this.recordIdDelete,
                IsActive__c: false,
            },
        };
        updateRecord(record)
            .then(() => {
                showSuccessToast(this.toastMessage);
                this.closeModal();
                const objDetails = Object.create({});
                objDetails.value = this.strategyId;
                genericEvent('strategy_deactivated', objDetails, this);
            })
            .catch(error => {
                consoleLog('Error', error);
            });
        let listChildComponent = this.template.querySelectorAll('c-territory-plan-objective-child');
        listChildComponent.forEach((element) =>{
            element.deactivateRecords();
        })   
    }
    // Method to handle toggle
    handleSectionToggle(event) {
        this.activeSection = event.detail.openSections;
    }
    createNewObjective(event) {
        this.showSaveView = true;
        this.displayEditField = this.objectiveFields;
        this.objectAPi = this.maplabels.UI_Label_Objective_API;
        this.toastMessage = this.maplabels.UI_Message_Objective_Create;

    }
    updateList(event) {
        this.refreshData();
        if(event.detail.isCreateForOverlayPlan) { 
            let objectiveChildComponents = this.template.querySelectorAll('c-territory-plan-objective-child');            
            if(isNull(objectiveChildComponents)) { return; }
            objectiveChildComponents.forEach((element) => {
                if(element.objectiveId === event.detail.objectiveId) { 
                    element.refreshOpportunityDetails();
                }
            });    
        }
    }
    
    refreshData() { 
        refreshApex(this.wiredResults);
    }
}
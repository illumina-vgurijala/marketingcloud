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
    updateRecord
} from 'lightning/uiRecordApi';
import OB_NAME_FIELD from '@salesforce/schema/Plan_Objective__c.Name';
import STATUS from '@salesforce/schema/Plan_Objective__c.Objective_Status__c';
import PRIORITY from '@salesforce/schema/Plan_Objective__c.Priority__c';
import OB_DUE_DATE from '@salesforce/schema/Plan_Objective__c.Due_Date__c';
import CLOSED_STATUS from '@salesforce/schema/Plan_Objective__c.Closed_Status__c';
import MARKET_SEGMENT from '@salesforce/schema/Plan_Objective__c.Market_Segment__c';
import PRODUCT_TYPE from '@salesforce/schema/Plan_Objective__c.Product_Type__c';
import fetchObjective from '@salesforce/apex/TerritoryPlanStrategyController.fetchObjective';
import COMMENTS from '@salesforce/schema/Objective__c.Comments__c';//DCP-52623
import {
    genericEvent,
    consoleLog,
    showErrorToast,
    showSuccessToast,
    consoleError
} from 'c/utils';
export default class TerritoryPlanObjectiveChild extends LightningElement {
    @api objectiveId;
    @api maplabels;
    @api planId;
    @track objectiveData;
    @track showEditView = false;
    @track showSaveView = false;
    @track showConfirmation = false;
    @track toastMessage = '';
    @track objectiveFields = [OB_NAME_FIELD, STATUS,  PRIORITY, COMMENTS, OB_DUE_DATE, MARKET_SEGMENT,CLOSED_STATUS, PRODUCT_TYPE];//DCP-52623
    @track confirmationMessage;
    @track objectType = 'Plan_Objective__c';
    wiredsObjectData;
    // Wire method to fetch Strategy data
    @wire(
        fetchObjective, {
            strRecordid: '$objectiveId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        consoleLog('Result', result);
        if (result.data) {
            this.objectiveData = JSON.parse(result.data);
        } else if (result.error) {
            consoleError('Error ->', result.error);
        }
    }
    // method called while editing objective
    editObjective(event) {
        this.recordIdUpdate = this.objectiveId;
        this.showEditView = true;
        this.DisplayEditField = this.objectiveFields;
        this.ObjectAPi = this.maplabels.UI_Label_Objective_API;
        this.ModalHeaders = this.maplabels.UI_Modal_Header_Edit_Objective;
        this.toastMessage = this.maplabels.UI_Message_Objective_Edit;
    }
    // Modal close
    closeModal() {
        this.showConfirmation = false;
        this.showEditView = false;
        this.showSaveView = false;
    }
    handleError(event) {
        showErrorToast(event.detail.value);
    }
    handleSubmit(event) {}
    handleSuccess() {
        showSuccessToast(this.toastMessage);
        refreshApex(this.wiredResults);
        this.closeModal();
    }
    // Confirmation box handler
    deleteObjectiveConfBox(event) {
        this.confirmationMessage = this.maplabels.UI_Message_Deactivate_Confirmation.replace('{0}', 'objective');
        this.recordIdDelete = this.objectiveId;
        this.showConfirmation = true;
    }
    // Method to deactivate records
    @api
    deactivateRecords() {
        let record = {
            fields: {
                Id: this.objectiveId,
                IsActive__c: false,
            },
        };
        updateRecord(record)
            .then(() => {
                showSuccessToast(this.maplabels.UI_Message_Objective_Deactivated);
                this.closeModal();
                const objDetails = Object.create({});
                objDetails.value = this.objectiveId;
                genericEvent('objectivedeactivated', objDetails, this);
            })
            .catch(error => {
                consoleLog('Error', error);
            });
    }
    handleSectionToggle() {

    }
    // Event handle to refresh data
    refreshDetails() {
        refreshApex(this.wiredResults);
    }

    @api
    refreshOpportunityDetails() {
        let opportunityAssociationComponent = this.template.querySelector('c-generic-plan-associated-opportunities');
        if(opportunityAssociationComponent !== undefined && opportunityAssociationComponent !== null) {
            opportunityAssociationComponent.refreshData();
        }

    }
}
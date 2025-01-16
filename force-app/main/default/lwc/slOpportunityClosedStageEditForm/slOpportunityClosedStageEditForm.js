import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OPP_STAGENAME from '@salesforce/schema/Opportunity.StageName';
import OPP_CLOSEREASONOTHER from '@salesforce/schema/Opportunity.Close_Reason_Other__c';
import OPP_CORELAB from '@salesforce/schema/Opportunity.Core_Lab__c';
import OPP_CORELABOTHER from '@salesforce/schema/Opportunity.Core_Lab_Other__c';

export default class SlOpportunityClosedStageEditForm extends LightningElement {
    @track recordId;
    @track fieldName;
    @track stageName;
    @track boolOpenPopup = false;
    @track abandonValue;
    oppName;
    isReadOnly = false;
    showCoreLab = false;
    oppStageName = OPP_STAGENAME
    oppCloseReasonOther = OPP_CLOSEREASONOTHER
    oppCoreLab = OPP_CORELAB
    oppCoreLabOther = OPP_CORELABOTHER
    handleSuccess(event) {
        this.boolOpenPopup = false;

        const SUCCESS_EVENT = new ShowToastEvent ({
            title: 'Opportunity Updated',
            message: 'Record ID: ' + event.detail.id,
            variant: 'success' 
        });
        this.dispatchEvent(SUCCESS_EVENT);
        window.location.reload();
    }

    handleError(event){
        const ERROR_EVENT = new ShowToastEvent ({
            title: 'Opportunity Update Error',
            message: 'There was an error updating the Opportunity. Record: ' + event.detail.detail,
            variant: 'error' 
        });
        this.dispatchEvent(ERROR_EVENT);
    }

    handleOnLoad(event) {
        let record = event.detail.records;
        let fields = record[this.recordId].fields;
        const abnrsnName = fields.Abandon_Reason__c.value;
        this.stageName = fields.StageName.value;
        this.oppName = fields.Name.value;     
        if(abnrsnName !== 'Other'){
            this.isReadOnly = true;
        } else {
            this.isReadOnly = false;
        }
    }

    resetFormAction() {
        const lwcInputFields = this.template.querySelectorAll(
            '.crother'
        );
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                field.reset();
            });
        }
     }

    handleStatusChange(event){
        if(event.detail.value !== 'Other'){
            this.resetFormAction();
            this.isReadOnly = true;
        } else {
            this.isReadOnly = false;
        }
    }

    hideModalBox() {
        this.boolOpenPopup = false;
    }
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(inputField => {
            if (!inputField.reportValidity()) {
                isValid = false;
            }
        });
        return isValid;
    }
    handleSubmit() {
        let isValid = this.isInputValid();
        if (isValid) {
            this.template.querySelector('lightning-record-edit-form').submit();
        }
    }

    @api openPopup(objCloseData){
        const constThis = this;
        if(objCloseData.stagevalue !== null && objCloseData.recordId !== null){
            constThis.recordId = objCloseData.recordId;
            if(objCloseData.stagevalue === 'Closed Lost'){
                constThis.fieldName = 'Loss_Reason__c';
                this.showCoreLab = false;
            }
            if(objCloseData.stagevalue === 'Closed Abandoned'){
                constThis.fieldName = 'Abandon_Reason__c';
                this.showCoreLab = true;
            }
            constThis.boolOpenPopup = true;
        }
    }
}
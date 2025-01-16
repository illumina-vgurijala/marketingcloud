import { LightningElement, track, api} from 'lwc';
import { genericEvent, consoleLog } from 'c/utils';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class GenericEditCreateRecords extends LightningElement {
    @api objectApiName;
    @api displayFields;
    @api mode;
    @api recordId;
    @api modalHeaders;
    @track isCreate = true;
    @track columnNumber;
    @track isMobile = false;
    @track booLoading = false;

    connectedCallback(){
        if(this.mode != 'Create'){
            console.log('--->'+this.isCreate);
            this.isCreate = false;
        }
        if(FORM_FACTOR == 'Large'){
            this.columnNumber = 2;
        }
        else{
            this.columnNumber = 1;
            this.isMobile = true;
        }

    }
    closeModal(event){
        const objDetails = Object.create({});
        objDetails.value =this.recordId;
        genericEvent('closemodal',objDetails,this);
    }
    handleSuccess(event){
        const objDetails = Object.create({});
        consoleLog('Upsert success',event.detail);
        consoleLog('Upsert success 1',event);
        consoleLog('Upsert success 2',event.getParams);
        objDetails.value =this.recordId;
        genericEvent('upsertsuccess',objDetails,this);
        this.booLoading = false;
    }
    handleError(event) {
        let message = '';
        if (Object.entries(event.detail.output.fieldErrors).length !== 0) {
            const getField = Object.keys(event.detail.output.fieldErrors)[0];
            message = event.detail.output.fieldErrors[getField][0].message;
        }
        else {
            message = event.detail.message + "\n" + event.detail.detail;
        }
        const objDetails = Object.create({});
        objDetails.value = message;
        genericEvent('upserterror',objDetails,this);
        this.booLoading = false;
    }
    handleSubmit(event) {
        this.booLoading = true;
        event.preventDefault();
        const objDetails = Object.create({});
        objDetails.fields =event.detail.fields;
        objDetails.objectAPI = this.objectApiName;
        objDetails.mode = this.mode;
        objDetails.template =this.template.querySelector('lightning-record-form');
        genericEvent('upsertsubmit',objDetails,this);
    }
}
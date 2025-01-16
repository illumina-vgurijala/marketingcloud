import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord ,getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ID_FIELD from '@salesforce/schema/Account.Id';
import STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import STATE_CODE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import POSTAL_CODE_FIELD from '@salesforce/schema/Account.BillingPostalCode';
import COUNTRY_CODE_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import STATE_FIELD from '@salesforce/schema/Account.BillingState';
import RE_SUBMISSION_REASON_FIELD from '@salesforce/schema/Account.Re_Submission_Reason__c';
import ADDRESS_STATUS_FIELD from '@salesforce/schema/Account.Address_Status__c';
import ACCOUNT_STATUS_FIELD from '@salesforce/schema/Account.Account_Status__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Account.RecordTypeId';
import accountRTChannelPartnerProspect from '@salesforce/label/c.AccountRTChannelPartnerProspect';
import {isNull, isNotEmpty, isBlank, callServer, isNotBlank, showErrorToast,consoleError,consoleLog } from 'c/utils';
import loadPage from '@salesforce/apex/ProspectAccountAddressValidationControl.loadPage';
import submitOutboundRequest from '@salesforce/apex/ProspectAccountAddressValidationControl.submitOutboundRequest';

const FIELDS = [ID_FIELD,STREET_FIELD,CITY_FIELD,STATE_CODE_FIELD,POSTAL_CODE_FIELD,COUNTRY_CODE_FIELD,COUNTRY_FIELD,STATE_FIELD,RE_SUBMISSION_REASON_FIELD,ADDRESS_STATUS_FIELD,ACCOUNT_STATUS_FIELD,RECORD_TYPE_ID_FIELD];
const RADIO_BUTTON_SELECTED_VALUE = 'option1';
export default class ProspectAccountAddressValidationComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @track accountRecord;         
    @track lstAddresses;
    @track objAddress;
    @track currentAddress;
    labelToValue;    
    booIsResubmitUser = false;
    booIsSubmitted = false;
    booIsVerified = false;
    booIsLoaded = false;
    isSpinnerActive = true;
    
    @wire (getObjectInfo, {objectApiName: ACCOUNT_OBJECT})
    accountObjectInfo;    

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS }) 
    wiredAccount({data,error}) {
        if(data) {           
            this.accountRecord = this.generateAccountDetails(data);            
            this.objAddress = this.generateCurrentAddress();
            this.currentAddress = {...this.objAddress};
            this.initializePageData();           
        }
        if(error) {
            consoleError('error in wire service in prospectaccountaddressvalidation ::: ',JSON.stringify(error));
            this.isSpinnerActive = false;            
        }
    }

    generateAccountDetails(data) {        
        const fieldValuesMap = data.fields;
        return Object.keys(fieldValuesMap).reduce((next, key) => {
            return { ...next, [key]: fieldValuesMap[key].value };
        },{});                
    }

    generateCurrentAddress() {
        let tempAddress = Object.create({});
        tempAddress.strStreet = this.accountRecord.BillingStreet;
        tempAddress.strCity = this.accountRecord.BillingCity;
        tempAddress.strCountry = this.accountRecord.BillingCountryCode;
        tempAddress.strState = this.accountRecord.BillingStateCode;
        tempAddress.strZip = this.accountRecord.BillingPostalCode;
        tempAddress.strAccountId = this.accountRecord.Id;
        tempAddress.index = 0;
        tempAddress.selectedRadioValue = RADIO_BUTTON_SELECTED_VALUE; 
        return tempAddress;
    }

    generateSuggestedAddressesList(data) {
        return data.map((item, index) => {
            const container = JSON.parse(JSON.stringify(item));
            container.index = index+1;
            container.cardTitle = this.labelToValue.UI_Label_Address_Validation_Suggested_Address_Title + ': ' + (index + 1);
            container.selectedRadioValue = '';
            return container;
        });
    }

    initializePageData() {
        callServer(loadPage, {            
            strAddressJSON : JSON.stringify(this.objAddress)
        }, result => {              
            let wrapResponse = JSON.parse(result);
            consoleLog('wrapResponse in prospectAccountAddressValidation initializePageData ::: ',wrapResponse);
            this.labelToValue = wrapResponse.labelToValue;            
            this.booIsResubmitUser = wrapResponse.booCanReSubmit;
            this.lstAddresses = this.generateSuggestedAddressesList(wrapResponse.lstAddress);                                 
            if(this.accountRecord.Address_Status__c === wrapResponse.labelToValue.Account_Address_Status_Submitted)
                this.booIsSubmitted = true;
            if(this.accountRecord.Address_Status__c === wrapResponse.labelToValue.Account_Address_Status_Verified)
                this.booIsVerified = true;
            this.booIsLoaded = true;
            this.isSpinnerActive = false; 
        }, error => {            
            this.isSpinnerActive = false; 
            consoleError('error occurred in initializePageData::: ', error);
        });
    }

    fetchRecordTypeName(currentRecordTypeId) {                
        return this.accountObjectInfo?.data?.recordTypeInfos[currentRecordTypeId]?.name;
    }

    handleChange(event) {
        const targetName = event.target.name;
        const targetValue = event.target.value;
        if(targetName === this.labelToValue.UI_Label_Address_Validation_Reason_For_Resubmission) {
            this.accountRecord.Re_Submission_Reason__c = targetValue;
        }
    }

    handleSelectAddress(event) {                                  
        const {addressDetails, index} = event.detail;            
        if(index === 0) {
            this.objAddress = {...this.objAddress, ...addressDetails, selectedRadioValue : RADIO_BUTTON_SELECTED_VALUE};  // keep the current address radio button as selected
            this.currentAddress = {...this.currentAddress, selectedRadioValue : RADIO_BUTTON_SELECTED_VALUE};
            this.lstAddresses = this.lstAddresses.map(item => {
                return {...item, selectedRadioValue : ''}  // deselect the other radio buttons in suggested address                 
            });                               
        } else {            
            this.objAddress = {...this.objAddress, ...addressDetails , index : index};
            this.currentAddress = {...this.currentAddress, selectedRadioValue : ''};                                
            this.lstAddresses = this.lstAddresses.map(item => {
                const container = {...item};
                if(item.index === index) {
                    container.selectedRadioValue = RADIO_BUTTON_SELECTED_VALUE;
                } else {
                    container.selectedRadioValue = ''; // deselect the other radio buttons in suggested address
                }
                return container;
            });
        }                                
    }

    handleValidateAndSave(event) {        
        if(!this.validateData()) { return; }
        
        this.accountRecord.BillingStreet = this.objAddress.strStreet;
        this.accountRecord.BillingCity = this.objAddress.strCity;
        //this.accountRecord.BillingState = this.objAddress.strState;
        this.accountRecord.BillingPostalCode = this.objAddress.strZip;
        this.accountRecord.Is_Updated_By_System__c = true;

        const recordToUpdate = Object.create({});
        recordToUpdate.Id = this.recordId;
        recordToUpdate.BillingStreet = this.accountRecord.BillingStreet;
        recordToUpdate.BillingCity = this.accountRecord.BillingCity;
        recordToUpdate.BillingPostalCode = this.accountRecord.BillingPostalCode;
        recordToUpdate.Is_Updated_By_System__c = this.accountRecord.Is_Updated_By_System__c;
        if(this.booIsResubmitUser) {
            recordToUpdate.Re_Submission_Reason__c = this.accountRecord.Re_Submission_Reason__c; 
        }
        
        
        const recordInput = { fields : {...recordToUpdate}}
        this.isSpinnerActive = true; 
        
        updateRecord(recordInput)
            .then(() => {                
                consoleLog('Account Record Updated. Now doing outbound call');                
                this.submitToERP();
            })
            .catch(error => {                
                consoleError('error occurred in saving Account::: ',JSON.stringify(error));
                this.isSpinnerActive = false; 
                this.showError(error.body.message);
            });
    }

    validateData() {        
        if(this.showSegmentationSelectionComponent) {            
            if(!this.template.querySelector('c-segmentation-selection-l-w-c')?.validateBeforeSave(true)) {
                return false;
            }
        }
        if(this.booIsSubmitted && isBlank(this.accountRecord.Re_Submission_Reason__c)) {
            this.showError(this.labelToValue.UI_Error_Address_Validation_Resumbission_Reason);
            return false;
        }
        return true;
    }    

    submitToERP() {        
        callServer(submitOutboundRequest, {            
            strAccountId : this.recordId
        }, result => {       
            setTimeout(() => {
                this.navigateToRecordPage();
            },1500);
            this.isSpinnerActive = false; 
            getRecordNotifyChange([{recordId: this.recordId}]);                   
        }, error => {
            consoleError('error in submitToERP, details ::: ', JSON.stringify(error));
            this.isSpinnerActive = false; 
        });
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.recordId,
                "objectApiName": "Account",
                "actionName": "view"
            },
        });
    }

    showError(strErrorMessage) {
        showErrorToast(strErrorMessage,'pester');
    }

    get providedAddressCardTitle() {
        if(isNull(this.labelToValue)) return '';
        
        if(this.booIsVerified || (this.booIsSubmitted && !this.booIsResubmitUser)) {
            return this.labelToValue.UI_Label_Address_Validation_Verified_Message;
        }
        return this.labelToValue.UI_Label_Address_Validation_Provided_Address;        
    }

    get showSuggestedAddressCard() {
        return !(this.booIsVerified || (this.booIsSubmitted && !this.booIsResubmitUser ));
    }

    get showSuggestedAddressesList() {
        return isNotEmpty(this.lstAddresses);
    }

    get showSubmissionButton() {        
        return !(this.booIsSubmitted || this.booIsVerified);
    }

    get showResubmissionButton() {        
        return (this.booIsSubmitted && this.booIsResubmitUser);
    }

    get showResubmissionReason() {
        return (this.booIsVerified && isNotBlank(this.accountRecord.Re_Submission_Reason__c) && this.booIsLoaded) || (this.booIsResubmitUser && this.booIsSubmitted && this.booIsLoaded);
    }

    get showSegmentationSelectionComponent() {        
        return !(this.fetchRecordTypeName(this.accountRecord.RecordTypeId) === accountRTChannelPartnerProspect);
    }
}
/* eslint-disable no-console */
/* eslint-disable no-alert */
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fecthAgreementWrapper from '@salesforce/apex/AgreementOutputParametersForm.getAgreementWrapper';
import readCSV from '@salesforce/apex/AgreementOutputParametersForm.readCSVFile';
import sendGenerateRequest from '@salesforce/apex/AgreementOutputParametersForm.sendGenerateRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sampleFile from '@salesforce/resourceUrl/SampleGenerateUpload';
import AGREEMENT_OBJECT from '@salesforce/schema/Apttus__APTS_Agreement__c';
import { getRecord } from 'lightning/uiRecordApi';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import SALES_ORG from '@salesforce/schema/Apttus__APTS_Agreement__c.Sales_Org__c'; //adding reference
import LANGUAGE from '@salesforce/schema/Apttus__APTS_Agreement__c.Preferred_Language__c';
import CURR from '@salesforce/schema/Apttus__APTS_Agreement__c.CurrencyIsoCode';

const columns = [
    { label: 'Material Group 1 Code', fieldName: 'materialGroup' },
    { label: 'Material Group 1 Description', fieldName: 'Description' },
];

export default class AgreementOutputParametersForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @track agreementWrapper;
    @track lstMaterialGroupCode = [];
    @track lstAgreementUpdated = [];
    @track errormsg;
    @api objectApiName;
    @track columns = columns;
    @track fileUploaded = false;
    @track sampleFile = window.location.origin + sampleFile;
    @track Customer;
    @track CustomerName;
    @track CustomerNameOutput;
    @track SalesOrganization;
    @track DistributionChannel;
    @track PricingDate = new Date();
    @track ExpirationDate;
    @track HideItemizedPriceList;
    @track DisplayCustomerDiscountedItemsOnly;
    @track DisplayDiscountException = true;
    @track IncludeAllMaterialsfromAgreement=true;
    @track includeAdditionalMaterials;
    @track excludeAdditionalMaterials;
    @track selectedMaterials = [];
    @track includeMaterialFile;
    @track excludeMaterialFile;
    @track mapoflabels;
    @track booLoading = false;
    @track HideListPrice;
	@track DisAgrNum;
    @track AccountOption = [];
    @track language;
    @track curr;
    @track languagepicklist = []

    // user current record ID - TTN
    // code from https://salesforce.stackexchange.com/questions/329238/get-picklist-values-after-dynamically-fetching-the-record-type-id-in-lwc
    @wire(getRecord, { recordId: "$recordId", fields: "RecordTypeId" })
    record;
    @wire(getPicklistValues, { recordTypeId: "$record.data.recordTypeId", fieldApiName: SALES_ORG })
    picklistValues;

    @wire(getObjectInfo, { objectApiName: AGREEMENT_OBJECT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CURR})
    picklistValuesCurr;

    // accepted parameters
    get acceptedFormats() {
        return ['.csv'];
    }
    @wire(fecthAgreementWrapper, { AgreementId: '$recordId' }) getagreementWrapper({ error, data }) {
        if (data) {
            this.lstMaterialGroupCode = data.lstMaterialGroupCode;
            this.agreementWrapper = data.objAgreement;
            
            let i;
            let my_ids = [];
            for (i = 0; i < this.lstMaterialGroupCode.length; i++) {
                if (this.lstMaterialGroupCode[i].isSelected === true) {
                    my_ids.push(this.lstMaterialGroupCode[i].materialGroup);
                }
            }
            if(data.lstLanguageSet.length > 0){
                data.lstLanguageSet.forEach((element, index, array) => {
                    this.languagepicklist.push({label : element , value : element});
                })
            }
            this.selectedMaterials = my_ids;
            this.SalesOrganization = data.objAgreement.Sales_Org__c; //adding reference sales org
            this.DistributionChannel = data.objAgreement.Distribution_Channel__c;
            this.PricingDate = data.objAgreement.Apttus__Contract_Start_Date__c;
            this.ExpirationDate = data.objAgreement.Apttus__Contract_End_Date__c;
            this.mapoflabels = data.mapoflabels;
            if(data.strAgreementRelationship.length > 0){
            data.strAgreementRelationship.forEach((element, index, array) => {
                if(index == 0){
                    this.Customer = element.Account__r.ERP_Customer_Id__c;
                    this.CustomerName = element.Account__r.Name+";"+element.Account__r.ERP_Customer_Id__c;
                    this.CustomerNameOutput = element.Account__r.Name;
                }
                this.AccountOption.push({label: element.Account__r.Name, value: element.Account__r.Name+";"+element.Account__r.ERP_Customer_Id__c});
            })
            }
            else{
                this.AccountOption.push({label: data.strCompanyName, value: data.strCompanyName+";"+data.objAgreement.Account_ERP_Number__c});
                this.Customer = data.objAgreement.Account_ERP_Number__c;
                this.CustomerName = data.strCompanyName+";"+data.objAgreement.Account_ERP_Number__c;
            }
            

        } else {
            this.errormsg = error;
        }
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFile = event.detail.files;

        // calling apex class
        readCSV({ idContentDocument: uploadedFile[0].documentId })
            .then(result => {
                let returndata = JSON.parse(result);
                this.includeMaterialFile = returndata.includeValue;
                this.excludeMaterialFile = returndata.excludeValue;
                this.fileUploaded = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!!',
                        message: this.mapoflabels.The_CSV_file_has_been_read,
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.error = error;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: this.mapoflabels.Please_upload_correct_file ,
                        variant: 'errormsg',
                    }),
                );
            })
    }
    FieldChange(event) {
        if (event.target.label == 'HideItemizedPriceList') {
            this.HideItemizedPriceList = event.target.checked;
        }
        if (event.target.label == 'DisplayCustomerDiscountedItemsOnly') {
            this.DisplayCustomerDiscountedItemsOnly = event.target.checked;
        }
        if (event.target.label == 'HideListPrice') {
            this.HideListPrice = event.target.checked;
        }
		if (event.target.label == 'DisAgrNum') {
            this.DisAgrNum = event.target.checked;
        }
        if (event.target.label == 'IncludeAllMaterialsfromAgreement') {
            this.IncludeAllMaterialsfromAgreement = event.target.checked;
        }
        if(event.target.label == 'ExcludeAdditionalMaterials'){
            this.excludeAdditionalMaterials = event.target.value;
        }
        if(event.target.label == 'IncludeAdditionalMaterials'){
            this.includeAdditionalMaterials = event.target.value;
        }
        if(event.target.label == 'PricingDate'){
            this.PricingDate = event.target.value;
        }
        if(event.target.label == 'SalesOrg'){
            this.SalesOrganization = event.target.value;
        }
        if(event.target.label == 'CustomerName'){
            this.Customer = event.target.value.split(';')[1];
            this.CustomerNameOutput = event.target.value.split(';')[0];
        }
        if(event.target.label == 'Currency'){
            this.curr = event.target.value;
        }
        if(event.target.label == 'Language'){
            this.language = event.target.value;
        }
    }
    submitGenerateRequest(event){
        this.booLoading = true;
        let formData = {
            'IncludeAllMaterial': this.IncludeAllMaterialsfromAgreement,
            'includeAdditionalMaterials' : this.includeAdditionalMaterials,
            'excludeAdditionalMaterials' : this.excludeAdditionalMaterials,
            'includeMaterialFile' : JSON.stringify(this.includeMaterialFile),
            'excludeMaterialFile' : JSON.stringify(this.excludeMaterialFile),
            'selectedMaterialGroup' : JSON.stringify(this.template.querySelector('lightning-datatable').getSelectedRows()),
            'pricingDate' : this.PricingDate,
            'language' : this.language,
            'hideListPrice' : this.HideListPrice,
			'disAgrNum' : this.DisAgrNum,
            'customerName' : this.CustomerNameOutput,
            'customerERPNumber' : this.Customer,
            'salesOrg' : this.SalesOrganization,
            'curr' : this.curr 
         };
        let stringData = JSON.stringify(formData);
        sendGenerateRequest({
            strFormData : stringData,
            strAgreementId: this.recordId
        })
            .then(result => {
                this.booLoading = false;
                if(result.includes('error')){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result,
                            variant: 'error'
                        })
                    );
                    this.cancelRequest();
                }
                else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result,
                            variant: 'Success'
                        })
                    );
                }
                this.cancelRequest();
            })
            .catch(error => {
                this.booLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error'
                    })
                );

            })
    }
    cancelRequest(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.recordId,
                "objectApiName": "Apttus__APTS_Agreement__c",
                "actionName": "view"
            },
        });
    }

}
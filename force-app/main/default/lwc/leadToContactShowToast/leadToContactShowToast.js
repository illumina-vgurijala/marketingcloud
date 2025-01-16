import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { consoleLog } from 'c/utils';
import lblAutoConversion from '@salesforce/label/c.LeadConvertionInProgress';
import lblAutoMerge from '@salesforce/label/c.LeadMergeInProgress';
import lblAutoConversionSub from '@salesforce/label/c.LeadConvertSuccessMsg';
import lblAutoMergeSub from '@salesforce/label/c.LeadMergeSuccessMsg';
import getMessageDetails from '@salesforce/apex/FindDuplicateRecordsController.getAutoActionMessageDetails';

/*const FIELDS = [
    'Lead.Is_AutoConversion_In_Progress__c',
    'Lead.Is_AutoMerge_In_Progress__c'    
];*/
export default class LeadToContactShowToast extends LightningElement {
    @api recordId;

    //below code will be used as a function
    connectedCallback(){
        getMessageDetails({leadId: this.recordId}).then(data => {
            console.log('=====data');
            console.log(data);
            if(data == lblAutoConversion){
                const evt = new ShowToastEvent({
                    title: lblAutoConversion,
                    message: lblAutoConversionSub,
                    variant: 'info',
                    mode:'sticky'
                });
                this.dispatchEvent(evt);
            } else if(data == lblAutoMerge ){
                const evt = new ShowToastEvent({
                    title: lblAutoMerge,
                    message: lblAutoMergeSub,
                    variant: 'info',
                    mode:'sticky'
                });
                this.dispatchEvent(evt);
            }

        })
        //catch the error if any and show it as a toast message.
        .catch((error) => {
            console.log('error-->',error);
            if(error && error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }	
        });
    }

    /*@wire(getMessageDetails, {leadId: '$recordId'}) getMessageDetails ({ error, data }) {
        if (data) {
            if(data == lblAutoConversion){
                const evt = new ShowToastEvent({
                    title: lblAutoConversion,
                    message: lblAutoConversionSub,
                    variant: 'info',
                    mode:'dismissable'
                });
                this.dispatchEvent(evt);
            } else if(data == lblAutoMerge ){
                const evt = new ShowToastEvent({
                    title: lblAutoMerge,
                    message: lblAutoMergeSub,
                    variant: 'info',
                    mode:'dismissable'
                });
                this.dispatchEvent(evt);
            }
        } 
    } */
    
    /*@wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    objContact({ data, error }) {
        /*if(data != undefined && data.fields.Is_AutoConversion_In_Progress__c.value == true ){
            console.log('data->>');
            const evt = new ShowToastEvent({
                title: 'Lead convertion is in progress..!!',
                message: 'An existing Contact has been found. DO NOT MODIFY THIS RECORD. System is attempting to convert Lead to existing Contact. Please refresh the page in 30 seconds.',
                variant: 'info',
                mode:'sticky'
            });
            this.dispatchEvent(evt);
        }
        if(data != undefined && data.fields.Is_AutoMerge_In_Progress__c.value == true){
            console.log('data->>');
            const evt = new ShowToastEvent({
                title: 'Lead merge is in progress..!!',
                message: 'An existing Lead has been found. DO NOT MODIFY THIS RECORD. System is attempting to merge Leads. Please refresh the page in 30 seconds. If merge succeeds, either reference system generated email or use global search function to search for the Lead.',
                variant: 'info',
                mode:'sticky'
            });
            this.dispatchEvent(evt);
        }
    };*/

}
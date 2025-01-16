import { LightningElement , track , api , wire } from 'lwc';
import fetchFileWithCase from '@salesforce/apex/RecallVerificationController.fetchFileWithCase';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe , MessageContext , APPLICATION_SCOPE } from 'lightning/messageService';
import RECALL_CHANNEL from "@salesforce/messageChannel/recall_verification_channel__c";
import { reduceErrors } from 'c/ldsUtils';
export default class ViewRecallVerification extends NavigationMixin(LightningElement)  {
    @api recordId;
    @track linkedCases = [];
    @track isSpinner = false;
    @track isRecall = false; //Added by Vishal for CMCM-10403
    get showCases() {
        return this.linkedCases.length > 0;
    }
    subscription = null;
    @wire(MessageContext)
    messageContext;
    connectedCallback() {
        this.isSpinner = true;
        fetchFileWithCase({caseId: this.recordId})
            .then(result => {
                if(result.length > 0){ //Added by Vishal for CMCM-10403
                    this.isRecall = true;
                }
                this.linkedCases = result;
                this.isSpinner = false;
            })
            .catch(error => {
                this.isSpinner = false;
                this.showToast('error' , reduceErrors(error).join(', ') , 'error');
            });
        this.handleSubscribe();

    }
    handleSubscribe() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            RECALL_CHANNEL,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }
    // Handler for message received by component
    handleMessage(message) {
        if(message.isRecallSubmited) {
            this.connectedCallback();
        }
    }
    showToast(title , message , variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        )
    }
    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
}
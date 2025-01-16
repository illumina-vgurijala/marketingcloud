import { LightningElement, api } from 'lwc';

export default class AddAssociatedCodesLwc extends LightningElement {

    @api recordId;
    @api objectApiName;
    
    connectedCallback() {
        if(!this.recordId) {
            this.recordId = window.location.pathname.split('/')[4];
            this.objectApiName = (this.recordId.includes('500') ? 'Case' : 'SVMXC__Service_Order__c');
        }
    }

}
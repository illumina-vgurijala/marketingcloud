import { LightningElement,api,track } from 'lwc';
import {
    genericEvent
} from 'c/utils';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class PlanCreationMaster extends LightningElement {
    @api currentUserId;
    @api territoryRecordTypeId;
    @track isMobile = false;
    @track isPortal = false;
    connectedCallback(){
        if(FORM_FACTOR == 'Small')
            this.isMobile = true;
        if(this.territoryRecordTypeId == 'Community')
            this.isPortal = true;
    }
    get isMobileOrPortal(){
        return this.isMobile || this.isPortal
    }
    closemodal(){
        const objDetails = Object.create({});
        objDetails.endIndex = this.endIndex;
        genericEvent('closemodal', objDetails, this);
    }
}
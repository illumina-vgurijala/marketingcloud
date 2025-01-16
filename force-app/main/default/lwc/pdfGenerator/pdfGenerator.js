import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import PORTAL_URL from '@salesforce/label/c.Portal_URL';

export default class PdfGenerator extends NavigationMixin(LightningElement) {
    siteURL;
    currentPageReference = null;
    caseId = null;
    //@api recId;
    @api recordId;

    //get the caseId from page url for either Service Console or CP portal
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            
            if (currentPageReference.state.c__caseId) {
                this.caseId = currentPageReference.state.c__caseId;
            } else {
                this.caseId = currentPageReference.state.caseId;
            }
        }
        this.siteURL = PORTAL_URL+'/apex/casePDF?recId=' + this.caseId;
    }

}
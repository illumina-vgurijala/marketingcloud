/* eslint-disable @lwc/lwc/no-inner-html */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable no-alert */
/* eslint-disable @lwc/lwc/no-document-query */
/* eslint-disable vars-on-top */
//import { LightningElement } from 'lwc';
import { LightningElement, wire , track , api  } from 'lwc';
import getDynamicQuickLinksList  from '@salesforce/apex/DynamicQuickLinksController.getDynamicQuickLinks';
import getDynamicVideoLinksList  from '@salesforce/apex/DynamicQuickLinksController.getActiveVideoLink';
export default class partnerPortalQuickLinks extends LightningElement {
    @track FIELDS;
    @track VideoArray;
    @track error;
    @track error1;
    @track privateTitle;
    @api
    get href() {
        return this.privateTitle;
    }

    // eslint-disable-next-line @lwc/lwc/valid-wire
    @wire(getDynamicQuickLinksList)
    wiredLinks({ error, data }) {
        if (data) {
            this.FIELDS = data;
            // eslint-disable-next-line no-alert
                let elem = this.template.querySelector('[data-id="link0"]').setAttribute('href', this.FIELDS[0].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link1"]').setAttribute('href', this.FIELDS[1].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link2"]').setAttribute('href', this.FIELDS[2].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link3"]').setAttribute('href', this.FIELDS[3].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link4"]').setAttribute('href', this.FIELDS[4].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link5"]').setAttribute('href', this.FIELDS[5].QuickLinkURL);
                    elem = this.template.querySelector('[data-id="link6"]').setAttribute('href', this.FIELDS[6].QuickLinkURL);
                //used it as a string, just for test cases
                // eslint-disable-next-line no-undef
                // eslint-disable-next-line no-console
                

                // eslint-disable-next-line @lwc/lwc/no-inner-html
                this.template.querySelector('[data-id="link0"]').innerHTML= this.FIELDS[0].QuickLinksLabel;
                this.template.querySelector('[data-id="link1"]').innerHTML= this.FIELDS[1].QuickLinksLabel;
                this.template.querySelector('[data-id="link2"]').innerHTML= this.FIELDS[2].QuickLinksLabel;
                this.template.querySelector('[data-id="link3"]').innerHTML= this.FIELDS[3].QuickLinksLabel;
                this.template.querySelector('[data-id="link4"]').innerHTML= this.FIELDS[4].QuickLinksLabel;
                this.template.querySelector('[data-id="link5"]').innerHTML= this.FIELDS[5].QuickLinksLabel;
                this.template.querySelector('[data-id="link6"]').innerHTML= this.FIELDS[6].QuickLinksLabel;
                this.error = undefined;
        } else if (error) {
            this.error = error;
            this.FIELDS = undefined;
           
            // eslint-disable-next-line no-console
            console.log('&&&- '+JSON.stringify(error)); 
            // eslint-disable-next-line no-alert
             
        }
    }
        @wire(getDynamicVideoLinksList)
        wiredVideoLinks({ error1, data }){
            if (data) {
                this.VideoArray = data;
                // eslint-disable-next-line no-alert
                    let elem = this.template.querySelector('[data-id="VidID"]').setAttribute('src', this.VideoArray[0].VideoURL);
                    //used it as a string, just for test cases
                    // eslint-disable-next-line no-undef
                    // eslint-disable-next-line no-console
                    this.error1 = undefined;
            } else if (error1) {
                this.error1 = error1;
                this.VideoArray = undefined;
                // eslint-disable-next-line no-console
                console.log('&&&- '+JSON.stringify(error1)); 
                // eslint-disable-next-line no-alert
                 
            }
        }
}
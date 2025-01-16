import { LightningElement, api,track } from 'lwc';
import getRecordDetails from '@salesforce/apex/ProactiveDynamicComponentController.getCurrentRecordDetails';
import proactiveBaseURL from '@salesforce/label/c.Proactive_Base_URL';
import {
    callServer,
    consoleError
} from 'c/utils';
export default class ProactiveDynamicComponent extends LightningElement {
    //variable used to get Object name from UI.
    @api objectName;
    //variable used to get corresponding Record ID
    @api recordId;
    //iFrame URL
    @track iframesrc;

    connectedCallback(){
        this.getCurrentRecordDetails();
    }
    //Server call to form iFrame URL based on Object Name and Record Id
    getCurrentRecordDetails() {
        if(this.objectName==='Account'){
            this.iframesrc = proactiveBaseURL+ 'account/'+this.recordId+'?view=DCP';
        } else {
            callServer(getRecordDetails,{
                recordId:this.recordId,
                objectName:this.objectName
            },result => {
                this.iframesrc = proactiveBaseURL+ 'instrument/'+result+'?view=DCP';
            }, error => {
                    consoleError('error',JSON.stringify(error));
            });

        }

       
    }
}
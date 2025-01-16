import {
    LightningElement,
    api,
    wire,
    track
} from 'lwc';
import {
    getRecord,
    updateRecord
} from 'lightning/uiRecordApi';
import {
    showErrorToast,
    showSuccessToast,
    callServer 
} from 'c/utils'; //DCP-49914
import ID_FIELD from "@salesforce/schema/Case.Id";
import UNREAD_FIELD from "@salesforce/schema/Case.Unread_Emails__c";
import { NavigationMixin } from 'lightning/navigation';

//START - DCP-49914
import checkRelatedWeChatComments from '@salesforce/apex/ToggleUnreadEmailController.checkRelatedWeChatComments'; 
import UI_CheckComments from '@salesforce/label/c.UI_CheckComments';
//END - DCP-49914
export default class ToggleUnreadEmail extends NavigationMixin(LightningElement) {

    //  variable used to fetch the corresponding case ID 
    @api recordId;
    //  variable used to maintain the state of unread email checkbox
    @track unread;
    //  variable used to set the value of toggle on the component load
    @track toggleValue = false;
    //  variable used to control the spinner
    @track booLoading = false;

    //START - DCP-49914
    //variable to control the text for comments list
    @track containsUnreadWeChatComment = false; 
    label = {UI_CheckComments};
    //END - DCP-49914

    // Initial Wire call to fetch case details
    @wire(getRecord, {
        recordId: '$recordId',
        fields: ["CASE.Unread_Emails__c"]
    })
    caseRecordFetch({
        error,
        data
    }) {
        console.log('data--'+data);
        if (data && data.fields && data.fields.Unread_Emails__c) {
            // setting up the default value of toggle using the ID of Lightning Input
            console.log('data fetched--'+JSON.stringify(data));
            this.toggleValue = data.fields.Unread_Emails__c.value;
            this.template.querySelector('[data-id="toggleButtonId"]').checked = this.toggleValue;

            //START - DCP-49914
            if(this.toggleValue) {
                this.booLoading = true;
                callServer(checkRelatedWeChatComments, {
                    recordId: this.recordId
                }, result => {
                    this.containsUnreadWeChatComment = result;
                    this.booLoading = false;
                }, error => {
                    this.booLoading = false;
                    console.log('Error in fetching'+error);     
                    
                });
            }
            //END - DCP-49914
            
        }
        else{
            console.log('Error in fetching'+error); 
        }
    }

    /**
     * method name: toggleChange
     * params: event
     * description: To be executed on click of toggle button. 
     * Updates the Unread Email checkbox and  provide aknowledgement to user with a toast message
     */

    toggleChange(event) {
        console.log('Entered JS' + event.target.checked);
        console.log('reocrd Id' + this.recordId);
        this.booLoading = true;
        if (event.target.checked) {
            this.unread = true;
        } else {
            this.unread = false;
        }
        const fields = {};
        console.log('status of toggle' + this.unread);

        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[UNREAD_FIELD.fieldApiName] = this.unread;

        const recordInput = {
            fields: fields
        };
        //Update the case record and displays a toast message
        updateRecord(recordInput).then((record) => {
            console.log(record);
            showSuccessToast('Unread Emails Updated Successfully');
            this.containsUnreadWeChatComment = this.unread; //DCP-49914
            this.booLoading = false;
        }).catch(error => {
            console.log('error'+error+'stringified'+JSON.stringify(error));
            showErrorToast(error.body.message);
            this.booLoading = false;
        });

    }
//
/**
 * DCP-43125
 * added by Deepika Ayyavari
* @description Method to navigate to emailRelatedList lwc component
*///

handleNavigate() {
    let compDefinition = {
        componentDef: "c:emailRelatedList",
        attributes: {
            ParentId : this.recordId
        }
    };

    // Base64 encode the compDefinition JS object
   let encodedCompDef = btoa(JSON.stringify(compDefinition));
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/one/one.app#' + encodedCompDef 
        }
    });
}
}

/**
 * @description       : 
 * @author            : Vaibhav
 * @group             : 
 * @last modified on  : 09-03-2020
 * @last modified by  : Vaibhav
 * Modifications Log 
 * Ver   Date         Author    Modification
 * 1.0   08-29-2020   Vaibhav   Initial Version
**/
import { LightningElement, wire, track, api } from 'lwc';
import runASOPEmailBusinessLogic from "@salesforce/apex/SendEmailToASOPFromCase.runASOPEmailBusinessLogic";
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class SendEmailToASOPFromCase extends NavigationMixin(LightningElement) {

    @track error;
    uiDisplayMessage = 'Please Wait.';
    @track showLoadingSpinner = false;
    @track searchTerm = '';
    @api triggeredFromRecordId;
    @api triggeredFromRecordObjectName;
    @api triggeredCaseId;
    @track disableSendEmailButton = true;
    @track hideSendEmailButton = false;
    uiMessageTextColor = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_offline';
    @track uiScenario = 'OnLoad';
    showSearchTermScreen = false;
    @track showAttachmentScreen = false;
    @track filesUploaded = [];
    MAX_FILE_SIZE = 4000000; //Max file size 4.0 MB
    totalSizeOfFilesUploaded = 0;



    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.showLoadingSpinner = true;
            this.triggeredFromRecordId = currentPageReference.state.c__id;
            this.triggeredFromRecordObjectName = currentPageReference.state.c__objectName;
            this.triggeredCaseId = currentPageReference.state.c__caseId;
            this.uiScenario = 'OnLoad';
            this.uiDisplayMessage = 'Please Wait.';
            this.uiMessageTextColor = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_offline';
            this.showSearchTermScreen = false;
            this.showAttachmentScreen = false;
            this.disableSendEmailButton = true;
            this.hideSendEmailButton = false;
            this.searchTerm = '';
            this.filesUploaded = [];
            window.console.log('Current Page Reference...' + JSON.stringify(currentPageReference));
            this.runApexASOPEmailMethod();
        }


    }

    //stores the value in search term input box
    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    //send email button
    handleSendEmail() {
        this.uiScenario = 'sendEmailClicked';
        this.runApexASOPEmailMethod();
    }

    //populate ui visual values
    setupUIDetails(data) {

        let displayMessage = data.uiDisplayMessage;
        this.uiDisplayMessage = displayMessage;
        this.disableSendEmailButton = displayMessage.includes("Success") ? true : displayMessage.includes("Error") ? true : false;
        this.uiMessageTextColor = displayMessage.includes("Success") ? 'slds-text-heading_small slds-align_absolute-center slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_success' : this.uiDisplayMessage.includes("Error") ? 'slds-text-heading_small slds-align_absolute-center slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_error' : 'slds-text-heading_small slds-align_absolute-center slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_warning';
        this.showLoadingSpinner = false;
        this.hideSendEmailButton = displayMessage.includes("Warning") ? true : false;

    }

    //apex method to send email
    runApexASOPEmailMethod() {

        this.showLoadingSpinner = true;
        this.showSearchTermScreen = this.triggeredFromRecordObjectName === 'EmailMessage' ? true : false;
        runASOPEmailBusinessLogic({
            recordId: this.triggeredFromRecordId,
            objectName: this.triggeredFromRecordObjectName,
            scenario: this.uiScenario,
            searchTerm: this.searchTerm,
            files: this.filesUploaded
        })
            .then((result) => {
                this.setupUIDetails(result);
                this.showLoadingSpinner = false;
                //reset cancel adding attachment screen
                this.cancelAddingAttachments();
            })
            .catch((error) => {
                this.error = error;
                console.log('error ' + JSON.stringify(this.error));
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    }),
                );
            });
    }

    //show attachment screen
    handleAddAttachment() {
        this.showAttachmentScreen = true;
    }

    //hide attachment screen
    cancelAddingAttachments() {
        this.showAttachmentScreen = false;
        this.filesUploaded = [];
        this.totalSizeOfFilesUploaded = 0;
        if(this.uiDisplayMessage.includes("Warning")){
            this.hideSendEmailButton = true;
        }
    }

    //file upload method
    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            let files = [];
            for (let i = 0; i < event.target.files.length; i++) {
                let file = event.target.files[i];
                this.totalSizeOfFilesUploaded += file.size;
                let reader = new FileReader();
                reader.onload = e => {
                    let base64 = 'base64,';
                    let content = reader.result.indexOf(base64) + base64.length;
                    let fileContents = reader.result.substring(content);
                    this.filesUploaded.push({ pathOnClient: file.name, title: file.name, versionData: fileContents });
                };
                reader.readAsDataURL(file);
            }
            //show send email button if attachment is added.
            this.hideSendEmailButton = this.filesUploaded.length === 0 || this.filesUploaded.length > 0 ? false : true;
            
            if (this.totalSizeOfFilesUploaded > this.MAX_FILE_SIZE) {
                console.log('totalSizeOfFilesUploaded === ' +this.totalSizeOfFilesUploaded);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'File size should be less then 4MB',
                        variant: 'error',
                    }),
                );
            }
        
        }
    }

    redirectBackToCase() {

        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
              recordId: this.triggeredCaseId,
              actionName: "view"
            }
          }).then((url) => {
            window.open(url);
          });

          //close the original window
          window.close();
      
     }


}
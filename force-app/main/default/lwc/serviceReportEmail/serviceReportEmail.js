/**
 *    @author Soumya Ranjan Sahu
 *    @date   10-03-2020
 *    @description    JavaScript for Lightning Web Component
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Soumya Ranjan Sahu           10-03-2020           Initial Version
 *    ------------------------------------------------------------------------------------                   
 */
import {LightningElement,api,wire,track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Company__c';
import CONTACT_ID from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Contact__c';
import CONTACT_NAME from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Contact__r.Name';
import CONTACT_EMAIL from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Contact__r.Email';
import CASE_ID from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Case__c';//DCP-44235
import SERVICE_REPORT_GENERATED_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.Is_Service_Report_Generated__c';
import getLatestServiceReportfromWorkOrder from '@salesforce/apex/ServiceReportEmailController.getLatestServiceReportfromWorkOrder';
import sendServiceReportEmail from '@salesforce/apex/ServiceReportEmailController.sendServiceReportEmail';
import getTemplateData from '@salesforce/apex/ServiceReportEmailController.getTemplateData';
import getResults from '@salesforce/apex/ServiceReportEmailController.getResults';
import getCCAddresses from '@salesforce/apex/ServiceReportEmailController.getCCAddresses';
import getRelatedContacts from '@salesforce/apex/ServiceReportEmailController.getRelatedContacts';
import { consoleError } from 'c/utils';
//Delay to Sync between Server Calls and Display of Search Results
const DELAY = 400;
//Get Account, Contact and workorder fields
const fields = [ACCOUNT_FIELD, SERVICE_REPORT_GENERATED_FIELD, CONTACT_ID, CONTACT_NAME, CONTACT_EMAIL,CASE_ID];
export default class ServiceReportEmail extends LightningElement {
    @api recordId;
    @track loaded = true;
    @track files = [];
    @track boolServiceReportGenerated;
    @track subject;
    @track body;
    @track searchRecords = [];
    @track selectedToRecords = [];
    @track selectedCCRecords = [];
    @api TOLoadingText = false;
    @api CCLoadingText = false;
    @track txtToclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track txtCCclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track TOmessageFlag = false;
    @track CCmessageFlag = false;
    @track sObjectMap = [];
    @track SearchTextTO='';
    @track SearchTextCC='';
    boolAlertResult;
    delayTimeout;
    @track error;
    accountId;
    relatedContacts=[];
    @track caseId; //DCP-44235

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To get contact, workorder fields and account of work order
    **/
    @wire(getRecord, {
        recordId: '$recordId',
        fields
    })
    WorkOrderRecord({
        error,
        data
    }) {
        
        let contactId;
        let contactName;
        let contactEmail;
        this.toggleSpinner();
        if (data) {
            this.boolServiceReportGenerated = getFieldValue(data, SERVICE_REPORT_GENERATED_FIELD);
            this.accountId = getFieldValue(data, ACCOUNT_FIELD);
            contactId = getFieldValue(data, CONTACT_ID);
            contactName = getFieldValue(data, CONTACT_NAME);
            contactEmail = getFieldValue(data, CONTACT_EMAIL);
            this.caseId = getFieldValue(data, CASE_ID);//DCP-44235
            let newsObject = {
                'recId': contactId,
                'recName': contactName,
                'recEmail': contactEmail,
                'icontype': 'standard:contact'
            };
            //Set Contact Email as default To Address
            this.selectedToRecords.push(newsObject);
        } else if (error) {
            this.error = error;
            console.log(error);
        }
        /**
        *  @author Soumya Ranjan Sahu 
        *  @description : To search for Associated Acc to Field Supp records based on the roles specified
        **/
        getCCAddresses({
                accountId: this.accountId
            })
            .then(result => {
                if (result != null) {
					if(this.selectedCCRecords.length>0){
                       this.selectedCCRecords=[];
                    }
                    for (let i = 0; i < result.length; i++) {
                        let newsObject = {
                            'recId': result[i].recId,
                            'recName': result[i].recName,
                            'recEmail': result[i].recEmail,
                            'icontype': 'standard:user'
                        };
                        this.selectedCCRecords.push(newsObject);
                    }
                }

            })
            .catch(error => {
                this.error = error;
                console.log(error);
            });
            /**
        *  @author Soumya Ranjan Sahu 
        *  @description : To gget all the related (Searchable) contacts associated with the account of the work order
        **/
       getRelatedContacts({
            accountId: this.accountId
        })
        .then(result => {
            if (result != null && result.length>0) {
                this.relatedContacts=result;
            }

        })
        .catch(error => {
            this.error = error;
            console.log(error);
        });
    }
    /**
        *  @author Soumya Ranjan Sahu 
        *  @description : Generic method to show dynamic search results based on input with delay of 400 ms
        **/
    searchField() {
        let selectedRecords = [];
        let currentText = arguments[0];
        selectedRecords = [...arguments[1]];
        let source = arguments[2];
        this.sObjectMap = [];
        let txtclassname;
        let selectContactRecId = [];
        let selectUserRecId = [];
        let containsComma = currentText.includes(",");
        if (currentText.length > 0 && containsComma) {
            if (source == 'ToEmailField') {
                this.TOmessageFlag = false;
            }
            if (source == 'CCEmailField') {
                this.CCmessageFlag = false;
            }
        }
        if(!containsComma){
        window.clearTimeout(this.delayTimeout);
        for (let i = 0; i < selectedRecords.length; i++) {
            if (selectedRecords[i].recId.startsWith("003")) {
                selectContactRecId.push(selectedRecords[i].recId);
            } else if (selectedRecords[i].recId.startsWith("005")) {
                selectUserRecId.push(selectedRecords[i].recId);
            }
        }
        this.delayTimeout = setTimeout(() => {
            this.currentText = currentText;
            //Turn ON load spinner
            if (source == 'ToEmailField') {
                this.TOLoadingText = true;
            }
            if (source == 'CCEmailField') {
                this.CCLoadingText = true;
            }
            //Get Results from Apex
            getResults({
                    value: currentText,
                    setContactIds: selectContactRecId,
                    setUserIds: selectUserRecId,
                    setRelatedContacts: this.relatedContacts
                })
                .then(result => {

                    this.searchRecords = result;
                    //Turn Off load spinner
                    if (source == 'ToEmailField') {
                        this.TOLoadingText = false;
                    }
                    if (source == 'CCEmailField') {
                        this.CCLoadingText = false;
                    }
                    txtclassname = result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                    if (source == 'ToEmailField') {
                        this.txtToclassname = txtclassname;
                    }
                    if (source == 'CCEmailField') {
                        this.txtCCclassname = txtclassname;
                    }

                    if (currentText.length > 0 && result.length == 0) {
                        if (source == 'ToEmailField') {
                            this.TOmessageFlag = true;
                        }
                        if (source == 'CCEmailField') {
                            this.CCmessageFlag = true;
                        }
                    } else {
                        //Show Icons conditionally
                        for (let i = 0; i < result.length; i++) {
                            if (result[i].recId.startsWith('003')) {
                                this.sObjectMap.push({
                                    value: 'standard:contact',
                                    key: result[i]
                                });
                            } else if (result[i].recId.startsWith('005')) {
                                this.sObjectMap.push({
                                    value: 'standard:user',
                                    key: result[i]
                                });
                            }

                        }
                        if (source == 'ToEmailField') {
                            this.TOmessageFlag = false;
                        }
                        if (source == 'CCEmailField') {
                            this.CCmessageFlag = false;
                        }
                    }

                })
                .catch(error => {
                    this.error = error;
                    console.log('-------error-------------' + error);
                });
        }, DELAY);
    }

    }
    /**
        *  @author Soumya Ranjan Sahu 
        *  @description : Add selected record to set of To Addresses
        **/
    setSelectedToRecords(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let recEmail = event.currentTarget.dataset.email;
        let icontype;
        //Show Icons conditionally
        if (recId.startsWith("003")) {
            icontype = 'standard:contact';
        } else if (recId.startsWith("005")) {
            icontype = 'standard:user';
        }
        let newsObject = {
            'recId': recId,
            'recName': selectName,
            'recEmail': recEmail,
            'icontype': icontype
        };
        this.selectedToRecords.push(newsObject);
        this.txtToclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.SearchTextTO = '';
        this.resetToErrorMessage();
        
       
    }

    resetToErrorMessage(){

       this.template.querySelector('.to-email').focus();
       setTimeout(() => {
        this.template.querySelector('.to-email').blur();
        this.template.querySelector('.to-email').focus();
    }, 10);
       
    }

    resetCCErrorMessage(){

        this.template.querySelector('.cc-email').focus();
        setTimeout(() => {
         this.template.querySelector('.cc-email').blur();
         this.template.querySelector('.cc-email').focus();
     }, 10);
        
     }

    /**
        *  @author Soumya Ranjan Sahu 
        *  @description : Remove selected record from set of To Addresses
        **/
    removeToRecord(event) {
        let selectRecId = [];
        for (let i = 0; i < this.selectedToRecords.length; i++) {
            if (event.detail.name !== this.selectedToRecords[i].recId)
                selectRecId.push(this.selectedToRecords[i]);
        }
        this.selectedToRecords = [...selectRecId];

    }
    /**
        *  @author Soumya Ranjan Sahu 
        *  @description : Add selected record to set of CC Addresses
        **/
    setSelectedCCRecords(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let recEmail = event.currentTarget.dataset.email;
        let icontype;
        //Show Icons conditionally
        if (recId.startsWith("003")) {
            icontype = 'standard:contact';
        } else if (recId.startsWith("005")) {
            icontype = 'standard:user';
        }
        let newsObject = {
            'recId': recId,
            'recName': selectName,
            'recEmail': recEmail,
            'icontype': icontype
        };
        this.selectedCCRecords.push(newsObject);
        this.txtCCclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.SearchTextCC = '';
        this.resetCCErrorMessage();
    }
    /**
        *  @author Soumya Ranjan Sahu 
        *  @description : Remove selected record from set of CC Addresses
        **/
    removeCCRecord(event) {
        let selectRecId = [];
        for (let i = 0; i < this.selectedCCRecords.length; i++) {
            if (event.detail.name !== this.selectedCCRecords[i].recId)
                selectRecId.push(this.selectedCCRecords[i]);
        }
        this.selectedCCRecords = [...selectRecId];
    }
     /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To fetch the latest Service Report on the work order
    **/

    @wire(getLatestServiceReportfromWorkOrder, {
        workOrderId: '$recordId'
    })
    wiredLatestServiceReport({
        error,
        data
    }) {
        if (data) {
            this.files = [...this.files, {
                Id: data.Id,
                name: data.Name
            }];//Add the Service Report to List of Attachments
            console.log(" ==== ", JSON.stringify(this.files));
        } else if (error) {
            this.error = error;
            console.log(error);
        }
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To prefill subject and Description
    **/
    @wire(getTemplateData, {
        workOrderId: '$recordId'
    })
    wiredTemplateData({
        error,
        data
    }) {
        if (data) {
            this.subject = data.subject;
            this.body = data.body;
        } else if (error) {
            this.error = error;
            console.log(error);
        }
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To send email to Selected Addresses with all attachments
    **/
    sendEmail(event) {
        if(this.SearchTextTO == undefined)
            this.SearchTextTO='';
        if(this.SearchTextCC == undefined)
            this.SearchTextCC='';
        let isToEmailValidated=true;
        let isCCEmailValidated=true;
        //To check if To EMail has some value
        if(this.SearchTextTO != ''){
            isToEmailValidated=this.addToEmails(this.SearchTextTO);
        }
        //To check if CC EMail has some value
        if(this.SearchTextCC != ''){
            isCCEmailValidated=this.addCCEmails(this.SearchTextCC);
        }
        this.boolAlertResult = this.CheckToAddr();
        if (this.boolAlertResult && isToEmailValidated && isCCEmailValidated) {
            console.log('Spinner ON before Sending Email');
            //turn ON Spinner till Email Result is fetched
            this.toggleSpinner();
            let ToAddresses = [];
            let CCAddresses = [];
            let setContentDocumentIds = [];
            let setAttachmentIds = [];
            //Building Lists for sending to Apex
            for (let i = 0; i < this.selectedToRecords.length; i++) {
                ToAddresses.push(this.selectedToRecords[i].recEmail);
            }
            for (let i = 0; i < this.selectedCCRecords.length; i++) {
                CCAddresses.push(this.selectedCCRecords[i].recEmail);
            }
            for (let i = 0; i < this.files.length; i++) {
                let fileId = this.files[i].Id;
                //Segregating Files and Attachments into different sets
                if (fileId.startsWith("069")) {
                    setContentDocumentIds.push(this.files[i].Id);
                }
                if (fileId.startsWith("00P")) {
                    setAttachmentIds.push(this.files[i].Id);
                }
            }
            //Invoking Email and send it out.
            sendServiceReportEmail({
                    lstToAddresses: ToAddresses,
                    lstCCAddresses: CCAddresses,
                    subject: this.subject,
                    body: this.body,
                    setContentDocumentIds: setContentDocumentIds,
                    setAttachmentIds: setAttachmentIds,
                    strWoId: this.recordId,
                    caseId: this.caseId
                })
                .then(result => {
                    this.toggleSpinner();
                    console.log('Email Result' + result);
                    if (result === 'The email was sent successfully.') {
                        //Show Email Result
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Email Sent!!',
                                message: result,
                                variant: 'Success',
                            }),
                        );
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Email Result',
                                message: result,
                                variant: 'error',
                            }),
                        );

                    }
                })
                .catch(error => {
                    this.toggleSpinner();
                    this.error = error;
                    console.log(error);
                });
        }
    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To handle file uploads/Drag and drop from Local
    **/

    handleUploadFinished(event) {
        let uploadedFiles = event.detail.files;

        for (let index = 0; index < uploadedFiles.length; index++) { //for(let index in uploadedFiles) {
            if ({}.hasOwnProperty.call(uploadedFiles, index)) {
                this.files = [...this.files, {
                    Id: uploadedFiles[index].documentId,
                    name: uploadedFiles[index].name
                }];
            }
        }
        console.log(" ==== ", JSON.stringify(this.files));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Succesful Uploads',
                message: ' File(s) uploaded Successfully!',
                variant: 'Success',
            }),
        );
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To remove attachment from list of selected attachments
    **/
    handleDelete(event) {
        for (let i = 0; i < this.files.length; i++) {
            if (this.files[i].Id === event.target.getAttribute('data-id')) {
                this.files.splice(i, 1);
            }
        }
    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To dynamically search for related Contacts/User
    **/
    handleToEmail(event) {
       // this.resetToErrorMessage();
        let toEmail = event.target.value;
        this.SearchTextTO=toEmail;
        event.stopPropagation();
        if(toEmail==''){
            this.resetToErrorMessage();
        }
        if(toEmail.length>2){
            
            this.searchField(toEmail, this.selectedToRecords, 'ToEmailField');
        }
        else
        this.txtToclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To make sure To field is not empty
    **/
    CheckToAddr() {
        if (this.selectedToRecords.length == 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'To Email field is Mandatory',
                    message: 'Please add a value to To Email field',
                    variant: 'Error',
                }),
            );
            return false;
        } else {
            return true;
        }

    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To dynamically search for related Contacts/User
    **/
    handleCCEmail(event) {
        let ccEmail = event.target.value;
        this.SearchTextCC=ccEmail;
        event.stopPropagation();
        if(ccEmail==''){
            this.resetCCErrorMessage();
        }
        if(ccEmail.length>2){
            
            this.searchField(ccEmail, this.selectedCCRecords, 'CCEmailField');
        }
        else
        this.txtCCclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Handle change in Subject Field
    **/
    handleSubject(event) {
        this.subject = event.target.value;
    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Handle change in Rich Text Body editor Field
    **/
    handleBody(event) {
        this.body = event.target.value;
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Add email addresses not in System to the List of To Addresses
    **/
    handleToEnterkey(event) {
        let keycode = (event.keyCode ? event.keyCode : event.which);
        let toEmailstr = event.target.value;
        if (keycode == '13' && toEmailstr!=='') {            
            this.addToEmails(toEmailstr);
        }
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Add email addresses not in System to the List of CC Addresses
    **/
    handleCCEnterkey(event) {
        let keycode = (event.keyCode ? event.keyCode : event.which);
        let ccEmailStr = event.target.value;
        
        if (keycode == '13' && ccEmailStr!=='') {
           
                this.addCCEmails(ccEmailStr);

        }
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Generic method to add Emails to set of To Addresses
    **/
   addToEmails() {
    let isValidEmail;   
    let reqFields = this.template.querySelectorAll('.to-email');
            reqFields.forEach(function(rf) {
                rf.reportValidity();
                isValidEmail=rf.checkValidity();
            });   
    let toEmailStr = arguments[0].replace(/ /g, "");
    let toEmails = toEmailStr.split(",");
    let prevToEmailLength=this.selectedToRecords.length;
    this.SearchTextTO = '';
    for (let index = 0; index < toEmails.length; index++){
        //let isValidEmail=this.validateEmail(toEmails[index]);
        if(isValidEmail){
            let isAlreadyadded=false;
            for (let i = 0; i < this.selectedToRecords.length; i++){
                if(this.selectedToRecords[i].recEmail==toEmails[index]){
                    isAlreadyadded=true;
                    if (this.SearchTextTO == '')
                        this.SearchTextTO = toEmails[index];
                    else {
                        this.SearchTextTO = this.SearchTextTO+', '+toEmails[index];
                    }
                }
            }
            if (!isAlreadyadded) {
                let newsObject = {
                    'recId': toEmails[index],
                    'recName': toEmails[index],
                    'recEmail': toEmails[index],
                    'icontype': 'utility:user'
                };
                this.selectedToRecords.push(newsObject);
                this.TOmessageFlag = false;

            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Duplicate Email',
                        message: 'Entered email(s) is/are already added.',
                        variant: 'Error',
                    }),
                );
            }
        } else {
            if (this.SearchTextTO == '')
                this.SearchTextTO = toEmails[index];
            else {
                this.SearchTextTO = this.SearchTextTO+', '+toEmails[index];
            }
        }
    }
    if(this.selectedToRecords.length==(prevToEmailLength + toEmails.length))
        return true;
    else
        return false;  
}
    
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Generic method to add Emails to set of CC Addresses
    **/
    addCCEmails() {
        let isValidEmail;
        let reqFields = this.template.querySelectorAll('.cc-email');
            reqFields.forEach(function(rf) {
            rf.reportValidity();
            isValidEmail=rf.checkValidity();
            });
        let ccEmailStr = arguments[0].replace(/ /g, "");
        let ccEmails = ccEmailStr.split(",");
        let prevCCEmailLength = this.selectedCCRecords.length;
        this.SearchTextCC = '';
        for (let index = 0; index < ccEmails.length; index++) {
            //let isValidEmail = this.validateEmail(ccEmails[index]);
            if (isValidEmail) {
                let isAlreadyadded = false;
                for (let i = 0; i < this.selectedCCRecords.length; i++) {
                    if (this.selectedCCRecords[i].recEmail == ccEmails[index]) {
                        isAlreadyadded = true;
                        if (this.SearchTextCC == '')
                            this.SearchTextCC = ccEmails[index];
                        else {
                            this.SearchTextCC = this.SearchTextCC+', '+ccEmails[index];
                        }
                    }
                }
                if (!isAlreadyadded) {
                    let newsObject = {
                        'recId': ccEmails[index],
                        'recName': ccEmails[index],
                        'recEmail': ccEmails[index],
                        'icontype': 'utility:user'
                    };
                    this.selectedCCRecords.push(newsObject);
                    this.CCmessageFlag = false;

                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Duplicate Email',
                            message: 'Entered email(s) is/are already added.',
                            variant: 'Error',
                        }),
                    );
                }
            } else {
                if (this.SearchTextCC == '')
                    this.SearchTextCC = ccEmails[index];
                else {
                    this.SearchTextCC = this.SearchTextCC+', '+ccEmails[index];
                }
            }
        }
        if (this.selectedCCRecords.length == (prevCCEmailLength + ccEmails.length))
            return true;
        else
            return false;
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Generic method to validate an Email
    **/
    validateEmail(){
        let inputText=arguments[0];
        let recEmail=inputText.replace(/ /g, "");
        if (/^([\w\-\.]+)@((\[([0-9]{1,3}\.){3}[0-9]{1,3}\])|(([\w\-]+\.)+)([a-zA-Z]{2,10}))$/.test(recEmail)) {//To validate if the entered email address is in correct format  
            return true;
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Email',
                    message: 'Please enter a valid email address',
                    variant: 'Error',
                }),
            );
            return false;
        }
    }
    //To Hide search list when user clicks else where in the component
    handlefocus(event) {
        this.txtToclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.txtCCclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }
    //To Hide CC search list when user clicks on To Email field
    handleToFieldFocus(event) {
        this.txtCCclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }
    //To Hide To search list when user clicks on CC Email field
    handleCCFieldFocus(event) {
        this.txtToclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    //Used for show/hide of spinner
    toggleSpinner() {
        this.loaded = !this.loaded;
    }
}
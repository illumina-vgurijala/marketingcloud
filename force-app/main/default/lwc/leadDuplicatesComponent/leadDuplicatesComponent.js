import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getRecord} from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import returnResponse from '@salesforce/apex/FindDuplicateRecordsController.fetchDuplicates';
import createWarnings from '@salesforce/apex/FindDuplicateRecordsController.createDuplicateWarnings';
import getLeadMergeAccess from '@salesforce/apex/FindDuplicateRecordsController.isMergeAccessGranted';
import convertLead from '@salesforce/apex/FindDuplicateRecordsController.convertLead';
import sendMergeReqst from '@salesforce/apex/FindDuplicateRecordsController.sendEmailMergeRequest';
import helpText from '@salesforce/label/c.DB_Help_Text_Non_Admins';
import showMsg1 from '@salesforce/label/c.DB_Show_Msg_1';
import showMsg2 from '@salesforce/label/c.DB_Show_Msg_2';
import warningMsg from '@salesforce/label/c.Warning_Msg_Lead_Contact_Conversion';
import emailSuccessMessage from '@salesforce/label/c.Email_Sent_Successfully';
import admin from '@salesforce/label/c.ProfileSystemAdmin';
import dataSteward from '@salesforce/label/c.ProfileDataSteward';
import salesUser from '@salesforce/label/c.SalesRepProfileName';
import revenueOps from '@salesforce/label/c.Profile_Commercial_and_Revenue_Operations';
import mrktLeadQualify from '@salesforce/label/c.Marketing_Lead_Qualification';
import fieldService from '@salesforce/label/c.ProfileName_FieldService';
import customerService from '@salesforce/label/c.ProfileCustomerService';
import techSupport from '@salesforce/label/c.ProfileName_TechnicalSupport';
import btnLabel from '@salesforce/label/c.Lead_Duplicates_Button_Label';
import commentBoxMsg from '@salesforce/label/c.Comment_Box_Label';
export default class LeadDuplicatesComponent extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api recordId;
    @track loaded = false;
    @track showModal = false;
    @track title;
    @track error;
    @track dupLeadCount;
    @track dupContactCount;
    @track totalCount;
    @track duplicateLeads=[];
    @track duplicateContacts=[];
    @track showLeadButton = false;
    @track showContactButton = false;
    @track leadBtnLabel;
    @track contactBtnLabel;
    @track mapScenarios;
    @track hideCheckboxColumn = true;
    @track hideLeadsCheckboxColumn = true;
    @track isContact;
    @track isLead;
    @track showCommentBox = false;
    @track showMergeButton = false;
    //Field to be displayed in UI along with their initial  width for contacts
    @track fieldnamestr = {"Id":"105","Name":"185","FirstNameLocal":"190","LastNameLocal":"190","Email":"195","Title":"100","Department__c":"150","Department_Local__c":"195","Marketing_Contact_Status__c":"195","Is_Active__c":"75","Account.Name":"175","Title":"85","Is_MyIllumina_User__c":"165","Phone":"155","MobilePhone":"155","Country_Local__c":"165", "PGUID__c":"100", "Is_Community_User__c":"140","RecordType.Name":"130","CreatedDate":"185"};
    //look up Field to be displayed in UI along with column header for contacts
    @track lookupmap = {"Account.Name":"Account Name","RecordType.Name":"Record Type"};
    //Field to be displayed in UI along with their initial  width for contacts
    @track leadfieldnamestr = {"Id":"105","Name":"185","Email":"195","Title":"100","Company":"100","FirstNameLocal":"190","LastNameLocal":"190","Job_Function__c":"175","Department__c":"150","Department_Local__c":"195","Phone":"130","Country":"100","Email_Verification_Status__c":"185","Status":"150","CreatedDate":"185"};
    //where clause contacts
    @track whereClauseContacts;
    //where clause leadds
    @track whereClauseLeads;
    //@track hasConvertAccess=false;
    @track isConvertDisabled=true;
    @track selectedLeadRecords;
    @track selectedContactRecords;
    @track disableNextButton = true;
    @track isCompleted = true;
    // Expose the labels to use in the templat
    label = {
        helpText, showMsg1,showMsg2,emailSuccessMessage,warningMsg,admin,dataSteward,salesUser,revenueOps,mrktLeadQualify,btnLabel,commentBoxMsg,fieldService,customerService,techSupport
    };
    lstProfilesForConvert = [this.label.dataSteward, this.label.admin, this.label.revenueOps, this.label.mrktLeadQualify,this.label.salesUser,this.label.fieldService, this.label.customerService,this.label.techSupport];
    lstProfilesForMerge = [this.label.dataSteward, this.label.admin];
    profileName;

    /**
     * method: wire function
     * Description: wire function for fetching user related fields like profile name.
     */
    
    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME] })
    userrecord(result){
        console.log('result:'+JSON.stringify(result));
        if(result.data){
            this.profileName = result.data.fields.Profile.value.fields.Name.value;
            if(this.lstProfilesForConvert.includes(this.profileName)){
                //this.hasConvertAccess = true;
                this.hideCheckboxColumn = false;
            } 
            if(this.lstProfilesForMerge.includes(this.profileName)){
                //this.hasConvertAccess = true;
                this.hideLeadsCheckboxColumn = false;
            }   
                  
        }else if(result.error){
            console.log('Error:'+JSON.stringify(result));
        }
    }
    //below code will be used as a function
   @wire(getLeadMergeAccess, {permissionSetName: 'MK_Lead_Merge'}) wiredPermissionSet ({ error, data }) {
        if (data) {
            if(data == true){
                this.hideLeadsCheckboxColumn = false;
            }
        } else if (error) {
            console.log('permission set access error:', JSON.stringify(error));
            if(error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }
        }
    }
    /**
     * method: connectedCallBack
     * Description: Initial load of records to get the count
     */
    connectedCallback(){
        //call the server load
        returnResponse({recordId:this.recordId})
        .then(data => {
            console.log('data-->',data);
            this.loaded=true;
            //if we have duplicates
            if(data.lstDuplicateRecords){
                this.totalCount = data.lstDuplicateRecords.length;
                //seperating leads & contacts
                for(let i=0; i< data.lstDuplicateRecords.length ; i++){
                    let duplicateRec = data.lstDuplicateRecords[i];
                    if(duplicateRec.substring(0,3) == '00Q'){
                        this.duplicateLeads.push(duplicateRec);
                    }else if(duplicateRec.substring(0,3) == '003'){
                        this.duplicateContacts.push(duplicateRec);
                    }
                }
                //calculating duplicate leads count
                if(this.duplicateLeads){
                    this.dupLeadCount=this.duplicateLeads.length;
                }else{
                    this.dupLeadCount = 0;
                }
                //calculating duplicate contacts count
                if(this.duplicateContacts){
                    this.dupContactCount = this.duplicateContacts.length;
                }else{
                    this.dupContactCount = 0;
                }
                //leads
                if(this.dupLeadCount > 0){
                    this.showLeadButton = true;
                    this.leadBtnLabel = this.label.btnLabel+' Leads ('+this.dupLeadCount+')';
                    this.duplicateLeads.unshift(this.recordId);
                    //build the whereclause
                    this.whereClauseLeads = "Id in "+"('" + this.duplicateLeads.join("', '") + "')";
                   
                }
                //contacts
                if(this.dupContactCount > 0){
                    this.showContactButton = true;
                    this.contactBtnLabel = this.label.btnLabel+' Contacts ('+this.dupContactCount+')';
                    //build the whereclause
                    this.whereClauseContacts = "Id in "+"('" + this.duplicateContacts.join("', '") + "')";
                   
                }
                //store the map of duplicates along with scenario Ids for merging
                if(data.mapDuplicatesRules){
                    this.mapScenarios = data.mapDuplicatesRules;
                    let firstKey = Object.keys(this.mapScenarios)[0];
                    this.mapScenarios[this.recordId] = this.mapScenarios[firstKey];
                }
                //buiild the title to display based on the count of duplicates
                this.title= this.label.showMsg1+" "+this.totalCount+" "+this.label.showMsg2+" "+data.objectName.toLowerCase()+".";
            }else{
				this.title=this.label.showMsg1+" no "+this.label.showMsg2+" "+data.objectName.toLowerCase()+".";
			}
        })
        //catch the error if any and show it as a toast message.
        .catch((error) => {
            this.data = undefined;
            this.error = error;
            this.loaded=true; 
            console.log('error-->',error);
            if(error && error.body){
                this.ShowTostMessage('Error', error.body.message, 'error');
            }	
        });
    }

    //to display the toast message
    ShowTostMessage(vartitle, varmessage, varvariant) {
        const evt = new ShowToastEvent({
            title: vartitle,
            message: varmessage,
            variant: varvariant,
        });
        this.dispatchEvent(evt);

    }
    /**
     * function which would be called up on viewDuplicates button.
     */
    viewDuplicates(event){
        let objectType = event.target.name;
        this.showMergeButton = false;
        this.showCommentBox= false;
        if(objectType == 'contact'){
            this.isLead = false;
            this.isContact = true;
        }else if(objectType == 'lead'){
            this.isContact = false;
            this.isLead = true;
            this.showMergeButton = true;
            this.showCommentBox= false;
        }
        this.showModal = true;
    }
    /**
     * Close the error Modal
     */
    closeModal(){
        this.showModal = false;
    }
    /**
     * function: next
     * Description: on click of next button, will take us to dupeblocker provided merge screen from where we can merge the leads.
     */
    next(){
        //this.ShowTostMessage('info', 'Next Method.', 'info');
        if(this.selectedLeadRecords && this.selectedLeadRecords.length > 0){
            this.isCompleted = false;
            //create a json obj and send as param with record id as the key and scenario Id as the value.
            let duplicateRecords={};
            for(let i=0; i<Object.keys(this.selectedLeadRecords).length;i++){
                duplicateRecords[this.selectedLeadRecords[i]]=this.mapScenarios[this.selectedLeadRecords[i]];
            }
            let objectName = 'Lead';
            //create warning records using these record Ids.
            createWarnings({recordId:this.recordId, mapDuplicates:duplicateRecords, scenarioType:objectName})
            .then(data=>{
                if(data){
                    let mergePageURL=window.location.origin+'/apex/CRMfusionDBR101__DB_Warning_Merge?id='+data;
                    window.open(mergePageURL,"_self");
                }
                this.isCompleted = true;
            })
            //catch the error and display it on UI
            .catch((error)=>{
                this.isCompleted = true;
                console.log('error-->',error);
                if(error && error.body){
                    this.ShowTostMessage('Error', error.body.message, 'error');
                }
            });
        }
    }
    /**
     * function: onConvert
     * Description: It will call an apex method which converts the source lead record into selected contact.
     * 
     */
    onConvert(){
        //create warning records using these record Ids.
        this.isCompleted = false;
        convertLead({leadId:this.recordId, contactId:this.selectedContactRecords[0]})
        .then(data=>{
            //if(data){
                // navigate to contact page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.selectedContactRecords[0],
                        objectApiName: 'Contact', // objectApiName is optional
                        actionName: 'view'
                    }
                });
            //}
            this.isCompleted = true;
            this.showModal = false;
        })
        //catch the error and display it on UI
        .catch((error)=>{
            this.isCompleted = true;
            console.log('error-->',error);
            if(error && error.body){
                this.ShowTostMessage('Error',error.body.message, 'error');
            }
        });
    }
    /*
    * method:handleSelect
    * description: It will fire when we select a record for merge and store the values in a variable to use later.
    */
    handleSelectToConvert(event){
        let records = event.detail.recordIds;
        if(records && Object.keys(records).length > 0){
            this.selectedContactRecords = records;
            //enable the convert button if the user selects only 1 record and disable otherwise.
            if(Object.keys(records).length == 1){
                this.isConvertDisabled = false;
            }else{
                this.isConvertDisabled = true;
                this.ShowTostMessage('Warning', this.label.warningMsg, 'warning');
            }
        }else{
            this.isConvertDisabled = true;
            this.selectedContactRecords={};    
        }       
    }
    /**
     * function: handleSelect
     * Description: This is to handle the selected duplicate lead records for merge
     */
    handleSelect(event){
        let leadRecords = event.detail.recordIds;
        if(leadRecords && Object.keys(leadRecords).length > 1){
            this.selectedLeadRecords = leadRecords;
            //enable the next button if the user has selected more than one record.
            this.disableNextButton = false;    
        }else{
            this.disableNextButton = true;
            this.selectedLeadRecords={};
        }
    }
    /*
    * method:submitMergeButton
    * Description: It will open the comment box with 'Send Merge Request' Button.
    */
    submitMergeButton(){
        this.showCommentBox=true ;
        this.showMergeButton=false ;
    }
    /*
    * method:sendEmail
    * Description: It will send an email to Data Stewards for requesting them to merge contact duplicate records.
    */
   sendEmail(){
    let comment= this.template.querySelector('lightning-textarea').value;
    this.isCompleted = false;
    sendMergeReqst({recordId:this.recordId, comment})	
    .then(success=>{
        if(success){
            this.isCompleted = true;
            this.showModal = false;
            this.ShowTostMessage('Success', this.label.emailSuccessMessage, 'success');
        }
        
    })
    //catch the error and display it on UI
    .catch((error)=>{
        this.isWarningCreated = true;
        console.log('error-->',error);
        if(error && error.body){
            this.ShowTostMessage('Error', error.body.message, 'error');
        }
    });
    
}
}
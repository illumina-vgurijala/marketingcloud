import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { LightningElement, track, wire,api } from 'lwc';
import { getRecord , getFieldValue,updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import CASE_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Case__c';
import WORKORDER_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Work_Order__c';
import RELATEDCONTACT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.RelatedContacts__c';
import RELATEDCONTACTNAME_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.RelatedContacts__r.Name';
import INSTALLEDPRODUCT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Installed_Product__c';
import QSRPRODUCT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Originating_Record_Product_ID__c';
import PRODUCT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Installed_Product__r.SVMXC__Product__c';
import CONTACT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Case__r.ContactId';
import ACCOUNT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Case__r.AccountId';
import WOCONTACT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Work_Order__r.SVMXC__Contact__c';
import WOACCOUNT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Work_Order__r.SVMXC__Company__c';
import RCONTACT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.RelatedContacts__r.Contact__c';
import RACCOUNT_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.RelatedContacts__r.Contact__r.AccountId';
import CASENUMBER_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Case__r.CaseNumber';
import FOLLOWUPCASE_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Follow_Up_Case__c';
import WORKORDERNAME_FIELD from '@salesforce/schema/Qualtrics_Survey_Response__c.Work_Order__r.Name';

export default class CreateCaseLink extends NavigationMixin(LightningElement)  {
    _title = 'Case Updated';
    message = '';
    variant = 'Success';
    @track caseexist;
    @track openmodel = false;
    @track followupCase;
    @track origin='Survey';
    @track data;
    @track recordtypeId;
    @api recordId;
    @track accountId;
    @track contactId;
    @track subject;
    @track installedProduct;
    @track product;
    @track parentId;
    @track booShowForm=true;
    @track modalClass = 'slds-modal ';
    @track modalBackdropClass = 'slds-backdrop ';


//Wire Method(Lightning Data service) to fetch the Record Type ID		 
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo({data, error}) {
        if(data) {
            let optionsValues = [];
            const rtInfos = data.recordTypeInfos;
          let rtValues = Object.values(rtInfos);
        for(let i = 0; i < rtValues.length; i++) {
                if(rtValues[i].name == 'Business Issue') {
                  this.recordtypeId= rtValues[i].recordTypeId;
                }
            }
		}else if(error) {
           this.ShowTostMessage('Error',error.body.message,'error')
		}
}

    
//Wire Method(Lightning Data service) to fetch the Qualtrics Data 
  @wire(getRecord, { recordId: '$recordId', fields: [QSRPRODUCT_FIELD,CASE_FIELD, ACCOUNT_FIELD,CONTACT_FIELD,CASENUMBER_FIELD,FOLLOWUPCASE_FIELD,WORKORDER_FIELD,RELATEDCONTACT_FIELD,WORKORDERNAME_FIELD,RELATEDCONTACTNAME_FIELD,WOCONTACT_FIELD,WOACCOUNT_FIELD,RCONTACT_FIELD,RACCOUNT_FIELD,INSTALLEDPRODUCT_FIELD,PRODUCT_FIELD]})
    record({ error, data }) {
        if (error) {
             let message = 'Unknown error';
              message = error.body.message;
                this.ShowTostMessage('Error',message,'error');
            
    } else if (data) {
        this.data=data;       
    }
    
}

//Pre-Populate the Case Fields on the UI with the Data available in Qualtrics Record when the Modal is Loaded											 
onLoad(event){
    this.booShowForm=false;
    this.followupCase=getFieldValue(this.data ,FOLLOWUPCASE_FIELD);
    this.caseexist=this.followupCase!=='' && this.followupCase!==null  ? true : false;
    this.booShowForm=false;
    //this.recordtypeId=getrecordTypeId();
    if(this.caseexist===false){
        if(getFieldValue(this.data ,CASE_FIELD)!=null){
    this.accountId=getFieldValue(this.data ,ACCOUNT_FIELD);
    this.contactId=getFieldValue(this.data ,CONTACT_FIELD);
    this.parentId=getFieldValue(this.data ,CASE_FIELD); 
    this.subject="Low Survey Score related to Case "+ getFieldValue(this.data ,CASENUMBER_FIELD);
        }else if(getFieldValue(this.data ,WORKORDER_FIELD)!=null){
            this.accountId=getFieldValue(this.data ,WOACCOUNT_FIELD);
            this.contactId=getFieldValue(this.data ,WOCONTACT_FIELD);
            //this.parentId=getFieldValue(this.data ,CASE_FIELD); 
            this.subject="Low Survey Score related to Work Order "+ getFieldValue(this.data ,WORKORDERNAME_FIELD);
        }else if(getFieldValue(this.data ,RELATEDCONTACT_FIELD)!=null){
            this.accountId=getFieldValue(this.data ,RACCOUNT_FIELD);
            this.contactId=getFieldValue(this.data ,RCONTACT_FIELD);
            //this.parentId=getFieldValue(this.data ,CASE_FIELD); 
            this.subject="Low Survey Score related to Trainning   "+ getFieldValue(this.data ,RELATEDCONTACTNAME_FIELD);
        }
    
    this.installedProduct=getFieldValue(this.data ,INSTALLEDPRODUCT_FIELD);
    this.product=getFieldValue(this.data ,QSRPRODUCT_FIELD);
      
    }
   this.booShowForm=true;
   this.openmodel = true;
   this.modalClass = 'slds-modal slds-fade-in-open';
    this.modalBackdropClass = 'slds-backdrop slds-backdrop_open';     
}

//Close the Pop up on click of Cancel Button 
    closeModal() {
        this.openmodel = false;
        this.modalClass = 'slds-modal ';
    this.modalBackdropClass = 'slds-backdrop ';
    } 

//Submit the Form on click of Save button on UI												   
    saveMethod(event) {
        this.booShowForm=false;
        event.preventDefault(); // stop the form from submitting
         const fields = event.detail.fields;
        //fields.Qualtrics_Survey_Response__c=this.recordId;
         this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

/*Method to Handles when the Form submit is successfull. Assign's the New case Id to the Qualtrics Record
    Hiding the Modal and Navigate the User to the Newly Created Case */										

	handleSuccess(event){
        const caserecId = event.detail.id;
        console.log('onsuccess: ', caserecId);
        if(this.caseexist===false){
            let record = {
                        fields: {
                            Id: this.recordId,
                            Follow_Up_Case__c: caserecId,
                        
                        },
                    };
        this.closeModal();
        this.booShowForm=true;
        this.modalClass = 'slds-modal ';
        this.modalBackdropClass = 'slds-backdrop ';
        
        updateRecord(record)
        .then(() => {
            console.log(" Successfully Updated QSR record..");
            this.navigate(caserecId);
        })
        .catch(error => {
            console.log("Error Updating QSR record.."+error);
			  this.ShowTostMessage('Error',error,'error');
        });
    }else{
        this.closeModal();
        this.booShowForm=true;
        this.modalClass = 'slds-modal ';
        this.modalBackdropClass = 'slds-backdrop ';
       this.ShowTostMessage(this._title,this.message,this.variant);
    }

 
    }

    handleerror(event){
        this.booShowForm=true;
    }

 //Navigate the User to Case detail Page										   
    navigate(recid){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recid,
                objectApiName: 'Case', 
                actionName: 'view'
            }
        });
        this.booShowForm=true;
    }

   //to display the toast message
    ShowTostMessage(vartitle,varmessage,varvariant){
        const evt = new ShowToastEvent({
            title: vartitle,
            message: varmessage,
            variant: varvariant,
        });
        this.dispatchEvent(evt);

    }													
    

}
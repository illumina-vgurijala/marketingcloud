import { LightningElement,track,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';// DCP-49741, added:getFieldValue
import USER_ID from '@salesforce/user/Id';
import USERTYPE_FIELD from '@salesforce/schema/User.UserType';
import { updateRecord } from 'lightning/uiRecordApi';
import WO_REASON_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.Reason_for_Missing_Documentation__c';
import ID_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.Id';
import WO_RECORD_TYPE from '@salesforce/schema/SVMXC__Service_Order__c.RecordType.Name';
import FS_Record_Type from '@salesforce/label/c.WorkOrderRecordTypeFieldService';
import SS_Record_Type from '@salesforce/label/c.WorkOrderRecordTypeServiceSupport';
import IS_INSTALLATION_TYPE from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Order_Type__c';// DCP-49741
import {
    callServer,
    consoleLog,
    showSuccessToast
} from 'c/utils';


export default class DocumentUploadComp extends NavigationMixin(LightningElement) {
@api 
recordId;

@track 
isRequiredWoRecordType=true;
@track
Reason_for_Missing_Documentation__c;

@track
isportaluser=false;

@track docNameFromRow;
@track workdetailfieldSet;

@track error;

@track ReasonForMissingDocs;
@track showSpinner=false;

//To get installed product, product id and product group details of work order records
@wire(getRecord, { recordId: '$recordId', fields:[WO_REASON_FIELD,WO_RECORD_TYPE]})
    workOrderRecord({data, error}){
        if(data){
            this.ReasonForMissingDocs = data.fields.Reason_for_Missing_Documentation__c.value;
            if(data.recordTypeInfo.name!==FS_Record_Type && data.recordTypeInfo.name!==SS_Record_Type){
                this.isRequiredWoRecordType = false;
            }
        } else if(error){
            consoleLog("error === "+error);
        }
    }

//To update the field value Reason for missing documentation in object-start

    handleReasonChange(event) {
        // this.inputLabel = event.target.label;
        let inputVal = event.currentTarget.value;
        this.inputValue = event.target.value;
        if( this.inputValue !== null && this.inputValue !== undefined){            
            this.ReasonForMissingDocs = event.currentTarget.value;
        }
    }
    updateRFMDRecord() {
        // Create the recordInput object
        this.showSpinner=true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[WO_REASON_FIELD.fieldApiName] = this.ReasonForMissingDocs;
        const recordInput = { fields };

         callServer(updateRecord,recordInput,result => {
            showSuccessToast('Work Order updated with Reason for Missing Documentation');
            // Display fresh data in the form
            this.showSpinner=false;
            
        },error => {
            consoleLog('Error block:'+JSON.stringify(error.body))
            showErrorToast( error.body.message);
        });
        
            
    }
//To update the field value Reason for missing documentation in object-End

@wire(getRecord, { recordId: USER_ID, fields: [USERTYPE_FIELD] })
userrecord(result){
    if(result.data){
        consoleLog('USer-result.data:'+JSON.stringify(result.data));
        if(result.data.fields.UserType.value==='PowerPartner'){  
            this.isportaluser =true;       
            this.columnactionmap={"Click to attach":"Upload Document,138"};
            
        }
    }else if(result.error){
        consoleLog('Error:'+JSON.stringify(result));
    
    }
}

//Pooja: Start : DCP-49741: to Check if the work order type os Installation
@wire(getRecord, { recordId: '$recordId', fields:[IS_INSTALLATION_TYPE]}) workOrder;
get isInstallationType(){
    console.log('IS_INSTALLATION_TYPE-->',getFieldValue(this.workOrder.data, IS_INSTALLATION_TYPE));
    console.log('doc upload-->', (getFieldValue(this.workOrder.data, IS_INSTALLATION_TYPE) ==='Installation') ? true : false);
    return (getFieldValue(this.workOrder.data, IS_INSTALLATION_TYPE) ==='Installation') ? true : false;
}
//End : DCP-49741
    /**
     * Method: renderedCallback
     * Description: method will used to call the child JS method for getting the updated data.
     */
     renderedCallback(){
        this.template.querySelector('c-work-order-document-upload').refreshComponent();
    }
   
}
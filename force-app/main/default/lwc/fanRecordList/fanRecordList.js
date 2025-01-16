import { LightningElement,api,wire,track } from 'lwc';
import getwrapperList from '@salesforce/apex/FANRecordListController.getwrapperList';
import { NavigationMixin } from 'lightning/navigation';
import FAI_Object from '@salesforce/schema/Field_Action_Item__c';
import WORK_ORDER_FIELD from '@salesforce/schema/Field_Action_Item__c.Work_Order__c';
import CASE_FIELD from '@salesforce/schema/Field_Action_Item__c.Case__c';
import FAN_FIELD from '@salesforce/schema/Field_Action_Item__c.Field_Action_Notification__c';
import { createRecord } from 'lightning/uiRecordApi';
import {callServer,consoleLog,isNotNull,isNotBlank,showSuccessToast,showErrorToast} from 'c/utils';


export default class FanRecordList  extends NavigationMixin(LightningElement) {

@api recordId;
@api showPlusButton = false;
@track fanActionTitle = "Action";
@track fanIDTitle = "FAN ID";
@track fanSubjectTitle = "Subject";
@track showFanList;
@track records;
@track recid;
@track showPopUp = false;
@track top=50;
@track left=50;
@track fixedWidth = "width:3rem;";
@track impactedRecId;
@track fanHeader = "Potential Matched FAN Records";
@api workOrderId ;
@track disableButton = false;


/**
     * Method Name: renderedCallback
     * Params: None
     * Description: Related to pre populating result DataWrapper.To make Cmp visbile or not
     */
connectedCallback(){    
    this.extractRelatedFAN();
}

@api
extractRelatedFAN(){
    callServer(getwrapperList,{recordId: this.recordId},result => {       
        this.records = result; 
        if(result.length>0){ 
            this.showFanList ='true'; 
        } 
    },error => {
        
    });
}

get assignClass() { 
    return this.active ? '' : 'slds-hint-parent';
}

/**
     * Method Name: showData
     * Params: even
     * Description: On mouse-hover setting recid in order to show pop-up having information about  subject,status and customer messaging.
     */
showData(event){
   
    this.recid = event.currentTarget.dataset.rangerid;
    this.showPopUp = true;
    this.left = event.clientX;
    this.top=event.clientY;   
    for(let i = 0; i < this.records.length; i++) {
        let obj = this.records[i];
        if(this.recid === obj.fanId){                   
            this.impactedRecId = obj.impactedProductRecId;            
        }        
    }
}

/**
     * Method Name: hideData
     * Params: event
     * Description: On mouse-hover setting recid to null, to remove popoup from UI.
     */

hideData(event){
    this.recid = "";
    this.showPopUp = false;
}

/**
     * Method Name: handlefanClick
     * Params: event
     * Description: On click of hyperlink,navigate to record's view page.
     */
handlefanClick(event){
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: event.target.dataset.name,
            objectApiName: 'Field_Action_Notification__c',
            actionName: 'view'
        }
    });
   


}
createFAI(event) {
   // this.showSpinner = true;
    this.disableButton = true;
    let fanId  = event.currentTarget.dataset.label;
     const fields = {};
     if(isNotNull(this.caseIPId) && isNotBlank(this.workOrderId)){
       fields[WORK_ORDER_FIELD.fieldApiName] = this.workOrderId;
     }
     fields[CASE_FIELD.fieldApiName] = this.recordId;
     fields[FAN_FIELD.fieldApiName] = fanId;
     const recordInput = { apiName: FAI_Object.objectApiName,
         fields };
    createRecord(recordInput)
        .then(fan => { // fan is return for success 
        consoleLog(fan);
            this.showSpinner = false
            showSuccessToast('Field Action Item created');
            this.showFanList = false;
        })
        .catch(error => {
        this.disableButton = false;
        consoleLog(error);
        showErrorToast('Error creating record');
    });
 }

/*dynamic css */
get boxClass() { 
    return `position: fixed;overflow:hidden; background-color:white; top:${this.top-100}px; left:${this.left+10}px`;
  }

}
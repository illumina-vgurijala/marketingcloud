import { api, LightningElement,track, wire } from 'lwc';
import { getObjectInfo,getPicklistValues } from 'lightning/uiObjectInfoApi';
import QUALITY_RECORD_OBJECT from '@salesforce/schema/Quality_Record__c';
import SOURCE from '@salesforce/schema/Quality_Record__c.Source__c';
import createQR from '@salesforce/apex/EtQComponentController.createQR';
import createQualityRecordJuntions from '@salesforce/apex/EtQComponentController.createQualityRecordJuntions';
import {isNotNull,isBlank,showSuccessToast,showErrorToast } from 'c/utils';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and provides creation functionality for QI Records from SFDC
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
* Abhinav             15-Apr-2022                 QACM-648 Enhancement- Header Update on HTML
*/

export default class CreateQiComponent extends LightningElement {

@api objectApiName;
@api blnCloseModalState = false;
@track btnDisabled = false;
@track etNum = '';
@track sourceSelected ='';
@api parentRecordId;
@track sourceType = []


@wire(getObjectInfo, { objectApiName: QUALITY_RECORD_OBJECT })
qrMetadata;

/**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Wired method to fetch the 'Source' picklist field values and display
    */
@wire(getPicklistValues, {recordTypeId: '$qrMetadata.data.defaultRecordTypeId',fieldApiName: SOURCE})
 qrPicklist({error,data}){
     if(isNotNull(data)){
         this.sourceType = data.values;
     }
 }


connectedCallback(){
    this.btnDisabled = true;
}

    /*get options() {
        return source;
    }*/

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to close the modal when close button is clicked
    */
    closeModal(){
        if(!this.blnCloseModalState){
            this.blnCloseModalState = true;
            const closeModalEvent = new CustomEvent("closemodalevent", {
              });
              this.dispatchEvent(closeModalEvent);
        }
        
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to create QR record in SFDC
    */
    apexCallout(){
        let tempstr = '';
        let qrStatus = 'QI Creation Initiated';
        createQR({
            etqNumber: tempstr,
            lookupIds: this.parentRecordId,
            objectName: this.objectApiName,
            source: this.sourceSelected,
            url: tempstr,
            status: qrStatus,
            problemTitle : tempstr,
            recordType : 'QI'
        })
        .then((result)=>{
            this.qrCreated();
            if(isNotNull(result)){
                this.createJunctionRecord(result.Id,this.parentRecordId,this.objectApiName);
                showSuccessToast('Quality Record created successfully');
                this.closeModal();
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
        
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to create QRJ record when QR is successfully created
    */
    createJunctionRecord(recId, lookupId, objApi){
        let qrjStatus = 'QI Created';
        createQualityRecordJuntions({
            qualityRec: recId,
            lookupIds: lookupId,
            objectName: objApi,
            status: qrjStatus
        })
        .then((result)=>{
            if(isNotNull(result)){
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

    handleSourceChange(event){
        this.sourceSelected = event.detail.value;
        this.saveBtnVisibility();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to validate the disabled state of Create Button
    */
    saveBtnVisibility(){
        if(isBlank(this.sourceSelected)){
            this.btnDisabled = true;
        }
        else{
            this.btnDisabled = false;
        }
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Event method when create button is clicked and CustomEvent is sent to parent component to refresh the existing linked records table.
    */
    qrCreated(){
        const clickEvent = new CustomEvent('createclick',{
            detail:{
                linkClicked: true
            }
        });
        this.dispatchEvent(clickEvent);
    }

}
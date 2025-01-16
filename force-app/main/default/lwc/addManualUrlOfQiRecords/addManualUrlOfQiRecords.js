import { LightningElement,api,track } from 'lwc';
import createQrjCallout from '@salesforce/apex/EtQComponentController.createQrjCallout';
import createQR from '@salesforce/apex/EtQComponentController.createQR';
import createQualityRecordJuntions from '@salesforce/apex/EtQComponentController.createQualityRecordJuntions';
import checkIfAlreadyLinked from '@salesforce/apex/EtQComponentController.checkIfAlreadyLinked';
import fetchQualityRecord from '@salesforce/apex/EtQComponentController.fetchQualityRecord';
import {isNotNull,isBlank,showErrorToast,showSuccessToast } from 'c/utils';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and contains a modal to create QR record using EtQ URL
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
* Abhinav             22-Apr-2022                 QACM-591 Removed QI Type Selection from the functionality
* Abhinav             22-Apr-2022                 QACM-700 Enhancement - SAP NCR URL
*/

export default class AddManualUrlOfQiRecords extends LightningElement {

@track manualClicked = false;
@api parentRecordId;
@track etqURL="";
@track objData;
@track btnDisabled = false;
@api objectApiName;
@track showSpinner = false;
@track qnNum = '';
@track isQiExisting = false;
@track isQiLinked = false;
@track qrId = '';

    connectedCallback(){
        this.btnDisabled = true;
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  Method to close the modal
    */
    closeModal(){
        const closeModalEvent = new CustomEvent("closemodalevent3", {
        });
        this.dispatchEvent(closeModalEvent);
    }

    handleUrlChange(event){
        this.etqURL = event.detail.value;
        this.saveBtnVisibility();
    }

    handleQIChange(event){
        this.qiType = event.detail.value;
        this.saveBtnVisibility();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to check the applicability of the URL and create QR/QRJ or show error based on URL
    * @Modification Updated for QACM-700 enhancement
    */
    apexCallout(){
        this.showSpinner = true;
        let isNcr = this.etqURL.includes('/QNInitiate/');
        if(isNcr){
            this.qnNum = 'QN-'+this.etqURL.split('/QNInitiate/')[1];
            this.checkIfRecordExists(this.qnNum);
            window.clearTimeout(this.delayTimeout);
            this.delayTimeout = setTimeout(() => {
                if(this.isQiExisting){
                    this.checkIfLinked(this.qrId,this.parentRecordId,this.objectApiName);
                    window.clearTimeout(this.delayTimeout);
                    this.delayTimeout = setTimeout(() => {
                        if(this.isQiLinked){
                            this.showSpinner = false;
                            showErrorToast('Quality Record is already linked to the Case/FAN record');
                        }
                        else{
                            this.createJunctionRecord(this.qrId,this.parentRecordId,this.objectApiName);
                            this.delayTimeout = setTimeout(() => {
                                this.linkClicked();
                                this.showSpinner = false;
                            },2000);
                        }
                    },2000);
                }
                else{
                    this.sapNcrCallout(this.etqURL);
                }
            },2000);
        }
        else{
            this.createManualQI();
        }
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  Method to create QR and QRJ when url includes other than 'QNInitiated' -- existing functionality based on QACM-14
    * @Modification Updated for QACM-700 enhancement
    */
    createManualQI(){
        createQrjCallout({
                etqUrl: this.etqURL,
                objApiName: this.objectApiName,
                lookupId: this.parentRecordId
            })
            .then((result)=>{
                this.showSpinner = false;
                if(isNotNull(result)){
                    if(result.status===1){
                        showErrorToast(result.message);
                        
                    }
                    else if(result.status===0){
                        showSuccessToast(result.message);
                        this.closeModal();
                    }
                    this.manualCreated();
                    
                }
            })
            .catch((error)=>{
                showErrorToast(error.body.message);
            });
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to update disabled state of 'Save' button based on URL entered
    */
    saveBtnVisibility(){
        if(isBlank(this.etqURL)){
            this.btnDisabled = true;
        }
        else{
            this.btnDisabled = false;
        }
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to send CustomEvent when QR is created from Manual URL to parent component to update the existing linked record.
    */
    manualCreated(){
        const clickEvent = new CustomEvent('manualclick',{
            detail:{
                linkClicked: true
            }
        });
        this.dispatchEvent(clickEvent);
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  QACM-700 Method to check if QR already exists when the URL contains QNInitiated
    */
    checkIfRecordExists(etqNo){
        fetchQualityRecord({
            etqNum: etqNo
        })
        .then((result)=>{
            if(result.length>0){
                this.isQiExisting=true;
                this.qrId = result[0].Id;
            }
            else{
                this.isQiExisting=false;
                this.qrId = '';
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  QACM-700 Method to check if QR is already linked to Case the URL contains QNInitiated
    */
    checkIfLinked(recId, lookupId, objApi){
        checkIfAlreadyLinked({
            qualityRec: recId,
            lookupIds: lookupId,
            objectName: objApi
        })
        .then((result)=>{
            if(isNotNull(result)){
                this.isQiLinked = result;
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  QACM-700 Method to create QR when the URL contains QNInitiated
    */
    sapNcrCallout(etqUrl){
        
        let tempstr = '';
        createQR({
            etqNumber: this.qnNum,
            lookupIds: this.parentRecordId,
            objectName: this.objectApiName,
            source: tempstr,
            url: etqUrl,
            status: tempstr,
            problemTitle : tempstr,
            recordType : 'Other'
        })
        .then((result)=>{
            this.showSpinner = false;
            if(isNotNull(result)){
                this.createJunctionRecord(result.Id,this.parentRecordId,this.objectApiName);                
                this.closeModal();
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

    /**
    * @author abhinav
    * @date   22-Apr-2022
    * @description  QACM-700 Method to create QRJ when the URL contains QNInitiated
    */
    createJunctionRecord(recId, lookupId, objApi){
        let qrjStatus = 'Manual Link';
        createQualityRecordJuntions({
            qualityRec: recId,
            lookupIds: lookupId,
            objectName: objApi,
            status: qrjStatus
        })
        .then((result)=>{
            this.showSpinner = false;
            this.manualCreated();
            this.closeModal();
            if(isNotNull(result)){
                showSuccessToast('Quality Record linked successfully');
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

}
import { LightningElement,api,track } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getLinkedQualityRecords from '@salesforce/apex/EtQComponentController.getLinkedQualityRecords';
import delinkQRJ from '@salesforce/apex/EtQComponentController.delinkQRJ';
import checkIfManuallyLinked from '@salesforce/apex/EtQComponentController.checkIfManuallyLinked';
import deleteManualQrj from '@salesforce/apex/EtQComponentController.deleteManualQrj';
import {isNotNull,isBlank,showErrorToast,showSuccessToast } from 'c/utils';

/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 This component is created under QACM-14 and the displays the searched QR records on the search screen 
                    and provides linking functionality or QI records to Case/FAN
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
* Abhinav             19-Apr-2022                 QACM-652 Enhancement - Add delinking/delete functionality for Manually Create QI Records
* Abhinav             04-May-2022                 Codescan issue fixes
*/

const columns = [
    { label: 'Quality Record ID', fieldName: 'etq_url', type: 'url',
    typeAttributes: {
        label: {
            fieldName: 'EtQ_Number__c'
        }
    } },
    { label: 'Problem Title', fieldName: 'Problem_Title__c' }
];

export default class DisplayExistingQiRecords extends LightningElement {

    @api objectApiName;
    @api recordId;
    @api parentRecordId;
    @api prev;
    @track hidecol = false;

    @api linkClicked;
    @api linkVal;
    @track keys = [];
    @track finalList1 = [];
    columns = columns;

    columnRendered = false;

    @track recAvlbl = false;
    @track noRecords = false;
    @track noOfRecords = 0;

    @track hasRendered = 0;

    connectedCallback(){
        this.displayLinkedQI();
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Push the Delink button column based on profiles data recieved from parentEtqComponent
    */
    renderedCallback(){
        this.columns=columns;
        this.updateColumnRendered();
        if(this.linkVal){
            this.recAvlbl=false;
            this.displayLinkedQI();
        }
    }

    /**
    * @author abhinav
    * @date   04-May-2022
    * @description  Push the Delink button column based on profiles data recieved from parentEtqComponent
    */
    updateColumnRendered(){
        if(this.hasRendered===1 && this.prev && !this.columnRendered && this.columns.length===2){
            this.columnRendered=true;
            this.columns.push({type: "button", typeAttributes: {  
                label: 'Delink',  
                name: 'Delink',  
                title: 'Delink',  
                disabled: {fieldName:'Btn_Status'},  
                value: 'Delink',  
                iconPosition: 'center'  
            }});
        }
    }

    /**
    * @author abhinav
    * @date   04-May-2022
    * @description  Delink button usability based on the QI and QRJ statuses
    */
    checkEtQIntegrationStatus(status,qiStatus){
        let btStatus = true;
        if(status==='Manual Link' || status==='Linked Successfully' || (status==='QI Created' && qiStatus==='QI Creation Successful')){
            btStatus = false;
        }
        return btStatus;
    }

    /**
    * @author abhinav
    * @date   04-May-2022
    * @description  Populate EtQ Number based on the QI Record
    */
    populateEtQNumber(etqNum){
        let result = "";
        if(isBlank(etqNum)){
            result = "Pending";
        }
        else{
            result = etqNum;
        }
        return result;
    }

    /**
    * @author abhinav
    * @date   04-May-2022
    * @description  Populate EtQ URL based on the QI Record
    */
    populateEtQURL(etqUrl){
        let url="";
        if(!isBlank(etqUrl)){
            url = etqUrl;
        }
        else{
            url = "Pending";
        }
        return url;
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  API enabled method to fetch the existing linked QI records for the Case/FAN
    */
    @api displayLinkedQI(){
        let start = Date.now();
        let strDate = start.toString();
        getLinkedQualityRecords({
            recId: this.parentRecordId,
            objName: this.objectApiName,
            nowTime: strDate
        })
        .then((result) => {
            if(isNotNull(result)){
                this.totalRecordCount = result.length;
                this.finalList1=[];
                this.columns=columns;
                if(this.totalRecordCount===0){
                    this.noRecords = true;
                    this.recAvlbl = false;
                }
                else{
                    this.noRecords = false;
                    
                    for(let i in result){
                        
                        if(result[i].hasOwnProperty('Quality_Record__r')){
                            let finalData={};
                        let qi = result[i].Quality_Record__r;
                        finalData["Id"] = result[i].Id;

                        finalData["etq_url"] = this.populateEtQURL(qi.External_URL__c);
                        
                        finalData["Problem_Title__c"] = qi.Problem_Title__c;
                        finalData["Sites_Impacted__c"] = qi.Sites_Impacted__c;

                        finalData["EtQ_Number__c"] = this.populateEtQNumber(qi.EtQ_Number__c);
                        
                        finalData["EtQ_Integration_Status__c"] = result[i].EtQ_Integration_Status__c;
                        
                        //setting the button disabled status based on the status of the Quality Record Junction
                        //finalData["Btn_Status"] = true;
                        finalData["Btn_Status"] = this.checkEtQIntegrationStatus(result[i].EtQ_Integration_Status__c,qi.EtQ_Integration_Status__c);
                        
                        //Push the Delink button column based on profiles data recieved from parentEtqComponent
                        this.hasRendered += 1;
                        this.updateColumnRendered();
                        this.finalList1.push(finalData);
                        }
                    }
                    this.recAvlbl = true;
                     this.template.querySelector("c-data-table-lazy-load").resetTable(this.finalList1);
                }
            }
            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch((error) => {
            console.log('existing error: '+JSON.stringify(error));
            showErrorToast(error.body.message);
        });
        this.linkVal = false;
    }

     /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Event method when delink button is clicked
    */
    callRowActionExisting(event){
        const recid = event.detail.value.Id;
        this.delinkQRJRec(recid);
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method call when the delink button is clicked
    */
    delinkQRJRec(id){
        checkIfManuallyLinked({qrjId: id})
        .then((result) => {
            if(isNotNull(result)){
                if(result){
                    //delete qrj record if the QR record is manually created from SFDC with no callback required
                    this.deleteQrj(id);
                }
                if(!result){
                    //set the status of QR record to 'Delink Initiated' for callback
                    this.delinkQrj(id);
                }
            }
        })
        .catch((error) => {
            showErrorToast(error.body.message);
        });        
    }


    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to delete the manually created QRJ record in SFDC
    */
    deleteQrj(id){
        deleteManualQrj({qrjId:id})
        .then((result)=>{
            if(isNotNull(result)){
                if(result){
                    showSuccessToast('Quality Record delinked successfully');
                    window.clearTimeout(this.delayTimeout);
                            this.delayTimeout = setTimeout(() => {
                                this.displayLinkedQI();
                            },3000);
                }
                else{
                    showErrorToast('Quality Record delink failed');
                }
            }   
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        })
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to initiate the delink of Linked QR record which is not manually created.
    */
    delinkQrj(id){
        delinkQRJ({qrjId: id})
                    .then((result) => {
                        if(isNotNull(result)){
                        }
                        showSuccessToast('Delink Initiated for the Quality Record Link');
                        window.clearTimeout(this.delayTimeout);
                            this.delayTimeout = setTimeout(() => {
                                this.displayLinkedQI();
                            },3000);
                        
                    })
                    .catch((error) => {
                        showErrorToast(error.body.message);
                    });
    }

}
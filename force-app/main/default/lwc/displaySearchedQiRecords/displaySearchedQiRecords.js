import { LightningElement,track,api } from 'lwc';
import searchQiRecords from '@salesforce/apex/EtQComponentController.searchQiRecords';
import createQualityRecordJuntions from '@salesforce/apex/EtQComponentController.createQualityRecordJuntions';
import checkIfAlreadyLinked from '@salesforce/apex/EtQComponentController.checkIfAlreadyLinked';
import {isNotNull,isBlank,showErrorToast,showSuccessToast  } from 'c/utils';

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
* Abhinav             19-Apr-2022                 Enhancement and Bug fixes QACM-674,QACM-671,QACM-651
*/

const columns = [
    { label: 'Problem Title', fieldName: 'Problem_Title__c' },
    { label: 'Sites Impacted', fieldName: 'Sites_Impacted__c'},
    { label: 'EtQ Number', fieldName: 'EtQ_Number__c'},
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date-local'},
    { label: 'Previous Related FAN or Case', fieldName: 'Recent'},
    {type: "button", typeAttributes: {  
        label: 'Link',  
        name: 'Link',  
        title: 'Link',  
        disabled: {fieldName:'Btn_Status'},  
        value: 'Link',  
        iconPosition: 'left'  
    }}
];

export default class DisplaySearchedQiRecords extends LightningElement {

    @api objectApiName;
    @api recordId;
    @api parentRecordId;

    columns = columns;
    @track finalList = [];
    @track dataList = [];
    @track hidecol = false;

    @track recAvlbl = false;
    @track noRecords = false;
    records;
    @track showSpinner = false;

    @api problemVal;
    @api sitesVal;
    @api numberVal;
    @api dateVal;

    @track prob = this.problemVal;
    @track sites = this.sitesVal;
    @track num = this.numberVal;
    @track dte = this.dateVal;

    @track rerender = false;
    @track colRender = false;

    @track data = [];
    @track totalRecordCount = 0;

    @track isQiLinked;

    connectedCallback(){
        //add the current phase column based on the object api name
        this.columns=columns;
        if(this.objectApiName==='Case' && this.columns.length===6){
            let currPhase = {label: 'Current Phase',fieldName: 'Current_Phase__c'};
            this.columns.splice(5,0,currPhase);
        }
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to display the searched QI records
    */
    @api reloadTable(problemTitleParam,sitesImpactedParam,etqNumberParam,createdDateParam){
        searchQiRecords({
            problemTitle: problemTitleParam,
            sitesImpacted: sitesImpactedParam,
            etqNumber: etqNumberParam,
            createdDate: createdDateParam
        })
        .then((result)=>{
            if(isNotNull(result)){
                let data = result;
                this.recAvlbl = false;
                this.noRecords = false;
                this.totalRecordCount = 0;
                this.finalList = [];
                this.dataList = [];
                this.rerender = false;
                if(isNotNull(data)){
                    this.totalRecordCount = data.length;
                    if(this.totalRecordCount===0){
                        this.noRecords = true;
                    }
                    else{
                        this.records = data;
                        for(let i in data){
                            let finalData={};
                            finalData["Id"] = data[i].Id;
                            finalData["Problem_Title__c"] = data[i].Problem_Title__c;
                            finalData["Sites_Impacted__c"] = data[i].Sites_Impacted__c;
                            finalData["EtQ_Number__c"] = data[i].EtQ_Number__c;

                            finalData["CreatedDate"] = this.setCreatedDate(data[i].EtQ_Created_Date__c);

                            finalData["Btn_Status"] = false;
                            finalData["Current_Phase__c"] = data[i].Current_Phase__c;
                            //check if the QI record is linked to any other Case/FAN
                            if(data[i].hasOwnProperty('Quality_Record_Junctions__r')){
                                let childObj = data[i].Quality_Record_Junctions__r;
                                finalData["Recent"] = '';
        
                                for(let j in childObj){
                                    //check if the QI record is linked to any other Case and append the Case number
                                    if(childObj[j].hasOwnProperty('Case__r')){
                                        let case1 = childObj[j].Case__r;
                                        let caseNum = '';
                                        if(finalData["Recent"].length===0){
                                            caseNum = 'CASE-'+case1.CaseNumber;
                                        }
                                        else{
                                            caseNum = ',CASE-'+case1.CaseNumber;
                                        }
                                        finalData["Recent"] += caseNum;
                                        if(this.parentRecordId === case1.Id){
                                            finalData["Btn_Status"] = true;
                                        }
                                    }
                                    else if(childObj[j].hasOwnProperty('Field_Action_Notification__r')){
                                        //check if the QI record is linked to any other FAN and append the FAN number
                                        let fan1 = childObj[j].Field_Action_Notification__r;
                                        let fan = '';
                                        if(finalData["Recent"].length===0){
                                            fan = fan1.Name;
                                        }
                                        else{
                                            fan = ','+fan1.Name;
                                        }
                                        finalData["Recent"] += fan;
                                        if(this.parentRecordId === fan1.Id){
                                            finalData["Btn_Status"] = true;
                                        }
                                    }
                                }
                                
                            }
                            this.finalList.push(finalData);
                        }
                        this.rerender = true;
                        this.dataList = this.finalList;
                        this.recAvlbl = true;
                        this.template.querySelector("c-data-table-lazy-load").resetTable(this.dataList);
                    }
                }
            }
        })
        .catch((error)=>{
            console.log('search err:'+JSON.stringify(error));
            showErrorToast(error.body.message);
        });
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Event method when link button is clicked on a QI record
    */
    callRowAction(event){
        const recId =  event.detail.value.Id;
            this.checkIfLinked(recId,this.parentRecordId,this.objectApiName);
            this.showSpinner=true;
            window.clearTimeout(this.delayTimeout);
            this.delayTimeout = setTimeout(() => {
                if(this.isQiLinked){
                    showErrorToast('The Quality Record you are selecting is already linked to the Case/FAN');
                }
                else if(!this.isQiLinked){
                    //create junction record
                    this.createJunctionRecord(recId,this.parentRecordId,this.objectApiName);
                    window.clearTimeout(this.delayTimeout);
                    this.delayTimeout = setTimeout(() => {
                        this.linkClicked();
                    },2000);
                }
                this.showSpinner = false;
            }, 3000);

    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Method to check if the QI record to be linked is already linked to the Case/FAN or not
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
    * @date   25-Mar-2022
    * @description  Method to create QRJ record when link button is clicked 
    */
    createJunctionRecord(recId, lookupId, objApi){
        let qrjStatus = 'Link Initiated';
        createQualityRecordJuntions({
            qualityRec: recId,
            lookupIds: lookupId,
            objectName: objApi,
            status: qrjStatus
        })
        .then((result)=>{
            if(isNotNull(result)){
                showSuccessToast('Quality Record link initiated successfully.');
            }
        })
        .catch((error)=>{
            showErrorToast(error.body.message);
        });
    }

    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Event method when link button is clicked and CustomEvent is sent to parent component to refresh the existing linked records table.
    */
    linkClicked(){
        const clickEvent = new CustomEvent('linkclick',{
            detail:{
                linkClicked: true
            }
        });
        this.dispatchEvent(clickEvent);
    }

    /**
    * @author abhinav
    * @date   04-May-2022
    * @description  Populate EtQ Created Date based on the QI Record
    */
    setCreatedDate(dateStr){
        let dateVal = ""
        if(!isBlank(dateStr)){
            dateVal = dateStr.substring(0,10);
        }
        return dateVal;
    }


}
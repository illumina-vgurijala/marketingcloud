import {
    LightningElement,
    api,
    track
} from 'lwc';
import {    
    consoleError,
    callServer,
    consoleLog
} from 'c/utils';
import getLineItemForAgreement from '@salesforce/apex/ApttusAgreementLineItemViewerController.getRecords';
import getrecord from '@salesforce/apex/ApttusAgreementLineItemViewerController.getAgreement';
import filterRecord from '@salesforce/apex/ApttusAgreementLineItemViewerController.getFilterRecords';
import channelpartnerrecordtype from '@salesforce/label/c.UI_Label_Channel_Partner_Agreement';
import labelLimitCount from '@salesforce/label/c.LabelViewLinesLimit';

import {
    columnsNotCP,
    columnsIsCP
} from './column.js';

export default class Lwcdatatbleex extends LightningElement {
       
    @api recordId;    
    @api agreementId;
    @api hideColumn = false;  
    @track data=[];    
    @track lstAgreementLinesAvailableFilteredSet = [];    
    @track listTempNextRecords = [];    
    @track columnsNotCP = columnsNotCP;
    @track columnsIsCP = columnsIsCP ;    
    agreementName = '';
    agreementNo = '';
    agreementRecordurl;
    isChannelPartnerType=false;    
    loadData = false;      
    strSearchKey;      
    offset ='100';    
    limitCount= parseInt(labelLimitCount, 10);        
    
    connectedCallback(){           
        this.initializeData();
    }

    //Initial Data Load Method
    initializeData(){        
        this.loadData =false;                       
        callServer(getrecord,{},result =>{                                              
            this.recordId=result.Id;
            let recordtype=result.RecordType.DeveloperName;
            this.agreementrec=result;
            this.agreementName=this.agreementrec.Name;
            this.agreementNo=this.agreementrec.Apttus__FF_Agreement_Number__c; 
            this.enableinfinityLoad = true;           
            let sfdcBaseURL = window.location.origin;
            this.agreementRecordurl=sfdcBaseURL+'/'+this.recordId;              
            this.nextrecords();                                  
            if(recordtype===channelpartnerrecordtype){                
                this.isChannelPartnerType=true;                
            }else{
                this.isChannelPartnerType=false;
            }                                               
        }, error => {
            consoleError('error ',JSON.stringify(error));
        });
    }

    searchKeyword(event) {
        this.strSearchKey = event.target.value.toLowerCase();
        if(this.strSearchKey===''){
            consoleLog('limitCountsearchkey==>'+this.limitCount);  
            this.handleSearch();
        }
    }

    handleSearch() {        
        this.loadData = false;                
        this.lstAgreementLinesAvailableFilteredSet = [];         
        consoleLog('limitCounthandlesearch==>'+this.limitCount);  
        callServer(filterRecord,{
            agreementId:this.recordId,
            searchKey:this.strSearchKey,
            limitCount : this.limitCount
            },result =>{
                this.listTempNextRecords  = [];
                let resultLineItem = JSON.parse(result);
                this.listTempNextRecords =resultLineItem.listAgreementLineItems;                                  
                this.lstAgreementLinesAvailableFilteredSet.push(...this.listTempNextRecords); 
                consoleLog('hasMoreLinesOnSearch==>'+resultLineItem.hasMoreLines);                   
                if(resultLineItem.hasMoreLines === 'yes'){                                        
                    this.limitCount = this.limitCount+parseInt(labelLimitCount, 10);                
                    this.handleSearch();
                }else{
                    consoleLog('allRecordsOnSearch==>'+this.lstAgreementLinesAvailableFilteredSet.length);  
                    this.limitCount = parseInt(labelLimitCount, 10);             
                    this.enableinfinityLoad = true;                    
                    this.loadData = true;                       
                }
        }, error => {
            consoleError('error ',JSON.stringify(error));
        });                   
    }
    
    nextrecords(){
        consoleLog('limitCountOnLoad==>'+this.limitCount);  
        callServer(getLineItemForAgreement,{
            agreementId : this.recordId,
            limitCount : this.limitCount
        },resultLineItemResult =>{  
            this.listTempNextRecords  = [];
            let resultLineItem = JSON.parse(resultLineItemResult);     
            this.listTempNextRecords =resultLineItem.listAgreementLineItems;                                  
            this.lstAgreementLinesAvailableFilteredSet.push(...this.listTempNextRecords);  
            consoleLog('hasMoreLinesOnSearch==>'+resultLineItem.hasMoreLines);                              
            if(resultLineItem.hasMoreLines === 'yes'){
                this.limitCount = this.limitCount+parseInt(labelLimitCount, 10);                
                this.nextrecords();
            }else{  
                consoleLog('allRecordsOnLoad==>'+this.lstAgreementLinesAvailableFilteredSet.length);  
                this.limitCount = parseInt(labelLimitCount, 10);                           
                this.enableinfinityLoad = true;                    
                this.loadData = true;                       
            }           
        }, error => {
            consoleError('error ',JSON.stringify(error));
        });  
    }
}
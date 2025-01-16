import { LightningElement,wire,api,track } from 'lwc';
import initRecord from '@salesforce/apex/WorkOrderDocumentUploadController.initRecord';
import getDocumentName from '@salesforce/apex/WorkOrderActivityRulesSelector.getWorkOrderActivityRuleById';
import getInstalledProductId from '@salesforce/apex/WorkOrderDocumentUploadController.getInstalledProductId';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERTYPE_FIELD from '@salesforce/schema/User.UserType';
import { refreshApex } from '@salesforce/apex';
import {
    callServer,
    consoleLog
   
} from 'c/utils';
import {tableColumns, tableColumnsforUploadedFiles} from './column.js';

export default class WorkOrderDocumentUpload extends NavigationMixin(LightningElement){
    @api recordId;
    @track records;
    @track uploadedrecords;
    @track docNameFromRow;
    @track error;
    @track productId;
    @track isportaluser=false;
    @track columns ;
    @track columnsforuploadedFiles ;
    @track afterRenderLength;
    @track beforeRenderLength;

    @wire(getInstalledProductId , {recordId: '$recordId'})
    getProductId({error,data}){
        if(data){
            this.productId=data;
        }
    }

    
@wire(getRecord, { recordId: USER_ID, fields: [USERTYPE_FIELD] })
userrecord(result){
    if(result.data){
        if(result.data.fields.UserType.value==='PowerPartner'){  
            this.isportaluser =true;           
        }
    }else if(result.error){
        consoleLog('Error:'+JSON.stringify(result));
   
    }
}
    connectedCallback(){
        this.columns=tableColumns;
        this.columnsforuploadedFiles=tableColumnsforUploadedFiles;
        this.serverCall();
    }
    /**
     * Method:renderedCallBack
     * Description: Method will be called after the refreshComponent method and will be stopped if there is no change between the documents count by using beforeRenderCount & afterRenderCount variables.
     */
     renderedCallback(){
        if(this.afterRenderLength !== undefined && this.beforeRenderLength !== undefined && this.afterRenderLength !== this.beforeRenderLength){
            this.beforeRenderLength = this.afterRenderLength;
            // use the existing resetTable method to reset the values
            if(this.template.querySelector('c-data-table-lazy-load')) {
                this.template.querySelector('c-data-table-lazy-load').resetTable(this.records);
                this.template.querySelectorAll('c-data-table-lazy-load')[1].resetTable(this.uploadedrecords);
            }
        }
        
    }
    /**
     * Method: refreshComponent
     * Description: Call this api method directly from the parent component to render this component and capture the old documents count (as it will fire before rendercallback)
     */
    @api
    refreshComponent(){
        this.serverCall();
        if(this.records){
            this.beforeRenderLength = this.records.length;
        }    
    }
    /**
     * Method: serverCall
     * Description: method to do the server call.
     * Need to assign the values to the array by using the ES6 spread operator otherwise it will not detect the change.
     */
    serverCall(){
        callServer(initRecord,{recordId: this.recordId},result => {
            let records = [];  
            result.lstDataWrapperforfileupload.forEach(record => {               
                let preparedRecord = {};
                preparedRecord.documentName = record.documentName;              
                preparedRecord.documentNumber = record.documentNumber;
                preparedRecord.documentUploaded = record.documentUploaded;
                preparedRecord.ActivityType = record.ActivityType;
                preparedRecord.fileType = record.fileType;
                preparedRecord.id = record.id;
                preparedRecord.versionId = record.versionId;
                records.push(preparedRecord);
            });
            this.records = [...records];      
            let uploadRecords = [];
            result.lstDataWrapperforfiledisplay.forEach(record => {               
                let preparedRecord = {};
                preparedRecord.documentName = record.documentName;              
                preparedRecord.documentNumber = record.documentNumber;
                preparedRecord.documentUploaded = record.documentUploaded;
                preparedRecord.ActivityType = record.ActivityType;
                preparedRecord.fileType = record.fileType;
                preparedRecord.id = record.id;
                preparedRecord.versionId = record.versionId;
                uploadRecords.push(preparedRecord);
            });
            this.uploadedrecords = [...uploadRecords];
            if(this.records){
                this.afterRenderLength = this.records.length;
            }
            
        },error => {
            
        });
    }
    handleFileUpload(event){
        const recId =  event.detail.value; 
        const searchRowId = recId.id; 

        callServer(getDocumentName,{ recId:searchRowId },result => {
            this.docNameFromRow = result.Document_Name__c;
            console.log('docNameFromRow--',this.docNameFromRow);
            this.error = undefined;
            this.template.querySelector('c-upload-attachement').handleuploadevent2(this.recordId,this.docNameFromRow,this.productId);
           // this.refreshData();
            
        },error => {
            this.error = error;
            this.docNameFromRow = undefined;
        });
        
    }

    handleFileViewevent(event){
        consoleLog('here..');
        const rec =  event.detail.value; 
        const versionId = rec.versionId; 
        consoleLog('versionId..'+versionId);
        if(this.isportaluser){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    pageName: 'filePreview',
                    recordId: versionId,
                    objectApiName: 'ContentVersion',
                    actionName: 'view',
                },
                state : {
                    selectedRecordId: versionId
                }
            });
        }else{
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state : {
                    selectedRecordId: versionId
                }
            });
        }
    }
    // in order to refresh your data, execute this function:
    refreshData(event) {
        consoleLog('inside handler');
        callServer(initRecord,{recordId: this.recordId},result => {
            this.records = result.lstDataWrapperforfileupload;
            this.uploadedrecords=result.lstDataWrapperforfiledisplay;
            
        },error => {
            
        });
        
    }

     
}
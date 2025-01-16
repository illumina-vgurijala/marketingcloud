import { LightningElement,api,track } from 'lwc';
import getObjectHistoryData from '@salesforce/apex/ACRHistoryTrackingRelatedListController.getObjectHistoryData';
import {    
    callServer,
    consoleLog
} from 'c/utils';

export default class aCRHistoryTrackingRelatedList extends LightningElement {
    @api recordId;
    @api acrId; 
    @track searchData;    
    @track columns = [
    {
        label: 'Date',
        fieldName: 'Date__c',
        type: 'date',
        typeAttributes: {
            month: 'numeric',
            day: 'numeric',            
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',            
            hour12: true
          },
        sortable: true
    },
    {
        label: 'Field',
        fieldName: 'Field__c',
        type: 'text',
        sortable: true
    },
    {
        label: 'User', fieldName: 'Userurl', type: 'url',
        typeAttributes: {
            label: { 
                fieldName: 'UserName' 
            },
            target : '_blank'
        },
        sortable: true
    },
    {
        label: 'Original Value',
        fieldName: 'Original_Value__c',
        type: 'text',
        sortable: true
    },
    {
        label: 'New Value',
        fieldName: 'New_Value__c',
        type: 'text',
        sortable: true
    },                                     
];
    
    connectedCallback(){                
        callServer(getObjectHistoryData,{
            recordId : this.acrId
        }, result => {                      
                /* Prepare the Org Host */
                let baseUrl = 'https://'+location.host+'/';
                result.forEach(caseRec => {                    
                    caseRec.UserName = caseRec.User__r.Name;
                    /* Prepare Contact Detail Page Url */
                    caseRec.Userurl = baseUrl+caseRec.User__c;                                        
                });  
                this.searchData = result;                    
            }, error => {                
                consoleLog('Error ---> ', error);                
            }            
        );          
                         
    }


}
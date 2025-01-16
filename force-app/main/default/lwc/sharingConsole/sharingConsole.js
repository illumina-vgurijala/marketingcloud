import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retriveShareRecords from '@salesforce/apex/SharingConsole.retriveShareRecords';
import reRunSharingRecords from '@salesforce/apex/SharingConsole.reRunSharingRecords';
import retriveDeferredRun from '@salesforce/apex/SharingConsole.retriveDeferredRun';
import reRunSharingUser from '@salesforce/apex/SharingConsole.reRunSharingForUsers';
import {getRecord} from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

const searchColumns = [{
        label: 'RowCause',
        fieldName: 'rowCause',
        sortable: true,
    }, {
        label: 'Shared With',
        fieldName: 'userName',
        sortable: true,
        type: 'text'
    }, {
        label: 'Accedd Level',
        fieldName: 'accessLevel',
        type: 'text',
        sortable: true
    }, {
        label: 'Last Modified Date',
        fieldName: 'lastModifiedDate',
        type: 'date',
        sortable: true,
        typeAttributes: 
        {
            day: 'numeric',  
            month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            second: '2-digit',  
            hour12: true
        }
    },
];

const columnsSharing = [{
        label: 'Id',
        fieldName: 'id',
    }, {
        label: 'Created Date',
        fieldName: 'createdDate',
        type: 'date',
        typeAttributes: 
        {
            day: 'numeric',  
            month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            second: '2-digit',  
            hour12: true
        }
    }, 
    {
        label: 'Object Type',
        fieldName: 'objectType',
        type: 'text'
    }, 
    {
        label: 'Owner Name',
        fieldName: 'ownerName',
        type: 'text'
    }
];

export default class SharingConsole extends NavigationMixin(LightningElement) {
    @track recordData;
    @track searchColumns = searchColumns;
    @track errorUserMsg = '';
    @track errorSearchMsg = '';
    @track RecordName;
    objectShare= '';
    recordId = '';
    value = '';
    @track isLoaded = false;
    @track displaySharingModel= false;
    @track sortBy;
    @track sortDirection;
    @track recordIds=[];
    @track isValidInput = true;
    @track displayApexJobs = false;

    handleRecordId(event) {
        this.recordId = event.detail.value;
    }
    handleUserId(event){
        this.userId = event.detail.value;
    }
    validateSearchInputs() {
        if(!this.recordId) {
            this.errorSearchMsg = 'Please enter Record Id or Ids.';
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please enter Record Id or Ids.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            this.recordData = undefined;
            return this.isValidInput = false;
        }
        
        this.recordIds = this.recordId.split(',');
        if(!this.checkForIdMatch(this.recordIds)){
            this.errorSearchMsg = 'Please enter matching Record Ids for the same Object.';
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please enter matching Record Ids for the same Object',
                variant: 'error'
            });
            this.dispatchEvent(event);
            this.recordData = undefined;
            return this.isValidInput = false;
        }
        this.isValidInput = true;
    }
    hangleShareRecords(){
        this.validateSearchInputs();
        if(this.isValidInput){
            this.isLoaded = !this.isLoaded;
            retriveShareRecords({recordIds : this.recordIds})
            .then(result => {
                this.recordData = result;
                this.isLoaded = false;
                this.displaySharingModel = true;
                this.sortData('userName', 'asc');
                window.console.log('Result Data: '+JSON.stringify(result.data));         
            })
            .catch(error => {
                this.isLoaded = false;
                window.console.log('Search Error: '+JSON.stringify(error));
                if(error) {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.recordData = undefined;
            }) 
        }
    }
    checkForIdMatch(recordIds){
        const arrRecordIds = recordIds.map((recordId) => recordId[0]+recordId[1]+recordId[2]);
        const isSameRecordId = (currentValue) => currentValue === arrRecordIds[0];
        return arrRecordIds.every(isSameRecordId);
    }

    @track recordData;
    @track rerunErrorMsg;
    @track errorRerunMsg;
    handleRerun() {
        this.validateSearchInputs();
        if(this.isValidInput){
            this.isLoaded = !this.isLoaded;
            reRunSharingRecords({recordIds : this.recordIds})
            .then(result => {
                this.recordData = result; 
                this.isLoaded = false;
                this.sortData('userName', 'asc');
                window.console.log('Rerun Result Data: '+JSON.stringify(result.data));         
            })
            .catch(error => {
                this.isLoaded = false;
                window.console.log('Rerun Error: '+JSON.stringify(error));
                if(error) {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.recordData = undefined;
            }) 
        }
    }
    @track sharingPending;
    @track columnsSharing = columnsSharing;
    @track sharingPendingErrorMsg;
    handleSharingPending(){
        this.isLoaded = !this.isLoaded;
        retriveDeferredRun()
        .then(result => {
            this.sharingPending = result;
            this.isLoaded = false;
            window.console.log('Sharing Result Data: '+JSON.stringify(result.data));  
        })
        .catch(error => {
            this.sharingPending = undefined;
            this.isLoaded = false;
            window.console.log('Rerun Error: '+JSON.stringify(error));
            if(error) {
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
        }) 

    }

    @track error ;
    @track email ; 
    @track name;
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.email = data.fields.Email.value;
            this.name = data.fields.Name.value;
        }
    }
    refreshView() {
        this.recordData = undefined;
        this.errorSearchMsg = '';
        this.displayApexJobs = false;
        this.displaySharingModel = false;
    }
    @track userId;
    handleRerunSharingModel(){
        this.validateUserInputs();
        if(this.isValidInput){
            this.bShowModal = true;
        }
    }
    validateUserInputs() {
        if(!this.userId) {
            this.errorUserMsg = 'Please enter User Record Id';
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please enter User Record Id',
                variant: 'error'
            });
            this.dispatchEvent(event);
            this.recordData = undefined;
            return this.isValidInput = false;
        }
        this.isValidInput = true;
    }
    handleRerunSharingUser(){
        this.bShowModal = false;
        this.displayApexJobs = true;
        reRunSharingUser({userId : this.userId})
        .then(result => {
            window.console.log(' =====> '+JSON.stringify(result.data));  
        })
        .catch(error => {
            this.result = undefined;
            window.console.log('Rerun Error: '+JSON.stringify(error));
            if(error) {
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
        }) 
    }
    handleSortData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordData));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.recordData = parseData;
    }
    @track url='';
    @track isMorethanOneId;
    handleExpandedList() {   
        this.isMorethanOneId = this.recordId.includes(',');
        if(this.isMorethanOneId === true)
        {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Search with One recordId, Expanded list does not support multiple Record Ids',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: "/p/share/SharingBlowoutPage/d?parentId="+this.recordIds
            }
        }).then((url) => {
            window.open(url,"width="+screen.availWidth+",height="+screen.availHeight);
        });
    } 
    @track urlQuipSharingDocument='';
    handleQuipSharingDocument() {   
        this.urlQuipSharingDocument = "https://illumina.quip.com/aVaoAeR7Nvoq/TAPS-Custom-Sharing";
        window.open(this.urlQuipSharingDocument,"width="+screen.availWidth+",height="+screen.availHeight);
    } 
    @track urlHelpAndTraining='';
    handleHelpAndTraining(){
        this.urlHelpAndTraining = "https://illumina.quip.com/ramJAlrrhfJM/TAPS-Sharing-Console-Help-Training";
        window.open(this.urlHelpAndTraining,"width="+screen.availWidth+",height="+screen.availHeight);
    }
    handleApexJobsPage(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: "setup/AsyncApexJobs/home"
            }
        }).then((url) => {
            //TODO - this is bad, url hacking need to redo this later. Compelted in a hurry
            url = url.replace('webpage/','');
            url = url.replace('%2F','/');
            url = url.replace('%2F','/');
            window.open(url,"width="+screen.availWidth+",height="+screen.availHeight);
        });
    }

    @track bShowModal = false;
    openModal() {    
        this.bShowModal = true;
    }
    closeModal() {    
        this.bShowModal = false;
    }

}
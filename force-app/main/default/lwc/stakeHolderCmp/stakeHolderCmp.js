import { LightningElement,track,api,wire} from 'lwc';
//import custom labels
import statusError from '@salesforce/label/c.UI_Error_Message_when_stakeholder_status_is_deactivated';
import headerStakeholder from '@salesforce/label/c.UI_Display_Edit_Stakeholder';

import getResults from '@salesforce/apex/StakeHolderController.getResults';

import getAllStakeholderRecord from '@salesforce/apex/StakeHolderController.getAllStakeholderRecord';
import updateStakeholer from '@salesforce/apex/StakeHolderController.updateStakeholer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';  
import getAllContact from '@salesforce/apex/StakeHolderController.getAllContact';
import { refreshApex } from '@salesforce/apex';

import NAME_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Name';
import BUYING_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Buying_Role__c';
import INFLUENCE_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Influence__c';
import PRIORITY_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Priority_Interests_Objectives__c';
import LEVEL_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Level_of_Support__c';
import PAIN_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Pain_Points_Concerns__c';
import ACCESS_FIELD from '@salesforce/schema/Key_Stakeholder_Analysis__c.Current_Access__c';

import {
    columnContact, 
    columnStakeholder
} from './columns.js';

export default class StakeHolderCmp extends LightningElement {
    @api recordId;   
    @track name;
    @track columnContact = columnContact;
    @track columnStakeholder = columnStakeholder;
    @track showContact = false;
    @track showStakeholderRecord = false;
    @track stakeholderRecords = [];
    @api searchRecords;
    @track contactInstance ;
    @track showAllContact = false;
    @track showSaveView = false;
    @track sortBy;
    @track sortDirection;
    @track stakeholderRecord = [
    ];
    @track editStakeholderRecord ;
    @track showEditView;
    @track errorMsg = statusError;
    @track headerStakeholder = headerStakeholder;
    @track showConfirmation = false;
    @track showtable = false;
    @track showRating = false;
    @api isAppPage = false;
    // Performance issue enhancement
    @track loadMoreStatus;
    @track OffSet;
    @track totalNumberOfRows;
    @track InfinityLoad = true;
    @track DisplayLabels;
    @track isLoading = false;
    @track isCurrentSearch = false;
    @track lastSearchSize;
    @track searchText;
    @track selectedRadioValue
     
    fields = [NAME_FIELD,BUYING_FIELD, INFLUENCE_FIELD,LEVEL_FIELD, ACCESS_FIELD, PRIORITY_FIELD,  PAIN_FIELD];
    @track value = 'searchAccountContacts';
    get options() {
        return [
            { label: 'Search All Contacts', value: 'searchAllContacts' },
            { label: 'Search Account Contacts', value: 'searchAccountContacts' },
        ];
    }
    // Performance issue fix
    loadMoreData(event) {
        if (!this.isLoading) {
            this.isLoading = true;
            const currentRecord = this.searchRecords;
            this.OffSet += 15;
            let localOffset = this.OffSet;
            this.OffSet = localOffset;
            if (this.selectedRadioValue === 'searchAllContacts') {
                getAllContact({recordId: this.recordId, inputText: this.searchText, offSet: this.offSet})
                    .then(result => {
                        const currentData = result;
                        const newData = currentRecord.concat(currentData);
                        this.searchRecords = newData;

                        if(Object.keys(newData).length == this.lastSearchSize){
                        this.InfinityLoad = false;
                        }
                        else{
                            this.lastSearchSize = Object.keys(newData).length;
                        }
                        this.isLoading = false;
                    })
                    // eslint-disable-next-line no-unused-vars
                    .catch(error => {
                        console.log('error'+error);
                        this.showContact = false;
                    });
            } else if (this.selectedRadioValue === 'searchAccountContacts') {
                getResults({ recordId: this.recordId, inputText: this.searchText, offSet: this.offSet })
                    .then(result => {
                        const currentData = result;
                        const newData = currentRecord.concat(currentData);
                        this.searchRecords = newData;
                        if(Object.keys(newData).length == this.lastSearchSize){
                            this.InfinityLoad = false;
                        }
                        else{
                            this.lastSearchSize = Object.keys(newData).length;
                        }
                        this.isLoading = false;
                    })
                    // eslint-disable-next-line no-unused-vars
                    .catch(error => {
                        console.log('error-->'+error);
                        this.showContact = false;
                    });
            }
        }

    }
    handleRadioButtonChange(event){
        
        this.value = event.target.value;
        console.log('option' + event.target.value);
    }
    handleKeyPress(event) {
        console.log('eventcd-->'+event);
        console.log('keycode-->',event.keyCode);
        let keyEnter = event.key;
        console.log('keyEnter-->',keyEnter);
        if(keyEnter === 'Enter'){
            this.handleSearch();
        }
        
    }
    
    handleSearch(){
        this.OffSet = 0;
        this.lastSearchSize = 0;
        this.InfinityLoad = true;
        let currentText = this.template.querySelector(".searchText").value;
        this.searchText = currentText;
        console.log('this.value-->' + this.value);
        const radioValue = this.value;
        this.selectedRadioValue = radioValue;
        console.log('radioValue-->', radioValue);
        if (radioValue === 'searchAllContacts') {
            getAllContact({ recordId: this.recordId, inputText: currentText, offSet: this.offSet })
                .then(result => {
                    this.searchRecords = result;
                    if (result.length > 0) {
                        this.showContact = true;
                        this.lastSearchSize = result.length;
                    } else {
                        this.showContact = false;
                    }


                })
                // eslint-disable-next-line no-unused-vars
                .catch(error => {
                    this.showContact = false;
                });
        } else if (radioValue === 'searchAccountContacts') {

            console.log('radioValue' + radioValue);
            console.log('this.value-->' + this.value);
            getResults({ recordId: this.recordId, inputText: currentText, offSet: this.offSet })
                .then(result => {
                    this.searchRecords = result;
                    if (result.length > 0) {
                        this.showContact = true;
                        this.lastSearchSize = result.length;
                    } else {
                        this.showContact = false;
                    }
                })
                // eslint-disable-next-line no-unused-vars
                .catch(error => {
                    this.showContact = false;
            });
        }
        
    }
    
    
    
    @wire(getAllStakeholderRecord, { recordId: '$recordId' })
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            this.stakeholderRecords = result.data;
            if(this.stakeholderRecords.length >0){
                this.showStakeholderRecord = true;
                let lstOfTempRecord = [];
                this.stakeholderRecords.forEach((con) => {
                    let objTemp = this.flatten(con);
                    if(this.isAppPage){
                        console.log('Reched if inside');
                        
                        objTemp.firstName = con.Contact__r.FirstName;
                        objTemp.lastName = con.Contact__r.LastName;
                        console.log('Passed if inside');
                    }
                    lstOfTempRecord.push(objTemp);
                    
                });
                this.stakeholderRecords = lstOfTempRecord;
                // eslint-disable-next-line no-console
                console.log('this.stakeholderRecords-->'+JSON.stringify(this.stakeholderRecords));
            }else{
                this.showStakeholderRecord = false;
            }
            
            
            
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.stakeholderRecords = undefined;
        }
    }
    
    handleRowAction(event) {
        // eslint-disable-next-line no-unused-vars
        const actionName = event.detail.action.name;
        console.log('action name-->'+actionName);
        const row = event.detail.row;
        this.contactInstance = row;
        if(this.contactInstance){
            this.showSaveView = true;
            
        }
    }
    createStakeHolder(event){
        this.contactInstance = event.target.value;
        if(this.contactInstance){
            this.showSaveView = true;
            
        }
    }
    
    handleChange(event) {
        this.showAllContact = event.target.checked;
    }
    handleEditSubmit(){
    }
    
    handleSubmit(event){
        event.preventDefault();  
        const fields = event.detail.fields;
        console.log('-contact-->' + this.contactInstance.ContactID);
        console.log('-recordid-->' + this.recordId);
        fields.Status__c = 'Active';
        fields.Account_Plan__c = this.recordId;
        fields.Contact__c = this.contactInstance.ContactID;
        this.template.querySelector('lightning-record-form').submit(fields);
        
    }
    handleEditSuccess (){
        const evt = new ShowToastEvent({
            title: "Success!",
            message: "The Stakeholder's record has been successfully updated.",
            variant: "success",
        });
        this.dispatchEvent(evt);
        this.showEditView = false; 
        
        refreshApex(this.wiredResults);   
        
    }
    handleEditOnError(){
        const evt = new ShowToastEvent({
            title: "Error!",
            message: "Pain Points Concerns or Priority Interests Objectives should not be blank.",
            variant: "error",
        });
        this.dispatchEvent(evt);
    }   
    
    handleSuccess (){
        const evt = new ShowToastEvent({
            title: "Success!",
            message: "The Stakeholder's record has been successfully saved.",
            variant: "success",
        });
        this.dispatchEvent(evt);
        this.showSaveView = false; 
        this.template.querySelector(".searchText").value = null;
        this.showContact = false;
        
        refreshApex(this.wiredResults);   
        
    }
    handleOnError(){
        const evt = new ShowToastEvent({
            title: "Error!",
            message: "Pain Points Concerns or Priority Interests Objectives should not be blank.",
            variant: "error",
        });
        this.dispatchEvent(evt);
    }   
    
    closeModal(){
        this.showSaveView = false;    
        
    }
    closeEditModal(){
        this.showEditView = false;    
    }
    //The method will be called on sort click
    handleSortdata(event) {
        // field name
         // field name
         this.sortBy = event.detail.fieldName;
         // sort direction
         this.sortDirection = event.detail.sortDirection;
         
        if(this.sortBy === 'stakeholderForFirstNameUrl'){
            this.sortData('Contact__r.FirstName', event.detail.sortDirection);
        }else if(this.sortBy === 'stakeholderForLastNameUrl'){
            this.sortData('Contact__r.LastName', event.detail.sortDirection);
        } else{
            // calling sortdata function to sort the data based on direction and selected field
            this.sortData(event.detail.fieldName, event.detail.sortDirection);
        }

        
    }
    handleSortdata1(event){
        // field name
        this.sortBy = event.detail.fieldName;
        // sort direction
         // sort direction
         this.sortDirection = event.detail.sortDirection;
         
        if(this.sortBy === 'NameUrl'){
            this.sortData1('Name', event.detail.sortDirection);
        }else if(this.sortBy === 'AccountUrl'){
            this.sortData1('AccountName', event.detail.sortDirection);
        } else{
            // calling sortdata function to sort the data based on direction and selected field
            this.sortData1(event.detail.fieldName, event.detail.sortDirection);
        }
        
    }
    sortData1(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.searchRecords));
        
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        
        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;
        
        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        
        // set the sorted data to data table data
        this.searchRecords = parseData;
        
    }
    
    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.stakeholderRecords));
        
            let keyValue = (a) => {
                return a[fieldname];
            };
        
        // Return the value stored in the field
       
        console.log('keyValue--->'+keyValue);
        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;
        
        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        
        // set the sorted data to data table data
        this.stakeholderRecords = parseData;
        
    }
    editStakeHolder(event){
        this.editStakeholderRecord = event.target.value;
        this.showEditView = true;
    }
    deleteStakeHolder(event){
        console.log('Indidedelere dtadjhsfsdu');
        let stakeholderRow = event.target.value;
        console.log('this.stakeholderRow-->'+JSON.stringify(stakeholderRow));
        console.log('edit viee---?'+this.showConfirmation);
        //stakeholderRow.Status__c = 'Inactive';
        console.log('edit viee---?'+this.showConfirmation);
        this.stakeholderRecord.push({Id: stakeholderRow.Id, Status__c: 'Inactive' });
        console.log('edit viee---?'+this.showConfirmation);
        this.showConfirmation = true;
        console.log('edit viee---?'+this.showConfirmation);
    }
    showRanking(event){
        let stakeholderRow = event.target.value;
        this.editStakeholderRecord = stakeholderRow;
        console.log('this.stakeholderRow-->'+JSON.stringify(this.editStakeholderRecord));
        this.showRating = true;
    }
    StakeholderRowAction(event){
        
        const actionName = event.detail.action.name;
        console.log('action name-->'+actionName);
        const stakeholderRow = event.detail.row;
        switch (actionName) {
            case 'Edit Stakeholder':
            this.editStakeholderRecord = stakeholderRow;
            this.showEditView = true;
            break;
            case 'Rating':
                    console.log('action name rating-->');
            this.editStakeholderRecord = stakeholderRow;
            console.log('this.stakeholderRow-->'+JSON.stringify(this.editStakeholderRecord));
            this.showRating = true;
            break;
            case 'Remove Stakeholder':
            // eslint-disable-next-line no-console
            console.log('this.stakeholderRow-->'+JSON.stringify(stakeholderRow));
            stakeholderRow.Status__c = 'Inactive';
            this.stakeholderRecord.push({Id: stakeholderRow.Id, Status__c: stakeholderRow.Status__c });
            // eslint-disable-next-line no-console
            console.log('this.stakeholderRecord-->'+JSON.stringify(this.stakeholderRecord));
            if(this.stakeholderRecord != null){
                this.showConfirmation = true
            }
            break;
        }
        
    }
    deactivateStakeholderRecord(){
        // eslint-disable-next-line no-console
        console.log('deactivateStakeholderRecord-->'); 
        this.stakeholderRecord.forEach(function(element) {
           element.Status__c = 'Inactive';
          });
        updateStakeholer({ editedStakeholerList : this.stakeholderRecord })
        // eslint-disable-next-line no-unused-vars
        .then(result => {
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: "The Stakeholder's record has been successfully updated.",
                    variant: 'success'
                })
                );
                this.showConfirmation = false;
                // Clear all draft value
                refreshApex(this.wiredResults); 
            })
            .catch(error => {
                this.showConfirmation = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong',
                        variant: 'Error'
                    })
                    );
                    // eslint-disable-next-line no-console
                    console.log('-------error-------------'+JSON.stringify(error));
                });
                this.showContact =false;
                this.template.querySelector(".searchText").value = null;
                
            }
            closeConfirmationModal(){
                this.showConfirmation = false;
            }
            closeRatingModal(){
                this.showRating = false;
            }
            
            _flatten (target, obj, path) {
                let i, empty;
                if (obj.constructor === Object) {
                    empty = true;
                    for (i in obj) {
                        
                        if (i === 'Id' && (obj.Account_Plan__c != null || obj.Buying_Role__c != null)) {
                            target['stakeholderForFirstNameUrl']= '/'+obj['Id'];
                            target['stakeholderForLastNameUrl']= '/'+obj['Id'];
                            target['Id']= obj['Id'];
                        }else{
                            empty = false;
                            this._flatten(target, obj[i], path ? path + '.' + i : i);
                        }
                      
                    }
                    if (empty && path) {
                        target[path] = {};
                    }
                } else if (constructor === Array) {
                    i = obj.length;
                    if (i > 0) {
                        while (i--) {
                            this._flatten(target, obj[i], path + '[' + i + ']');
                        }
                    } else {
                        target[path] = [];
                    }
                } else {
                    target[path] = obj;
                }
            }
            
            flatten (data) {
                let result = {};
                this._flatten(result, data, null);
                return result;
            }
            
        }
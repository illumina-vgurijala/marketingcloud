import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    consoleLog,
    showErrorToast,
    showSuccessToast,
    isBlank,
    callServer,
    isEmpty
} from 'c/utils';
import {
    columns,
    searchColumns
} from './columns.js';

import PARENT_ID from '@salesforce/schema/Knowledge_Association__c.Parent_Knowledge__c';
import RELATED_ID from '@salesforce/schema/Knowledge_Association__c.Related_Knowledge__c';

import {
    deleteRecord,
    createRecord
} from 'lightning/uiRecordApi';
import fetchRelatedKnowledge from '@salesforce/apex/KnowledgeAssociationComponentController.fetchRelatedKnowledge';
import fetchKnowledgeArticles from '@salesforce/apex/KnowledgeAssociationComponentController.fetchKnowledgeArticles';
export default class KnowledgeAssociationComponent extends LightningElement {
    @api recordId;
    @track booLoading = true;
    @track associatedRecords = [];
    @track column = columns;
    @track searchColumn = searchColumns;
    @track showConfirmation = false;
    @track activeSections = [];
    @track searchResult;
    mapUILabels = [];
    recordToDelete = '';
    queryTerm = '';
    connectedCallback() {
        this.getRelatedRecords();
    }
    // Fetch related knowledge article
    getRelatedRecords() {
        this.closeModal();
        this.associatedRecords = [];
        this.booLoading = true;
        callServer(fetchRelatedKnowledge, {
            strParentKnowledgeId: this.recordId
        }, result => {
            consoleLog('Related Result -->', JSON.parse(result));
            var parseResult = JSON.parse(result);
            this.mapUILabels = parseResult.mapLabels;
            var associatedRecords = parseResult.lstKnowledgeAssociationWrap;
            console.log(Object.keys(associatedRecords));
            Object.keys(associatedRecords).forEach(element => {
                this.activeSections.push(element);
                this.associatedRecords.push({
                    RecordType: element,
                    AssociatedData: associatedRecords[element]
                });
            });
            this.booLoading = false;
        }, error => {
            this.booLoading = false;
        });
    }
    // Row action for deletion
    handleRowAction(event) {
        const rowDetail = event.detail.value;
        console.log('Action Row -->' + rowDetail.strRecordId);
        this.recordToDelete = rowDetail.strRecordId;
        this.deleteRecordsConfirmtion();
    }
    //Row action fpr search result
    handleSearchRowAction(event) {
        const rowDetail = event.detail.value;
        console.log('Action Row -->' + rowDetail.strRecordId);
        this.addAssociation(rowDetail.strRecordId);
    }
    // Method to create association record.
    addAssociation(relatedRecordId) {
        const fields = {};
        fields[PARENT_ID.fieldApiName] = this.recordId;
        fields[RELATED_ID.fieldApiName] = relatedRecordId;
        const recordInput = {
            apiName: 'Knowledge_Association__c',
            fields
        };
        this.booLoading = true;
        callServer(createRecord,recordInput,
            result => {
            showSuccessToast(this.mapUILabels.UI_Message_Knowledge_Association_Success);
                this.getRelatedRecords();
                if (!isBlank(this.queryTerm))
                    this.searchKnowledge();
                this.booLoading = false;
            },
            error => {
                this.booLoading = false;
        });
    }
    // Reset funtionality
    closeModal() {
        this.showConfirmation = false;
        this.recordToDelete = '';
    }
    // COnfirmation pop up
    deleteRecordsConfirmtion() {
        this.showConfirmation = true;
    }
    // method to delete Association.
    deleteRecords() {
        this.booLoading = true;
        deleteRecord(this.recordToDelete)
            .then(() => {
                showSuccessToast(this.mapUILabels.UI_Message_Knowledge_Dissociation_Success);
                this.getRelatedRecords();
                if (!isBlank(this.queryTerm))
                    this.searchKnowledge();
                this.booLoading = false;
            })
            .catch(error => {
                consoleLog('Error', error)
                showErrorToast('Record Unlinked failed');
                this.booLoading = false;
            });
    }
    // Handler for toggle section
    handleSectionToggle(event) {
        this.activeSections = event.detail.openSections;
    }
    // Search field handler
    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey && !isBlank(evt.target.value)) {
            this.booLoading = true;
            this.queryTerm = evt.target.value;
            this.searchKnowledge();
        } else {
            this.searchResult = [];
        }
    }
    // Method to search based on query detail
    searchKnowledge() {
        this.searchResult = [];
        callServer(fetchKnowledgeArticles, {
            strSearchKey: this.queryTerm,
            strParentKnowledgeId: this.recordId
        }, result => {
            consoleLog('Search Result ',result);
            this.searchResult = JSON.parse(result);
            this.booLoading = false;
        }, error => {
            this.booLoading = false;
        });
    }
    // Getter method to show search result
    get showSearchResult() {
        return !isEmpty(this.searchResult);
    }
    get showAssociatedRecords(){
        return !isEmpty(this.associatedRecords);
    }
     //On click of x removing searchresults.
    changeHandler() {
        if(!isBlank(this.queryTerm))
            this.searchResult = []; 		        
    }

}
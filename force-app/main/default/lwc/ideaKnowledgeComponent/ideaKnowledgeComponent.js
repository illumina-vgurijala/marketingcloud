import { LightningElement, api, wire, track} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getLinkedIdeas from '@salesforce/apex/IdeaKnowledgeController.getLinkedIdeas';
import findIdeas from '@salesforce/apex/IdeaKnowledgeController.findIdeas';
import attachIdeas from '@salesforce/apex/IdeaKnowledgeController.attachIdeaToKnowledge';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {consoleLog,consoleError} from 'c/utils';

export default class IdeaKnowledgeComponent extends LightningElement {
    @track
    columns = [
        { label: 'Name', fieldName: 'valueUrl', type: 'url', typeAttributes: {label: {fieldName: 'Name'}, target: '_self'}},
        { label: 'Category', fieldName: 'Category__c'},
        { label: 'Sub-Category', fieldName: 'Sub_Category__c'},
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
        { label: 'Submitted By', fieldName: 'submittedBy'},
    ];
    @api recordId;
    searchTerm = '';
    isLoading = false;
    isLinkedIdeasLoading = true;
    @track searchedIdeas = [];
    @track linkedIdeas = [];
    @track searchErrors = {}; 
    showSearchResults = false;
    @track choosenRows;
    @track wiredIdeaList;

    connectedCallback() {
        this.isLinkedIdeasLoading = true;
    }

    @wire(getLinkedIdeas, {kavId : "$recordId"} )
    wiredIdeas (value) {
        // storing wire service provisioned values in a variable so it can be used later for refresh
        this.wiredIdeaList = value;
        const { data, error } = value;
        consoleLog('data', data);
        if (data) {
            this.linkedIdeas = data.map(row => {
                return {...row , valueUrl:`/${row.Id}`, submittedBy: `${row.CreatedBy.Name}`} 
            })
        } else if (error) {
            this.showToastMessage('Error!', error.body.message, 'error');
            this.linkedIdeas = [];
        }
        this.isLinkedIdeasLoading = false;

    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        this.searchTerm = evt.target.value;
        if (isEnterKey) {
            consoleLog('searchTerm: ' + this.searchTerm);
            this.searchIdeasMethod(this.searchTerm);
        }
    }

    getSelectedRows(event) {
        this.choosenRows = event.detail.selectedRows;
        consoleLog('this.choosenRows', this.choosenRows);
        consoleLog('this.choosenRows', this.choosenRows.length);
        if (this.choosenRows.length) {
            consoleLog('this.choosenRows Id', this.choosenRows[0].Id);

        }
        
    }

    async attachIdeasToKav(event) {
        this.isLoading = true;
        const ideaList = [];
        let result = false;

        for (let row of this.choosenRows) {
            ideaList.push(row.Id);
        }
        consoleLog('ideaList', ideaList);

        try {
            consoleLog('record id', this.recordId);
            result = await attachIdeas({ kavId: this.recordId, lstIdeaIds: ideaList});
            this.isLoading = false;
            consoleLog('result', result);
            if (result) {
                this.showToastMessage('Success!', 'Idea successfully linked to this Knowledge Article!', 'success');
                await refreshApex(this.wiredIdeaList);
            } else {
                this.showToastMessage('Warning!', 'Selected Idea is already linked to this Knowledge Article!', 'warning');
            }

        } catch(err) {
            consoleError('error occured: ', err);
            this.isLoading = false;
            this.searchErrors = err;
            this.searchIdeas = [];
            this.showToastMessage('Error!', err.body.message, 'error');
        }
    }

    async searchIdeasMethod(event) {
        this.isLoading = true;
        consoleLog('searchTerm: ' + this.searchTerm);
        if (!this.searchTerm) {
            this.showToastMessage('Error!', 'Please enter a valid value!', 'error');
            this.isLoading = false;
            return;
        }
        if (this.searchTerm.length < 3 || this.searchTerm.length > 255) {
            this.showToastMessage('Error!', 'Input value should be in 3-255 character range!', 'error');
            this.isLoading = false;
            return;
        }
        try {
            let ideaList = [];
            ideaList = await findIdeas({ searchText: this.searchTerm});
            consoleLog('ideaList', ideaList);
            this.searchedIdeas = ideaList.map(row => {
                consoleLog('row', row);
                return {...row , valueUrl:`/${row.Id}`, submittedBy: `${row.CreatedBy.Name}`} 
            })
            this.isLoading = false;
            consoleLog('searchedIdeas: ', this.searchedIdeas);
            this.showSearchResults = true;
            this.searchErrors = undefined;

        } catch(err) {
            this.isLoading = false;
            consoleError('error occured: ', err);
            this.searchErrors = err;
            this.searchIdeas = [];
            this.showToastMessage('Error!', err.body.message, 'error');
        }

    }

    showToastMessage(title, messageText, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: messageText,
            variant: variant,
          });
          this.dispatchEvent(evt);

    }


}
import { LightningElement,api,track } from 'lwc';
import { callServer,consoleLog,isEmpty,isNotEmpty } from 'c/utils';
import getResults from '@salesforce/apex/MultiSelectLookupController.getResults';

export default class LwcMultiLookup extends LightningElement {
    @api objectname;
    @api fieldname;
    @api iconnameSearch;
    @api iconnameDropDown;
    @api Label;
    @api required = false;
    @api orderBy = "asc";
    @api limit = "20";
    @api LoadingText = false;
    @track searchRecords = [];
    @track selectedRecords = [];
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track noResultsFlag = false;
    @track showSearchResult = false;
    @api errorMessage;
    @api checkValidity() {
        if(!this.required) {
            return false;
        }

        let inputCmp = this.template.querySelector("input");
        if (isEmpty(this.selectedRecords)) {
            inputCmp.setCustomValidity(this.errorMessage);
        } else {
            inputCmp.setCustomValidity(""); // if there was a custom error before, reset it
        }
        inputCmp.reportValidity();
        return true;
    }
    

    doneTypingInterval = 300;
    typingTimer;
 
    LwcMultiLookup()
    {
        this.required = true;
    }

    searchField(event) {
        let currentText = event.target.value;
        if(currentText.length < 3)
        {
            this.showSearchResult = false;
            return;
        }
        let selectRecId = [];
        this.selectedRecords.forEach(selectedRecord => {
            selectRecId.push(selectedRecord.strKey);
        });
        this.LoadingText = true;

        let params = {
            "objectName": this.objectname,
            "fieldName": this.fieldname,
            "value": currentText,
            "limitValue": this.limit,
            "orderBy": this.orderBy
        };
        params = JSON.stringify(params);
        consoleLog(params);

        this.typingTimer = setTimeout(() => {
            if(currentText){
                this.getResultsMethod(params, selectRecId);
            }
        }, this.doneTypingInterval);
    }

    getResultsMethod(params, selectRecId){
        callServer(getResults, { params: params, selectedRecId: selectRecId }
            , result => {
            result = JSON.parse(result);
            this.searchRecords = result;
            consoleLog('search records-->' + JSON.stringify(this.searchRecords));
            this.LoadingText = false;
            this.showSearchResult = true;
            
            this.txtclassname = isNotEmpty(result) ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(isNotEmpty(JSON.parse(params).value) && isEmpty(result)) {
                this.noResultsFlag = true;
            }
            else {
                this.noResultsFlag = false;
            }

            if(this.selectRecordId !== null && isNotEmpty(this.selectRecordId)) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }

        }, error => {
            consoleLog('-------error-------------'+error);
            consoleLog(error);
        });

    }
    
    setSelectedRecord(event) {
        // Fixed codescans
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let newsObject = { 'strKey' : recId ,'strValue' : selectName };
        this.selectedRecords.push(newsObject);
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let selRecords = this.selectedRecords;
		this.template.querySelectorAll('input').forEach(each => {
            each.value = '';
        });
        this.showSearchResult = false;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

    }

    removeRecord (event){
        this.selectedRecords = this.selectedRecords.filter(function removeSelected(selectedRecord) {
                                                                return event.detail.name !== selectedRecord.strKey;
                                                            });
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    
}
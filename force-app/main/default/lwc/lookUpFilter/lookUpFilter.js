/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';
import loadPage from '@salesforce/apex/LookupFilterController.loadPage';
import doSearch from '@salesforce/apex/LookupFilterController.doSearch';
import doSave from '@salesforce/apex/LookupFilterController.doSave';
import noICAErrorMsg from '@salesforce/label/c.UI_Label_No_ICA';
import expSubscription from '@salesforce/label/c.Expired_Subscription';
import { callServer,consoleLog,showErrorToast,showSuccessToast,isBlank,isNull,isNotEmpty } from 'c/utils';

export default class LookUpFilter extends LightningElement {

    @api strLookupApiName;
    @api strObjectApiName;
    @api strFieldFilters;
    @api strSearchFields;
    @api strDisplayFields;
    @api strOrderByClause;
    @api recordId;
    @api strTitle;
    //to load the page sections
    @track booConfigurationProper=false;
    @track booResultsFound=false;
    @track booLoading=true;
    //objects
    @api wrapInputs;
    @api wrapPageValues;
    @api lstRecords;
    @api strValue;
    @api strSearchLabel;
    @api wrapSelection;

    label = {
        noICAErrorMsg,
        expSubscription
    }

    connectedCallback(){
        /* Call the Salesforce Apex class method to find the Records */
        this.wrapInputs = {
            strLookupApiName: this.strLookupApiName,
            strObjectApiName: this.strObjectApiName, 
            strFieldFilters: this.strFieldFilters, 
            strSearchFields: this.strSearchFields, 
            strDisplayFields: this.strDisplayFields, 
            strOrderBy: this.strOrderByClause==null?'':this.strOrderByClause, 
            strSearch: ''
        };
        consoleLog('wrapInputs:',this.wrapInputs);
        consoleLog('recordId:',this.recordId);
        
        callServer(loadPage,{
            idRecord: this.recordId,
            strInputJSON: JSON.stringify(this.wrapInputs)
        },result => {
            consoleLog('result: ' + result);
            if(isNull(result)){
                showErrorToast('Unexpected error ');
                return;
            }
                
            let wrapJSON  = JSON.parse(result);
            consoleLog('wrapJSON: ' , wrapJSON);
            this.wrapPageValues= wrapJSON.wrapFields;
            this.strValue = wrapJSON.strValue;
            consoleLog('wrapPageValues: ' , this.wrapPageValues);
            consoleLog('strValue: ' + this.strValue);
            this.strSearchLabel = 'Search for '+this.wrapPageValues.strLookupLabel+'. Hit enter to search.';
            if(isNotEmpty(this.wrapPageValues.lstErrors)){
                let lstError = [];
                this.wrapPageValues.lstErrors.forEach(function(element,index){
                    let wrapError = {intIndex: index, strValue:element};
                    lstError.push(wrapError);
                });
                consoleLog('lstError: ' + lstError);
                this.wrapPageValues.lstErrors=lstError;
                this.booConfigurationProper=false;
            }else
                this.booConfigurationProper=true;
            this.booLoading=false;
        },error => {
            this.handleError(error);
        });
        
    }

    setRowSelection(event){
        const selectedRows = event.detail.selectedRows;
        consoleLog('selectedRows: ', selectedRows);
        this.wrapSelection = selectedRows[0];
        this.wrapPageValues.strLookupId =this.wrapSelection.Id;
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.strValue = evt.target.value;
            this.wrapInputs.strSearch = this.strValue;
            this.searchKey();
        }
    }

    searchKey(){
        consoleLog('wrapInputs:',this.wrapInputs);
        consoleLog('recordId:',this.recordId);
        consoleLog('wrapPageValues:',this.wrapPageValues);
        this.booLoading=true;
        this.booResultsFound=false;
        this.lstRecords = [];

        callServer(doSearch,{
            idRecord: this.recordId,
            strInputJSON: JSON.stringify(this.wrapInputs),
            strFieldsWrapper: JSON.stringify(this.wrapPageValues)
        },result => {
                
            consoleLog('result: ' + result);
            if(result ===null){
                showErrorToast('Unexpected error ');
                return;
            }
            if(!result.includes(expSubscription)){
            this.lstRecords  = JSON.parse(result);
            consoleLog('lstRecords: ' , this.lstRecords);
            }
            
            if(result.includes(expSubscription)){
                showErrorToast(result);
                this.booResultsFound=false;
                this.booLoading=false;
            }
            else if(isNotEmpty(this.lstRecords) && !result.includes(expSubscription)){
                this.booResultsFound=true;
                this.booLoading=false;
            }
            else{
                showErrorToast(this.label.noICAErrorMsg);
                this.booResultsFound=false;
                this.booLoading=false;
            }
        },error => {
            this.handleError(error);
        });
        
    }

    validateAndSave(){
        if(isNull(this.wrapSelection) || isBlank(this.wrapSelection.Id)){
            showErrorToast('Please select a value');
            return;
        }
        this.booLoading=true;
        consoleLog('wrapSelection: ', this.wrapSelection);
        this.wrapPageValues.strLookupId = this.wrapSelection.Id;
        this.strValue = this.wrapSelection.Name;
        callServer(doSave,{
            idRecord: this.recordId,
            strInputJSON: JSON.stringify(this.wrapInputs),
            strFieldsWrapper: JSON.stringify(this.wrapPageValues)
        },result => {
            if(result==='Success'){
                showSuccessToast('Save success');
                this.booLoading=false;
            }
                
        },error => {
            this.handleError(error);
        });
        
    }

    handleError(error){
        this.booLoading=false;
    }
}
import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

import loadPage from '@salesforce/apex/CustomerMasterDataSelectionController.loadPage';
import saveSelection from '@salesforce/apex/CustomerMasterDataSelectionController.saveSelection';
import searchIndirectCMD from '@salesforce/apex/CustomerMasterDataSelectionController.searchIndirectCMD';
import { callServer,showErrorToast,showSuccessToast,consoleLog,isNotBlank,isEmpty,isNotEmpty} from 'c/utils';

import BILL_TO from '@salesforce/schema/Apttus_Proposal__Proposal__c.Bill_To__c';
import SHIP_TO from '@salesforce/schema/Apttus_Proposal__Proposal__c.Ship_To__c';
import QUOTE_STAGE from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_Proposal__Approval_Stage__c';
import PAYMENT_TERM from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_Proposal__Payment_Term__c';
import INVALID_QUOTE from '@salesforce/schema/Apttus_Proposal__Proposal__c.Invalid_Quote__c';
import APPROVAL_STATUS from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_QPApprov__Approval_Status__c';
import PAYER from '@salesforce/schema/Apttus_Proposal__Proposal__c.Payer__c';
import IS_UPDATED_BY_SYSTEM from '@salesforce/schema/Apttus_Proposal__Proposal__c.Is_Updated_By_System__c';

import {
    lstDirectColumns, 
    lstIndirectColumns
} from './columns.js';

const FIELDS = [BILL_TO, SHIP_TO, QUOTE_STAGE, PAYMENT_TERM, INVALID_QUOTE, APPROVAL_STATUS, PAYER, IS_UPDATED_BY_SYSTEM];
const ACCOUNTRELATIONSHIPBILLTO = 'Bill To';
const SEARCHERRORS = ["Apex heap size too", "JSON string exceeds","Too many query rows"];


export default class customerMasterDataSelectionLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api strType;
    @api strRecordError;
    @api headerColor;
    intPageSize;
    mapLabels;
    lstDirectColumns = lstDirectColumns;
    lstIndirectColumns = lstIndirectColumns;
    lstDirectFull = [];
    lstIndirectFull = [];
    objTargetQuote;
    booDirectDeal;
    strUCCountry;
    strSalesArea;
    booAppReqQuote;
    quoteRecord;
    lstSelectionsDirect;
    lstSelectionsIndirect;
    lstselectionsfinal;
    objQuote = {};
    @track isDesktopView = false;
    @track booIsPageLoaded = false;
    @track booShowSpinner = true;
    @track booSearchDisable = true;
    @track lstDirect = [];
    @track lstIndirect = [];
    @track boolstDirectEmpty = true;
    @track boolstIndirectEmpty = true;
    @track sortByDirect = 'strName';
    @track sortByIndirect = 'strName';
    @track sortDirectionDirect = 'asc';
    @track sortDirectionIndirect = 'asc';
    @track isTypeBillTo = false;
    @track intDirectPageTotal = 1;
    @track intDirectPageNumber = 1;
    @track intIndirectPageTotal = 1;
    @track intIndirectPageNumber = 1;
    @track booIsDirectTotalPageGr1 = false;
    @track booIsIndirectTotalPageGr1 = false;
    @track booIsFirstPageDirect = true;
    @track booIsLastPageDirect = false;
    @track booIsFirstPageIndirect = true;
    @track booIsLastPageIndirect = false;
    @track strSearchName = "";
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS }) 
    rec(response) {
        this.quoteRecord = response;
        consoleLog('@@@ Wire Data @@@', this.quoteRecord);
        this.updateQuoteData();
        
    }

    get applyHeaderStyle() {
        return `color:${this.headerColor}`;
    }

    get applyDividerStyle() {
        return `border-top: 2px solid ${this.headerColor}`;
    }

    
    get saveRelatedSelectionButton() {
        if(this.strType === ACCOUNTRELATIONSHIPBILLTO) {
            return this.mapLabels.UI_Button_CMD_Selection_Save_Related_Bill_To;
        }
            return this.mapLabels.UI_Button_CMD_Selection_Save_Related_Ship_To;
    }

    get saveSearchedSelectionButton() {
        if(this.strType === ACCOUNTRELATIONSHIPBILLTO) {
            return this.mapLabels.UI_Button_CMD_Selection_Save_Searched_Bill_To;
        }
            return this.mapLabels.UI_Button_CMD_Selection_Save_Searched_Ship_To;
    }

    updateQuoteData() {
        this.objQuote.Id = this.recordId;
        this.objQuote.Bill_To__c = getFieldValue(this.rec.data, BILL_TO);
        this.objQuote.Ship_To__c = getFieldValue(this.rec.data, SHIP_TO);
        this.objQuote.Apttus_Proposal__Approval_Stage__c = getFieldValue(this.rec.data, QUOTE_STAGE);
        this.objQuote.Apttus_Proposal__Payment_Term__c = getFieldValue(this.rec.data, PAYMENT_TERM);
        this.objQuote.Invalid_Quote__c = getFieldValue(this.rec.data, INVALID_QUOTE);
        this.objQuote.Apttus_QPApprov__Approval_Status__c = getFieldValue(this.rec.data, APPROVAL_STATUS);
        this.objQuote.Payer__c = getFieldValue(this.rec.data, PAYER);
        this.objQuote.Is_Updated_By_System__c = getFieldValue(this.rec.data, IS_UPDATED_BY_SYSTEM);
    }

    connectedCallback() {
        if(FORM_FACTOR == 'Large') {
            this.isDesktopView = true;
        }
        else {
            this.isDesktopView = false;
        }
        callServer(loadPage, {strQuoteId: this.recordId, strType: this.strType}
            , response => {
                response = JSON.parse(response);
                if(response.booClosedOpportunity){
                    this.showErrorAndQuit(response.mapLabels.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity);
                }
                if(response.booInvalidQuote){
                    this.showErrorAndQuit(response.mapLabels.UI_InvalidQuoteError);
                    return;
                }

                if(response.booInReview || response.booAccepted || response.booApproved || response.booGenerated || response.booPresented) {
                    this.showErrorOnClick(response.mapLabels);
                }
               	this.lstDirectFull = response.lstDirect;
                this.mapLabels = response.mapLabels;
                this.booDirectDeal = response.booDirectDeal;
                this.strUCCountry = response.strUCCountry;
                this.strSalesArea = response.strSalesArea;
                this.booAppReqQuote = response.booAppReqQuote;
                this.intPageSize = response.strPageSizes.desktop;
                if(!this.isDesktopView) {
                    this.intPageSize = response.strPageSizes.mobile;
                }
                
                if(isNotEmpty(response.lstDirect)) {
                    this.boolstDirectEmpty = false;
                    this.sortData(this.sortByDirect, this.sortDirectionDirect, 'intDirectPage');
                    this.checkButtonVisibility('intDirectPage');
                }
                this.booIsPageLoaded = true;
                this.booShowSpinner = false;

        }, error => {
            this.handleError(error);
        });
        if(this.strType == 'Bill To') {
            this.isTypeBillTo = true;
        }
    }

    showErrorAndQuit(strMessage) {
        setTimeout(function(){
            showErrorToast(strMessage);
        }, '200')
        this.navigateToViewProposalPage();
    }

    showErrorOnClick(mapLabels,calledFrom){
    
        let objQuoteApprovalStage = getFieldValue(this.quoteRecord.data, QUOTE_STAGE);
        
        if(objQuoteApprovalStage === mapLabels.QuoteStageInReview &&  this.strType === mapLabels.AccountRelationshipBillTo) {
            this.showErrorAndQuit(mapLabels.UI_ErrorMessage_QuoteInReview_BillTo);
        }
        if(objQuoteApprovalStage === mapLabels.QuoteStageAccepted &&  this.strType === mapLabels.AccountRelationshipBillTo) {
            this.showErrorAndQuit(mapLabels.UI_ErrorMessage_QuoteInAccepted_BillTo);
        }
        if(objQuoteApprovalStage === mapLabels.QuoteStageInReview &&  this.strType === mapLabels.AccountRelationshipShipTo) {
            this.showErrorAndQuit(mapLabels.UI_ErrorMessage_QuoteInReview_ShipTo);
        }
        if(objQuoteApprovalStage === mapLabels.QuoteStageAccepted &&  this.strType === mapLabels.AccountRelationshipShipTo) {
            this.showErrorAndQuit(mapLabels.UI_ErrorMessage_QuoteInAccepted_ShipTo);   // DCP-30247 - Removed Error for Generated, Presented and Approved stages for ship tp
        }

    }

    navigateToViewProposalPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Apttus_Proposal__Proposal__c',
                actionName: 'view'
            },
        });
    }

    handleSortdataDirect(event) {
        this.sortByDirect = event.detail.fieldName;
        this.sortDirectionDirect = event.detail.sortDirection;
        this.sortData(this.sortByDirect, this.sortDirectionDirect, 'intDirectPage');
         
    }

    handleSortdataIndirect(event) {
        this.sortByIndirect = event.detail.fieldName;
        this.sortDirectionIndirect = event.detail.sortDirection;
        this.sortData(this.sortByIndirect, this.sortDirectionIndirect, 'intIndirectPage');
         
    }

    sortData(fieldname, direction, strPageName) {
        this.sortDatahelper(fieldname, direction, strPageName);
        let data;
        if(strPageName === 'intDirectPage') {
            data = this.lstDirectFull;
        }
        else{
            data = this.lstIndirectFull;
        }
        let intsize = data.length;
        let intPageSize = this.intPageSize;
        let intPageTotal = Math.floor(intsize/intPageSize)+(intsize%intPageSize>0?1:0);

        if(strPageName === 'intDirectPage') {
            this.intDirectPageTotal = intPageTotal;
            this.intDirectPageNumber = 1;
        }
        else {
            this.intIndirectPageTotal = intPageTotal;
            this.intIndirectPageNumber = 1;
        }

        this.setPage(strPageName)
    }

    sortDatahelper(fieldname, direction, strPageName) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.lstDirectFull));
        if(strPageName === 'intIndirectPage' ) {
            parseData = JSON.parse(JSON.stringify(this.lstIndirectFull));
        }

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
        if(strPageName === 'intDirectPage' ) {
            this.lstDirectFull = parseData;
        }
        else {
            this.lstIndirectFull = parseData;
        }
        
    }

    editPageValuehelper(strPageName,intValue) {
        let intPage = this.intDirectPageNumber;
        if(strPageName == 'intIndirectPage') {
            intPage = this.intIndirectPageNumber;
        }
        intPage+=intValue;
        if(strPageName == 'intDirectPage') {
            this.intDirectPageNumber = intPage;
        }
        else{
            this.intIndirectPageNumber = intPage;
        }
    }

    setPage(strPageName) {
        let intPageNumber = this.intDirectPageNumber;
        let intPageTotal = this.intDirectPageTotal;
        let intPageSize = this.intPageSize;
        let lstAllValues = this.lstDirectFull;
        if(strPageName === 'intIndirectPage') {
            intPageNumber = this.intIndirectPageNumber;
            intPageTotal = this.intIndirectPageTotal;
            lstAllValues = this.lstIndirectFull;
        }

        let intStart =  (intPageNumber - 1)*intPageSize,intEnd;
        if(intPageNumber == intPageTotal) {
            intEnd = lstAllValues.length;
        }   
        else{
            intEnd = (intPageNumber*intPageSize);
        }
        let lstPaginated = lstAllValues.slice(intStart,intEnd);
        consoleLog('@@@ LstPaginated @@@', lstPaginated);
        if(strPageName === 'intDirectPage') {
            this.lstDirect = lstPaginated;
        }  
        else{
            this.lstIndirect = lstPaginated;
        }
        this.checkButtonVisibility(strPageName);
    }

    checkButtonVisibility(strPageName) {
        if(strPageName == 'intDirectPage') {
            if(this.intDirectPageTotal > 1) {
                this.booIsDirectTotalPageGr1 = true;
            }
            else {
                this.booIsDirectTotalPageGr1 = false;
            }
            if(this.intDirectPageNumber == 1) {
                this.booIsFirstPageDirect = true;
            }
            else{
                this.booIsFirstPageDirect = false;
            }
            if(this.intDirectPageNumber == this.intDirectPageTotal) {
                this.booIsLastPageDirect = true;
            }
            else{
                this.booIsLastPageDirect = false;
            }
        }
        else{
            if(this.intIndirectPageTotal > 1) {
                this.booIsIndirectTotalPageGr1 = true;
            }
            else {
                this.booIsIndirectTotalPageGr1 = false;
            }

            if(this.intIndirectPageNumber == 1) {
                this.booIsFirstPageIndirect = true;
            }
            else{
                this.booIsFirstPageIndirect = false;
            }
            if(this.intIndirectPageNumber == this.intIndirectPageTotal) {
                this.booIsLastPageIndirect = true;
            }
            else{
                this.booIsLastPageIndirect = false;
            }
        }
        
    }

    prevPageDirect() {
        this.editPageValuehelper('intDirectPage',-1);
        this.setPage('intDirectPage');
        this.checkButtonVisibility('intDirectPage');
    }

    nextPageDirect() {
        this.editPageValuehelper('intDirectPage',+1);
        this.setPage('intDirectPage');
        this.checkButtonVisibility('intDirectPage');

    }

    prevPageIndirect() {
        this.editPageValuehelper('intIndirectPage',-1);
        this.setPage('intIndirectPage');
        this.checkButtonVisibility('intIndirectPage');

    }

    nextPageIndirect() {
        this.editPageValuehelper('intIndirectPage',1);
        this.setPage('intIndirectPage');
        this.checkButtonVisibility('intIndirectPage');
    }

    handleSearchText(event) {
        this.strSearchName = event.target.value;
        if(this.strSearchName == '') {
            this.booSearchDisable = true;
        }
        else {
            this.booSearchDisable = false;
        }

    }

    search() {
        this.boolstIndirectEmpty = true;
        this.booShowSpinner = true;
        let lstDirect = this.lstDirectFull.reduce(function(lstIds,objWrap){
            lstIds.push(objWrap.strRecordId);
            return lstIds;
        },
        []);

        let params = {
            strQuoteId: this.recordId,
            lstDirectCMDIds : lstDirect, 
            strType : this.strType,
            booDirectDeal : this.booDirectDeal,
            strName : this.strSearchName,
            strUCCountry: this.strUCCountry,
            strSalesArea: this.strSalesArea
        };
        consoleLog('@@@ Params @@@', params);
        let bypassShowToast = true;
        let mapLabels = this.mapLabels;
        this.lstIndirect = [];
        callServer(searchIndirectCMD, params
            , response => {
                response = JSON.parse(response);
                consoleLog('@@@ Response @@@', response);
                this.lstIndirectFull = response;

                if(isNotEmpty(response)) {
                    this.boolstIndirectEmpty = false;
                    this.sortData(this.sortByIndirect, this.sortDirectionIndirect, 'intIndirectPage');
                    consoleLog('Total Pages for Outside Relations: ' + this.intIndirectPageTotal)
                    this.checkButtonVisibility('intIndirectPage');
                }
                this.booShowSpinner = false;
            },error => {
                if(SEARCHERRORS.some(e=>error.body.message.includes(e))) {
                    showErrorToast( mapLabels.UI_ErrorMessage_Refine_Search);
                    this.booShowSpinner = false;
                    return;
                } else {
                    this.handleError(error);
                }
        },bypassShowToast);
}

    handleSelectionDirect(event) {
        let idSave = event.detail.id.split("-")[0];
        this.lstSelectionsDirect = [];
        this.lstSelectionsDirect = this.lstDirect.slice(idSave, idSave+1);
        consoleLog('@@@ Selected Record Direct @@@', this.lstSelectionsDirect);
        this.saveDirect();

    }

    handleSelectionIndirect(event) {
        let idSave = event.detail.id.split("-")[0];
        this.lstSelectionsIndirect = [];
        this.lstSelectionsIndirect = this.lstIndirect.slice(idSave, idSave+1);
        consoleLog('@@@ Selected Record Indirect @@@', this.lstSelectionsIndirect);
        this.saveIndirect();

    }

    getSelectedRowDirect(event) {
        const selectedRows = event.detail.selectedRows;
        this.lstSelectionsDirect = selectedRows;
        if(isNotEmpty(event.detail.selectedRows)) {
            let returnString = {
                "selectedRows":event.detail.selectedRows
            };
            const sendValues = new CustomEvent('directrowselection',{ detail : returnString
            });
            this.dispatchEvent(sendValues);
        }
    }

    getSelectedRowIndirect(event) {
        const selectedRows = event.detail.selectedRows;
        this.lstSelectionsIndirect = selectedRows;
        if(isNotEmpty(event.detail.selectedRows)) {
            let returnString = {
                "selectedRows":event.detail.selectedRows
            };
            const sendValues = new CustomEvent('indirectrowselection',{ detail : returnString
            });
            this.dispatchEvent(sendValues);
        }
    }

    saveDirect() {
        this.save('direct');
    }
    saveIndirect() {
        this.save('indirect');
    }

    save(strListId) {
        this.booShowSpinner = true;
        let lstSelections;
        lstSelections = this.lstSelectionsDirect;
        if(strListId == 'indirect') {
            lstSelections = this.lstSelectionsIndirect;
        }

        consoleLog('@@@ Selected Row @@@', lstSelections);
        let mapLabels = this.mapLabels;
        getRecordNotifyChange([{recordId: this.recordId}]);
        let objQuote = this.objQuote;
        let setInvalidStages = new Set ([mapLabels.QuoteStageInReview,
                                        mapLabels.QuoteStageAccepted,
                                        mapLabels.QuoteStageApproved,
                                        mapLabels.QuoteStageGenerated,
                                        mapLabels.QuoteStagePresented]);


        if(setInvalidStages.has(objQuote.Apttus_Proposal__Approval_Stage__c)) {
            this.showErrorOnClick(mapLabels);
        }

        let strError = ""; 
        if(objQuote.Invalid_Quote__c) {
            strError=mapLabels.UI_InvalidQuoteError;
        }

        if(isNotBlank(strError)) {
            this.showErrorAndQuit(strError);
            this.booShowSpinner = false;
            return;
        }
        this.validateAndSave(mapLabels, lstSelections, objQuote);

    }

    validateAndSave(mapLabels,lstSelections,objQuote) {
        let strError = "";
        let booDirectDeal = this.booDirectDeal;
        if(isEmpty(lstSelections)) {
            strError=mapLabels.UI_ErrorMessage_Select_Record;
        }
        else if(lstSelections[0].strIcon) {
            if(this.strType === mapLabels.AccountRelationshipBillTo) {
                strError = mapLabels.UI_Disclaimer;
            }
            else {
                strError = mapLabels.UI_ErrorMessage_Direct_Ship_To_Invalid_Country;
            }
        }

        if(isNotBlank(strError)) {
            showErrorToast(strError);
            this.booShowSpinner = false;
            return;
        }
        if (!objQuote.Is_Updated_By_System__c){
            objQuote.Is_Updated_By_System__c = true;
        }
        if(this.strType === mapLabels.AccountRelationshipBillTo) {
            objQuote.Bill_To__c = lstSelections[0].strRecordId;

            if(lstSelections[0].strAccountGroup === mapLabels.AccountGroupPayer){
                objQuote.Payer__c = lstSelections[0].strRecordId;
                objQuote.Apttus_Proposal__Payment_Term__c = lstSelections[0].strPaymentTerms;
            }
        }

        if(this.strType === mapLabels.AccountRelationshipShipTo){
            objQuote.Ship_To__c = lstSelections[0].strRecordId;
            if(this.booAppReqQuote && !booDirectDeal) {
                objQuote.Apttus_Proposal__Approval_Stage__c = mapLabels.QuoteStageDraft;
                objQuote.Apttus_QPApprov__Approval_Status__c = mapLabels.QuoteApprovalStatusNone;
            }
        }
        let params = {
            "strQuoteJSON" : JSON.stringify(objQuote),
            "strJSON" : JSON.stringify(lstSelections[0]),
            "strType" : this.strType,
            "booDirectDeal" : booDirectDeal,
            "strASA" : this.strSalesArea
        };

        callServer(saveSelection, params
            , response => {
                if(response !== 'Success'){
                    showErrorToast(response);
                    this.booShowSpinner = false;
                    return;
                }
                consoleLog('Started Refresh');
                getRecordNotifyChange([{recordId: this.recordId}]);
                consoleLog('Success');
                this.booShowSpinner = false;
                setTimeout(function(){
                    showSuccessToast(mapLabels.UI_Label_Save_Success);
                }, '350');
                this.navigateToViewProposalPage();
        }, error => {
            this.handleError(error); 
        });
             
    }

    @api validaterecords(strListId) {
        let strError = "";
        this.booShowSpinner = true;       
        this.lstSelectionsFinal = this.lstSelectionsDirect;
        if(strListId == 'indirect') {
            this.lstSelectionsFinal = this.lstSelectionsIndirect;
        }
        consoleLog('this.lstSelectionsFinal '+this.lstSelectionsFinal );
        let mapLabels = this.mapLabels;
        getRecordNotifyChange([{recordId: this.recordId}]);
        let objQuote = this.objQuote;
        let setInvalidStages = new Set ([mapLabels.QuoteStageInReview,
                                        mapLabels.QuoteStageAccepted,
                                        mapLabels.QuoteStageApproved,
                                        mapLabels.QuoteStageGenerated,
                                        mapLabels.QuoteStagePresented]);

           
        if(setInvalidStages.has(objQuote.Apttus_Proposal__Approval_Stage__c)) {
            this.booShowSpinner = false;
            this.showErrorOnClick(mapLabels);            
        }
        
        if(objQuote.Invalid_Quote__c) {
            strError=mapLabels.UI_InvalidQuoteError;
            this.booShowSpinner = false;
            return strError;
        }
        if(isEmpty(this.lstSelectionsFinal)) {
            strError=mapLabels.UI_ErrorMessage_Select_Record;
            this.booShowSpinner = false;
            return strError;
        }
        else if(this.lstSelectionsFinal[0].strIcon) {
            if(this.strType === mapLabels.AccountRelationshipBillTo) {
                strError = mapLabels.UI_Disclaimer;
                this.booShowSpinner = false;
                return strError;
            }
            else {
                 strError = mapLabels.UI_ErrorMessage_Direct_Ship_To_Invalid_Country;
                this.booShowSpinner = false;
                return strError;
            }
        }
        this.booShowSpinner = false;
       return null;
    }
    @api getBillToShipToRelatedData() {
        let strJSON = this.lstSelectionsFinal != null ? JSON.stringify(this.lstSelectionsFinal[0]) : null;
        let selectedListName = this.lstSelectionsFinal != null ? this.lstSelectionsFinal[0].strName : null;
        let selectedListERP = this.lstSelectionsFinal != null ? this.lstSelectionsFinal[0].strERP : null;
        let selectedFinalList = this.lstSelectionsFinal != null ? this.lstSelectionsFinal[0] : null;
       let params = {
           "quoteObj" : this.objQuote,
           "strJSON" : strJSON,
           "strType" : this.strType,
           "booDirectDeal" : this.booDirectDeal,
           "strASA" : this.strSalesArea,
           "selectedListName" :  selectedListName,
           "selectedFinalList" : selectedFinalList,
           "mapLabels" : this.mapLabels,
           "selectedListERP" : selectedListERP,
           "booAppReqQuote" : this.booAppReqQuote
       };
       return params;
   }
   @api getQuoteRecord() {
        return this.quoteRecord;
   }    

    setVisibilityDirect(event){
        let testRowIndex = event.detail.index;
        this.lstDirect[testRowIndex].isVisible = event.detail.selectedValue;
        this.setVisibility(this.lstDirect, testRowIndex);
    }

    setVisibilityIndirect(event){
        let testRowIndex = event.detail.index;
        this.lstIndirect[testRowIndex].isVisible = event.detail.selectedValue;
        this.setVisibility(this.lstIndirect, testRowIndex);
    }

    setVisibility(lstdata, testRowIndex){
        for(let i=0;i<lstdata.length;i++){
            if(i != testRowIndex){
                lstdata[i].isVisible = false;
            }
        }
    }

    handleError(error) {
        this.booShowSpinner = false;
    }

}
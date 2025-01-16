import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import saveSelection from '@salesforce/apex/CustomerMasterDataSelectionController.saveSelection';
import { callServer,showErrorToast,showSuccessToast,consoleLog,isNotBlank,isEmpty,isNotEmpty} from 'c/utils';

import UI_StaticText from '@salesforce/label/c.UI_CMD_BillTo_ShipTo_Statictext';
import UI_Button_Save from '@salesforce/label/c.UI_Button_CMD_BillTo_ShipTo_Save';
import UI_SaveSuccess from '@salesforce/label/c.UI_Label_Save_Success';
import UI_Button_Cancel_Modal from '@salesforce/label/c.UI_Button_Cancel';
import UI_Button_Ok_Modal from '@salesforce/label/c.UI_Button_Ok';
import UI_BillTo_ShipTo_Confirmation from '@salesforce/label/c.UI_BillTo_ShipTo_Confirmation_message';
import UI_ErrorMessage_SelectRecord from '@salesforce/label/c.UI_ErrorMessage_Select_Record';

export default class customerMasterDataParent extends NavigationMixin(LightningElement) {
    @api recordId;
    @api headercolor;
    @ track lstSelectionsDirectBillTo = [];
    @ track lstSelectionsInDirectBillTo = [];
    @ track lstSelectionsDirectShipTo = [];
    @ track lstSelectionsInDirectShipTo = [];
    @track showModal = false;
    @track modalBody = '';
    @track modalBodyBT = '';
    @track modalBodyST = '';
    @track showBT = false;
    @track showST = false;
    @track booShowSpinner = false;
    errorBillTo;
    errorShipTo;
    billToParam;
    shipToParam;
    quoteRecord;
    components;
    testinput = '';
    
    label = {
        UI_StaticText,
        UI_Button_Save,
        UI_SaveSuccess,
        UI_Button_Cancel_Modal,
        UI_Button_Ok_Modal,
        UI_ErrorMessage_SelectRecord,
        UI_BillTo_ShipTo_Confirmation
    };
    
    getSelecteddirectRowsBillto(event) {
        const selectedRows = event.detail.selectedRows;
       
        this.lstSelectionsDirectBillTo = selectedRows;
    }
    getSelectedIndirectRowsBillto(event) {
        const selectedRows = event.detail.selectedRows;
        consoleLog("billtodirect"+event.detail.selectedRows);
        this.lstSelectionsInDirectBillTo = selectedRows;
    }
    getSelecteddirectRowsShipto(event) {
        const selectedRows = event.detail.selectedRows;
        this.lstSelectionsDirectShipTo = selectedRows;
    }
    getSelectedIndirectRowsShipto(event) {
        const selectedRows = event.detail.selectedRows;
        this.lstSelectionsInDirectShipTo = selectedRows;
    }   
    saveRows(){             
        this.components = this.template.querySelectorAll('c-customer-master-data-l-w-c');
        if(isEmpty(this.lstSelectionsInDirectBillTo)) {
            this.errorBillTo = this.components[1].validaterecords('direct');
        }
        else {
            this.errorBillTo = this.components[1].validaterecords('indirect');
        }
        if(isEmpty(this.lstSelectionsInDirectShipTo)) {
            this.errorShipTo = this.components[0].validaterecords('direct');
        }
        else {
            this.errorShipTo = this.components[0].validaterecords('indirect');
        }      
        if(this.errorBillTo != null && this.errorShipTo != null)
        {
            showErrorToast('For BillTo: ' + this.errorBillTo + '\n For ShipTo: ' + this.errorShipTo);
            return;
        }
        else{
            if(this.errorBillTo != null &&  this.errorBillTo != this.label.UI_ErrorMessage_SelectRecord) {
                showErrorToast('For BillTo: ' + this.errorBillTo);
                return;
                
            } else {
                this.billToParam = this.components[1].getBillToShipToRelatedData();
            }           
            if(this.errorShipTo != null && this.errorShipTo != this.label.UI_ErrorMessage_SelectRecord) {
                showErrorToast('For ShipTo: ' + this.errorShipTo);
                return;
            }else {
                this.shipToParam = this.components[0].getBillToShipToRelatedData(); 
            }    
           
        } 
        this.quoteRecord = this.components[0].getQuoteRecord(); 
                
        if(this.billToParam.selectedListName !== null && this.shipToParam.selectedListName !== null) {
            this.showBT = true;
            this.showST = true;
           this.modalBodyBT = this.billToParam.selectedListName + ' (' + this.billToParam.selectedListERP + ')'; 
           this.modalBodyST = this.shipToParam.selectedListName + ' (' + this.shipToParam.selectedListERP + ')';          
            
        } else {
            if(this.billToParam.selectedListName !== null) {
                this.showBT = true;
                this.modalBodyBT = this.billToParam.selectedListName + ' (' + this.billToParam.selectedListERP + ')'; 
                
            }
            if(this.shipToParam.selectedListName !== null) {
                this.showST = true;
                this.modalBodyST = this.shipToParam.selectedListName + ' (' + this.shipToParam.selectedListERP + ')';
               // this.modalBody = this.label.uiBillToShipToConfirmation + '<br/>ShipTo:' + this.shipToParam.selectedListName+ '(' + this.shipToParam.selectedListERP + ')';
            }
        } 
        this.showModal = true; 
        
    }

    
    saveselectedrecords(billToParam,shipToParam) {
        let objQuote = billToParam != null ? billToParam.quoteObj : shipToParam.quoteObj;
        let booDirectDeal = billToParam != null ? billToParam.booDirectDeal : shipToParam.booDirectDeal;
        let mapLabels = billToParam != null ? billToParam.mapLabels : shipToParam.mapLabels;
        let booAppReqQuote = billToParam != null ? billToParam.booAppReqQuote : shipToParam.booAppReqQuote;
        let strJSONBillTo;
        let strJSONShipTo;
        let saveSuccess = this.label.UI_SaveSuccess;
        if (!objQuote.Is_Updated_By_System__c){
           objQuote.Is_Updated_By_System__c = true;
       }
       if(billToParam != null && billToParam.selectedFinalList != null) {
           objQuote.Bill_To__c =  billToParam.selectedFinalList.strRecordId;
           if(billToParam.selectedFinalList.strAccountGroup === mapLabels.AccountGroupPayer){
               objQuote.Payer__c =  billToParam.selectedFinalList.strRecordId;
               objQuote.Apttus_Proposal__Payment_Term__c = billToParam.selectedFinalList.strPaymentTerms;
           }
           strJSONBillTo = billToParam.strJSON;
       }

       if(shipToParam != null && shipToParam.selectedFinalList != null){
           objQuote.Ship_To__c =  shipToParam.selectedFinalList.strRecordId;
           if(booAppReqQuote && !booDirectDeal) {
               objQuote.Apttus_Proposal__Approval_Stage__c = mapLabels.QuoteStageDraft;
               objQuote.Apttus_QPApprov__Approval_Status__c = mapLabels.QuoteApprovalStatusNone;
           }
           strJSONShipTo = shipToParam.strJSON;
       }
        this.booShowSpinner = true;
        let params = {
            "strQuoteJSON" : JSON.stringify(objQuote),
            "strJSONBillTo" : strJSONBillTo,
            "strJSONShipTo" : strJSONShipTo,
            "strType" : billToParam.strType,
            "booDirectDeal" : billToParam.booDirectDeal,
            "strASA" : billToParam.strASA
        }; 
        callServer(saveSelection, params
            , response => {
                if(response !== 'Success'){
                    this.handleServerError(response);
                    return;                   
                }
                consoleLog('Started Refresh');
                this.booShowSpinner = false;
                setTimeout(function(){
                    showSuccessToast(saveSuccess);
                }, '350');                
                this.navigatedToViewProposalPage();               
                          
        }, error => {
            this.handleError(error);
        });
    }

    navigatedToViewProposalPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Apttus_Proposal__Proposal__c',
                actionName: 'view'
            },
        });
    }

    handleServerError(errormsg) {
        if(errormsg.includes(";")) {
            let errorList = errormsg.split(",");
            showErrorToast(errorList[0]);
            showErrorToast(errorList[1]);
            this.booShowSpinner = false;
        }
        else
        {
            showErrorToast(errormsg);
            this.booShowSpinner = false;
        }
    }


    handleError(error) {
        this.booShowSpinner = false;
    }

    closeModal() {
        this.showModal = false;
    }
    proceedModal() {
        this.booShowSpinner = true;
        this.showModal = false;
        this.saveselectedrecords(this.billToParam,this.shipToParam);
    }

}
import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import ERP_CUSTOMER_ID_FIELD from "@salesforce/schema/Account.ERP_Customer_Id__c";
import UI_IVDR_Document_Header from '@salesforce/label/c.UI_IVDR_Document_Header';
import UI_IVDR_SalesOrder_StartDate_Undefined_Error from '@salesforce/label/c.UI_IVDR_SalesOrder_StartDate_Undefined_Error';
import UI_IVDR_GreaterEndDate_Error from '@salesforce/label/c.UI_IVDR_GreaterEndDate_Error';
import UI_IVDR_GreaterStartDate_Error from '@salesforce/label/c.UI_IVDR_GreaterStartDate_Error';
import IVDR_Insufficent_Access_Message from '@salesforce/label/c.IVDR_Insufficent_Access_Message';
import UI_IVDR_EndDate_StartDate_Range_Error from '@salesforce/label/c.UI_IVDR_EndDate_StartDate_Range_Error';
import UI_IVDR_No_Results_Error from '@salesforce/label/c.UI_IVDR_No_Results_Error';
import fetchSalesOrderDetails from '@salesforce/apex/IVDRDocumentSearchController.fetchSalesOrderDetailsFromSAP';
import downloadSalesOrderDetails from '@salesforce/apex/IVDRDocumentSearchController.downloadSalesOrderDetails';
import checkCPProfile from '@salesforce/apex/IVDRDocumentSearchController.checkCPProfile';
import { showErrorToast, showSuccessToast, callServer, consoleError } from 'c/utils';
import { columns } from './column.js';


const fields = [NAME_FIELD, ERP_CUSTOMER_ID_FIELD];
export default class IVDRDocumentSearch extends LightningElement {
    @track showSpinner = true; //Spinner
    @track strToggleSpinnerClass = 'slds-hide';
    @api recordId; //holds current record's Id
    @api wrapperData=[]; //variable that holds returned wrapper data
    @track renderResults = false;  // variable for data table rendering
    @track salesOrder; //holds Sales Order value    
    @track startDate; //holds Start Date value
    @track objData = []; //holds salesorder details
    @track showComponent; //variable to show the component
    @track strHideCmp = 'slds-hide'; //variable to hide the component
    @track columns = columns; //table columns
    @track eDate; 
    //holds current date value
    todaysDate = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate(); 
    //cutsom labels to display validation errors
    label = {
        UI_IVDR_Document_Header, UI_IVDR_No_Results_Error, IVDR_Insufficent_Access_Message, UI_IVDR_GreaterStartDate_Error, UI_IVDR_GreaterEndDate_Error, UI_IVDR_SalesOrder_StartDate_Undefined_Error, UI_IVDR_EndDate_StartDate_Range_Error 
    };
    wiredsObjectData;
    @track stream;

    
    /*
    * Method Name: connectedCallback
    * Description: Method to get initiated on the component load.          
    */
    connectedCallback(){
        this.strToggleSpinnerClass = 'slds-hide';
        this.columns = columns;
        this.endDate = this.todaysDate;
        this.checkProfile();
    }

    /*
    * Method Name: checkProfile
    * Description: Method to check for CP Profile.               
    */
    checkProfile(){
        this.strToggleSpinnerClass = 'slds-show';
        callServer(checkCPProfile,{},
        data =>{
            if(data === true){
                this.strToggleSpinnerClass = 'slds-hide';
                this.strHideCmp = 'slds-hide';
                this.showComponent = true;
            }else{
                this.strToggleSpinnerClass = 'slds-hide';
                this.strHideCmp = 'slds-show';
                this.showComponent = false;
                showErrorToast(IVDR_Insufficent_Access_Message);
            }
        }, error => {
            showErrorToast(JSON.stringify(error));
            consoleError('error ', JSON.stringify(error));
            this.strToggleSpinnerClass = 'slds-hide';
        }); 
    }

    /*
    * Method Name: getRecord
    * Description: Method to get Account fields and display Account name.            
    */
    @wire(getRecord, {recordId: "$recordId", fields})
    account;

    get name() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    /*
    * Method Name: handleSearch
    * Description: Method to throw custom validations.              
    */
    handleSearch() {
        //To get input element value
        this.getInputElement('lightning-input');
        let templateStartDate = this.template.querySelector(".inputClassStartDate");
        let templateEndDate = this.template.querySelector(".inputClassEndDate");
        let templateSalesOrder = this.template.querySelector(".inputClassSalesOrder");
        let days = Math.ceil((new Date(this.eDate) - new Date(this.startDate)) / 8.64e7);
        let endDaysDiff = Math.ceil((new Date(this.endDate) - new Date(this.eDate)) / 8.64e7);
        let greaterEDate;
        let greaterSDate;
        console.log('difference in dates are-->' + days+'--enddaysdiff-->'+endDaysDiff);
        //Validation method to check the End Date is not greater than todays Date
        greaterEDate = this.checkGreaterEndDate(templateEndDate,this.eDate,endDaysDiff);
        if(this.salesOrder === ''){
            if(this.startDate === ''){
                templateStartDate.setCustomValidity(UI_IVDR_SalesOrder_StartDate_Undefined_Error);
                templateSalesOrder.setCustomValidity(UI_IVDR_SalesOrder_StartDate_Undefined_Error);
            }else{
                templateStartDate.setCustomValidity('');
                templateSalesOrder.setCustomValidity('');
                //Validation method to check the Start Date is not greater than End Date
                greaterSDate = this.checkGreaterStartDate(templateStartDate,this.startDate,this.eDate,days);
                if(greaterEDate === false && greaterSDate === false){
                    //Check StartDate is defined or null and call throwDaysRangeError method
                    this.checkStartDateNull(this.startDate,days,templateStartDate,templateEndDate);
                }
            }
        }else{
            templateStartDate.setCustomValidity('');
            templateSalesOrder.setCustomValidity('');
            templateEndDate.setCustomValidity('');
            //Show data when SalesOrder/StartDate is defined
            this.showDataWithStartDateOrSalesOrder(greaterEDate,this.startDate,days,templateEndDate,templateStartDate);
        }
            templateSalesOrder.reportValidity();
            templateStartDate.reportValidity();
            templateEndDate.reportValidity();
    }

    /*
    * Method Name: showDataWithStartDateOrSalesOrder
    * Description: Show data when SalesOrder/StartDate is defined(Splitting to fix Code Scan Issue).               
    */
    showDataWithStartDateOrSalesOrder(greaterEDate,startDate,days,templateEndDate,templateStartDate) {
        if(greaterEDate === false && (startDate === null || days >=0 && days <= 14 || startDate === '')){
            templateEndDate.setCustomValidity('');
            this.handlefetchSalesOrderDetails();
        }else{
            if(greaterEDate === true){
                templateEndDate.setCustomValidity(UI_IVDR_GreaterEndDate_Error);
            }else if(days <0){
                templateStartDate.setCustomValidity(UI_IVDR_GreaterStartDate_Error);
            }
            else{
                templateEndDate.setCustomValidity(UI_IVDR_EndDate_StartDate_Range_Error);
            }
        }
        templateStartDate.reportValidity();
        templateEndDate.reportValidity();
    }

    /*
    * Method Name: checkStartDateNull
    * Description: Check StartDate is defined or null and call throwDaysRangeError method(Splitting to fix Code Scan Issue).               
    */
    checkStartDateNull(startDate,days,templateStartDate,templateEndDate) {
        if(startDate === null){
            templateStartDate.setCustomValidity(UI_IVDR_SalesOrder_StartDate_Undefined_Error);
        } else {
            templateStartDate.setCustomValidity('');
            //Validation to check the date difference between Start date and End date is not more that 14 days
            this.throwDaysRangeError(days,templateEndDate);
        }
        templateStartDate.reportValidity();
    }

    /*
    * Method Name: checkGreaterEndDate
    * Description: Validation method to check the End Date is not greater than todays Date(Splitting to fix Code Scan Issue).               
    */
    checkGreaterEndDate(templateEndDate,eDate,endDaysDiff) {

        let CurrentDate = new Date();
        let greaterDate;
        if(new Date(eDate)>new Date(CurrentDate)){
            templateEndDate.setCustomValidity(UI_IVDR_GreaterEndDate_Error);
            greaterDate = true;
        }else{
            templateEndDate.setCustomValidity(''); 
            greaterDate = false;
        }
        if(endDaysDiff === 0){
            templateEndDate.setCustomValidity(''); 
            greaterDate = false;
        }
        templateEndDate.reportValidity();
        return greaterDate;
    }

    /*
    * Method Name: checkGreaterStartDate
    * Description: Validation method to check the Start Date is not greater than End Date(Splitting to fix Code Scan Issue).               
    */
    checkGreaterStartDate(templateStartDate,startDate,eDate,days) {

        let greaterStrtDate;
        if(new Date(startDate)>new Date(eDate) || days <0 ){    
            templateStartDate.setCustomValidity(UI_IVDR_GreaterStartDate_Error);
            greaterStrtDate = true;
        }else{
            templateStartDate.setCustomValidity('');
            greaterStrtDate = false;
        }
        if(days === 0){
            templateStartDate.setCustomValidity('');
            greaterStrtDate = false;
        }
        templateStartDate.reportValidity();
        return greaterStrtDate;
    }

    /*
    * Method Name: throwDaysRangeError
    * Description: Validation to check the date difference between Start date and End date is not more that 14 days.               
    * (Splitting to fix Code Scan Issue)
    */
    throwDaysRangeError(days,templateEndDate) {
        if (days > 14) {
            this.renderResults = false;
            templateEndDate.setCustomValidity(UI_IVDR_EndDate_StartDate_Range_Error);
        } else{
            templateEndDate.setCustomValidity('');
            this.handlefetchSalesOrderDetails();
        }
        templateEndDate.reportValidity();
    }

    /*
    * Method Name: handlefetchSalesOrderDetails
    * Description: Method  called by the HandleSearch method to make the first callout by passing the field values and 
    *              display the Returned Data with the response returned.              
    */
    handlefetchSalesOrderDetails(){
        this.renderResults = false;
        this.objData = [];
        this.strToggleSpinnerClass = 'slds-show';
        let customerErp = getFieldValue(this.account.data, ERP_CUSTOMER_ID_FIELD);
        if(customerErp === null || customerErp === '' || customerErp === undefined ){
            showErrorToast('ERP Customer ID cannot be blank');
            this.strToggleSpinnerClass = 'slds-hide';
        }else{
            if(this.eDate === null){
            this.eDate = this.endDate;
            }
            let sObj = { 'sobjectType': 'IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper' }; 
                sObj.salesOrder = this.salesOrder;
                sObj.startDate = this.startDate;
                sObj.endDate = this.eDate;
                sObj.erpCustomer = customerErp;
                sObj.id = this.recordId;
                this.objData.push(sObj);
                console.log('objdata--'+JSON.stringify(this.objData));
            callServer(fetchSalesOrderDetails,{ strOrderDetails: JSON.stringify(this.objData)},
            data =>{
                let dataRetunred = [];
                dataRetunred = JSON.parse(data);
                this.wrapperData = [];
                console.log('len--'+dataRetunred.length+'data--'+JSON.stringify(dataRetunred));

                if (dataRetunred.length === 0) {
                    this.strToggleSpinnerClass = 'slds-hide';
                    console.log('entered no runs');
                    this.renderResults = false;
                    showErrorToast(UI_IVDR_No_Results_Error);
                }
                else if(dataRetunred.length === 1){
                    this.tableDataReturned(dataRetunred);
                }else{
                    this.strToggleSpinnerClass = 'slds-hide';
                    this.wrapperData = dataRetunred;
                    this.renderResults = true;
                    showSuccessToast('');
                }

                this.objData = [];
                

            }, error => {
                showErrorToast(JSON.stringify(error));
                consoleError('error ', JSON.stringify(error));
                this.strToggleSpinnerClass = 'slds-hide';
            });        
        }   
    }

    /*
    * Method Name: tableDataReturned
    * Description: Method when the table data returns with a single record(Splitting to fix Code Scan Issue).               
    */
    tableDataReturned(dataRetunred) {
        let errorMessage;
        this.strToggleSpinnerClass = 'slds-hide';
        dataRetunred.forEach((rec)=>{
            if(rec.value !== null){
                errorMessage = rec.value;
            }
        });
        if(errorMessage){
            showErrorToast(errorMessage);
            this.strToggleSpinnerClass = 'slds-hide';
            this.renderResults = false;
        }else{
            this.strToggleSpinnerClass = 'slds-hide';
            this.wrapperData = dataRetunred;
            this.renderResults = true;
            showSuccessToast('');
        }
    }


    /*
    * Method Name: handleRowAction
    * Description: Method to make the second callout and download the SalesOrder information
    */
    handleRowAction(event) {
        const rowDetail = event.detail.value;
        this.strToggleSpinnerClass = 'slds-show';
        let rowData = [];
        if(rowDetail.Delivery === null || rowDetail.Delivery === '' || rowDetail.Delivery === undefined ){
            showErrorToast('Select a row with Delivery Number');
            this.strToggleSpinnerClass = 'slds-hide';
        }else{
            let sObj = { 'sobjectType': 'IVDRDocumentSearchResponseWrapper.results' }; 
                sObj.SalesOrder = rowDetail.SalesOrder;
                sObj.Customer = rowDetail.Customer;
                sObj.Delivery = rowDetail.Delivery;
                sObj.id = this.recordId;
            rowData.push(sObj);
            callServer(downloadSalesOrderDetails,{ strOrderDetails: JSON.stringify(rowData)},
            data =>{
                //this.strToggleSpinnerClass = 'slds-hide';
                let dataRetunred = [];
                dataRetunred = JSON.parse(data);
                if (data.length === 0) {
                    this.strToggleSpinnerClass = 'slds-hide';
                    showErrorToast(UI_IVDR_No_Results_Error);
                }
                else if(dataRetunred.length === 1){
                    this.streamDataReturned(dataRetunred);
                }else{
                    dataRetunred.forEach((rec)=>{
                        const pdfBytes = this.base64ToArrayBuffer(rec.Stream);
                        this.saveByteArray("IVDR_Document.pdf", pdfBytes);
                    });
                    showSuccessToast('');
                }

                rowData = [];
            }, error => {
                showErrorToast(JSON.stringify(error));
                consoleError('error ', JSON.stringify(error));
                this.strToggleSpinnerClass = 'slds-hide';
            }); 
        }
    }

    /*
    * Method Name: streamDataReturned
    * Description: Method when the stream data returns with a single record(Splitting to fix Code Scan Issue).               
    */
    streamDataReturned(dataRetunred) {
        this.stream = '';
        let errorMessage;
        this.strToggleSpinnerClass = 'slds-hide';
        dataRetunred.forEach((rec)=>{
            if(rec.value !== null){
                errorMessage = rec.value;
            }
            this.stream = rec.Stream;
        });
        if(errorMessage){
            showErrorToast(errorMessage);
            this.strToggleSpinnerClass = 'slds-hide';
        }else{
            this.strToggleSpinnerClass = 'slds-hide';
            showSuccessToast('');
            console.log('stream--'+this.stream);
            const pdfBytes = this.base64ToArrayBuffer(this.stream);
            this.saveByteArray("IVDR_Document.pdf", pdfBytes);
        }
    }

    /*
    * Method Name: base64ToArrayBuffer
    * Description: Method to convert string data into base64.               
    */
    /*global Uint8Array */
    base64ToArrayBuffer(base64) {
        let binary_string = window.atob(base64);
        let len = binary_string.length;
        let bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
            bytes[i] = binary_string.charCodeAt(i);
        }
        return bytes.buffer;
    }

    /*
    * Method Name: saveByteArray
    * Description: Method to download base64 data to PDF.               
    */
    saveByteArray(pdfName, byte) {
        let blob = new Blob([byte], { type: "application/pdf" });
        let link = document.createElement("a");
        link.href = window.URL.createObjectURL(blob);
        let fileName = pdfName;
        link.download = fileName;
        link.click();
    }

    /*
    * Method Name: handleReset
    * Description: Method to reset the data.               
    */
    handleReset(){
        consoleError('Inside Handle Reset');

        let templateEndDate = this.template.querySelector(".inputClassEndDate");
        let templateStartDate = this.template.querySelector(".inputClassStartDate");
        let templateSalesOrder = this.template.querySelector(".inputClassSalesOrder");
        templateEndDate.setCustomValidity('');
        templateStartDate.setCustomValidity('');
        templateSalesOrder.setCustomValidity('');
        templateEndDate.reportValidity();
        templateStartDate.reportValidity();
        templateSalesOrder.reportValidity();

        this.template.querySelectorAll("lightning-input").forEach(function(element) {
            if (element.name === 'input-3-Start-Date') {
                element.value = undefined;
            }       
        },this);
        this.template.querySelectorAll("lightning-input").forEach(function(element) {
           if (element.name === 'input-4-End-Date') {
            element.value = this.endDate;
            }
        },this);
        this.template.querySelectorAll("lightning-input").forEach(function(element) {
             if (element.name === 'input-2-Sales-Order') {
                element.value = undefined;
             }
         },this);

    }

    /*
    * Method Name: getInputElement
    * Description: To get input element value(Splitting  to fix Code Scan Issue).              
    */
    getInputElement(inputParam) { 
        let elementValue;
        this.template.querySelectorAll(inputParam).forEach(function(element) {
            if (element.name === 'input-3-Start-Date') {
                this.startDate = element.value;
            } 
            if (element.name === 'input-4-End-Date') {
                this.eDate = element.value;
            }
            if (element.name === 'input-2-Sales-Order') {
                this.salesOrder = element.value;
            }

            elementValue = element.value;
        },this);
        return elementValue;
    }
    
}
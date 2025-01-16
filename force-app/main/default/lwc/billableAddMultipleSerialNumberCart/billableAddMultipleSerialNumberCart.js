import { LightningElement,api,track} from 'lwc';
import {
    showErrorToast,
    showSuccessToast,
    consoleLog,
    isNotEmpty,
    consoleError,
    callServer,
    isBlank,
    isEmpty,
    isNotBlank
} from 'c/utils';
import initRecord from '@salesforce/apex/BillableAddMultipleSerialNumberCtrl.initRecord';
import UI_Label_Serial_Number_Selection from '@salesforce/label/c.UI_Label_Serial_Number_Selection';
import Button_Back_To_Cart from '@salesforce/label/c.Button_Back_To_Cart';
export default class BillableAddMultipleSerialNumberCart extends LightningElement {
    @api idProductConfigId;
    @track selectedLineItemDetails;
    @track selectedSerialNumber;
    idCurrentUC;
    lstLineItem;
    mapLabels;
    titleStyle;
    selectedLineItem;
    availableIP;
    booLoadingData = true;
    message = '';
    showInstalledProductList = false;
    @track boolIsRelocation;
    visible = false;
    queryTerm = '';
    label = {
        UI_Label_Serial_Number_Selection,
        Button_Back_To_Cart
    };
    // Connected Callback
    connectedCallback(){
        this.initializeDetails();
    }
    // Fetch and update variable during load
    initializeDetails(){
        this.booLoadingData = true;
        callServer(initRecord, {
            recordId: this.idProductConfigId
        }, result => {
            if (isNotBlank(result)) {
                this.returndata = JSON.parse(result);
                consoleLog('Data = ',this.returndata);
                this.lstLineItem = this.returndata.lstLineDetails;
                this.mapLabels = this.returndata.mapLabels;
                this.idCurrentUC = this.returndata.idCurrentUCId;
                this.boolIsRelocation = this.returndata.boolIsRelocation;
                consoleLog('boolIsRelocation = ',this.boolIsRelocation);
                let context = this;
                setTimeout(function(){
                    if(context.boolIsRelocation){
                        context.booLoadingData = false;
                        context.visible = false;
                    }
                    else{
                        context.message = context.mapLabels.UI_Message_Available_For_Relocation;
                        context.booLoadingData = false;
                        context.visible = true;
                    }
                }, '100');
                this.showInstalledProductList = false;
            }

        }, error => {
            consoleError('error ', JSON.stringify(error));
        });
    }
    // Handler method for Bac to cart button
    handleBackToCart(){
        const tileClicked = new CustomEvent('returnCart',{detail : "back TO CART", bubbles : true});
        this.dispatchEvent(tileClicked);
    }
    // event handle for selection of line item
    removeSelection(event){
        this.visible = false;
        this.showInstalledProductList = false;
        this.selectedLineItemDetails = event.detail.lineDetails;
        consoleLog('New Serial Number --:')
        this.selectedSerialNumber = event.detail.lineDetails.setSerialNumber;
        this.template.querySelectorAll('c-billable-show-line-item-cart').forEach(function(element){
            if(this.selectedLineItemDetails.strLineItemNumber !== element.lineItem.strLineItemNumber)//Codescan fix
                element.removeSelection();
        },this);
        consoleLog('---->',event.detail.lineDetails);
        let context = this;
        setTimeout(function(){
            context.showInstalledProductList = true;
        }, '100');
    }
    // event handle to refresh data after any DML
    refreshData(event){
        this.message = event.detail.lineNumber+' is updated.';
        this.selectedSerialNumber = event.detail.updatedSerialNumber;
        consoleLog('Updated Serial number -->',this.selectedSerialNumber);
        this.queryTerm = '';
        this.visible = true;
        let context = this;
        this.showInstalledProductList = false;
        setTimeout(function(){
            context.showInstalledProductList = true;
            //context.visible = false;
        }, '100');
    }
    // getter method to set toast style
    get notificationStyle(){
        return !this.boolIsRelocation ? "border-color:red;color:red;" : "border-color:green;color:green;";
    }
    // handler method for search
    handleKeyUp(event){
        consoleLog('In side handleKeyUp');
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey && !isBlank(event.target.value)) {
            this.queryTerm = event.target.value;
            this.template.querySelector('[data-id="availableIPs"]').search(this.queryTerm);
        }
    }
    // handler method for search
    changeHandler(event) {
        consoleLog('In side changeHandler');
        consoleLog('event',event);
        if(!isBlank(this.queryTerm))
            this.template.querySelector('[data-id="availableIPs"]').resetData();
    }
}
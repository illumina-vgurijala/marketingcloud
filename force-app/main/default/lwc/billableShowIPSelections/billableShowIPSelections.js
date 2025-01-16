import {
    LightningElement,
    api
} from 'lwc';
import {
    consoleLog,
    isNotEmpty,
    consoleError,
    callServer,
    isEmpty,
    genericEvent,
    isNotBlank
} from 'c/utils';
import {
    columns
} from './column.js';
import saveLine from '@salesforce/apex/BillableAddMultipleSerialNumberCtrl.saveLine';
import getInstalledProduct from '@salesforce/apex/BillableAddMultipleSerialNumberCtrl.getInstalledProduct';
export default class BillableShowIPSelections extends LightningElement {
    @api idCurrentUC;
    @api selectedLineItemDetails;
    @api selectedSerialNumber;
    @api isSelectedComponent = false;
    @api mapLabels;
    initialIPList = [];
    lstInstalledProduct = [];
    booLoading;
    cardTitle;
    buttonLabel;
    buttonTitle;
    connectedCallback() {
        consoleLog('connectedCallback BillableShowIPSelection -->',this.selectedSerialNumber);
        consoleLog('connectedCallback BillableShowIPSelection ',this.isSelectedComponent);
        this.cardTitle = this.isSelectedComponent ? this.mapLabels.UI_Label_Selected_Installed_Products_Serials : this.mapLabels.UI_Label_Add_Installed_Products_Serials;
        this.columns = columns;
        this.buttonLabel = this.isSelectedComponent ? this.mapLabels.Button_Remove_From_Cart_Line_Item : this.mapLabels.Button_Add_To_Cart_Line_Item;
        this.buttonTitle = this.isSelectedComponent ? this.mapLabels.Button_Remove_From_Cart_Line_Item : this.mapLabels.Button_Add_To_Cart_Line_Item;
        this.initializeDetails();
    }
    initializeDetails() {
        this.booLoading = true;
        callServer(getInstalledProduct, {
            idCurrentUC: this.idCurrentUC,
            strSerialNumber: JSON.stringify(this.selectedSerialNumber),
            boolIncludeOnly: this.isSelectedComponent
        }, result => {
            if (isNotBlank(result)) {
                this.returndata = JSON.parse(result);
                consoleLog('Data = ', this.returndata);
                this.lstInstalledProduct = this.returndata.lstIPDetails;
                this.initialIPList = this.returndata.lstIPDetails;
                let context = this;
                setTimeout(function () {
                    context.booLoading = false;
                }, '100');
            }
        }, error => {
            consoleError('error ', JSON.stringify(error));
        });
    }
    updateSerialNumber() {

        let selectedSerialNumberNew = [];
        let finalSerialNumberlist = [];
        this.template.querySelector('c-data-table-lazy-load').fetchSelectedRecord().forEach(element => {
            selectedSerialNumberNew.push(element.strSerialNumber);
        });
        consoleLog('selectedSerialNumberNew-', selectedSerialNumberNew);
        if (isNotEmpty(selectedSerialNumberNew)) {
            consoleLog('Inside Selected');
            this.booLoading = true;
            if (this.isSelectedComponent) {
                consoleLog('In if remove');
                finalSerialNumberlist = this.selectedSerialNumber.filter(function (ele) {
                    return !selectedSerialNumberNew.includes(ele);
                });
                consoleLog('finalSerialNumberlist ', finalSerialNumberlist);
            } else {
                consoleLog('In add else');
                finalSerialNumberlist = isNotEmpty(this.selectedSerialNumber) ? selectedSerialNumberNew.concat(this.selectedSerialNumber) : selectedSerialNumberNew;
            }
            callServer(saveLine, {
                recordId: this.selectedLineItemDetails.idLineItemid,
                strSerialNumber: JSON.stringify(finalSerialNumberlist)
            }, result => {
                const objDetails = Object.create({});
                objDetails.lineNumber = this.selectedLineItemDetails.strLineItemNumber;
                objDetails.updatedSerialNumber = finalSerialNumberlist;
                consoleLog('finalSerialNumberlist before evetn', finalSerialNumberlist);
                genericEvent('lineupdate', objDetails, this);
            }, error => {
                consoleError('error ', JSON.stringify(error));
            });
        }
    }
    // api method to handle query
    @api
    search(strQuery){
        consoleLog('Searched-->,',strQuery);
        this.booLoading = true;
        this.lstInstalledProduct = this.initialIPList.filter(function (ele) {
                return ele.strSerialNumber.includes(strQuery) || ele.strProductCode.includes(strQuery) || ele.strInstalledProductID.includes(strQuery);
            });
        let context = this;
        setTimeout(function(){
            context.booLoading = false;
        }, '50');

    }
    //  api method to reset data
    @api
    resetData(){
        this.booLoading = true;
        this.lstInstalledProduct = this.initialIPList;
        let context = this;
        setTimeout(function(){
            context.booLoading = false;
        }, '50');

    }
    get deActivateButton() {
        return isEmpty(this.lstInstalledProduct);
    }

}
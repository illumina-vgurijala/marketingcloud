import { LightningElement,api } from 'lwc';
import {
    showErrorToast,
    callServer,
    consoleLog,
    genericEvent
} from 'c/utils';
export default class BillableShowLineItemCart extends LightningElement {
    @api lineItem;
    titleStyle;
    selectedStyle = 'slds-m-around_medium slds-p-around_medium lgc-bg';
    nonSelectedStyle = 'slds-m-around_medium slds-p-around_medium lgc-bg-inverse';
    connectedCallback(){
        this.titleStyle = this.nonSelectedStyle;
    }
    tileClickHandler(){
        const objDetails = Object.create({});
        consoleLog('Line item on tileClickHandler',this.lineItem);
        objDetails.lineDetails = this.lineItem;
        genericEvent('removeselection', objDetails, this);
        consoleLog('tileClickHandler',this.lineItem.strLineItemNumber);
        this.titleStyle = this.selectedStyle;
    }
    @api
    removeSelection(){
        this.titleStyle = this.nonSelectedStyle;
    }
}
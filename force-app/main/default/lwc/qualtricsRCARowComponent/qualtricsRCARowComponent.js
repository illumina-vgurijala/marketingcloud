import {
    LightningElement,
    api,
    track
} from 'lwc';
import { genericEvent, isBlank } from 'c/utils';
import QSR_RCA_Option_Other from '@salesforce/label/c.QSR_RCA_Option_Other';
import UI_Label_Other_Root_Cause_Analysis from '@salesforce/label/c.UI_Label_Other_Root_Cause_Analysis';
export default class QualtricsRCARowComponent extends LightningElement {
    @api rowdetails;
    @track selectedValue;
    @track otherValue;
    @track rank;
    @track inputLabel;
    @track isOther = false;
    label = {
        QSR_RCA_Option_Other,
        UI_Label_Other_Root_Cause_Analysis
    }
    // On Load method
    connectedCallback(){
        this.rank = this.rowdetails.rank + 1;
        this.selectedValue = this.rowdetails.selectedValue;
        this.otherValue = this.rowdetails.otherValue;
        if(this.selectedValue == QSR_RCA_Option_Other)
            this.isOther = true;
    }
    // funtion to handle update of other value
    handleOtherChange(event){
        this.otherValue = event.detail.value;
    }
    // funtion to send custom event post focus out on other text box
    handleFocusOut(event){
        const objDetails = Object.create({});
        objDetails.value = this.selectedValue;
        objDetails.index = this.rowdetails.rank;
        objDetails.otherValue = this.otherValue;
        objDetails.oldValue = this.rowdetails.selectedValue;
        genericEvent('othervalueaddition',objDetails,this);
    }
    // funtion to handle chnage of picklist value on combo box
    handleChange(event) {
        this.selectedValue = event.detail.value;
        const objDetails = Object.create({});
        objDetails.value = this.selectedValue;
        objDetails.index = this.rowdetails.rank;
        objDetails.oldValue = this.rowdetails.selectedValue;
        if(this.selectedValue == this.label.QSR_RCA_Option_Other){
            this.isOther = true;
            objDetails.otherValue = this.otherValue;
        }
        else{
            this.isOther = false;
            objDetails.otherValue = '';
            this.otherValue = '';
        }
        genericEvent('selection',objDetails,this);
    }
    // funtion to handle delete button click
    handleDelete(event) {
        const objDetails = Object.create({});
        objDetails.value = this.rowdetails.selectedValue;
        objDetails.index = this.rowdetails.rank;
        this.isOther = false;
        this.otherValue = '';
        genericEvent('deleteselection',objDetails,this);
    }
    // api enabled method to validate inputs
    @api validate(){
        let boolNotInOption = false;
        let setPicklistValue = [];
        this.rowdetails.availableOption.forEach(element => {
            setPicklistValue.push(element.label);
        });
        boolNotInOption = !setPicklistValue.includes(this.selectedValue);
        if(isBlank(this.selectedValue) || boolNotInOption){
           this.template.querySelector('lightning-combobox').showHelpMessageIfInvalid();
           return true;
        }
        else if(this.selectedValue == this.label.QSR_RCA_Option_Other && isBlank(this.otherValue)){
            this.template.querySelector('lightning-textarea').showHelpMessageIfInvalid();
            return true;
        }
        else
            return false;
    }
}
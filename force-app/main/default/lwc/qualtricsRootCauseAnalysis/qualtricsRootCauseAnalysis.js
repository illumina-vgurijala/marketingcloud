import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { consoleLog,consoleError,showErrorToast,showSuccessToast,arraySubset,arrayRemove,arrayIndexRemove,isNotBlank } from 'c/utils';
import RCA from '@salesforce/schema/Qualtrics_Survey_Response__c.Root_Cause_Analysis_1__c';
import UI_Success_Message_QSR_Update from '@salesforce/label/c.UI_Success_Message_QSR_Update';
import UI_Error_Message_QSR_Update from '@salesforce/label/c.UI_Error_Message_QSR_Update';
import UI_QSRRCA_Label_Title from '@salesforce/label/c.UI_QSRRCA_Label_Title';
import UI_QSRRCA_Label_Rank from '@salesforce/label/c.UI_QSRRCA_Label_Rank';
import UI_QSRRCA_Label_Picklist_Options from '@salesforce/label/c.UI_QSRRCA_Label_Picklist_Options';
import UI_QSRRCA_Label_Action from '@salesforce/label/c.UI_QSRRCA_Label_Action';
import Save from '@salesforce/label/c.Save';
import UI_Label_MDG_Cancel_Button from '@salesforce/label/c.UI_Label_MDG_Cancel_Button';
import UI_QSRRCA_Label_Add_Row from '@salesforce/label/c.UI_QSRRCA_Label_Add_Row';
import UI_Error_Message_QSR_NotSelected from '@salesforce/label/c.UI_Error_Message_QSR_NotSelected';
import QSR_RCA_Fields from '@salesforce/label/c.QSR_RCA_Fields';
import QSR_RCA_Other_Fields from '@salesforce/label/c.QSR_RCA_Other_Fields';
import QSR_RCA_Option_Other from '@salesforce/label/c.QSR_RCA_Option_Other';
export default class qualtricsRootCauseAnalysis extends NavigationMixin(LightningElement) {
    @api QSRId;
    @track recordTypeId;
    @track boolPageLoaded = false;
    @track RCAPicklistOptions = [];
    @track recordDetails;
    @track isChanged = false;
    @track availableRCAList = [];
    @track reqField = RCA;
    @track wiredResults;
    @track selectedRCA = [];
    @track booLoading=true;
    @track fieldsQSR = [];
    @track maxRCALimit = 0;
    @track RCAFieldList = [];
    @track RCAFieldListOther;
    @track selectedOtherValue = '';
    @track recordPageUrl;
    @track boolRCAValue = false;
    label = {
        UI_Success_Message_QSR_Update,
        UI_Error_Message_QSR_Update,
        UI_QSRRCA_Label_Title,
        UI_QSRRCA_Label_Rank,
        UI_QSRRCA_Label_Picklist_Options,
        Save,
        UI_Label_MDG_Cancel_Button,
        UI_QSRRCA_Label_Add_Row,
        UI_QSRRCA_Label_Action,
        UI_Error_Message_QSR_NotSelected,
        QSR_RCA_Fields,
        QSR_RCA_Other_Fields,
        QSR_RCA_Option_Other
    };
    connectedCallback(){
        this.RCAFieldList = QSR_RCA_Fields.split(',');
        this.RCAFieldList.forEach((element) =>{
            this.fieldsQSR.push('Qualtrics_Survey_Response__c.'+element);
        })
        this.maxRCALimit = this.fieldsQSR.length;
        this.fieldsQSR.push('Qualtrics_Survey_Response__c.'+QSR_RCA_Other_Fields);
        this.fieldsQSR.push('Qualtrics_Survey_Response__c.RecordTypeId');
    }
    // Wire method to fetch record details on load.
    @wire(getRecord, {
        recordId: '$QSRId',
        fields : '$fieldsQSR'
    })
    imperativeWiring(result) {
        consoleLog('Result:',result);
        this.wiredResults = result;
        if (result.data) {
            this.recordTypeId = result.data.recordTypeInfo.recordTypeId;
            this.recordDetails = result.data;
        }
        else if (result.error) {
            consoleError('Error:',result.error);
        }
    }
    // Event listner method on load completion of generic component 
    handleComplete(event) {
        let picklistValues = JSON.parse(event.detail.picklist);
        picklistValues.forEach((element) => {
            this.RCAPicklistOptions.push({
                label: element.label,
                value: element.value
            });
        })
        this.generateSelectedList();
        this.boolPageLoaded = true;
        this.booLoading = false;
    }
    generateSelectedList(){
        this.selectedRCA = [];
        this.RCAFieldList.forEach((element) =>{
            if(isNotBlank(this.recordDetails.fields[element].value)){
                this.selectedRCA.push(this.recordDetails.fields[element].value);
                if(this.recordDetails.fields[element].value == this.label.QSR_RCA_Option_Other)
                   this.selectedOtherValue =  this.recordDetails.fields[this.label.QSR_RCA_Other_Fields].value;
            }
        })
        this.createRCAlist(this.selectedRCA);
    }
    // Method to create object list for selected value and corresponding option available.
    createRCAlist(arrSelectedValue){
        this.boolRCAValue = false;
        this.availableRCAList = [];
        arrSelectedValue.forEach((element, index, array) => {
            this.availableRCAList.push({
                selectedValue: element,
                availableOption : arrayRemove(this.RCAPicklistOptions,arraySubset(array,index)),
                rank : index,
                otherValue : element == this.label.QSR_RCA_Option_Other ? this.selectedOtherValue : ''
            })
        })
        let context = this;
        // To  re-render child component.
        setTimeout(function(){
            context.boolRCAValue = true;
        }, '100');
    }
    // Handler for Add row button
    handleAddRow(event) {
        if(!this.checkValidSelection()){
            let arr = arrayRemove(this.RCAPicklistOptions,this.selectedRCA);
            this.availableRCAList.push({
                availableOption : arr,
                selectedValue: '',
                rank : this.availableRCAList.length,
                otherValue : ''
            });
            this.isChanged = true;
        }
    }
    // Handler for change in picklist
    handleSelectionChange(event) {
        this.selectedRCA[event.detail.index] = event.detail.value;
        if(event.detail.oldValue == this.label.QSR_RCA_Option_Other)
            this.selectedOtherValue = '';
        this.selectedRCA = this.removeDuplicate(this.selectedRCA,event.detail.index, event.detail.value);
        this.createRCAlist(this.selectedRCA);
        this.isChanged = true;
    }
    // Handle to operate deletion of RCA
    handleDeleteAction(event) {
        this.selectedRCA = arrayIndexRemove(this.selectedRCA,event.detail.index);
        if(event.detail.value == this.label.QSR_RCA_Option_Other)
            this.selectedOtherValue = '';
        this.createRCAlist(this.selectedRCA);
        this.isChanged = true;
    }
    handleOtherValue(event){
        this.selectedOtherValue = event.detail.otherValue;
    }
    // Check if any picklist value is not selected
    checkValidSelection(){
        let boolNotCheckSelected = false;
        let listChildComponent = this.template.querySelectorAll('c-qualtrics-r-c-a-row-component');
        listChildComponent.forEach((element) =>{
            let flag = element.validate();
            boolNotCheckSelected = flag || boolNotCheckSelected;
        })
        return boolNotCheckSelected;
    }
    // Handle for save button
    handleSave(event) {
        let boolNotCheckSelected = this.checkValidSelection();
        if(boolNotCheckSelected){
            showErrorToast(this.label.UI_Error_Message_QSR_NotSelected);
        }else{
            this.booLoading=true;
            let record = {
                fields: {
                    Id: this.QSRId
                    },
            };
            this.RCAFieldList.forEach((element,index) =>{
                if(isNotBlank(this.selectedRCA[index])){
                    record.fields[element] = this.selectedRCA[index];
                }
                else{
                    record.fields[element] = '';
                }  
            })
            record.fields[this.label.QSR_RCA_Other_Fields] = this.selectedOtherValue;
            updateRecord(record)
                .then(() => {
                    showSuccessToast(this.label.UI_Success_Message_QSR_Update);
                    this.isChanged = false;
                    this.booLoading = false;
                    this.navigateToQSRRecord();
                })
                .catch(error => {
                    consoleError('Error while Saving',error);
                    showErrorToast(this.label.UI_Error_Message_QSR_Update);
                    this.booLoading = false;
                });
        }
    }
    // Getter method to disable Add button
    get addButtonDisabled() {
        return this.availableRCAList.length >= this.maxRCALimit;
    }
    get isChange(){
        return !this.isChanged;
    }
    handleCancel(event){
        this.navigateToQSRRecord();
    }
    // Remove duplicate form array
    removeDuplicate(arr,ind,value){
        return arr.filter(function (ele,index) {
            return !(index > ind && ele == value);
        });
    }
    // Navigation method to record page
    navigateToQSRRecord() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.QSRId,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url,"_self");
        });
    }
}
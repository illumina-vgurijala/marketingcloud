import { LightningElement, track, api } from 'lwc';
import {
    isBlank,
    isEmpty,
    showSuccessToast,
    showErrorToast,
    callServer,
    genericEvent,
} from 'c/utils';
import addAssociatedAccount from '@salesforce/apex/TerritoryPlanStrategyController.addAssociatedAccount';

export default class TerritoryPlanAssociatedAccountHelper extends LightningElement {
    @api objectiveRecordId;
    @api maplabels;
    @api recordData;     
    @track accountColumn;
    @track lstAccountAvailable = []; 
    @track lstAccountAvailableFilteredSet = [];
    @track customerTypePicklistValues = [];
    @track currentObjectiveDetails;
    booLoading = false;
    isCreate = false;
    strCustomerType;
    strCity;
    strAccountName;
    strERPNumber;

    connectedCallback() {
       this.loadData();
    }

    @api 
    loadData() {
        this.booLoading = true;
        if (this.recordData) {
            this.lstAccountAvailable = this.recordData.lstAccountAvailable;
            this.lstAccountAvailableFilteredSet = this.recordData.lstAccountAvailable;
            this.currentObjectiveDetails = this.recordData.currentObjectiveDetails;
            this.isCreate = this.recordData.isCreate;
            this.recordData.customerTypePicklistValues.forEach((element) => {
                this.customerTypePicklistValues.push({
                    label: element.label,
                    value: element.value
                });
            });  
            this.accountColumn = this.recordData.accountColumn;          
        } 
        this.booLoading = false;
    }

    closeModal() {
        this.resetSearchKey();
        const objDetails = Object.create({});
        genericEvent('closemodal',objDetails,this);
    }
    
    @api
    addAssociation() {
        this.booLoading = true;
        let setAccountId = [];
        let listChildComponent = this.template.querySelectorAll('c-data-table-lazy-load');
        listChildComponent.forEach((element) => {
            element.fetchSelectedRecord().forEach((element1) => {
                if (setAccountId.indexOf(element1.strAccountId) < 0)
                    setAccountId.push(element1.strAccountId);
            });
        });
        if (isEmpty(setAccountId)) {
            showErrorToast(this.maplabels.UI_Label_No_Row_Selected);
            this.booLoading = false;
        } else
            this.addAssociatedAccount(setAccountId);
    }
    addAssociatedAccount(lstAccountId) {
        callServer(addAssociatedAccount, {            
            lstAccountId: lstAccountId,
            objectiveId: this.objectiveRecordId,
            strObjectiveJSON : JSON.stringify(this.currentObjectiveDetails)
        }, result => {              
            showSuccessToast(result);                
            const objDetails = Object.create({});            
            genericEvent('accountassociate',objDetails,this);
            if(!this.isCreate) { 
                this.closeModal();
            }
        }, error => {
            showErrorToast(error.body.message);
            this.booLoading = false;                   
        });
    }

    handleSelectedRows(event) {        
        let data = event.detail;
        let accountsSelected = [];
        data.forEach(element => { 
            if (accountsSelected.indexOf(element.strAccountId) < 0){ 
                accountsSelected.push(element.strAccountId);
            }            
        });
        const objDetails = Object.create({});
        objDetails.selectedRows = accountsSelected;
        genericEvent('accountselect',objDetails,this);       
    }
    
    // reset search results
    @api
    resetSearchKey() {
        this.booLoading = true;
        this.strAccountName = '';
        this.strCity = '';
        this.strCustomerType = '';
        this.strERPNumber = '';
        this.lstAccountAvailableFilteredSet = this.lstAccountAvailable;
        // To  re-render child component.
        let context = this;
        setTimeout(function () {
            context.booLoading = false;
        }, '100');
    }
    // method to set variable
    fieldUpdate(event) {
        if (event.target.label === this.maplabels.UI_Label_Segmentation_Selection_Field_Customer_Type) {
            this.strCustomerType = event.target.value;
        }
        if (event.target.label === this.maplabels.UI_Label_City) {
            this.strCity = event.target.value;
        }
        if (event.target.label === this.maplabels.UI_Label_Account_Name) {
            this.strAccountName = event.target.value;
        }
        if (event.target.label === this.maplabels.UI_Label_Customer_ERP_Number) {
            this.strERPNumber = event.target.value;
        }

    }
    // method called when search is hit
    searchAccount() {
        this.booLoading = true;
        this.InfinityLoad = true;
        let tempFilteredList = this.lstAccountAvailable;
        this.lstAccountAvailableFilteredSet = [];
        if (isBlank(this.strAccountName) && isBlank(this.strCity) && isBlank(this.strCustomerType) && isBlank(this.strERPNumber)) {
            this.lstAccountAvailableFilteredSet = this.lstAccountAvailable;
        } else {
            if (!isBlank(this.strAccountName)) {
                let tempFiltered = tempFilteredList.filter(element => this.lowerCaseConvertor(element.accountName).includes(this.lowerCaseConvertor(this.strAccountName)));
                tempFilteredList = tempFiltered;
            }
            if (!isBlank(this.strCity)) {
                let tempFiltered = tempFilteredList.filter(element => this.lowerCaseConvertor(element.city).includes(this.lowerCaseConvertor(this.strCity)));
                tempFilteredList = tempFiltered;
            }
            if (!isBlank(this.strCustomerType)) {
                let tempFiltered = tempFilteredList.filter(element => element.customerType === this.strCustomerType);
                tempFilteredList = tempFiltered;
            }
            if (!isBlank(this.strERPNumber)) {
                let tempFiltered = tempFilteredList.filter(element => !isBlank(element.erpNumber) && this.lowerCaseConvertor(element.erpNumber).includes(this.lowerCaseConvertor(this.strERPNumber)));
                tempFilteredList = tempFiltered;
            }
            this.lstAccountAvailableFilteredSet = tempFilteredList;
        }
        // To  re-render child component.
        let context = this;
        setTimeout(function () {
            context.booLoading = false;
        }, '100');
    }
    // Getter methed to display message
    get noDataSearch() {
        return isEmpty(this.lstAccountAvailableFilteredSet) || this.booLoading;
    }
    // method to convert text to lower case
    lowerCaseConvertor(data) {
        return data.toLowerCase();
    }
}
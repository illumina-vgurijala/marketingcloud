import { LightningElement, api, wire } from 'lwc';
import fetchLookupData from '@salesforce/apex/AccountLookupLwcController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/AccountLookupLwcController.fetchDefaultRecord';
import fetchAccountData from '@salesforce/apex/AccountLookupLwcController.fetchAccountData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY = 300; // Delay for Apex callout timing in milliseconds

export default class AccountLookup extends LightningElement {
    @api label = 'Account Search';
    @api placeholder = 'search...';
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Account';
    @api defaultRecordId = '';

    isShowModal = false;
    accountSearchInput;
    lstResult = []; // To store list of returned records   
    hasRecords = true;
    searchKey = ''; // To store input field value    
    isSearchLoading = false; // To control loading spinner  
    delayTimeout;
    selectedRecord = {}; // To store selected lookup record in object format 

    connectedCallback() {
        if (this.defaultRecordId !== '') {
            fetchDefaultRecord({ recordId: this.defaultRecordId, sObjectApiName: this.sObjectApiName })
                .then((result) => {
                    if (result) {
                        this.selectedRecord = result;
                        this.handelSelectRecordHelper();
                    }
                })
                .catch((error) => {
                    this.showToast('error' , error.message , 'error');
                    this.selectedRecord = {};
                });
        }
    }

    @wire(fetchLookupData, { searchKey: '$searchKey', sObjectApiName: '$sObjectApiName' })
    searchResult({ data, error }) {
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length > 0;
            this.lstResult = data.map(account => {
                let address;
                    address = account.BillingAddress !== null ? account.BillingAddress : {};
                return { ...account, BillingAddressParsed: address };
            });
        } else if (error) {
            this.showToast('error' , error.message , 'error');
        }
    }

    handleKeyChange(event) {
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }

    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handleRemove() {
        this.searchKey = '';
        this.selectedRecord = {};
        this.lookupUpdatehandler(undefined);

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }

    handelSelectedRecord(event) {
        const objId = event.target.getAttribute('data-recid');
        this.selectedRecord = this.lstResult.find(data => data.Id === objId);
        this.lookupUpdatehandler(this.selectedRecord);
        this.handelSelectRecordHelper();
        this.isShowModal = false;
    }

    handelSelectRecordHelper() {
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');
    }

    lookupUpdatehandler(value) {
        const oEvent = new CustomEvent('lookupupdate', {
            detail: { selectedRecord: value }
        });
        this.dispatchEvent(oEvent);
    }

    showmoreResult() {
        this.isShowModal = true;
    }

    handleCancel() {
        this.isShowModal = false;
    }

    handleAccountSearch(event) {
        this.accountSearchInput = event.target.value;
        if (event.key === "Enter") {
            this.isSearchLoading = false;
            fetchAccountData({ searchKey: this.accountSearchInput, sObjectApiName: this.sObjectApiName })
                .then((result) => {
                    if (result) {
                        this.isSearchLoading = false;
                        this.hasRecords = result.length > 0;
                        this.lstResult = result.map(account => {
                            let address;
                                address = account.BillingAddress !== null ? account.BillingAddress : {};
                            return { ...account, BillingAddressParsed: address };
                        });
                    }
                })
                .catch((error) => {
                    this.showToast('error' , error.message , 'error');
                });
        }
    }
    showToast(title , message , variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        )
    }
}
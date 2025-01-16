import { LightningElement, track , api , wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FIELDS_CV_ID from "@salesforce/schema/ContentVersion.Id";
import FIELDS_IS_RECALL_RELATED from "@salesforce/schema/ContentVersion.IsRecallRelated__c";
import getCaseRecord from '@salesforce/apex/RecallVerificationController.getCaseRecord';
import linkFileWithCases from '@salesforce/apex/RecallVerificationController.linkFileWithCases';
import fetchCaseWithAccountId from '@salesforce/apex/RecallVerificationController.fetchCaseWithAccountId';
import { updateRecord , deleteRecord } from "lightning/uiRecordApi";
import { publish, MessageContext } from "lightning/messageService";
import RECALL_CHANNEL from "@salesforce/messageChannel/recall_verification_channel__c";
import { reduceErrors } from 'c/ldsUtils';
export default class RecallVerification extends LightningElement {
    @api recordId;
    @track accountName = '';
    @track accountId = '';
    @track caseNumber = '';
    @track caseId = '';
    @track isSearchEnabled = true;
    @track isSpinner = false;
    @track fileName = '';
    @track contentDocumentId = ''; // uploaded file doc Id
    @track cases = []; // recall cases
    @track selectedCases; // user's selected cases
    @track linkedCases = []; // list of case Id 
    @track isShowModal = false; // case selection model

    pageSizeOptions = [10]; //Page size options
    totalCaseRecords = 0; //Total no.of records
    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = [];
    @track isRecall = false; //Added by Vishal for CMCM-10403

    get acceptedFormats() {
        return ['.pdf', '.png' , '.jpg' , '.jpeg'];
    }
    get isContentDocumentId() {
        return this.contentDocumentId !== '';
    }
    get isFileName() {
        return this.fileName === '';
    }
    @wire(MessageContext)
    messageContext;
    connectedCallback() {
        getCaseRecord({caseId: this.recordId})
        .then(result => {
            if(result.length > 0){ //Added by Vishal for CMCM-10403
                this.isRecall = true;
            }
            for(let i = 0; i < result.length; i++) {
                result[i].isSelected = true;
                result[i].isDisabled = true;
            }
            this.cases = result;
            this.totalCaseRecords = result.length;
            this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
            this.paginationHelper();
        })
        .catch(error => {
            this.showToast('error' , reduceErrors(error).join(', ') , 'error');
            this.paginationHelper();
        });
    }

    handleAccountSelection(event) {
        this.accountId = event.detail.selectedRecord === undefined ? '' : JSON.parse(JSON.stringify(event.detail.selectedRecord)).Id;
        this.disabledSearch();
    }

    handleLookupValueSelectCase(event) {
        this.caseNumber = event.detail.productName;
        this.caseId = this.template.querySelector("c-product-Lookup").selectRecordId;
        this.disabledSearch();
    }
    handleReadOnly() {
        this.caseNumber = '';
        this.caseId = '';
        this.disabledSearch();
    }
    disabledSearch() {
        if(this.accountId !== '' && this.caseNumber === ''){
            this.isSearchEnabled = false;
        } else if(this.accountId === '' && this.caseNumber !== '') {
            this.isSearchEnabled = false;
        } else {
            this.isSearchEnabled = true;
        }
    }
    handleSearch() {
        // Implement the search functionality to fetch cases
        this.isSpinner = true;
        if(this.accountId !== '') {
            fetchCaseWithAccountId({ accountId: this.accountId })
            .then(result => {
                if(this.cases.length > 0 && result.length > 0) {
                this.addCases(result);
                this.totalCaseRecords = this.cases.length;
                this.paginationHelper();
                this.isSpinner = false;
            } else if (result.length > 0) {
                this.cases = result;
                this.totalCaseRecords = this.cases.length;
                this.paginationHelper();
                this.isSpinner = false;
            } else {
                this.isSpinner = false;
                this.showToast('warning', 'Accounts searched must be associated with a recall for verification form upload. The account entered is not associated with a recall. Select an account which has a case with the recall box checked and try again.', 'warning');
            }
            })
            .catch(error => {
                this.isSpinner = false;
                this.showToast('error' , reduceErrors(error).join(', ') , 'error');
            });
        } else if(this.caseId !== '') {
            getCaseRecord({ caseId: this.caseId })
            .then(result => {
                this.template.querySelector('c-product-Lookup').resetData();
                this.caseId = '';
                if(this.cases.length > 0 && result.length > 0) {
                    this.addCases(result);
                    this.totalCaseRecords = this.cases.length;
                    this.paginationHelper();
                    this.isSpinner = false;
                } else if (result.length > 0) {
                    this.cases = result;
                    this.isSpinner = false;
                } else {
                    this.isSpinner = false;
                    this.showToast('warning', 'All cases must be associated with a recall for verification form upload. The case number entered is not associated with a recall. Select a case with the recall box checked and try again.', 'warning');
                }
            })
            .catch(error => {
                this.isSpinner = false;
                this.showToast('error' , reduceErrors(error).join(', ') , 'error');
            });
        }
        this.paginationHelper();
    }

    addCases(result) {
        for(let i = 0; i < result.length; i++) {
            result[i].isSelected = false;
            const exists = this.cases.some(existingCase => existingCase.caseId === result[i].caseId);
            if (!exists) {
                this.cases.push(result[i]);
                this.totalCaseRecords = result.length;
                this.paginationHelper();
            }
        }
    }
    handleCheckboxChange(event) {
        const selectedCase = event.target.dataset.caseid;
        this.cases.forEach((item) => {
            if (selectedCase === item.caseId && event.target.checked) {
                item.isSelected = true;
            } else if(selectedCase === item.caseId) {
                item.isSelected = false;
            }
        });
    }
    // pagination

    get bDisableFirst() {
        return this.pageNumber === 1;
    }
    get bDisableLast() {
        return this.pageNumber === this.totalPages;
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalCaseRecords / this.pageSize);
        if(this.totalCaseRecords === 0) {
            this.totalPages = 1;
        }
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalCaseRecords) {
                break;
            }
            this.recordsToDisplay.push(this.cases[i]);
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.fileName = uploadedFiles[0].name;
        this.contentDocumentId = uploadedFiles[0].documentId;
        const contentVersionId = uploadedFiles[0].contentVersionId;
        const fields = {};

        fields[FIELDS_CV_ID.fieldApiName] = contentVersionId;
        fields[FIELDS_IS_RECALL_RELATED.fieldApiName] = true;

        const recordInput = {
        fields: fields
        };

        updateRecord(recordInput).then((record) => {
        })
        .catch(error => {
            this.showToast('error' , reduceErrors(error).join(', ') , 'error');
        });
    }

    async deleteFile() {
        this.isSpinner = true;
        try {
            await deleteRecord(this.contentDocumentId);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File deleted',
                        variant: 'success'
                    })
                );
            this.fileName = '';
            this.contentDocumentId = '';
            this.isSpinner = false; 
        } catch (e) {
            this.isSpinner = false; 
            this.showToast('error' , reduceErrors(e).join(', ') , 'error');
        }
    }

    previewAndLinkCases() {
        // Implement the functionality to preview and link cases
        this.selectedCases = this.cases.filter((cs) => cs.isSelected === true);
        this.isShowModal = true;
    }

    handleCancel() {
        // Implement the cancel functionality
        this.isShowModal = false;
    }

    handleProceed() {
        // Implement the proceed functionality
        this.isSpinner = true;
        this.isShowModal = false;
        const setCaseIds = this.cases.filter(cs => cs.isSelected === true && cs.caseId !== this.recordId).map(cs => cs.caseId);
        linkFileWithCases({ contentDocumentId : this.contentDocumentId , litsOfCase : setCaseIds})
        .then(result => {
            this.isSpinner = false;
            this.showToast('success' , 'successfully file got linked to cases' , 'success');
            const messaage = {
                isRecallSubmited: true
              };
            publish(this.messageContext, RECALL_CHANNEL, messaage);
            this.resetRecallData();
        })
        .catch(error => {
            this.isSpinner = false;
            this.showToast('error' , reduceErrors(error).join(', ') , 'error');
        });
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
    resetRecallData() {
        this.fileName = '';
        this.contentDocumentId = '';
        this.cases = [];
        this.selectedCases = []
        this.linkedCases = [];
        this.isShowModal = false;
        this.connectedCallback();
    }
}
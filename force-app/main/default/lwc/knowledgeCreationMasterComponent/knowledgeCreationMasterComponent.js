import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    NavigationMixin
} from 'lightning/navigation';
import {
    consoleLog,
    isBlank,
    isNotBlank,
    callServer,
    genericEvent
} from 'c/utils';
import {
    createPath    
} from './supportVariable.js';
import fetchRecordTypeId from '@salesforce/apex/KnowledgeCreationMasterController.fetchRecordTypeID';
export default class KnowledgeCreationMasterComponent extends NavigationMixin(LightningElement) {
    @api loadType;
    strHeader;
    @api recordTypeSelected = '';
    @track booLoading = false;
    steps = [];
    @track currentStep;
    // Variable for selective visibiltiy
    @track showPageLayout = false;
    @track showRecordTypeSelection = false;   
    @track showKnowledgeAssocaition = false;
    @api knowledgeid = '';
    @api selectedTitle = '';
    @api selectedKnowledgeArticle = '';
    @api selectedDomain = '';
    @api selectedSubDomain = '';
    @api clickedFlag ;
    // COnnected call back for onload
    connectedCallback() {
        this.booLoading = true;
        if (this.loadType === 'Create') {
            this.steps = createPath;
            this.currentStep = 'Select Template';
            this.showRecordTypeSelection = true;
            this.strHeader = "New Knowledge";
        }
        this.booLoading = false;
    }    
    // Handler method to set record type
    recordTypeSectionHandler(event) {
        this.recordTypeSelected = event.detail.value;        
    }
    nextScreen(event) {
        this.clickedFlag = true; 
        var stage = event.target.name;
        if (stage === 'Select Template') {
            this.clickedFlag = false;
            if (isNotBlank(this.recordTypeSelected)) {
                this.currentStep = 'Article Content';
                this.showPageLayout = true;
                this.showRecordTypeSelection = false;
            } else {
                this.template.querySelector('c-knowledge-record-selection').showError();
            }
        }
        if (stage === 'Article Content')
            this.template.querySelector('c-knowledge-creation-child').submitFilledForm();       
    }
    previousScreen(event) {
        var stage = event.target.name;
        consoleLog('Previous Button clicked -->', event.target.name);
        if (stage === 'Article Content') {
            this.currentStep = 'Select Template';
            this.showPageLayout = false;
            this.showRecordTypeSelection = true;
        }
        if (stage === 'Related Knowledge') {           
            this.currentStep = 'Article Content';
            this.showPageLayout = true;
            this.showKnowledgeAssocaition = false;
        }
       
    }
    // Handler event to save knowledge article
    handleFormSave(event) {
        this.clickedFlag = false;        
        this.knowledgeid = event.detail.value;
        this.currentStep = 'Related Knowledge';
        this.showPageLayout = false;       
        this.showKnowledgeAssocaition = true;
    }
    // Handler event for error in save
    handleFormError(event) {
        this.clickedFlag = false;
    }
    closeScreen(){
        
        //passing this custom event to aura for navigation.
        const objDetails = Object.create({});
        objDetails.value = this.knowledgeid;
        genericEvent("closeclicked", objDetails, this);         
    }   
    get isCreate() {
        return this.loadType === 'Create';
    }
    get renderRecordTypeSelection() {
        return (this.loadType === 'Create') && this.showRecordTypeSelection;
    }
    get unRenderPreviousButton() {
        return ((this.loadType === 'Create') && this.showRecordTypeSelection) || ((this.loadType === 'Edit') && this.showPageLayout);
    }
    get buttonLabelCancel(){
        if(this.showKnowledgeAssocaition)
            return 'Finish';
        else
            return 'Cancel';
    }
    get buttonLabelNext(){
        if(this.showPageLayout && this.loadType === 'Create')
        return 'Create and Proceed';             
        else
        return 'Next';
    }   

    get disableNextBtn(){
        return this.booLoading || this.showKnowledgeAssocaition || this.clickedFlag ;
    }

}
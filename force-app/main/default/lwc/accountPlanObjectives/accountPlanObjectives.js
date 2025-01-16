import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    refreshApex
} from '@salesforce/apex';
import {
    getRecord
} from 'lightning/uiRecordApi';

import initRecord from '@salesforce/apex/AccountPlanObjectivesController.initRecord';

import NAME_FIELD from '@salesforce/schema/Objective__c.Name';
import DUE_DATE from '@salesforce/schema/Objective__c.Due_Date__c';
import OBJECTIVE_STATUS from '@salesforce/schema/Objective__c.Objective_Status__c';
import CLOSED_STATUS from '@salesforce/schema/Objective__c.Closed_Status__c';
import PRIORITY from '@salesforce/schema/Objective__c.Priority__c';
import PLANSTRATEGY from '@salesforce/schema/Account_Plan__c.Illumina_Strategy__c';
import OBSTACLES from '@salesforce/schema/Account_Plan__c.Illumina_Obstacles_Risks__c';
import REQSUPPORT from '@salesforce/schema/Account_Plan__c.Required_Support_and_Resources__c';
import PRODUCT_TYPE from '@salesforce/schema/Objective__c.Product_Type__c';
import COMMENTS from '@salesforce/schema/Objective__c.Comments__c';//DCP-52623
//  DCP-39561  Territory Planning Modification
import {
    showErrorToast,
    showSuccessToast,
    consoleLog,
    isNotEmpty,
    consoleError,
    callServer
} from 'c/utils';
import ACCOUNTID from '@salesforce/schema/Account_Plan__c.Account_Name__c';
import getAssociatedObjective from '@salesforce/apex/AccountPlanObjectivesController.getAssociatedObjective';
import createAccountObjective from '@salesforce/apex/AccountPlanObjectivesController.createAccountObjective';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {
    objectiveColumn_Large, 
    objectiveColumn_Small
} from './columns.js';
// DCP-39561  Territory Modification ends
import {
    updateRecord
} from 'lightning/uiRecordApi';

export default class AccountPlanObjectives extends LightningElement {
    @api recordId;
    @api isAppPage;
    @track PlanStrategy;
    @track PlanReqSupport;
    @track PlanObstacles;
    @track ObjectiveData;
    @track recordIdUpdate;
    @track ObjectAPi;
    @track DisplayEditField;
    @track recordIdToDelete;
    @track ObjectiveId;
    @track myOpenSections;
    @track UILabels;
    @track LiveOpenSection;
    @track PreviousOpenSection;
    
    // Modal switch variables
    @track showSaveView = false;
    @track showConfirmation = false;
    @track showEditView = false;
    @track showEditViewAplan = false;
    //Labels and Headers
    @track SuccessMessage;
    @track ErrorMessage;
    @track ModalHeaders;
    @track ConfirmationMessage;

    //  DCP-39561  Territory Planning
    @track AccountId;
    @track addObjectiveView = false;
    @track objectiveColumn;
    @track territoryObjectives;
    @track hasNoTerritoryObjectives = true;
    @track booLoading = false;
    @track wiredResults;
    @track objectType = 'Account_Plan__c';
    connectedCallback() {
        if (FORM_FACTOR == 'Large')
            this.objectiveColumn = objectiveColumn_Large;
        else
            this.objectiveColumn = objectiveColumn_Small;
    }


    @track ObjectivefieldsEdit =[NAME_FIELD, DUE_DATE, OBJECTIVE_STATUS, COMMENTS, CLOSED_STATUS, PRIORITY, PRODUCT_TYPE];//DCP-52623
    @track Objectivefields = [NAME_FIELD, DUE_DATE, OBJECTIVE_STATUS, CLOSED_STATUS, PRIORITY, PRODUCT_TYPE];//DCP-52623
    @track AccountPlanFields = [PLANSTRATEGY, REQSUPPORT, OBSTACLES];


    @wire(getRecord, {
        recordId: '$recordId',
        fields: [PLANSTRATEGY, OBSTACLES, REQSUPPORT, ACCOUNTID]
    })
    getAccountPlan({
        data,
        error
    }) {
        if (data) {

            this.PlanStrategy = data.fields.Illumina_Strategy__c.value;
            this.PlanObstacles = data.fields.Illumina_Obstacles_Risks__c.value;
            this.PlanReqSupport = data.fields.Required_Support_and_Resources__c.value;
            this.AccountId = data.fields.Account_Name__c.value
        }
        if (error) {
            console.log(error);
        }
    }
    objectiveHover(event) {
        console.log('Hovering Hovering');
        console.log('--' + event.target.value);
    }

    wiredsObjectData;
    @wire(
        initRecord, {
            recordId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.booLoading = true;
        this.wiredResults = result;
        console.log('--%%%--' + JSON.stringify(this.wiredResults));
        console.log('--&&&--' + JSON.stringify(this.wiredResults.lstobjective));
        console.log('--***--' + JSON.stringify(this.wiredResults.data));

        if (result.data) {
            console.log('--$$$--' + JSON.stringify(JSON.parse(result.data)));
            let returndata = JSON.parse(result.data);
            this.ObjectiveData = returndata.lstobjectiveWrap;
            this.UILabels = returndata.mapLabel;
            console.log('Init method-->' + this.LiveOpenSection);
            this.booLoading = false;
        } else if (result.error) {
            console.log('$$$$$');
            this.booLoading = false;
            this.error = error;
        }
    }

    /* Button click entry methods*/
    editFields(event) {
        this.recordIdUpdate = this.recordId;
        this.ObjectAPi = "Account_Plan__c";
        this.showEditViewAplan = true;
        this.ModalHeaders = this.UILabels.UI_Objective_EditStrategy;
    }
    createNewObjective() {
        this.DisplayEditField = this.Objectivefields;
        this.ObjectAPi = "Objective__c";
        this.showSaveView = true;
    }
    editObjective(event) {
        console.log('---%^&*' + JSON.stringify(event.target.value));
        this.recordIdUpdate = event.target.value;
        this.showEditView = true;
        this.DisplayEditField = this.ObjectivefieldsEdit;////DCP-52623
        this.ObjectAPi = "Objective__c";        
        this.ModalHeaders = this.UILabels.UI_Objective_EditObjective;
        console.log(this.showEditView);
    }
    deleteObjectiveConfBox(event) {
        this.showConfirmation = true;
        this.recordIdToDelete = event.target.value;
        this.ConfirmationMessage = this.UILabels.UI_Objective_DeactivateObjective;
        this.ObjectAPi = "Objective__c";
        console.log('Record to inactive-->' + this.recordIdToDelete);
    }
    ///////// Button click entry methods ends /////////
    deleteDeactivateRecords(event) {
        console.log('---deleteDeactivateRecords-->' + this.ObjectAPi);
        if (this.ObjectAPi === "Objective__c") {
            let record = {
                fields: {
                    Id: this.recordIdToDelete,
                    IsInactive__c: true,
                },
            };

            updateRecord(record)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this.UILabels.UI_Objective_Delete,
                            variant: 'success'
                        })
                    );
                    this.closeModal();
                    refreshApex(this.wiredResults);
                })
                .catch(error => {
                    console.log('error');
                    console.log(JSON.stringify(error));
                });
        }
        refreshApex(this.wiredResults);
    }
    handleSectionToggle(event) {
        this.myOpenSections = event.detail.openSections;
        console.log('select-> ' + this.myOpenSections);
        if (this.PreviousOpenSection) {
            console.log('----- inside IF----');
            this.LiveOpenSection = this.myOpenSections.filter(n => !this.PreviousOpenSection.includes(n));
            this.PreviousOpenSection = this.myOpenSections;
        } else {
            console.log('----- inside else----');
            this.LiveOpenSection = this.myOpenSections;
            this.PreviousOpenSection = this.myOpenSections;
        }
        console.log('--->recently clicked --> ' + this.LiveOpenSection);
    }
    closeModal() {
        this.showSaveView = false;
        this.showEditView = false;
        this.showConfirmation = false;
        this.ModalHeaders = '';
        this.showEditViewAplan = false;
        this.addObjectiveView = false;
    }
    handleSuccess() {
        if (this.ObjectAPi === 'Objective__c') {
            const evt = new ShowToastEvent({
                title: "Success!",
                message: this.UILabels.UI_Objective_Message,
                variant: "success",
            });
            this.dispatchEvent(evt);
        }
        this.showSaveView = false;
        this.refreshData();

    }
    handleSubmit(event) {
        if (this.ObjectAPi == 'Objective__c') {
            console.log('Record id --?' + this.recordId);
            event.preventDefault();
            const fields = event.detail.fields;
            fields.Account_Plan__c = this.recordId;
            this.template.querySelector('lightning-record-form').submit(fields);
        }
    }
    handleOnError(event) {        
        const evt = new ShowToastEvent({
            title: "Error!",
            message: event.detail.value,
            variant: "error",
        });
        this.dispatchEvent(evt);
    }
    //----ENDS --- Methods for New objective record form
    //Methods for Edit
    handleEditSuccess(event) {
        console.log(this.ObjectAPi);
        if (this.ObjectAPi === "Objective__c") {
            console.log('hello hello');
            const evt = new ShowToastEvent({
                title: "Success!",
                message: this.UILabels.UI_Objective_Updated,
                variant: "success",
            });
            this.dispatchEvent(evt);
        }
        if (this.ObjectAPi === "Account_Plan__c") {
            console.log('hello');
            const evt = new ShowToastEvent({
                title: "Success!",
                message: this.UILabels.UI_Objective_Updated,
                variant: "success",
            });
            this.dispatchEvent(evt);
        }
        this.showEditView = false;
        this.showEditViewAplan = false;
        refreshApex(this.wiredResults);


    }
    handleEditOnError(event) {
        console.log('--->' + JSON.stringify(event.detail));
        console.log('---->' + JSON.stringify(event.detail.detail));
        if (this.ObjectAPi === "Account_Plan__c") {
            if (Object.entries(event.detail.output.fieldErrors).length !== 0) {
                const getField = Object.keys(event.detail.output.fieldErrors)[0];
                this.message = event.detail.output.fieldErrors[getField][0].message;
            } else {
                this.message = event.detail.message + "\n" + event.detail.detail;
            }
            const evt = new ShowToastEvent({
                title: "Error!",
                message: this.message,
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    }
    handleEditSubmit(event) {}
    //  DCP-39561  Territory Planning modification
    // Button action to show list of Territory Objective
    addObjectiveFromTerritoryPlan() {
        this.booLoading = true;
        callServer(getAssociatedObjective, {
            strAccountId: this.AccountId,
            strAccountPlanId: this.recordId
        }, result => {
            consoleLog('Fetched Objectives-->', JSON.parse(result));
            this.territoryObjectives = JSON.parse(result);
            if (isNotEmpty(this.territoryObjectives))
                this.hasNoTerritoryObjectives = false;
            this.addObjectiveView = true;
            this.booLoading = false;
        }, error => {
            consoleError(error);
            showErrorToast(this.UILabels.UI_Error_Message_System_Error);
            this.booLoading = false;
        });
    }
    // DCP-39561  Action when Add is clicked
    addObjective(event) {
        let selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        this.createAccountObjectives(selectedRecords);
    }
    // DCP-39561 Method to create Objective
    createAccountObjectives(selectedRecords) {
        this.booLoading = true;
        callServer(createAccountObjective, {
            lstAccountPlanWrapper: JSON.stringify(selectedRecords),
            strPlanId: this.recordId
        }, result => {
            showSuccessToast(result);
            refreshApex(this.wiredResults);
            this.addObjectiveView = false;
            this.booLoading = false;
        }, error => {
            consoleError(error);
            showErrorToast(this.UILabels.UI_Error_Message_System_Error);
            this.booLoading = false;
        });
    }
    refreshDetails(event) {
        refreshApex(this.wiredResults);
        this.closeModal();
    }
    //  DCP-39561  Territory Planning modification
    // Button action to show list of Territory Objective
    addObjectiveFromTerritoryPlan(){
        this.booLoading = true;
        callServer(getAssociatedObjective,{
            strAccountId : this.AccountId,
            strAccountPlanId : this.recordId
        },result => {
            consoleLog('Fetched Objectives-->',JSON.parse(result));
            this.territoryObjectives = JSON.parse(result);
            consoleLog('List -->',isNotEmpty(this.territoryObjectives));
            if(isNotEmpty(this.territoryObjectives))
                this.hasNoTerritoryObjectives = false;
            this.addObjectiveView = true;
            this.booLoading = false;
        },error => {
            this.booLoading = false;
        });
    }
    // DCP-39561  Action when Add is clicked
    addObjective(event){
        let selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        this.createAccountObjectives(selectedRecords);
    }
    // DCP-39561 Method to create Objective
    createAccountObjectives(selectedRecords){
        this.booLoading = true;
        callServer(createAccountObjective,{
            lstAccountPlanWrapper : JSON.stringify(selectedRecords),
            strPlanId : this.recordId
        },result => {
            showSuccessToast(result);
            refreshApex(this.wiredResults);
            this.addObjectiveView = false;
            this.booLoading = false;
        },error => {
            this.booLoading = false;
        });
    }
    refreshData(event) {
        refreshApex(this.wiredResults);
    }
}
import { LightningElement, track, api} from 'lwc';
import { genericEvent, consoleLog, callServer, consoleError, isNotBlank, isEmpty } from 'c/utils';
import fetchOpportunitiesToDisplay from '@salesforce/apex/PlanAssociatedOpportunitiesController.fetchOpportunitiesToDisplay';
import getAssociatedAccountsForObjectives from '@salesforce/apex/TerritoryPlanStrategyController.getAssociatedAccountsForObjectives';
import { opportunityColumn, accountColumn } from './columns.js';

const ADD_OBJECT_ASSOCIATION =  'Add Object Association'; 
export default class CreateObjectiveOpportunityAssociation extends LightningElement {
    @api objectApiName;
    @api displayFields;
    @api recordId;    
    @api parentId;    
    @api maplabels;
    @api planId;
    @track opportunityColumn = opportunityColumn;
    @track opportunityRecordData = {};    
    @track accountRecordData = {};    
    booLoading = false;    
    objectiveId;    
    booIsFirstPage = true;
    showOpportunity = false;
    //DCP-52242
    @track pathStages = [];
    lastStage;
    addObjectAssociation;
    @api isOverlayPlan = false;    
    showAccount = false;
    booIsSecondPage = false;
    @track selectedAccounts = [];

    connectedCallback() {
        this.pathStages = this.isOverlayPlan ? [this.maplabels.UI_Label_Create_Objective,this.maplabels.UI_Label_Add_Account,this.maplabels.UI_Label_Add_Opportunity] : [this.maplabels.UI_Label_Create_Objective,this.maplabels.UI_Label_Add_Opportunity];
        this.addObjectAssociation = this.isOverlayPlan ? this.maplabels.UI_Label_Add_Account : this.maplabels.UI_Label_Add_Opportunity;     
    }

    closeModal(event) {        
        const objDetails = Object.create({});
        objDetails.value =this.recordId;
        genericEvent('closemodal',objDetails,this);
    }

    handleSuccess(event) {   
        this.objectiveId  = event.detail.id;
        consoleLog('this.objectiveId : ',this.objectiveId);
        if(this.showOpportunity && this.objectiveId) {            
            this.handleOpportunityAssociation();
        } 
        else if(this.showAccount && this.objectiveId){
            this.handleAccountAssociation();
        }
        else {            
            const objDetails = Object.create({});        
            objDetails.value = this.objectiveId;
            genericEvent('upsertsuccess',objDetails,this);
            this.booLoading = false;
        }        
    }

    handleAccountAssociation(){
        this.booLoading = true;        
        callServer(getAssociatedAccountsForObjectives, {            
            strRecordId: this.objectiveId,
        }, result => {              
            if (isNotBlank(result)) {
                let returndata = JSON.parse(result);

                let dataForProcessing  = Object.create({});
                dataForProcessing.lstAccountAvailable = returndata.lstAccountWrap;                
                dataForProcessing.currentObjectiveDetails = returndata.planObjective; 
                dataForProcessing.customerTypePicklistValues = returndata.customerTypeValues;
                dataForProcessing.isCreate = true;
                dataForProcessing.accountColumn = accountColumn;

                this.accountRecordData = dataForProcessing;
                this.booIsSecondPage = true;
                this.booIsFirstPage = false;
                
                this.lastStage = this.maplabels.UI_Label_Create_Objective;
                this.addObjectAssociation = this.maplabels.UI_Label_Add_Opportunity;   
                this.showOpportunity = true;                    
            }            
            this.booLoading = false;
        }, error => {
            consoleError('error ', JSON.stringify(error));
            this.booLoading = false;         
        });               
    }

    handleOpportunityAssociation() {        
        this.booLoading = true;       
        callServer(fetchOpportunitiesToDisplay, {            
            strRecordId: this.planId,
            strObjectType: this.objectApiName,
            lstAccountIdsFromATO : this.selectedAccounts
        }, result => { 
            let dataForProcessing  = Object.create({});           
            if (isNotBlank(result)) {
                let returndata = JSON.parse(result);
                dataForProcessing.lstOpportunityAvailable = returndata.lstOpportunityWrapper;
                dataForProcessing.opportunityStageValues = returndata.opportunityStageValues;
                dataForProcessing.planRecordId = returndata.planRecordId;
                dataForProcessing.isTerritoryPlanObjective = returndata.isTerritoryPlanObjective;
                dataForProcessing.boolNoAccountsAdded = returndata.boolNoAccountsAdded;                
                dataForProcessing.opportunityColumn = this.opportunityColumn;
                dataForProcessing.objectiveRecordId = this.objectiveId;
                this.booIsFirstPage = false;
                this.booIsSecondPage = false;
                this.lastStage = this.isOverlayPlan ? this.maplabels.UI_Label_Add_Account : this.maplabels.UI_Label_Create_Objective;
                this.showAccount = false;
            }
            this.opportunityRecordData = dataForProcessing;                
            this.booLoading = false;
        }, error => {
            consoleError('error ', JSON.stringify(error));
            this.booLoading = false; 
            this.booIsFirstPage = false;           
        });        
    }

    handleError(event) {
        let message = '';
        if (Object.entries(event.detail.output.fieldErrors).length !== 0) {
            const getField = Object.keys(event.detail.output.fieldErrors)[0];
            message = event.detail.output.fieldErrors[getField][0].message;
        }
        else {
            message = event.detail.message + "\n" + event.detail.detail;
        }

        const objDetails = Object.create({});
        objDetails.value = message;
        consoleError('error happened : ',message);
        genericEvent('upserterror',objDetails,this);
        this.booLoading = false;
    }
    
    handleSubmit(event) {        
        this.booLoading = true;
        event.preventDefault();

        if(this.booIsFirstPage) {
            const fields = event.detail.fields;
            if(this.objectApiName === this.maplabels.UI_Label_Objective_API) {
                fields.Plan_Strategy__c = this.parentId;
            }
            else {
                fields.Account_Plan__c = this.parentId;
            }     
            this.template.querySelector('lightning-record-edit-form').submit(fields);            
        }else if (this.booIsSecondPage){
            this.template.querySelector('c-territory-plan-associated-account-helper').addAssociation();
            this.booLoading = false;
        }
         else {
            this.template.querySelector('c-generic-plan-associated-opportunities-helper').addAssociation();
            this.booLoading = false;
        }
    }

    handleClick(event) {
        consoleLog('event target : '+JSON.stringify(event.target.name));
        if(event.target.name === ADD_OBJECT_ASSOCIATION){
            if( !this.isOverlayPlan) {
                this.showOpportunity = true; 
            } 
            else {
                this.showAccount = true;
            }        
        } else {
            this.showOpportunity = false;
        }
    }
      
    handleOpportunityAssociationSuccess(event) {
        const objDetails = Object.create({});
        objDetails.isCreateForOverlayPlan = this.isOverlayPlan;
        objDetails.objectiveId = this.objectiveId;
        genericEvent('opportunityassociate',objDetails,this);
    }

    handleAccountAssociationSuccess(event) {
        this.showOpportunity = true;
        const objDetails = Object.create({});
        genericEvent('accountassociate',objDetails,this);        
        if(this.objectiveId) {            
            this.handleOpportunityAssociation();
        }
    }

    handleAccountsSelected(event) {
        this.selectedAccounts = event.detail.selectedRows;
    }

    get modalHeaders() {        
        if(this.booIsFirstPage) {
            return this.maplabels.UI_Label_Create_Objective;
        }
        else if (this.booIsSecondPage) {
            return this.maplabels.UI_Label_List_Account;
        } 
        return this.maplabels.UI_Label_List_Objective_Opportunity;        
    }

    get showAccountModal() {
        return this.isOverlayPlan && this.showAccount && this.booIsSecondPage;
    }
    get showCreateScreen() {
        return this.booIsFirstPage && !this.booIsSecondPage;
    }
    get showAddObjectButton() {
        return this.booIsFirstPage || this.booIsSecondPage;
    }
    get disableAddOppButton() {
        return this.isOverlayPlan && this.showAccount && isEmpty(this.selectedAccounts);
    }
}
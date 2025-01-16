import { 
    LightningElement, 
    track,
    api,
} from 'lwc';

import {
    isBlank,
    consoleLog,
    isEmpty,
    showSuccessToast,
    showErrorToast,
    callServer,
    genericEvent,
} from 'c/utils';
import addAssociatedOpportunities from '@salesforce/apex/PlanAssociatedOpportunitiesController.addAssociatedOpportunities';

export default class GenericPlanAssociatedOpportunitiesHelper extends LightningElement {
    @api recordData;
    @api maplabels;
    @track availableOpportunities = [];
    @track associatedOpp = [];        
    @track lstOpportunityAvailableFilteredSet = [];        
    @track opportunityStagePicklistValues = [];        
    @track wiredResults;
    objectiveRecordId;
    opportunityColumn; 
    planRecordId;
    isTerritoryPlanObjective;    
    booLoading = false;
    searchKey = '';        
    strOpportunityStage;
    strOpportunityName;
    boolNoAccountsAdded = false;    
    
    connectedCallback() {
        this.loadData();        
    }
    
    @api
    loadData() {
        this.booLoading = true;        
        if (this.recordData) {                
            this.availableOpportunities = this.recordData.lstOpportunityAvailable; //Available opps for association
            this.lstOpportunityAvailableFilteredSet = this.recordData.lstOpportunityAvailable;            
            this.recordData.opportunityStageValues.forEach((element) => {
                this.opportunityStagePicklistValues.push({
                    label: element.label,
                    value: element.value
                });
            });
            this.planRecordId = this.recordData.planRecordId;
            this.isTerritoryPlanObjective = this.recordData.isTerritoryPlanObjective;
            this.opportunityColumn = this.recordData.opportunityColumn;
            this.objectiveRecordId = this.recordData.objectiveRecordId;
            this.boolNoAccountsAdded = this.recordData.boolNoAccountsAdded;           
        }
        this.booLoading = false;    
    }

    // method called when search is hit
    searchOpportunities() {
        this.booLoading = true;
        this.InfinityLoad = true;
        let tempFilteredList = this.availableOpportunities;
        this.lstOpportunityAvailableFilteredSet = [];
        if (isBlank(this.strOpportunityName) && isBlank(this.strOpportunityStage)) {
            this.lstOpportunityAvailableFilteredSet = this.availableOpportunities;
        } else {
            if (!isBlank(this.strOpportunityName)) {                    
                let tempFiltered = tempFilteredList.filter(element => this.lowerCaseConvertor(element.strOpportunityName).includes(this.lowerCaseConvertor(this.strOpportunityName)));
                tempFilteredList = tempFiltered;
            }
            if (!isBlank(this.strOpportunityStage)) {
                let tempFiltered = tempFilteredList.filter(element => element.strOpportunityStageName === this.strOpportunityStage);
                tempFilteredList = tempFiltered;
            }
            this.lstOpportunityAvailableFilteredSet = tempFilteredList;
        }
        // To  re-render child component.
        let context = this;
        setTimeout(function () {
            context.booLoading = false;
        }, '100');
    }

    @api
    addAssociation() {
        this.booLoading = true;
        let opportunityIds = [];
        let listChildComponent = this.template.querySelectorAll('c-data-table-lazy-load');
        listChildComponent.forEach((element) => {
            element.fetchSelectedRecord().forEach((element1) => {
                if (opportunityIds.indexOf(element1.strOpportunityId) < 0)
                    opportunityIds.push(element1.strOpportunityId);
            });
        });

        consoleLog('opportunityIds => ',JSON.stringify(opportunityIds));

        if(this.boolNoAccountsAdded) {
            showErrorToast(this.maplabels.UI_Label_No_Account_For_Adding_Opportunity);
            this.booLoading = false;
        }
        else if (isEmpty(opportunityIds)) {
            showErrorToast(this.maplabels.UI_Label_No_Row_Selected);
            this.booLoading = false;
        } else {
            this.addAssociatedOpportunity(opportunityIds);
        }
    }

    addAssociatedOpportunity(opportunityIds) {
        let objectiveOppRelationships = [];
        opportunityIds.forEach((opportunityId) => {
            let junctionRecord = Object.create({});
            junctionRecord.Opportunity__c = opportunityId;
            if(this.isTerritoryPlanObjective) {
                junctionRecord.Plan_Objective__c = this.objectiveRecordId;
                junctionRecord.Plan__c = this.planRecordId;
            } else {
                junctionRecord.Account_Plan_Objective__c = this.objectiveRecordId;
                junctionRecord.Account_Plan__c = this.planRecordId;
            }
            objectiveOppRelationships.push(junctionRecord);
        })
        consoleLog('final list before sending to apex : ', JSON.stringify(objectiveOppRelationships));
        if(objectiveOppRelationships.length > 0) {
            callServer(addAssociatedOpportunities, {            
                strRecordData: JSON.stringify(objectiveOppRelationships)
            }, result => {              
                showSuccessToast(result);
                const objDetails = Object.create({});
                genericEvent('opportunityassociate',objDetails,this);
                this.closeModal();
            }, error => {
                showErrorToast(error.body.message);
                this.booLoading = false;                  
            });
        }

    }             

    @api
    resetSearchKey() {
        this.booLoading = true;
        this.strOpportunityStage = '';
        this.strOpportunityName = '';            
        this.lstOpportunityAvailableFilteredSet = this.availableOpportunities;
        // To  re-render child component.
        let context = this;
        setTimeout(function () {
            context.booLoading = false;
        }, '100');
    }
    // method to set variable
    fieldUpdate(event) {
        if (event.target.label === 'Opportunity Name') {
            this.strOpportunityName = event.target.value;
        }
        if (event.target.label === 'Opportunity Stage') {
            this.strOpportunityStage = event.target.value;
        }
    }

    closeModal() {        
        this.resetSearchKey();
        const objDetails = Object.create({});
        genericEvent('closemodal',objDetails,this);
    }

    // Getter methed to display message
    get noDataSearch() {
        return isEmpty(this.lstOpportunityAvailableFilteredSet) || this.booLoading;
    }

    // method to convert text to lower case
    lowerCaseConvertor(data) {
        return data.toLowerCase();
    }       
}
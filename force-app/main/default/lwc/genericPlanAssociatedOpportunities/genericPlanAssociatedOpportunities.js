import { LightningElement, track,
    api,
    wire } from 'lwc';

    import {
        refreshApex
    } from '@salesforce/apex';
    import {
        consoleLog,
        isEmpty,
        showSuccessToast,
        showErrorToast,
        callServer,
        consoleError
    } from 'c/utils';
    import {                
        accountFields,        
        associatedOppoFields,
        deleteIcon,
        opportunityField,
        ownerField
    } from './columns.js';
    import fetchAssociatedOpportunities from '@salesforce/apex/PlanAssociatedOpportunitiesController.fetchAssociatedOpportunities';
    import deleteAssociatedOpportunities from '@salesforce/apex/PlanAssociatedOpportunitiesController.deleteAssociatedOpportunities';

    export default class GenericPlanAssociatedOpportunities extends LightningElement {
        @api objectiveRecordId;
        @api maplabels;
        @api objectType;
        @api planId;
        @track associatedOpp = [];
        @track column ;//= column;        
        @track recordData = {};
        @track opportunitiesFound;        
        @track wiredResults; 
        addOppView = false;        
        sortBy;
        sortDirection;
        booLoading = false;
        
        @wire(
            fetchAssociatedOpportunities, {
                strRecordId: '$planId',
                strObjectiveId: '$objectiveRecordId',
                strObjectType: '$objectType'
            }
        )
        wiredData(result) {
            this.booLoading = true;            
            this.wiredResults = result;
            consoleLog('Associated Opportunity -->', result.data);            
            let dataForProcessing  = Object.create({});
            
            if (result.data) {                
                let returndata = JSON.parse(result.data);
                this.associatedOpp = returndata.lstObjectiveOppRelationshipWrapper; 
                dataForProcessing.lstOpportunityAvailable = returndata.lstOpportunityWrapper;
                dataForProcessing.opportunityStageValues = returndata.opportunityStageValues;
                dataForProcessing.planRecordId = returndata.planRecordId;
                dataForProcessing.isTerritoryPlanObjective = returndata.isTerritoryPlanObjective;
                dataForProcessing.boolNoAccountsAdded = returndata.boolNoAccountsAdded;
                if(returndata.isTerritoryPlanObjective){
                    this.column = [...opportunityField, ...deleteIcon];
                    dataForProcessing.opportunityColumn = [...associatedOppoFields, ...ownerField];
                }else{
                    this.column = [...opportunityField, ...accountFields ,...deleteIcon];
                    dataForProcessing.opportunityColumn = [...associatedOppoFields, ...accountFields ,...ownerField];    
                }
                
                dataForProcessing.objectiveRecordId = this.objectiveRecordId;                                                              
            } else if (result.error) {
                consoleError('Error', result.error);
            }

            this.recordData = dataForProcessing;
           
            let childComponent = this.template.querySelector('c-generic-plan-associated-opportunities-helper');                
            
            if(childComponent !== undefined && childComponent !== null){                    
                childComponent.recordData = this.recordData;
                childComponent.loadData();
            }                        
            this.booLoading = false;
        }

        createNewOppAssociation() {                                           
            this.refreshData();
            this.addOppView = true;                                                                     
        }

        closeModal() {
            this.addOppView = false;
            this.resetSearchKey();
        }

        removeOppAssociation() {
            this.booLoading = true;
            let associatedOppsForDeletion = [];
            let selectedRecords = this.template.querySelectorAll('lightning-datatable')[0].getSelectedRows();
            selectedRecords.forEach(element => {
                associatedOppsForDeletion.push(element.strRecordID);
            });
            if (isEmpty(associatedOppsForDeletion)) {
                showErrorToast(this.maplabels.UI_Label_No_Row_Selected);
                this.booLoading = false;
            }
            else{
                this.deleteAssociatedOpps(associatedOppsForDeletion);
            }
        }

        // Data Table funtionality
        handleRowAction(event) {
            const rowDetail = event.detail.row;
            const actionName = event.detail.action.name;
            if (actionName === 'Remove Opportunity'){
                this.booLoading = true;
                let associatedOppsForDeletion = [];
                associatedOppsForDeletion.push(rowDetail.strRecordID);
                consoleLog('List to be deleted', associatedOppsForDeletion);
                this.deleteAssociatedOpps(associatedOppsForDeletion);
            }
        }

        addAssociation() {
            this.template.querySelector('c-generic-plan-associated-opportunities-helper').addAssociation();
        }

        //Delete associated relationship records
        deleteAssociatedOpps(lstAssociatedRecordIds) {
            callServer(deleteAssociatedOpportunities, {            
                lstRecordIds: lstAssociatedRecordIds
            }, result => {              
                showSuccessToast(result);
                this.refreshData();
            }, error => {
                showErrorToast(error.body.message);
                this.booLoading = false;                 
            });
        }

        // Sorting method
        handleSortdataDetail(event) {
            // field name
            this.sortBy = event.detail.fieldName;
            // sort direction 
            this.sortDirection = event.detail.sortDirection;
            // calling sortdata function to sort the data based on direction and selected field
            this.associatedOpp = this.sortData(this.associatedOpp, event.detail.fieldName, event.detail.sortDirection);
        }

        sortData(datalist, fieldname, direction) {
            // serialize the data before calling sort function
            let parseData = JSON.parse(JSON.stringify(datalist));
    
            // Return the value stored in the field
            let keyValue = (a) => {
                return a[fieldname];
            };
    
            // cheking reverse direction 
            let isReverse = direction === 'asc' ? 1 : -1;
    
            // sorting data 
            parseData.sort((x, y) => {
                let a = keyValue(x) ? keyValue(x) : ''; // handling null values
                let b = keyValue(y) ? keyValue(y) : '';
    
                // sorting values based on direction
                return isReverse * ((a > b) - (b > a));
            });
    
            // set the sorted data to data table data
            return parseData;
    
        }

        get showAssociatedOpps() {
            return !isEmpty(this.associatedOpp) && !this.booLoading;
        }
            
        resetSearchKey() {
            this.template.querySelector('c-generic-plan-associated-opportunities-helper').resetSearchKey();
        }
        
        @api
        refreshData() {
            refreshApex(this.wiredResults);
        }
        
        get noAssociatedOpportunity() {
            return isEmpty(this.associatedOpp);
        }

        get disableAddOpportunity() {
            return isEmpty(this.recordData) && isEmpty(this.recordData.opportunityStageValues);
        }
    }
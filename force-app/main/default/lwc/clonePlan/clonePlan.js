import {
    LightningElement,
    api,
    track,
    wire
} from 'lwc';
import {
    consoleLog,
    showSuccessToast,
    callServer,
    genericEvent,
    isEmpty
} from 'c/utils';
import {
    NavigationMixin,
    CurrentPageReference
} from 'lightning/navigation';
import deepClone from '@salesforce/apex/PlanCloneController.deepClone';
import getStrategies from '@salesforce/apex/PlanCloneController.getStrategies';
import {
    loadSharedData,
    createChannelPartnerOptionListHelper,
    getYearOptions,
    territorySelectHelper,
    yearSelectHelper,
    validateInputHelper
} from 'c/planCreationHelper'
import Id from '@salesforce/user/Id';
import { CloseActionScreenEvent } from 'lightning/actions';
const STRING_SEPARATOR = "|";
export default class ClonePlan extends NavigationMixin(LightningElement) {
    @api userType;
    @api recordId;
    @api currentUserId;
    @track territoryName;
    @track territoryId;
    @track territoryCode;
    @track selectionView = false;
    @track objectApiName = 'Plan__c';
    @track territoryOptions = [];
    @track booLoading = true;
    @track modalHeader;
    @track mapUILabels = [];
    @track startDate;
    @track endDate;
    @track year;
    @track territorySelectView = false;
    @track roleSelectView = false;
    @track yearSelectView = false;
    @track overlayRole;
    @track roleOptions = [];
    @track isOverLayPlan = false;
    @track idRecordTypeId; //DCP-39621 : to fetch recordTypeId
    // DCP-39735
    @track idChannelPartner;
    @track isCommunity = false;
    @track isIndirectRecord = false;
    @track channelPartnerSelectView = false;
    @track channelPartnerOption = [];
    @track mapAccountWrapper = [];
    @track hasSingleTerritory = false;
    @track channelPartnerCode;
    @track territoryRegion;
    // DCP-40495
    @track mapAccountToMapYearQuota = {};
    @track channelPartnerValue;
    // Sprint 2 feedback DCP-41767
    @track planNameAutomated;
    @track channelPartnerName;

    @track booIsFirstPage = true;
    @track strButtonLabel = 'Clone'
    @track lstStrategies = [];
    @track strategy;
    @track booIsListEmpty = true;
    @track booDisabled = true;
    @track currentStep = '0';
    @track todaysDate; //DCP-52241

    pageNo = 0;
    totalPages = 0;


    steps = [
        { label: 'Details Page', value: '0' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            consoleLog('recordId --> ' + currentPageReference.state.recordId);
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getStrategies, { strRecordId: '$recordId'})
    getData({error, data}){
        this.booLoading = true;
        if(data){
            consoleLog('data obj -->', data);
            this.lstStrategies = JSON.parse(data);
            if(!isEmpty(this.lstStrategies)){
                this.booIsListEmpty = false;
                this.totalPages = this.lstStrategies.length;
                if(this.totalPages > 0){
                    this.strButtonLabel = 'Next';
                }
                this.lstStrategies.forEach((strategy, index) => {
                    this.steps.push({ label: strategy.name , value: index+1 });
                });
            }
            else{
                this.booIsListEmpty = true;
            }
            this.booLoading = false;
        }
        else if(error) {
            consoleLog('failed@@@');
            consoleLog(error);
            this.booLoading = false;
        }
        
    }

    connectedCallback() {
        this.currentUserId = Id; 
        consoleLog('Record Id -->', this.recordId);
        consoleLog('current User Id -->', this.currentUserId);       
        this.loadRecords();
        this.getDateValues();//DCP-52241
    }
    loadRecords() {
        let argument = {
            userRecordIdLocal: this.currentUserId,
            recordId: this.recordId
        }
        loadSharedData(this, argument, 'Clone');
    }
    closeModal() {
        this.selectionView = false;
        this.booLoading = false;
        this.territoryRecordId = '';
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    get yearOptions() {
        return getYearOptions();
    }
    createChannelPartnerOptionList() {
        createChannelPartnerOptionListHelper(this);
    }
    //To default value of Start Date and End Date with selected year on Plan object
    yearSelect(event) {
        yearSelectHelper(event, this);
    }
    territorySelect(event) {
        territorySelectHelper(event, this);
    }
    roleSelect(event) {

        this.overlayRole = event.target.value;
    }
    //Added as part of INC0364304
    channelPartnerSelect(event) {
        let split = event.target.value.split(STRING_SEPARATOR);
        this.idChannelPartner = split[0];
        this.channelPartnerCode = split[1];
        this.channelPartnerName = split[2];
    }
    // end of INC0364304
    next() {
        this.booLoading = true;
        if (!validateInputHelper(this,'Clone') && this.checkValidity()) {
            if(this.strButtonLabel === 'Clone') {
                this.clonePlanRecord();
                return
            }
            else{

                if(this.booIsFirstPage) {
                    this.selectionView = false;
                    this.booIsFirstPage = false;
                }

                if(this.pageNo < this.totalPages && !this.booIsFirstPage) {
                    this.strategy = this.lstStrategies[this.pageNo];
                    this.pageNo += 1;
                    this.currentStep = this.pageNo;
                    this.booDisabled = false;
                }

                if(this.pageNo === this.totalPages){
                    this.strButtonLabel = 'Clone';
                }
            }


        }
        this.booLoading = false;
    }
    previous() {
        if(this.pageNo >= 0) {
            this.pageNo -= 1;
            this.currentStep = this.pageNo;
            this.strategy = this.lstStrategies[this.pageNo-1];
            console.log(JSON.stringify(this.strategy));
            this.strButtonLabel = 'Next';
        }
        if(this.pageNo === 0){
            this.booDisabled = true;
            this.booIsFirstPage = true;
            this.selectionView = true;
        }
    }

    clonePlanRecord() {
        // DCP-41767
        if(!this.isOverLayPlan)
            this.planNameAutomated = this.isIndirectRecord ? this.year +' '+this.channelPartnerName+' Plan' : this.year +' '+this.territoryName+' Plan';
        let planData = {
            'Territory_Name': this.territoryName,
            'Territory_Code': this.territoryCode,
            'Territory_Id': this.territoryId,
            'Territory_Region': this.territoryRegion,
            'Overlay_Role': this.overlayRole,
            'Channel_Partner': this.idChannelPartner,
            'Channel_Partner_Territory_Code': this.channelPartnerCode,
            'Start_Date': this.startDate,
            'End_Date': this.endDate,
            'Name' : this.isOverLayPlan ? '' : this.planNameAutomated
        };
        consoleLog('Details -->', planData);
        this.booLoading = true;
        let lstStrategiesToClone = JSON.parse(JSON.stringify(this.lstStrategies));
        lstStrategiesToClone = lstStrategiesToClone.filter(function (selectedStrategies) {
            return selectedStrategies.isChecked;
        });

        lstStrategiesToClone.forEach(strategy => {
            strategy.lstObjectives = strategy.lstObjectives.filter(function (selectedObjectives) {
                return selectedObjectives.isChecked;
            });

            strategy.lstObjectives.forEach(objective => {
                objective.lstActions = objective.lstActions.filter(function (selectedActions) {
                    return selectedActions.isChecked;
                });
            });
        });

        consoleLog('@@@ Data to clone -->' + JSON.stringify(lstStrategiesToClone));

        callServer(deepClone, {
            strFieldValues: JSON.stringify(planData),
            strRecordId: this.recordId,
            strLstStrategies: JSON.stringify(lstStrategiesToClone)
        }, result => {
            consoleLog('data -->', result);
            showSuccessToast(this.mapUILabels.UI_Message_Plan_Created);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    objectApiName: 'Plan__c',
                    actionName: 'view'
                },
            });
            this.booLoading = false;
        }, error => {
            this.booLoading = false;
        });
    }
    // DCP-41767
    startSelect(event){
        this.startDate = event.target.value;
    }
    // DCP-41767
    endSelect(event){
        this.endDate = event.target.value;
    }

    handleChangeStrategies(event) {
        let index = event.target.id.split('-')[0];
        this.lstStrategies[index].isChecked = event.target.checked;
        if(!this.lstStrategies[index].isChecked) {
            this.lstStrategies[index].lstObjectives.forEach(objective => {
                objective.isChecked = false;
                objective.lstActions.forEach(action => {
                    action.isChecked = false;
                });
            });
        }

    }

    handleChangeObjectives(event) {
        let index = event.detail.index.split('_');
        let strategyIndex = index[0];
        let objectiveIndex = index[1];
        this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].isChecked = event.detail.checked;
        if(!this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].isChecked) {
            this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].lstActions.forEach(action => {
                action.isChecked = false;
            });
        }
    }

    handleChangeActions(event) {
        let index = event.detail.index.split('_');
        let strategyIndex = index[0]
        let objectiveIndex = index[1];
        let actionIndex = index[2];
        this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].lstActions[actionIndex].isChecked = event.detail.checked;               
    }

    handleDueDateChange(event) {
               
        let checked = event.detail.checked;
        let dueDate = event.detail.dueDate;
        let isObjective = event.detail.isObjective;
        let index = event.detail.index.split('_');
        let strategyIndex = index[0];
        let objectiveIndex = index[1];

        if(isObjective) {           
            this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].dueDate = checked ? dueDate : null ;
        } else {
            let actionIndex = index[2];            
            this.lstStrategies[strategyIndex].lstObjectives[objectiveIndex].lstActions[actionIndex].dueDate = checked ? dueDate : null;
        }        
    }

    checkValidity() {
        let isValidInput = true;
        if(!this.booIsFirstPage){
            isValidInput = this.template.querySelector('c-objectives-actions-for-plans-l-w-c').validateInputs() && this.validateInputs();   
        }
        return isValidInput;
    }
    
    // Get Today Date in ISO8601 format. 
    // DCP-52241
    getDateValues()
    {
        let today = new Date();
        let newDate = today.getDate();
        let newMonth = today.getMonth();
        let newMonthNumber = Number(newMonth) + 1;
        if(newDate < 10)
        {
            newDate = '0' + newDate;
        }
        if(newMonthNumber < 10)
        {
            newMonthNumber = '0' + newMonthNumber;
        }
        let todayDate = today.getFullYear() + '-' + newMonthNumber + '-' + newDate;
        this.todaysDate = todayDate;        
    }
    
    //DCP-52241
    handleStrategyDueDate(event) {

        let dueDate = event.target.value;
        let checked = event.target.dataset.checked;
        let index = event.target.dataset.id;
        this.validateInputs();
        this.lstStrategies[index].dueDate = checked ? dueDate : null;
    }

    // DCP-52241
    @api
    validateInputs() {
        return [...this.template.querySelectorAll('.due-date')]
            .reduce((validSoFar, inputCmp) => {               
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();                               
            }, true);       
    }

}
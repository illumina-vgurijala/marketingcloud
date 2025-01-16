import { LightningElement, api, track, wire } from 'lwc';
import { consoleLog, showSuccessToast, callServer, isEmpty, showErrorToast } from 'c/utils';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getObjectivesAndActions from '@salesforce/apex/AccountPlanCloneController.getObjectivesAndActions';
import cloneAccountPlan from '@salesforce/apex/AccountPlanCloneController.cloneAccountPlan';
import { getYearOptions } from 'c/planCreationHelper'
import UI_Year_Not_Selected from '@salesforce/label/c.UI_Year_Not_Selected';
import UI_Label_Plan_Start_Date from '@salesforce/label/c.UI_Label_Plan_Start_Date';
import UI_Label_Plan_End_Date from '@salesforce/label/c.UI_Label_Plan_End_Date';

export default class CloneAccountPlanLWC extends NavigationMixin(LightningElement) {

    steps = [
        { label: 'Details Page', value: 'step-1' },
        { label: 'Objectives/Actions', value: 'step-2' }
    ];

    @api recordId;
    @api objectApiName;
    @track lstObjectivesActions = [];
    @track booIsListEmpty;
    @track booShowSpinner=false;
    @track booIsAccountPlan;
    @track clonedRecordId;
    @track booRecordCreated;
    @track strButtonLabel = 'Next';
    @track booIsFirstPage = true;
    @track mapClonePlanDetails = {};
    @track currentStep = 'step-1';
    @track previousDisabled = true;
    @track year;

    // Adding labels
    yearErrorMessage = UI_Year_Not_Selected;
    startDate = UI_Label_Plan_Start_Date;
    endDate = UI_Label_Plan_End_Date;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            try{
                this.objectApiName = currentPageReference.attributes.apiName.split('.')[0];
            }
            catch(Exception) {
                this.objectApiName = currentPageReference.attributes.objectApiName;
            }
        }
    }

    @wire(getObjectivesAndActions, { strRecordId: '$recordId', objectApiName: '$objectApiName' })
    getData({error, data}){
        this.booShowSpinner = true;
        if(data){
            consoleLog('data obj -->', data);
            this.lstObjectivesActions = JSON.parse(data);
            if(!isEmpty(this.lstObjectivesActions)){
                this.booIsListEmpty = false;
            }
            else{
                this.booIsListEmpty = true;
            }
            this.booShowSpinner = false;
        }
        else if(error) {
            this.booShowSpinner = false;
        }
        
    }

    connectedCallback() {}

    @api
    get isAccountPlan() {
        return this.objectApiName==='Account_Plan__c' ? true : false;
    }

    @api
    get ismapClonePlanDetailsEmpty() {
        return Object.keys(this.mapClonePlanDetails).length;
    }

    get yearOptions() {
        return getYearOptions();
    }

    yearSelect(event) {
        this.year = event.target.value;
        this.mapClonePlanDetails['Start_Date__c'] = new Date(this.year + this.startDate).toISOString();
        this.mapClonePlanDetails['End_Date__c'] = new Date(this.year + this.endDate).toISOString();
    }

    handleChangeObjectives(event) {
        let index = event.detail.index;
        this.lstObjectivesActions[index].isChecked = event.detail.checked;
        if(!this.lstObjectivesActions[index].isChecked) {
            this.lstObjectivesActions[index].lstActions.forEach(action => {
                action.isChecked = false;
            });
        }
        consoleLog(JSON.stringify(this.lstObjectivesActions));
    }

    handleChangeActions(event) {
        let index = event.detail.index;
        let obj_index = index.split('_')[0];
        let act_index = index.split('_')[1];
        this.lstObjectivesActions[obj_index].lstActions[act_index].isChecked = event.detail.checked;

    }

    handleDueDateChange(event) {
               
        let checked = event.detail.checked;
        let dueDate = event.detail.dueDate;
        let isObjective = event.detail.isObjective;
        let objectiveIndex, actionIndex;
                
        if(isObjective) {
            objectiveIndex = event.detail.index;
            this.lstObjectivesActions[objectiveIndex].dueDate = checked ? dueDate : null ;
        } else {
            objectiveIndex = event.detail.index.split('_')[0];
            actionIndex = event.detail.index.split('_')[1];
            this.lstObjectivesActions[objectiveIndex].lstActions[actionIndex].dueDate = checked ? dueDate : null;
        }        
    }
    handleButtonClickNext() {
        if(this.booIsFirstPage && this.checkValidity()) {
            this.currentStep = 'step-2';
            this.previousDisabled = false;
            this.strButtonLabel = 'Clone';
            this.booIsFirstPage = false;
            const inputFields = this.template.querySelectorAll(
                'lightning-input-field'
            );
    
            if (inputFields) {
                inputFields.forEach(field => {
                    this.mapClonePlanDetails[field.fieldName] = field.value;
                });
            }
        }
        else if(!this.booIsFirstPage && this.checkValidity()){
            this.clone();
        }
    }

    handleButtonClickPrevious(){
        this.previousDisabled = true;
        this.booIsFirstPage = true;
        this.currentStep = 'step-1';
        this.strButtonLabel = 'Next';
    }

    checkValidity() {
        this.customErrors = [];
        let isInputsCorrect = [...this.template.querySelectorAll('lightning-input-field')].reduce( (val, inp) => {
            let inpVal = true;
            switch (inp.fieldName) {
                case 'Name':
                    inpVal = inp.value === '' || inp.value === null ? false : true;
                    if (!inpVal) { inp.reportValidity() }
                    break;

                default:
                    inpVal = true;
                    break;
            }
            return val && inpVal;
        }, true);
        
        let isYearSelected = [...this.template.querySelectorAll('lightning-combobox')];
        let isValid = true;
        isYearSelected.forEach(comboBox => {
            if(!comboBox.checkValidity()) {
                comboBox.reportValidity();
                isValid = false;
            }
        });

        let isValidDueDate = true; 
        if(!this.booIsFirstPage){
            isValidDueDate = this.template.querySelector('c-objectives-actions-for-plans-l-w-c').validateInputs();   
        } 

        return isInputsCorrect && isValid && isValidDueDate;
    }

    clone() {
        let lstObjectivesToClone = JSON.parse(JSON.stringify(this.lstObjectivesActions));
        lstObjectivesToClone = lstObjectivesToClone.filter(function (selectedObjectives) {
            return selectedObjectives.isChecked;
        });

        lstObjectivesToClone.forEach(objective => {
            objective.lstActions = objective.lstActions.filter(function (action) {
                return action.isChecked;
            });
        });
        let params = {
            strLstObjectivesActions: JSON.stringify(lstObjectivesToClone),
            strRecordId: this.recordId,
            objectApiName: this.objectApiName,
            strClonePlanDetails: JSON.stringify(this.mapClonePlanDetails)
        };
        this.booShowSpinner = true;
        callServer(cloneAccountPlan, {
            strPlanDetails : JSON.stringify(params)
        }, result => {
            consoleLog('data -->', result);
            this.clonedRecordId = result;
            this.booRecordCreated = true;
            showSuccessToast('Record cloned successfully');
            this.navigateToViewAccountPlanPageWithRecordId(result, 'view');
            this.booShowSpinner = false;
        }, error => {
            this.booShowSpinner = false;
            showErrorToast(error);
            this.navigateToViewAccountPlanPage();
        });


    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToViewAccountPlanPage() {
        this.navigateToViewAccountPlanPageWithRecordId(this.recordId, 'view');
    }

    navigateToViewAccountPlanPageWithRecordId(recordId, actionName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Account_Plan__c',
                actionName: actionName
            },
        });
    }
}
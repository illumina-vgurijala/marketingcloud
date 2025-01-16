import { LightningElement, api, track } from 'lwc';
import { consoleLog, isEmpty } from 'c/utils';


export default class ObjectivesActionsForPlansLWC extends LightningElement {
    @api lstObjectivesActions;
    @track booIsFirstPage = false;
    @track booIsListEmpty = true;
    @track todaysDate;    

    connectedCallback() {
        consoleLog('@@@lstObjectivesActions --> ' + JSON.stringify(this.lstObjectivesActions));
        if(!isEmpty(this.lstObjectivesActions)) {
            this.booIsListEmpty = false;
        }
        this.getDateValues();
    }

    handleChangeObjectives(event) {
        let index = event.target.id.split('-')[0];

        let returnString = {
            "index" : index,
            "checked" : event.target.checked
        }
        this.sendEvent(returnString, "objectivechange");
    }

    handleChangeActions(event) {
        let index = event.target.id.split('-')[0];
        let returnString = {
            "index" : index,
            "checked" : event.target.checked
        }
        this.sendEvent(returnString, "actionchange");
    }

    handleDueDateChange(event)
    {
        let dueDate = event.target.value;
        let checked = event.target.dataset.checked;
        let index = event.target.dataset.id;
        this.validateInputs();
        
        if(checked) {
            let returnString = {
                "index" : index,
                "checked" : checked,
                "dueDate" : dueDate,
                "isObjective" : event.target.classList.contains('objective')
            }
            this.sendEvent(returnString, "duedatechange");
        }
    }
    sendEvent(returnString, eventName){
        const sendValues = new CustomEvent(eventName, { detail : returnString
        });
        this.dispatchEvent(sendValues);
    }

    @api
    validateInputs() {
        return [...this.template.querySelectorAll('.due-date')]
            .reduce((validSoFar, inputCmp) => {               
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();                               
            }, true);       
    }

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
}
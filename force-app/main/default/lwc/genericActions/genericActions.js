import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    refreshApex
} from '@salesforce/apex';
import {
    callServer,
    genericEvent,
    consoleLog,
    showErrorToast,
    showSuccessToast,
    consoleError,
    isEmpty,
    isBlank
} from 'c/utils';
import fetchTaskList from '@salesforce/apex/TerritoryPlanStrategyController.fetchTaskList';
import deleteTask from '@salesforce/apex/AccountPlanObjectivesController.deleteTask';
import createTask from '@salesforce/apex/AccountPlanObjectivesController.createTask';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {
    column_Large
} from './column.js';

export default class GenericActions extends LightningElement {
    @api parentRecordId;
    @api maplabels;
    @track actionData;
    @track showTaskView = false;
    @track editTask = false;
    @track recordIdToDelete;
    @track showConfirmation = false;
    // Task record fields
    @track Subject;
    @track Assigned;
    @track DueDate;
    @track Description;
    @track TaskId;
    @track TaskStatus = 'Open';
    @track TaskPriority = 'Normal';
    @track lookuprecord;
    @track column;
    @track toastMessage;
    @track smallScreen;
    @track booLoading = false;
    @track hasData = false;
    @track selectedList = [];

    connectedCallback() {
        if (FORM_FACTOR === 'Large') {
            this.column = column_Large;
            this.smallScreen = false;
        } else {
            this.smallScreen = true;
        }
    }
    wiredsObjectData;
    @wire(
        fetchTaskList, {
            strRecordid: '$parentRecordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Task Data --> ', result.data);
            let returndata = JSON.parse(result.data);
            this.actionData = returndata.lstActionWrapper;
            if (!isEmpty(this.actionData))
                this.hasData = true;
        } else if (result.error) {
            consoleError('Error->', result.error);
        }
    }
    handleSectionToggle(event) {

    }
    get TaskPriorityoptions() {
        return [{
                label: 'Normal',
                value: 'Normal'
            },
            {
                label: 'High',
                value: 'High'
            },
        ];
    }
    get TaskStatusoptions() {
        return [{
                label: 'Open',
                value: 'Open'
            },
            {
                label: 'Completed',
                value: 'Completed'
            },
        ];
    }
    createNewTask(event) {
        this.editTask = false;
        this.ObjectAPi = this.maplabels.UI_Label_Task_API;
        this.ObjectiveId = this.parentRecordId;
        this.showTaskView = true;
        this.ModalHeaders = this.maplabels.UI_Modal_Header_New_Task;
        this.toastMessage = this.maplabels.UI_Message_Task_Create;
    }
    saveEditTask(event) {
        if (!this.validateInput()) {
            this.booLoading = true;
            if(this.editTask){ this.lookuprecord = this.template.querySelector('c-lookup-custom').selectRecordId(); }
            let lookuprecordid;
            if (!this.DueDate) this.DueDate = undefined;
            if (this.lookuprecord) lookuprecordid = this.lookuprecord.Id;
            let taskData = {
                'Subject': this.Subject,
                'DueDate': this.DueDate,
                'Descrition': this.Description,
                'Status': this.TaskStatus,
                'Priority': this.TaskPriority,
                'OwnerId': lookuprecordid,
                'TaskId': this.TaskId,
            };

            let stringData = JSON.stringify(taskData);
            let params = {
                taskData: stringData,
                objectiveId: this.ObjectiveId
            }
            if(!this.editTask){
                params["selectedRec"] = JSON.stringify(this.selectedList);
                consoleLog('selectedRec -->' + JSON.stringify(this.selectedList));
            }
            else{
                params["selectedRec"] = JSON.stringify([]);
            }
            callServer(createTask, params
                , result => {
                    if(result){
                        showSuccessToast(this.toastMessage);
                    }
                    refreshApex(this.wiredResults);
                    this.closeModal();
                    this.updateEvent();
                    this.booLoading = false;
                }, error => {
                    showErrorToast(error.body.message);
                    consoleLog('Error-->', error);
                    this.booLoading = false;
                }
            );
        }
        else{
            consoleLog('Validation Failed');
        }
    }

    //DCP-39189
    //To validate Subject and Due Date    
    validateInput() {
        let flag = false;
        if (isBlank(this.Subject)) {
            this.template.querySelector('.subjectSelect').showHelpMessageIfInvalid();
            flag = true;
        }
        if (isBlank(this.DueDate)) {
            this.template.querySelector('.duedateSelect').showHelpMessageIfInvalid();
            flag = true;
        }
        if(!this.editTask && isEmpty(this.selectedList) && this.template.querySelector('c-multi-select-lookup').checkValidity()) {
            flag = true;
        }
        return flag;
    }

    componenttaskdelete(event) {
        let TaskRow;
        if (this.smallScreen)
            TaskRow = event.target.value;
        else
            TaskRow = event.detail;
        this.recordIdToDelete = TaskRow.strrecordid;
        this.showConfirmation = true;
        this.ObjectAPi = this.maplabels.UI_Label_Task_API;
        this.ConfirmationMessage = this.maplabels.UI_Message_Delete_Confirmation.replace('{0}', 'Task');
    }
    deleteDeactivateRecords(event) {

        deleteTask({
                recordId: this.recordIdToDelete
            })
            .then(result => {
                showSuccessToast(this.maplabels.UI_Message_Task_Delete);
                refreshApex(this.wiredResults);
                this.closeModal();
                this.updateEvent();

            })
            .catch(error => {
                consoleLog('Error', error)
            })
        refreshApex(this.wiredResults);
    }
    componenttaskedit(event) {
        consoleLog('Inside component >');
        this.editTask = true;
        this.ModalHeaders = this.maplabels.UI_Modal_Header_Edit_Task;
        let TaskRow;
        if (this.smallScreen)
            TaskRow = event.target.value;
        else
            TaskRow = event.detail;
        this.recordIdUpdate = TaskRow.strrecordid;
        this.Subject = TaskRow.subject;
        this.DueDate = TaskRow.dueDate;
        this.Description = TaskRow.comments;
        this.TaskId = TaskRow.strrecordid;
        this.TaskStatus = TaskRow.status;
        this.TaskPriority = TaskRow.priority;
        this.lookuprecord = {
            "Id": TaskRow.assignedId,
            "Name": TaskRow.assignedTo
        }
        this.toastMessage = this.maplabels.UI_Message_Task_Edit;
        this.showTaskView = true;
    }
    taskFieldChange(event) {
        if (event.target.name === 'Subject') {
            this.Subject = event.target.value;
        }
        if (event.target.name === 'DueDate') {
            this.DueDate = event.target.value;
        }
        if (event.target.name === 'Description') {
            this.Description = event.target.value;
        }
        if (event.target.name === 'TaskStatus') {
            this.TaskStatus = event.target.value;
        }
        if (event.target.name === 'TaskPriority') {
            this.TaskPriority = event.target.value;
        }
    }
    resetTaskField() {
        this.Subject = undefined;
        this.Assigned = '';
        this.DueDate = undefined;
        this.Description = undefined;
        this.TaskId = undefined;
        this.TaskStatus = 'Open';
        this.TaskPriority = 'Normal';
        this.ObjectiveId = undefined;
        this.lookuprecord = undefined;

    }
    closeModal() {
        this.showSaveView = false;
        this.showEditView = false;
        this.showConfirmation = false;
        this.showTaskView = false;
        this.ModalHeaders = '';
        this.resetTaskField();
    }
    updateEvent() {
        const objDetails = Object.create({});
        objDetails.value = 'Record Action Performed';
        genericEvent('recordactionperformed', objDetails, this);
    }

    //DCP-46115
    setSelectedList(event)
    {
        console.log(JSON.stringify(event.detail));
        this.selectedList = [];
        let selectedUsers = event.detail.selRecords;
        selectedUsers.forEach(user => { this.selectedList.push(user.strKey); });

    }
}
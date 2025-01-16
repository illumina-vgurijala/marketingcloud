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
    consoleLog,
    isEmpty,
    showSuccessToast,
    showErrorToast,
    callServer,
    consoleError
} from 'c/utils';
import fetchAssociatedAccount from '@salesforce/apex/TerritoryPlanStrategyController.fetchAssociatedAccount';
import deleteAssociatedAccount from '@salesforce/apex/TerritoryPlanStrategyController.deleteAssociatedAccount';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {
    column, 
    accountColumn
} from './columns.js';

export default class TerrritoryPlanAssociatedAccount extends LightningElement {
    @api objectiveRecordId;
    @api maplabels;
    @track associatedAccount = [];
    @track column = column;
    @track lstAccountAvailable = [];
    @track recordData = {};
    @track wiredResults;
    addAccountView = false;
    sortBy;
    sortDirection;
    booLoading = false;
    isMobile = false;    
    
    connectedCallback() {
        if (FORM_FACTOR === 'Small')
            this.isMobile = true;
    }

    @wire(
        fetchAssociatedAccount, {
            strRecordId: '$objectiveRecordId'
        }
    )
    imperativeWiring(result) {
        this.booLoading = true;
        this.wiredResults = result;
        let dataForProcessing  = Object.create({});
        if (result.data) {            
            let returndata = JSON.parse(result.data);
            this.associatedAccount = returndata.lstAccountPlanObjectiveWrapper;
            dataForProcessing.lstAccountAvailable = returndata.lstAccountWrap;            
            dataForProcessing.currentObjectiveDetails = returndata.planObjective;
            dataForProcessing.customerTypePicklistValues = returndata.customerTypeValues;
            dataForProcessing.accountColumn = accountColumn;       
        } else if (result.error) {
            consoleError('Error', result.error);
        }

        this.recordData = dataForProcessing;
        this.booLoading = false;
    }
    createNewAssociation() {
        this.addAccountView = true;
    }
    closeModal() {
        this.addAccountView = false;
        this.resetSearchKey();
    }
    removeAssociation() {
        this.booLoading = true;
        let associatedAccountDelete = [];
        let selectedRecords = this.template.querySelectorAll('lightning-datatable')[0].getSelectedRows();
        selectedRecords.forEach(element => {
            associatedAccountDelete.push(element.strRecordID);
        });
        if (isEmpty(associatedAccountDelete)) {
            showErrorToast(this.maplabels.UI_Label_No_Row_Selected);
            this.booLoading = false;
        } else
            this.deleteAssociatedAccount(associatedAccountDelete);
    }
    // Data Table funtionality
    handleRowAction(event) {
        const rowDetail = event.detail.row;
        const actionName = event.detail.action.name;
        if(actionName === 'Remove Account') {
            this.booLoading = true;
            let associatedAccountDelete = [];
            associatedAccountDelete.push(rowDetail.strRecordID);
            consoleLog('List to be deleted', associatedAccountDelete);
            this.deleteAssociatedAccount(associatedAccountDelete);
        }
    }

    //Call child component for adding ATO records
    addAssociation() {
        this.template.querySelector('c-territory-plan-associated-account-helper').addAssociation();
    }
    
    //Delete ATO records
    deleteAssociatedAccount(lstAssociatedAccountId) {        
        callServer(deleteAssociatedAccount, {            
            lstRecordId: lstAssociatedAccountId
        }, result => {              
            showSuccessToast(result);
            refreshApex(this.wiredResults);
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
        this.associatedAccount = this.sortData(this.associatedAccount, event.detail.fieldName, event.detail.sortDirection);
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
    get showAssociatedAccount() {
        return !isEmpty(this.associatedAccount) && !this.booLoading;
    }

    // Changes for DCP-39127
    resetSearchKey() {
        this.template.querySelector('c-territory-plan-associated-account-helper').resetSearchKey();
    }

    refreshData() {
        refreshApex(this.wiredResults);
    }
    
    // Changes for DCP-39127
    get noAssociatedAccount() {
        return isEmpty(this.associatedAccount);
    }
}
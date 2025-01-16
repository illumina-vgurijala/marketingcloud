import { LightningElement, api, track } from 'lwc';

import retriveShareRecords from '@salesforce/apex/SharingConsole.retriveShareRecords';

const searchColumns = [{
        label: 'RowCause',
        fieldName: 'rowCause',
        sortable: true,
    }, {
        label: 'Shared With',
        fieldName: 'userName',
        sortable: true,
        type: 'text'
    }, {
        label: 'Accedd Level',
        fieldName: 'accessLevel',
        type: 'text',
        sortable: true
    }, {
        label: 'Last Modified Date',
        fieldName: 'lastModifiedDate',
        type: 'date',
        sortable: true,
        typeAttributes: 
        {
            day: 'numeric',  
            month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            second: '2-digit',  
            hour12: true
        }
    },
];
export default class RecordSharing extends LightningElement {
    
    @api recordId;
    @track searchData;
    @track searchColumns = searchColumns;
    @track errorMsg = '';
    @track isLoaded = false;

    connectedCallback() {
        this.isLoaded = !this.isLoaded;
        retriveShareRecords({recordIds : this.recordId})
        .then(result => {
            this.searchData = result; 
            this.isLoaded = false;
            this.sortData('userName', 'asc');
            window.console.log('Result Data:  '+JSON.stringify(result.data));         
        })
        .catch(error => {
            this.searchData = undefined;
            this.isLoaded = false;
            window.console.log('error: '+JSON.stringify(error));
            if(error) {
                this.errorMsg = error.body.message;
            }
        }) 
    }
    handleSortData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.searchData));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.searchData = parseData;
    }
}
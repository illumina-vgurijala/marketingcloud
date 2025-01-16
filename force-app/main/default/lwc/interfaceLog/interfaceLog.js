import { LightningElement, api, track } from 'lwc';
import retriveInterfaceLogRecords from '@salesforce/apex/InterfaceLog.retreiveInterfaceLogs';

const columns = [
    {
        label: 'Id',
        fieldName: 'id',
        type: 'url'
    },
    {
        label: 'Name',
        fieldName: 'name',
    }, {
        label: 'Result',
        fieldName: 'result',
        type: 'text'
    }, 
    {
        label: 'Last Modified Date',
        fieldName: 'lastModifiedDate',
        type: 'Datetime'
    }, 
];

export default class intertfaceLog extends LightningElement {
    
    @api recordId;
    @track searchData;
    @track columns = columns;
    @track errorMsg = '';

    connectedCallback() {
        retriveInterfaceLogRecords({recordId : this.recordId})
        .then(result => {
            this.searchData = result; 
            window.console.log(' Result Data:  '+JSON.stringify(result.data));         
        })
        .catch(error => {
            this.searchData = undefined;
            window.console.log('error:  '+JSON.stringify(error));
            if(error) {
                this.errorMsg = error.body.message;
            }
        }) 
    }
}
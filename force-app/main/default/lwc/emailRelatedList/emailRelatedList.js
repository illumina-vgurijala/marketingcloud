import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecords from '@salesforce/apex/EmailRelatedListController.getRecords';
import {isNotEmpty} from 'c/utils'; //DCP-51321
 
const columns = [
    {
        label: 'Subject',
        fieldName: 'subjectUrl',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { 
                fieldName: 'Subject' 
            },
            target : '_self'
        }
    },
    {
        label: 'From Address',
        fieldName: 'FromAddress',
        type: 'email',
        sortable: true
    },
    {
        label: 'To Address',
        fieldName: 'ToAddress',
        type: 'text',
        sortable: true
    },
    {
        label: 'Message Date',
        fieldName: 'MessageDate',
        type: 'date', 
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: 'numeric',
                minute: 'numeric',
                hour12: true
        },
          sortable: true
    },
    {
        label: 'Status',
        fieldName: 'Status',
        sortable: true
    },

    {
        label: 'Attachment',
        sortable: true,
        cellAttributes:{ 
                iconName: { 
                    fieldName: 'paperClipIcon' 
                },
                iconPosition: 'right', 
                iconAlternativeText: 'PaperClip Icon' 
            }
    },
];
/*********************************************
    * @description Method to get the data from apex class and assign the data to the lwc component 
    * @param ParentId parameter which passes caseId
    * @param caseNumber parameter which holds caseNumber
    * @param recordId parameter which holds case recordId
    * @param sortBy specifies the default sortby coloumn
    * @param sortDirection specifies the default sort direction
    * @param columns holds the list of columns to be displayed on data table
    * @param data holds the list of data to be displayed on the data table
    * @param error used to capture error
    * @return returns list of emails associated to a case
    * DCP-43125
    * updated by Deepika Ayyavari
    */ 
export default class emailRelatedList extends NavigationMixin( LightningElement ) {
    @api ParentId;
    @api caseNumber;
    @api recordId; 
    @track sortBy = 'MessageDate';
    @track sortDirection = 'desc'; 
    @track sortArray = [];
    columns = columns;
    data = [];
    error;
    totalNumberOfRows = 2000; // stop the infinite load after this threshold count
    // offSetCount to send to apex to get the subsequent result. 0 in offSetCount signifies for the initial load of records on component load.
    offSetCount = 0;
    loadMoreStatus;
    targetDatatable; // capture the loadmore event to fetch data and stop infinite loading
    totalNumberOfRows = this.offSetCount;
    
    connectedCallback() {
        //Get initial chunk of data with offset set at 0
        this.getRecords();
    }
 
    /*********************************************
    * @description passing parameter values to the apex method
    */
    getRecords() {
        getRecords({offSetCount : this.offSetCount, caseId: this.ParentId})
            .then(result => {
                result = JSON.parse(JSON.stringify(result));
                result.forEach(record => {
                    this.sortData('MessageDate','desc');
                    record.subjectUrl = '/' + record.Id;
                    //DCP-51321 [added criteria to display icon excluding logos Images]
                    if(isNotEmpty(record.ContentDocumentLinks)) {
                        record.paperClipIcon = 'utility:attach';
                    }
                    if(record.ParentId){
                        this.caseNumber = record.Parent.CaseNumber;
                    }
                    if(record.Status === '0'){
                        record.Status = 'New';
                    } 
                    if(record.Status === '1'){
                        record.Status = 'Read';
                    } 
                    if(record.Status === '2'){
                        record.Status = 'Replied';
                    } 
                    if(record.Status === '3'){
                        record.Status = 'Sent';
                    } 
                    if(record.Status === '4'){
                        record.Status = 'Forwarded';
                    } 
                     if(record.Status === '5'){
                        record.Status = 'Draft';
                    }  
                });
                
                
                this.data = [...this.data, ...result];
                this.sortArray = [...this.data];
                this.error = undefined;
                this.loadMoreStatus = '';
                
                if (this.targetDatatable && this.data.length >= this.totalNumberOfRows) {
                    //stop Infinite Loading when threshold is reached
                    this.targetDatatable.enableInfiniteLoading = false;
                    //Display "No more data to load" when threshold is reached
                    this.loadMoreStatus = 'No more data to load';
                }
                //Disable a spinner to signal that data has been loaded
                if (this.targetDatatable) this.targetDatatable.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.data = undefined;
                console.log('error : ' + JSON.stringify(this.error));
                
            });    
    }
    /*********************************************
    * @description Method to handle sort on all the columns in the lwc data table
    */
   handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        if((event.detail.fieldName !== undefined) && (event.detail.fieldName !== 'subjectUrl')) {
            this.sortData(event.detail.fieldName, event.detail.sortDirection);
       }
        else if(event.detail.fieldName === 'subjectUrl') {
           event.detail.fieldName = 'Subject';
           this.sortData('Subject', event.detail.sortDirection);
       }
        else{      
           this.sortData('paperClipIcon',event.detail.sortDirection);
       }
    }

    /*********************************************
    * @description Method to sort data in ascending or desending order 
    * all the columns in the lwc data table
    */

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.sortArray));

        // Return the value stored in the field
        let keyValue = (a) => {
            //return a[fieldname];
            return a.hasOwnProperty(fieldname) ? (typeof a[fieldname] === 'string' ? a[fieldname].toLowerCase() : a[fieldname]) : ''
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.data = parseData;

    }

 
    // Event to handle onloadmore on lightning datatable
    handleLoadMore(event) {
        event.preventDefault();
        // increase the offset count by 2000 on every loadmore event
        this.offSetCount = this.offSetCount + 2000;
        //Display a spinner to signal that data is being loaded
        event.target.isLoading = true;
        //Set the onloadmore event taraget to make it visible.
        this.targetDatatable = event.target;
        //Display "Loading" when more data is being loaded
        this.loadMoreStatus = 'Loading';
        // Get new set of records and append to this.data
        this.getRecords();
    }

 //Method to navigate to Case Detail page 
    handleNavigatetoCaseDetail(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.ParentId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

// Method to navigate to Case list view
    handleNavigatetoCaseView(){
        this[NavigationMixin.Navigate]({
            "type": "standard__objectPage",
            "attributes": {
                "objectApiName": "Case",
                "actionName": "home"
                }
            });
    }
}
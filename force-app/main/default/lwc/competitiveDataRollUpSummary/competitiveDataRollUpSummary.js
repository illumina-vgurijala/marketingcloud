import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import initRecords from '@salesforce/apex/CompetitiveDataRollUpSummaryCtrl.initRecords';
import relatedRecords from '@salesforce/apex/CompetitiveDataRollUpSummaryCtrl.relatedRecords';
import newButtonLbl from '@salesforce/label/c.CompetitiveDataRollUpSummary_New';
import { consoleLog, consoleError } from 'c/utils';

const RollUpcolumns = [{
    label: 'Company Name',
    fieldName: 'CompanyName',
    sortable: true
},
{
    label: 'Number Of Records',
    fieldName: 'NumberOfRecord',
    type : 'number',
    sortable: true,
    cellAttributes: 
        { 
            alignment: 'center' 
        }
},
{
    label: '',
    type: 'button-icon',
    initialWidth: 50,
    typeAttributes: {
        iconName: 'action:preview',
        title: 'Details',
        variant: 'border-filled',
        alternativeText: 'View'
    }
}
];
const RecordDetailColumn = [
    
    {
        label: 'Action',
        fieldName: 'cctRecLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'View' }, target: '_blank' }
    },
    {
        label: 'Account', 
        fieldName: 'AccountName',
        sortable: true
    },
    {
        label: 'Company',
        fieldName: 'Company',
        sortable: true
    },
    {
        label: 'Company Other',
        fieldName: 'CompanyOther',
        sortable: true
    },
    {
        label: 'Product Name',
        fieldName: 'ProductName',
        sortable: true
    },
    {
        label: 'Product Name-Other',
        fieldName: 'ProductNameOther',
        sortable: true
    },
    {
        label: 'Number of Units',
        fieldName: 'NumberOfUnits',
        type : 'number',
        cellAttributes: 
            { 
                alignment: 'center' 
            },
        sortable: true
    },
    {
        label: 'Usage Status',
        fieldName: 'IsInUse',
        sortable: true
    },
    {
        label: 'Created By',
        fieldName: 'CreatedByUser',
        sortable: true
    }
    

];
export default class CompetitiveDataRollUpSummary extends NavigationMixin(LightningElement) {
    @api recordId; 
    @track showtable = true;
    @track RollUpcolumns = RollUpcolumns;
    @track RecordDetailColumn = RecordDetailColumn;
    @track lstOfRecord;
    @track bShowModal = false;
    @track lstOfRecordDetail;
    @track CompanySelected;
    @track ShowEmptyMessage = false;
    @track sortBy;
    @track sortDirection;
    @track loadMoreStatus;
    @track OffSet;
    @track totalNumberOfRows;
    @track InfinityLoad = true;
    @track DisplayLabels;
    @track isLoading = false;
    @track isPageLayoutVisible=false;
    showAccountPlanCCT;
    accountId;
    newButtonLbl = newButtonLbl;
    @api isAppPage;
    channelName = '/event/CCT_Event__e';
    subscription = {};

    wiredsObjectData;
    @wire( initRecords, { recordId: '$recordId' } )
    wiredTenders(value) {

        this.wiredsObjectData = value;
        const { data, error } = value;

        if (data) {
            
            this.DisplayLabels = JSON.parse(data.lstLabels);

            if(Object.keys(data.CompData).length == 0){
                this.ShowEmptyMessage = true;
                
            }
            // eslint-disable-next-line no-console
           
            this.lstOfRecord = this.sortData(data.CompData,'NumberOfRecord','desc');
            // eslint-disable-next-line no-console
            //console.log('$%^&*I- '+JSON.stringify(this.lstOfRecord.CompetitiveDataList))
            this.accountId = data.accountId; 
         } else if (error) {
              // eslint-disable-next-line no-console
            
             this.error = error;
         }
    }

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    handleSubscribe() {
        // ARROW function is very important here. We have to use arrow function as it does not have its own scope
        const messageCallback = (response) => {
            this.handleResponse(response);
        }
 
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            this.subscription = response;
        });
    }

    handleResponse(response){
        let accountsIds = response.data.payload.Account_Ids__c;
        const ids = accountsIds.split(',');
        if(ids?.includes(this.accountId)) {
            refreshApex(this.wiredsObjectData);
        }
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            consoleError('Received error from server: ', error);
            // Error contains the server-side error
        });
    }

    // Row Action event to show the details of the record
    handleRowAction(event) {
        this.CompanySelected = event.detail.row.CompanyName;
        this.totalNumberOfRows = event.detail.row.NumberOfRecord;
        this.OffSet = 0;
		this.lstOfRecordDetail = [];
       
        consoleLog('Recordid-->', this.recordId);
        relatedRecords({
            recordId: this.recordId,
            Offset : this.OffSet,
            strCompanyName : this.CompanySelected
        })
        .then(result =>{
            this.lstOfRecordDetail = result;
            if (this.lstOfRecordDetail) {
               this.lstOfRecordDetail = JSON.parse(JSON.stringify(this.lstOfRecordDetail));
               this.lstOfRecordDetail.forEach(res => {
                res.cctRecLink = '/' + res.Id;
                res.View ='View';
            });
            this.lstOfRecordDetail = lstOfRecordDetail;
           }

           if(this.totalNumberOfRows == Object.keys(result).length)
                this.InfinityLoad = false;
        })
        .catch(error =>{
            
        })
        this.bShowModal = true; // display modal window
    }
    loadMoreData(event){
        if(!this.isLoading){
            this.isLoading = true;
            const currentRecord = this.lstOfRecordDetail;
            this.OffSet += 20;
            let localOffset = this.OffSet;
            this.OffSet = localOffset;
            relatedRecords({
                recordId: this.recordId,
                Offset : localOffset,
                strCompanyName : this.CompanySelected
            })
            .then(result =>{
                const currentData = result;
                const newData = currentRecord.concat(currentData);
                this.lstOfRecordDetail = newData;
                if (Object.keys(newData).length >= this.totalNumberOfRows) {
                    this.InfinityLoad = false;
                }
                else 
                {
                }
                this.isLoading = false;
            })
            .catch(error =>{
                consoleError(`Error while loading data record:${this.recordId} companyName:${this.CompanySelected}`, error);
            })
        }

    }
 
    // to close modal window set 'bShowModal' tarck value as false
    closeModal() {
        this.isPageLayoutVisible=false;
        this.bShowModal = false;
        this.offset = 0;
        this.InfinityLoad = true;
    }
    handleSortdataRollup(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction 
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.lstOfRecord = this.sortData(this.lstOfRecord,event.detail.fieldName, event.detail.sortDirection);
    }
    handleSortdataDetail(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction 
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.lstOfRecordDetail = this.sortData(this.lstOfRecordDetail,event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(datalist,fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(datalist));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
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
        return parseData;

    }
    handleNewClick(){
        
        this.showAccountPlanCCT=true;
        this.isPageLayoutVisible=true;
        
    }

    handleClickCancel(){
        this.closeModal();
    }
    
}
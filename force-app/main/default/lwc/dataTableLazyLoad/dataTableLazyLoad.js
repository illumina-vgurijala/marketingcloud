import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    isEmpty,
    genericEvent
} from 'c/utils';
import UI_Label_No_Row_Found from '@salesforce/label/c.UI_Label_No_Row_Found';
import UI_Label_Load_More from '@salesforce/label/c.UI_Label_Load_More';
export default class DataTableLazyLoad extends LightningElement {
    @api column;
    @api tableDataRecords;
    @api key;
    @api offSet;
    @api hideColumn;
    @api apexPagination;
    @api enableinfinityLoading = false;
    @api selectedRows; //SPQ-45
    @api sortOnCompleteData = false; //DCP-51321
    @api wrapHeader = "none"; //DCP-60
    @track tableDataRecordsSet = [];
    @track tableDataRecordLength;
    @track endIndex;
    @track infinityLoad = false;
    @track loadMoreButtonDisabled = false;
    @track fireEvent = false;
    @track sortBy;
    @track sortDirection;
    @track tableLoadingState = false;
    @track boolShowColumn = false;
    label = {
        UI_Label_Load_More,
        UI_Label_No_Row_Found
    };

    connectedCallback() {
        if (this.apexPagination === 'Yes')
            this.fireEvent = true;
        if(this.enableinfinityLoading)
            this.infinityLoad = true;
        if(this.hideColumn)
            this.boolShowColumn = true;
        console.log('boolShowColumn-->'+this.boolShowColumn);
        console.log('infinityLoad-->'+this.infinityLoad);
        this.offSet = parseInt(this.offSet);
        this.endIndex = this.offSet + 1;
        this.tableDataRecordLength = this.tableDataRecords.length;
        if (this.endIndex >= this.tableDataRecordLength){
            this.loadMoreButtonDisabled = true;
            this.infinityLoad = false;
        }
        this.tableDataRecordsSet = this.tableDataRecords.slice(0, this.endIndex);
        console.log('tableDataRecordsSet-->'+this.tableDataRecordsSet);
        console.log('tableDataRecordsSet-->'+this.endIndex);
    }
    loadMoreData() {
        if (this.fireEvent) {
            const objDetails = Object.create({});
            objDetails.endIndex = this.endIndex;
            genericEvent('loadmore', objDetails, this);
        } else {
            if (this.tableDataRecordLength >= this.endIndex) {
                this.tableLoadingState = true;
                this.endIndex += this.offSet;
                if (this.tableDataRecordLength <= this.endIndex) {
                    this.infinityLoad = false;
                    this.loadMoreButtonDisabled = true;
                }
                this.tableDataRecordsSet = this.tableDataRecords.slice(0, this.endIndex);
                this.tableLoadingState = false;
                const objDetails = Object.create({});//SPQ-45
                genericEvent('datapersistance',objDetails, this);//SPQ-45
            }
        }
    }

    get hasRows() {
        return !isEmpty(this.tableDataRecordsSet);
    }
    handleRowAction(event){
        const rowDetail = event.detail.row;
        const actionName = event.detail.action.name;
        const objDetails = Object.create({});
        objDetails.value = rowDetail;
        objDetails.actionName = actionName;
        genericEvent('customrowaction', objDetails, this);
    }
    @api
    fetchSelectedRecord() {
        let selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        return selectedRecords;
    }
    // Sorting method
    handleSortdataDetail(event) {
        // field name
        this.sortBy = event.detail.fieldName;
        console.log('Sorting details ->'+JSON.stringify(event.detail));

        // sort direction 
        this.sortDirection = event.detail.sortDirection;

        //START - DCP-51321
        if(this.sortOnCompleteData) {
            const objDetails = Object.create({});
            objDetails.fieldName = this.sortBy;
            objDetails.sortDirection = this.sortDirection;
            genericEvent('customsortaction', objDetails, this);
        } else {
            // calling sortdata function to sort the data based on direction and selected field
            this.tableDataRecordsSet = this.sortData(this.tableDataRecordsSet,event.detail.fieldName, event.detail.sortDirection);
        }
        //END - DCP-51321
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
    get showLoadmoreOption(){
        return !this.enableinfinityLoading && !this.loadMoreButtonDisabled;
    }
    //SPQ-45
    getSelectedRecords(event){
        const selectedRecords = event.detail.selectedRows;
        genericEvent('select',selectedRecords,this);

    }

    //DCP-51321
    @api
    resetTable(fileRecords) {
        this.tableDataRecordsSet = fileRecords;
    }
}
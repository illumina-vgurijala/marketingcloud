import {LightningElement,wire,api,track} from 'lwc';
import initRecords from '@salesforce/apex/DataTableController.initRecords';
import updateRecords from '@salesforce/apex/DataTableController.updateRecords';
import {NavigationMixin} from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class PotentialDuplicatesComponent extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api hideCheckboxcolumn = "false";
    @api initialwidth = null;
    @api noofrecordstoload = 10;
    @api showrownum = false;
    @api recordId;
    @api tablecss;
    @api fieldNamesStr;
    @api lookupmap;
    @api whereclause = '';
    @api rowactionmap;
    @api inlineEdit = false;
    @api colAction = false;
	@api columnWidthMode = 'fixed';
    @track data;
    @track columns;
    @track loadMoreStatus;
    @api totalNumberOfRows;
    @api columnactionmap;
    @track sortBy;
    @track sortDirection;
    @track isLoading;
    @track loaded;
	backupData;
	
    wiredsObjectData;
    //called on First Load
    @wire(initRecords, {
        objectName: '$objectApiName',
        fieldNamesStr: '$fieldNamesStr',
        recordId: '',
        orderby: 'Id',
        orderDir: 'ASC',
        inlineEdit: '$inlineEdit',
        enableColAction: '$colAction',
        lookupmap: '$lookupmap',
        rowactionmap: '$rowactionmap',
        whereclause: '$whereclause',
        columnactionmap: '$columnactionmap',
        initialWidth: '$initialwidth',
        noofrecordstoload: '$noofrecordstoload'
    })
    wiredSobjects(result) {
        this.loaded = false;
        this.wiredsObjectData = result;
        if (result.data) {
            this.data = result.data.sobList;
			this.backupData = result.data.sobList;
            console.log('Data..' + JSON.stringify(this.data));
            let rows = JSON.parse(JSON.stringify(this.data));

            /** In the DataTableController Apexclass for look type fields, we have added a object of LabelDescriptionWrapper
             * with a Label and a FieldName(used to fetch value for  a column from the datatable json) . Also we assigned it a typeattribute
             * which denotes which Other fieldName is used as cell label for this column. example :- for look up
             * lookupmap={"SVMXC__Product__r.Name":"Product"};
             * The column  is  "Product , type is "url" ,cell label will be fetched from a json field "product" and cell value from
             *  field "productLink"
             * 
             * As the sobList json returned from apex method is Sobject Rows and is immutable, hence the json is modified here and values for column labels
             * "product" and "productLink" is added below.
             */
            for (let i = rows.length - 1; i >= 0; i--) {
                let dataParse = rows[i];
                if(dataParse.Id == this.recordId){
                    dataParse.styleClass = 'utility:priority';
                }else{
                    dataParse.styleClass = '';
                }
                let tempd;
                for (let key1 in this.lookupmap) {
                    let fieldname = key1.split(".")[0];
                    let val = this.lookupmap[key1];
                    val = val.replace(" ", "").toLowerCase()
                    if (dataParse[fieldname] !== null && dataParse[fieldname] !== undefined) {

                        /** In the resulted json , for look up fields the data is fetch like this
                         * "SVMXC__Product__r":{"Name":"ASSY,MiSeq","Id":"01t1N00000KLBjnQAH"} */
                        tempd = dataParse[fieldname];
                        if (tempd !== null && tempd !== undefined) {
                            //add label(shown on UI) for  cell
                            dataParse[val] = tempd[key1.split(".")[1]];
                            //add cell value  the URL (hidden in UI)
                            dataParse[val + 'Link'] = '/' + tempd['Id'];
                        }
                    }
                }

                dataParse.nameLink = '/' + dataParse.Id;
            }
            this.data = rows;
            this.columns = JSON.parse(JSON.stringify(result.data.ldwList));
            this.totalNumberOfRows = result.data.totalCount;
            if(this.data.length < this.totalNumberOfRows){
                this.loadMoreStatus = 'Scroll down to see more records';
            }
            for(let i=0; i< this.columns.length;i++){
                let columnObj = this.columns[i];
				columnObj.hideDefaultActions = true;
                columnObj.sortable = true;
                if(columnObj.fieldName == "nameLink"){
                    let cell = columnObj.cellAttributes;
                    let cssStyle = { fieldName: 'styleClass'};
                    cell.iconName = cssStyle;
                    cell.iconLabel = '(current)';
                    cell.iconPosition = 'right';
                }
            }
            console.log('columns..' + JSON.stringify(this.columns));
            console.log('data 1..' + JSON.stringify(this.data));
            this.loaded = true;
        } else if (result.error) {
            this.loaded = true;
            console.log('error while loading--:',result.error);
            this.ShowTostMessage('Error', result.error.body.message, 'error');
        }

    }

    //called on Selected Event(If enabled)
    getSelectedName(event) {
        let selectedRows = event.detail.selectedRows;
        let recordIds = [];
        if (selectedRows.length > 0) {
            for (let i = 0; i < selectedRows.length; i++) {
                recordIds.push(selectedRows[i].Id);
            }    
        }
        const selectedEvent = new CustomEvent('selected', {
            detail: {
                recordIds
            },
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

    }

    //called on lazy loading on Scroll
    loadMoreData(event) {
        console.log('more data load--:');
        console.log('data length--:',this.data.length);
        console.log('total rows--:',this.totalNumberOfRows);
        if (this.data.length < this.totalNumberOfRows) {
            let eventDataTable = event.target;
            
            this.isLoading = true;
            //Display "Loading" when more data is being loaded
            this.loadMoreStatus = 'Loading';
            const currentRecord = this.data;
			console.log('length-->',this.backupData.length);
            const lastRecId = this.backupData[this.backupData.length - 1].Id;
            initRecords({
                    objectName: this.objectApiName,
                    fieldNamesStr: this.fieldNamesStr,
                    recordId: lastRecId,
                    orderby: 'Id',
                    OrderDir: 'ASC',
                    inlineEdit: this.inlineEdit,
                    enableColAction: this.colAction,
                    lookupmap: this.lookupmap,
                    rowactionmap: this.rowactionmap,
                    whereclause: this.whereclause,
                    columnactionmap: this.columnactionmap,
                    initialWidth: this.initialwidth,
                    noofrecordstoload: this.noofrecordstoload
                })
                .then(result => {
                    console.log('result--??');
                    let rows = JSON.parse(JSON.stringify(result.sobList));
                    console.log('rows.length..' + rows.length);
                    for (let i = rows.length - 1; i >= 0; i--) {
                        let dataParse = rows[i];
                        let tempd;
                        for (let key1 in this.lookupmap) {
                            let fieldname = key1.split(".")[0];
                            let val = this.lookupmap[key1];
                            val = val.replace(" ", "").toLowerCase()
                            if (dataParse[fieldname] !== null && dataParse[fieldname] !== undefined) {

                                tempd = dataParse[fieldname];

                                if (tempd !== null && tempd !== undefined) {
                                    dataParse[val] = tempd[key1.split(".")[1]];
                                    dataParse[val + 'Link'] = '/' + tempd['Id'];

                                }
                            }
                        }
                            dataParse.nameLink = '/ICPP/' + dataParse.Id;
                    }

                    this.backupData = this.data = currentRecord.concat(rows);
					
                    if (this.data.length >= this.totalNumberOfRows) {
                        eventDataTable.enableInfiniteLoading = false;
                        this.loadMoreStatus = 'No more data to load';
                    } else {
                        //this.loadMoreStatus = '';
                        this.loadMoreStatus = 'Scroll down to see more records';
                    }
                    this.isLoading = false;
                    
                    
                })
                .catch(error => {
                    this.isLoading=false;
                    console.log('error--??');
                    
                    if(error && error.body){
                        this.ShowTostMessage('Error', error.body.message, 'error');
                    }

                    console.log('-------error-------------' + error);
                    console.log(error);
                });
        }
    }
    //handle row action(if enabled) event 
    handleRowAction(event) {
        event.preventDefault();
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('actionName..' + actionName);
        switch (actionName) {
            case 'edit':
                this.editRecord(row);
                break;
            case 'view':
                this.viewRecord(row);
                break;
            case 'delete':
                this.deleteRecord(row);
                break;
            default:
                break;
        }
        console.log('dispatching event');
        const eEvent = new CustomEvent('actionevent', {
            detail: {
                action: actionName,
                rowId: row.Id

            }
        });
        this.dispatchEvent(eEvent);
    }

    // The method will be called on sort click
    updateColumnSorting(event) {
        // field name
        this.sortBy = event.detail.fieldName;
        console.log('eventDetail--:',event.detail);
        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(this.sortBy, this.sortDirection);
    }


    @api
    forceRefreshtable() {
        console.log('in ref table');
        refreshApex(this.wiredsObjectData);
    }

    sortData(fieldName, sortDirection) {
        console.log(sortDirection,'--sorting--',fieldName);
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldName];
        };

        // cheking reverse direction 
        let isReverse = sortDirection === 'asc' ? 1: -1;

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

    //to display the toast message
    ShowTostMessage(vartitle, varmessage, varvariant) {
        const evt = new ShowToastEvent({
            title: vartitle,
            message: varmessage,
            variant: varvariant,
        });
        this.dispatchEvent(evt);

    }
}
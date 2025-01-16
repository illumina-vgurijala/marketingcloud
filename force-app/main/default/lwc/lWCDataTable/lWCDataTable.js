import { LightningElement, wire, api, track } from 'lwc';
import initRecords from '@salesforce/apex/DataTableController.initRecords';
import updateRecords from '@salesforce/apex/DataTableController.updateRecords';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LwcDataTable  extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api hideCheckboxcolumn="true";
  @api initialwidth=null;
  @api noofrecordstoload=10;
  @api showrownum=false;
  @api recordId;
  @api tablecss="zoomtable";
  @api isportaluser=false;
  @api fieldNamesStr; 
  @api lookupmap;
  @api whereclause='';
  @api rowactionmap;
  @api inlineEdit = false;
  @api colAction = false;
  @track data;
  @track columns;
  @track loadMoreStatus;
  @api totalNumberOfRows;
  @api columnactionmap;
  

  wiredsObjectData;
//called on First Load
  @wire(initRecords, { objectName: '$objectApiName', fieldNamesStr: '$fieldNamesStr', recordId: '' , orderby: 'Id', orderDir: 'ASC',inlineEdit:'$inlineEdit' , enableColAction:'$colAction',lookupmap:'$lookupmap',rowactionmap:'$rowactionmap',whereclause:'$whereclause',columnactionmap:'$columnactionmap',initialWidth:'$initialwidth', noofrecordstoload:'$noofrecordstoload'})
    wiredSobjects(result) {
      
        this.wiredsObjectData = result;
        if (result.data) {
           this.data=result.data.sobList;
           console.log('Data..'+JSON.stringify(this.data));
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
	       for(let i =rows.length-1; i >=0; i--) {
             let dataParse = rows[i]; 
             let tempd;
                for (let key1 in this.lookupmap) {
                    let fieldname=key1.split(".")[0];
                    let val=this.lookupmap[key1];
                    val=val.replace(" ","").toLowerCase()
                    if(dataParse[fieldname]!==null && dataParse[fieldname]!==undefined){

                        /** In the resulted json , for look up fields the data is fetch like this
                         * "SVMXC__Product__r":{"Name":"ASSY,MiSeq","Id":"01t1N00000KLBjnQAH"} */
                        tempd=dataParse[fieldname];
                        if(tempd!==null && tempd!==undefined){
                        //add label(shown on UI) for  cell
                        dataParse[val] = tempd[key1.split(".")[1]]; 
                        //add cell value  the URL (hidden in UI)
                        if(this.isportaluser===false)
                            dataParse[val+'Link'] = '/'+tempd['Id']; 
                        else
                            dataParse[val+'Link'] = '/ICPP/'+tempd['Id']; 
                    
                        }
                    }
               } 

               if(this.isportaluser===false)
                dataParse.nameLink='/'+dataParse.Id;
             else
                dataParse.nameLink= '/ICPP/'+dataParse.Id; 
            }
	        this.data = rows;
            this.columns = result.data.ldwList;
            this.totalNumberOfRows = result.data.totalCount;
            console.log('columns..'+ JSON.stringify(this.columns));
            console.log('data 1..'+ JSON.stringify(this.data));
        }else if(result.error){
            this.ShowTostMessage('Error',error.body.message,'error');
        }
        
    }

    //called on Selected Event(If enabled)
    getSelectedName(event) {
        let selectedRows = event.detail.selectedRows;
        let recordIds=[];
        if(selectedRows.length > 0) {
            for(let i =0 ; i< selectedRows.length; i++) {
                recordIds.push(selectedRows[i].Id);
            }
            
           const selectedEvent = new CustomEvent('selected', { detail: {recordIds}, });
           // Dispatches the event.
           this.dispatchEvent(selectedEvent);
        }
        
    }

    //called on lazy loading on Scroll
    loadMoreData(event) {
            if (this.data.length < this.totalNumberOfRows) {
            this.loadMoreStatus = 'Loading';
            const currentRecord = this.data;
            const lastRecId = currentRecord[currentRecord.length - 1].Id;
            initRecords({ objectName: this.objectApiName, fieldNamesStr: this.fieldNamesStr, recordId: lastRecId , orderby: 'Id', OrderDir: 'ASC',inlineEdit:this.inlineEdit , enableColAction:this.colAction,lookupmap:this.lookupmap,rowactionmap:this.rowactionmap,whereclause:this.whereclause,columnactionmap:this.columnactionmap,initialWidth:this.initialwidth,noofrecordstoload:this.noofrecordstoload})
            .then(result => {
                let rows = JSON.parse(JSON.stringify(result.sobList)); 
               console.log('rows.length..'+rows.length);
         for(let i =rows.length-1; i >=0; i--) {
             let dataParse = rows[i]; 
             let tempd;
             for (let key1 in this.lookupmap) {
                 let fieldname=key1.split(".")[0];
                 let val=this.lookupmap[key1];
                 val=val.replace(" ","").toLowerCase()
                  if(dataParse[fieldname]!==null && dataParse[fieldname]!==undefined){
                      
                     tempd=dataParse[fieldname];
                    
                     if(tempd!==null && tempd!==undefined){
                         dataParse[val] = tempd[key1.split(".")[1]]; 
                         if(this.isportaluser===false)
                            dataParse[val+'Link'] = '/'+tempd['Id']; 
                         else
                            dataParse[val+'Link'] = '/ICPP/'+tempd['Id']; 
                     
                     }
                  }
             } 
     
             if(this.isportaluser===false)
                 dataParse.nameLink='/'+dataParse.Id;
             else
                dataParse.nameLink='/ICPP/'+dataParse.Id;  
     }

     this.data = currentRecord.concat(rows);

                if (this.data.length >= this.totalNumberOfRows) {
                    this.loadMoreStatus = 'No more data to load';
                } else {
                    this.loadMoreStatus = '';
                }
            })
            .catch(error => {
              
                    this.ShowTostMessage('Error',error.body.message,'error');
                
                console.log('-------error-------------'+error);
                console.log(error);
            });
        }
        }
//handle row action(if enabled) event 
        handleRowAction(event) {
            event.preventDefault(); 
            const actionName = event.detail.action.name;
            const row = event.detail.row;

            console.log('actionName..'+actionName);
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
               // this.viewRecord(row);
                break;
            }
              console.log('dispatching event');
           const eEvent = new CustomEvent('actionevent', {
                detail:{action:actionName,
                    rowId:row.Id

                }
            });
           this.dispatchEvent(eEvent);          
        }
    
		//currently we are doing client side delete, we can call apex tp delete server side
        deleteRecord(row) {
            const { id } = row;
            const index = this.findRowIndexById(id);
            if (index !== -1) {
                this.data = this.data
                    .slice(0, index)
                    .concat(this.data.slice(index + 1));
            }
        }
    
        findRowIndexById(id) {
            let ret = -1;
            this.data.some((row, index) => {
                if (row.id === id) {
                    ret = index;
                    return true;
                }
                return false;
            });
            return ret;
        }
    

        editRecord(row) {
            console.log('rowid..'+row.Id);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'edit',
                },
            });
        }
        
        viewRecord(row) {
            console.log('here..viewRecord');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'view',
                },
            });
        }

		//When save method get called from inlineEdit
        handleSave(event) {

            let draftValuesStr = JSON.stringify(event.detail.draftValues);
            updateRecords({ sobList: this.data, updateObjStr: draftValuesStr, objectName: this.objectApiName })
            .then(result => {
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated',
                        variant: 'success'
                    })
                );
                // Clear all draft values
                this.draftValues = [];
                return refreshApex(this.wiredsObjectData);
            })
            .catch(error => {
                
                    this.ShowTostMessage('Error',error.body.message,'error');
                
                console.log('-------error-------------'+error);
                console.log(error);
            });

        }

        // The method will be called on sort click
        updateColumnSorting(event) {
            let fieldName = event.detail.fieldName;
            let sortDirection = event.detail.sortDirection;    
            this.sortData(fieldName,sortDirection);
       }


       @api 
       forceRefreshtable() {
           console.log('in ref table');
        refreshApex(this.wiredsObjectData);
    }

    sortData(fieldName, sortDirection){
        console.log('sorting')
        let datatemp = this.data;
        //function to return the value stored in the field
        let key =(a) => a[fieldName]; 
        let reverse = sortDirection === 'asc' ? 1: -1;
        datatemp.sort((a,b) => {
            let valueA = key(a) ? key(a).toLowerCase() : '';
            let valueB = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((valueA > valueB) - (valueB > valueA));
        });

        //set sorted data to opportunities attribute
        this.data = datatemp;
    }

    //to display the toast message
    ShowTostMessage(vartitle,varmessage,varvariant){
        const evt = new ShowToastEvent({
            title: vartitle,
            message: varmessage,
            variant: varvariant,
        });
        this.dispatchEvent(evt);

    }

       
}
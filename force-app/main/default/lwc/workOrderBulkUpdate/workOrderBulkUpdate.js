import { LightningElement,wire,track,api } from 'lwc';
import getRelatedWorkOrders from '@salesforce/apex/WorkOrderBulkUpdateController.getRelatedWorkOrders';
import { NavigationMixin} from 'lightning/navigation';


export default class workOrderBulkUpdate extends NavigationMixin(LightningElement) {
    @api recordId;
    @api selectedData = [];
    @track data;
    @track openQuickAction;
    @track accountName;
    @track ownerName;
    @track fieldSupportName;
    @track woList = [];  
    @track FieldSupport_Name;
    @track isModalOpen = false;
    @track sortBy;
    @track sortDirection;
    @track getSelected;
    @track selectedrecordIds;
    @track selectedIds = []; 
    @track hasRendered = true;
    @track columns =[
        { label: 'WorkOrder Number', fieldName: 'woUrl', type:'url', 
          typeAttributes: {label: {fieldName: 'woName'}},
          tooltip: {fieldName : 'woName'},
          target : '_self', sortable: "true"},
        { label: 'Order Type', fieldName: 'orderType', type: 'text',sortable: "true" },
        { label: 'Account Name', fieldName: "accountName" , type: 'text',sortable: "true" },
        { label: 'Subject', fieldName: 'subject', type: 'text',sortable: "true" },
        { label: 'Order Status', fieldName: 'orderStatus', type: 'text',sortable: "true" },
        { label: 'Field Support', fieldName: "fieldSupportName", type: 'text',sortable: "true" },
        { label: 'Owner Name', fieldName: "ownerName" , type: 'text',sortable: "true"}
        ];

    //refresh datatable
    renderedCallback(){
        if(this.hasRendered){
        //Call Apex controller
        getRelatedWorkOrders({recordID: this.recordId })
        .then(data=>{

            if (data) {  
                let tempWoList = [];  
                for (let i = 0; i < data.length; i++) {
                    let tempRecord = Object.assign({}, data[i]); //cloning object 
                    console.log('***********temp'+tempRecord);
                    tempRecord.woUrl = '/'+tempRecord.woId;
                    tempRecord.fieldSupportName = tempRecord.fieldSupportName;
                    tempRecord.accountName = tempRecord.accountName;
                    tempRecord.orderType = tempRecord.orderType;
                    tempRecord.orderStatus = tempRecord.orderStatus;
                    tempRecord.subject = tempRecord.subject;
                    tempRecord.ownerName = tempRecord.ownerName;
                    tempWoList.push(tempRecord); 
                }  
                this.woList = tempWoList;  
                this.error = undefined;                    
               }   
            
            this.hasRendered = false;
        }).catch(error=>{console.log('Error'+error.body.message)});
    }
}
            //Pass Selected Record's and all field values
            getSelected() {
                debugger;
                console.log("getselectedrows:"+ this.template.querySelector('lightning-datatable').getSelectedRows());
            }
           // Open dialogue box
            openModal() {
                // to open modal set isModalOpen tarck value as true
                debugger;
                this.selectedrecordIds = this.template.querySelector('lightning-datatable').getSelectedRows();
                if(this.selectedrecordIds.length!=0){
                    this.openQuickAction = true;
                    this.isModalOpen = true; 
                }
                    else{
                    alert("Please select work orders before transfer");
                }            
            }
            // Close Dialogue box
            closeModal(event) {
                // to close modal set isModalOpen tarck value as false
                this.selectedIds = [];
                this.isModalOpen = false;
                this.openQuickAction = false;
                this.hasRendered = true;
            }
        

    //Sort function
    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.woList));

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
        this.woList = parseData;

    }
        
}
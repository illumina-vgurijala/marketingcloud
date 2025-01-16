import { LightningElement,track, api,wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import { RefreshEvent } from "lightning/refresh";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssociatedProductsListByCaseId from '@salesforce/apex/ManageAssociatedProductsController.getAssociatedProductsListByCaseId';
import getAssociatedProductsListByCaseIdImp from '@salesforce/apex/ManageAssociatedProductsController.getAssociatedProductsListByCaseIdImp'; //CMCM-5309 FR change 7th March 2024
import findProducts from '@salesforce/apex/ManageAssociatedProductsController.mainMethod';
import findProductsImp from '@salesforce/apex/ManageAssociatedProductsController.findProductsImp'; //CMCM-5309 FR change 7th March 2024
import createAssociatdInstalledProducts from '@salesforce/apex/ManageAssociatedProductsController.createAssociatdInstalledProducts';
import createPrimaryAssociatdInstalledProducts from '@salesforce/apex/ManageAssociatedProductsController.createPrimaryAssociatdInstalledProducts'; // CMCM 8090 by Dhairya Shah
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
//import valiErrorMsg from '@salesforce/label/c.CMCM5390_AC3_ErrorMsg'; //CMCM-5309 FR change 6th March 2024


const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Product Name', fieldName: 'productName' },
    { label: 'Product Code', fieldName: 'productCode' },
    //{label: 'Type', fieldName: 'type'}
    {label: 'Active Contract', fieldName: 'activeContract'} // addded by dhairya shah for CMCM - 7944
];

const DELAY = 350;
export default class ManageAssociatedProductsController extends LightningElement {
    error;
    searchKey='';
    casewoidvalue;
    wocaseidvalue;
    values=[];
    
    columns = columns;
    @api recordId;
    paramObjectList=[];
    //CMCM-5309 START
    selectedData = [];
    isLoading = false;
    isPreviousDisable=false;
    isNextDisable=false;
    disableAddasPrimary = false;// added by Dhairya Shah for CMCM - 8090
    recId ='';
    items = []; //contains all the records.
    @track data = []; //data  displayed in the table
    page = 1;
    @track apRecords =[];
    startingRecord = 1; //start record position per page
    endingRecord = 0; //end record position per page
    pageSize = 10; //default value we are assigning
    totalRecountCount = 0; //total record count received from all retrieved records
    totalPage = 0; //total number of page is needed to display all records
    //CMCM-5309 END
    disableAdd = true; // addded by dhairya shah for disable the add button if 0 record is selected for CMCM - 7944
    recordsCount = ''; // addded by dhairya shah for disable the add button if 0 record is selected for CMCM - 7944
    countnum = 0; // added by Dhairya Shah for CMCM 8090

    connectedCallback(){
        this.searchKey = 'default';
        this.values = 'option4';
        // condition added by Dhairya Shah for CMCM - 8090
        if(this.recordsCount == 0){
            this.disableAddasPrimary = true;
        }
    }
    @wire(getAssociatedProductsListByCaseId, {recordId: '$recordId'})
    existingAPRecords({ error, data }) { //CMCM-5309 FR change 6th March 2024
        if(data){
            this.apRecords = data;
            this.recId=this.recordId;
        }
    }

    //try to use static record id and check
    @wire(findProducts, {recordId: '$recId',searchKey: '$searchKey', options:'$values'}) 
    products({ error, data }) {  //CMCM-5309 Start to get the products based on search
        this.isLoading = true;
        this.items=[];
        if (data) {  
            this.page =1; //CMCM-5309  FR change 13th March 2024
            this.items = this.removeDuplicateData(data);
            this.isPreviousDisable =true;
            this.totalRecountCount = this.items.length;
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
            //here we slice the data according page size
            this.data = this.items.slice(0, this.pageSize);
            this.endingRecord = this.pageSize;
            if(this.totalPage===0 || this.totalPage===this.page){
                this.isNextDisable = true;
            }else{
                this.isNextDisable = false;
            }
            this.error = undefined;
        } else if (error) {
            if(this.recId!==''){//CMCM-5309 FR change 11th March added error message
                this.error = error;
                this.data = undefined;
            }
        }
        this.isLoading= false;
    }
    removeDuplicateData(itemRecs){
        let item =[];
        itemRecs.forEach((rec) => {
            let isPresent =false; 
            this.apRecords.forEach(res=>{
                if(res.Subscription__c!==null && res.Subscription__c!==undefined && rec.id === res.Subscription__c){
                    isPresent = true;
                }
                if((res.Installed_Product__c!== null && res.Installed_Product__c!==undefined && res.Installed_Product__c!=='undefined' ) &&
                (rec.id === res.Installed_Product__c || rec.name ===res.Installed_Product__r.Name)){ //CMCM-5309 FR change 6th March 2024
                    isPresent = true;
                }
            })
            if(!isPresent){
                item.push(rec);
            }
        });
        return item;
    }
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }

    //press on next button this method will be called
    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);
        }
    }
    //this method displays records page by page
    displayRecordPerPage(page) {
        if(this.page===1){
            this.isPreviousDisable =true;
        }else{
            this.isPreviousDisable =false;
        }
        if(this.totalPage!==this.page){
            this.isNextDisable = false;
        }else{
            this.isNextDisable = true;
        }
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;

        this.data = this.items.slice(this.startingRecord, this.endingRecord);

        //increment by 1 to display the startingRecord count, 
        //so for 2nd page, it will show "Displaying 6 to 10 of 23 records. Page 2 of 5"
        this.startingRecord = this.startingRecord + 1;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedData;
    }
    //CMCM-5309 END

    
    async handleChange(event) {
        this.searchKey = event.detail.searchKey;
        this.values = event.detail.values;
        this.countnum++;
        //refreshApex(this.products); //CMCM-5309  FR change 13th March 2024
        await this.refreshData();//CMCM-5309  FR change 13th March 2024
    }
 
    
    getSelectedRecords(event){
        refreshApex(this.existingAPRecords.data);  
        //Changes Started i.e. Related to CMCM-5309 added pagination and visible added records in every page
        try{
            let updatedItemsSet = new Set();
            // List of selected items we maintain.
            let selectedItemsSet = new Set(this.selectedData);
            // List of items currently loaded for the current view.
            let loadedItemsSet = new Set();
            
            this.data.forEach(ele => {
                loadedItemsSet.add(ele.id);
            });
            if (event.detail.selectedRows) {
                event.detail.selectedRows.forEach(ele => {
                    updatedItemsSet.add(ele.id);
                });
                // Add any new items to the selectedRows list
                selectedItemsSet = this.assignSelectedItemSet(updatedItemsSet,selectedItemsSet);
                
            }
            loadedItemsSet.forEach((id) => {
               if (selectedItemsSet.has(id) && !updatedItemsSet.has(id) && this.countnum === 0) {
                    // Remove any items that were unselected.
                    selectedItemsSet.delete(id);
                }
            });

            this.selectedData = [...selectedItemsSet];
            let selectedRows = this.selectedData;
            this.recordsCount = this.selectedData.length; // Total selected records count
            //added if else condition for disable the Add as Primary button if record count is greater than 1 by Dhairya Shah for CMCM 8090
            if(this.recordsCount > 1){
                this.disableAddasPrimary = true;
            }else if(this.recordsCount === 0){
                this.disableAddasPrimary = true;
            }
            else{
                this.disableAddasPrimary = false;
            }
            //added if else condition for disable the add button if no record is selected by Dhairya shah for CMCM 7944
            if(this.recordsCount > 0){
                this.disableAdd = false;
            }else{
                this.disableAdd = true;
            }
            this.assignParamObjectList(selectedRows);
            if(Object.keys(selectedRows).length === 0 ){
                this.paramObjectList = [];
            }
            this.countnum = 0;
        }catch(e){
            this.sendErrorMesg(e.body.message);
        }
        
    }
    assignParamObjectList(selectedRows){
        for (let i = 0; i < selectedRows.length; i++) {
            if(this.recordId.startsWith('a2B') ){
                    this.parameterObject = {
                    id: selectedRows[i],
                    workOrderId: this.recordId,
                    caseId: this.wocaseidvalue
                    
                };
            }
            else{
                this.parameterObject = {
                id: selectedRows[i],
                caseId: this.recordId,
                workOrderId: this.casewoidvalue
                };
            }
            const duplicaterecord = (this.paramObjectList.some(x=>{return x.id === selectedRows[i]}));
            let deselectedRecs = this.paramObjectList.filter(y => !selectedRows.includes(y[i]));
            if(!duplicaterecord || Object.keys(deselectedRecs).length === 0 ){  
                this.paramObjectList.push(this.parameterObject);    
            }
            else if(Object.keys(deselectedRecs).length> 0 ){
                    this.paramObjectList.splice(deselectedRecs);
                    this.paramObjectList.push(this.parameterObject);
                }  
        }
    }
    assignSelectedItemSet(updatedItemsSet,selectedItemsSet){
        updatedItemsSet.forEach((id) => {
            if (!selectedItemsSet.has(id)) {
                //CMCM-5309 FR change 6th March 2024
                selectedItemsSet.add(id);
                /*let isPresentVal = false;
                isPresentVal = this.checkIsPresentValue(id);
                
                if(!isPresentVal){
                    selectedItemsSet.add(id);
                }*/
            }
        });
        return selectedItemsSet;
    }
    //CMCM-5309 FR change 6th March 2024
   /* checkIsPresentValue(id){
        let isValPres = false;
        this.apRecords.forEach(rec=>{
            if(id.substring(0, 3)==='a20'){
                if(rec.Subscription__c!==null){
                    if(id === rec.Subscription__c){
                        isValPres = true;
                        this.sendErrorMesg(valiErrorMsg);
                    }
                }
            }else{
                if(id === rec.Installed_Product__c){
                    isValPres = true;
                    this.sendErrorMesg(valiErrorMsg);
                }
            }
        });
        return isValPres;
    }*/
    sendErrorMesg(err){
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Error",
                message: err,
                variant: "error",
            }),
        )
    }
   //Changes End i.e. Related to CMCM-5309

    @wire(getRecord, { recordId: '$recordId', fields: ['Case.Work_Order__c'] })
    getRecordHandler({ data, error }) {
        if (data) {
            if(this.recordId.startsWith('500')){
                this.casewoid = data.fields.Work_Order__c.value;
                this.casewoidquote = JSON.stringify(this.casewoid);
                if(this.casewoidquote === 'null'){
                this.casewoidvalue = this.casewoidquote;     
                }
                else{
                this.casewoidvalue = this.casewoidquote.slice(1,-1);
                }
            }    
            }
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['SVMXC__Service_Order__c.SVMXC__Case__c'] })
    getRecordHandlerWorkOrder({ data, error }) {
        if (data) {
            if(this.recordId.startsWith('a2B')){
                
                this.wocaseid = data.fields.SVMXC__Case__c.value;
                this.wocaseidquote = JSON.stringify(this.wocaseid);
                if(this.wocaseidquote === 'null'){
                this.wocaseidvalue = this.wocaseidquote;       
                }
                else{
                this.wocaseidvalue = this.wocaseidquote.slice(1,-1);
                }
                }   
            }
    }
    
    /*Changes made in handleSelect method, i.e. related to CMCM-5309 
    @description after click on select remove the selected records and assign Null for the parameters
    */
    async handleSelect() {
        this.isLoading = true;
        if (this.paramObjectList.length > 0){    
            await createAssociatdInstalledProducts({wrapperString:this.paramObjectList})
            .then(result => {
                this.template.querySelector('[data-id="datatable"]').selectedRows = [];
                this.paramObjectList=[];
                this.selectedData =[];
            }) .catch(error => {
                let errormessage='';
                this.error = error;
                if(this.error.body.pageErrors.length>0){
                    let errormessagequote = JSON.stringify(this.error.body.pageErrors[0].message);
                    errormessage = errormessagequote.slice(1,-1);
                }else{
                    errormessage=this.getErrorMessageForFieldError(this.error.body.fieldErrors);
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errormessage,
                        variant: 'error',
                    }),
                );
                this.template.querySelector('[data-id="datatable"]').selectedRows = [];
                this.paramObjectList=[];
                this.selectedData =[];
            }); 
            await this.refreshData(); //CMCM-5309 FR change 7th March 2024  
            this.dispatchEvent(new RefreshEvent());
            this.template.querySelector('[data-id="datatable"]').selectedRows = [];
            this.paramObjectList=[];
            this.selectedData=[];
            await this.template.querySelector('c-associated-products-component').refreshChild();
            this.isLoading= false;
            this.disableAdd = true; // addded by dhairya shah for disable the add button if 0 record is selected for CMCM - 7944
        }
    }
    //CMCM-5309 FR change 7th March 2024 refreshing the data after creating or deletation of AP recs ==>  START
    refreshData(event){
        this.refreshData();
    }
    //story  CMCMC-7268 and Bug is CMCM-7804  this method will return  error message 
    getErrorMessageForFieldError(fieldErrors){
        let errormessage = '';
            for (const key in fieldErrors) {
                if (Object.prototype.hasOwnProperty.call(fieldErrors, key)) {
                    const arr = fieldErrors[key];
                    for (const error of arr) {
                       if (error && error.message) {
                            errormessage += error.message;
                        }
                    }
                }
            }
    return errormessage;       
    }
    async refreshData(){
        await getAssociatedProductsListByCaseIdImp({recordId: this.recordId})
        .then(result=>{
            this.apRecords =[];
            this.apRecords = result;
            this.recId=this.recordId;
        });

        await findProductsImp({recordId: this.recId,searchKey: this.searchKey, options:this.values})
        .then(result=>{
            this.page =1;  //CMCM-5309  FR change 13th March 2024
            this.items=[]; 
            this.data=[];
            this.items = this.removeDuplicateData(result);
            this.isPreviousDisable =true;
            this.totalRecountCount = this.items.length;
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
            //here we slice the data according page size
            this.data = this.items.slice(0, this.pageSize);
            this.error = undefined;
        }).catch(error=>{
            this.error = error;
            this.data = undefined;
        });
         //CMCM-5309  FR change 13th March 2024
        this.endingRecord = this.pageSize;
        if(this.totalPage===0 || this.totalPage===this.page){
            this.isNextDisable = true;
        }else{
            this.isNextDisable = false;
        }
        this.displayRecordPerPage(this.page);// added by Dhairya Shah for CMCM 8090
    }
    //CMCM-5309  FR change 7th March 2024  ==> END
    
    //Added below function for CMCM 8090 by Dhairya Shah
    async handleSelectAddasPrimary() {
        this.isLoading = true;
        await createPrimaryAssociatdInstalledProducts({wrapperString:this.paramObjectList,recordId: this.recordId})
            .then(result => {
                this.template.querySelector('[data-id="datatable"]').selectedRows = [];
                this.paramObjectList=[];
                this.selectedData =[];
            }) .catch(error => {
                let errormessage='';
                this.error = error;
                if(this.error.body.pageErrors.length>0){
                    let errormessagequote = JSON.stringify(this.error.body.pageErrors[0].message);
                    errormessage = errormessagequote.slice(1,-1);
                }else{
                    errormessage=this.getErrorMessageForFieldError(this.error.body.fieldErrors);
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errormessage,
                        variant: 'error',
                    }),
                );
                this.template.querySelector('[data-id="datatable"]').selectedRows = [];
                this.paramObjectList=[];
                this.selectedData =[];
            }); 
            await this.refreshData();
            this.dispatchEvent(new RefreshEvent());
            this.template.querySelector('[data-id="datatable"]').selectedRows = [];
            this.paramObjectList=[];
            this.selectedData=[];
            await this.template.querySelector('c-associated-products-component').refreshChild();
            this.isLoading= false;
            this.disableAdd = true; 
            this.disableAddasPrimary = true; 
    }
}
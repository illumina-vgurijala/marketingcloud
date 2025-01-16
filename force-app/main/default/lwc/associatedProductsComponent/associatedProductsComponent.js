import { LightningElement, api,wire, track} from 'lwc';
import { deleteRecord } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningAlert from 'lightning/alert';
import {  IsConsoleNavigation, getFocusedTabInfo, openSubtab, refreshTab} from 'lightning/platformWorkspaceApi'; //8563 bug Added refreshTab method
import getAssociatedProductsList from '@salesforce/apex/ManageAssociatedProductsController.getAssociatedProductsList';
import updategetAssociatedProductsList from '@salesforce/apex/ManageAssociatedProductsController.updategetAssociatedProductsList';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe} from 'lightning/empApi'; //CMCM-9248
//delete apex method removed as it will be handled in trigger.

const actions = [
    { label: 'Delete', name: 'delete' }
];

const columns = [ 
    { 
    label: 'Associated Product', fieldName: 'apName', type:'url', 
          typeAttributes: {label: {fieldName: 'name'}},
          tooltip: {fieldName : 'name'},
          target : '_self', sortable: "true" },
    { label: 'Is Primary', fieldName: 'isPrimary',editable : false ,type: 'boolean'},
    {
        label: 'Installed Product',
        fieldName: 'ipLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'installedProductName' }, target: '_self' },
        editable : false,
    },
    
    {
        label: 'Product',
        fieldName: 'pLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'productName' }, target: '_self' },
        editable : false,
    },
    {
        label: 'Subscription',
        fieldName: 'subLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'subscription' }, target: '_self' },
        editable : false,
    },
    { label: 'Product Serial Number', fieldName: 'serialNumber',editable : false,type: 'text'},
    { label: 'Product Lot Number', fieldName: 'lotNumber',type: 'text',editable : false },
    { label: 'Expiry Date', fieldName: 'expiredDate',editable : false, type: 'date', typeAttributes: { year:'numeric', month:'short', day:'2-digit', timeZone:'UTC'} },
    { label: 'Is Expired?', fieldName: 'isExpired',editable : false,type: 'boolean'},
    { label: 'Software Version', fieldName: 'version',editable : false,type: 'text' },
    { type: 'action', typeAttributes: { rowActions: actions} }
];
const DELAY = 350;
export default class ManageAssociatedProductsController extends NavigationMixin(LightningElement) {
    constMessage = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
    error;
    products;
    columns = columns;
    @api recordId;
    isLoading=false;
    primaryCheckPass = true;
    @track data = [];
    @track contactData;
    draftValues = [];
    showProduct = true;
    showProduct1= false;
    @track indexedData;
    recdata = [];
    updateDataRec = [];
    @track refrecordId;
    urlLink='';
    @wire(getAssociatedProductsList, {recordId:'$recordId'})
    
    products;
    
    
    @wire(getAssociatedProductsList,{ recordId: '$recordId'} ) 
    getProdList(result) {  
        if (result.data) {   
            this.recdata = JSON.parse(JSON.stringify(result.data));
            const url = window.location.origin;
            this.urlLink=url;
            let tempProdList = [];  
            for (let i = 0; i < result.data.length; i++) {  
             let tempRecord = Object.assign({}, result.data[i]); //cloning object 
             if(tempRecord.installedProduct!==undefined && tempRecord.installedProduct!==null){
                  tempRecord.ipLink = this.ipLinkMethod(url,tempRecord.installedProduct);
             }
             if(tempRecord.productId!==undefined && tempRecord.productId!==null){
                  tempRecord.pLink =this.pLinkMethod(url,tempRecord.productId);
             }
             if(tempRecord.subscriptionId!==undefined && tempRecord.subscriptionId!==null){
                  tempRecord.subLink = this.subLinkMethod(url,tempRecord.subscriptionId);
             }
             tempRecord.apName = this.subLinkMethod(url,tempRecord.id);    
             tempProdList.push(tempRecord); 
            }  
            this.data = tempProdList;            
            this.error = undefined; 

            this.indexedData = this.data.map((item, index) => {
                return {
                    ...item,
                    index: index + 1 // Increment index by 1
                    };
                });
            } 
        }    
      
          ipLinkMethod(url,ip){
              let res='';
              if(url.includes('site') ){
                  res = '/ICPP/s/installed-product/' + ip;
              }
              else{
                  res = '/' + ip;
              }
              
              return res;
          }
      
          pLinkMethod(url,pd){
              let res='';
              if(url.includes('site') ){
                  res = '/ICPP/s/product/' + pd;
              }
              else{
                  res = '/' + pd;
              }
              return res;
          }
      
          subLinkMethod(url,sub){
            let res='';
            if(url.includes('site') ){
                res = '/ICPP/s/detail/' + sub;
            }else{
                res = '/' + sub;
            }
            return res;
          }

    @api
    refreshChild(){
        refreshApex(this.products);
        refreshApex(this.indexedData);
    }
   
    async handleRowAction(event) {
        this.isLoading =true;
        const actionName = event.detail.action.name;
        const id = event.detail.row.id;
        const isPrimary = event.detail.row.isPrimary;
        switch (actionName) {          
            case 'delete':
                this.isLoading=true;
                await deleteRecord(id)
                .then(() => {
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Record deleted",
                        variant: "success",
                    }),
                    )  
                    this.isLoading=false;
                    refreshApex(this.products); 
                    this.refreshTab(); //8563 Called refreshTab method
                    this.dispatchEvent(new CustomEvent('refreshdatafromchild',{detail:'none'}));//CMCM-5309 FR change 7th March 2024  
                }).catch(error => {
                    if(error.body.message.includes(this.constMessage)) {
                        this.errorMessage = error.body.message.substring(82+(this.constMessage).length);
                        this.errorMessageFinal = this.errorMessage.substring(0,this.errorMessage.length-6);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error updating record',
                                message: this.errorMessageFinal,
                                variant: 'error',
                            }),
                        );
                    } else {
                        const event = new ShowToastEvent({
                            title : 'Error',
                            message : error.body.output.errors[0].message,
                            variant : 'error'
                        });
                        this.dispatchEvent(event);
                    }
                    this.isLoading=false;
                    refreshApex(this.products);
                });
                this.isLoading=false;
                break;
        }
        
    }

    //cmcm-3591
    checkPrimaryLengthFunc(primaryCount){
        if(primaryCount > 1){
            LightningAlert.open({
                message: 'You can only select one record as primary',
                theme: 'error', // a red theme intended for error states
                label: 'Error!', // this is the header text
            });
            this.primaryCheckPass = false;
        } else {
            this.primaryCheckPass = true;
        }
        return this.primaryCheckPass;
    }
 
    handleCancel(event) {
        this.data = JSON.parse(JSON.stringify(this.data));
        this.showProduct = true;
        this.showProduct1= false;
        this.draftValues = [];
    }
 
    // This function is used to refresh the table once data updated
    async refresh() {
        await refreshApex(this.products);
    }

    // Method to update primary value
    getprimary(event){
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        const primaryval = event.target.checked;
        this.updateValueForDataRec(apId,primaryval,'Is_Primary__c');
    }
    getSerialNumber(event){
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        let serialnum =event.target.value;
        this.updateValueForDataRec(apId,serialnum,'Product_Serial_Number__c');
        
    }
    getLotNumber(event){
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        let lotNum =event.target.value;
        this.updateValueForDataRec(apId,lotNum,'Product_Lot_Number__c');
    }

    getExpiryDate(event){
        let expiryDate1 = event.target.value;
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        this.updateValueForDataRec(apId,expiryDate1,'Expired_Date__c');
    }
    getIsExpired(event){
        let isExpired = event.target.checked;
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        this.updateValueForDataRec(apId,isExpired,'Is_Expired__c');
        
    }
    getVersion(event){
        let version = event.target.value;
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        this.updateValueForDataRec(apId,version,'Software_Version__c');
    }
    getproduct(event){
        let pro = event.target.value;
        const apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);
        this.updateValueForDataRec(apId,pro,'Product__c');
    }
    updateValueForDataRec(apId,fieldVal,fieldName){
        let newapId = apId;
        if(this.urlLink.includes('site') ){
            newapId = apId.substring(apId.length-18,apId.length);
        }
        if(this.updateDataRec.length ===0){
            this.updateDataRec.push({Id :newapId});
            this.updateDataRec[0][fieldName] = fieldVal;
        }else{
            let i =0;
            let needUpdt = true;
            this.updateDataRec.forEach(frst =>{
                if(frst.Id===newapId){
                    if(this.updateDataRec[i].fieldName!==undefined){
                        this.updateDataRec[i].fieldName= fieldVal;
                        needUpdt = false;
                    }else{
                        this.updateDataRec[i][fieldName]= fieldVal;
                        needUpdt = false;
                    }
                    
                }
                i++;
            });
            if(needUpdt){
                this.updateDataRec.push({Id :newapId});
                this.updateDataRec[this.updateDataRec.length-1][fieldName] = fieldVal;
            }
        }

    }

    handleedit(){
        this.draftValues =[1];
        this.showProduct1= true;
        this.showProduct= false;
    }
    handleSuccess(event) {
        this.refrecordId = event.detail.id; 
    }
    async handleSaveNew(event){
        const filteredData = this.updateDataRec.filter(item => item.Is_Primary__c === true);
        if(filteredData.length > 1){
            this.checkPrimaryLengthFunc(filteredData.length);// here I used the checkPrimaryLengthFunc from line 335
            this.showProduct1= false;
            this.showProduct= true;
            this.draftValues=[];
            this.updateDataRec =[];
        }
        else{
            this.elseConditionFunction(filteredData);
        }
    }
    async elseConditionFunction(filteredData){
            this.recdata.forEach(rec=>{
                //CMCM -6878 - changes on 5th april (added condition filteredData.length >0)
                if(rec.isPrimary!== undefined && rec.isPrimary ===true && filteredData.length >0){
                    let fnd = false;
                    let i =0;
                    this.updateDataRec.forEach(updRec=>{
                        if(updRec.Id === rec.id ){
                            this.updateDataRec[i]['is_Primary__c']=false;
                            fnd=true;
                        }
                        i++;
                    })
                    if(!fnd){
                        this.updateDataRec.push({Id :rec.id,is_Primary__c:false});
                    }
                }
            })
            await this.handleSaveApexNew();
        this.isLoading=false;
        this.showProduct1= false; //CMCM -6878 - changes on 5th april 
        this.showProduct= true; //CMCM -6878 - changes on 5th april 
        this.draftValues =[];
        this.updateDataRec =[]; //CMCM -6878 - changes on 5th april 
        refreshApex(this.products);
    }
    async handleSaveApexNew(){
        //CMCM -6878 - changes on 5th april - Added below if condition 
        if(this.updateDataRec !== null && this.updateDataRec !== undefined && this.updateDataRec.length > 0){
            let updateData = JSON.stringify(this.updateDataRec);
            
            try {
                this.isLoading = true;
                await this.newhandleSaveApexNew1(updateData);
                this.isLoading=false;    
            } catch (err) {
                this.isLoading=false;
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error updating or reloading products',
                    message: 'Error updating or reloading products',
                    variant: 'error',
                    }),
                );
                this.showProduct1= false;
                this.showProduct= true;
                this.draftValues =[];
                this.updateDataRec = [];
                refreshApex(this.products);
        }
        }else{ //CMCM -6878 - changes on 5th april  Added else part 
            this.showProduct1= false;
            this.showProduct= true;
            this.draftValues =[];
            this.updateDataRec = [];
            refreshApex(this.products); 
        }
          
    }

    async newhandleSaveApexNew1(updateData){
        await updategetAssociatedProductsList({data:updateData})
                .then(result=>{
                    this.isLoading = false;
                    const event = new ShowToastEvent({
                        title: 'Associated Products Updated.',
                        message: 'Associated Products Updated.', //records update message change
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                    // Display fresh data in the datatable
                    refreshApex(this.products);
                    this.draftValues = [];
                    this.showProduct1= false; //CMCM -6878 - changes on 5th april 
                    this.showProduct= true; //CMCM -6878 - changes on 5th april 
                    this.updateDataRec =[]; //CMCM -6878 - changes on 5th april 
                }).catch(error => {
                    if(error.body.message.includes(this.constMessage)) {
                        this.errorMessage = error.body.message.substring(82+(this.constMessage).length);
                        /*if(this.errorMessage.includes('Product_Serial_Number__c')){
                            this.errorMessageFinal = this.errorMessage.substring(0,this.errorMessage.length-28);//CMCM -6878 - changes on 10th april
                        }*/
                        if (this.errorMessage.includes('The Installed Product') && this.errorMessage.includes('the Associated Product.')) {
                            const startIndex = this.errorMessage.indexOf('The Installed Product');
                            const endIndex = this.errorMessage.indexOf('the Associated Product.') + 'the Associated Product.'.length;
                            this.errorMessageFinal = this.errorMessage.substring(startIndex, endIndex).trim();
                        }else if(this.errorMessage.includes(': []')){
                            this.errorMessageFinal = this.errorMessage.substring(0,this.errorMessage.length-4);//CMCM -6878 - changes on 10th april
                        }else{
                            this.errorMessageFinal = this.errorMessage.substring(0,this.errorMessage.length);//CMCM -6878 - changes on 10th april
                        }
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error updating record',
                                message: this.errorMessageFinal,
                                variant: 'error',
                            }),
                        );
                    } else {
                        const event = new ShowToastEvent({
                            title : 'Error',
                            message : error.body.message,
                            variant : 'error'
                        });
                        this.dispatchEvent(event);
                    }
                    refreshApex(this.products);
                    this.showProduct1= false;
                    this.showProduct= true;
                    this.draftValues =[];
                    this.updateDataRec = [];
                });
    }

    //FOR HANDLING THE HORIZONTAL SCROLL OF TABLE MANUALLY
    tableOuterDivScrolled(event) {
        this._tableViewInnerDiv = this.template.querySelector(".tableViewInnerDiv");
        if (this._tableViewInnerDiv) {
            if (!this._tableViewInnerDivOffsetWidth || this._tableViewInnerDivOffsetWidth === 0) {
                this._tableViewInnerDivOffsetWidth = this._tableViewInnerDiv.offsetWidth;
            }
            this._tableViewInnerDiv.style = 'width:' + (event.currentTarget.scrollLeft + this._tableViewInnerDivOffsetWidth) + "px;" + this.tableBodyStyle;
        }
        this.tableScrolled(event);
    }
 
    tableScrolled(event) {
        if (this.enableInfiniteScrolling) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('showmorerecords', {
                    bubbles: true
                }));
            }
        }
        if (this.enableBatchLoading) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('shownextbatch', {
                    bubbles: true
                }));
            }
        }
    }
 
    //#region ***************** RESIZABLE COLUMNS *************************************/
    handlemouseup(e) {
        this._tableThColumn = undefined;
        this._tableThInnerDiv = undefined;
        this._pageX = undefined;
        this._tableThWidth = undefined;
    }
 
    handlemousedown(e) {
        if (!this._initWidths) {
            this._initWidths = [];
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            tableThs.forEach(th => {
                this._initWidths.push(th.style.width);
            });
        }
 
        this._tableThColumn = e.target.parentElement;
        this._tableThInnerDiv = e.target.parentElement;
        while (this._tableThColumn.tagName !== "TH") {
            this._tableThColumn = this._tableThColumn.parentNode;
        }
        while (!this._tableThInnerDiv.className.includes("slds-cell-fixed")) {
            this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
        }

        this._pageX = e.pageX;
        this._padding = this.paddingDiff(this._tableThColumn);
        this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
    }
 
    handlemousemove(e) {
        if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
            this._diffX = e.pageX - this._pageX;
 
            this.template.querySelector("table").style.width = (this.template.querySelector("table") - (this._diffX)) + 'px';
 
            this._tableThColumn.style.width = (this._tableThWidth + this._diffX) + 'px';
            this._tableThInnerDiv.style.width = this._tableThColumn.style.width;
 
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            let tableBodyRows = this.template.querySelectorAll("table tbody tr");
            tableBodyRows.forEach(row => {
                let rowTds = row.querySelectorAll(".dv-dynamic-width");
                rowTds.forEach((td, ind) => {
                    rowTds[ind].style.width = tableThs[ind].style.width;
                });
            });
        }
    }
 
    handledblclickresizable() {
        let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
        let tableBodyRows = this.template.querySelectorAll("table tbody tr");
        tableThs.forEach((th, ind) => {
            th.style.width = this._initWidths[ind];
            th.querySelector(".slds-cell-fixed").style.width = this._initWidths[ind];
        });
        tableBodyRows.forEach(row => {
            let rowTds = row.querySelectorAll(".dv-dynamic-width");
            rowTds.forEach((td, ind) => {
                rowTds[ind].style.width = this._initWidths[ind];
            });
        });
    }
 
    paddingDiff(col) {
 
        if (this.getStyleVal(col, 'box-sizing') === 'border-box') {
            return 0;
        }
 
        this._padLeft = this.getStyleVal(col, 'padding-left');
        this._padRight = this.getStyleVal(col, 'padding-right');
        return (parseInt(this._padLeft, 10) + parseInt(this._padRight, 10));
 
    }
 
    getStyleVal(elm, css) {
        return (window.getComputedStyle(elm, null).getPropertyValue(css))
    }
    scrollTbodyHorizontally(scrollAmount) {
        const tableBody = this.template.querySelector('tbody');
        if (tableBody) {
            tableBody.scrollLeft += scrollAmount;
        }
    }

    async handleSubtab(event){
       let apId = event.target.dataset.name.substring(1, event.target.dataset.name.length);

        if(this.urlLink.includes('site') ){
            apId = apId.substring(apId.length-18,apId.length);
                await this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: apId,
                        actionName: 'view'
                    }
                });
        }
        else{
            const tabInfo = await getFocusedTabInfo(this.tabId);
            const primaryTabId = tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId;
            // Open a record as a subtab of the current tab
            await openSubtab(primaryTabId, { recordId: apId, focus: true });
        }
    }
    //8563 bug Added refreshTab method
    @wire(IsConsoleNavigation) isConsoleNavigation;
    async refreshTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await refreshTab(tabId, {
            includeAllSubtabs: true
        });
    }
     // CMCM-9248 changes starts here ==>
    subscription = {};
    @api channelName = '/event/Associated_Product_DML_Event__e';

   connectedCallback() {  
        const self = this;
        const callbackFunction = function (response) {
            self.refresh();
        }
        subscribe(this.channelName, -1, callbackFunction).then(response => {
        });

    }
    // CMCM-9248 changes ends here ==>
}
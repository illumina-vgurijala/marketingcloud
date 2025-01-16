import { LightningElement,track,wire,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import returnResponse from '@salesforce/apex/ProductHierarchyDataSender.getProductsWithTopLevelProductsFromSAP';
//import returnResponse from '@salesforce/apex/ProductHierarchyWhrUsedWrapper.returnSampleJSONResponse';
import getProductID from '@salesforce/apex/TreeGrid.getProductID'
import { NavigationMixin } from 'lightning/navigation';
import getTreeGridData from '@salesforce/apex/TreeGrid.getTreeGridData';
import getCurrentApp from '@salesforce/apex/TreeGrid.getCurrentApp';
import bomUsedIn from '@salesforce/label/c.BOM_Used_In';
import bomLevel from '@salesforce/label/c.BOM_Level';
import bomApplication from '@salesforce/label/c.BOM_Application';
import helpText from '@salesforce/label/c.LimitToSingleLevelHelpText';
import topLevelErrorMessage from '@salesforce/label/c.TopLevelErrorMessage';
import searchErrorMessage from '@salesforce/label/c.SearchErrorMessage';
import sbomErrorMessage from '@salesforce/label/c.SbomErrorMessage';
import sbomIpErrorMessage from '@salesforce/label/c.SbomIpErrorMessage';
import BOMApplicableDateHelpText from '@salesforce/label/c.BOMApplicableDateHelpText';//QACM-78
import BOMStartDateEndDateLimit from '@salesforce/label/c.Error_Message_BOMStartDateEndDateLimit';//QACM-78
import getIpDetails from '@salesforce/apex/ServiceBomController.getIpDetails';
import getWODetails from '@salesforce/apex/ServiceBomController.getWODetails';
import getCaseDetails from '@salesforce/apex/ServiceBomController.getCaseDetails';
import getPODetails from '@salesforce/apex/ServiceBomController.getPODetails';
import  getProDetails from '@salesforce/apex/ServiceBomController.getProDetails';
import getassociatedProduct from '@salesforce/apex/ServiceBomController.getAssociatedProduct'; //CMCM-3200
import UI_Button_Cancel from '@salesforce/label/c.UI_Button_Cancel';
import UI_Button_Save from '@salesforce/label/c.Save';
//import CHANNEL_PARTNER_TYPE from '@salesforce/schema/Case.SVMXC__Company__r.ERP_Customer_Id__c';
//import CHANNEL_PARTNER_TYPE from '@salesforce/schema/Case.SVMXC__Company__r.Name';
//Fields that should be pre populated if the user is on Product record page.
import saveAssociatedProducts from '@salesforce/apex/ServiceBomController.saveAssociatedProducts'; //CMCM-3200


const FIELDS = [
    'Product2.Name',
    'Product2.ProductCode',
    'Product2.Service_Product_Type__c'
];
const ACCOUNTFIELDSONCASE = [
    'Case.Account.ERP_Customer_Id__c',
    'Case.Account.Name'
];
const ACCOUNTFIELDSONWO = [
    'SVMXC__Service_Order__c.SVMXC__Company__r.ERP_Customer_Id__c',
    'SVMXC__Service_Order__c.SVMXC__Company__r.Name'
];
//setting the columns for Products Returned section.
const columnsRP = [
    {label: 'Returned Product Code', fieldName: 'Material',type:'button',
    typeAttributes:{label:{ fieldName: 'Material'},
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disabled'},
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Returned Product Name', fieldName: 'Material_Desc' },
    { label: 'Status', fieldName: 'Status'},
    { label: 'Regulatory Type', fieldName: 'Regulatory_Type' },
   
];
//QACM-78 setting the columns for Returned product section for Case and Workorder.
const columnsRPForCaseandWorkorder = [
    {label: 'Returned Product Code', fieldName: 'Material',type:'button',
    typeAttributes:{label:{ fieldName: 'Material'},
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disabled'},
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Returned Product Name', fieldName: 'Material_Desc' },
    {   type: "button",
        label: 'Product Information',  
        typeAttributes: {  
            label: 'View',  
            name: 'productViewButton',    
            disabled: {fieldName:'productDisable'},  
            value: 'viewButton',  
            iconPosition: 'left',
            variant: 'brand'  
        } 
    },
    { label: 'Status', fieldName: 'Status'},
    { label: 'Regulatory Type', fieldName: 'Regulatory_Type' },
   
];
//setting the columns for Top level products section for Product and Partsorder.
const columns = [
    {label: 'Top Level Product Code', fieldName: 'Material',type:'button',
    typeAttributes:{label:{ fieldName: 'Material'},
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disabled'},
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Top Level Product Name', fieldName: 'Material_Desc' },
    { label: 'Status', fieldName: 'Status'},
    { label: 'Regulatory Type', fieldName: 'Regulatory_Type' },
];
//setting the columns for Parent products section.
const parentColumns = [
    {label: 'Parent Product Code', fieldName: 'Material',type:'button',
    typeAttributes:{label:{ fieldName: 'Material'},
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disabled'},
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Parent Product Name', fieldName: 'Material_Desc' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Regulatory Type', fieldName: 'Regulatory_Type' },
];
//Setting the cloumns to for lot number expiration table
const lotNoAndExpirationcolumns = [
    { label: 'Lot/Batch Number', fieldName: 'Batch' },
    { label: 'Expiration Date', fieldName: 'BatchExpiry' },
  
];
// product component columns for product and parts order
const columnsProductComponentsForProAndPO = [
    {
    type: "text",
    fieldName: "BomLevel",
    label: "BOM Level"
    },
{
   type:'button',
   label: 'Product Code', 
   typeAttributes:{
   label:{ fieldName: 'Material'},
   name: 'View',
   title: 'View',
   variant:{ fieldName: "ButtonHighlight" },
  disabled: { fieldName: 'disable'},
  value: 'View'
   }
}, 
  {
       type: 'text',
       fieldName: 'Material_Desc',
       label: 'Product Name'
   },
   {
       type: 'text',
       fieldName: 'Status',
       label: 'Status'
   },
   {
       type: 'text',
       fieldName: 'System_Blocks',
       label: 'SFDC Blocks'
   },
   {
       type: 'text',
       fieldName: 'Regulatory_Type',
       label: 'Regulatory Type'
   }
];
// product component columns for case and Workorder
const columnsProductComponentsForCaseAndWO = [
    {
    type: "text",
    fieldName: "BomLevel",
    label: "BOM Level"
    },
{
   type:'button',
   label: 'Product Code', 
   typeAttributes:{
   label:{ fieldName: 'Material'},
   name: 'View',
   title: 'View',
   variant:{ fieldName: "ButtonHighlight" },
disabled: { fieldName: 'disable'},
  value: 'View'
   }
}, 
  {
       type: 'text',
       fieldName: 'Material_Desc',
       label: 'Product Name'
   },
   { type: "button",
     label: 'Product information',  
      typeAttributes: {  
         label: 'View',  
         name: 'viewButton',  
         disabled: {fieldName:'batchDisable'},  
         value: 'viewButton',  
         iconPosition: 'left',
         variant: 'brand'  
     } },
   {
       type: 'text',
       fieldName: 'Status',
       label: 'Status'
   },
   {
       type: 'text',
       fieldName: 'System_Blocks',
       label: 'SFDC Blocks'
   },
   {
       type: 'text',
       fieldName: 'Regulatory_Type',
       label: 'Regulatory Type'
   }

];

    export default class bomSearchComponent extends NavigationMixin(LightningElement) {
        //CMCM 264 - added by Nidhi 
        //CMCM-7774 - Code Removed related to feature flag status
    get showComponent() {
       return true;
    }

    get displayaddbutton() {
        // Assuming you have isCaseOrWorkOredr defined elsewhere
        return this.isCaseOrWorkOredr;
    }
        //Feature flag changes end

    //variables
    @api recordId;
    @api objectApiName;
    //Boolean to show/hide Top Level Section
    @track showTopLevel=false;
    //Boolean to Show/Hide returned Products Section
    @track showReturnedProducts=false;
    //TopLeveldata to be displayed in TopLevel section.
    @track topLevelData=[];
    //Returned Products to be displayed in returned products section.
    @track productsReturnedData = [];
    //variable to show the error.
    @track error;
    //assign top level section columns to display in table.
    @track columns = columns;
    // Variable to control the "Add Product(s)" button CMCM 264
    @track isAddButtonDisabled = true; // Initially, the button is disabled
    @track TreeGridTableColumn;
    @track dataForDataTable=[];
    @track selectedRows = [];
    @track currentSelectedRows;  // used to track changes
    @track previousselectedRows;
    @api isSpinner = false; //CMCM-5524
    @track selectedProductRows; //CMCM-5524
     @track LastSelectedIndex; //CMCM-5524
    @track isFirstClick = false; //CMCM-5524
    @track copyDataForDataTable = []; //CMCM-5524


     /**
     * method name: handleSelectionChange
     * description: It enables and disables the add product button and multiselect of hierarchy  CMCM 264 
     */

    async handleSelectionChange(event) {
         console.log('<===handleSelectionChange====>');
    const selectedRows = event.detail.selectedRows;
    this.isAddButtonDisabled = selectedRows.length === 0;

    //this.dataForDataTable = selectedRows;
    const filtersize = selectedRows.filter(item => item !== null && Object.keys(item).length > 0);
    if(filtersize.length === 0) {
        this.previousselectedRows = 0;
        this.dataForDataTable = [];
    }
    if(filtersize.length > 0 && filtersize.length + 1 === this.previousselectedRows) {
        const selItems = [];
        let i = 0;
        for (i; i < filtersize.length; i++) {
            selItems.push(filtersize[i].Material);
        }
        this.selectedRows = selItems;
        this.dataForDataTable = filtersize;
        this.previousselectedRows = filtersize.length;
        return;
    }
    if (selectedRows.length > 0) {
        const selItems = [];
        this.handleMultiSelectCheckBox(this.treeItems, selectedRows, selItems);
        console.log('dataForDataTable:', this.dataForDataTable);

    }
    console.log('filtersize --',filtersize);
    console.log('filtersize length--',filtersize.length);
}

handleMultiSelectCheckBox(treeItems, selectedRows, selItems) {
    let self = this;
    function processItem(item, parentMaterials) {
        const currentMaterials = [...parentMaterials, item.Material];
        if (selectedRows.some(selected => selected.Material === item.Material)) {
            
            selItems.push({
                Material: item.Material,
                Data: item // Store the entire item data
            });

        // Add parent and grandparent data
            parentMaterials.forEach(parent => {
                selItems.push({
                    Material: parent,
                    Data: self.findItemByMaterial(treeItems , parent)
                });
            });
        }

        if (item._children) {
            item._children.forEach(childItem => {
                processItem.call(this, childItem, currentMaterials);
            });
        }
    }

    treeItems.forEach(item => {
        processItem.call(this, item, []);
    });
    const selectedItems = this.removeDuplicatesMaterial(selItems);
    const selMaterial = [];
    let i;
      for (i = 0; i < selectedItems.length; i++) {
        if(selectedItems[i].Material !== null && selectedItems[i].Material !== undefined) {
            selMaterial.push(selectedItems[i].Material);
        }
       if(selectedItems[i].Data !== null && selectedItems[i].Data !== undefined) {    
           this.dataForDataTable.push(selectedItems[i].Data);
        }
    }     
    this.selectedRows = selMaterial;    
    this.previousselectedRows = selMaterial.length;
    this.dataForDataTable = this.removeDuplicates(this.dataForDataTable);
}
findItemByMaterial(items, material) {
            for (const item of items) {
                if (item.Material === material) {
                // Item found, return it
                return item;
                }
            // Recursively search in children if they exist
            if (item._children && item._children.length > 0) {
            const foundInChild = this.findItemByMaterial(item._children, material);
            if (foundInChild) {
                // Item found in child, return it
                return foundInChild;
               }
            }
        }
    return null;
}
removeDuplicatesMaterial(Materials) {
    return Materials.filter((item, index, self) => {
        return index === self.findIndex(obj => obj.Material === item.Material);
    });
}
removeDuplicates(dataForDataTable) {
    //CMCM-5524 changes
    // Reverse the array to prioritize the last occurrences
    const reversedArray = dataForDataTable.slice().reverse();
    // Filter the reversed array
    const filteredReversedArray = reversedArray.filter((item, index, self) => {
        return index === self.findIndex(obj => obj.Material === item.Material && obj.Material_Desc !== null);
    });
    // Reverse it back to maintain the original order
    return filteredReversedArray.reverse();
}

    handleDataTableRowSelection(event) {
     
    }
    
    //assign returned products section columns to display in table.
    @track columnsRP = columnsRP;
    //get the current date and display it in Applicable date input on UI.
    @track dateToday = new Date().getFullYear()+'-'+(new Date().getMonth()+1)+'-'+new Date().getDate();
    //variable to store the json message and displays as NOTE.
    @track message = '';
    //title of the top level section.It changes to Parent Products if user selects the limit to single level checkbox.
    @track title = 'Top Level Products';
    //boolean to hide the radio buttons in lightning data table if the rows in table are only one.
    @track hideCheckBoxColumn = false;
    //store the limit to single level checlbox value.
    @track limitToSingleLevel = false;
    // Expose the labels to use in the templat
    label = {
        bomUsedIn, bomLevel,bomApplication,helpText,topLevelErrorMessage,searchErrorMessage,sbomErrorMessage,sbomIpErrorMessage
    };
    //QACM-78 
    @track lotNoAndExpirDateColumns= lotNoAndExpirationcolumns;
    //Boolean to Show/Hide  Product Component Section.
    @track showProductComponents=false;
    @track treeItems;
    @track loaded = true;
	@track showModal = false;
	@track className = 'defaultClass';
    @track topLevelCls = 'defaultClass';
    @track applicableDate;
	@track name;
    @track productCode;
    @track ServiceProductType;
	@track showExpandAllTreeGridBtn = true;
    @track showCollapseAllTreeGridBtn = false;
    @track bomLevelInput = '3';
    @track showServiceSbom=false;
    @track ipId;
    @track sbomId;
    @track ipName;
    /*QACM-78 Starts*/
    @track accountName;
    @track erpCustomerId;
    @track isCaseOrWorkOredr = false;
    @track startDateValue;
    @track endDateValue;
    @track applicableDateHelpText = BOMApplicableDateHelpText
    @track caseWOObjectApiName
    @track isShowModal = false
    @track columnsProductComponents = columnsProductComponentsForProAndPO;
    @track filterLevel = "2";
    @track startDateRequest;
    @track endDateRequest;
    @track tdata={}
    @track isShowModal= false
    @track batchColumnsData = []
    @track productComponentBatchData
    @track arrayOfBatch=[];
    @track accounterpCustomerId=""
    @track accountValue=""
    @track startDateEndDateErrorMessage = BOMStartDateEndDateLimit
    @track isSaved
    @track showProductModal = true;
    /*QACM-78 Ends*/

    /** CMCM-264 starts */
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    @track SaveBtn = UI_Button_Save;
    @track CancelBtn = UI_Button_Cancel
    /** CMCM-264 ends */

	 //populate bom levels picklist values.
	  get options() {
		return [
			{ label: '1', value: '1' },
			{ label: '2', value: '2' },
			{ label: '3', value: '3' },
			{ label: '4', value: '4' },
			{ label: '5', value: '5' },
			{ label: '6', value: '6' },
			{ label: '7', value: '7' },
		];
	}

    //QACM-78 Default value for Start date field 
    get startDate(){
        const startDate = new Date()
        startDate.setDate(startDate.getDate() - 365 )
        return startDate.toISOString().substring(0, 10)
    }

    get currentDate(){
        const curDate = new Date()
        return curDate.toISOString().substring(0, 10)
    }

    get checkCaseOrWO(){
        return this.isCaseOrWorkOredr;
    }
    /*QACM-78 Ends*/

    

    //QACM-78 Setting the account fields for case or WO
    get accountFields(){
        if(this.objectApiName==='SVMXC__Service_Order__c'){
            return ACCOUNTFIELDSONWO
        }
        else if(this.objectApiName==='Case'){
            return ACCOUNTFIELDSONCASE
        }
    }

	//store the changed value
	handleChange(event) {
		this.bomLevelInput = event.detail.value;
	}

	clickToExpandAll(e) {
    const grid = this.template.querySelector("lightning-tree-grid");
    grid.expandAll();
    this.showCollapseAllTreeGridBtn = true;
    this.showExpandAllTreeGridBtn = false;
    
	}

	clickToCollapseAll(e) {
    const grid = this.template.querySelector("lightning-tree-grid");
    grid.collapseAll();
    this.showCollapseAllTreeGridBtn = false;
    this.showExpandAllTreeGridBtn = true;
	}
    

   @track sfdcMessage = '';
   @track objectInfo;
   //CMCM-3200 Start
   connectedCallback() {
    this.isPrimaryAssociatedProduct = null;
    this.getIsPrimaryAssociatedProduct();
    //CMCM-3200 End
    console.log('-->this.objectApiName'+this.objectApiName);

    if(this.objectApiName === 'SVMXC__Service_Order__c') {
       this.handleServiceOrder();
    }
   else if(this.objectApiName === 'Case') {
        this.handleCase();
   }
   else if(this.objectApiName === 'SVMXC__RMA_Shipment_Order__c') {
        this.handleShipmentOrder();
   }
   
}
    // CMCM-3200 -START
    // if isprimart Porudct is available
    getIsPrimaryAssociatedProduct() {
    if(this.objectApiName === 'SVMXC__Service_Order__c' || this.objectApiName === 'Case') {
        this.getIsPrimaryAssociatedProductHelper();
    }
}
    getIsPrimaryAssociatedProductHelper() {
        getassociatedProduct({caseOrWorkOrderId : this.recordId})
        .then(result => {
                if (result !== null && result !== undefined && result.length > 0) {
                    this.isPrimaryAssociatedProduct = {
                    isPrimary: result[0].Is_Primary__c,
                    Material: result[0].hasOwnProperty('Product_Code__c') ? result[0].Product_Code__c : 'not available',
                    Material_Desc: result[0].hasOwnProperty('Product__r') ? result[0].Product__r.Name : 'not available',
                    lotNumber: result[0].hasOwnProperty('Product_Lot_Number__c') ? result[0].Product_Lot_Number__c : '', //CMCM-5524
                    serialnumber: result[0].hasOwnProperty('Product_Serial_Number__c') ? result[0].Product_Serial_Number__c : '', //CMCM-5524,
                    ExpiredDate: result[0].hasOwnProperty('Expired_Date__c') ? result[0].Expired_Date__c : null,
                    isExpire: result[0].Is_Expired__c,
                    id: result[0].Id,
                    recId: result[0].hasOwnProperty('Product__c') ? result[0].Product__c : null,
                    disabled:result[0].Is_Primary__c //CMCM-5524
                    };
                }
                this.handleIsPrimaryDisableCondition();

            })
        }
        handleIsPrimaryDisableCondition(){
            if(this.isPrimaryAssociatedProduct !== null && !this.isPrimaryAssociatedProduct.isPrimary) {
                this.isPrimaryAssociatedProduct.disabled = false;
            }
        } 
    handleServiceOrder() {
         //QACM-78 Setting up columns for Top level product and Product component section based on object
         this.columnsRP = columnsRPForCaseandWorkorder
         this.columnsProductComponents = columnsProductComponentsForCaseAndWO
         this.isCaseOrWorkOredr = true
         this.caseWOObjectApiName = this.objectApiName
         // get the IP and Product details from wo.
        getWODetails({ strWoId: this.recordId })
         .then(result => {
              if (result) {
             this.objectInfo = 'Product2';
                 if(result.some(e => (e.SVMXC__Product__r !== null ))) {
                 this.name = result[0].SVMXC__Product__r.Name;
                 this.productCode = result[0].SVMXC__Product__r.ProductCode;
                 this.ServiceProductType =result[0].SVMXC__Product__r.Service_Product_Type__c;
                 }
                 if(result.some(e => (e.SVMXC__Component__r !== null ))){
                 this.ipName = result[0].SVMXC__Component__r.SVMXC__Serial_Lot_Number__c;
                 }
                 this.erpCustomerId = result[0].SVMXC__Company__r.ERP_Customer_Id__c;//QACM-78
                 this.accountName = result[0].SVMXC__Company__r.Name;//QACM-78
             }
             })
             .catch(error => {
                 const evt = new ShowToastEvent({
                     title: 'Error!',
                     message: error.body.exceptionType +': ' +error.body.message,
                     variant: 'error',
                     mode: 'sticky',
                 });
                 this.dispatchEvent(evt);
             });
    }
    handleCase() {
        //QACM-78 Setting up columns for Top level product and Product component section based on object
        this.columnsRP = columnsRPForCaseandWorkorder
        this.columnsProductComponents = columnsProductComponentsForCaseAndWO
        this.isCaseOrWorkOredr = true
        this.caseWOObjectApiName = this.objectApiName
        console.log('9999this.recordId'+this.recordId+'...'+this.objectApiName);
       // get the IP and Product details from case
    getCaseDetails({ strCaseId: this.recordId })
    .then(result => {
         if (result) {
                this.objectInfo = 'Product2';
                if(result.some(e => (e.SVMXC__Product__r !== null ))){
                    this.name = result[0].SVMXC__Product__r.Name;
                    this.productCode = result[0].SVMXC__Product__r.ProductCode;
                    this.ServiceProductType =result[0].SVMXC__Product__r.Service_Product_Type__c;
                }
                if(result.some(e => (e.SVMXC__Component__r !== null ))){
                    this.ipName=result[0].SVMXC__Component__r.SVMXC__Serial_Lot_Number__c;
                }
                
                this.erpCustomerId = result[0].Account.ERP_Customer_Id__c;//QACM-78
                this.accountName = result[0].Account.Name;//QACM-78
        }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType +': ' +error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
        });
    }
    handleShipmentOrder() {
        //QACM-78 updating column based on object
       // get the IP and Product details from po
    getPODetails({ strPoId: this.recordId })
    .then(result => {
         if (result) {
        this.objectInfo = 'Product2';
        if(result.some(e => (e.SVMXC__Service_Order__r !== null ))){
            if(result.some(p => (p.SVMXC__Service_Order__r.SVMXC__Product__r !== null ))){
                this.name = result[0].SVMXC__Service_Order__r.SVMXC__Product__r.Name;
                this.productCode = result[0].SVMXC__Service_Order__r.SVMXC__Product__r.ProductCode;
                this.ServiceProductType =result[0].SVMXC__Service_Order__r.SVMXC__Product__r.Service_Product_Type__c;
            }
            if(result.some(q => (q.SVMXC__Service_Order__r.SVMXC__Component__r !== null ))){
                this.ipName=result[0].SVMXC__Service_Order__r.SVMXC__Component__r.SVMXC__Serial_Lot_Number__c;
            }
        }
        
        }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType +': ' +error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
        });
    }
    //wire function to get the product name and productcode to pre populate if the user is on product.
    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    objProduct({ data, error }) {
        if(data != undefined && data.apiName == 'Product2'){
			this.objectInfo = data.apiName;
            this.name = data.fields.Name.value;
            this.productCode = data.fields.ProductCode.value;
            this.ServiceProductType =data.fields.Service_Product_Type__c.value;
        }
    };
    //QACM-78 wire function to get the Account name to pre populate if the user is on case or workorder.
    @wire(getRecord, {recordId: '$recordId', fields: '$accountFields'})
    objAccount({ data, error }) {
        if(this.objectApiName === 'Case' ){
            this.columnsRP = columnsRPForCaseandWorkorder
            this.columnsProductComponents = columnsProductComponentsForCaseAndWO
            this.isCaseOrWorkOredr = true
            this.caseWOObjectApiName = this.objectApiName
            this.erpCustomerId = getFieldValue(data, 'Case.Account.ERP_Customer_Id__c');//QACM-78
            this.accountName = getFieldValue(data, 'Case.Account.Name');//QACM-78
        }
        else if(this.objectApiName === 'SVMXC__Service_Order__c'){
            this.columnsRP = columnsRPForCaseandWorkorder
            this.columnsProductComponents = columnsProductComponentsForCaseAndWO
            this.isCaseOrWorkOredr = true
            this.caseWOObjectApiName = this.objectApiName
            this.erpCustomerId = getFieldValue(data, 'SVMXC__Service_Order__c.SVMXC__Company__r.ERP_Customer_Id__c');//QACM-78
            this.accountName = getFieldValue(data, 'SVMXC__Service_Order__c.SVMXC__Company__r.Name');//QACM-78
        }
    }

    /**
    * method name: handleClick
    * params: none
    * description: To be executed on click of search button. 
    * displays products returned and top level products tables based on the data.
    */

    handleClick(){   
        let inputValues = [];
        let obj = {};
        this.showReturnedProducts =false;
        this.showProductComponents =false;
        this.showTopLevel = false;
		this.className = '';
        this.topLevelCls = '';
        this.hideCheckBoxColumn = false;
        this.showServiceSbom=false;
        this.message='';
        this.ipId='';
        this.sbomId='';

		/*QACM-78* setting validation on End date field */
        if(this.objectApiName==='Case' || this.objectApiName==='SVMXC__Service_Order__c'){
            this.template.querySelectorAll('c-product-Lookup').forEach(function(element){
                    if(element.label === 'Account'){
                        this.accountValue = element.selectRecordName
                    }
               
            },this);
            
            let enddate =this.template.querySelector(".enddate")
            if(this.accountValue){
                if(!this.endDateValue){
                    this.endDateValue = this.currentDate
                }
                if(!this.startDateValue){
                    this.startDateValue = this.startDate
                }
                const startDateData = new Date( this.startDateValue );
                const endDateData = new Date( this.endDateValue );
                let Difference_In_Time = endDateData.getTime() - startDateData.getTime();
                let Difference_In_Days = Difference_In_Time / (1000 * 3600 * 24);
                if(Difference_In_Days>365){
                    enddate.setCustomValidity(this.startDateEndDateErrorMessage);
                    enddate.reportValidity()
                    return
                }
                else{
                    enddate.setCustomValidity('')
                    enddate.reportValidity();
                }
                this.startDateRequest = this.startDateValue
                this.endDateRequest = this.endDateValue   
            } 
            else{
            enddate.setCustomValidity('')
            enddate.reportValidity();
            }
        }
        
        
        /*QACM-78 Ends*/
        //QACM-78 Starts
        if(this.objectApiName!=='Case' || this.objectApiName!=='SVMXC__Service_Order__c'){
            obj["ERP_Customer_ID"] = ''
            obj["StartDate"]=null
            obj["EndDate"]=null
        }//QACM-78 Ends
        
        
        //prepare the request paramters to send the HTTP request
        this.template.querySelectorAll("lightning-input").forEach(function(element){

            if(element.name == 'Multi_Level'){
                if(element.checked === true){
                    obj[element.name] = null;
                }else{
                    obj[element.name] = 'X';
                }
                this.limitToSingleLevel = element.checked;
            }else if(element.name == 'Valid_From'){
                this.applicableDate = element.value;
                let str2 = 'T00:00:00';
                if(this.applicableDate != null){
                    obj["Valid_From"] = this.applicableDate.concat(str2);
                }else{
                    obj["Valid_From"]= null;
                }    
            }else if((element.name == 'Serial_Number') || (element.name == 'Batch_Number')){
                obj[element.name] = element.value.toUpperCase();
            }else if((element.name == 'Service_ProductType')){
                this.ServiceProductType=element.value.toUpperCase();
                console.log('-->'+this.ServiceProductType);
            }else if(element.name === 'StartDate'){//QACM-78 starts
                this.startDateRequest = element.value;
                    let str = 'T00:00:00';
                if(this.startDateRequest !== null && this.startDateRequest !== undefined && this.startDateRequest !== "" ){
                    obj["StartDate"]=this.startDateRequest.concat(str);//QACM-78
                }
                else{
                    obj["StartDate"]=null
                }
            }
            else if(element.name === 'EndDate'){
                this.endDateRequest = element.value;
                let str = 'T00:00:00';
                if(this.endDateRequest !== null && this.endDateRequest !== undefined && this.endDateRequest !== ""){
                    obj["EndDate"]=this.endDateRequest.concat(str);
                }
                else{
                    obj["EndDate"]=null
                }
            }//QACM-78 Ends
            else{
                obj[element.name] = element.value;
            }
        },this);

        
        if(this.ServiceProductType=='INSTRUMENT'){
            this.template.querySelectorAll('c-product-Lookup').forEach(function(element){
                if(element.label == 'Serial Number'){
                    if(element.selectRecordName=== "" || element.selectRecordName===undefined){
                        this.message=this.label.sbomIpErrorMessage;
                        this.showServiceSbom= false;
                       }else{
                        this.ipDetails(element.selectRecordName,false);
                       }
                    
                }
               
            },this);
            
        }else{ 
            this.showServiceSbom= false;
        //get value from lookup field.
        let lookupSerialNumber;
        let lookupProduct;
            this.template.querySelectorAll('c-product-Lookup').forEach(function(element){
                if(element.label == 'Serial Number'){
                     lookupSerialNumber=element.selectRecordName;
                }
                if(element.label == 'Product Code'){
                     lookupProduct=element.selectRecordName;
                }
                //QACM-78
                if(this.objectApiName==='Case' || this.objectApiName==='SVMXC__Service_Order__c'){
                    if(element.label === 'Account'){
                        if(!element.selectRecordName){
                            this.erpCustomerId = ""
                        }
                    }
                }
                else{
                    this.erpCustomerId = ""
                }
                
                this.accounterpCustomerId = this.erpCustomerId
               
            },this);
       
        obj["Material"] = lookupProduct;
        obj["Serial_Number"]=lookupSerialNumber;
        inputValues.push(obj.Material,obj.ProductName,obj.Serial_Number,obj.Batch_Number);
        obj["Valid_To"] = null;
        obj["Integration_Sys"] = 'SFDC';
        obj["BOM_Level"] = this.bomLevelInput;
        obj["BOM_Usage"] = obj["Plant"] = obj["Message"] = '';
        obj["EX_Product_Return"] = obj["EX_Where_Used"] =[];
        obj["BOM_Used_In"] = this.label.bomUsedIn;
        obj["EX_ProductDelivery"]=[];//QACM-78
        obj["ERP_Customer_ID"] = this.erpCustomerId//QACM-78
        delete obj['ProductName'];
        delete obj['Service_ProductType'];

        //remove the blank values if any.
        let filtered = inputValues.filter(function (el) {
            return el != ''&& el != null;
        });
        if(Array.isArray(filtered) && filtered.length){
            this.loaded = false;
            //server call to get the response back and display on UI.
            returnResponse({jsonString:JSON.stringify(obj)})
            .then(result => {
                this.loaded = true;
                this.error = undefined;
                console.log('result-->', result);
                //set the message.
                if(result.sfdcToSAPCalloutStatus == 'Fail'){
                    this.sfdcMessage = result.Message;
					this.showModal = true;
                    
                }
                
                this.message = result.d.Message;
                //returned products wrapper.
                let productReturnWrapper = [];
                if(result.d.Ex_Product_Return != undefined){
                    productReturnWrapper = result.d.Ex_Product_Return.results;
                }
                //QACM-78 Starts
                let exProductDelivery =[];
                if(result.d.EX_ProductDelivery !== undefined && result.d.EX_ProductDelivery !== null && result.d.EX_ProductDelivery !== ""){
                    exProductDelivery = [...result.d.EX_ProductDelivery.results];
                }
                //QACM-78 Ends
                //where used wrapper.
                let whereUsedWrapper = [];
                if(result.d.Ex_Where_Used != undefined){
                    whereUsedWrapper = result.d.Ex_Where_Used.results;
                }
                /*
                * populate product returned table with max row limit as 5.
                */ 

                if(productReturnWrapper.length > 0){
                    //create an array of product codes to get their respective products sfdc Id's.
                    let productCodeArray = [];
                    for(let k=0; k< productReturnWrapper.length ; k++){
                        productCodeArray.push(productReturnWrapper[k].Material);
                    }
                    if(whereUsedWrapper.length > 0){
                        for(let m=0; m< whereUsedWrapper.length; m++){
                            productCodeArray.push(whereUsedWrapper[m].Material);
                        }
                    }
                    //server call to get the product Id's which are in the response.
                    getProductID({lstProductCodes:productCodeArray})
                    .then(response =>{
                        /*
                        * if the response is greater than 5, limit the records to 5.
                        */
                        let jsonReturnproducts = [];
                        for(let i=0; i<productReturnWrapper.length; i++){
                            //if(i<5){
                                //prepare the json object to include other extra varibales like product Id and disabled.
                                let jsonObj = {}
                                let returnedProduct = productReturnWrapper[i];
                                jsonObj["Batch_Number"] = returnedProduct.Batch_Number;
                                jsonObj["Material"] = returnedProduct.Material;
                                jsonObj["Material_Desc"] = returnedProduct.Material_Desc;
                                jsonObj["Regulatory_Type"] = returnedProduct.Regulatory_Type;
                                jsonObj["Serial_Number"] = returnedProduct.Serial_Number;
                                jsonObj["Status"] = returnedProduct.Status;
                                jsonObj["recId"] = response[returnedProduct.Material];
                                //assign disabled attribute as true if there is no productId existing in the DCP.
                                if(response[returnedProduct.Material] == null || response[returnedProduct.Material] == undefined){
                                    jsonObj["disabled"] = true;
                                }else{
                                    jsonObj["disabled"] = false;
                                }
                                //QACM-78 Starts
                                let batchArray = [...exProductDelivery]
                                let batchProductDelivery = batchArray.filter(batchData => {
                                    return batchData.Material === returnedProduct.Material;
                                });
                                if(batchProductDelivery.length>0){
                                    let batchObj={}
                                   this.arrayOfBatch=[];
                                    for(let b=0; b<batchProductDelivery.length; b++){
                                        let a= new Date(parseInt((batchProductDelivery[b].BatchExpiry).substr(6))); 
                                        let date1 =a.getDate()
                                        let month = a.getMonth()+1
                                        let year = a.getFullYear()
                                        if(date1<=9){
                                            date1 = '0'+date1
                                        }
                                        if(month<=9){
                                            month = '0'+month
                                        }
                                        let formattedDate = month+'/'+date1+'/'+year
                                       batchObj={
                                        Batch : batchProductDelivery[b].Batch,
                                        BatchExpiry : formattedDate,
                                        Material : batchProductDelivery[b].Material
                                       }
                                       this.arrayOfBatch.push(batchObj)
                                   }
                                    jsonObj["BatchDelivery"] = this.arrayOfBatch;
                                    jsonObj["productDisable"] = false;
                                }//QACM-78 Ends
                                else{
                                    jsonObj["productDisable"] = true;
                                }
                               // if(returnedProduct[i].)
                                
                                jsonReturnproducts.push(jsonObj);
                            //}
                        }
                       this.productsReturnedData = jsonReturnproducts.slice();
                        //show the returned products section if there are returned products.
						let rpLength = this.productsReturnedData.length;
                        if(rpLength > 0){
							if(rpLength > 5){
                                this.className = 'section1';
                            }
                            this.showReturnedProducts=true;
                            /**
                            * If returned products is 1 then directly populate the top level products 
                            * or else let the user select the product for which top level products to be displayed.
                            */
                            
                            if(rpLength == 1){
                                /*
                                * populate Top Level products table with max row limit as 10.
                                */   
                                
                                this.hideCheckBoxColumn = true;
                                if(whereUsedWrapper.length > 0 ){
                                    this.displayTopLevel(whereUsedWrapper,response);
                                }else{
                                    const evt = new ShowToastEvent({
                                        title: 'Info!',
                                        message: this.label.topLevelErrorMessage,
                                        variant: 'info',
                                        mode: 'sticky',
                                    });
                                    this.dispatchEvent(evt);
                                }
        
                            }
                        }            
                        
                    })
                    //catch the error and show it as a toast message.
                    .catch(error =>{
                        this.loaded = true;
                        this.showTopLevel = false;
                        this.showReturnedProducts = false;               
                        this.error = error.body;
                        this.topLevelData = undefined;
                        this.productsReturnedData = undefined;
                        const evt = new ShowToastEvent({
                            title: 'Error!',
                            message: error.body.exceptionType +': ' +error.body.message,
                            variant: 'error',
                            mode: 'sticky',
                        });
                        this.dispatchEvent(evt);
                    });

                }
                   
                
            })
            //catch the error if any and show it as a toast message.
            .catch((error) => {
                this.loaded = true;
                this.showTopLevel = false;
                this.showReturnedProducts = false;               
                this.error = error;
                this.topLevelData = undefined;
                this.productsReturnedData = undefined;
                const evt = new ShowToastEvent({
                    title: 'Error!',
                    message: error.body.exceptionType +': ' +error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
            }); 
            
        }else{
            //if there is no user input for product code, product name, serial number and batch number then, show an error.
            this.showTopLevel = false;
            this.showReturnedProducts = false;
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: this.label.searchErrorMessage,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
        }
    }               
    }
    /**
     * Method Name: clearData
     * Params: event
     * Description: This method would be called on click of 'Clear All' button and It will empty all input fields in the serach section.
     */
    clearData(event){
        this.showTopLevel = false;
        this.showReturnedProducts = false;
        this.showProductComponents =false;
        this.showServiceSbom=false;
        this.isModalOpen = false; //CMCM-5524
        this.selectedRows = []; //CMCM-5524
        this.isAddButtonDisabled = false; //CMCM-5524
        
        this.message = '';
        this.sfdcMessage = '';
        this.template.querySelectorAll('lightning-input').forEach(function(element){
            if(element.name == 'Multi_Level'){
                element.checked = false;
            }else if(element.name == 'Valid_From'){
                element.value = this.dateToday;
            }else{//QACM-78 Starts
                element.value = '';
                if((this.objectApiName==='Case' || this.objectApiName==='SVMXC__Service_Order__c')&& element.name === 'EndDate'){
                    element.setCustomValidity('');
                    element.reportValidity()
                }
            }//QACM-78 Ends
            
        },this);
        //clearing look-up field
       // this.template.querySelector('c-product-Lookup').resetData(event);
        //this.template.querySelectorAll('c-product-Lookup').resetData(event);
        this.template.querySelectorAll('c-product-Lookup').forEach(function(element){
            element.resetData(event);
        },this);
		this.className = '';
        this.topLevelCls = '';
        this.hideCheckBoxColumn = false;
        this.template.querySelector('lightning-combobox').value = '3';
    }
    /*
    * Method Name: fetchTopLevels
    * Params: event
    * Description: get the data in the specific row onclick of radio button (Row Actions) 
    *              and display top levels respective to that returned product.
    */
    fetchTopLevels(event) {
        this.loaded = false;
        this.showTopLevel=false;
        this.showProductComponents = false;
        //fetch the row details
        let selectedRows = event.detail.selectedRows;

        //create a json object of requestparams to send it to server.
        let obj = {};
        obj["Material"] = selectedRows[0].Material;
        obj["Serial_Number"] = selectedRows[0].Serial_Number.toUpperCase();
        obj["Batch_Number"] = selectedRows[0].Batch_Number.toUpperCase();
        let str2 = 'T00:00:00';
        if(this.applicableDate != null){
            obj["Valid_From"] = this.applicableDate.concat(str2);
        }else{
            obj["Valid_From"]= null;
        }
        if(this.limitToSingleLevel == true){
            obj["Multi_Level"] = null;
        }else{
            obj["Multi_Level"] = 'X';
        }
        obj["Integration_Sys"] = 'SFDC';
        obj["Valid_To"]= null;
        obj["Plant"] = obj["BOM_Usage"] = obj["Message"] =  '';
        obj["BOM_Level"] = this.bomLevelInput;
        obj["EX_Product_Return"] = obj["EX_Where_Used"] =[];
        obj["BOM_Used_In"] = this.label.bomUsedIn;

        //calling the server method for getting top levels.
        returnResponse({jsonString:JSON.stringify(obj)})
            .then(result => {
                this.loaded = true;
                this.error = undefined;
                this.topLevelData = [];
                if(result.sfdcToSAPCalloutStatus == 'Fail'){
                    this.sfdcMessage = result.Message;
                    this.showModal = true;
                }else if(result.sfdcToSAPCalloutStatus == 'Success'){
					this.message = result.d.Message;
					//top levels from server.
					let whereUsedWrapper = [];
					if(result.d.Ex_Where_Used != undefined){
						whereUsedWrapper = result.d.Ex_Where_Used.results;
					}
					//get the product codes that returned and fetch their respective sfdc Id's.
					let productCodeArray = [];
					for(let b=0; b<whereUsedWrapper.length; b++){
						
						productCodeArray.push(whereUsedWrapper[b].Material);
					}
					//server call to get the product Id.
					getProductID({lstProductCodes:productCodeArray})
					.then(response =>{
						/*
						* populate Top Level products table with max row limit as 10.
						*/
							this.displayTopLevel(whereUsedWrapper,response);
					})
					.catch(error => {
						//catch the error and show it as a toast message.
						this.loaded = true;
						this.showTopLevel = false;
						this.showReturnedProducts = false;               
						this.error = error.body;
						this.topLevelData = undefined;
						this.productsReturnedData = undefined;
						const evt = new ShowToastEvent({
							title: 'Error!',
							message: error.body.exceptionType +': ' +error.body.message,
							variant: 'error',
							mode: 'sticky',
						});
						this.dispatchEvent(evt);

					});

				}
            })
            .catch(error => {
                //catch  the error and show it as a toast message.
                this.loaded = true;
                this.showTopLevel = false;
                this.showReturnedProducts = false;               
                this.error = error.body;
                this.topLevelData = undefined;
                this.productsReturnedData = undefined;
                const evt = new ShowToastEvent({
                    title: 'Error!',
                    message: error.body.exceptionType +': ' +error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
            });
    }
     /*
    * Method Name: handleAddProduct
    * Description: manage the process of adding a product
    */
    handleAddProduct(event){
        let showProductModal = true;
    }
    /*
    * Method Name: handleLookupValueSelect
    * Params: event
    * Description: on selecting the look up value, get the info from child to parent component and auto populate fields if needed
    *               using that info.
    */
    handleLookupValueSelect(event){
        //subscribing to the event that is fired from child to display the name.
        let SearchedProdValue = this.template.querySelector("c-product-Lookup").selectRecordName;
        getProDetails({strProdCode:SearchedProdValue})
        .then(result => {
            if (result) {
                this.template.querySelector("[data-field='Service_ProductType']").value=result[0].Service_Product_Type__c;
                let prodname = event.detail.productName;  
                this.template.querySelector("[data-field='ProductName']").value = prodname;
            }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType +': ' +error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
        });
       
        
    }
    /*
    * Method Name: handleLookupValueSelectIP
    * Params: event
    * Description: on selecting the look up value, get the info from child to parent component and auto populate fields if needed
    *               using that info.
    */
    handleLookupValueSelectIP(event){
        //subscribing to the event that is fired from child to display the name.
        let prodname = event.detail.productName;
            this.ipDetails(prodname,true);
        
    }
    /*
    * Method Name: ipDetails
    * Params: prodname,lookup
    * Description: get Ip details from server call getIpDetails
    */
    ipDetails(prodname,lookup){
       this.message='';
       this.ipId='';
       this.sbomId='';
       this.name='';
       this.ServiceProductType='';
       this.productCode='';
        getIpDetails({ name:prodname })
            .then(result => {
             if (result) {
              if(result.hasOwnProperty('ip')){
                this.ipId=result.ip;
              }
              if(result.hasOwnProperty('sbom')){
                this.sbomId=result.sbom;
              } 
              if(result.hasOwnProperty('productId') ){
                this.name=result.productId;
              }
              if(result.hasOwnProperty('materialName')){
                this.ServiceProductType= result.materialName;
              }
              if(result.hasOwnProperty('material')){
                this.productCode=result.material;
              }
              
            if(!lookup){
                if(this.ServiceProductType==='INSTRUMENT'&&(this.ipId===null||this.ipId===undefined||this.ipId=='') ){
                    this.message=this.label.sbomIpErrorMessage;
                    this.showServiceSbom= false;
                 }
                 else if((this.sbomId===null||this.sbomId===undefined || this.sbomId =='' )&& !(this.ipId===null||this.ipId===undefined||this.ipId=='') ){
                    this.message=this.label.sbomErrorMessage;
                    this.showServiceSbom= false;
                }
                else{
                    this.showServiceSbom= true;
                }
            }
             
        }
            })
            .catch(error => {
                this.showServiceSbom= false;
                const evt = new ShowToastEvent({
                    title: 'Error!',
                    message: error.body.exceptionType +': ' +error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
            });
        }

    /**
     * Method Name: displayTopLevel
     * Params: whereUsedWrapper, response
     * Description: Display the top levels section.
     */
    displayTopLevel(whereUsedWrapper, response){
        
        this.showTopLevel=false;
        this.title = 'Top Level Products';
        this.columns = columns; 

        let jsonData = [];
        //if the toplevels returns are more than 10, display only 10.
        if(whereUsedWrapper.length > 0){
            for(let c = 0; c< whereUsedWrapper.length ; c++){
                //if(c<10){
                    //json object to store extra variables like product id and desabled attribute.
                    let jsonObj = {}
                    let returnedProduct = whereUsedWrapper[c];
                    jsonObj["Batch_Number"] = returnedProduct.Batch_Number;
                    jsonObj["Material"] = returnedProduct.Material;
                    jsonObj["Material_Desc"] = returnedProduct.Material_Desc;
                    jsonObj["Regulatory_Type"] = returnedProduct.Regulatory_Type;
                    jsonObj["Serial_Number"] = returnedProduct.Serial_Number;
                    jsonObj["Status"] = returnedProduct.Status;
                    jsonObj["recId"] = response[returnedProduct.Material];
                    if(response[returnedProduct.Material] == null || response[returnedProduct.Material] == undefined){
                        jsonObj["disabled"] = true;
                    }else{
                        jsonObj["disabled"] = false;
                    }
                    jsonData.push(jsonObj);
                //}
            }
            this.topLevelData = jsonData.slice();
            //show top levels section only if there is top levels data.
			let topeLevelLength = this.topLevelData.length;
            if(topeLevelLength > 0){
				if(topeLevelLength > 10){
                    this.topLevelCls = 'section2';
                }
                this.showTopLevel=true;
                // if limit to single checkbox is clicked, display parent products instead of top levels.
                if(this.limitToSingleLevel == true){
                    this.title = 'Parent Products';
                    this.columns = parentColumns;
                }
            }
            console.log('data--:'+this.topLevelData);
        } 
    }
    /**
     * method name: handleReadOnly
     * Params: None
     * description: It makes product name field as input from read only.
     */
    handleReadOnly(){
        this.template.querySelector("[data-field='ProductName']").value = '';
        this.template.querySelector("[data-field='Service_ProductType']").value = '';
    }
    /**
     * Method Name:  fetchProductComponent
     * Params: event
     * Description : It will called on selcting the top level section row and which willl display product components section.
     */
    fetchProductComponent(event){
		//  to get the selected product.
		let SearchedProdValue = this.template.querySelector("c-product-Lookup")
      .selectRecordName;
        this.loaded = false;
		this.showCollapseAllTreeGridBtn = false;
        this.showExpandAllTreeGridBtn = true;
        //back end call
       //fetch the row details
       let selectedRows = event.detail.selectedRows;
       //create a json object of requestparams to send it to server.
       let obj = {};
      
       obj["Material"]= selectedRows[0].Material;
       
       obj["Serial_Number"]= selectedRows[0].Serial_Number.toUpperCase();
       obj["Batch_Number"]= selectedRows[0].Batch_Number.toUpperCase();
       let str2 = 'T00:00:00';
		if(this.applicableDate != null){
			obj["Valid_From"] = this.applicableDate.concat(str2);
		}else{
			obj["Valid_From"]= null;
		}
       obj["Integration_Sys"]='SFDC';
       obj["Multi_Level"]='X';
       obj["BOM_Level"]=this.bomLevelInput;
       obj["BOM_Usage"]=null;
       obj["Plant"]=null;
       obj["Application"]=this.label.bomApplication;
       obj["Limit_explosion"]=null;
       obj["Engineering"]=null;
       obj["Production"]=null;
       obj["Plant_maint"]=null;
       obj["Bulk_material"]=null;
       obj["PM_Assembly"]=null;
       obj["Ex_Product_Return"]=[];
       obj["Ex_BOM_Explosion"]=[];
       obj["EX_ProductDelivery"]=[];//QACM-78
       obj["FilterLevel"] = this.filterLevel//QACM-78
       //QACM-78 stars
       if(this.objectApiName==='SVMXC__Service_Order__c' || this.objectApiName==='Case'){
            let str = 'T00:00:00';
            if(this.startDateRequest !== null && this.startDateRequest!== undefined && this.startDateRequest!==""){
                obj["StartDate"]=this.startDateRequest.concat(str);//QACM-78
            }
            else{
                obj["StartDate"]=null
            }
            if(this.endDateRequest !== null && this.endDateRequest !== undefined && this.endDateRequest!==""){
                obj["EndDate"]=this.endDateRequest.concat(str);//QACM-78
            }
            else{
                obj["EndDate"]=null
            }
            obj["ERP_Customer_ID"] = this.accounterpCustomerId 
       }
       else{
        obj["ERP_Customer_ID"] = ''
        obj["StartDate"]=null
        obj["EndDate"]=null
        
       }//QACM-78 Ends
       
       
       getTreeGridData({ selectedProduct: JSON.stringify(obj),searchedProduct: SearchedProdValue})
       .then(result => {
            if (result) {
                  this.loaded = true;
                   let res = result;
                   //QACM-78 Starts
                   if(res[0].BatchResults){
                    this.productComponentBatchData = [...res[0].BatchResults];
                   }
                   //QACM-78 Ends
                   let tempjson = JSON.parse(JSON.stringify(result).split('items').join('_children'));
                   this.treeItems = tempjson;
                   this.message = result[0].Message;
                   this.sfdcMessage=result[0].ErrorMessage;
                   //this.showProductComponents=true;
                  this.showProductComponents=result[0].showProductComponent;
                   
                
             } 
           
        })
        .catch(error => {
            this.loaded = true;
            this.showProductComponents=false;
            const evt = new ShowToastEvent({
            title: 'Error!',
               message: error.body.exceptionType +': ' +error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt); 
        }); 
    }
    /**
     * Method Name:callRowAction
     *  Params: event
     * Description : It is to navigate to product record page in DCP if the user clicks on product code in toplevel && returned products section.
     */
    callRowAction(event){
        
        //get the record Id.
        const recId = event.detail.row.recId;
        //get the action name
        const actionName = event.detail.action.name;
        //if the action name is View, navigate to product record page.
        if(actionName == 'View'){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recId,
                    actionName: 'view',
                },
            }).then(url => {
                getCurrentApp().then(result=>{
                    
                    let appName = result.toUpperCase();
                    if(appName.includes('CONSOLE')){
                        // View a custom object record.
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: recId,
                                objectApiName: 'Product2', // objectApiName is optional
                                actionName: 'view'
                            }
                        });
                    }else{
                        window.open(url);
                    }
                }).catch(error=>{
                    const evt = new ShowToastEvent({
					title: 'Error!',
					   message: error.body.exceptionType +': ' +error.body.message,
						variant: 'error',
						mode: 'sticky',
					});
					this.dispatchEvent(evt);
                });
            });
        }
        //QACM-78 Starts
        if(actionName === 'viewButton'){
            
            this.batchColumnsData= [...this.productComponentBatchData]
            this.isShowModal =true
        }
        if(actionName === 'productViewButton'){
            this.batchColumnsData=[...event.detail.row.BatchDelivery]
            this.isShowModal =true
        }
        //QACM-78 Ends
    }
	/**
     * Close the error Modal
     */
    closeModal(){
        this.showModal = false;
    }

    /**
     * QACM-78 event handler for Start Date field
     */
    startDateEventHandler(event){
        this.startDateValue=event.target.value
        
    }

    /**
     * QACM-78 event handler for End Date field
     */
    endDateEventHandler(event){
        this.endDateValue=event.target.value
        let enddate =this.template.querySelector(".enddate")
        enddate.setCustomValidity('');
        enddate.reportValidity()
    }
     /*
    * Method Name: handleAccountLookupValueSelect
    * Params: event
    * Description: QACM-78 on selecting the Account look up value, get the info from child to parent component and auto populate fields if needed
    *               using that info.
    */
     handleAccountLookupValueSelect(event){
       this.erpCustomerId = event.detail.productName;
    }
    //QACM-79 method to close the model window
    hideModalBox(){
        this.isShowModal =false
    }
  
     //CMCM-264
    //Adding Modal Popup code  
    openModal() {
        // CMCM-3200 Start
      const tableData = [];
        for (let i = 0; i < this.dataForDataTable.length; i++) {
            if (this.dataForDataTable[i].recId !== null) {
                const data = {
                    isPrimary: false,
                    Material: this.dataForDataTable[i].Material,
                    Material_Desc: this.dataForDataTable[i].Material_Desc,
                    lotNumber: this.dataForDataTable[i].lotNumber,
                    serialnumber: this.dataForDataTable[i].serialnumber,
                    ExpiredDate: this.dataForDataTable[i].ExpiredDate,
                    isExpire: this.dataForDataTable[i].isExpire,
                    Status: this.dataForDataTable[i].Status,
                    System_Blocks: this.dataForDataTable[i].System_Blocks,
                    disable: this.dataForDataTable[i].disable,
                    recId: this.dataForDataTable[i].recId,
                    id: null
                };
                tableData.push(data);
            }
        }

        // Update this.dataForDataTable with new tableData
        this.dataForDataTable = tableData;
        
        //console.log('Initial dataForDataTable:', JSON.stringify(this.dataForDataTable));

        let isPrimaryPresent = false;
        if (this.isPrimaryAssociatedProduct !== null && this.isPrimaryAssociatedProduct !== undefined) {
            this.dataForDataTable.forEach(datatab => {
                //console.log('datatab before check>>', JSON.stringify(datatab));
                if (datatab.isPrimary === true) {
                    isPrimaryPresent = true;
                }
            });

            //console.log('isPrimaryPresent before addition>>', isPrimaryPresent);
            if (!isPrimaryPresent) {
                this.dataForDataTable.push(this.isPrimaryAssociatedProduct);
            }
        }

        //console.log('dataForDataTable before remove functions:', JSON.stringify(this.dataForDataTable));

        // CMCM-3200 changing the sequence of calling primary product and remove duplicates.
        this.dataForDataTable = this.removeMaterrialNotFound(this.dataForDataTable); // 3200 14 dec (working but hierarchy not working)
        this.dataForDataTable = this.removeDuplicates(this.dataForDataTable);

        //console.log('dataForDataTable after remove functions:', JSON.stringify(this.dataForDataTable));

        if (this.copyDataForDataTable.length === 0 || this.copyDataForDataTable.length !== this.dataForDataTable.length) {
            this.copyDataForDataTable = JSON.parse(JSON.stringify(this.dataForDataTable));
        }

        this.isModalOpen = true;
    }
    removeMaterrialNotFound(dataForDataTable) {   //3200 change
        return dataForDataTable.filter((item, index, self) => {
            return item.Status !== 'Material not available in SFDC';
        });
    }
    
    closeModalPopup() {
        // to close modal set isModalOpen track value as false
        // CMCM-5524 change
        this.dataForDataTable = JSON.parse(JSON.stringify(this.copyDataForDataTable));
        if (this.isPrimaryAssociatedProduct !== null && this.isPrimaryAssociatedProduct !== undefined) {
            this.isPrimaryAssociatedProduct.isPrimary = true;
        }

        this.isModalOpen = false;
    }

    getPrimaryAndDisabled(index) {
        return index === this.LastSelectedIndex;
    }
    
    submitDetails() {
        this.isSpinner = true;//CMCM-5524
        const productData = this.collectModalData();
        console.log('productData :: '+JSON.stringify(productData));
        saveAssociatedProducts({ product: JSON.stringify(productData), sObjectRecordId: this.recordId })
            .then(() => {
                // Handle success
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Associated products saved successfully',
                    variant: 'success'
                }));
                
                this.isModalOpen = false;
                this.isSpinner = false;//CMCM-5524
                this.clearData(); //CMCM-5524 
                this.getIsPrimaryAssociatedProduct();//CMCM-5524
            })
            .catch(error => {
                // Handle error
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error saving data',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }

    collectModalData() {
        return this.dataForDataTable.map(item => {
            const isExistingRecord = item.id !== null;
            return {
                ...item,
                isExistingRecord: isExistingRecord,
                serialnumber: item.serialnumber !== null ? item.serialnumber : '',
                lotNumber: item.lotNumber !== null ? item.lotNumber : '',
                ExpiredDate: item.ExpiredDate !== null ? item.ExpiredDate : null,
                isExpire: item.isExpire  !== null ? item.isExpire : false,
                isPrimary: item.isPrimary !== null ? item.isPrimary : false,
                recId: item.recId !== null ? item.recId : null,
                id: item.id !== null ? item.id : null
            };
        });
    }
    //CMCM-5524
    handleIsPrimaryChange(event) {
        const selectedIndex = parseInt(event.target.dataset.index, 10);
        this.dataForDataTable.forEach((item, index) => {
            if (item.disabled && !this.isFirstClick) {
                this.LastSelectedIndex = index;
            }
            if (selectedIndex === index && event.target.checked) {
                item.isPrimary = true;
            } else {
                item.isPrimary = false;
            }

        });
        this.isFirstClick = true;
        this.dataForDataTable = [...this.dataForDataTable];
    }
    handleLotNumberUpdate(event) {
        const index = event.target.dataset.index;    
        const updatedValue = event.target.value;    
        this.dataForDataTable[index].lotNumber = updatedValue;
    }
    handleSerialNoUpdate(event) {
        const index = event.target.dataset.index;    
        const updatedValue = event.target.value;    
        this.dataForDataTable[index].serialnumber = updatedValue;
    }
    handleExpiredDateUpdate(event) {
        const index = event.target.dataset.index;    
        const updatedValue = event.target.value;    
        this.dataForDataTable[index].ExpiredDate = updatedValue;
    }
    handleisExpireUpdate(event) {
        const index = event.target.dataset.index;    
        const updatedValue = event.target.checked;    
        this.dataForDataTable[index].isExpire = updatedValue;
    }
    //CMCM-3200 End
    @track tempList = []; // Declare tempList as a tracked property
    @track selectRows;    // Declare selectRows as a tracked property

    updateSelectedRows() {
        // Use 'this.selectRows' to access the component's property
        this.selectRows = this.template.querySelector('lightning-tree-grid').getSelectedRows();

        // Use 'this.tempList' to access the component's property
        this.tempList = []; // Reinitialize tempList as an empty array

        if (this.selectRows.length > 0) {
            this.selectRows.forEach(record => {
                this.tempList.push(record.Id);
            });
        }
    }
}
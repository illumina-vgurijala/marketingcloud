import { LightningElement, track,api } from 'lwc';
import getFruList from '@salesforce/apex/ServiceBomController.getFruList';
import getProductReturned from '@salesforce/apex/ServiceBomController.getProductReturned';
import getCurrentApp from '@salesforce/apex/TreeGrid.getCurrentApp';
import { NavigationMixin } from 'lightning/navigation';
const columnsFru = [
    {label: 'Product Image', fieldName: 'productRecId',type:'button',
    initialWidth: 100, 
    typeAttributes:{label:'Open Image',
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disable'},
    value: 'view',
    iconPosition: 'left'
    }},
    {label: 'Product Code', fieldName: 'material',type:'button',
    initialWidth: 100,
    typeAttributes:{ label:{fieldName: 'material'},
    name: 'productCode',
    title: 'View',
    variant:'base',
    disabled: false,
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Product Name', fieldName: 'materialName',wrapText: true,initialWidth: 300 },
    { label: 'Type', fieldName: 'type',initialWidth: 80,wrapText: true },
    { label: 'Status', fieldName: 'status',initialWidth: 80 ,wrapText: true},
    { label: 'SFDC Blocks', fieldName: 'systemBlocks',wrapText: true },
];
const columnProReturned=[
    {label: 'Product Code', fieldName: 'productRecId',type:'button',
    typeAttributes:{label:{ fieldName: 'material'},
    name: 'View',
    title: 'View',
    variant:'base',
    disabled: { fieldName: 'disable'},
    value: 'view',
    iconPosition: 'left'
    }},
    { label: 'Product Name', fieldName: 'materialName' },
    { label: 'Installed Product', fieldName: 'ip' },
    { label: 'Service Bill of Materials', fieldName: 'sbom'},
];
export default class ServiceBom extends NavigationMixin(LightningElement) {
    @api showSbom;
    @api ipid;
    @api sbomid;
    @track showPic;
    @track ismodalopen;
    @track fruListResult = [];
    @track fruListData = [];
    @track columnsFru = columnsFru;
    @track productReturnedSbom = [];
    @track columnProReturned = columnProReturned;
    @track filterValue='';
    @track picture;
    @track hasNotrendered=true;
    @track loadedSbomSearch= false;
    
    /**
     * Method Name:renderedCallback
     *  Params: 
   */
    renderedCallback(){
        console.log('--->ipid'+this.ipid+ ' -->sbomid'+this.sbomid+'...hasNotrendered'+this.hasNotrendered);
    if(this.hasNotrendered &&this.ipid!==undefined && this.sbomid!==undefined&& this.ipid!==null && this.sbomid!==null){
        this.hasNotrendered= false;
        console.log('loading....');
        this.loadedSbomSearch=false;
        console.log('--->ipid'+this.ipid+ ' ?sbomid'+this.sbomid );
       getProductReturned({ idIP: this.ipid})
        .then(result => {
             if (result) {
              console.log('inside if getProductReturned'+JSON.stringify(result));
              this.productReturnedSbom= result;
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
        console.log('inside handleSearchSbom');
         this.getFruListDetails(this.sbomid,this.filterValue);
        }
    }
    /**
     * Method Name:getFruListDetails
     *  Params: sbomid,filterValue
     * Desc : get Fru List details.
   */
    getFruListDetails(sbomid,filterValue){
        console.log('inside frulist fun');
        getFruList({ sbomId: sbomid , filter : filterValue })
        .then(result => {
             if (result) {
             console.log('inside if getFruList'+result.length);
             let sortedResult= this.sortProductCode(result);
             this.fruListData= sortedResult;
              this.fruListResult= sortedResult; 
              this.loadedSbomSearch= true;
             }
            })
            .catch(error => {
                this.loadedSbomSearch= true;
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
     * Method Name:sortProductCode
     *  Params: result
     * Desc : to sort the result based on productcode.
   */
    sortProductCode(result){
        let sortedResults = result.slice(0);
        sortedResults.sort(function(a,b) {
            console.log('inside sort method');
                let x = a.material.toLowerCase();
                let y = b.material.toLowerCase();
                return x < y ? -1 : x > y ? 1 : 0;
            });
        return sortedResults.reverse();;
    }
    /**
     * Method Name:callRowActionSbom
     *  Params: event
     * Desc : service bom table row action.
   */
    callRowActionSbom(event){
        console.log('inside callRowActionSbom'+event.detail.action.name);
        if(event.detail.action.name==='productCode'){
            this.NavigationToProduct(event.detail.row.productRecId,'productCode');
        }else{
        this.picture = event.detail.row.productRecId;
        this.showPic = true;
        this.ismodalopen=true;
        }
        
     }
     /**
     * Method Name:hanldeCloseModal
     *  Params: event
     * Desc : hanlde Close Modal.
   */
      hanldeCloseModal(event) {
        console.log('inside parent hanldeCloseModal');
        this.showPic = false;
            this.ismodalopen=false;
      }
      /**
     * Method Name:hanldeCloseModal
     *  Params: event
     * Desc : hanlde Close Modal.
   */
      handleFilterChange(event){
        this.loadedSbomSearch=false;
        if(this.template.querySelector('lightning-input').name=== 'filter'){
            this.filterValue=this.template.querySelector('lightning-input').value.toLowerCase();
        }
        console.log('inside handleFilterChange'+this.filterValue);
       this.getFruListDetails(this.sbomid,this.filterValue);
       console.log('fruListData length'+ this.fruListData.length);
     }
     /**
     * Method Name:callRowActionNav
     *  Params: event
     * Desc :navigate to product record page.
   */
     callRowActionNav(event){
        const recId = event.detail.row.productId;
        console.log('inside callRowActionNav recId',recId);
        const actionName = event.detail.action.name;
        // navigate to product record page.
        this.NavigationToProduct(recId,actionName);
     }
     /**
     * Method Name:handleTextChange
     *  Params: event
     * Desc : call handleFilterChange when user click on enter.
   */
     handleTextChange(event){
         if (event.keyCode === 13 ){
             this.handleFilterChange(event);
         }
        }
        /**
     * Method Name:callRowActionNav
     *  Params: event
     * Desc :redirecting to product page..
   */
      NavigationToProduct(recId, actionName){
          console.log('NavigationToProduct recId'+recId+'--> actionName'+actionName);
        if(actionName == 'View'||actionName == 'productCode'){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recId,
                    actionName: 'view',
                },
            }).then(url => {
                getCurrentApp().then(result=>{
                    
                    let appName = result.toUpperCase();
                    console.log('appName-->',appName);
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

     }
}
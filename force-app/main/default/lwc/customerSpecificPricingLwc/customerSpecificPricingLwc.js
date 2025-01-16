import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
/** SampleLookupController.search() Apex method */
import apexSearch from '@salesforce/apex/CustomerSpecificPricingController.search';
import getPricingData from '@salesforce/apex/CustomerSpecificPricingController.getPricingData';
import checkCPProfile from '@salesforce/apex/CustomerSpecificPricingController.checkCPProfile'; //cmcp-13
import {consoleLog,callServer,consoleError} from     'c/utils';                                            //cmcp-13
import lookuperrormessage from '@salesforce/label/c.Lookup_Error_Message_CSP';
import lookuperrortitle from '@salesforce/label/c.Lookup_Error_Title_CSP';
import couldnotfetchprice from '@salesforce/label/c.Could_not_fetch_Prices_Message';
import noselection from '@salesforce/label/c.No_Selection_Lookup_Error_Message_CSP';
import tryselectionagain from '@salesforce/label/c.Please_make_selection_CSP';
import showpricingtitle from '@salesforce/label/c.Show_Pricing_Button_Title';
import showproduct from '@salesforce/label/c.Search_Product_Title';
import currentPricingDetail from '@salesforce/label/c.Current_Pricing_Details_Label';
import customerName from '@salesforce/label/c.Customer_Name_CSP';
import customerNumber from '@salesforce/label/c.Customer_Number_CSP';
import salesOrg from '@salesforce/label/c.Sales_Org_CSP';
import currencyHead from '@salesforce/label/c.Currency_CSP';
import prodDetails from '@salesforce/label/c.Product_Details_Head';
import prodName from '@salesforce/label/c.Product_Name_Head';
import prodCode from '@salesforce/label/c.Product_Code_Head';
import oldMaterialNo from '@salesforce/label/c.Old_Material_Number_Head';
import custSpecPrice from '@salesforce/label/c.Customer_Specific_Price_Head';
import listPrice from '@salesforce/label/c.List_Price_Head';
import prodMobile from '@salesforce/label/c.Product_Head_Mobile';

export default class customerSpecificPricing extends LightningElement {
    
    label = {
        lookuperrormessage,
        lookuperrortitle,
        couldnotfetchprice,
        noselection,
        tryselectionagain,
        showpricingtitle,
        showproduct,
        currentPricingDetail,
        customerName,
        customerNumber,
        salesOrg,
        currencyHead,
        prodDetails,
        prodName,
        prodCode,
        oldMaterialNo,
        custSpecPrice,
        listPrice,
        prodMobile
        
    }

    // Use alerts instead of toast to notify user
    @api notifyViaAlerts = false;
    @api buttonLabel = this.label.showpricingtitle;
    @api placeholder = this.label.showproduct;
    @api recordId;
    @track isMultiEntry = true;
    @track initialSelection = [];
    @track errors = [];
    @track spinnerOn = false;
    @track firstScreen = true;
    @track materialData = [];
    @track customerNumber;
    @track salesOrg;
    @track DistChannel;
    @track division;
    @track currncy;
    @track pricingDate;
    @api desktopVersion;
    @track customerName;
    @track currencyCode;
    @track hideIt= false; //Cmcp-13
    selection = [];

    connectedCallback()
    {
        console.log('Record Id --- ' + this.recordId);
        console.log('Dekstop version value ---- ' + this.desktopVersion);
        this.checkCPAccess();
    }


    handleLookupTypeChange(event) {
        this.initialSelection = [];
        this.errors = [];
        this.isMultiEntry = event.target.checked;
    }

    handleSearch(event) {
        apexSearch(event.detail)
            .then(results => {
                this.template.querySelector('c-d-l-w-c_-look-up').setSearchResults(results);
            })
            .catch(error => {
                this.notifyUser(this.label.lookuperrortitle,this.label.lookuperrormessage, 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }

    handleSelectionChange() {
        this.errors = [];
    }

    //CMCP-13 
    checkCPAccess() {
        callServer(checkCPProfile,{},result =>{
                let returnData = JSON.parse(result);
                consoleLog('check cp access return = ',returnData);
                if(returnData){
                    this.hideIt = true; 
                }
        }, error => {
                consoleError('error',JSON.stringify(error));
                
        });
    }

 
    handleSubmit() {
        this.spinnerOn = true;
        this.checkForErrors();
        if (this.errors.length === 0) {
             this.selection = this.template.querySelector('c-d-l-w-c_-look-up').getSelection();
             console.log('The selection is '+JSON.stringify(this.selection));
             getPricingData({accountId : this.recordId , JsonString : JSON.stringify(this.selection)})
            .then(result => { let finalResult = JSON.parse(result);
                console.log('Success -- ' + JSON.parse(JSON.stringify(finalResult)));
                if(finalResult)
                {
                    this.customerNumber = finalResult.customerNumber;
                    this.salesOrg = finalResult.salesOrg;
                    this.customerName = finalResult.AccountName;
                    this.currencyCode = finalResult.currencyCode;
                    this.materialData = finalResult.resp;
                    if(this.materialData)
                    {
                        for(let i = 0 ; i < this.materialData.length ; i++)
                        {
                            this.materialData[i].isVisible = false;
                        }
                        this.firstScreen = false; 
                    }
                    else
                    {
                        this.notifyUser('Error', this.label.couldnotfetchprice, 'error');
                    }
                }
                else
                {
                    this.notifyUser('Error',this.label.couldnotfetchprice, 'error');
                }
                this.spinnerOn = false;
            })
            .catch(error => {
                this.notifyUser('Error', this.label.couldnotfetchprice , 'error');
                this.spinnerOn = false;
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
        }
        else{
            this.notifyUser('Error', this.label.couldnotfetchprice , 'error');
        }
    } 

    checkForErrors() {
        const selection = this.template.querySelector('c-d-l-w-c_-look-up').getSelection();
        if (selection.length === 0) {
            this.errors = [
                { message: this.label.noselection },
                { message: this.label.tryselectionagain }
            ];
        } else {
            this.errors = [];
        }
    }

    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts){
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }

        setvisibility(event){
            let testRowIndex = event.detail.index;
            this.materialData[testRowIndex].isVisible = event.detail.selectedValue;
            for(let i=0;i<this.materialData.length;i++){
                if(i != testRowIndex){
                   this.materialData[i].isVisible = false;
                }
            }
        }
}
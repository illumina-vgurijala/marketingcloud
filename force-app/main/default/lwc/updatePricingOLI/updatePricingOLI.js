import { LightningElement,wire,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import checkRecrdAccess from '@salesforce/apex/UpdatePricingOLIController.checkRecordAccess';
import getPricing from '@salesforce/apex/UpdatePricingOLIController.getPricingDetails';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { callServer,showErrorToast,showSuccessToast} from 'c/utils';

export default class UpdatePricingOLI extends LightningElement {

@track loadSpinner = true;
    
@wire(CurrentPageReference)
    currentPageReference;


connectedCallback()
{
    this.loadSpinner = true;
    callServer(checkRecrdAccess, {oppId: this.currentPageReference.state.c__recordId}
        , response => {
                       if(response === 'success')
                       {
                            this.getPricingDetails();
                       }
                       else
                       {
                        showErrorToast('You do not have access to edit the opportunity');
                        this.loadSpinner = false;
                        getRecordNotifyChange([{recordId: this.currentPageReference.state.c__recordId}]);
                        this.navigateToViewOLIRelatedPage();
                       }
             }, error => {
                this.handleErrorChanges();
            });
}

getPricingDetails()
{
    callServer(getPricing, {oppId: this.currentPageReference.state.c__recordId}
        , response => {
            let strResponse = JSON.stringify(response);
            if(strResponse === '"success"'){
                showSuccessToast('Prices have been updated.');
                this.loadSpinner = false;
                getRecordNotifyChange([{recordId: this.currentPageReference.state.c__recordId}]);
                this.navigateToViewOLIRelatedPage(); 
                }
                else if(strResponse === '"Quote Present Error"')
                {
                    showErrorToast('Products cannot be added or modified once a quote has been generated. Please contact your Partner Account Manager or Sales Operations.');
                    this.handleErrorChanges();
                }
                else if(strResponse.includes("*#"))
                {
                    strResponse.replace('*#', '');
                    let errorStr = strResponse.substring(strResponse.indexOf(",") + 1, strResponse.lastIndexOf(":"));
                    showErrorToast(errorStr);
                    this.handleErrorChanges();
                }
                else
                {
                    showErrorToast('Pricing not available.');
                    this.handleErrorChanges(); 
                }         
             }, error => {
                console.log(error);
                this.handleErrorChanges();
            });
}

navigateToViewOLIRelatedPage() {
    let sfdcBaseURL = window.location.origin;
    window.location.replace(sfdcBaseURL+'/lightning/r/Opportunity/'+this.currentPageReference.state.c__recordId+'/related/OpportunityLineItems/view');
}

handleErrorChanges()
{
    this.loadSpinner = false;
    getRecordNotifyChange([{recordId: this.currentPageReference.state.c__recordId}]);
    setTimeout(() => { this.navigateToViewOLIRelatedPage(); }, 2000);
    
}

}
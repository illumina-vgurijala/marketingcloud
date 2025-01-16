import { LightningElement,api } from 'lwc';
import updateQuotationToDenied from '@salesforce/apex/ManualDenyQuoteController.updateQuotationToDenied';
import { callServer,showErrorToast,consoleError,consoleLog} from 'c/utils';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";
import DENY_MESSAGE from '@salesforce/label/c.UI_DeniedQuoteMessage';
import DENY_SAPQUOTEFAILDMESSAGE from '@salesforce/label/c.UI_DeniedSAPQuoteStatusFailedMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ManualDenyQuoteCmp extends LightningElement {
    @api recordId;
    @api invoke() {
        this.confirmationBox();
    }

     async confirmationBox() {
        const result = await LightningConfirm.open({
            message: DENY_MESSAGE,
            variant: "header", 
            theme: "warning",
            label: "Deny Quote"
        });
        //result is true if OK was clicked
        if (result) {
            this.handleSuccessAlertClick();
        } else {
            this.handleErrorAlertClick();
        }
    }

   
    handleSuccessAlertClick() {
        callServer(updateQuotationToDenied, {quoteRecordId: this.recordId}
            , response => {
                consoleLog('Response-->'+response);
                if(response === true){
                    getRecordNotifyChange([{recordId : this.recordId}]);
                    this.closeAction();
                }else{
                    const evt = new ShowToastEvent({
                        title: 'Toast Error',
                        message: DENY_SAPQUOTEFAILDMESSAGE,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
            }, error => {
                consoleError('Response-->'+error);
                showErrorToast('Error while denying the Quote');
                
            });
    }

    handleErrorAlertClick() {
        //showErrorToast('Error while denying the Quote');
        this.closeAction();
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}
import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { callServer,showErrorToast,showSuccessToast} from 'c/utils';
import saveRecord from '@salesforce/apex/PPMAgreementQuickActionController.saveRecord';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getAgreementRecord from '@salesforce/apex/PPMAgreementQuickActionController.getAgreementRecord';

const SUCCESSFULLY_UPDATED = '"Successfully updated"';
const REQUEST = 'Request';
const SUCCESS_TOAST ='Post Pricing Message Updated.';

export default class PPMAgreementQuickAction extends NavigationMixin(LightningElement) {
    @track loadSpinner = true;
    @track ppm;
    @track PPMMessage;
    @track PPMUpdate;
    @track reviewStatus;
    @track error;
    @api recordId;
    //@track response;
    
        @wire(getAgreementRecord, {aggRecordId: '$recordId' })
            wiredAgreement({data, error}){
                if(data){
                    this.PPMUpdate = data['Post_Pricing_Message__c'];
                    this.PPMMessage = data['Post_Pricing_Message__c'];
                    this.reviewStatus = data['Apttus__Status_Category__c'];
                    this.statusValidation();
                    this.error = undefined;
                    }
                if(error){
                    this.loadSpinner = false;
                    console.error(error);
                }
            }
        statusValidation(){
            if(this.reviewStatus === REQUEST){
                this.loadSpinner = false;
            }else{
                this.loadSpinner = true;
                showErrorToast('Post Pricing Message cannot be added/updated to an agreement at ' + this.reviewStatus + ' stage.' );
                this.navigateToRecordPage();
            }
        }
    
        navigateToRecordPage() {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Apttus__APTS_Agreement__c',
                    actionName: 'view'
                }
            });
    }

        ppmInputTextOnChange(event){
            this.PPMUpdate = event.target.value;
            }
                
        updatePPMOnAgreement(){
            this.loadSpinner = true;

            if(this.PPMMessage === this.PPMUpdate){
                showSuccessToast(SUCCESS_TOAST);
                this.loadSpinner = false;
                this.refreshComponent();
            }else{
                callServer(saveRecord, {
                    aggRecordId: this.recordId ,
                    ppmValue: this.PPMUpdate
                }, response => {
                    let strResponse = JSON.stringify(response);
                    if(strResponse === SUCCESSFULLY_UPDATED){
                        showSuccessToast(SUCCESS_TOAST);
                        this.loadSpinner = false;
                        this.refreshComponent();
                        this.navigateToRecordPage();
                        }else{
                        showErrorToast(strResponse);
                        this.loadSpinner = false;
                        }
                }, error => {
                    console.log(error);
                });
                
            }
           
        }
        refreshComponent(){
            getRecordNotifyChange([{recordId: this.recordId}]);
        }  
}
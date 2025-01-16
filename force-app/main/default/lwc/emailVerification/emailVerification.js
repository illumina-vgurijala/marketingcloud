import { LightningElement, api, track } from 'lwc';
import { callServer, consoleLog,showErrorToast,showSuccessToast,showWarningToast} from 'c/utils';
import { refreshApex } from '@salesforce/apex';
import sendVerificationRequest from '@salesforce/apex/EmailVerificationController.sendVerificationRequest';
import getRecordData from '@salesforce/apex/EmailVerificationController.getRecordData';
import emailValidationErrMsg from '@salesforce/label/c.UI_Agreement_Generate_Failed';
export default class email_Verification extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track wiredResults;
    @track leadEmailId;
    @track leadEmailVerificationDate;
    @track leadEmailVerificationStatus;
    @track IsVerifyDisabled = true;
    @track booLoading = true;
    // Initial Wire call to fetch lead details
    connectedCallback(){        
        this.serverCallTOApex();                                   
    }
    serverCallTOApex(){  
        callServer(getRecordData,{
            recordId : this.recordId,
            objectApiName : this.objectApiName,
            boolIsFromLwc : true
        }, result => {   
            this.wiredResults = result;                         
            this.leadEmailId = result.Email;
            this.leadEmailVerificationDate = result.Email_Verification_Date__c;                      
            this.IsVerifyDisabled = result.IsVerified__c;
            this.booLoading = false;                                         
            }, error => {                
                consoleLog('Error ---> ', error);                
            }            
        );
    }

    // handler funtion to call apex verification method
    handleVerify(event){
        this.booLoading = true;
        consoleLog('this.leadEmailId===>',this.leadEmailId);
        if(this.leadEmailId === '' || this.leadEmailId === undefined || this.leadEmailId === null){                 
            showErrorToast('Please Enter Email And Try Again');  
            this.booLoading = false;          
            
        }else{
            sendVerificationRequest({
                strEmail: this.leadEmailId,
                recordId : this.recordId,
                objectApiName : this.objectApiName,
                boolIsFromLwc : true
            })
                .then(result => {
                    consoleLog('Return===>',result);
                    if(result.includes('Error-')){
                        //showErrorToast(result.replace('Error-',''));
                        showErrorToast(emailValidationErrMsg); // TASK0784023 - Update email verification technical error message to UI friendly message
                        this.booLoading = false;
                    }
                    else{                    
                        if(result === 'Verified With Warning'){
                            showWarningToast('Email Verified with warning');
                        }else if(result === 'Verified Successfully'){
                            showSuccessToast('Email Verified Successfully');
                        }else{
                            showErrorToast('Email Verification Failure');
                        }                           
                        refreshApex(this.wiredResults);
                        this.booLoading = false;                    
                    }

                })
                .catch(error => {
                    showErrorToast(error.body.message);
                    this.booLoading = false;

                })
                        
        }
    }
    
}
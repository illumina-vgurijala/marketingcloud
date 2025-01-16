import { LightningElement,track,api} from 'lwc';
import {showErrorToast,showSuccessToast,callServer,genericEvent} from "c/utils";
import submitRecord from '@salesforce/apex/SubmitKAApprovalController.submitApproval';  
import approvalSubmitted from '@salesforce/label/c.Approval_Submitted_Successfully';

export default class SubmitKnowledgeArticleApproval extends LightningElement {
    @track comments;
    @track showModal = true;
    @api recId; // current record Id
    @track spinner = false ; //INC0406797
    
    label = {
        approvalSubmitted
    };
    onCommentChange(event) {  
        this.comments = event.detail.value;  
    } 
    //calling apex method
    submitKAApproval() {
        this.spinner = true ;  
        callServer(submitRecord, {
            knowledgeArticleId : this.recId,  
            approvalComment : this.comments    
        }, result => {
            if (result == 'success') {
                this.spinner = false ;  
                showSuccessToast(this.label.approvalSubmitted);
            } 
            this.showModal=false;
            //INC0310817
            genericEvent('reload','Event for refreshing tab',this);
            //End of INC0310817
            this.cancel();
        }, error => {
            this.cancel();
        })  			
    } 
    //close submit approval popup
    cancel() {
        this.spinner = false ;
        genericEvent('close','Event for closing Popup',this);
    }
    
}
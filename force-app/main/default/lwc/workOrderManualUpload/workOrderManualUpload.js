import {LightningElement,wire, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import saveFiles from '@salesforce/apex/UploadAttachmentController.saveFiles';

export default class WorkOrderManualUpload extends LightningElement {
    @api recordId;
    documentTypeFileUpload='Manual Signed LOA'
   
    //DCP-49741 : This method is used to display success message after file is uploaded and Update the work order fields
    handleUploadFinished(event){
        console.log('uploaded file-->',event.detail.files);
        let file=event.detail.files;
        console.log('uploaded file-->',file.length);
            const toastEvent = new ShowToastEvent({
                title: 'Success!',
                message: `${file.length} file uploaded successfully`,
                variant: 'success'
            });
            this.dispatchEvent(toastEvent);
        
            saveFiles({woRecordId:this.recordId})
            .then(()=>{
                console.log('inside line 36');
            })
            .catch(error=>{
                console.log('error-->',error);
                const showError = new ShowToastEvent({
                    title:'Error!',
                    variant:'error',
                    message:'Something went wrong while updating Work Order record'
                });
                this.dispatchEvent(showError);
            });

       
    }

}
import { LightningElement, api ,track} from 'lwc';
// imported to show toast messages
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import DCIRFILEEXTENSIONS from '@salesforce/label/c.DCIRFileExtensions';
import WODOCSFILEEXTENSIONS from '@salesforce/label/c.WO_Documents_File_Extensions';
import createFilesinIP from '@salesforce/apex/UploadAttachmentController.createFileRecInIP';//Added for DCP-43185
import COFD_Label from '@salesforce/label/c.COFD_Label';
import DCIR_Label from '@salesforce/label/c.DCIR_Label';

export default class UploadAttachement extends NavigationMixin(LightningElement) {
    @api
    recordId;
    @track identifier;

    @api isdcirorcofd;

    @api modalClass = 'slds-modal ';
    @track modalBackdropClass = 'slds-backdrop ';
    @track openmodel = false;
    @track Document_Type_fileupload;//added DCP-43185
    @track showModal;
    // accepted parameters
    get acceptedFormats() {
        if(!this.identifier){
            return   DCIRFILEEXTENSIONS;
        }
        else{
            return   WODOCSFILEEXTENSIONS;
        }
    }

    //called implicitly by salesforce  lightning file upload component once file is uploaded
    handleUploadFinished(event) {
        let strFileNames = '';
        let strFileIds ='';//Added DCP-43185
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        

        for(let i = 0; i < uploadedFiles.length; i++) {
            strFileNames += uploadedFiles[i].name + ', ';
            strFileIds += uploadedFiles[i].documentId + ', ';//Added DCP-43185

        }

        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!!',
                message: strFileNames + ' Files uploaded Successfully!!!',
                variant: 'success',
            }),
        );
        if(!this.identifier){
            this.updatePOL();
        }
        if(this.identifier){
            this.createRecordInContentDocLink(strFileIds); 
            
            
        }
        this.closeModal();
    }

    //closes the modal pop up
    closeModal() {
        this.showModal = false;
        this.modalClass = 'slds-modal ';
        this.modalBackdropClass = 'slds-backdrop ';
    } 
   
    //handler to handle upload event , renders the file upload pop up
    @api
    handleuploadevent(rowid){
        this.showModal = true;
        this.modalClass = 'slds-modal slds-fade-in-open';
        this.modalBackdropClass = 'slds-backdrop slds-backdrop_open'; 
        this.recordId=rowid;
        
    }  
    //added-DCP-43185-start
    @api
    handleuploadevent2(uiRecId,rowDocName,installedProduct){
        this.showModal = true;
        this.modalClass = 'slds-modal slds-fade-in-open';
        this.modalBackdropClass = 'slds-backdrop slds-backdrop_open'; 
        this.recordId=uiRecId;
        this.identifier=true;
        if(rowDocName)
            this.Document_Type_fileupload=rowDocName;
        else
            this.Document_Type_fileupload='Genric DOC';
            this.installedProductInWo=installedProduct;
    }  
    //Nadded-DCP-43185-End
    //update the PO record after file upload
    updatePOL() {
        //DCP-49920 updated for COFD
        let polRecord;
        if(this.isdcirorcofd === DCIR_Label){
            polRecord = {
                fields: {
                    Id: this.recordId,
                    Is_DCIR_Filled__c: true
                    
                },
            };
        }

        else if(this.isdcirorcofd === COFD_Label){
            polRecord = {
                fields: {
                    Id: this.recordId,
                    Is_CofD_Filled__c: true
                    
                },
            };
        }
        updateRecord(polRecord)
            // eslint-disable-next-line no-unused-vars
            .then(() => {
                console.log('ref event fire');   
                const sEvent = new CustomEvent('refevent');
               this.dispatchEvent(sEvent);
               console.log('ref event fired'); 

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record Is Updated',
                        variant: 'sucess',
                    }),
                );
           
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error on data save',
                        message: error.message.body,
                        variant: 'error',
                    }),
                );
            });
    } 
    createRecordInContentDocLink(strFile) {
        const fields = {};
        createFilesinIP({ recIpId:this.installedProductInWo,fileAttachId:strFile })
            .then(() => {
                
                const viewchangeevent = new CustomEvent('refevents');
                //const cEvent = new CustomEvent('refevent');
                this.dispatchEvent(viewchangeevent); 
                console.log('ev fired3'); 
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Files uploaded in Installed Product',
                        variant: 'success',
                    }),
                );

                
              
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });

            
    }    
}
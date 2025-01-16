import { LightningElement,wire,track,api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getKeyMethod from '@salesforce/apex/KeyMethodCtrl.getKeyMethod';
import {updateRecord} from 'lightning/uiRecordApi';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

export default class KeyMethodComponent extends NavigationMixin(LightningElement) {

     @track data
     @api recordId;
     @track wireResult;
     @track draftValues=[];
    
     // Define key method component datatable coloums
     columns =  [
        { label: 'Key Method', fieldName: 'Key_Method__c'},
        { label: 'Estimated Annual Sample Volume', fieldName: 'Estimated_Annual_Sample_Volume__c',type: "number",editable:true },
        {
        type: "button", label: 'Edit', initialWidth: 80, typeAttributes: {
            name: 'Edit',
            title: 'Edit',
            disabled: false,
            value: 'edit',
            iconPosition: 'center',
            iconName:'utility:edit',
            variant:'Brand'
        }
        },
        {
        type: "button", label: 'Delete', initialWidth: 80, typeAttributes: {
            name: 'Delete',
            title: 'Delete',
            disabled: false,
            value: 'delete',
            iconPosition: 'center',
            iconName:'utility:delete',
            variant:'destructive'
        }
        }
    ];
    
    //Declear the wire method
    @wire(getKeyMethod, { recordId: '$recordId' })
     wiredResult(result){
        this.wireResult = result;
        if (result.data) {
            this.data = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }
    
    // Define the logic for onrow edit and delete button function 
    callRowAction(event){
        const recId = event.detail.row.Id;
        const actionName = event.detail.action.name;
        if (actionName === 'Edit') {
            this.handleAction(recId, 'edit');
        } else if (actionName === 'Delete') {
            this.handleDeleteRow(recId);
        } 
    }
  
    // Method to impliment inline editing on keymethod datatable
    async HandleSaveInlineEdit(event){
        const records = event.detail.draftValues.slice().map((draftValue)=>{
            const fields = Object.assign({},draftValue);
            return {fields};
        });
        this.draftValues = [];
        try{
            const recordUpdate = records.map((record)=>updateRecord(record));
            await Promise.all(recordUpdate);
            this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated',
                variant: 'success'
            })
        );
            refreshApex(this.wireResult);
           }
         catch(errorInline) {
            this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error updating or refreshing records',
                    message: errorInline.body.output.fieldErrors.Key_Method__c[0].message,
                    variant: 'error'
                })
          );
    };
    }
  
   // Method for delete button on table
    handleDeleteRow(recordIdToDelete) {
        deleteRecord(recordIdToDelete)
            .then(result => {
                this.showToast('Success!!', 'Record deleted successfully!!', 'success', 'dismissable');
                return refreshApex(this.wireResult);
            }).catch(error => {
                this.error = error;
            });
    }
  
    //Method for edit button on table
    handleAction(recordId, mode) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Key_Method__c',
                actionName: mode
            }
        })
       return refreshApex(this.wireResult);
    }
   
    //Method for toast message
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
   
    //will navigate user to key method releated detail record page when click on view all buttton on table
    navigateToRelatedList(){
          this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account_Plan__c',
                relationshipApiName: 'Key_Methods__r',
                actionName: 'view'
            },
        });
    }
    
    // will navigate user to key method new record create page layout
    navigateToNewKeyMethodPage() {
      const defaultValues = encodeDefaultFieldValues({
      Account_Plan__c :this.recordId
    });
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
        attributes: {
        objectApiName: "Key_Method__c",
        actionName: "new",
      },
      state: {
        defaultFieldValues: defaultValues,
      },
    });
  }     
}
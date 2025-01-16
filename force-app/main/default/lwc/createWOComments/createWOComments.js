import { LightningElement, wire , track  } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import COMMENT from '@salesforce/schema/Comment__c';
import {showErrorToast, showSuccessToast} from 'c/utils';

export default class CreateWOComments extends NavigationMixin(LightningElement) {

	workOrderId = null;
	currentPageReference = null; 
	recordtypeId = null;
	saveAndNew = false;
	isLoading = false;
	
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.isLoading = true;
        if(currentPageReference){
          if (currentPageReference.state.c__workOrderId) {
            this.workOrderId = currentPageReference.state.c__workOrderId;
          } else {
            this.workOrderId = currentPageReference.state.workOrderId;
          }
        }
        this.isLoading = false;
    }
     
    @wire(getObjectInfo, { objectApiName: COMMENT })
        objectInfo({data, error}) {
        if(data) {
           const rtInfos = data.recordTypeInfos;
           this.recordtypeId = Object.keys(rtInfos).find(rti => rtInfos[rti].name === 'Work Order - Manual');
         }else if(error) {
            this.ShowTostMessage('Error',error.body.message,'error')
         }
   }

   navigateToCommentRecord(event) {
	showSuccessToast("Record created successfully.");
    this.handleReset();
    if(!this.saveAndNew) {
      	this.isLoading = false;
			let commentRecordId = event.detail.id;
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: commentRecordId,
					objectApiName:'Comment__c',
					actionName: 'view'
				},
			});
		}
	}

	closeModal() {
		this.handleReset();
		this[NavigationMixin.Navigate]({
          	type: 'standard__recordPage',
          	attributes: {
				recordId: this.workOrderId,
				objectApiName:'SVMXC__Service_Order__c',
				actionName: 'view'
          },
      }); 
   } 

	handleSave() {
		this.isLoading = true;
		let isValid = this.validateInputFieldValues();
			this.saveAndNew = false;
		if (isValid) {
			this.handleRecordSave();
		} else {
		this.isLoading = false;
		return;
		}
	}

	handleRecordSave() {
		this.template.querySelector('lightning-record-edit-form').submit(this.fields);
	}

	handleSaveAndNew() {
		this.isLoading = true;
		let isValid = this.validateInputFieldValues();
		this.saveAndNew = true;
		if (isValid) {
			this.handleRecordSave();
		} else {
			this.isLoading = false;
			return;
		}
	}

    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
          '.resetName'
        );
        if (inputFields) {
          inputFields.forEach(field => {
            field.reset();
          });
        }
		this.isLoading = false;
    }

	validateInputFieldValues() {
		this.template.querySelectorAll('lightning-input-field').forEach(element => {
			element.reportValidity();
		});
  
		return this.template.querySelector(".slds-has-error");
	}
  
	handleError(event) {
		showErrorToast(event.detail.detail);
	}
}
import {
    LightningElement,
    wire,
    track
  } from 'lwc';
  import {
    NavigationMixin,
    CurrentPageReference
  } from 'lightning/navigation';
  import {
    getObjectInfo
  } from 'lightning/uiObjectInfoApi';
  import RELATED_CONTACT from '@salesforce/schema/Related_Contacts__c';
  import {showErrorToast, showSuccessToast} from 'c/utils';
  
  export default class TraineeRecordCreationComponent extends NavigationMixin(LightningElement) {
    
  
    @track traineeRecordTypeId;
    workOrderId = null;
    currentPageReference = null;
    recordtypeId = null;
  
    saveAndNew = false;
    isLoading = false;
  
      /*
       * Method Name: getStateParameters
       * Params: CurrentPageReference
       * Description: Wire Adaptor method to fetch WO Id
       *               
       */
  
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
      this.isLoading = true;
        if (currentPageReference) {
            
            if (currentPageReference.state.c__workOrderId) {
                this.workOrderId = currentPageReference.state.c__workOrderId;
            } else {
                this.workOrderId = currentPageReference.state.workOrderId;
            }
        }
        this.isLoading = false;
    }
  
    /*
       * Method Name: objectInfo
       * Params: 
       * Description: Fetch the record type Id 
       *               
    */
  
    @wire(getObjectInfo, {
        objectApiName: RELATED_CONTACT
    })
    objectInfo({
        data,
        error
    }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            this.recordtypeId = Object.keys(rtInfos).find(rti => rtInfos[rti].name === 'Trainee');
  
        } else if (error) {
            this.ShowTostMessage('Error', error.body.message, 'error')
        }
    }
  
    /*
       * Method Name: navigateToTraineeRecord
       * Params: event
       * Description: Method to navigate to the Trainee detail page
       *               
    */
  
    navigateToTraineeRecord(event) {
        showSuccessToast("Record created successfully.");
        this.handleReset();
        if (!this.saveAndNew) {
          this.isLoading = false;
            let traineeRecordId = event.detail.id;
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: traineeRecordId,
                    objectApiName: 'Related_Contacts__c',
                    actionName: 'view'
                },
            });
        }
    }
  
    /*
       * Method Name: closeModal
       * Params: event
       * Description: Method to close the popup when clicked on close button
       *               
    */
  
    closeModal() {
      this.handleReset();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.workOrderId,
                objectApiName: 'SVMXC__Service_Order__c',
                actionName: 'view'
            },
        });
    }
  
     /*
       * Method Name: handleSave
       * Params: 
       * Description: Method to save the record post validating the fields in UI
       *               
    */
  
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
  
    /*
       * Method Name: handleRecordSave
       * Params: 
       * Description: Method to submit the values from UI to create the record
       *               
    */
  
    handleRecordSave() {
  
        this.template.querySelector('lightning-record-edit-form').submit(this.fields);
    }
  
     /*
       * Method Name: handleSaveAndNew
       * Params: 
       * Description: Method called on clicking save and new button click to validate and save the trainee record
       *               
    */
  
    handleSaveAndNew() {
        let isValid = this.validateInputFieldValues();
        this.saveAndNew = true;
        if (isValid) {
            this.handleRecordSave();
        } else {
            return;
        }
    }
  
    /*
       * Method Name: handleSaveAndNew
       * Params: 
       * Description: Method to reset all the field values except the WO field since it is a child record creation
       *               
    */
  
    handleReset() {
        const inputFields = this.template.querySelectorAll(
            '.resetName'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }
  
     /*
       * Method Name: validateInputFieldValues
       * Params: 
       * Description: Method to validate the fields like the format and empty check , so that the 
       * record with null values are not saved for mandatory fields
       *               
    */
  
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
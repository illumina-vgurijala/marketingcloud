import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import enterTerminationDate from '@salesforce/label/c.UI_Enter_Termination_Date';
import agreementEndDate from '@salesforce/label/c.UI_Agreement_End_Date';
import pickTerminationDate from '@salesforce/label/c.UI_Pick_Termination_Date';
import updateTerminationDateButton from '@salesforce/label/c.UI_Button_Update_Termination_Date';
import invalidDateMessage from '@salesforce/label/c.UI_Message_Invalid_Date';
import invalidTerminateDateMessage from '@salesforce/label/c.UI_Message_Invalid_Termination_Date';
import successLabelFuture from '@salesforce/label/c.UI_Message_Terminate_Date_Updated';
import successLabelNow from '@salesforce/label/c.UI_Message_Terminate_Request_Sent';
import successLabelBlankDate from '@salesforce/label/c.UI_Message_Termination_Date_Updated';
import updateTerminationDate from '@salesforce/apex/ApttusAgreementValidateController.updateTerminationDateAgreement';
import DATE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Termination_Date__c';
import ENDDATE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c';
import { callServer,showErrorToast,showSuccessToast} from 'c/utils';

export default class AutoTerminateAgreement extends NavigationMixin(LightningElement) {

    @api agreementid;
    @track isError = false;
    @track objAgreement;
    @track enddatefield;
    @track datefield;
    @track disableButton = false;
    @track loadInput = true;
    @track todaysDate;
    @track selectedDateInput;
    @track showSpinner = false;

    label = {
      enterTerminationDate,
      agreementEndDate,
      pickTerminationDate,
      updateTerminationDateButton,
      invalidDateMessage,
      invalidTerminateDateMessage,
      successLabelFuture,
      successLabelNow,
      successLabelBlankDate
    }

    @wire(getRecord, { recordId: '$agreementid' , fields: [DATE_FIELD,ENDDATE_FIELD] })
    wiredRecord({ error, data }) {
    if (error) { 
      this.isError = true;
      }
      else if(data)
      {
        this.objAgreement = data;
        this.enddatefield = this.objAgreement.fields.Apttus__Contract_End_Date__c.value;
        this.datefield = this.objAgreement.fields.Apttus__Termination_Date__c.value;
        this.getDateValues();
      }
    }

    getDateValues()
    {
      let today = new Date();
      let newDate = today.getDate();
      let newMonth = today.getMonth();
      let newMonthNumber = Number(newMonth) + 1;
      if(newDate < 10)
      {
          newDate = '0' + newDate;
      }
      if(newMonthNumber < 10)
      {
        newMonthNumber = '0' + newMonthNumber;
      }
      let todayDate = today.getFullYear() + '-' + newMonthNumber + '-' + newDate;

        this.todaysDate = todayDate;
        if(!this.datefield)
        {
          this.datefield = todayDate;
        }
        this.selectedDateInput = this.datefield;
    }

    validateDate(event)
    {
      let selectedDate = event.currentTarget.value;
      this.selectedDateInput = selectedDate;
      this.validateDateInputs();      
    }

    validateDateInputs()
    {
        let inputCmp = this.template.querySelector(".inputtermdate");
        let haserror = inputCmp.checkValidity();
        
        if((this.selectedDateInput != '') && (this.selectedDateInput < this.todaysDate || this.selectedDateInput > this.enddatefield))
        {
            showErrorToast(this.label.invalidTerminateDateMessage);
            this.disableButton = true;
        }
        else if(!haserror)
        {
            showErrorToast(this.label.invalidDateMessage);
            this.disableButton = true;
        } 
        else
        {
            this.disableButton = false;
            let inputCmp = this.template.querySelector(".inputtermdate");
            inputCmp.reportValidity();
            return true;
        }
    }

    updateTerminationDate()
    {
       let isValid = this.validateDateInputs();
       if(isValid)
       {
       this.showSpinner = true;
       if(!this.selectedDateInput)
       {
         this.selectedDateInput = '#@#@';
       }
       callServer(updateTerminationDate,{agreementId:this.agreementid ,termDate: this.selectedDateInput}
        ,result => {
        if(result === 'true')
        {
          if(this.selectedDateInput === this.todaysDate)
          {
            this.showSpinner = false;
            const fireParentAuraMethod = new CustomEvent('fireparentmethod', {});
            this.dispatchEvent(fireParentAuraMethod);
          }
          else
          {
            this.showSpinner = false;
            if(this.selectedDateInput === '#@#@')
            {
              showSuccessToast(this.label.successLabelBlankDate);
            }
            else
            {
              showSuccessToast(this.label.successLabelFuture);
            }
            this.navigateToViewAgreementPage();
          }
        }
        else
        {
          this.showSpinner = false;
          showErrorToast(result);  
        }
       },error => {
        this.showSpinner = false;
        showErrorToast(error);
      });
    }
  }

    navigateToViewAgreementPage() {
      this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
              recordId: this.agreementid,
              objectApiName: 'Apttus__APTS_Agreement__c',
              actionName: 'view'
          },
      });
  }

  }
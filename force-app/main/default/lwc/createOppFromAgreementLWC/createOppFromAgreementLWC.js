/**
*    @author        Tapas Chakraborty
*    @date          04-Sep-2020
*    @description   Initial Version: DCP-40569 create  Standing Quote Opportunity from Standing Quote Agreement
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty              04-Sep-2020         Initial Version: DCP-40569 create  Standing Quote Opportunity from Standing Quote Agreement
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------
*/

import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FISCALQUARTER from '@salesforce/schema/Opportunity.Fiscal_Quarter__c';
import AMOUNT from '@salesforce/schema/Opportunity.Amount';
import CLOSEDATE from '@salesforce/schema/Opportunity.CloseDate';
import NAME from '@salesforce/schema/Opportunity.Name';
import ACCOUNTID from '@salesforce/schema/Opportunity.AccountId';
import RELATEDAGREEMENT from '@salesforce/schema/Opportunity.Related_Agreement__c';
import STAGENAME from '@salesforce/schema/Opportunity.StageName';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import OpportunityRTStandingQuote from '@salesforce/label/c.OpportunityRTStandingQuote';
import helpTextForeCastAmountOnOpportunity from '@salesforce/label/c.UI_Msg_HelpTextForeCastAmountOnOpportunity';

const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const standingQuoteRecordType = 'Standing Quote';

export default class CreateOppFromAgreementLWC extends NavigationMixin(LightningElement) {
    label = {OpportunityRTStandingQuote,helpTextForeCastAmountOnOpportunity};
    standingQuoteRecordType = standingQuoteRecordType;

    @api agreementID = '';
    @api agreementAccountId = '';
    @api agreementAccountName = '';
    @api agreementName = '';

    @track booLoading = false;
    @track recordTypeId;
    @track userAmount;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfoFunction(result){
        if(result.data){
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name == this.standingQuoteRecordType);
        }
        else if(result.error){
            console.log('error '+result.error);
        }
    }

    modalName = 'New Opportunity : Standing Quote';
    opportunityId;
    opportunityName = '';
    fiscalquarter = FISCALQUARTER.fieldApiName;
    amount = AMOUNT.fieldApiName;
    
    handleAmountChange(event){
        this.userAmount = event.target.value;
    }

    handleSubmit(event) {
        try {
            this.booLoading = true;
            event.preventDefault();       // stop the form from submitting
            const fields = event.detail.fields;
            
            let objDate = new Date();
            objDate.setDate(objDate.getDate() + 2);
            fields[CLOSEDATE.fieldApiName] = objDate.getFullYear() + '-' + (objDate.getMonth() + 1) + '-' + objDate.getDate();//dummy value in closedate for insert; in beforeinsert trigger actual closedate based on Quarter will be added
            fields[NAME.fieldApiName] = 'Standing Quote Opportunity';//same reason as for CloseDate above
            fields[ACCOUNTID.fieldApiName] = this.agreementAccountId;
            fields[RELATEDAGREEMENT.fieldApiName] = this.agreementID;
            fields[STAGENAME.fieldApiName] = 'Finalize';
            fields[AMOUNT.fieldApiName] = this.userAmount;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
        catch (err) {
            console.log('THe error in handleSubmit ' + err.message);
        }
    }

    handleSuccess(event) {
        this.booLoading = false;
        this.opportunityId = event.detail.id;
        this.opportunityName = event.detail.fields.Name.value;
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Opportunity ' + '\"' + this.opportunityName + '\"' + ' was created.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunityId,
                objectApiName: 'Opportunity', 
                actionName: 'view'
            }
        });
    }

    handleEditOnError(event) {
        try {
            console.log('error is '+JSON.stringify(event));
            this.booLoading = false;
            let errorString = '' ;
            for (const error of event.detail.output.errors) {
                errorString += `${error.message}, `;
            }
            errorString = errorString.substring(0,errorString.length - 2);
            const errorEvt = new ShowToastEvent({
                title: "Error",
                message: errorString,
                variant: "error",
                mode: "sticky"
            });
            this.dispatchEvent(errorEvt);
        }
        catch (err) {
            console.log('The error is ' + err.message);
        }
    }

    closeModal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.agreementID,
                objectApiName: 'Apttus__APTS_Agreement__c', 
                actionName: 'view'
            }
        });
    }
}
import { LightningElement, api, track } from 'lwc';
import { genericEvent, isBlank, showErrorToast } from 'c/utils';
const EVENT_OOC_CHANGE = 'openofferchange';

export default class OpenOfferComparisonCustomerDetails extends LightningElement {
    @api mapLabels;
    @api purchasesProductsShippingOptions;
    @api forProfitCompanyOptions;
    @api clinicalOncologyScreeningDxTestingOptions;
    @api lstOncologyLabManufacturerComparisonOptions;
    @api lstSequencingLiquidBxCancerScreening; //DCP-56397
    @api componentDisabled = false;
    @api conditionalReadonly = false;
    
    @track accountDetails;
    
    @api 
    get accountRecord() {
        return this.accountDetails;
    }
    set accountRecord(value) {
        this.accountDetails = JSON.parse(JSON.stringify(value));
    }

    sendEvent(returnObject, eventName){         
        genericEvent(eventName,returnObject,this);            
    }

    handleChange(event) {
        const targetName = event.target.name;
        const targetValue = event.target.value;
        const checkboxtargetValue = event.target.checked;

        if(targetName === this.mapLabels.UI_Label_Purchases_Products_Shipping_to_U_S) {
            this.accountDetails.Purchases_Products_Shipping_to_U_S__c = targetValue;
        }
        if(targetName === this.mapLabels.UI_Label_For_Profit_Company) {
            this.accountDetails.For_Profit_Company__c = targetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Clinical_Oncology_Screening_Dx_Testing) {
            this.accountDetails.Clinical_Oncology_Screening_Dx_Testing__c = targetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Oncology_Lab_Manufacturer_Comparison) {
            this.accountDetails.Oncology_Lab_Manufacturer_Comparison__c = targetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Signed_Open_Offer) {
            this.accountDetails.Signed_Open_Offer__c = checkboxtargetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Open_Offer_Comparison_Customer) {
            this.accountDetails.Open_Offer_Comparison_Customer__c = checkboxtargetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Eligible_To_Estimate_Consumable_Spend) {
            this.accountDetails.Eligible_To_Estimate_Consumable_Spend__c = checkboxtargetValue;
        }
        //DCP-56397
        if(targetName === this.mapLabels.UI_Label_Sequencing_Liquid_Bx_Cancer_Screening) {
            this.accountDetails.Sequencing_Liquid_Bx_Cancer_Screening__c = targetValue;
        }

        const returnObject = this.generateObjectWithUpdatedDataForEvent();
        this.sendEvent(returnObject,EVENT_OOC_CHANGE); 
    }
    
    generateObjectWithUpdatedDataForEvent() {
        const objDetails = Object.create({});
        objDetails.Purchases_Products_Shipping_to_U_S__c = this.accountDetails.Purchases_Products_Shipping_to_U_S__c;
        objDetails.For_Profit_Company__c = this.accountDetails.For_Profit_Company__c;
        objDetails.Clinical_Oncology_Screening_Dx_Testing__c = this.accountDetails.Clinical_Oncology_Screening_Dx_Testing__c;
        objDetails.Oncology_Lab_Manufacturer_Comparison__c = this.accountDetails.Oncology_Lab_Manufacturer_Comparison__c;
        objDetails.Signed_Open_Offer__c = this.accountDetails.Signed_Open_Offer__c;
        objDetails.Open_Offer_Comparison_Customer__c = this.accountDetails.Open_Offer_Comparison_Customer__c;
        objDetails.Eligible_To_Estimate_Consumable_Spend__c = this.accountDetails.Eligible_To_Estimate_Consumable_Spend__c;
        objDetails.Sequencing_Liquid_Bx_Cancer_Screening__c = this.accountDetails.Sequencing_Liquid_Bx_Cancer_Screening__c //DCP-56397

        return objDetails;
    }

    @api
    validateOpenOfferFields(booDoSubmit, boolHideComparisonCustomerFields) {        
        const boolOpenOfferFieldsBlank =
            isBlank(this.accountDetails.For_Profit_Company__c) ||
            isBlank(this.accountDetails.Purchases_Products_Shipping_to_U_S__c) ||
            isBlank(this.accountDetails.Clinical_Oncology_Screening_Dx_Testing__c);
        
        const boolSequencingCancerScreeningFieldBlank = this.accountDetails.Clinical_Oncology_Screening_Dx_Testing__c === this.mapLabels.UI_Label_Yes && isBlank(this.accountDetails.Sequencing_Liquid_Bx_Cancer_Screening__c);

        if (booDoSubmit) {
            if(boolHideComparisonCustomerFields) {
                return true;
            }
            else if(boolOpenOfferFieldsBlank) {
                showErrorToast(this.mapLabels.UI_Error_Message_ERP_Submit_Error,'pester');
                return false;
            }            
        }
        else if(boolSequencingCancerScreeningFieldBlank){
            showErrorToast(this.mapLabels.UI_Error_Message_Sequencing_Liquid_Bx_Cancer_Screening_Required,'pester');
            return false;
        }
        return true;
    }
}
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord , getRecordNotifyChange } from 'lightning/uiRecordApi';
import loadPage from '@salesforce/apex/SegmentationSelectionController.loadPage';
import saveMarketSegments from '@salesforce/apex/SegmentationSelectionController.saveMarketSegments';
import { NavigationMixin } from 'lightning/navigation';
import ID_FIELD from '@salesforce/schema/Account.Id';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import COUNTRY_CODE_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import ACCOUNT_STATUS_FIELD from '@salesforce/schema/Account.Account_Status__c';
import FOR_PROFIT_COMPANY_FIELD from '@salesforce/schema/Account.For_Profit_Company__c';
import PURCHASES_PRODUCTS_SHIPPING_FIELD from '@salesforce/schema/Account.Purchases_Products_Shipping_to_U_S__c';
import CLINICAL_ONCOLOGY_SCREENING_FIELD from '@salesforce/schema/Account.Clinical_Oncology_Screening_Dx_Testing__c';
import ONCOLOGY_LAB_MANUFACTURER_COMPARISON_FIELD from '@salesforce/schema/Account.Oncology_Lab_Manufacturer_Comparison__c';
import SIGNED_OPEN_OFFER_FIELD from '@salesforce/schema/Account.Signed_Open_Offer__c';
import OPEN_OFFER_COMPARISON_CUSTOMER_FIELD from '@salesforce/schema/Account.Open_Offer_Comparison_Customer__c';
import ELIGIBLE_TO_ESTIMATE_CONSUMABLE_SPEND_FIELD from '@salesforce/schema/Account.Eligible_To_Estimate_Consumable_Spend__c';
import CLINICAL_TYPE from '@salesforce/schema/Account.Clinical_Type__c';
import CUSTOMER_SUB_TYPE_FIELD from '@salesforce/schema/Account.Customer_Sub_Type__c';
import CUSTOMER_TYPE_FIELD from '@salesforce/schema/Account.Customer_Type__c';
import MARKET_SEGMENT from '@salesforce/schema/Account.Market_Segment__c';
import CHANNEL_PARTNER_TYPE from '@salesforce/schema/Account.Channel_Partner_Type__c';
import RECORDTYPEID_FIELD from '@salesforce/schema/Account.RecordTypeId';
import SEQUENCING_LIQUID_BX_CANCER_SCREENING_FIELD from '@salesforce/schema/Account.Sequencing_Liquid_Bx_Cancer_Screening__c'; //DCP-56397
import { isEmpty, isNull, isBlank, consoleError,showErrorToast, callServer, consoleLog } from 'c/utils';

const FIELDS = [ID_FIELD,NAME_FIELD,COUNTRY_CODE_FIELD,FOR_PROFIT_COMPANY_FIELD,PURCHASES_PRODUCTS_SHIPPING_FIELD,CLINICAL_ONCOLOGY_SCREENING_FIELD,ONCOLOGY_LAB_MANUFACTURER_COMPARISON_FIELD,SIGNED_OPEN_OFFER_FIELD,OPEN_OFFER_COMPARISON_CUSTOMER_FIELD,CLINICAL_TYPE,CUSTOMER_SUB_TYPE_FIELD,CUSTOMER_TYPE_FIELD,MARKET_SEGMENT,CHANNEL_PARTNER_TYPE,RECORDTYPEID_FIELD,ELIGIBLE_TO_ESTIMATE_CONSUMABLE_SPEND_FIELD,SEQUENCING_LIQUID_BX_CANCER_SCREENING_FIELD,ACCOUNT_STATUS_FIELD];

export default class SegmentationSelectionLWC extends NavigationMixin(LightningElement) {    
    @api recordId;    
    @track lstCustomerSubTypePicklistValues = [];
    @track lstOriginalMarketSegments = [];
    @track lstSequencingLiquidBxCancerScreening = []; //DCP-56397
    @track lstMarketSegments;
    @track accountRecord;
    @track originalAccountRecord;
    booCheckPermissionForReadOnly = true;    
    lstMarketSegmentPicklistValues = [];    
    lstClinicalTypePicklistValues = [];
    lstCustomerTypePicklistValues = [];        
    lstPurchasesProductsShippingToUS = [];
    lstForProfitCompany = [];
    lstClinicalOncologyScreeningDxTesting = [];
    lstOncologyLabManufacturerComparison = [];     
    mapClinicalOncologyToSequencingLiquidBx = []; //DCP-56397   
    marketSegmentToSubSegment = {};
    customerTypeToSubType = {};        
    mapLabels;
    wrapDummy = {};    
    submitURL;
    accountERPId;
    boolHideComparisonCustomerFields;
    conditionalReadOnlyForOO;
    booReadOnly;    
    booDisabled = false;
    boolHideSubmit = true;       
    boolUS = false;
    recordTypeDeveloperName;
    isSpinnerActive = true;
	boolUnverified = false;
    boolUSUnverified = true;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS }) 
    wiredAccount({data,error}) {
        if(data) {            
            this.accountRecord = this.generateAccountDetails(data);             
            this.originalAccountRecord = JSON.parse(JSON.stringify(this.accountRecord));
            this.initializeComponentData();
        }
        if(error) {
            consoleError('error in wire service in segmentationSelectionLWC ::: ', error);
            this.isSpinnerActive = false;  
        }
    }

    @api 
    get booCheckPermission() {
        return this.booCheckPermissionForReadOnly;
    }
    set booCheckPermission(value) {
        this.booCheckPermissionForReadOnly = value;
    }

    generateAccountDetails(data) {        
        const fieldValuesMap = data.fields;
        return Object.keys(fieldValuesMap).reduce((next, key) => {
            return { ...next, [key]: fieldValuesMap[key].value };
        },{});                
    }

    initializeComponentData() {
        callServer(loadPage, {
            strAccountId : this.recordId
        }, result => {          
                let response = JSON.parse(result);
                consoleLog('response in initializeComponentData ::: ',response);
                this.mapLabels = response.mapLabels;                
                this.lstMarketSegmentPicklistValues = this.generatePicklistOptions(response.lstMarketSegmentPicklistValues.filter(wrapPickVal => wrapPickVal.strKey !== 'Multiple' ));                
                
                let multiSelect = {};
                Object.keys(response.marketSegmentToSubSegment).forEach((attr)=>{
                    let lstValues = [];
                    response.marketSegmentToSubSegment[attr].forEach((pickVal)=>{
                        if(isBlank(pickVal.strKey)) return;
                        let multiVal ={'label': pickVal.strValue,'value' : pickVal.strKey};
                        lstValues.push(multiVal);
                    });
                    multiSelect[attr] = lstValues;
                });

                this.marketSegmentToSubSegment = multiSelect;
                this.lstClinicalTypePicklistValues = this.generatePicklistOptions(response.lstClinicalTypePicklistValues);
                this.lstCustomerTypePicklistValues = this.generatePicklistOptions(response.lstCustomerTypePicklistValues);
                this.customerTypeToSubType = response.customerTypeToSubType;
                this.lstCustomerSubTypePicklistValues = this.generatePicklistOptions(this.generateDependentPicklistOptions(this.customerTypeToSubType,this.accountRecord.Customer_Type__c));
                this.lstPurchasesProductsShippingToUS = this.generatePicklistOptions(response.lstPurchasesProductsShippingToUS);
                this.lstForProfitCompany = this.generatePicklistOptions(response.lstForProfitCompany);
                this.lstClinicalOncologyScreeningDxTesting = this.generatePicklistOptions(response.lstClinicalOncologyScreeningDxTesting);
                this.lstOncologyLabManufacturerComparison = this.generatePicklistOptions(response.lstOncologyLabManufacturerComparison);                
                this.mapClinicalOncologyToSequencingLiquidBx = response.mapClinicalOncologyToSequencingLiquidBx; //DCP-56397
                this.lstSequencingLiquidBxCancerScreening = this.generatePicklistOptionsForSequencingLiqPicklist(this.mapClinicalOncologyToSequencingLiquidBx,this.accountRecord.Clinical_Oncology_Screening_Dx_Testing__c);   //DCP-56397
                this.wrapDummy = response.dummyMarketSegment;
                this.lstMarketSegments = this.generateMarketSegmentList(response.lstMarketSegments);
                this.lstOriginalMarketSegments = JSON.parse(JSON.stringify(response.lstMarketSegments));
                this.submitURL = response.mapLabels.SegmentSubmitURL;                
                this.accountERPId = response.CustomerERPID;
                this.recordTypeDeveloperName = response.objAccount.RecordType.DeveloperName;
                this.boolHideComparisonCustomerFields = response.boolComparisonCustomerFieldsFLS;
                this.conditionalReadOnlyForOO = response.conditionalReadOnlyAccessForOO;
                this.booReadOnly = this.booCheckPermissionForReadOnly ? !response.booHasEditPermission : false;
                this.boolHideSubmit = response.DisplaySubmitButton ? false : true ;
                this.boolUS = this.accountRecord.BillingCountryCode === this.mapLabels.US ? true : false;  
				this.boolUnverified = this.accountRecord.Account_Status__c == 'Unverified';
                this.boolUSUnverified = this.boolUS && this.boolUnverified;
                if(!response.booObjectHasEditPermission || this.boolHideComparisonCustomerFields) {                                
                    this.booDisabled = true;
                    this.booReadOnly = true;                
                }                        
                this.isSpinnerActive = false;                 
            }, error => {                
                consoleError('Error in server call ::: ', JSON.stringify(error));
                this.isSpinnerActive = false;                                
            }            
        );
    }
    
    generatePicklistOptions(data) {
        return data?.map( item => ({ 'label' : item.strValue, 'value' : item.strKey }));
    }

    generateDependentPicklistOptions(mapDependencies,strSelectedValue) {        
        return mapDependencies[strSelectedValue];
    }
    
    generateMarketSegmentList(data) {        
        return data.map((item, index) => {
            const container = JSON.parse(JSON.stringify(item));
            container.index = index;
            return container;
        });
    }    

    generatePicklistOptionsForSequencingLiqPicklist(data, value) {        
        let picklistValues = this.generateDependentPicklistOptions(data,value);
        picklistValues = this.generatePicklistOptions(picklistValues);
        if(value === this.mapLabels.UI_Label_Yes) {
            return picklistValues;
        }

        if(isNull(picklistValues)) { return picklistValues;}
        
        return picklistValues.filter(item => item.label !== this.mapLabels.UI_Label_Comparison_Customer_Information);
    }

    handleChange(event) {
        const targetName = event.target.name;
        const targetValue = event.target.value;
        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Clinical_Type) {
            this.accountRecord.Clinical_Type__c = targetValue;
        }
        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Customer_Type) {
            this.accountRecord.Customer_Type__c = targetValue;
            this.accountRecord.Customer_Sub_Type__c = null;
            this.lstCustomerSubTypePicklistValues = this.generatePicklistOptions(this.generateDependentPicklistOptions(this.customerTypeToSubType,this.accountRecord.Customer_Type__c));
        }
        if(targetName === this.mapLabels.UI_Label_Segmentation_Selection_Field_Customer_Sub_Type) {
            this.accountRecord.Customer_Sub_Type__c = targetValue;
        }        
    }

    handleMarketSegmentChange(event) {
        const {index,strMarketSegment,lstSubSegments,decAllocation,booDelete} = event.detail;        
        const elementIndex = this.lstMarketSegments.findIndex(item => item.index === index);                
        
        this.lstMarketSegments[elementIndex].strMarketSegment = strMarketSegment;
        this.lstMarketSegments[elementIndex].lstSubSegments = lstSubSegments;
        this.lstMarketSegments[elementIndex].decAllocation = decAllocation;
        this.lstMarketSegments[elementIndex].booDelete = booDelete;                
    }

    addRow(event) {
        if(this.booReadOnly){
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Market_Segment_Locked);
            return;
        }      
        let dummy = JSON.parse(JSON.stringify(this.wrapDummy));
        dummy.index = this.lstMarketSegments.length;
        this.lstMarketSegments.push(dummy);             
    }

    evenSplit(event) {
        const lstShownRecords = this.lstMarketSegments.filter(item => !item.booDelete );
        
        if(isEmpty(lstShownRecords)) { return; }

        let intEvenAllocation = parseFloat((100/lstShownRecords.length).toFixed(2));        
        
        let marketSegmentsCopy = JSON.parse(JSON.stringify(this.lstMarketSegments));                 
        marketSegmentsCopy.forEach((element,index) => {            
            marketSegmentsCopy[index].decAllocation = intEvenAllocation;            
        });  
        this.lstMarketSegments = marketSegmentsCopy;                   
    }

    handleSave(event) {
        this.validateBeforeSave(false);
    }
    
    handleClose(event) {
        this.showInfoSection = false;
    }

    @api
    validateBeforeSave(boolDoSubmit) {                               
        if(this.booReadOnly) {
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Account_Locked);
            return false;
        }

        let skipSegmentValidation = 
            this.recordTypeDeveloperName === this.mapLabels.AccountRecordTypeDeveloperNameChannelPartnerProspect ||
            (this.recordTypeDeveloperName === this.mapLabels.AccountProspect && !isBlank(this.accountRecord.Channel_Partner_Type__c));
            
        const lstShownRecords = this.lstMarketSegments.filter(marketSegment => !marketSegment.booDelete);        
        const lstMethodsForEvaluation = [
            { methodName : 'validateOpenOfferFields' , params : { boolDoSubmit }},
            { methodName : 'validateAdditionalSegmentationFields' , params : { boolDoSubmit, skipSegmentValidation }},
            { methodName : 'validateRowComponentFields', params : { boolDoSubmit, skipSegmentValidation, lstShownRecords }}            
        ];
        
        let boolIsValid = true;
        
        lstMethodsForEvaluation.forEach(method => {                
            boolIsValid = this[method.methodName]({...method.params, boolIsValid });
        });  
       
        consoleLog('boolIsValid before returing to caller ::: ',boolIsValid);
        if(!boolIsValid) { return false; }
        
        this.doSave(this.accountRecord,this.lstMarketSegments,lstShownRecords);
        
        return true;
    }

    validateRowComponentFields({boolDoSubmit,skipSegmentValidation,lstShownRecords,boolIsValid}) {         
        if(!boolIsValid) { return boolIsValid; }

        const {totalAllocation, booRequiredError} = this.calculateAllocation();        
        if(booRequiredError) {
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Complete_Required_fields);
            return false;
        }
        
        if(boolDoSubmit && isEmpty(lstShownRecords) && !skipSegmentValidation) {
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Submit_Error);
            return false;
        }
        
        if(Math.round(totalAllocation) !== 100 && !isEmpty(lstShownRecords)) {
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Allocation_Total);
            return false;
        }
        
        return true;
    }

    validateOpenOfferFields({boolDoSubmit,boolIsValid}) {        
        if (this.accountRecord.BillingCountryCode !== this.mapLabels.US) { return true; }
        
        if(!boolIsValid) { return boolIsValid; }
        
        const openOfferComponent = this.template.querySelector('c-open-offer-comparison-customer-details');
        if(isNull(openOfferComponent)) { return true; }
        
        return openOfferComponent.validateOpenOfferFields(boolDoSubmit, this.boolHideComparisonCustomerFields)                
    }

    validateAdditionalSegmentationFields({boolDoSubmit,skipSegmentValidation,boolIsValid}) {        
        if(!boolIsValid) { return boolIsValid; }

        let boolAreAnySegmentationFieldsBlank = isBlank(this.accountRecord.Clinical_Type__c) || isBlank(this.accountRecord.Customer_Type__c) || isBlank(this.accountRecord.Customer_Sub_Type__c);
        if (boolDoSubmit && !skipSegmentValidation && boolAreAnySegmentationFieldsBlank) {
            this.showError(this.mapLabels.UI_Error_Message_Segmentation_Selection_Submit_Error);
            return false;
        }
        return true;
    }

    calculateAllocation() {
        const childComponents = this.template.querySelectorAll('c-segmentation-row-component-l-w-c');
        
        let booRequiredError = false;
        let totalAllocation = 0;
        this.lstMarketSegments.forEach((marketSegment) => {
            if(marketSegment.booDelete) { return; }

            if(isNull(marketSegment.strMarketSegment) || isNull(marketSegment.decAllocation)){
                booRequiredError = true;
                childComponents.forEach(component => {
                    if(isNull(component.strMarketSegment) || isNull(component.decAllocation)) {
                        component.validateInputFields();                         
                    }
                });                                   
            }
               
            if(!isNaN(marketSegment.decAllocation)) {
                totalAllocation += parseFloat(marketSegment.decAllocation);
            }
        });

        return { totalAllocation, booRequiredError };
    }
    
    doSave(accountRecord,lstMarketSegments,lstShownRecords) {        
        const mapAccountFieldValues = Object.create({});        
        mapAccountFieldValues.Id = this.recordId;
        mapAccountFieldValues.For_Profit_Company__c = accountRecord.For_Profit_Company__c;
        mapAccountFieldValues.Purchases_Products_Shipping_to_U_S__c = accountRecord.Purchases_Products_Shipping_to_U_S__c;
        mapAccountFieldValues.Clinical_Oncology_Screening_Dx_Testing__c = accountRecord.Clinical_Oncology_Screening_Dx_Testing__c;
        mapAccountFieldValues.Clinical_Type__c = accountRecord.Clinical_Type__c;
        mapAccountFieldValues.Customer_Type__c = accountRecord.Customer_Type__c;
        mapAccountFieldValues.Customer_Sub_Type__c = accountRecord.Customer_Sub_Type__c;
        mapAccountFieldValues.Sequencing_Liquid_Bx_Cancer_Screening__c = accountRecord.Sequencing_Liquid_Bx_Cancer_Screening__c; //DCP-56397
        mapAccountFieldValues.Is_Updated_By_System__c = true;

        if(!this.conditionalReadOnlyForOO) {
            mapAccountFieldValues.Signed_Open_Offer__c = accountRecord.Signed_Open_Offer__c;
            mapAccountFieldValues.Open_Offer_Comparison_Customer__c = accountRecord.Open_Offer_Comparison_Customer__c;
            mapAccountFieldValues.Eligible_To_Estimate_Consumable_Spend__c = accountRecord.Eligible_To_Estimate_Consumable_Spend__c;
            mapAccountFieldValues.Oncology_Lab_Manufacturer_Comparison__c = accountRecord.Oncology_Lab_Manufacturer_Comparison__c;
        }

        let lstSaveRecords = lstMarketSegments.filter(record => !isNull(record.strRecordId) || !record.booDelete); //Remove items added on the fly that were removed from UI, so no need to delete them from database
        
        const recordInput = { fields : {...mapAccountFieldValues}}

        consoleLog('recordInput for saving account & segment record::: ',JSON.stringify(recordInput));  
        this.isSpinnerActive = true;      
        updateRecord(recordInput)
            .then(() => {
                consoleLog('Successfully updated account. Now updating market segments.');                                
                this.saveMarketSegmentRecords(lstSaveRecords);
            })
            .catch(error => {
                consoleError('error in updateRecord ::: ',JSON.stringify(error));
                this.isSpinnerActive = false;
                this.showError(error.body.message);   
            });
    }

    saveMarketSegmentRecords(lstMarketSegments) {
        if(isEmpty(lstMarketSegments)) { return; }
        
        callServer(saveMarketSegments, {            
            strAccount : this.recordId,
            strJSON : JSON.stringify(lstMarketSegments)
        }, result => { 
            this.isSpinnerActive = false;
            getRecordNotifyChange([{recordId: this.recordId}]);
        }, error => {
            consoleError('Error saving Market Segment record ::: ',JSON.stringify(error));
            this.lstMarketSegments = JSON.parse(JSON.stringify(lstMarketSegments));
            this.isSpinnerActive = false;  
        });
    }

    handleCancel(event) {
        this.lstMarketSegments = JSON.parse(JSON.stringify(this.lstOriginalMarketSegments));
        this.accountRecord = JSON.parse(JSON.stringify(this.originalAccountRecord));
        this.lstCustomerSubTypePicklistValues = this.generatePicklistOptions(this.generateDependentPicklistOptions(this.customerTypeToSubType,this.accountRecord.Customer_Type__c));
        this.lstSequencingLiquidBxCancerScreening = this.generatePicklistOptions(this.generateDependentPicklistOptions(this.mapClinicalOncologyToSequencingLiquidBx,this.accountRecord.Clinical_Oncology_Screening_Dx_Testing__c));  //DCP-56397
    }

    handleNavigate(event) {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.submitURL + this.accountERPId
            }
        });
    }
    
    handleOpenOfferSectionChange(event) {        
        const details = event.detail;
        const openOfferFieldValues = Object.keys(details).reduce((next, key) => {
            return { ...next, [key]: details[key] };
        },{});

        this.accountRecord = {...this.accountRecord, ...openOfferFieldValues };

        this.accountRecord.Sequencing_Liquid_Bx_Cancer_Screening__c = isNull(this.accountRecord.Clinical_Oncology_Screening_Dx_Testing__c) || this.accountRecord.Clinical_Oncology_Screening_Dx_Testing__c === 'No' ? null : this.accountRecord.Sequencing_Liquid_Bx_Cancer_Screening__c;
                           
        this.lstSequencingLiquidBxCancerScreening = this.generatePicklistOptionsForSequencingLiqPicklist(this.mapClinicalOncologyToSequencingLiquidBx,this.accountRecord.Clinical_Oncology_Screening_Dx_Testing__c); //DCP-56397
                                         
    }

    showError(strErrorMessage) {
        showErrorToast(strErrorMessage,'pester');
    }
}

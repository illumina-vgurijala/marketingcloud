import { LightningElement ,api,track,wire} from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import OBJ_NAME from '@salesforce/schema/Competitive_Complementary_Technology__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from "lightning/navigation";
import { consoleLog, consoleError, showSuccessToast, showErrorToast} from 'c/utils';
import getObjName from '@salesforce/apex/CompetitiveDataRollUpSummaryCtrl.getObjectNameById';

import COMP_NAME_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.CompetitorName__c';
import CATEGORY_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Category__c';
import PRODUCT_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.ProductName__c';
import COMP_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Company_Other__c';
import OUTSOURCED_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Outsourced_Service_Provider__c';
import CAT_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Category_Other__c';
import PROD_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Name_Other__c';
import COMP_NOTES_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Details_Comments__c';

//account fields
import ACCOUNT_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Account__c';
import NUM_UNITS_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Number_Of_Units__c';
import USAGE_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Is_In_Use__c';

//opportunity fields
import OPP_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Opportunity_Name__c';
import POSITIONING_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Competitive_Positioning__c';
import PRIMARY_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Primary_Competitor__c';
import GB_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Dollar_Per_Gb__c';
import MILLION_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Dollar_Per_Million_Reads__c';

// labels
import lblHeader from '@salesforce/label/c.CCTNewFormHeader';
import lblOppSeparator from '@salesforce/label/c.CCTOpporunityCostSeparator';

const ACCOUNT = 'Account';
const OPPORTUNITY = 'Opportunity';

const ACCOUNT_REQUEST_FIELDS = [ACCOUNT_FIELD, NUM_UNITS_FIELD, USAGE_FIELD, COMP_NAME_FIELD, CATEGORY_FIELD, PRODUCT_FIELD, COMP_OTHER_FIELD, OUTSOURCED_FIELD, CAT_OTHER_FIELD, PROD_OTHER_FIELD, COMP_NOTES_FIELD];
const OPPORTUNITY_REQUEST_FIELDS = [OPP_FIELD, POSITIONING_FIELD, PRIMARY_FIELD, GB_FIELD, MILLION_FIELD, COMP_NAME_FIELD, CATEGORY_FIELD, PRODUCT_FIELD, COMP_OTHER_FIELD, OUTSOURCED_FIELD, CAT_OTHER_FIELD, PROD_OTHER_FIELD, COMP_NOTES_FIELD];

const generateField = (id, fieldName, isSeparator=false, isDependencySelect=false, shouldDisplay=true, value=null, disabled = false, size=6) => {
    return {
        id:id, 
        name: fieldName, 
        isSeparator: isSeparator,
        isDependencySelect: isDependencySelect, 
        shouldDisplay: shouldDisplay, 
        value: value, 
        disabled: disabled,
        size: size
    };
}

const generateFormField = (id, fieldName, disabled=false, value=null, size=6, shouldDisplay=true) => {
    let field = generateField(id, fieldName);
    field.value = value;
    field.disabled = disabled;
    field.size = size;
    field.shouldDisplay = shouldDisplay;
    return field;
}

const generateDependantComponent = (id) => {
    let field = generateField(id, 'dependencyComponent');
    field.isDependencySelect = true;
    return field;
} 

const generateSeparator = (id, label)=> {
    let field = generateField(id, label);
    field.size = 12;
    field.isSeparator = true;
    return field;
}

export default class CompetitiveComplementaryTechnologyNewForm extends NavigationMixin(LightningElement)  {

    @api recordId = null;
    @api parentId = null; // Account/Opportunity. Filled from CCTNewAction.cmp
    @api parentObjectName;
    @track recordTypeOptions = [];
    @api show = false;
    @api isRecordtypeScreen = false;
    isLoading = false;
    selectedRecordTypeId;

    // Fields from child component
    childComponentFields = {
        [COMP_NAME_FIELD.fieldApiName]: null,
        [CATEGORY_FIELD.fieldApiName]: null,
        [PRODUCT_FIELD.fieldApiName]: null,
        [COMP_OTHER_FIELD.fieldApiName]: null,
        [OUTSOURCED_FIELD.fieldApiName]: null,
        [CAT_OTHER_FIELD.fieldApiName]: null,
        [PROD_OTHER_FIELD.fieldApiName]: null,
    }

    labels = {
        header: lblHeader,
    }

    @track accountFields = [
        generateSeparator(0, lblHeader),
        generateFormField(1, ACCOUNT_FIELD.fieldApiName, false, null, 12),
        generateDependantComponent(2),
        generateFormField(3, NUM_UNITS_FIELD.fieldApiName),
        generateFormField(4, USAGE_FIELD.fieldApiName),
        generateFormField(5, COMP_NOTES_FIELD.fieldApiName, false, null, 12),
    ];

    accountFieldsNames = []
    @track opportunityFields = [
        generateSeparator(0, lblHeader),
        generateFormField(1, OPP_FIELD.fieldApiName, false, null, 12),
        generateDependantComponent(2),
        generateFormField(3, POSITIONING_FIELD.fieldApiName),
        generateFormField(4, PRIMARY_FIELD.fieldApiName, false, false),
        generateSeparator(5, lblOppSeparator),
        generateFormField(6, GB_FIELD.fieldApiName),
        generateFormField(7, MILLION_FIELD.fieldApiName),
        generateFormField(8, COMP_NOTES_FIELD.fieldApiName, false, null, 12),
    ];


    @wire(getObjectInfo, { objectApiName: OBJ_NAME })
    wiredObjectInfo({ error, data }) {
        if (data) {

            // gets record types from schema
            if(data.recordTypeInfos) {
                let recordTypeOptions = [];
                for (const key in data.recordTypeInfos) {
                    let value = data.recordTypeInfos[key]
                    if(value.name !== 'Master'){
                        let recordTypeOption = {
                            'label' :value.name,
                            'value':value.recordTypeId,
                        }
                        recordTypeOptions.push(recordTypeOption);
                    }

                }
                this.recordTypeOptions = recordTypeOptions;
            }

        } else if (error) {
            consoleError('error while pulling info from CCT Object', error);
            showErrorToast('Unable to load Competitive &amp; Complementary Technologies record types. Please contact your administrator.');
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: "$fieldsRequest" })
    cctRecord({error, data}) {
        if(data) {
            consoleLog('cct record', data);
            this.childComponentFields[COMP_NAME_FIELD.fieldApiName] = getFieldValue(data, COMP_NAME_FIELD);
            this.childComponentFields[CATEGORY_FIELD.fieldApiName] = getFieldValue(data, CATEGORY_FIELD);
            this.childComponentFields[PRODUCT_FIELD.fieldApiName] = getFieldValue(data, PRODUCT_FIELD);
            this.childComponentFields[COMP_OTHER_FIELD.fieldApiName] = getFieldValue(data, COMP_OTHER_FIELD);
            this.childComponentFields[OUTSOURCED_FIELD.fieldApiName] = getFieldValue(data, OUTSOURCED_FIELD);
            this.childComponentFields[CAT_OTHER_FIELD.fieldApiName] = getFieldValue(data, CAT_OTHER_FIELD);
            this.childComponentFields[PROD_OTHER_FIELD.fieldApiName] = getFieldValue(data, PROD_OTHER_FIELD);

            this.template.querySelector('c-depended-pick-list-l-w-c').setValues(this.childComponentFields);

            if(this.isFromAccountContext()) {
                this.getField(this.accountFields, ACCOUNT_FIELD.fieldApiName).value = getFieldValue(data, ACCOUNT_FIELD);
                this.parentId = getFieldValue(data, ACCOUNT_FIELD);
                this.getField(this.accountFields, NUM_UNITS_FIELD.fieldApiName).value = getFieldValue(data, NUM_UNITS_FIELD);
                this.getField(this.accountFields, USAGE_FIELD.fieldApiName).value = getFieldValue(data, USAGE_FIELD);
                this.getField(this.accountFields, COMP_NOTES_FIELD.fieldApiName).value = getFieldValue(data, COMP_NOTES_FIELD);
            } else {
                this.getField(this.opportunityFields, OPP_FIELD.fieldApiName).value = getFieldValue(data, OPP_FIELD);
                this.parentId = getFieldValue(data, OPP_FIELD);
                this.getField(this.opportunityFields, POSITIONING_FIELD.fieldApiName).value = getFieldValue(data, POSITIONING_FIELD);
                this.getField(this.opportunityFields, PRIMARY_FIELD.fieldApiName).value = getFieldValue(data, PRIMARY_FIELD);
                this.getField(this.opportunityFields, GB_FIELD.fieldApiName).value = getFieldValue(data, GB_FIELD);
                this.getField(this.opportunityFields, MILLION_FIELD.fieldApiName).value = getFieldValue(data, MILLION_FIELD);
                this.getField(this.opportunityFields, COMP_NOTES_FIELD.fieldApiName).value = getFieldValue(data, COMP_NOTES_FIELD);
            }
        }

        if(error) {
            consoleError('Unable to retrieve recod', data);
        }
    }

    get fieldsRequest() {
        return this.isFromAccountContext() ?  ACCOUNT_REQUEST_FIELDS : OPPORTUNITY_REQUEST_FIELDS;
    }

    get isGlobalAction () {
        return this.show;
    }

    get fields() {
        return this.isFromAccountContext() ? this.accountFields : this.opportunityFields;
    }

    /**Life cycle hook */
    connectedCallback() {

        if(!this.parentObjectName) {
            getObjName({recordId: this.parentId})
                .then(res => {
                    this.parentObjectName = res;
                })
                .catch(error => {
                    consoleError(`Unable to solve object name from id(${this.parentId}):`, error);
                    showErrorToast(`Unable to identify if related record is Account or Opportunity. Please contact your administrator.`);
                });
        }
    }

    renderedCallback() {
        this.prefillValueFromRecord();
    }

    disconnectedCallback() {
        console.log('disconnectedCallback');
    }

    /**Prefill fields from origin record */
    prefillValueFromRecord = ()=> {
        if(this.isFromAccountContext()) {
            this.getField(this.accountFields, ACCOUNT_FIELD.fieldApiName).value = this.parentId // AccountId
        } else {
            this.getField(this.opportunityFields, OPP_FIELD.fieldApiName).value = this.parentId; // opportunityId
        }
    }

    cleanFields = () => {
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            element.value = null;
        });

        this.template.querySelector('c-depended-pick-list-l-w-c').cleanValues();
    }

    /**
     * Handle Save Button. Gather all fields form to submit
     * @param {*} event 
     */
    handleSubmit(event){
        event.preventDefault();

        if(this.isLoading) return;

        this.isLoading = true;

        const fields = event.detail.fields;
        fields.RecordTypeId = this.getRecordTypeId();

        // fill child component fields
        Object.assign(fields, this.childComponentFields);

        consoleLog(JSON.parse(JSON.stringify(fields)));
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    /**
     * Gets CCTs recordtype 
     * @returns Id recordType
     */
    getRecordTypeId = () => {

        if(this.selectedRecordTypeId)
            return this.selectedRecordTypeId;

        let recordTypeId = this.recordTypeOptions?.find(recordtype => recordtype?.label?.includes(this.parentObjectName))?.value;

        consoleLog('recordTypeId', recordTypeId);

        return recordTypeId
    }

    /**
     * On Success save
     * @param {*} event 
     */
    handleSuccess(event){
        let updatedRecord = event.detail;
        consoleLog('onsuccess: ', JSON.stringify(updatedRecord.id));
        showSuccessToast('record is created ' + updatedRecord.id);

        const onSuccessEvent = new CustomEvent("savesucess", {detail: 
            {
                recordId: updatedRecord.id,
                parentId: this.parentId,
                parentObjectName: this.parentObjectName
            }
        });

        this.dispatchEvent(onSuccessEvent);

        this.isLoading = false;
    }

    /**
     * On error Save
     * @param {*} event 
     */
    handleError(event){
        const errordata = event.detail;
        consoleError('errordata: ', JSON.stringify(errordata));
        showErrorToast(errordata.detail ? errordata.detail : errordata.message);
        this.isLoading = false;
    }

    /**
     * Handles cancel button click
     * @param {*} event 
     */
    handleClickCancel(event){
        this.cleanFields();
        this.dispatchEvent(new CustomEvent("clickcancel"));
    }

    /**
     * Determines if is from Account context
     * @returns 
     */
    isFromAccountContext = () => {
        return this.parentObjectName === ACCOUNT;
    }

    /**
     * Handles record type selector option
     * @param {*} event 
     */
    handleChangeRecordType(event){
        this.selectedRecordTypeId = event.detail.value;

        this.parentObjectName = event.target.options
            .find(opt => opt.value === event.detail.value)
            .label.includes(ACCOUNT)? ACCOUNT : OPPORTUNITY;

        console.log('selectedRecordTypeId-->>'+ this.selectedRecordTypeId);

        this.isRecordtypeScreen = false;
    }

    /**
     * Handles dependedPickListLWC
     * @param {*} event 
     */
    handleOnSelectionbox(event) {
        this.childComponentFields[COMP_NAME_FIELD.fieldApiName] = event.detail.competitor;
        this.childComponentFields[CATEGORY_FIELD.fieldApiName] = event.detail.category;
        this.childComponentFields[PRODUCT_FIELD.fieldApiName] = event.detail.product;
    }

    handleOtherFields(event) {
        this.childComponentFields[COMP_OTHER_FIELD.fieldApiName] = event.detail[COMP_OTHER_FIELD.fieldApiName];
        this.childComponentFields[OUTSOURCED_FIELD.fieldApiName] = event.detail[OUTSOURCED_FIELD.fieldApiName];
        this.childComponentFields[CAT_OTHER_FIELD.fieldApiName] = event.detail[CAT_OTHER_FIELD.fieldApiName];
        this.childComponentFields[PROD_OTHER_FIELD.fieldApiName] = event.detail[PROD_OTHER_FIELD.fieldApiName];
    }

    /**
     * Gets field object from otherFields array.
     * @param {String} fieldName 
     * @returns Object
     */
    getField = (array, fieldName) => {
        return array?.find(field => field?.name === fieldName);
    }
}
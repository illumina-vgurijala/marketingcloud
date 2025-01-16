import { LightningElement, track, api, wire } from 'lwc'
import getProducts from '@salesforce/apex/CompetitiveDataRollUpSummaryCtrl.getJSONProductNames';
import { consoleLog, consoleError, showErrorToast } from 'c/utils';
import CCT_OBJECT from '@salesforce/schema/Competitive_Complementary_Technology__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import errorLoadMsg from '@salesforce/label/c.CCTFormErrorLoadingOptions';
import errorMatchingOptionsMsg from '@salesforce/label/c.CCTFormErrorMatchingOptions';
import phCompetitor from '@salesforce/label/c.CCTPlaceholderSelectCompetitor';
import phCategory from '@salesforce/label/c.CCTPlaceholderSelectCategory';
import phProduct from '@salesforce/label/c.CCTPlaceholderSelectProduct';

import COMP_NAME_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.CompetitorName__c';
import CATEGORY_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Category__c';
import PRODUCT_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.ProductName__c';
import COMP_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Company_Other__c';
import CAT_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Category_Other__c';
import PROD_OTHER_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Product_Name_Other__c';
import OUTSOURCED_FIELD from '@salesforce/schema/Competitive_Complementary_Technology__c.Outsourced_Service_Provider__c';

const OUTSOURCED_OPTION = 'Outsourced / Service Provider';
const OTHER_OPTION = 'Other';

export default class DependedPickListLWC extends LightningElement {

    object;
    isFinishLoadNameFields = false;
    isFinishLoadOptions = false;

    @track competitorOptions;
    @track categoryOptions;
    @track productOptions;

    valCompetitor;
    valCategory;
    valProduct;

    @api setValues(valuesObj) {
        this.valCompetitor = valuesObj[COMP_NAME_FIELD.fieldApiName];
        this.valCategory = valuesObj[CATEGORY_FIELD.fieldApiName];
        this.valProduct = valuesObj[PRODUCT_FIELD.fieldApiName];

        this.getOtherField(COMP_OTHER_FIELD.fieldApiName).value = valuesObj[COMP_OTHER_FIELD.fieldApiName];
        this.getOtherField(OUTSOURCED_FIELD.fieldApiName).value = valuesObj[OUTSOURCED_FIELD.fieldApiName];
        this.getOtherField(CAT_OTHER_FIELD.fieldApiName).value = valuesObj[CAT_OTHER_FIELD.fieldApiName];
        this.getOtherField(PROD_OTHER_FIELD.fieldApiName).value = valuesObj[PROD_OTHER_FIELD.fieldApiName];

        if(this.object) {
            this.setOptionsFromValues();
            this.validateIntegrityOptions();
        }
    }

    @api cleanValues() {
        const otherNameFields = this.otherFields.map(elem => elem.name);

        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.value = null;
            if(otherNameFields.includes(element.dataset.name)) {
                element.disabled = true;
            }
        });

        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.value = null;
        });

        this.validateOtherFields();
    }

    get disabledProductField () {
        return (this.valCategory === undefined || this.valCategory === null);
    }

    get disabledCategoryField () {
        return this.valCompetitor === undefined || this.valCompetitor === null;
    }

    get displayCmp () {
        return this.isFinishLoadNameFields && this.isFinishLoadOptions;
    }

    labels = {
        CompetitorField: null,
        CategoryField: null,
        ProductField: null,
        PlaceholderSelectCompetitor: phCompetitor,
        PlaceholderSelectCategory: phCategory,
        PlaceholderSelectProduct: phProduct
    }

    @track otherFields = [
        {id:1, name: COMP_OTHER_FIELD.fieldApiName, label:null, value: null, disabled: true, onchange:(e) =>{this.onChangeInput(e)}},
        {id:2, name: OUTSOURCED_FIELD.fieldApiName, label:null, value: null, disabled: true, onchange:(e) =>{this.onChangeInput(e)}},
        {id:3, name: CAT_OTHER_FIELD.fieldApiName, label:null, value: null, disabled: true, onchange:(e) =>{this.onChangeInput(e)}},
        {id:4, name: PROD_OTHER_FIELD.fieldApiName, label:null, value: null, disabled: true, onchange:(e) =>{this.onChangeInput(e)}},
    ];

    @wire(getObjectInfo, { objectApiName: CCT_OBJECT })
    cctInfo({ data, error }) {
        if (data) {
            this.labels.CompetitorField = data.fields.CompetitorName__c.label;
            this.labels.CategoryField = data.fields.Product_Category__c.label;
            this.labels.ProductField = data.fields.ProductName__c.label;
            this.getOtherField(COMP_OTHER_FIELD.fieldApiName).label = data.fields[COMP_OTHER_FIELD.fieldApiName].label;
            this.getOtherField(OUTSOURCED_FIELD.fieldApiName).label = data.fields[OUTSOURCED_FIELD.fieldApiName].label;
            this.getOtherField(CAT_OTHER_FIELD.fieldApiName).label = data.fields[CAT_OTHER_FIELD.fieldApiName].label;
            this.getOtherField(PROD_OTHER_FIELD.fieldApiName).label = data.fields[PROD_OTHER_FIELD.fieldApiName].label;
        }

        if (error) {
            consoleError('Unable to load CCT fields labels: ', error);
            showErrorToast(errorLoadMsg);
        }

        this.isFinishLoadNameFields = true;

    }

    connectedCallback() {
        this.getOptions();
    }

    renderedCallback() {
        console.log('renderedCallback');

        if(this.valCompetitor && this.valCategory && this.valProduct) {
            this.validateOtherFields();
        }
    }

    disconnectedCallback() {
        console.log('disconnectedCallback');
    }

    /**
     * Gets JSON objec that would be used to render select options.
     */
    getOptions = () => {
        getProducts().then(res => {

            this.object = res;
            this.competitorOptions = this.generateOptions(this.object);

            if(this.valCompetitor && this.valCategory && this.valProduct) { // it comes from edit
                this.setOptionsFromValues();
                this.validateIntegrityOptions();
            }
        }).catch(error => {
            consoleError('Received error from server: ', error);
            showErrorToast(errorLoadMsg);
        }).finally(() => {
            this.isFinishLoadOptions = true;
        });
    }

    setOptionsFromValues = () => {
        if(this.object[this.valCompetitor]) {
            this.categoryOptions = this.generateOptions(this.object[this.valCompetitor]);
        }

        if(this.object[this.valCompetitor] && this.object[this.valCompetitor][this.valCategory]) {
            this.productOptions = this.generateOptions(this.object[this.valCompetitor][this.valCategory]);
        } 
    }

    validateIntegrityOptions() {
        let notFoundValueOption = '';

        if(!this.competitorOptions || !this.competitorOptions.find(option => option.label === this.valCompetitor)) {
            notFoundValueOption += 'Competitor Name, ';
            this.competitorOptions =  this.competitorOptions || [];
            this.competitorOptions.push({label: this.valCompetitor, value: this.valCompetitor})
        }

        if(!this.categoryOptions || !this.categoryOptions.find(option => option.label === this.valCategory)) {
            notFoundValueOption += 'Product Category, ';
            this.categoryOptions = this.categoryOptions || [];
            this.categoryOptions.push({label: this.valCategory, value: this.valCategory})
        }

        if(!this.productOptions || !this.productOptions.find(option => option.label === this.valProduct)) {
            notFoundValueOption += 'Product Name';
            this.productOptions = this.productOptions || [];
            this.productOptions.push({label: this.valProduct, value: this.valProduct});
        }

        if(notFoundValueOption.length > 0) {
            consoleError(errorMatchingOptionsMsg.replace('{0}', notFoundValueOption), this.object);
        }

        this.validateOtherFields();
    }

    validateOtherFields = () => {
        this.enableEditionCompetitveOtherField();
        this.enableEditionOutsourcedField();
        this.enableEditionCategoryOtherField();
        this.enableEditionProductOtherField();
    }

    /**
     * It generates options for combo-boxes
     * @param {*} values 
     * @returns 
     */
    generateOptions(values) {
        let res = [];

        if(Array.isArray(values)) {
            for(let i = 0; i < values.length; i++) {
                res.push({label : values[i], value: values[i]});
            }
            return res;
        }

        for(let val in values) {
            res.push({label : val, value: val});
        }

        return res;
    }

    /**
     * Onchange for Competitor combo-box. Sets matching matrix from this.object. It notifies selection to parent component.
     * @param {*} event 
     */
    handleCompetitor(event) {
        let competitor = event.target.value;
        
        this.valCompetitor = competitor;
        this.categoryOptions = this.generateOptions(this.object[this.valCompetitor]);

        this.valCategory = null;
        this.valProduct = null;

        this.validateOtherFields();

        this.sendEventSelection();
    }

    /**
     * Onchange for Category combo-box. Sets matching matrix from this.object.  It notifies selection to parent component.
     * @param {*} event 
     */
    handleCategory(event) {
        let category = event.target.value;
        this.valCategory = category;
        this.valProduct = null;

        consoleLog('path:' + this.valCompetitor + '|' + this.valCategory);
        this.productOptions = this.generateOptions(this.object[this.valCompetitor][this.valCategory]);

        this.enableEditionCategoryOtherField();
        this.enableEditionProductOtherField();

        this.sendEventSelection();
    }

    /**
     * Onchange for Product combo-box. Sets matching matrix from this.object. It notfies selection to Parent.
     * @param {*} event 
     */
    handleProduct(event) {
        this.valProduct = event.target.value;

        this.enableEditionProductOtherField();

        this.sendEventSelection();
    }

    onChangeInput(event) {
        let fieldName = event.target.getAttribute('data-name');
        let field = this.getOtherField(fieldName);
        field.value = event.target.value;
        this.sendEventOnChangeOtherField();
    }

    sendEventSelection = () => {
        const onChangeEvt = new CustomEvent("selectionbox", { detail: 
            {
                competitor: this.valCompetitor,
                category: this.valCategory,
                product: this.valProduct,
            }
        });

        this.dispatchEvent(onChangeEvt);
    }

    sendEventOnChangeOtherField = () => {

        let values = {};
        this.otherFields.forEach( field => {
            values[field.name] = field.value;
        });
        const onChangeEvt = new CustomEvent("otherfieldchanged", { detail: values });

        this.dispatchEvent(onChangeEvt);
    }

    /**
     * Fetch field by name and enable/disable.
     * @param {String} fieldName fieldApiName.
     * @param {Boolean} enable false to disable it and clear value.
     */
    enableDisableField = (fieldName, enable) => {
        let field = this.getOtherField(fieldName);
        if(enable) {
            field.disabled = false;
        } else {
            field.disabled = true;
            field.value = null;
            this.sendEventOnChangeOtherField();
        }
    }

    /**
     * Gets field object from otherFields array.
     * @param {String} fieldName 
     * @returns Object
     */
    getOtherField = (fieldName) => {
        return this.otherFields?.find(field => field?.name === fieldName);
    }

    enableEditionCompetitveOtherField = () => {
        this.enableDisableField(COMP_OTHER_FIELD.fieldApiName, this.valCompetitor !== null && this.valCompetitor === OTHER_OPTION);
    }

    enableEditionOutsourcedField = () => {
        this.enableDisableField(OUTSOURCED_FIELD.fieldApiName, this.valCompetitor !== null && this.valCompetitor === OUTSOURCED_OPTION);
    }

    enableEditionCategoryOtherField = () => {
        this.enableDisableField(CAT_OTHER_FIELD.fieldApiName, this.valCategory !== null && this.valCategory === OTHER_OPTION);
    }

    enableEditionProductOtherField = () => {
        this.enableDisableField(PROD_OTHER_FIELD.fieldApiName, this.valProduct !== null && this.valProduct === OTHER_OPTION);
    }
}
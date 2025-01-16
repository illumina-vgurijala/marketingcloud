/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement,api,track } from 'lwc';
import getResults from '@salesforce/apex/ProductLookupController.getResults';
import getAccountResults from '@salesforce/apex/AccountLookupController.getAccountResults';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class productLookup extends LightningElement {
    //objectName on which lookup search would be operated. Value is defaulted to Product2 however, 
    //It can bbe changed from the Parent component.
    @api objectName = 'Product2';
    //FieldName on which lookup search would be operated.
    @api fieldName = 'ProductCode';
    //field which is displayed after lookup search
    @api displayField = '';
    //optional field included in search.  
    @api optionalField = '';
    //recordId of the selected record.
    @api selectRecordId = '';
    //selected record value
    @api selectRecordName;
    //label on the field 
    @api label = 'Product Code';
    // results
    @api searchRecords = [];
    // required attribute on the field
    @api required = false;
    //icon name to display
    @api iconName = 'standard:product'
    //loading.. text
    @api LoadingText = false;
    //QACM-78 case or work order object api name
    @api caseWoObjApiName = '';
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    //message display
    @track messageFlag = false;
    //search icon flag
    @track iconFlag =  true;
    // readonly attribute
    @track inputReadOnly = false;
    //apiname of the object(current record page)
    @api objApiName;
    //flag to stop executing the logic multiple times.
    @track hasNotrendered = true;
    //@api readOnlyField = false;
    /**
     * Method Name: renderedCallback
     * Params: None
     * Description: Related to pre populating the product code && product name if the user is in product page.
     */
    renderedCallback(){
        if(this.hasNotrendered && (this.objApiName === 'Product2' || this.objApiName==='SVMXC__Installed_Product__c' || this.objectName === 'Account')){
            this.iconFlag = false;
            this.hasNotrendered = false;
        }
    }
    /**
     * Method Name: searchField
     * Params:event
     * Description: server call to get the search results to display 
     */
    searchField(event) {
        //current value
        let currentText = event.target.value;
        // this.searchRecords = null;
        
        //if(currentText.length > 2){
        this.LoadingText = true;
        //server call to get the results
        if(this.objectName !== 'Account'){  //QACM-78
            getResults({ ObjectName: this.objectName, fieldName: this.fieldName, value: currentText, displayText:this.displayField, optionalField:this.optionalField })
            .then(result => {
            this.searchRecords= result;
            this.LoadingText = false;
                        
            this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length === 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                            
            }
            else {
                this.iconFlag = true;
                            
            }
            })
            .catch(error => {
            //show the error as a toast message
                console.log(error);
                const evt = new ShowToastEvent({
                    title: 'Error!',
                    message: error.body.exceptionType +': ' +error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
            });
        }
        /**
         * QACM-78 Adding below code to fetch the acount details based on the search on account field from case or work oder object
         */
        else if(this.caseWoObjApiName === 'Case' ||this.caseWoObjApiName === 'SVMXC__Service_Order__c'){
            getAccountResults({ objectName: this.objectName, fieldName: this.fieldName, value: currentText, displayText:this.displayField})
                .then(result => {
                    this.searchRecords= result;
                    this.LoadingText = false;
                    
                    this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                    if(currentText.length > 0 && result.length === 0) {
                        this.messageFlag = true;
                    }
                    else {
                        this.messageFlag = false;
                    }

                    if(this.selectRecordId !== null && this.selectRecordId !== undefined && this.selectRecordId !== '') {
                        this.iconFlag = false;
                        
                    }
                    else {
                        this.iconFlag = true;
                        
                    }
                })
                .catch(error => {
                    //show the error as a toast message
                    console.log(error);
                    const evt = new ShowToastEvent({
                        title: 'Error!',
                        message: error.body.exceptionType +': ' +error.body.message,
                        variant: 'error',
                        mode: 'sticky',
                    });
                    this.dispatchEvent(evt);
                });
        }        
        /*QACM-78 Ends*/
    }
    /**
     * Method Name: setSelectedRecord
     *  Params: event
     * Description: setting the record selected into lookup field.
     */
    setSelectedRecord(event) {
        //selected value
        let currentText = event.currentTarget.dataset.id;
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.iconFlag = false;
        
        this.selectRecordName = event.currentTarget.dataset.name;
        let selectName = event.currentTarget.dataset.name;
        this.selectRecordId = currentText;
        this.inputReadOnly = true;
        
        let productName = event.currentTarget.dataset.field;
        //firing the custom event with corresponding product name value.
        const selectedEvent = new CustomEvent('selected', { detail: {productName}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
    
    
    /**
     * Method Name:resetData 
     * Params: event
     * Description: It will reset the data of the lookup component.
     */
    // eslint-disable-next-line no-unused-vars
    @api
    resetData(event) {
        this.selectRecordName = "";
        this.selectRecordId = "";
        this.inputReadOnly = false;
        this.iconFlag = true;
        
        let readOnlyField = false;
        //fire an custom event 
        const selectedEvent = new CustomEvent('readonly', { detail: {readOnlyField}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

}
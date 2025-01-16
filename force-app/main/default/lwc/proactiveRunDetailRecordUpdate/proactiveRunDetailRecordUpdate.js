import { LightningElement,api,track } from 'lwc';
import saveMetrics from '@salesforce/apex/ProactiveComponentController.saveMetrics';
import getRunMetrics from '@salesforce/apex/ProactiveComponentController.getRunMetrics';
import fetchProactiveRunDetailRec from '@salesforce/apex/ProactiveComponentController.fetchProactiveRunDetailRec';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    showErrorToast,
    showSuccessToast
} from 'c/utils';


export default class ProactiveRunDetailRecordUpdate extends LightningElement {

    @api recordId;// holds current record's Id
    @api objectApiName; // holds Object label
    @track runId;
    @track serialNumber;
    @track environment;
    @track category;
    @track proId;
    @track woId;
    // variable used to display spinner while processing
    @track strToggleSpinnerClass = 'slds-hide';
    @track runMetricResponse = [];
    
    connectedCallback() {
        console.log('Record Id from Parent :'+ this.recordId);
        this.strToggleSpinnerClass = 'slds-show';
        fetchProactiveRunDetailRec({
            prdId: this.recordId
        })
        .then(result => {
            // returns the record detail based on the Id
            if (result) {
                console.log('result**' + JSON.stringify(result));

                if (result.some(e => (e.id !== ' '))) {
                    console.log('Entered Proactive');
                    if (result[0].Serial_Number__c && result[0].Environment__c && result[0].Proactive_Id__c) {
                        this.runId = result[0].BS_Run_ID__c;
                        this.serialNumber = result[0].Serial_Number__c;
                        this.environment = result[0].Environment__c;
                        this.category = result[0].Product_Category__c;
                        this.proId = result[0].Proactive_Id__c;
                        this.woId = result[0].Work_Order__c;
                        this.getProMetricsUpdated();
                    } else {
                       showErrorToast('Data fetch unsuccessful on this record,check Serial Number & Proactive Id & Environment ');
                       console.log('Error in fetching the Proactive Run Detail data');
                       this.strToggleSpinnerClass = 'slds-hide';
                        this.dispatchEventToAura();
                    }
                }
                
            }
        })
        .catch(error => {
            this.dispatchEventToAura();
            this.strToggleSpinnerClass = 'slds-hide';
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType + ': ' + error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);

            this.strToggleSpinnerClass = 'slds-hide';
        });
    }


    

    /*
     * Method Name: getRunMetrics
     * params: 
     * Description: Fetch the metric response for the specific Proactive Run Detail record 
     *               
     */

    getProMetricsUpdated() {

        let mObj = {};
        mObj["category"] = this.category;
        mObj["runId"] = this.runId;
        mObj["serialNumber"] = this.serialNumber;
        mObj["env"] = this.environment;
        mObj["id"] = this.proId;
        mObj["objectName"] = this.objectApiName;
        mObj["isProactiveUpdate"] = true;

        getRunMetrics({
            runMetrics: JSON.stringify(mObj)
        }).then(response => {
            console.log('Response obtained for this Record' + response.jsonRes);
            this.runMetricResponse = response.jsonRes;
            let responseCode = response.statusCode;
            if (responseCode === 200) {
                console.log('Response Fetched SuccessFully');
                this.saveRunAPData();
            }
            else{
                showErrorToast('Run Metrics fetch unsuccessfull for selected Run--'+responseCode);
                this.strToggleSpinnerClass = 'slds-hide';
                this.dispatchEventToAura();
            }
            
            
        }).catch(error => {
    
            this.strToggleSpinnerClass = 'slds-hide';
            this.dispatchEventToAura();
            this.error = error.body;
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType + ': ' + error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
    
        });
    }

    /*
     * Method Name: saveRunAPData
     * Description: This method is used to save the metrics after been previwed and user selects the additional products
     *               
     */

    saveRunAPData() {
        console.log('****Entered SaveRun');
        let saveObj = {};
        saveObj["jsonRes"] = this.runMetricResponse;
        saveObj["category"] = this.category;
        saveObj["recordId"] = this.woId;
        saveObj["runNotes"] = '';
        saveObj["ipId"] = null;
        saveObj["selectedRecords"] = null;
        saveObj["id"] = this.proId;
        saveObj["env"] = this.environment;
        saveObj["serialNumber"] = this.serialNumber;
        saveObj["isProactiveUpdate"] = true;
        saveMetrics({
            saveRunMetrics: JSON.stringify(saveObj)
        })
        .then(response => {
            // response holds Success or Fail 
            console.log('Response after save->' + response);
            this.strToggleSpinnerClass = 'slds-hide';
           
            this.dispatchEventToAura();
            if (response === 'Success') {
                showSuccessToast('Proactive Run Detail updated Successfully');
                
            } else {
                showErrorToast('Data Save Unsuccessfull');
                this.dispatchEventToAura();
            }
        })
        .catch(error => {
            this.strToggleSpinnerClass = 'slds-hide';
            this.dispatchEventToAura();
            console.log('error after save->' + error);
            this.error = error.body;
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error.body.exceptionType + ': ' + error.body.message,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(evt);
        });
    }

    /*
     * Method Name: dispatchEventToAura
     * Description: This method is used fire event to parent aura component from child lwc
     *               
     */

    dispatchEventToAura() {
        let closeQuickAction = true;
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: closeQuickAction
          });
          // Fire the custom event
          this.dispatchEvent(valueChangeEvent);
    }
}
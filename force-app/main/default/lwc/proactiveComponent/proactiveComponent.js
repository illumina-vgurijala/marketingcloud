import {
    api,
    LightningElement,
    track,wire
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    showErrorToast,
    showSuccessToast,
	consoleLog
} from 'c/utils';
import {
    getRecord
} from 'lightning/uiRecordApi';
import getWODetails from '@salesforce/apex/ProactiveComponentController.getWODetails';
import getCaseDetails from '@salesforce/apex/ProactiveComponentController.getCaseDetails';
import fetchRuns from '@salesforce/apex/ProactiveComponentController.fetchRuns';
import getCategory from '@salesforce/apex/ProactiveComponentController.getCategory';
import getRunMetrics from '@salesforce/apex/ProactiveComponentController.getRunMetrics';
import saveMetrics from '@salesforce/apex/ProactiveComponentController.saveMetrics';
import fetchAdditionalProducts from '@salesforce/apex/ProactiveComponentController.fetchAdditionalProducts';
import displayComponentCase from '@salesforce/label/c.DisplayComponentCase';
import displayComponentWO from '@salesforce/label/c.DisplayComponentWO';
import SelectAssociatedProductHeader from '@salesforce/label/c.SelectAssociatedProductHeader';

import ID_FIELD from '@salesforce/schema/Case.Id';
import IP_FIELD from '@salesforce/schema/Case.SVMXC__Component__c';
const FIELDS = [ID_FIELD,IP_FIELD];

export default class proactiveComponent extends LightningElement {

    @api objectApiName; // holds Object label
    @api recordId; // holds current record's Id
    // get the current date and display it in Applicable date input on UI.
    @track dateTodays = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate();
    // varible used to hold the 7 days behind date
    @track dateBehind;
    // variable used to hold the serial number of the Installed Product
    // variable used to hold the Installed product 
    @track installedProduct;
    @track ipName;
    //variable used to hold the message to be displayed on UI
    @track message;
    //variable declared to use in the date calculation and date validation
    @track sDate;
    //variable declared to use in the date calculation and date validation
    @track eDate;
    // variable for data table rendering 
    @track renderIPResults = false;
    // array variable used to hold the runs returned 
    @track productsReturnedData = [];
    // variable for rendering metric information of each run
    @track displayEachRecInfo = false;
    // array variable to hold the dynamic mapping of run metrics
    @track mapData = [];
    // array variable to hold the selected record information from child component
    @track idFromSelectedRun = [];
    // array variable to hold the proactiveLink fetched from metric information
    @track proactiveLink = '';
    // variable to hold the category of the selected Installed Product
    @track ipCategory;
    // variable used to render the entire component when criteria met
    @track showComponent;
    // array variable used to hold the run metric response of each run for Save logic
    @track runMetricResponse = [];
    // variable used to display spinner while processing
    @track strToggleSpinnerClass = 'slds-hide';
    // Expose the labels to use in the template
    @track ipConnectivityStatus;
    // variable to hold the status of the instrument connectivity with Proactive
    @track ipId;
    // variable to hold the salesforce Id of the Installed Product selected by user
    @track runNotes;
    // Variable to hold the notes entered by the end user before saving the run's metrics
    @track selectAssociatedProducts;
    // Variable to render the section to let the user select the additional products from Proactive to Save into salesforce
    @track apLstData=[];
    // Variable to hold the list of Additional products to iterate over the lightning data table.c/accountPlanObjectives
    @track selectedRows = [];
    // Variable to make the additional products displayed in the UI to be selected/checked by default
    @track isGenotyping = false;
    // Variable used to conditionally display the Save button for Genotyping Product type
    @track selectedRunMetrics;
    // Variable to hold the selectedrun's information 
    @track readLength;
    // Variable to hold the Read length of the selected run 
    @track runStartDate; //DCP-51097 - Start
    // Variable to hold the start date of the selected run
    @track runEndDate;
    // Variable to hold the end date of the selected run
    @track runStatus; //DCP-51097 - End
    // Variable to hold the status of the selected run
    @track mappedProductCategories = ['HiSeq','iSeq','MA Scanners','MiniSeq','MiSeq','NovaSeq','NextSeq 1000/2000','NextSeq 500/550','HiSeq HD','HiSeq X','NovaSeq X Series']; // DCP-51936
    // Variable to hold the array of mapped product categories
    @track enableFetchRuns = false;
    // Variable to enable and disable the Fetch Runs Button on the search criteria section
    @track displayErrorMessage = false;
    // Variable to hold the status of the WO
    woStatus;
    // Variable to hold the RUNID displayed in the runs returned section
    name;
    // Variable to hold the feature flag data
    label = {
        displayComponentCase,
        displayComponentWO,
        SelectAssociatedProductHeader
    };

    // array variable to hold and pass the column information to child component
    @track lstAllTableColumns = [

        {
            label: 'Run Id',
            fieldName: 'name',

        },
        {
            label: 'Read Length',
            fieldName: 'readLength',
        },
        {
            label: 'Run Start Date',
            fieldName: 'instrumentStartDtFormated',

        },
        {
            label: 'Run End Date',
            fieldName: 'instrumentEndDtFormated',

        },
        {
            label: 'Run Status',
            fieldName: 'status',

        }
        
    ];

    @track apTableColumns = [
        {
            label: 'Serial Number',
            fieldName: 'serialNumber',
        },
        {
            label: 'Part Number',
            fieldName: 'partNumber',
        },
        {
            label: 'Lot Number',
            fieldName: 'lotNumber',
        },
        {
            label: 'Expiration Date',
            fieldName: 'expirationDate',
        }
    ]

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS }) 
    wiredAccount({data,error}) {
        if(data) {            
            this.connectedCallback();
            this.renderIPResults = false;
            this.displayEachRecInfo = false;
            this.selectAssociatedProducts = false;
            
        }
        if(error) {
            consoleLog('Error in fetching updated value'); 
        }
    }
    /*
     * Method Name: connectedCallback
     * Description: This Method get initiated on the component load
     *               
     */
    connectedCallback() {
        this.strToggleSpinnerClass = 'slds-show';
        this.calculatedateBehind();
        //9296 changes
        if (this.objectApiName === 'SVMXC__Service_Order__c') {
            this.handelWOlogic();
        }
        else if (this.objectApiName === 'Case') {
            this.handleCaseLogic();
        }
    }
    
    handelWOlogic() {
        this.ipName = '';
        getWODetails({
            strWoId: this.recordId
        })
            .then(result => {
                if (result) {
                    this.handelWOlogicHelper(result);
                }
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error in WO Fetch!',
                    message: error.body.exceptionType + ': ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
                this.strToggleSpinnerClass = 'slds-hide';
            });
    }
    
    handelWOlogicHelper(result) {
        if (result.some(e => (e.SVMXC__Order_Status__c !== ' '))) {
            this.woStatus = result[0].SVMXC__Order_Status__c;
        }
        this.showComponent = true; // Always show the component
        if (result.some(e => (e.SVMXC__Component__r) && (e.SVMXC__Component__r.SVMXC__Serial_Lot_Number__c !== ' ') &&
            (e.SVMXC__Component__r.Product_Category__c !== ' '))) {
            this.ipName = result[0].SVMXC__Component__r.SVMXC__Serial_Lot_Number__c;
            this.ipCategory = result[0].SVMXC__Component__r.Product_Category__c;
            this.ipConnectivityStatus = result[0].SVMXC__Component__r.Proactive_Connectivity_Status__c;
            this.ipId = result[0].SVMXC__Component__c;
            this.isGenotypingCategory(this.ipCategory);
            this.isMappedCategory(this.ipCategory, this.woStatus);
        }
        this.strToggleSpinnerClass = 'slds-hide';
    }
    
    handleCaseLogic() {
        this.ipName = '';
        getCaseDetails({
            strCaseId: this.recordId
        })
            .then(result => {
                if (result) {
                    this.handleCaseLogicHelper(result);
                }
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error in Fetch!',
                    message: error.body.exceptionType + ': ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
                this.strToggleSpinnerClass = 'slds-hide';
            });
    }
    
    handleCaseLogicHelper(result) {
        if (result.some(e => (e.Work_Order_Status__c !== ' '))) {
            this.woStatus = result[0].Work_Order_Status__c;
        }
        this.showComponent = true; // Always show the component
        if (result.some(e => (e.SVMXC__Component__r) && (e.SVMXC__Component__r.SVMXC__Serial_Lot_Number__c !== ' ') &&
            (e.SVMXC__Component__r.Product_Category__c !== ' '))) {
            this.ipName = result[0].SVMXC__Component__r.SVMXC__Serial_Lot_Number__c;
            this.ipCategory = result[0].SVMXC__Component__r.Product_Category__c;
            this.ipConnectivityStatus = result[0].SVMXC__Component__r.Proactive_Connectivity_Status__c;
            this.ipId = result[0].SVMXC__Component__c;
            this.isGenotypingCategory(this.ipCategory);
            this.isMappedCategory(this.ipCategory, this.woStatus);
        }
        this.strToggleSpinnerClass = 'slds-hide';
    }
    
    /*
     * Method Name: isGenotypingCategory
     * params: category
     * Description: This method is used to identify the category if it is type Genotyping(MA Scanners) , so that the UI button Save Run and Products
     * is rendered
     * DCP-51097              
     */

    isGenotypingCategory(category){
        if(category === 'MA Scanners'){
            this.isGenotyping = true;
        }
        else{
            this.isGenotyping = false;
        }
    }  

    /*
     * Method Name: isMappedCategory
     * params: category
     * Description: This method is used to indentify if the category is within the mapped category
     * is rendered
     *               
     */

    isMappedCategory(category,woStatus){
        if(!this.mappedProductCategories.includes(category)){
            this.displayErrorMessage = true;
            this.message = 'This instrument type is not currently supported for Proactive Run Details';
            this.enableFetchRuns = true;
            
        }
        else if(woStatus !== 'Closed' && woStatus !== 'Not Applicable'){
            this.enableFetchRuns = false;
            this.displayErrorMessage = false;
            
        }
    }


    /*
     * Method Name: handleClick
     * params: event
     * Description: This is used to validate the date difference and validation of Installed Product if Null and
     *              make the first callout to Proactive by passing the values StartDate,EndDate,SerialNumber and 
     *              display prepare the productsReturnedData with the response returned.
     *               
     */

    handleClick() {

        this.template.querySelectorAll('c-product-Lookup').forEach(function(element) {
            console.log('elementlabel->' + element.label);
            if (element.label === 'Installed Product') {
                console.log('InstalledProduct-->' + element.selectRecordName);

                this.installedProduct = element.selectRecordName;
                if (!this.installedProduct) {
                    showErrorToast('Installed Product Value cannot be Empty');
                    this.renderIPResults = false;
                    this.displayEachRecInfo = false;
                    this.selectAssociatedProducts = false;
                    this.strToggleSpinnerClass = 'slds-hide';
                    return;
                }
            }
        }, this);

        this.template.querySelectorAll("lightning-input").forEach(function(element) {
            console.log('Entered handleClick' + element.name);
            if (element.name === 'Start_Date') {
                console.log('Entered handle1' + element.value);
                this.sDate = element.value;
            }
        }, this);

        this.template.querySelectorAll("lightning-input").forEach(function(element) {
            if (element.name === 'Endng_Date') {
                console.log('Entered handle2' + element.value);
                this.eDate = element.value;
            }
        }, this);

        let days = Math.ceil((new Date(this.eDate) - new Date(this.sDate)) / 8.64e7);
        var CurrentDate = new Date();
        console.log('difference in dates are-- ' + days);

        console.log('***eDts*'+this.eDate+'**tDts*'+this.dateTodays+'****'+this.sDate);
        console.log('^^^^DT^^'+new Date(this.eDate)+'@@@@@'+CurrentDate);
        
        /* Validation to check the End Date is not greater than todays Date*/
        //if(new Date(this.eDate)>new Date(this.dateTodays)){
        if(new Date(this.eDate)>new Date(CurrentDate)){
            console.log('Validation 1');
            showErrorToast('Your End Date cannot be a date in the future.');
            return;
        }
        /* Validation to check the Start date is not greater than End date*/  
        if(new Date(this.sDate)>new Date(this.eDate)){
            console.log('Validation 2');
            showErrorToast('Please make sure your Start Date comes before your End Date');
            return;
        }

         /* Validation to check the connectivity of IP with Proactive system*/  
         if(!(this.ipConnectivityStatus) || this.ipConnectivityStatus !== 'Connected'){
            console.log('Validation 3');
            showErrorToast('The installed Product in this search is not connected to Proactive');
            return;
        }


        /* Validation to check the date difference between Start date and End date is not more that 14 days*/  
        if (days > 14) {
            this.renderIPResults = false;
            this.displayEachRecInfo = false;
            this.selectAssociatedProducts = false;
            showErrorToast('Please select start and end dates within 2 weeks of each other');
        } else {
            this.handleDaysLessThan14();
            
        }

    }

    /*
     * Method Name: handleDaysLessThan14
     * Description: This method used to make the first callout to fetch the runs and display them on UI
     * This is catching an event from child component
     *               
     */

    handleDaysLessThan14(){
        console.log('Entered Else Installed Product'+this.installedProduct);

            if (this.installedProduct) {
                let obj = {};
                obj["sDate"] = this.sDate;
                obj["eDate"] = this.eDate;
                obj["serialNumbers"] = this.installedProduct;
                obj["objectName"] = this.objectApiName;
                console.log('Entered installed product null check');
                this.strToggleSpinnerClass = 'slds-show';
                fetchRuns({
                        
                        runsData: JSON.stringify(obj)

                    })
                    .then(response => {
                        console.log('Response***' + response);
                        let proRunsRetunred = [];
                        proRunsRetunred = JSON.parse(response);
                        console.log('proRunsRetunred***' + proRunsRetunred);
                        this.productsReturnedData = proRunsRetunred;
                       
                        if (this.productsReturnedData.length === 0) {

                            this.strToggleSpinnerClass = 'slds-hide';
                            console.log('entered no runs');
                            this.renderIPResults = false;
                            showErrorToast('No runs were returned. Please confirm the instrument is connected to Proactive, adjust your filter criteria and try again.');
                        } else {
                            this.renderIPResults = true;
                            this.strToggleSpinnerClass = 'slds-hide';
                        }
                    })
                    .catch(error => {
                        //catch the error and show it as a toast message.
                        this.strToggleSpinnerClass = 'slds-hide';
                        this.error = error.body;
                        const evt = new ShowToastEvent({
                            title: 'Error!',
                            message: error.body.exceptionType + ': ' + error.body.message,
                            variant: 'error',
                            mode: 'sticky',
                        });
                        this.dispatchEvent(evt);
                    });
                this.renderIPResults = true;
            }
        
            this.renderIPResults = false;
            this.displayEachRecInfo = false;
            this.selectAssociatedProducts = false;
    }
    /*
     * Method Name: handleCustomEvent
     * Params: event
     * Description: This method used to make the second callout using RunId,Serialnumber,Environment,Id
     * This is catching an event from child component
     *               
     */
    handleCustomEvent(event) {
        this.strToggleSpinnerClass = 'slds-show';
        this.runNotes = '';
        this.proactiveLink = '';
        this.displayEachRecInfo = false;
        this.selectAssociatedProducts = false;

        const textVal = event.detail;
        console.log('ID value obtained from selection-' + textVal);
        if (textVal) {
            this.idFromSelectedRun = JSON.parse(event.detail);
        } else {
            showErrorToast('No Rows selected');
        }
        console.log('serial Number--->' + this.idFromSelectedRun[0].instrumentSerialNumber + '***->' +
            'runId-->' + this.idFromSelectedRun[0].runId + '***' +
            'environment-->' + this.idFromSelectedRun[0].environment + '***' +
            'Id-->' + this.idFromSelectedRun[0].id + '***'+ 
            'readLength-->' + this.idFromSelectedRun[0].readLength+ '***'+
            'Run Start Date-->' + this.idFromSelectedRun[0].instrumentStartDtFormated+ '****'+
            'Run End Date-->' + this.idFromSelectedRun[0].instrumentEndDtFormated+'******'+
            'name-->' + this.idFromSelectedRun[0].name+'******'+
            'Run Status-->'+ this.idFromSelectedRun[0].status);

            this.selectedRunMetrics = this.idFromSelectedRun[0];
            this.readLength = this.idFromSelectedRun[0].readLength;
            this.runStartDate = this.idFromSelectedRun[0].instrumentStartDtFormated; //DCP-51097 - Start
            this.runEndDate = this.idFromSelectedRun[0].instrumentEndDtFormated;
            this.runStatus = this.idFromSelectedRun[0].status; //DCP-51097 - End
            this.name = this.idFromSelectedRun[0].name; //DCP- 51976
           

        this.mapData = [];
        let mObj = {};
        mObj["category"] = this.ipCategory;
        mObj["runId"] = this.idFromSelectedRun[0].runId;
        mObj["serialNumber"] = this.idFromSelectedRun[0].instrumentSerialNumber;
        mObj["env"] = this.idFromSelectedRun[0].environment;
        mObj["id"] = this.idFromSelectedRun[0].id;
        mObj["objectName"] = this.objectName;
        mObj["isProactiveUpdate"] = false;

        getRunMetrics({
               
                runMetrics: JSON.stringify(mObj)
                
            })
            .then(response => {
                // response have the Map of labels and response from the second callout
                console.log('summary fields formed' + response);
                console.log('summary fields formed Stringified' + JSON.stringify(response.lablesToMap));
                if (response) {

                    let responseCode = response.statusCode;
                    console.log('Run metrics return code' + responseCode + 'Map->' + response.lablesToMap);
                    if (response.lablesToMap && responseCode === 200) {
                        console.log('***if');
                        this.displayEachRecInfo = true;
                        
                        showSuccessToast('Run Metrics fetched successfully');
                    } else {
                        console.log('***else');
                        this.displayEachRecInfo = false;
                        showErrorToast('Run Metrics fetch unsuccessful for selected Run--'+responseCode);
                    }

                    console.log('summary fields formed**' + response.lablesToMap);
                    let nMapD = response.lablesToMap;
                    console.log('****' + nMapD);
                    this.runMetricResponse = response.jsonRes;
                    this.proactiveLink = response.proactiveLink;

                    for (let key in nMapD) {
                        console.log('insideFor' + nMapD[key] + key);
						let keyAttr = key.replace('\r\n', '');
						
						if(keyAttr === '\nRun ID'){
							this.mapData.push({
								value: this.idFromSelectedRun[0].name,
								key: keyAttr
							});
						} else {
							this.mapData.push({
								value: nMapD[key],
								key: keyAttr
							});
						}
                    }
					
		
                    this.strToggleSpinnerClass = 'slds-hide';
                    this.captureAdditionalProduct();
                    console.log('mapData***' + JSON.stringify(this.mapData));
                    console.log('Second Response****--'+this.runMetricResponse);
                }

            })
            .catch(error => {

                this.strToggleSpinnerClass = 'slds-hide';
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
     * Method Name: handlenextpage
     * Params: event
     * Description: This method is used to close the metrics section when user clicks on next buttons or other buttons. 
     * This is catching an event from child component
     *               
     */

    handlenextpage(event) {
        const textVal = event.detail;
        console.log('user navigated to next page-->' + textVal);
        if (textVal) {
            this.displayEachRecInfo = false;
            this.selectAssociatedProducts = false;
        }

    }

    /*
     * Method Name: captureAdditionalProduct
     * Description: This method is used to save the metrics after been previewed 
     *               
     */

    captureAdditionalProduct() {
        console.log('entered fetch AP');
        this.strToggleSpinnerClass = 'slds-show';
        // Always set selectAssociatedProducts to true
        this.selectAssociatedProducts = true;
    
        fetchAdditionalProducts({
            jsonRes: this.runMetricResponse,
            category: this.ipCategory
        })
        .then(response => {
            // response holds list of additional products 
            if (!response.length) {
                console.log('No APs are returned');
            }
            
    
            this.apLstData = response;
            
            let my_ids = []; // To populate the checkboxes to TRUE on the datatable load itself
            this.apLstData.forEach(element => {
                my_ids.push(element.serialNumber);
            });
            
            this.selectedRows = my_ids;
           
            this.strToggleSpinnerClass = 'slds-hide';
        })
        .catch(error => {
            this.strToggleSpinnerClass = 'slds-hide';
            console.log('error in fetching Additional Products>' + error);
            this.error = error.body;
            const evt = new ShowToastEvent({
                title: 'Error in AP fetch!',
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
        this.strToggleSpinnerClass = 'slds-show';
        let selectedRecords;
        if(!this.isGenotyping){
         selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();  
        }
        
        console.log('*proactiveLink**' + this.proactiveLink);
        console.log('*ipCategory**' + this.ipCategory);
        console.log('*runMetricResponse**' + this.runMetricResponse);
        console.log('*runNotes**' + this.runNotes);
        console.log('*ipId***' + this.ipId);
        console.log('**Selected Products****'+JSON.stringify(selectedRecords));
        console.log('Read Length'+this.readLength);
        let saveObj = {};
        saveObj["jsonRes"] = this.runMetricResponse;
        saveObj["category"] = this.ipCategory;
        saveObj["recordId"] = this.recordId;
        saveObj["runNotes"] = this.runNotes;
        saveObj["ipId"] = this.ipId;
        saveObj["selectedRecords"] = JSON.stringify(selectedRecords);
        saveObj["id"] = this.selectedRunMetrics.id;
        saveObj["env"] = this.selectedRunMetrics.environment;
        saveObj["serialNumber"] = this.selectedRunMetrics.instrumentSerialNumber;
        saveObj["readLength"] = this.readLength;
        saveObj["runStartDate"] = this.runStartDate;
        saveObj["runEndDate"] = this.runEndDate;
        saveObj["runStatus"] = this.runStatus;
        saveObj["isProactiveUpdate"] = false;
        saveObj["runName"] = this.name;

        console.log('Json Formed**'+JSON.stringify(saveObj));
        
        saveMetrics({
               
                saveRunMetrics: JSON.stringify(saveObj)
            })
            .then(response => {
                // response holds Success or Fail 
                console.log('Response after save->' + response);
                this.strToggleSpinnerClass = 'slds-hide';
                if (response === 'Success') {
                    showSuccessToast('The Metrics Data Selected is saved successfully');
                } else if (response === 'Fail') {
                    showErrorToast('Data Save Unsuccessfull');
                }
            })
            .catch(error => {
                this.strToggleSpinnerClass = 'slds-hide';
                consoleLog('error after save->' , JSON.stringify(error));
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
     * Method Name: handleLookupValueSelectIP
     * Params: event
     * Description: on selecting the look up value, get the info from child to parent component and fetching the category of the selected
     * Installed product based on its name
     *               
     */

    handleLookupValueSelectIP(event) {
        //subscribing to the event that is fired from child to display the serial number.
        let prodname = event.detail.productName;
        console.log('IP Serial/Lot Number-->' + prodname);

        getCategory({
                serialNumbers: prodname
            })
            .then(response => {
                console.log('Response***' + JSON.stringify(response));
                if (!(response === '') && (response)) {
                    this.ipCategory = response.SVMXC__Product__r.Product_Category__c;
                    this.ipId = response.Id;
                    this.ipConnectivityStatus = response.Proactive_Connectivity_Status__c;
                    this.isGenotypingCategory(this.ipCategory);
                    this.isMappedCategory(this.ipCategory,'');
                    console.log('****'+this.ipCategory+'****'+this.ipId+'***'+this.ipConnectivityStatus);
                } else {
                    showErrorToast('Invalid Installed Product selected,Check its product & category');
                }
            }).catch(error => {
                console.log('entered exception' + error.body.message + '**' + error.body.exceptionType);
                //catch the error and show it as a toast message.                
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
     * Method Name: closeRecInfoForm
     * Description: This method is used to save the metrics after been previewed 
     *               
     */

    closeRecInfoForm() {
        this.displayEachRecInfo = false;
        //this.renderIPResults = false;
    }

    /*
     * Method Name: closeApSelectionSection
     * Description: This method is used to close the Additional Product selection section
     *               
     */

    closeApSelectionSection() {
        this.selectAssociatedProducts = false;
		this.displayEachRecInfo = false;
    }


    /*
     * Method Name: resetData
     * params: event
     * Description: This method is used to reset the data , so that the start date ,end date and Installed Product switched back to 
     *              original values even after changed on UI
     *               
     */

    resetData() {

        console.log('Inside Reset Data');

        this.renderIPResults = false;
        this.displayEachRecInfo = false;
        this.selectAssociatedProducts = false;

        this.template.querySelectorAll('lightning-input').forEach(function(element) {

            if (element.name === 'Start_Date') {
                console.log('startdate' + this.dateBehind);
                element.value = this.dateBehind;
            }
        }, this);

        this.template.querySelectorAll('lightning-input').forEach(function(element) {

            if (element.name === 'Endng_Date') {
                console.log('endingdate' + this.dateTodays);
                element.value = this.dateTodays;
            }
        }, this);

        this.connectedCallback();
        console.log('Fetching the current record IP-' + this.ipName);

    }

    /*
     * Method Name: calculatedateBehind
     * params: event
     * Description: This method stamps the date which is 7 days behind to the current date into dateBehind
     *               
     */

    calculatedateBehind() {
        console.log('entered date cal***');
        let myCurrentDate = new Date();
        let myPastDate = new Date(myCurrentDate);
        myPastDate.setDate(myPastDate.getDate() - 7);
        this.dateBehind = myPastDate.getFullYear() + '-' + (myPastDate.getMonth() + 1) + '-' + myPastDate.getDate();
        console.log('myPastDate***' + this.dateBehind + '****' + this.dateTodays);

    }

    notesChange(event){
        console.log('Entered Notes in UI');
        this.runNotes= event.target.value;
    }
}
import {
    LightningElement,
    api,
    wire,
    track
} from 'lwc';
import {
    getRecord
} from 'lightning/uiRecordApi';
import {
    refreshApex
} from '@salesforce/apex';
import {
    loadScript
} from 'lightning/platformResourceLoader';

import tableauJSAPI from '@salesforce/resourceUrl/TableauJSAPI';

import {
    isBlank,
    consoleLog,
    isEmpty,
    isNotNull,
    isNotBlank,
    getEncodedParams
} from 'c/utils';

export default class TableauEmbedder extends LightningElement {
    //design parameters start
    @api strobjectApi;
    @api recordId;
    @api strTableauURL;
    @api intHeight;
    @api booHideTab;
    @api booHideToolbar;
    @api strFilters;
    @api strField; //dummy not to be used. Put to make configuration on lightning record page easier
    @api strReportName;
    //design parameters end

    @api lstFields;//parsed fields
    @track booConfigurationProper = false;//if true will show list of errors
    @api mapParamField = new Map();//map of param name and respective key
    @track lstErrors = [];
    @api intErrorCounter = 1;//key for list of errors
    @track booLoading = false;//control spinner
    
    @track recordDetails;//for refresh apex

    viz;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$lstFields'
    })
    wiredRecord(response) {
        this.recordDetails = response;
        consoleLog('Details fetched', response);
        let strFinalURL = this.strTableauURL;
        if (isNotNull(response.error)) { //loading data had issues so show on screen
            this.booConfigurationProper = false; //show error section in markup
            if (Array.isArray(response.error.body)) {
                response.error.body.forEach(element => {
                    this.addError(element.message);
                });
            } else if (typeof response.error.body.message === 'string') {
                this.addError(response.error.body.message);
            } else {
                this.addError(JSON.stringify(response.error));
            }
        } else { //loading data was success
            if (isNotBlank(this.strFilters)){
                let fieldsInfo =response.data.fields;
                let booFirstParam=true;
                Object.keys(this.mapParamField).forEach(strParamKey => {
                    let strValue;
                    if(fieldsInfo[this.mapParamField[strParamKey]]){
                        strValue=fieldsInfo[this.mapParamField[strParamKey]].value;
                        if(strParamKey.includes('Percent') && !isNaN(strValue))
                            strValue=strValue/100;
                    }else{
                        this.booConfigurationProper=false;
                        this.addError('Field '+this.mapParamField[strParamKey]+' not found');
                        return;
                    }
                    if(isNotNull(strValue)){
                        let strParam = getEncodedParams(strParamKey,strValue);
                        consoleLog('strParamKey: '+strParamKey);
                        consoleLog('strParam: '+strParam);
                        if(booFirstParam){//for first param don't prefix
                            strFinalURL+=strParam;
                            booFirstParam=false;
                        }else
                            strFinalURL+='&'+strParam;
                    }
                });
            }
        }
        if (isNotBlank(this.strFilters) && this.booConfigurationProper)
            this.loadTableau(strFinalURL);
        this.booLoading = false;
    }

    async connectedCallback() {
        await loadScript(this, tableauJSAPI);
        this.setFields();
        if (this.booConfigurationProper) {
            if (isNotBlank(this.strFilters))
                this.reloadRecordDetails();
            else
                this.loadTableau(this.strTableauURL);
        }
    }

    setFields() {
        this.lstFields = [];
        if (isBlank(this.strFilters)) {
            this.lstFields.push(this.strobjectApi + '.Name');
            consoleLog('default load: ', this.lstFields);
            this.booConfigurationProper = true;
            return;
        }
        consoleLog('setting fields');
        let lstFieldExpressionSplit = this.strFilters.split("|"); //get the different expressions for URL parameters
        lstFieldExpressionSplit.forEach(element => {
            let lstFieldValues = element.split('=');
            if (lstFieldValues.length != 2 || isBlank(lstFieldValues[1].trim())) { //each expression should be split to an array of 2
                this.addError('Could not parse expression: ' + element);
            } else {
                this.mapParamField[lstFieldValues[0].trim()] = lstFieldValues[1].trim();
                this.lstFields.push(this.strobjectApi + '.' + lstFieldValues[1].trim());
            }
        });
        if (isEmpty(this.lstErrors)) {
            this.booConfigurationProper = true;
        }
    }

    addError(strMessage) { //add message to list of errors. Can't keep in util because of dependency of error counter in this JS
        let strError = {
            intIndex: this.intErrorCounter++,
            strValue: strMessage
        };
        this.lstErrors.push(strError);
    }

    reloadRecordDetails() { //re-trigger wire now that the fields are set.
        this.booLoading = true;
        refreshApex(this.recordDetails);
        
    }

    loadTableau(strFinalURL){
        this.booLoading = false;
        let context = this;
        setTimeout(function(){
            context.renderTableauFrame(strFinalURL,context);
        },20);
    }

    renderTableauFrame(strFinalURL,context) { //rendering of the tableau component happens here
        const containerDiv = context.template.querySelector('div.tableauFrame');
        consoleLog('strFinalURL: ' + strFinalURL);
        const urlToLoad = new URL(strFinalURL);
        //set Dimensions
        containerDiv.style.height = `${context.intHeight}px`;
        const intWidth = containerDiv.offsetWidth;
        urlToLoad.searchParams.append(':size', `${intWidth},${context.intHeight}`);
        //set options
        const options = {
            hideTabs: context.booHideTab,
            hideToolbar: context.booHideToolbar,
            height: `${context.intHeight}px`,
            width: '100%'
        };

        const strURL = urlToLoad.toString();
        consoleLog('vizURLString' + strURL);

        context.viz = new tableau.Viz(containerDiv, strURL, options);
    }

    
}
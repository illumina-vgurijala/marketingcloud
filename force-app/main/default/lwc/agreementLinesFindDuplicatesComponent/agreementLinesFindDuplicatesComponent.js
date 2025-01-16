import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import modal from '@salesforce/resourceUrl/customModalCss';
import { loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import getDuplicateAgreementLines from '@salesforce/apex/AgreementLinesFindDuplicatesController.getDuplicateAgreementLines';
import { consoleLog,isNotEmpty,consoleError } from 'c/utils';

const column = [{
    label: 'Agreement Number',
    fieldName: 'agreemementId',
    type: 'url',

    typeAttributes: {
        label: {
            fieldName: 'agreementNumber'
        },
        tooltip: {
            fieldName: 'agreementNumber'
        },
        target: '_blank'
    },
    sortable: false
},
{
    label: 'Line Type',
    fieldName: 'lineType'
},
{
    label: 'Customer ERP Number',
    fieldName: 'customerERPNumber'
},
{
    label: 'Price Group',
    fieldName: 'priceGroup'
},
{
    label: 'Sales Org',
    fieldName: 'salesOrg'
},
{
    label: 'Distribution Channel',
    fieldName: 'distributionChannel'
},
{
    label: 'Material Number',
    fieldName: 'materialNumber'
},
{
    label: 'Material Group 1',
    fieldName: 'materialGroup'
},
{
    label: 'Ultimate Consignee ERP Number',
    fieldName: 'ucERPNumber'
},
{
    label: 'Current Discount',
    fieldName: 'discount'
},
{
    label: 'Current Discount Type',
    fieldName: 'discountType'
},
{
    label: 'Existing Discount',
    fieldName: 'existingDiscount'
},
{
    label: 'Existing Discount Type',
    fieldName: 'existingDiscountType'
},
{
    label: 'End Date',
    fieldName: 'endDate'
}
];
export default class AgreementLinesFindDuplicatesComponent extends LightningElement {
    @api recordId;
    @track column = column;
    @track booLoaded = false;
    @track showErrorMessage = false;
    @track lstDuplicateAgreementLines = [];
    @track wiredResults;
    errorMessageToDisplay = '';

    connectedCallback() {
        loadStyle(this, modal);
    }
    @wire(
        getDuplicateAgreementLines, {
            agreementId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            consoleLog('Data returned from apex =>', this.wiredResults.data);
            let returnData = JSON.parse(this.wiredResults.data);
            this.lstDuplicateAgreementLines = returnData.duplicates;
            
            if(returnData.strMessage)
            {
                this.showErrorMessage = true;
                this.errorMessageToDisplay = returnData.strMessage;
            }
        } else if (result.error) {
            consoleError('Error Returned : ', JSON.stringify(result.error));
            this.showErrorMessage = true;
            this.errorMessageToDisplay = JSON.stringify(result.error);          
        }
        this.booLoaded = true;
    }
    get showDataTable() {        
        return isNotEmpty(this.lstDuplicateAgreementLines);
    }
    closeModal(event) {
        console.log('closeModal clicked');
        this.lstDuplicateAgreementLines = [];
        this.showErrorMessage = false;
        this.errorMessageToDisplay = '';
        refreshApex(this.wiredResults);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    exportDataHandler(event) {
        let agreementLineHeaders = {
            agreementLineID : 'Agreement Line Item Id',
            agreementLineName : 'Agreement Line Item Name',
            agreemementId : 'Agreement Id',
            agreementName : 'Agreement Name',
            agreementNumber : 'Agreement Number',
            lineType : 'Line Type',
            customerERPNumber : 'Customer ERP Number',
            salesOrg : 'Sales Org',
            distributionChannel : 'Distribution Channel',
            currencyValue : 'CurrencyIsoCode',
            materialNumber : 'Material Number',
            discountPercent : 'Discount In Percent',
            discount : 'Current Discount',
            discountType : 'Current Discount Type',            
            existingDiscount : 'Existing Discount',
            existingDiscountType : 'Existing Discount Type',
            startDate : 'Start Date',
            endDate : 'End Date',
            discontinued : 'Discontinued',
            materialGroup : 'Material Group',
            priceGroup : 'Price Group',
            ucERPNumber : 'Ultimate Consignee ERP Number',
            partnerRole : 'Partner Role'
        }
        this.exportCSVFile(agreementLineHeaders, this.lstDuplicateAgreementLines, 'duplicate_agreement_lines_export')
    }
    exportCSVFile(headers, totalData, fileTitle) {
        if(!totalData || !totalData.length){
            return null;
        }
        let originalJsonObject = JSON.stringify(totalData);        
        const jsonObject = originalJsonObject.replace(/\//g, '');

        const result = this.convertToCSV(jsonObject, headers);
        if(!result){
            return null;
        }
        const blob = new Blob([result]);
        const exportedFileName = fileTitle? fileTitle+'.csv':'export.csv';
        if(navigator.msSaveBlob){
            navigator.msSaveBlob(blob, exportedFileName);
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
            const link = window.document.createElement('a');
            link.href='data:text/csv;charset=utf-8,' + encodeURI(result);
            link.target = '_blank';
            link.download=exportedFileName;
            link.click();
        } else {
            const link = window.document.createElement('a');
            if(link.download !== undefined){
                const url = URL.createObjectURL(blob);
                link.setAttribute('href', url);
                link.setAttribute('download', exportedFileName);
                link.style.visibility='hidden';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        }
    }
    convertToCSV(objArray, headers){
        const columnDelimiter = ',';
        const lineDelimiter = '\r\n';
        const actualHeaderKey = Object.keys(headers);
        const headerToShow = Object.values(headers);
        
        let str = '';
        str+=headerToShow.join(columnDelimiter);
        str+=lineDelimiter;
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray;
        data.forEach(obj=>{
            let line ='';
            actualHeaderKey.forEach(key=>{
                if(line !==''){
                    line+=columnDelimiter;
                }
                
                let strItem = obj[key] ? obj[key]+'': '';
                let newValueOfItem = strItem ? strItem.replace(/,/g, ''):strItem;
                
                if(key === 'agreementNumber')
                {
                    newValueOfItem = newValueOfItem ? '="'+newValueOfItem+'"' : newValueOfItem;
                }
                line += newValueOfItem;  
            })
            str+=line+lineDelimiter;
        })
        return str;
    }        
}
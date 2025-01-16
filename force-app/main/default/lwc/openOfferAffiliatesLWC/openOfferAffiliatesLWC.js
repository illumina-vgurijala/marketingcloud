import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { lstAffliateColumns, mapColumnNameToIconName } from './columns.js';
import { loadStyle } from 'lightning/platformResourceLoader';
import modal from '@salesforce/resourceUrl/customModalCss';
import { callServer,showErrorToast,showSuccessToast,isEmpty,isNotEmpty,isNull,isNotNull,consoleError,consoleLog} from 'c/utils';
import loadPage from '@salesforce/apex/OpenOfferAffiliationController.loadPage';
import upsertAffiliates from '@salesforce/apex/OpenOfferAffiliationController.upsertAffiliates';
import { refreshApex } from '@salesforce/apex';

export default class OpenOfferAffiliatesLWC extends LightningElement {    
    columns = lstAffliateColumns;
    mapLabels;    
    boolShowSpinner = true;
    boolComponentReadOnly = false;
    @api recordId;
    @track wiredResults;
    @track affiliateAccountsToBeIncluded = [];
    @track affiliateAccountsToBeExcluded = [];
    @track affiliateAccountsNotInHierarchy = [];
    @track originalAffiliateAccountsToBeIncluded = [];
    @track originalAffiliateAccountsToBeExcluded = [];
    @track originalAffiliateAccountsNotInHierarchy = [];

    connectedCallback() {
        loadStyle(this, modal);
    }

    @wire(
        loadPage, {
            strAgreementId: '$recordId'
        }
    )
    imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            let returnData = JSON.parse(this.wiredResults.data);
            this.mapLabels = returnData.mapLabels;
            this.boolComponentReadOnly = returnData.boolComponentReadOnly;
            this.segregateAffiliates(returnData.lstOpenOfferAffiliatesWrapper,returnData.lstCustomerERPsInHierarchy, returnData.mapERPCustomerIdToAccount, returnData.lstAffiliateERPIds);
            this.boolShowSpinner = false;
        } else if (result.error) {
            consoleError('Error Returned : ', JSON.stringify(result.error));
            this.boolShowSpinner = false;
        }
    }

    segregateAffiliates(allAffiliates, allAccountsInHierarchy, mapERPCustomerIdToAccount,lstAffiliateERPIds) {                    
        if(isNotNull(mapERPCustomerIdToAccount)) {
            let affiliatesPostInsertScenarioAddition = this.updateAffiliateListForInsertScenario(allAffiliates,mapERPCustomerIdToAccount,lstAffiliateERPIds);
            this.createAllAffiliatesTables(affiliatesPostInsertScenarioAddition,allAccountsInHierarchy);
        } else {
            this.createAllAffiliatesTables(allAffiliates,allAccountsInHierarchy);
        }
    }
    
    updateAffiliateListForInsertScenario(existingAffiliates,mapERPCustomerIdToAccount,lstAffiliateERPIds) {
        // any new affiliate added here will be for an account which is not present in agreement account relationship, 
        // but got added to Account hierarchy, so it needs to be added to affiliates list without an Id

        let counter = isNull(existingAffiliates) ? 0 : existingAffiliates.length;
        
        Object.keys(mapERPCustomerIdToAccount)?.forEach((strERPCustomerId) => {
            if(!lstAffiliateERPIds.includes(strERPCustomerId)) {
                let affiliate = Object.create({});
                affiliate.id = null;
                affiliate.includeInAnnualConsumableSpend = false;
                affiliate.considerForGFDiscountCalculation = false;
                affiliate.optInReceivingOpenOfferDiscount = false;
                affiliate.accountName = mapERPCustomerIdToAccount[strERPCustomerId]?.Name;
                affiliate.accountId = '/'+mapERPCustomerIdToAccount[strERPCustomerId]?.Id;
                affiliate.customerERPNumber = strERPCustomerId;
                affiliate.intIndex = counter === 0 ? 0 : counter;
                counter+= 1;
                existingAffiliates.push(affiliate);             
            }
        });

        return existingAffiliates;
    }

    createAllAffiliatesTables(allAffiliates,allAccountsInHierarchy) {
        let affiliatesToBeIncluded = [];
        let affiliatesToBeExcluded = [];
        let affiliatesNotInHierarchy = [];

        allAffiliates.forEach(objAffiliate => {
            let affiliate = JSON.parse(JSON.stringify(objAffiliate));      
            let boolAffiliateNotInHierarchy = isNotEmpty(allAccountsInHierarchy) && !allAccountsInHierarchy.includes(affiliate.customerERPNumber) && isNotNull(objAffiliate.id);
            
            if(boolAffiliateNotInHierarchy) {                
                affiliate = this.updateAffiliateDetails(affiliate);
                affiliate.tableName = 'affiliateAccountsNotInHierarchy';               
                affiliatesNotInHierarchy.push(affiliate);
            } else if(!boolAffiliateNotInHierarchy && affiliate.optInReceivingOpenOfferDiscount && isNotNull(affiliate.id)) {                
                affiliate = this.updateAffiliateDetails(affiliate);
                affiliate.tableName = 'affiliateAccountsToBeIncluded';
                affiliatesToBeIncluded.push(affiliate);
            } else if((!boolAffiliateNotInHierarchy && !affiliate.optInReceivingOpenOfferDiscount) || isNull(affiliate.id)) {                
                affiliate = this.updateAffiliateDetails(affiliate);
                affiliate.tableName = 'affiliateAccountsToBeExcluded';
                affiliatesToBeExcluded.push(affiliate);
            }
        });

        this.affiliateAccountsToBeIncluded = affiliatesToBeIncluded;
        this.affiliateAccountsToBeExcluded = affiliatesToBeExcluded;
        this.affiliateAccountsNotInHierarchy = affiliatesNotInHierarchy;

        this.originalAffiliateAccountsToBeIncluded = affiliatesToBeIncluded;
        this.originalAffiliateAccountsToBeExcluded = affiliatesToBeExcluded;
        this.originalAffiliateAccountsNotInHierarchy = affiliatesNotInHierarchy;    
    }

    updateAffiliateDetails(affiliateRecord) {        
        Object.keys(mapColumnNameToIconName).forEach(fieldName => {
            const fieldValue = affiliateRecord[fieldName];
            const iconValue = this.getIconClass(fieldValue);
            const iconFieldName = mapColumnNameToIconName[fieldName];
            affiliateRecord[iconFieldName] = iconValue;
        });
        return affiliateRecord;
    }

    getSelectedRow(event) {
        if(this.boolComponentReadOnly) { return; }
        const selectedRow = event.detail.row;
        const columnName = event.detail.action.class.fieldName;
        const tableName = selectedRow.tableName;
        const indexValue = selectedRow.intIndex;         
                
        const elementIndex = this[tableName].findIndex(item => item.intIndex === indexValue);
        const affiliate = this[tableName][elementIndex]; // get the affiliate record after identifying the correct Table and index
        affiliate[columnName] = !affiliate[columnName]; // toggle the value in affiliate data for the given field
        const iconName = mapColumnNameToIconName[columnName];  // get the right icon name mapping based on column Name
        affiliate[iconName] = this.getIconClass(affiliate[columnName]);  // get the right icon style and then assign it to the affiliate record's icon value
        this[tableName][elementIndex] = affiliate; // update the record in the selected table
        this[tableName] = JSON.parse(JSON.stringify(this[tableName]));  // update the table to re render the component
    }

    getIconClass(value) {
        return value === true ? 'action:approval' : 'action:remove';
    }

    saveRecords(event) {
        
        this.boolShowSpinner = true;
        const affiliatesRowsToBeDeleted = this.template.querySelector("[data-field='affiliatesNotInNGN']")?.getSelectedRows();              
        const affiliatesUpdateList = [];
        const optedInAffiliatesList = [];
        [...this.affiliateAccountsToBeIncluded, ...this.affiliateAccountsToBeExcluded].forEach(affiliate => {
            const finalAffiliate = Object.create({});
            finalAffiliate.id = affiliate.id;
            finalAffiliate.Include_In_Annual_Consumable_Spend__c = affiliate.includeInAnnualConsumableSpend;
            finalAffiliate.Consider_for_GF_Discount_Calculation__c = affiliate.considerForGFDiscountCalculation;
            finalAffiliate.Opt_In_Receiving_Open_Offer_Discount__c = affiliate.optInReceivingOpenOfferDiscount;
            
            if(isNull(affiliate.id)) {
                finalAffiliate.Agreement__c = this.recordId;
                finalAffiliate.Account__c = affiliate.accountId.replace('/','');
            }            
            affiliatesUpdateList.push(finalAffiliate);
            if(finalAffiliate.Opt_In_Receiving_Open_Offer_Discount__c) {
                optedInAffiliatesList.push(finalAffiliate);
            }
        });

        if(isEmpty(optedInAffiliatesList)) {
            showErrorToast(this.mapLabels.UI_Message_Affiliate_Selection_Error);
            this.boolShowSpinner = false;
            return ;
        }

        const affiliatesDeletionList = affiliatesRowsToBeDeleted?.map(affiliate => {
            const finalAffiliate = Object.create({});
            finalAffiliate.id = affiliate.id;
            return finalAffiliate;
        });
     
        consoleLog('final lists before sending to apex ');
        consoleLog('affiliatesUpdateList ::: ',affiliatesUpdateList);
        consoleLog('affiliatesDeletionList ::: ',affiliatesDeletionList);
        
        callServer(upsertAffiliates, {
            affiliatesUpdateList : JSON.stringify(affiliatesUpdateList),
            affiliatesDeletionList : JSON.stringify(affiliatesDeletionList)
        }, result => {
            this.boolShowSpinner = false;
            showSuccessToast(this.mapLabels.UI_Message_Affiliates_Saved);
            this.refreshData();
            this.closeAction();
        }, error => {                
            consoleError('Error in server call for upsertAffiliates ::: ', JSON.stringify(error));
            this.boolShowSpinner = false;                               
        });           
    }

    closeModal() {
        this.affiliateAccountsToBeIncluded = this.originalAffiliateAccountsToBeIncluded;
        this.affiliateAccountsToBeExcluded = this.originalAffiliateAccountsToBeExcluded;
        this.affiliateAccountsNotInHierarchy = this.originalAffiliateAccountsNotInHierarchy;
        this.closeAction();
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    refreshData() {
        this.boolShowSpinner = true;
        refreshApex(this.wiredResults);
    }
    get showAffiliatesInclusionTable() {
        return isNotEmpty(this.affiliateAccountsToBeIncluded);
    }
    
    get showAffiliatesExclusionTable() {
        return isNotEmpty(this.affiliateAccountsToBeExcluded);
    }

    get showAffiliatesNotInHierarchyTable() {
        return isNotEmpty(this.affiliateAccountsNotInHierarchy);
    }
}
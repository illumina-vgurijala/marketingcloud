import { LightningElement, track, api, wire } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import WrappedHeaderTable from "@salesforce/resourceUrl/WrappedHeaderTable";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import hasUserPermissionAndAccess from '@salesforce/apex/ViewSalesMarginDataController.hasUserPermissionAndAccess';
import getMarginAnalysis from '@salesforce/apex/ViewSalesMarginDataController.getMarginAnalysis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UI_Text_Error_Missing_Permission_To_View_Margin_Data from '@salesforce/label/c.UI_Text_Error_Missing_Permission_To_View_Margin_Data';
import UI_Text_Sandbox_Error_To_View_Margin_Data from '@salesforce/label/c.UI_Text_Sandbox_Error_To_View_Margin_Data';
import UI_Text_Error_TargetMarginFailed from '@salesforce/label/c.UI_Text_Error_TargetMarginFailed';
import UI_Text_Error_CoGsFailed from '@salesforce/label/c.UI_Text_Error_CoGsFailed';
import UI_Text_BudgetFX_Rate_USD_to_Local from '@salesforce/label/c.UI_Text_BudgetFX_Rate_USD_to_Local';
import UI_Text_LineItemLevelAnalysis from '@salesforce/label/c.UI_Text_LineItemLevelAnalysis';
import UI_Text_NetMargin from '@salesforce/label/c.UI_Text_NetMargin';
import UI_Text_StandardMarginAtListPrice from '@salesforce/label/c.UI_Text_StandardMarginAtListPrice';
import UI_Text_StandardMarginAtQuoteProposedPrice from '@salesforce/label/c.UI_Text_StandardMarginAtQuoteProposedPrice';
import UI_Text_ProductLineLevelAnalysis from '@salesforce/label/c.UI_Text_ProductLineLevelAnalysis';
import UI_Text_StandardMarginAtChannelPartnerPrice from '@salesforce/label/c.UI_Text_StandardMarginAtChannelPartnerPrice';
import Indirect_Direct_UC_Quote from '@salesforce/label/c.Indirect_Direct_UC_Quote';
import Direct_Quote from '@salesforce/label/c.Direct_Quote';
import Indirect_Quote from '@salesforce/label/c.Indirect_Quote';
import UI_Text_StandardProfit from '@salesforce/label/c.UI_Text_StandardProfit';
import { consoleLog, consoleError } from 'c/utils';

import {
    indirectColumns,
    directToUCcolumns,
    directColumns,
    lineLevelColumns
} from './column.js';

export default class ViewSalesMarginDataLWC extends NavigationMixin(LightningElement) {
    @api quoteId;
    @api approvalRequestId;
    indirectColumns = indirectColumns;
    directToUCcolumns = directToUCcolumns;
    directColumns = directColumns;
    lineLevelColumns = lineLevelColumns;
    userHasQuotePermission;
    userHasViewMarginPermission;
    userGroupErrorInSandbox = false;
    showQuotePermissionError = false;
    isSandbox = false;
    isSubstituteUser = false;
    hasGroupAccess = false;
    columnMinWidthSet = false;
    boolShowTargetMarginError = false;
    boolShowCoGsError = false;
    @track loading = true;
    @track quoteAndLineDetails = [];
    @track approvalRejectLink = '';
    @track quoteLink = '';

    errorMsg = UI_Text_Error_Missing_Permission_To_View_Margin_Data;
    errorSandboxMsg = UI_Text_Sandbox_Error_To_View_Margin_Data;
    UI_Text_BudgetFX_Rate_USD_to_Local = UI_Text_BudgetFX_Rate_USD_to_Local;
    UI_Text_LineItemLevelAnalysis = UI_Text_LineItemLevelAnalysis;
    UI_Text_NetMargin = UI_Text_NetMargin;
    UI_Text_StandardMarginAtListPrice = UI_Text_StandardMarginAtListPrice;
    UI_Text_StandardMarginAtQuoteProposedPrice = UI_Text_StandardMarginAtQuoteProposedPrice;
    UI_Text_ProductLineLevelAnalysis = UI_Text_ProductLineLevelAnalysis;
    UI_Text_StandardMarginAtChannelPartnerPrice = UI_Text_StandardMarginAtChannelPartnerPrice;
    UI_Text_Error_TargetMarginFailed = UI_Text_Error_TargetMarginFailed;
    UI_Text_Error_CoGsFailed = UI_Text_Error_CoGsFailed;
    UI_Text_StandardProfit = UI_Text_StandardProfit;


    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.quoteId = currentPageReference.state.c__quoteId;
            this.approvalRequestId = currentPageReference.state.c__approvalRequestId;
            this.approvalRejectLink = '/apex/CustomQuoteApprovalSummary?id='+this.approvalRequestId+'&pageMode=approveReject' + '&sObjectId=' + this.quoteId;
            this.quoteLink = '/' + this.quoteId;
            if (this.quoteId) {
                this.checkUserPermission();
            }
        }
    }
    renderedCallback() {
        if (!this.stylesLoaded) {
            Promise.all([loadStyle(this, WrappedHeaderTable)])
                .then(() => {
                    consoleLog("Custom styles loaded");
                    this.stylesLoaded = true;
                })
                .catch((error) => {
                    consoleError("Error loading custom styles");
                });
        }

        if(!this.columnMinWidthSet){
            const someDataTable = this.template.querySelector('.ltngtable');
            if(someDataTable ){            
                someDataTable.minColumnWidth = someDataTable.minColumnWidth <= 50 ? 100 : someDataTable.minColumnWidth;
                this.columnMinWidthSet = true;
            }
        }
    }

    connectedCallback() {
        
    }

    checkUserPermission() {
        hasUserPermissionAndAccess({ quoteId: this.quoteId })
            .then(result => {
                if (result) {
                    for (let key in result) {
                        consoleLog('key---> ', key, result[key]);
                        this.userHasQuotePermission = result['hasAccess'];
                        this.userHasViewMarginPermission = result['hasPermission'];
                        this.isSandbox = result['isSandbox'];
                        this.isSubstituteUser = result['isSubstituteUser'];
                        this.hasGroupAccess = result['hasGroupAccess'];
                    }
                    //DGP-502: below logic checks error message from DGP-497 and DGP-502
                    if(!this.isSandbox){
                       this.runProdChecks()
                    } else{
                        this.runSandboxChecks()
                    }
                } else {
                    this.userHasQuotePermission = false;
                }
            })
            .catch(error => {
                consoleError(error);
                this.userHasQuotePermission = false;
                //this.loading = false;
                //this.showError();
            })            
    }

    runProdChecks(){
        if(this.userHasQuotePermission && this.userHasViewMarginPermission) {
            this.loadQuoteData();
        } else if(!this.userHasQuotePermission || !this.userHasViewMarginPermission) {
            this.showQuotePermissionError = true;
            this.loading = false;
        }
    }

    runSandboxChecks(){
        if(this.userHasQuotePermission && !this.isSubstituteUser && this.hasGroupAccess && this.userHasViewMarginPermission) {
            consoleLog('userHasQuotePermission isSandbox isSubstituteUser hasGroupAccess---> ', this.userHasQuotePermission, this.isSandbox, this.isSubstituteUser, this.hasGroupAccess);
            this.loadQuoteData();
        } else {
            if(!this.userHasQuotePermission || !this.userHasViewMarginPermission){
                this.showQuotePermissionError = true;
                this.loading = false;
            }
            if(!this.hasGroupAccess || this.isSubstituteUser){
                this.userGroupErrorInSandbox = true;
                this.loading = false;
            }
        }
    }

    loadQuoteData() {
        this.loadQuoteLineItems();
    }

    loadQuoteLineItems() {
        getMarginAnalysis({ quoteId: this.quoteId})
            .then(result => {
                result.lineItems.sort((a, b) => b.standardCogsSort - a.standardCogsSort);
                result.productLines.sort((a, b) => b.productLineSortBy - a.productLineSortBy);
                this.quoteAndLineDetails = result;
                this.UI_Text_BudgetFX_Rate_USD_to_Local = UI_Text_BudgetFX_Rate_USD_to_Local.replace('Local Currency', this.quoteAndLineDetails.currencyIsoCode);
                this.UI_Text_LineItemLevelAnalysis = UI_Text_LineItemLevelAnalysis.replace('Local Currency', this.quoteAndLineDetails.currencyIsoCode);
                this.UI_Text_StandardProfit = UI_Text_StandardProfit.replace('Local Currency', this.quoteAndLineDetails.currencyIsoCode);
                this.boolShowTargetMarginError = this.quoteAndLineDetails.boolShowTargetMarginError;
                this.boolShowCoGsError = this.quoteAndLineDetails.boolShowCogsError;
                consoleLog('MarginAnalysis > ' + JSON.stringify(result));
            })
            .catch(error => {
                consoleError(error);
            })
            .finally(() => {
                this.loading = false;
            })
    }

    showError() {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: UI_Text_Error_Missing_Permission_To_View_Margin_Data,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    get isDirectQuote() {
        return this.quoteAndLineDetails.quoteType === Direct_Quote;
    }

    get isDirectToUCQuote() {
        return this.quoteAndLineDetails.quoteType === Indirect_Direct_UC_Quote;
    }

    get isIndirectQuote() {
        return this.quoteAndLineDetails.quoteType === Indirect_Quote;
    }

    get hasPermission(){
       return this.userHasQuotePermission && this.userHasViewMarginPermission && !this.loading && !this.userGroupErrorInSandbox && !this.showQuotePermissionError
    }

    get permissionErrorInSandbox(){
        return this.userGroupErrorInSandbox && !this.loading
    }

    get noPermissionOrAccess(){
        return this.showQuotePermissionError && !this.loading
    }
}
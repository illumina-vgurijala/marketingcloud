/**
*    @author Roopal Verma
*    @date   2021-03-18
*    @description   Add Product Flows for quick cart
*    Modification Log:
*    Test coverage 75% :- TestApttusAddProduct
*    Test coverage 90% :- TestApttusAddProduct
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                    Description
*       Roopal Verma                 18-03-2021                 Initial Version
*       Rishab Wali                  25-06-2021                 DCP-45399 Adding Exception Handing
*       Khushbu Vasani               24-Nov-2021                TASK0672536 : price override based on new custom permission and for ops quoting user
*       Arif,Dalali                  2022-sep-12                CMSI-205 Instrumentation 
*       Aman Tyagi                   12-Dec-2022                CodeScan Fixes 
------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusCreateQuickQuoteController{
    public static Id oppId ;
    public static String priceListId;
    public static boolean hasError {get; set;}
    public static String opptyId {get; set;}
    public static String baseUrl {get; set;}
    private static final string SL_APTTUS_ALLOW_PRICE_OVERRIDE = 'SL_Apttus_Allow_Price_Override';
    private static final String LOG_TITLE = 'ApttusCreateQuickQuoteController';

    /**
     * Constructor Method to assign pricelist from Opportunity
     */
    public ApttusCreateQuickQuoteController() {
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE+'.ApttusCreateQuickQuoteController()');
        oppId = ApexPages.currentPage().getParameters().get('oppId');
        opptyId = oppId;
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        Set<Id> setOppId = new Set<Id>();        // <-- Roopal
        setOppId.add(oppId);

        List<Opportunity> lstOpp = new OpportunitySelector().selectOpportunities(setOppId);
        Set<String> setPriceListNames = UtilsCollection.getSetOfStrings(lstOpp, 'Price_List__c');
        String strPriceListName = lstOpp[0].Price_List__c;
        ilib_LogEvent.info('setPriceListNames :' +setPriceListNames);
        ilib_LogEvent.info('strPriceListName :' +strPriceListName);
        Map<String, Apttus_Config2__PriceList__c> mpNameToPriceLists =  new ApttusPriceListsSelector().selectActive(setPriceListNames);
        if(mpNameToPriceLists.containsKey(strPriceListName)) {          // --> Getting Price list from opp 
            priceListId = mpNameToPriceLists.get(strPriceListName).Id;
        }
        ilib_LogEvent.info('priceListId :' +priceListId);
        ilib_LogEvent.pop();
    }

    /**
     * @Method to redirect to respective flow within the cart
     */
    public static PageReference redirectToCart() {
        ilib_LogEvent.push(LOG_TITLE+'.redirectToCart()');
        
        hasError = false;
        ilib_LogEvent.info('hasError :' +hasError);
        Apttus_Proposal__Proposal__c newProposalSO = new Apttus_Proposal__Proposal__c();
        ID proposalRecordTypeID = [select ID FROM recordType where sObjectType='Apttus_Proposal__Proposal__c' AND Name = 'Proposal' LIMIT 1].Id;
        ilib_LogEvent.info('proposalRecordTypeID :'+proposalRecordTypeID);
        // API -1 : for creating proposal 
        newProposalSO = Apttus_Proposal.ProposalWebService.createProposalFromOpportunity(oppId, proposalRecordTypeID);
        system.debug('-- ' + newProposalSO );
        
        //Query can be leveraged to  obtain specific PriceList.
        newProposalSO.Apttus_QPConfig__PriceListId__c = priceListId;
		//DCP-45399 - Add Products to Opp Directly
		try{
            ApttusProposals.boolHasOppLineItems = true;
            insert newProposalSO;
        }
        Catch(Exception e)
        {
            ApexPages.addMessages(e);
            ilib_LogEvent.info('ApttusCreateQuickQuoteController' + e.getMessage() );
            ApexExceptions.emit('ApttusCreateQuickQuoteController', e,ilib_LogEvent.SALES);
            hasError = true;
            ilib_LogEvent.info('hasError :' +hasError);
            ilib_LogEvent.info('Returning Null');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return null;
        }
        
        OpportunityLineItemsSelector oppLineItemSelector = new OpportunityLineItemsSelector();
        List<OpportunityLineItem> lstOli = new List<OpportunityLineItem>();
        lstOli = oppLineItemSelector.selectOpportunityLineItems(new Set<Id>{oppId});
        
        Apttus_Proposal__Proposal__c newProposalSOUpd = [Select Id,Apttus_Proposal__Opportunity__r.RecordType.Name,Contract_Numbers__c,Quote_Sub_Type__c,Direct_Sale_to_Ultimate_Consignee__c From Apttus_Proposal__Proposal__c where id = :newProposalSO.Id];
        System.debug('&& proposal'+ newProposalSOUpd);
        ilib_LogEvent.info('&& proposal'+ newProposalSOUpd);
        String opportunityRTName = newProposalSOUpd.Apttus_Proposal__Opportunity__r.RecordType.Name;
        system.debug('Opp Record &&'+opportunityRTName);                      // <-- Roopal - Added add product controller conditions
        ilib_LogEvent.info('Opp Record &&'+opportunityRTName);
        //API - 2 for creating product configuration and navigating to cart page

        String redirectURL = '/apex/Apttus_Lightning_Page_Redirect?id=' + newProposalSOUpd.id+'&useAdvancedApproval=true';
        ilib_LogEvent.info('redirectURL :'+ redirectURL);
        String strContractnumber = newProposalSOUpd.Contract_Numbers__c;
        system.debug('Contract No &&'+strContractnumber);
        ilib_LogEvent.info('Contract No &&'+strContractnumber);
        if(lstOli.isEmpty())
        {
            if (newProposalSOUpd.Id != null)
            {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return getRedirectURL(newProposalSOUpd,opportunityRTName,redirectURL,strContractnumber);
            }
            ilib_LogEvent.info('Returning Null');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return null;
        }
        else
        {
            OpportunitySyncToQuotes.opportunitySyncToQuoteWithSharing(new List<Id> {newProposalSO.Id});
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return getRedirectURL(newProposalSOUpd,opportunityRTName,redirectURL,strContractnumber);
        }
        
    }
   
    //TASK0672536 : price override based on new custom permission and for ops quoting user
    private static Boolean checkQuotingUserOrHasPriceOveridePermission(Id currentUserProfileId)
    {
        ilib_LogEvent.push(LOG_TITLE+'.checkQuotingUserOrHasPriceOveridePermission()');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return Profiles.getCommercialOpsQuotingUserProfileId().contains(currentUserProfileId) || FeatureManagement.checkPermission(SL_APTTUS_ALLOW_PRICE_OVERRIDE);
        
    }

    /**
     * @Method to redirect to consortia flow
     */
    private static String returnConsortiaFlows(Apttus_Proposal__Proposal__c newProposalSOUpd,String opportunityRTName,String redirectURL,String strContractnumber){
        ilib_LogEvent.push(LOG_TITLE+'.returnConsortiaFlows()');
        String strReturnURL = '';
        if (newProposalSOUpd.Quote_Sub_Type__c == Label.OpportunityTypeConsortium || newProposalSOUpd.Quote_Sub_Type__c == Label.OpportunityTypeReorderConsortiumConsumable)
            {
                if (newProposalSOUpd.Direct_Sale_to_Ultimate_Consignee__c) 
                {
                    //TASK0672536 : price override based on new custom permission and for ops quoting user
                    if (opportunityRTName.contains(Label.DistributionChannelIndirect) && checkQuotingUserOrHasPriceOveridePermission(UserInfo.getProfileId()))
                        {
                            strReturnURL = redirectURL + '&flow=RegionalSalesOpsIndirectConsortiaFlow&cntrNbr_1=' + strContractnumber;
                        }
                    else
                        {
                            strReturnURL = redirectURL + '&flow=DirectSaleToUCConsortia&cntrNbr_1=' + strContractnumber;
                        }
                }
                else
                {
                    {
                        strReturnURL = redirectURL + '&flow=ConsortiaOppFlow&cntrNbr_1=' + strContractnumber;
                    }
                }
            }
        ilib_LogEvent.info('strReturnURL : ' +strReturnURL);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return strReturnURL;
    }
    
    /* Mehtod to get Redirect URL */
    public static PageReference getRedirectURL(Apttus_Proposal__Proposal__c newProposalSOUpd,String opportunityRTName,String redirectURL,String strContractnumber)
    {
        ilib_LogEvent.push(LOG_TITLE+'.getRedirectURL()');
        String strConsortiaURL = returnConsortiaFlows(newProposalSOUpd,opportunityRTName,redirectURL,strContractnumber);
        ilib_LogEvent.info('strConsortiaURL :' +strConsortiaURL);
        if(String.isNotBlank(strConsortiaURL))
        {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return new PageReference(strConsortiaURL);
        }
        //TASK0672536 : price override based on new custom permission and for ops quoting user
        Boolean userIsCommercialOps = checkQuotingUserOrHasPriceOveridePermission(UserInfo.getProfileId());
        ilib_LogEvent.info('userIsCommercialOps :' +userIsCommercialOps);
        if (opportunityRTName.contains(Label.DistributionChannelDirect))
        {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return userIsCommercialOps ?  new PageReference(redirectURL + '&flow=RegionalSalesOpsNGDefault&cntrNbr_1=' + strContractnumber) : new PageReference(redirectURL + '&flow=NGDefault&cntrNbr_1='+strContractnumber);
        }

        if (opportunityRTName.contains(Label.DistributionChannelIndirect) && newProposalSOUpd.Direct_Sale_to_Ultimate_Consignee__c)
        {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return userIsCommercialOps ? new PageReference(redirectURL + '&flow=RegionalSalesOpsIndirectOppFlow&cntrNbr_1=' + strContractnumber) : new PageReference(redirectURL + '&flow=IndirectOppFlow&cntrNbr_1=' + strContractnumber); 
        }

        if (opportunityRTName.contains(Label.DistributionChannelIndirect) && !newProposalSOUpd.Direct_Sale_to_Ultimate_Consignee__c)
        {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return userIsCommercialOps ? new PageReference(redirectURL + '&flow=RegionalSalesOpsIndirectUCFalseOppFlow&cntrNbr_1=' + strContractnumber) : new PageReference(redirectURL + '&flow=IndirectUCFalseOppFlow&cntrNbr_1=' + strContractnumber); 
        }
        ilib_LogEvent.info('Returning Null');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return null;
    }
}

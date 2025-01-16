/*
* @author Kushagra Desai
* @Date 2018-10-22
* @Description  DCP-13049: UPDATES TO - Quote Acknowledgment to DCP
Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*      Joshith K                    18 -Nov-2019        Adding Logic to Populate Promotion Json field in Quote(INC0232672)
*      Satya Swain                  07-Jan-2020         Adding logic to populate Sub Total Field for custom Quote for INC0236538 
*      Nishan Shetty                22-April-2022       CodeScan Fix Avoid Literals in If condition.
*      Prem Ranjan                  04 May 2022             CodeScan Fix (APEX) Unused Local Variable
*      Aman Tyagi                   31-Mar-2022         CodeScan Fixes
*      Jitesh Lakhwani              25-July-2022        DCP-54361 : Show Applied Promo's on Quote Header level.
*    -----------------------------------------------------------------------------------------------------------------------------
*/
@RestResource(urlMapping='/QuotationSyncInterface/')
global with sharing class QuotationDataReceiver extends ilib_RestReceiver {

    private static List<QuotationDataRecieverWrapper.QuoteWrapper> lstQuoteWrapper;

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final Integer INTEGER_TWO = 2;
    private static final Integer INTEGER_THREE = 3;
    private static final Integer INTEGER_FOUR = 4;
    private static final Integer INTEGER_FIVE = 5;

    public static final String PROMO1 = 'Promo1'; // DCP-54361 Changes
    public static final String PROMO2 = 'Promo2'; // DCP-54361 Changes
    public static final String PROMO3 = 'Promo3'; // DCP-54361 Changes
    //END CodeScan Fix
      
    @Httppost
    /*
    * @Author: Satya Swain
    * @Description : this method has logic for upsert the incoming values
    * @param : null
    * @return : void
    */
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        QuotationDataReceiver instantiated = new QuotationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, lstQuoteWrapper);

            primaryRecordId = upsertIncomingValuesImpl();
            erpCustomerId = getRelatedErpCustomerId('Apttus_Proposal__Proposal__c', 'Apttus_Proposal__Opportunity__r.Account', primaryRecordId);
        }

        catch (Exception e){
            strRestError = UtilsRest.handleCustomRestError(e);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError),
                primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        lstQuoteWrapper = (List<QuotationDataRecieverWrapper.QuoteWrapper>) System.JSON.deserialize(jsonInput, List<QuotationDataRecieverWrapper.QuoteWrapper>.class);
        System.debug('QuoteWrapper::::'+lstQuoteWrapper);
    }

    private static Id upsertIncomingValuesImpl()
    {
        Apttus_Proposal__Proposal__c oneQuote;

        ilib_UpsertHelpers.QuoteUnitOfWorkHelper objQuoteWork =new ilib_UpsertHelpers.QuoteUnitOfWorkHelper();
        ilib_UpsertHelpers.QuotationLineItemUnitOfWorkHelper objQuoteLineWork=new ilib_UpsertHelpers.QuotationLineItemUnitOfWorkHelper();
        ilib_UpsertHelpers.OpportunityUnitOfWorkHelper objOpportunityWork=new ilib_UpsertHelpers.OpportunityUnitOfWorkHelper();

        Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>> mapPromo1ToLine = new Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>>();
        Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>> mapPromo2ToLine = new Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>>();
        Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>> mapPromo3ToLine = new Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>>();
        Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>> mapPromo4ToLine = new Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>>();
        Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>> mapPromo5ToLine = new Map<String,List<Apttus_Proposal__Proposal_Line_Item__c>>();

        //This will store the Incentive with promo Key Name (Example: PROMO1 -> Quote_Id_1, Incentive, PROMO2 -> Quote_Id_2,Incentive)
        Map<String, Map<Id,Apttus_Config2__Incentive__c>> promoToIdToIncentiveMap = new Map<String, Map<Id,Apttus_Config2__Incentive__c>>(); //DCP-54361
        List<Apttus_Proposal__Proposal__c> quoteSObjectList = new List<Apttus_Proposal__Proposal__c>();//DCP-54361

        ilib_SObjectUnitOfWork objUnitOfWork=new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> { Apttus_Proposal__Proposal__c.SObjectType, Apttus_Proposal__Proposal_Line_Item__c.SObjectType});

        objUnitOfWork.registerWork(objQuoteWork);
        objUnitOfWork.registerWork(objQuoteLineWork);
        objUnitOfWork.registerWork(objOpportunityWork);

        // Creation of set for ERPids
        Set<String> setCustomerDataERPIDs = new Set<String>();
        Set<String> setAccountERPIDs = new Set<String>();
        Set<Id> setOpportunityIDs = new Set<Id>();
        Set<String> setProductCode = new Set<String>();
        Set<String> setLineItem = new Set<String>();

        Decimal decSubTotalPLI = 0;

        // Adding all ERPid to set
        for (QuotationDataRecieverWrapper.QuoteWrapper objQuoteWrapper: lstQuoteWrapper)
        {
            setCustomerDataERPIDs.add(objQuoteWrapper.Ship_To);
            setCustomerDataERPIDs.add(objQuoteWrapper.Bill_To);
            setCustomerDataERPIDs.add(objQuoteWrapper.Payer);
            setAccountERPIDs.add(objQuoteWrapper.Distributor);
            setAccountERPIDs.add(objQuoteWrapper.Apttus_Proposal_Account);
            setAccountERPIDs.add(objQuoteWrapper.Ultimate_Consignee);
            setOpportunityIDs.add(objQuoteWrapper.Apttus_Proposal_Opportunity);
            if(objQuoteWrapper.Apttus_Proposal_Opportunity == null) throw new UtilsRest.InterfaceException('Opportunity Id is missing');

            for (QuotationDataRecieverWrapper.ProposalLineitemWrapper quoteLineItem :objQuoteWrapper.ProposalLineitemWrapper){
                setProductCode.add(quoteLineItem.Apttus_Proposal_Product);
                //Added by Satya for INC0236538 
                if(quoteLineItem.Apttus_QPConfig_NetPrice != null){
                    decSubTotalPLI = decSubTotalPLI + UtilsRest.convertStringToNumber(quoteLineItem.Apttus_QPConfig_NetPrice);
                }
            }

        }
        System.debug('@@@@ decSubTotalPLI: '+decSubTotalPLI);

        // Fetch List of records needed for lookup
        List<Customer_Master_Data__c> lstCustumerData = new CustomerMasterDataSelector().selectByAccountERPId(setCustomerDataERPIDs);
        List<Account> lstAccountData = new AccountsSelector().selectAccountsForERPCustomerIds(setAccountERPIDs);
        List<Product2> lstProductData = new ProductsSelector().selectProductsForMaterialNumber(setProductCode);
        List<Opportunity> lstOppsData = new OpportunitySelector().selectOpportunities(setOpportunityIDs);

        Map<id,Opportunity> idsToOpportunityId = new Map<id,Opportunity>(lstOppsData);

        Map<String,String> erpIdToCustomerId = UtilsObject.getMapOfStringToString(lstCustumerData,'ERP_Customer_Id__c','id');
        Map<String,String> erpIdToAccountId = UtilsObject.getMapOfStringToString(lstAccountData,'ERP_Customer_Id__c','id');
        Map<String,String> materialNumberToProductId = UtilsObject.getMapOfStringToString(lstProductData,'Material_Number__c','id');
        system.debug('Product2 map : '+materialNumberToProductId);

        for (QuotationDataRecieverWrapper.QuoteWrapper objQuoteWrapper: lstQuoteWrapper)
        {
            Apttus_Proposal__Proposal__c quoteSObject = objQuoteWrapper.getSObject();
            oneQuote = quoteSObject;

            quoteSObject.Ship_To__c = erpIdToCustomerId.get(objQuoteWrapper.Ship_To);
            quoteSObject.Bill_To__c = erpIdToCustomerId.get(objQuoteWrapper.Bill_To);
            quoteSObject.Payer__c = erpIdToCustomerId.get(objQuoteWrapper.Payer);
            quoteSObject.Distributor__c = erpIdToAccountId.get(objQuoteWrapper.Distributor);
            quoteSObject.Apttus_Proposal__Account__c = erpIdToAccountId.get(objQuoteWrapper.Apttus_Proposal_Account);
            quoteSObject.Ultimate_Consignee__c =erpIdToAccountId.get(objQuoteWrapper.Ultimate_Consignee);
            quoteSObject.Is_Updated_By_System__c = true;
            //Added by Satya for INC0236538 
            quoteSObject.Sub_Total__c = decSubTotalPLI;
            
            if(idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c) == null)  throw new UtilsRest.InterfaceException('Opportunity id doest not exists');
            if (quoteSObject.Distributor__c != idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c).Distributor__c || quoteSObject.Ultimate_Consignee__c != idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c)
            {
                System.debug('Line 130');
                if(quoteSObject.Distributor__c != null){
                idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c).Distributor__c = quoteSObject.Distributor__c;
                }

                if(quoteSObject.Ultimate_Consignee__c != null){
                idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c = quoteSObject.Ultimate_Consignee__c;
                }

                idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c).Is_Updated_By_System__c = true;
                System.debug('Loopsss --- '+idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c));
                objOpportunityWork.registerUpsert(idsToOpportunityId.get(quoteSObject.Apttus_Proposal__Opportunity__c));
            }
            //INC0232672
            List<RealtimePricingRequest.PromotionWrapper> lstPromotion=new List<RealtimePricingRequest.PromotionWrapper>();

            if(String.isNotBlank(quoteSObject.Promo_Code_1__c)){
              RealtimePricingRequest.PromotionWrapper objPromotion= new RealtimePricingRequest.PromotionWrapper();
              objPromotion.PromoCode=quoteSObject.Promo_Code_1__c;
              objPromotion.PromoChannel=quoteSObject.Promo_Channel_1__c;
              lstPromotion.add(objPromotion);
            }
            if(String.isNotBlank(quoteSObject.Promo_Code_2__c)){
              RealtimePricingRequest.PromotionWrapper objPromotion= new RealtimePricingRequest.PromotionWrapper();
              objPromotion.PromoCode=quoteSObject.Promo_Code_2__c;
              objPromotion.PromoChannel=quoteSObject.Promo_Channel_2__c;
              lstPromotion.add(objPromotion);
            }
            if(String.isNotBlank(quoteSObject.Promo_Code_3__c)){
              RealtimePricingRequest.PromotionWrapper objPromotion= new RealtimePricingRequest.PromotionWrapper();
              objPromotion.PromoCode=quoteSObject.Promo_Code_3__c;
              objPromotion.PromoChannel=quoteSObject.Promo_Channel_3__c;
              lstPromotion.add(objPromotion);
              
            }
            if(!lstPromotion.isEmpty()){
                
                quoteSObject.Promotion_JSON__c=JSON.serialize(lstPromotion);
            }

            //DCP-54361
            quoteSObjectList.add(quoteSObject);
            objQuoteWork.registerUpsert(quoteSObject);

            for (QuotationDataRecieverWrapper.ProposalLineitemWrapper quoteLineItem :objQuoteWrapper.ProposalLineitemWrapper)
            {
                if (quoteLineItem.Reason_For_Rejection == null || quoteLineItem.Reason_For_Rejection == '')
                {
                    Apttus_Proposal__Proposal_Line_Item__c quoteLineSObject = quoteLineItem.getSObject();

                    // Add all Promotion details\\
                    Integer intCounter = 1;
                    for (QuotationDataRecieverWrapper.Promotion promo : quoteLineItem.Promotion)
                    {
                        system.debug('Promotion incoming '+promo);
                        if(intCounter==INTEGER_ONE){
                            if(mapPromo1ToLine.containsKey(promo.PromotionCodeName)){
                                mapPromo1ToLine.get(promo.PromotionCodeName).add(quoteLineSObject);
                            }
                            else{
                                mapPromo1ToLine.put(promo.PromotionCodeName,new List<Apttus_Proposal__Proposal_Line_Item__c>{quoteLineSObject});
                            }
                        }
                        if(intCounter==INTEGER_TWO){
                         if(mapPromo2ToLine.containsKey(promo.PromotionCodeName)){
                                mapPromo2ToLine.get(promo.PromotionCodeName).add(quoteLineSObject);
                            }
                            else{
                                mapPromo2ToLine.put(promo.PromotionCodeName,new List<Apttus_Proposal__Proposal_Line_Item__c>{quoteLineSObject});
                            }
                        }
                        if(intCounter==INTEGER_THREE){
                            if(mapPromo3ToLine.containsKey(promo.PromotionCodeName)){
                                mapPromo3ToLine.get(promo.PromotionCodeName).add(quoteLineSObject);
                            }
                            else{
                                mapPromo3ToLine.put(promo.PromotionCodeName,new List<Apttus_Proposal__Proposal_Line_Item__c>{quoteLineSObject});
                            }
                        }
                        if(intCounter==INTEGER_FOUR){
                            if(mapPromo4ToLine.containsKey(promo.PromotionCodeName)){
                                mapPromo4ToLine.get(promo.PromotionCodeName).add(quoteLineSObject);
                            }
                            else{
                                mapPromo4ToLine.put(promo.PromotionCodeName,new List<Apttus_Proposal__Proposal_Line_Item__c>{quoteLineSObject});
                            }
                        }
                        if(intCounter==INTEGER_FIVE){
                            if(mapPromo5ToLine.containsKey(promo.PromotionCode)){
                                mapPromo5ToLine.get(promo.PromotionCode).add(quoteLineSObject);
                            }
                            else{
                                mapPromo5ToLine.put(promo.PromotionCode,new List<Apttus_Proposal__Proposal_Line_Item__c>{quoteLineSObject});
                            }
                        }
                        intCounter++;

                        quoteLineSObject.Applied_Discount_Details__c = quoteLineSObject.Applied_Discount_Details__c + ' , ' + promo.PromotionCode + ' - ' + promo.PromotionCodeName;
                    }
                    quoteLineSObject.Applied_Discount_Details__c = quoteLineSObject.Applied_Discount_Details__c.removeEnd(',');

                    quoteLineSObject.Apttus_Proposal__Product__c = materialNumberToProductId.get(quoteLineItem.Apttus_Proposal_Product);
                    quoteLineSObject.ERP_Line_Number__c=objQuoteWrapper.SAP_Quote+'_'+quoteLineItem.ERP_Line_number;
                    System.debug('Product id : '+ quoteLineSObject.Apttus_Proposal__Product__c);

                    objUnitOfWork.registerRelationship(quoteLineSObject,Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Proposal__c, quoteSObject);
                    objQuoteLineWork.registerUpsert(quoteLineSObject);
                } else {
                    setLineItem.add(objQuoteWrapper.SAP_Quote+'_'+quoteLineItem.ERP_Line_number);
                }
            }
        }
        
        if (!setLineItem.isEmpty())
            objQuoteLineWork.registerDelete(new QuotationLineItemSelector().fetchLineItemId(setLineItem));
        // Added to add promo look up
        Set<String> setUniquePromos = new Set<String>();
        setUniquePromos.addAll(mapPromo1ToLine.keySet());
        setUniquePromos.addAll(mapPromo2ToLine.keySet());
        setUniquePromos.addAll(mapPromo3ToLine.keySet());
        setUniquePromos.addAll(mapPromo4ToLine.keySet());
        setUniquePromos.addAll(mapPromo5ToLine.keySet());
        for(Apttus_Config2__Incentive__c objappliedpromo : new ApttusIncentivesPromotionsSelector().getPromotions(setUniquePromos)){
            if(mapPromo1ToLine.containsKey(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                for(Apttus_Proposal__Proposal_Line_Item__c objline : mapPromo1ToLine.get(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                    objline.Promotion_1__c = objappliedpromo.id;
                    //DCP54361
                    if(promoToIdToIncentiveMap.containsKey(PROMO1)){

                        promoToIdToIncentiveMap.get(PROMO1).put(objline.Apttus_Proposal__Proposal__c, objappliedpromo);
                    }
                    else{
                        promoToIdToIncentiveMap.put(PROMO1, new Map<Id, Apttus_Config2__Incentive__c>{objline.Apttus_Proposal__Proposal__c => objappliedpromo});
                    }
                }
            }
            if(mapPromo2ToLine.containsKey(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                for(Apttus_Proposal__Proposal_Line_Item__c objline : mapPromo2ToLine.get(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                    objline.Promotion_2__c = objappliedpromo.id;
                    
                    //DCP54361
                    if(promoToIdToIncentiveMap.containsKey(PROMO2)){

                        promoToIdToIncentiveMap.get(PROMO2).put(objline.Apttus_Proposal__Proposal__c, objappliedpromo);
                    }
                    else{
                        promoToIdToIncentiveMap.put(PROMO2, new Map<Id, Apttus_Config2__Incentive__c>{objline.Apttus_Proposal__Proposal__c => objappliedpromo});
                    }
                }
            }
            if(mapPromo3ToLine.containsKey(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                for(Apttus_Proposal__Proposal_Line_Item__c objline : mapPromo3ToLine.get(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                    objline.Promotion_3__c = objappliedpromo.id;
                    //DCP54361
                    if(promoToIdToIncentiveMap.containsKey(PROMO3)){

                        promoToIdToIncentiveMap.get(PROMO3).put(objline.Apttus_Proposal__Proposal__c, objappliedpromo);
                    }
                    else{
                        promoToIdToIncentiveMap.put(PROMO3, new Map<Id, Apttus_Config2__Incentive__c>{objline.Apttus_Proposal__Proposal__c => objappliedpromo});
                    }
                }
            }
            if(mapPromo4ToLine.containsKey(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                for(Apttus_Proposal__Proposal_Line_Item__c objline : mapPromo4ToLine.get(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                    objline.Promotion_4__c = objappliedpromo.id;
                }
            }
            if(mapPromo5ToLine.containsKey(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                for(Apttus_Proposal__Proposal_Line_Item__c objline : mapPromo5ToLine.get(objappliedpromo.Apttus_Config2__IncentiveCode__c)){
                    objline.Promotion_5__c = objappliedpromo.id;
                }
            }

        }

        //Start of DCP-54361
        for (Apttus_Proposal__Proposal__c quoteSObj: quoteSObjectList)
        {
            populatePromotionOnQuote(quoteSObj, promoToIdToIncentiveMap);
        }
        //End of DCP-54361

        objUnitOfWork.commitWork();
        return (oneQuote != null ? oneQuote.Id : null);
    }

    /*
    * @Author: Jitesh Lakhwani
    * @Description : This method will populate applied promotion on Quote Object  
    * @return void
    */
    private static void populatePromotionOnQuote(Apttus_Proposal__Proposal__c proposal, Map<String, Map<Id, Apttus_Config2__Incentive__c>> promoKeyToIncentive){

        if(promoKeyToIncentive.containsKey(PROMO1) && promoKeyToIncentive.get(PROMO1).get(proposal.Id).Master_Promotions__c != null){

            proposal.Applied_Promo_1__c = promoKeyToIncentive.get(PROMO1).get(proposal.Id).Master_Promotions__c;
        }
        if(promoKeyToIncentive.containsKey(PROMO2) && promoKeyToIncentive.get(PROMO2).get(proposal.Id).Master_Promotions__c != null){

            proposal.Applied_Promo_2__c = promoKeyToIncentive.get(PROMO2).get(proposal.Id).Master_Promotions__c;
        }
        if(promoKeyToIncentive.containsKey(PROMO3) && promoKeyToIncentive.get(PROMO3).get(proposal.Id).Master_Promotions__c != null){

            proposal.Applied_Promo_3__c = promoKeyToIncentive.get(PROMO3).get(proposal.Id).Master_Promotions__c;
        }
    }
}
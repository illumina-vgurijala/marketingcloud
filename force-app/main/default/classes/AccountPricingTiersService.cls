/**
 *    @author Khushbu Vasani
 *    @date   2022-06-15
 *    @description  Account PRicing Tier Service
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date               Description
 *    Khushbu Vasani               15 June-2022        Initial Version
 *    Himanshu                     19 July 2022        DCP-55231 Show warning message when NGN is Differenct of Sold to and UC
 *    Saddam                       10-Aug-2022         DCP-55553 Created method getOpenOfferByCustomerForCLM(),getPricingDiscountTierToAssociate to retrieve list of PDt Records form wrapper.
 *    Khushbu Vasani               2022-09-01           DCP-56658 changes
 */
 
public without sharing class AccountPricingTiersService {
  
    private static final String LOG_TITLE = 'AccountPricingTiersService';

    /**
     * OpenOfferPricingDiscount for given erp id
     */
    public class OpenOfferPricingDiscount {
        public String erpCustomerId;
        public Decimal consumablePricingTier;
        public Map<String, Decimal> categoryToConsumableDiscount;
        public Decimal instrumentPricingTier;
        public Map<String, Decimal> categoryToInstrumentDiscount;
        public Decimal servicesPricingTier;
        public Map<String, Decimal> categoryToServicesDiscount;
        public Decimal servicesDiscount;
        public List<Pricing_Discount_Tier__c> listOfPRicingDiscountTier;//DCP-55553
    }

    /**
     * @owner Khushbu Vasani
     * @description Get Open Offer Discount
     * @param erpCustomerIds
     *        pricingDate
     */
    public List<OpenOfferPricingDiscount> getOpenOfferByCustomer(Set<String> setErpCustomerIds, DateTime pricingDate)
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push('.getOpenOfferByCustomer()');

        List<OpenOfferPricingDiscount> listOpenOfferPricingDiscount = new List<OpenOfferPricingDiscount>(); 

        List<Account_Discount_Tier__c> listAccountPricingTier = new AccountDiscountTierSelector().getAccountPricingForERPIds(setErpCustomerIds);
        if(listAccountPricingTier.isEmpty())
        {
            return listOpenOfferPricingDiscount;
        }
        
        Set<Decimal> setTier = new Set<Decimal>();

        Map<String,Map<String,Decimal>> mapERPIdToMapOfDiscountTypeToTier =new Map<String,Map<String,Decimal>>();
        getTierData(listOpenOfferPricingDiscount, listAccountPricingTier, setTier,mapERPIdToMapOfDiscountTypeToTier);        

        if(listOpenOfferPricingDiscount.isEmpty())
        {
            return listOpenOfferPricingDiscount;
        }

        List<Pricing_Discount_Tier__c> listPRicingDiscountTier = new PricingDiscountTierSelector().getPricingTierBasedOnTier(setTier, pricingDate);
        Map<Decimal, Map<string,  Map<String, Decimal>>> mapPricingTier = getPricingDiscountTier(listPRicingDiscountTier);
        
        if(mapPricingTier.isEmpty())
        {
             return listOpenOfferPricingDiscount;
        }
                            
        populateOpenOfferDiscount(listOpenOfferPricingDiscount, mapPricingTier);
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return listOpenOfferPricingDiscount;
    }

    private void populateOpenOfferDiscount(List<OpenOfferPricingDiscount> listOpenOfferPricingDiscount, Map<Decimal, Map<string,  Map<String, Decimal>>> mapPricingTier)
    {
        ilib_LogEvent.push('.populateOpenOfferDiscount()');
        // There can be  max 2 values only here
        for(OpenOfferPricingDiscount oopd : listOpenOfferPricingDiscount)
        {
            ilib_LogEvent.info('OpenOfferPricingDiscount-->: '+oopd);

            oopd.categoryToConsumableDiscount = new Map<string, Decimal>();
            oopd.categoryToInstrumentDiscount = new Map<string, Decimal>();
            oopd.categoryToServicesDiscount = new Map<string, Decimal>();

            if(mapPricingTier.containsKey(oopd.consumablePricingTier))
            {
                Map<string,  Map<String, Decimal>> mapDiscountTypePricingTier = mapPricingTier.get(oopd.consumablePricingTier);
                if(mapdiscountTypePricingTier.containsKey(label.ProductMaterialClassConsumables))
                {
                    oopd.categoryToConsumableDiscount = mapdiscountTypePricingTier.get(label.ProductMaterialClassConsumables);
                }
            }
            if(mapPricingTier.containsKey(oopd.InstrumentPricingTier))
            {
                Map<string,  Map<String, Decimal>> mapDiscountTypePricingTier = mapPricingTier.get(oopd.InstrumentPricingTier);
                if(mapdiscountTypePricingTier.containsKey(Label.ProductMaterialClassInstrument))
                {
                    oopd.categoryToInstrumentDiscount = mapdiscountTypePricingTier.get(Label.ProductMaterialClassInstrument);
                }
            }
            if(mapPricingTier.containsKey(oopd.servicesPricingTier))
            {
                Map<string,  Map<String, Decimal>> mapDiscountTypePricingTier = mapPricingTier.get(oopd.servicesPricingTier);
                if(mapdiscountTypePricingTier.containsKey(Label.ProductMaterialClassServices))
                {
                    oopd.categoryToServicesDiscount = mapdiscountTypePricingTier.get(Label.ProductMaterialClassServices);
                }
            }
        }

        ilib_LogEvent.pop();
    }

    // Map of Tier, Discount Type, Open Offer PRoduct catoegory and Discount value
    private Map<Decimal, Map<string,  Map<String, Decimal>>> getPricingDiscountTier(List<Pricing_Discount_Tier__c> listPRicingDiscountTier)
    {     
        ilib_LogEvent.push('.getPricingDiscountTier()');
        Map<Decimal, Map<string, Map<String, Decimal>>> mapPricingTierDiscount = new  Map<Decimal, Map<string, Map<String, Decimal>>>();
        for(Pricing_Discount_Tier__c pricingTier :listPRicingDiscountTier)
        {
            if(!mapPricingTierDiscount.containskey(pricingTier.Discount_Tier__c))
            {
                Map<string, Map<String, Decimal>> mapDiscountTier = new Map<string, Map<String, Decimal>>();
                mapPricingTierDiscount.put(pricingTier.Discount_Tier__c, mapDiscountTier);
            }

            Map<string, Map<String, Decimal>> mapDiscountTierData = mapPricingTierDiscount.get(pricingTier.Discount_Tier__c);
            if(!mapDiscountTierData.containskey(pricingTier.UG_Discount_Type__c))
            {
                Map<String, Decimal> listTier = new Map<String, Decimal>();
                mapDiscountTierData.put(pricingTier.UG_Discount_Type__c, listTier);
            }

            Map<String, Decimal> mapCategoryDiscount = mapDiscountTierData.get(pricingTier.UG_Discount_Type__c);
            if(!mapCategoryDiscount.containskey(pricingTier.Open_Offer_Product_Category__c))
            {
                mapCategoryDiscount.put(pricingTier.Open_Offer_Product_Category__c, pricingTier.Discount_Value__c);
            }
        }

        ilib_LogEvent.pop();
        return mapPricingTierDiscount;

    }

    private void getTierData(List<OpenOfferPricingDiscount> listOpenOfferPricingDiscount, List<Account_Discount_Tier__c> listAccountPricingTier,  Set<Decimal> setTier,Map<String,Map<String,Decimal>> mapERPIdToMapOfDiscountTypeToTier)
    {
        OpenOfferPricingDiscount objOpenOfferPricing;
        for(Account_Discount_Tier__c accDisTier : listAccountPricingTier)
        {
            if(objOpenOfferPricing == null || objOpenOfferPricing.erpCustomerId != accDisTier.ERP_Customer_Id__c)
            {
                objOpenOfferPricing = new OpenOfferPricingDiscount();
                listOpenOfferPricingDiscount.add(objOpenOfferPricing);
            }
            objOpenOfferPricing.erpCustomerId = accDisTier.ERP_Customer_Id__c;
            if(accDisTier.discount_type__c == Label.ProductMaterialClassServices)
            {
                objOpenOfferPricing.servicesPricingTier = Integer.valueOf(accDisTier.Pricing_Tier__c);                   
            }
            else if(accDisTier.discount_type__c == Label.ProductMaterialClassConsumables)
            {
                objOpenOfferPricing.consumablePricingTier = Integer.valueOf(accDisTier.Pricing_Tier__c);
            }
            else{
                objOpenOfferPricing.instrumentPricingTier = Integer.valueOf(accDisTier.Pricing_Tier__c);
            }

            setTier.add(accDisTier.Pricing_Tier__c);

            if(!mapERPIdToMapOfDiscountTypeToTier.containsKey(accDisTier.ERP_Customer_Id__c)){ //DCP-55553
                Map<String,Decimal> mapDiscountTypeToTier = new Map<String,Decimal>();
                mapERPIdToMapOfDiscountTypeToTier.put(accDisTier.ERP_Customer_Id__c,mapDiscountTypeToTier);
            }

            Map<string,Decimal> mapDiscountTypeToTierData = new Map<string,Decimal>();
            mapDiscountTypeToTierData = mapERPIdToMapOfDiscountTypeToTier.get(accDisTier.ERP_Customer_Id__c);
            
            if(!mapDiscountTypeToTierData.containsKey(accDisTier.discount_type__c)){
                mapDiscountTypeToTierData.put(accDisTier.discount_type__c,accDisTier.Pricing_Tier__c);
            }         
        }
    }

    /**
    *  @author Himanshu
    *  @description To check for different Ngn of Sold To and UC when both are Open offer Customer.
    *  @param Apttus_Config2__LineItem__c objLineItem 
    **/
    public static boolean checkCriteriaForWarningMessageForNoNgnAndDiffErpOfSoldToAndUc (Apttus_Config2__LineItem__c objLineItem) {
        Boolean noNgnAndDiffErpOfSoldToAndUc = false;
        Account objSoldTo = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r;
        Account objUltimateConsignee = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r;

        Boolean boolUcIsOocc = objUltimateConsignee.Open_Offer_Comparison_Customer__c || objUltimateConsignee.Signed_Open_Offer__c;
        Boolean boolSoldToIsOoocc = objSoldTo.Open_Offer_Comparison_Customer__c || objSoldTo.Signed_Open_Offer__c;
        
        Boolean boolQuoteIsOpenOffer = objLineItem.Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c!=null && objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c;
       
        string strUcErpNgnNumber = string.isBlank(objUltimateConsignee.National_Group_Number__c) ? objUltimateConsignee.erp_customer_id__C : objUltimateConsignee.National_Group_Number__c;
        string strSoldToErpNgnNumber = string.isBlank(objSoldTo.National_Group_Number__c) ? objSoldTo.erp_customer_id__C : objSoldTo.National_Group_Number__c;
        boolean boolDiffNgn = strUcErpNgnNumber != strSoldToErpNgnNumber;

        if(boolDiffNgn && boolQuoteIsOpenOffer && boolUcIsOocc && boolSoldToIsOoocc) {
            noNgnAndDiffErpOfSoldToAndUc = true;
        }
         return noNgnAndDiffErpOfSoldToAndUc;
     }

    /**
    *  @author Saddam
    *  @description method to return the PDT records with ERP to agreements.cls
    *  @param Set<string> set of agreement Acnt erp ids.
    **/
    public  List<OpenOfferPricingDiscount> getOpenOfferByCustomerForCLM(Set<String> setErpCustomerIds) {
       
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push('.getOpenOfferByCustomerForCLM()');

        List<OpenOfferPricingDiscount> listOpenOfferPricingDiscount = new List<OpenOfferPricingDiscount>(); 

        List<Account_Discount_Tier__c> listAccountPricingTier = new AccountDiscountTierSelector().getAccntPricingTiersForErpIds(setErpCustomerIds);

        if(listAccountPricingTier.isEmpty()) {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return listOpenOfferPricingDiscount;
       }
       ilib_LogEvent.info('listAccountPricingTier-->: '+listAccountPricingTier);

        Set<Decimal> setTier = new Set<Decimal>();
        Map<String,Map<String,Decimal>> mapERPIdToMapOfDiscountTypeToTier = new  Map<String,Map<String,Decimal>>();    
        getTierData(listOpenOfferPricingDiscount, listAccountPricingTier, setTier,mapERPIdToMapOfDiscountTypeToTier);        

        ilib_LogEvent.info('setTier-->: '+setTier);
        ilib_LogEvent.info('mapDiscountTypeToTier-->: '+mapERPIdToMapOfDiscountTypeToTier);

        if(listOpenOfferPricingDiscount.isEmpty()) {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return listOpenOfferPricingDiscount;
        }
        List<Pricing_Discount_Tier__c> listPRicingDiscountTier = new PricingDiscountTierSelector().getPricingTierBasedOnCustomerTier(setTier);
        ilib_LogEvent.info('listPRicingDiscountTier-->: '+listPRicingDiscountTier);

        getPricingDiscountTierToAssociate(listPRicingDiscountTier, mapERPIdToMapOfDiscountTypeToTier,listOpenOfferPricingDiscount);
       
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return listOpenOfferPricingDiscount;       
    }

     /**
    *  @author Saddam
    *  @description method to return the PDT records with ERP Mapped to wrapper list.
    *  @param Set<string set of agreement Acnt erp ids.
    **/
    public void getPricingDiscountTierToAssociate(List<Pricing_Discount_Tier__c> listPRicingDiscountTier, Map<String,Map<String,Decimal>> mapERPIdToMapOfDiscountTypeToTier,List<OpenOfferPricingDiscount> listOpenOfferPricingDiscount) {
        
        ilib_LogEvent.push('.getPricingDiscountTier()');
        for(OpenOfferPricingDiscount objOOPricingDiscount:listOpenOfferPricingDiscount){
            if(mapERPIdToMapOfDiscountTypeToTier.containsKey(objOOPricingDiscount.erpCustomerId)){
                List<Pricing_Discount_Tier__c> listPricingDiscountTierToReturn = new List<Pricing_Discount_Tier__c>();
                Map<String,Decimal> mapDiscountTypeToTier = mapERPIdToMapOfDiscountTypeToTier.get(objOOPricingDiscount.erpCustomerId);
                for(Pricing_Discount_Tier__c objPdtRecords :listPRicingDiscountTier) {
                    if(mapDiscountTypeToTier.containsKey(objPdtRecords.UG_Discount_Type__c)) {
                        if(objPdtRecords.Discount_Tier__c == mapDiscountTypeToTier.get(objPdtRecords.UG_Discount_Type__c)){
                            listPricingDiscountTierToReturn.add(objPdtRecords);
                        }
                    }
                }
                objOOPricingDiscount.listOfPRicingDiscountTier = new List<Pricing_Discount_Tier__c>();
                objOOPricingDiscount.listOfPRicingDiscountTier.addAll(listPricingDiscountTierToReturn);
            }
        } 
        ilib_LogEvent.pop();
    }
     /**
    *  @author Khushbu Vasani
    *  @description To check for Open Offer Discount % is null i.e. no data in account discount tier object and Sold/UC is Open Offer comparison Customer.
    *  @param Apttus_Config2__LineItem__c objLineItem 
    **/
    public static boolean checkCriteriaForWarningMessageForNoADTData (Apttus_Config2__LineItem__c objLineItem) {
        Boolean boolNoADTData = false;
        Boolean boolUcIsOocc = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c || objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c;
        Boolean boolSoldToIsOoocc = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c || objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c;
      
        Boolean boolQuoteIsOpenOffer = objLineItem.Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c!=null && objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c;
       
        if((boolUcIsOocc || boolSoldToIsOoocc) && boolQuoteIsOpenOffer && objLineItem.Open_Offer_Max__c == null) {
            boolNoADTData = true;
        }
         return boolNoADTData;
     }
   
}
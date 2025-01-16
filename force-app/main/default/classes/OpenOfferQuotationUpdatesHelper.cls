/**
*    @author Nesar Mohan
*    @date   2022-06-02
*    @description    DCP-53938: Helper class to evalute the logic of open offer criteria and update the fields on quote record
*    Test class for 90%+ coverage : TestApttusProposalLineItemsOpenOffer
*    Test class for 75%+ coverage : TestApttusProposalLineItemsOpenOffer
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*        Nesar Mohan                  2022-06-02           Initial Version
*        Himanshu                     2022-06-21           To get Material Class for DCP-53205
*        Satya Swain                  2022-06-23           TASK0799027 : Replace ApttusProposalLineItemsHelper with this class to make it 
                                                           specific to Open offer calculations
*        Khushbu Vasani               2022-09-01           DCP-56658 changes
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpenOfferQuotationUpdatesHelper {
    public static final String OODISCOUNTEXCEPTIONREQUEST = 'Open_Offer_Discount_Exception_Request';
    private static final String LOG_TITLE = 'OpenOfferQuotationUpdatesHelper';
    
    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to evaluate open offer logic
    *  @PARAM :         Map<Id,Id>
    *  @RETURN:         void
    */
    public void evaluateOpenOfferLogic(Map<Id,Id> mapLineItemIdtoQuoteId) {

        ilib_LogEvent.push(LOG_TITLE + '.evaluateOpenOfferLogic()');

        Map<Id,Apttus_Proposal__Proposal__c> mapIdToProposalForUpdate = new Map<Id,Apttus_Proposal__Proposal__c>();
        Set<Id> setCartLineItemIds =  mapLineItemIdtoQuoteId.keyset();
        Map<Id,Boolean> mapQuoteIdToOpenOfferValue = new Map<Id,Boolean>();
        Map<Id,Set<String>> mapQuoteIdToOpenOfferProductMaterialClass =  new Map<Id,Set<String>>();//DCP-53205
        List<Apttus_Config2__LineItem__c> lstCartLineItemsWithOOProduct = new List<Apttus_Config2__LineItem__c>();
        
        List<Apttus_Config2__LineItem__c> lstCartLineItems = new ApttusLineItemsSelector().selectById(setCartLineItemIds);

        for(Apttus_Config2__LineItem__c objCartLineItem : lstCartLineItems) {
            Set<String> setStringMaterialClass = new Set<String>();
            if (objCartLineItem.Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c!=null) {
                mapQuoteIdToOpenOfferValue.put(mapLineItemIdtoQuoteId.get(objCartLineItem.Id),true);
                lstCartLineItemsWithOOProduct.add(objCartLineItem);
                populateMapOfOpenOfferProductClassTypes(mapQuoteIdToOpenOfferProductMaterialClass,objCartLineItem,setStringMaterialClass,mapLineItemIdtoQuoteId);//DCP-53205
            } else if (!mapQuoteIdToOpenOfferValue.containsKey(mapLineItemIdtoQuoteId.get(objCartLineItem.Id))) {
                mapQuoteIdToOpenOfferValue.put(mapLineItemIdtoQuoteId.get(objCartLineItem.Id),false);
                mapQuoteIdToOpenOfferProductMaterialClass.put(mapLineItemIdtoQuoteId.get(objCartLineItem.Id),setStringMaterialClass);//DCP-53205
            }
        }

        List<Apttus_Proposal__Proposal__c> lstProposal = new ApttusProposalsSelector().selectById(mapQuoteIdToOpenOfferValue.keyset());
        
        for(Apttus_Proposal__Proposal__c objQuoteRecord : lstProposal) {
            objQuoteRecord.Quote_Has_Open_Offer_Product__c = mapQuoteIdToOpenOfferValue.get(objQuoteRecord.id);
            objQuoteRecord.Open_Offer_Discount_Violation_Type__c = '';
            objQuoteRecord.Open_Offer_Product_Type__c = String.join(new List<String>(mapQuoteIdToOpenOfferProductMaterialClass.get(objQuoteRecord.id)), ';');
            mapIdToProposalForUpdate.put(objQuoteRecord.id,objQuoteRecord);
        }

        if(!lstCartLineItemsWithOOProduct.isEmpty()) {
            evaluateDiscountCheck(lstCartLineItemsWithOOProduct,mapLineItemIdtoQuoteId,mapIdToProposalForUpdate);
        }
        
        if(!mapIdToProposalForUpdate.isEmpty()) {
            try {
                Database.update(mapIdToProposalForUpdate.values());
            } catch(Exception e) {
                ApexExceptions.emit(LOG_TITLE, e);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to evaluate account Discount check logic
    *  @PARAM :         List<Apttus_Config2__LineItem__c>, Map<Id,Id>, Map<Id,Apttus_Proposal__Proposal__c>
    *  @RETURN:         void
    */
    public void evaluateDiscountCheck(List<Apttus_Config2__LineItem__c> lstCartLineItems, Map<Id,Id> mapLineItemIdtoQuoteId,Map<Id,Apttus_Proposal__Proposal__c> mapIdToProposalForUpdate) {
        
        ilib_LogEvent.push(LOG_TITLE + '.evaluateDiscountCheck()');
        
        Code_Parameter__mdt objOOViolationType = Code_Parameter__mdt.getInstance(OODISCOUNTEXCEPTIONREQUEST);

        Map<Id,String> mapQuoteIdToDiscountExceededType = new Map<Id,String>();
        calculateDiscountViolationTypeCriteria(lstCartLineItems,mapQuoteIdToDiscountExceededType,mapLineItemIdtoQuoteId,objOOViolationType);

        List<Apttus_Proposal__Proposal__c> lstProposalsEligibleForDiscountViolation = new ApttusProposalsSelector().selectById(mapQuoteIdToDiscountExceededType.keySet());

        for(Apttus_Proposal__Proposal__c objQuoteRecord : lstProposalsEligibleForDiscountViolation) {
            Boolean booIsDirectQuote = objQuoteRecord.Quote_Type__c.startsWith(System.Label.DistributionChannelDirect);
            Boolean booHasQuoteId = mapIdToProposalForUpdate.containsKey(objQuoteRecord.Id);
            String strvalueToPopulate = mapQuoteIdToDiscountExceededType.get(objQuoteRecord.Id);

            if(booHasQuoteId && booIsDirectQuote) {
                mapIdToProposalForUpdate.get(objQuoteRecord.Id).Open_Offer_Discount_Violation_Type__c = strvalueToPopulate;
            } else if(!booHasQuoteId && booIsDirectQuote) {
                objQuoteRecord.Open_Offer_Discount_Violation_Type__c = strvalueToPopulate;
                mapIdToProposalForUpdate.put(objQuoteRecord.id,objQuoteRecord);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    *  @AUTHOR:         Himanshu Malik
    *  @DESCRIPTION:    Method to get Material Class for DCP-53205
    *  @PARAM :         Map<Id,Set<String>> mapQuoteIdToOpenOfferProductMaterialClass,Apttus_Config2__LineItem__c objCartLineItem,Set<String> setStringMaterialClass,Map<Id,Id> mapLineItemIdtoQuoteId
    *  @RETURN:         void
    */
    public void populateMapOfOpenOfferProductClassTypes(Map<Id,Set<String>> mapQuoteIdToOpenOfferProductMaterialClass,Apttus_Config2__LineItem__c objCartLineItem,Set<String> setStringMaterialClass,Map<Id,Id> mapLineItemIdtoQuoteId) {
       
        ilib_LogEvent.push(LOG_TITLE + '.populateMapOfOpenOfferProductClassTypes()');
        Decimal decimalAppliedDiscountPercentage = objCartLineItem.Applied_Discount_Percentage__c == NULL ? 0 : objCartLineItem.Applied_Discount_Percentage__c;
        Decimal decimalOpenOfferMaxPercentage = objCartLineItem.Open_Offer_Max__c == NULL ? 0 : objCartLineItem.Open_Offer_Max__c;
        Boolean boolAppliedPercentGreaterThanOOMax = decimalAppliedDiscountPercentage > decimalOpenOfferMaxPercentage;
        if(mapQuoteIdToOpenOfferProductMaterialClass.containskey(mapLineItemIdtoQuoteId.get(objCartLineItem.Id)) && boolAppliedPercentGreaterThanOOMax ) {
            mapQuoteIdToOpenOfferProductMaterialClass.get(mapLineItemIdtoQuoteId.get(objCartLineItem.Id)).add(objCartLineItem.Apttus_Config2__ProductId__r.Material_Class__c);
        } else if (!mapQuoteIdToOpenOfferProductMaterialClass.containskey(mapLineItemIdtoQuoteId.get(objCartLineItem.Id)) && boolAppliedPercentGreaterThanOOMax) {
            setStringMaterialClass.add(objCartLineItem.Apttus_Config2__ProductId__r.Material_Class__c);
            mapQuoteIdToOpenOfferProductMaterialClass.put(mapLineItemIdtoQuoteId.get(objCartLineItem.Id),setStringMaterialClass);
        }
        ilib_LogEvent.pop();
    }        

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to calculate Discount Violation Type
    *  @PARAM :         List<Apttus_Config2__LineItem__c> lstCartLineItems, Map<Id,String> mapQuoteIdToDiscountExceededType,Map<Id,Id> mapLineItemIdtoQuoteId, Code_Parameter__mdt objOOViolationType
    *  @RETURN:         void
    */
    public void calculateDiscountViolationTypeCriteria(List<Apttus_Config2__LineItem__c> lstCartLineItems, Map<Id,String> mapQuoteIdToDiscountExceededType,Map<Id,Id> mapLineItemIdtoQuoteId, Code_Parameter__mdt objOOViolationType) {
        
        ilib_LogEvent.push(LOG_TITLE + '.calculateDiscountViolationTypeCriteria()');   
        for(Apttus_Config2__LineItem__c objLineItem : lstCartLineItems) {

            Boolean boolUcIsOocc = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c || objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c;
            Boolean boolSoldToIsOoocc = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c || objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c;
           
            Boolean boolQuoteIdKeyFoundInMap = mapQuoteIdToDiscountExceededType.containsKey(mapLineItemIdtoQuoteId.get(objLineItem.Id));
            String strValueFromMap = mapQuoteIdToDiscountExceededType.get(mapLineItemIdtoQuoteId.get(objLineItem.Id));
            Boolean boolMapContainsNGNValue = boolQuoteIdKeyFoundInMap && strValueFromMap == System.Label.NoOpenOfferDiscountDueToDifferentNgn;
            Boolean boolMapContainsExceededByFifteen = boolQuoteIdKeyFoundInMap && strValueFromMap == System.Label.DiscountExceededByFifteen;
            
            Decimal decAppliedDiscountPercentage = objLineItem.Applied_Discount_Percentage__c == NULL ? 0 : objLineItem.Applied_Discount_Percentage__c;
            Decimal decOpenOfferMaxPercentage = objLineItem.Open_Offer_Max__c == NULL ? 0 : objLineItem.Open_Offer_Max__c;
            Decimal decPercentageDifference = decAppliedDiscountPercentage - decOpenOfferMaxPercentage;
            Boolean boolAppliedPercentGreaterThanOOMax = decAppliedDiscountPercentage > decOpenOfferMaxPercentage;
            Boolean boolDiscountTypeIsDiscretionary = !String.isBlank(objLineItem.Applied_Discount_Details__c) && objLineItem.Applied_Discount_Details__c.contains(System.Label.ApprovalStepNameSalesDiscretionary);
           
            //DCP-56658 changes
            Account objUltimateConsignee = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r;
            Account objSoldTo = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r;

            string strUcErpNgnNumber = string.isBlank(objUltimateConsignee.National_Group_Number__c) ? objUltimateConsignee.erp_customer_id__C : objUltimateConsignee.National_Group_Number__c;
            string strSoldToErpNgnNumber = string.isBlank(objSoldTo.National_Group_Number__c) ? objSoldTo.erp_customer_id__C : objSoldTo.National_Group_Number__c;
            boolean boolDiffNgn = strUcErpNgnNumber != strSoldToErpNgnNumber;


            //Boolean boolNgnEmptyForSoldToAndUC = string.isEmpty(objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c) && string.isEmpty(objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c);
            // Boolean boolErpDifferentForSoldToAndUC = false;
            // if(boolUcIsOocc && boolSoldToIsOoocc && boolDiffNgn)
            // {
            //     boolErpDifferentForSoldToAndUC = objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c != objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c;
            // }
            Boolean boolNoAdtData = false;
            if((boolUcIsOocc || boolSoldToIsOoocc) && objLineItem.Open_Offer_Max__c == null)
            {
                boolNoAdtData = true;
            }

            if((boolUcIsOocc && boolSoldToIsOoocc && boolDiffNgn) || boolNoAdtData) {
                mapQuoteIdToDiscountExceededType.put(mapLineItemIdtoQuoteId.get(objLineItem.Id),System.Label.NoOpenOfferDiscountDueToDifferentNgn);
            } else if(boolDiscountTypeIsDiscretionary && boolAppliedPercentGreaterThanOOMax && decPercentageDifference > Decimal.valueOf(objOOViolationType.Value__c) && !boolMapContainsNGNValue) {
                mapQuoteIdToDiscountExceededType.put(mapLineItemIdtoQuoteId.get(objLineItem.Id),System.Label.DiscountExceededByFifteen);
            } else if(boolDiscountTypeIsDiscretionary && boolAppliedPercentGreaterThanOOMax && decPercentageDifference <= Decimal.valueOf(objOOViolationType.Value__c) && !boolMapContainsNGNValue && !boolMapContainsExceededByFifteen) {
                mapQuoteIdToDiscountExceededType.put(mapLineItemIdtoQuoteId.get(objLineItem.Id),System.Label.DiscountExceeded);
            } else if(!boolQuoteIdKeyFoundInMap) {
                mapQuoteIdToDiscountExceededType.put(mapLineItemIdtoQuoteId.get(objLineItem.Id),'');
            }
        }
        ilib_LogEvent.pop();
    }
}

/**
*    @author Rohan Chandarana
*    @date   06-06-2018
*    @description   Domain class for ApttusProposalLineItemTrigger
*    @Test class for 90% coverage - TestApttusApprovals, TestApttusProposalLineItemsOpenOffer 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*      Developer                      Date                 Description
*      Rohan                          06-June-2018         Initial Version
*      Gopesh Banker (Apttus)         19 Sept, 2018        changes on onAfterInsert, adding methods syncProposalLines, onAfterUpdate, onAfterDelete
*      Gopesh Banker (Apttus)         26 Sept, 2018        changes on onAfterInsert and onAfterDelete to use processAssetRenewalAutomation, added method processAssetRenewalAutomation
*      Govind Dubey                   26 Sept, 2018        Added logic for Software Products added in PLI for DCP-12276 in afterInsert
*      Govind Dubey                   3 April, 2019        Modified getApprovalMatrix method to accomodate sales Org change for DCP-24594
*      Roopal Verma                   3 July , 2019        DCP-25340, Promotion Approvals
*      Roopal Verma                   6 Aug, 2019          DCP-25340, Regression fix
*      Roopal Verma                   27 Aug , 2019        DCP-26583 End of sale condition
*      Roopal Verma                   27 Aug , 2019        DCP-26583 End of sale condition
*      Arnab Modak                    11 Sep , 2019        DCP-28664 - Approval should fire only for Fix Bundle Components
*      Prakhar Kumar                  11 Nov , 2019        DCP-30368/31200 - Stamping/ removing of Quote Line Item Ids on Quote object based on Informatics Product
*      Rahul Bishnoi                  17 Jan , 2020        DCP-32794 - Remove Software_Product_Check__c
*      Rahul Bishnoi                  27 Jan , 2020        DCP-31767 - Set default value of Primary Contact in Registration Contact field
*      Roopal Verma                   14 May , 2020        DCP-29812 - Logic for unique product specific term
*      Roopal Verma                   10 Sept, 2020        DCP-40107 - Approvals redesign
*      Prabhsimran Singh              23 Nov, 2020         INC0298256 Issue fix
*      Todd Newman                    3 Dec, 2020          TASK0545558 change to approval required for certain Dx Materials
*      Joshith K                      17 dec,2020          TASK0547837 updated CPQ_SALES_HIERARCHY to CPQ_Sales_Hierarchy 
*      Roopal Verma                   24 Nov, 2020         DCP-43262 - Error handling for approvals
*      Bharath Varma                  22 feb, 2021         Added logic to populate Registration Contact for DCP-45314
*      Satya Swain                    02 Sep 2021          DCP-48131: Added Logic to Include New Approvals Pipeline
*     ------------------------------------------------------------------------------------
*      Rishi Sharma                   24 Sep, 2021         Added logic to check/uncheck Is Free Trial and Free trial check fields for IP2-175
*    ------------------------------------------------------------------------------------
*      Khushbu Vasani                 24 Jan, 2022         Added Informatics_Line_Item_Number__c boolean as existing text 255 field was failing and was not used
*      Bharath Varma                  31 Mar, 2022         INC0384911: Added logic to recalculate the Informatics line numbers on update
*      Nesar Mohan                    2  Jun, 2022         DCP-53938 - Update ApttusProposalLineItems to streamline multiple queueables enqueued into single thread
*      Bharath Varma                  12 May, 2022         INC0396464: Made Informatics_Product_Line_Item_Numbers__c blank when there are no informatics products left
*      Preetha                        21 May, 2022         CMSI-68 Instrumentation has been made for this class
*      Avina                          07-July-2022         CMSI-51 - Added getWorkstream method to return the workstream
*      Adithi Acharya                 10 Aug, 2022         DCP-56268:  Changed the references of Registration Contact to Registrant Contact and added null check on Registrant Contact
*      Satya Swain                    22 Aug 2022          TASK0799027 : Added ability to launch Platform event for handling 200+ lines for evaluating open offer business logic
*      Prem Ranjan                    20-Feb-2023          CodeScan Fixes (APEX) Variable Naming Conventions
*      Gerardo Garcia                 24-Jan-2024          CMCM-5310 Refactor on onBeforeInsert. By creating setDefaultValuePrimaryContact and updateQuotes methods. Reduced query of quotation
*      Akshay Hedaoo                  16-Aug-2024          CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
*      Sai Pasumarthy                 17-Dec-2024          CMCM-11325 : TI- Quotation Line Item:Check for Product Specific Terms And Material Class
*/
public with sharing class ApttusProposalLineItems extends ilib_SObjectDomain { 
    
    /* 
* @Roopal
* Approval Categories
*/
    public static Boolean skipAfterDelete = false;
    public static final String APPROVAL_STATUS_NONE = 'None';  
    public static final String PRODUCT_TYPE_PRODCUT_SERVICE = 'Product/Service';
    public static final String LINE_STATUS_RENEWED = 'Renewed';
    public static final Integer MAX_APPROVAL_LEVEL = Integer.valueOf(Label.Maximum_Approval_Level);
    private static Set<Id> setSynced=new Set<ID>();
    public List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems;
    public static final String HIERARCHY_RECORD_OWNER = 'Record Owner';
    public static final String HIERARCHY_CUSTOM ='Custom';
    public static final String APPROVAL_TYPE_MATNUM ='Material_Number';
    public static final String APPROVAL_TYPE_MATGRP ='Material_Group';
    public static final String APPROVAL_TYPE_DISCOUNT ='Discount';
    public static final String BLANK_STRING ='BLANK';
    public static final String ADD_ON = 'ADD-ON';
    public static final String EXECUTE = 'execute';
    public static Set<String> setIsoCodes = new Set<String>();
    
    public static map<string,Integer> mapApprovalPriorityMetadata = new map<string,Integer>();
    public static Map<Id,String> mapQuoteIdToAccount = new Map<Id,String>();
    private static Set<Id> setQuotationIdsWithMatrixError = new Set<Id>();
    
    private static final String LOG_TITLE = 'ApttusProposalLineItems'; //INC0384911
    private static final Integer INT_MAX_SIZE = 255;
    public static final String MAPISEMPTY = 'map is empty';//CMSI-68
    public static final String STRING_CODE_PARAMETER_OPEN_OFFER_THRESHOLD = 'Open_Offer_Quotation_Line_Threshold'; //TASK0799027
    public static final Integer INTEGER_OPEN_OFFER_THRESHOLD_DEFAULT = 200; //TASK0799027
    @TestVisible private static Boolean boolUseLargeCartProcessingMechanism = false;    
    /*
* Approval Category
*/
    public enum ApprovalCategory {CPQ_DISCOUNT, CPQ_MATERIAL_NUMBER, CPQ_MATERIAL_GROUP_1,CPQ_MATERIAL_NUMBER_CUSTOM, CPQ_MATERIAL_GROUP_CUSTOM,CPQ_DISCOUNT_CUSTOM,CPQ_Sales_Hierarchy, PROMOTION}
    
    /*
Super method for class
*/
    public ApttusProposalLineItems(List<Apttus_Proposal__Proposal_Line_Item__c> sObjectList) {
        super(sObjectList);
    }
    
    /**
* Boilerplate which is required for base class instantiation logic
**/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
Constructor class
*/
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApttusProposalLineItems(sObjectList);
        }
    }
    
    /**
*  @author  Rohan Chandarana
*  @description Before Insert Logic (e.g. set approvals, reset approval for clone etc)
**/
    public override void onBeforeInsert()
    {        
        List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems = (List<Apttus_Proposal__Proposal_Line_Item__c>)records;
        setIsoCodes.add(lstProposalLineItems[0].CurrencyIsoCode);
        List<CurrencyType> currencyTypeList = new CurrencyCodesSelector().getCurrencyTypeRecordsFromIsoCodes(setIsoCodes);
        Decimal cts = currencyTypeList[0].conversionRate;
        totalamountpriortodicountUSD(lstProposalLineItems,cts);
        ilib_LogEvent.info('lstProposalLineItems : '+ lstProposalLineItems.size() + ' ' + UtilsCollection.getSetOfIds(lstProposalLineItems));//CMSI-68
        
        setClonedQuoteValues(lstProposalLineItems);
        
        if (lstProposalLineItems.isEmpty()) { return; }
        
        Set<Id> productIds = UtilsCollection.getSetOfIds(lstProposalLineItems, 'Apttus_Proposal__Product__c');
        ilib_LogEvent.info('productIds : '+productIds);
        Map<Id, Product2> mapIdToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(productIds));
        ilib_LogEvent.info('mapIdToProduct :'+(!mapIdToProduct.isEmpty()? String.valueOf(mapIdToProduct.keySet()):MAPISEMPTY));
        
        updateProdSpecificTerm(lstProposalLineItems, mapIdToProduct);
        
        //IP2-175 Show/Hide Submit for approval button
        checkFreeTrial(lstProposalLineItems, mapIdToProduct);
        updateERPOnRenewal(lstProposalLineItems);
        
        //CMCM-9780
        updateHideContractDates(lstProposalLineItems);

        checkProductSpecificTermsAndMaterialClass(lstProposalLineItems, mapIdToProduct); //CMCM-11325
        
        //IP2-175 - end
        Set<Id> setQuotationIds = UtilsCollection.getSetOfIds(lstProposalLineItems, 'Apttus_Proposal__Proposal__c');
        
        //DCP-31200 Set default value of Primary Contact in Contact ID field -- START
        //DCP-31767 Set default value of Primary Contact in Registration Contact field
        Map<id,Apttus_Proposal__Proposal__c> idToProposal = new Map<id,Apttus_Proposal__Proposal__c>( new ApttusProposalsSelector().selectByQuoteId(setQuotationIds));
        
        setDefaultValuePrimaryContact(lstProposalLineItems, idToProposal);
        //DCP-31200 Set default value of Primary Contact in Contact ID field -- END
        
        updateQuotes(lstProposalLineItems, idToProposal); 
    }
    
    private void setDefaultValuePrimaryContact(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<id,Apttus_Proposal__Proposal__c> idToProposal) {
        if(idToProposal.isEmpty()) { return; }
        
        Map<String, Apttus_Config2__OrderLineItem__c> mapERPtoOli = getOrderLIwithERP(lstProposalLineItems);
        
        for(Apttus_Proposal__Proposal_Line_Item__c ql: lstProposalLineItems) {
            
            Apttus_Proposal__Proposal__c quotation = idToProposal.get(ql.Apttus_Proposal__Proposal__c);
            
            if(ql.Registrant_Contact__c != null )
                continue;
            
            if(isContactFromQuotation(quotation, ql)) {
                ql.Registrant_Contact__c = quotation.Apttus_Proposal__Primary_Contact__c;
            }
            
            if(ql.Existing_Subscription__c == null && ql.Product_Type__c == ADD_ON) {
                ql.Registrant_Contact__c = null;
            }
            
            if(isContactFromERP(ql, mapERPtoOli)) {
                Apttus_Config2__OrderLineItem__c configLineItem = mapERPtoOli.get(ql.ERP_Line_Number_Id__c);
                ql.Registrant_Contact__c = configLineItem?.Registrant_Contact__c;
            }
            
            ilib_LogEvent.message('Quotation line item:' + ql.Id + ' regContact -->' + ql.Registrant_Contact__c);
        }
    }
    
    private static Boolean isContactFromQuotation(Apttus_Proposal__Proposal__c quotation, Apttus_Proposal__Proposal_Line_Item__c ql) {
        return quotation?.Apttus_Proposal__Primary_Contact__c != null
            && ql.Product_Type__c != ADD_ON
            && ql.Is_Informatics_Product__c == true;
    }
    
    private static Boolean isContactFromERP(Apttus_Proposal__Proposal_Line_Item__c ql, Map<String, Apttus_Config2__OrderLineItem__c> mapERPtoOli) {
        return ql.ERP_Line_Number_Id__c != null 
            && mapERPtoOli.containsKey(ql.ERP_Line_Number_Id__c) 
            && ql.Is_Informatics_Product__c == true;
    }
    
    private void updateQuotes(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<id,Apttus_Proposal__Proposal__c> idToQuotation) {
        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive();
        ilib_LogEvent.info('lstCustomApprovalMatrix.size() : '+ lstCustomApprovalMatrix.size()+ ' ' + UtilsCollection.getSetOfIds(lstCustomApprovalMatrix));//CMSI-68
        if (idToQuotation.isEmpty() || lstCustomApprovalMatrix.isEmpty()) { return; }
        
        Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate = new Map<Id, Apttus_Proposal__Proposal__c>(); //DCP-26583 Moved the map up to accomodate End of sale condition  
        
        Set<Id> setAccountOwnerIds = new Set<Id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c objPLI: lstProposalLineItems)
        {
            Apttus_Proposal__Proposal__c objProposal = idToQuotation.get(objPLI.Apttus_Proposal__Proposal__c);
            if(objProposal == null) continue;
            
            if (objProposal.Apttus_Proposal__Account__r.OwnerId != null) { setAccountOwnerIds.add(objProposal.Apttus_Proposal__Account__r.OwnerId); }
            if (objProposal.Ultimate_Consignee__r.OwnerId != null) { setAccountOwnerIds.add(objProposal.Ultimate_Consignee__r.OwnerId); }
            if (objProposal.Distributor__r.OwnerId != null) { setAccountOwnerIds.add(objProposal.Distributor__r.OwnerId); }
            
            setQuotationExpectedEndDateFromQuoteLine(objProposal, objPLI, idToQuotationForUpdate);
        }
        
        idToQuotationForUpdate = setApprovals(lstProposalLineItems, setAccountOwnerIds, idToQuotation, idToQuotationForUpdate);
        ilib_LogEvent.info('idToQuotationForUpdate :'+(!idToQuotationForUpdate.isEmpty()? String.valueOf(idToQuotationForUpdate.keySet()):MAPISEMPTY));//CMSI-68
        if(!idToQuotationForUpdate.isEmpty()) {
            update idToQuotationForUpdate.values();
        }
    }
    
    private void setQuotationExpectedEndDateFromQuoteLine(Apttus_Proposal__Proposal__c objProposal, 
                                                          Apttus_Proposal__Proposal_Line_Item__c objPLI, 
                                                          Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate) 
    {
        if(objProposal.Apttus_QPConfig__PricingDate__c == null) return;
        
        if (isQuotationPricingDateStillEffective(objProposal)
            && isQuotationLineEndSaleDateInRange30Days(objPLI, objProposal.Apttus_QPConfig__PricingDate__c)
            && isQuotationExpectedEndDateIsGreaterThanQuotationLine(objProposal, objPLI))
        {
            objProposal.Apttus_Proposal__ExpectedEndDate__c = objPLI.End_Of_Sale_Date__c;
            idToQuotationForUpdate.put(objProposal.id, objProposal);
        }
        else if (!isQuotationPricingDateStillEffective(objProposal)
                 && isQuotationLineEndSaleDateInRange30Days(objPLI, date.Today())
                 && isQuotationExpectedEndDateIsGreaterThanQuotationLine(objProposal, objPLI))
        {
            objProposal.Apttus_Proposal__ExpectedEndDate__c = objPLI.End_Of_Sale_Date__c;
            idToQuotationForUpdate.put(objProposal.id, objProposal);
        }
    }
    
    private Boolean isQuotationPricingDateStillEffective(Apttus_Proposal__Proposal__c objProposal) {
        return  objProposal.Apttus_QPConfig__PricingDate__c >= Date.Today();
    }
    
    //DCP-26583- Added check for End of Sale
    private Boolean isQuotationLineEndSaleDateInRange30Days(Apttus_Proposal__Proposal_Line_Item__c objPLI, Datetime dateVal) {
        return objPLI.End_Of_Sale_Date__c < dateVal.addDays(30) && objPLI.End_Of_Sale_Date__c >= Date.Today();
    }
    
    private Boolean isQuotationExpectedEndDateIsGreaterThanQuotationLine(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal_Line_Item__c objPLI) {
        return objProposal.Apttus_Proposal__ExpectedEndDate__c == null || objProposal.Apttus_Proposal__ExpectedEndDate__c > objPLI.End_Of_Sale_Date__c;
    }
    
    /*
* [DCP-45314] Get OrderLineItems based on ERP Line Number Id
*/
    public Map<String, Apttus_Config2__OrderLineItem__c> getOrderLIwithERP(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems) {
        ilib_LogEvent.push(LOG_TITLE + '.getOrderLIwithERP()');//CMSI-68
        Map<String, Apttus_Config2__OrderLineItem__c> mapERPtoOli = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Set<String> setOliERP = new Set<String>();
        
        
        for(Apttus_Proposal__Proposal_Line_Item__c qLI: lstProposalLineItems) {
            if(qLI.ERP_Line_Number_Id__c != null) {
                setOliERP.add(qLI.ERP_Line_Number_Id__c);
            }
        }
        ilib_LogEvent.info('setOliERP : '+setOliERP); //CMSI-68
        List<Apttus_Config2__OrderLineItem__c> lstOrderLI = new ApttusOrderLineItemsSelector().selectOLIbyERPHeaderContract(setOliERP);
        
        for(Apttus_Config2__OrderLineItem__c oLI: lstOrderLI) {
            mapERPtoOli.put(oLI.ERP_Line_Number_Id__c, oLI);
        }
        ilib_LogEvent.info('mapERPtoOli :'+(!mapERPtoOli.isEmpty()? String.valueOf(mapERPtoOli.keySet()):MAPISEMPTY));//CMSI-68
        ilib_LogEvent.pop();//CMSI-68
        return mapERPtoOli;
    }
    
    /*
* [DCP-45314] Get OrderLineItems based on Id
*/
    public Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLIwithId(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems) {
        ilib_LogEvent.push(LOG_TITLE + '.getOrderLIwithId()');//CMSI-68
        Map<Id, Apttus_Config2__OrderLineItem__c> mapIdtoOli = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        Set<Id> setOliId = new Set<Id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c qLI: lstProposalLineItems) {
            if(qLI.Existing_Subscription__c != null) {
                setOliId.add(qLI.Existing_Subscription__c);
            }
        }
        
        List<Apttus_Config2__OrderLineItem__c> lstOrderLIExistingSub = new ApttusOrderLineItemsSelector().fetchLinesByIds(setOliId);
        for(Apttus_Config2__OrderLineItem__c oLI: lstOrderLIExistingSub) {
            mapIdtoOli.put(oLI.Id, oLI);
        }
        ilib_LogEvent.pop(); //CMSI-68
        return mapIdtoOli;
        
    }
    
    /**
*  @author  Govind Dubey
*  @description get the approval level based on different custom approval matrix field values
*  @Parameter Set of owner Account Ids
*  @return Map of Approval Hirarchies
**/
    private Map<id, Approval_Hierarchy__c> getApprovalHierarchyByAccountOwner(Set<Id> setAccountOwnerIds){
        ilib_LogEvent.push(LOG_TITLE + '.getApprovalHierarchyByAccountOwner()');//CMSI-68
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = new Map<id, Approval_Hierarchy__c>();   
        ilib_LogEvent.info('setAccountOwnerIds : '+setAccountOwnerIds);//CMSI-68     
        if (!setAccountOwnerIds.isEmpty()){
            List<Approval_Hierarchy__c> lstApprovalHierarchy = new ApprovalHierarchiesSelector().selectByAccountOwner(ApprovalCategory.CPQ_Sales_Hierarchy.name(), setAccountOwnerIds);
            ilib_LogEvent.info('Hierarchy List Result: '+UtilsCollection.getSetOfIds(lstApprovalHierarchy));//CMSI-68
            for(Approval_Hierarchy__c objApprovalHierarchy: lstApprovalHierarchy){
                ownerToApporovalHierarchy.put(objApprovalHierarchy.Approver_Level_1__c, objApprovalHierarchy);
            }
        }
        ilib_LogEvent.pop(); //CMSI-68
        return ownerToApporovalHierarchy;
    }
    
    /**
*  @author  Roopal Verma
*  @description DCP-25340 get the approval level and approval hierarchy from custom approval matrix
*  @Parameter Custom approval matrix, Incentive Id, Map of Id to Incentive
*  @return Custom promotion Wrapper
**/
    private CustomPromotionWrapper findLevelAndHierarchyForPromotion(CustomApprovalMatrixWrapper customMatrixWrapper,Id idIncentive,Map<Id, Apttus_Config2__Incentive__c> mapIdToIncentive){
        CustomPromotionWrapper objCustomPromotionWrapper = new CustomPromotionWrapper();
        if(customMatrixWrapper.promoCodeToListApprovalMatrix.containsKey(mapIdToIncentive.get(idIncentive).Apttus_Config2__IncentiveCode__c)){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.promoCodeToListApprovalMatrix.get(mapIdToIncentive.get(idIncentive).Apttus_Config2__IncentiveCode__c);
            for(Custom_Approval_Matrix__c objMatrix: lstApprovalMatrix){
                objCustomPromotionWrapper.idApprovalHierarchyPromotion = objMatrix.Approval_Hierarchy__c;
                for(Integer intCurrentLevel=1; intCurrentLevel<=MAX_APPROVAL_LEVEL;intCurrentLevel++){
                    Object objApprover = objMatrix.getSobject('Approval_Hierarchy__r').get('Approver_Level_'+intCurrentLevel+'__c');
                    if(objApprover==null) { break; }
                    objCustomPromotionWrapper.intApprovalLevelPromotion = intCurrentLevel;
                }
            }
        }
        return objCustomPromotionWrapper;
    }
    
    /**
*  @author  Govind Dubey
*  @description get the approval level based on different custom approval matrix field values
*  @Parameter Proposal line Item object and Set of Countries stored in custom metadata and list of Approval matrix
*  @return Approval level in integer
**/
    private CustomApprovalMatrixResult getApprovalMatrix(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal_Line_Item__c pli, String strDistributionChannel, Map<Custom_Approval_Matrix__c, Set<String>> mapCAMIdToSet,String strApprovalType, List<Custom_Approval_Matrix__c> lstApprovalMatrix,Map<Id, Product2> mapIdToProduct){
        return getApprovalMatrix(objProposal, pli, strDistributionChannel, mapCAMIdToSet, strApprovalType, lstApprovalMatrix,false,mapIdToProduct);
    }
    
    /**
*  @author  Rohan Chandarana
*  @description After Insert Logic (e.g. set approvals on Finalized Proposal etc)
**/
    public override void onAfterInsert() {
        ilib_Queueablethread queueableThreadAfterInsert = new ilib_Queueablethread('ApttusProposalLineItemsAfterInsert'); //DCP-53938
        Set<Id> setAssetLineItemIds = new Set<Id>();
        Set<Id> setClonedProposalIds = new Set<Id>();
        Set<Id> setFinalizedPropsalIds = new Set<Id>();
        Set<Id> setSoftwareProposalIds = new Set<Id>();
        List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync = new List<Admin_Operation__e>(); // Added for TASK0799027   
        Map<Id,Id> mapLineItemIdtoQuoteId = new Map<Id,Id>(); //DCP-53938
        
        /**
*  @author  Prakhar kumar
*  @description DCP-30368 For Stamping the QLI ID to Quote if it is a informatics Product
**/
        List<Apttus_Proposal__Proposal__c> lstQuote =new List<Apttus_Proposal__Proposal__c>();
        Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>> mapQuoteIDtoInfoQLI = new Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>>();
        // Fetching all the Custom Metadata        
        //Has all the Productcodes from metadata.
        
        String strCodeParameterValue = Code_Parameter__mdt.getInstance(STRING_CODE_PARAMETER_OPEN_OFFER_THRESHOLD)?.Values_Text__c;
        Integer intThresholdValue = String.isBlank(strCodeParameterValue) ? INTEGER_OPEN_OFFER_THRESHOLD_DEFAULT : Integer.valueOf(strCodeParameterValue);
        
        Boolean boolEligibleForBulkAsyncProcessing = records.size() > intThresholdValue;
        ilib_LogEvent.info('boolEligibleForBulkAsyncProcessing ::: '+boolEligibleForBulkAsyncProcessing);
        ilib_LogEvent.info('records.size() ::: '+records.size());
        
        for (Apttus_Proposal__Proposal_Line_Item__c pli : (List<Apttus_Proposal__Proposal_Line_Item__c>)records){
            if(String.isEmpty(pli.Apttus_Proposal__Proposal__c)) { continue; }
            if(pli.isClone()){
                setClonedProposalIds.add(pli.Apttus_Proposal__Proposal__c);
                ilib_LogEvent.message('setClonedProposalIds : '+setClonedProposalIds);//CMSI-68
                
            }else if(pli.Configuration_Status__c == System.Label.ConfigurationStatusFinalized){
                setFinalizedPropsalIds.add(pli.Apttus_Proposal__Proposal__c);
                if(pli.Material_Class__c == Label.ProductMaterialClassInformaticsSoftware) { setSoftwareProposalIds.add(pli.Apttus_Proposal__Proposal__c); }
            }
            if(pli.Apttus_QPConfig__LineStatus__c == LINE_STATUS_RENEWED && !String.isBlank(pli.Apttus_QPConfig__AssetLineItemId__c)) { setAssetLineItemIds.add(pli.Apttus_QPConfig__AssetLineItemId__c); }
            
            //compare each Quote Line item with all the Product codes of metadata for match
            if(pli.Is_Informatics_Product__c){
                if(!mapQuoteIDtoInfoQLI.containsKey(pli.Apttus_Proposal__Proposal__c)) {
                    mapQuoteIDtoInfoQLI.put(pli.Apttus_Proposal__Proposal__c, new List<Apttus_Proposal__Proposal_Line_Item__c>());
                }
                mapQuoteIDtoInfoQLI.get(pli.Apttus_Proposal__Proposal__c).add(pli);
            }
            
            //TASK0799027
            Boolean boolQuoteIsOpenOfferComparisonCustomer = pli.Open_Offer_Comparison_Customer__c || pli.Signed_Open_Offer__c;          
            if(boolQuoteIsOpenOfferComparisonCustomer) { //DCP-53938
                populateInputsForOpenOfferAsyncProcessing(mapLineItemIdtoQuoteId, lstOpenOfferQuotationUpdatesAsync, pli, boolEligibleForBulkAsyncProcessing);
            }
            //end of TASK0799027            
        }
        
        ilib_LogEvent.info('mapQuoteIDtoInfoQLI :'+(!mapQuoteIDtoInfoQLI.isEmpty()? String.valueOf(mapQuoteIDtoInfoQLI.keySet()):MAPISEMPTY));//CMSI-68
        Set<Id> setQuoteIds = mapQuoteIDtoInfoQLI.keySet(); 
        lstQuote = new ApttusProposalsSelector().selectByQuoteId(setQuoteIds);
        ilib_LogEvent.info('lstQuote: ' + UtilsCollection.getSetOfIds(lstQuote));//CMSI-68
        List<Apttus_Proposal__Proposal__c> lstProposalToUpdate = new List<Apttus_Proposal__Proposal__c>();
        //For removing duplicate iteration 
        Set<Id> setQuoteIdsforUnique = new set<Id>();
        for(Apttus_Proposal__Proposal__c quoteObj: lstQuote) {    
            setQuoteIdsforUnique.add(quoteObj.id);
            // INC0372151 : added Informatics_Line_Item_Number__c boolean
            quoteObj.Informatics_Line_Item_Number__c = true;
            List<Apttus_Proposal__Proposal_Line_Item__c> lstQLI = mapQuoteIDtoInfoQLI.get(quoteObj.id) ;
            for(Apttus_Proposal__Proposal_Line_Item__c ob : lstQLI){  //check for required fields
                
                InformaticProductsService.InformaticsProductWrapper wrap = InformaticProductsService.getConfig(ob);  
                if(wrap== null || allFieldsFilled(ob, wrap)) {
                    continue;
                }
                
                if(String.isNotBlank(quoteObj.Informatics_Product_Line_Item_Numbers__c)){
                    quoteObj.Informatics_Product_Line_Item_Numbers__c = quoteObj.Informatics_Product_Line_Item_Numbers__c + ',' +  ob.Name ;
                }else{ 
                    quoteObj.Informatics_Product_Line_Item_Numbers__c = ob.Name ;
                } 
            }
            if(String.isNotBlank(quoteObj.Informatics_Product_Line_Item_Numbers__c) && quoteObj.Informatics_Product_Line_Item_Numbers__c.length() > INT_MAX_SIZE){
                quoteObj.Informatics_Product_Line_Item_Numbers__c = quoteObj.Informatics_Product_Line_Item_Numbers__c.substring(0,INT_MAX_SIZE);
            } 
            quoteObj.Apttus_Proposal__Approval_Stage__c = System.Label.ProposalApprovalStatusApprovalRequired;
            quoteObj.Apttus_QPApprov__Approval_Status__c = System.Label.ProposalApprovalStatusNotSubmitted;
            lstProposalToUpdate.add(quoteObj);
        }
        //DCP-30368: update the quotations with the stamps
        
        // <----DCP-30368: END-->
        //<-----DGP-415 ---->
		Map<Id,Apttus_Proposal__Proposal_Line_Item__c> newMap = (Map<Id,Apttus_Proposal__Proposal_Line_Item__c>)trigger.newMap;
        List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems = (List<Apttus_Proposal__Proposal_Line_Item__c>) records;
        
		ProposalLineItemReapprovalManager.processNewLineItemsForReapproval(newMap);
		//<----DGP-415 End --->
        //Set Approval Stage/Status on Proposal if not cloned and configuration is finalized
        //DCP-32794 - remove Software_Product_Check__c
        ilib_LogEvent.info('setFinalizedPropsalIds : '+setFinalizedPropsalIds); //CMSI-68
        if(!setFinalizedPropsalIds.isEmpty()){
            for(Id idProposal: setFinalizedPropsalIds){
                if(! setQuoteIdsforUnique.contains(idProposal)){  //For removing duplicate iteration - Gopi
                    Apttus_Proposal__Proposal__c objProposal = new Apttus_Proposal__Proposal__c(Id = idProposal);
                    objProposal.Apttus_Proposal__Approval_Stage__c = System.Label.ProposalApprovalStatusApprovalRequired;
                    objProposal.Apttus_QPApprov__Approval_Status__c = System.Label.ProposalApprovalStatusNotSubmitted;
                    // INC0396464 : made Informatics_Product_Line_Item_Numbers__c blank when there are no informatics products left
                    objProposal.Informatics_Product_Line_Item_Numbers__c = '';
                    // INC0372151 : made Informatics_Line_Item_Number__c boolean:if no informatcis product then make false
                    objProposal.Informatics_Line_Item_Number__c = false;
                    lstProposalToUpdate.add(objProposal);
                }
            }
            
        }
        ilib_LogEvent.info('lstProposalToUpdate : '+UtilsCollection.getSetOfIds(lstProposalToUpdate));//CMSI-68
        if(!lstProposalToUpdate.isEmpty()) {
            update lstProposalToUpdate;
        }
        
        ilib_LogEvent.info('mapLineItemIdtoQuoteId size: ' + mapLineItemIdtoQuoteId.size());
        
        //Sync Proposal with Opportunity if line items cloned
        ilib_LogEvent.info('setClonedProposalIds : '+setClonedProposalIds); //CMSI-68
        
        if(!setClonedProposalIds.isEmpty()) {
            ApttusSyncToOpportunityQueueable queueableClassInstance = new ApttusSyncToOpportunityQueueable(setClonedProposalIds);
            queueableThreadAfterInsert.logAndQueue(queueableClassInstance, 'OnPLIClone', EXECUTE);
        }
        
        //move open offer processing logic to new method as part of TASK0799027
        evaluateOpenOfferQuotationUpdates(mapLineItemIdtoQuoteId, lstOpenOfferQuotationUpdatesAsync, queueableThreadAfterInsert,boolEligibleForBulkAsyncProcessing);
        syncProposalLines((List<Apttus_Proposal__Proposal_Line_Item__c>)records, new Set<String>{System.Label.OpportunityTypeCustomProductFirstBuy},queueableThreadAfterInsert);
        processAssetRenewalAutomation(setAssetLineItemIds, true);
        
        if(!queueableThreadAfterInsert.lstQueueableJobs.isEmpty()) { //DCP-53938 Cleanup
            ilib_QueueableManager.enqueueJob(queueableThreadAfterInsert);
        }
    }
    
    /**
*  @author Satya Swain
*  @description TASK0799027 : handle Open Offer calculation logic.
*  if we are over the threshold then populate list of Admin_Operation__e
*  else we populate map<Id,Id> for Queueable
*  @param Map<Id,Id> mapLineItemIdtoQuoteId, List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync, ilib_Queueablethread queueableThreadFromContext
*  @return void
**/
    private void populateInputsForOpenOfferAsyncProcessing(Map<Id,Id> mapLineItemIdtoQuoteId, List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync,Apttus_Proposal__Proposal_Line_Item__c objQuotationLineItem, Boolean boolEligibleForBulkAsyncProcessing) {
        Boolean boolForcePlatformEventMechanism = System.Test.isRunningTest() ? boolUseLargeCartProcessingMechanism : boolEligibleForBulkAsyncProcessing;
        if(boolForcePlatformEventMechanism) {
            lstOpenOfferQuotationUpdatesAsync.add(new Admin_Operation__e(Related_Record__c = objQuotationLineItem.id,Name__c = 'OpenOfferQuotationUpdatesAsync'));
        } else {
            mapLineItemIdtoQuoteId.put(objQuotationLineItem.Apttus_QPConfig__DerivedFromId__c,objQuotationLineItem.Apttus_Proposal__Proposal__c);
        }
    }
    
    /**
*  @author Satya Swain
*  @description TASK0799027 : handle Open Offer calculation logic.
*  if we are over the threshold then we launch a platform event
*  else we handle the business logic via queueable ()
*  @param Map<Id,Id> mapLineItemIdtoQuoteId, List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync, ilib_Queueablethread queueableThreadFromContext, Boolean boolEventNeededForOpenOfferCalculation
*  @return void
**/
    private void evaluateOpenOfferQuotationUpdates(Map<Id,Id> mapLineItemIdtoQuoteId, List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync, ilib_Queueablethread queueableThreadFromContext, Boolean boolEventNeededForOpenOfferCalculation) {
        Boolean boolForcePlatformEventMechanism = System.Test.isRunningTest() ? boolUseLargeCartProcessingMechanism : boolEventNeededForOpenOfferCalculation;
        if(boolForcePlatformEventMechanism) {
            evaluateOpenOfferQuotationUpdates(lstOpenOfferQuotationUpdatesAsync);
        } else {
            evaluateOpenOfferQuotationUpdates(mapLineItemIdtoQuoteId, queueableThreadFromContext);
        }
    }
    
    /**
*  @author Satya Swain
*  @description TASK0799027 : launch platform event to handle open offer quotation update calculations     
*  @param List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync
*  @return void
**/
    private void evaluateOpenOfferQuotationUpdates(List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync) {
        if(!lstOpenOfferQuotationUpdatesAsync.isEmpty()) {
            EventBus.publish(lstOpenOfferQuotationUpdatesAsync);
        }
    }
    
    /**
*  @author Satya Swain
*  @description TASK0799027 : launch queueable to handle open offer quotation update calculations
*  @param Map<Id,Id> mapLineItemIdtoQuoteId, List<Admin_Operation__e> lstOpenOfferQuotationUpdatesAsync, ilib_Queueablethread queueableThreadFromContext
*  @return void
**/
    private void evaluateOpenOfferQuotationUpdates(Map<Id,Id> mapLineItemIdtoQuoteId,ilib_Queueablethread queueableThreadFromContext) {
        if(!mapLineItemIdtoQuoteId.isEmpty()) {            
            OpenOfferQuotationUpdatesQueueable queueableClassInstance = new OpenOfferQuotationUpdatesQueueable('evaluateOpenOfferLogic',mapLineItemIdtoQuoteId); //DCP-53938
            queueableThreadFromContext.logAndQueue(queueableClassInstance, 'evaluateOpenOfferLogic', EXECUTE);
        }
    }
    
    
    /**
*  @author Roopal Verma
*  @description Convert Custom Approval Matrix List to Wrapper (i.e. group matrix records based on approval category) DCP-40107
*  @param List<Custom_Approval_Matrix__c> List of Custom Approval Matrix
*  @return CustomApprovalMatrixWrapper Approval Matrix Wrapper
**/
    private CustomApprovalMatrixWrapper getCustomApprovalMatrixWrapper(List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix){
        ilib_LogEvent.push(LOG_TITLE + '.getCustomApprovalMatrixWrapper()'); //CMSI-68
        CustomApprovalMatrixWrapper customMatrixWrapper = new CustomApprovalMatrixWrapper();
        for (Custom_Approval_Matrix__c am : lstCustomApprovalMatrix)
        {
            customMatrixWrapper.mapIdtoCAM.put(am.id,am);
            getPromoCodeWrapper(am,customMatrixWrapper);
            if(am.Approval_Hierarchy_Type__c != null)
            {
                List<String> lstAppHierarchyTypes = new List<String>();
                lstAppHierarchyTypes = am.Approval_Hierarchy_Type__c.split(';');
                if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_MATERIAL_NUMBER.Name() && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER)) 
                {
                    customMatrixWrapper.lstMatrixMaterialNumberRO.add(am);
                    customMatrixWrapper.setMaterialNumberMatrixIds.add(am.Id);
                } 
                else if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_MATERIAL_GROUP_1.Name() && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER))
                {
                    getMapMaterialGroup(am,customMatrixWrapper.mapMatrixtoMaterialGroupRO);
                    
                }
                else if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_DISCOUNT.Name() && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER))
                {
                    customMatrixWrapper.lstMatrixDiscountRO.add(am);
                } 
                if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_MATERIAL_GROUP_1.Name() && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    getMapMaterialGroup(am,customMatrixWrapper.mapMatrixtoMaterialGroupCustom);
                    
                } 
                if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_MATERIAL_NUMBER.Name() && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    customMatrixWrapper.lstMatrixMaterialNumberCustom.add(am);
                    customMatrixWrapper.setMaterialNumberMatrixIds.add(am.Id);
                } 
                if(am.RecordType.DeveloperName == ApprovalCategory.CPQ_DISCOUNT.Name() && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    customMatrixWrapper.lstMatrixDiscountCustom.add(am);
                }
            }
        }
        ilib_LogEvent.pop(); //CMSI-68
        return customMatrixWrapper;
        
    }
    
    /*
* @Roopal
* Calculating Map of Material Group wrapper
*/
    private void getMapMaterialGroup(Custom_Approval_Matrix__c objCam,Map<Custom_Approval_Matrix__c,Set<String>> mapMatrixToMG){
        if(mapMatrixToMG.containsKey(objCam)) 
        {
            Set<String> setMatGrp = mapMatrixToMG.get(objCam);
            setMatGrp.add(objCam.Material_Group_1__c);
            mapMatrixToMG.put(objCam, setMatGrp);
        }
        else
        {
            mapMatrixToMG.put(objCam, new Set<String> { objCam.Material_Group_1__c });
        }
    }
    
    /*
* @Roopal
* Calculating Map of Material Group wrapper
*/
    private void getPromoCodeWrapper(Custom_Approval_Matrix__c am,CustomApprovalMatrixWrapper customMatrixWrapper){
        if(am.RecordType.DeveloperName == ApprovalCategory.PROMOTION.Name()){
            if(!customMatrixWrapper.promoCodeToListApprovalMatrix.containsKey(am.Promo_Code__c)) { customMatrixWrapper.promoCodeToListApprovalMatrix.put(am.Promo_Code__c, new List<Custom_Approval_Matrix__c>()); } //DCP-25340, Get Map of protion code and approval matrix
            customMatrixWrapper.promoCodeToListApprovalMatrix.get(am.Promo_Code__c).add(am);
        }
    }
    
    
    /**
*  @Name           : processAssetRenewalAutomation
*  @Author         : Gopesh Banker (Apttus)
*  @Description    : logic for setting custom status on asset renewal
*  @Since          : 26 Sept 2018
*  @Returns        : null
*  @Params         : set of asset line item ids, boolean value if being done on insert trigger
**/
    public void processAssetRenewalAutomation(Set<Id> setAssetLineItemIds, Boolean isInsert){
        ilib_LogEvent.push(LOG_TITLE + '.processAssetRenewalAutomation()');//CMSI-68
        ilib_LogEvent.info('setAssetLineItemIds :'+setAssetLineItemIds);//CMSI-68
        if(!setAssetLineItemIds.isEmpty()){
            List<Apttus_Config2__AssetLineItem__c> lstAssetLines = new ApttusAssetLineItemsSelector().selectById(setAssetLineItemIds);
            List<Apttus_Config2__AssetLineItem__c> lstAssetLinesToUpdate = new List<Apttus_Config2__AssetLineItem__c>();
            for(Apttus_Config2__AssetLineItem__c objALI : lstAssetLines){
                if(objALI.Apttus_Config2__AssetStatus__c == System.Label.AssetLineItemStatusActivated){
                    if(isInsert){
                        if(objALI.Days_After_Expiry__c <= 0) { objALI.Status__c = System.Label.AssetLineItemStatusPendingRenewal; }
                        else { objALI.Status__c = System.Label.AssetLineItemStatusExpiredPendingRenewal; }
                    }else{
                        if (objALI.Days_After_Expiry__c <= 0) { objALI.Status__c = System.Label.AssetLineItemStatusActivated; }
                        else { objALI.Status__c = System.Label.AssetLineItemStatusExpired; }
                    }
                    lstAssetLinesToUpdate.add(objALI);
                }
            }
            ilib_LogEvent.info('lstAssetLinesToUpdate :'+UtilsCollection.getSetOfIds(lstAssetLinesToUpdate)); //CMSI-68
            if(!lstAssetLinesToUpdate.isEmpty()) { update lstAssetLinesToUpdate; }
        }
        ilib_LogEvent.pop();//CMSI-68
    }
    
    /**
*  @Name           : onBeforeUpdate
*  @Author         : Bharath Varma
*  @Description    : before update logic called
*  @Since          : 4 Mar 2021
*  @Returns        : null
*  @Params         : map of id to sobject records
**/
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords){
        Map<Id, Apttus_Proposal__Proposal_Line_Item__c> oldRecords = (Map<Id, Apttus_Proposal__Proposal_Line_Item__c>) existingRecords;
        List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems = (List<Apttus_Proposal__Proposal_Line_Item__c>) records;
        Map<Id, Apttus_Config2__OrderLineItem__c> mapIdtoOli = getOrderLIwithId(lstProposalLineItems);
        ilib_LogEvent.info('mapIdtoOli :'+(!mapIdtoOli.isEmpty()? String.valueOf(mapIdtoOli.keySet()):MAPISEMPTY)); //CMSI-68

        Set<Id> productIds = UtilsCollection.getSetOfIds(lstProposalLineItems, 'Apttus_Proposal__Product__c');
        ilib_LogEvent.info('productIds : '+productIds);
        Map<Id, Product2> mapIdToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(productIds));
        ilib_LogEvent.info('mapIdToProduct :'+(!mapIdToProduct.isEmpty()? String.valueOf(mapIdToProduct.keySet()):MAPISEMPTY));

        for(Apttus_Proposal__Proposal_Line_Item__c pli: lstProposalLineItems) {
            //IP2-175 uncheck free trial checkbox when an add on is selected
            if(pli.Is_Free_Trial__c && mapIdtoOli.get(pli.Existing_Subscription__c) != null && pli.Existing_Subscription__c != null && pli.Existing_Subscription__c != oldRecords.get(pli.Id).Existing_Subscription__c && ((mapIdtoOli.get(pli.Existing_Subscription__c).ERP_Line_Number_Id__c != null) || (pli.ERP_Line_Number_Id__c != null)))
            {
                pli.Free_Trial_Check__c = false;
            }
            //IP2-175 end
            if(pli.Existing_Subscription__c != null && pli.Product_Type__c == ADD_ON && mapIdtoOli.containsKey(pli.Existing_Subscription__c) && pli.Existing_Subscription__c != oldRecords.get(pli.Id).Existing_Subscription__c) {
                pli.Registrant_Contact__c = mapIdtoOli.get(pli.Existing_Subscription__c).Registrant_Contact__c == null ? null : mapIdtoOli.get(pli.Existing_Subscription__c).Registrant_Contact__c;
            }
            else if(pli.Existing_Subscription__c == null && pli.Product_Type__c == ADD_ON && oldRecords.get(pli.Id).Existing_Subscription__c != null){
                pli.Registrant_Contact__c = null;
            }
        }
        setIsoCodes.add(lstProposalLineItems[0].CurrencyIsoCode);
        ilib_LogEvent.info('setIsoCodes :'+setIsoCodes);//CMSI-68
        List<CurrencyType> currencyTypeList = new CurrencyCodesSelector().getCurrencyTypeRecordsFromIsoCodes(setIsoCodes);
        Decimal cts = currencyTypeList[0].conversionRate;
        ilib_LogEvent.info('cts :'+cts); //CMSI-68
        totalamountpriortodicountUSD(lstProposalLineItems,cts);
        
        //CMCM-9780
        updateHideContractDates(lstProposalLineItems);
        checkProductSpecificTermsAndMaterialClass(lstProposalLineItems, mapIdToProduct); //CMCM-11325

    
    }
    
    
    /**
*  @Name           : onAfterUpdate
*  @Author         : Gopesh Banker (Apttus)
*  @Description    : after update logic called
*  @Since          : 19 Sept 2018
*  @Returns        : null
*  @Params         : map of id to sobject records
**/
    public override void onAfterUpdate(Map<Id, SObject> existingRecords)
    {        
        syncProposalLines((List<Apttus_Proposal__Proposal_Line_Item__c>)records, new Set<String>{System.Label.OpportunityTypeCustomProductFirstBuy},null);
        checkRequiredData((List<Apttus_Proposal__Proposal_Line_Item__c>)records,'Update'); // DCP-30368
    }
    //<---- DGP-415------->
			/**
	*  @Name           : onBeforeDelete
	*  @Author         : Kumar Gaurav
	*  @Description    : Before delete logic called
	*  @Since          : 29-May-2024
	*  @Returns        : Map <Id, SObject> existingRecords
	*  @Params         : null
	**/
		public override void onBeforeDelete()
		{
			Map<Id,Apttus_Proposal__Proposal_Line_Item__c> oldMap = (Map<Id,Apttus_Proposal__Proposal_Line_Item__c>)trigger.oldMap;
			List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems = (List<Apttus_Proposal__Proposal_Line_Item__c>) records;
            
			ProposalLineItemReapprovalManager.processOldLineItemsBeforeDelete(oldMap);
		}
		//<-------DGP-415 End----->
    /**
*  @Name           : onAfterDelete
*  @Author         : Gopesh Banker (Apttus)
*  @Description    : after delete logic called
*  @Since          : 19 Sept 2018
*  @Returns        : null
*  @Params         : null
**/
    public override void onAfterDelete()
    {
        if(skipAfterDelete) {
            ilib_LogEvent.info('onBeforeUpdate skipped!'); 
            ilib_LogEvent.pop(); 
            return;
        }
        
        Set<Id> setAssetLineItemIds = new Set<Id>();
        syncProposalLines((List<Apttus_Proposal__Proposal_Line_Item__c>)records, new Set<String>{System.Label.OpportunityTypeCustomProductFirstBuy},null);
        for(Apttus_Proposal__Proposal_Line_Item__c pli : (List<Apttus_Proposal__Proposal_Line_Item__c>)records){
            if(pli.Apttus_QPConfig__LineStatus__c == LINE_STATUS_RENEWED && !String.isBlank(pli.Apttus_QPConfig__AssetLineItemId__c) && pli.Configuration_Status__c == System.Label.ConfigurationStatusFinalized) {
                setAssetLineItemIds.add(pli.Apttus_QPConfig__AssetLineItemId__c);
            }
        }
        ilib_LogEvent.info('setAssetLineItemIds :'+setAssetLineItemIds);//CMSI-68
        processAssetRenewalAutomation(setAssetLineItemIds, false);
        checkRequiredData((List<Apttus_Proposal__Proposal_Line_Item__c>)records,'Delete');  //DCP-30368
        
        
    }
    
    /**
*  @author Avina
*  @description  CMSI-51,method will return the workstream
*  @return string
**/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
    
    /**
*  @Name           : syncProposalLines
*  @Author         : Gopesh Banker (Apttus)
*  @Description    : check if the opp record type is the one that is mentioned, and if yes, syncs all proposals to opp
*  @Since          : 19 Sept 2018
*  @Returns        : null
*  @Params         : list of proposalLineIds, Set of opportunity recordtype names
**/
    private void syncProposalLines(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLines, Set<String> setOpportunityTypes,ilib_Queueablethread queueableThreadFromContext)
    {
        //CMSI-68
        ilib_LogEvent.push(LOG_TITLE + '.syncProposalLines()');
        ilib_LogEvent.info('lstProposalLines : '+UtilsCollection.getSetOfIds(lstProposalLines));
        ilib_LogEvent.info('setOpportunityTypes : '+setOpportunityTypes);//CMSI-68
        Set<Id> setProposalIdsToSync = new Set<Id>();
        for (Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLines){
            if(!setSynced.contains(pli.Apttus_Proposal__Proposal__c) 
               && setOpportunityTypes.contains(pli.Quote_Sub_Type__c) 
               && !String.isBlank(pli.Apttus_Proposal__Proposal__c)){
                   setProposalIdsToSync.add(pli.Apttus_Proposal__Proposal__c);
                   setSynced.add(pli.Apttus_Proposal__Proposal__c);
               } 
        }
        if(!setProposalIdsToSync.isEmpty()) { 
            ApttusSyncToOpportunityQueueable queueableClassInstance = new ApttusSyncToOpportunityQueueable(setProposalIdsToSync);
            
            if(queueableThreadFromContext!=null) { //DCP-53938 Cleanup
                queueableThreadFromContext.logAndQueue(queueableClassInstance, 'OnProposalSync', EXECUTE);
            }
            else {
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('OnProposalSync');
                queueableThread.logAndQueue(queueableClassInstance, 'OnProposalSync', EXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SALES);
            }
        }
    }
    
    /**
*  @author Roopal Verma
*  @description Wrapper class for List of Appproval Matrix DCP-40107
**/
    public class CustomApprovalMatrixWrapper {
        
        public Map<Id,Custom_Approval_Matrix__c> mapIdtoCAM{
            get {
                if (mapIdtoCAM == null) { mapIdtoCAM = new Map<Id,Custom_Approval_Matrix__c>(); }
                return mapIdtoCAM;
            }
            set; 
        }
        
        public List<Custom_Approval_Matrix__c> lstMatrixMaterialNumberRO {
            get {
                if (lstMatrixMaterialNumberRO == null) { lstMatrixMaterialNumberRO = new List<Custom_Approval_Matrix__c>(); }
                return lstMatrixMaterialNumberRO;
            }
            set;
        }
        
        public Map<Custom_Approval_Matrix__c,Set<String>> mapMatrixtoMaterialGroupRO {
            get {
                if (mapMatrixtoMaterialGroupRO == null) { mapMatrixtoMaterialGroupRO = new Map<Custom_Approval_Matrix__c,Set<String>>(); }
                return mapMatrixtoMaterialGroupRO;
            }
            set;
        }
        
        public List<Custom_Approval_Matrix__c> lstMatrixDiscountRO {
            get {
                if (lstMatrixDiscountRO == null) { lstMatrixDiscountRO = new List<Custom_Approval_Matrix__c>(); }
                return lstMatrixDiscountRO;
            }
            set;
        }
        
        public List<Custom_Approval_Matrix__c> lstMatrixMaterialNumberCustom {
            get {
                if (lstMatrixMaterialNumberCustom == null) { lstMatrixMaterialNumberCustom = new List<Custom_Approval_Matrix__c>(); }
                return lstMatrixMaterialNumberCustom;
            }
            set;
        }
        
        public Map<Custom_Approval_Matrix__c,Set<String>> mapMatrixtoMaterialGroupCustom {
            get {
                if (mapMatrixtoMaterialGroupCustom == null) { mapMatrixtoMaterialGroupCustom = new Map<Custom_Approval_Matrix__c,Set<String>>(); }
                return mapMatrixtoMaterialGroupCustom;
            }
            set;
        }
        
        public List<Custom_Approval_Matrix__c> lstMatrixDiscountCustom {
            get {
                if (lstMatrixDiscountCustom == null) { lstMatrixDiscountCustom = new List<Custom_Approval_Matrix__c>(); }
                return lstMatrixDiscountCustom;
            }
            set;
        }
        
        public Set<Id> setMaterialNumberMatrixIds {
            get {
                if (setMaterialNumberMatrixIds == null) { setMaterialNumberMatrixIds = new Set<Id>(); }
                return setMaterialNumberMatrixIds;
            }
            set;
        }
        
        public Map<String, List<Custom_Approval_Matrix__c>> promoCodeToListApprovalMatrix {
            get {
                if (promoCodeToListApprovalMatrix == null) { promoCodeToListApprovalMatrix = new Map<String, List<Custom_Approval_Matrix__c>>(); }
                return promoCodeToListApprovalMatrix;
            }
            set;
        }
        
    }
    
    /**
*  @author Rohan Chandarana
*  @description Wrapper class for Appproval Matrix Result
**/
    public class CustomApprovalMatrixResult {
        Integer intApprovalLevel;
        Custom_Approval_Matrix__c soApprovalMatrix;
        Boolean booldiscountlessthanLevel1;
        Id idOwner;
    }
    
    /**
*  @author Rohan Chandarana
*  @description Wrapper class for Promotion approval
**/
    public class CustomPromotionWrapper{
        Integer intApprovalLevelPromotion;
        Id idApprovalHierarchyPromotion;
    }
    
    /**
*  @author Rohan Chandarana
*  @description After undelete Logic (for Preview Scenario)
**/
    public override void onAfterUndelete(){
        Set<Id> setAssetLineItemIds = new Set<Id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c pli : (List<Apttus_Proposal__Proposal_Line_Item__c>)records)
        {
            if(pli.Apttus_QPConfig__LineStatus__c == LINE_STATUS_RENEWED && !String.isBlank(pli.Apttus_QPConfig__AssetLineItemId__c)) {
                setAssetLineItemIds.add(pli.Apttus_QPConfig__AssetLineItemId__c);
            }
        }
        ilib_LogEvent.info('setAssetLineItemIds :'+setAssetLineItemIds); //CMSI-68
        processAssetRenewalAutomation(setAssetLineItemIds, true);
    }
    
    /* Created By : KD
* Description : DCP-30368: Method to check all required data on QLI record
*/
    private List<Apttus_Proposal__Proposal__c> lstQuote;
    
    private void checkRequiredData(List<Apttus_Proposal__Proposal_Line_Item__c> lstrecords, String action){
        ilib_LogEvent.push(LOG_TITLE + '.checkRequiredData()');
        Map<Id,Set<String>> mapQuoteIDToInCompleteLines = new Map<Id,Set<String>>();      
        Set<Id> setQuoteIds = new Set<Id>(); 
        List<Apttus_Config2__LineItem__c > updateLineItemRecords =new List<Apttus_Config2__LineItem__c >();
        Set<Id > setUpdateLineItemRecords = new Set<Id >();
        
        List<Apttus_Proposal__Proposal_Line_Item__c> allProposalLineItems = new ApttusProposalLineItemsSelector().selectByQuoteId(UtilsCollection.getSetOfIds(lstrecords, 'Apttus_Proposal__Proposal__c'));
        ilib_LogEvent.info('allProposalLineItems :'+UtilsCollection.getSetOfIds(allProposalLineItems)); //CMSI-68
        for(Apttus_Proposal__Proposal_Line_Item__c pli : allProposalLineItems){
            if(!pli.Is_Informatics_Product__c){ continue; }
            
            setQuoteIds.add(pli.Apttus_Proposal__Proposal__c);
            // Line is informatics
            ilib_LogEvent.message('Informatics pli: ' + pli);
            Boolean boolAllFieldFilled = true;  
            InformaticProductsService.InformaticsProductWrapper wrap = InformaticProductsService.getConfig(pli);  
            ilib_LogEvent.message('Configuration: '+wrap);
            
            if(action == 'Update' && wrap!=null){
                //Checking if the required fields are filled
                boolAllFieldFilled =allFieldsFilled(pli, wrap);
                
                Apttus_Config2__LineItem__c objLineItem =new Apttus_Config2__LineItem__c();
                if(pli.Apttus_QPConfig__DerivedFromId__c!= NULL) {
                    objLineItem.Id = pli.Apttus_QPConfig__DerivedFromId__c;
                }
                
                integer fieldIndex=0;
                for(String str:wrap.lstQuoteFields){
                    if(!wrap.setReadOnlyFields.contains(str)) {
                        objLineItem.put(wrap.lstCartFields[fieldIndex],pli.get(str));
                    }
                    fieldIndex++;
                }
                if(pli.Apttus_QPConfig__DerivedFromId__c!= NULL && !setUpdateLineItemRecords.contains(objLineItem.Id)) {
                    updateLineItemRecords.add(objLineItem);  //Copying the values to the line Item object. 
                    setUpdateLineItemRecords.add(objLineItem.Id);
                }
            }      
            if(!boolAllFieldFilled){
                Set<String> setIncompleteLines = mapQuoteIDToInCompleteLines.get(pli.Apttus_Proposal__Proposal__c);
                if(setIncompleteLines ==null) {
                    setIncompleteLines= new Set<String>();
                    mapQuoteIDToInCompleteLines.put(pli.Apttus_Proposal__Proposal__c,setIncompleteLines);
                }                        
                setIncompleteLines.add(pli.Name);
            }
        }
        ilib_LogEvent.info('updateLineItemRecords : '+UtilsCollection.getSetOfIds(updateLineItemRecords));//CMSI-68
        ilib_LogEvent.info('mapQuoteIDToInCompleteLines : '+mapQuoteIDToInCompleteLines);//CMSI-68
        if(!updateLineItemRecords.isEmpty()) {
            update updateLineItemRecords;   
        }
        if(setQuoteIds.isEmpty()) {
            ilib_LogEvent.pop();
            return;   
        }
        if(lstQuote==null) {
            lstQuote = new ApttusProposalsSelector().selectById(setQuoteIds);
        }
        
        Set<Id> setQuoteIdsforUnique = new set<Id>();
        List<Apttus_Proposal__Proposal__c> lstUpdateQuote = new List<Apttus_Proposal__Proposal__c>();
        for(Apttus_Proposal__Proposal__c quoteObj: lstQuote){    
            setQuoteIdsforUnique.add(quoteObj.id);
            
            // INC0384911 Added logic to recalculate Informatics_Product_Line_Item_Numbers__c on update
            Apttus_Proposal__Proposal__c objUpdateQuote = 
                new Apttus_Proposal__Proposal__c (id=quoteObj.id,
                                                  Informatics_Product_Line_Item_Numbers__c = quoteObj.Informatics_Product_Line_Item_Numbers__c);
            
            // INC0384911 Condition to blank out field when all the required fields are populated on all the informatics line items 
            Set<String> lstQLINames = mapQuoteIDToInCompleteLines.get(quoteObj.id);
            if(lstQLINames == null) {
                if(String.isNotBlank(objUpdateQuote.Informatics_Product_Line_Item_Numbers__c)) {
                    objUpdateQuote.Informatics_Product_Line_Item_Numbers__c = null;
                    lstUpdateQuote.add(objUpdateQuote);
                }
                continue;
            }
            // INC0384911 Runs only if there are informatic lines where all the required fields are NOT populated
            objUpdateQuote.Informatics_Product_Line_Item_Numbers__c = null;
            for(String lineItemName : lstQLINames){  //check for required fields
                
                if(String.isBlank(objUpdateQuote.Informatics_Product_Line_Item_Numbers__c)){ 
                    objUpdateQuote.Informatics_Product_Line_Item_Numbers__c = lineItemName ;
                }
                // INC0384911 Checking with intMaxSize - 4 to add 4 dots at the end to show there are more line items
                else if(String.isNotBlank(objUpdateQuote.Informatics_Product_Line_Item_Numbers__c) && objUpdateQuote.Informatics_Product_Line_Item_Numbers__c.length() < INT_MAX_SIZE - 4){
                    objUpdateQuote.Informatics_Product_Line_Item_Numbers__c = objUpdateQuote.Informatics_Product_Line_Item_Numbers__c + ',' +  lineItemName ;
                }
                else{
                    objUpdateQuote.Informatics_Product_Line_Item_Numbers__c = objUpdateQuote.Informatics_Product_Line_Item_Numbers__c + '....';
                    break;
                }
            }
            lstUpdateQuote.add(objUpdateQuote);
            
        }
        
        ilib_LogEvent.info('lstUpdateQuote : '+UtilsCollection.getSetOfIds(lstUpdateQuote));//CMSI-68
        ilib_LogEvent.info('lstQuote : '+UtilsCollection.getSetOfIds(lstQuote));//CMSI-68
        if(!lstUpdateQuote.isEmpty()) {
            update lstUpdateQuote;
        }
        
        ilib_LogEvent.pop();
        
    }
    
    /* Created By : Akshay
* Description : DCP-30368: Method to check all required data on QLI record
*/
    private Boolean allFieldsFilled(Apttus_Proposal__Proposal_Line_Item__c pli, InformaticProductsService.InformaticsProductWrapper wrap){
        for(String strAPIName : wrap.setRequiredFields) {
            if(pli.get(strAPIName) == null){
                return false;
            }
        }
        return true;
    }
    
    /* Created By : Roopal
* Description : DCP-29812 - Logic for unique product specific term
*/
    private void updateProdSpecificTerm(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<Id, Product2> mapIdToProduct){
        ilib_LogEvent.push(LOG_TITLE + '.updateProdSpecificTerm()');//CMSI-68
        Map<Id, Apttus_Proposal__Proposal_Line_Item__c> mapProdIdtoPLI = new Map<Id, Apttus_Proposal__Proposal_Line_Item__c>();    //DCP-29812
        for(Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLineItems){
            if(mapProdIdtoPLI.isEmpty() || !mapProdIdtoPLI.containsKey(pli.Apttus_Proposal__Product__c)){    //DCP-29812
                mapProdIdtoPLI.put(pli.Apttus_Proposal__Product__c,pli);                                     //DCP-29812
            }
        }
        ilib_LogEvent.info('mapProdIdtoPLI :'+(!mapProdIdtoPLI.isEmpty()? String.valueOf(mapProdIdtoPLI.keySet()):MAPISEMPTY));//CMSI-68
        List<Product2> lstUniqueProdIds = mapIdToProduct.values();    //DCP-29812 <-- start
        ilib_LogEvent.info('lstUniqueProdIds : '+ UtilsCollection.getSetOfIds(lstUniqueProdIds));
        Set<Id> setUniqueIds = new Set<Id>();
        for(Product2 objProd : lstUniqueProdIds){
            if(objProd.Product_Specific_Terms__c != null) {
                setUniqueIds.add(objProd.Id);
            }
        }
        ilib_LogEvent.info('setUniqueIds : '+setUniqueIds); //CMSI-68
        
        for(Apttus_Proposal__Proposal_Line_Item__c objQLI : mapProdIdtoPLI.values()){
            if(setUniqueIds.contains(objQLI.Apttus_Proposal__Product__c)){
                objQLI.Product_Specific_Terms_Line_Item__c = 1;
            }
            objQLI.Distinct_Material_Number__c =1;
        }  
        ilib_LogEvent.pop();//CMSI-68                                                                                                   //DCP-29812 end -->
    }
    
    /* Created By : Rishi Sharma
* Description : IP2-175 - Identify if a product is free trial
* @Parameter List of Proposal Line items
* @return null
*/
    private void checkFreeTrial(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<Id, Product2> mapIdToProduct){
        ilib_LogEvent.push(LOG_TITLE + '.checkFreeTrial()');//CMSI-68
        Map<Id, Apttus_Proposal__Proposal_Line_Item__c> mapProdIdtoPLI = new Map<Id, Apttus_Proposal__Proposal_Line_Item__c>();   
        Map<Id, Apttus_Config2__OrderLineItem__c> mapIdtoOli = getOrderLIwithId(lstProposalLineItems); 
        ilib_LogEvent.info('mapIdtoOli :'+(!mapIdtoOli.isEmpty()? String.valueOf(mapIdtoOli.keySet()):MAPISEMPTY));//CMSI-68
        for(Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLineItems){
            if(mapProdIdtoPLI.isEmpty() || !mapProdIdtoPLI.containsKey(pli.Apttus_Proposal__Product__c)){    
                mapProdIdtoPLI.put(pli.Apttus_Proposal__Product__c,pli);                                     
            }
        }
        ilib_LogEvent.info('mapProdIdtoPLI :'+(!mapProdIdtoPLI.isEmpty()? String.valueOf(mapProdIdtoPLI.keySet()):MAPISEMPTY));//CMSI-68
        List<Product2> lstProd = mapIdToProduct.values();
        Set<String> setProdCode = new Set<String>();
        Map<id, String> mapProdIdtoProdCode = new Map<id, String>();
        for(Product2 objProd : lstProd){
            mapProdIdtoProdCode.put(objProd.id, objProd.ProductCode);
            setProdCode.add(objProd.ProductCode);
        }
        Map<String, Set<String>> mapPrdtoICA = new Map<String, Set<String>>();
        ilib_LogEvent.info('setProdCode :'+setProdCode);//CMSI-68
        List<Product_Code_to_Subscription_Map__mdt> lstPrdMdt = new ProductCodetoSubscriptionSelector().selectAllRecords(setProdCode);
        ilib_LogEvent.info('lstPrdMdt :'+lstPrdMdt); //CMSI-68
        if(!lstPrdMdt.isEmpty()){
            for(Product_Code_to_Subscription_Map__mdt mdtPrdtoIca: lstPrdMdt){
                mapPrdtoICA.put(mdtPrdtoIca.Product_Code__c, new Set<String>(mdtPrdtoIca.Subscription__c.split(',')));
            }
        }
        ilib_LogEvent.info('mapPrdtoICA :'+mapPrdtoICA); //CMSI-68
        updateFreeTrial(mapProdIdtoPLI, mapPrdtoICA, mapProdIdtoProdCode, mapIdtoOli, setProdCode);
        ilib_LogEvent.pop(); //CMSI-68 
    }
    
    /* Created By : Rishi Sharma
* Description : IP2-175 - Update Free Trial fields
* @Parameter mapProdIdtoPLI, mapPrdtoICA, mapProdIdtoProdCode, mapIdtoOli
* @return null
*/
    private void updateFreeTrial(Map<Id, Apttus_Proposal__Proposal_Line_Item__c> mapProdIdtoPLI, Map<String, Set<String>> mapPrdtoICA, Map<id, String> mapProdIdtoProdCode, Map<Id, Apttus_Config2__OrderLineItem__c> mapIdtoOli, Set<String> setProdCode){
        ilib_LogEvent.push(LOG_TITLE + '.updateFreeTrial()');//CMSI-68
        for(Apttus_Proposal__Proposal_Line_Item__c objQLI : mapProdIdtoPLI.values()){
            if(mapPrdtoICA.containsKey(mapProdIdtoProdCode.get(objQLI.Apttus_Proposal__Product__c))){
                objQLI.Is_Free_Trial__c = true;
                Boolean isParentProductPresent = false;
                if(objQLI.Is_Free_Trial__c) {
                    mapPrdtoICA.get(mapProdIdtoProdCode.get(objQLI.Apttus_Proposal__Product__c)).retainALL(setProdCode);
                    isParentProductPresent =  mapPrdtoICA.get(mapProdIdtoProdCode.get(objQLI.Apttus_Proposal__Product__c)).isEmpty() ? false : true;
                }
                if((objQLI.Existing_Subscription__c != null && mapIdtoOli.get(objQLI.Existing_Subscription__c).ERP_Line_Number_Id__c == null) || objQLI.ERP_Line_Number_Id__c == null){
                    objQLI.Free_Trial_Check__c = true;
                }
                if(isParentProductPresent) {
                    objQLI.Free_Trial_Check__c = false;
                }
            }  
        }
        ilib_LogEvent.pop(); //CMSI-68
    }
    
    /* Created By : Rishi Sharma
* Description : IP2-175 - Update ERP Line Number Id
* @Parameter List of Proposal Line items
* @return null
*/
    private void updateERPOnRenewal(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems){
        ilib_LogEvent.push(LOG_TITLE + '.updateERPOnRenewal()');//CMSI-68
        Boolean boolRenewal = false; 
        String strErpLineNo = '';
        String strRenewalType = 'Renewal - Software No Upsell';
        Set<id> setRelQuote = new Set<id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLineItems){
            setRelQuote.add(pli.Apttus_Proposal__Proposal__c);
        }
        ilib_LogEvent.info('setRelQuote :'+setRelQuote); //CMSI-68
        List<Apttus_Proposal__Proposal__c> lstRelatedQuote = new ApttusProposalsSelector().selectByQuoteId(setRelQuote);
        
        for(Apttus_Proposal__Proposal__c quo : lstRelatedQuote){
            if(quo.Quote_Sub_Type__c == strRenewalType){
                boolRenewal = true;
            }
        }
        if(boolRenewal == true){
            for(Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLineItems){
                if(pli.Previous_ERP_Contract_Number__c != null && pli.Previous_ERP_Contract_Line_Number__c != null && strErpLineNo == ''){
                    strErpLineNo = pli.Previous_ERP_Contract_Number__c+'_'+pli.Previous_ERP_Contract_Line_Number__c;
                }
                if(pli.Is_Free_Trial__c && pli.Previous_ERP_Contract_Number__c == null && pli.Previous_ERP_Contract_Line_Number__c == null && strErpLineNo != ''){
                    pli.ERP_Line_Number_Id__c = strErpLineNo;
                }
            }  
        }
        ilib_LogEvent.pop(); //CMSI-68
    }
    
    /* Created By : Roopal
* Description : DCP-40107 - Logic for getting priority of custom approval matrix.
*/
    private Integer getPriority(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal_Line_Item__c pli, String strDistributionChannel, Custom_Approval_Matrix__c objMatrix, boolean boolTransborder)
    {      
        String strAccRegion = BLANK_STRING;
        String strAccCountry = BLANK_STRING;
        String strRegion = objMatrix.Region__c;
        String strDistChannel = objMatrix.Distribution_Channel__c;
        String strSalesOrg = objMatrix.Sales_Organization__c;
        String strCountry = objMatrix.Country__c;
        String strCurrency = objMatrix.Currency__c;
        Integer intPriority = null;
        
        ilib_LogEvent.message('$$ strfirlds : '+strRegion+'_'+strDistChannel+'_'+strSalesOrg+'_'+strCountry+'_'+strCurrency);//CMSI-68
        
        AccountData accFields = getAccountData(objProposal,strDistributionChannel,boolTransborder);
        strAccRegion = accFields.strAccRegion;
        strAccCountry = accFields.strAccCountry;
        
        boolean boolSalesOrgBlank = String.isBlank(strSalesOrg);
        boolean boolRegionBlank = String.isBlank(strRegion) ;
        boolean boolDistChannelBlank = String.isBlank(strDistChannel);
        boolean boolCountryBlank = String.isBlank(strCountry);
        boolean boolCurrencyBlank = String.isBlank(strCurrency);
        
        boolean boolSalesOrg = (String.isBlank(strSalesOrg) ? false : strSalesOrg.contains(pli.Sold_To_Sales_Organization__c));
        boolean boolRegionCheck = (String.isBlank(strRegion) ? false : strRegion.contains(strAccRegion));  
        
        boolean boolCountryConditionCheck = (String.isBlank(strCountry) ? false : strCountry.contains(strAccCountry));
        boolean boolDistributionChannelCheck = (String.isBlank(strDistChannel) ? false : strDistChannel.contains(strDistributionChannel));
        boolean boolCurrencyCheck = (String.isBlank(strCurrency) ? false : strCurrency.contains(pli.CurrencyIsoCode));
        
        String strCondition = boolSalesOrg+'_'+boolRegionCheck+'_'+boolCountryConditionCheck+'_'+boolDistributionChannelCheck+'_'+boolCurrencyCheck+'_'+boolSalesOrgBlank+'_'+boolRegionBlank+'_'+boolDistChannelBlank+'_'+boolCountryBlank+'_'+boolCurrencyBlank;
        ilib_LogEvent.message('strCondition : '+strCondition);//CMSI-68
        
        if(!mapApprovalPriorityMetadata.isEmpty() && mapApprovalPriorityMetadata.containsKey(strCondition)){
            intPriority = mapApprovalPriorityMetadata.get(strCondition);
        }
        ilib_LogEvent.message('intPriority : '+intPriority);//CMSI-68
        return intPriority;
    }
    
    /*
*@ Roopal
*Wrapper Method for storing account valurs
*/
    public class AccountData {
        String strAccRegion;
        String strAccCountry;
    }
    
    /* Created By : Roopal
* Description : DCP-40107 - Method to get account country and region
*/
    private AccountData getAccountData(Apttus_Proposal__Proposal__c objProposal, String strDistributionChannel, boolean boolTransborder){
        String strAccRegion = BLANK_STRING;
        String strAccCountry = BLANK_STRING;
        if(boolTransborder){
            if(strDistributionChannel == System.Label.DistributionChannelIndirect){
                strAccRegion = (String.isBlank(objProposal.Distributor__r.Territory_Region__c) ? strAccRegion: objProposal.Distributor__r.Territory_Region__c);
                strAccCountry = objProposal.Distributor__r.BillingCountryCode;
                if(String.isBlank(strAccRegion)) {
                    mapQuoteIdToAccount.put(objProposal.id,objProposal.Distributor__r.Name);
                }
            }else{
                strAccRegion = (String.isBlank(objProposal.Ultimate_Consignee__r.Territory_Region__c) ? strAccRegion : objProposal.Ultimate_Consignee__r.Territory_Region__c);
                strAccCountry = objProposal.Ultimate_Consignee__r.BillingCountryCode;
                if(String.isBlank(strAccRegion)) {
                    mapQuoteIdToAccount.put(objProposal.id,objProposal.Ultimate_Consignee__r.Name);
                }
            }
        }else{
            strAccRegion = strDistributionChannel == System.Label.DistributionChannelIndirect ? (String.isBlank(objProposal.Ultimate_Consignee__r.Territory_Region__c) ? strAccRegion : objProposal.Ultimate_Consignee__r.Territory_Region__c) : (String.isBlank(objProposal.Apttus_Proposal__Account__r.Territory_Region__c) ? strAccRegion : objProposal.Apttus_Proposal__Account__r.Territory_Region__c);
                strAccCountry = strDistributionChannel == System.Label.DistributionChannelIndirect ? objProposal.Ultimate_Consignee__r.BillingCountryCode : objProposal.Apttus_Proposal__Account__r.BillingCountryCode;
            if(strAccRegion == BLANK_STRING && strDistributionChannel == System.Label.DistributionChannelIndirect) {
                mapQuoteIdToAccount.put(objProposal.id,objProposal.Ultimate_Consignee__r.Name);
            }
            else if(strAccRegion == BLANK_STRING && strDistributionChannel != System.Label.DistributionChannelIndirect) {
                mapQuoteIdToAccount.put(objProposal.id,objProposal.Apttus_Proposal__Account__r.Name);
            }
        }
        AccountData result = new AccountData();
        result.strAccRegion =strAccRegion;
        result.strAccCountry =strAccCountry;
        ilib_LogEvent.message('result of getAccountData: '+result);//CMSI-68
        return result;
    }
    
    /* Created By : Roopal
* Description : DCP-40107 - Logic for getting custom approval matrix.
*/
    private CustomApprovalMatrixResult getApprovalMatrix(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal_Line_Item__c pli, String strDistributionChannel, Map<Custom_Approval_Matrix__c, Set<String>> mapCAMIdToSet,String strApprovalType, List<Custom_Approval_Matrix__c> lstApprovalMatrix, boolean boolTransborder,Map<Id, Product2> mapIdToProduct){
        Integer intApprovalLevel;
        Custom_Approval_Matrix__c objApprovalMatrix = null;
        Integer intPriority = null;
        Datetime lastModifiedDate = null;
        boolean booldiscountlessthanLevel1 = false;
        Id idProduct = (pli.Apttus_QPConfig__OptionId__c == null) ? pli.Apttus_Proposal__Product__c : pli.Apttus_QPConfig__OptionId__c;
        
        Decimal decAdjPercent = (pli.Applied_Discount_Percentage__c == null? 0:pli.Applied_Discount_Percentage__c) ;
        Decimal decAdjAmount = (pli.Applied_Discount_Amount__c == null? 0:pli.Applied_Discount_Amount__c);
        if (!lstApprovalMatrix.isEmpty() && decAdjPercent > 0){
            for (Custom_Approval_Matrix__c objMatrix : lstApprovalMatrix){
                Integer intPriorityNew;
                Datetime lastModifiedDateNew;
                boolean boolApprovalMatrixFound = false;
                List<String> lstAppHierarchyTypes = new List<String>();
                lstAppHierarchyTypes = objMatrix.Approval_Hierarchy_Type__c.split(';');
                if(mapCAMIdToSet!=null && !mapCAMIdToSet.isEmpty() && mapCAMIdToSet.containsKey(objMatrix)){
                    Set<String> setValues = mapCAMIdToSet.get(objMatrix);
                    List<String> lstValues = new List<String>();
                    lstValues = getSetValues(setValues);
                    ilib_LogEvent.message('setValues : '+setValues); //CMSI-68
                    if(strApprovalType == APPROVAL_TYPE_MATNUM && lstValues.contains(mapIdToProduct.get(idProduct).Material_Number__c)){
                        intPriorityNew = getPriority(objProposal,pli,strDistributionChannel,objMatrix,boolTransborder);
                        lastModifiedDateNew = objMatrix.LastModifiedDate;
                        ilib_LogEvent.message('intPriorityNew : '+intPriorityNew);//CMSI-68
                        ilib_LogEvent.message('lastModifiedDateNew : '+lastModifiedDateNew);//CMSI-68
                    }else if(strApprovalType == APPROVAL_TYPE_MATGRP && lstValues.contains(mapIdToProduct.get(idProduct).Material_Group_1_Code__c)){
                        intPriorityNew = getPriority(objProposal,pli,strDistributionChannel,objMatrix,boolTransborder);
                        lastModifiedDateNew = objMatrix.LastModifiedDate;
                        ilib_LogEvent.message('intPriorityNewMG : '+intPriorityNew);//CMSI-68
                        ilib_LogEvent.message('lastModifiedDateNewMG : '+lastModifiedDateNew);//CMSI-68
                    }
                }else if(mapCAMIdToSet == null && strApprovalType == APPROVAL_TYPE_DISCOUNT){
                    intPriorityNew = getPriority(objProposal,pli,strDistributionChannel,objMatrix,boolTransborder);
                    lastModifiedDateNew = objMatrix.LastModifiedDate;
                    ilib_LogEvent.message('intPriorityNewDis : '+intPriorityNew);//CMSI-68
                    ilib_LogEvent.message('lastModifiedDateNewDis : '+lastModifiedDateNew);//CMSI-68
                }
                PriorityResult priorityResults = getPriorityResult(intPriorityNew,lastModifiedDateNew,objMatrix,intPriority,lastModifiedDate,objApprovalMatrix);
                intPriority = priorityResults.intPriority;
                objApprovalMatrix = priorityResults.soApprovalMatrix;
                lastModifiedDate = priorityResults.lastModifiedDate;
                boolApprovalMatrixFound = priorityResults.boolApprovalMatrixFound;    
                ilib_LogEvent.message('boolApprovalMatrixFound : '+boolApprovalMatrixFound);//CMSI-68
                if(boolApprovalMatrixFound == true){
                    CustomApprovalMatrixResult calculatedResult = getCustomApprovalMatrixResult(objApprovalMatrix,decAdjAmount,decAdjPercent,lstAppHierarchyTypes);
                    objApprovalMatrix = calculatedResult.soApprovalMatrix;
                    intApprovalLevel = calculatedResult.intApprovalLevel;
                    booldiscountlessthanLevel1 = calculatedResult.booldiscountlessthanLevel1;
                }
                
            }
        }
        CustomApprovalMatrixResult result = new CustomApprovalMatrixResult();
        result.intApprovalLevel = intApprovalLevel;
        result.soApprovalMatrix = objApprovalMatrix;
        result.booldiscountlessthanLevel1 = booldiscountlessthanLevel1;
        result.idOwner = getIdOwner(objProposal,strDistributionChannel,boolTransborder);
        ilib_LogEvent.message('result of getApprovalMatrix: '+result);//CMSI-68
        return result;
    } 
    
    /* Created By : Roopal
* Description : DCP-40107 - Method to get Owner Id
*/
    private Id getIdOwner(Apttus_Proposal__Proposal__c objProposal, String strDistributionChannel, boolean boolTransborder){
        Id idOwner;
        if(boolTransborder){
            if(strDistributionChannel == System.Label.DistributionChannelIndirect) {
                idOwner = objProposal.Distributor__r.OwnerId;
            }
            else { idOwner = objProposal.Ultimate_Consignee__r.OwnerId; }
        }else { idOwner = strDistributionChannel == System.Label.DistributionChannelIndirect ? objProposal.Ultimate_Consignee__r.OwnerId : objProposal.Apttus_Proposal__Account__r.OwnerId; }
        ilib_LogEvent.message('idOwner : '+idOwner);//CMSI-68
        return idOwner;
    }
    
    /*
*@ Roopal
*Wrapper Method for storing priority information
*/
    public class PriorityResult {
        Integer intPriority;
        Custom_Approval_Matrix__c soApprovalMatrix;
        Datetime lastModifiedDate;
        boolean boolApprovalMatrixFound;
    }
    
    /*
* @Roopal
* To get priority information
*/
    public PriorityResult getPriorityResult(Integer intPriorityNew,Datetime lastModifiedDateNew,Custom_Approval_Matrix__c objMatrix,Integer intPriority,Datetime lastModifiedDate,Custom_Approval_Matrix__c objApprovalMatrix){
        boolean boolApprovalMatrixFound = false;
        if (intPriorityNew != null && lastModifiedDateNew != null){
            if(intPriority == null || intPriority > intPriorityNew){
                intPriority = intPriorityNew;
                lastModifiedDate = lastModifiedDateNew;
                objApprovalMatrix = objMatrix;
                boolApprovalMatrixFound = true;
            }
            else if(intPriority != null && intPriority == intPriorityNew){
                if(lastModifiedDate < lastModifiedDateNew) {
                    objApprovalMatrix = objMatrix;
                }
                boolApprovalMatrixFound = true;
            }
        }
        PriorityResult priorityResults = new PriorityResult();
        priorityResults.intPriority = intPriority;
        priorityResults.soApprovalMatrix = objApprovalMatrix;
        priorityResults.lastModifiedDate = lastModifiedDate;
        priorityResults.boolApprovalMatrixFound = boolApprovalMatrixFound;
        ilib_LogEvent.message('priorityResults : '+priorityResults);//CMSI-68
        return priorityResults;
    }
    
    
    /*
* @Roopal
* Calculate levels based on discount
*/
    private CustomApprovalMatrixResult getCustomApprovalMatrixResult(Custom_Approval_Matrix__c objMatrix,Decimal decAdjAmount,Decimal decAdjPercent,List<String> lstAppHierarchyTypes){
        Custom_Approval_Matrix__c objApprovalMatrix = null;
        Integer intApprovalLevel = null;
        Boolean booldiscountlessthanLevel1 = false; 
        Decimal decMinDiscountPercent = (lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM) && objMatrix.Min_Discount__c!=null?objMatrix.Min_Discount__c :0);
        Decimal decMinDiscountAmount = (lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM) && objMatrix.Min_Discount_Amount__c!=null?objMatrix.Min_Discount_Amount__c :0);
        if(decAdjAmount>decMinDiscountAmount && decAdjPercent>decMinDiscountPercent){
            for(Integer intCurrentLevel=1; intCurrentLevel<=MAX_APPROVAL_LEVEL;intCurrentLevel++){
                Decimal decMatrixDiscountAmount = (Decimal) objMatrix.get('Discount_Amount_Level_' + intCurrentLevel + '__c');
                Decimal decMatrixDiscountPercent = (Decimal) objMatrix.get('Discount_Level_' + intCurrentLevel + '__c');
                if (decMatrixDiscountAmount!=null && decMatrixDiscountPercent!=null){
                    intApprovalLevel = intCurrentLevel;
                    objApprovalMatrix = objMatrix;
                    booldiscountlessthanLevel1 = false;
                    if (decAdjAmount <= decMatrixDiscountAmount || decAdjPercent <= decMatrixDiscountPercent) { break; }
                }
            }
        }
        else if(decAdjAmount <= decMinDiscountAmount || decAdjPercent <= decMinDiscountPercent)
        {
            objApprovalMatrix = objMatrix;
            booldiscountlessthanLevel1 = true;
        }
        CustomApprovalMatrixResult result = new CustomApprovalMatrixResult();
        result.intApprovalLevel = intApprovalLevel;
        result.soApprovalMatrix = objApprovalMatrix;
        result.booldiscountlessthanLevel1 = booldiscountlessthanLevel1;
        ilib_LogEvent.message('result of getCustomApprovalMatrixResult: '+result);//CMSI-68
        return result;
    }
    
    /*
* @Roopal
* To get set of material group or material number values
*/
    private List<String> getSetValues(Set<String> setValues){
        List<String> lstValues = new List<String>();
        if(setValues != null){
            for(String strVal : setValues) {
                lstValues.addAll(strVal.split(';'));
            }
        }
        ilib_LogEvent.message('lstValues of getSetValues: '+lstValues);//CMSI-68
        return lstValues;
    }
    
    /*
* @Roopal
* To set fields in cloned quotes
*/
    private void setClonedQuoteValues(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems){
        ilib_LogEvent.push(LOG_TITLE + '.setClonedQuoteValues()');//CMSI-68
        ilib_LogEvent.info('lstProposalLineItems : '+UtilsCollection.getSetOfIds(lstProposalLineItems));//CMSI-68
        for (Integer index = lstProposalLineItems.size() - 1; index >= 0; index--){
            if (lstProposalLineItems[index].isClone()) {
                lstProposalLineItems[index].Apttus_QPApprov__Approval_Status__c = APPROVAL_STATUS_NONE;
                //@Joshith - Null external id fields
                lstProposalLineItems[index].ERP_Line_Number__c = null;
                lstProposalLineItems[index].Legacy_SFDC_Record_ID__c = null;
                lstProposalLineItems[index].Global_Trade_Block__c = false;
                lstProposalLineItems.remove(index);
            }
        }
        ilib_LogEvent.pop(); //CMSI-68
    }       
    
    @TestVisible
    private static Boolean useOldFrameworkWhileTesting = true;
    
        
    /*
* @Roopal
* Calculate approval logic
*/
    public Map<Id, Apttus_Proposal__Proposal__c> setApprovals(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems,
                                                              Set<Id> setAccountOwnerIds, 
                                                              Map<id,Apttus_Proposal__Proposal__c> idToProposal,
                                                              Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate)
    {
        ilib_LogEvent.push(LOG_TITLE + '.setApprovals()');//CMSI-68
        //// DCP-48131 : NEW APPROVALS start
        Boolean forceOldFramework = System.Test.isRunningTest() && useOldFrameworkWhileTesting;
        if (Feature.isOn('SalesApprovalsPipeline') && !forceOldFramework)
        {
            Approvals.QuoteLineInputs approvalInputs = new Approvals.QuoteLineInputs(lstProposalLineItems, idToProposal);
            IApprovalsAPI approvals = ApprovalsService.init(approvalInputs);
            Approvals.QuoteHeaderUpdates headerUpdates = approvals.processQuoteLines();
            
            for (Id quoteId : headerUpdates.idToUpdates.keySet())
            {
                Apttus_Proposal__Proposal__c quote = idToQuotationForUpdate.get(quoteId);
                if (quote == null)
                {
                    quote = idToProposal.get(quoteId);
                }
                
                if (quote == null) { continue; }
                
                Approvals.QuoteHeaderUpdateFields headerUpdater = headerUpdates.idToUpdates.get(quoteId);
                headerUpdater.updateHeaderRecord(quote);
                
                idToQuotationForUpdate.put(quoteId, quote);
            }
            ilib_LogEvent.pop();
        }
        //// DCP-48131 : NEW APPROVALS end
        else 
        {
            PreparedApprovalSets approvalSets = getPreparedApprovalSets(lstProposalLineItems,setAccountOwnerIds);
            
            Map<Id,Id> mapQuoteIdToROHierarchy = new Map<Id,Id>();
            Map<Id,Id> mapQuoteIdToUCHierarchy = new Map<Id,Id>();
            Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError = new Map<Id, Set<Id>>();
            //Calling method for initializing custom metadata map.
            initializeApprovalPriorityMetadata();
            
            for (Apttus_Proposal__Proposal_Line_Item__c pli : lstProposalLineItems)
            {
                calculateLineLevelApprovals(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,mapQuoteIdToROHierarchy,mapQuoteIdToUCHierarchy);
            }
            
            //To Display error in case of Sales Discretionary Approvals - If hierarchy not found
            approvalErrorHandling(quoteIdToSetOfOwnerIdsForError,idToQuotationForUpdate,idToProposal);
            
            //Updating quotation record for Record owner hierarhcy details DCP-40107
            Set<Id> setAllQuoteIds = new Set<Id>();
            if (!mapQuoteIdToROHierarchy.isEmpty()) {
                setAllQuoteIds.addAll(mapQuoteIdToROHierarchy.keyset());
            }
            if (!mapQuoteIdToUCHierarchy.isEmpty()) {
                setAllQuoteIds.addAll(mapQuoteIdToUCHierarchy.keyset());
            }
            
            ilib_LogEvent.info('setAllQuoteIds : ' + setAllQuoteIds);//CMSI-68
            
            if (!setAllQuoteIds.isEmpty()) {
                updateQuotations(setAllQuoteIds,idToProposal,mapQuoteIdToROHierarchy,mapQuoteIdToUCHierarchy,idToQuotationForUpdate);
            } 
        }
        ilib_LogEvent.info('idToQuotationForUpdate :'+(!idToQuotationForUpdate.isEmpty()? String.valueOf(idToQuotationForUpdate.keySet()):MAPISEMPTY));//CMSI-68
        ilib_LogEvent.pop(); //CMSI-68
        return idToQuotationForUpdate;
    }
    
    /*
* @Roopal
* Update quotations
*/
    private void updateQuotations(Set<Id> setAllQuoteIds, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, Map<Id, Id> mapQuoteIdToROHierarchy, Map<Id, Id> mapQuoteIdToUCHierarchy, Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate)
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateQuotations()');//CMSI-68
        for(Id idQuote : setAllQuoteIds){
            Apttus_Proposal__Proposal__c objQuotation = idToProposal.get(idQuote);
            if(mapQuoteIdToROHierarchy.containsKey(idQuote)) {
                objQuotation.Approval_Hierarchy_Record_Owner__c = mapQuoteIdToROHierarchy.get(idQuote);
            }
            if(mapQuoteIdToUCHierarchy.containsKey(idQuote)) {
                objQuotation.Approval_Hierarchy_Transborder__c = mapQuoteIdToUCHierarchy.get(idQuote);
            }
            if(!idToQuotationForUpdate.containsKey(idQuote)) {
                idToQuotationForUpdate.put(idQuote,objQuotation);
            }
        }
        ilib_LogEvent.info('idToQuotationForUpdate :'+(!idToQuotationForUpdate.isEmpty()? String.valueOf(idToQuotationForUpdate.keySet()):MAPISEMPTY));//CMSI-68
        ilib_LogEvent.pop(); //CMSI-68
    }
    
    /*
* @Roopal
* Update Error Map
*/
    private String updateErrorMap (Id idQuote,List<User> lstUser,Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError,String strHierarchyError){
        for(User u : lstUser){
            if(quoteIdToSetOfOwnerIdsForError.get(idQuote).contains(u.Id)){
                if(String.isBlank(strHierarchyError)) {
                    strHierarchyError = Label.UI_Error_ApprovalHierarchyNotInPlace+' '+u.Name+'.';
                }
                else {
                    strHierarchyError += ', '+u.Name;
                }
            } 
        }
        if(String.isNotBlank(strHierarchyError)) {
            strHierarchyError +=' '+Label.UI_Error_ContactQuoteTeam + '\n';
        }
        ilib_LogEvent.message('strHierarchyError : ' + strHierarchyError);//CMSI-68
        return strHierarchyError;
    }
    
    /*
* @Roopal
* Approval error handling DCP-43262
*/
    private void approvalErrorHandling (Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate,Map<id,Apttus_Proposal__Proposal__c> idToProposal){
        ilib_LogEvent.push(LOG_TITLE + '.approvalErrorHandling()');//CMSI-68
        Set<Id> setQuoteToUpdate = new Set<Id>();
        List<User> lstUser = new List<User>();
        String strHierarchyError = '';
        String strTerritoryError = '';
        String strMatrixError = '';
        lstUser = returnUserList(quoteIdToSetOfOwnerIdsForError,setQuoteToUpdate);
        ilib_LogEvent.info('lstUser : ' + UtilsCollection.getSetOfIds(lstUser));//CMSI-68
        ilib_LogEvent.info('mapQuoteIdToAccount : ' +mapQuoteIdToAccount);//CMSI-68
        if(!mapQuoteIdToAccount.isEmpty()) {
            setQuoteToUpdate.addAll(mapQuoteIdToAccount.keySet());
        }
        if(!setQuotationIdsWithMatrixError.isEmpty()) {
            setQuoteToUpdate.addAll(setQuotationIdsWithMatrixError);
        }
        ilib_LogEvent.info('setQuoteToUpdate : ' + setQuoteToUpdate); //CMSI-68 
        if(!setQuoteToUpdate.isEmpty()){
            for(Id idQuote : setQuoteToUpdate){
                Apttus_Proposal__Proposal__c objQuotation = idToProposal.get(idQuote);
                if(!lstUser.isEmpty()) {
                    strHierarchyError = updateErrorMap(idQuote,lstUser,quoteIdToSetOfOwnerIdsForError,strHierarchyError);
                }
                if(mapQuoteIdToAccount.keySet().contains(idQuote)){
                    if(String.isBlank(strTerritoryError)) {
                        strTerritoryError = Label.UI_Error_AccountTerritoryNotInPlace+' '+mapQuoteIdToAccount.get(idQuote)+'.';
                    }
                    else {
                        strTerritoryError += ', '+mapQuoteIdToAccount.get(idQuote);
                    }
                    if(String.isNotBlank(strTerritoryError)) {
                        strTerritoryError +=' '+Label.UI_Error_ContactRegionalSalesOps + '\n';    
                    }        
                }
                if(setQuotationIdsWithMatrixError.contains(idQuote)) {
                    strMatrixError = Label.UI_Error_ApprovalMatrixNotFound + '\n';
                }
                
                
                objQuotation.Sales_Discretionary_Approval_Error__c =  strHierarchyError + strTerritoryError + strMatrixError;
                
                idToQuotationForUpdate.put(objQuotation.id,objQuotation);
            }
        }
        ilib_LogEvent.pop(); //CMSI-68
    }
    
    /*
* @Roopal
* Get list of users DCP-43262
*/
    private List<User> returnUserList (Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError,Set<Id> setQuoteToUpdate){
        ilib_LogEvent.push(LOG_TITLE + '.returnUserList()');//CMSI-68
        List<User> lstUser = new List<User>();
        if(!quoteIdToSetOfOwnerIdsForError.isEmpty()){
            setQuoteToUpdate.addAll(quoteIdToSetOfOwnerIdsForError.keySet());
            Set<Id> setOwnerId = new Set<Id>();
            for(Id idQuote : quoteIdToSetOfOwnerIdsForError.keySet()) {
                setOwnerId.addAll(quoteIdToSetOfOwnerIdsForError.get(idQuote));
            }
            lstUser = new UsersSelector().selectByUserId(setOwnerId);
        }
        ilib_LogEvent.info('lstUser : ' + lstUser);//CMSI-68 
        ilib_LogEvent.pop(); //CMSI-68
        return lstUser;
    }
    /*
* @Roopal
* Get Map of Custom Approval Matrix to Set of Products associated to it
*/
    public static Map<Custom_Approval_Matrix__c, Set<String>> getMapCAMIdToSetProducts(List<Custom_Approval_Matrix_Products__c> lstCAMProduct,Map<Custom_Approval_Matrix__c, Set<String>> mapCAMIdToSetProduct, CustomApprovalMatrixWrapper customMatrixWrapper)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getMapCAMIdToSetProducts()');//CMSI-68
        for(Custom_Approval_Matrix_Products__c objCAMP :lstCAMProduct)
        {
            
            if(mapCAMIdToSetProduct.containsKey(customMatrixWrapper.mapIdtoCAM.get(objCAMP.Custom_Approval_Matrix__c)))
            {
                Set<String> setProductMaterialNo = mapCAMIdToSetProduct.get(customMatrixWrapper.mapIdtoCAM.get(objCAMP.Custom_Approval_Matrix__c));
                setProductMaterialNo.add(objCAMP.Product__r.Material_Number__c);
                mapCAMIdToSetProduct.put(customMatrixWrapper.mapIdtoCAM.get(objCAMP.Custom_Approval_Matrix__c), setProductMaterialNo);
            }
            else 
            {
                mapCAMIdToSetProduct.put(customMatrixWrapper.mapIdtoCAM.get(objCAMP.Custom_Approval_Matrix__c), new Set<String> { objCAMP.Product__r.Material_Number__c });
            }
        }
        ilib_LogEvent.info('mapCAMIdToSetProduct : ' +mapCAMIdToSetProduct);//CMSI-68
        ilib_LogEvent.pop(); //CMSI-68
        return mapCAMIdToSetProduct;
    }
    
    /*
*@ Roopal
*Wrapper Method for storing promotions Sets
*/
    public class PrepareSets {
        Set<Id> setProductId;
        Set<Id> setIncentiveId;
    }
    
    /*
* @Roopal
* Get Sets of Ids
*/
    private PrepareSets getPreparedSets(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getPreparedSets()');//CMSI-68
        ilib_LogEvent.info('lstProposalLineItems :'+UtilsCollection.getSetOfIds(lstProposalLineItems)); //CMSI-68
        Set<Id> setProductId = new Set<Id>();
        Set<Id> setIncentiveId = new Set<Id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c objPLI: lstProposalLineItems){
            if(objPLI.Promotion_1__c != null) {  //DCP-25340 Adding incentives from PLI to the set of incentive Ids <--- Start
                setIncentiveId.add(objPLI.Promotion_1__c);
            }
            if(objPLI.Promotion_2__c != null) {
                setIncentiveId.add(objPLI.Promotion_2__c);
            }
            if(objPLI.Promotion_3__c != null) {
                setIncentiveId.add(objPLI.Promotion_3__c);
            }
            if(objPLI.Promotion_4__c != null) {
                setIncentiveId.add(objPLI.Promotion_4__c);
            }
            if(objPLI.Promotion_5__c != null) {
                setIncentiveId.add(objPLI.Promotion_5__c); //DCP-25340 End --->
            }
            setProductId.add(objPLI.Apttus_Proposal__Product__c);
            if(objPLI.Apttus_QPConfig__OptionId__c != null) {
                setProductId.add(objPLI.Apttus_QPConfig__OptionId__c);
            }
        }
        
        PrepareSets result = new PrepareSets();
        result.setProductId = setProductId;
        result.setIncentiveId = setIncentiveId;
        ilib_LogEvent.info('result of getPreparedSets: '+ result);//CMSI-68
        ilib_LogEvent.pop(); //CMSI-68
        return result;
    }
    
    /*
*@ Roopal
*Wrapper Method for storing Approval Sets
*/
    public class PreparedApprovalSets {
        public CustomApprovalMatrixWrapper customMatrixWrapper;
        public Map<Id, Product2> mapIdToProduct;
        public Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct;
        public Map<Id, Apttus_Config2__Incentive__c> mapIdToIncentive;
        public Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy;
    }
    
    /*
* @Roopal
* Get Sets and Maps for approvals
*/
    private PreparedApprovalSets getPreparedApprovalSets(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Set<Id> setAccountOwnerIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getPreparedApprovalSets()');//CMSI-68
        Set<Id> setProductId = new Set<Id>();
        Set<Id> setIncentiveId = new Set<Id>(); 
        
        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive();
        CustomApprovalMatrixWrapper customMatrixWrapper = getCustomApprovalMatrixWrapper(lstCustomApprovalMatrix);
        ilib_LogEvent.info('customMatrixWrapper :'+customMatrixWrapper); //CMSI-68
        
        PrepareSets setIds = getPreparedSets(lstProposalLineItems);
        setProductId = setIds.setProductId;
        setIncentiveId = setIds.setIncentiveId;
        
        Map<Id, Product2> mapIdToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(setProductId));
        ilib_LogEvent.info('mapIdToProduct :'+(!mapIdToProduct.isEmpty()? String.valueOf(mapIdToProduct.keySet()):MAPISEMPTY));//CMSI-68
        
        Set<Id> setCAMMaterialNoId = customMatrixWrapper.setMaterialNumberMatrixIds;
        List<Custom_Approval_Matrix_Products__c> lstCAMProduct = new CustomApprovalMatrixProductSelector().selectbyCustomApprMatrixId(setCAMMaterialNoId);
        ilib_LogEvent.info('lstCAMProduct : ' + UtilsCollection.getSetOfIds(lstCAMProduct));
        
        Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct = new Map<Custom_Approval_Matrix__c,Set<String>>();
        mapCAMIdToSetProduct = getMapCAMIdToSetProducts(lstCAMProduct,mapCAMIdToSetProduct,customMatrixWrapper);
        
        Map<Id, Apttus_Config2__Incentive__c> mapIdToIncentive = new Map<Id,Apttus_Config2__Incentive__c>(new ApttusIncentivesPromotionsSelector().getPromotionsById(setIncentiveId)); //DCP-25340, Map of Incentive Id to Incentives
        
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = getApprovalHierarchyByAccountOwner(setAccountOwnerIds);
        
        PreparedApprovalSets result = new PreparedApprovalSets();
        result.customMatrixWrapper = customMatrixWrapper;
        result.mapIdToProduct = mapIdToProduct;
        result.mapCAMIdToSetProduct = mapCAMIdToSetProduct;
        result.mapIdToIncentive = mapIdToIncentive;
        result.ownerToApporovalHierarchy = ownerToApporovalHierarchy;
        ilib_LogEvent.info('result of getPreparedApprovalSets: ' + result);//CMSI-68
        ilib_LogEvent.pop(); //CMSI-68
        return result;
    }
    
    /*
* @Roopal
* Get Sets of Ids
*/
    private void calculateLineLevelApprovals (Apttus_Proposal__Proposal_Line_Item__c pli,Map<id,Apttus_Proposal__Proposal__c> idToProposal,PreparedApprovalSets approvalSets,Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError,Map<Id,Id> mapQuoteIdToROHierarchy,Map<Id,Id> mapQuoteIdToUCHierarchy){
        String strApprovalCategory = '';
        Integer intApprovalLevelDiscount = null;
        Integer intApprovalLevelUCDiscount = null;
        Id idApprovalHierarchyDiscount = null;
        Id idApprovalHierarchyUCDiscount = null;
        String strApprovalStatus = null;
        Boolean boolApprovalFoundMNRO = false;
        Boolean boolApprovalFoundMGRO = false;
        Boolean boolApprovalFoundDisRO = false;
        Boolean boolApprovalFoundMNCust = false;
        Boolean boolApprovalFoundMGCust = false;
        Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate = new Map<Id, Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        
        blankOutErrorFields(objProposal,idToQuotationForUpdate);
        
        //Set Product Level Approvals
        
        //DCP-28664 Identify Fix Bundle
        Boolean isFixBundle = false;
        if(pli.Apttus_QPConfig__OptionId__c == null && pli.Material_Class_Type__c == Label.FixedBundleMatClassType){
            isFixBundle = true;
        }
        ApprovalsResult approvalResults = new ApprovalsResult();
        ilib_LogEvent.message('isFixBundle : '+isFixBundle);
        if(objProposal!=null && pli.Applied_Discount_Details__c!=null && pli.Applied_Discount_Percentage__c != null && pli.Applied_Discount_Percentage__c > 0 && !isFixBundle){
            String strDistributionChannel = calculateDisChannel(objProposal);
            
            //DCP-25340, Promotion Approvals
            approvalResults = calculatePromotionApprovals(pli,approvalSets,strApprovalCategory,approvalResults);
            
            if(pli.Applied_Discount_Details__c.contains(label.ApprovalStepNameSalesDiscretionary)){
                //Record Owner approvals DCP-40107
                //Material Number Approvals
                approvalResults = calculateMaterialNumberRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel, approvalResults);
                boolApprovalFoundMNRO = approvalResults.boolApprovalFoundMNRO;
                intApprovalLevelDiscount = approvalResults.intApprovalLevelDiscount;
                idApprovalHierarchyDiscount = approvalResults.idApprovalHierarchyDiscount;
                idApprovalHierarchyUCDiscount = approvalResults.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = approvalResults.intApprovalLevelUCDiscount;
                strApprovalCategory = approvalResults.strApprovalCategory;
                strApprovalStatus = approvalResults.strApprovalStatus;
                ilib_LogEvent.message('matNumROResults : '+approvalResults);//CMSI-68
                
                //Material Group Approvals
                approvalResults = calculateMaterialGroupRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel,boolApprovalFoundMNRO,intApprovalLevelDiscount,idApprovalHierarchyDiscount,idApprovalHierarchyUCDiscount,intApprovalLevelUCDiscount,approvalResults);
                boolApprovalFoundMGRO = approvalResults.boolApprovalFoundMGRO;
                intApprovalLevelDiscount = approvalResults.intApprovalLevelDiscount;
                idApprovalHierarchyDiscount = approvalResults.idApprovalHierarchyDiscount;
                idApprovalHierarchyUCDiscount = approvalResults.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = approvalResults.intApprovalLevelUCDiscount;
                strApprovalCategory = approvalResults.strApprovalCategory;
                strApprovalStatus = approvalResults.strApprovalStatus;
                ilib_LogEvent.message('matGrpROResults : '+approvalResults);//CMSI-68
                
                //Discount approval for record owner
                approvalResults = calculateDiscountRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel,boolApprovalFoundMNRO,boolApprovalFoundMGRO,intApprovalLevelDiscount,idApprovalHierarchyDiscount,idApprovalHierarchyUCDiscount,intApprovalLevelUCDiscount,approvalResults);
                boolApprovalFoundDisRO = approvalResults.boolApprovalFoundDisRO;
                intApprovalLevelDiscount = approvalResults.intApprovalLevelDiscount;
                idApprovalHierarchyDiscount = approvalResults.idApprovalHierarchyDiscount;
                idApprovalHierarchyUCDiscount = approvalResults.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = approvalResults.intApprovalLevelUCDiscount;
                strApprovalCategory = approvalResults.strApprovalCategory;
                strApprovalStatus = approvalResults.strApprovalStatus;
                ilib_LogEvent.message('disROResults : '+approvalResults);//CMSI-68
                
                // Custom approval flow DCP-40107
                if(boolApprovalFoundDisRO == true || boolApprovalFoundMGRO == true || boolApprovalFoundMNRO == true)
                {
                    //Material Number Custom Approval
                    approvalResults = calculateMatNumCustom(pli,idToProposal,approvalSets,strApprovalCategory,strApprovalStatus,strDistributionChannel,approvalResults);
                    boolApprovalFoundMNCust = approvalResults.boolApprovalFoundMNCust;
                    strApprovalCategory = approvalResults.strApprovalCategory;
                    strApprovalStatus = approvalResults.strApprovalStatus;
                    ilib_LogEvent.message('matNumCustomResults : '+approvalResults);//CMSI-68
                    
                    //Material Group Custom Approval
                    approvalResults = calculateMatGrpCustom(pli,idToProposal,approvalSets,strApprovalCategory,strApprovalStatus,strDistributionChannel,boolApprovalFoundMNCust,approvalResults);
                    boolApprovalFoundMGCust = approvalResults.boolApprovalFoundMGCust;
                    strApprovalCategory = approvalResults.strApprovalCategory;
                    strApprovalStatus = approvalResults.strApprovalStatus;
                    ilib_LogEvent.message('matGrpCustomResults : '+approvalResults);//CMSI-68
                    
                    //Discount Custom Approval
                    approvalResults = calculateDisCustom(pli,idToProposal,approvalSets,strApprovalCategory,strApprovalStatus,strDistributionChannel,boolApprovalFoundMNCust,boolApprovalFoundMGCust,approvalResults);
                    ilib_LogEvent.message('disCustomResults : '+approvalResults);//CMSI-68
                }
                
            }
            
        }
        
        updatePLI(pli,approvalResults);
        ilib_LogEvent.message('pli : '+pli);//CMSI-68
        
        setPLIConditionalFields(pli,objProposal,mapQuoteIdToROHierarchy,mapQuoteIdToUCHierarchy);
    }
    
    /*
* @Roopal
* Update proposal line item fields
*/
    private void updatePLI (Apttus_Proposal__Proposal_Line_Item__c pli,ApprovalsResult approvalResults){
        pli.Approval_Level_Discount__c = approvalResults.intApprovalLevelDiscountCustom;
        pli.Approval_Level_Product__c = approvalResults.intApprovalLevelMaterialNumCustom;
        pli.Approval_Level_Product_Group__c = approvalResults.intApprovalLevelMaterialGroupCustom;
        pli.Approval_Level_Promotion__c = approvalResults.intApprovalLevelPromotion;
        pli.Approval_Level_Promotion_2__c = approvalResults.intApprovalLevelPromotion2;
        pli.Approval_Level_Promotion_3__c = approvalResults.intApprovalLevelPromotion3;
        pli.Approval_Level_Promotion_4__c = approvalResults.intApprovalLevelPromotion4;
        pli.Approval_Level_Promotion_5__c = approvalResults.intApprovalLevelPromotion5;
        pli.Approval_Level_UC_Discount__c = approvalResults.intApprovalLevelUCDiscount;
        pli.Approval_Level_Record_Owner__c = approvalResults.intApprovalLevelDiscount;
        pli.Approval_Hierarchy_Discount__c = approvalResults.idApprovalHierarchyDiscountCustom;
        pli.Approval_Hierarchy_Record_Owner__c = approvalResults.idApprovalHierarchyDiscount;
        pli.Approval_Hierarchy_UC_Discount__c = approvalResults.idApprovalHierarchyUCDiscount;
        pli.Approval_Hierarchy_Product__c = approvalResults.idApprovalHierarchyMaterialNumCustom;
        pli.Approval_Hierarchy_Product_Group__c = approvalResults.idApprovalHierarchyMaterialGroupCustom;
        pli.Approval_Hierarchy_Promotion__c = approvalResults.idApprovalHierarchyPromotion;
        pli.Approval_Hierarchy_Promotion_2__c = approvalResults.idApprovalHierarchyPromotion2;
        pli.Approval_Hierarchy_Promotion_3__c = approvalResults.idApprovalHierarchyPromotion3;
        pli.Approval_Hierarchy_Promotion_4__c = approvalResults.idApprovalHierarchyPromotion4;
        pli.Approval_Hierarchy_Promotion_5__c = approvalResults.idApprovalHierarchyPromotion5;
        pli.Apttus_QPApprov__Approval_Status__c = approvalResults.strApprovalStatus;
        pli.Approval_Category__c = approvalResults.strApprovalCategory;
    }
    
    /*
* @Roopal
* Blank out error fields on quote
*/
    private void blankOutErrorFields (Apttus_Proposal__Proposal__c objProposal,Map<Id, Apttus_Proposal__Proposal__c> idToQuotationForUpdate){
        if(objProposal!=null && String.isNotBlank(objProposal.Sales_Discretionary_Approval_Error__c)){
            objProposal.Sales_Discretionary_Approval_Error__c = null;
            idToQuotationForUpdate.put(objProposal.id, objProposal);
        }
    }
    
    /*
* @Roopal
* Calculate Distribution Channel
*/
    private String calculateDisChannel(Apttus_Proposal__Proposal__c objProposal)
    {
        String strDistributionChannel = System.Label.DistributionChannelDirect;
        if(objProposal.Quote_Type__c!=null && objProposal.Quote_Type__c.startsWith('Indirect')) {
            strDistributionChannel = System.Label.DistributionChannelIndirect;
        }
        ilib_LogEvent.message('strDistributionChannel :'+strDistributionChannel);
        return strDistributionChannel;
    }
    
    /*
* @Roopal
* Set conditional fields on line item 
*/
    private void setPLIConditionalFields(Apttus_Proposal__Proposal_Line_Item__c pli, Apttus_Proposal__Proposal__c objProposal, Map<Id, Id> mapQuoteIdToROHierarchy, Map<Id, Id> mapQuoteIdToUCHierarchy)
    {
        if(pli.Approval_Hierarchy_Record_Owner__c != null) {
            mapQuoteIdToROHierarchy.put(objProposal.id,pli.Approval_Hierarchy_Record_Owner__c);
        }
        if(pli.Approval_Hierarchy_UC_Discount__c != null) {
            mapQuoteIdToUCHierarchy.put(objProposal.id,pli.Approval_Hierarchy_UC_Discount__c);
        }
        if(!(String.isBlank(pli.Line_Description__c))) { pli.Apttus_Proposal__Description__c = pli.Line_Description__c; }
    }
    
    /*
*@ Roopal
*Wrapper Method for storing Approval Sets
*/
    public class ApprovalsResult {
        Id idApprovalHierarchyPromotion;
        Id idApprovalHierarchyPromotion2;
        Id idApprovalHierarchyPromotion3;
        Id idApprovalHierarchyPromotion4;
        Id idApprovalHierarchyPromotion5;
        Integer intApprovalLevelPromotion;
        Integer intApprovalLevelPromotion2; //DCP-25340, Added levels for 5 promotion fields 
        Integer intApprovalLevelPromotion3;
        Integer intApprovalLevelPromotion4;
        Integer intApprovalLevelPromotion5;
        String strApprovalCategory;  
        String strApprovalStatus;  
        Boolean boolApprovalFoundMNRO;
        Integer intApprovalLevelDiscount;
        Id idApprovalHierarchyDiscount;
        Id idApprovalHierarchyUCDiscount;
        Integer intApprovalLevelUCDiscount;
        Boolean boolApprovalFoundMGRO;
        Boolean boolApprovalFoundDisRO;
        Boolean boolApprovalFoundMNCust;
        Integer intApprovalLevelMaterialNumCustom;
        Id idApprovalHierarchyMaterialNumCustom; 
        Boolean boolApprovalFoundMGCust;
        Integer intApprovalLevelMaterialGroupCustom;
        Id idApprovalHierarchyMaterialGroupCustom; 
        Integer intApprovalLevelDiscountCustom;   
        Id idApprovalHierarchyDiscountCustom;
        Id idCalApprovalHierarchy;
        Integer intCalApprovalLevel; 
        
        /*
* Initialize Approval results fields
* @Roopal
*/
        public ApprovalsResult() {
            idApprovalHierarchyPromotion = null;
            idApprovalHierarchyPromotion2 = null;
            idApprovalHierarchyPromotion3 = null;
            idApprovalHierarchyPromotion4 = null;
            idApprovalHierarchyPromotion5 = null;
            intApprovalLevelPromotion = null;
            intApprovalLevelPromotion2 = null; 
            intApprovalLevelPromotion3 = null;
            intApprovalLevelPromotion4 = null;
            intApprovalLevelPromotion5 = null;
            strApprovalCategory = '';  
            strApprovalStatus = '';  
            boolApprovalFoundMNRO = false;
            intApprovalLevelDiscount = null;
            idApprovalHierarchyDiscount= null;
            idApprovalHierarchyUCDiscount = null;
            intApprovalLevelUCDiscount = null;
            boolApprovalFoundMGRO = false;
            boolApprovalFoundDisRO = false;
            boolApprovalFoundMNCust = false;
            intApprovalLevelMaterialNumCustom = null;
            idApprovalHierarchyMaterialNumCustom = null; 
            boolApprovalFoundMGCust = false;
            intApprovalLevelMaterialGroupCustom = null;
            idApprovalHierarchyMaterialGroupCustom = null; 
            intApprovalLevelDiscountCustom = null;   
            idApprovalHierarchyDiscountCustom = null;
            idCalApprovalHierarchy = null;
            intCalApprovalLevel = null; 
        }
    }
    
    /*
* @Roopal
* Calculate Promotions
*/
    private ApprovalsResult calculatePromotionApprovals (Apttus_Proposal__Proposal_Line_Item__c pli,PreparedApprovalSets approvalSets,String strApprovalCategory,ApprovalsResult result)
    {
        String strApprovalStatus = '';
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Map<Id, Apttus_Config2__Incentive__c> mapIdToIncentive = approvalSets.mapIdToIncentive;
        Id idApprovalHierarchyPromotion = null;
        Id idApprovalHierarchyPromotion2 = null;
        Id idApprovalHierarchyPromotion3 = null;
        Id idApprovalHierarchyPromotion4 = null;
        Id idApprovalHierarchyPromotion5 = null;
        Integer intApprovalLevelPromotion = null;
        Integer intApprovalLevelPromotion2 = null; //DCP-25340, Added levels for 5 promotion fields 
        Integer intApprovalLevelPromotion3 = null;
        Integer intApprovalLevelPromotion4 = null;
        Integer intApprovalLevelPromotion5 = null;
        
        
        if(pli.Promotion_1__c != null || pli.Promotion_2__c!= null || pli.Promotion_3__c!= null || pli.Promotion_4__c!= null || pli.Promotion_5__c!= null){
            ApprovalsResult promo1Values = calculatePromotionApproval(pli.Promotion_1__c,customMatrixWrapper,mapIdToIncentive,result);
            idApprovalHierarchyPromotion = promo1Values.idCalApprovalHierarchy;
            intApprovalLevelPromotion = promo1Values.intCalApprovalLevel;
            
            ApprovalsResult promo2Values = calculatePromotionApproval(pli.Promotion_2__c,customMatrixWrapper,mapIdToIncentive,result);
            idApprovalHierarchyPromotion2 = promo2Values.idCalApprovalHierarchy;
            intApprovalLevelPromotion2 = promo2Values.intCalApprovalLevel;
            
            ApprovalsResult promo3Values = calculatePromotionApproval(pli.Promotion_3__c,customMatrixWrapper,mapIdToIncentive,result);
            idApprovalHierarchyPromotion3 = promo3Values.idCalApprovalHierarchy;
            intApprovalLevelPromotion3 = promo3Values.intCalApprovalLevel;
            
            ApprovalsResult promo4Values = calculatePromotionApproval(pli.Promotion_4__c,customMatrixWrapper,mapIdToIncentive,result);
            idApprovalHierarchyPromotion4 = promo4Values.idCalApprovalHierarchy;
            intApprovalLevelPromotion4 = promo4Values.intCalApprovalLevel;
            
            ApprovalsResult promo5Values = calculatePromotionApproval(pli.Promotion_5__c,customMatrixWrapper,mapIdToIncentive,result);
            idApprovalHierarchyPromotion5 = promo5Values.idCalApprovalHierarchy;
            intApprovalLevelPromotion5 = promo5Values.intCalApprovalLevel;
            
            if((intApprovalLevelPromotion!=null && idApprovalHierarchyPromotion!=null) || (intApprovalLevelPromotion2!=null && idApprovalHierarchyPromotion2!=null) || (intApprovalLevelPromotion3!=null && idApprovalHierarchyPromotion3!=null) || (intApprovalLevelPromotion4!=null && idApprovalHierarchyPromotion4!=null) || (intApprovalLevelPromotion5!=null && idApprovalHierarchyPromotion5!=null)) {
                strApprovalCategory += ';' + ApprovalCategory.PROMOTION.name();
            }
            strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
        }
        
        result.idApprovalHierarchyPromotion = idApprovalHierarchyPromotion;
        result.idApprovalHierarchyPromotion2 = idApprovalHierarchyPromotion2;
        result.idApprovalHierarchyPromotion3 = idApprovalHierarchyPromotion3;
        result.idApprovalHierarchyPromotion4 = idApprovalHierarchyPromotion4;
        result.idApprovalHierarchyPromotion5 = idApprovalHierarchyPromotion5;
        result.intApprovalLevelPromotion = intApprovalLevelPromotion;
        result.intApprovalLevelPromotion2 = intApprovalLevelPromotion2; //DCP-25340, Added levels for 5 promotion fields 
        result.intApprovalLevelPromotion3 = intApprovalLevelPromotion3;
        result.intApprovalLevelPromotion4 = intApprovalLevelPromotion4;
        result.intApprovalLevelPromotion5 = intApprovalLevelPromotion5;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculatePromotionApprovals :'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Promotion Approval
*/
    private ApprovalsResult calculatePromotionApproval(Id promotion, CustomApprovalMatrixWrapper customMatrixWrapper, Map<Id, Apttus_Config2__Incentive__c> mapIdToIncentive, ApprovalsResult result)
    {
        Id idCalApprovalHierarchy = null;
        Integer intCalApprovalLevel = null;
        if(promotion != null){
            CustomPromotionWrapper objCustomPromotionWrapper = findLevelAndHierarchyForPromotion(customMatrixWrapper,promotion,mapIdToIncentive);
            idCalApprovalHierarchy = objCustomPromotionWrapper.idApprovalHierarchyPromotion;
            intCalApprovalLevel = objCustomPromotionWrapper.intApprovalLevelPromotion;
        }
        result.idCalApprovalHierarchy = idCalApprovalHierarchy;
        result.intCalApprovalLevel = intCalApprovalLevel;
        //CMSI-68
        ilib_LogEvent.message('result of calculatePromotionApproval:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Material Number Record owner
*/
    private ApprovalsResult calculateMaterialNumberRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, ApprovalsResult result)
    {
        Boolean boolApprovalFoundMNRO = false;
        Integer intApprovalLevelDiscount = null;
        Id idApprovalHierarchyDiscount = null;
        Id idApprovalHierarchyUCDiscount = null;
        Integer intApprovalLevelUCDiscount = null;
        Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct = approvalSets.mapCAMIdToSetProduct;
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        
        if ((pli.Apttus_QPConfig__LineType__c == PRODUCT_TYPE_PRODCUT_SERVICE && pli.Apttus_QPConfig__IsPrimaryLine__c == true) || pli.Apttus_QPConfig__LineType__c == 'Option'){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixMaterialNumberRO;
            String strApprovalType = APPROVAL_TYPE_MATNUM;
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,mapCAMIdToSetProduct,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            ilib_LogEvent.message('objApprovalMatrix :'+objApprovalMatrix);//CMSI-68
            Id idHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
            ilib_LogEvent.message('idHierarchy :'+idHierarchy);//CMSI-68
            
            if(idHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                result = calculateMatNumHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
                strApprovalCategory = result.strApprovalCategory;
                boolApprovalFoundMNRO = result.boolApprovalFoundMNRO;
            }
            boolApprovalFoundMNRO = matrixErrorIfCondition(objProposal,objApprovalMatrix,boolApprovalFoundMNRO);
            ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError + setQuotationIdsWithMatrixError :'+quoteIdToSetOfOwnerIdsForError+'_'+setQuotationIdsWithMatrixError);//CMSI-68
            if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelDiscount = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.CPQ_MATERIAL_NUMBER.name() + ';';
                boolApprovalFoundMNRO = true;
            }
            else if(objApprovalMatrix.booldiscountlessthanLevel1)
            {
                if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                    setQuotationIdsWithMatrixError.remove(objProposal.id);
                }
                boolApprovalFoundMNRO = false;
            }            
            //if direct deal and trans border flag is set then use the UC approval
            if(objProposal.Apttus_Proposal__Opportunity__r.Transborder_Flag__c==true || objProposal.Indirect_Transregion_Flag__c==true){
                result = calculateTransMatNumRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel,idApprovalHierarchyDiscount,lstApprovalMatrix,result);
                boolApprovalFoundMNRO = result.boolApprovalFoundMNRO;
                idApprovalHierarchyUCDiscount = result.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = result.intApprovalLevelUCDiscount;
                strApprovalCategory = result.strApprovalCategory;
                strApprovalStatus = result.strApprovalStatus;
            }
            ilib_LogEvent.message('ROBooleanMaterialNumber :'+boolApprovalFoundMNRO);//CMSI-68
        }
        
        result.boolApprovalFoundMNRO = boolApprovalFoundMNRO;
        result.intApprovalLevelDiscount =intApprovalLevelDiscount;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateMaterialNumberRO:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Material material Approval hierarchy error
*/
    private ApprovalsResult calculateMatNumHyrError(Apttus_Proposal__Proposal__c objProposal, CustomApprovalMatrixResult objApprovalMatrix, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, ApprovalsResult result)
    {
        boolean boolApprovalFoundMNRO = false;
        if(quoteIdToSetOfOwnerIdsForError.containsKey(objProposal.id)) { quoteIdToSetOfOwnerIdsForError.get(objProposal.id).add(objApprovalMatrix.idOwner); }
        else { quoteIdToSetOfOwnerIdsForError.put(objProposal.id, new Set<Id>{objApprovalMatrix.idOwner}); }
        if(objApprovalMatrix.soApprovalMatrix != null){
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_MATERIAL_NUMBER.name())) { strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_NUMBER.name() + ';'; }
            boolApprovalFoundMNRO = true;
            result.strApprovalCategory = strApprovalCategory;  
            result.boolApprovalFoundMNRO = boolApprovalFoundMNRO;
        }
        //CMSI-68
        ilib_LogEvent.info('result of calculateMatNumHyrError:'+result);
        ilib_LogEvent.pop();  
        return result;
    }
    
    /*
* @Roopal
* Calculate Material Number Record owner
*/
    private ApprovalsResult calculateTransMatNumRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, Id idApprovalHierarchyDiscount, List<Custom_Approval_Matrix__c> lstApprovalMatrix, ApprovalsResult result)
    {
        Boolean boolApprovalFoundMNRO = false;
        Id idApprovalHierarchyUCDiscount = null;
        Integer intApprovalLevelUCDiscount = null;
        
        Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct = approvalSets.mapCAMIdToSetProduct;
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        String strApprovalType = APPROVAL_TYPE_MATNUM;
        
        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel, mapCAMIdToSetProduct,strApprovalType, lstApprovalMatrix, true,mapIdToProduct);
        ilib_LogEvent.message('objApprovalMatrixTrans :'+objApprovalMatrix);//CMSI-68
        Id idUCHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
        ilib_LogEvent.message('idUCHierarchyTrans :'+idUCHierarchy);//CMSI-68
        if(idUCHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            result = calculateMatNumHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
            strApprovalCategory = result.strApprovalCategory;
            boolApprovalFoundMNRO = result.boolApprovalFoundMNRO;
        }
        if(objApprovalMatrix.soApprovalMatrix == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            boolApprovalFoundMNRO = false;
            setQuotationIdsWithMatrixError.add(objProposal.Id);
        }
        ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError+setQuotationIdsWithMatrixError :'+quoteIdToSetOfOwnerIdsForError+'_'+setQuotationIdsWithMatrixError);//CMSI-68
        if(idUCHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null && idApprovalHierarchyDiscount!=null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            idApprovalHierarchyUCDiscount = idUCHierarchy;
            intApprovalLevelUCDiscount = objApprovalMatrix.intApprovalLevel;
            strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_MATERIAL_NUMBER.name())) { strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_NUMBER.name() + ';'; }
            boolApprovalFoundMNRO = true;
        }
        else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                setQuotationIdsWithMatrixError.remove(objProposal.id);
            }
            boolApprovalFoundMNRO = false;
        }
        result.boolApprovalFoundMNRO = boolApprovalFoundMNRO;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateTransMatNumRO :'+result);
        return result;
    }
    
    
    /*
* @Roopal
* Calculate Material Group Record owner
*/
    private ApprovalsResult calculateMaterialGroupRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, Boolean boolApprovalFoundMNRO, Integer intApprovalLevelDiscount, Id idApprovalHierarchyDiscount, Id idApprovalHierarchyUCDiscount, Integer intApprovalLevelUCDiscount, ApprovalsResult result)
    {
        Boolean boolApprovalFoundMGRO = false;
        Id idProduct = (pli.Apttus_QPConfig__OptionId__c == null) ? pli.Apttus_Proposal__Product__c : pli.Apttus_QPConfig__OptionId__c;
        
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        
        if(boolApprovalFoundMNRO == false && mapIdToProduct.get(idProduct).Material_Group_1_Code__c != null){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = new List<Custom_Approval_Matrix__c>();
            Set<Custom_Approval_Matrix__c> setApprovalMatrix = customMatrixWrapper.mapMatrixtoMaterialGroupRO.keyset();
            lstApprovalMatrix.addAll(setApprovalMatrix);
            String strApprovalType = APPROVAL_TYPE_MATGRP;
            
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,customMatrixWrapper.mapMatrixtoMaterialGroupRO,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            Id idHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
            ilib_LogEvent.message('idHierarchy :'+idHierarchy);//CMSI-68
            
            if(idHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                result = calculateMatGrpHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
                strApprovalCategory = result.strApprovalCategory;
                boolApprovalFoundMGRO = result.boolApprovalFoundMGRO;
                if(objApprovalMatrix.soApprovalMatrix != null){
                    calculateMatGrpRemoveError(objProposal);
                }
            }
            boolApprovalFoundMGRO = matrixErrorIfCondition(objProposal,objApprovalMatrix,boolApprovalFoundMGRO);
            ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError+setQuotationIdsWithMatrixError :'+quoteIdToSetOfOwnerIdsForError+'_'+setQuotationIdsWithMatrixError);//CMSI-68
            if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelDiscount = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.CPQ_MATERIAL_GROUP_1.name() + ';';
                boolApprovalFoundMGRO = true;
                calculateMatGrpRemoveError(objProposal);
            }
            boolApprovalFoundMGRO = calculateMatGrpLessThan1(objProposal,objApprovalMatrix,boolApprovalFoundMGRO);
            ilib_LogEvent.message('boolApprovalFoundMGRO :'+boolApprovalFoundMGRO);//CMSI-68
            ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError :'+quoteIdToSetOfOwnerIdsForError);//CMSI-68
            
            //if direct deal and trans border flag is set then use the UC approval
            if(objProposal.Apttus_Proposal__Opportunity__r.Transborder_Flag__c==true || objProposal.Indirect_Transregion_Flag__c==true){
                result = calculateTransMatGroupRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel,idApprovalHierarchyDiscount,lstApprovalMatrix,result);
                boolApprovalFoundMGRO = result.boolApprovalFoundMGRO;
                idApprovalHierarchyUCDiscount = result.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = result.intApprovalLevelUCDiscount;
                strApprovalCategory = result.strApprovalCategory;
                strApprovalStatus = result.strApprovalStatus;
            }
        }
        
        result.boolApprovalFoundMGRO = boolApprovalFoundMGRO;
        result.intApprovalLevelDiscount =intApprovalLevelDiscount;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateMaterialGroupRO:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Material group Approval hierarchy error
*/
    private ApprovalsResult calculateMatGrpHyrError(Apttus_Proposal__Proposal__c objProposal, CustomApprovalMatrixResult objApprovalMatrix, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, ApprovalsResult result)
    {
        boolean boolApprovalFoundMGRO = false;
        if(quoteIdToSetOfOwnerIdsForError.containsKey(objProposal.id)){
            quoteIdToSetOfOwnerIdsForError.get(objProposal.id).add(objApprovalMatrix.idOwner);
        }  
        else { quoteIdToSetOfOwnerIdsForError.put(objProposal.id, new Set<Id>{objApprovalMatrix.idOwner}); }
        if(objApprovalMatrix.soApprovalMatrix != null){
            calculateMatGrpRemoveError(objProposal);
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_MATERIAL_GROUP_1.name())) { strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_GROUP_1.name() + ';'; }
            boolApprovalFoundMGRO = true;
            result.strApprovalCategory = strApprovalCategory;  
            result.boolApprovalFoundMGRO = boolApprovalFoundMGRO;
        }
        //CMSI-68
        ilib_LogEvent.message('result of calculateMatGrpHyrError:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Material group remove error
*/
    private void calculateMatGrpRemoveError (Apttus_Proposal__Proposal__c objProposal){
        if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
            setQuotationIdsWithMatrixError.remove(objProposal.id);
        }
    }
    
    /*
* @Roopal
* Calculate Material group less than level 1
*/
    private boolean calculateMatGrpLessThan1 (Apttus_Proposal__Proposal__c objProposal,CustomApprovalMatrixResult objApprovalMatrix,Boolean boolApprovalFoundMGRO)
    {
        if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            boolApprovalFoundMGRO = false;
            calculateMatGrpRemoveError(objProposal);
        }
        //CMSI-68
        ilib_LogEvent.message('boolApprovalFoundMGRO :'+boolApprovalFoundMGRO);
        return boolApprovalFoundMGRO;
    }
    
    /*
* @Roopal
* Calculate Material Group Record owner
*/
    private ApprovalsResult calculateTransMatGroupRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, Id idApprovalHierarchyDiscount, List<Custom_Approval_Matrix__c> lstApprovalMatrix, ApprovalsResult result)
    {
        Boolean boolApprovalFoundMGRO = false;
        Id idApprovalHierarchyUCDiscount = null;
        Integer intApprovalLevelUCDiscount = null;
        
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        String strApprovalType = APPROVAL_TYPE_MATGRP;
        
        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel, customMatrixWrapper.mapMatrixtoMaterialGroupRO,strApprovalType, lstApprovalMatrix, true,mapIdToProduct);
        ilib_LogEvent.message('objApprovalMatrixTrans :'+objApprovalMatrix);//CMSI-68
        Id idUCHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
        ilib_LogEvent.message('idUCHierarchyTrans :'+idUCHierarchy);//CMSI-68
        
        if(idUCHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            result = calculateMatGrpHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
            strApprovalCategory = result.strApprovalCategory;
            boolApprovalFoundMGRO = result.boolApprovalFoundMGRO;
        }
        if(objApprovalMatrix.soApprovalMatrix == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            boolApprovalFoundMGRO = false;
            setQuotationIdsWithMatrixError.add(objProposal.Id);
        }
        ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError + setQuotationIdsWithMatrixError :'+quoteIdToSetOfOwnerIdsForError+'_'+setQuotationIdsWithMatrixError);//CMSI-68
        if(idUCHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null && idApprovalHierarchyDiscount!=null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            idApprovalHierarchyUCDiscount = idUCHierarchy;
            intApprovalLevelUCDiscount = objApprovalMatrix.intApprovalLevel;
            strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_MATERIAL_GROUP_1.name()))  { strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_GROUP_1.name() + ';'; }
            boolApprovalFoundMGRO = true;
        }
        else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                setQuotationIdsWithMatrixError.remove(objProposal.id);
            }
            boolApprovalFoundMGRO = false;
        }
        result.boolApprovalFoundMGRO = boolApprovalFoundMGRO;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateTransMatGroupRO:'+result);
        return result;
    }
    
    
    /*
* @Roopal
* Calculate Discount Record owner
*/
    private ApprovalsResult calculateDiscountRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, Boolean boolApprovalFoundMNRO, Boolean boolApprovalFoundMGRO, Integer intApprovalLevelDiscount, Id idApprovalHierarchyDiscount, Id idApprovalHierarchyUCDiscount, Integer intApprovalLevelUCDiscount, ApprovalsResult result)
    {
        Boolean boolApprovalFoundDisRO = false;
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        
        if (boolApprovalFoundMGRO == false && boolApprovalFoundMNRO == false){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixDiscountRO;
            String strApprovalType = APPROVAL_TYPE_DISCOUNT;
            
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,null,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            ilib_LogEvent.message('objApprovalMatrix :'+objApprovalMatrix);//CMSI-68
            Id idHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
            ilib_LogEvent.message('idHierarchy :'+idHierarchy);//CMSI-68
            
            if(idHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                result = calculateDiscountROHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
                strApprovalCategory = result.strApprovalCategory;
                boolApprovalFoundDisRO = result.boolApprovalFoundDisRO;
                if(objApprovalMatrix.soApprovalMatrix != null){
                    calculateMatGrpRemoveError(objProposal);
                }
            }
            boolApprovalFoundDisRO = matrixErrorIfCondition(objProposal,objApprovalMatrix,boolApprovalFoundDisRO); 
            if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null  && objApprovalMatrix.booldiscountlessthanLevel1 == false){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelDiscount = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.CPQ_DISCOUNT.name() + ';';
                boolApprovalFoundDisRO = true;
                if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                    setQuotationIdsWithMatrixError.remove(objProposal.id);
                }
            }
            else if(objApprovalMatrix.booldiscountlessthanLevel1)
            {
                if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                    setQuotationIdsWithMatrixError.remove(objProposal.id);
                }
                boolApprovalFoundMGRO = false;
            }
            ilib_LogEvent.message('boolApprovalFoundDisRO :'+boolApprovalFoundDisRO);//CMSI-68
            ilib_LogEvent.message('quoteIdToSetOfOwnerIdsForError+setQuotationIdsWithMatrixError :'+quoteIdToSetOfOwnerIdsForError+'_'+setQuotationIdsWithMatrixError);//CMSI-68            
            //if direct deal and trans border flag is set then use the UC approval
            if(objProposal.Apttus_Proposal__Opportunity__r.Transborder_Flag__c==true || objProposal.Indirect_Transregion_Flag__c==true){
                result = calculateTransDiscountRO(pli,idToProposal,approvalSets,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,strApprovalStatus,strDistributionChannel,idApprovalHierarchyDiscount,lstApprovalMatrix,result);
                boolApprovalFoundDisRO = result.boolApprovalFoundDisRO;
                idApprovalHierarchyUCDiscount = result.idApprovalHierarchyUCDiscount;
                intApprovalLevelUCDiscount = result.intApprovalLevelUCDiscount;
                strApprovalCategory = result.strApprovalCategory;
                strApprovalStatus = result.strApprovalStatus;
            }
        }
        result.boolApprovalFoundDisRO = boolApprovalFoundDisRO;
        result.intApprovalLevelDiscount =intApprovalLevelDiscount;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateDiscountRO:'+result);
        return result;
    }
    
    /*
* @Roopal
* If condition for matrix error
*/
    private Boolean matrixErrorIfCondition (Apttus_Proposal__Proposal__c objProposal,CustomApprovalMatrixResult objApprovalMatrix,Boolean boolApprovalFound){
        if(objApprovalMatrix.soApprovalMatrix == null && objApprovalMatrix.booldiscountlessthanLevel1 == false){
            boolApprovalFound = false;
            setQuotationIdsWithMatrixError.add(objProposal.Id);
        }
        //CMSI-68
        ilib_LogEvent.message('boolApprovalFound :'+boolApprovalFound);
        return boolApprovalFound;
    }
    
    /*
* @Roopal
* Calculate Discount Approval hierarchy error
*/
    private ApprovalsResult calculateDiscountROHyrError(Apttus_Proposal__Proposal__c objProposal, CustomApprovalMatrixResult objApprovalMatrix, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, ApprovalsResult result)
    {
        boolean boolApprovalFoundDisRO = false;
        if(quoteIdToSetOfOwnerIdsForError.containsKey(objProposal.id)){
            quoteIdToSetOfOwnerIdsForError.get(objProposal.id).add(objApprovalMatrix.idOwner);
        }  
        else { quoteIdToSetOfOwnerIdsForError.put(objProposal.id, new Set<Id>{objApprovalMatrix.idOwner}); }
        if(objApprovalMatrix.soApprovalMatrix != null){
            calculateMatGrpRemoveError(objProposal);
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_DISCOUNT.name())) { strApprovalCategory += ApprovalCategory.CPQ_DISCOUNT.name() + ';' ; }
            boolApprovalFoundDisRO = true;
            result.strApprovalCategory = strApprovalCategory;  
            result.boolApprovalFoundDisRO = boolApprovalFoundDisRO;
        }
        //CMSI-68
        ilib_LogEvent.message('result of calculateDiscountROHyrError:'+result);
        return result;
    }
    
    
    /*
* @Roopal
* Calculate Discount Transborder Record owner
*/
    private ApprovalsResult calculateTransDiscountRO(Apttus_Proposal__Proposal_Line_Item__c pli, Map<id,Apttus_Proposal__Proposal__c> idToProposal, PreparedApprovalSets approvalSets, Map<Id, Set<Id>> quoteIdToSetOfOwnerIdsForError, String strApprovalCategory, String strApprovalStatus, String strDistributionChannel, Id idApprovalHierarchyDiscount, List<Custom_Approval_Matrix__c> lstApprovalMatrix, ApprovalsResult result)
    {
        Id idApprovalHierarchyUCDiscount = null;
        Integer intApprovalLevelUCDiscount = null;
        Boolean boolApprovalFoundDisRO = false;
        
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = approvalSets.ownerToApporovalHierarchy;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        String strApprovalType = APPROVAL_TYPE_DISCOUNT;
        
        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel, null,strApprovalType, lstApprovalMatrix, true,mapIdToProduct);
        ilib_LogEvent.message('objApprovalMatrixTrans :'+objApprovalMatrix);//CMSI-68
        Id idUCHierarchy = (ownerToApporovalHierarchy.containsKey(objApprovalMatrix.idOwner) ? ownerToApporovalHierarchy.get(objApprovalMatrix.idOwner).id : null);
        ilib_LogEvent.message('idUCHierarchyTrans :'+idUCHierarchy);//CMSI-68
        if(idUCHierarchy == null && objApprovalMatrix.booldiscountlessthanLevel1 ==false){
            result = calculateDiscountROHyrError(objProposal,objApprovalMatrix,quoteIdToSetOfOwnerIdsForError,strApprovalCategory,result);
            strApprovalCategory = result.strApprovalCategory;
            boolApprovalFoundDisRO = result.boolApprovalFoundDisRO;
            
        }
        if(objApprovalMatrix.soApprovalMatrix == null && objApprovalMatrix.booldiscountlessthanLevel1 ==false){
            boolApprovalFoundDisRO = false;
            setQuotationIdsWithMatrixError.add(objProposal.Id);
        }
        if(idUCHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null && idApprovalHierarchyDiscount!=null  && objApprovalMatrix.booldiscountlessthanLevel1 ==false){
            idApprovalHierarchyUCDiscount = idUCHierarchy;
            intApprovalLevelUCDiscount = objApprovalMatrix.intApprovalLevel;
            strApprovalStatus = System.Label.ProposalApprovalStatusApprovalRequired;
            if(!strApprovalCategory.contains(ApprovalCategory.CPQ_DISCOUNT.name())) { strApprovalCategory += ApprovalCategory.CPQ_DISCOUNT.name() + ';'; }
            boolApprovalFoundDisRO = true;
        }
        else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            if(setQuotationIdsWithMatrixError.contains(objProposal.id)) {
                setQuotationIdsWithMatrixError.remove(objProposal.id);
            }
            boolApprovalFoundDisRO = false;
        }
        result.boolApprovalFoundDisRO = boolApprovalFoundDisRO;
        result.idApprovalHierarchyUCDiscount = idApprovalHierarchyUCDiscount;
        result.intApprovalLevelUCDiscount = intApprovalLevelUCDiscount;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateTransDiscountRO:'+result);
        return result;
    }
    
    
    /*
* @Roopal
* Calculate Material Number Custom Approval
*/
    private ApprovalsResult calculateMatNumCustom (Apttus_Proposal__Proposal_Line_Item__c pli,Map<id,Apttus_Proposal__Proposal__c> idToProposal,PreparedApprovalSets approvalSets,String strApprovalCategory, String strApprovalStatus,String strDistributionChannel,ApprovalsResult result)
    {
        Boolean boolApprovalFoundMNCust = false;
        Integer intApprovalLevelMaterialNumCustom = null;
        Id idApprovalHierarchyMaterialNumCustom = null;
        
        Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct = approvalSets.mapCAMIdToSetProduct;
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        
        if ((pli.Apttus_QPConfig__LineType__c == PRODUCT_TYPE_PRODCUT_SERVICE && pli.Apttus_QPConfig__IsPrimaryLine__c == true) || pli.Apttus_QPConfig__LineType__c == 'Option'){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixMaterialNumberCustom;
            String strApprovalType = APPROVAL_TYPE_MATNUM;
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,mapCAMIdToSetProduct,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            ilib_LogEvent.message('objApprovalMatrix for Discount,value 1: '+objApprovalMatrix);//CMSI-68
            intApprovalLevelMaterialNumCustom = objApprovalMatrix.intApprovalLevel;
            idApprovalHierarchyMaterialNumCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);
            if(idApprovalHierarchyMaterialNumCustom!=null && intApprovalLevelMaterialNumCustom!=null){
                strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_NUMBER_CUSTOM.name() + ';';
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                boolApprovalFoundMNCust = true;
            }
            ilib_LogEvent.message('boolApprovalFoundMNCust : '+boolApprovalFoundMNCust);//CMSI-68
        }
        result.boolApprovalFoundMNCust = boolApprovalFoundMNCust;
        result.intApprovalLevelMaterialNumCustom =intApprovalLevelMaterialNumCustom;
        result.idApprovalHierarchyMaterialNumCustom = idApprovalHierarchyMaterialNumCustom;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateMatNumCustom:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Material Group Custom Approval
*/
    private ApprovalsResult calculateMatGrpCustom (Apttus_Proposal__Proposal_Line_Item__c pli,Map<id,Apttus_Proposal__Proposal__c> idToProposal,PreparedApprovalSets approvalSets,String strApprovalCategory, String strApprovalStatus,String strDistributionChannel,Boolean boolApprovalFoundMNCust,ApprovalsResult result)
    {
        Boolean boolApprovalFoundMGCust = false;
        Integer intApprovalLevelMaterialGroupCustom = null;
        Id idApprovalHierarchyMaterialGroupCustom = null;
        
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);
        Id idProduct = (pli.Apttus_QPConfig__OptionId__c == null) ? pli.Apttus_Proposal__Product__c : pli.Apttus_QPConfig__OptionId__c;
        
        if(boolApprovalFoundMNCust == false && mapIdToProduct.get(idProduct).Material_Group_1_Code__c != null){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = new List<Custom_Approval_Matrix__c>();
            Set<Custom_Approval_Matrix__c> setApprovalMatrix = customMatrixWrapper.mapMatrixtoMaterialGroupCustom.keyset();
            lstApprovalMatrix.addAll(setApprovalMatrix);
            String strApprovalType = APPROVAL_TYPE_MATGRP;
            
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,customMatrixWrapper.mapMatrixtoMaterialGroupCustom,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            ilib_LogEvent.message('objApprovalMatrix for Material group custom :'+objApprovalMatrix);//CMSI-68
            
            intApprovalLevelMaterialGroupCustom =   objApprovalMatrix.intApprovalLevel;
            idApprovalHierarchyMaterialGroupCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);
            if(intApprovalLevelMaterialGroupCustom!=null && idApprovalHierarchyMaterialGroupCustom!=null){
                strApprovalCategory += ApprovalCategory.CPQ_MATERIAL_GROUP_CUSTOM.name() + ';';
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                boolApprovalFoundMGCust = true;
            }
            ilib_LogEvent.message('boolApprovalFoundMGCust :'+boolApprovalFoundMGCust);//CMSI-68
        }
        result.boolApprovalFoundMGCust = boolApprovalFoundMGCust;
        result.intApprovalLevelMaterialGroupCustom =intApprovalLevelMaterialGroupCustom;
        result.idApprovalHierarchyMaterialGroupCustom = idApprovalHierarchyMaterialGroupCustom;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateMatGrpCustom:'+result);
        return result;
    }
    
    /*
* @Roopal
* Calculate Discount Custom Approval
*/
    private ApprovalsResult calculateDisCustom (Apttus_Proposal__Proposal_Line_Item__c pli,Map<id,Apttus_Proposal__Proposal__c> idToProposal,PreparedApprovalSets approvalSets,String strApprovalCategory, String strApprovalStatus,String strDistributionChannel,Boolean boolApprovalFoundMNCust,Boolean boolApprovalFoundMGCust,ApprovalsResult result)
    {
        Integer intApprovalLevelDiscountCustom = null;
        Id idApprovalHierarchyDiscountCustom = null;
        
        Map<Id, Product2> mapIdToProduct = approvalSets.mapIdToProduct;
        CustomApprovalMatrixWrapper customMatrixWrapper = approvalSets.customMatrixWrapper;
        Apttus_Proposal__Proposal__c objProposal = idToProposal.get(pli.Apttus_Proposal__Proposal__c);        
        
        if (boolApprovalFoundMNCust == false && boolApprovalFoundMGCust == false){
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixDiscountCustom;
            String strApprovalType = APPROVAL_TYPE_DISCOUNT;
            
            CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(objProposal, pli, strDistributionChannel,null,strApprovalType,lstApprovalMatrix,mapIdToProduct);
            
            intApprovalLevelDiscountCustom =   objApprovalMatrix.intApprovalLevel;
            idApprovalHierarchyDiscountCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);
            if(intApprovalLevelDiscountCustom!=null && idApprovalHierarchyDiscountCustom!=null){
                strApprovalCategory += ApprovalCategory.CPQ_DISCOUNT_CUSTOM.name() + ';';
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
            }
        }
        result.intApprovalLevelDiscountCustom =intApprovalLevelDiscountCustom;
        result.idApprovalHierarchyDiscountCustom = idApprovalHierarchyDiscountCustom;
        result.strApprovalCategory = strApprovalCategory;  
        result.strApprovalStatus = strApprovalStatus;
        //CMSI-68
        ilib_LogEvent.message('result of calculateDisCustom:'+result);
        return result;
    }
    
    /*
* @Prabhsimran
* Initializing approval priority metadata map
*/    
    private void initializeApprovalPriorityMetadata()
    {
        ilib_LogEvent.push(LOG_TITLE + '.initializeApprovalPriorityMetadata()');//CMSI-68
        if(mapApprovalPriorityMetadata.isEmpty()){
            List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations = new ApprovalPriorityMetadataSelector().selectAllPriorityCombinations();
            ilib_LogEvent.info('lstPriorityCOmbinations :'+lstPriorityCOmbinations);//CMSI-68
            for(Approval_Priority_Combination__mdt objpriority :lstPriorityCOmbinations){
                String strMetaCond = objpriority.Price_List_Type_Check__c+'_'+objpriority.Region_Check__c+'_'+objpriority.Country_Check__c+'_'+objpriority.Distribution_Channel_Check__c+'_'+objpriority.Currency_Check__c+'_'+objpriority.Price_List_Type_Blank__c+'_'+objpriority.Region_Blank__c+'_'+objpriority.Distribution_Channel_Blank__c+'_'+objpriority.Country_Blank__c+'_'+objpriority.Currency_Blank__c;
                //String strMetaCond = objpriority.Region_Check__c+'_'+objpriority.Country_Check__c+'_'+objpriority.Distribution_Channel_Check__c+'_'+objpriority.Currency_Check__c+'_'+objpriority.Region_Blank__c+'_'+objpriority.Distribution_Channel_Blank__c+'_'+objpriority.Country_Blank__c+'_'+objpriority.Currency_Blank__c;
                ilib_LogEvent.message('strMetaCond :'+strMetaCond);//CMSI-68   
                mapApprovalPriorityMetadata.put(strMetaCond,Integer.valueOf(objpriority.Value__c));   
            }
        }
        ilib_LogEvent.pop();  //CMSI-68
    }
    /*
* @Himanshu
* Calculte totalamountpriortodicountUSD
*/ 
    private void totalamountpriortodicountUSD(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems,Decimal conversionValue){
        ilib_LogEvent.push(LOG_TITLE + '.totalamountpriortodicountUSD()');//CMSI-68
        for(Apttus_Proposal__Proposal_Line_Item__c objlineItem:lstProposalLineItems)
        {
            objlineItem.Total_Amount_Prior_To_Discount_in_USD__c = objlineItem.Total_Amount_Prior_To_Discount__c/conversionValue;
        }
        ilib_LogEvent.pop(); //CMSI-68
        
    }
    
    /* Created By : Akshay Hedaoo
     * Description : CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
     * @Parameter lstProposalLineItems
     * @return null
     */     
    public static void updateHideContractDates(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems){
        Set<Id> priceListIds = new Set<Id>();
        for(Apttus_Proposal__Proposal_Line_Item__c lineItem : lstProposalLineItems){
        priceListIds.add(lineItem.Apttus_QPConfig__PriceListItemId__c);
        }
        Map<Id , Apttus_Config2__PriceListItem__c> priceListMap = new Map<Id , Apttus_Config2__PriceListItem__c>(new PriceListItemsSelector().fetchPriceTypeFromPriceListItem(priceListIds));
        for(Apttus_Proposal__Proposal_Line_Item__c lineItem : lstProposalLineItems){
        if(lineItem.Apttus_QPConfig__PriceListItemId__c != null && priceListMap.get(lineItem.Apttus_QPConfig__PriceListItemId__c) != NULL && priceListMap.get(lineItem.Apttus_QPConfig__PriceListItemId__c).Apttus_Config2__PriceType__c == System.Label.PriceListItemPriceTypeOneTime){           
           lineItem.Hide_Contract_Dates__c = true;                
          } 
        }
    }

    /*
    @Author : Sai Pasumarthy
    @Story : CMCM-11325
    @Description : TI- Quotation Line Item:Check for Product Specific Terms And Material Class
    @Paramters : List of Line Item
    */   
    @testVisible
    private static void checkProductSpecificTermsAndMaterialClass(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<Id, Product2> mapIdToProduct){
        
        ilib_LogEvent.push(LOG_TITLE + '.checkProductSpecificTermsAndMaterialClass()');
        if (Feature.isOn('WF_FF_Check_Product_Specific_Terms')) {
           
            for(Apttus_Proposal__Proposal_Line_Item__c lineItem : lstProposalLineItems){

                lineItem.Template_China_Prod1__c = lineItem.Template_Material_Number__c == Label.ProductChina1 ? 1 : 0;
                lineItem.Template_China_Prod2__c = lineItem.Template_Material_Number__c == Label.ProductChina2 ? 1 : 0;
                lineItem.Template_China_Prod3__c = lineItem.Template_Material_Number__c == Label.ProductChina3 ? 1 : 0;
                lineItem.Template_China_Prod4__c = lineItem.Template_Material_Number__c == Label.ProductChina4 ? 1 : 0;
                lineItem.Template_China_Prod5__c = lineItem.Template_Material_Number__c == Label.ProductChina5 ? 1 : 0;
                lineItem.Template_China_Prod6__c = lineItem.Template_Material_Number__c == Label.ProductChina6 ? 1 : 0;
                
                Product2 product = mapIdToProduct.get(lineItem.Apttus_Proposal__Product__c);

                lineItem.Template_Material_Class_Flag__c = product?.Material_Class__c == System.Label.InstalledProductMaterialClassInstrument ? 1 : 0;

                if( lineItem.Promotion_1__c == null && lineItem.Promotion_2__c == null && lineItem.Promotion_3__c == null && lineItem.Promotion_4__c == null && lineItem.Promotion_5__c == null ){
                    lineItem.Template_Promotions__c = 0;
                } else { 
                    lineItem.Template_Promotions__c = 1;
                }
                
                lineItem.Template_Applied_Disc_Details__c = lineItem.Applied_Discount_Details__c == System.Label.QLIAppliedDiscDetailFixedPrice ? 1 : 0;
                
                if( product?.Material_Type__c == System.Label.Material_Type_Infinium && 
                    product?.Material_Class_Type__c == System.Label.Material_Class_Type_Infinium &&
                    product?.Product_Level_Indicator__c == System.Label.Product_Level_Indicator
                    ){
                    lineItem.Template_Infinium_Product__c = 1;
                }
                else {
                    lineItem.Template_Infinium_Product__c = 0;
                }
            }
        }
        ilib_LogEvent.pop();
    }

}
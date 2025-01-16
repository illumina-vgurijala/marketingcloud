/* @ author       : Indra Ganesan
* @ date         : 05-18-2018
* @ Description  : OpportunityLineItem Trigger helper class contains all Business logic implementation
* Test Class for 75% Coverage : TestApttusAddProduct, TestBatchToPopulateAppliedDisPer, TestCreateQuoteAutomation, TestOpportunityLineItems, TestUpdatePricingOLIController, TestUpdateProductPricingController
* Test Class for 90% Coverage : TestApttusAddProduct, TestBatchToPopulateAppliedDisPer, TestCreateQuoteAutomation, TestOpportunityLineItems, TestUpdatePricingOLIController, TestUpdateProductPricingController
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Indra Ganesan        05-18-2018                  DCP-598             Initial version
* Indra Ganesan        06-14-2018                  DCP-2987            Modified as per Todd's comments
* Govind Dubey         26-06-2018                  DCP-2433            Modified for deletion of Product scenario, added initializeVariable() and onAfterDelete()
* Indra Ganesan        10-07-2018                  DCP-2919            Modified to Add Are Products Added
* Govind Dubey         13-07-2018                  DCP-607             Added updateReordFSOpportunityRecordTypeToStandard method
* Akash Kumar          08-06-2018                  DCP-7708            Added Method to Prevent delete of Opportunity Products on Creation of Quote
* Indra Ganesan        09-06-2018                  DCP-9720            Modified OnAfterDelete
* Sandeep R            10-29-2018                  DCP-706             Added logic to maintain comma seperated string of product Lines on Opportunity from opportunity line items.
* Rahul Sharma         02-01-2019                  DCP-22903           Removed logic for auto switch record type for field services
* Arnab Modak          28-08-2019                  DCP-28663           Not syncing Fixed Bundle SKU to the Opportunity from Quote
* Rahul Bishnoi         12-05-2019				   DCP-30367           if a line item is informatics product, then set Informatics_Opportunity__c to true.
* Saurav Bhandari      08-11-2019                  DCP-28965           Added logic of checking Is_Customer_Readiness_Form_Required__c on onAfterInsert and AfterDelete method
* Adyasha Satapathy    16-9-2020                   DCP-40052           Added logic for switching of record types to Standard for certain conditions on Opp Line Items
                                                                       and control a flagg whichh triggers validation rule - CheckFSAndROSwitchFromStandardToNonStd.
* Prem Ranjan          28-06-2021                  DCP-48006           Carting Products: Finalize Adding Products to Opportunity
* Dushyant Srivastava  17-12-2021                  DCP-51025           Added logic to mark CP Modified Pricing if sales price is changed.
* Ashwin Kumar         20-Jan-2022                 INC0372516          Added check in initializeVariable method to avoid null exception
* Prem Ranjan          24-March-2022               DCP-52276           CodeScan Fix : Instrumentation/Debt Reduction Sales 22Q2
* Aman Tyagi           31-Mar-2022                                     CodeScan Fixes
* Anshaj Sinha         22-Aug-2022                 CMSI-199            Instrumented class with PS Log FW Methods and modified existing instrumentation
* Enrique Reyes        03-Jun-2024                 PRB0048991          Use the map for all updates instead of performing a dml update
*/
public with sharing class OpportunityLineItems extends ilib_SObjectDomain {

    private Map<Id, Opportunity> idToOpportunity;
    private Map<Id, Set<String>> oppIdToProdType;
    private Map<Id, Set<String>> oppIdToProdGroup;
    private Boolean booCheckFieldsChanged = false;
    public static boolean boolRunBeforeInsertLogic = false;
    public static String opportunityId = 'OpportunityId'; //DCP-48006 
    public static final String OPTION = 'Option';
    public static boolean isAutomation = false; //DCP-51025 
    public static final String LOG_TITLE = 'OpportunityLineItems';
    private final static String SOURCE = 'OpportunityLineItems';
    private static final String MAPISEMPTY = 'Map is Empty';
    private static final String OPPTYIDS = 'mapUpdateOpportunity Ids : ';

    public static Map<String, Schema.RecordTypeInfo> stringToRecordTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    /*
    * Method: Constructor
    * Parameters: List of OpportunityLineItem
    */
    public OpportunityLineItems(List<OpportunityLineItem> sObjectList) {
        super(sObjectList);
        initializeVariable();
    }

    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
    
        /*
        * @Author: Ashwin 
        * @Description : parameterized constructor of base class
        * @param : List<SObject> sObjectList
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new OpportunityLineItems(sObjectList);
        }
    }

     /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

    /**
     *  @author       : Govind Dubey
     *  @description  : Query for product types for each opportunity
     *  @param        : NA
     *  @return       : void
     */
    private void initializeVariable() {
        ilib_LogEvent.push(LOG_TITLE +'.initializeVariable()');
        oppIdToProdType = new Map<Id, Set<String>>();
        oppIdToProdGroup = new Map<Id, Set<String>>();

        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(records, opportunityId);
        List<OpportunityLineItem> lstAllOptyLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(setOpportunityIds);
        Set<Id> setProposalLineItems = UtilsCollection.getSetOfIds(lstAllOptyLineItems, 'Quote_Line_Item__c');
        ilib_LogEvent.info('setProposalLineItems : '+setProposalLineItems);
        Map<Id,Apttus_Proposal__Proposal_Line_Item__c> idToProposalLineItems = new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>(new ApttusProposalLineItemsSelector().fetchQuotationLineItemById(setProposalLineItems));
        Set<Id> setProductIds = new Set<Id>();
        for(Apttus_Proposal__Proposal_Line_Item__c objPLI : idToProposalLineItems.values()) {
            if(objPLI.Apttus_QPConfig__LineType__c == OPTION) {
                setProductIds.add(objPLI.Apttus_QPConfig__OptionId__c);
            } else {
                setProductIds.add(objPLI.Apttus_Proposal__Product__c);
            }
        }
        ilib_LogEvent.info('setProductIds : '+setProductIds);

        // get opportunity details
        idToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));

        // if no IDs are present in incoming records we are done
        if (setOpportunityIds.isEmpty()) { ilib_LogEvent.pop(); 
            return; }
        if (setProductIds.isEmpty()) {
            setProductIds = UtilsCollection.getSetOfIds(lstAllOptyLineItems, 'Product2Id');
            if (setProductIds.isEmpty()) { ilib_LogEvent.pop();
                return; }
        } 

        ilib_LogEvent.info('setProductIds :'+setProductIds);

        // get product details
        Map<Id, Product2> idToProduct = new Map<Id, Product2>(new ProductsSelector().selectProducts(setProductIds));

        // Collect product types and product group by opportunity
        setProductGroupAndType(idToProposalLineItems,lstAllOptyLineItems,idToProduct,oppIdToProdType,oppIdToProdGroup);

        ilib_LogEvent.pop();  
    }
    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    private static Product2 setProduct(Map<Id,Apttus_Proposal__Proposal_Line_Item__c> idToProposalLineItems,  Map<Id, Product2> idToProduct, OpportunityLineItem oli ) {
        return idToProposalLineItems.isEmpty()?idToProduct.get(oli.Product2Id):idToProposalLineItems.get(oli.Quote_Line_Item__c).Apttus_QPConfig__LineType__c==OPTION?idToProduct.get(idToProposalLineItems.get(oli.Quote_Line_Item__c).Apttus_QPConfig__OptionId__c):idToProduct.get(idToProposalLineItems.get(oli.Quote_Line_Item__c).Apttus_Proposal__Product__c);      
    }
     /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    private static void setProductGroupAndType(Map<Id,Apttus_Proposal__Proposal_Line_Item__c> idToProposalLineItems, List<OpportunityLineItem> lstAllOptyLineItems,  Map<Id, Product2> idToProduct, Map<Id, Set<String>> oppIdToProdType, Map<Id, Set<String>> oppIdToProdGroup) {
        ilib_LogEvent.push(LOG_TITLE +'.setProductGroupAndType()');
        for (OpportunityLineItem os : lstAllOptyLineItems) { 
            if( (idToProposalLineItems.isEmpty() && !idToProduct.containsKey(os.Product2Id))    //INC0372516
            || (!idToProposalLineItems.isEmpty() && os.Quote_Line_Item__c == null)
                ) { continue; } 
           Product2 objProduct = setProduct(idToProposalLineItems, idToProduct, os);

            if (!oppIdToProdType.containsKey(os.OpportunityId)) {
                ilib_LogEvent.message('<--Contains Material Class-->' + objProduct.Material_Class__c);
            oppIdToProdType.put(os.OpportunityId, new Set<String>());
            }

            if (String.isNotBlank(objProduct.Material_Class__c)) {
                oppIdToProdType.get(os.OpportunityId).add(objProduct.Material_Class__c);
            }

            if (!oppIdToProdGroup.containsKey(os.OpportunityId)) {
                ilib_LogEvent.message('<--Contains Product Group-->' + objProduct.Product_Group__c);
                oppIdToProdGroup.put(os.OpportunityId, new Set<String>());
            }

            if (String.isNotBlank(objProduct.Product_Group__c)) {
                oppIdToProdGroup.get(os.OpportunityId).add(objProduct.Product_Group__c);
            }
            }
            ilib_LogEvent.info('oppIdToProdType : '+oppIdToProdType);
            ilib_LogEvent.info('oppIdToProdGroup : '+oppIdToProdGroup);
            ilib_LogEvent.pop();
    }


    /**
     *  @author       : Indra Ganesan
     *  @description  : US-598: Updates product type on opportunity
     *  @param        : List<OpportunityLineItem>
     *  @return       : void
     */
    public override void onAfterInsert() {
        //DCP-28663 - To not sync FixedBundleSKU ProposalLineItem to Opportunity
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(records, opportunityId);
        ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        List<OpportunityLineItem> lstOptyLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(setOpportunityIds);
        OpportunityLineItemsHelper oliHelper =new OpportunityLineItemsHelper();
        //DCP-28965 - To get the related opportunities for opportunity line item
        Set<Id> setCRFNeededOppIds = new Set<Id>();       
        Set<Id> setInfoOppids = new Set<Id>();
        //DCP-40052 - Shorter Sales Cycle
        Set<Id> setOpprtyIds = new Set<Id>();

        oliHelper.prepareOpportunitySet(lstOptyLineItems,setCRFNeededOppIds,setInfoOppids,setOpprtyIds);  

        ilib_LogEvent.info('setInfoOppidsafterinsert : ' + setInfoOppids);
        oliHelper.opportunityLineToDelete(lstOptyLineItems);//Delete List Opportunity line items

        if(!setOpprtyIds.isEmpty()) {
            updateReorderFSOpportunityRecordTypeToStandard(setOpprtyIds);
        }
        ilib_LogEvent.info('<-- populateProductTypeOnOpportunity ENTRY -->'+oppIdToProdType);
        updateOpportunityOnAfterInsert(idToOpportunity.values(),setCRFNeededOppIds,setInfoOppids,oppIdToProdType,oppIdToProdGroup);
        ilib_LogEvent.info('<-- populateOnOpportunity EXIT -->');
    }

    /**
     *  @author       : Govind Dubey
     *  @description  : US-2433: Updates product type on opportunity if products deleted.
     *  @return       : void
     */
    public override void onAfterDelete() {
        ilib_LogEvent.info('<-- deleteProductTypeOnOpportunity ENTRY -->');
        //DCP-28965 - To add the relevant opportunites to set where opportunity line item meet the criteria
        List<OpportunityLineItem> lstAllOptyLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(idToOpportunity.keyset());
        Set<Id> setCRFNeededOppIds = new Set<Id>();
        //DCP-40052
        Set<Id> setOppRecTypeSwitch = new Set<Id>();
        ilib_LogEvent.info('lstAllOptyLineItems : ' + lstAllOptyLineItems);
        Map<id, List<OpportunityLineItem>> mapOppidToOpportunitylineitem = new Map<id, List<OpportunityLineItem>>();
        OpportunityLineItemsHelper oliHelper =new OpportunityLineItemsHelper();

        //DCP-30367 - Create map opp id to opportunity line item.
        oliHelper.createMapOppIdToOLI(lstAllOptyLineItems, mapOppidToOpportunitylineitem, setCRFNeededOppIds, setOppRecTypeSwitch);
       
        ilib_LogEvent.info('map Oppid ToOpportunitylineitem : ' + mapOppidToOpportunitylineitem);
        updateOpportunityOnAfterDelete(idToOpportunity.values(),mapOppidToOpportunitylineitem,setCRFNeededOppIds,oppIdToProdType,oppIdToProdGroup, setOppRecTypeSwitch);
       
        ilib_LogEvent.info('<-- deleteOnOpportunity EXIT -->');
    }

    /**
     *  @author       : Akash Kumar.
     *  @description  : US-7708: Prevent delete of Opportunity Products on Creation of Quote
     *  @return       : void
     */
    public override void onBeforeDelete() {
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(records, opportunityId);
        ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        idToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
        List<OpportunityLineItem> lstTempOpp = (List<OpportunityLineItem>) records;
        //Prevent delete of Opportunity Products on Creation of Quote
        OpportunityLineItemsHelper.addErrorOnOppLineItem(lstTempOpp, idToOpportunity);
    }

    /**
     *  @author       : Dushyant Srivastava.
     *  @description  : DCP-51025 updating Dist Mod Sales Price if sales price is updated.
     *  @return       : void
     */
    public override void onBeforeupdate(Map<Id, SObject> idToOldOpportunityLineItem) {
        // DCP-51025 updating Dist Mod Sales Price if sales price is updated
        OpportunityLineItemsHelper.markCPModifiedPriceTrue((List<OpportunityLineItem>)records , idToOldOpportunityLineItem, isAutomation);
    }

    /**
     *  @author       : Prem Ranjan
     *  @description  : updat eOpportunity On After Insert
     *  @return       : void
     */
    public void updateOpportunityOnAfterInsert(List<Opportunity> lstOpportunity, Set<Id> setCRFNeededOppIds, Set<Id> setInfoOppids, Map<Id, Set<String>> oppIdToProdType, Map<Id, Set<String>> oppIdToProdGroup) {  
        ilib_LogEvent.push(LOG_TITLE +'.updateOpportunityOnAfterInsert()');   
		OpportunityLineItemsHelper oliHelper =new OpportunityLineItemsHelper();
        Map<Id, Opportunity> mapUpdateOpportunity = new Map<Id, Opportunity>();
        // update parent opportunities with inserted product types
        // set flags on parent opportunities
        if (!oppIdToProdType.isEmpty() || !setInfoOppids.isEmpty()) {
            for (Opportunity opp : lstOpportunity) {
                if(mapUpdateOpportunity.containsKey(opp.Id)) {
                    opp = mapUpdateOpportunity.get(opp.Id);
                }
                oliHelper.updateOpportunityForInformaticsProduct(opp, mapUpdateOpportunity, setInfoOppids);
                ilib_LogEvent.message('<--Join-->');
                booCheckFieldsChanged = oliHelper.updateOppFields(opp, oppIdToProdType);
                
                //DCP-28965 - To update the Is_Customer_Readiness_Form_Required__c checkbox on opportunity          
                oliHelper.markisCRFRequiredTrue(opp, booCheckFieldsChanged, mapUpdateOpportunity, setCRFNeededOppIds);

                /*************** ICE - Opportunity Product Line Begins**********************************************/
                oliHelper.updateParentOpp(opp,mapUpdateOpportunity,oppIdToProdGroup);
                /*************** ICE - Opportunity Product Line Ends**********************************************/
            }
        }
        ilib_LogEvent.info(OPPTYIDS + (mapUpdateOpportunity != NULL ? String.valueOf(mapUpdateOpportunity.keySet()): MAPISEMPTY));

        if(!mapUpdateOpportunity.isEmpty()) {
            List<Database.SaveResult> lstSaveErrorsPlan = Database.update(mapUpdateOpportunity.values(), false); 
            ApexExceptions.emitSaveErrors(lstSaveErrorsPlan, SOURCE+' Opportunity '); 
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author       : Prem Ranjan
     *  @description  : update Opportunity On After Delete
     *  @return       : void
     */
    public void updateOpportunityOnAfterDelete(List<Opportunity> lstOpportunity, Map<id, List<OpportunityLineItem>> mapOppidToOpportunitylineitem, Set<Id> setCRFNeededOppIds, Map<Id, Set<String>> oppIdToProdType, Map<Id, Set<String>> oppIdToProdGroup, Set<Id> setOppRecTypeSwitch) {
        ilib_LogEvent.push(LOG_TITLE +'.updateOpportunityOnAfterDelete()');     
        OpportunityLineItemsHelper oliHelper =new OpportunityLineItemsHelper();
        Map<Id, Opportunity> mapUpdateOpportunity = new Map<Id, Opportunity>();
        for (Opportunity opp : lstOpportunity) {
            ilib_LogEvent.message('opportunity in for : ' + opp.Id);
            if(mapUpdateOpportunity.containsKey(opp.Id)) {
                opp = mapUpdateOpportunity.get(opp.Id);
            }  
            oliHelper.setInformaticsOppyToFalse(opp, mapUpdateOpportunity, mapOppidToOpportunitylineitem);

            
            booCheckFieldsChanged = oliHelper.updateParentOppFieldsOnOLIDel(opp, oppIdToProdType);
            ilib_LogEvent.message('booCheckFieldsChanged : '+booCheckFieldsChanged);

            if (booCheckFieldsChanged && opp.Account_Change__c && !mapUpdateOpportunity.containsKey(opp.Id)) {
                mapUpdateOpportunity.put(opp.Id, opp);
            }

            /*************** ICE - Opportunity Product Line Begins**********************************************/
            oliHelper.populateICEOpportunityProductLine(opp, oppIdToProdGroup, mapUpdateOpportunity, setCRFNeededOppIds, setOppRecTypeSwitch);

            /*************** ICE - Opportunity Product Line Ends **********************************************/
        }

        if(!mapUpdateOpportunity.isEmpty()) {
            ilib_LogEvent.info(OPPTYIDS + (mapUpdateOpportunity != NULL ? String.valueOf(mapUpdateOpportunity.keySet()):MAPISEMPTY));
            List<Database.SaveResult> lstSaveErrorsPlan = Database.update(mapUpdateOpportunity.values(), false);  
            ApexExceptions.emitSaveErrors(lstSaveErrorsPlan, SOURCE+' Opportunity '); 
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author       : Adyasha Satapathy
     *  @description  : US-40052: Switch FS/Reorder Record Types to Standard if Opportunity has line items that meet the conditions & Set the falg to true
     *                            which will prevent Switching of record type back.
     *  @return       : void
     */
    public void updateReorderFSOpportunityRecordTypeToStandard(Set<Id> setOpprtyIds) {
        ilib_LogEvent.push(LOG_TITLE +'.updateReorderFSOpportunityRecordTypeToStandard()');
        for(Id opportunityId : setOpprtyIds) {
            Opportunity objOpportunity = idToOpportunity.get(opportunityId);
            if (!(objOpportunity.RecordType.DeveloperName == System.Label.OpportunityRTDirectStandard ||
                objOpportunity.RecordType.DeveloperName == System.Label.OpportunityRTIndirectStandard ||
                objOpportunity.RecordType.DeveloperName == System.Label.OpportunityRTStandingQuote)) {
                    objOpportunity.StageName = System.Label.OpportunityStageCreate;
                    objOpportunity.Type = System.Label.OpportunityTypeStandardSale;
                
                if(objOpportunity.RecordType.DeveloperName == System.Label.OpportunityRTDirectReOrder || 
                    objOpportunity.RecordType.DeveloperName == System.Label.OpportunityRTDirectFieldServices) {
                    objOpportunity.RecordTypeId = stringToRecordTypeInfo.get(System.Label.OpportunityRTDirectStandard).getRecordTypeId();
                }
                if(objOpportunity.RecordType.DeveloperName == System.Label.IndirectReOrder || objOpportunity.RecordType.DeveloperName == System.Label.IndirectFieldServices) {
                    objOpportunity.RecordTypeId = stringToRecordTypeInfo.get(System.Label.OpportunityRTIndirectStandard).getRecordTypeId();

                } 
                objOpportunity.ByPass_Change_Record_Type_To_Standard__c = true;
                objOpportunity.Is_Updated_By_System__c = true;
                objOpportunity.Is_Record_Type_Switched_To_Standard__c = true;
            }
        }
        ilib_LogEvent.pop();
    }

    /**
    *  @author       : Prem Ranjan
    *  @description  : DCP-48006: Carting Products: Finalize Adding Products to Opportunity
    *  @return       : void
    */
    public override void onBeforeInsert() {
        checkQuoteCreationBeforeInsert(records);
    }

    /*Method - Add Error if quote already created */  
    public static void checkQuoteCreationBeforeInsert(List<OpportunityLineItem> lstOli) {
        ilib_LogEvent.push(LOG_TITLE +'.checkQuoteCreationBeforeInsert()');
        ilib_LogEvent.info('lstOli : '+lstOli);
        if(Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) { return; }
        if(boolRunBeforeInsertLogic || !test.isRunningTest()) { 
            Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(lstOli, opportunityId);
            Map<Id,Opportunity> idToOpportunityMap = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
            for (OpportunityLineItem oli : lstOli) {
                if (!oli.By_Pass_Sync_To_Opportunity__c && idToOpportunityMap.get(oli.OpportunityId).First_Proposal_Id__c != null && idToOpportunityMap.get(oli.OpportunityId).Account_Change__c == False) {
                    oli.addError(System.Label.UI_AddProductErrorOnQuoteCreation);
                }
            }
        }
        ilib_LogEvent.pop();
    }

}
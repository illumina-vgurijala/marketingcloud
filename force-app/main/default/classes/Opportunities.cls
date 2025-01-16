/**
*    @author        Govind Dubey
*    @date          2018-05-15
*    @description   Opportunity domain class
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
      TestOpportunity
      TestOpportunitiesAgreement
      TestOpportunitiesAccount
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                21 May 2018            To check Contact Role functionality for DCP-1010,548
*             Govind DUbey                31 May 2018            added createOpportunityContactRolesMap() to create map
*             Akash Kumar                 03 July 2018           added conditions to check Other Market Segment and Primary
*                                                                Segment Value
*             Roopal Verma                01 Aug 2018            To check if sold to Account on opportunity is inactive member of related consortium
*             Indra Ganesan               02 Aug 2018            Update Primary Contact On Opportunity
*             Rahul Sharma                03 Aug 2018            Update Sold To Sales Area and Ultimate Consignee Sales Area On Opportunity
*             Rahul Sharma                04 Aug 2018            Update Price List Type and Price List On Opportunity
*             Rahul Sharma                24 Aug 2018            Update logic for Price List Type,Price List and Currency On Opportunity
*             Rahul Sharma                08 Sep 2018            Update the existing quotes on Opprtunity When Sold To Is Changed
*             Akshay Mohan                11 Sep 2018            Update the Quotes based on change of Ultimate Consignee(Ship To) and Account(Bill To)
*             Rahul Sharma                19 Sep 2018            Update the existing quotes on Sold To and UC Change
*             Rahul Sharma                24 Sep 2018            Update the existing quotes on Distributor Change
*             Akash Kumar                 28 Sep 2018            Update Field Service related fields on Opportunity
*             Rahul Sharma                03 Oct 2018            Update Price List Fields for Indirect Deals
*             Rahul Sharma                20 Oct 2018            Update Contract Number For Direct and Indirect
*             Govind Dubey                23 Oct 2018            populateDistributorAccount logic for Distributor Account Automation DCP-13652
*             Satya Swain                 23 Oct 2018            Populate Company Code Address from metadata using Company Code
*             Vishnu Priya Duggineni      31 Oct 2018            Check sold to account not part of user's account territory
*             Rahul Sharma                30 Oct 2018            Push down Pricelist to Quote
*             Rahul Sharma                09 Nov 2018            Cancelling check on Direct Sale To Ultimate Consignee DCP-14650
*             Roopal Verma                16 Nov 2018            Bypassed custom Validation errors for system admins and data stewards profiles
*             Rahul Sharma                18 Nov 2018            Updated logic for Population of sales area fields DCP-12852
*             Roopal Verma                29 Nov 2018            Updated Populate pricelist method
*             Chaarvi Sardana             13 Dec 2018            Updated logic for populateFieldServiceFields DCP-16207
*             Roopal Verma                29 Nov 2018            Updated Populate pricelist method.
*             Roopal Verma                13 Dec 2018            Added logic to populate pricelist method for blank prospect ERP id
*             Chaarvi Sardana             18 Dec 2018            Added logic in checkAccountChangeAndSendEmail and checkSoldToOrUltimateConsigneeChange to bypass quote for partner users
*             Akshay Mohan                11 Jan 2019            Moved logic of PriceBook Stamping to trigger before insert/update
*             Pankaj Singla               22 Mar 2019            Bypass Contact Validation Rules For Contact Update
*             Rahul Sharma                20 Jun 2019            DCP-25384 UC Apex Sharing
*             Todd Newman                 01 Nov 2019            INC0234515 utilize platform event to update Opportunities
*             Rahul Bishnoi               03 Dec 2019            DCP-30367 Create new renewal opportunities and related items, if Opportunity is closed won and informatics opportunity.
*             Joshith k                   17 Mar 2020            INC0257010 - call stampSalesAreaIdFields on Ship_To_Sales_Org__c changes
*             Tapas Chakraborty           14 Aug 2020            DCP-40024,29588 created methods - createContactRoleForPartnersCreatedRecords,addPrimaryContactForPartnersCreatedRecords and updateContactOnQuotes
*             Tapas Chakraborty           09 sEP 2020            DCP-40569, DCP-40570 created methods - preventStandingQuoteOppsCreationForSameQuarter,preventIncorrectAccountOnStandingQuoteOpps
*        Pankaj Singla          14-Sept 2020       DCP-40572- Added changes for clone opportunity
*             Anish                       15-Mar-2021            DCP-43258 Refactor Process Builder
*             Rishab                      22-Mar-2021            DCP-45454 Opportunity Performance Improvements
*             Rishab                      22-Mar-2021            DCP-45455 Opportunity Performance Improvements
*             Anish                       24-Mar-2021            DCP-45455 Opportunity Performance Improvements
*             Akshay Mohan                07-June-2021           DCP-46835 Set Exclude from Forecast field
*             Akshay Mohan                18-June-2021           DCP-38968 Change sharing logic for Opportunity to Field Support
*             Anand Palla                 14-Jun-2021            DCP-46168 Email notification for Closed Won Tender Opportunities
*             KD                          16-June-2021           DCP-46224: Set Relocation Type field
*             Ashwin Kumar                28-Jun-2021            INC0329074 Remove populateFieldServiceFields() method calls from before Trigger context to avoid Validation rule bypass
*             Ashwin Kumar                23-Aug-2021            INC0336441 Include record type check in Insert scenario for Transborder flag update
*             Ashwin Kumar                05-Aug-2021            INC0337404 Added Boolean check to avoid Too many queueables error
*             Ashwin Kumar                01-Sept-2021           INC0337404 Added Old and New value check for Reason for moving backwards field to avoid recursion
*             Ashwin Kumar                24-Sept-2021           INC0347480 Removed condition which ran populateFieldServiceFields() only during bulk DML
*             Ashwin Kumar                28-Feb-2022            INC0379847 Publish OpportunityServiceUserRecalcs PE only when relevant updates are made
*             Rishab Wali                 23-Mar-2022            DCP-52296 Waterfall Opp Adjustments
*             Nishan Shetty               31-March-2022          DCP-52276: CodeScan Fixes
*             Rishab Wali                 23-Mar-2022            DCP-52296 Waterfall Opp Adjustments
*             Aman Tyagi                  31-Mar-2022            CodeScan Fixes
*             Adithi Acharya              21-June-2022           Added condition for TestOpportunities fix to exempt method updateManualQuoteNumber run for Channel Partner users
*             Nitin Reddy                 24-june-2022           CMSI-68 Instrumentation
*             Avina                       07-July-2022           CMSI-51 - Added getWorkstream method to return the workstream
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Iram Malik                 14-Jul-2022            Codescan fixes
*             Nishan Shetty                 24-Aug-2022          DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*             Rishab Wali                 23-Aug-2022            DCP-56623 - Waterfall Changes for Open Opps
*             Khushbu                     04-Sept-2022           DCP-56658- populate approval hierarchy owner
*             Rishab Wali                 27-Sep-2022            DCP-57910 - Adding check for waterfall changes
*             Deep Diwakar                03-Oct-2022            DCP-57910 - Correcting empty/null checks and adding reset waterfall condition
*             Adithi Acharya              31-Oct-2022            DCP-56437 : Removal of Rejected Quote Stage
*              Iram Malik                 14-Jul-2022            Codescan fixes
*              Jitesh Lakhwani            02-Sept-2022           INC0419938
*             Atit Kar                    13-March-2023          INC0419938 - Removed updateManualQuoteNumber method
*             Atit Kar                    21-March-2023          TASK0876760 - created methods updateBUAndSubRegionSoldTOUCDist to update values on proposal 
*            Deep Diwakar                 June-28-2023           DCP-60098: Moving contact update logic for closed opportunity into new transaction
*            Deep Diwakar                 Aug-12-2023            DCP-60131: Moving open opportunity processing for waterfall into new transaction/platform event
*            Sai Pasumarthy               Nov-27-2024            CMCM-11235 TI- Opportunity : Update Stage to Close Abandoned when Deal Registration is Rejected
*            Sai Pasumarthy               Dec-04-2024            CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
*------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class Opportunities extends ilib_SObjectDomain {
    private static final String LOG_TITLE = 'Opportunities';
    public static Boolean hasRunTaps = false;

    private static Map<Id, Schema.RecordTypeInfo> idToRecordType;
    // cache describe result

    public static final Set<String> DIRECT_RECORD_TYPES = new Set<String> { Label.OpportunityRTDirectFieldServices, Label.OpportunityRTDirectReOrder, Label.OpportunityRTDirectStandard };
    public static final Set<String> INDIRECT_RECORD_TYPES = new Set<String> { Label.OpportunityRTIndirectStandard, Label.IndirectReOrder, Label.IndirectFieldServices };

    public static final String RT_STANDARD_DIRECT = 'Standard';
    public static final String RT_STANDARD_INDIRECT = 'Indirect_Standard';
    public static final String OPPORTUNITY_RT_DIRECT_RE_ORDER = 'Re_Order';
    public static final String OPPORTUNITY_RT_STANDING_QUOTE = 'Standing_Quote';
  public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_MAP = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

    public static final String STRING_OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final String STRING_OPPORTUNITY_STAGE_CLOSED_LOST = 'Closed Lost';
    public static final String STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED = 'Closed Abandoned';
    public static final String STRING_OPPORTUNITY_ABANDON_REASON = 'Deal Registration Rejected'; // CMCM-11235
    public static final String STRING_OPPORTUNITY_DEAL_REGISTRATION_REJECTED = 'Rejected'; // CMCM-11235
    public static final String OPPORTUNITY_TYPE_RENEWAL_SERVICE_CONTRACT_NO_UPSELL = 'Renewal - Service Contract No Upsell';
    public static final String OPPORTUNITY_TYPE_RENEWAL_SOFTWARE_NO_UPSELL = 'Renewal - Software No Upsell';
    public static final String OPPORTUNITY_TYPE_UPSELL_WITH_SERVICE_CONTRACT_RENEWAL = 'Upsell with Service Contract Renewal';

    public static final Set<String> OPEN_STATUSES = new Set<String> { 'Create', 'Qualify',  'Develop',  'Prove',  'Negotiate & Resolve', 'Finalize' };
    public static final Set<String> CLOSED_STATUSES = new Set<String> { STRING_OPPORTUNITY_STAGE_CLOSED_WON, STRING_OPPORTUNITY_STAGE_CLOSED_LOST, STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED, 'Duplicate/Error' };
    public static final Set<String> OPPTY_CLOSED_STAGES = new Set<String> {STRING_OPPORTUNITY_STAGE_CLOSED_WON, STRING_OPPORTUNITY_STAGE_CLOSED_LOST, STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED};
    public static final Set<String> OPP_STAGE_AFTER_QUALIFY = new Set<String>{System.Label.OpportunityStageDevelop, System.Label.OpportunityStageProve
                                                                                ,System.Label.OpportunityStageNegotiateResolve, System.Label.OpportunityStageFinalize}; //CMCM-11292
    public static final Set<String> OPP_STAGE_AFTER_DEVELOP = new Set<String>{System.Label.OpportunityStageProve
                                                                                ,System.Label.OpportunityStageNegotiateResolve
                                                                                ,System.Label.OpportunityStageFinalize}; //CMCM-11292
    public static final String STRING_OPEN_OPPORTUNITY = 'Open Opportunity';
  public static final String STRING_OPPORTUNITIES = 'opportunities';
  public static final String STRINGEXCEPTIONLOGMESSAGE = 'Task Creation From Opportunity - Opportunities.createTaskForOpportunity()'; //DCP-45454
    public static final String BU_SOLD_TO = 'Business_Unit_Sold_To__c'; //TASK0876760
    public static final String BU_UC = 'Business_Unit_UC__c'; //TASK0876760
    public static final String SUBREGION_SOLD_TO = 'Sub_Region_Sold_To__c'; //TASK0876760
    public static final String SUBREGION_UC = 'Sub_Region_UC__c'; //TASK0876760
    public static final String BU_DISTRIBUTOR = 'Business_Unit_Distributor__c'; 
    public static final String SUBREGION_DISTRIBUTOR = 'Sub_Region_Distributor__c'; 
    public static List<OpportunityContactRole> lstOpportunityContactRole;
    // Not using user selector as Sales rep do not have view profile permission
    private static User objUser = [Select Id, FirstName, Profile.Name, IsPortalEnabled,ContactId FROM User WHERE Id = :UserInfo.getUserId()];
    private static Profile objProfileSnapLogic=[select id, name from profile where name=:Label.Integration_Sales_SNAP_Profile];
    private PriceBook2 objStandardPriceBook;
  private static Map<Integer,List<String>> numToMonth;
  private static List<Period> lstPeriod;
    public static final String STRING_ISCONVERTED_FROM_LEAD_YES = 'Yes';
    public static Set<String> setByPassProfiles = new Set<String>{Label.ProfileSystemAdmin, Label.ProfileDataSteward};
    public static final String STRING_CHANNEL_PARTNER_AFFILICATE = 'Affiliate';
    public static final String STRING_ACCOUNT_GROUP_DISTRIBUTOR = 'Distributor';
    public static final Set<String> OPPORTUNITY_TYPE = new Set<String> {'Consortium', 'Reorder - Consortium Consumable'};
    public static final String OPPORTUNITY_CONSORTIUM_CLOSED_STATUS = 'Closed';
  public static final List<String> LSTFISCALQUARTERS = new List<String>{'Current Quarter','Current Quarter + 1','Current Quarter + 2','Current Quarter + 3'};
  public static final String UCMARKETSEGMENTMULTIPLE = 'Multiple';
    public static Map<Id,Boolean> oppIdToDirectStandardRTMap = new Map<Id,Boolean>(); //DCP-45454
    public static Boolean boolTaskCreated = false; //DCP-45454

  public static final String OPPTYPECUSTOMPRODUCTFIRSTBUY = 'Custom Product (First Buy)'; //DCP-45455
    public static Set<String> recordTypeDevNameSet = new Set<String>{System.Label.OpportunityRTDirectFieldServices,System.Label.OpportunityRTDirectReOrder,
                                                                     System.Label.OpportunityRTDirectStandard }; //DCP-45455
    public static Map<Id,Boolean> oppIdToTransborderLogicTrueMap = new Map<Id,Boolean>();
    public static Boolean boolOptyClosedEmailSent = false;
    public static Boolean boolIsOpptyUpdated = false; //INC0337404
    public static final String ULTIMATE_CONSIGNEE = 'Ultimate_Consignee__c';
    public static final String ACCOUNT_ID = 'AccountId';
    public static final String DISTRIBUTOR = 'Distributor__c';
    public static final String EXECUTE = 'execute';
    public static final String APTTUS_PROPOSAL_APPROVAL_STAGE = 'Apttus_Proposal__Approval_Stage__c';
    public static final String NULLSTR = 'Null';
    public static final String OBJOPPSTR ='objOpp : ';
    public static final String OBJCONSTR='objCon : ';
    public static final String STROPPORTUNITY = 'Opportunity';

    /*
    * Comments are added to fix code scan issues
    */
    public static Map<Id, Schema.RecordTypeInfo> getIdToRecordType()
    {
    
        if (idToRecordType == null) idToRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();
        ilib_LogEvent.message('idToRecordType : '+(idToRecordType != Null ? String.valueof(idToRecordType.keySet()):NULLSTR));
        
        return idToRecordType;
    }

    /*
    * Comments are added to fix code scan issues
    */
    public Opportunities(List<Opportunity> sObjectList) {
        super(sObjectList);
        if (objStandardPriceBook == null)
        {
            List<PriceBook2> lstPriceBook= [SELECT Id, Name FROM PriceBook2 WHERE IsStandard = true];
            if (!lstPriceBook.isEmpty())
            objStandardPriceBook = lstPriceBook.get(0);
            ilib_LogEvent.info('objStandardPriceBook : '+objStandardPriceBook);
        }
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Comments are added to fix code scan issues
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Opportunities(sObjectList);
        }
    }

    /*
    * Comments are added to fix code scan issues
    */
    public override void onBeforeInsert()
    {
        List<Opportunity> opportunities = (List<Opportunity>) records;
        populateDistributorAccount(opportunities);
        checkConsortiumAccountMember(opportunities);
        OpportunitiesHelper.updateOpportunityFromUltimateConsignee(opportunities); //DCP-45454
        populatePriceListFields(opportunities, null, false);
        populateCompanyCodeAddress(opportunities);
        populateSoldToAndUCRegionOnOpportunity();
        populateOpportunityFieldsWhileleadconversion(opportunities);
        addPrimaryContactForPartnersCreatedRecords(opportunities);
        updateStandingQuoteOppDate(opportunities, null);
        preventStandingQuoteOppsInSameAgreementANDAccountANDQuarter(opportunities, null);
        preventIncorrectAccountOnStandingQuoteOpps(opportunities, null);
        updateStandingQuoteOppName(opportunities, null);
        addParentFieldForClonedOpportunities(opportunities);
        updateTransborderFlagOnOpportunity(true);
        populateComplianceLastModifiedDate(opportunities);
        oppStageChangeOnDealReject(opportunities); //CMCM-11235
    }

    /*
    * Comments are added to fix code scan issues
    */
    public override void onBeforeUpdate(Map<Id, sObject> idToOldRecords)
    {
        populatePriceListFields((List<Opportunity>)records, idToOldRecords, true);
        populateSoldToAndUCRegionOnOpportunity();
        populateCompanyCodeAddress((List<Opportunity>)records);
        populateOpportunityContactRoleField((List<Opportunity>)records);
        checkConsortiumAccountMember((List<Opportunity>)records);
        updateStandingQuoteOppDate((List<Opportunity>)records, (Map<Id,Opportunity>)idToOldRecords);
        preventStandingQuoteOppsInSameAgreementANDAccountANDQuarter((List<Opportunity>)records, (Map<Id,Opportunity>)idToOldRecords);
        preventIncorrectAccountOnStandingQuoteOpps((List<Opportunity>)records, (Map<Id,Opportunity>)idToOldRecords);
        updateStandingQuoteOppName((List<Opportunity>)records, (Map<Id,Opportunity>)idToOldRecords);
        updateTransborderFlagOnOpportunity(false); //DCP-45455
        updateFieldIsFirstProposalSent();//DCP-45454
        OpportunitiesHelper.updateMarketSegmentClinicalType((List<Opportunity>)records,(Map<Id,Opportunity>)trigger.oldMap);//DCP-45454
        populateComplianceLastModifiedDate((List<Opportunity>)records);
        oppStageChangeOnDealReject((List<Opportunity>)records); //CMCM-11235
        oppStageChangeBackwardMovementinPipeline((List<Opportunity>)records); //CMCM-11292
        OpportunitiesHelper.updateCloseDateToToday((List<Opportunity>)records,(Map<Id,Opportunity>)trigger.oldMap);
    }

    /*
    * Comments are added to fix code scan issues
    */
    public override void onAfterInsert()
    {
        populateFieldServiceFields();
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), Opportunity.SObjectType);//DCP-38968 //DCP-44091
      createContactRoleForPartnersCreatedRecords(records);
    processClonedOpportunity(records);
    updatePartnerRequestStatus(records);//DCP-43258
        updateIsUpdatedBySystemAndReasonBackwards(true);//DCP-45454
    }

    /*
    * Comments are added to fix code scan issues
    */
    public override void onAfterUpdate(Map<Id, sObject> idToOldRecords)
    {
        checkAccountChangeAndSendEmail((List<Opportunity>)records, idToOldRecords);
        checkSoldToOrUltimateConsigneeChange((List<Opportunity>)records, idToOldRecords);
        processClosedOpportunities((List<Opportunity>)records, idToOldRecords);
        populateFieldServiceFields();
        recalculateSharing(idToOldRecords);
    updateContactOnQuotes((List<Opportunity>)records, (Map<Id, Opportunity>)idToOldRecords);
      updatecurrencyOnSQOppProds((List<Opportunity>)records, (Map<Id,Opportunity>)idToOldRecords);
        updateQuoteFromOpportunity(); //DCP-45455
    updateQuoteRecordTypeOnOpportunity((List<Opportunity>)records); //DCP-45455
       //createTaskForOpportunity(); //DCP-45454 // Commented for CMCM-1367
       triggerhandlerOppQuoteRecall();//added as part of CMCM-1036

        if(!boolOptyClosedEmailSent) {
            emailAlertforWonTendOpps((List<Opportunity>)records ,(Map<Id,Opportunity>)idToOldRecords );//DCP-46168
            boolOptyClosedEmailSent = true;
            ilib_LogEvent.info('boolOptyClosedEmailSent : '+boolOptyClosedEmailSent);
        }
        if(!boolIsOpptyUpdated) {    //INC0337404
            boolIsOpptyUpdated = true;
            ilib_LogEvent.info('boolIsOpptyUpdated : '+boolIsOpptyUpdated);
            updateIsUpdatedBySystemAndReasonBackwards(false);//DCP-45454
        }
    }

    /**
    *  @author Avina
    *  @description  CMSI-51,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
    
    /*DCP-34009
    * Comments are added to fix code scan issues
    */
    public static boolean checkOpportunityClosedStage(Opportunity objOpportunity)
    {
        ilib_LogEvent.message('objOpportunity : '+objOpportunity);
        ilib_LogEvent.message('returning : '+String.valueOf(CLOSED_STATUSES.contains(objOpportunity.StageName)));
        return CLOSED_STATUSES.contains(objOpportunity.StageName);
    }

    /*DCP-34009
    * Comments are added to fix code scan issues
    */
    public static boolean checkIfOpportunityRecordTypeIsRenewal(Opportunity objOpp)
    {
        ilib_LogEvent.message(OBJOPPSTR+objOpp);
        String strOppTypeName = objOpp.Type;
        String strOppRecordTypeName = objOpp.RecordTypeName__c;
        ilib_LogEvent.message('strOppTypeName : '+strOppTypeName);
        ilib_LogEvent.message('strOppRecordTypeName : '+strOppRecordTypeName);
        boolean bool=(strOppRecordTypeName == OPPORTUNITY_RT_DIRECT_RE_ORDER && strOppTypeName == OPPORTUNITY_TYPE_RENEWAL_SERVICE_CONTRACT_NO_UPSELL)
        || (strOppRecordTypeName == OPPORTUNITY_RT_DIRECT_RE_ORDER && strOppTypeName == OPPORTUNITY_TYPE_RENEWAL_SOFTWARE_NO_UPSELL)
        || (strOppRecordTypeName == RT_STANDARD_DIRECT && strOppTypeName == OPPORTUNITY_TYPE_UPSELL_WITH_SERVICE_CONTRACT_RENEWAL);
        ilib_LogEvent.message('returning bool : '+bool);
        return (strOppRecordTypeName == OPPORTUNITY_RT_DIRECT_RE_ORDER && strOppTypeName == OPPORTUNITY_TYPE_RENEWAL_SERVICE_CONTRACT_NO_UPSELL)
                    || (strOppRecordTypeName == OPPORTUNITY_RT_DIRECT_RE_ORDER && strOppTypeName == OPPORTUNITY_TYPE_RENEWAL_SOFTWARE_NO_UPSELL)
                    || (strOppRecordTypeName == RT_STANDARD_DIRECT && strOppTypeName == OPPORTUNITY_TYPE_UPSELL_WITH_SERVICE_CONTRACT_RENEWAL)
        ;
    }

    /**
    * @description    For Creation of OpportunityContactRole related to Opportunity Map
    */
    private void populateOpportunityContactRoleField(List<Opportunity> lstOpportunities)
    {
        ilib_LogEvent.push(LOG_TITLE+'.populateOpportunityContactRoleField');
        Boolean booIndirectDeal;
        for (Opportunity objOpp : lstOpportunities)
        {
            String strRecordTypeName = getIdToRecordType().get(objOpp.RecordTypeId).getDeveloperName();
            ilib_LogEvent.message('strRecordTypeName : '+strRecordTypeName);
            booIndirectDeal = INDIRECT_RECORD_TYPES.contains(strRecordTypeName);
            ilib_LogEvent.message('booIndirectDeal : '+booIndirectDeal);
            if (booIndirectDeal
                    && String.isBlank(objOpp.Distributor__c)
                    && objOpp.Is_Converted_From_Lead__c != Label.OpportunityIsConvertedFromLeadYes
                    && !setByPassProfiles.contains(objUser.Profile.Name)
            )
                objOpp.Distributor__c.addError(Label.UI_Error_BlankDistributor);

            if (String.isBlank(objOpp.PriceBook2Id)
                    && objStandardPriceBook != null
                    && String.isNotBlank(objStandardPriceBook.Id)
            )
                objOpp.PriceBook2Id = objStandardPriceBook.Id;
        }
        ilib_LogEvent.pop();
    }

    private void recalculateSharing(Map<Id, sObject> idToOldRecords)
    {
        ilib_LogEvent.push(LOG_TITLE + '.recalculateSharing()');
        //DCP-38968:Start- Add Current UC sharing logic
        if(hasRunTaps) {
            ilib_LogEvent.info('Recursion stop');
            ilib_LogEvent.pop();
            return;
        }

        //DCP-38968 Add Current UC
        List<String> fieldsThatTriggerRecalcuation = new List<String> {ACCOUNT_ID, ULTIMATE_CONSIGNEE,'Current_Ultimate_Consignee__c', 'OwnerId'}; 
        //DCP-38968:End- Add Current UC sharing logic
        TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        Set<Id> reparentedRecordIds = tapsOrchestratorInst.updateRequiresRecalculation(records, idToOldRecords, fieldsThatTriggerRecalcuation);
        ilib_LogEvent.info('reparentedRecordIds: '+reparentedRecordIds);

        //DCP-38968:Start- Optimize if & add sharing record
        if(reparentedRecordIds.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }
        tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Opportunity.SObjectType);//DCP-44091
        //DCP-38968:End- Optimize if & add sharing record
        tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Customer_Readiness_Form__c.SObjectType);//DCP-44091

        Boolean userHasQuoteLicense = new usersselector().isUserLicensedForPackage('Apttus_Proposal', userInfo.getUserId());
        ilib_LogEvent.info('userHasQuoteLicense ' + userHasQuoteLicense);


        if (System.Test.isRunningTest() || userHasQuoteLicense)
        {
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Proposal__Proposal__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__ProductConfiguration__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__FavoriteConfiguration__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__TempObject__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__Order__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Approval__Approval_Request__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Approval__Approval_Request_History__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__TempRenewAssetGroup__c.SObjectType);//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(reparentedRecordIds, Apttus_Config2__TempRenewAssetLineItem__c.SObjectType);//DCP-44091
        }

        hasRunTaps = true;
        ilib_LogEvent.info('hasRunTaps ' + hasRunTaps);
        ilib_LogEvent.pop();
    }

     /**
    * @description: DCP-4498:Checks if sold to Account on opportunity is inactive member of related consortium
    */
    public static void checkConsortiumAccountMember(List<Opportunity> lstOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkConsortiumAccountMember()');
        if (Trigger.isUpdate && (Label.Profile_SNAP_Integration.equals(objUser.Profile.Name) || (Label.Automated_Process_User.equals(objUser.FirstName)))){
            ilib_LogEvent.pop();
            return;
        }
        if (lstOpportunity == null || lstOpportunity.isEmpty()){ 
            ilib_LogEvent.pop();
            return;
        }
        Set<Id> setConsortiumId = UtilsCollection.getSetOfIds(lstOpportunity,'Consortium__c');
        ilib_LogEvent.info('setConsortiumId : '+setConsortiumId);
        if (setConsortiumId.isEmpty()){ 
            ilib_LogEvent.pop();
            return;
        }

        // List storing Consortia Account related to Consortia where is_inactive__c is false
        List<Consortium_Account__c> lstConsortiumAccount = new ConsortiumAccountSelector().selectConsortiumAccount(setConsortiumId);
        Map<Id, Consortium__c> idToConsortium = new Map<Id, Consortium__c>(new Consortiumselector().selectConsortium(setConsortiumId));
        ilib_LogEvent.info('idToConsortium : ' +  (idToConsortium != Null ? String.valueof(idToConsortium.keySet()):NULLSTR));
        Set<Id> setConAccounts = UtilsCollection.getSetOfIds(lstConsortiumAccount,'Account__c');
        ilib_LogEvent.info('setConAccounts : '+setConAccounts);
        for (Opportunity objOpp: lstOpportunity)
        {
            if (!String.isNotBlank(objOpp.Consortium__c)){
                ilib_LogEvent.pop();
                return;
            }
            if (OPPORTUNITY_TYPE.contains(objOpp.Type) && OPPORTUNITY_CONSORTIUM_CLOSED_STATUS.equals(idToConsortium.get(objOpp.Consortium__c).Open_Closed_Consortium__c)
                    && !setConAccounts.contains(objOpp.AccountId))
                    objOpp.addError(System.Label.OpportunityConsortiumMemberError);
        }
        ilib_LogEvent.pop();
    }

    private static set<id> setAccountIdForUCIsBlank(List<Opportunity> lstOpportunity, set<Id> ucAccountIds) {
        ilib_LogEvent.push(LOG_TITLE + '.setAccountIdForUCIsBlank()');
        for(Opportunity objOpp: lstOpportunity) {
            if(String.isBlank(objOpp.Ultimate_Consignee__c))
                ucAccountIds.add(objOpp.accountId);
        }
        ilib_LogEvent.info('returning ucAccountIds : '+ucAccountIds);
        ilib_LogEvent.pop();
        return ucAccountIds;
    }

    /**
    * @description: Assign Sold to acount region field and Ultimate consignee region on opportunity based on account region
    **/
    public void populateSoldToAndUCRegionOnOpportunity()
    {
        ilib_LogEvent.push(LOG_TITLE + '.populateSoldToAndUCRegionOnOpportunity()');
        if (records == null || records.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }
        List<Opportunity> lstOpportunities;
        if (Trigger.isInsert)
            lstOpportunities = (List<Opportunity>)records;
        else
            lstOpportunities = (List<Opportunity>)UtilsObject.filterForFieldChanges(Trigger.new, Trigger.OldMap, new List<String> {ACCOUNT_ID, ULTIMATE_CONSIGNEE});
        Set<Id> setAccountIds = new Set<Id>();
        setAccountIds.addAll(UtilsCollection.getSetOfIds(lstOpportunities, ACCOUNT_ID));
        setAccountIds.addAll(setAccountIdForUCIsBlank(lstOpportunities, UtilsCollection.getSetOfIds(lstOpportunities, ULTIMATE_CONSIGNEE)));
        ilib_LogEvent.info('setAccountIds : '+setAccountIds);
        if(setAccountIds.isEmpty()){ 
            ilib_LogEvent.pop();
            return;
        }
        Map<Id ,Account> idToAccount = new Map<Id ,Account>(new AccountsSelector().selectAccounts(setAccountIds));
        ilib_LogEvent.info('idToAccount : ' + (idToAccount != Null ? String.valueof(idToAccount.keySet()):NULLSTR));

        for(Opportunity objOpp : lstOpportunities) {
            if(idToAccount.containsKey(objOpp.AccountId)){
                objOpp.Sold_To_Account_Region__c = idToAccount.get(objOpp.AccountId).Territory_Region__c;
                ilib_LogEvent.message('objOpp.Sold_To_Account_Region__c : '+objOpp.Sold_To_Account_Region__c);
            }

            if(idToAccount.containsKey(objOpp.Ultimate_Consignee__c)){
                objOpp.Ultimate_Consignee_Region__c = idToAccount.get(objOpp.Ultimate_Consignee__c).Territory_Region__c;
                ilib_LogEvent.message('objOpp.Ultimate_Consignee_Region__c : '+objOpp.Ultimate_Consignee_Region__c);
            }

        }
        ilib_LogEvent.pop();
    }

    /**
     * @description    DCP-8330 & DCP-12478:Calculating Price list
     **/
    public void populatePriceListFields(List<Opportunity> lstOpportunity,Map<Id,SObject> idToOldOpportunity, Boolean isUpdate) {
        ilib_LogEvent.push(LOG_TITLE + '.populatePriceListFields()');
        ilib_LogEvent.info('isUpdate : '+isUpdate);
        if (lstOpportunity == null || lstOpportunity.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        Map<Id, List<Opportunity>> changedSoldToIdToOpp = new Map<Id, List<Opportunity>>()
                , changedUCIdToOpp = new Map<Id, List<Opportunity>>()
                , changedDisIdToOpp = new Map<Id, List<Opportunity>>();

        Set<Id> setAccReqASA = new Set<Id>();
        List<Opportunity> changedSoldToOpportunities = UtilsCollection.filterOnFieldsModified(lstOpportunity, idToOldOpportunity, new List<String> {ACCOUNT_ID ,'Sales_Org_Override__c', 'Ship_To_Sales_Org__c'});
        changedSoldToIdToOpp = UtilsCollection.getMapOfIdToSObjects(changedSoldToOpportunities, ACCOUNT_ID);
        ilib_LogEvent.info('changedSoldToIdToOpp : ' + (changedSoldToIdToOpp != Null ? String.valueof(changedSoldToIdToOpp.keySet()):NULLSTR));
        setAccReqASA.addall(UtilsCollection.getSetOfIds(changedSoldToOpportunities, ACCOUNT_ID));

        List<Opportunity> changedUCOpportunities = UtilsCollection.filterOnFieldsModified(lstOpportunity, idToOldOpportunity, new List<String> {ULTIMATE_CONSIGNEE ,'Sales_Org_Override__c', 'Ship_To_Sales_Org__c'});
        changedUCIdToOpp = UtilsCollection.getMapOfIdToSObjects(changedUCOpportunities, ULTIMATE_CONSIGNEE);
        ilib_LogEvent.info('changedUCIdToOpp : ' + (changedUCIdToOpp != Null ? String.valueof(changedUCIdToOpp.keySet()):NULLSTR));
        setAccReqASA.addall(UtilsCollection.getSetOfIds(changedUCOpportunities, ACCOUNT_ID));

        List<Opportunity> changedDistOpportunities = UtilsCollection.filterOnFieldsModified(lstOpportunity, idToOldOpportunity, new List<String> {DISTRIBUTOR ,'Sales_Org_Override__c', 'Ship_To_Sales_Org__c'});
        changedDisIdToOpp = UtilsCollection.getMapOfIdToSObjects(changedDistOpportunities, DISTRIBUTOR);
        ilib_LogEvent.info('changedDisIdToOpp : ' + (changedDisIdToOpp != Null ? String.valueof(changedDisIdToOpp.keySet()):NULLSTR));
        //Calling Service method to stamp Sales areas on Opportunity
        AutomatePricelistFieldsService.stampSalesAreaIdFields(changedSoldToIdToOpp,changedUCIdToOpp,changedDisIdToOpp,isUpdate);
        //Calling Service method to stamp pricelist fields on Opportunity
        AutomatePricelistFieldsService.stampPricelistFields(changedSoldToIdToOpp,changedUCIdToOpp,changedDisIdToOpp,setAccReqASA,isUpdate);
        ilib_LogEvent.pop();
    }

    /**
     * @description DCP-11696, calculation of Company Code Addresses
     **/
    private static void populateCompanyCodeAddress(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.populateCompanyCodeAddress()');
        if(lstOpportunity.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        Set<String> setCompanyCode = UtilsCollection.getSetOfStrings(lstOpportunity, 'Company_Code__c');
        ilib_LogEvent.info('setCompanyCode : '+setCompanyCode);
        Map<String,Company_Code_Address__mdt> companyCodeToCompanyCodeAddress = new Map<String,Company_Code_Address__mdt>();

        if(setCompanyCode.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }
        for(Company_Code_Address__mdt ccAdd : new CompanyCodeAddressesSelector().selectCompanyCodeAddress(setCompanyCode))
            companyCodeToCompanyCodeAddress.put(ccAdd.Company_Code__c,ccAdd);

        for(Opportunity opp : lstOpportunity) {
            if(String.isNotBlank(opp.Company_Code__c) && companyCodeToCompanyCodeAddress.containsKey(opp.Company_Code__c)) {
                opp.Company_Name__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Company_Name__c);
                opp.Address_Line_1__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_1__c);
                opp.Address_Line_2__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_2__c);
                opp.Address_Line_3__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_3__c);
                opp.Address_Line_4__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_4__c);
                opp.Address_Line_5__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_5__c);
                opp.Address_Line_6__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Address_Line_6__c);
                opp.Footer_Full_Street__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Footer_Full_Street__c);
                opp.Footer_City__c = setCompanyCodeAddressFields(companyCodeToCompanyCodeAddress.get(opp.Company_Code__c).Footer_City__c);
            }
            else
            {
                opp.Company_Code_Address__c = NULL;
                ilib_LogEvent.message('opp.Company_Code_Address__c : '+opp.Company_Code_Address__c);
                opp.Company_Name__c = NULL;
                opp.Address_Line_1__c = NULL;
                opp.Address_Line_2__c = NULL;
                opp.Address_Line_3__c = NULL;
                opp.Address_Line_4__c = NULL;
                opp.Address_Line_5__c = NULL;
                opp.Address_Line_6__c = NULL;
                opp.Footer_Full_Street__c = NULL;
                opp.Footer_City__c = NULL;
            }
            ilib_LogEvent.message('opp.Company_Name__c : '+opp.Company_Name__c);
            ilib_LogEvent.message('opp.Address_Line_1__c : '+opp.Address_Line_1__c);
            ilib_LogEvent.message('opp.Address_Line_2__c : '+opp.Address_Line_2__c);
            ilib_LogEvent.message('opp.Address_Line_3__c : '+opp.Address_Line_3__c);
            ilib_LogEvent.message('opp.Address_Line_4__c : '+opp.Address_Line_4__c);
            ilib_LogEvent.message('opp.Address_Line_5__c : '+opp.Address_Line_5__c);
            ilib_LogEvent.message('opp.Address_Line_6__c : '+opp.Address_Line_6__c);
            ilib_LogEvent.message('opp.Footer_Full_Street__c : '+opp.Footer_Full_Street__c);
            ilib_LogEvent.message('opp.Footer_City__c : '+opp.Footer_City__c);
        }
        ilib_LogEvent.pop();
    }
    private static string setCompanyCodeAddressFields(String companyCodeToCompanyCodeAddressField) {
       
        ilib_LogEvent.message('companyCodeToCompanyCodeAddressField : '+companyCodeToCompanyCodeAddressField);
        if(String.isBlank(companyCodeToCompanyCodeAddressField)) {
            ilib_LogEvent.message('Returning NULL');
            return NULL;
        }
        ilib_LogEvent.message('companyCodeToCompanyCodeAddressField : '+companyCodeToCompanyCodeAddressField);
        
        return companyCodeToCompanyCodeAddressField;
    }

    /**
    *  @description populate Distributor Account for Indirect Opportunity whenever possible and
    **/
    public void populateDistributorAccount(List<Opportunity> lstOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + '.populateDistributorAccount()');
        Set<Id> setSoldToAccountIds = utilscollection.getSetOfIds(lstOpportunity, ACCOUNT_ID);
        ilib_LogEvent.info('setSoldToAccountIds : '+setSoldToAccountIds);
        if (setSoldToAccountIds.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }
        List<Partner_Association__c> lstPartnerAssociation = new PartnerAssociationsSelector().selectPartners(setSoldToAccountIds);
        Map<Id, Id> soldToToDistributor = UtilsCollection.getMapOfIdToId(lstPartnerAssociation, 'Associated_Channel_Partner__c', 'Parent_Channel_Partner__c');
        ilib_LogEvent.info('soldToToDistributor : ' +  soldToToDistributor);
        if(setSoldToAccountIds.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }
        Map<Id, Account> idToSoldToAccount = new Map<Id, Account>(new AccountsSelector().selectAccounts(setSoldToAccountIds));
        ilib_LogEvent.info('idToSoldToAccount : ' + (idToSoldToAccount != Null ? String.valueof(idToSoldToAccount.keySet()):NULLSTR));
        for (Opportunity objOpp : lstOpportunity)
        {
            if (!isIndirectRecordType(objOpp.RecordTypeId)) {
                ilib_LogEvent.pop();
                return;
            }
            setDistributor(objOpp, idToSoldToAccount, soldToToDistributor);
            setOpportunityAttributesforLeadConversion(objOpp);
            if(checkPriceBookIsBlank(objOpp.PriceBook2Id)){
                objOpp.PriceBook2Id = objStandardPriceBook.Id;
                ilib_LogEvent.message('objOpp.PriceBook2Id : '+objOpp.PriceBook2Id);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    * @description: This will update LeadSource field with 'Funnel Marketing' value for 'Marketing Lead Qualification' Profile users
    * INC0419938
    * @param: Opportunity objOppNew, Opportunity objOppOld
    */
    public static void setLeadSource(Opportunity objOppNew, Opportunity objOppOld){

        if((objOppOld == null && Profiles.getMarketingLeadQualificationProfileId().contains(userinfo.getProfileId())) ||
            (objOppOld != null && objOppOld.LeadSource != LABEL.Lead_Source_Funnel_Marketing && Profiles.getMarketingLeadQualificationProfileId().contains(userinfo.getProfileId()))){
            objOppNew.LeadSource = LABEL.Lead_Source_Funnel_Marketing;
        }
    }

    /*
    * @description: This will update recordTypeName__c field with DeveloperName of the Record Type
    * INC0419938
    * @param: Opportunity objOppNew, Opportunity objOppOld
    */
    public static void setRecordTypeName(Opportunity objOppNew, Opportunity objOppOld){

        if(objOppOld == null || (objOppOld != null && objOppOld.recordTypeID != objOppNew.recordTypeID)){
            objOppNew.RecordTypeName__c = getIdToRecordType().get(objOppNew.recordTypeID).getDeveloperName();
        }
    }

    /*
    * @description: This will update Estimated_Close_Date__c field with CloseDate of the Record when New Optty record is created
    *               OR when close date is updated
    * INC0419938
    * @param: Opportunity objOppOld, Opportunity objOppNew
    */
    public static void setEstimatedCloseDate(Opportunity objOppNew, Opportunity objOppOld){

        if(objOppOld == null || (objOppOld != null && objOppOld.CloseDate != objOppNew.CloseDate && !OPPTY_CLOSED_STAGES.contains(objOppNew.StageName))){
            objOppNew.Estimated_Close_Date__c = objOppNew.CloseDate;
        }
    }

    /*
    * Comments are added to fix code scan issues
    */
    public static boolean isIndirectRecordType(Id recordTypeId) {

        ilib_LogEvent.message('recordTypeId : '+recordTypeId);
        ilib_LogEvent.message('return : '+string.valueOf(INDIRECT_RECORD_TYPES.contains(getIdToRecordType().get(recordTypeId).getDeveloperName())));
        
        return INDIRECT_RECORD_TYPES.contains(getIdToRecordType().get(recordTypeId).getDeveloperName());
    }

    /*
    * Comments are added to fix code scan issues
    */
    public boolean checkPriceBookIsBlank(String priceBook2Id) {
        
        ilib_LogEvent.message('priceBook2Id : '+priceBook2Id);
        ilib_LogEvent.message('return : '+string.valueOf(String.isBlank(priceBook2Id) && objStandardPriceBook != null && String.isNotBlank(objStandardPriceBook.Id)));
    
        return String.isBlank(priceBook2Id) && objStandardPriceBook != null && String.isNotBlank(objStandardPriceBook.Id);
    }

    /*
    * Comments are added to fix code scan issues
    */
    public static void setDistributor(Opportunity objOpp,  Map<Id, Account> idToSoldToAccount, Map<Id, Id> soldToToDistributor) {
        
        ilib_LogEvent.message(OBJOPPSTR+objOpp);
        ilib_LogEvent.message('idToSoldToAccount : ' + (idToSoldToAccount != Null ? String.valueof(idToSoldToAccount.keySet()):NULLSTR));
        ilib_LogEvent.message('soldToToDistributor : ' + soldToToDistributor);
        if (!(String.isBlank(objOpp.Distributor__c)
            && isIndirectRecordType(objOpp.RecordTypeId)
            && idToSoldToAccount.containsKey(objOpp.AccountId)
            && STRING_ACCOUNT_GROUP_DISTRIBUTOR.equals(idToSoldToAccount.get(objOpp.AccountId).Account_Group__c))) {
                return;
            }

            if(checkChannelPartnerAfflicate(idToSoldToAccount.get(objOpp.AccountId).Channel_Partner_Type__c))
                objOpp.Distributor__c = soldToToDistributor.containsKey(objOpp.AccountId) ? soldToToDistributor.get(objOpp.AccountId) : null;
            else
                objOpp.Distributor__c = objOpp.AccountId;
        ilib_LogEvent.message('objOpp.Distributor__c : '+objOpp.Distributor__c);
        
    }

    /*
    * Comments are added to fix code scan issues
    */
    public static boolean checkChannelPartnerAfflicate(String channelPartnerType)
    {
        ilib_LogEvent.message('channelPartnerType : '+channelPartnerType);
        ilib_LogEvent.message('return : '+string.valueOf(STRING_CHANNEL_PARTNER_AFFILICATE.equals(channelPartnerType)));
        return STRING_CHANNEL_PARTNER_AFFILICATE.equals(channelPartnerType);
    }

    /*
    * Comments are added to fix code scan issues
    */
    public static void setOpportunityAttributesforLeadConversion(Opportunity objOpp)
    {
        ilib_LogEvent.message(OBJOPPSTR+objOpp);
        Boolean isConverted = STRING_ISCONVERTED_FROM_LEAD_YES.equals(objOpp.Is_Converted_From_Lead__c );
        ilib_LogEvent.message('isConverted : '+isConverted);
        String recordType = getIdToRecordType().get(objOpp.RecordTypeId).getDeveloperName();
        ilib_LogEvent.message('recordType : '+recordType);
        if(String.isBlank(objOpp.Distributor__c)  && isIndirectRecordType(objOpp.RecordTypeId) && !isConverted && !setByPassProfiles.contains(objUser.Profile.Name))
            objOpp.Distributor__c.addError(Label.UI_Error_BlankDistributor);
        if(isConverted && objOpp.Ultimate_Consignee__c == null && RT_STANDARD_INDIRECT.equals(recordType)){
            objOpp.Ultimate_Consignee__c = objOpp.AccountId;
            ilib_LogEvent.message('objOpp.Ultimate_Consignee__c : '+objOpp.Ultimate_Consignee__c);
        }
        if(isConverted && !(RT_STANDARD_DIRECT.equals(recordType) || RT_STANDARD_INDIRECT.equals(recordType))){
            objOpp.Is_Updated_By_System__c = True;
            ilib_LogEvent.message('objOpp.Is_Updated_By_System__c : '+objOpp.Is_Updated_By_System__c);
        }
        
    }

    /*
    * Comments are added to fix code scan issues
    */
    public static Set<Id> indirectOpportuntiesSoldtos(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.indirectOpportuntiesSoldtos()');
        set<Id> indirectOpportuntiesSoldtos = new Set<Id>();
        for (Opportunity objOpp: lstOpportunity)
        {
            if (isIndirectRecordType(objOpp.RecordTypeId))
                indirectOpportuntiesSoldtos.add(objOpp.AccountId);
        }
        ilib_LogEvent.info('indirectOpportuntiesSoldtos : '+indirectOpportuntiesSoldtos);
        ilib_LogEvent.pop();
        return indirectOpportuntiesSoldtos;
    }

    /**
    * @description: Update Contact Status for closed opportunities
    */
    private void processClosedOpportunities(List<Opportunity> lstOpportunity, Map<Id, sObject> mapIdToOldOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + 'processClosedOpportunities()');
        Set<Id> setOpportunityIds = new Set<Id>();
        Map<Id, Opportunity> mapClosedWonOppIds = new Map<Id, Opportunity>();
        Set<Id> setContactIds = new Set<id>();
        Map<Id, String> idToStringContactIdOppStage = new Map<Id, String>();
        Set<String> setClosedOpportunityStatusString=new Set<String> { STRING_OPPORTUNITY_STAGE_CLOSED_LOST, STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED,
        STRING_OPPORTUNITY_STAGE_CLOSED_WON};
        ilib_LogEvent.info('setClosedOpportunityStatusString : '+setClosedOpportunityStatusString);
        /*Set of all opportunity stages which have to be considered*/
        List<Contact> lstUpdateContactRecords = new List<Contact>();
        List<OpportunityContactRole> lstOpportunityContactRoles;
        
        Set<Id> setWaterFallOpportunities=new Set<Id>();
        Set<Id> setWaterFallOpenOpp=new Set<Id>();
        Map<Id,Contact> mapIdContacts=new Map<Id,Contact>();
        Map<Id,OpportunityContactRole> mapConIdToOppContactRole=new Map<Id,OpportunityContactRole>();
        for (Opportunity objOppty : lstOpportunity)
        {
            Opportunity objOldOppty = (Opportunity)mapIdToOldOpportunity.get(objOppty.Id);
            Boolean boolStageUpdated=objOppty.StageName == objOldOppty.StageName?false:true;
            Boolean boolStageClosedWon=objOppty.StageName.equals(STRING_OPPORTUNITY_STAGE_CLOSED_WON)?true:false;
            Boolean boolLeadSourceUpdated=objOppty.LeadSource==objOldOppty.LeadSource?false:true;
            Boolean boolStageOpen=setClosedOpportunityStatusString.contains(objOppty.StageName)?false:true;

            // DCP-60131: Tracking if Oppty type has changed
            Boolean boolOpptyTypeChanged = objOppty.Type.equalsIgnoreCase(objOldOppty.Type)? false:true;

            ilib_LogEvent.message('objOldOppty : '+objOldOppty);
            ilib_LogEvent.message('boolStageUpdated : '+boolStageUpdated);
            ilib_LogEvent.message('boolStageClosedWon : '+boolStageClosedWon);
            ilib_LogEvent.message('boolLeadSourceUpdated : '+boolLeadSourceUpdated);
            ilib_LogEvent.message('boolStageOpen : '+boolStageOpen);
            ilib_LogEvent.message('boolOpptyTypeChanged : '+boolOpptyTypeChanged);
            // Loop over all the opportunity records in update trigger and add closed opportunities to set
            if (objOppty.StageName != objOldOppty.StageName && setClosedOpportunityStatusString.contains(objOppty.StageName))
                setOpportunityIds.add(objOppty.Id);
             //DCP-30367 Loop over all the opportunity records in update trigger and add closed won opportunities to set
             if (boolStageUpdated && objOppty.StageName.equals(STRING_OPPORTUNITY_STAGE_CLOSED_WON) 
                && objOppty.Informatics_Opportunity__c) {
                mapClosedWonOppIds.put(objOppty.id,objOppty);
            }
            if(boolStageUpdated && boolStageClosedWon) {
                setWaterFallOpportunities.add(objOppty.Id);
            }
      
            // DCP-60131: Adding oppty type check to consider it for waterfall process
            if((boolStageUpdated || boolLeadSourceUpdated || boolOpptyTypeChanged)  && boolStageOpen ) {
                setWaterFallOpenOpp.add(objOppty.Id);
            }
        }
        ilib_LogEvent.info('mapClosedWonOppIds : ' + (mapClosedWonOppIds != Null ? String.valueof(mapClosedWonOppIds.keySet()):NULLSTR));
        ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        ilib_LogEvent.info('setWaterFallOpportunities : '+setWaterFallOpportunities);
        ilib_LogEvent.info('setWaterFallOpenOpp : '+setWaterFallOpenOpp);
        //DCP-30367 - Invoke queable class to create renewable oppOrtunities
        if(mapClosedWonOppIds != null && !mapClosedWonOppIds.isEmpty()) {
                RenewOppQueueable queueableClassInstance = new RenewOppQueueable(mapClosedWonOppIds,0);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities');
                queueableThread.logAndQueue(queueableClassInstance, 'RenewOppQueueable', EXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            }

        // DCP-60098: Moving contact update logic in different transaction due to limited visibility of opportunity based on user access/sharing
        List<ProcessContactOnOpportunityClose__e> lstContactEvent = new List<ProcessContactOnOpportunityClose__e>();

        for (Id opptyId : setOpportunityIds) {
            ProcessContactOnOpportunityClose__e event = new ProcessContactOnOpportunityClose__e();
            event.OpportunityId__c = opptyId;
            lstContactEvent.add(event);
        }

        ilib_LogEvent.info('Contact update event size: ' + lstContactEvent.size());
        if (!lstContactEvent.isEmpty()) {
            EventBus.publish(lstContactEvent);

        }
        // DCP-60098: changes ends here

        if(!setWaterFallOpenOpp.isEmpty()) {
            // DCP-60131: publishing event for processing open opportunities for waterfall 
            ilib_LogEvent.info('publishing open waterfall oppty event - setWaterFallOpenOpp : '+setWaterFallOpenOpp);
            MktgWaterfallServiceHelper.publishWaterfallOpptyEvent('Opportunity', setWaterFallOpenOpp);
        }

        ilib_LogEvent.pop();
    }

    /**
    * @description  Stamp FS user IDs on opportunities via platform event which triggers a batch
    */
    public void populateFieldServiceFields()
    {
        ilib_LogEvent.push(LOG_TITLE + 'populateFieldServiceFields()');
        if (records == null || records.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        List<Opportunity> lstOpportunities;
        if (Trigger.isInsert)
            lstOpportunities = (List<Opportunity>)records;
        else
            lstOpportunities = (List<Opportunity>)UtilsObject.filterForFieldChanges(Trigger.new, Trigger.OldMap, new List<String> {ULTIMATE_CONSIGNEE, DISTRIBUTOR});
        if (lstOpportunities.isEmpty()) { 
            ilib_LOgEvent.pop();
            return; }     //INC0379847

        OpportunityBatchUpdateFSUsers fsUserUpdater = new OpportunityBatchUpdateFSUsers();
        Map<Id, List<Opportunity>> accountIdToOpportunities = fsUserUpdater.mapAccountIdToOpportunities(lstOpportunities);
        Set<Id> setAccountIds = accountIdToOpportunities.keySet();
        ilib_LogEvent.info('setAccountIds : '+setAccountIds);
        OpportunityServiceUserRecalcs.publish(setAccountIds);
        ilib_LogEvent.pop();
    }

   /**
    * @description Method to send email when Sold To,UC or Distributor Changes
    */
    public static void checkAccountChangeAndSendEmail(List < Opportunity > lstOpportunity,Map<Id,sObject> idToOldOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkAccountChangeAndSendEmail()');
        if (Label.Profile_Marketing_Lead_Qualification.equals(objUser.Profile.Name)) {
            ilib_LogEvent.pop();
            return;
        }

        Map<Id,Opportunity> idToSoldToAccountChangeOpp = new Map<Id,Opportunity>(); //Codescan Fix: One Declaration Per line
        Map<Id,Opportunity> idToUCAccountChangeOpp =  new Map<Id,Opportunity>();
        Map<Id,Opportunity> idToDistributorChangeOpp = new Map<Id,Opportunity>();
        List<Apttus_Proposal__Proposal__c> lstQuotes= new List<Apttus_Proposal__Proposal__c>();
        String strSoldToOwnerEmail;
        String strUCOwnerEmail; 
        String strDistOwnerEmail;

        for(Opportunity objOptNew:lstOpportunity) {
            Opportunity objOptOld = (Opportunity)idToOldOpportunity.get(objOptNew.Id);
            if(objOptNew.Billing_Country_Sold_To__c != objOptNew.Billing_Country_Ultimate_Consignee__c
               && objOptOld.Billing_Country_Sold_To__c == objOptOld.Billing_Country_Ultimate_Consignee__c
               && DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objOptNew.RecordtypeId).getDeveloperName()))
                continue; //ignore Direct - Transborder as those will invalidate quotes

            // check if Sold To has changed
            if(String.isNotBlank(objOptNew.AccountId) &&
               objOptNew.AccountId != objOptOld.AccountId) {
                   idToSoldToAccountChangeOpp.put(objOptNew.Id,objOptNew);

               }

            // check if UC has changed
            if(String.isNotBlank(objOptNew.Ultimate_Consignee__c) &&
               objOptNew.Ultimate_Consignee__c != objOptOld.Ultimate_Consignee__c) {
                   idToUCAccountChangeOpp.put(objOptNew.Id,objOptNew);

               }

            //check if Distributor has changed and Direct Sale to Ultimate Consignee is True
            if(String.isNotBlank(objOptNew.Distributor__c) &&
               objOptNew.Distributor__c != objOptOld.Distributor__c) {
                   idToDistributorChangeOpp.put(objOptNew.Id,objOptNew);

               }
        }
        ilib_LogEvent.info('idToSoldToAccountChangeOpp' +  (idToSoldToAccountChangeOpp != Null ? String.valueof(idToSoldToAccountChangeOpp.keySet()):NULLSTR));
        ilib_LogEvent.info('idToUCAccountChangeOpp' +  (idToUCAccountChangeOpp != Null ? String.valueof(idToUCAccountChangeOpp.keySet()):NULLSTR));
        ilib_LogEvent.info('idToDistributorChangeOpp' +  (idToDistributorChangeOpp != Null ? String.valueof(idToDistributorChangeOpp.keySet()):NULLSTR));
        Set<Id> setFilteredOpportunities = new Set<Id>();
        setFilteredOpportunities.addAll(idToSoldToAccountChangeOpp.keySet());
        setFilteredOpportunities.addAll(idToUCAccountChangeOpp.keySet());
        setFilteredOpportunities.addAll(idToDistributorChangeOpp.keySet());
        ilib_LogEvent.info('setFilteredOpportunities ' + setFilteredOpportunities);

        if(setFilteredOpportunities.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }


        List<Opportunity> lstUpdatedOpps = new List<Opportunity>();
        lstUpdatedOpps = new OpportunitySelector().selectOpportunities(setFilteredOpportunities);
        Boolean booIsPortalEnabled = objUser.IsPortalEnabled;
        ilib_LogEvent.info('booIsPortalEnabled ' + booIsPortalEnabled);
        if(booIsPortalEnabled!=true)      //to bypass quote/apttus updates for channel partner users
        {
            lstQuotes =new ApttusProposalsSelector().selectValidQuote(setFilteredOpportunities);
            //only if Valid Quotes Exist then run the logic
            if(!lstQuotes.isEmpty()) {
                for(Opportunity opp : lstUpdatedOpps) {

                        if(idToSoldToAccountChangeOpp.containsKey(opp.Id)) {
                            strUCOwnerEmail = opp.Ultimate_Consignee__r.Owner.Id;
                            ilib_LogEvent.message('strUCOwnerEmail ' + strUCOwnerEmail);
                            AutomateEmailMethodOnAccountChange.sendEmailOnAccountChange(strUCOwnerEmail,Label.DeveloperName_Sold_To_Template,opp.Id);
                        }
                        if(idToUCAccountChangeOpp.containsKey(opp.Id)) {
                            strSoldToOwnerEmail = opp.Account.Owner.Id;
                            ilib_LogEvent.message('strSoldToOwnerEmail ' + strSoldToOwnerEmail);
                            AutomateEmailMethodOnAccountChange.sendEmailOnAccountChange(strSoldToOwnerEmail,Label.Opportunity_UC_Change_Template,opp.Id);
                        }
                        if(idToDistributorChangeOpp.containsKey(opp.Id)) {
                            strDistOwnerEmail = opp.Account.Owner.Id;
                            ilib_LogEvent.message('strDistOwnerEmail ' + strDistOwnerEmail);
                            AutomateEmailMethodOnAccountChange.sendEmailOnAccountChange(strDistOwnerEmail,Label.Opportunity_Distributor_Change_Template,opp.Id);
                        }
                    }
                }
        }

        ilib_LogEvent.pop();

    }

    /*
    * @description Method to update Is Updated by system and ultimate consignee when lead is converted
    */
    public static void populateOpportunityFieldsWhileleadconversion(List < Opportunity > lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.populateOpportunityFieldsWhileleadconversion()');
        for(Opportunity objOpp: lstOpportunity)
        {    
            setOpportunityAttributesforLeadConversion(objOpp);
            setRecordTypeName(objOpp, null); // Method to resolve Incident INC0419938
            setLeadSource(objOpp, null); // Method to resolve Incident INC0419938
            setEstimatedCloseDate(objOpp, null); //Method to resolve Incident INC0419938
        }
        ilib_LogEvent.pop();
    }

    /**
    *  @description Update the Quotes based on change of Ultimate Consignee(Ship To) and Account(Bill To)
    **/
    private void checkSoldToOrUltimateConsigneeChange(List<Opportunity> lstOpportunity, Map<Id, sObject> mapIdToOldOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkSoldToOrUltimateConsigneeChange()');
        if (Label.Profile_Marketing_Lead_Qualification.equals(objUser.Profile.Name)) {
            ilib_LogEvent.pop();
            return;
        }

        // This method should be moved to automate bill to ship to out of opportunties, this will be taken up in August release
        Map<Id, Opportunity> idToSoldToAccountChangeOpp = new Map<Id, Opportunity>(); 
        Map<Id, Opportunity> idToUCAccountChangeOpp = new Map<Id,Opportunity>(); 
        Map<Id, Opportunity> idToDistributorChangeOpp = new Map<Id, Opportunity>();
        Map<Id, String> distributorIdToUCERPId= new  Map<Id, String>();
        Set<Id> setAccounts = new Set<Id>();
        Set<String> setPriceLists = new Set<String>();

        Set<Id> setDistributorId = new Set<Id>();
        List<Account_Sales_Area__c> lstAccountSalesArea = new List<Account_Sales_Area__c>();
        Map<String, List<Account_Sales_Area__c>> mapUCERPToDistSalesArea = new Map<String, List<Account_Sales_Area__c>>();

        for(Opportunity objOptNew : lstOpportunity)
        {
            
            Opportunity objOptOld = (Opportunity)mapIdToOldOpportunity.get(objOptNew.Id);
            ilib_LogEvent.message('objOptOld' + objOptOld);
            if (objOptNew.Billing_Country_Sold_To__c != objOptNew.Billing_Country_Ultimate_Consignee__c
               && objOptOld.Billing_Country_Sold_To__c == objOptOld.Billing_Country_Ultimate_Consignee__c
               && DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objOptNew.RecordtypeId).getDeveloperName())
            )
                continue; //ignore Direct - Transborder as those will invalidate quotes

            //check if Sold To has changed
            if (String.isNotBlank(objOptNew.AccountId)
                    && objOptNew.AccountId != objOptOld.AccountId
            ) {
                idToSoldToAccountChangeOpp.put(objOptNew.Id,objOptNew);
                setAccounts.add(objOptNew.AccountId);
            }

            //check if UC has changed
            if (String.isNotBlank(objOptNew.Ultimate_Consignee__c)
                    && objOptNew.Ultimate_Consignee__c != objOptOld.Ultimate_Consignee__c
            ) {
                idToUCAccountChangeOpp.put(objOptNew.Id,objOptNew);
                setAccounts.add(objOptNew.Ultimate_Consignee__c);
                setDistributorId.add(objOptNew.Distributor__c);
            }

            //check if Distributor has changed
            if (String.isNotBlank(objOptNew.Distributor__c)
                    && objOptNew.Distributor__c != objOptOld.Distributor__c
            ) {
                idToDistributorChangeOpp.put(objOptNew.Id,objOptNew);
                if (objOptNew.Direct_Sale_to_Ultimate_Consignee__c)
                    idToUCAccountChangeOpp.put(objOptNew.Id,objOptNew);
                setAccounts.add(objOptNew.Distributor__c);
                setAccounts.add(objOptNew.Ultimate_Consignee__c);
                setDistributorId.add(objOptNew.Distributor__c);
            }

            //check if pricelist has changed
            if (String.isNotBlank(objOptNew.Price_List__c)
                    && objOptNew.Price_List__c != objOptOld.Price_List__c
            ) {
                setPriceLists.add(objOptNew.Price_List__c);
            }
        }

        ilib_LogEvent.info('idToSoldToAccountChangeOpp' + (idToSoldToAccountChangeOpp != Null ? String.valueof(idToSoldToAccountChangeOpp.keySet()):NULLSTR));
        ilib_LogEvent.info('idToUCAccountChangeOpp' + (idToUCAccountChangeOpp != Null ? String.valueof(idToUCAccountChangeOpp.keySet()):NULLSTR));
        ilib_LogEvent.info('idToDistributorChangeOpp' + (idToDistributorChangeOpp != Null ? String.valueof(idToDistributorChangeOpp.keySet()):NULLSTR));
        ilib_LogEvent.info('distributorIdToUCERPId' +  distributorIdToUCERPId);
        ilib_LogEvent.info('setAccounts:' +  setAccounts);
        ilib_LogEvent.info('setPriceLists:' +  setPriceLists);

        //don't proceed if nothing found
        if (setAccounts.isEmpty()) {
            ilib_LogEvent.pop();
            return;
        }


        Map<Id, Account> idToAccount = new Map<Id, Account>(new AccountsSelector().selectAccounts(setAccounts));
        ilib_LogEvent.info('idToAccount' + (idToAccount != Null ? String.valueof(idToAccount.keySet()):NULLSTR));


        //store consolidated Opportunity ids which have either the sold to or UC changed or Distributor Changed
        Set<Id> setFilteredOpportunities = new Set<Id>();
        setFilteredOpportunities.addAll(idToSoldToAccountChangeOpp.keySet());
        setFilteredOpportunities.addAll(idToUCAccountChangeOpp.keySet());
        setFilteredOpportunities.addAll(idToDistributorChangeOpp.keySet());
        ilib_LogEvent.info('setFilteredOpportunities: ' +  setFilteredOpportunities);


        Map<Id, Opportunity> filteredIdToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setFilteredOpportunities));
        //will come here only if some records need to be updated.
        Map<Id, Apttus_Proposal__Proposal__c> idToProposal = new Map<Id, Apttus_Proposal__Proposal__c>();

        //Set to store Quote Stages
        Set<String> setQuoteStage = new Set<String>{
            System.Label.QuotationApprovalStatusApproved,
            System.Label.QuoteStageGenerated,
            System.Label.QuoteStagePresented};

        //map of erp ids to proposal
        Map<String, List<Apttus_Proposal__Proposal__c>> soldToERPIdToProposal = new Map<String, List<Apttus_Proposal__Proposal__c>>(),
            ucERPIdToProposal = new Map<String,List<Apttus_Proposal__Proposal__c>>();

        Map<String, String> soldToERPToSAERP = new Map<String, String>();
        Map<String, String> ucERPToSAERP = new Map<String, String>();
        Map<String, String> accountERPToCountry = new Map<String, String>();

        Boolean booIsPortalEnabled = objUser.IsPortalEnabled;
        ilib_LogEvent.info('booIsPortalEnabled: ' +  booIsPortalEnabled);


        if (!booIsPortalEnabled) //By pass Qoutes for channel partner users
        {
            List<Apttus_Proposal__Proposal__c> lstValidQuotes = new ApttusProposalsSelector().selectValidQuote(setFilteredOpportunities);

            if(lstValidQuotes.isEmpty()){
                ilib_LogEvent.pop();
                return;
            }

            //Map of Pricelist names with Id
            Map<String, Apttus_Config2__PriceList__c> mpNameToPriceLists =  new ApttusPriceListsSelector().selectActive(setPriceLists);
            ilib_LogEvent.info('mpNameToPriceLists' + (mpNameToPriceLists != Null ? String.valueof(mpNameToPriceLists.keySet()):NULLSTR));
            for (Apttus_Proposal__Proposal__c objProposal : lstValidQuotes)
            {
                // Add all Sold To Change related Approved,Generated and Presented Quotes
                if (idToSoldToAccountChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c) && setQuoteStage.contains(objProposal.Apttus_Proposal__Approval_Stage__c))
                    AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,APTTUS_PROPOSAL_APPROVAL_STAGE,System.Label.QuoteStageDenied);

                // Add all UC Change related Approved,Generated and Presented Quotes
                if (idToUCAccountChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c) && setQuoteStage.contains(objProposal.Apttus_Proposal__Approval_Stage__c))
                    AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,APTTUS_PROPOSAL_APPROVAL_STAGE,System.Label.QuoteStageDenied);

                // Add all Distributor Change related Approved,Generated and Presented Quotes
                if (idToDistributorChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c)
                   && setQuoteStage.contains(objProposal.Apttus_Proposal__Approval_Stage__c)
                ) {
                    AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,APTTUS_PROPOSAL_APPROVAL_STAGE,System.Label.QuoteStageDenied);
                }

                if (!(Label.QuoteStageDraft.equals(objProposal.Apttus_Proposal__Approval_Stage__c)
                     || Label.QuoteApprovalStatusNone.equals(objProposal.Apttus_Proposal__Approval_Stage__c)
                     || Label.ProposalApprovalStatusApprovalRequired.equals(objProposal.Apttus_Proposal__Approval_Stage__c))
                )
                    continue;//if not submitted proposal then only proceed with next records

                Account account = OpportunitiesHelper.getAccountIdBasedOnProposal(objProposal);

                // get all Distributor change related Quotes
                if (idToDistributorChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c))
                {
                    String strPriceListName = idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Price_List__c;
                    ilib_LogEvent.message('strPriceListName : '+strPriceListName);
                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageDraft)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, DISTRIBUTOR, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__r); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,DISTRIBUTOR,idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__c);
                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__c, objProposal);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Contract_Numbers__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c);
                        if(String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Apttus_QPConfig__PriceListId__c',mpNameToPriceLists.get(strPriceListName).Id);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Sales_Organization__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Distribution_Channel__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Division__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c);
                    }

                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageApprovalRequired)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, DISTRIBUTOR, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__r); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,DISTRIBUTOR,idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__c);
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,APTTUS_PROPOSAL_APPROVAL_STAGE,System.Label.QuoteStageDraft);
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Apttus_QPApprov__Approval_Status__c',System.Label.QuoteApprovalStatusNone);

                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Distributor__c, objProposal);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Contract_Numbers__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c);
                        if(String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Apttus_QPConfig__PriceListId__c',mpNameToPriceLists.get(strPriceListName).Id);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Sales_Organization__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Distribution_Channel__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c);
                        if(String.isNotBlank(idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                            AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Sold_To_Division__c',idToDistributorChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c);
                    }

                    Opportunity objOpp = filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c);
                    ilib_LogEvent.message('objOpp.Distributor__c:' + objOpp.Distributor__c);
                    if (!DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objOpp.RecordtypeId).getDeveloperName()) && !objOpp.Direct_Sale_to_Ultimate_Consignee__c)
                    {
                        Account objAccount = idToAccount.get(objOpp.Distributor__c);
                        ilib_LogEvent.message('objAccount:' + objAccount);
                        ilib_LogEvent.message('objAccount ERP_Customer_Id__c:' + objAccount.ERP_Customer_Id__c);
                        if (String.isNotBlank(objAccount.ERP_Customer_Id__c))
                        {
                            if (ucERPIdToProposal.containsKey(objAccount.ERP_Customer_Id__c))
                                ucERPIdToProposal.get(objAccount.ERP_Customer_Id__c).add(objProposal);
                            else
                                ucERPIdToProposal.put(objAccount.ERP_Customer_Id__c, new List<Apttus_Proposal__Proposal__c>{objProposal});

                            ucERPToSAERP.put(objAccount.ERP_Customer_Id__c,objOpp.Sales_Area_Distributor__c);
                        }
                    }

                    if (!DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objOpp.RecordtypeId).getDeveloperName()) && objOpp.Direct_Sale_to_Ultimate_Consignee__c)
                    {
                        if(String.isNotBlank(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c))
                            distributorIdToUCERPId.put(objOpp.Distributor__c,objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c);
                    }
                }

                // get all sold To change related Quotes
                if (idToSoldToAccountChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c))
                {
                    String strPriceListName = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Price_List__c;
                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageDraft)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, ACCOUNT_ID, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Account); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal, objProposal, 'Apttus_Proposal__Account__c', idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).AccountId);

                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).AccountId, objProposal);
                        if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            objProposal.Contract_Numbers__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c;
                        if (String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;

                        if (DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objProposal.Apttus_Proposal__Opportunity__r.RecordtypeId).getDeveloperName()))
                        {
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                                objProposal.Sold_To_Sales_Organization__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c;
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                                objProposal.Sold_To_Distribution_Channel__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c;
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                                objProposal.Sold_To_Division__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c;
                        }
                    }

                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageApprovalRequired)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, ACCOUNT_ID, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Account); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,'Apttus_Proposal__Account__c',idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).AccountId);

                        objProposal.Apttus_Proposal__Approval_Stage__c = System.Label.QuoteStageDraft;
                        objProposal.Apttus_QPApprov__Approval_Status__c = System.Label.QuoteApprovalStatusNone;

                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).AccountId, objProposal);
                        if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            objProposal.Contract_Numbers__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c;
                        if (String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;
                        if (DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objProposal.Apttus_Proposal__Opportunity__r.RecordtypeId).getDeveloperName())) {
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                                objProposal.Sold_To_Sales_Organization__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c;
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                                objProposal.Sold_To_Distribution_Channel__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c;
                            if (String.isNotBlank(idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                                objProposal.Sold_To_Division__c = idToSoldToAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c;
                        }
                    }

                    Opportunity objOpp = filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c);
                    ilib_LogEvent.message(OBJOPPSTR + objOpp);
                    ilib_LogEvent.message('erp id:' + objOpp.Account.ERP_Customer_Id__c);
                    ilib_LogEvent.message('account object via map:' + idToAccount.get(objOpp.AccountId));
                    ilib_LogEvent.message('erp id via map:' + idToAccount.get(objOpp.AccountId).ERP_Customer_Id__c);


                    String strERPId = idToAccount.get(objOpp.AccountId).ERP_Customer_Id__c;
                    ilib_LogEvent.message('strERPId:' + strERPId);

                    if(String.isNotBlank(strERPId))
                    {
                        if (soldToERPIdToProposal.containsKey(strERPId))
                            soldToERPIdToProposal.get(strERPId).add(objProposal);
                        else
                            soldToERPIdToProposal.put(strERPId, new List<Apttus_Proposal__Proposal__c>{objProposal});

                        soldToERPToSAERP.put(strERPId,objOpp.Sales_Area_Sold_To__c);
                    }
                }

                // get all UC change related Quotes
                if (idToUCAccountChangeOpp.containsKey(objProposal.Apttus_Proposal__Opportunity__c))
                {
                    String strPriceListName = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Price_List__c;
                    ilib_LogEvent.message('strPriceListName : '+strPriceListName);
                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageDraft)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, ULTIMATE_CONSIGNEE, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__r); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,ULTIMATE_CONSIGNEE,idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c);

                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c, objProposal);
                        if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            objProposal.Contract_Numbers__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c;
                        if (String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;
                        if (DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objProposal.Apttus_Proposal__Opportunity__r.RecordtypeId).getDeveloperName()))
                        {
                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                                objProposal.Sold_To_Sales_Organization__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c;
                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                                objProposal.Sold_To_Distribution_Channel__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c;
                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                                objProposal.Sold_To_Division__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c;
                        }
                    }

                    if (objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageApprovalRequired)
                    {
                        updateBUAndSubRegionSoldTOUCDist(idToProposal, objProposal, ULTIMATE_CONSIGNEE, filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__r); //TASK0876760
                        AutomateBillToShipToService.setProposalValue(idToProposal,objProposal,ULTIMATE_CONSIGNEE,idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c);
                        
                        objProposal.Approval_Hierarchy_Record_Owner__c = getApprovalHierarchyOwner(account, idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Ultimate_Consignee__c, objProposal);
                        if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c))
                            objProposal.Contract_Numbers__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Contract_Number__c;
                        if (String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName))
                            objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;
                        if (objProposal.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName == System.Label.OpportunityRTDirectFieldServices
                            || objProposal.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName == System.Label.OpportunityRTDirectReOrder
                            || objProposal.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName == System.Label.OpportunityRTDirectStandard
                        ) {
                            objProposal.Apttus_Proposal__Approval_Stage__c = System.Label.QuoteStageDraft;
                            objProposal.Apttus_QPApprov__Approval_Status__c = System.Label.QuoteApprovalStatusNone;

                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c))
                                objProposal.Sold_To_Sales_Organization__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Sales_Organization__c;
                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c))
                                objProposal.Sold_To_Distribution_Channel__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Distribution_Channel__c;
                            if (String.isNotBlank(idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c))
                                objProposal.Sold_To_Division__c = idToUCAccountChangeOpp.get(objProposal.Apttus_Proposal__Opportunity__c).Sold_to_Division__c;
                        }
                    }
                    ilib_LogEvent.message('objProposal : '+objProposal);
                    Opportunity objOpp = filteredIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c);
                    ilib_LogEvent.message(OBJOPPSTR+objOpp);
                    Account objAccount = idToAccount.get(objOpp.Ultimate_Consignee__c);
                    ilib_LogEvent.message('objAccount : '+objAccount);
                    if (String.isNotBlank(objAccount.ERP_Customer_Id__c))
                    {
                        if (ucERPIdToProposal.containsKey(objAccount.ERP_Customer_Id__c))
                            ucERPIdToProposal.get(objAccount.ERP_Customer_Id__c).add(objProposal);
                        else
                            ucERPIdToProposal.put(objAccount.ERP_Customer_Id__c, new List<Apttus_Proposal__Proposal__c>{objProposal});

                        ucERPToSAERP.put(objAccount.ERP_Customer_Id__c,objOpp.Sales_Area_Ultimate_Consignee__c);
                        accountERPToCountry.put(objAccount.ERP_Customer_Id__c,objAccount.BillingCountry);
                    }

                    if (!DIRECT_RECORD_TYPES.contains(getIdToRecordType().get(objOpp.RecordtypeId).getDeveloperName()) && objOpp.Direct_Sale_to_Ultimate_Consignee__c)
                        if (String.isNotBlank(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c))
                            distributorIdToUCERPId.put(objOpp.Distributor__c,objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c);
                }
            }
        }

        Set<Id> setDistributorIds = new Set<Id>();
        setDistributorIds = distributorIdToUCERPId.keyset();
        if (!setDistributorIds.isEmpty())
        {
            lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setDistributorIds);
            

            for (Account_Sales_Area__c asa : lstAccountSalesArea)
            {
                String strUCERPId = distributorIdToUCERPId.get(asa.Account__c);
                if(mapUCERPToDistSalesArea.containsKey(strUCERPId))
                    mapUCERPToDistSalesArea.get(strUCERPId).add(asa);
                else
                   mapUCERPToDistSalesArea.put(strUCERPId,new List<Account_Sales_Area__c> {asa});
            }
        }
        ilib_LogEvent.info('soldToERPIdToProposal' + (soldToERPIdToProposal != Null ? String.valueof(soldToERPIdToProposal.keySet()):NULLSTR));
        ilib_LogEvent.info('ucERPIdToProposal' + (ucERPIdToProposal != Null ? String.valueof(ucERPIdToProposal.keySet()):NULLSTR));
        ilib_LogEvent.info('soldToERPToSAERP' + soldToERPToSAERP);
        ilib_LogEvent.info('ucERPToSAERP' + ucERPToSAERP);
        ilib_LogEvent.info('accountERPToCountry' + accountERPToCountry);
        ilib_LogEvent.info('idToProposal' + (idToProposal != Null ? String.valueof(idToProposal.keySet()):NULLSTR));
        ilib_LogEvent.info('mapUCERPToDistSalesArea' + (mapUCERPToDistSalesArea != Null ? String.valueof(mapUCERPToDistSalesArea.keySet()):NULLSTR));

        Map<Id, Apttus_Proposal__Proposal__c> idToUpdateProposal = AutomateBillToShipToService.setBillToShipTo(soldToERPIdToProposal, ucERPIdToProposal, mapUCERPToDistSalesArea, soldToERPToSAERP, ucERPToSAERP, accountERPToCountry,filteredIdToOpportunity);
        ilib_LogEvent.info('idToUpdateProposal' + (idToUpdateProposal != Null ? String.valueof(idToUpdateProposal.keySet()):NULLSTR));
        List<Apttus_Proposal__Proposal__c> lstProposals = new List<Apttus_Proposal__Proposal__c>();

        if (idToUpdateProposal != null)
        {
            Set<Id> setIdUpdatedProposal = idToUpdateProposal.keySet();
            lstProposals.addAll(idToUpdateProposal.values());

            for (Id quoId:idToProposal.keySet())
                if (!setIdUpdatedProposal.contains(quoId))
                    lstProposals.add(idToProposal.get(quoId));
        }
        else
        {
            lstProposals = idToProposal.values();
        }

        if(!lstProposals.isEmpty())
            update lstProposals;


        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-40024 Create Contact role for opportunitites created by Partners
     * After insert trigger method
     **/
    private void createContactRoleForPartnersCreatedRecords(List<Opportunity> opportunities) {
        ilib_LogEvent.push(LOG_TITLE + '.createContactRoleForPartnersCreatedRecords()');
        List<OpportunityContactRole> lstOpportunityContactRoles = new List<OpportunityContactRole>();

        if(objUser.IsPortalEnabled) {
            for(Opportunity objOpp : opportunities) {
                OpportunityContactRole ocr = new OpportunityContactRole(ContactId = objUser.ContactId,
                                                                        OpportunityId = objOpp.id,
                                                                        IsPrimary = true);
                lstOpportunityContactRoles.add(ocr);
            }
        }
    
        if(!lstOpportunityContactRoles.isEmpty()) {
            OpportunityContactRoles.isConRoleCreatedFromOpp = true;
            List<Database.SaveResult> srCreateOppConRole = Database.insert(lstOpportunityContactRoles,false);
            ApexExceptions.emitSaveErrors(srCreateOppConRole, STRING_OPPORTUNITIES);
        }
        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-40024 populate primary Contact for opportunitites created by Partners
     * Before insert trigger method
     **/
    private void addPrimaryContactForPartnersCreatedRecords(List<Opportunity> opportunities) {
        ilib_LogEvent.push(LOG_TITLE + '.addPrimaryContactForPartnersCreatedRecords()');
        if(objUser.IsPortalEnabled) {
            for(Opportunity objOpp : opportunities) {
                objOpp.Primary_Contact__c = objUser.ContactId;
                objOpp.Is_Contact_Role_Identified__c = true;
                ilib_LogEvent.message('objOpp.Primary_Contact__c : '+objOpp.Primary_Contact__c);
                ilib_LogEvent.message('objOpp.Is_Contact_Role_Identified__c : '+objOpp.Is_Contact_Role_Identified__c);
            }
        }
        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-29588 populate primary Contact on quotes if same is changed on opty
     * After update trigger method
     **/
    private void updateContactOnQuotes(List<Opportunity> lstOpps, Map<Id, Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.updateContactOnQuotes()');
        if(objUser.IsPortalEnabled){
            ilib_LogEvent.pop();
            return;
        }

        set<Id> setOppIds = new set<Id>();
        Map<Id,Id> idOppToIdPrimaryContact = new Map<Id,Id>();
        List<Apttus_Proposal__Proposal__c> lstPropsToUpdate = new List<Apttus_Proposal__Proposal__c>();

        for(Opportunity objOpp : lstOpps) {
            Opportunity objOldOpp = idToOldOpps.get(objOpp.Id);
            if(objOldOpp.Primary_Contact__c != objOpp.Primary_Contact__c) {
                setOppIds.add(objOpp.Id);
                idOppToIdPrimaryContact.put(objOpp.Id, objOpp.Primary_Contact__c);
            }
        }
        ilib_LogEvent.info('setOppIds : '+ setOppIds);
        ilib_LogEvent.info('idOppToIdPrimaryContact' + idOppToIdPrimaryContact);
        if(setOppIds.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }
        for(Apttus_Proposal__Proposal__c objProp : new ApttusProposalsSelector().selectValidQuote(setOppIds)) {
            Id idPrimaryCon = idOppToIdPrimaryContact.get(objProp.Apttus_Proposal__Opportunity__c);
            ilib_LogEvent.message('idPrimaryCon : '+idPrimaryCon);
            if(objProp.Apttus_Proposal__Primary_Contact__c != idPrimaryCon && objProp.Apttus_Proposal__Approval_Stage__c != ApttusProposals.APPROVAL_STAGE_DENIED) {
                objProp.Apttus_Proposal__Primary_Contact__c = idPrimaryCon;
                lstPropsToUpdate.add(objProp);
            }
        }
        
        if(!lstPropsToUpdate.isEmpty()) {
            ApttusProposals.isQuoteUpdatedFromOpty = true;
            List<Database.SaveResult> srUpdateProps = Database.update(lstPropsToUpdate,false);
            ApexExceptions.emitSaveErrors(srUpdateProps, STRING_OPPORTUNITIES);
        }
        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40569 and 40570 update opty name if close date is changed
     * before update trigger method
     **/
    public void updateStandingQuoteOppDate(List<Opportunity> lstOpps, Map<Id,Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.updateStandingQuoteOppDate()');
        List<Opportunity> lstLWCSQOpps = new List<Opportunity>();
        List<Opportunity> lstStdSQOpps = new List<Opportunity>();

        for(Opportunity opp : lstOpps) {
            Opportunity oldOpp=null;
            if(idToOldOpps != null)
                oldOpp = idToOldOpps.get(opp.Id);

            if(opp.recordTypeId == RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId() && (Trigger.isInsert || (Trigger.isUpdate && (opp.CloseDate != oldOpp.CloseDate || opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_WON)))) {
                if(Trigger.isInsert && !opp.isClone() && opp.Fiscal_Quarter__c != null)
                    lstLWCSQOpps.add(opp);
                else {
                    lstStdSQOpps.add(opp);
                }
            }
        }
        if(lstLWCSQOpps.isEmpty() && lstStdSQOpps.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        lstPeriod = [SELECT Id, StartDate,EndDate FROM Period WHERE Type = 'Quarter' AND EndDate >=: Date.today() ORDER BY EndDate];
        ilib_LogEvent.info('lstPeriod : '+UtilsCollection.getSetOfIds(lstPeriod));
        for(Opportunity opp : lstLWCSQOpps) {
            if(opp.Fiscal_Quarter__c == LSTFISCALQUARTERS[0]) {
                opp.Last_Date_Of_Quarter__c = lstPeriod[0].EndDate;
                opp.CloseDate = lstPeriod[0].EndDate;
            }
            else if(opp.Fiscal_Quarter__c == LSTFISCALQUARTERS[1]) {
                opp.Last_Date_Of_Quarter__c = lstPeriod[1].EndDate;
                opp.CloseDate = lstPeriod[1].EndDate;
            }
            else if(opp.Fiscal_Quarter__c == LSTFISCALQUARTERS[2]) {
                opp.Last_Date_Of_Quarter__c = lstPeriod[2].EndDate;
                opp.CloseDate = lstPeriod[2].EndDate;
            }
            else if(opp.Fiscal_Quarter__c == LSTFISCALQUARTERS[3]) {
                opp.Last_Date_Of_Quarter__c = lstPeriod[3].EndDate;
                opp.CloseDate = lstPeriod[3].EndDate;
            }
            ilib_LogEvent.message(' opp.Last_Date_Of_Quarter__c : '+ opp.Last_Date_Of_Quarter__c);
            ilib_LogEvent.message(' opp.CloseDate : '+ opp.CloseDate);
        }
        for(Opportunity opp : lstStdSQOpps) {
            for(integer i = 0 ; i < lstPeriod.size() ; i++) {
                Period objPeriod = lstPeriod[i];
                ilib_LogEvent.fine('objPeriod : '+objPeriod);
                if(objPeriod.StartDate <= opp.CloseDate && objPeriod.EndDate >= opp.CloseDate) {
                    opp.Last_Date_of_Quarter__c = objPeriod.EndDate;
                    ilib_LogEvent.fine('opp.Last_Date_of_Quarter__c : '+opp.Last_Date_of_Quarter__c);
                    break;
                }
            }
        }
        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40569 add error if opp for same quarter for a standing quote agreement is present
     * Before insert trigger method
     **/
    public void preventStandingQuoteOppsInSameAgreementANDAccountANDQuarter(List<Opportunity> lstOpps, Map<Id,Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.preventStandingQuoteOppsInSameAgreementANDAccountANDQuarter()');
        Set<Id> agreementIds = New Set<Id>();
        Set<Id> accountIds = New Set<Id>();
        Set<Date> setLastDateOfQuarters = new Set<Date>();
        Set<String> setOppUnique = new Set<String>();
        Set<Id> setStandingQuoteOppIds = New Set<Id>();
        List<Opportunity> lstStandingQuoteOpps = New List<Opportunity>();

        if(numToMonth == null) {
            numToMonth = createMonthToQuarterMap();
            ilib_LogEvent.info('numToMonth : '+numToMonth);
        }
        if(lstPeriod == null){
            lstPeriod = [SELECT Id, StartDate,EndDate FROM Period WHERE Type = 'Quarter' AND EndDate >=: Date.today() ORDER BY EndDate];
        }
        for(Opportunity opp : lstOpps) {
            Opportunity oldOpp;
            if(idToOldOpps != null)
                oldOpp = idToOldOpps.get(opp.Id);

            if(opp.recordTypeId == RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId()) {
                if(Trigger.isInsert || (Trigger.isUpdate && (opp.Related_Agreement__c != oldOpp.Related_Agreement__c || opp.AccountId != oldOpp.AccountId || opp.CloseDate != oldOpp.CloseDate || opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_WON))) {
                    if(opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED)
                        continue;
                    agreementIds.add(opp.Related_Agreement__c);
                    accountIds.add(opp.AccountId);
                    setStandingQuoteOppIds.add(opp.Id);
                    lstStandingQuoteOpps.add(opp);
                    if(opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_WON) {
                        setLastDateOfQuarters.add(lstPeriod[0].EndDate);
                    }
                    else {
                        setLastDateOfQuarters.add(opp.Last_Date_of_Quarter__c);
                    }
                }
            }
        }
        ilib_LogEvent.info('agreementIds : '+ agreementIds);
        ilib_LogEvent.info('accountIds : '+ accountIds);
        ilib_LogEvent.info('setLastDateOfQuarters : '+ setLastDateOfQuarters);
        ilib_LogEvent.info('setStandingQuoteOppIds : '+ setStandingQuoteOppIds);
        if(lstStandingQuoteOpps.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        for(Opportunity opty : new OpportunitySelector().selectOpportunitiesByAgreementIdsAccIdsClosedates(agreementIds,accountIds,setLastDateOfQuarters,setStandingQuoteOppIds)) {
            String strOptyUnique = String.valueOf(opty.Related_Agreement__c).substring(0,15) + '_' + String.valueOf(opty.AccountId).substring(0,15) + '_' + opty.Last_Date_of_Quarter__c;
            setOppUnique.add(strOptyUnique);
        }
        ilib_LogEvent.info('setOppUnique : '+ setOppUnique);
        for(Opportunity opp : lstStandingQuoteOpps) {
            if(String.isNotBlank(opp.Related_Agreement__c)){
                String strOppUnique = String.valueOf(opp.Related_Agreement__c).substring(0,15) + '_' + String.valueOf(opp.AccountId).substring(0,15) + '_' + ((opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_WON) ? lstPeriod[0].EndDate : opp.Last_Date_of_Quarter__c);
                ilib_LogEvent.message('lstStandingQuoteOpps'+strOppUnique+'=='+setOppUnique);
                if(setOppUnique.contains(strOppUnique)){
                    opp.addError(Label.UI_Error_StandingOppSameQuarter);
                }
            }
        }

        ilib_LogEvent.pop();
    }

/**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40569 and 40570 add error if standing quote agreement is not related to the account being added
     * before update trigger method
     **/
    public void preventIncorrectAccountOnStandingQuoteOpps(List<Opportunity> lstOpps, Map<Id,Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.preventIncorrectAccountOnStandingQuoteOpps()');
        Set<Id> setAgreementIds = New Set<Id>();
        List<Opportunity> lstStandingQuoteOpps = New List<Opportunity>();

        for(Opportunity opp : lstOpps) {
            Opportunity oldOpp;
            if(idToOldOpps != null)
                oldOpp = idToOldOpps.get(opp.Id);
            if(opp.recordTypeId == RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId() && ((Trigger.isInsert && opp.isClone()) || (Trigger.isUpdate && (opp.AccountId != oldOpp.AccountId || opp.Related_Agreement__c != oldOpp.Related_Agreement__c)))) {
                setAgreementIds.add(opp.Related_Agreement__c);
                lstStandingQuoteOpps.add(opp);
            }
        }
        ilib_LogEvent.info('setAgreementIds : '+ setAgreementIds);
        if(setAgreementIds.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        List<Agreement_Account_Relationship__c> lstAgmtAccRelation = new AgreementAccountRelationshipSelectors().selectByAgreementId(setAgreementIds);
        Map<Id,Set<Id>> idAgmtToLstOfIdAcc =  UtilsCollection.getMapOfIdToIds(lstAgmtAccRelation, 'Agreement__c', 'Account__c');
        ilib_LogEvent.info('idAgmtToLstOfIdAcc' + (idAgmtToLstOfIdAcc != Null ? String.valueof(idAgmtToLstOfIdAcc.keySet()):NULLSTR));
        for(Opportunity opp : lstStandingQuoteOpps) {
            Set<Id> setAccIdsRelatedToAgmt = idAgmtToLstOfIdAcc.get(opp.Related_Agreement__c);
            ilib_LogEvent.message('setAccIdsRelatedToAgmt : '+ setAccIdsRelatedToAgmt);
            System.debug(LoggingLevel.ERROR, 'opp: ' + opp);
            System.debug(LoggingLevel.ERROR, 'setAccIdsRelatedToAgmt: ' + setAccIdsRelatedToAgmt);
            System.debug(LoggingLevel.ERROR, 'opp.AccountId: ' + opp.AccountId);
            if(setAccIdsRelatedToAgmt != null && !setAccIdsRelatedToAgmt.contains(opp.AccountId)) {
                opp.addError(Label.UI_Error_StandingOppWrongAccount);
            }
        }
        ilib_LogEvent.pop();
    }

    /**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40569 and 40570 update opty name if close date is changed
     * before update trigger method
     **/
    public void updateStandingQuoteOppName(List<Opportunity> lstOpps, Map<Id,Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.updateStandingQuoteOppName()');
        List<Opportunity> lstStandingQuoteOpps = New List<Opportunity>();
        Set<Id> setAgreementIds = New Set<Id>();
        Set<Id> setAccountIds = New Set<Id>();


        for(Opportunity opp : lstOpps) {
            Opportunity oldOpp;
            if(idToOldOpps != null)
                oldOpp = idToOldOpps.get(opp.Id);

            if(opp.recordTypeId == RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId()) {
                 if(Trigger.isInsert || (Trigger.isUpdate && (opp.CloseDate != oldOpp.CloseDate || opp.AccountId != oldOpp.AccountId || opp.Related_Agreement__c != oldOpp.Related_Agreement__c  || opp.StageName == STRING_OPPORTUNITY_STAGE_CLOSED_WON))) {
                    lstStandingQuoteOpps.add(opp);
                    setAgreementIds.add(opp.Related_Agreement__c);
                    setAccountIds.add(opp.AccountId);

                    if(Trigger.isUpdate) {
                        setAgreementIds.add(oldOpp.Related_Agreement__c);
                        setAccountIds.add(oldOpp.AccountId);
                    }
                }
            }
        }
        ilib_LogEvent.info('setAgreementIds : '+ setAgreementIds);
        ilib_LogEvent.info('setAccountIds : '+ setAccountIds);
        if(lstStandingQuoteOpps.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        Map<Id,Account> idToAcc = new Map<Id,Account> (new AccountsSelector().selectAccounts(setAccountIds));
        Map<Id,  Apttus__APTS_Agreement__c> idToAgmt = new Map<Id,Apttus__APTS_Agreement__c> (new ApttusAgreementSelectors().selectAgreements(setAgreementIds));
        ilib_LogEvent.info('idToAcc' + (idToAcc != Null ? String.valueof(idToAcc.keySet()):NULLSTR));
        ilib_LogEvent.info('idToAgmt' + (idToAgmt != Null ? String.valueof(idToAgmt.keySet()):NULLSTR));

        if(numToMonth == null) {
            numToMonth = createMonthToQuarterMap();
        }

        for(Opportunity opp : lstStandingQuoteOpps) {
            opp.CurrencyIsoCode = idToAcc.get(opp.AccountId).CurrencyIsoCode;//update opp currency based on Account's currency
            ilib_LogEvent.message('opp.CurrencyIsoCode : '+opp.CurrencyIsoCode);
            if(Trigger.isInsert) {
                opp.Name = getOppFormattedName(opp, idToAgmt.get(opp.Related_Agreement__c).Name, idToAcc.get(opp.AccountId).Name, numToMonth);
            }
            else if(Trigger.isUpdate) {
                Opportunity oldOpp = idToOldOpps.get(opp.Id);
                if(String.isNotBlank(oldOpp.Related_Agreement__c)){
                    String oldOppFormattedName = getOppFormattedName(oldOpp, idToAgmt.get(oldOpp.Related_Agreement__c).Name, idToAcc.get(oldOpp.AccountId).Name, numToMonth);
                    if(opp.Name == oldOppFormattedName){
                        opp.Name = getOppFormattedName(opp, idToAgmt.get(opp.Related_Agreement__c).Name, idToAcc.get(opp.AccountId).Name, numToMonth);
                    }
                }
            }
            ilib_LogEvent.message('opp.Name : '+opp.Name);
        }
        ilib_LogEvent.pop();
    }

  private String getOppFormattedName(Opportunity opp, String agmtName, String accName, Map<Integer, List<String>> numberToMonth) {
        
        ilib_LogEvent.message('opp : ' + opp);
        ilib_LogEvent.message('agmtName : ' + agmtName);
        ilib_LogEvent.message('accName : ' + accName);
        ilib_LogEvent.message('numberToMonth : ' + (numberToMonth != Null ? String.valueof(numberToMonth.keySet()):NULLSTR));
        String oppDateFormatted;
        Integer intLength=120;
        if(opp.stagename == STRING_OPPORTUNITY_STAGE_CLOSED_WON) {
            oppDateFormatted = numberToMonth.get(Date.today().month())[0] + (Date.today().day() > 9 ? '' : '0')+ Date.today().day() + Date.today().year();
        }
        else {
            oppDateFormatted = numberToMonth.get(opp.CloseDate.month())[0] + (opp.CloseDate.day() > 9 ? '' : '0')+ opp.CloseDate.day() + opp.CloseDate.year();
        }
        String oppNameFormatted = agmtName+'_'+accName+'_'+oppDateFormatted;
        if(oppNameFormatted.length() > intLength) {
            Integer extraSize = oppNameFormatted.length() - 120;
            oppNameFormatted = agmtName + '_' + accName.substring(0, (accName.length() - extraSize)) + '_' + oppDateFormatted;
        }
        ilib_LogEvent.message('oppNameFormatted ' + oppNameFormatted);
        return oppNameFormatted;
    }

   /**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40569 and 40570 createMonthToQuarterMap
     * before update trigger method
     **/
    public Map<Integer, List<String>> createMonthToQuarterMap() {
            ilib_LogEvent.push(LOG_TITLE + '.createMonthToQuarterMap()');
            Map<Integer, List<String>> mapNumToQtr = new Map<Integer, List<String>> ();
            mapNumToQtr.put(1, new List<String>{'Jan','1'});
            mapNumToQtr.put(2, new List<String>{'Feb','1'});
            mapNumToQtr.put(3, new List<String>{'Mar','1'});
            mapNumToQtr.put(4, new List<String>{'Apr','2'});
            mapNumToQtr.put(5, new List<String>{'May','2'});
            mapNumToQtr.put(6, new List<String>{'Jun','2'});
            mapNumToQtr.put(7, new List<String>{'Jul','3'});
            mapNumToQtr.put(8, new List<String>{'Aug','3'});
            mapNumToQtr.put(9, new List<String>{'Sep','3'});
            mapNumToQtr.put(10, new List<String>{'Oct','4'});
            mapNumToQtr.put(11, new List<String>{'Nov','4'});
            mapNumToQtr.put(12, new List<String>{'Dec','4'});
            ilib_LogEvent.info('mapNumToQtr : ' + (mapNumToQtr != Null ? String.valueof(mapNumToQtr.keySet()):NULLSTR));
            ilib_LogEvent.pop();
            return mapNumToQtr;
    }

/**
     * @author Tapas
     * @date   18 Sep 2020
     * @description    DCP-40569 update currency on SQ opp products from opp
     * after update trigger method
   **/
    private void updatecurrencyOnSQOppProds(List<Opportunity> lstOpps,Map<Id,Opportunity> idToOldOpps) {
        ilib_LogEvent.push(LOG_TITLE + '.updatecurrencyOnSQOppProds()');   
        Set<Id> setStandingQuoteOppIds = new Set<Id>();
        Map<Id,Opportunity> idToOpp = new Map<Id,Opportunity> ();

        for(Opportunity opp : lstOpps) {
            Opportunity oldOpp;
            if(idToOldOpps != null){
                oldOpp = idToOldOpps.get(opp.Id);
                ilib_LogEvent.message('oldOpp : '+oldOpp);
            }

            if(opp.recordTypeId == RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId() && (Trigger.isInsert || (Trigger.isUpdate && opp.AccountId != oldOpp.AccountId))) {
                idToOpp.put(opp.Id, opp);
                setStandingQuoteOppIds.add(opp.Id);
            }
        }
        ilib_LogEvent.info('setStandingQuoteOppIds : '+ setStandingQuoteOppIds);
        ilib_LogEvent.info('idToOpp : ' +(idToOpp != Null ? String.valueof(idToOpp.keySet()):NULLSTR));  
        if(setStandingQuoteOppIds.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }

        List<Standing_Quote_Opportunity_Product__c> lstSQOPs = new StandingQuoteOpportunityProductsSelector().selectSQProductsByOpportunityIds(setStandingQuoteOppIds);
        if(lstSQOPs.isEmpty()){
            ilib_LogEvent.pop();
            return;
        }
        List<Standing_Quote_Opportunity_Product__c> lstSQOPsToUpdate = new List<Standing_Quote_Opportunity_Product__c>();

        for(Standing_Quote_Opportunity_Product__c objSQOP : lstSQOPs) {
            Opportunity opp = idToOpp.get(objSQOP.Opportunity__c);
            if(objSQOP.CurrencyIsoCode != opp.CurrencyIsoCode) {
                objSQOP.CurrencyIsoCode = opp.CurrencyIsoCode;
                lstSQOPsToUpdate.add(objSQOP);
            }
        }
        if(!lstSQOPsToUpdate.isEmpty())
            update lstSQOPsToUpdate;
        ilib_LogEvent.pop();
    }

  /**
     * @author Pankaj Singla
     * @date   14 Sep 2020
     * @description    DCP-40572 Updated Related Opportunity field for cloned Opportunities
     * before update trigger method
   **/
  private void addParentFieldForClonedOpportunities(List<Opportunity> lstOpportunity) {
    ilib_LogEvent.push(LOG_TITLE + '.addParentFieldForClonedOpportunities()');
    for(Opportunity opp:lstOpportunity) {
      if(opp.isClone() && opp.getCloneSourceId()!=null && opp.RecordTypeId==RECORD_TYPE_MAP.get(OPPORTUNITY_RT_STANDING_QUOTE).getRecordTypeId()) {
        opp.Cloned_From_Opportunity__c=opp.getCloneSourceId();
        ilib_LogEvent.message(' opp.Cloned_From_Opportunity__c : '+ opp.Cloned_From_Opportunity__c);
      }
    }
    ilib_LogEvent.pop();
  }
  
  /**
     * @author Pankaj Singla
     * @date   14 Sep 2020
     * @description    DCP-40572 Clone the Opportunity and Standing Quote Opportunity Product Related List
     * after update trigger method
   **/
  private void processClonedOpportunity(List<Opportunity> lstOpportunity) {
    ilib_LogEvent.push(LOG_TITLE + '.processClonedOpportunity()');
    if(objUser.IsPortalEnabled){
        ilib_LogEvent.pop();
        return;
    }

    /*Map to contain the new opportunity and cloned from parent record*/
    Map<Id,Id> mapNewOppToSourceOpp=new Map<Id,Id>();
    Set<Id> setParentOppIds=new Set<Id>();
    Map<Id,List<Standing_Quote_Opportunity_Product__c>> mapOppIdToListStandingQuote=new Map<Id,List<Standing_Quote_Opportunity_Product__c>>();
    List<Standing_Quote_Opportunity_Product__c> lstStandardQuoteOppProduct=new List<Standing_Quote_Opportunity_Product__c>();
    for(Opportunity opp:lstOpportunity) {
      if(opp.isClone() && opp.getCloneSourceId()!=null && opp.Cloned_From_Opportunity__c!=null) {
        mapNewOppToSourceOpp.put(opp.Id,opp.getCloneSourceId());
        setParentOppIds.add(opp.getCloneSourceId());

      }
    }
    ilib_LogEvent.info('setParentOppIds : '+ setParentOppIds);
    ilib_LogEvent.info('mapNewOppToSourceOpp : ' +mapNewOppToSourceOpp); 
    if(setParentOppIds.isEmpty()){
        ilib_LogEvent.pop();
        return;
    }
    for(Standing_Quote_Opportunity_Product__c objSQOP: new StandingQuoteOpportunityProductsSelector().selectSQProductsByOpportunityIds(setParentOppIds)) {
      if(mapOppIdToListStandingQuote.containsKey(objSQOP.Opportunity__c)) {
        List<Standing_Quote_Opportunity_Product__c> lstTemp=mapOppIdToListStandingQuote.get(objSQOP.Opportunity__c);
        lstTemp.add(objSQOP);
        mapOppIdToListStandingQuote.put(objSQOP.Opportunity__c,lstTemp);

      }
      else {
        List<Standing_Quote_Opportunity_Product__c> lstTemp=new List<Standing_Quote_Opportunity_Product__c>();
        lstTemp.add(objSQOP);
        mapOppIdToListStandingQuote.put(objSQOP.Opportunity__c,lstTemp);
      }
    }
    ilib_LogEvent.info('mapOppIdToListStandingQuote : ' + (mapOppIdToListStandingQuote != Null ? String.valueof(mapOppIdToListStandingQuote.keySet()):NULLSTR)); 
    for(Id idNewOpptyId:mapNewOppToSourceOpp.keyset()) {
      if(mapOppIdToListStandingQuote.containsKey(mapNewOppToSourceOpp.get(idNewOpptyId))) {
        for(Standing_Quote_Opportunity_Product__c objSQOP:mapOppIdToListStandingQuote.get(mapNewOppToSourceOpp.get(idNewOpptyId))) {
          Standing_Quote_Opportunity_Product__c objSQOPCLoned=objSQOP.clone();
          objSQOPCLoned.Opportunity__c=idNewOpptyId;
          objSQOPCLoned.Material_Name__c = objSQOP.Material_Name__c;
          lstStandardQuoteOppProduct.add(objSQOPCLoned);
        }
      }

    }
    if(!lstStandardQuoteOppProduct.isEmpty()) {
      insert lstStandardQuoteOppProduct;
    }
    ilib_LogEvent.pop();
  }

   /**
     * @author Anish
     * @date   15-Mar-2021
     * @description    DCP-43258 Refactor the Opportunity Process Builders
     * after insert trigger method
   * Test coverage by TestPartnerRequestQueueable
   **/
    private void updatePartnerRequestStatus(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.updatePartnerRequestStatus()');
        Set<Id> partnerRequestIdSet = new Set<Id>();
        for(Opportunity opty:lstOpportunity) {
            String recordType = getIdToRecordType().get(opty.RecordTypeId).getDeveloperName();
            if(opty.Partner_Request__c != null && RT_STANDARD_INDIRECT.equals(recordType)) {
                partnerRequestIdSet.add(opty.Partner_Request__c);
            }
        }
        ilib_LogEvent.info('partnerRequestIdSet : '+ partnerRequestIdSet);
        if(!partnerRequestIdSet.isEmpty()) {
            PartnerRequestQueueable queueableClassInstance = new PartnerRequestQueueable(partnerRequestIdSet);
            ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities_PartnerRequestQueueable');
            queueableThread.logAndQueue(queueableClassInstance, 'PartnerRequestQueueable', EXECUTE);
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
        }
        ilib_LogEvent.pop();
    }
  /**
     * @author Rishab
     * @date   22-Mar-2021
     * @description    DCP-45455 Opportunity Performance Improvements [Test Coverage - TestUpdateQuoteFieldsFromOppQueueable]
    **/
    private void updateTransborderFlagOnOpportunity(Boolean isInsert)
    {
        ilib_LogEvent.push(LOG_TITLE+'updateTransborderFlagOnOpportunity()');
        ilib_LogEvent.info('isInsert : '+isInsert);
        Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)trigger.oldMap;
        ilib_LogEvent.info('oppOldMap : ' + (oppOldMap != Null ? String.valueof(oppOldMap.keySet()):NULLSTR));
        List<Opportunity> oppList = (List<Opportunity>) records;
        Set<Id> setSoldToAndUCIds = new Set<Id>();
        setSoldToAndUCIds.addAll(UtilsCollection.getSetOfIds(oppList , ACCOUNT_ID));
        setSoldToAndUCIds.addAll(UtilsCollection.getSetOfIds(oppList , ULTIMATE_CONSIGNEE));
        setSoldToAndUCIds.addAll(UtilsCollection.getSetOfIds(oppList , 'Current_Ultimate_Consignee__c'));
        ilib_LogEvent.info('setSoldToAndUCIds : '+ setSoldToAndUCIds);
        Map<Id,Account> accIdToAccMap = new Map<Id,Account>(new AccountsSelector().selectAccounts(setSoldToAndUCIds));
        ilib_LogEvent.info('accIdToAccMap : ' + (accIdToAccMap != Null ? String.valueof(accIdToAccMap.keySet()):NULLSTR)); 
        //DCP-46835: Start-Platform event for Admin operation
        List<Admin_Operation__e> lstExcludeFromForecastUpdates = new List<Admin_Operation__e>();
        //DCP-46835: End-Platform event for Admin operation
        for(Opportunity opp : oppList)
        {
            if(isInsert && opp.Ultimate_Consignee__c != null && opp.AccountId != null &&
               accIdToAccMap.get(opp.Ultimate_Consignee__c).BillingCountry != accIdToAccMap.get(opp.AccountId).BillingCountry &&
               recordTypeDevNameSet.contains(getIdToRecordType().get(opp.RecordTypeId).getDeveloperName()) )
               {
                    opp.Transborder_Flag__c = true;
               }
            else if(!isInsert && opp.Ultimate_Consignee__c != null && (opp.Ultimate_Consignee__c != oppOldMap.get(opp.Id).Ultimate_Consignee__c ||
                    opp.AccountId != oppOldMap.get(opp.Id).AccountId))
                {
                    if(recordTypeDevNameSet.contains(getIdToRecordType().get(opp.RecordTypeId).getDeveloperName())
                       && opp.Transborder_Flag__c == false &&
                       accIdToAccMap.get(opp.Ultimate_Consignee__c).BillingCountry != accIdToAccMap.get(opp.AccountId).BillingCountry )
                     {
                       opp.Transborder_Flag__c = true;
                       oppIdToTransborderLogicTrueMap.put(opp.Id,true);
                     }
                     if(opp.Transborder_Flag__c && accIdToAccMap.get(opp.Ultimate_Consignee__c).BillingCountry == accIdToAccMap.get(opp.AccountId).BillingCountry)
                     {
                        opp.Transborder_Flag__c = false;
                     }
                }
            //DCP-46835: Start-Compute Exclude From Forecast logic
            if(OpportunitiesService.needsExcludeFromForecast(opp)) {
                lstExcludeFromForecastUpdates.add(new Admin_Operation__e(Related_Record__c=opp.id,Name__c='UpdateOppExcludeForecast'));
            }
            //DCP-46835: End-Compute Exclude From Forecast logic
            // DCP-46224 : Set relocation type field
            if(isInsert && String.isNotBlank(opp.Ultimate_Consignee__c) && String.isNotBlank(opp.Current_Ultimate_Consignee__c)) {
                opp.Relocation_Type__c =  OpportunitiesService.updateRelocationType(opp,accIdToAccMap);
            }
            else if(!isInsert && String.isNotBlank(opp.Ultimate_Consignee__c) && String.isNotBlank(opp.Current_Ultimate_Consignee__c)
                        && (opp.Ultimate_Consignee__c != oppOldMap.get(opp.Id).Ultimate_Consignee__c
                            ||  opp.Current_Ultimate_Consignee__c != oppOldMap.get(opp.Id).Current_Ultimate_Consignee__c)) {
                                    opp.Relocation_Type__c =  OpportunitiesService.updateRelocationType(opp,accIdToAccMap);
            }
            else if(!isInsert && (String.isBlank(opp.Ultimate_Consignee__c) || String.isBlank(opp.Current_Ultimate_Consignee__c))
                        && String.isNotBlank(opp.Relocation_Type__c)) {
                            opp.Relocation_Type__c = null;
            }
            ilib_LogEvent.message('Relocation_Type__c :'+opp.Relocation_Type__c);
            // DCP-46224 : Set relocation type field ends
        }
        //DCP-46835: Start-Publish platform event
        if(!lstExcludeFromForecastUpdates.isEmpty()) {
            EventBus.publish(lstExcludeFromForecastUpdates);
        }
        //DCP-46835: End-Publish platform event
        ilib_LogEvent.pop();
    }
   /**
     * @author Rishab
     * @date   23-Mar-2021
     * @description    DCP-45454 Opportunity Performance Improvements [Covered by - TestOpportunities]
    **/
    public static void updateFieldIsFirstProposalSent()
    {
        ilib_LogEvent.push(LOG_TITLE+'updateFieldIsFirstProposalSent()');
        Map<Id,Opportunity> oppNewMap = (Map<Id,Opportunity>)trigger.newMap;
        Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)trigger.oldMap;
        ilib_LogEvent.info('oppNewMap : ' + (oppNewMap != Null ? String.valueof(oppNewMap.keySet()):NULLSTR));
        ilib_LogEvent.info('oppOldMap : ' +  (oppOldMap != Null ? String.valueof(oppOldMap.keySet()):NULLSTR));
        for(Opportunity opp : oppNewMap.values())
        {
            if(getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectStandard
                && (opp.StageName == System.Label.OpportunityStageQualify || opp.StageName == System.Label.OpportunityStageDevelop)
                && opp.Proposal_Sent_On__c != oppOldMap.get(opp.Id).Proposal_Sent_On__c && opp.Proposal_Sent_On__c != null
                && opp.Is_First_Proposal_Sent__c == false)
            {
                    opp.Is_First_Proposal_Sent__c = true;
                    oppIdToDirectStandardRTMap.put(opp.Id,true);
            }
            else if((getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectReOrder
                    || getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectFieldServices)
                    && opp.StageName == System.Label.OpportunityStageDevelop && opp.Proposal_Sent_On__c != oppOldMap.get(opp.Id).Proposal_Sent_On__c
                    && opp.Proposal_Sent_On__c != null && opp.Is_First_Proposal_Sent__c == false)
            {
                    opp.Is_First_Proposal_Sent__c = true;
                    oppIdToDirectStandardRTMap.put(opp.Id,false);
            }
 
            setRecordTypeName(opp, oppOldMap.get(opp.Id)); // Method to resolve Incident INC0419938
            setLeadSource(opp, oppOldMap.get(opp.Id)); // Method to resolve Incident INC0419938
            setEstimatedCloseDate(opp, oppOldMap.get(opp.Id)); //Method to resolve Incident INC0419938
                
        }
        ilib_LogEvent.info('oppIdToDirectStandardRTMap : ' +  oppIdToDirectStandardRTMap);
        ilib_LogEvent.pop();
    }

    /**
     * @author Rishab
     * @date   23-Mar-2021
     * @description    DCP-45454 Opportunity Performance Improvements [Covered by - TestOpportunities]
    **/
    public static void createTaskForOpportunity()
    {
        ilib_LogEvent.push(LOG_TITLE+'createTaskForOpportunity()');
        if(!oppIdToDirectStandardRTMap.isEmpty() && !boolTaskCreated)
        {
            boolTaskCreated = true;
            createTaskForOppStandardDirectReorderRT(oppIdToDirectStandardRTMap);
        }
        ilib_LogEvent.pop();
    }

    /**
     * @author Rishab
     * @date   24-Mar-2021
     * @description    DCP-45454 Opportunity Performance Improvements [Covered by - TestOpportunities]
    **/
    @future
    public static void createTaskForOppStandardDirectReorderRT(Map<Id,Boolean> oppIdToStandardRTMap)
    {
        try {
            ilib_LogEvent.push(LOG_TITLE+'createTaskForOppStandardDirectReorderRT()');
            ilib_LogEvent.info('oppIdToStandardRTMap : ' +oppIdToStandardRTMap);
            Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(oppIdToStandardRTMap.keySet()));
            ilib_LogEvent.info('idToOpportunity : ' + (idToOpportunity != Null ? String.valueof(idToOpportunity.keySet()):NULLSTR));
            List<Task> lstTask = new List<Task>();
            for(Id oppId : oppIdToStandardRTMap.keySet())
            {
                Task tsk = new Task();
                tsk.ActivityDate = System.TODAY() + 7 ;
                tsk.CurrencyIsoCode = idToOpportunity.get(oppId).Account.CurrencyIsoCode;
                tsk.OwnerId = idToOpportunity.get(oppId).OwnerId;
                tsk.whatId = oppId;
                tsk.subject = oppIdToStandardRTMap.get(oppId) ? Label.ProposalSentOnDSTaskMessage :  Label.ProposalSentOnROFSTaskMessage;
                lstTask.add(tsk);
            }
            insert lstTask;
            ilib_LogEvent.pop();
    }
        Catch(Exception e) { ApexExceptions.emit(Opportunities.STRINGEXCEPTIONLOGMESSAGE, e); }
    }


    /**
     * @author Rishab
     * @date   31-Mar-2021
     * @description    DCP-45454 Opportunity Performance Improvements [Covered by - TestOppUpdateIsUpdatedBySystemQueueable]
    **/
    public void updateIsUpdatedBySystemAndReasonBackwards(Boolean isInsert)
    {
        ilib_LogEvent.push(LOG_TITLE+'updateIsUpdatedBySystemAndReasonBackwards()');
        ilib_LogEvent.info('isInsert : '+isInsert);
        Map<Id,Opportunity> oppNewMap = (Map<Id,Opportunity>)trigger.newMap;
        Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)trigger.oldMap;
        ilib_LogEvent.info('oppNewMap : ' +(oppNewMap != Null ? String.valueof(oppNewMap.keySet()):NULLSTR));
        ilib_LogEvent.info('oppOldMap : ' + (oppOldMap != Null ? String.valueof(oppOldMap.keySet()):NULLSTR));
        List<Opportunity> oppToBeUpdatedList = new List<Opportunity>();
        for(Opportunity opp : oppNewMap.values())
        {
            if(isInsert && (opp.Is_Updated_By_System__c || opp.ByPass_LockSentProposalDate__c || opp.ByPass_Change_Record_Type_To_Standard__c))
            {
                oppToBeUpdatedList.add(opp);
            }
            else if(!isInsert && ((opp.Is_Updated_By_System__c != oppOldMap.get(opp.Id).Is_Updated_By_System__c && opp.Is_Updated_By_System__c)
                    || (opp.ByPass_LockSentProposalDate__c != oppOldMap.get(opp.Id).ByPass_LockSentProposalDate__c && opp.ByPass_LockSentProposalDate__c)
                    || (opp.ByPass_Change_Record_Type_To_Standard__c != oppOldMap.get(opp.Id).ByPass_Change_Record_Type_To_Standard__c && opp.ByPass_Change_Record_Type_To_Standard__c)
                    || (String.isNotBlank(opp.Reason_for_Moving_Backwards__c) && oppOldMap.get(opp.Id).Reason_for_Moving_Backwards__c != opp.Reason_for_Moving_Backwards__c) ))      //INC0337404
                    {
                        oppToBeUpdatedList.add(opp);
                    }
        }
        if(!oppToBeUpdatedList.isEmpty())
        {
            if(System.isBatch() || System.isFuture()) {
                List<Opportunity> oppList = new List<opportunity>();
                for(Opportunity opp : oppToBeUpdatedList)
                {
                    Opportunity objOpp = new Opportunity(Id = opp.Id);
                    objOpp.Is_Updated_By_System__c = false;
                    if(!isInsert && OppUpdateIsUpdatedBySystemQueueable.blankOutReasonForMovingBackward(oppOldMap.get(opp.Id),oppNewMap.get(opp.Id)))
                    {
                        objOpp.Reason_for_Moving_Backwards__c = '';
                    }
                    objOpp.ByPass_LockSentProposalDate__c = false;
                    objOpp.ByPass_Change_Record_Type_To_Standard__c = false;
                    oppList.add(objOpp);
                }
                update oppList;
            }
            else
            {
                OppUpdateIsUpdatedBySystemQueueable queueableClsInstance = new OppUpdateIsUpdatedBySystemQueueable(oppToBeUpdatedList,oppOldMap,OppNewMap);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities_OppUpdateIsUpdatedBySystemQueueable');
                queueableThread.logAndQueue(queueableClsInstance, 'OppUpdateIsUpdatedBySystemQueueable', EXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            }
        }
        ilib_LogEvent.pop();
    }

    /* @author Rishab
     * @date   23-Mar-2021
     * @description    DCP-45455 Opportunity Performance Improvements [Test Coverage - TestUpdateQuoteFieldsFromOppQueueable]
    **/
    public static void updateQuoteFromOpportunity()
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateQuoteFromOpportunity()');
        Map<Id,Opportunity> oppNewMap = (Map<Id,Opportunity>)trigger.newMap;
        ilib_LogEvent.info('oppNewMap : ' + (oppNewMap != Null ? String.valueof(oppNewMap.keySet()):NULLSTR));
        Set<Id> updateOppIdSet = new Set<Id>();
        ilib_LogEvent.info('Static Map  ----' +  oppIdToTransborderLogicTrueMap);
        for(Opportunity opp : oppNewMap.values())
        {
            if(oppIdToTransborderLogicTrueMap.containsKey(opp.Id) && oppIdToTransborderLogicTrueMap.get(opp.Id) == true)
            {
                updateOppIdSet.add(opp.Id);
            }
        }
        ilib_LogEvent.info('updateOppIdSet : '+ updateOppIdSet);
        if(!updateOppIdSet.isEmpty())
        {
            UpdateQuoteFieldsFromOppQueueable queueableClsInstance = new UpdateQuoteFieldsFromOppQueueable(updateOppIdSet);
            ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities_UpdateQuoteFieldsFromOppQueueable');
            queueableThread.logAndQueue(queueableClsInstance, 'UpdateQuoteFieldsFromOppQueueable', EXECUTE);
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
        }

        ilib_LogEvent.pop();
    }

  /**
     * @author Anish
     * @date   24-Mar-2021
     * @description    DCP-45455 Opportunity Performance Improvements - Update Quotation Record Type
   * @Test Coverage - TestUpdateQuoteRecordTypeQueueable
    **/
    public static void updateQuoteRecordTypeOnOpportunity(List<Opportunity> lstOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateQuoteRecordTypeOnOpportunity()');
        Set<Id> oppIdSet = new Set<Id>();
        Map<id,Opportunity> oldOppMap = (Map<Id,Opportunity>) trigger.oldMap;
        ilib_LogEvent.info('oldOppMap : ' + (oldOppMap != Null ? String.valueof(oldOppMap.keySet()):NULLSTR));
        for(Opportunity opp : lstOpportunity)
        {
            if(opp.Type != oldOppMap.get(opp.Id).Type || opp.RecordTypeId != oldOppMap.get(opp.Id).RecordTypeId) {
            oppIdSet.add(opp.Id);
            }
        }
        ilib_LogEvent.info('oppIdSet : '+ oppIdSet);
        if(!oppIdSet.isEmpty())
        {
            if(System.isBatch() || System.isFuture() || System.isQueueable()) {
                UpdateQuoteRecordTypeQueueable.updateRecordType(oppIdSet);
            }
            else
            {
                UpdateQuoteRecordTypeQueueable queueableClsInstance = new UpdateQuoteRecordTypeQueueable(oppIdSet);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities_UpdateQuoteRecordTypeQueueable');
                queueableThread.logAndQueue(queueableClsInstance, 'UpdateQuoteRecordTypeQueueable', EXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            }
        }
        ilib_LogEvent.pop();
    }

    /* @author Anand
     * @date   14-Jun-2021
     * @description    DCP-46168 trigger email notification when Opportunity is Closed Won(Only for Tender)
    **/
    public static void emailAlertforWonTendOpps(List<Opportunity> lstOpportunity,Map<Id,Opportunity> idToOldRecords)
    {
        ilib_LogEvent.push(LOG_TITLE + '.emailAlertforWonTendOpps()');
        Set<Id> oppIdSet = new Set<Id>();
        for(Opportunity opp : lstOpportunity) {
            if(opp.stagename != idToOldRecords.get(opp.Id).stagename && opp.stagename == Label.OpportunityStageClosedWon && opp.Type == Label.OpportunityTypeTender) {
                oppIdSet.add(opp.Id);
            }
        }
        ilib_LogEvent.info('oppIdSet : '+ oppIdSet);
        if(!oppIdSet.isEmpty()) {
            EmailAlertforClosedWonTenderOpptyClass.sendEmailAlert(oppIdSet);
        }
        ilib_LogEvent.pop();
    }

    private static Id getApprovalHierarchyOwner(Account acc, Id drivingAccountOnOppId, Apttus_Proposal__Proposal__c objProposal)
    {
        if(acc.Id == drivingAccountOnOppId && objProposal.Work_Order__c == null)
        {
            return OpportunitiesHelper.getAccountHierarchy(acc.Owner.Id);
        }

        return null;
    }
    
    /**
     * @author Atit Kar
     * @date   21-Mar-2023
     * @description   TASK0876760 - Set values on proposal based on update scenario
    **/
    public static void updateBUAndSubRegionSoldTOUCDist(Map<Id,Apttus_Proposal__Proposal__c> idToProposal,Apttus_Proposal__Proposal__c objProposal, String accountType, Account objAccount) {
        AutomateBillToShipToService.setProposalValue(idToProposal, objProposal, accountType == ULTIMATE_CONSIGNEE ? BU_UC : accountType == ACCOUNT_ID ? BU_SOLD_TO : BU_DISTRIBUTOR, objAccount.Business_Unit__c);
        AutomateBillToShipToService.setProposalValue(idToProposal, objProposal, accountType == ULTIMATE_CONSIGNEE ? SUBREGION_UC : accountType == ACCOUNT_ID ? SUBREGION_SOLD_TO : SUBREGION_DISTRIBUTOR, objAccount.Subregion__c);
    }

    /**
     * @author Enrique Reyes
     * @date 15-Sept-2023
     * @description Populate Compliance Last Modified Date
     **/
    private static void populateComplianceLastModifiedDate(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.populateComplianceLastModifiedDate()');

        for(Opportunity opp : lstOpportunity) {
            if(Trigger.isInsert && opp.Compliance_Last_Modified_Date__c == null){
                opp.Compliance_Last_Modified_Date__c = Datetime.now();
            } else if(Trigger.isUpdate && !UtilsSettings.isAutomatedUser()) {
                opp.Compliance_Last_Modified_Date__c = Datetime.now();
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
     * @author Sai Pasumarthy
     * @date 27-Nov-2024
     * @description CMCM-11235 TI- Opportunity : Update Stage to Close Abandoned when Deal Registration is Rejected
     **/
    public static void oppStageChangeOnDealReject(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.oppStageChangeOnDealReject()');
        if(Feature.isOn('WF_Opp_Update_Stage_To_Close_Abandoned')) {
            Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)trigger.oldMap;
            for(Opportunity opp : lstOpportunity) {
                if(Trigger.isInsert && opp.Deal_Registration_Status__c == STRING_OPPORTUNITY_DEAL_REGISTRATION_REJECTED){
                    opp.StageName = STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED;
                    opp.Abandon_Reason__c = STRING_OPPORTUNITY_ABANDON_REASON;
                } else if(Trigger.isUpdate && opp.Deal_Registration_Status__c == STRING_OPPORTUNITY_DEAL_REGISTRATION_REJECTED 
                            && (opp.Deal_Registration_Status__c != oppOldMap.get(opp.Id).Deal_Registration_Status__c)) {
                    opp.StageName = STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED;
                    opp.Abandon_Reason__c = STRING_OPPORTUNITY_ABANDON_REASON;
                }
            }
        }
       
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
     /**
     * @author Sai Pasumarthy
     * @date 27-Nov-2024
     * @description CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
     **/
    public static void oppStageChangeBackwardMovementinPipeline(List<Opportunity> lstOpportunity) {
        ilib_LogEvent.push(LOG_TITLE + '.oppStageChangeBackwardMovementinPipeline()');
        if(Feature.isOn('WF_Opp_Backward_Movement')) {
            Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)trigger.oldMap;
            for(Opportunity opp : lstOpportunity) {                
                Boolean isStandardRecordType = isStandardRecordType(opp);
                Boolean isStandardRecordAndPostQualify = isStandardRecordAndPostQualify(oppOldMap.get(opp.Id), opp);
                Boolean isNonStandardRecordAndPostDevelop = isNonStandardRecordAndPostDevelop(oppOldMap.get(opp.Id), opp);                
               if(          opp.StageName != oppOldMap.get(opp.Id).StageName 
                            && !OPPTY_CLOSED_STAGES.contains(opp.StageName) 
                            && (
                                  (isStandardRecordType && isStandardRecordAndPostQualify) || 
                                  (isNonStandardRecordAndPostDevelop)
                              )
                            ) { 
                                opp.Backward_Movement_in_Pipeline__c = true;
                }
            }
        }
       
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
     * @author Sai Pasumarthy
     * @date 27-Nov-2024
     * @description CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
     **/
    private static Boolean isStandardRecordAndPostQualify(Opportunity oppOld, Opportunity opp) {
        return (oppOld.StageName == System.Label.OpportunityStageFinalize ||                                      
        (oppOld.StageName == System.Label.OpportunityStageQualify && !OPP_STAGE_AFTER_QUALIFY.contains(opp.StageName)) ||                                      
        (oppOld.StageName == System.Label.OpportunityStageDevelop && !OPP_STAGE_AFTER_DEVELOP.contains(opp.StageName)) ||
        (oppOld.StageName == System.Label.OpportunityStageProve && 
        !(opp.StageName == System.Label.OpportunityStageNegotiateResolve || opp.StageName == System.Label.OpportunityStageFinalize)) ||
        (oppOld.StageName == System.Label.OpportunityStageNegotiateResolve && opp.StageName != System.Label.OpportunityStageFinalize));
        }
    
    /**
     * @author Sai Pasumarthy
     * @date 27-Nov-2024
     * @description CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
     **/
    private static Boolean isNonStandardRecordAndPostDevelop(Opportunity oppOld, Opportunity opp) {
        String opportunityRecordName = getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() ;
        return (
            opportunityRecordName == System.Label.OpportunityRTDirectReOrder ||
            opportunityRecordName == System.Label.IndirectReOrder ||
            opportunityRecordName == System.Label.FieldServices ||
            opportunityRecordName == System.Label.IndirectFieldServices 
          ) && 
          ( 
              oppOld.StageName == System.Label.OpportunityStageFinalize ||
              ( oppOld.StageName == System.Label.OpportunityStageDevelop && opp.StageName != System.Label.OpportunityStageFinalize)
          );
    
    }
    
    /**
     * @author Sai Pasumarthy
     * @date 27-Nov-2024
     * @description CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
     **/
    private static Boolean isStandardRecordType(Opportunity opp) {
        return getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectStandard || getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTIndirectStandard;
        }

/**
     * @author Vinay S Reddy
     * @date 17-Oct-2023
     * @handler for emiting platform event for Process Quotes On Opportunity Close
     **/
    public static void triggerhandlerOppQuoteRecall(){   
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        List<ProcessQuotesOnOpportunityClose__e> peRecords=new List<ProcessQuotesOnOpportunityClose__e>();
        Map<Id,Opportunity> newRecords=(Map<Id,Opportunity>)Trigger.newMap;

        for(Opportunity temp : newRecords.values()){   
                if(temp.StageName ==Label.OpportunityStageClosedAbandoned || temp.StageName ==Label.OpportunityStageClosedLost) 
                { 	ProcessQuotesOnOpportunityClose__e idField =new ProcessQuotesOnOpportunityClose__e(oppId__c =temp.Id);
                    peRecords.add(idField);                 
                }
        }
                ilib_LogEvent.message('Platform Events dispatched with Opportunity Records are '+peRecords);

                List<Database.SaveResult> results = EventBus.publish(peRecords);

        for (Database.SaveResult sr : results){
                if (sr.isSuccess()) {
                    ilib_LogEvent.message('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        system.debug('Error returned: ' 
                            + err.getStatusCode() +
                            ' - ' 
                            + err.getMessage());
                    }
                }
            }
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
        }
}
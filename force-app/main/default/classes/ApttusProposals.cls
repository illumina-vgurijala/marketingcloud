/**
*  @date   2018-05-15
*  @description    domain class for Quotes
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
   -TestTAPS_ApttusProposals
   -TestOpportunities
   -TestApttusOrders
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Roopal             2018-07-09    onBeforeUpdate(),restrictQuoteOnClosedOpportunity() for DCP-3899
*      Akash              2018-07-27    populateGlobalMessage() for DCP-946
*      Govind Dubey       2018-09-10    added logic CustomApprovalMatrixWrapper and setApprovals logic for PPM Approval Matrix
*      Roopal Verma       2018-09-26    Changed Post pricing message name to Post_Pricing_Message_List__c
*      Roopal Verma       2018-10-01    setMyIlluminaEmail(), To check if MyIllumina zemail is in Sold to Account
*      Gopesh banker      2018-10-09    line 260 onafterupdate, added incoterms field in or condition   
*      Rahul Sharma       2018-10-09    checkValidToInSameQuarter()
*      Kristiyan Petkov   2018-10-19    update fields on the cloned quote
*      Milan Savaliya     2018-10-23    update PriceList on before Insert
*      Gopinath Reddy     2018-10-29    Added logic for Indirect Trans Region Approvals on Before Update in setApprovals and getTransRegionProposalIds
*      Gopinath Reddy     2018-10-29    On Before insert, validateRenewalUCsHaveLineItems() for DCP - 14180
*      Rahul Sharma       2018-10-30    Added logic to on updatePricing() to update cart with new pricelist
*      Milan Savaliya     2018-10-31    Moved Syn Opp Line Logic from Batch to Platform Event
*      Kushagra Desai     2018-12-12    Skiping of quotes created by Integration
*      Akshay Mohan       2019-04-09    DCP-24588 Allow search for payers
*      Sampath Goud       2019-04-15    DCP-24587 call sharing method for product configuration
*      Roopal Verma       2019-06-20    DCP-25455 Inco terms approval
*      Saswati Prusty     2019-06-22    DCP-25456  Consortia Approvals - number of sample exception
*      Rahul Sharma       2019-07-03    DCP-25384 UC Apex Sharing - Removed ApttusProposalsService Call
*      Roopal Verma       2019-08-12    DCP-28526 Inco Terms Approvals Region Enhancement 
*      Pragna             2019-12-04    DCP-29916 Added one more condition on checkValidToInSameQuarter()
*      Rahul Bishnoi      2019-12-05    DCP-30367 - added Informatics_Quotation_c__c = true condition for renewal informatics quotations.
*      Arnab Modak        2020-03-05    DCP-34009 - Refactored the class
*      Joshith K          2020-03-13    INC0257010-- update Sold to sales Org in Opportunity (setShipToSalesOrgForOpportunity method)
*      Tapas Chakraborty  14 Aug 2020   29588 created methods updatePrimaryContactOnOpportunityContactRole
*      Raja Siva Krishna  2020-08-24    DCP-40114 picklist to multipicklist changes for region__c and country__c in custom approval matrix
*      Raja Siva Krishna  2020-11-10    INC0295821-Incident fix
*      Rishab Wali        2021-03-05    DCP-43259 Quote Improvements
*      Bharath Varma      2021-03-16    DCP-43259 Quote Improvements
*      Rishab Wali        2021-03-05    DCP-45453 Quote Improvements
*      Akshay Mohan       4 May 2021    DCP-38808: Add logic for quote amount update to work order
*      Adyasha Satapathy  2021-05-06    DCP-38809: Bypass Creation of Lines from opportunity product for billable services flow
*      Ashwin Kumar       2021-05-11    INC0321438 - Queried Config Line Items separately and used in updatePricing() method
*      KD                 2-June-2021   DCP-38933 : Updated SelectById method to selectOpportunities mmethod
*      KD                 22-June-2021  DCP-46257 : Logic to populate Inventory Location
*      KD                 29-June-2021  DCP-46226 : Payment term defaulting for Greater china.
*      Rishab             15-June-2021  [DCP-46920] - Auto Generate Document when approved
*      Adyasha            23-Aug-2021   INC0340937 - Query Site object only if user has access.
*      Anish              7-Sept-2021   DCP-49904 - Enable auto generate for auto approved quotes
*      Kushal Shah        28-Sep-2021   DCP-49429: Added logic for MFN Aprovals
*      Ashwin Kumar       15-Nov-2021   INC0350488: Display Add Products button conditionally with checkbox only when cart reprice is completed for Cloned Quote.
*      Koustubh M         17-Dec-2021   TASK0679416: Bug fix - Multiple queueables were getting queued in the same batchable context.
*      Rishi Sharma       24-May-2022   DCP-53954: PPM: Ability to Move PPM to Custom Object and Allow filtering of PPM by Region
*      Khushbu Vasani     13-Dec-2022   DCP-54531 : populate role for created by and submitted by user
*      Anshaj Sinha		  20-June-2022	CMSI-68 - Instrumented the class for ilib_LogEvent Framework
*      Nishan Shetty      24-Aug-2022   DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*      Khushbu            04-Sept-2022  DCP-56658- populate approval hierarchy owner
*      Adithi Acharya     13-Sept-2022  DCP-54080 : Method to Auto Populate Sales_Quote_Contract_Type__c field on Quotation
     
*      Juned              14-Sept-2022  P2 INC0423774 - Add logic to populate Approval Hierarchy Record Owner only when Quote stage is Draft/Approval Required
*      Prem Ranjan        26-Oct-2022   DCP-54361: Fix as suggested by sandeep, not carry promos on clone quote.
*      Ashwin Kumar       15-Nov-2022   INC0429503: Populate Price List from Opportunity when Quote is cloned.
*      Adithi Acharya     31-Oct-2022   DCP-56437 : Removal of Rejected Quote Stage
*      Adyasha Satapathy  24-Nov-2022   POL-54: Update region references to AMEA and EUR 
*      Vishal Reddy       30-Nov-2022   DCP-58263: Added functionality to check if products are missing HSN or SAC code and send emails
*      Rishi Sharma       4-Jan-2023    DCP-58707: Restrict Quotes with previous year pricing from expiring after the yearly price change date
*      Ashwin             20-Jan-2023   INC0449312 - Add bypass logic similar to DCP-58707 conditions when Valid to date is updated.
*      Prem Ranjan        20-Feb-2023   CodeScan Fixes (APEX) Variable Naming Conventions
*      Atit Kar           21-Mar-2023   TASK0876760 - update values on proposal
*      Rajbabu Boopalan   16-Oct-2023   CMCM-2523 - Annual Price Change Date logic change. Do not update approval category when valid to date is null
*      Rajbabu Boopalan   03-Nov-2023   CMCM-4516 - All Selector methods reafactoring (replace selectors with plain SOQL queries) to handle CPU timeout error.
*      Gerardo Garcia     24-Jan-2024   CMCM-5310 Add Flag of skipUpdateTrigger which disable/enable executing before/after update.
*      Pradeep Landge     20-Nov-2024   CMCM-11336 Logic for updating Template Consortia Terms And Conditions
*      Vinay S Reddy      20-Nov-2024   CMCM-11810 Prevent Multiple Quotes for Web Generated Opportunities
*      Sai Pasumarthy     20-Nov-2024   CMCM-11328 - TI- Quotation: Lock Record Based On Quote Stage
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ApttusProposals extends ilib_SObjectDomain {

    private static final String LOG_TITLE = 'ApttusProposals.';

    public static Boolean skipUpdateTrigger = false;
    private static Boolean hasRunTaps = false;
    public static final String APPROVAL_STATUS_NONE = 'None';
    public static final String APPROVAL_STAGE_DRAFT = 'Draft';
    public static final String OPPORTUNITY_TYPE_RENEWAL_SERVICE_CONTRACT_NO_UPSELL = 'Renewal - Service Contract No Upsell';
    public static final String OPPORTUNITY_TYPE_RENEWAL_SOFTWARE_NO_UPSELL = 'Renewal - Software No Upsell';
    public static final String OPPORTUNITY_TYPE_UPSELL_WITH_SERVICE_CONTRACT_RENEWAL = 'Upsell with Service Contract Renewal';
    public static final String QUOTE_STAGE_GENERATED = 'Generated';
    public static final String QUOTE_STAGE_PRESENTED = 'Presented';
    public static final String CONFIGURATION_STATUS_FINALIZED = 'Finalized';
    public static final String CONFIGURATION_STATUS_SAVED = 'Saved';
    public static final String QUOTE_REGION_AMEA = 'AMEA';  // POL-54
    public static final String QUOTE_REGION_CHINA = 'China';
    public static final String COUNTRY_JAPAN = 'Japan';
    public static final String QUOTE_REGION_APAC = 'APAC';
    public static final String ACCOUNT_GROUP_PAYER = 'Payer';
    public static final String OPPORTUNITY_TYPE_CONSORTIUM = 'Consortium';
    public static final String OPPORTUNITY_TYPE_REORDER_CONSORTIUM_CONSUMABLE = 'Reorder - Consortium Consumable';
    public static final String OPPORTUNITY_TYPE_REORDER_NON_CONSORTIUM_CONSUMABLE = 'Reorder - Non Consortium Consumable';//DCP-58707
    public static final String OPPORTUNITY_TYPE_STANDARD_SALE = 'Standard Sale';//DCP-58707
    public static final String FIELD_PROPOSAL_PAYMENT_TERM = 'Apttus_Proposal__Payment_Term__c';
    public static final String FIELD_TRANSREGION_FLAG = 'Transregion_Flag__c';
    public static final String FIELD_INDIRECT_TRANSREGION_FLAG = 'Indirect_Transregion_Flag__c';
    public static final String FIELD_QUOTE_SUB_TYPE = 'Quote_Sub_Type__c';
    public static final String FIELD_INCO_TERM_1 = 'Inco_Term_1__c';
    public static final String LINE_PRICING_STATUS_PENDING = 'Pending';
    public static final String APPROVAL_STAGE_DENIED = 'Denied';
    public static final String APPROVAL_STAGE_ACCEPTED = 'Accepted'; //CMCM-11328 
    public static final String QUOTE_PROP_READ_ONLY_RECORD_TYPE = 'Proposal_Read_Only'; //CMCM-11328
    public static final String APPROVAL_STAGE_APPROVED = 'Approved';
    public static final String APPROVAL_STAGE_REQUIRED = 'Required';
    public static final string STRING_APTTUSPROPOSALS = 'ApttusProposals';
    public static Boolean isQuoteUpdatedFromOpty = false;                                        
//commented for TASK0876760: public static final String STRING_PAYMENT_TERM_RECORD_TYPE = 'Payment_Term';//DCP-40114
    public static final String STRING_INCO_TERM_RECORD_TYPE = 'Inco_Terms';//DCP-40114
    public static final String QUOTE_COUNTRY_JP = 'JP';//DCP-40114   
    public static final String OPPORTUNITY_STAGE_CREATE = 'Create';//DCP-43259  
    public static Boolean boolHasRunOnce = false;
    public static Boolean isChanged = false;
    public static final String STREXECUTE = 'execute';  
    public static final String QUOTE_TYPE_DIRECT_STANDARD = 'Direct Standard'; //DCP-45453
    public static final String QUOTE_TYPE_DIRECT_REORDER_CUSTOM_PRODUCT = 'Direct Reorder and Custom Product'; //DCP-45453
    public static final String QUOTE_TYPE_DIRECT_FIELD_SERVICES = 'Direct Field Services'; //DCP-45453
    public static Boolean boolHasOppLineItems = false;
    public static Boolean boolCheckPLIndicatorOnInsertFromTest = false; //DCP-45399  
    public static final Set<String> SET_QUOTE_SUBTYPES_FOR_BYPASS = new Set<String>{Label.OpportunityTypeBillableService};  // DCP-38809 
    public static final String MFN_APPROVAL = 'MFN_Approval'; //DCP-49429
    public static final String DSM_APPROVAL_AFTER_PRICE_CHANGE = 'DSM_Approval_After_PriceChange'; //DCP-58707
    public static Boolean booIsRepriceRequired = false;       //INC0350488 - This is set to true in CreateQuoteAutomation
    public static Boolean boolByPassReprice = false;          //INC0362941 - This is set to true in RenewOppQueueable
    public static final Set<String> SET_QUOTE_STAGE = new Set<String>{Label.QuoteStageDraft,Label.QuoteStageApprovalRequired};  // DCP-53191
    private static final String STROBJPROPOSAL = 'objProposal : ';
    private static final String MAPISEMPTY = 'Null';
    public static final string EMAIL_ID_FOR_MISSING_SAC_CODE = 'Email_ID_For_Missing_SAC_Code';
    public static final string EMAIL_ID_FOR_MISSING_HSN_CODE = 'Email_ID_For_Missing_HSN_Code';
    public static final string EMAIL_ID_CC_FOR_MISSING_HSN_CODE = 'Email_ID_CC_For_Missing_HSN_Code';
    public static final string MATERIAL_TYPE_ZDIN = 'ZDIN';
    public static final string HSN = 'HSN';
    public static final string SAC = 'SAC';
    public static final string SALES_ORG_INDIA = 'IN01';
    public static final string APPROVAL_STEP_NAME_PRICING_CHANGE = 'Sales Manager - Extend Pre-Price Change Pricing';
    private static Code_Parameter__mdt codeParameterAPCDThresholdDays = Code_Parameter__mdt.getInstance('Annual_Price_Change_Threshold');     //CMCM-2523
    private static final integer APCD_THRESHOLD_DAYS = integer.valueOf(codeParameterAPCDThresholdDays.Value__c);
    public Map<Id,Datetime> proposalIdToAPCDate = new Map<Id,Datetime>();
     
    
    public static final String WEBGENOPP = Label.OpportunityTypeWebGenerated;

    
    
    public Map<String, String> fieldToApprovalType = new Map<String, String> {
        'Apttus_Proposal__Payment_Term__c' => 'Terms_Of_Payment',
        'Post_Pricing_Message_List__c' => 'Post_Pricing_Message',
        'Transregion_Flag__c' => 'Region',
        'Indirect_Transregion_Flag__c' => 'Region',
        'Quote_Sub_Type__c' => 'Consortia',  //Saswati: Added Quote Sub Type for DCP-25456, to set approvals for Consortia Quotes
        'Inco_Term_1__c' => 'Inco_Terms'  //Roopal: DCP-25455,  to ser inco terms approvals
        };

    public Set<String> setQuoteApprovalFields = new Set<String> {
        'Post_Pricing_Message_List__c',
        'Transregion_Flag__c',
        'Apttus_Proposal__Payment_Term__c',
        'Indirect_Transregion_Flag__c',
        'Quote_Sub_Type__c'  //Saswati: Added Quote Sub Type for DCP-25456, to set approvals for Consortia Quotes
    };
	
	public static final String APPROVAL_STAGE_IN_REVIEW = 'In Review'; //DCP-46920
    public static boolean boolRecursiveCheck = false; //DCP-46920

    /*DCP-28526 Added INCO_TERMS*/
    public enum ApprovalCategory { POST_PRICING_MESSAGE, PAYMENT_TERM, INCO_TERMS }

    /*Parameterised Constructor */
    public ApttusProposals(List<Apttus_Proposal__Proposal__c> sObjectList) {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApttusProposals(sObjectList);
        }
    }

    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
    
    /*Mark Existing Quote Non Primary Method */
    private void markExistingPrimaryQuoteNonPrimary(Set<Id> setOpportunityIds)
    {
        ilib_LogEvent.push(LOG_TITLE+'markExistingPrimaryQuoteNonPrimary()');
        ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        if (setOpportunityIds.isEmpty()) {ilib_LogEvent.pop(); 
		return; }

        // NOTE: called from before insert only, will only execute once
        //CMCM-4516
        //List<Apttus_Proposal__Proposal__c> lstPrimaryProposals = new ApttusProposalsSelector().selectPrimary(setOpportunityIds);
        List<Apttus_Proposal__Proposal__c> lstPrimaryProposals = [SELECT Payment_Term_Description__c, 
        Total_Number_Of_Samples__c, 
        Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c,
        Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c,
        Apttus_Proposal__Opportunity__r.Name,
        Apttus_Proposal__Opportunity__r.AccountId,
        Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Account.BillingCountry,
        Apttus_Proposal__Opportunity__r.Account.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Distributor__c,
        Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,
        Apttus_Proposal__Opportunity__r.StageName,
        Apttus_Proposal__Opportunity__r.Probability,
        Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c,
        Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c,
        Apttus_Proposal__Account__r.Territory_Region__c,
        Ultimate_Consignee__r.Territory_Region__c,
        Distributor__r.Territory_Region__c,
        Apttus_Proposal__Opportunity__r.Contract_Number__c,
        Apttus_Proposal__Opportunity__r.Transborder_Flag__c,
        Distributor__r.BillingCountry,
        Distributor__r.BillingCountryCode,
        Apttus_Proposal__Account__r.BillingCountry,
        Apttus_Proposal__Account__r.BillingCountryCode,
        Ultimate_Consignee__r.BillingCountry,
        Ultimate_Consignee__r.BillingCountryCode,
        Ultimate_Consignee__r.OwnerId,
        Distributor__r.OwnerId,
        Apttus_Proposal__Account__r.OwnerId,
        Apttus_Proposal__Opportunity__r.Account.Name,
        Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c,
        Bill_To__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c,
        Apttus_Proposal__Primary_Contact__r.Email,
        Apttus_Proposal__Account__r.Name,
        Ultimate_Consignee__r.Name,
        Distributor__r.Name,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Sales_Org_Override__c,
        Owner.Id,
        Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c,
        Apttus_Proposal__Account__r.Territory_Name__c,
        Apttus_Proposal__Opportunity__r.Product_Interest__c,
        Apttus_Proposal__Opportunity__r.Territory_Region__c,
        Apttus_Proposal__Primary_Contact__r.Name,
        Prepared_by__r.Email,
        Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c,
        Work_Order__r.Name,
        Work_Order__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Price_List_Type__c,
        Approval_Category__c,
        Quote_Total_Value_Prior_To_DiscountUSD__c,
        Id,
        Bill_To__c,
        Ship_To__c,
        Apttus_QPApprov__Approval_Status__c,
        Apttus_Proposal__Approval_Stage__c,
        Apttus_Proposal__Primary__c,
        Apttus_Proposal__Opportunity__c,
        Apttus_Proposal__Account__c,
        Cloned_From__c,
        Ship_To_ERP_Number__c,
        CurrencyIsoCode,
        Apttus_Proposal__Discount_Percent__c,
        Apttus_Proposal__ExpectedStartDate__c,
        Apttus_Proposal__Amount__c,
        Apttus_Proposal__ExpectedEndDate__c,
        Post_Pricing_Message__c,
        Discount_Reason__c,
        Discount_Reason_Definition__c,
        Discount_Justification__c,
        Quote_Total_Value_Prior_To_Discount__c,
        Total_Cart_Discount__c,
        Blended_Discount_Percentage__c,
        Quote_Total_Value_After_Discount__c,
        Apttus_Proposal__Primary_Contact__c,
        Invalid_Quote__c,
        MyIllumina_User_Email__c,
        Distributor__c,
        SAP_Quote__c,
        Is_Updated_By_System__c,
        Promo_Channel_1__c,
        Promo_Code_1__c,
        Promo_Channel_2__c,
        Promo_Code_2__c,
        Promo_Channel_3__c,
        Promo_Code_3__c,
        Ultimate_Consignee__c,
        Apttus_QPConfig__PriceListId__c,
        Apttus_QPConfig__PricingDate__c,
        Sold_To_ERP_Number__c,
        Ultimate_Consignee_ERP_Number__c,
        Bill_To_ERP_Number__c,
        Informatics_Quotation_c__c,
        Payer_ERP_Number__c,
        Informatics_Product_Line_Item_Numbers__c,
        Distributor_ERP_Number__c,
        Name,
        Web_Visible__c,
        Apttus_Proposal__Payment_Term__c,
        Quote_Type__c,
        Payer__c,
        Total_Net__c,
        Total_Discount__c,
        Estimated_Freight__c,
        Estimated_Tax__c,
        Post_Pricing_Message_List__c,
        Preferred_Language__c,
        Inco_Term_1__c,
        Prepared_by__c,
        Sold_to_Sales_Organization__c,
        Sold_to_Distribution_Channel__c,
        Sold_to_Division__c,
        Region_Ultimate_Consignee__c,
        Region_Distributor__c,
        Region_Sold_To__c,
        Indirect_Transregion_Flag__c,
        SAP_Errors__c,
        Direct_Sale_to_Ultimate_Consignee__c,
        Promotion_JSON__c,
        Opportunity_Record_Type__c,
        Sales_Discretionary_Approval_Error__c,
        Quote_Sub_Type__c,
        Subtotal__c,
        Sub_Total__c,
        Contract_Numbers__c,
        Fapiao_Type_Code__c,
        Fapiao_Type_Description__c,
        Last_Generate_Success__c,
        Last_Validation_Id__c,
        Generate_In_Progress__c,
        Async_Generation_Complete__c,
        View_Contract__c,
        BDR_Deal_Governing_Terms__c,
        Estimated_Presentation_Date__c,
        Informatics_Line_Item_Number__c,
        Open_Offer_Discount_Exception_Request__c,
        Open_Offer_Discount_Violation_Type__c,
        Quote_For_Open_Offer_Customer__c,
        Quote_Has_Open_Offer_Product__c,
        Sold_To_Account_Region__c,
        Work_Order__c,
        Number_of_MFN_Line_Items__c,
        Apttus_Proposal__Proposal_Name__c,
        Submit_For_Approval__c,
        Approval_Hierarchy_Record_Owner__c,
        Approval_Hierarchy_Transborder__c,
        Generate__c,
        Territory_Region__c,
        Async_Validation_Complete__c,
        OwnerId,
        Validation_In_Progress__c,
        Inventory_Location_ERP_Number__c,
        Open_Offer_Legal_Approver_Comments__c,
        Sub_Region_Sold_To__c,
        Business_Unit_Sold_To__c,
        Sub_Region_UC__c,
        Business_Unit_UC__c,
        Sub_Region_Distributor__c,
        Business_Unit_Distributor__c, RecordTypeId, Apttus_Proposal__Opportunity__r.Type,
        Apttus_Proposal__Opportunity__r.Account.Owner.Id, Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Id 
        FROM Apttus_Proposal__Proposal__c 
        WHERE Apttus_Proposal__Opportunity__c IN :setOpportunityIds AND Apttus_Proposal__Primary__c = true];
        if (!lstPrimaryProposals.isEmpty())
        {
            for (Apttus_Proposal__Proposal__c objProposal : lstPrimaryProposals){
                ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
                objProposal.Apttus_Proposal__Primary__c = false;
                ilib_LogEvent.message('objProposal.Apttus_Proposal__Primary__c = false');
            }

            // NOTE: async update candidate
            update lstPrimaryProposals;
        }
        ilib_LogEvent.pop();
    }

    /*Set Default Values For Cloned Quote */
    private void setDefaultValuesForClonedQuotes(Apttus_Proposal__Proposal__c objProposal, Map<Id, Opportunity> idToOpportunity, Map<String, Apttus_Config2__PriceList__c> mpNameToPriceLists)
    {
        ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
        objProposal.Apttus_Proposal__ExpectedStartDate__c = Date.today();
        objProposal.Apttus_Proposal__ExpectedEndDate__c = null;
        objProposal.Apttus_Proposal__Approval_Stage__c = APPROVAL_STAGE_DRAFT;
        objProposal.Apttus_QPApprov__Approval_Status__c = APPROVAL_STATUS_NONE;
        objProposal.Prepared_by__c = UserInfo.getUserid();
        objProposal.SAP_Quote__c = null;
        objProposal.Generated_Date__c = null;
        objProposal.Cloned_From__c = objProposal.getCloneSourceId();
        objProposal.Apttus_QPConfig__PricingDate__c = DateTime.now();
        objProposal.Quote_Output_Generated_Valid_From_Date__c = null;
        objProposal.Apttus_Proposal__Presented_Date__c = null;
        objProposal.Apttus_Proposal__Proposal_Approval_Date__c = null;
        //Default Reprice completed field to true when Renewal Quotes are created(by clone) from RenewOppQueueable.cls
        objProposal.Is_Reprice_Completed__c = boolByPassReprice; //INC0350488;INC0362941
        objProposal.Created_By_Role__c = null;//54390
        objProposal.Submitted_By_Role__c = null;
         //Added by Himanshu below as part of DCP-56110
         // This is done to reset open offer fields for cloning of quote
         objProposal.Open_Offer_Product_Type__c = null;
         objProposal.Quote_Has_Open_Offer_Product__c =false;
         objProposal.Open_Offer_Discount_Violation_Type__c = null;
         objProposal.Open_Offer_Legal_Approver_Comments__c = null; // blank out open offer legal approver comments
         objProposal.Open_Offer_Discount_Exception_Request__c = null;
         //End of DCP-56110
        // Added as per ask from sandeep to make promo null on clone DCP-54361
        objProposal.Applied_Promo_1__c = null;
        objProposal.Applied_Promo_2__c = null;
        objProposal.Applied_Promo_3__c = null;

        //INC0429503
        Opportunity objOpp = idToOpportunity.containsKey(objProposal.Apttus_Proposal__Opportunity__c) ? idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c) : null;
        String strPriceListName = objOpp != null ? objOpp.Price_List__c : null;
        if(String.isNotBlank(strPriceListName) && mpNameToPriceLists.containsKey(strPriceListName)) {
            objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;
        }
    }

    /*Stamp Values from Opportunity */
    private void stampValuesOnQuoteFromOpportunity(Apttus_Proposal__Proposal__c objProposal, Map<Id, Opportunity> idToOpportunity, Map<String, Apttus_Config2__PriceList__c> mpNameToPriceLists)
    {
        ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
        ilib_LogEvent.message('idToOpportunity Ids : '+(idToOpportunity != Null ? String.valueof(idToOpportunity.keySet()):MAPISEMPTY));
        ilib_LogEvent.message('mpNameToPriceLists : '+mpNameToPriceLists);
        if (idToOpportunity.containsKey(objProposal.Apttus_Proposal__Opportunity__c))
        {
            ilib_LogEvent.message('Inside if block to stamp values from Opportunity');
            Opportunity objOpp = idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c);
            objProposal.Sold_To_Account_Region__c = objOpp.Sold_To_Account_Region__c;
            objProposal.Ultimate_Consignee_Region__c = objOpp.Ultimate_Consignee_Region__c;
            objProposal.Apttus_Proposal__Primary_Contact__c = objOpp.Primary_Contact__c;//29588         
            String strPriceListName = objOpp.Price_List__c;
            //DCP-45453 Quote Improvements change start
            objProposal.Apttus_QPConfig__PricingDate__c = System.now();
            objProposal.Apttus_Proposal__ExpectedStartDate__c = System.today();
            objProposal.Apttus_Proposal__Account__c = checkIfNull(objOpp.AccountId) ? null : objOpp.AccountId;
            objProposal.Apttus_QPConfig__PaymentTermId__c = checkIfNull(objOpp.Account.Apttus_Config2__PaymentTermId__c) ? null : objOpp.Account.Apttus_Config2__PaymentTermId__c ; 
            objProposal.Company_Code_Address__c = checkIfNull(objOpp.Company_Code_Address__c) ? null : objOpp.Company_Code_Address__c;
            objProposal.Contract_Numbers__c = checkIfNull(objOpp.Contract_Number__c) ? null : objOpp.Contract_Number__c ;
            objProposal.Distributor__c = checkIfNull(objOpp.Distributor__c) ? null : objOpp.Distributor__c;
            objProposal.Project_Manager_For_Consortium__c = (checkIfNull(objOpp.Consortium__c) && checkIfNull(objOpp.Consortium__r.Project_Manager__c)) ? null : objOpp.Consortium__r.Project_Manager__c ;
            objProposal.Sold_To_Distribution_Channel__c = checkIfNull(objOpp.Sold_to_Distribution_Channel__c) ? null : objOpp.Sold_to_Distribution_Channel__c ;
            objProposal.Sold_To_Division__c = checkIfNull(objOpp.Sold_to_Division__c) ? null : objOpp.Sold_to_Division__c;
            objProposal.Sold_To_Sales_Organization__c = checkIfNull(objOpp.Sold_to_Sales_Organization__c) ? null : objOpp.Sold_to_Sales_Organization__c;
            objProposal.Ultimate_Consignee__c = checkIfNull(objOpp.Ultimate_Consignee__c) ? null : objOpp.Ultimate_Consignee__c ; 
            //TASK0876760 : Start
            objProposal.Sub_Region_Sold_To__c = checkIfNull(objOpp.Account.Subregion__c) ? null : objOpp.Account.Subregion__c;
            objProposal.Sub_Region_UC__c = checkIfNull(objOpp.Ultimate_Consignee__r.Subregion__c) ? null : objOpp.Ultimate_Consignee__r.Subregion__c;
            objProposal.Sub_Region_Distributor__c = checkIfNull(objOpp.Distributor__r.Subregion__c) ? null : objOpp.Distributor__r.Subregion__c;
            objProposal.Business_Unit_Sold_To__c = checkIfNull(objOpp.Account.Business_Unit__c) ? null : objOpp.Account.Business_Unit__c;
            objProposal.Business_Unit_UC__c = checkIfNull(objOpp.Ultimate_Consignee__r.Business_Unit__c) ? null : objOpp.Ultimate_Consignee__r.Business_Unit__c;
            objProposal.Business_Unit_Distributor__c = checkIfNull(objOpp.Distributor__r.Business_Unit__c) ? null : objOpp.Distributor__r.Business_Unit__c;
            //TASK0876760 : End
            setPreparedBy(objOpp,objProposal); //DCP-45453 Set Prepared By Field
            if(mpNameToPriceLists.containsKey(strPriceListName)) {
                objProposal.Apttus_QPConfig__PriceListId__c = mpNameToPriceLists.get(strPriceListName).Id;
            }
        }
    }
    private boolean checkIfNull(object value)
    {
        return value == null || value == '' ? true : false; 
    }

    private void setPreparedBy(Opportunity objOpp , Apttus_Proposal__Proposal__c objProposal)
    {
        if(objOpp.Type == Label.OpportunityTypeWebGenerated) { // comes from myIllumina webservice
            objProposal.Prepared_by__c = String.isEmpty(objOpp.OwnerId) ? UserInfo.getUserId() : objOpp.OwnerId;
            return;
        }
        
        Set<String> quoteTypeSet = new Set<String>{QUOTE_TYPE_DIRECT_STANDARD,QUOTE_TYPE_DIRECT_REORDER_CUSTOM_PRODUCT,QUOTE_TYPE_DIRECT_FIELD_SERVICES};
        objProposal.Prepared_by__c = quoteTypeSet.contains(objProposal.Quote_Type__c) && !checkIfNull(objOpp.OwnerId) ? objOpp.OwnerId : UserInfo.getUserId() ;
    }

    private void addTransregionApprovalCategory(Apttus_Proposal__Proposal__c objProposal)
    {
        ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
        if (objProposal.Transregion_Flag__c && fieldToApprovalType.containsKey(FIELD_TRANSREGION_FLAG)){
            objProposal.Approval_Category__c = fieldToApprovalType.get(FIELD_TRANSREGION_FLAG);
            ilib_LogEvent.message('objProposal.Approval_Category__c : '+objProposal.Approval_Category__c);
        }

        if (objProposal.Indirect_Transregion_Flag__c && fieldToApprovalType.containsKey(FIELD_INDIRECT_TRANSREGION_FLAG)){
            objProposal.Approval_Category__c = fieldToApprovalType.get(FIELD_INDIRECT_TRANSREGION_FLAG);
            ilib_LogEvent.message('objProposal.Approval_Category__c : '+objProposal.Approval_Category__c);
        }
    }

    /**
     * Adds default values to new records
     * Called during before insert event (e.g. set defaults before insert of proposal record)
     **/
    public override void onBeforeInsert()
    {
  /*
            Added by - Himanshu Malik
            DCP-50487  Disable Cart Versioning
        */
        List<Apttus_Proposal__Proposal__c> newProposals = (List<Apttus_Proposal__Proposal__c>) trigger.new;
        for (Apttus_Proposal__Proposal__c oProposal : newProposals)
        {
            ilib_LogEvent.message('oProposal : '+oProposal);
            oProposal.Apttus_QPConfig__DisableCartVersioning__c = true;
            ilib_LogEvent.message('oProposal.Apttus_QPConfig__DisableCartVersioning__c = true');
        }

        
        //added as part of cmcm-11810
        
        addErrorforMultipleQuotesOnWebGenOpp(newProposals,null);
        
        
        checkProductIndicatorIfOppHasLineItems((List<Apttus_Proposal__Proposal__c>)records); //DCP-45399

        List<Apttus_Proposal__Proposal__c> lstProposalsOnOpenOpps = restrictQuoteOnClosedOpportunity((List<Apttus_Proposal__Proposal__c>)records, null);
        if (lstProposalsOnOpenOpps.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        
        //Get Set of open Opportunity Ids
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(lstProposalsOnOpenOpps, 'Apttus_Proposal__Opportunity__c');
        ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        
        //Mark existing primary quote as non-primary
        markExistingPrimaryQuoteNonPrimary(setOpportunityIds);

        //Map to store Related Opportunity
        //CMCM-4516
        //Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
        Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c,
        Consortium__r.Initial_Sale_Special_Terms__c,Consortium__r.Re_Order_Special_Terms__c,Consortium__r.Stage__c //CMCM-11336
        FROM Opportunity WHERE Id IN :setOpportunityIds]);
        //populateMapOfIdToOpportunity(setOpportunityIds);

        //DCP-54080 : Method call to setContractType
        setContractType(idToOpportunity,(List<Apttus_Proposal__Proposal__c>) trigger.new);

        //Set to store Price List names of Opportunities
        Set<String> setPriceListNames = UtilsCollection.getSetOfStrings(idToOpportunity.values(), 'Price_List__c');
        ilib_LogEvent.info('setPriceListNames : '+setPriceListNames);

        Map<String, Apttus_Config2__PriceList__c> mpNameToPriceLists =  new ApttusPriceListsSelector().selectActive(setPriceListNames);

        List<Apttus_Proposal__Proposal__c> lstNotClonedProposals = new List<Apttus_Proposal__Proposal__c>();
        //DCP-46257
        List<Apttus_Proposal__Proposal__c> lstInventoryLocationProposal = new List<Apttus_Proposal__Proposal__c>();
        Set<Id> setDistributorAccount = new Set<Id>();
        for (Apttus_Proposal__Proposal__c objProposal : lstProposalsOnOpenOpps)
        {
            ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
            objProposal.Apttus_Proposal__Primary__c = true;
            objProposal.Legacy_SFDC_Record_ID__c = null; //@Roopal- INC0196658 hotfix
            ilib_LogEvent.message('objProposal.Apttus_Proposal__Primary__c = true');
            ilib_LogEvent.message('objProposal.Legacy_SFDC_Record_ID__c = null');
            if (objProposal.isClone())
            {
                setDefaultValuesForClonedQuotes(objProposal, idToOpportunity, mpNameToPriceLists);  //INC0429503
            }
            else
            {
                //INC0350488 - Set boolean to true if Quote is not cloned and not created as part of Billable flow
                objProposal.Is_Reprice_Completed__c = booIsRepriceRequired ? false : true;
                //Stamp SoldToAccountRegion, UltimateConsigneeRegion and PriceList on Quote from Opportunity
                stampValuesOnQuoteFromOpportunity(objProposal,idToOpportunity,mpNameToPriceLists);
                addTransregionApprovalCategory(objProposal);
                lstNotClonedProposals.add(objProposal);
            }
            //DCP-46257
            if(!checkIfNull(objProposal.Distributor__c)){
                lstInventoryLocationProposal.add(objProposal);
                setDistributorAccount.add(objProposal.Distributor__c);
            }
            

        }
        //DCP-46257
        if(!setDistributorAccount.isEmpty()){
            setInventoryLocation(lstInventoryLocationProposal,setDistributorAccount);
        }
        setMyIlluminaEmailIdOnProposal(lstProposalsOnOpenOpps,idToOpportunity); //DCP-45453 Set MyIlluminaId
        PreferredLanguageService.updatePreferredLanguageOnQuote(lstProposalsOnOpenOpps,idToOpportunity); //DCP-45453 Set Preferred Language      

        if (!lstNotClonedProposals.isEmpty()){
            defaultBillToShipTo(lstNotClonedProposals, idToOpportunity);}

            validateRenewalUCsHaveLineItems(lstNotClonedProposals, idToOpportunity);
        updateConsortiaTerms(Trigger.new,idToOpportunity);//cmcm-11336
        ilib_LogEvent.pop();
    }


    /**
     * Author : Adithi Acharya
     * Description : DCP-54080 : method to populate Sales_Quote_Contract_Type__c field default value based on 
     *               Direct and Indirect quote from Opportunity RecordType
     **/

    public void setContractType(Map<Id,Opportunity> idToOpportunity,List<Apttus_Proposal__Proposal__c> lstProposals){
        for (Apttus_Proposal__Proposal__c objProposal : lstProposals){
              
                if(Opportunities.DIRECT_RECORD_TYPES.contains(idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).RecordType.DeveloperName))
                {
                    objProposal.Sales_Quote_Contract_Type__c = Label.SalesQuoteContractTypePurchaseContract_Direct;               
            
                }
                else if(Opportunities.INDIRECT_RECORD_TYPES.contains(idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).RecordType.DeveloperName))
                {
                    objProposal.Sales_Quote_Contract_Type__c = Label.SalesQuoteContractTypePurchaseContract_Indirect;
                }
            
        }
    }
    
    
    /**
     * Author : KD
     * Description : DCP-46257 Method to set Inventory Location on quotation
     **/
    private void setInventoryLocation(List<Apttus_Proposal__Proposal__c> lstProposal,Set<Id> setDistributorAccount){
        ilib_LogEvent.push(LOG_TITLE+'setInventoryLocation()');
        if(!Schema.sObjectType.SVMXC__Site__c.isAccessible()) {ilib_LogEvent.pop(); 
		return; } //INC0340937
        //CMCM-4516
        // List<SVMXC__Site__c> lstLocation = new LocationsSelector().selectDistributorPartnerStockLocationByAccount(setDistributorAccount);
        List<SVMXC__Site__c> lstLocation = selectDistributorPartnerStockLocationByAccount(setDistributorAccount);
        if(lstLocation.isEmpty()){
			ilib_LogEvent.pop();
            return;
        }
        Map<Id, List<SVMXC__Site__c>> mapAccountIdToLstLocation = UtilsCollection.getMapOfIdToSObjects(lstLocation,'SVMXC__Account__c');
        for(Apttus_Proposal__Proposal__c objProposal : lstProposal){
            if(mapAccountIdToLstLocation.containsKey(objProposal.Distributor__c)){
                objProposal.Inventory_Location__c = mapAccountIdToLstLocation.get(objProposal.Distributor__c)[0].id;
                ilib_LogEvent.message(STROBJPROPOSAL+objProposal);
                ilib_LogEvent.message('objProposal.Inventory_Location__c : '+objProposal.Inventory_Location__c);
            }
        }
        ilib_LogEvent.pop();   
    }
    /*Set My Illumina Email Id from Opp Primary Contact */
    private void setMyIlluminaEmailIdOnProposal(List<Apttus_Proposal__Proposal__c> lstProposals , Map<Id, Opportunity> idToOpp)
    {
        ilib_LogEvent.push(LOG_TITLE+'setMyIlluminaEmailIdOnProposal()');
        for(Apttus_Proposal__Proposal__c prop : lstProposals)
        {
            ilib_LogEvent.message('proposal record in iteration : '+prop);
            if(!checkIfNull(prop.Apttus_Proposal__Opportunity__c) && idToOpp.containsKey(prop.Apttus_Proposal__Opportunity__c))
            {
                prop.MyIllumina_User_Email__c = checkIfNull(idToOpp.get(prop.Apttus_Proposal__Opportunity__c).Primary_Contact__c) ? null : idToOpp.get(prop.Apttus_Proposal__Opportunity__c).Primary_Contact__r.Email ;
                ilib_LogEvent.message('prop.MyIllumina_User_Email__c : '+prop.MyIllumina_User_Email__c);
            }
        }
        ilib_LogEvent.pop();
    }

    /**
     * @author Gopinath Reddy 
     * @date   2018-10-24
     * @description    DCP-14180 Common asset line items by SoldTo and Ultimate Consignee Account 
     * Before update trigger method
     * Preventing the creation of Quote on Renewal Opportunity  if no common assets found.
     *  @param List<Apttus_Proposal__Proposal__c> lstProposals,Map<Id, Opportunity> idToOpp
     **/
    private void validateRenewalUCsHaveLineItems(List<Apttus_Proposal__Proposal__c> lstProposals , Map<Id, Opportunity> idToOpp)
    {
		ilib_LogEvent.push(LOG_TITLE+'validateRenewalUCsHaveLineItems()');
        // collect UC IDs where opportunities are renewals
        Set<Id> setRenewalOppUCAccountIds = new Set<Id>();
        for (Apttus_Proposal__Proposal__c objProposal : lstProposals)
        {
            Opportunity objOpp = idToOpp.get(objProposal.Apttus_Proposal__Opportunity__c);
            if (objOpp != null)
            {
                ilib_LogEvent.message('objOpp : '+objOpp);
                if (Opportunities.checkIfOpportunityRecordTypeIsRenewal(objOpp))
                {
                    if (objOpp.Ultimate_Consignee__c != null){
                        setRenewalOppUCAccountIds.add(objOpp.Ultimate_Consignee__c);}
                    else{
                        objProposal.addError(Label.UI_Error_No_Common_Asset_Line_Items);}
                }
            }
        }
        System.debug('@@@setRenewalOppUCAccountIds ' + setRenewalOppUCAccountIds);
		ilib_LogEvent.info('setRenewalOppUCAccountIds : '+setRenewalOppUCAccountIds);

        if (setRenewalOppUCAccountIds.isEmpty()){ilib_LogEvent.pop(); 
		return; }

        // given the UC accounts collected, find which ones have asset lines
        Set<Id> setUcIdsWithLineItems = new Set<Id>();
        //CMCM-4516
        // for (Apttus_Config2__AssetLineItem__c objALI : new ApttusAssetLineItemsSelector().selectAssetsByUC(setRenewalOppUCAccountIds))
        for (Apttus_Config2__AssetLineItem__c objALI : selectAssetsByUC(setRenewalOppUCAccountIds))
        {
            ilib_LogEvent.message('objAli : '+objALI);
            if (objALI.Ultimate_Consignee__c != null){
                setUcIdsWithLineItems.add(objALI.Ultimate_Consignee__c);}
        }
        System.debug('@@@setUcIdsWithLineItems ' + setUcIdsWithLineItems);
		ilib_LogEvent.info('setUcIdsWithLineItems : '+setUcIdsWithLineItems);

        // Display error on the Opportunity if the UC does not have any asset lines
        for (Apttus_Proposal__Proposal__c objProposal : lstProposals)
        {
            Opportunity objOpp = idToOpp.get(objProposal.Apttus_Proposal__Opportunity__c);
            ilib_LogEvent.message('objOpp : '+objOpp);
            if (objOpp != null && setRenewalOppUCAccountIds.contains(objOpp.Ultimate_Consignee__c) && !setUcIdsWithLineItems.contains(objOpp.Ultimate_Consignee__c))
            {
                objProposal.addError(Label.UI_Error_No_Common_Asset_Line_Items);
            }
        }
		ilib_LogEvent.pop();
    }

    /*Sync Indirect Opportunity Products To Quotes */
    public void syncIndirectOpportunityProductsToQuotes(List<Apttus_Proposal__Proposal__c> lstProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'syncIndirectOpportunityProductsToQuotes()');
        Set<Id> setOfIndirectOpportunityIds = new Set<Id>();
        Map<Id, Apttus_Proposal__Proposal__c> idToProposalToAddProduct = new Map<Id, Apttus_Proposal__Proposal__c>();

        for (Apttus_Proposal__Proposal__c objProposal : lstProposal)
        {
            Boolean boolQuoteSubTypeByPass = String.isNotBlank(objProposal.Quote_Sub_Type__c) && SET_QUOTE_SUBTYPES_FOR_BYPASS.contains(objProposal.Quote_Sub_Type__c);//DCP-38809 --> Billable Flow

            //DCP-30367 - added Informatics_Quotation_c__c = true condition for renewal informatics quotations.
            if (objProposal.Apttus_QPConfig__PriceListId__c != NULL
                && objProposal.Apttus_Proposal__Opportunity__c != NULL
                && ((objProposal.Quote_Type__c != NULL
                && objProposal.Quote_Type__c.Contains('Indirect'))
                || objProposal.Informatics_Quotation_c__c == true)
                && !boolQuoteSubTypeByPass //DCP-38809
            ) {
                setOfIndirectOpportunityIds.add(objProposal.Apttus_Proposal__Opportunity__c);
                idToProposalToAddProduct.put(objProposal.Id, objProposal);
            }
        }
		ilib_LogEvent.info('setOfIndirectOpportunityIds : '+setOfIndirectOpportunityIds);
		ilib_LogEvent.info('idToProposalToAddProduct : '+idToProposalToAddProduct);

        List<OpportunitySyncToQuote__e> lstOppSyncs= new List<OpportunitySyncToQuote__e>();
        if (setOfIndirectOpportunityIds.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        
        //CMCM-4516
        //Map<Id, Opportunity> idToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOfIndirectOpportunityIds));
        Map<Id, Opportunity> idToOpportunity = new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c FROM Opportunity WHERE Id IN :setOfIndirectOpportunityIds]);
        for (Apttus_Proposal__Proposal__c objProposal : idToProposalToAddProduct.values())
        {
            if (idToOpportunity.containsKey(objProposal.Apttus_Proposal__Opportunity__c)
                && String.isBlank(idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).First_Proposal_Id__c)
            ) {
                OpportunitySyncToQuote__e oppprtunitySyncToQuote = new OpportunitySyncToQuote__e(QuoteId__c = objProposal.Id);
                lstOppSyncs.add(oppprtunitySyncToQuote);
            }
        }

        if (lstOppSyncs.isEmpty()) {ilib_LogEvent.pop(); 
		return; }

        publishSyncPlatformEvent(JSON.serialize(lstOppSyncs));
		ilib_LogEvent.pop();
    }

    /**
    *  @author Akshay Mohan 
    *  @description publish platform event for syncing to quote
    *  @param JSON of List<OpportunitySyncToQuote__e>
    **/
    @future
    private static void publishSyncPlatformEvent(String sLstOpps)
    {
		ilib_LogEvent.push(LOG_TITLE+'publishSyncPlatformEvent()');
        if (!System.Test.isRunningTest())
        {
            EventBus.publish((List<OpportunitySyncToQuote__e>)
                JSON.deserialize(sLstOpps, List<OpportunitySyncToQuote__e>.class)
            );
        }
		ilib_LogEvent.pop();
    }

    /**
     * Creates cart For first Proposal and Adds Opportunity Products to cart
     * Called during After insert event (e.g. set defaults before insert of proposal record)
     **/
    public override void onAfterInsert()
    {
        syncIndirectOpportunityProductsToQuotes(records);
        if(!boolHasOppLineItems){
		syncDirectOpportunityProductsToQuotes(records); //DCP-45399
        }
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091

        //DCP-43259 Quote Improvements
        autoPopulateFieldsOnUpdate(true);
		
		//DCP-43259 Quote Improvements
        checkIsUpdatedBySystem(true);

        //DCP-54531
        ApttusProposalPopulateRoleQueueable queueableClassInstance = new ApttusProposalPopulateRoleQueueable(records,null);
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('ApttusProposalPopulateRoleQueueable');
        queueableThread.logAndQueue(queueableClassInstance, 'ApttusProposalPopulateRoleQueueable', 'execute');
        ilib_QueueableManager.enqueueJob(queueableThread); 
    }

    /**
    *  @author Akshay Mohan 
    *  @description Update the Quotes based on of Ultimate Consignee(Ship To) and Account(Bill To) 
    *  @param List<Apttus_Proposal__Proposal__c> lstProposals,Map<Id, Opportunity> idToOpp
    **/
    private void defaultBillToShipTo(List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id, Opportunity> idToOpp)
    {
		ilib_LogEvent.push(LOG_TITLE+'defaultBillToShipTo()');
        System.debug('lstProposals: ' + lstProposals);
        System.debug('idToOpp: ' + idToOpp);

        Map<String, List<Apttus_Proposal__Proposal__c>>
            soldToERPIdToProposal = new Map<String, List<Apttus_Proposal__Proposal__c>>(),
            ucERPIdToProposal = new Map<String, List<Apttus_Proposal__Proposal__c>>();
        Map<String, String> soldToERPToSAERP = new Map<String, String>();
        Map<String, String> ucERPToSAERP = new Map<String, String>();
        Map<String, String> accountERPToCountry = new Map<String, String>();
        Map<Id, String> distributorIdToUCERPId= new  Map<Id, String>();
        Set<Id> setDistributorId = new Set<Id>();
        Map<String, List<Account_Sales_Area__c>> ucERPToDistSalesArea = new Map<String, List<Account_Sales_Area__c>>();
        List<Account_Sales_Area__c> lstAccountSalesArea = new List<Account_Sales_Area__c>();

        for (Apttus_Proposal__Proposal__c objProposal : lstProposals)
        {
            if (objProposal.Is_Updated_By_System__c) { continue; } // Skiping records as these are created by integration

            Opportunity objOpp = idToOpp.get(objProposal.Apttus_Proposal__Opportunity__c);
            ilib_LogEvent.message('objOpp : '+objOpp);

            //add sold to Quotes to map
            if(String.isNotBlank(objOpp.Account.ERP_Customer_Id__c))
            {
                if (soldToERPIdToProposal.containsKey(objOpp.Account.ERP_Customer_Id__c)){
                    soldToERPIdToProposal.get(objOpp.Account.ERP_Customer_Id__c).add(objProposal);}
                else{
                    soldToERPIdToProposal.put(objOpp.Account.ERP_Customer_Id__c, new List<Apttus_Proposal__Proposal__c>{objProposal});
                }
                soldToERPToSAERP.put(objOpp.Account.ERP_Customer_Id__c,objOpp.Sales_Area_Sold_To__c);
            }

            Boolean booIndirectDistributorScenario = !Opportunities.DIRECT_RECORD_TYPES.contains(objOpp.RecordType.DeveloperName) && !objOpp.Direct_Sale_to_Ultimate_Consignee__c;
            ilib_LogEvent.message('booIndirectDistributorScenario : '+booIndirectDistributorScenario);
            //add UC Quotes to map
            if (!booIndirectDistributorScenario && String.isNotBlank(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c))
            {
                if (ucERPIdToProposal.containsKey(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c)){
                    ucERPIdToProposal.get(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c).add(objProposal);}
                else{
                    ucERPIdToProposal.put(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c, new List<Apttus_Proposal__Proposal__c>{objProposal});
                }
                ucERPToSAERP.put(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c,objOpp.Sales_Area_Ultimate_Consignee__c);
                accountERPToCountry.put(objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c,objOpp.Ultimate_Consignee__r.BillingCountry);

                if (String.isNotBlank(objOpp.Distributor__c)){
                    distributorIdToUCERPId.put(objOpp.Distributor__c,objOpp.Ultimate_Consignee__r.ERP_Customer_Id__c);}
            }

            if (booIndirectDistributorScenario && String.isNotBlank(objOpp.Distributor__r.ERP_Customer_Id__c))
            {
                if (ucERPIdToProposal.containsKey(objOpp.Distributor__r.ERP_Customer_Id__c)){
                    ucERPIdToProposal.get(objOpp.Distributor__r.ERP_Customer_Id__c).add(objProposal);}
                else{
                    ucERPIdToProposal.put(objOpp.Distributor__r.ERP_Customer_Id__c, new List<Apttus_Proposal__Proposal__c>{objProposal});
                }
                ucERPToSAERP.put(objOpp.Distributor__r.ERP_Customer_Id__c,objOpp.Sales_Area_Distributor__c);
            }
        }

        setDistributorId = distributorIdToUCERPId.keyset();
        if (!setDistributorId.isEmpty())
        {
            //CMCM-4516
            //lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setDistributorId);
            lstAccountSalesArea = [SELECT Id,Name,Price_List_Type__c,Account__c,CurrencyIsoCode,ERP_Account_Sales_Area_Id__c,Price_List__c,Term_Of_Payment__c,Contract_Number__c,Company_Code__c,Inco_Term_1__c,Customer_Master_Data__c, Price_Group_Description__c,Price_Group__c,Sales_Organization__c,Distribution_Channel__c,Division__c FROM Account_Sales_Area__c WHERE Account__r.id IN :setDistributorId AND IsInactive__c = false];
            System.debug('lstAccountSalesArea-->' +lstAccountSalesArea);

            for(Account_Sales_Area__c asa : lstAccountSalesArea)
            {
				ilib_LogEvent.message('Account Sales Area Record : '+asa);
                String strUCERPId = distributorIdToUCERPId.get(asa.Account__c);
                if (ucERPToDistSalesArea.containsKey(strUCERPId)) { ucERPToDistSalesArea.get(strUCERPId).add(asa); }
                else { ucERPToDistSalesArea.put(strUCERPId,new List<Account_Sales_Area__c> {asa}); }
            } 
			
        }

        ilib_LogEvent.info('soldToERPIdToProposal: ' + soldToERPIdToProposal);
        ilib_LogEvent.info('ucERPIdToProposal: ' + ucERPIdToProposal);
        ilib_LogEvent.info('soldToERPToSAERP: ' + soldToERPToSAERP);
        ilib_LogEvent.info('ucERPToSAERP: ' + ucERPToSAERP);
        ilib_LogEvent.info('accountERPToCountry: ' + accountERPToCountry);
        ilib_LogEvent.info('ucERPToDistSalesArea: ' + ucERPToDistSalesArea);
        //call service to handle update logic
        AutomateBillToShipToService.setBillToShipTo(
                soldToERPIdToProposal,
                ucERPIdToProposal,
                ucERPToDistSalesArea,
                soldToERPToSAERP,
                ucERPToSAERP,
                accountERPToCountry,
                idToOpp); // DCP-46226
				ilib_LogEvent.pop();
    } 

    private List<CurrencyType> fetchCurrencyTypeRecordsForAllIsoCodes() {
        CurrencyCodesSelector selector = new CurrencyCodesSelector();
        return selector.fetchCurrencyTypeRecordsForAllIsoCodes();
    }

    /**
    * Method to create and return map of Currency ISO Code wise Conversion Rate.
    **/
   private Map<String, Decimal> getCurrencyCodeWiseConversionRate() {
       Map<String, Decimal> currencyCodeWiseConversionRate = new Map<String, Decimal>();
       List<CurrencyType> currencyTypeList = fetchCurrencyTypeRecordsForAllIsoCodes();
       
       for(CurrencyType currType : currencyTypeList) {
           currencyCodeWiseConversionRate.put(currType.IsoCode, currType.ConversionRate);
       }
       
       return currencyCodeWiseConversionRate;
   }


    /**
     *  @author Roopal Verma
     *  @description  Before update trigger method
     **/
    public override void onBeforeUpdate(Map<Id, SObject> idToProposal)
    {
        ilib_LogEvent.push(LOG_TITLE+'onBeforeUpdate()');

        if(skipUpdateTrigger) {
            ilib_LogEvent.info('onBeforeUpdate skipped!'); 
            ilib_LogEvent.pop(); 
            return;
        }

        List<Apttus_Proposal__Proposal__c> lstUpdatedProposal = UtilsCollection.filterOnModified((List<Apttus_Proposal__Proposal__c>)records, (Map<Id, Apttus_Proposal__Proposal__c>) idToProposal);
        List<Apttus_Proposal__Proposal__c> lstProposalsOnOpenOpps = restrictQuoteOnClosedOpportunity((List<Apttus_Proposal__Proposal__c>)records, (Map<Id, Apttus_Proposal__Proposal__c>) idToProposal);
		//List<Apttus_Proposal__Proposal__c> lstProposalsFilteredOnStage = new List<Apttus_Proposal__Proposal__c>();
        List<Apttus_Proposal__Proposal__c> lstProposalsForIlluminaEmail = new List<Apttus_Proposal__Proposal__c>();

        //Check for Approval 
        if (lstProposalsOnOpenOpps.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        
        Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal = (Map<Id,Apttus_Proposal__Proposal__c>)idToProposal;
        Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal = new Map<Id, Apttus_Proposal__Proposal__c>(lstProposalsOnOpenOpps);
        //DCP-46257
        List<Apttus_Proposal__Proposal__c> lstInventoryLocationProposal = new List<Apttus_Proposal__Proposal__c>();
        Set<Id> setDistributorAccount = new Set<Id>();

        //INC0449312 - Moved common queries to onBeforeUpdate() and passed as param
        Map<Id, Opportunity> idToOpportunity;
        if (idToNewProposal.isEmpty()) {
            idToOpportunity = new Map<Id, Opportunity>();
        } else {
            Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(idToNewProposal.values(), 'Apttus_Proposal__Opportunity__c');
            //Map to store Related Opportunity
            //CMCM-4516
            //idToOpportunity =  new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
            idToOpportunity =  new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c,
            Consortium__r.Initial_Sale_Special_Terms__c,Consortium__r.Re_Order_Special_Terms__c,Consortium__r.Stage__c //CMCM-11336
             FROM Opportunity WHERE Id IN :setOpportunityIds]);
        }
        proposalIdToAPCDate = new AnnualPricingScheduleHelper().getAnnualPriceChangeDatebyProposal(idToNewProposal.values(), idToOpportunity);
        setApprovals(idToOldProposal, idToNewProposal, idToOpportunity);     //INC0449312 - Added param - idToOpportunity

        Map<String, Decimal> currencyCodeWiseConversionRate = getCurrencyCodeWiseConversionRate();
        
        for (Apttus_Proposal__Proposal__c objProposal : lstUpdatedProposal)
        {
            // Check is Primary contact or Myillumina Email is changed
            if (objProposal.Apttus_Proposal__Primary_Contact__c != idToOldProposal.get(objProposal.id).Apttus_Proposal__Primary_Contact__c
                || objProposal.MyIllumina_User_Email__c != idToOldProposal.get(objProposal.id).MyIllumina_User_Email__c
                || (objProposal.Apttus_Proposal__Primary_Contact__c != null && objProposal.MyIllumina_User_Email__c == null)
            ) {
                lstProposalsForIlluminaEmail.add(objProposal);
            }
            //DCP-46257
            if(objProposal.Distributor__c != idToOldProposal.get(objProposal.id).Distributor__c){
                if(checkIfNull(objProposal.Distributor__c)){
                    objProposal.Inventory_Location__c = null;
                    ilib_LogEvent.message('objProposal.Inventory_Location__c = null');
                }
                else{
                    lstInventoryLocationProposal.add(objProposal);
                    setDistributorAccount.add(objProposal.Distributor__c);
                }
            }
            if(SET_QUOTE_STAGE.contains(objProposal.Apttus_Proposal__Approval_Stage__c)){
            checkForSubmitForApprovalErrors(objProposal);
            }
            if(objProposal.Post_Pricing_Message__c != idToOldProposal.get(objProposal.id).Post_Pricing_Message__c){
                objProposal.PPM_Last_Modified_Date__c = Datetime.now().formatGMT('yy-MM-dd HH:mm:ss');
                
            }
            if (objProposal.Total_Discount_USD__c == null && objProposal.Total_Discount__c != null && currencyCodeWiseConversionRate.containsKey(objProposal.currencyIsoCode)) {
                objProposal.Total_Discount_USD__c = objProposal.Total_Discount__c / currencyCodeWiseConversionRate.get(objProposal.currencyIsoCode);
            }
            if (objProposal.Total_Discount_USD__c != null && objProposal.Total_Discount__c != null && currencyCodeWiseConversionRate.containsKey(objProposal.currencyIsoCode)) {
                objProposal.Total_Discount_USD__c = objProposal.Total_Discount__c / currencyCodeWiseConversionRate.get(objProposal.currencyIsoCode);
            }
            //CMCM-11328
            if(Feature.isOn('WF_Quotation_Lock_Record_Stage') && idToOldProposal.get(objProposal.id).RecordType.DeveloperName != QUOTE_PROP_READ_ONLY_RECORD_TYPE && (objProposal.Apttus_Proposal__Approval_Stage__c == APPROVAL_STAGE_DENIED || objProposal.Apttus_Proposal__Approval_Stage__c == APPROVAL_STAGE_ACCEPTED)) {
                objProposal.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByDeveloperName().get(QUOTE_PROP_READ_ONLY_RECORD_TYPE).getRecordTypeId();
            }
        }
        //DCP-46257
        if(!setDistributorAccount.isEmpty()){
            ilib_LogEvent.info('setDistributorAccount : '+setDistributorAccount);
            setInventoryLocation(lstInventoryLocationProposal,setDistributorAccount);
        }
        if (!lstProposalsForIlluminaEmail.isEmpty())
        {
            setMyIlluminaEmail(lstProposalsForIlluminaEmail, idToOldProposal);
        }

        //INC0449312 - Added param - idToOpportunity
        checkValidToInSameQuarter(records, idToOldProposal, idToOpportunity);  // was lstProposalsFilteredOnStage
        //ApttusProposalReapprovalHandler.evaluateLinesForReapproval(records,Trigger.newMap,Trigger.oldMap);

        rollUpTermMonths(idToNewProposal);
        updateConsortiaTerms(Trigger.new, idToOpportunity);//cmcm-11336

        
        // added as part of cmcm-11810
        
        List<Apttus_Proposal__Proposal__c> newProposals = (List<Apttus_Proposal__Proposal__c>) trigger.new;
        Map<Id,Apttus_Proposal__Proposal__c> oldProposals = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.oldmap;
        
        addErrorforMultipleQuotesOnWebGenOpp(newProposals,oldProposals);
        
        ilib_LogEvent.pop();
    }



    /**
     *  @author Pradeep Landge
     *  @description  CMCM-11336 | Method to handle the logic for updating Template Consortia Terms And Conditions
    **/
    @TestVisible
    private static void updateConsortiaTerms(List < Apttus_Proposal__Proposal__c > lstProposals, Map < Id, Opportunity > opportunitiesMap) {
        if (Feature.isOn('WF_Quotation_Populate_Consortia')) {
            for (Apttus_Proposal__Proposal__c proposal: lstProposals) {
                if (proposal.Apttus_Proposal__Opportunity__c != null && opportunitiesMap.containsKey(proposal.Apttus_Proposal__Opportunity__c)) {
                    Opportunity opp = opportunitiesMap.get(proposal.Apttus_Proposal__Opportunity__c);

                    if (String.isNotBlank(opp.Consortium__c) && proposal.Invalid_Quote__c == false) {
                        String termsConditions = null;
                        if (opp.Consortium__r.Stage__c == Label.ConsortiumStageEarlyEngagement || opp.Consortium__r.Stage__c == Label.ConsortiumStageInitialSale) {
                            termsConditions = opp.Consortium__r.Initial_Sale_Special_Terms__c;
                        } else if (opp.Consortium__r.Stage__c == Label.ConsortiumStageReOrder) {
                            termsConditions = opp.Consortium__r.Re_Order_Special_Terms__c;
                        }
                        proposal.Template_Consortia_Terms_And_Conditions__c = termsConditions;
                    }
                }
            }
        }
    }


    /**
     *  @author Rahul Sharma
     *  @description Check Valid To Date is In Current Quarter When updated for Generated/Presented Quotes
     *  @parameter lstProposals quotes filtered on stage = generated or presented
     *  @parameter idToOldProposal
     *  @parameter idToOpportunity
     *  INC0449312 - Added param - idToOpportunity
     **/
    public void checkValidToInSameQuarter(List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id,Apttus_Proposal__Proposal__c> idToOldProposal, Map<Id, Opportunity> idToOpportunity)
    {
		ilib_LogEvent.push(LOG_TITLE+'checkValidToInSameQuarter()');
        //map to store quarter number with start and end date
        Map<String, Date> mapQuarterToStartDate = new Map<String, Date>();
        Map<String, Date> mapQuarterToEndDate = new Map<String, Date>();
        List<Apttus_Proposal__Proposal__c> lstUpdatedProposal = new List<Apttus_Proposal__Proposal__c>();

        for (Apttus_Proposal__Proposal__c objProposal : lstProposals)
        {
            // Filter Generated and Presented Quotes
            if (objProposal.Apttus_Proposal__Approval_Stage__c != QUOTE_STAGE_GENERATED
                && objProposal.Apttus_Proposal__Approval_Stage__c != QUOTE_STAGE_PRESENTED){
                continue; }

            if (objProposal.Apttus_Proposal__ExpectedEndDate__c == idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c
                || idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c == null){
                continue; }

            if (objProposal.Apttus_Proposal__ExpectedEndDate__c == null)
            {
                objProposal.addError(Label.UI_ErrorMessage_ValidToDateNotInSameQuarter);
                continue;
            }

            lstUpdatedProposal.add(objProposal);
        }
        if (lstUpdatedProposal.isEmpty()) {ilib_LogEvent.pop(); 
		return; }

        List<Period> lstPeriod = [SELECT EndDate, FullyQualifiedLabel, Id, QuarterLabel, StartDate FROM Period WHERE Type = 'Quarter'];
        
        //CMCM-2523 fetch approval requests and check if DSM Price change approval is already obtained
        string queryApprovalReq = 'SELECT Id,Name,Apttus_QPApprov__ProposalId__c,Apttus_Approval__Sequence__c,Apttus_Approval__Step_Name__c,'
            +' Apttus_Approval__StepLabel__c,Apttus_Approval__StepSequenceString__c'
            +' FROM Apttus_Approval__Approval_Request__c '
            +' WHERE Apttus_QPApprov__ProposalId__c IN :lstUpdatedProposal AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c != NULL '
            +' ORDER BY Apttus_Approval__StepSequenceString__c ASC, Apttus_Approval__Sequence__c ASC NULLS FIRST, Apttus_Approval__StepLabel__c ASC NULLS FIRST';
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequests = Database.query(queryApprovalReq);
        //DateTime dtPriceChange = DateTime.valueOf(codeParameterPricingDate.Value__c + ' 00:00:00');    

        for (Apttus_Proposal__Proposal__c objProposal : lstUpdatedProposal)
        {
            String strValidToYear = String.valueOf(idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c.YEAR());
            System.debug('strValidToYear: '+strValidToYear);
            ilib_LogEvent.message('strValidToYear : '+strValidToYear);

            if (!lstPeriod.isEmpty())
            {
                for (Period pd : lstPeriod)
                {
                    if (pd.FullyQualifiedLabel.contains(strValidToYear))
                    {
                        mapQuarterToStartDate.put(pd.QuarterLabel, pd.StartDate);
                        mapQuarterToEndDate.put(pd.QuarterLabel, pd.EndDate);
                    }
                }
            }
			ilib_LogEvent.info('mapQuarterToStartDate : '+mapQuarterToStartDate);
			ilib_LogEvent.info('mapQuarterToEndDate : '+mapQuarterToEndDate);

            String newFiscalQuarter;
            String oldFiscalQuarter;
            for (String quarterNum : mapQuarterToStartDate.keySet())
            {
                ilib_LogEvent.message('quarterNum : '+quarterNum);
                if (objProposal.Apttus_Proposal__ExpectedEndDate__c >= mapQuarterToStartDate.get(quarterNum)
                   && objProposal.Apttus_Proposal__ExpectedEndDate__c <= mapQuarterToEndDate.get(quarterNum)
                ) {
                       newFiscalQuarter = quarterNum;
                }

                if (idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c >= mapQuarterToStartDate.get(quarterNum)
                   && idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c <= mapQuarterToEndDate.get(quarterNum)
                ) {
                       oldFiscalQuarter = quarterNum;
                }
				ilib_LogEvent.message('oldFiscalQuarter : '+oldFiscalQuarter);
				ilib_LogEvent.message('newFiscalQuarter : '+newFiscalQuarter);
            }

            if (oldFiscalQuarter != newFiscalQuarter
                && objProposal.Apttus_Proposal__ExpectedEndDate__c >= idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c // DCP-29916 by @Pragna, SonarCube by Arnab
            ) {
                objProposal.addError(Label.UI_ErrorMessage_ValidToDateNotInSameQuarter);
            }
            //DCP-58707
            // CMCM-2523 - for this proposal find whether extend Pre-Price change pricing approval is already obtained and set flag
            Boolean isApprovalObtained = checkIsPriceChangeApprovalObtained(objProposal, lstApprovalRequests);
            DateTime dtPriceChange = null;
            // CMCM-2523 Get the Annual price change date for this quote
            if(proposalIdToAPCDate != null && proposalIdToAPCDate.containsKey(objProposal.id)){
                dtPriceChange = proposalIdToAPCDate.get(objProposal.id);
            }
            if (dtPriceChange != null && dtPriceChange>= Date.today() && objProposal.Apttus_Proposal__ExpectedEndDate__c >= dtPriceChange 
                && (objProposal.Quote_Sub_Type__c == OPPORTUNITY_TYPE_REORDER_NON_CONSORTIUM_CONSUMABLE 
                || objProposal.Quote_Sub_Type__c == OPPORTUNITY_TYPE_STANDARD_SALE) 
                && idToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Price_List_Type__c != null
                && (idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c == null
                || idToOldProposal.get(objProposal.Id).Apttus_Proposal__ExpectedEndDate__c  + APCD_THRESHOLD_DAYS >= dtPriceChange)
                && !isApprovalObtained ) {
                objProposal.addError(Label.UI_ErrorMessage_ValidToDatePastPriceChange);
            }
        }
		ilib_LogEvent.pop();
    }

    /**CMCM-2523
     * Method to check if the quote already obtained Sales Manager - Extend Pre-Price Change Pricing approval
     * We don't check approval status here because we validate Generated and Presented quotes only.
     * */
    private boolean checkIsPriceChangeApprovalObtained(Apttus_Proposal__Proposal__c proposal, List<Apttus_Approval__Approval_Request__c> lstApprovalRequests) {
        boolean isApprovalObtained = false;
        for(Apttus_Approval__Approval_Request__c approvalRequest: lstApprovalRequests) {
            if(proposal.id == approvalRequest.Apttus_QPApprov__ProposalId__c 
                && approvalRequest.Apttus_Approval__Step_Name__c == APPROVAL_STEP_NAME_PRICING_CHANGE) {
                isApprovalObtained = true;
                break;
            }
        }
        return isApprovalObtained;
    }
    
    /*Share quote with Appropriate Owners */
    public void quoteSharingWithAppropriateOwners(List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, SObject> idToProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'quoteSharingWithAppropriateOwners()');
        if (hasRunTaps || isInsertOperationForObject(getSObjectType())) {ilib_LogEvent.pop(); 
            return; }

        List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId' };
        TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        Set<Id> idsWithNewOwners = tapsOrchestratorInst.updateRequiresRecalculation(lstProposal, idToProposal, fieldsThatTriggerRecalculation);
		

        if (idsWithNewOwners.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        ilib_LogEvent.info('idsWithNewOwners : '+idsWithNewOwners);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, getSObjectType());
        // Commenting as part of DCP-43261/TASK0548217
        //TAPS_Orchestrator.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__ProductConfiguration__c.SObjectType);
        TAPS_SharingUsingFuture.recFutureSharing(idsWithNewOwners, string.valueOf(Apttus_Config2__ProductConfiguration__c.SObjectType));
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__FavoriteConfiguration__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__TempObject__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__Order__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__AssetLineItem__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__AssetLineItemHistory__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Approval__Approval_Request__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Approval__Approval_Request_History__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__TempRenewAssetGroup__c.SObjectType);
        tapsOrchestratorInst.recalculateRecordChanges(idsWithNewOwners, Apttus_Config2__TempRenewAssetLineItem__c.SObjectType);
        hasRunTaps = true;
		ilib_LogEvent.pop();
    }

     /**
     *  @author Vishal Reddy
     *  @description  Runs in onAfterUpdate, queries the line items for all proposals submitted for approval and calls sendEmailForMissingProductCode for each proposal 
     *  @parameter Map of Old Quote/Proposal, map of New Quote/Proposal
     **/
    public static void checkProductsForMissingCodes(Map<Id,Apttus_Proposal__Proposal__c> newMap, Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        Set<Id> setProposalIdApprovalSubmitted = new Set<Id>();
        ilib_LogEvent.info('newMap: '+newMap);
        ilib_LogEvent.info('oldMap: '+oldMap);
        
        for(Apttus_Proposal__Proposal__c prpsl : newMap.values())
        {
            ilib_LogEvent.message('updated proposal approval stage: '+prpsl.Apttus_Proposal__Approval_Stage__c);
            ilib_LogEvent.message('old proposal approval stage: '+oldMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c);
            ilib_LogEvent.message('approval submitted proposal: '+prpsl.id);

            if((prpsl.Apttus_Proposal__Approval_Stage__c == 'Approved' 
                ||prpsl.Apttus_Proposal__Approval_Stage__c == 'In Review') 
                && oldMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c == 'Approval Required')
                {
                    setProposalIdApprovalSubmitted.add(prpsl.Id);
                }
        }
        ilib_LogEvent.info('setProposalIdApprovalSubmitted: '+setProposalIdApprovalSubmitted);
        Map<Id, Map<String, List<Apttus_Proposal__Proposal_Line_Item__c>>> mapForEmail = new Map<Id, Map<String, List<Apttus_Proposal__Proposal_Line_Item__c>>>();
        List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPli = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        if(!setProposalIdApprovalSubmitted.isEmpty()){
            //CMCM-4516
            // lstPli = new ApttusProposalLineItemsSelector().selectByQuoteId(setProposalIdApprovalSubmitted);
            lstPli = proposalsSelectByQuoteId(setProposalIdApprovalSubmitted);
        }
        for(Apttus_Proposal__Proposal_Line_Item__c pli : lstPli){
            ilib_LogEvent.message('pli product material type: '+pli.Apttus_Proposal__Product__r.material_type__c);
            ilib_LogEvent.message('Is HSN empty?: '+String.isBlank(pli.Commodity_Import_Code_India_HSN__c));
            ilib_LogEvent.message('Is SAC empty?: '+String.isBlank(pli.Control_Code_India_SAC__c));
                if(pli.Apttus_Proposal__Product__r.material_type__c != MATERIAL_TYPE_ZDIN && String.isBlank(pli.Commodity_Import_Code_India_HSN__c) && pli.Sold_To_Sales_Organization__c == SALES_ORG_INDIA){
                    ilib_LogEvent.message('pli with missing HSN:' + pli.id);
                    if(mapForEmail.containsKey(pli.Apttus_Proposal__Proposal__c)){
                        if(mapForEmail.get(pli.Apttus_Proposal__Proposal__c).containsKey(HSN)){
                            mapForEmail.get(pli.Apttus_Proposal__Proposal__c).get(HSN).add(pli);
                        }
                        else{
                            mapForEmail.get(pli.Apttus_Proposal__Proposal__c).put(HSN,new List<Apttus_Proposal__Proposal_Line_Item__c>{pli});
                        }
                    }
                    else{
                        mapForEmail.put(pli.Apttus_Proposal__Proposal__c, new map<String, List<Apttus_Proposal__Proposal_Line_Item__c>>{'HSN'=>new List<Apttus_Proposal__Proposal_Line_Item__c>{pli}});
                    }
                }
                else if(pli.Apttus_Proposal__Product__r.material_type__c == MATERIAL_TYPE_ZDIN && String.isBlank(pli.Control_Code_India_SAC__c) && pli.Sold_To_Sales_Organization__c == SALES_ORG_INDIA){
                    ilib_LogEvent.message('pli with missing sac:' + pli.id);
                    if(mapForEmail.containsKey(pli.Apttus_Proposal__Proposal__c)){
                        if(mapForEmail.get(pli.Apttus_Proposal__Proposal__c).containsKey(SAC)){
                            mapForEmail.get(pli.Apttus_Proposal__Proposal__c).get(SAC).add(pli);
                        }
                        else{
                            mapForEmail.get(pli.Apttus_Proposal__Proposal__c).put(SAC,new List<Apttus_Proposal__Proposal_Line_Item__c>{pli});
                        }
                    }
                    else{
                        mapForEmail.put(pli.Apttus_Proposal__Proposal__c, new map<String, List<Apttus_Proposal__Proposal_Line_Item__c>>{'SAC'=>new List<Apttus_Proposal__Proposal_Line_Item__c>{pli}});
                    }
                }
        }

        ilib_LogEvent.info('mapForEmail : '+mapForEmail);
        for (Id proposalId : mapForEmail.keyset()){
            lstMails.addAll(sendEmailForMissingProductCode(mapForEmail.get(proposalId)));
        }
		ilib_LogEvent.info('lstMails : '+lstMails);
		ilib_LogEvent.pop();
        Messaging.sendEmail(lstMails);
    }

    /**
     *  @author Rohan Chandarana
     *  @description  After update trigger method (e,g, sync primary quote to opportunity on swaping of primary quote)
     *  @parameter Map of Old Quote/Proposal
     **/
    public override void onAfterUpdate(Map<Id, SObject> idToOldProposal)
    {
        ilib_LogEvent.info('in onafterupdate()');

        if(skipUpdateTrigger) {
            ilib_LogEvent.info('onAfterUpdate skipped!'); 
            ilib_LogEvent.pop(); 
            return;
        }

        if(!TestAutomateBillToShipToService.boolDontRunLogic){
            //DCP-43259 Quote Improvements        
            Map<Id,Apttus_Proposal__Proposal__c> newMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.newMap;
            Map<Id,Apttus_Proposal__Proposal__c> oldMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.oldMap;
            
            checkProductsForMissingCodes(newMap,oldMap);

            if(!boolRecursiveCheck){
                autoGenerateQuoteDocumentWhenApproved(); }	
            updateQuoteStageOnOpp(trigger.newMap,trigger.oldMap);
            
            //DCP-43259 Quote Improvements
            autoPopulateFieldsOnUpdate(false);

            ilib_Queueablethread queueableThreadAfterUpdate = new ilib_Queueablethread('ApttusProposalsAfterUpdate');         
            syncPrimaryQuotesToOpportunities(idToOldProposal);

            updatePricing((Map<Id, Apttus_Proposal__Proposal__c>)idToOldProposal);

            quoteSharingWithAppropriateOwners(records, idToOldProposal);

            setShipToSalesOrgForOpportunity(idToOldProposal);
            if(!isQuoteUpdatedFromOpty){
                queueableThreadAfterUpdate.logandQueue(new ApttusProposalQueueable(ApttusProposalQueueable.STRING_UPDATEPRIMARYCONTACTONOPPORTUNITYCONTACTROLE ,(List<Apttus_Proposal__Proposal__c>)records, (Map<Id, Apttus_Proposal__Proposal__c>)idToOldProposal),'ApttusProposalQueueable', ApttusProposalQueueable.STRING_UPDATEPRIMARYCONTACTONOPPORTUNITYCONTACTROLE);}

            if(queueableThreadAfterUpdate!=null && !boolHasRunOnce && checkIsPrimaryQuoteAndPrimaryContactUpdated((List<Apttus_Proposal__Proposal__c>)records, (Map<Id, Apttus_Proposal__Proposal__c>)idToOldProposal)){ //Koustubh M, TASK0679416, 17th Dec 2021 :- Bug fix - Multiple queueables were getting queued in the same batchable context.
                ilib_QueueableManager.enqueueJob(queueableThreadAfterUpdate,ilib_LogEvent.SALES);} 	

            //DCP-43259 Quote Improvements
            checkIsUpdatedBySystem(false);	
            //<--DGP-31-->
            ApttusProposalReapprovalHandler.evaluateLinesForReapproval(records,Trigger.newMap,Trigger.oldMap);
            //<---DGP-31 End--->
        }   
    }

    /**
     *  @author Koustubh M
     *  @description TASK0679416, 17th Dec 2021 :- Bug fix - Multiple queueables were getting queued in the same batchable context.
     **/
    private boolean checkIsPrimaryQuoteAndPrimaryContactUpdated(List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal){
        ilib_LogEvent.push(LOG_TITLE+'checkIsPrimaryQuoteAndPrimaryContactUpdated()');
        for(Apttus_Proposal__Proposal__c objProposal : lstProposal){
            Apttus_Proposal__Proposal__c objOldProposal = idToOldProposal.get(objProposal.Id);
            if((objProposal.Apttus_Proposal__Primary__c && objProposal.Apttus_Proposal__Primary_Contact__c != objOldProposal.Apttus_Proposal__Primary_Contact__c) || 
               (objProposal.Apttus_Proposal__Primary__c != objOldProposal.Apttus_Proposal__Primary__c && objProposal.Apttus_Proposal__Primary__c)){
					ilib_LogEvent.message('Return true');
					ilib_LogEvent.pop();
                    return true;
                }
        }
		ilib_LogEvent.message('Return false');
		ilib_LogEvent.pop();
        return false;

    }

    /**
     *  @author Govind Dubey
     *  @description To update the Pricing Line Items as null if Quote Pricing date is of future.
     **/
    public void updatePricing(Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'updatePricing()');
        // only update pricing if one of these fields was changed
        List<String> priceFields = new List<String> { 'Apttus_QPConfig__PriceListId__c', 'Contract_Numbers__c', 'Apttus_QPConfig__PricingDate__c', 'Inco_Term_1__c' };
        Set<Id> changedPriceValuesIds = UtilsCollection.filterForFieldChanges(records, idToOldProposal, priceFields);
        if (changedPriceValuesIds.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        ilib_LogEvent.info('changedPriceValuesIds : '+changedPriceValuesIds);
        // create maps for old and new values of changed quotes
        Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal = new Map<Id, Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)records);
        Map<Id, Apttus_Proposal__Proposal__c> idToRepricedProposal = new Map<Id, Apttus_Proposal__Proposal__c>();
        Map<Id, Apttus_Proposal__Proposal__c> idToOldRepricedProposal = new Map<Id, Apttus_Proposal__Proposal__c>();
        for (Id i : changedPriceValuesIds)
        {
            idToRepricedProposal.put(i, idToNewProposal.get(i));
            idToOldRepricedProposal.put(i, idToOldProposal.get(i));
        }
		ilib_LogEvent.info('idToRepricedProposal Ids : '+(idToRepricedProposal !=NULL ? String.valueOf(idToRepricedProposal.keySet()):MAPISEMPTY));
		ilib_LogEvent.info('idToOldRepricedProposal Ids : '+(idToOldRepricedProposal !=NULL ? String.valueOf(idToOldRepricedProposal.keySet()):MAPISEMPTY));

        // get carts associated with the changed quotes
        //CMCM-4516
        // List<Apttus_Config2__ProductConfiguration__c> lstRelatedCarts = new ApttusProductConfigurationsSelector().selectConfigsByQuote(changedPriceValuesIds);// INC0321438 - method name updated.
        List<Apttus_Config2__ProductConfiguration__c> lstRelatedCarts = selectConfigsByQuote(changedPriceValuesIds);
        
        // INC0321438 - populate proposalIdToCart Map with Proposal Id as key and latest cart as value instead of List of Carts since latest cart is used for further processing
        Map<Id, Apttus_Config2__ProductConfiguration__c> proposalIdToCart = new Map<Id, Apttus_Config2__ProductConfiguration__c>();
        Set<Id> setProductConfigIds = new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c relatedCart : lstRelatedCarts){
            if(!proposalIdToCart.containsKey(relatedCart.Apttus_QPConfig__Proposald__c)){
                proposalIdToCart.put(relatedCart.Apttus_QPConfig__Proposald__c, relatedCart);
                setProductConfigIds.add(relatedCart.Id);
            }
        }
		ilib_LogEvent.info('proposalIdToCart Ids : '+(proposalIdToCart !=NULL ? String.valueOf(proposalIdToCart.keySet()):MAPISEMPTY));
        ilib_LogEvent.info('setProductConfigIds : '+setProductConfigIds);
        // INC0321438 - get cart line items associated with cartList
        //CMCM-4516
        // List<Apttus_Config2__LineItem__c> lstRelatedConfigLines = new ApttusLineItemsSelector().selectLineItemsByConfigId(setProductConfigIds);
        List<Apttus_Config2__LineItem__c> lstRelatedConfigLines = selectLineItemsByConfigId(setProductConfigIds);
        Map<Id, List<Apttus_Config2__LineItem__c>> configIdToConfigLines = UtilsCollection.getMapOfIdToSObjects(lstRelatedConfigLines, 'Apttus_Config2__ConfigurationId__c');

        List<Apttus_Config2__ProductConfiguration__c> lstCartsToUpdate = new List<Apttus_Config2__ProductConfiguration__c>();
        List<Apttus_Config2__LineItem__c> lstLineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
        Map<Id, Id> cartIdToPricelistId = new Map<Id, Id>();

        for (Id idProposal : changedPriceValuesIds)
        {
            Apttus_Proposal__Proposal__c newProposal = idToRepricedProposal.get(idProposal);
            Apttus_Proposal__Proposal__c oldProposal = idToOldRepricedProposal.get(idProposal);

            // if no carts move on
            if (!proposalIdToCart.containsKey(idProposal)) { continue; }

            // QUESTION: why only the first cart?
            // INC0321438 - Updated List to single Sobject since only the first cart record is used for processing
            Apttus_Config2__ProductConfiguration__c objCart = proposalIdToCart.get(idProposal);

            // if cart is already finalized or saved move on
            if (objCart.Apttus_Config2__Status__c != Label.ConfigurationStatusFinalized && objCart.Apttus_Config2__Status__c != Label.ConfigurationStatusSaved)
                { continue; }

            objCart.Apttus_Config2__Status__c = Label.ConfigurationStatusSaved;
            objCart.Apttus_Config2__IsPricePending__c = true;
            lstCartsToUpdate.add(objCart);

            // if pricelist has changed, need to call Apttus API to reprice it
            if (newProposal.Apttus_QPConfig__PriceListId__c != oldProposal.Apttus_QPConfig__PriceListId__c){
                cartIdToPricelistId.put(objCart.Id, newProposal.Apttus_QPConfig__PriceListId__c);}

            if (newProposal.Contract_Numbers__c != oldProposal.Contract_Numbers__c){
                objCart.Apttus_Config2__ContractNumbers__c = newProposal.Contract_Numbers__c;}

            if (newProposal.Apttus_QPConfig__PricingDate__c != oldProposal.Apttus_QPConfig__PricingDate__c){
                objCart.Apttus_Config2__EffectiveDate__c = newProposal.Apttus_QPConfig__PricingDate__c;}

            for (Apttus_Config2__LineItem__c lineItem : configIdToConfigLines.get(objCart.Id))   //INC0321438 - Iterate through separately queried Cart LineItems List
            {
                lineItem.Apttus_Config2__PriceListItemId__c = null;
                lineItem.Apttus_Config2__PricingStatus__c = LINE_PRICING_STATUS_PENDING;
                lineItem.Global_Trade_Block__c = false;
                lstLineItemsToUpdate.add(lineItem);
            }
        }

        // NOTE: async candidate (both updates)
        if (!lstCartsToUpdate.isEmpty()){
            update lstCartsToUpdate;}

        if (!lstLineItemsToUpdate.isEmpty()){
            update lstLineItemsToUpdate;}

        // reprice carts where pricelist was changed
        if (!cartIdToPricelistId.isEmpty())
        {
            for (Id id : cartIdToPricelistId.keyset()) {
                Apttus_Config2.CPQWebService.updateEffectivePriceListForCart(id, cartIdToPricelistId.get(id));
            }
        }
		ilib_LogEvent.pop();
    }

    private void syncPrimaryQuotesToOpportunities(Map<Id, SObject> idToOldProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'syncPrimaryQuotesToOpportunities()');
        Set<Id> setUpdatedToPrimaryProposals = new Set<Id>();
        //DCP-38808: Start - declare platform event list
        List<Admin_Operation__e> lstQuoteAmountUpdates = new List<Admin_Operation__e>();
        //DCP-38808: End - declare platform event list
        for (Apttus_Proposal__Proposal__c objProposal : (List<Apttus_Proposal__Proposal__c>)records)
        {
            Apttus_Proposal__Proposal__c oldProposal = (Apttus_Proposal__Proposal__c)idToOldProposal.get(objProposal.Id);

            if (objProposal.Apttus_Proposal__Primary__c == true
                && objProposal.Apttus_Proposal__Primary__c != oldProposal.Apttus_Proposal__Primary__c)
            {
                setUpdatedToPrimaryProposals.add(objProposal.id);
            }
            //DCP-38808: Start - Add records to platform event list if quote amount changes or quote becomes primary
            if(objProposal.Apttus_Proposal__Primary__c && String.isNotBlank(objProposal.Work_Order__c) &&
                ((!oldProposal.Apttus_Proposal__Primary__c) ||           //quote is made primary
                (objProposal.Total_Net__c!=oldProposal.Total_Net__c))    // quote amount has changed
            )
            {   lstQuoteAmountUpdates.add(new Admin_Operation__e(Related_Record__c=objProposal.id,Name__c='UpdateQuoteAmountOnWO'));    }
            //DCP-38808: End - Add records to platform event list if quote amount changes or quote becomes primary
        }
		ilib_LogEvent.info('setUpdatedToPrimaryProposals : '+setUpdatedToPrimaryProposals);
        //DCP-38808: Start - Publish platform event
        if(!lstQuoteAmountUpdates.isEmpty()) {
			ilib_LogEvent.message('publishing platform event');
            EventBus.publish(lstQuoteAmountUpdates);
        }
        //DCP-38808: End - Publish platform event

        if (!setUpdatedToPrimaryProposals.isEmpty())
        {
            //Updated - Using ilib_QueueableManager Interface
            ApttusSyncToOpportunityQueueable queueableClassInstance = new ApttusSyncToOpportunityQueueable(setUpdatedToPrimaryProposals);
            ilib_Queueablethread queueableThread = new ilib_Queueablethread('AfterUpdateProposals');
            queueableThread.logAndQueue(queueableClassInstance, 'ApttusSyncToOpportunityQueueable', 'execute');
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);  
        }
		ilib_LogEvent.pop();
    }

    /**
     *  @author Roopal Verma
     *  @description  Method to add error if there is any updation, insertion or cloning of quote happened on closed opportunity DCP-3899
     *  @parameter List of Quote/Proposal
     *  @return  List of open Quote/Proposal.
     **/
    public List<Apttus_Proposal__Proposal__c> restrictQuoteOnClosedOpportunity(List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'restrictQuoteOnClosedOpportunity()');
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(lstProposal, 'Apttus_Proposal__Opportunity__c');
		ilib_LogEvent.info('setOpportunityIds : '+setOpportunityIds);
        //CMCM-4516
        //Map<Id, Opportunity> idToOportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
        Map<Id, Opportunity> idToOportunity = new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c FROM Opportunity WHERE Id IN :setOpportunityIds]);

        List<Apttus_Proposal__Proposal__c> lstProposalForOpenOpty = new List<Apttus_Proposal__Proposal__c>();
        Boolean boolIsUpdate = false;

        for (Apttus_Proposal__Proposal__c objProposal : lstProposal)
        {
            Apttus_Proposal__Proposal__c objProposalOld;
            if (idToOldProposal != null){
                objProposalOld = idToOldProposal.get(objProposal.id);
				ilib_LogEvent.message('objProposalOld : '+objProposalOld);
                boolIsUpdate = true;
            }

            Boolean boolIsOpportunityClosed = false;

            if (boolIsUpdate && objProposal.Apttus_Proposal__Approval_Stage__c == QUOTE_STAGE_GENERATED && objProposalOld.Apttus_Proposal__Approval_Stage__c == QUOTE_STAGE_PRESENTED && objProposal.View_Contract__c == false && objProposalOld.View_Contract__c == true){
                objProposal.Apttus_Proposal__Approval_Stage__c = QUOTE_STAGE_PRESENTED;
				ilib_LogEvent.message('objProposal.Apttus_Proposal__Approval_Stage__c : '+objProposal.Apttus_Proposal__Approval_Stage__c);
            }

            if (String.isNotBlank(objProposal.Apttus_Proposal__Opportunity__c) && idToOportunity.containsKey(objProposal.Apttus_Proposal__Opportunity__c)) {
                boolIsOpportunityClosed = Opportunities.checkOpportunityClosedStage(idToOportunity.get(objProposal.Apttus_Proposal__Opportunity__c));
				ilib_LogEvent.message('boolIsOpportunityClosed : '+boolIsOpportunityClosed);
				}

            if (boolIsOpportunityClosed
                    && objProposal.Is_Updated_By_System__c == false
                    && (objProposalOld == null || objProposalOld.Is_Updated_By_System__c == objProposal.Is_Updated_By_System__c)
            ) {
                objProposal.addError(Label.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity);
                System.debug('Added Error ' + Label.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity);
            }
            else if((objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageDraft 
                || objProposal.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageApprovalRequired) && String.isBlank(objProposal.Work_Order__c)//INC0423774
                && !objProposal.Transborder_Flag__c)//PRB0049668
            {
                //56658
                    Id accountOwnerID = OpportunitiesHelper.getAccountOwnerId(idToOportunity.get(objProposal.Apttus_Proposal__Opportunity__c),objProposal);
                    objProposal.Approval_Hierarchy_Record_Owner__c = OpportunitiesHelper.getAccountHierarchy(accountOwnerID);
                    lstProposalForOpenOpty.add(objProposal);
            }
            else {
                lstProposalForOpenOpty.add(objProposal);    //INC0423774
            }
        }
		ilib_LogEvent.pop();

        return lstProposalForOpenOpty;
    }

    /**
     *  @author Govind Dubey
     *  @description To compare the Ultimate consignee and Sold To Regions
     *  @param Maps of old proposal and new proposals
     *  @return set of Trans Region Proposals
     **/
    private Set<Id> getTransRegionProposalIds(Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal, Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'getTransRegionProposalIds()');
        Set<Id> setTransRegionProposals = new Set<Id>();

        // collect quotes for which account lookups were modified
        // and collect the related accounts (Sold To, UC, Distributor)
        List<Apttus_Proposal__Proposal__c> quotesWithModifiedAccounts = new List<Apttus_Proposal__Proposal__c>();
        Set<Id> setAccountIds = new Set<Id>();
        for (Id idProposal : idToNewProposal.keySet())
        {
            Apttus_Proposal__Proposal__c objProposalNew = idToNewProposal.get(idProposal);
            Apttus_Proposal__Proposal__c objProposalOld = idToOldProposal.get(idProposal);
			ilib_LogEvent.message('objProposalNew : '+objProposalNew);
			ilib_LogEvent.message('objProposalOld : '+objProposalOld);

            // check direct trans region
            if (objProposalNew.Transregion_Flag__c
                || ((objProposalNew.Ultimate_Consignee__c != null && objProposalNew.Apttus_Proposal__Account__c != null)
                    && isTransRegionApprovalCheckRequired(objProposalOld, objProposalNew))
            ) {
                quotesWithModifiedAccounts.add(objProposalNew);
                setAccountIds.add(objProposalNew.Apttus_Proposal__Account__c);
                setAccountIds.add(objProposalNew.Ultimate_Consignee__c);
            }

            // check the indirect trans region
            if (objProposalNew.Indirect_Transregion_Flag__c
                || ((objProposalNew.Ultimate_Consignee__c != null && objProposalNew.Distributor__c != null)
                    && isIndirectTransRegionApprovalCheckRequired(objProposalOld, objProposalNew))
            ) {
                quotesWithModifiedAccounts.add(objProposalNew);
                setAccountIds.add(objProposalNew.Distributor__c);
                setAccountIds.add(objProposalNew.Ultimate_Consignee__c);   
            }
        }
		ilib_LogEvent.info('setAccountIds : '+setAccountIds);

        if (quotesWithModifiedAccounts.isEmpty()){ilib_LogEvent.pop(); 
		return setTransRegionProposals; }

        //CMCM-4516
        // Map<Id, Account> idToAccount = new Map<Id, Account> (new AccountsSelector().selectAccounts(setAccountIds));
        Map<Id, Account> idToAccount = new Map<Id, Account> (selectAccounts(setAccountIds));
        for (Apttus_Proposal__Proposal__c objProp : quotesWithModifiedAccounts)
        {
            // for direct trans region
            if (idToAccount.containsKey(objProp.Ultimate_Consignee__c) && idToAccount.containsKey(objProp.Apttus_Proposal__Account__c))
            {
                String strUCRegion = idToAccount.get(objProp.Ultimate_Consignee__c).Territory_Region__c;
                String strSoldToRegion = idToAccount.get(objProp.Apttus_Proposal__Account__c).Territory_Region__c;

                if (strSoldToRegion != null && strUCRegion != null && strSoldToRegion != strUCRegion){
                    setTransRegionProposals.add(objProp.id);}
            }

            // for indirect Trans Region
            if (objProp.Indirect_Transregion_Flag__c)
            {
                if (idToAccount.containsKey(objProp.Ultimate_Consignee__c) && idToAccount.containsKey(objProp.Distributor__c))
                {
                    String strUCRegion = idToAccount.get(objProp.Ultimate_Consignee__c).Territory_Region__c;
                    String strDistRegion = idToAccount.get(objProp.Distributor__c).Territory_Region__c; 

                    if (strDistRegion != null && strUCRegion != null && strDistRegion != strUCRegion){
                        setTransRegionProposals.add(objProp.id);}
                }
            }
        }
		ilib_LogEvent.info('setTransRegionProposals : '+setTransRegionProposals);
		ilib_LogEvent.pop();

        return setTransRegionProposals;
    }

    /**
    *  @description setting approvals
    *  INC0449312 - Added param - idToOpportunity
    **/
    private void setApprovals(Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal, Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal, Map<Id, Opportunity> idToOpportunity)
    {
		ilib_LogEvent.push(LOG_TITLE+'setApprovals()');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries());

        if (idToNewProposal.keySet().isEmpty()){ilib_LogEvent.pop(); 
		return; }

        CustomApprovalMatrixWrapper objCustomMatrixWrapper = getCustomApprovalMatrixWrapper();
        if (objCustomMatrixWrapper == null){ilib_LogEvent.pop(); 
		return; }
    
        Map<Id, Apttus_Proposal__Proposal__c> idToFilteredProposals = new Map<Id, Apttus_Proposal__Proposal__c>(idToNewProposal.values());
		ilib_LogEvent.info('idToFilteredProposals Ids : '+(idToFilteredProposals !=NULL ? String.valueOf(idToFilteredProposals.keySet()):MAPISEMPTY));
        Map<Id, String> proposalIdToDefaultPaymentTerm = getProposalIdToDefaultPaymentTerm(idToFilteredProposals);
        Map<Id, String> proposalIdToDefaultIncoTerm = getProposalIdToDefaultIncoTerm(idToFilteredProposals); //DCP-25455 getting default inco term value

        List<Post_Pricing_Messages__c> lstPostPricingMessages = new List<Post_Pricing_Messages__c>();
        if (objCustomMatrixWrapper.setPostPriceMesage.contains('Non-Standard Post Pricing Message'))
        {
            //CMCM-4516
            //lstPostPricingMessages  = new PostPricingMessageSelector().selectPostPricingMessageByDeveloperName('Non_Standard_Post_Pricing_Message');
            lstPostPricingMessages  = [SELECT Name, Value__c, PicklistValue__c, Preferred_Language__c, Active__c FROM Post_Pricing_Messages__c WHERE Name LIKE 'Non_Standard_Post_Pricing_Message%'];
        }
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('2. Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        Set<String> setNonStandardPPM = new Set<String>();
        if (!lstPostPricingMessages.isEmpty())
        {
            for (Post_Pricing_Messages__c ppm : lstPostPricingMessages){
                setNonStandardPPM.add(ppm.PicklistValue__c); }
        }
		ilib_LogEvent.info('setNonStandardPPM : '+setNonStandardPPM);

        Map<String, String> territoryRegionToPaymentTermValues = getTerritoryRegionToPaymentTermValues();

        Set<Id> setTransRegionProposals = getTransRegionProposalIds(idToOldProposal, idToNewProposal);

        for (Apttus_Proposal__Proposal__c objProposalNew : idToNewProposal.values()) {
            String strApprovalCategory = '';
            //commented for TASK0876760: String strLatestPaymentTermRecId =  '';//DCP-40114
            String strLatestIncoTermRecId =  '';//DCP-40114
            Boolean boolCountryCheck = false; //DCP-40114
            Boolean boolCountryIncludeCheck = false; //DCP-40114
            if (fieldToApprovalType.containsKey(FIELD_TRANSREGION_FLAG) && setTransRegionProposals.contains(objProposalNew.Id))
            {
                strApprovalCategory += ';' + fieldToApprovalType.get(FIELD_TRANSREGION_FLAG);
            }

            if (fieldToApprovalType.containsKey(FIELD_INDIRECT_TRANSREGION_FLAG) && setTransRegionProposals.contains(objProposalNew.Id))
            {
                strApprovalCategory += ';' + fieldToApprovalType.get(FIELD_INDIRECT_TRANSREGION_FLAG);
            }

            // add subtype for consortia quotes DCP-25456
            if (fieldToApprovalType.containsKey(FIELD_QUOTE_SUB_TYPE)
                && (objProposalNew.Quote_Sub_Type__c == OPPORTUNITY_TYPE_CONSORTIUM
                    || objProposalNew.Quote_Sub_Type__c == OPPORTUNITY_TYPE_REORDER_CONSORTIUM_CONSUMABLE)
            ) {
                strApprovalCategory += ';' + fieldToApprovalType.get(FIELD_QUOTE_SUB_TYPE);
            }

            // given the region, get the payment terms that require approval
            String strApprovalRequiredPaymentTermValues = getApprovalRequiredPaymentTermValues(objProposalNew, territoryRegionToPaymentTermValues);

            if (proposalIdToDefaultPaymentTerm.get(objProposalNew.Id) != objProposalNew.Apttus_Proposal__Payment_Term__c
                && objCustomMatrixWrapper.setPaymentTermRegion.contains(objProposalNew.Territory_Region__c)
                && objProposalNew.Apttus_Proposal__Payment_Term__c != null
                && strApprovalRequiredPaymentTermValues.contains(objProposalNew.Apttus_Proposal__Payment_Term__c))
            {
/* TASK0876760
                if((objProposalNew.Territory_Region__c == QUOTE_REGION_AMEA || objProposalNew.Territory_Region__c == QUOTE_REGION_CHINA) && objProposalNew.country__C !=COUNTRY_JAPAN){  // POL-54
                    boolCountryCheck = true;
                }else if(objProposalNew.Territory_Region__c == QUOTE_REGION_AMEA && objProposalNew.country__C == COUNTRY_JAPAN){ // POL-54
                    boolCountryCheck = true;
                    boolCountryIncludeCheck = true;
                }
                Custom_Approval_Matrix__c latestAmRecord = getLatestApprovalMatrix(STRING_PAYMENT_TERM_RECORD_TYPE,
                                                            objProposalNew.Territory_Region__c,
                                                            boolCountryCheck,
                                                            boolCountryIncludeCheck);//DCP-40114
                //region china; country japan not valid approval rule so making record to null                                            
                if(objProposalNew.Territory_Region__c == QUOTE_REGION_CHINA && objProposalNew.country__C == COUNTRY_JAPAN) {
                    latestAmRecord = new Custom_Approval_Matrix__c(); }
            
                if(latestAmRecord !=null && !String.isBlank(latestAmRecord.id)) {
                    strLatestPaymentTermRecId = String.valueOf(latestAmRecord.id); }//DCP-40114
*/

                if(fieldToApprovalType.containsKey(FIELD_PROPOSAL_PAYMENT_TERM)){
                    strApprovalCategory += ';' + fieldToApprovalType.get(FIELD_PROPOSAL_PAYMENT_TERM); }
            }

            // if incoterm is not default for region, add approval DCP-25455
            if (proposalIdToDefaultIncoTerm.get(objProposalNew.Id) != objProposalNew.Inco_Term_1__c
                && !String.isBlank(objProposalNew.Inco_Term_1__c)
                && proposalIdToDefaultIncoTerm.get(objProposalNew.Id) != null)
            {
                if (objCustomMatrixWrapper.setIncoTermRegion.contains(objProposalNew.Territory_Region__c)) {//DCP-28526 Added condition of region 
                    boolCountryCheck = false; //DCP-40114
                    boolCountryIncludeCheck = false; //DCP-40114
                    Custom_Approval_Matrix__c latestAmRecord = getLatestApprovalMatrix(STRING_INCO_TERM_RECORD_TYPE,
                                                                objProposalNew.Territory_Region__c, boolCountryCheck,
                                                                boolCountryIncludeCheck);//DCP-40114 
                    if(latestAmRecord !=null && !String.isBlank(latestAmRecord.id)){
                        strLatestIncoTermRecId = String.valueOf(latestAmRecord.id);}//DCP-40114
                    if(fieldToApprovalType.containsKey(FIELD_INCO_TERM_1)){
                        strApprovalCategory += ';' + fieldToApprovalType.get(FIELD_INCO_TERM_1);}
                }
            } 

            // if the value in any of the setQuoteApprovalFields changes, add that approval category
            for (String strField : setQuoteApprovalFields)
            {
                String strNewValue = String.valueOf(objProposalNew.get(strField));
				ilib_LogEvent.message('strNewValue : '+strNewValue);

                if ((objCustomMatrixWrapper.setPostPriceMesage.contains(strNewValue) || setNonStandardPPM.contains(strNewValue)) 
                    && fieldToApprovalType.containsKey(strField)){
                    strApprovalCategory += ';' + fieldToApprovalType.get(strField); }
            }
            //DCP-49429
            if(objProposalNew.Number_of_MFN_Line_Items__c > 0)
            {
                strApprovalCategory += ';' + MFN_APPROVAL;
            }
            //DCP-58707
            //CMCM-2523
            DateTime dtPriceChange = null;
            if(proposalIdToAPCDate != null && proposalIdToAPCDate.containsKey(objProposalNew.id)) {
                dtPriceChange = proposalIdToAPCDate.get(objProposalNew.id);
            }
            Boolean boolDSMApproval = dtPriceChange != null && objProposalNew.Apttus_QPConfig__PriceListId__c != null 
                                    && objProposalNew.Apttus_QPConfig__PricingDate__c!= null
                                    && objProposalNew.Apttus_QPConfig__PricingDate__c < dtPriceChange 
                                    && (objProposalNew.Quote_Sub_Type__c == OPPORTUNITY_TYPE_REORDER_NON_CONSORTIUM_CONSUMABLE 
                                    || objProposalNew.Quote_Sub_Type__c == OPPORTUNITY_TYPE_STANDARD_SALE) 
                                    && dtPriceChange>= Date.today()
                                    && idToOpportunity.get(objProposalNew.Apttus_Proposal__Opportunity__c).Price_List_Type__c != null
                                    && (objProposalNew.Apttus_Proposal__ExpectedEndDate__c != null && objProposalNew.Apttus_Proposal__ExpectedEndDate__c >= dtPriceChange);
			ilib_LogEvent.info('boolDSMApproval : '+boolDSMApproval);
            if(boolDSMApproval){
                strApprovalCategory += ';' + DSM_APPROVAL_AFTER_PRICE_CHANGE;
            }

            objProposalNew.Approval_Category__c = strApprovalCategory; 
//commented for TASK0876760: objProposalNew.Payment_Term_Approval_Matrix__c = strLatestPaymentTermRecId;//DCP-40114  
            objProposalNew.Inco_Term_Approval_Matrix__c = strLatestIncoTermRecId;//DCP-40114      
        }
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('3. Number of Queries used in this apex code so far: ' + Limits.getQueries());
		ilib_LogEvent.pop();
    }
   
    private String getApprovalRequiredPaymentTermValues(Apttus_Proposal__Proposal__c objProposalNew, Map<String, String> territoryRegionToPaymentTermValues)
    {
		ilib_LogEvent.push(LOG_TITLE+'getApprovalRequiredPaymentTermValues()');
		ilib_LogEvent.info('objProposalNew : '+objProposalNew);
		ilib_LogEvent.info('territoryRegionToPaymentTermValues : '+territoryRegionToPaymentTermValues);
        String strApprovalRequiredPaymentTermValues = '';

        // for Japan, EUR, or AMR
        if ((objProposalNew.Territory_Region__c != QUOTE_REGION_AMEA && objProposalNew.Territory_Region__c != QUOTE_REGION_CHINA)
            || (objProposalNew.Territory_Region__c == QUOTE_REGION_AMEA && objProposalNew.Country__c == COUNTRY_JAPAN)
        ) { // POL-54
            strApprovalRequiredPaymentTermValues = territoryRegionToPaymentTermValues.get(objProposalNew.Territory_Region__c);
        }

        // for AMEA outside Japan and China  POL-54
        else if ((objProposalNew.Territory_Region__c == QUOTE_REGION_AMEA && objProposalNew.Country__c != COUNTRY_JAPAN)
            || (objProposalNew.Territory_Region__c == QUOTE_REGION_CHINA && objProposalNew.Country__c != COUNTRY_JAPAN)
        ) {
            strApprovalRequiredPaymentTermValues = territoryRegionToPaymentTermValues.get(QUOTE_REGION_APAC);
        }
		ilib_LogEvent.info('strApprovalRequiredPaymentTermValues : '+strApprovalRequiredPaymentTermValues);
		ilib_LogEvent.pop();

        return strApprovalRequiredPaymentTermValues;
    }

    /**
    *  @description To get the map of proposal id to Default payment term values.
    *  @return Map of Proposal id to Default Payment Term
    **/
    private Map<Id, String> getProposalIdToDefaultPaymentTerm(Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'getProposalIdToDefaultIncoTerm()');
        Map<Id, String> proposalIdToDefaultPaymentTerm = new Map<Id, String>();

        // find proposals with payers
        Map<Id, Id> proposalIdToPayer = new Map<Id, Id>();
        for (Id idProposal : idToNewProposal.keySet())
        {
            Apttus_Proposal__Proposal__c objProposalNew = idToNewProposal.get(idProposal);
            if (!String.isEmpty(objProposalNew.Payer__c)){
                proposalIdToPayer.put(objProposalNew.Id, objProposalNew.Payer__c);}
        }


        if (proposalIdToPayer.isEmpty()){ilib_LogEvent.pop(); 
		return proposalIdToDefaultPaymentTerm; }
        ilib_LogEvent.info('proposalIdToPayer : '+proposalIdToPayer);

        // get payer CMD details
        //CMCM-4516
        /*Map<Id, Customer_Master_Data__c> idToPayerCMD = new Map<Id, Customer_Master_Data__c>(
            new CustomerMasterDataSelector().selectById(new Set<Id>(proposalIdToPayer.values()))
        );*/
        Map<Id, Customer_Master_Data__c> idToPayerCMD = new Map<Id, Customer_Master_Data__c>([SELECT Id,Name,Street__c,City__c,Zip_Postal_Code__c,State_Province__c,Country__c,Country_Code__c,ERP_Customer_Id__c,Account_Group__c,Care_Of__c,Mark_For_Deletion__c FROM Customer_Master_Data__c WHERE Id IN:proposalIdToPayer.values()]);


        //CMCM-4516
        //List<Apttus_Proposal__Proposal__c> lstProposalsWithPayers = new ApttusProposalsSelector().selectByQuoteId(proposalIdToPayer.keySet());
        List<Apttus_Proposal__Proposal__c> lstProposalsWithPayers = [SELECT Payment_Term_Description__c, 
        Total_Number_Of_Samples__c, 
        Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c,
        Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c,
        Apttus_Proposal__Opportunity__r.Name,
        Apttus_Proposal__Opportunity__r.AccountId,
        Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Account.BillingCountry,
        Apttus_Proposal__Opportunity__r.Account.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Distributor__c,
        Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,
        Apttus_Proposal__Opportunity__r.StageName,
        Apttus_Proposal__Opportunity__r.Probability,
        Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c,
        Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c,
        Apttus_Proposal__Account__r.Territory_Region__c,
        Ultimate_Consignee__r.Territory_Region__c,
        Distributor__r.Territory_Region__c,
        Apttus_Proposal__Opportunity__r.Contract_Number__c,
        Apttus_Proposal__Opportunity__r.Transborder_Flag__c,
        Distributor__r.BillingCountry,
        Distributor__r.BillingCountryCode,
        Apttus_Proposal__Account__r.BillingCountry,
        Apttus_Proposal__Account__r.BillingCountryCode,
        Ultimate_Consignee__r.BillingCountry,
        Ultimate_Consignee__r.BillingCountryCode,
        Ultimate_Consignee__r.OwnerId,
        Distributor__r.OwnerId,
        Apttus_Proposal__Account__r.OwnerId,
        Apttus_Proposal__Opportunity__r.Account.Name,
        Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c,
        Bill_To__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c,
        Apttus_Proposal__Primary_Contact__r.Email,
        Apttus_Proposal__Account__r.Name,
        Ultimate_Consignee__r.Name,
        Distributor__r.Name,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Sales_Org_Override__c,
        Owner.Id,
        Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c,
        Apttus_Proposal__Account__r.Territory_Name__c,
        Apttus_Proposal__Opportunity__r.Product_Interest__c,
        Apttus_Proposal__Opportunity__r.Territory_Region__c,
        Apttus_Proposal__Primary_Contact__r.Name,
        Prepared_by__r.Email,
        Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c,
        Work_Order__r.Name,
        Work_Order__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Price_List_Type__c,
        Approval_Category__c,
        Quote_Total_Value_Prior_To_DiscountUSD__c,
        Id,
        Bill_To__c,
        Ship_To__c,
        Apttus_QPApprov__Approval_Status__c,
        Apttus_Proposal__Approval_Stage__c,
        Apttus_Proposal__Primary__c,
        Apttus_Proposal__Opportunity__c,
        Apttus_Proposal__Account__c,
        Cloned_From__c,
        Ship_To_ERP_Number__c,
        CurrencyIsoCode,
        Apttus_Proposal__Discount_Percent__c,
        Apttus_Proposal__ExpectedStartDate__c,
        Apttus_Proposal__Amount__c,
        Apttus_Proposal__ExpectedEndDate__c,
        Post_Pricing_Message__c,
        Discount_Reason__c,
        Discount_Reason_Definition__c,
        Discount_Justification__c,
        Quote_Total_Value_Prior_To_Discount__c,
        Total_Cart_Discount__c,
        Blended_Discount_Percentage__c,
        Quote_Total_Value_After_Discount__c,
        Apttus_Proposal__Primary_Contact__c,
        Invalid_Quote__c,
        MyIllumina_User_Email__c,
        Distributor__c,
        SAP_Quote__c,
        Is_Updated_By_System__c,
        Promo_Channel_1__c,
        Promo_Code_1__c,
        Promo_Channel_2__c,
        Promo_Code_2__c,
        Promo_Channel_3__c,
        Promo_Code_3__c,
        Ultimate_Consignee__c,
        Apttus_QPConfig__PriceListId__c,
        Apttus_QPConfig__PricingDate__c,
        Sold_To_ERP_Number__c,
        Ultimate_Consignee_ERP_Number__c,
        Bill_To_ERP_Number__c,
        Informatics_Quotation_c__c,
        Payer_ERP_Number__c,
        Informatics_Product_Line_Item_Numbers__c,
        Distributor_ERP_Number__c,
        Name,
        Web_Visible__c,
        Apttus_Proposal__Payment_Term__c,
        Quote_Type__c,
        Payer__c,
        Total_Net__c,
        Total_Discount__c,
        Estimated_Freight__c,
        Estimated_Tax__c,
        Post_Pricing_Message_List__c,
        Preferred_Language__c,
        Inco_Term_1__c,
        Prepared_by__c,
        Sold_to_Sales_Organization__c,
        Sold_to_Distribution_Channel__c,
        Sold_to_Division__c,
        Region_Ultimate_Consignee__c,
        Region_Distributor__c,
        Region_Sold_To__c,
        Indirect_Transregion_Flag__c,
        SAP_Errors__c,
        Direct_Sale_to_Ultimate_Consignee__c,
        Promotion_JSON__c,
        Opportunity_Record_Type__c,
        Sales_Discretionary_Approval_Error__c,
        Quote_Sub_Type__c,
        Subtotal__c,
        Sub_Total__c,
        Contract_Numbers__c,
        Fapiao_Type_Code__c,
        Fapiao_Type_Description__c,
        Last_Generate_Success__c,
        Last_Validation_Id__c,
        Generate_In_Progress__c,
        Async_Generation_Complete__c,
        View_Contract__c,
        BDR_Deal_Governing_Terms__c,
        Estimated_Presentation_Date__c,
        Informatics_Line_Item_Number__c,
        Open_Offer_Discount_Exception_Request__c,
        Open_Offer_Discount_Violation_Type__c,
        Quote_For_Open_Offer_Customer__c,
        Quote_Has_Open_Offer_Product__c,
        Sold_To_Account_Region__c,
        Work_Order__c,
        Number_of_MFN_Line_Items__c,
        Apttus_Proposal__Proposal_Name__c,
        Submit_For_Approval__c,
        Approval_Hierarchy_Record_Owner__c,
        Approval_Hierarchy_Transborder__c,
        Generate__c,
        Territory_Region__c,
        Async_Validation_Complete__c,
        OwnerId,
        Validation_In_Progress__c,
        Inventory_Location_ERP_Number__c,
        Open_Offer_Legal_Approver_Comments__c,
        Sub_Region_Sold_To__c,
        Business_Unit_Sold_To__c,
        Sub_Region_UC__c,
        Business_Unit_UC__c,
        Sub_Region_Distributor__c,
        Business_Unit_Distributor__c
        FROM Apttus_Proposal__Proposal__c
        WHERE Id IN :proposalIdToPayer.keySet()];

        // collect: 1) sold to and payer keys, 2) payer ID to quotes
        Set<String> setSoldToPayerASAKeys = new Set<String>();
        Map<String, List<Apttus_Proposal__Proposal__c>> payerErpIdToProposals = new Map<String, List<Apttus_Proposal__Proposal__c>>();
        for (Apttus_Proposal__Proposal__c objQuote : lstProposalsWithPayers)
        {
            Id payerId = proposalIdToPayer.get(objQuote.Id);
            if (String.isNotBlank(objQuote.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c) && (idToPayerCMD.get(payerId)) != null)
            {
                String strPayerERPID = idToPayerCMD.get(payerId).ERP_Customer_Id__c + '_' + AutomateBillToShipToService.getSalesAreaFromERP(objQuote.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c);
                AutomateBillToShipToService.addListToMap(payerErpIdToProposals, strPayerERPID, new List<Apttus_Proposal__Proposal__c> {objQuote});
                setSoldToPayerASAKeys.add(objQuote.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c);
				ilib_LogEvent.message('strPayerERPID : '+strPayerERPID);
            }
        }
        setSoldToPayerASAKeys.addAll(payerErpIdToProposals.keySet());
        System.debug('payerErpIdToProposals: ' + payerErpIdToProposals);
        System.debug('Sold To sales areas: ' + setSoldToPayerASAKeys);
		ilib_LogEvent.info('setSoldToPayerASAKeys : '+setSoldToPayerASAKeys);

        if (setSoldToPayerASAKeys.isEmpty()){
			ilib_LogEvent.pop();
            return proposalIdToDefaultPaymentTerm;}

        // map sold to/payer sales area ID to ASA record
        Map<String, Account_Sales_Area__c> accountSAKeyToSA = new Map<String, Account_Sales_Area__c>();
        //CMCM-4516
        for (Account_Sales_Area__c objASA : new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setSoldToPayerASAKeys))
        //for (Account_Sales_Area__c objASA : [SELECT Id,Name,Price_List_Type__c,Account__c,CurrencyIsoCode,ERP_Account_Sales_Area_Id__c,Price_List__c,Sales_Organization__c,Distribution_Channel__c,Term_Of_Payment__c,Division__c,Contract_Number__c,Company_Code__c,Inco_Term_1__c,Customer_Master_Data__c,Price_Group__c, Price_Group_Description__c,Account__r.ERP_Customer_Id__c, Customer_Master_Data__r.Account_Group__c, Customer_Master_Data__r.Care_Of__c, Customer_Master_Data__r.City__c, Customer_Master_Data__r.Country_Code__c, Customer_Master_Data__r.Country__c, Customer_Master_Data__r.CurrencyIsoCode, Customer_Master_Data__r.ERP_Customer_Id__c, Customer_Master_Data__r.Id, Customer_Master_Data__r.Mark_For_Deletion__c, Customer_Master_Data__r.Name, Customer_Master_Data__r.State_Province__c, Customer_Master_Data__r.Street__c, Customer_Master_Data__r.Zip_Postal_Code__c,  (SELECT CurrencyIsoCode, Default_Partner__c, ERP_Account_Relationship_Id__c, ERP_Customer_Id__c, Id, IsInactive__c, Name, Related_ERP_Customer_Id__c, Relationship__c FROM Partner_Functions__r ORDER BY Name ASC NULLS FIRST ) FROM Account_Sales_Area__c WHERE  ERP_Account_Sales_Area_Id__c IN :setSoldToPayerASAKeys])
        {
            accountSAKeyToSA.put(objASA.ERP_Account_Sales_Area_Id__c, objASA);
        }

        // find the best payer match, then map to the payer's payment terms
        for (String payerERPASA : payerErpIdToProposals.keySet())
        {
            Account_Sales_Area__c objASA = accountSAKeyToSA.get(payerERPASA);
            Boolean booFoundPayer = false;

            if (objASA != null && objASA.Partner_Functions__r != null 
                && !objASA.Partner_Functions__r.isEmpty())
            {
                // look for payer under bill to sales area
                for (Account_Relationship__c objRelation : objASA.Partner_Functions__r)
                {
                    if(ACCOUNT_GROUP_PAYER.equals(objRelation.Relationship__c) && !objRelation.IsInactive__c)
                    {
                        booFoundPayer = true;
						ilib_LogEvent.message('booFoundPayer = true');
                        break;
                    }
                }
                if (booFoundPayer)
                {
                    for (Apttus_Proposal__Proposal__c objProp : payerErpIdToProposals.get(payerERPASA)){
                        //DCP-DCP-46226
                        proposalIdToDefaultPaymentTerm.put(objProp.Id,AutomateBillToShipToService.getPaymentTermOverride(objProp.Apttus_Proposal__Opportunity__r,objASA.Term_Of_Payment__c));
                    }
                }
            }

            // get payment term from sold to sales area
            if (!booFoundPayer) 
            {
                for (Apttus_Proposal__Proposal__c objProp : payerErpIdToProposals.get(payerERPASA))
                {
                    if (accountSAKeyToSA.containsKey(objProp.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c)){
                        //DCP-DCP-46226
                        proposalIdToDefaultPaymentTerm.put(objProp.Id, 
                            AutomateBillToShipToService.getPaymentTermOverride(
                                objProp.Apttus_Proposal__Opportunity__r,
                                accountSAKeyToSA.get(objProp.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c).Term_Of_Payment__c));
                    }
                }
            }
        }

        System.debug('@@@ proposalIdToDefaultPaymentTerm ' + proposalIdToDefaultPaymentTerm);
		ilib_LogEvent.info('proposalIdToDefaultPaymentTerm : '+proposalIdToDefaultPaymentTerm);
		ilib_LogEvent.pop();
        return proposalIdToDefaultPaymentTerm;
    }
    
    /**
    *  @description To get the map of proposal id to Default inco term values.
    *  @return Map of Proposal id to Default Inco Term
    **/
    private Map<Id, String> getProposalIdToDefaultIncoTerm(Map<Id, Apttus_Proposal__Proposal__c> idToNewProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'getProposalIdToDefaultIncoTerm()');
        Map<Id, String> proposalIdToDefaultIncoTerm = new Map<Id, String>();

        // find proposals with ship tos
        Map<Id, Id> proposalIdToShipTo = new Map<Id, Id>();
        for (Id idProposal : idToNewProposal.keySet())
        {
            Apttus_Proposal__Proposal__c objProposalNew = idToNewProposal.get(idProposal);
            ilib_LogEvent.message('objProposalNew : '+objProposalNew);
            if (!String.isEmpty(objProposalNew.Ship_To__c)){
                proposalIdToShipTo.put(objProposalNew.Id, objProposalNew.Ship_To__c);}
        }
        System.debug('--proposalIdToShipTo--' + proposalIdToShipTo);

        if (proposalIdToShipTo.isEmpty()){ilib_LogEvent.pop(); 
		return proposalIdToDefaultIncoTerm; }
        ilib_LogEvent.info('proposalIdToShipTo : '+proposalIdToShipTo);

        // get ship to CMD details
        Map<Id, Customer_Master_Data__c> idToShipToCMD = new Map<Id, Customer_Master_Data__c>();
        //CMCM-4516
        //for (Customer_Master_Data__c objCMD : new CustomerMasterDataSelector().selectById(new Set<Id>(proposalIdToShipTo.values()))){
        for (Customer_Master_Data__c objCMD : [SELECT Id,Name,Street__c,City__c,Zip_Postal_Code__c,State_Province__c,Country__c,Country_Code__c,ERP_Customer_Id__c,Account_Group__c,Care_Of__c,Mark_For_Deletion__c FROM Customer_Master_Data__c WHERE Id IN:proposalIdToShipTo.values()]) {
            idToShipToCMD.put(objCMD.Id,objCMD);
        }
        System.debug('--idToShipToCMD--'+idToShipToCMD);

        //CMCM-4516
        //List<Apttus_Proposal__Proposal__c> lstProposalsWithShipTos = new ApttusProposalsSelector().selectByQuoteId(proposalIdToShipTo.keySet());
        List<Apttus_Proposal__Proposal__c> lstProposalsWithShipTos = [SELECT Payment_Term_Description__c, 
        Total_Number_Of_Samples__c, 
        Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c,
        Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c,
        Apttus_Proposal__Opportunity__r.Name,
        Apttus_Proposal__Opportunity__r.AccountId,
        Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Account.BillingCountry,
        Apttus_Proposal__Opportunity__r.Account.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode,
        Apttus_Proposal__Opportunity__r.Distributor__c,
        Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,
        Apttus_Proposal__Opportunity__r.StageName,
        Apttus_Proposal__Opportunity__r.Probability,
        Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c,
        Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c,
        Apttus_Proposal__Account__r.Territory_Region__c,
        Ultimate_Consignee__r.Territory_Region__c,
        Distributor__r.Territory_Region__c,
        Apttus_Proposal__Opportunity__r.Contract_Number__c,
        Apttus_Proposal__Opportunity__r.Transborder_Flag__c,
        Distributor__r.BillingCountry,
        Distributor__r.BillingCountryCode,
        Apttus_Proposal__Account__r.BillingCountry,
        Apttus_Proposal__Account__r.BillingCountryCode,
        Ultimate_Consignee__r.BillingCountry,
        Ultimate_Consignee__r.BillingCountryCode,
        Ultimate_Consignee__r.OwnerId,
        Distributor__r.OwnerId,
        Apttus_Proposal__Account__r.OwnerId,
        Apttus_Proposal__Opportunity__r.Account.Name,
        Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c,
        Bill_To__r.ERP_Customer_Id__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c,
        Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c,
        Apttus_Proposal__Primary_Contact__r.Email,
        Apttus_Proposal__Account__r.Name,
        Ultimate_Consignee__r.Name,
        Distributor__r.Name,
        Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Sales_Org_Override__c,
        Owner.Id,
        Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c,
        Apttus_Proposal__Account__r.Territory_Name__c,
        Apttus_Proposal__Opportunity__r.Product_Interest__c,
        Apttus_Proposal__Opportunity__r.Territory_Region__c,
        Apttus_Proposal__Primary_Contact__r.Name,
        Prepared_by__r.Email,
        Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c,
        Work_Order__r.Name,
        Work_Order__r.Owner.Name,
        Apttus_Proposal__Opportunity__r.Price_List_Type__c,
        Approval_Category__c,
        Quote_Total_Value_Prior_To_DiscountUSD__c,
        Id,
        Bill_To__c,
        Ship_To__c,
        Apttus_QPApprov__Approval_Status__c,
        Apttus_Proposal__Approval_Stage__c,
        Apttus_Proposal__Primary__c,
        Apttus_Proposal__Opportunity__c,
        Apttus_Proposal__Account__c,
        Cloned_From__c,
        Ship_To_ERP_Number__c,
        CurrencyIsoCode,
        Apttus_Proposal__Discount_Percent__c,
        Apttus_Proposal__ExpectedStartDate__c,
        Apttus_Proposal__Amount__c,
        Apttus_Proposal__ExpectedEndDate__c,
        Post_Pricing_Message__c,
        Discount_Reason__c,
        Discount_Reason_Definition__c,
        Discount_Justification__c,
        Quote_Total_Value_Prior_To_Discount__c,
        Total_Cart_Discount__c,
        Blended_Discount_Percentage__c,
        Quote_Total_Value_After_Discount__c,
        Apttus_Proposal__Primary_Contact__c,
        Invalid_Quote__c,
        MyIllumina_User_Email__c,
        Distributor__c,
        SAP_Quote__c,
        Is_Updated_By_System__c,
        Promo_Channel_1__c,
        Promo_Code_1__c,
        Promo_Channel_2__c,
        Promo_Code_2__c,
        Promo_Channel_3__c,
        Promo_Code_3__c,
        Ultimate_Consignee__c,
        Apttus_QPConfig__PriceListId__c,
        Apttus_QPConfig__PricingDate__c,
        Sold_To_ERP_Number__c,
        Ultimate_Consignee_ERP_Number__c,
        Bill_To_ERP_Number__c,
        Informatics_Quotation_c__c,
        Payer_ERP_Number__c,
        Informatics_Product_Line_Item_Numbers__c,
        Distributor_ERP_Number__c,
        Name,
        Web_Visible__c,
        Apttus_Proposal__Payment_Term__c,
        Quote_Type__c,
        Payer__c,
        Total_Net__c,
        Total_Discount__c,
        Estimated_Freight__c,
        Estimated_Tax__c,
        Post_Pricing_Message_List__c,
        Preferred_Language__c,
        Inco_Term_1__c,
        Prepared_by__c,
        Sold_to_Sales_Organization__c,
        Sold_to_Distribution_Channel__c,
        Sold_to_Division__c,
        Region_Ultimate_Consignee__c,
        Region_Distributor__c,
        Region_Sold_To__c,
        Indirect_Transregion_Flag__c,
        SAP_Errors__c,
        Direct_Sale_to_Ultimate_Consignee__c,
        Promotion_JSON__c,
        Opportunity_Record_Type__c,
        Sales_Discretionary_Approval_Error__c,
        Quote_Sub_Type__c,
        Subtotal__c,
        Sub_Total__c,
        Contract_Numbers__c,
        Fapiao_Type_Code__c,
        Fapiao_Type_Description__c,
        Last_Generate_Success__c,
        Last_Validation_Id__c,
        Generate_In_Progress__c,
        Async_Generation_Complete__c,
        View_Contract__c,
        BDR_Deal_Governing_Terms__c,
        Estimated_Presentation_Date__c,
        Informatics_Line_Item_Number__c,
        Open_Offer_Discount_Exception_Request__c,
        Open_Offer_Discount_Violation_Type__c,
        Quote_For_Open_Offer_Customer__c,
        Quote_Has_Open_Offer_Product__c,
        Sold_To_Account_Region__c,
        Work_Order__c,
        Number_of_MFN_Line_Items__c,
        Apttus_Proposal__Proposal_Name__c,
        Submit_For_Approval__c,
        Approval_Hierarchy_Record_Owner__c,
        Approval_Hierarchy_Transborder__c,
        Generate__c,
        Territory_Region__c,
        Async_Validation_Complete__c,
        OwnerId,
        Validation_In_Progress__c,
        Inventory_Location_ERP_Number__c,
        Open_Offer_Legal_Approver_Comments__c,
        Sub_Region_Sold_To__c,
        Business_Unit_Sold_To__c,
        Sub_Region_UC__c,
        Business_Unit_UC__c,
        Sub_Region_Distributor__c,
        Business_Unit_Distributor__c
        FROM Apttus_Proposal__Proposal__c
        WHERE Id IN :proposalIdToShipTo.keySet()];

        // collect: 1) UC and ship to keys, 2) ship to ID to quotes
        Set<String> setUcShipToASAKeys = new Set<String>();
        Map<String, List<Apttus_Proposal__Proposal__c>> shipToErpIdToProposals = new Map<String, List<Apttus_Proposal__Proposal__c>>();
        for (Apttus_Proposal__Proposal__c objProposalNew : lstProposalsWithShipTos)
        {
            Id idShipTo = proposalIdToShipTo.get(objProposalNew.Id);
            String rtName = objProposalNew.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName;

            // found a ship to, use that
            if ((Opportunities.DIRECT_RECORD_TYPES.contains(rtName)
                    || (!Opportunities.DIRECT_RECORD_TYPES.contains(rtName) && objProposalNew.Direct_Sale_to_Ultimate_Consignee__c))
                && String.isNotBlank(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c)
                && (idToShipToCMD.get(idShipTo)) != null)
            {
                String strShipToERPID = idToShipToCMD.get(idShipTo).ERP_Customer_Id__c + '_' + AutomateBillToShipToService.getSalesAreaFromERP(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c);
                AutomateBillToShipToService.addListToMap(shipToErpIdToProposals, strShipToERPID, new List<Apttus_Proposal__Proposal__c> {objProposalNew});
                setUcShipToASAKeys.add(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c);
            }

            // use the distributor as the ship to
            else if (!Opportunities.DIRECT_RECORD_TYPES.contains(rtName)
                && !objProposalNew.Direct_Sale_to_Ultimate_Consignee__c
                && String.isNotBlank(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c)
                && (idToShipToCMD.get(idShipTo)) != null
            ) {
                String strDistributorERPID = idToShipToCMD.get(idShipTo).ERP_Customer_Id__c + '_' + AutomateBillToShipToService.getSalesAreaFromERP(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c);
                AutomateBillToShipToService.addListToMap(shipToErpIdToProposals, strDistributorERPID, new List<Apttus_Proposal__Proposal__c> {objProposalNew});
                setUcShipToASAKeys.add(objProposalNew.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c);
            }
        }
        setUcShipToASAKeys.addAll(shipToErpIdToProposals.keySet());
        System.debug('---setUcShipToASAKeys---' + setUcShipToASAKeys);


        if (setUcShipToASAKeys.isEmpty()) {
			ilib_LogEvent.pop();
            return proposalIdToDefaultIncoTerm;
        }
        ilib_LogEvent.info('setUcShipToASAKeys : '+setUcShipToASAKeys);

        Map<String, Account_Sales_Area__c> ucShipToSAERPToSA = new Map<String, Account_Sales_Area__c>();
        //CMCM-4516
        for (Account_Sales_Area__c objASA : new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setUcShipToASAKeys))
        //for (Account_Sales_Area__c objASA : [SELECT Id,Name,Price_List_Type__c,Account__c,CurrencyIsoCode,ERP_Account_Sales_Area_Id__c,Price_List__c,Sales_Organization__c,Distribution_Channel__c,Term_Of_Payment__c,Division__c,Contract_Number__c,Company_Code__c,Inco_Term_1__c,Customer_Master_Data__c,Price_Group__c, Price_Group_Description__c,Account__r.ERP_Customer_Id__c, Customer_Master_Data__r.Account_Group__c, Customer_Master_Data__r.Care_Of__c, Customer_Master_Data__r.City__c, Customer_Master_Data__r.Country_Code__c, Customer_Master_Data__r.Country__c, Customer_Master_Data__r.CurrencyIsoCode, Customer_Master_Data__r.ERP_Customer_Id__c, Customer_Master_Data__r.Id, Customer_Master_Data__r.Mark_For_Deletion__c, Customer_Master_Data__r.Name, Customer_Master_Data__r.State_Province__c, Customer_Master_Data__r.Street__c, Customer_Master_Data__r.Zip_Postal_Code__c,  (SELECT CurrencyIsoCode, Default_Partner__c, ERP_Account_Relationship_Id__c, ERP_Customer_Id__c, Id, IsInactive__c, Name, Related_ERP_Customer_Id__c, Relationship__c FROM Partner_Functions__r ORDER BY Name ASC NULLS FIRST ) FROM Account_Sales_Area__c WHERE  ERP_Account_Sales_Area_Id__c IN :setUcShipToASAKeys])
        {
            ucShipToSAERPToSA.put(objASA.ERP_Account_Sales_Area_Id__c, objASA);
        }
        System.debug('---ucShipToSAERPToSA---' + ucShipToSAERPToSA);

        for (String shipToERPASA : shipToErpIdToProposals.keySet())
        {
            Account_Sales_Area__c objASA = ucShipToSAERPToSA.get(shipToERPASA);
			ilib_LogEvent.message('objASA : '+objASA);

            if (objASA != null)
            {
                for (Apttus_Proposal__Proposal__c objProp : shipToErpIdToProposals.get(shipToERPASA)){
					ilib_LogEvent.fine('objProp : '+objProp);
                    proposalIdToDefaultIncoTerm.put(objProp.Id, objASA.Inco_Term_1__c);}
            }
        }

        System.debug('---proposalIdToDefaultIncoTerm---' + proposalIdToDefaultIncoTerm);
		ilib_LogEvent.info('proposalIdToDefaultIncoTerm : '+proposalIdToDefaultIncoTerm);
		ilib_LogEvent.pop();
        return proposalIdToDefaultIncoTerm;
    }

    /**
    *  @author Govind Dubey
    *  @description To check if TransRegion Approval Required or not.
    *  @param old proposal and new proposals
    **/
    private boolean isTransRegionApprovalCheckRequired(Apttus_Proposal__Proposal__c objProposalOld, Apttus_Proposal__Proposal__c objProposalNew)
    {
        return setQuoteApprovalFields.contains(FIELD_TRANSREGION_FLAG)
            && (objProposalNew.Ultimate_Consignee__c != objProposalOld.Ultimate_Consignee__c
                || objProposalNew.Apttus_Proposal__Account__c != objProposalOld.Apttus_Proposal__Account__c);
    }
    
    /**
    *  @author Gopinath Reddy
    *  @description To check if Indirect TransRegion Approval Required or not.
    *  @param old proposal and new proposals
    **/
    private boolean isIndirectTransRegionApprovalCheckRequired(Apttus_Proposal__Proposal__c objProposalOld, Apttus_Proposal__Proposal__c objProposalNew)
    {
        return setQuoteApprovalFields.contains(FIELD_INDIRECT_TRANSREGION_FLAG)
            && (objProposalNew.Ultimate_Consignee__c != objProposalOld.Ultimate_Consignee__c
                || objProposalNew.Distributor__c != objProposalOld.Distributor__c);
    }

    /**
    *  @author Govind Dubey
    *  @description Convert Custom Approval Matrix List to Wrapper (i.e. group matrix records based on approval category)
    *  @param List<Custom_Approval_Matrix__c> List of Custom Approval Matrix
    *  @return CustomApprovalMatrixWrapper Approval Matrix Wrapper
    **/
    private CustomApprovalMatrixWrapper getCustomApprovalMatrixWrapper()
    {
		ilib_LogEvent.push(LOG_TITLE+'getCustomApprovalMatrixWrapper()');
        //CMCM-4516
        // List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive(
        //     new Set<String> {'Post_Pricing_Message', 'Payment_Term', 'Inco_Terms'}
        // );

        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = selectActive(
            new Set<String> {'Post_Pricing_Message', 'Payment_Term', 'Inco_Terms'}
        );

        if (lstCustomApprovalMatrix.isEmpty()){ilib_LogEvent.pop(); 
		return null; }

        CustomApprovalMatrixWrapper objCustomMatrixWrapper = new CustomApprovalMatrixWrapper();
        for (Custom_Approval_Matrix__c objApprovalMatrix : lstCustomApprovalMatrix)
        {
			ilib_LogEvent.message('objApprovalMatrix : '+objApprovalMatrix);
            if (objApprovalMatrix.RecordType.DeveloperName == ApprovalCategory.POST_PRICING_MESSAGE.Name()){
                objCustomMatrixWrapper.setPostPriceMesage.add(objApprovalMatrix.Post_Pricing_Message__c);}

            if (objApprovalMatrix.RecordType.DeveloperName == ApprovalCategory.PAYMENT_TERM.Name() && objApprovalMatrix.Region__c != null){
                objCustomMatrixWrapper.setPaymentTermRegion.addall(objApprovalMatrix.Region__c.split(';')); }//DCP-40114 splitting multipicklist values and then assinging to set

            if (objApprovalMatrix.RecordType.DeveloperName == ApprovalCategory.INCO_TERMS.Name()  && objApprovalMatrix.Region__c != null){ // DCP-28526 Added condition for inco terms region 
                objCustomMatrixWrapper.setIncoTermRegion.addall(objApprovalMatrix.Region__c.split(';')); }//DCP-40114 splitting multipicklist values and then assinging to set
        }

        System.debug('--objCustomMatrixWrapper--'+objCustomMatrixWrapper);
		ilib_LogEvent.pop();
        return objCustomMatrixWrapper;
    }
    /**
    *  @author Raja Siva Krishna
    *  @description To get the last modified approval matrix.
    *  @param Record Type, Territory Region, consider country,  include country value in filter
    *  @return Custom_Approval_Matrix__c Approval Matrix
    **/
    private Custom_Approval_Matrix__c getLatestApprovalMatrix(String amRecType, String territoryRegion, Boolean countryCheck, Boolean countryIncludeCheck){
		ilib_LogEvent.push(LOG_TITLE+'getLatestApprovalMatrix()');
		ilib_LogEvent.info('amRecType : '+amRecType);
		ilib_LogEvent.info('territoryRegion : '+territoryRegion);
        Custom_Approval_Matrix__c latestApprovalMatrix = new Custom_Approval_Matrix__c();
        //CMCM-4516
        // List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive(
        //     new Set<String> {STRING_INCO_TERM_RECORD_TYPE/*, STRING_PAYMENT_TERM_RECORD_TYPE TASK0876760*/ }
        // );
        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = selectActive(new Set<String> {STRING_INCO_TERM_RECORD_TYPE});
        for(Custom_Approval_Matrix__c am:lstCustomApprovalMatrix){
            if(am.RecordType.DeveloperName == amRecType && !String.isBlank(am.region__c) && am.region__c.split(';').contains(territoryRegion)){
                //region AMEA or China and country is JP 
                //POL-54
                if(countryCheck && countryIncludeCheck && !String.isBlank(am.country__c) && am.country__c.split(';').contains(QUOTE_COUNTRY_JP)){
                    latestApprovalMatrix = am;
                }
                //region is AMEA and country is not JP   
                //POL-54
                else if(countryCheck && !countryIncludeCheck && !String.isBlank(am.country__c) && !am.country__c.split(';').contains(QUOTE_COUNTRY_JP)){
                    latestApprovalMatrix = am;
                }
                //Incident fix:INC0295821-region is AMEA or china and country is blanck and not JP  
                //POL-54
                else if(countryCheck && !countryIncludeCheck && String.isBlank(am.country__c)){
                    latestApprovalMatrix = am;
                }
                //other regions without any country check
                else if(!countryCheck && !countryIncludeCheck ){
                    latestApprovalMatrix = am;                    
                }
                else{
                    continue;
                }
            }
        }
		ilib_LogEvent.info('latestApprovalMatrix : '+latestApprovalMatrix);
		ilib_LogEvent.pop();
        return latestApprovalMatrix;
    }
    
    private Map<String, String> getTerritoryRegionToPaymentTermValues()
    {
		ilib_LogEvent.push(LOG_TITLE+'getTerritoryRegionToPaymentTermValues()');
        Map<String, String> territoryRegionToPaymentTermValues = new Map<String, String>();

        //CMCM-4516
        /*List<Code_Parameter__mdt> lstCodeParameter = new CodeParametersSelector().selectCodeParameterByDeveloperName(
            new Set<String> { 'EUR_Approval_Payment_Term', 'JAPAN_Approval_Payment_Term', 'AMR_Approval_Payment_Term', 'APAC_Approval_Payment_Term' }
        ); // POL-54*/
        List<Code_Parameter__mdt> lstCodeParameter = [SELECT DeveloperName, PicklistValue__c, Values_Text__c, Value__c FROM Code_Parameter__mdt WHERE DeveloperName IN ('EUR_Approval_Payment_Term', 'JAPAN_Approval_Payment_Term', 'AMR_Approval_Payment_Term', 'APAC_Approval_Payment_Term')];

        for (Code_Parameter__mdt cp : lstCodeParameter)
        {
			ilib_LogEvent.message('cp.PickListValue__c : '+cp.PickListValue__c);
			ilib_LogEvent.message('cp.Value__c : '+cp.Value__c);
            territoryRegionToPaymentTermValues.put(cp.PickListValue__c, cp.Value__c);
        }
		ilib_LogEvent.info('territoryRegionToPaymentTermValues : '+territoryRegionToPaymentTermValues);
		ilib_LogEvent.pop();
        return territoryRegionToPaymentTermValues;
    }

    /**
    *  @author Govind Dubey
    *  @description Wrapper class for List of Appproval Matrix
    **/
    public class CustomApprovalMatrixWrapper {

        public Set<String> setPostPriceMesage {
            get {
                if (setPostPriceMesage == null) { setPostPriceMesage = new Set<String>(); }
                return setPostPriceMesage;
            }
            set;
        }
        public Set<String> setPaymentTermRegion {
            get {
                if (setPaymentTermRegion == null) { setPaymentTermRegion = new Set<String>(); }
                return setPaymentTermRegion;
            }
            set;
        }

        public Set<String> setIncoTermRegion { // DCP-28526 Added set for Inco Terms regions 
            get { 
                if (setIncoTermRegion == null) { setIncoTermRegion = new Set<String>(); }
                return setIncoTermRegion; 
            } 
            set; 
        } 
    }

    /**
    *  @author Roopal Verma
    *  @description To check if MyIllumina zemail is in Sold to Account
    **/
    public static void setMyIlluminaEmail(List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'setMyIlluminaEmail()');
        Map<Id, Apttus_Proposal__Proposal__c> idToNewContactProposal = new Map<Id, Apttus_Proposal__Proposal__c>();
        Map<Id, Apttus_Proposal__Proposal__c> idToOldContactProposal = new Map<Id, Apttus_Proposal__Proposal__c>();
        Map<Id, Apttus_Proposal__Proposal__c> idToUpdatedEmailProposal = new Map<Id, Apttus_Proposal__Proposal__c>();

        for (Apttus_Proposal__Proposal__c objProposal : lstProposal)
        {
            Apttus_Proposal__Proposal__c objOldProposal = idToOldProposal.get(objProposal.Id);

            if (objProposal.Apttus_Proposal__Primary_Contact__c != objOldProposal.Apttus_Proposal__Primary_Contact__c // primary contact changed
                || (objProposal.MyIllumina_User_Email__c == null && objProposal.Apttus_Proposal__Primary_Contact__c != null) // have a primary contact but not myILMN email
            ) {
                idToNewContactProposal.put(objProposal.Id, objProposal);
                idToOldContactProposal.put(objProposal.Id, objOldProposal);
            }

            if (objProposal.MyIllumina_User_Email__c != objOldProposal.MyIllumina_User_Email__c) { // myILMN email changed
                idToUpdatedEmailProposal.put(objProposal.Id, objProposal);}
        }

        if (idToNewContactProposal.isEmpty() && idToUpdatedEmailProposal.isEmpty()){ilib_LogEvent.pop(); 
		return; }

        // query for all primary contact details
        Map<Id, Contact> idToPrimaryContact = new Map<Id, Contact>();
        if (!idToNewContactProposal.isEmpty())
        {
            Set<Id> setNewContactIds = UtilsCollection.getSetOfIds(idToNewContactProposal.values(), 'Apttus_Proposal__Primary_Contact__c');
            Set<Id> setOldContactIds = UtilsCollection.getSetOfIds(idToOldContactProposal.values(), 'Apttus_Proposal__Primary_Contact__c');
            Set<Id> setAllContactIds = new Set<Id>();

            if (!setNewContactIds.isEmpty()) { setAllContactIds.addAll(setNewContactIds);}
            if (!setOldContactIds.isEmpty()) { setAllContactIds.addAll(setOldContactIds);}
            //CMCM-4516
            //if (!setAllContactIds.isEmpty()) { idToPrimaryContact = new Map<Id, Contact>(new ContactsSelector().selectContacts(setAllContactIds));}
            if (!setAllContactIds.isEmpty()) { idToPrimaryContact = new Map<Id,Contact>([SELECT id,Email,name,Phone,AccountId,LastModifiedDate,Is_Active__c,PGUID__c,Country_Local__c, FirstName, LastName, MailingCountry, Preferred_Language__c FROM Contact WHERE Id IN :setAllContactIds]);}
        }

        // get all emails on sold to's contacts
        Set<String> setAllSoldToContactEmails = new Set<String>();
        if (!idToUpdatedEmailProposal.isEmpty())
        {
            Set<Id> idToSoldToAcc = UtilsCollection.getSetOfIds(lstProposal, 'Apttus_Proposal__Account__c');
            //CMCM-4516
            //List<Contact> lstAccContact = new ContactsSelector().selectContactsFromAccount(idToSoldToAcc);
            List<Contact> lstAccContact = [SELECT id,Email,name,Phone,AccountId,LastModifiedDate,Is_Active__c,PGUID__c,Country_Local__c, FirstName, LastName, MailingCountry, Preferred_Language__c FROM Contact WHERE Id IN :idToSoldToAcc];
            setAllSoldToContactEmails = UtilsCollection.getSetOfStrings(lstAccContact, 'Email');
        }
        
        for (Apttus_Proposal__Proposal__c objProposal : lstProposal)
        {
            // if the myILMN email changed
            if (idToUpdatedEmailProposal.containsKey(objProposal.Id))
            {
                objProposal.Is_Updated_By_System__c = true;

                // Checking if updated Myillumina Email is not in Sold To Account Contact
                if (!setAllSoldToContactEmails.contains(objProposal.MyIllumina_User_Email__c)){
                    objProposal.addError(Label.UI_ErrorMessage_MyIlluminaEmailNotInSoldTo); }
            }

            // if myILMN email is blank, set it to the primary contact email
            else if (idToNewContactProposal.containsKey(objProposal.Id))
            {
                System.debug('--IsPrimaryContactUpdated--');
				ilib_LogEvent.message('IsPrimaryContactUpdated');
                String strMyIlluminaEmail = objProposal.MyIllumina_User_Email__c;
                Id idOldPrimaryContact = idToOldContactProposal.get(objProposal.Id).Apttus_Proposal__Primary_Contact__c;
                Id idNewPrimaryContact = objProposal.Apttus_Proposal__Primary_Contact__c;
                String strOldMyIlluminaEmail = (idToPrimaryContact.containsKey(idOldPrimaryContact) ? idToPrimaryContact.get(idOldPrimaryContact).Email : null);
                System.debug('strMyIlluminaEmail'+strMyIlluminaEmail);
				ilib_LogEvent.message('strMyIlluminaEmail : '+strMyIlluminaEmail);

                if (strMyIlluminaEmail == null
                    || idOldPrimaryContact == null
                    || strMyIlluminaEmail == strOldMyIlluminaEmail
                ) {
                    objProposal.MyIllumina_User_Email__c = idToPrimaryContact.containsKey(idNewPrimaryContact) ? idToPrimaryContact.get(idNewPrimaryContact).Email : null;
					ilib_LogEvent.message('objProposal.MyIllumina_User_Email__c : '+objProposal.MyIllumina_User_Email__c);
                }
            }
			
        }
		ilib_LogEvent.pop();
    }
    /**
    *  @author Joshith K
    *  @description To Udate opportunity Ship to sales org when sold to sales org updated
    **/
    public void setShipToSalesOrgForOpportunity(Map<Id, SObject> idToOldProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'setShipToSalesOrgForOpportunity()');
        List<Apttus_Proposal__Proposal__c> lstSoldTOSalesOrgChanged = new List<Apttus_Proposal__Proposal__c>();
        for (Apttus_Proposal__Proposal__c objProposal : (List<Apttus_Proposal__Proposal__c>)records)
        {
            if (objProposal.Sold_To_Sales_Organization__c != null
                && objProposal.Sold_To_Sales_Organization__c != ((Apttus_Proposal__Proposal__c)idToOldProposal.get(objProposal.Id)).Sold_To_Sales_Organization__c
                && objProposal.Apttus_Proposal__Primary__c == true
                && objProposal.Apttus_Proposal__Approval_Stage__c != APPROVAL_STAGE_DENIED
            ) {
                lstSoldTOSalesOrgChanged.add(objProposal);
            }
        }
        if (lstSoldTOSalesOrgChanged.isEmpty()) {ilib_LogEvent.pop(); 
		return; }

        Set<Id> oppId = new Set<Id>();
        for (Apttus_Proposal__Proposal__c objProposal : lstSoldTOSalesOrgChanged)
        {
            oppId.add(objProposal.Apttus_Proposal__Opportunity__c);
        }
		ilib_LogEvent.info('oppId : '+oppId);
        //CMCM-4516
        //Map<Id,Opportunity> mapOpportunity= new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(oppId)); // DCP-38933
        Map<Id,Opportunity> mapOpportunity= new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c FROM Opportunity WHERE Id IN :oppId]);
        for (Apttus_Proposal__Proposal__c objProposal : lstSoldTOSalesOrgChanged)
        {
            mapOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c).Ship_To_Sales_Org__c=objProposal.Sold_To_Sales_Organization__c;
        }

        if (!mapOpportunity.values().isEmpty())
        {
            update mapOpportunity.values();
        }
        ilib_LogEvent.info('mapOpportunity Ids : '+(mapOpportunity !=NULL ? String.valueOf(mapOpportunity.keySet()):MAPISEMPTY));
		ilib_LogEvent.pop();
    }

    /**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-29588 update Opportunity Contact Role from quotes if primary contact on Primary quotes for direct optys is edited
     * After update trigger method
     **/
    public static  void updatePrimaryContactOnOpportunityContactRole(List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal){
        ilib_LogEvent.push(LOG_TITLE+'updatePrimaryContactOnOpportunityContactRole()');
        List<Apttus_Proposal__Proposal__c> lstProps = new List<Apttus_Proposal__Proposal__c>();
        List<OpportunityContactRole> lstOCRs = new List<OpportunityContactRole>();
        Set<Id> setOppIds = new Set<Id>();
        Map<Id, List<OpportunityContactRole>> oppIdToOppContRole = new Map<Id, List<OpportunityContactRole>>();
        
        for(Apttus_Proposal__Proposal__c objProposal : (List<Apttus_Proposal__Proposal__c>)lstProposal){
            Apttus_Proposal__Proposal__c objOldProposal = idToOldProposal.get(objProposal.Id);
            if((objProposal.Apttus_Proposal__Primary__c && objProposal.Apttus_Proposal__Primary_Contact__c != objOldProposal.Apttus_Proposal__Primary_Contact__c) || 
               (objProposal.Apttus_Proposal__Primary__c != objOldProposal.Apttus_Proposal__Primary__c && 
                objProposal.Apttus_Proposal__Primary__c)){
                    lstProps.add(objProposal);
                    setOppIds.add(objProposal.Apttus_Proposal__Opportunity__c);
                }
        }
        if(!setOppIds.isEmpty()){
		ilib_LogEvent.info('setOppIds : '+setOppIds);
            //CMCM-4516
            //for(OpportunityContactRole objOCR : new OpportunityContactRoleSelector().selectRoles(setOppIds)){
            for(OpportunityContactRole objOCR : selectRoles(setOppIds)) {
                if(!oppIdToOppContRole.containsKey(objOCR.OpportunityId)){
                    oppIdToOppContRole.put(objOCR.OpportunityId,new List<OpportunityContactRole>());}
                oppIdToOppContRole.get(objOCR.OpportunityId).add(objOCR);
            }
        }    
        for(Apttus_Proposal__Proposal__c objProposal : lstProps){
            Boolean recordFound = false;
            if(oppIdToOppContRole.get(objProposal.Apttus_Proposal__Opportunity__c) != null){
                for(OpportunityContactRole objOCR : oppIdToOppContRole.get(objProposal.Apttus_Proposal__Opportunity__c)){
                    if(objProposal.Apttus_Proposal__Primary_Contact__c == objOCR.ContactId){
                        recordFound = true;
                        if(!objOCR.IsPrimary){
                            objOCR.IsPrimary = true;
                            lstOCRs.add(objOCR);
                        }
                        break;
                    }
                }
            }
            if(!recordFound){
                OpportunityContactRole objOppConRoleNew = new OpportunityContactRole(ContactId = objProposal.Apttus_Proposal__Primary_Contact__c,
                                                                                     OpportunityId = objProposal.Apttus_Proposal__Opportunity__c,
                                                                                     IsPrimary = true);
                lstOCRs.add(objOppConRoleNew);
            }
        }
        if(!lstOCRs.isEmpty()){
            OpportunityContactRoles.isConRoleUpdatedFromQuote = true;
            List<Database.UpsertResult> srUpsertOptyConRole = Database.upsert(lstOCRs, true);
            ApexExceptions.emitUpsertErrors(srUpsertOptyConRole, STRING_APTTUSPROPOSALS);
        }      
		ilib_LogEvent.pop();
    }

    /**
     *  @author Roopal Verma
     *  @description Rolls up term months field from quotation line item on quotation
     *  @parameter lstProposals 
     **/
    public void rollUpTermMonths(Map<Id, Apttus_Proposal__Proposal__c> idToProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'rollUpTermMonths()');
		ilib_LogEvent.info('idToProposal Ids : '+(idToProposal !=NULL ? String.valueOf(idToProposal.keySet()):MAPISEMPTY));
        Map<Id, double> mapQuoteIdToTerm = new Map<Id, double>();
        Set<Id> setQuoteIds = idToProposal.keySet();
        List<AggregateResult> lstAggrResults = [SELECT Apttus_Proposal__Proposal__c QuoteID, SUM(Term_Months__c) Total FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c IN :setQuoteIds GROUP BY Apttus_Proposal__Proposal__c];

        for (AggregateResult result : lstAggrResults) {
            ilib_LogEvent.message('result : '+result);
            Id idQuote = (Id) result.get('QuoteID');
            double doTotal = (double) result.get('Total');
            ilib_LogEvent.message('idQuote : '+idQuote);
            ilib_LogEvent.message('doTotal : '+doTotal);
            mapQuoteIdToTerm.put(idQuote, doTotal);
        }
		ilib_LogEvent.info('mapQuoteIdToTerm : '+mapQuoteIdToTerm);
        for (Apttus_Proposal__Proposal__c objQuote : idToProposal.values()) {
            Double doTermMonth = 0;
			ilib_LogEvent.message('objQuote : '+objQuote);
            if (mapQuoteIdToTerm.containsKey(objQuote.Id)) {
                doTermMonth = mapQuoteIdToTerm.get(objQuote.Id);
				ilib_LogEvent.message('doTermMonth : '+doTermMonth);
            }

            if(objQuote.Template_Term_Months__c != doTermMonth){
                objQuote.Template_Term_Months__c = doTermMonth;
				ilib_LogEvent.message('objQuote.Template_Term_Months__c : '+objQuote.Template_Term_Months__c);
            }
        }
		ilib_LogEvent.pop();
    }
	
	/*Method - Updates Opportunity Fields on Quote update [DCP-43259] Test Class - TestOpportunityUpdateFromQuoteQueueable*/
    public static void updateQuoteStageOnOpp(Map<Id,SObject> newMapSObject , Map<Id,SObject> oldMapSObject)
    {
		ilib_LogEvent.push(LOG_TITLE+'updateQuoteStageOnOpp()');
        Map<Id,Apttus_Proposal__Proposal__c> newMap = (Map<Id,Apttus_Proposal__Proposal__c>)newMapSObject;
        Map<Id,Apttus_Proposal__Proposal__c> oldMap = (Map<Id,Apttus_Proposal__Proposal__c>)oldMapSObject;
        Map<Id,Apttus_Proposal__Proposal__c> mapPropWithChangesNew = new Map<Id,Apttus_Proposal__Proposal__c>();
        Map<Id,Apttus_Proposal__Proposal__c> mapPropWithChangesold = new Map<Id,Apttus_Proposal__Proposal__c>();
        
        for(Apttus_Proposal__Proposal__c prpsl : newMap.values())
        {
            if((prpsl.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageInReview 
            && oldMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c != System.Label.QuoteStageInReview) 
            || (prpsl.Apttus_Proposal__Approval_Stage__c != System.Label.QuoteStageInReview 
            && oldMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageInReview))
            {
                mapPropWithChangesNew.put(prpsl.Id,prpsl);
                mapPropWithChangesold.put(prpsl.Id,oldMap.get(prpsl.Id));
            }
        }
		ilib_LogEvent.info('mapPropWithChangesNew Ids : '+(mapPropWithChangesNew !=NULL ? String.valueOf(mapPropWithChangesNew.keySet()):MAPISEMPTY));
		ilib_LogEvent.info('mapPropWithChangesold Ids : '+(mapPropWithChangesold !=NULL ? String.valueOf(mapPropWithChangesold.keySet()):MAPISEMPTY));

        if(!mapPropWithChangesNew.keySet().isEmpty()){
        OpportunityUpdatesFromQuoteQueueable oppUpdateFromQuote = new OpportunityUpdatesFromQuoteQueueable(mapPropWithChangesNew,mapPropWithChangesold);
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('ApttusProposals_OpportunityUpdatesFromQuoteQueueable');
        queueableThread.logAndQueue(oppUpdateFromQuote, 'OpportunityUpdatesFromQuoteQueueable', STREXECUTE);
        ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);  
        }
		ilib_LogEvent.pop();
    }
    /*Method - Checks if quote is Generated or Presented and fires Queueable Job DCP-43259- [TestClass - TestAutoPopulateFieldsOnUpdateQueueable] */
    public static void autoPopulateFieldsOnUpdate(Boolean isInsert)
    {
		ilib_LogEvent.push(LOG_TITLE+'autoPopulateFieldsOnUpdate()');
        Map<Id,Apttus_Proposal__Proposal__c> newPropMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.newMap;
        Map<Id,Apttus_Proposal__Proposal__c> oldPropMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.oldMap;
        boolean fireQueueable = false;
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(newPropMap.values() , 'Apttus_Proposal__Opportunity__c');
        //Map to store Related Opportunity
        //CMCM-4516 continuing to use selectr as it checks cache for the queried records
        Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
        //Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c FROM Opportunity WHERE Id IN :setOpportunityIds]);

        for(Apttus_Proposal__Proposal__c prpsl : newPropMap.values())
        {
            if(isInsert && idToOpportunity.get(prpsl.Apttus_Proposal__Opportunity__c).First_Proposal_Id__c == null)
            {
                fireQueueable = true;
            }
            if(!isInsert && oldPropMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c != prpsl.Apttus_Proposal__Approval_Stage__c //Koustubh M, TASK0679416, 17th Dec 2021 :- Bug fix - Multiple queueables were getting queued in the same batchable context.
            && ((prpsl.Apttus_Proposal__ReadyToPresent__c && prpsl.Apttus_Proposal__Presented_Date__c != null 
            && prpsl.Apttus_Proposal__Approval_Stage__c == QUOTE_STAGE_PRESENTED) || prpsl.Apttus_Proposal__Approval_Stage__c == QUOTE_STAGE_GENERATED))
            {
                fireQueueable = true; //DCP-46204
            }
            if(!isInsert && prpsl.Apttus_Proposal__Approval_Stage__c == QUOTE_STAGE_PRESENTED 
            && oldPropMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c != prpsl.Apttus_Proposal__Approval_Stage__c //Koustubh M, TASK0679416, 17th Dec 2021 :- Bug fix - Multiple queueables were getting queued in the same batchable context.
            && idToOpportunity.get(prpsl.Apttus_Proposal__Opportunity__c).Proposal_Sent_On__c == null 
            && idToOpportunity.get(prpsl.Apttus_Proposal__Opportunity__c).StageName != OPPORTUNITY_STAGE_CREATE)
            {
                fireQueueable = true;
            }
        }

        if(fireQueueable)
        {
            fireQueueableForOppUpdates(idToOpportunity,newPropMap,isInsert);
        }
		ilib_LogEvent.pop();
    }
    /* Method to Initialize Queueable Class- Test Class - TestAutoPopulateFieldsOnUpdateQueueable*/
    public static void fireQueueableForOppUpdates(Map<Id,Opportunity> oppIdToOppMap , Map<id,Apttus_Proposal__Proposal__c> proposalMap,Boolean isInsert)
    {
		ilib_LogEvent.push(LOG_TITLE+'fireQueueableForOppUpdates()');
        AutoPopulateOppFieldsOnUpdateQueueable oppFieldsUpdate = new AutoPopulateOppFieldsOnUpdateQueueable(oppIdToOppMap,proposalMap,isInsert);
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('ApttusProposals_AutoPopulateOppFieldsOnUpdateQueueable');
        queueableThread.logAndQueue(oppFieldsUpdate, 'AutoPopulateOppFieldsOnUpdateQueueable', STREXECUTE);
        ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SALES);
		ilib_LogEvent.pop();
    }
	
	/*Method - Check if Is Updated By System is Updated to False [DCP-43259] Test Class - TestOpportunityUpdatesFromQuoteQueueable */
    public static void checkIsUpdatedBySystem(Boolean isInsert)
    {
		ilib_LogEvent.push(LOG_TITLE+'checkIsUpdatedBySystem()');
        Map<Id,Apttus_Proposal__Proposal__c> newMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.newMap;
        Map<Id,Apttus_Proposal__Proposal__c> oldMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.oldMap;
        Set<Id> prpIdSet = new Set<Id>();
        for(Apttus_Proposal__Proposal__c prpsl : newMap.values())
        {
            if(isInsert && newMap.get(prpsl.Id).Is_Updated_By_System__c)
            {
                prpIdSet.add(prpsl.Id);
            }
            else if(!isInsert && oldMap.get(prpsl.Id).Is_Updated_By_System__c != prpsl.Is_Updated_By_System__c && prpsl.Is_Updated_By_System__c)
            {
                prpIdSet.add(prpsl.Id);
            }
        }
        if(!prpIdSet.isEmpty() && !boolHasRunOnce)
        {
			ilib_LogEvent.info('prpIdSet : '+prpIdSet);
            boolHasRunOnce = true;
            if(System.isBatch() || TestBatchOpportunityQuotePopulateRegion.dontRun) 
            {
                List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
                for(Id proposalId : prpIdSet)
                {
                Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c(Id=proposalId , Is_Updated_By_System__c = false);
                proposalList.add(prop);
                }
                update proposalList;
            }
            else
            {
                QuotationIsUpdatedBySystemQueueable oppIsUpdatedBySystemUpdate = new QuotationIsUpdatedBySystemQueueable(prpIdSet);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('ApttusProposals_QuotationIsUpdatedBySystemQueueable');
                queueableThread.logAndQueue(oppIsUpdatedBySystemUpdate, 'QuotationIsUpdatedBySystemQueueable', STREXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);    
            }
        }
		boolHasRunOnce = true;
		ilib_LogEvent.pop();
    }
	
	/*
	 *@author Rishab
	 *description- [DCP-46920] Auto Generate Document when approved 
	 */
	public static void autoGenerateQuoteDocumentWhenApproved()
	{
		ilib_LogEvent.push(LOG_TITLE+'autoGenerateQuoteDocumentWhenApproved()');
        if(!test.isRunningTest() || (Test.isRunningTest() && TestApttusProposals.runAutoGenerateLogic)){
            Map<Id,Apttus_Proposal__Proposal__c> newMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.newMap;
            Map<Id,Apttus_Proposal__Proposal__c> oldMap = (Map<Id,Apttus_Proposal__Proposal__c>)trigger.oldMap;
            Set<Id> setProposalId = new set<Id>();
            List<String> lstActionClasses = new List<String>{'QuoteGenerateSAPCallQueueable','QuoteGenerationQueueable','SendEmailToQuoteOwnersQueueable'};

            for(Apttus_Proposal__Proposal__c prpsl : newMap.values())
            {
                if((prpsl.Apttus_Proposal__Approval_Stage__c == APPROVAL_STAGE_APPROVED 
                    && oldMap.get(prpsl.Id).Apttus_Proposal__Approval_Stage__c != prpsl.Apttus_Proposal__Approval_Stage__c // DCP-49904 - Removed check for prior stage to be In Review
                    && !prpsl.Direct_Sale_to_Ultimate_Consignee__c && String.isBlank(prpsl.Work_Order__c)) || test.isRunningTest())
                    {
                        setProposalId.add(prpsl.Id);
                    }
            }
            
            if(!setProposalId.isEmpty())
            {
                boolRecursiveCheck = true;
                CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
                List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{ApttusCheckPriceBaseClass.CODEPARAMETERNAME});    
                Map<Id,Integer> proposalIdToLineItemNumber = getProposalToLineItemNumberMap(setProposalId);
                Set<Id> setQuoteIdToUpdated = new Set<Id>();

                for(Id proposalId : setProposalId)
                {
                    if(test.isRunningTest() || (proposalIdToLineItemNumber.containsKey(proposalId) && proposalIdToLineItemNumber.get(proposalId) < Integer.valueOf(objCodeParam[0].Value__c)))
                    {
                        setQuoteIdToUpdated.add(proposalId);
                    }
                }
				ilib_LogEvent.info('setQuoteIdToUpdated : '+setQuoteIdToUpdated);
                if(!setQuoteIdToUpdated.isEmpty())
                {
                    ilib_Queueablethread queueableDocGenerate = new ilib_Queueablethread('ApttusProposals_AutoGenerateDoc');
                    for(Id prpId : setQuoteIdToUpdated)
                    {
                        OpportunityQuoteAutomationQueueable quoteAutoGen = new OpportunityQuoteAutomationQueueable(prpId,null,lstActionClasses);
                        queueableDocGenerate.logAndQueue(quoteAutoGen,'QuotationAutoGenerateDoc', STREXECUTE);
                    }
                    ilib_QueueableManager.enqueueJob(queueableDocGenerate,ilib_LogEvent.SALES);
                }
            }
        }
		ilib_LogEvent.pop();
	}

       /*
        *@author Rishab
        *@Param -> set of Proposal ids 
        *@description -> returns Map of proposal to number of line items */
        public static Map<Id,Integer> getProposalToLineItemNumberMap(Set<Id> setProposalId)
        {
			ilib_LogEvent.push(LOG_TITLE+'getProposalToLineItemNumberMap()');
            Map<Id,Integer> prpslIdToLineItemNumber = new Map<Id,Integer>();
            //CMCM-4516
            // List<Apttus_Proposal__Proposal_Line_Item__c> lstPli = new List<Apttus_Proposal__Proposal_Line_Item__c>(new ApttusProposalLineItemsSelector().selectByQuoteId(setProposalId));
            List<Apttus_Proposal__Proposal_Line_Item__c> lstPli = proposalsSelectByQuoteId(setProposalId);
            ilib_LogEvent.info('lstPli: '+lstPli);
            for(Apttus_Proposal__Proposal_Line_Item__c pli : lstPli)
            {
                if(prpslIdToLineItemNumber.containsKey(pli.Apttus_Proposal__Proposal__c)){
                    Integer i = prpslIdToLineItemNumber.get(pli.Apttus_Proposal__Proposal__c);
                    prpslIdToLineItemNumber.put(pli.Apttus_Proposal__Proposal__c,i+1);
                }
                else
                {
                    prpslIdToLineItemNumber.put(pli.Apttus_Proposal__Proposal__c,1);
                }
            }
			ilib_LogEvent.info('prpslIdToLineItemNumber : '+prpslIdToLineItemNumber);
			ilib_LogEvent.pop();

            return prpslIdToLineItemNumber;
        }
	/* [DCP-45399] Sync Indirect Opportunity Products To Quotes */
    public void syncDirectOpportunityProductsToQuotes(List<Apttus_Proposal__Proposal__c> lstProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'syncDirectOpportunityProductsToQuotes()');
        Set<Id> setOfDirectOpportunityIds = new Set<Id>();
        Map<Id, Apttus_Proposal__Proposal__c> idToProposalToAddProduct = new Map<Id, Apttus_Proposal__Proposal__c>();

        for (Apttus_Proposal__Proposal__c objProposal : lstProposal)
        {
            if(objProposal.isClone()) { continue; } 
            Boolean boolQuoteSubTypeByPass = String.isNotBlank(objProposal.Quote_Sub_Type__c) && SET_QUOTE_SUBTYPES_FOR_BYPASS.contains(objProposal.Quote_Sub_Type__c);//Bypass for billable flow

            if (objProposal.Apttus_QPConfig__PriceListId__c != NULL
                && objProposal.Apttus_Proposal__Opportunity__c != NULL
                && objProposal.Quote_Type__c != NULL
                && objProposal.Quote_Type__c.contains('Direct')
                && !boolQuoteSubTypeByPass )
            {
                setOfDirectOpportunityIds.add(objProposal.Apttus_Proposal__Opportunity__c);
                idToProposalToAddProduct.put(objProposal.Id, objProposal);
            }
        }


        List<OpportunitySyncToQuote__e> lstDirectOppSyncs= new List<OpportunitySyncToQuote__e>();
        if (setOfDirectOpportunityIds.isEmpty()) {ilib_LogEvent.pop(); 
		return; }
        ilib_LogEvent.info('setOfDirectOpportunityIds : '+setOfDirectOpportunityIds);
            
        //CMCM-4516
        //Map<Id, Opportunity> idToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOfDirectOpportunityIds));
        Map<Id, Opportunity> idToOpportunity = new Map<Id, Opportunity>([SELECT AccountId, Account_Change__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, ByPass_LockSentProposalDate__c, Company_Code_Address__c, Consortium__c, Contract_Number__c, CurrencyIsoCode, Direct_Sale_to_Ultimate_Consignee__c, Distributor__c, Exclude_from_Forecast__c, First_Proposal_Id__c, ICE_Opportunity_Product_Lines__c, Id, Is_Contact_Role_Identified__c, Is_Customer_Readiness_Form_Required__c, Is_Power_Sponsor_Identified__c, Is_Quote_Stage_In_Review__c, Is_Updated_By_System__c, OwnerId, Partner_Request__c, Price_List_Type__c, Price_List__c, Primary_Contact__c, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c, Product_Interest__c, Product_Type__c, Proposal_Sent_On__c, RecordTypeId, RecordTypeName__c, Sales_Area_Distributor__c, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Ship_To_Sales_Org__c, Sold_To_Account_Region__c, Sold_to_Distribution_Channel__c, Sold_to_Division__c, Sold_to_Sales_Organization__c, StageName, Territory_Region__c, Transborder_Flag__c, Type, Ultimate_Consignee_Region__c, Ultimate_Consignee__c, Work_Order__c, Account.Apttus_Config2__PaymentTermId__c, Account.BillingCountry, Account.Business_Unit__c, Account.CurrencyIsoCode, Account.ERP_Customer_Id__c, Account.Preferred_Language__c, Account.Subregion__c, Consortium__r.Project_Manager__c, Distributor__r.BillingCountry, Distributor__r.Business_Unit__c, Distributor__r.ERP_Customer_Id__c, Distributor__r.Subregion__c, Primary_Contact__r.Email, Primary_Contact__r.Phone, RecordType.DeveloperName, Related_Agreement__r.OwnerId, Ultimate_Consignee__r.BillingCountry, Ultimate_Consignee__r.Business_Unit__c, Ultimate_Consignee__r.CurrencyIsoCode, Ultimate_Consignee__r.ERP_Customer_Id__c, Ultimate_Consignee__r.Subregion__c, Work_Order__r.Account_Region__c, Work_Order__r.Initiate_Quoting__c, Work_Order__r.Name, Work_Order__r.OwnerId, Account.Owner.Id, Distributor__r.Owner.Id, Partner_Request__r.RecordType.DeveloperName, Related_Agreement__r.Apttus__Account__r.Territory_Region__c, Related_Agreement__r.Owner.Email, Ultimate_Consignee__r.Owner.Id, Work_Order__r.Owner.Email, Work_Order__r.Owner.Type, Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c FROM Opportunity WHERE Id IN :setOfDirectOpportunityIds]);
        for (Apttus_Proposal__Proposal__c objProposal : idToProposalToAddProduct.values())
        {
            if (idToOpportunity.containsKey(objProposal.Apttus_Proposal__Opportunity__c))
            {
                OpportunitySyncToQuote__e directOppSyncToQuote = new OpportunitySyncToQuote__e(QuoteId__c = objProposal.Id);
                lstDirectOppSyncs.add(directOppSyncToQuote);
            }
        }

        if (lstDirectOppSyncs.isEmpty()) {ilib_LogEvent.pop(); 
		return; }

        publishSyncPlatformEvent(JSON.serialize(lstDirectOppSyncs));
		ilib_LogEvent.pop();
    }

    /*Method - [DCP-45399] To check If Products Added are having correct Product Level Indicators for all users */
    public static void checkProductIndicatorIfOppHasLineItems(List<Apttus_Proposal__Proposal__c> lstProposal)
    {
		ilib_LogEvent.push(LOG_TITLE+'checkProductIndicatorIfOppHasLineItems()');
        Map<id,String> productIdToIndicatorMap = new Map<Id,String>();
        Map<Id,Set<Id>> oppIdToProductSet = new Map<Id,Set<Id>>();
        Map<Id,String> productIdToProductNameMap = new Map<Id,String>();
        Map<Id,String> productIdToProductCodeMap = new Map<Id,String>();

        if(!test.isRunningTest() || boolCheckPLIndicatorOnInsertFromTest)
        {
            Set<Id> setOppIds = UtilsCollection.getSetOfIds(lstProposal, 'Apttus_Proposal__Opportunity__c');

            //CMCM-4516
            // OpportunityLineItemsSelector oppLineItemSelector = new OpportunityLineItemsSelector();
            List<OpportunityLineItem> lstOli = new List<OpportunityLineItem>();
            
            if(setOppIds.isEmpty()){ilib_LogEvent.pop(); 
			return; }
            //CMCM-4516
            //lstOli = oppLineItemSelector.selectOpportunityLineItems(setOppIds);
            lstOli = selectOpportunityLineItems(setOppIds);
            if(lstOli.isEmpty()) {ilib_LogEvent.pop(); 
			return; }

            for(OpportunityLineItem oli : lstOli)
            {
                if(oppIdToProductSet.containsKey(oli.opportunityId))
                {
                    Set<Id> productsSet = oppIdToProductSet.get(oli.opportunityId);
                    productsSet.add(oli.Product2Id);
                    oppIdToProductSet.put(oli.opportunityId,productsSet);
                }
                else
                {
                    oppIdToProductSet.put(oli.opportunityId,new Set<Id>{oli.Product2Id});
                }
                if(String.isNotBlank(oli.Product2.Product_Level_Indicator__c))
                {
                    productIdToIndicatorMap.put(oli.Product2Id,oli.Product2.Product_Level_Indicator__c);
                }
                else
                {
                    productIdToIndicatorMap.put(oli.Product2Id,'');
                }                
                productIdToProductNameMap.put(oli.Product2Id,oli.Product2.Name);
                productIdToProductCodeMap.put(oli.Product2Id,oli.Product2.ProductCode);
            }
			ilib_LogEvent.info('productIdToProductNameMap : '+productIdToProductNameMap);
			ilib_LogEvent.info('productIdToProductCodeMap : '+productIdToProductCodeMap);
            if(!productIdToIndicatorMap.isEmpty() && !oppIdToProductSet.isEmpty())
            {
                generateErrorsForProducts(productIdToIndicatorMap,oppIdToProductSet,productIdToProductNameMap,productIdToProductCodeMap);
            }
        }
		ilib_LogEvent.pop();
    }

    /**Method - Add errors for product level indicator */
    public static void generateErrorsForProducts(Map<id,String> productIdToIndicatorMap,Map<Id,Set<Id>> oppIdToProductSet,Map<Id,String> productIdToProductNameMap,Map<Id,String> productIdToProductCodeMap)
    {
		ilib_LogEvent.push(LOG_TITLE+'generateErrorsForProducts()');
        String initailError = 'The below products have a commercial status (Product Level Indicator, or PLI)'+
                              ' that you are not authorized to quote. Please remove the below products to continue quoting, '+
                              ' or contact your Regional Quoting team or the Product Manager for assistance:      ';
		ilib_LogEvent.info('initialError : '+initailError);
        Product_Level_Indicator__c pli = Product_Level_Indicator__c.getInstance(userinfo.getProfileId());
        String strIndicatorsAllowed = pli.Values__c;
        List<String> lstProductLevelIndicator = new List<String>();
        if(test.isRunningTest())
        {
            strIndicatorsAllowed = 'COM_TEST,COM_TTTT';
        }
        if(String.isNotBlank(strIndicatorsAllowed))
        {
            if(strIndicatorsAllowed.contains(','))
            {
                lstProductLevelIndicator = strIndicatorsAllowed.split(',');
            }
            else
            {
                lstProductLevelIndicator.add(strIndicatorsAllowed);
            }
        }

        for(Apttus_Proposal__Proposal__c proposal : (List<Apttus_Proposal__Proposal__c>)trigger.new)
        {
            String errorMsg = '';
            if(oppIdToProductSet.containsKey(proposal.Apttus_Proposal__Opportunity__c))
            {
                Set<Id> productIdSet = oppIdToProductSet.get(proposal.Apttus_Proposal__Opportunity__c);
                for(Id prodId : productIdSet)
                {
                    if(productIdToIndicatorMap.containsKey(prodId) && !lstProductLevelIndicator.contains('\'' + productIdToIndicatorMap.get(prodId) + '\''))
                    {
                        errorMsg += productIdToProductCodeMap.get(prodId) + ' - ' + productIdToProductNameMap.get(prodId) + ', ' + 'PLI: ' + productIdToIndicatorMap.get(prodId) + ';    ';
                    }
                }
            }
			ilib_LogEvent.message('errorMsg : '+errorMsg);
            if(String.isNotBlank(errorMsg))
            {
                proposal.addError(initailError + errorMsg);
            }
        }
		ilib_LogEvent.pop();
    }

    /*INC0350488 - Method to update Reprice Completed flag to true and show Add Products button on Quote */
    public static void updateRepriceFlagOnQuote(Id proposalId) {
		ilib_LogEvent.push(LOG_TITLE+'updateRepriceFlagOnQuote()');
        Apttus_Proposal__Proposal__c objProposal = new Apttus_Proposal__Proposal__c(Id=proposalId);
        objProposal.Is_Reprice_Completed__c = true;
        update objProposal;
        ilib_LogEvent.info(STROBJPROPOSAL+objProposal);
		ilib_LogEvent.pop();
    }
    /*
    *@author Himanshu
    *@Param -> Apttus_Proposal__Proposal__c  objProposal
    *@description -> Stamp value for Subit for Approval Message for Open Offer 
    */
    public static  void checkForSubmitForApprovalErrors(Apttus_Proposal__Proposal__c objProposal) {
        Boolean boolIsOpenOfferCustomerAndHasProduct = objProposal.Quote_For_Open_Offer_Customer__c  && objProposal.Quote_Has_Open_Offer_Product__c;
        if((objProposal.Open_Offer_Discount_Violation_Type__c == System.Label.DiscountExceededByFifteen || objProposal.Open_Offer_Discount_Violation_Type__c == System.Label.DiscountExceeded ) && !String.isBlank(objProposal.Open_Offer_Discount_Exception_Request__c) && String.isBlank(objProposal.Discount_Justification__c) && boolIsOpenOfferCustomerAndHasProduct) {
            objProposal.Submit_For_Approval_Error__c = Label.UI_Label_Open_Offer_Discount_Exception_Message;
        } else {
            objProposal.Submit_For_Approval_Error__c = '';

        }


    }

    /*
    *@author Vishal
    *@Param -> Map<String, List<Apttus_Proposal__Proposal_Line_Item__c>> mapForEmail
    *@description -> Returns a list of Messaging.SingleEmailMessage object when products do not have HSN or SAC codes 
    */
    public static List<Messaging.SingleEmailMessage> sendEmailForMissingProductCode(Map<String, List<Apttus_Proposal__Proposal_Line_Item__c>> mapForEmail){
        ilib_LogEvent.push(LOG_TITLE+'.sendEmailForMissingProductCode()');
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingHSN = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingSAC = new List<Apttus_Proposal__Proposal_Line_Item__c>();

        for (String missingCode : mapForEmail.keySet()){
            if(missingCode == HSN){
                lstPliMissingHSN.addAll(mapForEmail.get(missingCode));
            }
            else{
                lstPliMissingSAC.addAll(mapForEmail.get(missingCode));
            }
        }
        ilib_LogEvent.info('lstPliMissingSAC:'+lstPliMissingSAC);
        if(!lstPliMissingSAC.isEmpty()){
            mails.add(getSACMissingEmail(lstPliMissingSAC));
        }
        ilib_LogEvent.info('lstPliMissingHSN:'+lstPliMissingHSN);
        if(!lstPliMissingHSN.isEmpty()){
            mails.add(getHSNMissingEmail(lstPliMissingHSN));
        }
        ilib_LogEvent.info('mails:'+mails);
        ilib_LogEvent.pop();
        return mails;
    }


    /*
    *@author Vishal
    *@Param -> List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingSAC
    *@description -> Returns a Messaging.SingleEmailMessage object when products do not have SAC code 
    */

    public static Messaging.SingleEmailMessage getSACMissingEmail(List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingSAC){
        List<String> listToAddressSAC = new List<String>();
        if(!Test.isRunningTest()){
            listToAddressSAC.addAll(Code_Parameter__mdt.getInstance(EMAIL_ID_FOR_MISSING_SAC_CODE).Value__c.split(';'));
        }
        else {
            listToAddressSAC.add('abc@illumina.com');
        } 
        ilib_LogEvent.info('listToAddressSAC:'+ listToAddressSAC);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(listToAddressSAC);
        mail.setSubject('Missing SAC Code (India)');
        String strBody = '<p>Quote ' + lstPliMissingSAC[0].Apttus_Proposal__Proposal__r.Name + ' was created with the following product(s) missing the SAC Code:</n></p>';
        Integer num = 1;
        for (Apttus_Proposal__Proposal_Line_Item__c pli : lstPliMissingSAC){
            strBody += '<table><tbody>';
            strBody += '<tr><td style = "vertical-align:top;">' + num + ') </td><td style = "vertical-align:top;">Product Number</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.ProductCode + '</td></tr>';
            strBody += '<tr><td style = "vertical-align:top;"></td><td style = "vertical-align:top;">Product Name</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.Name + '</td></tr>';
            strBody += '<tr><td style = "vertical-align:top;"></td><td style = "vertical-align:top;">Product Description</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.Description + '</td><tr>';
            strBody += '</tbody></table><br><br>';
            num += 1;
        }
        strBody += '<p>Please add SAC Code for the product(s) listed above.</p><p>Thank you.</p>';
        mail.setHtmlBody(strBody);
        return mail;
    }

    /*
    *@author Vishal
    *@Param -> List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingHSN
    *@description -> Returns a Messaging.SingleEmailMessage object when products do not have HSN code 
    */
    public static Messaging.SingleEmailMessage getHSNMissingEmail(List<Apttus_Proposal__Proposal_Line_Item__c> lstPliMissingHSN){
        List<String> listToAddressHSN = new List<String>();
        if(!Test.isRunningTest()){
            listToAddressHSN.addAll(Code_Parameter__mdt.getInstance(EMAIL_ID_FOR_MISSING_HSN_CODE).Value__c.split(';'));
        }
        else {
            listToAddressHSN.add('abc@illumina.com');
        }
        String strCCAddressHSN = Test.isRunningTest() ? 'abc@illumina.com' : Code_Parameter__mdt.getInstance(EMAIL_ID_CC_FOR_MISSING_HSN_CODE).Values_Text__c;
        ilib_LogEvent.info('listToAddressHSN:'+ listToAddressHSN);
        ilib_LogEvent.info('strCCAddressHSN:'+ strCCAddressHSN);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(listToAddressHSN);
        mail.setCCAddresses(new List<String>{strCCAddressHSN});
        mail.setSubject('Missing HSN Code (India)');
        String strBody = '<p>Quote ' + lstPliMissingHSN[0].Apttus_Proposal__Proposal__r.Name + ' was created with the following product(s) missing the HSN Code:</n></p>';
        Integer num = 1;

        for (Apttus_Proposal__Proposal_Line_Item__c pli : lstPliMissingHSN){
            strBody += '<table><tbody>';
            strBody += '<tr><td style = "vertical-align:top;">' + num + ') </td><td style = "vertical-align:top;">Product Number</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.ProductCode + '</td></tr>';
            strBody += '<tr><td style = "vertical-align:top;"></td><td style = "vertical-align:top;">Product Name</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.Name + '</td></tr>';
            strBody += '<tr><td style = "vertical-align:top;"></td><td style = "vertical-align:top;">Product Description</td><td style = "vertical-align:top;"> - </td></td>' + '<td style = "vertical-align:top;">' + pli.Apttus_Proposal__Product__r.Description + '</td><tr>';
            strBody += '</tbody></table><br><br>';
            num += 1;
        }
        strBody += '<p>Please add HSN Code for the product(s) listed above.</p><p>Thank you.</p>';
        mail.setHtmlBody(strBody);
        return mail;
    }
    
    // added as part of CMCM-11810 
    private void addErrorforMultipleQuotesOnWebGenOpp(List<Apttus_Proposal__Proposal__c> newProposals,Map<Id,Apttus_Proposal__Proposal__c> oldProposals){
        list<Apttus_Proposal__Proposal__c> listofUpdatedProposals = new List<Apttus_Proposal__Proposal__c>();
        
        if(oldProposals != null){
            for(Apttus_Proposal__Proposal__c tempNewProposals : newProposals){
               if(oldProposals.get(tempNewProposals.Id)?.Apttus_Proposal__Opportunity__c != tempNewProposals.Apttus_Proposal__Opportunity__c){
                    listofUpdatedProposals.add(tempNewProposals);
                }
            }
        } else{listofUpdatedProposals.addAll(newProposals);
              }
        
        
        
        AggregateResult[] groupedResultsWebGenOpp;
        if(oldProposals == null || (listofUpdatedProposals.size()>0)){
        	 groupedResultsWebGenOpp = [Select Apttus_Proposal__Opportunity__r.Id,COUNT(ID) from Apttus_Proposal__Proposal__c where Apttus_Proposal__Opportunity__r.type=:WEBGENOPP GROUP BY Apttus_Proposal__Opportunity__r.ID]; 
        	 for(AggregateResult ar : groupedResultsWebGenOpp){
            	for(Apttus_Proposal__Proposal__c tempProposals2:listofUpdatedProposals){
                	if((tempProposals2.Apttus_Proposal__Opportunity__c  == (String) ar.get('ID')) && (Integer) ar.get('expr0')>0){
                    	tempProposals2.addError(Label.MultipleQuotePreventForWebGenOpp) ;
                	}
            	}
        	}
        }
            system.debug('Tracking SOQL after Aggr '+Limits.getqueries());	
        
    }
    
    //CMCM-4516
    private static List<Apttus_Proposal__Proposal_Line_Item__c> proposalsSelectByQuoteId(Set<Id> setQuoteIds) {
        return [SELECT Id,Customer_Net_Price__c,Premium__c,Freight_Discount_Amount__c,Apttus_QPConfig__Uom__c,Apttus_Proposal__Quantity__c,Approval_Level_Promotion__c,
        Approval_Category__c,Apttus_Proposal__Proposal__c,Apttus_QPApprov__Approval_Status__c,Configuration_Status__c,Material_Number__c,Apttus_QPConfig__ListPrice__c,
        Applied_Discount_Amount__c,Applied_Discount_Details__c,Apttus_QPConfig__AdjustedPrice__c,Apttus_QPConfig__Quantity2__c,Apttus_QPConfig__NetPrice__c,Apttus_QPConfig__NetAdjustmentPercent__c,
        Apttus_QPConfig__AdjustmentAmount__c,Apttus_QPConfig__AdjustmentType__c ,Applied_Discount_Percentage__c,Freight_Discount_Percentage__c,Discounted_Price_Per_Unit__c,Distributor_Discount_Amount__c,
        Distributor_Discount_Percentage__c,Stacked_Discount_Amount__c,Stacked_Discount_Percentage__c,Name,Apttus_QPConfig__LineNumber__c,Apttus_QPConfig__ItemSequence__c,
        Apttus_QPConfig__LineType__c,Apttus_QPConfig__PrimaryLineNumber__c,Apttus_QPConfig__IsPrimaryLine__c,Apttus_QPConfig__LineStatus__c,Apttus_QPConfig__AssetLineItemId__c,Apttus_QPConfig__PriceType__c,
        Apttus_QPConfig__SellingFrequency__c,Apttus_QPConfig__ChargeType__c,Apttus_Proposal__Product__c,ERP_Line_Number__c,Serial_Number__c,Billing_Type__c,Apttus_QPConfig__SellingTerm__c,Apttus_QPConfig__ParentBundleNumber__c,
        Total_Discount_Percentage__c,Total_Discount_Amount__c,Distributor_Specific_Discount_Percentage__c,Distributor_Specific_Discount__c,Apttus_QPConfig__BillingFrequency__c,Derived_From_Name__c,Sales_Discretionary_Type__c,
        Sales_Discretionary_Discount__c,Customer_Price_Per_Unit__c,Distributor_Rebate__c,Apttus_QPConfig__OptionId__c,Price_Override__c,Beadchip_Part_Number__c,Project_Id__c,List_Price__c,Apttus_QPConfig__PriceAdjustmentAmount__c,
        Max_Samples_Allowed_Per_kit__c,Price_per_sample__c,Total_List_Price__c,Customer_Premium_Amount_Per_Unit__c,Distributor_Specific_Price__c,Program_Type__c,Equipment_Id__c,Apttus_QPConfig__StartDate__c,Apttus_QPConfig__EndDate__c,
        Suggested_Sales_Discount_Percentage__c,Suggested_Sales_Discount_Amount__c,Meets_Discount_Guidelines__c,Previous_ERP_Contract_Line_Number__c,Instance_Region__c,Domain_Name__c,Previous_ERP_Contract_Number__c,Registrant_Contact__c,
        Service_Connectivity__c,Custom_License_Flag__c,Custom_Licensing_Description__c,Product_Family__c,Product_Type__c,Product_Tier__c,Is_Informatics_Product__c,Is_iCredit__c,Is_Dragen__c,Apttus_QPConfig__DerivedFromId__c,
        Existing_Subscription__c,Renewal_Subscription__c,CurrencyIsoCode,Manual_Rebate__c,Signed_Open_Offer__c,Open_Offer_Comparison_Customer__c,Open_Offer_Product__c,Custom_Setup_Details__c,Manual_Rebate_Per_Unit__c,
        Select_Instance_Type__c,Primary_Email__c,Server_Connectivity__c,Sold_To_Sales_Organization__c,Apttus_Proposal__Product__r.Name,Apttus_Proposal__Product__r.ProductCode,Apttus_Proposal__Product__r.Bundle_Id__c,
        Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c,Apttus_Proposal__Product__r.Description,Apttus_Proposal__Product__r.Material_Type__c,Apttus_QPConfig__NetUnitPrice__c,Material_Class_Type__c,
        Shipping_In_Close_Quarter__c,Shipping_In_1Q_After_Close_Quarter__c,Shipping_In_2Q_After_Close_Quarter__c,Term_Months__c,Apttus_Proposal__Product__r.End_Of_Sale_Date__c,Control_Code_India_SAC__c,Commodity_Import_Code_India_HSN__c,
        Apttus_Proposal__Product__r.End_Of_Service_Date__c,Apttus_Proposal__Product__r.Material_Number__c,Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c,Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c,
        Apttus_QPConfig__OptionId__r.Material_Number__c,Apttus_QPConfig__OptionId__r.Name,Product_Indicator__c,Apttus_Proposal__Proposal__r.Quote_Type__c,Apttus_Proposal__Proposal__r.Name,Apttus_Proposal__Product__r.Material_Class_Type__c,
        Registrant_Contact__r.PGUID__c,Registrant_Contact__r.Email,Custom_License_Setup_Required__c,Custom_Setup_Required__c,Open_Offer_Max__c,Trade_In_Type__c
        FROM Apttus_Proposal__Proposal_Line_Item__c
        WHERE Apttus_Proposal__Proposal__c IN :setQuoteIds
        ];
    }

    private static List<Custom_Approval_Matrix__c> selectActive(Set<String> setTypes) {

        String strCondition = 'Active__c=true' + (setTypes == null ? ''  : ' AND RecordType.DeveloperName IN :setTypes');
        String query = 'SELECT Min_Discount__c,  Min_Discount_Amount__c,  Promotion__c,  Promo_Code__c,  Sales_Organization__c,  Material_Group_1__c, Material_Number__c, Agreement_Minimum_Discount__C,  Action__c, '
        + 'Agreement_Record_Type__c,  Clause_Name__c,  Region__c,  Approval_Hierarchy_Type__c, LastModifiedDate, Email_Queue__c,  Name, Active__c,  Discount_Level_1__c,  Discount_Level_2__c,  Discount_Level_3__c, '
        + 'Discount_Level_4__c,  Discount_Level_5__c,  Discount_Level_6__c, Discount_Level_7__c, Discount_Level_8__c,  Discount_Amount_Level_1__c,  Discount_Amount_Level_2__c,  Discount_Amount_Level_3__c,  Discount_Amount_Level_4__c,  Discount_Amount_Level_5__c, '
        + 'Discount_Amount_Level_6__c,Discount_Amount_Level_7__c, Discount_Amount_Level_8__c,  Material_Class__c,  Product__c,  Approver__c,  Promotion_Code__c,  RecordType.DeveloperName,  Distribution_Channel__c,  Country__c, Currency__c,  Post_Pricing_Message__c, '
        + 'Approval_Hierarchy__c,  Approval_Hierarchy__r.Approver_Level_1__c,  Approval_Hierarchy__r.Approver_Level_2__c,  Approval_Hierarchy__r.Approver_Level_3__c,  Approval_Hierarchy__r.Approver_Level_4__c, '
        + 'Approval_Hierarchy__r.Approver_Level_5__c,  Approval_Hierarchy__r.Approver_Level_6__c,  Material_Number__r.Material_Number__c FROM Custom_Approval_Matrix__c WHERE ' 
        + strCondition 
        + ' ORDER BY LastModifiedDate DESC';
        return Database.query(query);
        
    }

    private static List<SVMXC__Site__c> selectDistributorPartnerStockLocationByAccount(Set<Id> setAccountIds) {
        String strLocationType = 'Partner Stock';
        String likeVal = '%' + strLocationType + '%';
        return [SELECT 
            id,
            SVMX_PS_Active__c,
            Name,
            Is_Illumina_Address__c,
            SVMXC__Country__c,
            SVMX_PS_External_ID__c,
            Is_Primary_Illumina_Address__c,
            Inventory_Authority__c,
            Type__c,
            SVMXC__Account__c,
            ERP_Customer_ID__c
            FROM SVMXC__Site__c
            WHERE Type__c =: strLocationType AND SVMXC__Account__c IN :setAccountIds AND Name LIKE :likeVal
        ];
    }

    private List<Apttus_Config2__AssetLineItem__c> selectAssetsByUC(Set<Id> setUCId) {
        return [SELECT 
            id,
            Name,
            Apttus_Config2__AssetStatus__c,
            Days_After_Expiry__c,
            Apttus_Config2__AccountId__c,
            Ultimate_Consignee__c,
            Status__c,
            Apttus_Config2__StartDate__c,
            Apttus_Config2__EndDate__c,
            Serial_Number__c,
            Apttus_Config2__ProductId__r.Name,
            Apttus_Config2__ProductId__r.Apttus_Config2__ProductType__c,
            Apttus_Config2__ProductId__r.SVMXC__Product_Type__c,
            Apttus_Config2__ProductId__r.ProductCode
            FROM Apttus_Config2__AssetLineItem__c
            WHERE Ultimate_Consignee__c IN :setUCId
        ];
    }

    private List<Apttus_Config2__ProductConfiguration__c> selectConfigsByQuote(Set<Id> setProposalIds) {
        return [SELECT 
            id,
            Apttus_QPConfig__Proposald__c,
            Apttus_Config2__ApprovalStatus__c,
            Apttus_Config2__BillToAccountId__c,
            Apttus_Config2__BusinessObjectId__c,
            Apttus_Config2__NumberOfItems__c,
            Apttus_Config2__AccountId__c,
            Apttus_Config2__Status__c,
            Apttus_Config2__EffectiveDate__c,
            Apttus_Config2__PriceListId__c,
            Apttus_Config2__IsPricePending__c,
            Promotion_JSON__c,
            SAP_Errors__c,
            Promo_Name_1__c,
            Promo_Name_2__c,
            Promo_Name_3__c,
            SAP_quote_c__c,
            Apttus_Config2__ExpectedEndDate__c,
            Sub_Total__c,
            Is_SAP_Pricing_Completed__c,
            Apttus_Config2__VersionNumber__c,
            Number_of_Line_Items_During_Check_Price__c,
            GT_Check_Pending_Count__c
        FROM Apttus_Config2__ProductConfiguration__c
        WHERE Apttus_QPConfig__Proposald__c IN :setProposalIds
        ];
        
    }

    private List<Apttus_Config2__LineItem__c> selectLineItemsByConfigId(Set<Id> idConfigRequest) {
        return [
            SELECT Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__ProductId__r.Material_Class_Type__c,Apttus_Config2__OptionId__r.Material_Class__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ParentProductId__r.Bundle_Id__c,
            Apttus_Config2__ProductId__r.Product_Group_Code__c,Apttus_Config2__ProductId__r.Material_Number__c,Apttus_Config2__OptionId__r.Material_Number__c,Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
            Apttus_Config2__ProductId__r.Bundle_Id__c,Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c,Apttus_Config2__ProductId__r.End_Of_Sale_Date__c,Apttus_Config2__ProductId__r.End_Of_Service_Date__c,
            Apttus_Config2__OptionId__r.End_Of_Sale_Date__c,Apttus_Config2__OptionId__r.End_Of_Service_Date__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__OptionId__r.Name,Apttus_Config2__ConfigurationId__r.Promo_Name_1__c,
            Apttus_Config2__ConfigurationId__r.Promo_Name_2__c,Apttus_Config2__ConfigurationId__r.Promo_Name_3__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, 
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c,Apttus_Config2__ProductId__r.Open_Offer_Product__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c,Registrant_Contact__c,Registrant_Contact__r.AccountId,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Open_Offer_Comparison_Customer__c, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.Signed_Open_Offer__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Open_Offer_Comparison_Customer__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.Signed_Open_Offer__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.National_Group_Number__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.National_Group_Number__c,Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c,
            Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r.ERP_Customer_Id__c, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r.ERP_Customer_Id__c,id,Name,
            Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__AdjustmentType__c,Apttus_Config2__ListPrice__c,Apttus_Config2__LineNumber__c,Apttus_Config2__Quantity__c,Apttus_Config2__BasePrice__c,Apttus_Config2__NetPrice__c,
            Sales_Discretionary_Discount__c,Sales_Discretionary_Type__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__BaseExtendedPrice__c,Volume_Discount__c,Promotion_Discount__c,Apttus_Config2__PriceMethod__c,
            Apttus_Config2__PriceType__c,
            Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__SellingFrequency__c,Customer_Distributor_Specific_Price__c,Apttus_Config2__ItemSequence__c,Distributor_Specific_Price__c,
            Distributor_Specific_Discount_Percentage__c,
            Distributor_Specific_Discount__c,Total_Discount_Percentage__c,Total_Discount_Amount__c,Apttus_Config2__PricingStatus__c,Promo_Name__c,Promotion_Code__c,Apttus_Config2__PriceListItemId__c,Global_Trade_Block__c,
            Apttus_Config2__PrimaryLineNumber__c,
            Apttus_Config2__ParentBundleNumber__c,SAP_Net_Price__c,Apttus_Config2__HasOptions__c,Apttus_Config2__LineType__c,SAP_Cross_Plant_Status__c,Max_Samples_Allowed_Per_kit__c,Apttus_Config2__AssetLineItemId__c,
            Apttus_Config2__ConfigurationId__c,
            ERP_Line_Number__c,Software_Type__c,Apttus_Config2__ProductId__c,Apttus_Config2__BillingFrequency__c,Distributor_Rebate__c,Applied_Discount_Details__c,Price_Override__c,Reason_For_Price_Override__c,
            Project_Id__c,Beadchip_Part_Number__c,
            Customer_Price_Per_Unit__c,Customer_Net_Price__c,LastModifiedById,List_Price__c,Unit_Price__c,Total_List_Price__c,Price_per_sample__c,Customer_Premium_Amount_Per_Unit__c,Equipment_Id__c,Serial_Number__c,End_Of_Sale_Date__c,
            End_Of_Service_Date__c,Line_Item_Old_Values__c,Suggested_Sales_Discount_Percentage__c,Suggested_Sales_Discount_Amount__c,Manual_Rebate__c,Manual_Rebate_Per_Unit__c,Line_Item_Validate_Old__c,Program_Type__c,
            Shipping_In_Close_Quarter__c,
            Cost_Center__c,Distributor_Total_Discount__c,Open_Offer_Max__c,Applied_Discount_Percentage__c
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c IN :idConfigRequest
            ORDER BY Apttus_Config2__LineNumber__c, Apttus_Config2__OptionId__r.Apttus_Config2__ConfigurationType__c ASC
        ];
    }

    private List<Account> selectAccounts(Set<Id> accountIds) {
        return [
            SELECT 
            Id,
            Name,
            OwnerId,
            ERP_Customer_Id__c,
            Account_Group__c,
            BillingStreet,
            BillingPostalCode,
            BillingCity,
            BillingCountryCode,
            BillingCountry,
            BillingState,
            BillingStateCode,
            Phone,
            CurrencyIsoCode,
            NameLocal,
            Street_2_Local__c,
            Street_Local__c,
            City_Local__c,
            Country_Local__c,
            State_Province_Local__c,
            Customer_Type__c,
            Customer_Sub_Type__c,
            Clinical_Type__c,
            Market_Segment__c,
            AccountId_18_Char_Id__c,
            Channel_Partner_Type__c,
            Website,
            Zip_Postal_Code_Local__c,
            Tier__c,
            Address_Status__c,
            Account_Status__c,
            LastModifiedById,
            Care_Of__c,
            Care_Of_Local__c,
            Territory_Region__c,
            District__c,
            Territory_Code__c,
            Ultimate_Parent_Id__c,
            IsCustomerPortal,
            IsPartner,
            R_Q_Contact_Compliant__c, 
            R_Q_Contact_Eligible__c, 
            R_Q_Non_Compliance_Date__c, 
            Eligible_To_Estimate_Consumable_Spend__c,
            LastModifiedBy.Email,
            Parent.ERP_Customer_Id__c,
            Owner.Name,
            Preferred_Language__c, 
            Field_Comments__c, 
            Territory_Name__c
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    private static List<OpportunityContactRole> selectRoles(Set<Id> opportunityIds) {
        return [
            SELECT 
            id,
            isPrimary,
            Role,
            contactId,
            OpportunityId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ];
    }

    private static List<OpportunityLineItem> selectOpportunityLineItems(Set<Id> opportunityIds) {
        return [SELECT
                OpportunityId,
                Product2Id,
                Product2.Name,
                Product2.ProductCode,
                Product2.Apttus_Config2__ConfigurationType__c,
                Product2.Material_Class_Type__c,
                Product2.IsActive,
                Product2.Service_Product_Type__c,
                Product2.Auto_Create_Installation_Workflow__c, //Added as part of CMCM-1662 
                OptionId__c,
                UnitPrice,
                Quantity,
                ProductCode,
                TotalPrice,
                Shipping_In_Close_Quarter__c,
                Shipping_In_1Q_After_Close_Quarter__c,
                Shipping_In_2Q_After_Close_Quarter__c,
                Quote_Line_Item__c,
                End_Date__c,
                Start_Date__c,
                PricebookEntryId,
                Has_Informatics_Product__c,
                ERP_Line_Number_Id__c,
                Serial_Number__c,
                Quote_Line_Item__r.Existing_Subscription__r.ERP_Line_Number_Id__c,
                Product2.Material_Class__c, // Added as part of DCP-40052
                Work_Detail_Line__c, // Added as part of DCP-38809
                List_Price__c, // Added as part of DCP-47880
                Customer_Specific_Price__c,// Added as part of DCP-47880
                Product2.Product_Level_Indicator__c,//Added as part of DCP-45399
                Quote_Line_Item__r.Registrant_Contact__c//DCP-56258     
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ];
    }
}
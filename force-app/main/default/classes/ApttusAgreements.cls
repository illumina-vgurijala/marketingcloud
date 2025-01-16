/**
*    @author Saswati Prusty
*    @date   05 Dec 2019
*    @description    Class to handle Agreement Trigger.
*    Test Class 90% Coverage : TestApttusAgreements
*    @Test Class for atleast 75% coverage.
      -TestAPTS_ImportFullySignedDocument
      -TestAddMaterialGroupController
      -TestAgrLinesFindDuplicatesController
      -TestOpenOfferAgreements
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                         Date                     Description
*    Saswati Prusty                    05 Dec 2019              Initial Version - DCP-31654 : Update Price Group on Insertion and Update.
*    B Kamini                          13 Jan 2020              Updated onbeforeUpdate - DCP-31209: validatedate()
*    Adhithyan                         23 Jan 2020              Added populateCompanyCodeAddress for DCP- 33550
*    Umesh                             11-2-2020                DCP-32575: Added validateAgreementSalesOrg(List<Apttus__APTS_Agreement__c> lstAgreements) method
*    B Kamini                          20 Feb 2020              DCP-34092: Removed validatedate method
*    Joshith K                         04 Mar 2020              DCP-34982 : default sales org and Currency on Agreement creation.
*    Todd                              04 Mar 2020              DCP-34086: add restrictEditsOnActiveAgreements()
*    Vishnu Kurra                      18 March 2020            DCP-33720: To populate AgreementLineItemrquired/Optional field
*    B Kamini                          07 May 2020              DCP-37876: To populate Account region field
*    Roopal Verma                      12 May 2020              DCP-37652: To populate Submitted By and Approval Request Present from Approval requests.
*    Roopal Verma                      16 Jun 2020              DCP-37705 Channel Partner One Time Approval
*    Joshith K                         10-June-2020             TASK0493822- update approval Line items  if Agreement is Approved or Rejected.
*    Aditi Joshi                       12-Aug-2020              DCP-39893- Added field 'Renewl Decision' to filter logic for bypassing this field from validation.
*    Rahul Bishnoi                     31-August-2020           INC0284388- Added Account_Owner_Email__c to the allowedToEdit Set.
*    Tapas Chakraborty                 28-Oct-2020              INC0293002 - Reset status,status category, validation status of cloned agreements
*    Rishab Wali                       23-Nov-2020              DCP-43224 - Update Agreement Account Relationship record if Account is Updated
*    Roopal Verma                      03-Dec-2020              DCP-43226 - Moved fields that are editable on active agreements to metadata
*    Joshith K                         26-Nov-2020              TASK0537090- batch call on Agreement Activate--updateLineItemStatusForActivate.
*    Rishab Wali                       23-Nov-2020              DCP-43224 - Update Agreement Account Relationship record if Account is Updated
*    Rishab Wali                       22-Feb-2021              DCP-37232 - Default Preferred Language on Agreements
*    Rahul Bishnoi                     12-May-2021              INC0320773 - Added a new field parent agreement number.
*    Anand Kumar Palla                 14-Jun-2021              DCP-43594 - Removed Send for TAM Review functionality
*    Bharath Varma                     21-Jun-2021              DCP-46102 - Added Non-Compliance checks for Tender Agreements
*    Prem Ranjan                       22-Jun-2021              DCP-46535 - Ability to submit the agreement for an approval for Indirect channel
*    Bharath Varma                     29-Jun-2021              DCP-47006 - Added method to calculate number of line items with UC Discounts 
*    Prem Ranjan                       24-Aug-2021              DCP-49596 - Ability to trigger PPM Approvals along with Discount Approvals
*    Anand Palla                       08-Sept-2021             DCP-48672 - Added method to find Country Category for Europe template // POL-54 
*    Juned                             15-Sep-2021              DCP-48211 - Method to update Cycle time report stage. This field is also updated in the flow - Agreement: Update Cycle Time Report Stage Field
*    Nishan Shetty                     12-Nov-2021              DCP-50448 - Upsert Channel Partner Quota Records related to Distributor Account of Channel Partner Agreement.
*    Anand Palla                       02-Dec-2021              DCP-51143 - Method to populate 'Not Submitted' as default value for Approval Status.   
*    Bharath Varma                     10-Feb-2022              INC0375108 - Added a filter on Agreements inside setAppReqPresent to check if Approval Status is updated
*    Bharath Varma                     12-May-2022              TASK0747373 - Method to make Start date as Today if it is in the past
*    Anshaj Sinha                      14-June-2022             CMSI-68 - Instrumented the class for ilib_LogEvent Framework
*    Avina                             07-July-2022             CMSI-51 - Added getWorkstream method to return the workstream
*    Saddam                            18-Jul-2022              DCP-54435 - Created new method for OO Recordtype setOpenOfferEndDate(), and modified setCreatedDateAndStartDate() and called new inside this.
*    Rucha Dalvi                       14-Jul-2022              DCP-54438 - Customer Interest:Auto Association of Affiliates Accounts to Open Offer Agreement
*    Saddam                            10-Aug-2022              DCP-55553 - Created New method createUGOutputRecord() , and modifed createAccountJunctionRecord() to use the same for loop to get the MapOfAgreeidstoerp.
*    Saddam                            25-Aug-2022              DCP-54810-Created new Method updateOpenOfferAgreementStatus() to update OO Status and calling the method inside the checkIfPreferredLanguageIsUpdated().
*    Nishan Shetty                     24-Aug-2022              DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    Vivek R                           13-Sep-2022              DCP-54499 - Added logic to populate Account Owner field for Open Offer agreements
*    Rucha Dalvi                       15-Sept-2022             DCP-56502 - Defaulting values in resetStatusOfClonedAgreements for Open Offer Agreement
*    Parthasarathy D                   27-Sept-2022             DCP-56507 - Updated the method "updateOpenOfferAgreementStatus" to update the open offer status to Terminated. 
*    Jitesh                            14-Sept-2022             DCP-56503
*    Amogh                             23-Nov-2023              CMCM-2709 - Updated the method "checkComplianceConditions" to update the additional criteria for Non-Compliance.
*    Pradeep Landge                    18-Jul-2024              CMCM-7846 - Add requiresFreightApproval method
*    Gerardo Garcia                    08-Aug-2024              CMCM-9576 - Move PB into code. Set Clinical_Type__c with Account's, during beforeInsert.
*    Vijay Masne                       23-Oct-2024              TI-10949  - TI- Agreement: Status & Status Category as Request.
*    Vijay Masne                       04-Nov-2024              TI-11007  - TI- APTS Set status category and status after the generation of document
*    Vijay Masne                       11-Nov-2024              TI-10601  - TI- Agreement : Update Other Party Signed Date when fully signed
*    Rajbabu Boopalan                  17-Dec-2024              CMCM-12243 - [CLM] [Channel Partner] Automation of VAD Designation
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ApttusAgreements extends ilib_SObjectDomain {

    public static final String STATUS_CATEGORY_IN_EFFECT = 'In Effect';
    public static final String STATUS_CATEGORY_IN_EFFECT_WON = 'In Effect/Won';//CMCM-2709
    public static final String STATUS_CATEGORY_TERMINATED = 'Terminated';
    public static final String STATUS_CATEGORY_AMENDED = 'Amended';
    public static final String STATUS_CATEGORY_RENEWED = 'Renewed';
    public static final String STATUS_CATEGORY_REAGENT_RENTAL = 'Reagent Rental';
    public static final String AGREEMENT_SUBTYPE_ONE_TIME = 'One Time';
    public static final String AGREEMENT_SUBTYPE_ONE_TIME_SALE_AND_TERMED =  'One Time Sale & Termed';//CMCM-2709
    public static final String AGREEMENT_SUBTYPE_TERMED =  'Termed';//CMCM-2709
    public static final String APPROVAL_STATUS_CANCELLED = 'Cancelled';
    public static final String STRING_STATUS_CANCELLED = 'Cancelled';
    public static final String APPROVAL_STATUS_REJECTED = 'Rejected';
    public static final String APPROVAL_STATUS_PENDING = 'Pending Approval';
    public static final string APPROVAL_STATUS_NOT_SUBMITTED = 'Not Submitted';
    public static final string APPROVAL_STATUS_APPROVAL_REQ = 'Approval Required';
    public static final Set<String> STATUSES_NOT_IN_APPROVAL = new Set<String> { APPROVAL_STATUS_NOT_SUBMITTED, APPROVAL_STATUS_APPROVAL_REQ };
    public static final Set<String> SET_OF_SUBTYPE = new Set<String> { AGREEMENT_SUBTYPE_TERMED, AGREEMENT_SUBTYPE_ONE_TIME_SALE_AND_TERMED };//CMCM-2709
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_APPROVAL_REQUIRED = 'Approval Required';
    public static final Set<String> ZERO_PRECISION_CURRENCIES = new Set<String> {'JPY', 'KRW'};
    private static final Integer MASTER_SERVICE_APPROVAL_MIN_TERM = 24;
    private static final Integer MASTER_SERVICE_APPROVAL_MAX_TERM = 36;
    private static final Integer PARTNER_APPROVAL_MIN_TERM = 12;
    private static final Integer PARTNER_APPROVAL_MIN_NOTIFICATION_PERIOD = 30;
    public static Boolean hasRunTaps = false;
    private static Map<Id, RecordTypeInfo> rtMap;
    public static final String STR_ACCOUNT_API_NAME = 'Apttus__Account__c'; //DCP-37232 
    public static final String INDIRECT = 'Indirect';//DCP-46535
    public static final String CHINA = 'China';//DCP-46535
    public static final String STANDING_QUOTE = 'Standing_Quote';//DCP-49596
    public static final String SPECIAL_PROGRAMS = 'Special_Programs';//CMCM-7846
    public static final String OPEN_OFFER = 'Open_Offer_Agreement';//CMCM-7846
    public static final String STANDARD = 'Standard';//CMCM-7846
    private static final String OUTPUT_GENERATED = 'Output Generated'; //DCP-48211
    public static boolean stopRecursiveCallToChannelPartnerQuotaMethod =false;//DCP-50448
    private static final String LOG_TITLE = 'ApttusAgreements.'; //INC0375108
    public static final String STRING_OPEN_OFFER_AGREEMENT_END_DATE = 'Open_Offer_End_Date';//Dcp-54435    
    public static final Set<String> ACCOUNT_STATUS_VALUES = new Set<String> {'Active', 'Pending Obsolete','Pending Validation','Pending Upgrade','Active Prospect','Prospect Validation','Unverified',STRING_STATUS_CANCELLED};
    private static final String STRRETURN = 'Return : ';
    private static final String ACCOUNT_CHANNEL_PARTNER_TYPE_VAD = 'Value Added Distributor';

    /*Approval Category Picklist Value Enums*/ 
    public enum ApprovalCategory {CHANNEL_PARTNER_TERM_SHEET_APPROVAL, MASTER_SERVICE_TERM_SHEET_APPROVAL, CHANNEL_PARTNER_ONE_TIME_APPROVAL, POST_PRICING_MESSAGE,FREIGHT_APPROVAL} //DCP-32563,DCP-37705 Channel Partner One Time Approval,DCP-49596

    /*
    * Super class
    */
    public ApttusAgreements(List<Apttus__APTS_Agreement__c> sObjectList)
    {
        super(sObjectList); 
    }
    
    /**
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Constructor for base class
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusAgreements(sObjectList);
        }
    }

    /*
    * Method to get Map of Agreement Id to RecordType
    */
    public static Map<Id, RecordTypeInfo> getRecordTypeMap()
    {
        ilib_LogEvent.push(LOG_TITLE+'getRecordTypeMap()');
        if (rtMap == null) { rtMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById(); }
        ilib_LogEvent.info('Map of Agreement Id to Record Type : '+rtMap);
        ilib_LogEvent.pop();
        return rtMap;
    }

    /*
    * Author : Saswati
    * User Story : DCP - 31654
    * Functionality : To update Price Group from Account Sales Area on insert.
    */
    public override void onBeforeInsert()
    {
        List<Apttus__APTS_Agreement__c> lstAgreements = (List<Apttus__APTS_Agreement__c>)records;
        ilib_LogEvent.message('@@@ Agreement record - ' + lstAgreements);

        resetStatusOfClonedAgreements(lstAgreements);
        //Regression issue fix - time zone
        //TASK0747373 - Updated method name from setCreatedDate to setCreatedDateAndStartDate, and added logic in the same method
        //DCP-54435 Updated method to call the setOpenOfferEndDate() inside to avoid new for loop.
        setCreatedDateAndStartDate(lstAgreements);
        setAccountRegion(lstAgreements);
        setApprovalCategory(lstAgreements);

        //Added for DCP-34982
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAgreements, STR_ACCOUNT_API_NAME);
        ilib_LogEvent.info('setAccountIds: '+ setAccountIds);
        List<Account> relAccounts = new AccountsSelector().selectAccounts(setAccountIds);
        Map<Id, Account> mapAccounts = new Map<Id, Account>(relAccounts);
        setDefaultSalesOrgAndCurrency(relAccounts, lstAgreements);//adding reference sales org

        //Added for DCP-33708
        setPriceGroupAndPGDescription(lstAgreements);//adding reference sales org

        //Added for DCP - 33550
        populateCompanyCodeAddress(lstAgreements);//adding reference sales org

        //DCP-33720
        populateAgreementLineItem(lstAgreements);

        //DCP-32575
        validateAgreementSalesOrg(lstAgreements);//adding reference sales org
        
        //DCP-37232
        PreferredLanguageService.setPreferredLanguage(lstAgreements); //Set Default Preferred Language

        //DCP-46102
        checkForTenderCompliance(lstAgreements);

        //DCP-51143
        populateDefaultApprovalStatus(lstAgreements);

        populateDefaultClinicalType(lstAgreements, mapAccounts);

        //TI-10949
        updateAgreementStatus(lstAgreements, (Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);

        //TI-11007
        updateAgreementCategoryStatus(lstAgreements, (Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);

        //TI-10601
        updateOtherPartySignedDate(lstAgreements, (Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);

        //CMCM-12243
        updateVADDesignation(lstAgreements, mapAccounts);
    }

    /*
    * Method to populate created date on agreement
    * date : 21-jul -2022 ,
    * Modified the method and calling the setOpenOfferEndDate() inside the loop to avoid extra for loop in new method.
    */
    public void setCreatedDateAndStartDate(List<Apttus__APTS_Agreement__c> lstAgreements) {  

        ilib_LogEvent.push(LOG_TITLE+'setCreatedDate()');
        // START DCP-54435
        Code_Parameter__mdt  objEndDateCodeParam =  Code_Parameter__mdt.getInstance(STRING_OPEN_OFFER_AGREEMENT_END_DATE);
        string strOpenOfferEndDateParam = objEndDateCodeParam.Value__c;
        //End date code parameter metadata
        //spliting the date value from mdt. 
        List<string> stringList = strOpenOfferEndDateParam.split('/');

        integer intMonth = integer.valueof(stringList[0]);
        integer intDay   = integer.valueof(stringList[1]);
        integer intYear  = integer.valueof(stringList[2]);

        Date dtEndDateValue = date.newinstance(intYear,intMonth,intDay);

        for(Apttus__APTS_Agreement__c oAgreement:lstAgreements) {   
            //calling method to set Open Offer Enddate.
            setOpenOfferEndDate(oAgreement,dtEndDateValue);
            //end DCP-54435
            //oAgreement.Created_Date__c = Date.Today();
            //TASK0747373
            //oAgreement.Apttus__Contract_Start_Date__c =  oAgreement.Apttus__Contract_Start_Date__c < Date.Today() ? Date.Today() : oAgreement.Apttus__Contract_Start_Date__c;
           // ilib_LogEvent.message('oAgreement.Created_Date__c : '+oAgreement.Created_Date__c);
        }
       // ilib_LogEvent.pop();
    }

    /*
    *  @author       : Saddam 
    *  @description  : DCP-54435 - Method to set default End date for Open offer agreement 
    *  @param        : Agreement Record,Date from setCreatedDateAndStartDate() 
    *  @return       : none
    */
    public void setOpenOfferEndDate(Apttus__APTS_Agreement__c agrRecord,Date dtOpenOfferEndDate ) {

        ilib_LogEvent.push(LOG_TITLE+'setOpenOfferEndDate()');
        ilib_LogEvent.info('Agreement received from method '+agrRecord);
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        String strRecordTypeName = idToRecordTypeInfo.get(agrRecord.RecordTypeId).getDeveloperName();
        if(strRecordTypeName == System.label.AgreementRecordTypeOpenOffer) {    
            agrRecord.Apttus__Contract_End_Date__c = dtOpenOfferEndDate;
            ilib_LogEvent.info('Apttus__Contract_End_Date__c : '+agrRecord.Apttus__Contract_End_Date__c);
        }
        ilib_LogEvent.pop();
    }

    /*
    * After Insert Trigger
    */
    public override void onAfterInsert()
    {
        // create an association (junction) record for each agreement to its account lookup
        createAccountJunctionRecord();
    }
    
    /*
    * Method to create Account Junction Record
    */
    private void createAccountJunctionRecord()
    {  
        ilib_LogEvent.push(LOG_TITLE+'createAccountJunctionRecord()');
        // filter out agreements that don't have account values
        List<Apttus__APTS_Agreement__c> agreementsWithAccounts = new List<Apttus__APTS_Agreement__c>();

        //Open Offer Agreement that have account values
        List<Apttus__APTS_Agreement__c> lstOOAgreementsWithAccounts = new List<Apttus__APTS_Agreement__c>();
        Map<Id, RecordTypeInfo> mapIdToRecordTypeInfo = getRecordTypeMap();
        Map<String,Set<Id>> mapNGNToAccountId = new Map<String,Set<Id>>();
        Map<id,string> mapOfAgrmntIdToErp = new Map<id,string>(); //DCP-55553

        for(Apttus__APTS_Agreement__c agreement : (List<Apttus__APTS_Agreement__c>)records) {
            if (agreement.Apttus__Account__c != null) { 
                //DCP-54438 - Get OO Agreements with account
                String strRecordTypeName = mapIdToRecordTypeInfo.get(agreement.RecordTypeId).getDeveloperName();
                if(strRecordTypeName == System.label.AgreementRecordTypeOpenOffer) {
                    mapOfAgrmntIdToErp.put(agreement.Id,agreement.Account_ERP_Number__c); //DCP-55553
                    lstOOAgreementsWithAccounts.add(agreement);
                    if(agreement.Account_National_Group_Number__c!=null) {
                        if(! mapNGNToAccountId.containsKey(agreement.Account_National_Group_Number__c)) {
                            mapNGNToAccountId.put(agreement.Account_National_Group_Number__c,new Set<Id>());
                        }
                            mapNGNToAccountId.get(agreement.Account_National_Group_Number__c).add(agreement.Apttus__Account__c);
                     } else {
                        //DCP-58532 Defect Fix
                        agreementsWithAccounts.add(agreement);
                     }
                } else {
                    agreementsWithAccounts.add(agreement);
                }
            }
        }

        //Start - DCP-54438
        if(!agreementsWithAccounts.isEmpty()) {
            createAccountJunctionRecord(agreementsWithAccounts);
        }
        
        if(!mapNGNToAccountId.isEmpty() && !lstOOAgreementsWithAccounts.isEmpty()) {
            ilib_LogEvent.message('mapNGNToAccountId: '+mapNGNToAccountId);
            ilib_LogEvent.message('lstOOAgreementsWithAccounts: '+lstOOAgreementsWithAccounts);
            getAffiliatesForOOAgreement(mapNGNToAccountId,lstOOAgreementsWithAccounts);
        }
        
        //DCP-55553
        if(!mapOfAgrmntIdToErp.isEmpty() && !lstOOAgreementsWithAccounts.isEmpty() ) {
            createUGOutputRecord(mapOfAgrmntIdToErp,new Map<Id,Apttus__APTS_Agreement__c>(lstOOAgreementsWithAccounts));
        }
        
        ilib_LogEvent.pop();
    }

    // NOTE: public so that we can use this to seed data
    /*
    * Method to create Account Junction Record
    */
    public void createAccountJunctionRecord(List<Apttus__APTS_Agreement__c> agreementsWithAccounts)
    {
        ilib_LogEvent.push(LOG_TITLE+'createAccountJunctionRecord()');
        // create an association (junction) record for each agreement to its account lookup
        List<Agreement_Account_Relationship__c> newJunctionRows = new List<Agreement_Account_Relationship__c>();
        Map<Id, RecordTypeInfo> mapIdToRecordTypeInfo = getRecordTypeMap();
        for (Apttus__APTS_Agreement__c agreement : agreementsWithAccounts)
        {
            //DCP-58532 Defect Fix Start
            String strRecordTypeName = mapIdToRecordTypeInfo.get(agreement.RecordTypeId).getDeveloperName();    
            Boolean boolCheckForOOCondition = strRecordTypeName == System.label.AgreementRecordTypeOpenOffer && LABEL.Apttus_Status_In_Amendment.equals(agreement.Apttus__Status__c);
            if(boolCheckForOOCondition){continue;}
            //End
            newJunctionRows.add(
                new Agreement_Account_Relationship__c(Agreement__c = agreement.Id, Account__c = agreement.Apttus__Account__c)
            );
        }
        insert newJunctionRows;
        ilib_LogEvent.pop();    
    }
    
    /*
    *  @author       : Rucha Dalvi
    *  @description  : DCP-54438 - Method to associate affiliates with Open Offer Agreements
    *  @param        : Map of Open Offer Agreements with Rekated Account and Map of Primary Account on Agreement
    *  @return       : none
    */
    public static void getAffiliatesForOOAgreement(Map<String,Set<Id>> mapNGNToAccountId, List<Apttus__APTS_Agreement__c> lstOOAgreementsWithAccounts) {

        ilib_LogEvent.push(LOG_TITLE + '.getAffiliatesForOOAgreement()');
        Map<Id,Set<Id>> mapOpenOfferAgreementToRelatedAccountId = new Map<Id,Set<Id>>();
        Map<Id,String> mapIdToNGN = new Map<Id,String>();
        Map<id, Set<String>> mapAccountWithSalesOrg = new  Map<id, Set<String>>();
        Map<id, Set<String>> mapAccountWithDistributionChnl = new Map<id, Set<String>>();

        List<Account_Sales_Area__c> lstOfAccountSalesArea = new AccountSalesAreaSelector().getAcntSalesAreaByAccountNGN(mapNGNToAccountId.keySet(),ACCOUNT_STATUS_VALUES);
        if(!lstOfAccountSalesArea.isEmpty() && lstOfAccountSalesArea!=null){
            for(Account_Sales_Area__c acntSalesArea : lstOfAccountSalesArea ){
                if(String.isBlank(acntSalesArea.Account__r.National_Group_Number__c)){
                    continue;
                }
                if(mapNGNToAccountId.containsKey(acntSalesArea.Account__r.National_Group_Number__c)) {
                    mapNGNToAccountId.get(acntSalesArea.Account__r.National_Group_Number__c).add(acntSalesArea.Account__c);
                }
                mapIdToNGN.put(acntSalesArea.Account__c,acntSalesArea.Account__r.National_Group_Number__c);
                if(!mapAccountWithSalesOrg.containskey(acntSalesArea.Account__c)){
                    mapAccountWithSalesOrg.put(acntSalesArea.Account__c,new Set<String>());
                }
                mapAccountWithSalesOrg.get(acntSalesArea.Account__c).add(acntSalesArea.Sales_Organization__c);
                if(!mapAccountWithDistributionChnl.containskey(acntSalesArea.Account__c)){
                    mapAccountWithDistributionChnl.put(acntSalesArea.Account__c,new Set<String>());
                }
                mapAccountWithDistributionChnl.get(acntSalesArea.Account__c).add(acntSalesArea.Distribution_Channel__c);
            }
        }      

        for(Apttus__APTS_Agreement__c objAgreement:lstOOAgreementsWithAccounts) {
            String strNGN = mapIdToNGN.get(objAgreement.Apttus__Account__c);
            Set<Id> setAccountIdToAdd = mapNGNToAccountId.get(strNGN);
            mapOpenOfferAgreementToRelatedAccountId.put(objAgreement.Id,setAccountIdToAdd);
        }
        
        if(!mapOpenOfferAgreementToRelatedAccountId.isEmpty()) {
            createOOAgreementAccountRelationshipRecords(mapOpenOfferAgreementToRelatedAccountId, lstOOAgreementsWithAccounts,mapAccountWithSalesOrg,mapAccountWithDistributionChnl);
        }
        ilib_LogEvent.pop();
    }
    
    /*
    *  @author       : Rucha Dalvi
    *  @description  : DCP-54438 - Method to create Agreement Accnt Relati]onship Record for Open Offer Agreements
    *  @param        : Map of Open Offer Agreements with Account Id
    *  @return       : none
    */
    public static void createOOAgreementAccountRelationshipRecords(Map<Id,Set<Id>> mapOpenOfferAgreementToRelatedAccountId, List<Apttus__APTS_Agreement__c> lstOOAgreementsWithAccounts,Map<id, Set<String>> mapAccountWithSalesOrg ,Map<id, Set<String>> mapAccountWithDistributionChnl) {
        ilib_LogEvent.push(LOG_TITLE + '.createOOAgreementAccountRelationshipRecords()');
        ilib_LogEvent.message('mapOpenOfferAgreementToRelatedAccountId size: '+mapOpenOfferAgreementToRelatedAccountId.size());
        ilib_LogEvent.message('lstOOAgreementsWithAccounts : '+lstOOAgreementsWithAccounts);
        // create an association (junction) record for each agreement to its account lookup
        List<Agreement_Account_Relationship__c> lstOOAgreementAccountRecord = new List<Agreement_Account_Relationship__c>();
        for(Apttus__APTS_Agreement__c objAgreement : lstOOAgreementsWithAccounts) {
            if(!mapOpenOfferAgreementToRelatedAccountId.containsKey(objAgreement.Id)){continue;}
            //start of DCP-56503 changes
            if(LABEL.Apttus_Status_In_Amendment.equals(objAgreement.Apttus__Status__c)){continue;}
            //End of DCP-56503 changes
            for(Id accountId : mapOpenOfferAgreementToRelatedAccountId.get(objAgreement.Id)) {
                //To check if Sales Org of Account to be associated is same as Agreement Header
                Boolean boolKeyFound = mapAccountWithSalesOrg.containsKey(accountId) && mapAccountWithDistributionChnl.containsKey(accountId);
                if(!boolKeyFound) {continue;}
                if (mapAccountWithSalesOrg.get(accountId).contains(objAgreement.Sales_Org__c) && mapAccountWithDistributionChnl.get(accountId).contains(objAgreement.Distribution_Channel__c) ) {
                    ilib_LogEvent.info('accountId : '+accountId);
                    lstOOAgreementAccountRecord.add(
                        new Agreement_Account_Relationship__c(Agreement__c = objAgreement.Id, Account__c = accountId)
                    );
                }
            } 
        }

        List<Database.SaveResult> lstSaveErrors = Database.insert(lstOOAgreementAccountRecord,false);
        if(!lstSaveErrors.isEmpty()) { 
            ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
        }
        ilib_LogEvent.pop();
    }

    /*
    *  @author       : Saddam 
    *  @description  : DCP-55553 - Method to create UGOutput records using AccountpricingTierservice Class. 
    *  @param        : Map Of Agreement Ids to Account ERP number.
    *  @return       : none
    */
    public void createUGOutputRecord(Map<id,string> mapOfAgrmntIdToErp,Map<Id,Apttus__APTS_Agreement__c> mapIdToAgreementRecord) {

        ilib_LogEvent.push(LOG_TITLE+'createUGOutputRecord()');
        ilib_LogEvent.info('mapOfAgrmntIdToErp-->: '+mapOfAgrmntIdToErp);
        Map<string,list<Pricing_Discount_Tier__c>> mapOfErpToLstOfPDT = new Map<string,list<Pricing_Discount_Tier__c>>();
        if(!mapOfAgrmntIdToErp.isempty()) {
            List<AccountPricingTiersService.OpenOfferPricingDiscount> listOpenOfferPricingDiscount = new AccountPricingTiersService().getOpenOfferByCustomerForCLM(new Set<String>(mapOfAgrmntIdToErp.values()));   
            ilib_LogEvent.info('listOpenOfferPricingDiscount-->: '+listOpenOfferPricingDiscount);  
            for(AccountPricingTiersService.OpenOfferPricingDiscount objOOPdt : listOpenOfferPricingDiscount) {
                if(!mapOfErpToLstOfPDT.containsKey(objOOPdt.erpCustomerId)) {
                    mapOfErpToLstOfPDT.put(objOOPdt.erpCustomerId,objOOPdt.listOfPRicingDiscountTier);
                } 
            }
        }   
        ilib_LogEvent.info('mapOfErpToLstOfPDT-->: '+mapOfErpToLstOfPDT);
   
        List<Universal_Grid_Output__c> lstOfUGOutputToInsert = new List<Universal_Grid_Output__c>();
        if(!mapOfAgrmntIdToErp.isEmpty()){
            for(ID agreementId : mapOfAgrmntIdToErp.keySet()) {
                string strErpId = mapOfAgrmntIdToErp.get(agreementId);
                if(mapOfErpToLstOfPDT.containsKey(strErpId) && !mapOfErpToLstOfPDT.isEmpty()) {
                    for(Pricing_Discount_Tier__c objPdtRecords: mapOfErpToLstOfPDT.get(strErpId)) {
                        Apttus__APTS_Agreement__c objAgreement = mapIdToAgreementRecord.get(agreementId);
                        Date dtAgrStartDate = objAgreement.Apttus__Contract_Start_Date__c;  
                        if(objPdtRecords.Valid_From__c <= dtAgrStartDate && objPdtRecords.Valid_To__c >= dtAgrStartDate) {
                            Universal_Grid_Output__c objUgOutput = new Universal_Grid_Output__c();
                                objUgOutput.Pricing_Discount_Tier__c=objPdtRecords.Id ;
                                objUgOutput.Agreement__c= agreementId;
                                lstOfUGOutputToInsert.add(objUgOutput);
                        }
                    }
                }
            }
        }
        ilib_LogEvent.info('lstOfUGOutputToInsert-->: '+lstOfUGOutputToInsert);

        List<Database.SaveResult> lstSaveErrors = Database.insert(lstOfUGOutputToInsert,false);
        if(!lstSaveErrors.isEmpty()) { 
            ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
        }  

        ilib_LogEvent.pop();

    }
    
    /*
    * Method to restrict edit on Active Agreements
    */
    private void restrictEditsOnActiveAgreements(Map<Id, SObject> idToOldAgreement)
    {
        ilib_LogEvent.push(LOG_TITLE+'restrictEditsOnActiveAgreements()');
        // bypass if this is an insert rather than an update operation
        if (isInsertOperationForObject()){ilib_LogEvent.pop(); 
        return;}
            

        // bypass admins and integration profiles
        Boolean isBypassProfile = Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId()) || Profiles.getAllAdminProfileIds().contains(UserInfo.getProfileId());

        ilib_LogEvent.info('isBypassProfile : '+isBypassProfile);
        

        if (isBypassProfile) {ilib_LogEvent.pop(); 
        return;}            

        // filter on not updated by system (backdoor)
        Map<String, Set<Object>> userUpdatedValues = new Map<String, Set<Object>> {'Is_Updated_By_System__c' => new Set<Object> {false}};
        List<Apttus__APTS_Agreement__c> userUpdated = UtilsCollection.filterForValues(records, idToOldAgreement, userUpdatedValues);
        if (userUpdated.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        // ignore not active agreements
        Map<String, Set<Object>> activeAgreementsValues = new Map<String, Set<Object>> {
            'Apttus__Status_Category__c' => new Set<Object> {STATUS_CATEGORY_IN_EFFECT, STATUS_CATEGORY_TERMINATED, STATUS_CATEGORY_AMENDED, STATUS_CATEGORY_RENEWED}
        };
        List<Apttus__APTS_Agreement__c> activeAgreements = UtilsCollection.filterForUnchangedValues(userUpdated, idToOldAgreement, activeAgreementsValues);

        if (activeAgreements.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        // filter for anything edited except these fields. Added fields to the metadata DCP-43226
        String strEditableFields ='';
        Set<String> setCodeParamName =new Set<String>{'Fields_Editable_On_Active_Agreements'}; 
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
        if(!lstCodeParam.isEmpty()) { 
            strEditableFields =lstCodeParam[0].value__c;
            ilib_LogEvent.info('strEditableFields : '+strEditableFields);
        }
        Set<String> setAllowedToEdit = new Set<String>(strEditableFields.split(','));
        
        List<Apttus__APTS_Agreement__c> editedAgreements = UtilsCollection.filterOnModified(activeAgreements, idToOldAgreement, setAllowedToEdit);

        // whatever is left violates the don't edit active agreements rule
        for (Apttus__APTS_Agreement__c agreement : editedAgreements) { agreement.addError(Label.UI_AgreementRestrictOnActive); }
        ilib_LogEvent.pop();
    }

   /*
    * Author : Saswati
    * User Story : DCP - 31654
    * Functionality : To update Price Group from Account Sales Area on update.
    */
    public override void onBeforeUpdate(Map<Id, SObject> idToAgreements)
    {
        checkIfPreferredLanguageIsUpdated(trigger.newmap,trigger.oldmap); //DCP-37232 Default Preferred Language
        // anything below this only runs for non-integration profiles
        if (Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) {ilib_LogEvent.pop(); 
        return;}

        List<Apttus__APTS_Agreement__c> lstAgreements = (List<Apttus__APTS_Agreement__c>)records;

        restrictEditsOnActiveAgreements(idToAgreements);

        // anything below here only runs on agreements where values actually changed
        List<Apttus__APTS_Agreement__c> lstModifiedAgreements = UtilsCollection.filterOnModified(records, idToAgreements);          
         
        if (lstModifiedAgreements.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        setPriceGroupAndPGDescription(lstModifiedAgreements);//adding reference sales org

        setApprovalCategory(lstModifiedAgreements);

        //Added for DCP - 33550
        populateCompanyCodeAddress(lstModifiedAgreements);//adding reference sales org
              
        //DCP-33720
        populateAgreementLineItem(lstAgreements);

        validateAgreementSalesOrg(lstAgreements);//adding reference sales org

        setAppReqPresent(lstAgreements, idToAgreements);
        
        checkAgreementsWithUCDiscLineItems(lstAgreements); //DCP-47006
        
        // DCP-46102
        checkForTenderCompliance(lstAgreements);
        
        //DCP-48672
        checkCountryCategory(lstAgreements);
        updateCycleTimeReportStage(lstAgreements); //DCP-48211

        //TI-10949
        updateAgreementStatus(lstAgreements,(Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);

        //TI-11007
       updateAgreementCategoryStatus(lstAgreements, (Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);

       //TI-10601
       updateOtherPartySignedDate(lstAgreements, (Map<Id, Apttus__APTS_Agreement__c>)trigger.oldMap);
    }
    
    /**
    *  @author Avina
    *  @description  CMSI-51,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

    /*
    * After update trigger
    */
    public override void onAfterUpdate(Map<Id, SObject> idToAgreements)
    {   
        shareAgreementsThatChangedOwner(idToAgreements);

        updateLineItemStatuses(idToAgreements); 

        updateLineItemStatusForActivate(idToAgreements);

        checkIfAccountIsUpdated(trigger.newmap,trigger.oldmap); //DCP-43224 - Update Agreement Account Relationship record if Account is Updated

        //START DCP-50448 [Upsert Channel Partner Quota Records related to Distributor Account of Channel Partner Agreement]
        upsertChannelPartnerQuotaRecords((List<Apttus__APTS_Agreement__c>)records,idToAgreements);
        //END DCP-50448
    }

    private void shareAgreementsThatChangedOwner(Map<Id, SObject> idToAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'shareAgreementsThatChangedOwner()');
        if (hasRunTaps) {ilib_LogEvent.pop(); 
        return;}

        List<String> fieldsThatTriggerRecalculation = new List<String> {'OwnerId'};
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        Set<Id> idsThatNeedRecalculation = tapsOrchestrator.updateRequiresRecalculation(records, idToAgreements, fieldsThatTriggerRecalculation);//DCP-44091
        ilib_LogEvent.info('idsThatNeedRecalculation : '+idsThatNeedRecalculation);
        if (!idsThatNeedRecalculation.isEmpty())
        {
            tapsOrchestrator.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
            hasRunTaps = true;
        }
        ilib_LogEvent.pop();
    }

    private void updateLineItemStatuses(Map<Id, SObject> idToAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'updateLineItemStatuses()');
        // filter where status changed to either approved or rejected
        List<Apttus__APTS_Agreement__c> lstAgreementsWithChangedStatus = UtilsCollection.filterForChangeToValue(
            records,
            idToAgreements,
            new Map<String, Set<Object>> {'Apttus_Approval__Approval_Status__c' => new Set<Object> {APPROVAL_STATUS_APPROVED, APPROVAL_STATUS_REJECTED}}
        );
        if (lstAgreementsWithChangedStatus.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        // update child line item status to match
        // start a new transaction context (via platform event)
        // so the line items can be updated in a batch class
        Map<Id, String> idToAgreementStatus = UtilsCollection.getMapOfIdToString(lstAgreementsWithChangedStatus, 'Id', 'Apttus_Approval__Approval_Status__c');
        ilib_LogEvent.info('idToAgreementStatus : '+idToAgreementStatus);
        AgreementLineStatusUpdates.publish(idToAgreementStatus);
        ilib_LogEvent.pop();
    }

    /*
     * Author : Adhithyan
     * User Story : DCP - 33550
     * Functionality : Company Name and Address to be autopopulated on requested fields using the company code in Sales org field from metadata
     * Method Called from: onbeforeUpdate, onBeforeInsert
     * Parameter passed: List<Apttus__APTS_Agreement__c> List of Agreement from Trigger Context
     */
     //adding reference sales org
    private void populateCompanyCodeAddress(List<Apttus__APTS_Agreement__c> lstAgreement)
    {
        ilib_LogEvent.push(LOG_TITLE+'populateCompanyCodeAddress()');
        if (lstAgreement.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        Set<String> setCompanyCode = UtilsCollection.getSetOfStrings(lstAgreement, 'Sales_Org__c');
        ilib_LogEvent.info('setCompanyCode : '+setCompanyCode);

        Map<String, Company_Code_Address__mdt> mapCmpnyCde2CmpnyCdeAdd = new Map<String, Company_Code_Address__mdt>();

        if (!setCompanyCode.isEmpty()) {
            for (Company_Code_Address__mdt ccAdd : new CompanyCodeAddressesSelector().selectCompanyCodeAddress(setCompanyCode)) {
                 mapCmpnyCde2CmpnyCdeAdd.put(ccAdd.Company_Code__c, ccAdd);
            }
            ilib_LogEvent.message('mapCmpnyCde2CmpnyCdeAdd : '+mapCmpnyCde2CmpnyCdeAdd);
        }

        for (Apttus__APTS_Agreement__c oAgreement : lstAgreement)
        {
            String strCompanyAddress = '';
            if (String.isNotBlank(oAgreement.Sales_Org__c) && mapCmpnyCde2CmpnyCdeAdd.containsKey(oAgreement.Sales_Org__c)) {
                oAgreement.Company_Name__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Company_Name__c);
                oAgreement.Address_Line_1__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_1__c);
                oAgreement.Address_Line_2__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_2__c);
                oAgreement.Address_Line_3__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_3__c);
                oAgreement.Address_Line_4__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_4__c);
                oAgreement.Address_Line_5__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_5__c);
                oAgreement.Address_Line_6__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_6__c);
                oAgreement.Footer_Full_Street__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Footer_Full_Street__c);
                oAgreement.Footer_City__c = getSafeString(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Footer_City__c);

                strCompanyAddress = getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_1__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_2__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_3__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_4__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_5__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Address_Line_6__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Footer_Full_Street__c, '\n');
                strCompanyAddress += getSafeStringWithSuffix(mapCmpnyCde2CmpnyCdeAdd.get(oAgreement.Sales_Org__c).Footer_City__c, '\n');

                oAgreement.Company_Code_Address__c = String.isNotBlank(strCompanyAddress) ? strCompanyAddress : '';
            }
            else {
                oAgreement.Company_Code_Address__c = '';
                oAgreement.Company_Name__c = '';
                oAgreement.Address_Line_1__c = '';
                oAgreement.Address_Line_2__c = '';
                oAgreement.Address_Line_3__c = '';
                oAgreement.Address_Line_4__c = '';
                oAgreement.Address_Line_5__c = '';
                oAgreement.Address_Line_6__c = '';
                oAgreement.Footer_Full_Street__c = '';
                oAgreement.Footer_City__c = '';
            }
        }
        ilib_LogEvent.pop();
    }
// reference
    private String getSafeString(String val)
    {
        ilib_LogEvent.message('val : '+val);
        return getSafeStringWithSuffix(val, '');
    }

    private String getSafeStringWithSuffix(String val, String suffix)
    {
        if (String.isBlank(val)) {ilib_LogEvent.pop(); 
        return '';}
        ilib_LogEvent.message('val + suffix : '+val + suffix);
        return val + suffix;
    }

    private Boolean requiresPartnerApproval(Apttus__APTS_Agreement__c objAgreement)
    {
        Boolean bool = objAgreement.Term_in_Months__c > PARTNER_APPROVAL_MIN_TERM
            || objAgreement.Notification_Period_for_Price_Changes__c > PARTNER_APPROVAL_MIN_NOTIFICATION_PERIOD
            || objAgreement.Apttus__Auto_Renewal__c
            || !String.isBlank(objAgreement.Territory__c)
            || objAgreement.Value_Added_Distributor__c
            || objAgreement.Exclusivity__c
            || !String.isBlank(objAgreement.Incoterm__c)
            || !String.isBlank(objAgreement.Competitive_Products__c)
            || hasNonZeroValue(objAgreement.Q1_Quota__c)
                || hasNonZeroValue(objAgreement.Q2_Quota__c)
                || hasNonZeroValue(objAgreement.Q3_Quota__c)
                || hasNonZeroValue(objAgreement.Q4_Quota__c);

        ilib_LogEvent.message(STRRETURN+bool);

        return bool;
    }
    //CMCM-7846 - To check is valid Agreement to update Approval Category as Freight_Charge
    private Boolean requiresFreightApproval(Apttus__APTS_Agreement__c objAgreement, String rtName)
    {
        Apttus__APTS_Agreement__c objOldAgreement = new Apttus__APTS_Agreement__c();
        if(Trigger.oldMap!=null){
            objOldAgreement = (Apttus__APTS_Agreement__c)Trigger.oldMap.get(objAgreement.Id);
        }
        
        Boolean bool = ((rtName == STANDING_QUOTE ||
        rtName == System.Label.AgreementRecordTypeTender || 
        (rtName == SPECIAL_PROGRAMS && objAgreement.Apttus__Subtype__c == STATUS_CATEGORY_REAGENT_RENTAL) ||
        rtName == OPEN_OFFER) && 
        objAgreement.Freight_Charge__c != STANDARD);
        
        ilib_LogEvent.message(STRRETURN+bool);
        return bool;
    }

    private Boolean requiresMasterServiceApproval(Apttus__APTS_Agreement__c objAgreement)
    {
        Boolean bool = objAgreement.Term_in_Months__c > MASTER_SERVICE_APPROVAL_MIN_TERM && objAgreement.Term_in_Months__c < MASTER_SERVICE_APPROVAL_MAX_TERM;
        ilib_LogEvent.message(STRRETURN+bool);
        return bool;
    }

    private Boolean requiresOneTimeApproval(Apttus__APTS_Agreement__c objAgreement)    //DCP-37705 Channel Partner One Time Approval
    {
        Boolean bool = objAgreement.Apttus__Subtype__c == AGREEMENT_SUBTYPE_ONE_TIME && (String.isNotBlank(objAgreement.Ultimate_Consignee__c) || String.isNotBlank(objAgreement.One_Time_Agreement_Products__c));
        ilib_LogEvent.message(STRRETURN+bool);
        return bool;
    }

    //DCP-46535 changes
    private Boolean requiresLineApprovalAndOpen(Apttus__APTS_Agreement__c objAgreement, String rtName)
    {
        Boolean bool = (objAgreement.Number_of_Line_Items_Approvals__c > 0
            && objAgreement.Apttus_Approval__Approval_Status__c != Label.AgreementApprovalStatusApproved
            && objAgreement.Apttus_Approval__Approval_Status__c != APPROVAL_STATUS_CANCELLED
            && objAgreement.Apttus_Approval__Approval_Status__c != APPROVAL_STATUS_REJECTED
            && objAgreement.Apttus_Approval__Approval_Status__c != APPROVAL_STATUS_PENDING
        ) || (rtName == System.Label.AgreementRecordTypeTender && objAgreement.Apttus__Subtype__c == INDIRECT && objAgreement.Region__c == CHINA && (objAgreement.Sub_Distributor__c != null || objAgreement.Estimated_Tender_Value__c != null || objAgreement.Apttus__Account__c != null))
        || ((rtName == System.Label.AgreementRecordTypeTender || rtName == STANDING_QUOTE) && (String.isNotBlank(objAgreement.Post_Pricing_Message__c)));//DCP-49596
        ilib_LogEvent.message(STRRETURN+bool);
        return bool;
    }

    private Boolean requiresLineApprovalAndClosed(Apttus__APTS_Agreement__c objAgreement)
    {
        Boolean bool = objAgreement.Number_of_Line_Items_Approvals__c > 0
            && (objAgreement.Apttus_Approval__Approval_Status__c == Label.AgreementApprovalStatusApproved
                || objAgreement.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_REJECTED
                || objAgreement.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_CANCELLED);
        ilib_LogEvent.message(STRRETURN+bool);
        return bool;
    }

    /*
    * Author : Saswati Prusty
    * User Story : DCP - 32563
    * Functionality : Agreement header approvals
    */
    private void setApprovalCategory(List<Apttus__APTS_Agreement__c> allAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'setApprovalCatgory()');
        // filter agreements that need approval categories
        // on insert all agreements need categories
        // on update, only if certain values have changed/are present
        List<Apttus__APTS_Agreement__c> lstFilteredAgreements = filterAgreementsForApproval(allAgreements);
        if (lstFilteredAgreements.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();

        for (Apttus__APTS_Agreement__c objAgreement : lstFilteredAgreements)
        {
            String strApprovalCategory = '';
            String strApprovalStatus = objAgreement.Apttus_Approval__Approval_Status__c;

            String rTName = null;
            if (objAgreement.RecordTypeId != null) {
                rtName = idToRecordTypeInfo.get(objAgreement.RecordTypeId).getDeveloperName();
            }
            ilib_LogEvent.message('rtName : '+rtName);

            if (rTName == Label.AgreementRecordTypeChannelPartner && requiresOneTimeApproval(objAgreement)) {//DCP-37705 Channel Partner One Time Approval
                ilib_LogEvent.message('***  Inside If condition for Channel Partner approval check ==> 1');

                strApprovalCategory += ApprovalCategory.CHANNEL_PARTNER_ONE_TIME_APPROVAL.name() + ';';
                strApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
            }
            if (rTName == Label.AgreementRecordTypeChannelPartner && requiresPartnerApproval(objAgreement)) {
                ilib_LogEvent.message('***  Inside If condition for Channel Partner approval check');
                strApprovalCategory += ApprovalCategory.CHANNEL_PARTNER_TERM_SHEET_APPROVAL.name() + ';';
                strApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
            }
            else if(requiresFreightApproval(objAgreement, rtName)){//CMCM-7846
                ilib_LogEvent.message('***  Inside If condition for Non-Standard/DNC Freight Approval check');
                strApprovalCategory += ApprovalCategory.FREIGHT_APPROVAL.name() + ';';
                strApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
            }
            else if (rTName == Label.AgreementRecordTypeMasterService && requiresMasterServiceApproval(objAgreement)) {
                strApprovalCategory += ApprovalCategory.MASTER_SERVICE_TERM_SHEET_APPROVAL.name() + ';';
                strApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
            }
            else if (requiresLineApprovalAndOpen(objAgreement, rtName)) {
                strApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
                //DCP-49596
                if (objAgreement.Post_Pricing_Message__c != NULL) {
                        strApprovalCategory += ApprovalCategory.POST_PRICING_MESSAGE.name() + ';';
                    }
            }
            else if (requiresLineApprovalAndClosed(objAgreement)) {
                if (objAgreement.Apttus_Approval__Approval_Status__c == Label.AgreementApprovalStatusApproved) {
                    strApprovalStatus = Label.AgreementApprovalStatusApproved;
                }
                else if (objAgreement.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_CANCELLED) {
                    strApprovalStatus = APPROVAL_STATUS_CANCELLED;
                }
                else if (objAgreement.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_REJECTED) {
                    strApprovalStatus = APPROVAL_STATUS_REJECTED;
                }
            }
            else if (objAgreement.Number_Of_Agreement_Line_Items__c > 0
                && objAgreement.Number_of_Line_Items_Approvals__c < 1 && String.isBlank(objAgreement.Approval_Category__c)
            ) {
                 strApprovalStatus = Label.AgreementApprovalStatusApproved;
            }

            objAgreement.Approval_Category__c = strApprovalCategory;
            objAgreement.Apttus_Approval__Approval_Status__c = strApprovalStatus;
            ilib_LogEvent.message('objAgreement.Approval_Category__c : '+objAgreement.Approval_Category__c);
            ilib_LogEvent.message('objAgreement.Apttus_Approval__Approval_Status__c : '+objAgreement.Apttus_Approval__Approval_Status__c);
        }
        ilib_LogEvent.pop();
    }

    private List<Apttus__APTS_Agreement__c> filterAgreementsForApproval(List<Apttus__APTS_Agreement__c> allAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'filterAgreementsForApproval()');
        // on insert, no filtering
        // need to set initial approval categories
        if (Trigger.isInsert) {ilib_LogEvent.pop(); 
        return allAgreements; }

        // on update, filter
        List<Apttus__APTS_Agreement__c> lstFilteredAgreements = new List<Apttus__APTS_Agreement__c>();

        // collections used for filtering agreements
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        List<String> lstFieldsTriggerApprovals = new List<String> {
            'Term_in_Months__c', 'Incoterm__c', 'Apttus__Subtype__c', 'Notification_Period_for_Price_Changes__c',
            'Apttus__Auto_Renewal__c', 'Territory__c', 'Value_Added_Distributor__c', 'Exclusivity__c',
            'Competitive_Products__c', 'Q1_Quota__c', 'Q2_Quota__c', 'Q3_Quota__c', 'Q4_Quota__c', 'Annual_Quota__c',
            'Apttus__Subtype__c', 'Region__c', 'Sub_Distributor__c', 'Estimated_Tender_Value__c', 'Apttus__Account__c'//DCP-46535
            ,'Post_Pricing_Message__c'//DCP-49596
            ,'Freight_Charge__c','Number_Of_Agreement_Line_Items__c'//CMCM-7846
        };

        for (Apttus__APTS_Agreement__c objNewAgreement : allAgreements)
        {
            Apttus__APTS_Agreement__c objOldAgreement = (Apttus__APTS_Agreement__c)Trigger.oldMap.get(objNewAgreement.Id);
            ilib_LogEvent.message('objOldAgreement : '+objOldAgreement);


            String rTName = objNewAgreement.RecordTypeId == null ? null : idToRecordTypeInfo.get(objNewAgreement.RecordTypeId).getDeveloperName();
            ilib_LogEvent.message('rTName : '+rTName);

            // if RT is one of these values and one of lstFieldsTriggerApprovals was modified
            // then this approval needs approval categories updated
            if ((rtName == System.Label.AgreementRecordTypeChannelPartner || rtName == System.Label.AgreementRecordTypeMasterService || rtName == System.Label.AgreementRecordTypeTender || rtName == STANDING_QUOTE //DCP-49596 added standing quote RT
             || rtName == OPEN_OFFER || rtName == SPECIAL_PROGRAMS //CMCM-7846
            )
                && UtilsCollection.areAnyValuesModified(objNewAgreement, objOldAgreement, lstFieldsTriggerApprovals)
            ) {
                lstFilteredAgreements.add(objNewAgreement);
            }
        }
        ilib_LogEvent.info('lstFilteredAgreements Ids :'+UtilsCollection.getSetOfIds(lstFilteredAgreements));
        ilib_LogEvent.pop();

        return lstFilteredAgreements;
    }

    private Boolean hasNonZeroValue(Decimal val)
    {
        return (val != null && String.valueOf(val) != '' && val != 0);
    }

    /*
    * Author : Pankaj
    * User Story : DCP - 33708
    * Functionality : To update price group and price group description
    */
    //adding reference sales org
    private void setPriceGroupAndPGDescription(List<Apttus__APTS_Agreement__c> lstAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'setPriceGroupAndPGDescription()');
        // filter agreements that need values
        List<Apttus__APTS_Agreement__c> lstAgreementsToSetValues;
        if (Trigger.isInsert) {
            lstAgreementsToSetValues = new List<Apttus__APTS_Agreement__c>(lstAgreements);
        }
        else { // isUpdate
            // on update, only proceed if any of these values has changed
            List<String> priceGroupRelevantFields = new List<String> {'Sales_Org__c', 'Price_Group_Description__c'};
            lstAgreementsToSetValues = UtilsCollection.filterOnFieldsModified(lstAgreements, Trigger.oldMap, priceGroupRelevantFields);
            if (lstAgreementsToSetValues.isEmpty()) {ilib_LogEvent.pop(); 
            return;}
        }

        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAgreementsToSetValues, STR_ACCOUNT_API_NAME);
        System.debug('@@@ setAccountIds- ' + setAccountIds);
        ilib_LogEvent.info('setAccountIds : '+setAccountIds);

        List<Account_Sales_Area__c> lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setAccountIds);
        System.debug('@@@ lstAccountSalesArea - '+lstAccountSalesArea);
        if (lstAccountSalesArea.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        Map<String, List<Account_Sales_Area__c>> accountToListOfSalesArea = new Map<String, List<Account_Sales_Area__c>>();
        accountToListOfSalesArea = setAccountToListOfSalesArea(lstAccountSalesArea,accountToListOfSalesArea);
        System.debug('@@@ accountToListOfSalesArea - ' + accountToListOfSalesArea);

        for (Apttus__APTS_Agreement__c oAgreement : lstAgreements)
        {
            ilib_LogEvent.message('oAgreement : '+oAgreement);
            // default to blank
            oAgreement.Price_Group__c = '';
            oAgreement.Price_Group_Description__c = '';

            if (!accountToListOfSalesArea.containskey(oAgreement.Apttus__Account__c)) {continue;}

            for (Account_Sales_Area__c oAccSalesArea2 : accountToListOfSalesArea.get(oAgreement.Apttus__Account__c))
            {
                ilib_LogEvent.fine('oAccSalesArea2 : '+oAccSalesArea2);
                if (oAgreement.Sales_Org__c == oAccSalesArea2.Sales_Organization__c && oAgreement.Distribution_Channel__c == oAccSalesArea2.Distribution_Channel__c) {
                    ilib_LogEvent.fine('Inside if condition');
                    System.debug('Inside if condition');
                    oAgreement.Price_Group__c=oAccSalesArea2.Price_Group__c;
                    oAgreement.Price_Group_Description__c=oAccSalesArea2.Price_Group_Description__c;
                    ilib_LogEvent.fine('oAgreement.Price_Group__c : '+oAgreement.Price_Group__c);
                    ilib_LogEvent.fine('oAgreement.Price_Group_Description__c : '+oAgreement.Price_Group_Description__c);
                }
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    * Method to set Map AccountToListOfSalesArea
    */
    private Map<String, List<Account_Sales_Area__c>> setAccountToListOfSalesArea(List<Account_Sales_Area__c> lstAccountSalesArea,Map<String, List<Account_Sales_Area__c>> accountToListOfSalesArea){
        ilib_LogEvent.push(LOG_TITLE+'setAccountToListOfSalesArea()');
        for (Account_Sales_Area__c oSalesArea : lstAccountSalesArea)
        {
            ilib_LogEvent.message('oSalesArea : '+oSalesArea);
            if (oSalesArea.Price_Group__c != null && oSalesArea.Price_Group_Description__c != null) {
                if (!accountToListOfSalesArea.containskey(oSalesArea.Account__c)) {
                    accountToListOfSalesArea.put(oSalesArea.Account__c, new List<Account_Sales_Area__c>());
                }
                accountToListOfSalesArea.get(oSalesArea.Account__c).add(oSalesArea);
            }
        }
        ilib_LogEvent.pop();
        return accountToListOfSalesArea;
    }

    /*
    * Author : Vishnu Kurra
    * User Story : DCP - 33720
    * Functionality : To populate Line Items Required Optional Field
    */
    private void populateAgreementLineItem(List<Apttus__APTS_Agreement__c> lstAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'populateAgreementLineItem()');
        if (lstAgreements.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();

        Set<String> setRecordTypeName = new Set<String>();
        Set<String> setSubtype = new Set<String>();

        for (Apttus__APTS_Agreement__c oAgreement : lstAgreements)
        {
            ilib_LogEvent.message('Agreement Records : '+oAgreement);
            if (String.isNotBlank(oAgreement.Apttus__Subtype__c)) {
                ilib_LogEvent.message('Inside If Condition');
                setSubtype.add(oAgreement.Apttus__Subtype__c);
                setRecordTypeName.add(idToRecordTypeInfo.get(oAgreement.RecordTypeId).getName());
            }
        }

        List<Agreement_Line_Items_Required__mdt> lstLineRequredConfig = new AgreementLineItemRequiredSelector().selectAgreementLineItem(setSubtype, setRecordTypeName);

        for (Apttus__APTS_Agreement__c oAgreement : lstAgreements)
        {
            // default value
            oAgreement.Line_Items_Required_Optional__c = Label.AgreementLineItemOptional;

            // check if config says required
            for (Agreement_Line_Items_Required__mdt lineRequredConfig : lstLineRequredConfig)
            {
                ilib_LogEvent.fine('Inside nested for loop');
                ilib_LogEvent.fine('lineRequredConfig : '+lineRequredConfig);
                if (lineRequredConfig.Agreement_Record_Type__c == idToRecordTypeInfo.get(oAgreement.RecordTypeId).getName()
                    && lineRequredConfig.Agreement_Sub_Type__c == oAgreement.Apttus__Subtype__c
                ) {  oAgreement.Line_Items_Required_Optional__c = lineRequredConfig.Is_Agreement_Line_Items_Required__c;
                     ilib_LogEvent.fine('oAgreement.Line_Items_Required_Optional__c : '+oAgreement.Line_Items_Required_Optional__c); 
                }
            }
        }
        ilib_LogEvent.pop();
    }
    
    //adding reference
    /*
    * Author : Umesh
    * User Story : DCP - 32575
    * Functionality : To validate Agreement Sales Org
    */
    //adding reference sales org
    private void validateAgreementSalesOrg(List<Apttus__APTS_Agreement__c> lstAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'validateAgreementSalesOrg()');
        if (lstAgreements.isEmpty()) {ilib_LogEvent.pop(); 
        return;}

        ilib_LogEvent.info('@@@ Agreement record - ' + lstAgreements);

        Set<Id> setAccount = UtilsCollection.getSetOfIds(lstAgreements, STR_ACCOUNT_API_NAME);
        ilib_LogEvent.info('Account Id Set : '+setAccount);

        Map<Id, Set<String>> accountToSetOfSalesAreas = new Map<Id, Set<String>>();
        //Added to fix bulk test error : SOQL and Too many queries
        if (!setAccount.isEmpty()) {
            List<Account_Sales_Area__c> lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setAccount);
            ilib_LogEvent.info('@@@ lstAccountSalesArea - ' + lstAccountSalesArea);

            for (Account_Sales_Area__c oSalesArea : lstAccountSalesArea)
            {
                if (oSalesArea.Sales_Organization__c == null) {continue;}

                if (!accountToSetOfSalesAreas.containskey(oSalesArea.Account__c)) {
                    accountToSetOfSalesAreas.put(oSalesArea.Account__c, new Set<String>());
                }
                accountToSetOfSalesAreas.get(oSalesArea.Account__c).add(oSalesArea.Sales_Organization__c);
            }
        }
        ilib_LogEvent.message('Set of Account Id to Sales Org : '+accountToSetOfSalesAreas);

        for (Apttus__APTS_Agreement__c oAgreement : lstAgreements)
        {
            if (String.isBlank(oAgreement.Sales_Org__c)) {continue;}

            if (!accountToSetOfSalesAreas.containsKey(oAgreement.Apttus__Account__c)) {
                oAgreement.addError(Label.UI_Error_Message_Validate_Salesorg);
            }
            else if (!accountToSetOfSalesAreas.get(oAgreement.Apttus__Account__c).contains(oAgreement.Sales_Org__c)) {
                oAgreement.addError(Label.UI_Error_Message_Validate_Salesorg);
            }
        }
        ilib_LogEvent.pop();
    }

    //adding reference
    /*
    * Author : Joshith
    * User Story : DCP - 34982
    * Functionality : To Default Sales Org and Currency  depending on Related Account Country code on Agreement creation.
    */
    //adding reference sales org
    private void setDefaultSalesOrgAndCurrency(List<Account> accounts, List<Apttus__APTS_Agreement__c> lstAgreement) {
        ilib_LogEvent.push(LOG_TITLE+'setDefaultSalesOrgAndCurrency()');
        Map<String, String> mapAccountWithCountryCode = new Map<String, String>();
        Map<String, String> mapAccountWithCurrencyCode = new Map<String, String>();
        Map<String, Id> mapAccountWithOwnerId = new Map<String, Id>();
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();

        for (Account objAcc : accounts) {
            ilib_LogEvent.message('Account Records : '+objAcc);
            mapAccountWithCountryCode.put(objacc.Id, objacc.BillingCountryCode);
            mapAccountWithCurrencyCode.put(objacc.Id, objacc.CurrencyIsoCode);
            mapAccountWithOwnerId.put(objacc.Id, objacc.OwnerId);
        }

        Set<String> setCountryCodes = new Set<String>(mapAccountWithCountryCode.values());
        ilib_LogEvent.info('setCountryCodes : '+setCountryCodes);

        Map<String, String> mapSalesArea = UtilsObject.getMapOfStringToString(new SalesAreasSelector().selectSalesArea(setCountryCodes), 'Country_Code__c', 'Sales_Organization__c');
        ilib_LogEvent.info('mapSalesArea : '+mapSalesArea);

        for (Apttus__APTS_Agreement__c objAgreement : lstAgreement)
        {
            ilib_LogEvent.message('objAgreement : '+objAgreement);
            if (objAgreement.Sales_Org__c == null) {
                objAgreement.Sales_Org__c = mapSalesArea.get(mapAccountWithCountryCode.get(objAgreement.Apttus__Account__c));
                ilib_LogEvent.message('objAgreement.Sales_Org__c : '+objAgreement.Sales_Org__c);
            }

            if (idToRecordTypeInfo.containsKey(objAgreement.RecordTypeId) && (idToRecordTypeInfo.get(objAgreement.RecordTypeId).getName() == Label.AgreementRecordTypeNameStandingQuote || 
                idToRecordTypeInfo.get(objAgreement.RecordTypeId).getName() == Label.AgreementRecordTypeNameTender ||
                idToRecordTypeInfo.get(objAgreement.RecordTypeId).getName() == Label.AgreementRecordTypeNameOpenOffer)) { // Added for DCP-54499
                if(objAgreement.Apttus__Account__c != null && String.isNotBlank(objAgreement.Apttus__Account__c)
                   && mapAccountWithOwnerId.containsKey(objAgreement.Apttus__Account__c))
                    {
                        objAgreement.Prepared_By__c = mapAccountWithOwnerId.get(objAgreement.Apttus__Account__c);
                        ilib_LogEvent.message('objAgreement.Prepared_By__c : '+objAgreement.Prepared_By__c);
                    } 
            }

            objAgreement.CurrencyIsoCode = mapAccountWithCurrencyCode.get(objAgreement.Apttus__Account__c);
            ilib_LogEvent.message('objAgreement.CurrencyIsoCode : '+objAgreement.CurrencyIsoCode);
        }
        ilib_LogEvent.pop();
    }

     /*
    @author: B Kamini
    @Story : DCP-37876
    @Description : To populate Account Region on Agreement based on Account's Region
    */

    public void setAccountRegion(List<Apttus__APTS_Agreement__c> lstAgreements){

        ilib_LogEvent.push(LOG_TITLE+'setAccountRegion()');
        Set<Id> setAccountOnAgreement = new Set<Id>();
        Map<Id,String> mapAccountRegion = new Map<Id,String>();

        for (Apttus__APTS_Agreement__c agreement : lstAgreements) {
            if (agreement.Apttus__Account__c != null) {setAccountOnAgreement.add(agreement.Apttus__Account__c);} //Set of accounts from agreement
        }

        List<Account> lstTerritoryRegions = new AccountsSelector().getAccountsTerritories(setAccountOnAgreement);
        if(!lstTerritoryRegions.isEmpty()){
            for(Account oAccount : lstTerritoryRegions ){
                mapAccountRegion.put(oAccount.Id,oAccount.Territory_Region__c); //map of account ids and correspomding regions from account
            }
        }

        ilib_LogEvent.info('setAccountOnAgreement : '+setAccountOnAgreement);
        ilib_LogEvent.info('mapAccountRegion : '+mapAccountRegion);

        for(Apttus__APTS_Agreement__c agreement : lstAgreements){
            if (agreement.Apttus__Account__c != null && mapAccountRegion.containsKey(agreement.Apttus__Account__c)){
                agreement.Account_Region__c = mapAccountRegion.get(agreement.Apttus__Account__c);
            }
        }
        ilib_LogEvent.pop();

    }

    /*
    @author: Roopal Verma
    @Story : DCP-37652
    @Description : To populate Submitted By and Approval Request Present from Approval requests.
    */
    public void setAppReqPresent(List<Apttus__APTS_Agreement__c> lstAgreements, Map<Id, SObject> idToAgreements){
        
        ilib_LogEvent.push(LOG_TITLE+'setAppReqPresent()');
        if (lstAgreements.isEmpty()){ilib_LogEvent.pop(); 
        return;}

        // Bharath Varma - INC0375108: Added filter on agreements where the Approval Status is updated.
        // Only Agreements whose approval status is updated are considered while updating Approval_Request_Present__c field
        List<Apttus__APTS_Agreement__c> lstAgreementsWithModifiedApprovalStatus = UtilsCollection.filterOnFieldsModified(lstAgreements, idToAgreements, new List<String>{'Apttus_Approval__Approval_Status__c'});
        
        if (lstAgreementsWithModifiedApprovalStatus.isEmpty()){ilib_LogEvent.pop(); 
        return;}

        Set<Id> setAgreementId = (new Map<Id,Apttus__APTS_Agreement__c>(lstAgreements)).keySet();
        ilib_LogEvent.info('setAgreementId : '+setAgreementId);
        List<Apttus_Approval__Approval_Request__c> lstAppReq = new ApttusApprovalRequestsSelector().selectAppReqByAgreementId(setAgreementId);
        Map<Id, Id> mapAgreementIdToSubmittedBy = new Map<Id, Id>();

        if(!lstAppReq.isEmpty()){
            for(Apttus_Approval__Approval_Request__c objAppReq : lstAppReq){
                if(!mapAgreementIdToSubmittedBy.containskey(objAppReq.Apttus_Approval__Related_Agreement__c)){
                    mapAgreementIdToSubmittedBy.put(objAppReq.Apttus_Approval__Related_Agreement__c,objAppReq.CreatedById);
                }
            }
        }
        ilib_LogEvent.message('mapAgreementIdToSubmittedBy : '+mapAgreementIdToSubmittedBy);

        for(Apttus__APTS_Agreement__c objAgreement : lstAgreementsWithModifiedApprovalStatus){
            if(mapAgreementIdToSubmittedBy.containskey(objAgreement.id)){
                objAgreement.Approval_Request_Present__c = true;
                objAgreement.Submitted_by__c = mapAgreementIdToSubmittedBy.get(objAgreement.id);
            }
            else { objAgreement.Approval_Request_Present__c = false; }

        }
        ilib_LogEvent.pop();
    }

    /*
    * INC0277130 - JPY and KRW currencies should not have units smaller than 1  
    */
    public static Integer getCurrencyPrecision(String currencyCode) 
    {   
        ilib_LogEvent.push(LOG_TITLE+'getCurrencyPrecision()');
        ilib_LogEvent.info('currencyCode : '+currencyCode);
        Integer precision = 2; // default value 
        if (ApttusAgreements.ZERO_PRECISION_CURRENCIES.contains(currencyCode)) {
            precision = 0;
        }
        ilib_LogEvent.info('precision : '+precision);
        ilib_LogEvent.pop();
        return precision;
    }

    /*
    @author: Tapas
    @Story : INC0293002
    @Description : To reset agreement status, status category and validation status if agreement is cloned via OOTB Clone button(and not by Amend/Renew button)
    */

    private void resetStatusOfClonedAgreements(List<Apttus__APTS_Agreement__c> lstAgreements){
        ilib_LogEvent.push(LOG_TITLE+'resetStatusOfClonedAgreements()');
        Set<String> setAmendRenewStatuses = new Set<String>{Label.Apttus_Status_In_Amendment, Label.Apttus_Status_In_Renewal};
        Set<Id> cloneSourceIds = new Set<Id>();
        List<Apttus__APTS_Agreement__c> lstClonedAgreements = new List<Apttus__APTS_Agreement__c>();
        //Added for Open Offer Agreements
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap(); 
        for(Apttus__APTS_Agreement__c objAgreement : lstAgreements){
            if(objAgreement.isClone()){
                ilib_LogEvent.message('resetStatusOfClonedAgreements- the cloned agmt id is : '+objAgreement.getCloneSourceId());
                cloneSourceIds.add(objAgreement.getCloneSourceId());
                lstClonedAgreements.add(objAgreement);
            }
        }
        if(cloneSourceIds.isEmpty()) {ilib_LogEvent.pop(); 
        return; }

        Map<Id,Apttus__APTS_Agreement__c> idToAgreement = new Map<Id,Apttus__APTS_Agreement__c>(new ApttusAgreementSelectors().selectAgreements(cloneSourceIds));
        for(Apttus__APTS_Agreement__c objAgreement : lstClonedAgreements){
            
            String strRecordTypeName = idToRecordTypeInfo.get(objAgreement.RecordTypeId).getDeveloperName();
            //Added check for Open Offer Agreements Amends
            if(!(objAgreement.Apttus__Status_Category__c == Label.AgreementStatusCategoryRequest && setAmendRenewStatuses.contains(objAgreement.Apttus__Status__c))
               || setAmendRenewStatuses.contains(idToAgreement.get(objAgreement.getCloneSourceId()).Apttus__Status__c)  
               || (strRecordTypeName == System.label.AgreementRecordTypeOpenOffer && LABEL.Apttus_Status_In_Amendment.equals(objAgreement.Apttus__Status__c))) {
                   
                if(strRecordTypeName == System.label.AgreementRecordTypeOpenOffer) {
                    if(System.label.Apttus_Status_In_Amendment.equals(objAgreement.Apttus__Status__c)) {
                        //DCP-56502 Defaulting values in case of Amendments
                        objAgreement.Open_Offer_Status__c = Label.AgreementOpenOfferStatusAffiliateConfirmation;
                        objAgreement.Apttus__Status__c = Label.Apttus_Status_In_Amendment;
                        objAgreement.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
                       // objAgreement.Apttus__Contract_Start_Date__c = Date.Today();
                    }
               } else{
                    objAgreement.Apttus__Status__c = Label.AgreementStatusRequest;
                    objAgreement.Agreement_Not_Amended__c = true;
                    objAgreement.Apttus_Approval__Approval_Status__c = APPROVAL_STATUS_NOT_SUBMITTED;
                    objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryRequest;
                    objAgreement.Validation_Status__c = '';
                    objAgreement.Pricing_Generation_Status__c = '';
                    objAgreement.Apttus__Activated_By__c = null;
                    objAgreement.Apttus__Activated_Date__c = null;
                    objAgreement.Apttus__Amendment_Effective_Date__c = null;
                    objAgreement.Apttus__Other_Party_Returned_Date__c = null;
                    objAgreement.Apttus__Company_Signed_By__c = null;
                    objAgreement.Apttus__Company_Signed_Date__c = null;
                    objAgreement.Apttus__Company_Signed_Title__c = null;
                    //objAgreement.Customer_Reference_Number__c = null;
                    objAgreement.Apttus__IsInternalReview__c = false;
                    objAgreement.Apttus_CMConfig__IsSystemGenerated__c = false;
                    objAgreement.Apttus__Is_System_Update__c = false;
                    objAgreement.Is_Updated_By_System__c = false;
                    objAgreement.Legacy_Agreement_Number__c = null;
                    objAgreement.Apttus__Other_Party_Sent_Date__c = null;
                    objAgreement.Apttus__Other_Party_Signed_By__c = null;
                    objAgreement.Apttus__Other_Party_Signed_Date__c = null;
                    objAgreement.Apttus__Other_Party_Signed_Title__c = null;
                    objAgreement.Apttus__Requestor__c = null;
                    objAgreement.Apttus__Termination_Date__c = null;
                    objAgreement.Is_Validated_Successful__c = false;    
               }
            }
        }
        ilib_LogEvent.pop();

    }

    /*
    @Author - Rishab Wali
    @Story : DCP-43224
    @Description : Check If Account is Updated on Agreement.
    @Paramters - Old Map , New Map
    */
    public static void checkIfAccountIsUpdated(Map<Id,SObject> newAgreementDataMap , Map<Id,SObject> oldAgreementDataMap)
    {
        ilib_LogEvent.push(LOG_TITLE+'checkIfAccountIsUpdated()');
        Map<Id,Apttus__APTS_Agreement__c> newDataMap = (Map<Id,Apttus__APTS_Agreement__c>)newAgreementDataMap;
        Map<Id,Apttus__APTS_Agreement__c> oldDataMap = (Map<Id,Apttus__APTS_Agreement__c>)oldAgreementDataMap;
        Map<Id,Id> aggToOldAccountMap = new Map<Id,Id>();
        Set<Id> setAgreementIds = new Set<Id>(); 
        for(Apttus__APTS_Agreement__c agg : newDataMap.values())
        {   if(agg.Apttus__Account__c != oldDataMap.get(agg.Id).Apttus__Account__c) {
                setAgreementIds.add(agg.Id);
                aggToOldAccountMap.put(agg.Id,oldDataMap.get(agg.Id).Apttus__Account__c);
            }
        }
        if(!setAgreementIds.isEmpty()) {
            updateAgreementAccountRelationship(setAgreementIds,aggToOldAccountMap);
        }
        ilib_LogEvent.info('setAgreementIds : '+setAgreementIds);
        ilib_LogEvent.info('aggToOldAccountMap : '+aggToOldAccountMap);
        ilib_LogEvent.pop();
    }

    /*
    @Author - Rishab Wali
    @Story : DCP-43224
    @Description : Update Agreement Account Relationship records.
    @Paramters - Set <Id> Agreement Id Set
    */
    public static void updateAgreementAccountRelationship(Set<Id> agreementIdSet , Map<Id,Id> aggIdToOldAccMap)
    {
        ilib_LogEvent.push(LOG_TITLE+'updateAgreementAccountRelationship()');
        List<Agreement_Account_Relationship__c> lstAggAccRltnship = new List<Agreement_Account_Relationship__c>();
        AgreementAccountRelationshipSelectors aggAccSelector = new AgreementAccountRelationshipSelectors();
        lstAggAccRltnship = aggAccSelector.selectByAgreementId(agreementIdSet);

        for(Agreement_Account_Relationship__c objAggAccRltn : lstAggAccRltnship)
        {
            ilib_LogEvent.message('objAggAccRltn : '+objAggAccRltn);
            if(aggIdToOldAccMap.containsKey(objAggAccRltn.Agreement__c) 
               && objAggAccRltn.Account__c == aggIdToOldAccMap.get(objAggAccRltn.Agreement__c)) {
                objAggAccRltn.Account__c =  objAggAccRltn.Agreement__r.Apttus__Account__c;
                ilib_LogEvent.message('objAggAccRltn.Account__c : '+objAggAccRltn.Account__c); 
            }
        }
        update lstAggAccRltnship;
        ilib_LogEvent.pop();

    }          

    
    /*
    @author: Joshith K
    @Story : TASK0537090
    @Description : To update agreement lines on Activation.
    */ 
    private void updateLineItemStatusForActivate(Map<Id, SObject> idToAgreements)
    {
        ilib_LogEvent.push(LOG_TITLE+'updateLineItemStatusForActive()');
        //Activation 
        List<Apttus__APTS_Agreement__c> lstAgreementsWithChangedStatus = UtilsCollection.filterForChangeToValue(
            records,
            idToAgreements,
            new Map<String, Set<Object>> {'Apttus__Status__c' => new Set<Object> {Label.AgreementStatusActivated}}
        );
        for(Apttus__APTS_Agreement__c objAgreement:lstAgreementsWithChangedStatus)
        {   
                ApttusAgreementErrorHandler.updateLineItems(objAgreement,Label.AgreementActionActivate);     
        }
        ilib_LogEvent.pop();
        
    }

    /*
    @Author - Rishab Wali
    @Story : DCP-37232
    @Description : Check If Preferred Language is Updated on Agreement.
    @Paramters - Old Map , New Map
    @Modified for Open offer.dcp-54810
    */
    public static void checkIfPreferredLanguageIsUpdated(Map<Id,SObject> newAgreementDataMap , Map<Id,SObject> oldAgreementDataMap)
    {
        ilib_LogEvent.push(LOG_TITLE+'checkIfPreferredLanguageIsUpdated()');
        Map<Id,Apttus__APTS_Agreement__c> newDataMap = (Map<Id,Apttus__APTS_Agreement__c>)newAgreementDataMap;
        Map<Id,Apttus__APTS_Agreement__c> oldDataMap = (Map<Id,Apttus__APTS_Agreement__c>)oldAgreementDataMap;
        List<Apttus__APTS_Agreement__c> lstAgreements = new List<Apttus__APTS_Agreement__c>(); 

        for(Apttus__APTS_Agreement__c agg : newDataMap.values())
        {
            updateOpenOfferAgreementStatus(agg,oldDataMap);//DCP-54810 OpenOffer 
            if(agg.Preferred_Language__c != oldDataMap.get(agg.Id).Preferred_Language__c) {
                lstAgreements.add(agg);
            }
        }
        if(!lstAgreements.isEmpty()) {
            PreferredLanguageService.setPreferredLanguage(lstAgreements);
        }
        ilib_LogEvent.pop();
    }       
    /*
    @Author - Saddam
    @Story : DCP-54810
    @Description : Check if approval status and status category is updating then udpate the OO Agreements OO status value. 
    @Paramters - Agreement Record,Old Map , New Map
    */
    public static void updateOpenOfferAgreementStatus(Apttus__APTS_Agreement__c objAgreement,Map<Id,Apttus__APTS_Agreement__c> oldDataMap) {

        ilib_LogEvent.push(LOG_TITLE+'updateOpenOfferAgreementStatus()');
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap(); 
        String strRecordTypeName = idToRecordTypeInfo.get(objAgreement.RecordTypeId).getDeveloperName();
        
        if(strRecordTypeName != System.label.AgreementRecordTypeOpenOffer) {  
            ilib_LogEvent.pop(); 
            return; 
        }     
        if(objAgreement.Apttus_Approval__Approval_Status__c != oldDataMap.get(objAgreement.Id).Apttus_Approval__Approval_Status__c ) {
            if(objAgreement.Apttus_Approval__Approval_Status__c ==  System.label.AgreementApprovalStatusPendingApproval) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusEligibilityApproval; 
            } else if(objAgreement.Apttus_Approval__Approval_Status__c == System.label.AgreementApprovalStatusApproved) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusAffiliateConfirmation; }  
        }
        if(objAgreement.Apttus__Status_Category__c != oldDataMap.get(objAgreement.Id).Apttus__Status_Category__c) {
            if(objAgreement.Apttus__Status_Category__c == System.label.InSignatures) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusSignatures;
            } else if(objAgreement.Apttus__Status_Category__c == System.label.AgreementStatusCategoryInEffect) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusInEffect;
            } else if(objAgreement.Apttus__Status_Category__c == STATUS_CATEGORY_AMENDED) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusAmended;
            } else if(objAgreement.Apttus__Status_Category__c == System.label.AgreementStatusCategoryCancelled) {
                    objAgreement.Open_Offer_Status__c = System.label.AgreementOpenOfferStatusCancelled;
            } else if(objAgreement.Apttus__Status_Category__c == System.label.AgreementStatusCategoryTerminated) { // DCP-56507 Changes.
                    objAgreement.Open_Offer_Status__c = System.label.OpenOfferAgreementStatusCategoryTerminated;
            }
        }
        ilib_LogEvent.pop(); 
    }            
    
    /*
    @Author : Bharath Varma
    @Story : DCP-47006
    @Description : Method to check number of Line items with UC Discounts.
    @Paramters : List of Agreements
    @Test Class : TestApttusAgreements.testUCMaterialRollUp
    */
    private void checkAgreementsWithUCDiscLineItems(List<Apttus__APTS_Agreement__c> lstAgreements) {

        ilib_LogEvent.push(LOG_TITLE+'checkAgreementsWithUCDiscLineItems()');
        Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement = ApttusAgreementsHelper.getMapIdToAgreement(lstAgreements);
        List<Apttus__AgreementLineItem__c> lstAgreementLineItems = new ApttusAgreementLineItemSelectors().selectAgreementLineItem(mapIdToAgreement.keySet());
        ApttusAgreementsHelper.updateAgrFromLineItems(lstAgreementLineItems, mapIdToAgreement);
        ilib_LogEvent.pop();

    }
    
    /*
    @Author : Bharath Varma
    @Story : DCP-46102
    @Description : Check if the Tender Agreement in Compliant.
    @Paramters : List of Agreements
    @Test Class : TestApttusAgreements.testNonComplianceConditions
    */
    private void checkForTenderCompliance(List<Apttus__APTS_Agreement__c> records) {
        ilib_LogEvent.push(LOG_TITLE+'checkForTenderCompliance()');
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        String rTName = null;
        for(Apttus__APTS_Agreement__c agreement: records) {
            if (agreement.RecordTypeId != null) {
                rtName = idToRecordTypeInfo.get(agreement.RecordTypeId).getDeveloperName(); 
                ilib_LogEvent.message('rtName : '+rtName);
            }
            if(rtName == Label.AgreementRecordTypeNameTender) {
                agreement.Reason_for_Non_Compliance__c = checkComplianceConditions(agreement);
                ilib_LogEvent.message('agreement.Reason_For_Non_Compliance__c : '+agreement.Reason_for_Non_Compliance__c);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46102
    @Description : Method to check the non-compliance conditions.
    @Paramters : Agreement
    @Test Class : TestApttusAgreements.testNonComplianceConditions
    */
    private String checkComplianceConditions(Apttus__APTS_Agreement__c agreement) {
        ilib_LogEvent.push(LOG_TITLE+'checkComplianceConditions()');
        ilib_LogEvent.info('agreement : '+agreement);
        String bullet = '~ ';
        String endLine = '\n';
        String errorMessage = '';
        Set<String> tenderStatuses = new Set<String>{'Submitted', 'Lost', 'Won Pending PO/Contract', 'In Effect/Won', STRING_STATUS_CANCELLED};

        if(agreement.Tender_Type__c == null) {
            errorMessage += bullet + Label.UI_Label_TenderTypeBlank + endLine;
        }
        if(agreement.Submission_Response_Deadline__c < System.Today() && agreement.Tender_submitted_date__c == null) {
            errorMessage += bullet + Label.UI_Label_Submission_Deadline_Not_Met + endLine;
        }
        if(agreement.Tender_submitted_date__c > agreement.Submission_Response_Deadline__c) {
            errorMessage += bullet + Label.UI_Label_Submitted_After_Deadline + endLine;
        }
        if(tenderStatuses.contains(agreement.Tenders_Status__c) && agreement.Tenders_Status__c != STRING_STATUS_CANCELLED  && agreement.Estimated_Tender_Value__c == null) {
            errorMessage += bullet + Label.UI_Label_Estimated_Tender_Value_Is_Blank + endLine;
        }
        if(agreement.TAMs_Deadline_to_Respond__c < System.Today() && agreement.Date_TAM_decision_received__c == null) {
            errorMessage += bullet + Label.UI_Label_TAMs_Deadline_To_Respond_Not_Met + endLine;
        }
        if(tenderStatuses.contains(agreement.Tenders_Status__c) && agreement.Product_Interest__c == null) {
            errorMessage += bullet + Label.UI_Label_Product_Interest_Is_Blank + endLine;
        }
        if(agreement.Total_contract_length_with_extension__c == null && SET_OF_SUBTYPE.contains(agreement.Apttus__Subtype__c)) {
            errorMessage += bullet + Label.UI_Label_Total_contract_length_blank + endLine;
        }
        if(agreement.Date_awarded__c == null && agreement.Tenders_Status__c == STATUS_CATEGORY_IN_EFFECT_WON) {
            errorMessage += bullet + Label.UI_Label_Award_date_not_specified + endLine;
        }
        agreement.Non_Compliant_Tender__c = errorMessage == '' ? false : true;
        ilib_LogEvent.info('errorMessage : '+errorMessage);
        ilib_LogEvent.pop();
        return errorMessage;
    }

    /*
    @Author : Anand Palla
    @Story : DCP-48672
    @Description : Method to check whether the country is IVDR/EU.
    @Paramters : Agreement
    */
    private void checkCountryCategory(List<Apttus__APTS_Agreement__c> records){
        ilib_LogEvent.push(LOG_TITLE+'checkCountryCategory()');
        List<CountryRegionMapping__mdt> lstIVDRCountries = new CountryRegionMappingMetaDataSelector().selectIVDRCountryRegionMappingMetaRecords();
        List<CountryRegionMapping__mdt> lstEUCountries = new CountryRegionMappingMetaDataSelector().selectEUCountryRegionMappingMetaRecords();
        ilib_LogEvent.info('lstIVDRCountries : '+lstIVDRCountries);
        ilib_LogEvent.info('lstEUCountries : '+lstEUCountries);
        Set<String> setOfIVDRCountries = new Set<String>();
        Set<String> setOfEUCountries = new Set<String>();
        for(CountryRegionMapping__mdt crm : lstIVDRCountries){           
            if(crm.IVDR__c){
                setOfIVDRCountries.add(crm.CountryName__c);
            }
        }
        for(CountryRegionMapping__mdt crmd : lstEUCountries){           
            if(crmd.EU__c){
                setOfEUCountries.add(crmd.CountryName__c);
           }
        }
        ilib_LogEvent.info('setOfIVDRCountries : '+setOfIVDRCountries);
        ilib_LogEvent.info('setOfEUCountries : '+setOfEUCountries);
        updateCountryCategory(records,setOfIVDRCountries,setOfEUCountries);
        ilib_LogEvent.pop();
    }
    
    /*
    @Author : Juned
    @Story : DCP-48211
    @Description : Method to update Cycle TIme Report Stage field. 
    @Paramters : List of Agreements
    */
    private void updateCycleTimeReportStage(List<Apttus__APTS_Agreement__c> lstAgreements) {
        ilib_LogEvent.push(LOG_TITLE+'updateCycleTimeReportStage()');
        for(Apttus__APTS_Agreement__c agreement: lstAgreements) {
            if(agreement.Apttus__Status_Category__c == Label.AgreementStatusCategoryInAuthoring) {
                agreement.Cycle_Time_Report_Stage__c = OUTPUT_GENERATED;
                ilib_LogEvent.message('agreement.Cycle_Time_Report_Stage__c : '+agreement.Cycle_Time_Report_Stage__c);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Anand Palla
    @Story : DCP-48672
    @Description : Method to update the country category.
    @Paramters : List of Agreements
    */
    private void updateCountryCategory(List<Apttus__APTS_Agreement__c> lstAgreements,Set<String> setOfIVDRCountries,Set<String> setOfEUCountries) {
        ilib_LogEvent.push(LOG_TITLE+'updateCountryCategory()');
        ilib_LogEvent.info('setOfIVDRCountries : '+setOfIVDRCountries);
        ilib_LogEvent.info('setOfEUCountries : '+setOfEUCountries);
        
        for(Apttus__APTS_Agreement__c agreement: lstAgreements){
            if(agreement.Country_On_Account_Approvals__c != null && setOfIVDRCountries.contains(agreement.Country_On_Account_Approvals__c)){
                agreement.Country_Category__c = 'IVDR';
            }           
           if(agreement.Country_On_Account_Approvals__c != null && setOfEUCountries.contains(agreement.Country_On_Account_Approvals__c)){
                agreement.Country_Category__c = 'EU';
            }
           if(agreement.Country_On_Account_Approvals__c != null && setOfEUCountries.contains(agreement.Country_On_Account_Approvals__c) && setOfIVDRCountries.contains(agreement.Country_On_Account_Approvals__c)){
                agreement.Country_Category__c = 'IVDR/EU';
           }
           if(agreement.Country_On_Account_Approvals__c != null && !setOfEUCountries.contains(agreement.Country_On_Account_Approvals__c) && !setOfIVDRCountries.contains(agreement.Country_On_Account_Approvals__c)){
            agreement.Country_Category__c = '';
           }
        }
        ilib_LogEvent.pop();
    }


    /*
    @Author : Nishan Shetty
    @Story : DCP-50448
    @Description : Method to upsert Channel Partner Quota Records.
    @Paramters : List of Agreements
    */
    private void upsertChannelPartnerQuotaRecords(List<Apttus__APTS_Agreement__c> records,Map<Id, SObject> oldAgreementDataMap) {
        ilib_LogEvent.push(LOG_TITLE+'upsertChannelPartnerQuotaRecords()');
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        Map<Id, Apttus__APTS_Agreement__c> mapAcctIdToAgreement =new Map<Id,Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> oldDataMap = (Map<Id,Apttus__APTS_Agreement__c>)oldAgreementDataMap;
        String strChannelPartnerSubType =  Label.Channel_Partner_Agreement_Subtype;
        
        for(Apttus__APTS_Agreement__c objAgreement:records) {

            if(idToRecordTypeInfo.containsKey(objAgreement.RecordTypeId) 
            && idToRecordTypeInfo.get(objAgreement.RecordTypeId).getDeveloperName() == Label.AgreementRecordTypeChannelPartner
            && objAgreement.Apttus__Subtype__c !=null
            && strChannelPartnerSubType.containsIgnoreCase(objAgreement.Apttus__Subtype__c) 
            && objAgreement.Validation_Status__c!= oldDataMap.get(objAgreement.Id).Validation_Status__c 
            && objAgreement.Validation_Status__c == Label.AgreementValidationStatusActivateCompleted
            && objAgreement.Apttus__Account__c!=null) {  
                mapAcctIdToAgreement.put(objAgreement.Apttus__Account__c,objAgreement);
            }
        }
        
        if(!mapAcctIdToAgreement.isEmpty() && !stopRecursiveCallToChannelPartnerQuotaMethod) {
            ilib_LogEvent.info('mapAcctIdToAgreement : '+mapAcctIdToAgreement.keySet());
            stopRecursiveCallToChannelPartnerQuotaMethod=true;
            ChannelPartnerQuotaAutomation.upsertChannelPartnerQuotas(JSON.serialize(mapAcctIdToAgreement));
        }
        ilib_LogEvent.pop();
    }


    /*
    @Author : Anand Palla
    @Story : DCP-51143
    @Description : Method to populate 'Not Submitted' as default value for Approval Status.
    @Paramters : List of Agreements
    */
    private void populateDefaultApprovalStatus(List<Apttus__APTS_Agreement__c> records) {
        ilib_LogEvent.push(LOG_TITLE+'populateDefaultApprovalStatus()');
        for(Apttus__APTS_Agreement__c agreement: records) {
            ilib_LogEvent.message('agreement : '+agreement);
            if (agreement.Apttus_Approval__Approval_Status__c == null) {
                agreement.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;
                ilib_LogEvent.message('agreement.Apttus_Approval__Approval_Status__c : '+agreement.Apttus_Approval__Approval_Status__c);
            }
        }
        ilib_LogEvent.pop();
    }

    private void populateDefaultClinicalType(List<Apttus__APTS_Agreement__c> records, Map<Id, Account> mapAccounts) {
        for(Apttus__APTS_Agreement__c record : records) {
            Account acc = mapAccounts.get(record.Apttus__Account__c);
            if(acc != null && String.isBlank(record.Clinical_Type__c)) {
                record.Clinical_Type__c =  acc.Clinical_Type__c;
            }
        }
    }

     /*
    @Author : Vijay Masne
    @Story : TI-10949
    @Description : TI- Agreement: Status & Status Category as Request.
    @Paramters : List of Agreements
    */
    @testVisible
    private static void updateAgreementStatus(List<Apttus__APTS_Agreement__c> newAgreements, Map<Id, Apttus__APTS_Agreement__c> oldAgreementsMap) {
       
        if (Feature.isOn('WF_FF_APTS_Set_Status_Request')) {
            for (Apttus__APTS_Agreement__c agreement : newAgreements) {
              
                Apttus__APTS_Agreement__c oldAgreement = oldAgreementsMap != null ? oldAgreementsMap.get(agreement.Id) : null;
                
                Boolean hasStatusCategoryChanged = (oldAgreement != null && oldAgreement.Apttus__Status_Category__c != agreement.Apttus__Status_Category__c);
                Boolean hasStatusChanged = (oldAgreement != null && oldAgreement.Apttus__Status__c != agreement.Apttus__Status__c);
                
                if ((oldAgreement == null || hasStatusCategoryChanged || hasStatusChanged) && 
                    agreement.Name != null && 
                    agreement.Apttus__Status_Category__c == System.label.AgreementStatusRequest &&
                    (agreement.Apttus__Status__c != System.label.Apttus_Status_In_Amendment && 
                     agreement.Apttus__Status__c != System.label.Apttus_Status_In_Renewal)) {
                        
                    // Update Agreement Status to "Request"
                    agreement.Apttus__Status__c = System.label.AgreementStatusRequest;
                }

            }
        }
    }
    /*
    @Author : Vijay Masne
    @Story : TI-11007
    @Description : TI- APTS Set status category and status after the generation of document.
    @Paramters : List of Agreements
    */
    @testVisible
    private static void updateAgreementCategoryStatus(List<Apttus__APTS_Agreement__c> newAgreements, Map<Id, Apttus__APTS_Agreement__c> oldAgreementsMap) {

        // Check if the feature flag 'WF_APTS_Set_Status' is enabled
        if (Feature.isOn('WF_APTS_Set_Status')) {
                       
            for (Apttus__APTS_Agreement__c agreement : newAgreements) {
                
                Apttus__APTS_Agreement__c oldAgreement = oldAgreementsMap != null ? oldAgreementsMap.get(agreement.Id) : null;
               
                if (agreement.Apttus__Workflow_Trigger_Viewed_Final__c == true) {
                    
                    // Update the fields as specified
                    agreement.Apttus__Status_Category__c = System.label.AgreementStatusCategoryInAuthoring; 
                   
                    agreement.Apttus__Status__c = System.label.UI_Label_Agreement_Status_Author_Contract; 
               
                    agreement.Apttus__Workflow_Trigger_Viewed_Final__c = false; 
                   
                }
            }
        }
    }
     /*
    @Author : Vijay Masne
    @Story : TI-10601
    @Description : TI- Agreement : Update Other Party Signed Date when fully signed.
    @Paramters : List of Agreements
    */
    @testVisible
    private static void updateOtherPartySignedDate(List<Apttus__APTS_Agreement__c> newAgreements, Map<Id, Apttus__APTS_Agreement__c> oldAgreementsMap) {

        // Check if the feature flag 'WF_APTS_Set_Status' is enabled
        if (Feature.isOn('WF_FF_APTS_Set_Fully_Signed')) {
                       
            for (Apttus__APTS_Agreement__c agreement : newAgreements) {
                Apttus__APTS_Agreement__c oldAgreement = oldAgreementsMap != null ? oldAgreementsMap.get(agreement.Id) : null;
                
                Boolean isFullySigned = (agreement.Apttus__Status__c == System.Label.AgreementStatusFullySigned);
                Boolean wasNotFullySigned = (oldAgreement == null || oldAgreement.Apttus__Status__c != System.Label.AgreementStatusFullySigned);
    
                if (isFullySigned && wasNotFullySigned) {
                    agreement.Apttus__Other_Party_Signed_Date__c = Date.today();
                }
            }
        }
    }
    /*
    @Author : Rajbabu Boopalan
    @Story : CMCM-12243
    @Description : [CLM] [Channel Partner] Automation of VAD Designation
    @Paramters : List of Agreements, Related Accounts Map
    */
    private static void updateVADDesignation(List<Apttus__APTS_Agreement__c> newAgreements,  Map<Id, Account> mapAccounts) {
        // Check if the feature flag 'Sales_CLM_Auto_Update_VAD' is enabled
        if (Feature.isOn('Sales_CLM_Auto_Update_VAD')) {
                       
            for (Apttus__APTS_Agreement__c agreement : newAgreements) {
                Account acc = mapAccounts != null ? mapAccounts.get(agreement.Apttus__Account__c):null;
                Boolean isVADDistributorAccount = (acc != null && String.isNotBlank(acc.Channel_Partner_Type__c) 
                    && acc.Channel_Partner_Type__c == ACCOUNT_CHANNEL_PARTNER_TYPE_VAD);
                agreement.Value_Added_Distributor__c = false;
                // if the agreement's related account's CP type is VAD then set VAD flag on the agreement
                if (isVADDistributorAccount) {
                    agreement.Value_Added_Distributor__c = true;
                }
            }
        }
    }

}
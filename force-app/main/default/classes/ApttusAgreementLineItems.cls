/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    ApttusAgreementLineItems domain class
 *    Test Class 90%+ Coverage : TestApttusAgreements
 *    Test Class 75% Coverage :TestAgrLinesFindDuplicatesController , TestOpenOfferAgreements.
 *    Modification Log:
 *    Test Class 90%+ Coverage : TestApttusAgreements
 *    Test Class 75% Coverage :TestAgrLinesFindDuplicatesController , TestOpenOfferAgreements.
 *   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date               Description
 *     Kushagra                   11-Dec-2019          Initial Version
 *     Satya Swain                20-Dec-2019          Added methods for DCP-31673
 *     Kushagra Desai             15-Jan-2020          DCP-33377 : Condition type/Table update; before update
 *     Saswati                    16-Jan-2020          DCP-31789 : Approvals Framework
 *     B Kamini                   20-Jan-2020          DCP-31442 : Validations on adding product or product groups
 *     B Kamini                   08-Feb-2020          DCP-33776 : Modified on After update, on after Delete and associateAccountsOnAgreement method
 *     Saswati                    08-Feb-2020          DCP-32563 : Modified setApprovals method to accomodate changes for DCP-32563
 *     Pankaj                     13-feb-2020          DCP-31660 : Condition type/Table update; before update
 *     B Kamini                   19-Feb-2020          DCP-34092 : Added on before delete and added method validateLineStatusonDeletionAGLI method
 *     B Kamini                   24-Feb-2020          DCP-34092: Added checkupdatefieldsonValidateCompleted() to restrict users from editing line items when Agreement
                                                       Validation Status is Validate completed/Validate In progress
 *     Pankaj Sharma              28 Feb 2020          DCP-34093 : added Material group1 description logic
 *     Satya Swain                09-March-2020        DCP-34983 : Added setAccountLookup method to populate Account Id in Agreement LI
 *     Saswati Prusty             10 March 2020        DCP-32046
 *     Prabhsimran Singh          17 March 2020        DCP-32572
 *     Vishnu Kurra               18 March 2020        DCP-33720: To check Agreement ApprovalStatus is Approved
 *     Satya Swain                23 March 2020        DCP-36047 : Added deleteDiscontinuedAgreementLineItems 
 *     Satya Swain                27 March 2020        DCP-36652 : Bypassing validations for beforeDelete methods for Amend/Renew
 *      Pankaj                  13-feb-2020             DCP-31660 : Condition type/Table update; before update
 *     Kushagra Desai             27 March 2020         DCP-36645 : Blanking out Validation status on date update before activation
 *     B Kamini                    4 April 2020         DCP-34092 : Added populateLineStatusOnAGLIonUpdation (removed PB logic for line status update & incorporated via code)
 *     B Kamini                    8 April 2020         DCP-37265: Bypassed validation check for auto-approval for one transaction in validateApprovalStatus
 *     Joshith k                  27-May-2020           INC0270711- change logic in SetApprovals to map each line item with specific pricelist item.
 *     Rishab Wali                16-June-2020          DCP-38285 - Updated calculateDiscount() to populate Customer Price,List Price and Discount Amount   
 *     Rahul Bishnoi              17-June-2020         TASK0486150- Delete Agreement Account relationships after Line is items is discontinued.
 *     Joshith K                  10-June-2020         TASK0493822- update approval hierarchy discount in Agreement.
*      Roopal                     01-Sept-2020          DCP-40115 - Approval redesign- moved approval methods to new class ApttusAgreementsApprovals
*      Joshith K                  23-Nov-2020           TASK0537090-bypass populateLineStatusOnAGLIonUpdation for Interation profile and admin profiles
*      Anish                      10-Dec-2020           DCP-43353 - Special Programs related changes   
*      Prabhsimran Singh          10-Feb-2021           INC0307963 - Updated updatelstValues() to populate discontinued field.
*      Bharath Varma              29-Jun-2021           DCP-47006 - Added method to calculate number of Line items with UC Discounts
*      Bharath Varma              28-Feb-2022           TASK0700485 - Added method to check line items with Discounts on Amended agreements when the parent agreement doesnot have line items.
*      Ashwin Kumar               11-Mar-2022           INC0381333 - Add logic to never delete the default (AAR account = Agreement's Acc) agreement account relationship during insert/update/delete of ALI
*      Bharath Varma              08-Mar-2022           TASK0720220 - Added logic to update validation status to blank when a line item is deleted to force validation.
*      Bharath Varma              17-Mar-2022           TASK0726911 - Added logic to update validation status to blank when a parent line item's Discontinued flag is updated in the Amend scenario.
*      Bharath Varma              07-Apr-2022           INC0388579 - Converted future to Queueable in the method checkUCDiscLineItems
*      Nitin Reddy                24-june-2022          CMSI-68 Instrumentation
*      Nishan Shetty              30-June-2022          DCP-52703 - Implementing Group Sort Based on Material Code.
*      Avina                      07-July-2022          CMSI-51 - Added getWorkstream method to return the workstream
*      Saddam                     25-Aug-2022           DCP-54810 ,Added a Null check to checkUCDiscLineItems() ,Added condition inside aferdelete() to chcek Open offer agrmnt line items to stop passing the ids. 
*      Vivek                      31-Aug-2022           DCP-54529, added a method to check the record type for open offer agreement line items
*      Prem Ranjan                14-Sep-2022           DCP-56504,  @Description : Method to return True when it match few combination(as below) to make line status as updated.
*      Parthasarathy D            15-Sept-2022          DCP-56501 - Introduced validations for the Open Offer Agreement Line items.
*      Adithi Acharya             10-Jan-2023           CodescanFix [(APEX) Avoid unused local variable]
*    ------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ApttusAgreementLineItems extends ilib_SObjectDomain
{
    
    public static set<String> lineTypeForApprovals = new set<String>{'Price Group - Material', 'Price Group - Material Group 1'}; //DCP-32046 : Saswati
    Set<String> setAgreementNonChannelPartnerRecordType = new Set<String>{Label.AgreementRecordTypeMasterCustomer,Label.AgreementRecordTypeMasterService,Label.AgreementRecordTypeNegotiatedTermsAndConditions,Label.AgreementRecordTypeStandingQuote,Label.AgreementRecordTypeTender};
    Set<String> setSpecialProgramsSubtype = new Set<String>{Label.AgreementTypeReagentRental};//DCP-43353
    Map<String, Agreement_Condition_Table_Type_Mapping__mdt> strToAgrCondTableTypeMapping = new Map<String, Agreement_Condition_Table_Type_Mapping__mdt>();
    Map<String, Agreement_Condition_Table_Type_Mapping__mdt> strToAgrCondTableTypeMappingWithSubtype = new Map<String, Agreement_Condition_Table_Type_Mapping__mdt>();//dcp-43353
    Map<Id, Boolean> idToIsCPAgrementLineItem = new Map<Id, Boolean>();
    List<Apttus__APTS_Agreement__c> listAgreementsFromIntialize = new List<Apttus__APTS_Agreement__c>(); // Added by Saswati - 32046, SOQL Fixes
	public final static String DISCONTINUENO = 'No'; //INC0307963
    public static Boolean isDiscountLinesFutureCalled = false; //DCP-47006
    private static final String LOG_TITLE = 'ApttusAgreementLineItems';
    private static final String FAILED = 'Failed';
    private static Map<Id, RecordTypeInfo> rtMap; //DCP-54810
 

    @TestVisible
    private static Boolean useOldFrameworkWhileTesting = true;

    
    /*
     * public constructor for ApttusAgreementLineItems
     */
    public ApttusAgreementLineItems(List<Apttus__AgreementLineItem__c> sObjectList) {

        super(sObjectList);
        queryListOfAgreements(); // Added by Saswati - 32046, SOQL Fixes
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
         * return a new object ApttusAgreementLineItems
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApttusAgreementLineItems(sObjectList);
        }

    }
     /*
    *method to reduce Apttus Agreement Queries 
    Returns list of Agreement Records
    // Added by Saswati - 32046, SOQL Fixes
    */
    
    public void queryListOfAgreements() {
        ilib_logEvent.push(LOG_TITLE+'.queryListOfAgreements()');
        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>)records;
        set<Id> setAgreementIds = new set<Id>();
        for(Apttus__AgreementLineItem__c oALI:lstAgreementLineItem) {
            if(oALI.Apttus__AgreementId__c!=null) {
                setAgreementIds.add(oALI.Apttus__AgreementId__c);
                ilib_LogEvent.message('setAgreementIds : '+setAgreementIds);
            }
        }
        listAgreementsFromIntialize = new ApttusAgreementSelectors().selectAgreements(setAgreementIds);
        ilib_LogEvent.pop();
    }

    /*
    @Author : Vivek
    @Story : DCP-54529
    @Description : Method to check the record type of the open offer agreement line items.
    */
    private static Boolean checkAgrmntLIRcrdTypeOpenOffer(Apttus__AgreementLineItem__c ali){

        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        return idToRecordTypeInfo.get(ali.RecordTypeId).getDeveloperName()==System.label.AgreementLineItemRecordTypeDevNameOpenOffer;
    }

    /**
     * Adds default values to new records
     * Called during before insert event (e.g. set defaults before insert of proposal record)
     **/
    public override void onBeforeInsert() {

        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>)records;
        List<Apttus__AgreementLineItem__c> listALIExceptExisting = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> listALIForDates = new List<Apttus__AgreementLineItem__c>();
        Map<Id,Apttus__APTS_Agreement__c> mapOfAgrmnt = new Map<Id,Apttus__APTS_Agreement__c>(listAgreementsFromIntialize);
        Map<id,List<Apttus__AgreementLineItem__c>> agreementoLstALIWithMaterial = new Map<id,List<Apttus__AgreementLineItem__c>>();//DCP-56504

        for(Apttus__AgreementLineItem__c aLI :lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(aLI)) {// Added for DCP-54529
                Apttus__APTS_Agreement__c agrmnt = mapOfAgrmnt.get(aLi.Apttus__AgreementId__c);
                aLI.Sales_Org__c = agrmnt.Sales_Org__c;
                aLI.Distribution_Channel__c = agrmnt.Distribution_Channel__c;
                if(aLI.Apttus_CMConfig__StartDate__c == null || aLI.Apttus_CMConfig__EndDate__c == null) {
                    listALIForDates.add(aLI);
                }
                createMapWithAggToALIWithSameMaterial(aLI,agreementoLstALIWithMaterial); //DCP-56504
                continue;
            }
            if(!String.isblank(aLI.Line_Type_1__c)) {
                aLI.Line_Type__c = aLI.Line_Type_1__c;
                ilib_LogEvent.message('aLI.Line_Type__c : '+aLI.Line_Type__c);
            }
            System.debug('*** Checking Line Status  in before Insert - '+ aLI.Apttus_CMConfig__LineStatus__c);
            if(aLI.Apttus_CMConfig__LineStatus__c!=Label.AgreementLineItemLineStatusExisting) {
                listALIExceptExisting.add(aLI);
            }
            System.debug('*** Checking Start date  in before Insert - '+ aLI.Apttus_CMConfig__StartDate__c);
            System.debug('*** Checking End date  in before Insert - '+ aLI.Apttus_CMConfig__EndDate__c);
            if(aLI.Apttus_CMConfig__StartDate__c == null || aLI.Apttus_CMConfig__EndDate__c == null) {
                listALIForDates.add(aLI);
            }
        }
        //DCP-56504
        periodOverlapCheckForMSA(lstAgreementLineItem, agreementoLstALIWithMaterial);
        //33720
        if(!listALIExceptExisting.isEmpty()) {
            validateApprovalStatus(listALIExceptExisting);
        }
        updateConditionTypeTableData(lstAgreementLineItem);
        validateMaterialNumber();
        validateERPNumber();
        setAccountLookup(records);
        populateMaterialGroup1Desc(lstAgreementLineItem);
        //DCP -32572 : Added to populate product.
        populateProduct(lstAgreementLineItem);
        populateStartAndEndDate(listALIForDates);
        
        
        // DGP-103, DGP-416 : To populate Discount Guidance Field Values
        populateDiscountGridGroupForMaterialGroupLines(lstAgreementLineItem);
        
        DiscountGuidancePopulatorForCLM populator = new DiscountGuidancePopulatorForCLM();
        populator.deriveFieldValuesForDiscountGuidance(lstAgreementLineItem, null);
        

        // TASK0700485
        checkDiscountsOnAmendedAgr(lstAgreementLineItem);        
        //// DCP-50961 : NEW APPROVALS start
        Boolean forceOldFramework = System.Test.isRunningTest() && useOldFrameworkWhileTesting;
        if (Feature.isOn('SalesCLMApprovalsPipeline') && !forceOldFramework)
        {
            if(!listALIExceptExisting.isEmpty()) {
                Approvals.AgreementLineInputs approvalInputs = new Approvals.AgreementLineInputs(listALIExceptExisting, new Map<Id,Apttus__APTS_Agreement__c>(listAgreementsFromIntialize));
                IApprovalsAPI approvals = ApprovalsService.init(approvalInputs);
                approvals.processAgreementLines();
            }
        }
        else
        {
            if(!listALIExceptExisting.isEmpty()) {
                ApttusAgreementsApprovals.setApprovals(listALIExceptExisting,listAgreementsFromIntialize);
            }
        }

        //START DCP-52703
        setAgreementLineItemPriority(lstAgreementLineItem);
        //END DCP-52703
    }
    
    /**
    *  @author      : KD
    *  @description : Method to blank out Validation status if dates are updated post approval and Pre-activation
    *  @param       : Line item list
    *  @return      : void
    */
    public void updateAgreementValidationStatus(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Map<Id, sObject> existingRecords,Set<Id> setAgrId) {
        ilib_LogEvent.push(LOG_TITLE + '.updateAgreementValidationStatus()');
        ilib_LogEvent.info('existingRecords : '+(existingRecords != Null ? String.valueof(existingRecords.keySet()):'Null'));
        ilib_LogEvent.info('setAgrId : '+setAgrId);
        List<Apttus__APTS_Agreement__c> lstAgreementToUpdate = new List<Apttus__APTS_Agreement__c>();
        Boolean boolToUpdate = false;
        ilib_LogEvent.info('boolToUpdate : '+boolToUpdate);
        List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(setAgrId);
        for(Apttus__APTS_Agreement__c agr:lstAgreement) {
            boolToUpdate = false;
            
            if(agr.Apttus__Status_Category__c != Label.UI_Label_Agreement_Status_In_Effect) {

                // TASK0720220 - Added this logic to update Validation status as blank when Agr lines get deleted
                Boolean boolBlankOutValidationStatus = String.isNotBlank(agr.Validation_Status__c) && (agr.Validation_Status__c.contains(Label.Completed) || agr.Validation_Status__c.contains(FAILED));
                boolToUpdate = existingRecords == null && boolBlankOutValidationStatus;
                // TASK0720220 - Added this check to bypass this during deletion of line items
                if(existingRecords != null) {
                    for(Apttus__AgreementLineItem__c objNewAgl : lstAgreementLineItem) {
                        Apttus__AgreementLineItem__c oldagl = (Apttus__AgreementLineItem__c)(existingRecords.get(objNewAgl.Id));
                        ilib_LogEvent.fine('oldagl : '+oldagl);
                        // Blank out Validation Status when one of the below two conditions is true
                        boolToUpdate = (oldagl.get('Apttus_CMConfig__StartDate__c') != objNewAgl.get('Apttus_CMConfig__StartDate__c') || oldagl.get('Apttus_CMConfig__EndDate__c') != objNewAgl.get('Apttus_CMConfig__EndDate__c')) ||
                                        // TASK0726911 - Added this check to blank out the status when the user updates the Discontinued flag on the AGL copied from the Parent in the Amend scenario
                                        (boolBlankOutValidationStatus && objNewAgl.get('Apttus_CMConfig__LineStatus__c') == Label.AgreementLineItemLineStatusUpdated && oldagl.get('Discontinued__c') != objNewAgl.get('Discontinued__c'));
                    }
                }

                if(boolToUpdate) {
                    agr.Validation_Status__c = '';
                    lstAgreementToUpdate.add(agr);
                }
           

            }
        }

        if(!lstAgreementToUpdate.isEmpty()) {
            update lstAgreementToUpdate;
        }

        ilib_LogEvent.pop();

    }
      /*
    @author      : Saswati
    @description : method to populate Start date and end date on insertion of line items 
    @Param       : Line Item List 
    @return      : void
    */
    public void populateStartAndEndDate(List<Apttus__AgreementLineItem__c> listALI) {
        ilib_LogEvent.push(LOG_TITLE+'.populateStartAndEndDate()');
        System.debug('@@@ Inside populate start and end date');
        set<Id> setAgreementId = new set<Id>();
        for(Apttus__AgreementLineItem__c oALI: listALI) {
            if(oALI.Apttus__AgreementId__c!=null) {
                setAgreementId.add(oALI.Apttus__AgreementId__c);
            }
        }
        List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(setAgreementId);
        if(!lstAgreement.isEmpty()) {
            for(Apttus__APTS_Agreement__c oAgreement: lstAgreement) {
                for(Apttus__AgreementLineItem__c oALI: listALI) {
                    if(oALI.Apttus__AgreementId__c==oAgreement.Id && oAgreement.Apttus__Contract_Start_Date__c!= null && oALI.Apttus_CMConfig__StartDate__c==null) {
                        System.debug('@@@ Inside populate start and end date - if check start date');
                        oALI.Apttus_CMConfig__StartDate__c = oAgreement.Apttus__Contract_Start_Date__c;
                    }
                    if(oALI.Apttus__AgreementId__c==oAgreement.Id && oAgreement.Apttus__Contract_End_Date__c!= null && oALI.Apttus_CMConfig__EndDate__c==null) {
                        System.debug('@@@ Inside populate start and end date - if check end date');
                        oAli.Apttus_CMConfig__EndDate__c = oAgreement.Apttus__Contract_End_Date__c;
                    }

                }
            }
        
        }
        
        ilib_LogEvent.pop();
    }
    /*
     * Called during before update event
     **/

    public override void onBeforeUpdate(Map<Id, sObject> existingRecords) {
        // Id userId = UserInfo.getUserId();
        // Set<Id> setUserIds = new Set<Id>();
        // setUserIds.add(userId);
        // List<User> lstuserdetails = new UsersSelector().selectByUserId(setUserIds);
        // String ProfileName =lstuserdetails[0].Profile.Name;
        if (Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) {
            return;
        }
        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>) records;
        Map<String, List<Apttus__AgreementLineItem__c>> updatedlstvalues = updatelstValues(lstAgreementLineItem, existingRecords);

        List<Apttus__AgreementLineItem__c> lstAgreementLineItemForMaterialGroupDesc = updatedlstvalues.get('lstAgreementLineItemForMaterialGroupDesc');
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemForMaterialNumber = updatedlstvalues.get('lstAgreementLineItemForMaterialNumber');
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemProductRemoval = updatedlstvalues.get('lstAgreementLineItemProductRemoval');
       
        If(!Profiles.getAllAdminProfileIds().contains(Userinfo.getProfileId())
        &&!Profiles.getSalesIntegrationProfileIds().contains(Userinfo.getProfileId()))
        {
            populateLineStatusOnAGLIonUpdation(lstAgreementLineItem,existingRecords);
        }
        checkupdatefieldsonValidateCompleted(lstAgreementLineItem,existingRecords);
        updateConditionTypeTableData(lstAgreementLineItem);
       //validateMaterialNumber(); // Material Number check
        setAccountLookup(records);

        if(!lstAgreementLineItemForMaterialGroupDesc.isEmpty()) {
            populateMaterialGroup1Desc(lstAgreementLineItemForMaterialGroupDesc);
        }

        //DCP - 32572: Added to populate product.
        if(!lstAgreementLineItemForMaterialNumber.isEmpty()) {
            populateProduct(lstAgreementLineItemForMaterialNumber);
        }
        if(!lstAgreementLineItemProductRemoval.isEmpty()) {
            depopulateProduct(lstAgreementLineItemProductRemoval);
        }
        
        
        // DGP-103, DGP-416 : To populate Discount Guidance Field Values
        populateDiscountGridGroupForMaterialGroupLines(lstAgreementLineItem);
        
        if(!Profiles.getAdminProfileId().contains(UserInfo.getProfileId())
           		&& !Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) {
            DiscountGuidancePopulatorForCLM populator = new DiscountGuidancePopulatorForCLM();
            populator.deriveFieldValuesForDiscountGuidance(lstAgreementLineItem, (Map<Id, Apttus__AgreementLineItem__c>) existingRecords);
        }
        
        
        //DCP-32046 : Added change to restrict approval call during update
        restrictApprovalCallDuringUpdate(lstAgreementLineItem, existingRecords);        

        //START DCP-52703
        setAgreementLineItemPriority(lstAgreementLineItem);
        //END DCP-52703
    }

    /*
     * Update List items based on logic *Code scan fix*
     */
    public Map<String, List<Apttus__AgreementLineItem__c>> updatelstValues(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, Map<Id, sObject> existingRecords) {
        ilib_LogEvent.push(LOG_TITLE+'.updatelstValues()');
        Map<String, List<Apttus__AgreementLineItem__c>> mapToReturn = new Map<String, List<Apttus__AgreementLineItem__c>>();
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemForMaterialGroupDesc = New List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemForMaterialNumber = New List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemProductRemoval = New List<Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c aLI :lstAgreementLineItem) {
            Apttus__AgreementLineItem__c oAgrLi = (Apttus__AgreementLineItem__c)(existingRecords.get(aLI.Id));
            ilib_LogEvent.message('oAgrLi : '+oAgrLi);
            if(!String.isblank(aLI.Line_Type_1__c)) {
                aLI.Line_Type__c = aLI.Line_Type_1__c;
                ilib_LogEvent.message('aLI.Line_Type__c : '+aLI.Line_Type__c);
            }
            if(aLI.Material_Group_1__c != oAgrLi.Material_Group_1__c) {
                lstAgreementLineItemForMaterialGroupDesc.add(aLI);
            }
            //DCP- 32572
            if(String.isNotBlank(aLI.Material_Number__c) && aLI.Material_Number__c != oAgrLi.Material_Number__c) {
                lstAgreementLineItemForMaterialNumber.add(aLI);
            }
            if(String.isNotBlank(oAgrLi.Material_Number__c) && String.isBlank(aLI.Material_Number__c)) {
                lstAgreementLineItemProductRemoval.add(aLI);
            }
			//INC0307963
            if(String.isBlank(aLI.Discontinued__c))
                aLI.Discontinued__c = DISCONTINUENO;
                ilib_LogEvent.message('aLI.Discontinued__c : '+aLI.Discontinued__c);
        }
        mapToReturn.put('lstAgreementLineItemForMaterialGroupDesc', lstAgreementLineItemForMaterialGroupDesc);
        mapToReturn.put('lstAgreementLineItemForMaterialNumber', lstAgreementLineItemForMaterialNumber);
        mapToReturn.put('lstAgreementLineItemProductRemoval', lstAgreementLineItemProductRemoval);
        ilib_LogEvent.info('mapToReturn : ' + (mapToReturn != Null ? String.valueof(mapToReturn.keySet()):'Null'));
        ilib_LogEvent.pop();
        return mapToReturn;

    }

    /*
     * //DCP-32046 : Added change to restrict approval call during update
     */
    public void restrictApprovalCallDuringUpdate(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, Map<Id, sObject> existingRecords) {
        // List<List<Apttus__AgreementLineItem__c>> lstToReturn = new List<List<Apttus__AgreementLineItem__c>>();
        ilib_LogEvent.push(LOG_TITLE+'.restrictApprovalCallDuringUpdate()');
        if (!lstAgreementLineItem.isEmpty()) {
            Map<Id, Apttus__AgreementLineItem__c> idToOldAgreementLineItem = (Map<Id,Apttus__AgreementLineItem__c>)existingRecords;
            Map<String, List<Apttus__AgreementLineItem__c>> segregatedLineItems = segregateLineItems(lstAgreementLineItem, idToOldAgreementLineItem);

            List<Apttus__AgreementLineItem__c> lstNewALI = segregatedLineItems.get('lstNewALI');
            List<Apttus__AgreementLineItem__c> listValidateERP = segregatedLineItems.get('listValidateERP');
            List<Apttus__AgreementLineItem__c> listValidateMaterialNumber = segregatedLineItems.get('listValidateMaterialNumber');
            List<Apttus__AgreementLineItem__c> listALIOnDateChange = segregatedLineItems.get('listALIOnDateChange');
            
            //List<Apttus__APTS_Agreement__c> lstAgreements = new ApttusAgreementSelectors().selectAgreements(setAgreement);
            validationsAndNextSteps(lstNewALI, listValidateERP, listValidateMaterialNumber, listALIOnDateChange);
        }  
        ilib_LogEvent.pop();
    }

    /* 
     * Code scan fixes
     */ 
    public Map<String, List<Apttus__AgreementLineItem__c>> segregateLineItems(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, Map<Id, Apttus__AgreementLineItem__c> idToOldAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.segregateLineItems()');
        Map<String, List<Apttus__AgreementLineItem__c>> mapToReturn = new Map<String, List<Apttus__AgreementLineItem__c>>();
        List<Apttus__AgreementLineItem__c> lstNewALI = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> listValidateERP = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> listValidateMaterialNumber = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> listALIOnDateChange = new List<Apttus__AgreementLineItem__c>();
        Boolean checkCond = false;
        for(Apttus__AgreementLineItem__c oALI : lstAgreementLineItem) {
            //if(checkAgrmntLIRcrdTypeOpenOffer(oALI)){continue;} // Added for DCP-54529
            checkCond = false;
            //54529-added check for Open Offer
            if((oALI.Customer_ERP_Number__c!= idToOldAgreementLineItem.get(oALI.id).Customer_ERP_Number__c || oALI.Ultimate_Consignee_ERP_Number__c!=idToOldAgreementLineItem.get(oALI.id).Ultimate_Consignee_ERP_Number__c ) && !checkAgrmntLIRcrdTypeOpenOffer(oALI)) {
                listValidateERP.add(oALI);
            }
            // DCP-56501 Updated the below condition to check Open Offer ALI.
            if(oALI.Material_Number__c!= idToOldAgreementLineItem.get(oALI.id).Material_Number__c || (checkAgrmntLIRcrdTypeOpenOffer(oALI) && oALI.Customer_Election__c != idToOldAgreementLineItem.get(oALI.id).Customer_Election__c)) {
                listValidateMaterialNumber.add(oALI);
            }

            //54529-added check for Open Offer
            if(oALI.Apttus_CMConfig__StartDate__c==null || 
                oALI.Apttus_CMConfig__EndDate__c==null || 
                oALI.Apttus_CMConfig__StartDate__c != idToOldAgreementLineItem.get(oALI.id).Apttus_CMConfig__StartDate__c || 
                oALI.Apttus_CMConfig__EndDate__c != idToOldAgreementLineItem.get(oALI.id).Apttus_CMConfig__EndDate__c) {
                listALIOnDateChange.add(oALI);
                checkCond = true;
            }
            
            /*
             * Due to code scan issue "Nested IF", moved the if statement outside the nested if
             */
            if( checkCond && oALI.Apttus_CMConfig__LineStatus__c!=Label.AgreementLineItemLineStatusExisting &&
                !Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId()) && 
                !Profiles.getAdminProfileId().contains(UserInfo.getProfileId())) {
                lstNewALI.add(oALI); // enhancement changes
            } 
            if(oALI.Apttus_CMConfig__LineStatus__c!=Label.AgreementLineItemLineStatusExisting && (oALI.Discount__c != idToOldAgreementLineItem.get(oALI.id).Discount__c || oALI.Discontinued__c != idToOldAgreementLineItem.get(oALI.id).Discontinued__c || oALI.Line_Type__c != idToOldAgreementLineItem.get(oALI.id).Line_Type__c ||oALI.Line_Type_1__c != idToOldAgreementLineItem.get(oALI.id).Line_Type_1__c ||oALI.Material_Group_1__c != idToOldAgreementLineItem.get(oALI.id).Material_Group_1__c ||oALI.Material_Number__c != idToOldAgreementLineItem.get(oALI.id).Material_Number__c ||oALI.Discount_Type__c != idToOldAgreementLineItem.get(oALI.id).Discount_Type__c||oALI.Sales_Org__c != idToOldAgreementLineItem.get(oALI.id).Sales_Org__c ||oALI.Distribution_Channel__c != idToOldAgreementLineItem.get(oALI.id).Distribution_Channel__c ||oALI.CurrencyIsoCode != idToOldAgreementLineItem.get(oALI.id).CurrencyIsoCode ||oALI.Customer_ERP_Number__c != idToOldAgreementLineItem.get(oALI.id).Customer_ERP_Number__c) && !checkAgrmntLIRcrdTypeOpenOffer(oALI)) {
                lstNewALI.add(oALI);
            }
        }
        mapToReturn.put('lstNewALI', lstNewALI);
        mapToReturn.put('listValidateERP', listValidateERP);
        mapToReturn.put('listValidateMaterialNumber', listValidateMaterialNumber);
        mapToReturn.put('listALIOnDateChange', listALIOnDateChange);
        ilib_LogEvent.info('mapToReturn : ' + (mapToReturn != Null ? String.valueof(mapToReturn.keySet()):'Null'));
        ilib_LogEvent.pop();
        return mapToReturn;
        
    }

    /*
     * *Code Scan fix* to reduce size of onBeforeUpdate
     */
    public void validationsAndNextSteps(List<Apttus__AgreementLineItem__c> lstNewALI, List<Apttus__AgreementLineItem__c> listValidateERP, List<Apttus__AgreementLineItem__c> listValidateMaterialNumber, List<Apttus__AgreementLineItem__c> listALIOnDateChange) {
        ilib_LogEvent.push(LOG_TITLE+'.validationsAndNextSteps()');
        if(!listALIOnDateChange.isEmpty()) {
            populateStartAndEndDate(listALIOnDateChange);
        }

        if(!listValidateMaterialNumber.isEmpty()) {
            validateMaterialNumber(); 
        }      

        if(!listValidateERP.isEmpty()) {
            validateERPNumber();
        }

        Boolean forceOldFramework = System.Test.isRunningTest() && useOldFrameworkWhileTesting;
        if (Feature.isOn('SalesCLMApprovalsPipeline') && !forceOldFramework)
        {
            if(!lstNewALI.isEmpty()) {
                Approvals.AgreementLineInputs approvalInputs = new Approvals.AgreementLineInputs(lstNewALI, new Map<Id,Apttus__APTS_Agreement__c>(listAgreementsFromIntialize));
                IApprovalsAPI approvals = ApprovalsService.init(approvalInputs);
                approvals.processAgreementLines();
            }
        }
        else
        {
            if(!lstNewALI.isEmpty()) {
                ApttusAgreementsApprovals.setApprovals(lstNewALI,listAgreementsFromIntialize);
            }
        }
        ilib_LogEvent.pop();
    }


    /*
     * Called before delete event
     **/
    public override void onBeforeDelete() {
        system.debug('Inside on before delete');
        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>) records;
        validateLineStatusonDeletionAGLI(lstAgreementLineItem);
        validateApprovalStatus(lstAgreementLineItem);
    }

    /**
    *  @author      : B Kamini
    *  @description : Method to validate line status before deleting line items
    *  @param       : Line item list
    *  @return      : void
    */
    public void validateLineStatusonDeletionAGLI(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.validateLineStatusonDeletionAGLI()');
        for(Apttus__AgreementLineItem__c oAgrLI :lstAgreementLineItem) {
            // Added bug fix by Satya for DCP-36652
            Boolean isAgreementAmendedOrRenewed = checkForAgreementRenewalOrAmendment(oAgrLI);
            if(!Profiles.getAdminProfileId().contains(UserInfo.getProfileId()) && oAgrLI.Apttus_CMConfig__LineStatus__c!=NULL && (oAgrLI.Apttus_CMConfig__LineStatus__c==Label.AgreementLineItemLineStatusExisting||oAgrLI.Apttus_CMConfig__LineStatus__c==Label.AgreementLineItemLineStatusUpdated) && !isAgreementAmendedOrRenewed) {
                oAgrLI.adderror(Label.UI_AgLIValidationOnDelete);
            }
            // DCP-56501 Added the condition for the Open Offer Agreement Line Items.
            Boolean boolBypassValidationProfiles = Profiles.getAdminProfileId().contains(UserInfo.getProfileId()) || Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId());
            if(!boolBypassValidationProfiles && oAgrLI.Apttus_CMConfig__LineStatus__c!=NULL && (oAgrLI.Apttus_CMConfig__LineStatus__c==Label.AgreementLineItemLineStatusExisting||oAgrLI.Apttus_CMConfig__LineStatus__c==Label.AgreementLineItemLineStatusUpdated) && !isAgreementAmendedOrRenewed && checkAgrmntLIRcrdTypeOpenOffer(oAgrLI)) {
                oAgrLI.adderror(Label.ErrorMessageForOpenOfferDeletionValidation);
            }
            ilib_logEvent.message('oAgrLI : '+oAgrLI);
            
        }
        ilib_LogEvent.pop();

    }  
    
    /**
    *  @author      : B Kamini
    *  @description : Method to check if Agreement's Validation status is Completed/Is in progress
    *  @param       : Line item list
    *  @return      : void
    */
   public void checkupdatefieldsonValidateCompleted(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Map<Id, sObject> existingRecords) {
    ilib_LogEvent.push(LOG_TITLE+'.checkupdatefieldsonValidateCompleted()');
    Map <String, Schema.SObjectField> fieldMap = Schema.SObjectType.Apttus__AgreementLineItem__c.fields.getMap();
    list<string> lstFieldstoCheck = new list<string>();
    // Set<ID> setAgreementID = new Set<ID>();
    //Removed set Agreements, assigning static list value to list of agreements. - Saswati
    List<Apttus__APTS_Agreement__c> lstAgreement = listAgreementsFromIntialize; // Added by Saswati - 32046, SOQL Fixes
    Id userId = UserInfo.getUserId();
    Set<Id> setUserIds = new Set<Id>();
    setUserIds.add(userId);
    ilib_LogEvent.info('setUserIds : '+setUserIds);
    List<User> lstuserdetails = new UsersSelector().selectByUserId(setUserIds);
    String profileName =lstuserdetails[0].Profile.Name;
    ilib_LogEvent.info('profileName : '+profileName);
    for(Schema.SObjectField sfield : fieldMap.Values()) {
        schema.describefieldresult dfield = sfield.getDescribe();
        ilib_logEvent.message('dfield : '+dfield);
        if(dfield.isUpdateable() && dfield.getname()!= 'Apttus_CMConfig__StartDate__c' && dfield.getname()!= 'Apttus_CMConfig__EndDate__c' ) {
            lstFieldstoCheck.add(dfield.getname());
        }
    }
    ilib_LogEvent.info('lstFieldstoCheck : '+lstFieldstoCheck);
    for(Apttus__APTS_Agreement__c agr:lstAgreement) {
        if(agr.Validation_Status__c==Label.UI_Agreement_Validation_Status_Completed.replace('{0}',Label.AgreementActionValidate ) || agr.Validation_Status__c==label.AgreementValidationStatusInProgress.replace('{0}',Label.AgreementActionValidate) || agr.Apttus_Approval__Approval_Status__c == Label.AgreementApprovalStatusApproved) {
            for(Apttus__AgreementLineItem__c objNewAgl : lstAgreementLineItem) {
                Apttus__AgreementLineItem__c oldagl = (Apttus__AgreementLineItem__c)(existingRecords.get(objNewAgl.Id));
                for(String  fieldname: lstFieldstoCheck) {
                    if(profileName!=Label.System_Administrator && profileName!=Label.Integration_Sales_SNAP_Profile && oldagl.get(fieldname) != objNewAgl.get(fieldname) && !agr.Is_Auto_Approved__c
                    && !(objNewAgl.Apttus_Approval__Approval_Status__c != oldagl.Apttus_Approval__Approval_Status__c
                    &&objNewAgl.Apttus_Approval__Approval_Status__c==Label.AgreementApprovalStatusApproved) &&
                    (agr.Apttus__Status_Category__c == Label.AgreementStatusCategoryInEffect ||
                    agr.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Amended ||
                    agr.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Terminated)
                    ) {
                        objNewAgl.adderror(Label.UI_AgreementLineItemsCannotBeEditedAfterValidateCompletedOrValidateInProgress);
                    }
                }
            }
        }
    }
    ilib_LogEvent.pop();
}
/*
    @Author : Saddam
    @Story : DCP-54810
    @Description : Method to get record type map.
    */
    public static Map<Id, RecordTypeInfo> getRecordTypeMap()
    {
        if (rtMap == null) { rtMap = Apttus__AgreementLineItem__c.sObjectType.getDescribe().getRecordTypeInfosById(); }
        return rtMap;
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : Method to update condition fields on line
    *  @param       : Line item list
    *  @return      : void
    */

    public void updateConditionTypeTableData(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.updateConditionTypeTableData()');
        Set<Id> setAgreementId = new Set<Id>();
        Map<id,List<Apttus__AgreementLineItem__c>> mapAgreementidToLines = new Map<id,List<Apttus__AgreementLineItem__c>>();
        Map<id,Apttus__APTS_Agreement__c>  mapAgreementidToAgrObj = new   Map<id,Apttus__APTS_Agreement__c>();
        Set<String> setLineType = new Set<String>();
        Set<String> setDiscountType = new Set<String>();
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();

        for(Apttus__AgreementLineItem__c objAgrln : lstAgreementLineItem) {
            //Dcp-54810 Strats Open offer.
            string  strAgrmntlineitemRecordType = idToRecordTypeInfo.get(objAgrln.RecordTypeId).getDeveloperName(); 
            if(strAgrmntlineitemRecordType==System.label.AgreementLineItemRecordTypeDevNameOpenOffer){continue;} 
            //Dcp-54810 ends
            setAgreementId.add(objAgrln.Apttus__AgreementId__c);
            if(!mapAgreementidToLines.containskey(objAgrln.Apttus__AgreementId__c)) {
                mapAgreementidToLines.put(objAgrln.Apttus__AgreementId__c, new List<Apttus__AgreementLineItem__c>());
            }
            mapAgreementidToLines.get(objAgrln.Apttus__AgreementId__c).add(objAgrln);
            setLineType.add(objAgrln.Line_Type__c);
            setDiscountType.add(objAgrln.Discount_Type__c);
        }
        ilib_LogEvent.info('setAgreementId : '+setAgreementId);
        if(mapAgreementidToLines.isEmpty()) {
            ilib_LogEvent.pop();
            return;}
        List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(mapAgreementidToLines.keyset());
        for(Apttus__APTS_Agreement__c objAgreement : lstAgreement) {
            mapAgreementidToAgrObj.put(objAgreement.id,objAgreement);
        }
        List<Agreement_Condition_Table_Type_Mapping__mdt> lstAgrCondTableTypeMapping = new AgreementConditionMappingSelector().getAgreementConditionMapping(setLineType,setDiscountType);
        for(Agreement_Condition_Table_Type_Mapping__mdt objAgrCondTableTypeMapping : lstAgrCondTableTypeMapping) {
            if(objAgrCondTableTypeMapping.Subtype__c != null && objAgrCondTableTypeMapping.Subtype__c != '' && !strToAgrCondTableTypeMappingWithSubtype.containsKey(objAgrCondTableTypeMapping.Line_Type__c+objAgrCondTableTypeMapping.Discount_Type__c+objAgrCondTableTypeMapping.Record_Type__c+objAgrCondTableTypeMapping.Subtype__c)){//DCP-43353
                strToAgrCondTableTypeMappingWithSubtype.put(objAgrCondTableTypeMapping.Line_Type__c+objAgrCondTableTypeMapping.Discount_Type__c+objAgrCondTableTypeMapping.Record_Type__c+objAgrCondTableTypeMapping.Subtype__c,objAgrCondTableTypeMapping);
            }
            else if(!strToAgrCondTableTypeMapping.containsKey(objAgrCondTableTypeMapping.Line_Type__c+objAgrCondTableTypeMapping.Discount_Type__c+objAgrCondTableTypeMapping.Record_Type__c)) {
                strToAgrCondTableTypeMapping.put(objAgrCondTableTypeMapping.Line_Type__c+objAgrCondTableTypeMapping.Discount_Type__c+objAgrCondTableTypeMapping.Record_Type__c,objAgrCondTableTypeMapping);
            }
        }
        updateConditionTypeTable(lstAgreementLineItem,strToAgrCondTableTypeMapping,strToAgrCondTableTypeMappingWithSubtype,mapAgreementidToAgrObj);
        ilib_LogEvent.pop();
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : Method to update condition fields from metadata
    *  @param       : Line item list,List of agreement, key map
    *  @return      : void
    */
    public void updateConditionTypeTable(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Map<String, Agreement_Condition_Table_Type_Mapping__mdt> strToAgrCondTableTypeMapping,Map<String, Agreement_Condition_Table_Type_Mapping__mdt> strToAgrCondTableTypeMappingWithSubtype,Map<id,Apttus__APTS_Agreement__c>  mapAgreementidToAgrObj) {
        ilib_LogEvent.push(LOG_TITLE+'.updateConditionTypeTable()');
        ilib_LogEvent.info('strToAgrCondTableTypeMapping : '+(strToAgrCondTableTypeMapping != Null ? String.valueof(strToAgrCondTableTypeMapping.keySet()):'Null'));
        ilib_LogEvent.info('strToAgrCondTableTypeMappingWithSubtype : '+(strToAgrCondTableTypeMappingWithSubtype != Null ? String.valueof(strToAgrCondTableTypeMappingWithSubtype.keySet()):'Null'));
        ilib_LogEvent.info('mapAgreementidToAgrObj : ' +(mapAgreementidToAgrObj != Null ? String.valueof(mapAgreementidToAgrObj.keySet()):'Null'));
        String strAgreementRecordType = '';
        String strKey = '';
        String strKeyWithSubtype = '';
        System.debug('strToAgrCondTableTypeMapping::::'+strToAgrCondTableTypeMapping);
        System.debug('strToAgrCondTableTypeMappingWithSubtype::::'+strToAgrCondTableTypeMappingWithSubtype);
        for(Apttus__AgreementLineItem__c objAgreementLineItem : lstAgreementLineItem) {
            if(objAgreementLineItem.Line_Type__c == Label.AgreementLineItemLineTypeIsQuota) {
                objAgreementLineItem.Condition_Table__c='';
                objAgreementLineItem.Condition_Type__c='';
                ilib_LogEvent.message('objAgreementLineItem.Condition_Table__c : '+objAgreementLineItem.Condition_Table__c);
                ilib_LogEvent.message('objAgreementLineItem.Condition_Type__c : '+objAgreementLineItem.Condition_Type__c);  
            } else {//DCP-43353
                Map<Id, RecordTypeInfo> agLIRecordTypeinfo = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
                Apttus__APTS_Agreement__c objAgr = mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c);
                ilib_LogEvent.message('objAgr : '+objAgr);
                strAgreementRecordType = agLIRecordTypeinfo.get(objAgr.RecordTypeId).getName();
                if(strAgreementRecordType == System.label.AgreementRecordTypeNameOpenOffer){continue;} //Added for DCP-54529
                ilib_LogEvent.message('strAgreementRecordType : '+strAgreementRecordType);
                strKey = createKeyForMetadataMap(objAgreementLineItem,strAgreementRecordType);
                ilib_LogEvent.message('strKey : '+strKey);
                strKeyWithSubtype = createKeyForMetadataMapWithSubtype(objAgreementLineItem,strAgreementRecordType,mapAgreementidToAgrObj);
                ilib_LogEvent.message('strKeyWithSubtype : '+strKeyWithSubtype);
                System.debug('Record Type detected Else Block'+strAgreementRecordType+' \t key value: '+ strKey);
                System.debug('strKeyWithSubtype:::::::: '+ strKeyWithSubtype);
                if((!strToAgrCondTableTypeMapping.containsKey(strKey) && !strToAgrCondTableTypeMappingWithSubtype.containsKey(strKeyWithSubtype)) || (strAgreementRecordType == Label.AgreementLIRecordTypeSpecialPrograms && !setSpecialProgramsSubtype.contains(String.valueOf(mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c).Apttus__Subtype__c)))){
                    objAgreementLineItem.addError(Label.UI_ErrorMessage_AgrLineItem_FPMaintenanceError);
                }
                else if(strToAgrCondTableTypeMappingWithSubtype.containsKey(strKeyWithSubtype)){
                    objAgreementLineItem.Condition_Table__c = strToAgrCondTableTypeMappingWithSubtype.get(strKeyWithSubtype).Condition_Table__c ;
                    objAgreementLineItem.Condition_Type__c = strToAgrCondTableTypeMappingWithSubtype.get(strKeyWithSubtype).Condition_Type__c;
                    ilib_LogEvent.message('objAgreementLineItem.Condition_Table__c : '+objAgreementLineItem.Condition_Table__c);
                    ilib_LogEvent.message('objAgreementLineItem.Condition_Type__c : '+objAgreementLineItem.Condition_Type__c); 
                }
                else{
                    objAgreementLineItem.Condition_Table__c = strToAgrCondTableTypeMapping.get(strKey).Condition_Table__c ;
                    objAgreementLineItem.Condition_Type__c = strToAgrCondTableTypeMapping.get(strKey).Condition_Type__c;
                    ilib_LogEvent.message('objAgreementLineItem.Condition_Table__c : '+objAgreementLineItem.Condition_Table__c);
                    ilib_LogEvent.message('objAgreementLineItem.Condition_Type__c : '+objAgreementLineItem.Condition_Type__c); 
                }
                
                if(strAgreementRecordType == Label.AgreementLIRecordTypeSpecialPrograms && mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c).Apttus__Subtype__c != null && String.valueOf(mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c).Apttus__Subtype__c) == Label.AgreementTypeReagentRental){
                    objAgreementLineItem.Customer_Condition_Group_4__c = Label.AgreementLIConGrp4ReagentRental;
                    ilib_LogEvent.message('objAgreementLineItem.Customer_Condition_Group_4__c : '+objAgreementLineItem.Customer_Condition_Group_4__c);
                }
            }
        }
        ilib_LogEvent.pop();
    }
    
    
    /**
    *  @author      : Kushagra Desai
    *  @description : Method to create metadata key
    *  @param       : agreement record, line item record,recordtype
    *  @return      : Key string
    */
    private String createKeyForMetadataMap(Apttus__AgreementLineItem__c objAgreementLineItem,String strAgreementRecordType) {
        ilib_LogEvent.message('objAgreementLineItem : '+objAgreementLineItem);
        ilib_LogEvent.message('strAgreementRecordType : '+strAgreementRecordType);
        String key = '';
        ilib_LogEvent.message('key : '+key);
        String strLineType = String.valueOf(objAgreementLineItem.Line_Type__c);
        ilib_LogEvent.message('strLineType : '+strLineType);
        String strDiscountType = String.valueOf(objAgreementLineItem.Discount_Type__c);
        ilib_LogEvent.message('strDiscountType : '+strDiscountType);
        key = strLineType+ strDiscountType + strAgreementRecordType;
        ilib_LogEvent.message('key : '+key);
        return key;
    }
    
    /**
    *  @author      : Anish Pathak
    *  @description : Method to create metadata key -DCP-43353
    *  @param       : agreement record, line item record,recordtype
    *  @return      : Key string
    */
    private String createKeyForMetadataMapWithSubtype(Apttus__AgreementLineItem__c objAgreementLineItem,String strAgreementRecordType,Map<id,Apttus__APTS_Agreement__c>  mapAgreementidToAgrObj) {
        
        ilib_LogEvent.message('objAgreementLineItem : '+objAgreementLineItem);
        ilib_LogEvent.message('strAgreementRecordType : '+strAgreementRecordType);
        ilib_LogEvent.message('mapAgreementidToAgrObj : ' + (mapAgreementidToAgrObj != Null ? String.valueof(mapAgreementidToAgrObj.keySet()):'Null'));
        String keyWithSubtype = '';
        ilib_LogEvent.message('keyWithSubtype : '+keyWithSubtype);
        String strLineType = String.valueOf(objAgreementLineItem.Line_Type__c);
        ilib_LogEvent.message('strLineType : '+strLineType);
        String strDiscountType = String.valueOf(objAgreementLineItem.Discount_Type__c);
        ilib_LogEvent.message('strDiscountType : '+strDiscountType);
        keyWithSubtype = strLineType+ strDiscountType + strAgreementRecordType;
        ilib_LogEvent.message('keyWithSubtype : '+keyWithSubtype);
        if(mapAgreementidToAgrObj.containskey(objAgreementLineItem.Apttus__AgreementId__c) && mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c).Apttus__Subtype__c != null) {
            keyWithSubtype = strLineType+ strDiscountType + strAgreementRecordType+String.valueOf(mapAgreementidToAgrObj.get(objAgreementLineItem.Apttus__AgreementId__c).Apttus__Subtype__c);
        }
        ilib_LogEvent.message('keyWithSubtype : '+keyWithSubtype);
        return keyWithSubtype;
    }

  /*
    @author: B Kamini
    @Story : DCP-31442
    @Description : Validation on Material Number & Material Group1 on Agreement Line Items
    */
    public void validateMaterialNumber() {
        ilib_LogEvent.push(LOG_TITLE+'.validateMaterialNumber()');
        List<Apttus__AgreementLineItem__c> lstAgreementLIs = (List<Apttus__AgreementLineItem__c>)records;
        // Map<id,Product2> idtoProductMap = new Map<id,Product2>();
        // Map<id,String> idtoMaterialGroup = new Map<id,String>();
        // DCP-56501 Introduced below logic for Profile Check.
        Boolean boolBypassValidationProfiles = Profiles.getAdminProfileId().contains(UserInfo.getProfileId()) || Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId());
        Set<String> materialNumbersOnAgreementLineItem = new Set<String>();
        Set<String> materialNumbersOnProducts = new Set<String>();
        Set<Id> setALIIds = new Set<Id>();
        Map<String,Set<String>> mapMaterialNumbertoCustomElection = new Map<String,Set<String>>();
        // DCP-56501 Populate the AgreementID set to check for the Material Number.
        Set<Id> setAgreementIds = new Set<Id>();
        for(Apttus__AgreementLineItem__c oAgrLI:lstAgreementLIs) {
            if(checkAgrmntLIRcrdTypeOpenOffer(oAgrLI))
            {
                setAgreementIds.add(oAgrLI.Apttus__AgreementId__c);
            }             
            if(oAgrLI.Id != null) {
                setALIIds.add(oAgrLI.Id);
            }
            if(oAgrLI.Material_Number__c!=null) { //Added : Too many queries
                materialNumbersOnAgreementLineItem.add(oAgrLI.Material_Number__c);
            }
            // DCP-56501 - Added the else condition to check Material number to be present for open offer Agreement line items if the Line type is Material or PSP Material.
            else if(!boolBypassValidationProfiles && oAgrLI.Material_Number__c==null && checkAgrmntLIRcrdTypeOpenOffer(oAgrLI) && (oAgrLI.Open_Offer_Line_Type__c == Label.OpenOfferLineTypePSPMaterial || oAgrLI.Open_Offer_Line_Type__c == Label.OpenOfferLineTypeMaterial)) {
                oAgrLI.adderror(Label.ErrorMessageForOpenOfferLineItemMaterialNumber);
            }
        }        
        ilib_LogEvent.info('materialNumbersOnAgreementLineItem : '+materialNumbersOnAgreementLineItem);
        List<Product2> lstProducts = new ProductsSelector().selectProductsForMaterialNumberOld(materialNumbersOnAgreementLineItem);

        if(!lstProducts.isEmpty()) { //Added: Too many queries
            for(Product2 oProd : lstProducts) {
            materialNumbersOnProducts.add(oProd.Material_Number__c);
            materialNumbersOnProducts.add(oProd.Old_Material_Number__c);
            }
            ilib_LogEvent.info('materialNumbersOnProducts : '+materialNumbersOnProducts);
        }
        // DCP-56501  
        if(!setAgreementIds.isEmpty()) {
            mapMaterialNumbertoCustomElection = getExistingALIRecords(setAgreementIds,materialNumbersOnAgreementLineItem,setALIIds);
        }              
        validateMaterialNumAndCustomerElection(boolBypassValidationProfiles,lstAgreementLIs,materialNumbersOnProducts,mapMaterialNumbertoCustomElection);
        ilib_LogEvent.pop();
    }
    /**
    *  @author Satya Swain
    *  @description Populate Account Lookup on Agreement Line Item based on Customer ERP Number for DCP-34983
    *  @param List<Apttus__AgreementLineItem__c> lstAgreementLineItem
    *  @return void
    **/
    private void setAccountLookup(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.setAccountLookup()');
        Set<String> setAccountERPIds = new Set<String>();
        Map<String, Account> erpIdToAccount = new Map<String, Account>();

        for(Apttus__AgreementLineItem__c objAgreementLI : lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(objAgreementLI)){continue;} // Added for DCP-54529
            if(objAgreementLI.Customer_ERP_Number__c!=null) { //Saswati - added null check
                setAccountERPIds.add(objAgreementLI.Customer_ERP_Number__c);
            }
        }
        ilib_LogEvent.info('setAccountERPIds : '+setAccountERPIds);

        if(setAccountERPIds.isEmpty()) {
            ilib_LogEvent.pop();
            return;}

        List<Account> lstCustomerAccount = new AccountsSelector().selectAccountsForERPCustomerIds(setAccountERPIds);
        for(Account objAccount : lstCustomerAccount) {
            if(!erpIdToAccount.containsKey(objAccount.ERP_Customer_Id__c)) {
                erpIdToAccount.put(objAccount.ERP_Customer_Id__c, objAccount);
            }
        }
        ilib_LogEvent.info('erpIdToAccount : ' + (erpIdToAccount != Null ? String.valueof(erpIdToAccount.keySet()):'Null'));
        for(Apttus__AgreementLineItem__c objAgreementLI : lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(objAgreementLI)){continue;} // Added for DCP-54529
            if(objAgreementLI.Customer_ERP_Number__c != NULL
            && erpIdToAccount.containsKey(objAgreementLI.Customer_ERP_Number__c)
            && erpIdToAccount.get(objAgreementLI.Customer_ERP_Number__c) != Null) {
                System.debug('@@@@  Account Id -->'+erpIdToAccount.get(objAgreementLI.Customer_ERP_Number__c).Id);
                objAgreementLI.Account__c = erpIdToAccount.get(objAgreementLI.Customer_ERP_Number__c).Id;
            }
            ilib_LogEvent.message(' objAgreementLI.Account__c : '+ objAgreementLI.Account__c);
        }
        ilib_LogEvent.pop();
    }

    
    /*
    @author: B Kamini
    @Story : DCP-31442
    @Description : Validation on Customer ERP number & Ultimate Consignee ERP number on Agreement Line Items
    */
    public void validateERPNumber() {
        ilib_LogEvent.push(LOG_TITLE+'.validateERPNumber()');
        List<Apttus__AgreementLineItem__c> lstAgreementLIs = (List<Apttus__AgreementLineItem__c>)records;
        List<String> lstCustomerERPsOnAgreementLineItem = new List<String>();
        // List<String> lstCustomerERPonCustomerMDT = new List<String>();
        Set<String> setUltimateConsigneeERPsOnALI = new Set<String>();
        // List<String> lstUltimateConsigneeERPsOnAccount = new List<String>();

        //Added null checks - too many queries
        for(Apttus__AgreementLineItem__c oAgrLI:lstAgreementLIs) {
            if(checkAgrmntLIRcrdTypeOpenOffer(oAgrLI)){continue;} // Added for DCP-54529
            if(oAgrLI.Customer_ERP_Number__c!=null) {
                lstCustomerERPsOnAgreementLineItem.add(oAgrLI.Customer_ERP_Number__c);
            }
            if(oAgrLI.Ultimate_Consignee_ERP_Number__c!=null) {
                setUltimateConsigneeERPsOnALI.add(oAgrLI.Ultimate_Consignee_ERP_Number__c);
            }
        }
        List<String> lstCustomerERPonCustomerMDT = getCustomerERPonCustomerMDT(lstCustomerERPsOnAgreementLineItem);
        ilib_LogEvent.info('lstCustomerERPonCustomerMDT : '+lstCustomerERPonCustomerMDT);
        for(Apttus__AgreementLineItem__c oAgrLI:lstAgreementLIs) {
            if( oAgrLI.Customer_ERP_Number__c!=NULL && lstCustomerERPonCustomerMDT!=Null && !(lstCustomerERPonCustomerMDT.contains(oAgrLI.Customer_ERP_Number__c))) {
                oAgrLI.adderror(Label.UI_ERP_Number_Not_Valid_Part1+oAgrLI.Customer_ERP_Number__c+Label.UI_ERP_Number_Not_Valid_Part2);
            }

        }

        //DCP-47006
        Map<String, String> mapUltimateConsigneeERPtoAccountName = getUltimateConsigneeERPsOnAccount(setUltimateConsigneeERPsOnALI);
        setUCNameonALI(lstAgreementLIs, mapUltimateConsigneeERPtoAccountName);
        ilib_LogEvent.pop();
    }

    private void setUCNameonALI(List<Apttus__AgreementLineItem__c> lstAgreementLIs, Map<String, String> mapUltimateConsigneeERPtoAccountName) {
        ilib_LogEvent.push(LOG_TITLE+'.setUCNameonALI()');
        ilib_LogEvent.info('mapUltimateConsigneeERPtoAccountName : ' + mapUltimateConsigneeERPtoAccountName);
        for(Apttus__AgreementLineItem__c oAgrLI:lstAgreementLIs) {
            if(oAgrLI.Ultimate_Consignee_ERP_Number__c!=NULL && mapUltimateConsigneeERPtoAccountName!=Null && mapUltimateConsigneeERPtoAccountName.containsKey(oAgrLI.Ultimate_Consignee_ERP_Number__c)) {
                oAgrLI.Ultimate_Consignee_Name__c = mapUltimateConsigneeERPtoAccountName.get(oAgrLI.Ultimate_Consignee_ERP_Number__c);
                ilib_LogEvent.message('oAgrLI.Ultimate_Consignee_Name__c : '+oAgrLI.Ultimate_Consignee_Name__c);
            }
            else if(oAgrLI.Ultimate_Consignee_ERP_Number__c!=NULL && mapUltimateConsigneeERPtoAccountName!=Null && !(mapUltimateConsigneeERPtoAccountName.containsKey(oAgrLI.Ultimate_Consignee_ERP_Number__c))) {
                oAgrLI.adderror(Label.UI_ERP_Number_Not_Valid_Part1+oAgrLI.Ultimate_Consignee_ERP_Number__c+Label.UI_ERP_Number_Not_Valid_Part2);
            }

        }
        ilib_LogEvent.pop();
    }

    /*
     * return list of CustomerERPonCustomerMDT
     */ 
    public List<String> getCustomerERPonCustomerMDT(List<String> lstCustomerERPsOnAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.getCustomerERPonCustomerMDT()');
        ilib_LogEvent.info('lstCustomerERPsOnAgreementLineItem : '+lstCustomerERPsOnAgreementLineItem);
        List<String> lstCustomerERPonCustomerMDT = new List<String>();
        List<Customer_Master_Data__c> lstCustomerMD = new List<Customer_Master_Data__c>();

        // Added : too many queries
        if(!lstCustomerERPsOnAgreementLineItem.isEmpty()) {
            lstCustomerMD = new CustomerMasterDataSelector().selectByERPId(lstCustomerERPsOnAgreementLineItem );
        }
        //Added : too many queries
        if(!lstCustomerMD.isEmpty()) {
            for(Customer_Master_Data__c oCustomerMD : lstCustomerMD) {
                lstCustomerERPonCustomerMDT.add(oCustomerMD.ERP_Customer_Id__c);
            }
            
        }
        ilib_LogEvent.info('lstCustomerERPonCustomerMDT : '+lstCustomerERPonCustomerMDT);
        ilib_LogEvent.pop();
        return lstCustomerERPonCustomerMDT;
        
    }

    /*
     * return list of UltimateConsigneeERPsOnAccount
     */ 
    public Map<String, String> getUltimateConsigneeERPsOnAccount(Set<String> setUltimateConsigneeERPsOnALI) {
        ilib_LogEvent.push(LOG_TITLE+'.getUltimateConsigneeERPsOnAccount()');
        ilib_LogEvent.info('setUltimateConsigneeERPsOnALI : '+setUltimateConsigneeERPsOnALI);
        Map<String, String> mapUltimateConsigneeERPtoAccountName = new Map<String, String>();
    
        List<Account> lstUltimateConsigneeERP = new AccountsSelector().selectAccountsForERPCustomerIds(setUltimateConsigneeERPsOnALI );
        for(Account oAccount : lstUltimateConsigneeERP ) {
            mapUltimateConsigneeERPtoAccountName.put(oAccount.ERP_Customer_Id__c, oAccount.Name);
        }
        ilib_LogEvent.info('mapUltimateConsigneeERPtoAccountName : '+mapUltimateConsigneeERPtoAccountName);
        ilib_LogEvent.pop();
        return mapUltimateConsigneeERPtoAccountName;
    }
    
    
    /*
     * Called during before update event
     **/
    public override void onAfterInsert() {
        // Initialized a Queueable thread for onAfterInsert. All queueables should be queued in this thread
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('Agreements_OnAfterInsert_AutoUpdateFieldsOnAgreementQueueable');
        
        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>)records;
        //Added by Rahul - DCP-32801
        associateAccountsOnAgreement(lstAgreementLineItem,null,true);
        //Added by Satya - DCP-36047
        deleteDiscontinuedAgreementLineItems(lstAgreementLineItem);
        //DCP-47006
        checkUCDiscLineItems(lstAgreementLineItem,queueableThread);

        // enqueueing the thread Job in the Queueable Manager
        enqueueJob(queueableThread);
    }
    /*
     * Called during before update event
     **/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords){
        if (Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) {
            return;
        }
        // Initialized a Queueable thread for onAfterUpdate. All queueables should be queued in this thread
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('Agreements_OnAfterUpdate_AutoUpdateFieldsOnAgreementQueueable');

        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>)records;
        //Type casting sObject existing records to Agreement Line Items
        Map<Id, Apttus__AgreementLineItem__c> idToAgmtLineItem = (Map<Id, Apttus__AgreementLineItem__c>)existingRecords;
        Set<Id> setAgreementId = new Set<Id>();
        Set<ID> setAgreementIdValidate = new Set<Id>();
        List<Apttus__AgreementLineItem__c> lstagl = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> discontinuedLItems = new List<Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c agl: lstAgreementLineItem) {
            if(agl.Discontinued__c != idToAgmtLineItem.get(agl.Id).Discontinued__c) {
                discontinuedLItems.add(agl);
            }
            System.debug('Discontinued Line Items -->'+ discontinuedLItems);
            setAgreementIdValidate.add(agl.Apttus__AgreementId__c);
            ilib_LogEvent.message('setAgreementIdValidate : '+setAgreementIdValidate);
            if(agl.Apttus__AgreementId__c != idToAgmtLineItem.get(agl.Id).Apttus__AgreementId__c || agl.Customer_ERP_Number__c != idToAgmtLineItem.get(agl.Id).Customer_ERP_Number__c
            || agl.Line_Type__c != idToAgmtLineItem.get(agl.Id).Line_Type__c  || agl.Price_Group__c != idToAgmtLineItem.get(agl.Id).Price_Group__c  || agl.Sales_Org__c != idToAgmtLineItem.get(agl.Id).Sales_Org__c ) {
                setAgreementId.add(agl.Apttus__AgreementId__c);
                ilib_LogEvent.message('setAgreementId : '+setAgreementId);
                lstagl.add(agl);
            }
        }

        callAssociateAccountsOnAgreement(setAgreementId);

        if(!Profiles.getAdminProfileId().contains(UserInfo.getProfileId()) && !Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId())) {
            updateAgreementValidationStatus(lstAgreementLineItem,idToAgmtLineItem,setAgreementIdValidate);
        }
        if(!discontinuedLItems.isEmpty()) {
            deleteAgreementAccountRelationship(discontinuedLItems);
        }
        //DCP-47006
        checkUCDiscLineItems(lstAgreementLineItem, queueableThread);

        // enqueueing the thread Job in the Queueable Manager
        enqueueJob(queueableThread);
    }

    /*
     * Call associateAccountsOnAgreement when Agreement Account Relationships are present on Agreements
     */
    public void callAssociateAccountsOnAgreement(Set<Id> setAgreementId) {
        ilib_LogEvent.push(LOG_TITLE+'.callAssociateAccountsOnAgreement()');
        ilib_LogEvent.info('setAgreementId : '+setAgreementId);
        if (!setAgreementId.isEmpty()) {
            List<Agreement_Account_Relationship__c> lstAar = new AgreementAccountRelationshipSelectors().selectByAgreementId(setAgreementId);
            if (!lstAar.isEmpty()) {
                List<Agreement_Account_Relationship__c> lstAarDefaultExcluded = removeDefaultAggAccRelationship(lstAar);     //INC0381333
                if (!lstAarDefaultExcluded.isEmpty()) { delete lstAarDefaultExcluded; }
                List<Apttus__AgreementLineItem__c> lstUpdatedAgreements = new ApttusAgreementLineItemSelectors().selectAgreementLineItem(setAgreementId);
                associateAccountsOnAgreement(lstUpdatedAgreements,null,true);
            }
        }
        ilib_LogEvent.pop();
    }

    /**
    *  @author Ashwin
    *  @description fix for INC0381333
    *  @return List<Agreement_Account_Relationship__c> lstAar without default AAR
    **/
    private static List<Agreement_Account_Relationship__c> removeDefaultAggAccRelationship(List<Agreement_Account_Relationship__c> lstAar){
        //usual traverse from 0 to list size does not remove subsequent element that also satisfies the criteria, if they are adjacent values
        //hence reverse traverse is needed
        ilib_LogEvent.push(LOG_TITLE+'.removeDefaultAggAccRelationship()');
        for(Integer index = lstAar.size() - 1; index >= 0; index--) {
            if(lstAar[index].Agreement__r.Apttus__Account__c == lstAar[index].Account__c) { 
                lstAar.remove(index);
            }
        }
        ilib_LogEvent.info('lstAar : '+UtilsCollection.getSetOfIds(lstAar));
        ilib_LogEvent.pop();
        return lstAar;
    }

    /**
    *  @author Rahul Bishnoi
    *  @description TASK0486150- Delete Agreement Account relationships after Line is items is discontinued..
    *  @return void
    **/
    private void deleteAgreementAccountRelationship(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE + '.deleteAgreementAccountRelationship()');
        Set<Id> setAgreementId = new Set<Id>();
        List<Apttus__AgreementLineItem__c> subsetExistingLineItems = new List<Apttus__AgreementLineItem__c>();
        List<Apttus__AgreementLineItem__c> lstHeaderLI = new List<Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c agl: lstAgreementLineItem) {
            setAgreementId.add(agl.Apttus__AgreementId__c);
        }
        ilib_LogEvent.info('setAgreementId : '+setAgreementId);
        //INC0381333
        list<Agreement_Account_Relationship__c> lstAarDefaultExcluded = removeDefaultAggAccRelationship(new AgreementAccountRelationshipSelectors().selectByAgreementId(setAgreementId));
        ilib_LogEvent.info('Count of all Agreement Account relationships excluding default --> ' + lstAarDefaultExcluded.size());
        //ilib_LogEvent.info('all Agreement Account relationships excluding default --> ' + lstAarDefaultExcluded);
        List<Apttus__AgreementLineItem__c> allExistingLineItems = new ApttusAgreementLineItemSelectors().selectByAgreementId(setAgreementId);
        for(Apttus__AgreementLineItem__c objLI: allExistingLineItems) {
            if(objLI.Discontinued__c != Label.AgreementLineItemDiscontinuedYes) {
                subsetExistingLineItems.add(objLI);
            }
            if(objLI.Customer_ERP_Number__c == objLI.Apttus__AgreementId__r.Account_ERP_Number__c) {
                lstHeaderLI.add(objLI);
            }
        }
        if(!lstAarDefaultExcluded.isEmpty()) { delete lstAarDefaultExcluded; }

        if(subsetExistingLineItems.isEmpty()) {
            //List<Agreement_Account_Relationship__c> lstSubsetAARRecords = associateAccountsOnAgreement(lstHeaderLI,null,true);
            associateAccountsOnAgreement(lstHeaderLI,null,true); //codescan fix
            //ilib_LogEvent.info('Re-Inserted Agreement Account relationships --> ' + lstSubsetAARRecords);
        } else {
           // ilib_LogEvent.info('Deleted Account relationships --> ' + lstAarDefaultExcluded);
            //List<Agreement_Account_Relationship__c> lstSubsetAARRecords = associateAccountsOnAgreement(subsetExistingLineItems,null,true);
            associateAccountsOnAgreement(subsetExistingLineItems,null,true); //codescan fix
            //ilib_LogEvent.info('Re-Inserted Agreement Account relationships --> ' + lstSubsetAARRecords);
        }
        ilib_LogEvent.pop();
    }
    /*
    * onAfterDelete Method to handle deletion
    */
    public override void onAfterDelete() {
        // Initialized a Queueable thread for onAfterDelete. All queueables should be queued in this thread
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('Agreements_OnAfterDelete_AutoUpdateFieldsOnAgreementQueueable');

        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = (List<Apttus__AgreementLineItem__c>)records;
        Set<Id> setAgreementId = new Set<Id>();
        Map<string,Agreement_Account_Relationship__c> mapAAR = new Map<string,Agreement_Account_Relationship__c>();
        list<Agreement_Account_Relationship__c> aarToDel = new list<Agreement_Account_Relationship__c>();

        for(Apttus__AgreementLineItem__c agl: lstAgreementLineItem) {
             setAgreementId.add(agl.Apttus__AgreementId__c);
        }
        ilib_LogEvent.info('setAgreementId : '+setAgreementId);
        List<Apttus__AgreementLineItem__c> lstUpdatedAgreements = new ApttusAgreementLineItemSelectors().selectAgreementLineItem(setAgreementId);
        List<Agreement_Account_Relationship__c> lstValidRecords =  associateAccountsOnAgreement(lstUpdatedAgreements,null,false);

        list<Agreement_Account_Relationship__c> lstExistingRecords = new AgreementAccountRelationshipSelectors().selectByAgreementId(setAgreementId);
        for(Agreement_Account_Relationship__c objValidRecords : lstValidRecords) {
            mapAAR.put(String.valueOf(objValidRecords.Account__c)+String.valueOf(objValidRecords.Agreement__c), objValidRecords);
        }
        for(Agreement_Account_Relationship__c objExistingRecords : lstExistingRecords) {
            if(!mapAAR.containsKey(''+objExistingRecords.Account__c+objExistingRecords.Agreement__c)) {
                aarToDel.add(objExistingRecords);
            }
        }

        if(!aarToDel.isEmpty()) {   //INC0381333
            List<Agreement_Account_Relationship__c> lstAarDefaultExcluded = removeDefaultAggAccRelationship(aarToDel);
            if(!lstAarDefaultExcluded.isEmpty()) { delete lstAarDefaultExcluded; }
        }
        // TASK0720220 - Calling this method on delete to blank out validation status
        // To force the user to re-validate after deleting line items
        updateAgreementValidationStatus(null, null, setAgreementId);
        //DCP-47006
        checkUCDiscLineItems(lstUpdatedAgreements, queueableThread);

        // enqueueing the thread Job in the Queueable Manager
        enqueueJob(queueableThread);
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
    *  @author Rahul Sharma
    *  @description Associate Multiple Accounts to agreement in junction object on upload of line items.
    *  @return void
    **/

    public static List<Agreement_Account_Relationship__c> associateAccountsOnAgreement(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Map<Id,Apttus__AgreementLineItem__c> idToAgmtLineItem , boolean isInsert) {
        ilib_LogEvent.push(LOG_TITLE+'.associateAccountsOnAgreement()');
        ilib_LogEvent.info('idToAgmtLineItem' + (idToAgmtLineItem != Null ? String.valueof(idToAgmtLineItem.keySet()):'Null'));
        ilib_LogEvent.info('isInsert : '+isInsert);
        Set<String> setCustomerERP = new Set<String>();
        Map<Id,Set<String>> mapAgreementToERP = new Map<Id,Set<String>>();
        list<string> lstPG = new list<string>();
        list<string> lstsalesOrg = new list<string>();
        Map<string,set<string>> mapPGsalesorg = new Map<string,set<string>>();
        list<Id> agreementIds = new list<Id>();
        Map<String,Set<String>> mapAccountSalesAreaKeyToERP = new Map<String,Set<String>>();
        Map<String,Agreement_Account_Relationship__c> mapAgreementAccount = new Map<String,Agreement_Account_Relationship__c>();
        // List<Agreement_Account_Relationship__c> lstAgmtAccounts = new List<Agreement_Account_Relationship__c>();
        Map<string,Agreement_Account_Relationship__c> mapAAR = new Map<string,Agreement_Account_Relationship__c>();
        list<Agreement_Account_Relationship__c> aarToIns = new list<Agreement_Account_Relationship__c>();

        for(Apttus__AgreementLineItem__c objAgrln:lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(objAgrln)){continue;} // Added for DCP-54529
            if(objAgrln.Line_Type__c == Label.UI_LinetypePriceGroupMaterial || objAgrln.Line_Type__c==Label.UI_LineTypePriceGroupMaterial1) {
                agreementIds.add(objAgrln.Apttus__AgreementId__c);
                lstPG.add(objAgrln.Price_Group__c);
                lstsalesOrg.add(objAgrln.Sales_Org__c);
                ilib_LogEvent.message('agreementIds : '+agreementIds);
                if( !mapPGsalesorg.containsKey(objAgrln.Apttus__AgreementId__c) ) {
                    mapPGsalesorg.put(objAgrln.Apttus__AgreementId__c,new Set<String>());
                }
                mapPGsalesorg.get(objAgrln.Apttus__AgreementId__c).add(objAgrln.Price_Group__c+objAgrln.Sales_Org__c);

            } else {
                agreementIds.add(objAgrln.Apttus__AgreementId__c);
                ilib_LogEvent.message('agreementIds : '+agreementIds);
                if( objAgrln.Customer_ERP_Number__c != Null) {
                    if( !mapAgreementToERP.containskey(objAgrln.Apttus__AgreementId__c) ) {
                        mapAgreementToERP.put(objAgrln.Apttus__AgreementId__c,new Set<String>{objAgrln.Customer_ERP_Number__c});
                    }
                    mapAgreementToERP.get(objAgrln.Apttus__AgreementId__c).add(objAgrln.Customer_ERP_Number__c);
                }
            }
        }
        ilib_LogEvent.info('lstPG : '+lstPG);
        ilib_LogEvent.info('lstsalesOrg : '+lstsalesOrg);
        ilib_LogEvent.info('mapPGsalesorg' + (mapPGsalesorg != Null ? String.valueof(mapPGsalesorg.keySet()):'Null'));
        ilib_LogEvent.info('mapAgreementToERP' +(mapAgreementToERP != Null ? String.valueof(mapAgreementToERP.keySet()):'Null'));
        for(Id id:mapAgreementToERP.keyset()) {
            setCustomerERP.addAll(mapAgreementToERP.get(id));
        }
        ilib_LogEvent.info('setCustomerERP : '+setCustomerERP);
        List<Account_Sales_Area__c> lstAccountSalesArea= new AccountSalesAreaSelector().selectAccountSaleaAreaByAccount(lstPG,lstsalesOrg);
        for(Account_Sales_Area__c accSaleArea : lstAccountSalesArea) {
            if(!mapAccountSalesAreaKeyToERP.containskey(accSaleArea.Price_Group__c+accSaleArea.Sales_Organization__c)) {
                mapAccountSalesAreaKeyToERP.put(accSaleArea.Price_Group__c+accSaleArea.Sales_Organization__c,new Set<String>{accSaleArea.Account__c});
            }
            mapAccountSalesAreaKeyToERP.get(accSaleArea.Price_Group__c+accSaleArea.Sales_Organization__c).add(accSaleArea.Account__c);
        }
        ilib_LogEvent.info('mapAccountSalesAreaKeyToERP' + (mapAccountSalesAreaKeyToERP != Null ? String.valueof(mapAccountSalesAreaKeyToERP.keySet()):'Null'));
        for(string aggId : mapPGsalesorg.keyset()) {
            for(string pgSalesOrgId : mapPGsalesorg.get(aggId)) {
                if(mapAccountSalesAreaKeyToERP.containsKey(pgSalesOrgId)) {
                    for(string accId : mapAccountSalesAreaKeyToERP.get(pgSalesOrgId)) {
                        Agreement_Account_Relationship__c aar = new Agreement_Account_Relationship__c();
                        aar.Account__c = accId;
                        aar.Agreement__c = aggId;
                        ilib_LogEvent.fine('aar.Account__c : '+aar.Account__c);
                        ilib_LogEvent.fine('aar.Agreement__c : '+aar.Agreement__c);
                        mapAgreementAccount.put(accId+aggId, aar );
                    }
                }
            }
        }
        
        List<Account> lstAccounts = new AccountsSelector().selectAccountsForERPCustomerIds(setCustomerERP);
        for(Id id: mapAgreementToERP.keyset()) {
            for(Account acc: lstAccounts) {
                if(mapAgreementToERP.get(Id).contains(acc.ERP_Customer_Id__c)) {
                    Agreement_Account_Relationship__c aar = new Agreement_Account_Relationship__c();
                    aar.Account__c = acc.Id;
                    aar.Agreement__c = id;
                    ilib_LogEvent.fine('aar.Account__c : '+aar.Account__c);
                    ilib_LogEvent.fine('aar.Agreement__c : '+aar.Agreement__c);
                    mapAgreementAccount.put(''+acc.Id+Id, aar );
                }
            }
        }
        
        //Insert records into the junction object
        if(isInsert) {
            Set<Id> setAgreementId = new Set<Id>(agreementIds);
            list<Agreement_Account_Relationship__c> lstExistingRecords = new AgreementAccountRelationshipSelectors().selectByAgreementId(setAgreementId);
            
            for(Agreement_Account_Relationship__c objExistingRecords : lstExistingRecords) {
                mapAAR.put(String.valueOf(objExistingRecords.Account__c)+String.valueOf(objExistingRecords.Agreement__c), objExistingRecords);
            }
            ilib_LogEvent.info('mapAAR' + (mapAAR != Null ? String.valueof(mapAAR.keySet()):'Null'));
            for(Agreement_Account_Relationship__c objValidRecords : mapAgreementAccount.values() ) {
                if(!mapAAR.containsKey(String.valueOf(objValidRecords.Account__c)+String.valueOf(objValidRecords.Agreement__c))) {
                    aarToIns.add(objValidRecords);
                }
            }
            
            if(!aarToIns.isEmpty()) {   //INC0381333
                List<Agreement_Account_Relationship__c> lstAarDefaultExcluded = removeDefaultAggAccRelationship(aarToIns);
                
                if(!lstAarDefaultExcluded.isEmpty()) { insert lstAarDefaultExcluded; }
            }
        }
        ilib_LogEvent.info('mapAgreementAccount' + (mapAgreementAccount != Null ? String.valueof(mapAgreementAccount.keySet()):'Null'));
        ilib_LogEvent.pop();
        return mapAgreementAccount.values();
    }
    /**
    *  @author Satya Swain
    *  @description Delete AgreementLineItems where Discontinued is Yes for Renew/Amend Scenario for DCP-36047
    *  @param List<Apttus__AgreementLineItem__c> lstAgreementLineItem
    *  @return void
    **/
    private void deleteDiscontinuedAgreementLineItems(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.deleteDiscontinuedAgreementLineItems()');
        List<Apttus__AgreementLineItem__c> lstAgreementLineItemToDelete = new List<Apttus__AgreementLineItem__c>();
                
        for(Apttus__AgreementLineItem__c objAgreementLineItem : lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(objAgreementLineItem)){continue;} // Added for DCP-54529
            if(objAgreementLineItem.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting 
            && objAgreementLineItem.Discontinued__c == Label.AgreementLineItemDiscontinuedYes) {
                Apttus__AgreementLineItem__c objALIToBeDeleted = new Apttus__AgreementLineItem__c(id = objAgreementLineItem.id);
                ilib_LogEvent.message('objALIToBeDeleted : '+objALIToBeDeleted);
                lstAgreementLineItemToDelete.add(objALIToBeDeleted);
            }
        }
        
        
        if(!lstAgreementLineItemToDelete.isEmpty()) {
            delete lstAgreementLineItemToDelete;
        }
       ilib_LogEvent.pop(); 
    }

    /**
     *  @author Pankaj Sharma
     *  @populates material group1 description based on material group 1
     *  @Parameter List of AgrLi
     *  @return N/A
     **/
    private void populateMaterialGroup1Desc(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.populateMaterialGroup1Desc()');
        
        Map<String,Material_Group__mdt> mapMaterialCodeToMaterialGrpMapping = new Map<String,Material_Group__mdt>();
        List<Material_Group__mdt> lstMaterialGrouppMapping = new MaterialGroupsSelector().selectAll();
        for(Material_Group__mdt oMaterialGroupMapping : lstMaterialGrouppMapping) {
            mapMaterialCodeToMaterialGrpMapping.put(oMaterialGroupMapping.MasterLabel,oMaterialGroupMapping);
        }
        ilib_LogEvent.info('mapMaterialCodeToMaterialGrpMapping' + (mapMaterialCodeToMaterialGrpMapping != Null ? String.valueof(mapMaterialCodeToMaterialGrpMapping.keySet()):'Null'));
        for(Apttus__AgreementLineItem__c oAgrLI : lstAgreementLineItem) {
            if(checkAgrmntLIRcrdTypeOpenOffer(oAgrLI)){continue;} // Added for DCP-54529
            if(oAgrLI.Material_Group_1__c == null) {
                oAgrLI.Material_Group_1_Description__c=''; 
            } else {
                if(mapMaterialCodeToMaterialGrpMapping.Keyset().Contains(oAgrLI.Material_Group_1__c)) {
                    oAgrLI.Material_Group_1_Description__c=mapMaterialCodeToMaterialGrpMapping.get(oAgrLI.Material_Group_1__c).Description__c;
                    ilib_LogEvent.message('oAgrLI.Material_Group_1_Description__c : '+oAgrLI.Material_Group_1_Description__c);
                }
            }
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author Prabhsimran Singh
     *  @populates product based on material number
     *  @Parameter List of AgrLi
     *  @return N/A
     **/
    private void populateProduct(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.populateProduct()');
        set<String> setMaterialNo = new set<String>();
        // Map<String,Id> mapMaterialNoProductId = new Map<String,Id>();
        // Map<String,Id> mapOldMaterialNoProductId = new Map<String,Id>();
        Map<String, Product2> mapMaterialNoProduct = new Map<String, Product2>(); // DGP-103
        Map<String, Product2> mapOldMaterialNoProduct = new Map<String, Product2>(); // DGP-103
        if(!lstAgreementLineItem.isEmpty()) {
            for(Apttus__AgreementLineItem__c oAgrLI : lstAgreementLineItem) {
                if(String.isNotBlank(oAgrLI.Material_Number__c)) {
                    setMaterialNo.add(oAgrLI.Material_Number__c);
                }
            }
            ilib_LogEvent.info('setMaterialNo : '+setMaterialNo);
        }

        if(!setMaterialNo.isEmpty()) {
            List<Product2> lstProducts = new ProductsSelector().selectProductsForMaterialNumberOld(setMaterialNo);
            for(Product2 prd : lstProducts) {
                if(String.isNotBlank(prd.Material_Number__c)) {
                    // mapMaterialNoProductId.put(prd.Material_Number__c,prd.Id);
                    mapMaterialNoProduct.put(prd.Material_Number__c,prd); // DGP-103
                }
                if(String.isNotBlank(prd.Old_Material_Number__c)) {
                    // mapOldMaterialNoProductId.put(prd.Old_Material_Number__c,prd.Id);
                    mapOldMaterialNoProduct.put(prd.Old_Material_Number__c,prd); // DGP-103
                }
            }
           ilib_LogEvent.info('mapMaterialNoProduct : ' + mapMaterialNoProduct);
           ilib_LogEvent.info('mapOldMaterialNoProduct : ' + mapOldMaterialNoProduct);
            for(Apttus__AgreementLineItem__c oAgrLI : lstAgreementLineItem) {
                if(String.isNotBlank(oAgrLI.Material_Number__c) ) {
                    if(!mapMaterialNoProduct.isEmpty() &&
                        mapMaterialNoProduct.containsKey(oAgrLI.Material_Number__c)) {
                            oAgrLI.Apttus__ProductId__c = mapMaterialNoProduct.get(oAgrLI.Material_Number__c).Id;
                            oAgrLI.Discount_Grid_Group__c = mapMaterialNoProduct.get(oAgrLI.Material_Number__c).Discount_Grid_Group__c; // DGP-103
                           ilib_LogEvent.message('oAgrLI.Apttus__ProductId__c : '+oAgrLI.Apttus__ProductId__c);
                    } else if(!mapOldMaterialNoProduct.isEmpty() &&
                               mapOldMaterialNoProduct.containsKey(oAgrLI.Material_Number__c)) {
                                   oAgrLI.Apttus__ProductId__c = mapOldMaterialNoProduct.get(oAgrLI.Material_Number__c).Id;
                                   oAgrLI.Discount_Grid_Group__c = mapOldMaterialNoProduct.get(oAgrLI.Material_Number__c).Discount_Grid_Group__c; // DGP-103
                                ilib_LogEvent.message('oAgrLI.Apttus__ProductId__c : '+oAgrLI.Apttus__ProductId__c);
                    } else {
                        oAgrLI.Apttus__ProductId__c = null;
                        oAgrLI.Discount_Grid_Group__c = null; // DGP-103
                        ilib_LogEvent.message('oAgrLI.Apttus__ProductId__c : '+oAgrLI.Apttus__ProductId__c);
                    }
                }

            }
        }
    ilib_LogEvent.pop();
    }
    /**
     *  @author Prabhsimran Singh
     *  @depopulate product on agreement line item if material no is empty.
     *  @Parameter List of AgrLi
     *  @return N/A
     **/
    private void depopulateProduct(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE+'.depopulateProduct()');
        if(!lstAgreementLineItem.isEmpty()) {
            for(Apttus__AgreementLineItem__c oAgrLI : lstAgreementLineItem) {
                if(String.isBlank(oAgrLI.Material_Number__c)) {
                    oAgrLI.Apttus__ProductId__c = null;
                    oAgrLI.Discount_Grid_Group__c = null; // DGP-103
                }
            }
        }
        ilib_LogEvent.pop();
    }
    
    /**
     * DGP-103 : Method to populate Discount Grid Group for Material Group 1 Line Item from Material Group metadata instance.
     **/
    private void populateDiscountGridGroupForMaterialGroupLines(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        
        for(Apttus__AgreementLineItem__c oAgrLI : lstAgreementLineItem) {
            
            if((String.isNotBlank(oAgrLI.Line_Type__c) && oAgrLI.Line_Type__c.contains(Label.LineTypeMaterialGroup1)) || System.Test.isRunningTest()) {
                Material_Group__mdt mgMetadata = Material_Group__mdt.getInstance(oAgrLI.Material_Group_1__c);
                oAgrLI.Discount_Grid_Group__c = mgMetadata == null ? null : mgMetadata.Discount_Grid_Group__c;
            }
        }
    }
    
    /**
     *  @author vishnu kurra
     *  User Story : DCP - 33720
    *   Functionality : To validate approval status
     **/
    public void validateApprovalStatus(List<Apttus__AgreementLineItem__c> lstAgreementLineItem) {
        // set<Id> setAgreementIds = new set<Id>();
        ilib_LogEvent.push(LOG_TITLE+'.validateApprovalStatus()');
        Map<Id,String> mapofAggrement = new Map<Id,String>();
        if(!lstAgreementLineItem.isEmpty()) {

            List<Apttus__APTS_Agreement__c> lstAgreement = listAgreementsFromIntialize; // Added by Saswati - 32046, SOQL Fixes
            if(!lstAgreement.isEmpty()) {
                for( Apttus__APTS_Agreement__c objAgreement:lstAgreement) {
                    if(objAgreement.Apttus_Approval__Approval_Status__c == Label.AgreementApprovalStatusApproved &&
                    (objAgreement.Apttus__Status_Category__c == Label.AgreementStatusCategoryInEffect ||
                    objAgreement.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Amended ||
                    objAgreement.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Terminated) &&
                        !objAgreement.Is_Auto_Approved__c) {//Added Is Auto Approved check as part of defect DCP-37265){
                        mapofAggrement.put(objAgreement.Id,objAgreement.Apttus_Approval__Approval_Status__c);
                    }
                }
              ilib_LogEvent.info('mapofAggrement : ' + mapofAggrement);
            }
            for(Apttus__AgreementLineItem__c ali :lstAgreementLineItem) {
                if(checkAgrmntLIRcrdTypeOpenOffer(ali)){continue;} // Added for DCP-54529
                // Added bug fix for DCP-36652
                Boolean isAgreementAmendedOrRenewed = checkForAgreementRenewalOrAmendment(ali);
                if(mapofAggrement.containsKey(ali.Apttus__AgreementId__c) && !isAgreementAmendedOrRenewed) {
                    // ali.adderror(Label.UI_Error_Message_Approval_Status);
                    ali.adderror(Label.UI_Error_Message_Upload_Lines_Items);
                }
            }
        }
        ilib_LogEvent.pop();
    }

    private Boolean checkForAgreementRenewalOrAmendment(Apttus__AgreementLineItem__c objAgreementLineItem) {
        
        ilib_LogEvent.message('objAgreementLineItem : '+objAgreementLineItem);
        ilib_LogEvent.message('returning : '+String.valueOf(objAgreementLineItem.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting 
        && objAgreementLineItem.Discontinued__c == Label.AgreementLineItemDiscontinuedYes));
     
        return objAgreementLineItem.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting 
        && objAgreementLineItem.Discontinued__c == Label.AgreementLineItemDiscontinuedYes;
    }

   /*
    *  @author      : B Kamini
    *  @description : Method to populate line status on Line item to Updated if any change is made on Line item and the line status was previously Existing
    *  @param       : Line item list
    *  @return      : void
    */
    public void populateLineStatusOnAGLIonUpdation(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Map<Id, sObject> existingRecords) {
        ilib_LogEvent.push(LOG_TITLE+'.populateLineStatusOnAGLIonUpdation()');
        Map<id,List<Apttus__AgreementLineItem__c>> agreementoLstALIWithMaterial = new Map<id,List<Apttus__AgreementLineItem__c>>();

        for(Apttus__AgreementLineItem__c objNewAgl : lstAgreementLineItem) {
            Apttus__AgreementLineItem__c oldagl = (Apttus__AgreementLineItem__c)(existingRecords.get(objNewAgl.Id));
            // Defect DCP-58345 fix- Introduced below boolean to check for the customer election change.
            Boolean boolCustomerElectionChanged = oldagl.Customer_Election__c != objNewAgl.Customer_Election__c;
            Boolean boolAgreementLineIsOpenOffer = checkAgrmntLIRcrdTypeOpenOffer(objNewAgl);
            Boolean boolLineStatusCriteriaSatisfied = oldagl.Apttus_CMConfig__LineStatus__c != null && oldagl.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting;
            // Defect DCP-58345 Fix - Updated the condition below to include the boolean boolCustomerElectionChanged.
            Boolean boolOpenOfferUpdateCriteriaSatisfied = boolAgreementLineIsOpenOffer && (boolCustomerElectionChanged || isCombinationTrueForOOLT(objNewAgl,oldagl)) && boolLineStatusCriteriaSatisfied;
            Boolean boolNonOpenOfferUpdateCriteriaSatisfied = !boolAgreementLineIsOpenOffer && boolLineStatusCriteriaSatisfied;

            if(boolOpenOfferUpdateCriteriaSatisfied || boolNonOpenOfferUpdateCriteriaSatisfied) {
                objNewAgl.Apttus_CMConfig__LineStatus__c = Label.AgreementLineItemLineStatusUpdated;
                ilib_LogEvent.message('objNewAgl.Apttus_CMConfig__LineStatus__c : '+objNewAgl.Apttus_CMConfig__LineStatus__c);
            }

            //DCP-56504    Creating agreementoLstALIWithMaterial Map for periodOverlapCheckForMSA()
            if((objNewAgl.Supply_Agreement_Start_Date__c != oldagl.Supply_Agreement_Start_Date__c || objNewAgl.Supply_Agreement_End_Date__c != oldagl.Supply_Agreement_End_Date__c) && checkAgrmntLIRcrdTypeOpenOffer(objNewAgl)) { 
                agreementoLstALIWithMaterial.put(objNewAgl.Apttus__AgreementId__c, new List<Apttus__AgreementLineItem__c>());                
            }
        }

        periodOverlapCheckForMSA(lstAgreementLineItem, agreementoLstALIWithMaterial);
        ilib_LogEvent.pop();  
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-47006
    @Description : Method to check line items with UC Discounts.
    @Test Class : TestApttusAgreements.testUCMaterialRollUp
    @@Added NUll check for the list. DCP-54810 .
    */
    private void checkUCDiscLineItems(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, ilib_Queueablethread queueableThread) {
        ilib_LogEvent.push(LOG_TITLE+'.checkUCDiscLineItems()');
        ilib_LogEvent.info('queueableThread : '+queueableThread);
        Set<Id> setAgreementIds = new Set<Id>();

            for(Apttus__AgreementLineItem__c agrLI : lstAgreementLineItem) {
                    setAgreementIds.add(agrLI.Apttus__AgreementId__c);
            } 
        
        ilib_LogEvent.info('setAgreementIds : '+setAgreementIds);
        // INC0388579 - If it is called from a batch or a futire, do the update in this context. 
        // Saving on a query by passing the line items to the queueable
        if(System.isBatch() || System.isFuture()) {
            AutoUpdateFieldsOnAgreementQueueable.updateCustomRollUpsOnAgreements(setAgreementIds, lstAgreementLineItem,Trigger.isdelete);
        }
        else{
            // add queueable to the thread to update the custom roll up fields on the Agreement
            AutoUpdateFieldsOnAgreementQueueable queueableClsInstance = new AutoUpdateFieldsOnAgreementQueueable(setAgreementIds);
            queueableClsInstance.setBooleanForDeleteTrigger(Trigger.isdelete);
            queueableThread.logAndQueue(queueableClsInstance, 'AutoUpdateFieldsOnAgreementQueueable', 'execute');
        }
        ilib_logEvent.pop();
    }


    /*
    @Author : Bharath Varma
    @Story : TASK0700485
    @Description : Method to check line items with Discounts on Amended agreements when the parent agreement doesnot have line items.
    */
    private void checkDiscountsOnAmendedAgr(List<Apttus__AgreementLineItem__c> agreementLineItems) {

        ilib_LogEvent.push(LOG_TITLE + '.checkDiscountsOnAmendedAgr()');
        Map<Id, List<Apttus__AgreementLineItem__c>> mapAgrIdToListLineItems = new Map<Id, List<Apttus__AgreementLineItem__c>>();

        for(Apttus__AgreementLineItem__c agrLineItem : agreementLineItems) {
            if(checkAgrmntLIRcrdTypeOpenOffer(agrLineItem)){continue;} // Added for DCP-54529
            // Create a map of Agr Id to List of Agreement Line items
            if(mapAgrIdToListLineItems.containsKey(agrLineItem.Apttus__AgreementId__c)) {
                mapAgrIdToListLineItems.get(agrLineItem.Apttus__AgreementId__c).add(agrLineItem);
            }
            mapAgrIdToListLineItems.put(agrLineItem.Apttus__AgreementId__c, new List<Apttus__AgreementLineItem__c>{agrLineItem});
        }

        ilib_LogEvent.info('mapAgrIdToListLineItems keyset ::: ' + (mapAgrIdToListLineItems != Null ? String.valueof(mapAgrIdToListLineItems.keySet()):'Null'));


        // Query the related agreement records present on the agr to see if this agreement is amended from another parent agr
        List<Apttus__APTS_Related_Agreement__c> relatedAgreements = new ApttusRelatedAgreementSelectors().getRelatedAgreementForCurrentAgreement(mapAgrIdToListLineItems.keySet());
        // If it is not amended, then return
        if(relatedAgreements.isEmpty()) {
            ilib_LogEvent.pop();
            return; }

        for(Apttus__APTS_Related_Agreement__c relatedAgreement : relatedAgreements) {
            // Check if the Parent Agr has 0 line items and add error on the agrLineItems if they have discounts more than 0
            if(mapAgrIdToListLineItems.containsKey(relatedAgreement.Apttus__APTS_Contract_To__c) && relatedAgreement.Apttus__APTS_Contract_From__r.Number_Of_Agreement_Line_Items__c == 0) {
                for(Apttus__AgreementLineItem__c agrLineItem : mapAgrIdToListLineItems.get(relatedAgreement.Apttus__APTS_Contract_To__c)) {
                    agrLineItem.addError(Label.UI_Label_Line_Items_Not_Allowed);
                }
            }
        }

        ilib_LogEvent.pop();
        
    }

    /*
    @Author : Bharath Varma
    @Story : INC0388579
    @Description : Method to enqueue thread Job when queueableThread is not empty
    */
    public void enqueueJob(ilib_Queueablethread queueableThread) {
        ilib_LogEvent.push(LOG_TITLE+'.enqueueJob()');
        ilib_LogEvent.info('queueableThread : '+queueableThread);
        if(!queueableThread.lstQueueableJobs.isEmpty()) { ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES); }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Nishan Shetty
    @Story :  DCP-52703
    @Description : Method to set the priority of Agreement Line Item based on Material Code and Approval Status.
    */
    public void setAgreementLineItemPriority(List<Apttus__AgreementLineItem__c> lstAgreementLineItems) {
        ilib_LogEvent.push(LOG_TITLE+'.setAgreementLineItemPriority()');

        Map<String,Material_Group__mdt> mapMaterialGroupMetaData = Material_Group__mdt.getAll();

        for(Apttus__AgreementLineItem__c objAgreementLine:lstAgreementLineItems) {
            if(checkAgrmntLIRcrdTypeOpenOffer(objAgreementLine)){continue;} // Added for DCP-54529
            if(objAgreementLine.Material_Group_1__c!=null 
            && mapMaterialGroupMetaData.containsKey(objAgreementLine.Material_Group_1__c) 
            && mapMaterialGroupMetaData.get(objAgreementLine.Material_Group_1__c).Priority__c!=null
            && objAgreementLine.Apttus_CMConfig__LineStatus__c!=Label.AgreementLineItemLineStatusExisting 
            && (objAgreementLine.Apttus_Approval__Approval_Status__c== Label.AgreementApprovalStatusApprovalRequired
                || objAgreementLine.Apttus_Approval__Approval_Status__c== Label.AgreementApprovalStatusRejected 
                || objAgreementLine.Apttus_Approval__Approval_Status__c==Label.AgreementApprovalStatusCancelled
                || objAgreementLine.Apttus_Approval__Approval_Status__c==Label.AgreementApprovalStatusPendingApproval
            )) {
                objAgreementLine.Priority__c=mapMaterialGroupMetaData.get(objAgreementLine.Material_Group_1__c).Priority__c;
            } else {
                objAgreementLine.Priority__c=null;
            }
            ilib_LogEvent.message('ObjectAgreementLineItem : '+objAgreementLine);
        }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Prem Ranjan
    @Story :  DCP-56504
    @Description : Method to return True when it match few combination(as below) to make line status as updated.
					Capture the line status as Updated if any of the below combination is changed per line type:
						Material – Quote Discount, Supply Agreement Discount, Supply Agreement Start Date, Supply Agreement End Date, Universal Grid Discount, Agreement Line item start date
						PSP Category -->  PSP% or Universal Grid%
						PSP Material - PSP % or Universal Grid %
    */
    public Boolean isCombinationTrueForOOLT(Apttus__AgreementLineItem__c newALI , Apttus__AgreementLineItem__c oldALI) {
        Boolean boolResult =false;

        Boolean boolQuoteDiscountChanged = newALI.Quote_Discount__c != oldALI.Quote_Discount__c;
        Boolean boolSupplyAggDisChanged = newALI.Supply_Agreement_Discount__c != oldALI.Supply_Agreement_Discount__c;
        Boolean boolSupplyAggStartDateChanged = newALI.Supply_Agreement_Start_Date__c != oldALI.Supply_Agreement_Start_Date__c;
        Boolean boolSupplyAggEndDateChanged = newALI.Supply_Agreement_End_Date__c != oldALI.Supply_Agreement_End_Date__c;
        Boolean boolUGDChanged = newALI.Universal_Grid_Discount__c != oldALI.Universal_Grid_Discount__c;
        Boolean boolALIStartDateChanged = newALI.Apttus_CMConfig__StartDate__c != oldALI.Apttus_CMConfig__StartDate__c;

        if(newALI.Open_Offer_Line_Type__c == Label.OpenOfferLineTypeMaterial && (boolQuoteDiscountChanged || boolSupplyAggDisChanged ||
                                                            boolSupplyAggStartDateChanged || boolSupplyAggEndDateChanged ||
                                                            boolUGDChanged || boolALIStartDateChanged )) {
            boolResult = true;
        }

        Boolean boolPSPDiscountChanged = newALI.PSP_Discount__c != oldALI.PSP_Discount__c;
        Boolean boolUGDiscountChanged = newALI.Universal_Grid_Discount__c != oldALI.Universal_Grid_Discount__c;

        if((newALI.Open_Offer_Line_Type__c == Label.OpenOfferLineTypePSP || newALI.Open_Offer_Line_Type__c == Label.OpenOfferLineTypePSPMaterial) 
                                                    && (boolPSPDiscountChanged || boolUGDiscountChanged  )) {
            boolResult = true;
        }

         return boolResult;
	}

    /*
    @Author : Prem Ranjan
    @Story :  DCP-56504
    @Description : Method to to populate Map with Agreement to Lst ALI With Material.
    */
    public static void createMapWithAggToALIWithSameMaterial(Apttus__AgreementLineItem__c aLI, Map<id,List<Apttus__AgreementLineItem__c>> agreementoLstALIWithMaterial) {
        if(aLI.Supply_Agreement_Start_Date__c != null && 
        aLI.Supply_Agreement_End_Date__c != null) { 

            if(agreementoLstALIWithMaterial.containsKey(aLI.Apttus__AgreementId__c)) {
                agreementoLstALIWithMaterial.get(aLI.Apttus__AgreementId__c).add(aLI);
            } else {
                agreementoLstALIWithMaterial.put(aLI.Apttus__AgreementId__c, new List<Apttus__AgreementLineItem__c>());
            } 
            ilib_LogEvent.message('ObjectAgreementLineItem : '+aLI);
        }
    }
    
    /*
    @Author : Prem Ranjan
    @Story :  DCP-56504
    @Description : Method to add error on Incase if there are more than 1 line item for the same material (example: In case of MSA), then period for each line items cannot overlap.
    */
    public static void periodOverlapCheckForMSA(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, Map<id,List<Apttus__AgreementLineItem__c>> agreementoLstALIWithMaterial) {
        ilib_LogEvent.push(LOG_TITLE+'.periodOverlapCheckForMSA()');
        Boolean boolBypassValidationProfiles = Profiles.getAdminProfileId().contains(UserInfo.getProfileId()) || Profiles.getSalesIntegrationProfileIds().contains(UserInfo.getProfileId());
        if(!agreementoLstALIWithMaterial.keyset().isEmpty() && !boolBypassValidationProfiles) {
            List<Apttus__AgreementLineItem__c> lstAllALI = new ApttusAgreementLineItemSelectors().selectAgreementLineItem(agreementoLstALIWithMaterial.keyset());
            if(!lstAllALI.isEmpty()) {
                for(Apttus__AgreementLineItem__c objAgreementLine : lstAllALI) {
                    if(String.isNotEmpty(objAgreementLine.Material_Number__c) 
                        && objAgreementLine.Supply_Agreement_Start_Date__c != null 
                        && objAgreementLine.Supply_Agreement_End_Date__c != null ) {
                        agreementoLstALIWithMaterial.get(objAgreementLine.Apttus__AgreementId__c).add(objAgreementLine);
                    }
                }
            }
            for(Apttus__AgreementLineItem__c objAgreementLine : lstAgreementLineItem) {
                if(agreementoLstALIWithMaterial.containsKey(objAgreementLine.Apttus__AgreementId__c)) {
                    if(checkOverlapOfDates(objAgreementLine,agreementoLstALIWithMaterial.get(objAgreementLine.Apttus__AgreementId__c))) {
                        objAgreementLine.adderror(Label.UI_ALIPreiodOverlapError);
                    }
                }
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Prem Ranjan
    @Story :  DCP-56504
    @Description : Method to add error on Incase if there are more than 1 line item for the same material (example: In case of MSA), then period for each line items cannot overlap.
    */
    public static boolean checkOverlapOfDates(Apttus__AgreementLineItem__c objALIUpdate, List<Apttus__AgreementLineItem__c> lstAgreementLineItems) {
        
        for(Apttus__AgreementLineItem__c objAgreementLine : lstAgreementLineItems) {
            Boolean boolCheckIfNotTheSameRecord = Trigger.isInsert && objAgreementLine != objALIUpdate ? true : objAgreementLine.id != objALIUpdate.id;
            if( objALIUpdate.Material_Number__c == objAgreementLine.Material_Number__c &&
                boolCheckIfNotTheSameRecord &&
                objAgreementLine.Supply_Agreement_Start_Date__c < objALIUpdate.Supply_Agreement_End_Date__c &&
                objAgreementLine.Supply_Agreement_End_Date__c > objALIUpdate.Supply_Agreement_Start_Date__c) {
                return true;
            }
        }
        return false;
    }
    /*
    @author: Parthasarathy D
    @Story : DCP-56501
    @Description : Validation on Customer Election type on Agreement Line Items
    */
    public void validateMaterialNumAndCustomerElection(Boolean boolBypassValidationProfiles,List<Apttus__AgreementLineItem__c> lstAgreementLIs,Set<String> materialNumbersOnProducts,Map<String,Set<String>> mapMaterialNumbertoCustomElection) {
        ilib_LogEvent.push(LOG_TITLE+'.validateMaterialNumAndCustomElection()');
        Set<String> setHandledMaterialNumber = new Set<String>();        
        Map<String,Set<String>> mapNewMaterialNumbertoCustomElection = new Map<String,Set<String>>();
        Map<Id, Apttus__APTS_Agreement__c> mapAgreementIDtoObj; 
        // Logic to check for the Agreement Status and Parent Agreement ID.
        if(!listAgreementsFromIntialize.isEmpty()) {
            mapAgreementIDtoObj = new Map<Id, Apttus__APTS_Agreement__c>(listAgreementsFromIntialize);
        }
        for(Apttus__AgreementLineItem__c objAgreementLine:lstAgreementLIs) {
            if(!String.isBlank(objAgreementLine.Material_Number__c) && materialNumbersOnProducts!=Null && !(materialNumbersOnProducts.contains(objAgreementLine.Material_Number__c))) {
                objAgreementLine.adderror(Label.UI_Material_Number_Not_Valid_Part1+objAgreementLine.Material_Number__c+Label.UI_Material_Number_Not_Valid_Part2);
            } else if(!boolBypassValidationProfiles && checkAgrmntLIRcrdTypeOpenOffer(objAgreementLine) && !String.isBlank(objAgreementLine.Material_Number__c) && !String.isBlank(objAgreementLine.Customer_Election__c)) {       
                if(mapMaterialNumbertoCustomElection.containsKey(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c)) {
                    checkCustomerElection(objAgreementLine,mapMaterialNumbertoCustomElection,mapAgreementIDtoObj);       
                } else {
                    if(setHandledMaterialNumber.isEmpty() || !setHandledMaterialNumber.contains(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c)) {
                        setHandledMaterialNumber.add(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c);
                        if(mapNewMaterialNumbertoCustomElection.containsKey(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c)) {
                            mapNewMaterialNumbertoCustomElection.get(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c).add(objAgreementLine.Customer_Election__c);
                        } else {
                            mapNewMaterialNumbertoCustomElection.put(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c, new Set<String>{objAgreementLine.Customer_Election__c});
                        }          
                    } else if(setHandledMaterialNumber.contains(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c)) {
                        if(checkCustomerElection(objAgreementLine,mapNewMaterialNumbertoCustomElection,mapAgreementIDtoObj)) {
                            continue;
                        }
                        else
                        {
                            if(mapNewMaterialNumbertoCustomElection.containsKey(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c)) {
                                mapNewMaterialNumbertoCustomElection.get(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c).add(objAgreementLine.Customer_Election__c);
                            } else {
                                mapNewMaterialNumbertoCustomElection.put(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c, new  Set<String>{objAgreementLine.Customer_Election__c});
                            }
                        }
                         
                    }
                }
            }

        }
        ilib_LogEvent.pop();
    }

    /*
    @Author : Parthasarathy D
    @Story :  DCP-56501
    @Description : Method to get the existing Agreement Line Item records
    */
    public Map<String,Set<String>> getExistingALIRecords(Set<Id> setAgreementId,Set<String> setMaterialNumbers,Set<ID> setExistingALI) {
        ilib_LogEvent.push(LOG_TITLE+'.getExistingALIRecords()');
        List<Apttus__AgreementLineItem__c> lstExistingALIRecords = new ApttusAgreementLineItemSelectors().selectAgreementLineItemForMaterialNumber(setAgreementId,setMaterialNumbers);
        Map<String,Set<String>> mapMaterialNumbertoCustomElection = new Map<String,Set<String>>();
        if(!lstExistingALIRecords.isEmpty()) {
            for(Apttus__AgreementLineItem__c objALI : lstExistingALIRecords) {
                if(!setExistingALI.contains(objALI.Id)) {
                    if(mapMaterialNumbertoCustomElection.containsKey(objALI.Material_Number__c+objALI.Apttus__AgreementId__c)) {
                        mapMaterialNumbertoCustomElection.get(objALI.Material_Number__c+objALI.Apttus__AgreementId__c).add(objALI.Customer_Election__c);
                    } else {
                        mapMaterialNumbertoCustomElection.put(objALI.Material_Number__c+objALI.Apttus__AgreementId__c, new Set<String>{objALI.Customer_Election__c});
                    } 
                }
                
            }
        }  
        ilib_LogEvent.pop();   
        return mapMaterialNumbertoCustomElection;     
         
    }

    /*
    @Author : Parthasarathy D
    @Story :  DCP-56501
    @Description : Method to check for the validation.
    */
    public boolean checkCustomerElection(Apttus__AgreementLineItem__c objAgreementLine, Map<String,Set<String>> mapMaterialNumberToCustomerElection, Map<Id, Apttus__APTS_Agreement__c> mapAgreementIDtoObj) {
        ilib_LogEvent.push(LOG_TITLE+'.checkCustomerElection()');
        Boolean errorFlag = false;
        Boolean boolIsAgreementIsInAmendStatus = mapAgreementIDtoObj.get(objAgreementLine.Apttus__AgreementId__c)?.Apttus__Status__c == Label.UI_Label_Agreement_Status_In_Amendment;
        Boolean boolIsAgreementhasParent = mapAgreementIDtoObj.get(objAgreementLine.Apttus__AgreementId__c)?.Parent_Agreement_Number__c != null;
        Boolean boolIsAgreementIsInAmendment = boolIsAgreementIsInAmendStatus && boolIsAgreementhasParent;
        Boolean boolCustElecPSP = objAgreementLine.Customer_Election__c == Label.CustomElectionPickListPSP;
        Boolean boolCustElecQuote = objAgreementLine.Customer_Election__c == Label.CustomElectionPickListQuote;
        Boolean boolCustElecSA = objAgreementLine.Customer_Election__c == Label.CustomElectionPickListSupplyAgreement;
        Boolean boolCustElecUG = objAgreementLine.Customer_Election__c == Label.CustomElectionPickListUniversalGrid;
        Boolean boolAlreadyHasUG = mapMaterialNumberToCustomerElection.get(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c).contains(Label.CustomElectionPickListUniversalGrid);
        Boolean boolAlreadyHasSA = mapMaterialNumberToCustomerElection.get(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c).contains(Label.CustomElectionPickListSupplyAgreement);
        Boolean boolSameMaterialNumber = mapMaterialNumberToCustomerElection.get(objAgreementLine.Material_Number__c+objAgreementLine.Apttus__AgreementId__c).contains(objAgreementLine.Customer_Election__c);
        if(!boolIsAgreementIsInAmendment) {
            errorFlag =true;
            if(boolSameMaterialNumber) {
                objAgreementLine.adderror(Label.ErrorMessageForOpenOfferCustElectionValidation);
            } else {
                objAgreementLine.adderror(Label.ErrorMessageForOpenOfferSameMaterialValidation);
            }
        }else if(boolIsAgreementIsInAmendment && (boolCustElecPSP || boolCustElecQuote || (boolCustElecSA && !boolAlreadyHasSA) || (boolCustElecUG && !boolAlreadyHasSA && !(boolAlreadyHasUG && objAgreementLine.id!=null)))) { // Amendments
            errorFlag =true;
            if(boolSameMaterialNumber) {
                objAgreementLine.adderror(Label.ErrorMessageForOpenOfferCustElectionValidation);
            } else {
                objAgreementLine.adderror(Label.ErrorMessageForOpenOfferSameMaterialValidation);
            }
        }              
        ilib_LogEvent.pop();
        return errorFlag;
    }
}
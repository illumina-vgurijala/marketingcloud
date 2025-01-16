/****************************************************************************************************************************************
* NAME         : Cases
* DESCRIPTION  : Domain class for Case
*                    
* @AUTHOR : Veerendra
* @DATE   : 06-Jun-2018  
* @testclasses : TestCases
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Veerendra               06-Jun-2018          Initial Version. Create Entitlement records when Case is created
* Nitin                   07-July-2018         To add consequnces code to case if the PAE/PFA question is answered Yes.
* Shashank              15-July-2018           To make changes for change in data model of Code_Library__c as per DCP-837 
* Shashank              24-July-2018           To disassociate codes on Cases when pAE/pFA question is answered as no as per DCP-8176 
* Shashank              01-August-2018         changes for GIS Review comments for DCP-616
* Shashank              7-September-2018         DCP-8815 
* Tapas          16-May-2019         for DCP-25233 and 25243 created createAssociatedCode method. 
* KD                    14-May-2020             DCP-37743 : Removed validation related to Date_of_Issue_Awareness__c            

* KD                    20-May-2020             DCP-37743 : Removed validation related to Hazard_Code__c      
*Adyasha                04-March-2021           DCP-44980 : Added check to update IVD Product Identifier(Additional Prod) to 
                                                false if QA Review = "Non IVD Product" and vice versa    
*Nitin                  11-March-2021           Refactored whole class and introduced a new framework
*Vignesh                20-Jun-2021             DCP-46053 - Updated Logic to populate Product Lot NUmber/Product Serial Number field
*Nishan Shetty          9-Aug-2021             CMCP-23 : Updated caseFieldAssingments(),populateCaseOwnersManager() and created updatePartnerCaseFlag
                                                methods to include logic to identify Case as Partner Case.  
*Rishi Sharma           30-Aug-2021             DCP-47271 : Created updateWOReopenedCase method to update Work Order field on Case when a 
                                                case is reopened BeforeUpdate.                                               
*Nishan                 15-Sep-2021             CMCP-22 Request GTS Work Order Relocations.
*Gladis                 03-Mar-2022             QACM-4/QACM-267 "Potentially Reportable" field cannot be edited when the Status is Completed/Closed.
*Abhinav                09-Mar-2022             QACM-5 Whenever QA Profiles update QA Reopen Code(s) then populate Reason for Reopen Field
*Gladis                 09-Mar-2022             QACM-123 Edit QA review section only in Non-closed statuses.
*Nishan Shetty          22-Sept-2021            CMCP-64 - Updating Request Ownership Status to Completed. 
*Preetha                14-Mar-2022             QACM-18 Added checkShowOnCaseOnAP medthod check for Show on case AP
*Nishan Shetty          22-Sept-2021            CMCP-64 - Updating Request Ownership Status to Completed.  
*Romi Taskar            22-March-2022           DCP-46058 - Adding Profile check for FS profile to update Record type and Order Type.
*Preetha                25-Mar-2022             QACM-82 validateProductUtilizationMode to check Product Utilization Mode/AutoUpdate RUO before completing a case
*Gladis                 19-Apr-2022             QACM-14/QACM-672 Added method validateNullQualityJuncRecords to throw error when there are no QualityJuncRecords are populated upon Case closure.
*Susmitha               26-Aug-2022             QACm-108 Disassociate codes and update code title on Associated codes on RT chnage
* Preetha               30-Aug-2022             QACM-782 Added chatterPostNotification to post chatter notification on Product Utilization change
* Gladis                08-Sep-2022             DCP-55963 Updated error messages and added the final static strings to labels.
*Sagar                  01-Sep-2022             DCP-51201: To Send Case information to medical Affairs(Veeva)    
* Rohan                 20-Dec-2022             DCP-56388: Validation on Case for Elevated cases if subtype is updated  
*Pooja                  13-Dec-2022             POL-51 : To update case region to account's territory region for reopen cases
*Shivani                03-Jan-2023             DCP-52634 - Populate Subecription on Work Order creation
*Abhishek               13-Jul-2023             CMCM-204 - Removed the checkWorkFlowUpdateSentToQualtrics function and added this functionality into Case Record-Trigger After Save : Qualtrics flow
*Chaitanya              14-Jul-2023             CMCM-163 - Removed the case:Qualtrics Surveys: TS/FS= Business Issue apex peace of code  and added this functionality into Case Record-Trigger After Save : Qualtrics flow
*Abhishek               22-Sept-2023            CMCM-3533 - Added the updateAnaysisCode method to update Contains_Logistics_Analysis_Code__c field
*Abhishek               22-Nov-2023             CMCM-263 -  called addAssociatedProductsOnCaseCreation method to create Associatd Product
*Dhairya Shah           17 April 2024           CMCM-6760 - Removed the method -checkShowOnCaseOnAP() -caseLineRecordHelper()
*Nitin Zagade           14 Aug 2024             CMCM-9391
****************************************************************************************************************************************/ 
public with sharing class Cases extends ilib_SObjectDomain {

    public static final String STRING_PAE_PFA_ANSWER_YES = 'Yes';
    public static final String STRING_PAE_PFA_ANSWER_NO = 'No';
    public static final String STRING_IN_PROGRESS ='In Progress';
    public static final String STRING_COMPLETED ='Completed';
    public static final String STRING_PENDING_QA_REVIEW='Pending QA Review';
    public static final String STRING_CASE_RECORD_EDIT_SOURCE_CLONE_CASE_SFM='Clone Case SFM';
    public static final String STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS='Web - My Illumina - CS';
    public static final String STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_TS='Web - My Illumina - TS';
    public static final String STRING_CASE_ORIGIN_WECHAT ='WeChat - TS';//DCP-46141
    public static boolean blnCheckValidation = false;
    public static final String STRING_CUSTOMER_SERVICE='Customer Service';
    public static final String STRING_TECHNICAL_SUPPORT='Technical Support';
    public static final String STRING_PRIMARY_FS_ENGINEER='Primary Field Service Engineer';    
    public static final string STRING_CASE_STATUS_CLOSED_DUPLICATE = 'Closed-Duplicate';
    public static final String STRING_PROACTIVE_INTEGRATION_USER = 'Integration';  
    public static final String STRING_PAE_PFA_EVALUATION_STATUS = 'Pending';
    public static final String STRING_QA_REVIEW_NO_IVD_PRODUCT = 'Non IVD Product';//DCP-44980
    public static final String STRING_AWAITING_RESPONSE_CUSTOMER='Awaiting Response - Customer';
    public static final String STRING_AWAITING_RESPONSE_INTERNAL='Awaiting Response - Internal';
    public static boolean allowUpdateOnCase = true; 
    public static final List<String> LST_SERVICE_PROFILES = new List<String>{STRING_CUSTOMER_SERVICE,'Field Service',STRING_TECHNICAL_SUPPORT};
    public static final set<string> SET_COMPLETED_CASE_STATUS = new set<string>{Label.CaseStatusCompleted, Label.CaseStatusPendingLogisticsReview, Label.CaseStatusPendingQAReview, Label.CaseStatusReopenRequested,
                                            Label.CaseStatusClosedDuplicate, Label.CaseStatusClosed};
    public static final Set<String> SET_WO_INTEGRATION_STATUS_SUCCESS = new Set<String> { 'Success', 'Not Required', '' };
    
    public static final set<string> SET_CASE_PRE_COMPLETION_STATUS = new set<string>{'Initiated',STRING_IN_PROGRESS, 'Reopened'};
    public static final String STRING_CREATE_TIME_IN_STATE_RECORDS ='createTimeInStateRecords';
    public static final String STRING_CASE_QUEUEABLE ='CaseQueueable';
    public static boolean runTimeInStateCreationOnInsert = true;
    public static boolean runTimeInStateUpdateStatusOnce = true;
    public static boolean runTimeInStateCreationOnce = true;    
    public static final String STRING_INSTALLED_PRODUCT_FIELD_API_NAME = 'SVMXC__Component__c';
    public static final String STRING_LOCATION_FIELD_API_NAME = 'SVMXC__Site__c';
    public static final String STRING_CASE_STATUS='Case Status';
    public static final String STRING_UNCHECKCLOSEDWITHASSOCIATEDCODES = 'uncheckClosedWithAssociatedCodes'; 
    public static final String STRING_GTS_STATUS_REQUEST_INITIATED = 'Request Initiated';//CMCP-22
    public static Set<String> setAsynchoronousMethods = new Set<String>();
    private static final String CODEPARAMETERACRHISTORYTRACKINGFIELDS = 'Case_Fields_To_Track'; //QACM-5
    public static final String STRING_QA_REVIEW_REQUEST_UPDATE = 'QA Review Request Update: '; //qacm-5
    // Record Type Ids
    // Record Type Ids    
    public static final Id SERVICE_REQUEST_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId(); //QACM-108
    public static final Id BUSINESS_ISSUE_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();     
    public static final Id INQUIRY_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
    public static final String STRING_WORK_ORDER_RT_REMOTE_SUPPORT = 'Remote Support';
	public static final String STRING_WORK_ORDER_RT_FIELD_SERVICE = 'Field Service'; //DCP - 46058
    public static final string STRING_LABEL_SERVICE_ACTIVITIES = 'Service Activities'; //DCP - 46058
	public static final string STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED = 'Assignment Accepted';//DCP - 46058
    public static final String STRING_DISASSOCIATECODES_RECORDS ='updateCodeTitleonRTChange';//QACM-108 added

    public static final String STRING_REQUESTED ='Requested';//CMCP-64
	public static  Boolean isDistrictRegionUpdated = false; //PRB0044921

    //QACM-18 Starts
    public static final String STRING_CASE_SUBTYPE_COMPLAINT = 'Complaint';
    public static final String STRING_CLOSED = 'Closed';
    public static Boolean isShowOnCaseRecord = false;
    //QACM-18 Ends

    public static final String QA_REVIEW_REFER_EXISTING_OR_PRIOR_INVESTIGATION ='Refer to Existing/Prior Investigation';//QACM-14/QACM-672
    public static final String QA_REVIEW_FURTHER_INVESTIGATION_REQUIRED ='Further Investigation Required';//QACM-14/QACM-672
     
     public static Boolean isIVDAssociatedProd = false;//CMCM-7245
     public static final String STRING_RUO = 'RUO';//QACM-82



    //Error Messages
	public static set<String> setErrMessages = new set<String>();
    /* DCP-55963 starts- Updated the error messages and added them as labels*/
    public static final String CHECK_PROFILE_ON_NOTIFICATION_BUTTON = Label.CaseErrorMessage_CHECK_PROFILE_ON_NOTIFICATION_BUTTON;
    public static final String CHECK_CASE_TYPE_ON_NOTIFICATION_BUTTON = Label.CaseErrorMessage_CHECK_CASE_TYPE_ON_NOTIFICATION_BUTTON;
    public static final String STRING_SELECT_CONTACT_ON_IP = Label.CaseErrorMessage_STRING_SELECT_CONTACT_ON_IP; 
    public static final String STRING_PAE_PFA_ERROR_MESSAGE = Label.CaseErrorMessage_STRING_PAE_PFA_ERROR_MESSAGE;
    public static final String STRING_SELECT_CONTACT_ON_ACCOUNT = Label.CaseErrorMessage_STRING_SELECT_CONTACT_ON_ACCOUNT;
    public static final String STRING_PAE_PFA_EVALUATION_REQUIRED =  Label.CaseErrorMessage_STRING_PAE_PFA_EVALUATION_REQUIRED;
    public static final String STRING_PAE_PFA_ANSWER_ALL_OR_NONE = Label.CaseErrorMessage_STRING_PAE_PFA_ANSWER_ALL_OR_NONE;
    public static final String STRING_PAE_PFA_ANSWER_ALL =  Label.CaseErrorMessage_STRING_PAE_PFA_ANSWER_ALL;
    public static final String STRING_AWARENESS_DATE_CANNOT_BE_CHANGED = Label.CaseErrorMessage_STRING_AWARENESS_DATE_CANNOT_BE_CHANGED;
    public static final String STRING_EDIT_QA_REVIEW_SECTION = Label.CaseErrorMessage_STRING_EDIT_QA_REVIEW_SECTION;
    public static final String STRING_ERROR_MESSAGE_FOR_PAE_PFA_NO = Label.CaseErrorMessage_STRING_ERROR_MESSAGE_FOR_PAE_PFA_NO;
    public static final String STRING_ERROR_MESSAGE_FOR_CASE_COMPLETION =Label.CaseErrorMessage_STRING_ERROR_MESSAGE_FOR_CASE_COMPLETION;
    public static final String STRING_ERROR_MESSAGE_FOR_IVD_PRODUCT =Label.CaseErrorMessage_STRING_ERROR_MESSAGE_FOR_IVD_PRODUCT;
    public static final String STRING_ERROR_MESSAGE1_FOR_AWARENESS_DATE = Label.CaseErrorMessage_STRING_ERROR_MESSAGE1_FOR_AWARENESS_DATE;
    public static final String STRING_ERROR_MESSAGE_FOR_CLOSE_DUPLICATE = Label.CaseErrorMessage_STRING_ERROR_MESSAGE_FOR_CLOSE_DUPLICATE;
    public static final String STRING_INVESTIGATION_SUMMERY_ERROR_MESSAGE = Label.CaseErrorMessage_STRING_INVESTIGATION_SUMMERY_ERROR_MESSAGE; 
    public static final String STRING_CASE_COMPLETION_ERROR_MESSAGE = Label.CaseErrorMessage_STRING_CASE_COMPLETION_ERROR_MESSAGE;
    /* DCP-55963 ends*/
    public static final String STRING_SER_REQUEST_CODE='SER Request for Install';
    public static final String STRING_SHOW_ON_CASE_ERROR_MESSAGE = '"Show on Case" is not checked on any case Associated Product (AP). Select "Show on Case" for the most relevant AP.';//QACM-18
    public static final String STRING_PRD_UTILIZATION_MODE_ERROR_MESSAGE = 'Product Utilization Mode is required for IVD Complaint cases. Populate Product Utilization Mode before completing this case.';//QACM-82
    
    //*************************static lists for storing queried data throughout transactions**********************
    public static string loggedInUserProfileName;
    public static Map<Id,Contact> mapContactIdToContactForSuppliedEmail; 
    public static Map<Id,Contact> mapContactIdToContact;
    public static Map<Id,Account> mapAccountIdToAccount;
    public static Map<Id, UserTerritory2Association> mapIdToUserTerritory2Association;
    public static Map<Id, User> mapUserIdToUser;
    public static Map<Id, SVMXC__Installed_Product__c> mapIPIdToIPDetails;
    public static Map<Id, Case_Routing_Criteria_Mappings__mdt> mapIdToRoutingCriteria;
    public static Map<Id, Case_Routing_Criteria_Mappings__mdt> mapIdToInternalNonCustomerCriteria;
    public static Map<Id, Associated_Code_Mapping__mdt> mapAssociatedCodesMapping;
    public static Map<String, Id> mapGroupNameToGroupId;
    public static Map<Id, AccountContactRelation> mapACRelationIdToACRelation;
    public static Map<Id, Associated_Product__c> mapAPidToAssociatedProductDetails;
    public static Set<String> setGroupNames = new Set<String>{System.label.CS_Globally_Unassigned_Email};//INC0379775
    public static Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrders;
    public static Map<Id, Associated_Codes__c> mapAssociatedCodeIdsToAssociatedCodes;   
    public static Map<Id, Code_Library__c>  mapCodeLibraryIdsToRec;
    public static Map<Id, Case> mapParentCaseIdToParentCase;
    public static Map<Id, caseTeamRole> mapIdToCaseTeamRole;
    public static Map<Id, Account_to_Field_Support__c> mapAccToFieldSelctrIDToDetails;
	public static Map<Id, CaseTeamTemplate> mapIdToCaseTeamTemplate;
	public static Map<Id, CaseTeamMember> mapIdToCaseTeamMember;
    //DCP-47530
    public static boolean bypassStatusEditValidationForTPSP = false;
    public static final String STRING_STATUS_EDIT_ERROR_MESSAGE = 'Case Status cannot be edited by Third Party Service Users Manually.';
    public static final String LOG_TITLE = 'Cases';
    public static List<Associated_Codes__c> lstAssociationCodesToInsert = new List<Associated_Codes__c>();
    public static Boolean createInstallServiceRequestCode = false;
    public static Map<Id,List<Case>> mapAccountIdtoCases=new  Map<Id,List<Case>>();//CMCP-23
    public static Map<Id, SVMXC__Case_Line__c> mapShowOnCaseLineIdToCases;//QACM-18
    //QACM-82
     public static Map<Id, Associated_product__c> mapIVDAssociatedProductIdToCases;
     public static Map<id,Case> mapCaseProductDetails;

     //DCP-53957
     public static final String STRING_GUEST='Guest';
     public static final String CODE_DISASSOCIATED='Code Disassociated';
     public static final String CASE_OF_REOPENED_DENIED='CaseOfReopenDenied';
     public static final String CASE_OF_REOPEN_STATUS='CaseOfReopenStatus';
     public static final String CASE_OF_LOCATION_CHANGE='CaseOfLocationChange';
     public static final String SUBJECT_DESC_OTHERS_CHANGE='SubjectDescriptionOthersChange';
     public static final String STRING_USER_ID_005='005';
     public static final String INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE= 'insertEntitlementAndcheckContractCoverage';
     public static Boolean isrecordupdatedfromSFM=false;
     public static final Set<String> SET_CASE_CAREGORIES = new Set<String>{'Change Order Confirmation', 'Conversion / Ship Schedule', 'MyIllumina', 'Order Expedite', 'Order Status', 'Question', 'Quotes', 'Response' };      
     public static final Set<String> SET_COMPLETED_CASE_STATUSES = new Set<String>{STRING_COMPLETED, STRING_CLOSED, 'Pending Logistics Review', STRING_PENDING_QA_REVIEW};
     //QACM-123 set of string with non-closed statuses 
     public static final Set<String> SET_STATUS_FOR_QAREVIEW= new Set<String>{STRING_COMPLETED,STRING_CLOSED,STRING_CASE_STATUS_CLOSED_DUPLICATE};   
         
     //DCP-51201
     public static final string CASE_CREATION_INITIATED='Case Creation Initiated';
     //DCP-52634
    public static Map<Id, SVMXC__Service_Contract__c> mapSubscriptionIdToSubDetails  = new Map<Id, SVMXC__Service_Contract__c>();
    //CMCM-196
    public static Map<Id, List<SVMXC__Service_Order__c>> mapCaseIdWorkOrders = new map<id, List<SVMXC__Service_Order__c>>();
    public static Id idQueueId;
    public static Boolean skipCaseTrigger = false;
    public static boolean isPrimaryAPUpdate = false;
    public static boolean isIVDProductIdentifierAdditionalProdUpdated= false;
    // CMCM-263
    public static List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
    // CMCM-6731
    public static final String CASE_OPTIMIZATION = 'CaseOptimization';
    public static List<SVMXC__Service_Contract__c> lstSubscription = new List<SVMXC__Service_Contract__c>();
    public static List<Product2> productsList = new List<Product2>(); 
    public static Group technicalSupportQueue;
    public static List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
    public static List<SVMXC__Service_Order__c> updateCaseQualifyCompletionWorkOrder = new List<SVMXC__Service_Order__c>();
    public static List<Case> qualtricsCase = new List<Case>();
    public static List<Case> sendGTSCase = new List<Case>();
    public static List<Case> caseWithNOQualityList = new List<case>();
    public static List<SVMXC__Service_Order__c> elevatedWOList = new List<SVMXC__Service_Order__c>();
    public static Map<String, List<String>> mapFieldsToBeByPassed = new Map<String, List<String>> ();

    public static Boolean bypasscheckpAEpFAAwarenessDateEvaluation = false; //bypass validation error in checkpAEpFAAwarenessDateEvaluation method CMCM-13337
    //*****************************************************************************************************************
    
	/*
     * Constructor for Cases
     */
    public Cases(List<Case> sObjectList) {
        super(sObjectList);

        //DCP-46141 - Bypass for weChat profile charket user
        if (FeatureManagement.checkPermission('Bypass_Person_Object_Permission')){
            configuration.disableTriggerCRUDSecurity();
            
        ilib_LogEvent.rootTitle = LOG_TITLE;
    }
}   
/*
 * Boilerplate which is required for base class instantiation logic
 */
public class Constructor implements ilib_SObjectDomain.IConstructable 
{
    /* Param - sobjectList */
    public ilib_SObjectDomain construct(List<SObject> sObjectList) {
        return new Cases(sObjectList);  
    }
}
    
    /**
    *  @author Nitin Sood
    *  @description - 
    *                 To be executed, when the Case is inserted. 
    *                 Checks pFA/pAE Evaluation for IVD and non IVD Products
    *  @PARAM :  
    *  @RETURN:  void
    */   
    public override void onBeforeInsert()
    { 
        if(!skipCaseTrigger){
        flipNewCaseToInprogress(records);    
        //Assigining values to case fields for diferent scenarios
        caseFieldAssingments(records, null);
        //validations for pAE pFA Evaluation question answers 
        checkpAEpFAEvaluation((List<Case>)records, null);
        //populate Account and Contact for supplied Email if supplied email is not blank
        populateAccountContactForSuppliedEmail(records);            
        validateAccountContactIPOnCase(records, null);
        populateLocationProductUpgradeType(records, null);
		
        PopulateDistrictRegion_CaseHelper.populateDistrictRegionOnCase(records, null);
        populateShipToCountryOnCase(records);
        populateCaseOwnersManager(records, null);
                   
        markCaseAsSpam(records);
        populateOwnerAsServiceQueue(records, null);
        populateCustomerNotificationEmailAddress(records, null);
        clearInactiveContactOnCase(records);
        populateCasesToPrediction(records);
        markHasSRServiceRequestCodeTrue(records);
        populateInternalNonCustomer(records);
        updateAnaysisCode(records); // CMCM-3533
        }
        if(isPrimaryAPUpdate){
        validateAccountContactIPOnCase(records, null);
        populateLocationProductUpgradeType(records, null);
        }
    }
    
	/*
     * Description - onBeforeupdate method
	 * return - void
     */
    public override void onBeforeupdate(Map<Id, SObject> oldRecords)
    {     
        if(!skipCaseTrigger){
        queryRecordsforExecution(records, oldRecords);//POL-51
        //Assigining values to case fields for diferent scenarios
        caseFieldAssingments(records, oldRecords );
        caseFieldAssingmentsBeforeUpdate(records, oldRecords);
		
        PopulateDistrictRegion_CaseHelper.populateDistrictRegionOnCase(records, oldRecords);
        populateCaseOwnersManager(records, oldRecords);

        validateAccountContactIPOnCase(records, oldRecords);
        populateLocationProductUpgradeType(records, oldRecords );
        
        checkWorkOrderForCaseCompletion(records, oldRecords);
        populateOwnerAsServiceQueue(records, oldRecords);
        populateCustomerNotificationEmailAddress(records, oldRecords);
        ValidateClosedDuplicate_CaseHelper.checkForClosedDuplicateCases(records, oldRecords);
		//validations for pAE pFA Evaluation question answers 
        checkpAEpFAEvaluation((List<Case>)records, oldRecords);  
        CreateAssociatedCode_CaseHelper.fetchCodeTitleFromCase(records, (Map<Id,Case>)oldRecords);
        //DCP-47271 - Update Work Order field on case if a old case is reopened
        updateWOReopenedCase(records, (Map<Id,Case>)oldRecords);
        //DCP-28102
        checkCaseEdit((List<Case>)records , oldRecords);
        //DCP-47530
        validateStatusEditForTPSPUser(records, oldRecords);
        //START CMCP-22
        validateCaseWorkAssociationForGTS(records,oldRecords);
        //END CMCP-22
        allowUpdateOnCase=false;
        //DCP-49922
        populateInternalNonCustomerForTS(records,oldRecords);
        //QACM-5
        checkIfReopenCodesUpdated(records, oldRecords);
        //QACM-82
        validateProductUtilizationMode(records,oldRecords);

        //QACM-8
        populateQACompletionDate(records,oldRecords);
        //QACM-14/QACM-672
        validateNullQualityJuncRecords(records,oldRecords);
        //DCP-56388
        checkSubTypeEditForOpenElevation(records,oldRecords);
        updateAnaysisCode(records); // CMCM-3533
         //CMCM-9391
        CaseWO_POlHelper.validateReturnPartOrder(records,(Map<Id,Case>)oldRecords);
        //CMCM-10196
        SetBlankValuesonCase_CaseHelper.setBlankValueOnRecallFields(records,(Map<Id,Case>)oldRecords);
        }
        if(isPrimaryAPUpdate){
        validateAccountContactIPOnCase(records, oldRecords);
        populateLocationProductUpgradeType(records, oldRecords );
        } 
        //CMCM-8106
        if (isIVDProductIdentifierAdditionalProdUpdated) {
            checkpAEpFAEvaluation((List<Case>)records, oldRecords);
        } 
       
    }
	/*
     * Description - onAfterInsert method
	 * return - void
     */
    public override void onAfterInsert()
    { 
        if(!skipCaseTrigger){
        createWorkOrder(records, null);
        asynchoronousMethodCallsAfterInsert(records);
        insertSerReqCodeForInstallCases(records);
        // CMCM-263
        //CMCM - 7542 Added isTestrunning condition with featureflag.
        if(Feature.isOn('ServiceAssociatedProducts') || AssociatedProduct.isTestRunning) {
            AssociatedProduct.addAssociatedProductsOnCaseCreation(records,workOrderList);
        }
        }
    }
    
	/*
     * Description - onAfterUpdate method
	 * return - void
     */
    public override void onAfterUpdate(Map<Id, SObject> mapOld) {   
        if(!skipCaseTrigger){
        // CMCM-11352
        UpdateAPwithIPProductSub_CaseHelper.isCaseIPProdorSUbchanged((List<Case>)records, (Map<Id,Case>)mapOld, workOrderList);
        setIsReopenApproved(records,mapOld);
        createWorkOrder(records, (Map<Id,Case>)mapOld); 
        insertAssociatedCodes();
        UpdateWorkOrder_CaseHelper.updateWorkOrderForVariousConditions(records, (Map<Id,Case>)mapOld);        
        asynchoronousMethodCallsAfterupdate(records, (Map<Id,Case>)mapOld );
        //QACM-5
        createHistoryRecord(records,mapOld);
        
        //Dummy commit
        chatterPostNotification(records, (Map<Id,Case>)mapOld);
        }
        //CMCM-8106
        if (isIVDProductIdentifierAdditionalProdUpdated) {
            asynchoronousMethodCallsAfterupdate(records, (Map<Id,Case>)mapOld );
        }  
    }   

    //***********************functional methods for before insert event starts***********************************   
	
	/*
     * Description - caseFieldAssingments method
	 * return - void
     */
    public void caseFieldAssingments(List<Sobject> records, Map<Id, SObject> oldRecords) {
        CasesHelper.Profiles profilesQuery = new CasesHelper.Profiles();        
        profilesQuery.initLoggedInProfileName();      
        for(Case objCase : (List<Case>)records) {
            Case objOldCase = null;   
            if(oldRecords != null && !oldRecords.isEmpty()) {
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            if(Trigger.isInsert) {                               
                //populating original customer input with description
                if(originCheck(objCase)) {
                    objCase.Original_Customer_Input__c = objCase.Description;
                }
                //Start(CMCP-23)-setting Partner Case flag to True if Case is created by Channel Partner user.
                if(channelPartnerCheck(objCase)) {
                    objCase.Partner_Case__c = true; 
                 }
                 //End(CMCP-23)

            }
            if(Trigger.isInsert || Trigger.isUpdate) {
                if(statuschek(objOldCase,objCase)) {
                    objCase.First_Call_Resolution__c = false;
                }
                if(objOldCase == null ||(objOldCase != null && objCase.Description != objOldCase.Description)) {
                    objCase.Short_Description__c=objCase.Description;
                }
    
            }
        }
            updatePartnerCase(records,oldRecords);
    }
    private static boolean originCheck(Case objCase) {
       return objCase.Origin != null && (objCase.Origin.equals(STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS)|| objCase.Origin.equals(STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_TS)) && (loggedInUserProfileName == 'Integration MyIllumina P2P Service' || loggedInUserProfileName == 'Integration MyIllumina P2P Contacts');
    }
    private static boolean channelPartnerCheck(Case objCase) {
       return Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileId()).Is_Channel_Partner__c && !objCase.Partner_Case__c;
    }
    private static boolean statuschek(Case objOldCase, Case objCase) {
        return (objOldCase == null || (objOldCase != null && objCase.Status != objOldCase.Status)) && objCase.status != null && objCase.status.equals(System.label.CaseStatusReopenedInProgress) && objCase.First_Call_Resolution__c == true;
    }
    private static void updatePartnerCase(List<Sobject> records, Map<Id, SObject> oldRecords) {
		Map<Id,List<Case>> mapAccountIdtoListCases = new Map<Id,List<Case>>();//CMCP-23

        for(Case objCase : (List<Case>)records) {
            //START CMCP-23 [Storing Account Id to Cases]
            Case objOldCase = null;   
            if(oldRecords != null && !oldRecords.isEmpty()) {
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            if((Trigger.isInsert || (objOldCase != null && objOldCase.AccountId!=objCase.AccountId)) && objCase.AccountId != null) {
                if(mapAccountIdtoListCases.containsKey(objCase.AccountId)) {
                    mapAccountIdtoListCases.get(objCase.AccountId).add(objCase);
                } else {
                    mapAccountIdtoListCases.put(objCase.AccountId,new List<Case>{objCase});
                }
        }
         //END CMCP-23
        }
        //START CMCP-23
        if(UserInfo.getUserType()!= STRING_GUEST) {
            updatePartnerCaseFlag(mapAccountIdtoListCases);
        }
        //END CMCP-23
    }
    /**
    *  @author Deepika Ayyavari
    *  @description - Check Internal Non customer checkbox.
    *                 
    *  @PARAM :  List<Case> lstNewCases
    *  @RETURN:  void
    */ 

    public void populateInternalNonCustomer (List<Sobject> records) {
        try {
            // Added condition for CMCM - 10026
            Set<Id> inqCaseIds = new Set<Id> ();
            for(Case objCase : (List<Case>)records) {
                if(objCase.RecordTypeId == INQUIRY_CASE_RECORDTYPE &&  objCase.Internal_Non_Customer__c!=true && objCase.Origin == 'Email - CS' && objCase.SuppliedEmail !=null) {
                    inqCaseIds.add(objCase.Id);
                }
            }
            if (inqCaseIds != null && !inqCaseIds.isEmpty()) {
                CasesHelper.InternalNonCustomerCriteriaMapping internalNonCustomerMappingQuery = new  CasesHelper.InternalNonCustomerCriteriaMapping();   
                internalNonCustomerMappingQuery.initMapInternalNonCustomerCriteriaMappings();
            }
            // Condition for CMCM - 10026 Ended
            for(Case objCase : (List<Case>)records) {
                Boolean emailMatchResult = false;
                if(objCase.RecordTypeId == INQUIRY_CASE_RECORDTYPE &&  objCase.Internal_Non_Customer__c!=true && objCase.Origin == 'Email - CS' && objCase.SuppliedEmail !=null) {
                    for(Case_Routing_Criteria_Mappings__mdt caseSpamRec : mapIdToInternalNonCustomerCriteria.values()) {
                        if(caseSpamRec.From_Addresses__c != null) {
                            Matcher matcher = Pattern.compile(caseSpamRec.From_Addresses__c.toLowerCase()).matcher(objCase.SuppliedEmail.toLowerCase());
                            system.debug('matcher:' +matcher);
                            emailMatchResult = matcher.find();  
                            system.debug('emailMatchResult:' +emailMatchResult);
                        }
                        
                            //populating internal non customer for Inquiry cases
                            if(caseSpamRec.From_Addresses__c != null && emailMatchResult == True) {
                            objCase.Internal_Non_Customer__c = true;
                            break;
                            }
                    }
                }
            }
        } Catch(Exception e) {
            System.debug(e.getmessage());
            ApexExceptions.emit('Cases.populateInternalNonCustomer',e);
        }
            
    }

    /**
    *  @author Deepika Ayyavari
    *  @description - Check Internal Non customer checkbox for TS.
    *  @PARAM :  List<Case> lstNewCases              
    *  @PARAM :  Map<Id,Case> OldMap
    *  @RETURN:  void
    */ 

    public void populateInternalNonCustomerForTS (List<Sobject> records, Map<Id, SObject> oldRecords) {
        Map<String, String> queueNameToIdMap = UtilsSettings.getCustomMetadataMap('Queue_Ids');

        for(Case objCase : (List<Case>)records) {
            Case objOldCase=null;   
            
            if(oldRecords!=null && !oldRecords.isEmpty()) {
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            if(objOldCase != null && objCase.OwnerId != objOldCase.OwnerId && (objCase.ownerId == queueNameToIdMap.get('Technical_Support') || objCase.ownerId == queueNameToIdMap.get('China_Technical_Support'))) {
                objCase.Internal_Non_Customer__c = false; 
            }               
        }
    }
    
    /*
     * Description - populateAccountContactForSuppliedEmail method
	 * return - void
     */
    public void populateAccountContactForSuppliedEmail(List<Sobject> records) {
            
        Map<string,Contact> mapWebEmailToContact = new map <string,contact>();      
        set<String> setEmails = new Set<String>();  
        
        for(Case objCase : (List<Case>)records) {        
            if(objCase.Origin!=null && objCase.Origin.equals(STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS)) {

                if(objCase.SuppliedEmail!=null) {
                    setEmails.add(objCase.SuppliedEmail);
                }
            }
        }
        
        if(setEmails!=null && !setEmails.isEmpty()) {
			CasesHelper.Contacts contactsQuery = new  CasesHelper.Contacts();			
            contactsQuery.initMapContactIdToContact(setEmails);
            if(mapContactIdToContactForSuppliedEmail != null && mapContactIdToContactForSuppliedEmail.values().size()==1) {                  
                for(Contact con: mapContactIdToContactForSuppliedEmail.values()) {
                    mapWebEmailToContact.put(con.email,con);
                }
            }
        }
        if(mapWebEmailToContact!=NULL && !mapWebEmailToContact.isEmpty()) {
            for(Case objCases : (List<Case>)records) {
                if(mapWebEmailToContact.get(objCases.SuppliedEmail)!=null) {
                    objCases.AccountId = mapWebEmailToContact.get(objCases.SuppliedEmail).AccountId;
                    objCases.ContactId = mapWebEmailToContact.get(objCases.SuppliedEmail).Id;  
                }
            }   
        }
                    
    }

	/*
     * Description - populateShipToCountryOnCase method
	 * return - void
     */
    public void populateShipToCountryOnCase(List<Sobject> records){
        Set<Id> setAccountId =  new Set<Id>();
        
        for(Case objCase : (List<Case>)records) {
            if(objCase.AccountId != null ){
                setAccountId.add(objCase.AccountId);
            }
            
            CasesHelper.Accounts accountQuery = new  CasesHelper.Accounts();		
            accountQuery.initMapAccountIdToAccount(setAccountId);
            if(objCase.AccountId !=null && mapAccountIdToAccount!=null && mapAccountIdToAccount.containskey(objCase.AccountId) && mapAccountIdToAccount.get(objCase.AccountId).BillingCountry !=null) {
                objCase.Ship_to_Country__c = mapAccountIdToAccount.get(objCase.AccountId).BillingCountry;               
            }
        }
        
    }

    /**
    *  @author 
    *  @description - Populate Case Owner Manager Fields.
    *                 
    *  @PARAM :  List<Case> lstNewCases
    *  @PARAM :  Map<Id,Case> OldMap
    *  @RETURN:  void
    */ 
    public void populateCaseOwnersManager(List<Sobject> records, Map<Id, SObject> oldRecords) {
         Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToPFSERoles = new Map<Id,Map<String,Account_to_Field_Support__c>>();
         set<String> cpAccounts = new Set<String>();         
         cpAccounts = populateCaseOwnersManagerHelper(records,oldRecords);
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        Set<String>  setFSERoles = new Set<String>{STRING_PRIMARY_FS_ENGINEER}; 
        if(cp.Is_Channel_Partner__c == true) {
            accountIdToPFSERoles = ServiceUtilityCollection.fetchAccountRoles(cpAccounts,setFSERoles);//todo
        }
        for(Case objCase : (List<Case>)records) {

             //Start (CMCP-23)-Creating instance of Old Case Record
             Case objOldCase = null;       
             if(oldRecords != null && !oldRecords.isEmpty()) {
                 objOldCase = (Case)(oldRecords.get(objCase.Id));
             }
             //END (CMCP-23)
                            
               
                if(mapUserIdToUser != null && mapUserIdToUser.containsKey(objCase.OwnerId)) {
                    String key = objCase.AccountID;           
                    objCase.Case_Owner_s_Manager_Email__c = mapUserIdToUser.get(objCase.OwnerId).Manager_Email__c;
                    
                    if(powerPartnercheck(accountIdToPFSERoles,objCase)) {
                        objCase.CP_Account_Primary_FSE__c = accountIdToPFSERoles.get(key).Values()[0].User__c;
                        objCase.Case_Owner_s_Manager_Email__c = accountIdToPFSERoles.get(key).Values()[0].User__r.Related_User_Email__c;
                    }

                   //Start (CMCP-23)-Setting Partner Case Flag to True if Case Owner is Channel Partner User (CMCP-23).  
                    if(ownerIdcheck(objOldCase,objCase)) {
                        if(Channel_Partner_Profile_Settings__c.getInstance(mapUserIdToUser.get(objCase.OwnerId).ProfileId).Is_Channel_Partner__c && !objCase.Partner_Case__c) {
                            objCase.Partner_Case__c=true;
                        }
                        //START CMCP-64 [Updating Request Ownership Status Field to Completed]
                        if(Channel_Partner_Profile_Settings__c.getInstance(mapUserIdToUser.get(objCase.OwnerId).ProfileId).Is_Channel_Partner__c && objCase.Request_Ownership_Status__c == STRING_REQUESTED) {
                            objCase.Request_Ownership_Status__c=STRING_COMPLETED; 
                        }
                        //END CMCP-64
                    }
                    //End (CMCP-23)
                }
        }       
    }
	private static set<String> populateCaseOwnersManagerHelper(List<Sobject> records, Map<Id, SObject> oldRecords) {
        Set<Id> setUserId = new Set<Id>();
        set<String> cpAccounts = new Set<String>();   
        
        for(Case objCase : (List<Case>)records) {
            Case objOldCase = null;       
            if(oldRecords!=null && !oldRecords.isEmpty()) {
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            
            if(string.valueOf(objCase.OwnerId).startsWith(STRING_USER_ID_005) || (objOldCase != null && objCase.OwnerId !=  objOldCase.OwnerId && string.valueOf(objCase.OwnerId).startsWith(STRING_USER_ID_005))) {
                setUserId.add(objCase.OwnerId);
            }                    
        
            if(objCase.AccountId!=null || (objOldCase != null && objCase.OwnerId !=  objOldCase.OwnerId && objCase.AccountId!=null )) {
                cpAccounts.add(objCase.AccountId);
            } 
        }
        
        if(!setUserId.isEmpty()) {
			CasesHelper.Users usersQuery = new  CasesHelper.Users();
            usersQuery.initMapUserIdToUser(setUserId, false);
        }
        return cpAccounts;
    }
    private static boolean powerPartnercheck(Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToPFSERoles, Case objCase) {
        String key = objCase.AccountID;
        return accountIdToPFSERoles.get(key) != null && !accountIdToPFSERoles.IsEmpty() && mapUserIdToUser.get(objCase.OwnerId).UserType == 'PowerPartner';
    }
    private static boolean ownerIdcheck(Case objOldCase, Case objCase) {
        return ((objOldCase == null || (objCase.OwnerId != objOldCase.OwnerId)) && String.valueOf(objCase.OwnerId).startsWith('005'));
    }
	/*
     * Description - populateLocationProductUpgradeType method DCP-52634
	 * return - void
     */
    public void populateLocationProductUpgradeType(List<Sobject> records, Map<Id, SObject> oldRecords){

        ilib_LogEvent.push(LOG_TITLE + '.populateLocationProductUpgradeType');
        
        Set<Id> setIPIdsForAccount = new Set<Id>(); 
	    //DCP-52634     
	    Set<Id> setSubIdsForCase = new Set<Id>(); 
        List<SVMXC__Service_Contract__c> lstSubscription = new list<SVMXC__Service_Contract__c>();    
	    Set<String> subscriptionProductCodeSet = new Set<String>();    
        Map<String,Id> productCodeBYProductIdMap = new Map<String,Id>();

        setIPIdsForAccount = processIPIdsForAccount(records, oldRecords);
        setSubIdsForCase = processSubIdsForCase(records, oldRecords);
        fetchAndUpdateInstalledProducts(setIPIdsForAccount);
        lstSubscription  = getsubscriptionProductCodeSet(setSubIdsForCase);
        getMapSubscriptionIdToSubDetails(lstSubscription);
        system.debug('mapSubscriptionIdToSubDetails:::'+mapSubscriptionIdToSubDetails);
        subscriptionProductCodeSet = getSubscriptionProductCodeSet(lstSubscription);
        system.debug('subscriptionProductCodeSet:::'+subscriptionProductCodeSet);
        productCodeBYProductIdMap = getProductCodeBYProductIdMap(setSubIdsForCase,subscriptionProductCodeSet);
        system.debug('productCodeBYProductIdMap:::'+productCodeBYProductIdMap);

        for(Case objCase : (List<Case>)records) {
            Case objOldCase= oldRecords!=null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null; 
             objCase =  updateInstalledProductType(objOldCase,objCase);
             objCase = updateProduct(objCase,productCodeBYProductIdMap);
             objCase = updateHandler(objOldCase,objCase);
            system.debug('objCase.Installed_Product_Upgrade_Type__c:::'+objCase.Installed_Product_Upgrade_Type__c);
            system.debug('objCase.IVD_Product_Identifier__c	:::'+objCase.IVD_Product_Identifier__c	);
        }  

        ilib_LogEvent.pop();    
    }

     // AY updated
    private static Set<Id> processIPIdsForAccount(List<Case> records, Map<Id, SObject> oldRecords) {
        Set<Id> setIPIdsForAccount = new set<Id>();
        for (Case objCase : records) {
            Case objOldCase = oldRecords != null && !oldRecords.isEmpty() ? (Case) oldRecords.get(objCase.Id) : null;
            
            if(objCase.SVMXC__Component__c != null && (objOldCase == null || (objOldCase != null && objCase.SVMXC__Component__c != objOldCase.SVMXC__Component__c))) {
                setIPIdsForAccount.add(objCase.SVMXC__Component__c);
           }
        }
        return setIPIdsForAccount;
    }

    private static Set<Id> processSubIdsForCase(List<Case> records, Map<Id, SObject> oldRecords) {
        Set<Id> setSubIdsForCase = new set<Id>();
        for (Case objCase : records) {
            Case objOldCase = oldRecords != null && !oldRecords.isEmpty() ? (Case) oldRecords.get(objCase.Id) : null;
            
            if(objCase.Subscription__c != null && (objOldCase == null || (objOldCase != null && (objCase.Subscription__c != objOldCase.Subscription__c || objCase.SVMXC__Component__c != objOldCase.SVMXC__Component__c)))) {
                setSubIdsForCase.add(objCase.Subscription__c);
            }
        }
        return setSubIdsForCase;
    }

    private static void fetchAndUpdateInstalledProducts(Set<Id> setIPIdsForAccount) {
        if (setIPIdsForAccount != null && !setIPIdsForAccount.isEmpty()) {
            CasesHelper.InstalledProducts installedProductsQuery = new CasesHelper.InstalledProducts();
            installedProductsQuery.initMapIPIdToIPDetails(setIPIdsForAccount);
        }
    }

    private static List<SVMXC__Service_Contract__c> getsubscriptionProductCodeSet(Set<Id> setSubIdsForCase) { 
        if((lstSubscription.isEmpty() ||  Feature.isOn(CASE_OPTIMIZATION)) && setSubIdsForCase != null && !setSubIdsForCase.isEmpty()) {
			lstSubscription = new ServiceContractSelector().selectServiceContracts(setSubIdsForCase);
        }
        return lstSubscription;
    }

    private static void getMapSubscriptionIdToSubDetails(List<SVMXC__Service_Contract__c> lstSubscription){
        if(!lstSubscription.isEmpty()) {
            ilib_LogEvent.message('mapSubscriptionIdToSubDetails'+mapSubscriptionIdToSubDetails);
            mapSubscriptionIdToSubDetails.putAll(lstSubscription);
        }
    }

    private static Set<String> getSubscriptionProductCodeSet(List<SVMXC__Service_Contract__c> lstSubscription){
        Set<String> subscriptionProductCodeSet = new Set<String>(); 
        for(SVMXC__Service_Contract__c smcObj : lstSubscription) {
            if(smcObj.ProductCode__c != null) {
                subscriptionProductCodeSet.add(smcObj.ProductCode__c);
            }
        }
      return subscriptionProductCodeSet;
     }

     private static Map<String,Id> getProductCodeBYProductIdMap(Set<Id> setSubIdsForCase,Set<String> subscriptionProductCodeSet) {
        Map<String,Id> productCodeBYProductIdMap = new Map<String,Id>();
        if((productsList.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && subscriptionProductCodeSet != null && !subscriptionProductCodeSet.isEmpty()) {
            productsList = new ProductsSelector().fetchProductId(subscriptionProductCodeSet);
        }
        if (!productsList.isEmpty()) {
            for(Product2 prodObj : productsList) {
                productCodeBYProductIdMap.put(prodObj.ProductCode,prodObj.Id);
            }
        }
        return productCodeBYProductIdMap;
     }

     private static Case updateInstalledProductType(Case objOldCase,Case caseObj) {
        Case objCase = caseObj;
        if(objOldCase != null && objOldCase.SVMXC__Component__c != null && objCase.SVMXC__Component__c == null) {//INC0449836 : clear product upgrade type if IP is clear
            objCase.Installed_Product_Upgrade_Type__c = 'NONE' ;
        }
        if(objCase.SVMXC__Component__c != null && mapIPIdToIPDetails != null && !mapIPIdToIPDetails.isEmpty() && mapIPIdToIPDetails.containsKey(objCase.SVMXC__Component__c)){
            if(mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Site__c!=null){
                objCase.SVMXC__Site__c = mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Site__c;
            }
            if(mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Product__c!=null){
                objCase.SVMXC__Product__c = mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Product__c;
            }
            if(mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).Installed_Product_Upgrade_Type__c!=null){
                objCase.Installed_Product_Upgrade_Type__c= mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).Installed_Product_Upgrade_Type__c;
            }
            //added by dhairya shah for CMCM 7910
            if(objCase.SVMXC__Component__c != null){
                objCase.Product_Serial_Number__c = mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Serial_Lot_Number__c;
            }
        }



        return objCase;
     }
    
     private static Case updateProduct( Case caseObj, Map<String,Id> productCodeBYProductIdMap) {
        Case objCase = caseObj;
        if(objCase.SVMXC__Component__c == null && mapSubscriptionIdToSubDetails != null && !mapSubscriptionIdToSubDetails.isEmpty() && mapSubscriptionIdToSubDetails.containsKey(objCase.Subscription__c) && productCodeBYProductIdMap !=null && !productCodeBYProductIdMap.isEmpty() ){
            objCase.SVMXC__Product__c =  productCodeBYProductIdMap.get(mapSubscriptionIdToSubDetails.get(objCase.Subscription__c).ProductCode__c);
        }
        return objCase;
       }

    private static Case updateHandler(Case objOldCase, Case caseObj) {
        Case objCase = caseObj;
        Boolean checkSubscription; 
        String strZuoraSubscriptionCheck = '';
        if(objOldCase == NULL || objOldCase.Subscription__c != objCase.Subscription__c) {
            checkSubscription = objCase.Subscription__c!=null && !mapSubscriptionIdToSubDetails.isEmpty() && mapSubscriptionIdToSubDetails.containsKey(objCase.Subscription__c) ? true :false;
            Id subscriptionId = objCase.Subscription__c;
            strZuoraSubscriptionCheck = getStrZuoraSubscriptionCheck(subscriptionId,strZuoraSubscriptionCheck);
            objCase.Subscription_License_Status__c = checkSubscription ? mapSubscriptionIdToSubDetails.get(objCase.Subscription__c).Status__c : '';
            objCase.Registrant_Email_Address__c = checkSubscription ? mapSubscriptionIdToSubDetails.get(objCase.Subscription__c).Registration_Contact_Email__c : '';
            objCase.Domain_Name__c = checkSubscription ? mapSubscriptionIdToSubDetails.get(objCase.Subscription__c).Domain_URL_Pattern__c : '';
            objCase.Workgroup_Name__c = checkSubscription ? mapSubscriptionIdToSubDetails.get(objCase.Subscription__c).Workgroup_Name__c : '';
            objCase.SubscriptionID__c = strZuoraSubscriptionCheck;
        }
        return objCase;
    }

    private static String getStrZuoraSubscriptionCheck(Id subscriptionId, String strZuoraSubscriptionCheck){
        String tempString = strZuoraSubscriptionCheck;
        if(subscriptionId != null && !mapSubscriptionIdToSubDetails.isEmpty() && mapSubscriptionIdToSubDetails.containsKey(subscriptionId)){
            tempString = mapSubscriptionIdToSubDetails.get(subscriptionId).Zuora_Subscription_ID__c== null? '': mapSubscriptionIdToSubDetails.get(subscriptionId).Zuora_Subscription_ID__c;  
        }
        return tempString;
    }
	/*
     * Description - validateAccountContactIPOnCase method
	 * return - void
     */
    public void validateAccountContactIPOnCase(List<Sobject> records, Map<Id, SObject> oldRecords){
		CasesHelper.Profiles profilesQuery = new  CasesHelper.Profiles();        
        profilesQuery.initLoggedInProfileName();  
		
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setIPIdsForAccount = new Set<Id>();         
        for(Case objCase : (List<Case>)records) {
            
            Case objOldCase=null;       
            if(oldRecords!=null && !oldRecords.isEmpty()){
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            
			if(objOldCase == null || (objOldCase != null && (objCase.SVMXC__Component__c != objOldCase.SVMXC__Component__c  || objCase.ContactId != objOldCase.ContactId || objCase.AccountId != objOldCase.AccountId) )){
				if(objCase.SVMXC__Component__c != null){
					setIPIdsForAccount.add(objCase.SVMXC__Component__c);
				}
				if(String.isNotBlank(objCase.ContactId) && objCase.ContactId != null){
                    setContactIds.add(objCase.ContactId);					
				}
			}
        }
        fetchIPContactRelatedToCase(setIPIdsForAccount,records,setContactIds);
    }

    /**
    * @description ::DCP-53957: codescan fix: fetch Installed product and Contact present on case 
    * @param setIPIdsForAccount 
    * @param records 
    * @param setContactIds 
    **/
    public void fetchIPContactRelatedToCase(Set<Id> setIPIdsForAccount,List<Sobject> records,Set<Id> setContactIds) {
        Set<String> setCaseOrigins = new Set<String>{'Email - ProActive - TS', 'Survey', 'Web - My Illumina - TS', 'Web - My Illumina - CS'};
        CasesHelper.InstalledProducts installedProductsQuery = new  CasesHelper.InstalledProducts();        
        installedProductsQuery.initMapIPIdToIPDetails(setIPIdsForAccount);     
        Map<Id, set<Id>> contactIdToRelatedAccIds = getContactRelatedAccountIds((List<Case>)records);//todo
		CasesHelper.Contacts contactsQuery = new  CasesHelper.Contacts();
        contactsQuery.initMapContactIdToContact(setContactIds);

        for(Case objCase : (List<Case>)records) {

		    //Added bypass Snap Sales profile for update for INC0330235
            if((Trigger.isInsert && loggedInUserProfileName != null && !loggedInUserProfileName.containsIgnoreCase('integration') && !setCaseOrigins.contains(objCase.Origin) && objCase.SuppliedEmail == null) || (Trigger.isUpdate && loggedInUserProfileName != null && loggedInUserProfileName!=Label.Integration_Sales_SNAP_Profile)) {
                updateAccountOnCase(objCase,contactIdToRelatedAccIds,setCaseOrigins);
            }
        }
    }
    
    /**
    * @description :DCP-53957: codescan fix: Validate and update Account on case
    * @param objCase 
    * @param contactIdToRelatedAccIds 
    **/
    public void updateAccountOnCase(Case objCase,Map<Id, set<Id>> contactIdToRelatedAccIds, Set<String> setCaseOrigins) {

        if(objCase.SVMXC__Component__c != null && mapIPIdToIPDetails != null && mapIPIdToIPDetails.containsKey(objCase.SVMXC__Component__c)) {
            if(objCase.ContactId != null && mapContactIdToContact != null && mapContactIdToContact.containsKey(objCase.ContactId) && mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Company__c  != mapContactIdToContact.get(objCase.ContactId).AccountId && contactIdToRelatedAccIds != null &&  contactIdToRelatedAccIds.containsKey(objCase.ContactId) && !contactIdToRelatedAccIds.get(objCase.ContactId).contains(mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Company__c)) {
                objCase.addError(STRING_SELECT_CONTACT_ON_IP);
                setErrMessages.add(STRING_SELECT_CONTACT_ON_IP);
            } else {
                objCase.AccountId =  mapIPIdToIPDetails.get(objCase.SVMXC__Component__c).SVMXC__Company__c;
            }
        } else if(objCase.SVMXC__Component__c == null && objCase.ContactId != null && objCase.AccountId != null) {
            if(mapContactIdToContact != null && mapContactIdToContact.containsKey(objCase.ContactId) && mapContactIdToContact.get(objCase.ContactId).AccountId != objCase.AccountId && contactIdToRelatedAccIds != null && contactIdToRelatedAccIds.containsKey(objCase.ContactId) && !contactIdToRelatedAccIds.get(objCase.ContactId).contains(objCase.AccountId )) {
                objCase.addError(STRING_SELECT_CONTACT_ON_ACCOUNT);
                setErrMessages.add(STRING_SELECT_CONTACT_ON_ACCOUNT);
            } else {
                if(mapContactIdToContact != null && mapContactIdToContact.containsKey(objCase.ContactId) && contactIdToRelatedAccIds != null && contactIdToRelatedAccIds.containsKey(objCase.ContactId) && !contactIdToRelatedAccIds.get(objCase.ContactId).contains(objCase.AccountId )) {
                objCase.AccountId = mapContactIdToContact.get(objCase.ContactId).AccountId;  
                }                   
            }
        }
        else if(objCase.SVMXC__Component__c == null && objCase.ContactId != null && objCase.AccountId == null) {
            if(objCase.AccountId == null && mapContactIdToContact != null && mapContactIdToContact.containsKey(objCase.ContactId)) {
                objCase.AccountId = mapContactIdToContact.get(objCase.ContactId).AccountId;                    
            }
        }
    }
	 
	/*
     * Description - flipNewCaseToInprogress method
	 * return - void
     */
    public void flipNewCaseToInprogress(List<Sobject> records) {
        
        for(Case objCase : (List<Case>)records) {       
            if(objCase.Origin != null && (objCase.Origin.startsWith('Phone - ') || objCase.Origin.startsWith('In Person - ') || objCase.Origin.startsWith('Fax - ') || objCase.Origin.contains('- CP'))) {
                objCase.Status=STRING_IN_PROGRESS;
                objCase.SVMXC__Actual_Initial_Response__c = System.now();
                objCase.SVMXC__Time_to_Initial_Response__c = Decimal.valueOf(objCase.SVMXC__Actual_Initial_Response__c.getTime() - system.now().getTime()) / 1000.0 / 60.0;
            
            }
        }       
    }
    
	/*
     * Description - markCaseAsSpam method
	 * return - void
     */
    public void markCaseAsSpam(List<Sobject> records) {
		CasesHelper.CaseRoutingCriteriaMapping caseRoutingCriteriaMappingQuery = new  CasesHelper.CaseRoutingCriteriaMapping();        
        caseRoutingCriteriaMappingQuery.initMapCaseRoutingCriteriaMappings();       
		CasesHelper.Profiles profilesQuery = new  CasesHelper.Profiles();        
        profilesQuery.initLoggedInProfileName();  

        for(Case objCase : (List<Case>)records) {
            Boolean keywordMatchResult = false;
            Boolean emailMatchResult = false;
            try {
                if(loggedInUserProfileName != null && !loggedInUserProfileName.containsIgnoreCase('integration') && objCase.SuppliedEmail != null) {

                    for(Case_Routing_Criteria_Mappings__mdt caseSpamRec : mapIdToRoutingCriteria.values()) {                  
                        if(objCase.Origin != null && caseSpamRec.Case_Origin__c != null && objCase.Origin.equalsIgnoreCase(caseSpamRec.Case_Origin__c)) {
                            if(caseSpamRec.Keywords__c != null && objCase.Subject != null){                            
               if(!caseSpamRec.Keywords__c.startswith('.*')) {
                  keywordMatchResult = objCase.Subject.startswith(caseSpamRec.Keywords__c);
                } else{
                  Matcher matcher = Pattern.compile(caseSpamRec.Keywords__c.toLowerCase()).matcher(objCase.Subject.toLowerCase());
                  keywordMatchResult = matcher.find();
                }  
                            }
                            if(caseSpamRec.From_Addresses__c != null){
                                Matcher matcher = Pattern.compile(caseSpamRec.From_Addresses__c.toLowerCase()).matcher(objCase.SuppliedEmail.toLowerCase());
                                emailMatchResult = matcher.find();   
                            }
                            if(((caseSpamRec.Keywords__c != null && keywordMatchResult == True)||caseSpamRec.Keywords__c == null) && ((caseSpamRec.From_Addresses__c != null && emailMatchResult == True)|| caseSpamRec.From_Addresses__c == null)){
                                   objCase.Category__c = caseSpamRec.Category__c;
                                   objCase.Sub_Type__c = caseSpamRec.Sub_Type__c;
                                   objCase.Status = caseSpamRec.Case_Status__c ;     
                                   break;
                            }
                        }
                    }           
                } 
            } 
            Catch(Exception e){
                System.debug(e.getmessage());
                ApexExceptions.emit('Cases',e);
            }   
        }       
    }
    
	/*
     * Description - populateOwnerAsServiceQueue method
	 * return - void
     */
    public void populateOwnerAsServiceQueue(List<Sobject> records, Map<Id, SObject> oldRecords) {
		CasesHelper.PublicGroups publicGroupsQuery = new  CasesHelper.PublicGroups();        
        publicGroupsQuery.initMapGroupNameToGroupId();
        //Id idQueueId;       
        if(mapGroupNameToGroupId!=  null && !mapGroupNameToGroupId.isEmpty() && mapGroupNameToGroupId.containsKey(System.label.CS_Globally_Unassigned_Email)) {//INC0379775
            idQueueId = mapGroupNameToGroupId.get(System.label.CS_Globally_Unassigned_Email);//INC0379775
        }
        
        for(Case objCase : (List<Case>)records) {

            Case objOldCase = null;       
            if(oldRecords!=null && !oldRecords.isEmpty()) {
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            populateOwnerAsServiceQueuehelper(objCase, objOldCase);
        } 
        
    }

    private void populateOwnerAsServiceQueuehelper(Case objCase, Case objOldCase ){
        
        if(objCase.Origin!=null && objCase.Origin.equals(STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS) && objCase.Record_Edit_Source__c!=STRING_CASE_RECORD_EDIT_SOURCE_CLONE_CASE_SFM){
            if(objOldCase == null || (objOldCase != null && objCase.Origin!=objOldCase.Origin)){
                if(!(System.Test.isRunningTest())){  
                    objCase.OwnerId=(idQueueId!=null)?idQueueId:null;
                }    
            }
        }       

    }
    
	/*
     * Description - populateCustomerNotificationEmailAddress method
	 * return - void
     */
    public void populateCustomerNotificationEmailAddress(List<Sobject> records, Map<Id, SObject> oldRecords){
        
        set<String> setCaseStatusesforEmailNotification=new set<String>{System.label.CaseStatusCompleted,System.label.CaseStatusPendingLogisticsReview,System.label.CaseStatusPendingQAReview,System.label.CaseStatusReopenRequested,System.label.CaseStatusClosedDuplicate,System.label.CaseStatusClosed}; 
        Set<Id> setContactIdsForAccount = new Set<Id>();
        
        for(Case objCase : (List<Case>)records) {
            Case objOldCase=oldRecords!=null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null;
            if((trigger.isInsert && String.isNotBlank(objCase.ContactId) && objCase.ContactId != null)  || (trigger.isUpdate && objCase.ContactId != objOldCase.ContactId && objCase.ContactId != null)){
                setContactIdsForAccount.add(objCase.ContactId);
            }
        }
        // Added if condition for CMCM-10026
        if (setContactIdsForAccount != null && !setContactIdsForAccount.isEmpty()) {
            CasesHelper.Contacts contactsQuery = new  CasesHelper.Contacts();
            contactsQuery.initMapContactIdToContact(setContactIdsForAccount);    
        }
        if(mapContactIdToContact != null && !mapContactIdToContact.isEmpty()) {
            for(Case objCase : (List<Case>)records){
                if(objCase.ContactId!=null && objCase.status!=null && !setCaseStatusesforEmailNotification.contains(objCase.status) && mapContactIdToContact.containsKey(objCase.ContactId)) {
                    objCase.Customer_Notification_Email_Address__c= mapContactIdToContact.get(objCase.ContactId).Email;
                }   
                else  if(objCase.SuppliedEmail!=null && objCase.status!=null && !setCaseStatusesforEmailNotification.contains(objCase.status) ){
                    objCase.Customer_Notification_Email_Address__c=objCase.SuppliedEmail;
                }   
            }
        }
        
    }
    
	/*
     * Description - clearInactiveContactOnCase method
	 * return - void
     */
    public void clearInactiveContactOnCase(List<Sobject> records){
        
        Set<Id> setContactIds = new Set<Id>();  
        for(Case objCase : (List<Case>)records){
            if(String.isNotBlank(objCase.ContactId) && objCase.ContactId != null){
                setContactIds.add(objCase.ContactId);
            }
        }
		CasesHelper.Contacts contactsQuery = new  CasesHelper.Contacts();
        contactsQuery.initMapContactIdToContact(setContactIds);           
        for(Case objCase : (List<Case>)records){    
            if(mapContactIdToContact !=  null && !mapContactIdToContact.isEmpty() && mapContactIdToContact.containsKey(objCase.ContactId)){
                if(mapContactIdToContact.get(objCase.ContactId).Is_Active__c == false){
                    objCase.ContactId = null;
                }
            }       
        }

    }
    
	/*
     * Description - getContactRelatedAccountIds method
	 * return - void
     */
    public Map<Id, set<Id>> getContactRelatedAccountIds(List<Case> lstCaseRecords){
        Map<Id, set<Id>> contactIdToAccountIds = new Map<Id, set<Id>>();
        Set<Id> setContactIds = new Set<Id>();
        Map<Id, set<Id>> emptymap = new Map<Id, set<Id>>();
        
        if(lstCaseRecords != null && !lstCaseRecords.isEmpty()){
            for(Case caseObj:  lstCaseRecords )
            {
                if(caseObj.ContactId != null ){
                    setContactIds.add(caseObj.ContactId);
                }
            }
        }        
        
        if(!setContactIds.isEmpty()){
			CasesHelper.AccountContactRelations accountContactRelationsQuery = new  CasesHelper.AccountContactRelations();
            accountContactRelationsQuery.initMapACRelationIdToACRelation(setContactIds);
            if(mapACRelationIdToACRelation != null && !mapACRelationIdToACRelation.isEmpty()){
                for(AccountContactRelation objAccConRelation : mapACRelationIdToACRelation.values()){
                   // if(objAccConRelation.ContactId != null ){
                        if(objAccConRelation.ContactId != null && contactIdToAccountIds.containsKey(objAccConRelation.ContactId)){
                            contactIdToAccountIds.get(objAccConRelation.ContactId).add(objAccConRelation.AccountId);
                        } 
                        else{
                            contactIdToAccountIds.put(objAccConRelation.ContactId,new set<Id>{objAccConRelation.AccountId});
                        }
                   // }
                }
            }
        }
        if(contactIdToAccountIds != null && !contactIdToAccountIds.isEmpty()){
            return contactIdToAccountIds;
        }
        else {
            return emptymap;
        }
    }
    
    /**
    *  @author Nitin Sood
    *  @description - 
    *                 To be executed, when the Case is updated. 
    *                 Checks pFA/pAE Evaluation for IVD and non IVD Products
    *  @PARAM :  List<Case> lstNewCases
    *  @RETURN:  void
    */  
    public void checkpAEpFAEvaluation(List<Case> lstNewCases, Map<Id, SObject> oldRecords) {
        // Added conditional logic for CMCM-10026
        List<Case> lstNewBICases = new List<Case>();
        for (Case newCaseRec : lstNewCases) {
            if (newCaseRec.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE) {
                lstNewBICases.add(newCaseRec);
            }
        }
        // End conditional logic for CMCM-10026
        Set<Id> setCasesWithIVDProducts = getCaseIdWithAdditionalIVDProduct(lstNewCases); 
        
        for(Case objCase : lstNewBICases) {
            Case objOldCase;
            if(oldRecords != null && !oldRecords.isEmpty()){
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }
            //UnreadEmail Bypass rule - INC0381901
            if(objOldCase != null && !oldRecords.isEmpty() && objOldCase.Unread_Emails__c == objCase.Unread_Emails__c){ 
                validatedpAEpFAOnVariousConditions(objOldCase,objCase,setCasesWithIVDProducts);
            }// End UnreadEmail Bypass - INC0381901
        }   
    } 

    /**
    * @description : Throw Error message on various PAE PFA Evaluation || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    * @param setCasesWithIVDProducts 
    **/
    public void validatedpAEpFAOnVariousConditions(Case objOldCase,Case objCase,Set<Id> setCasesWithIVDProducts)
    {
        if(objOldCase == null && (objCase.Answer_1__c != null || objCase.Answer_2__c != null || objCase.Answer_3__c != null || objCase.Answer_4__c != null || objCase.Answer_5__c != null || objCase.PAE_PFA_Evaluation_Required__c != 'Pending')){
            objCase.addError(STRING_PAE_PFA_ERROR_MESSAGE);
        }        
        else if(objCase.IVD_Product_Identifier__c == false && !setCasesWithIVDProducts.contains(objCase.Id)){   
            
            if(SET_COMPLETED_CASE_STATUSES.contains(objCase.Status) && !((objCase.Answer_1__c == null && objCase.Answer_2__c == null &&  objCase.Answer_3__c == null &&  objCase.Answer_4__c == null && objCase.Answer_5__c == null) || (objCase.Answer_1__c != null && objCase.Answer_2__c != null &&  objCase.Answer_3__c != null &&  objCase.Answer_4__c != null && objCase.Answer_5__c != null))){
                objCase.addError(STRING_PAE_PFA_ANSWER_ALL_OR_NONE);
            }

            checkpAEpFANoAndpAEpFAAllAnswer(objOldCase,objCase);
            updatepFApAEEvalRequired(objOldCase,objCase);
            //DCP-25229
            if(objOldCase!=null && objCase.Status != objOldCase.Status && objCase.Status ==STRING_CASE_STATUS_CLOSED_DUPLICATE ){
                
                if(objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_EVALUATION_STATUS){
                    objCase.addError(STRING_ERROR_MESSAGE_FOR_CLOSE_DUPLICATE);
                }else if(objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_YES && objOldCase.Status != STRING_PENDING_QA_REVIEW){
                    objCase.Status = STRING_PENDING_QA_REVIEW;
                    //DCP-47530
                    //adding this boolean to bypass the validation on editing case status field for TPSP user.
                    bypassStatusEditValidationForTPSP = true;
                }
            } 
            //end of DCP-25229
        }
    
        else if(objCase.IVD_Product_Identifier__c == true || setCasesWithIVDProducts.contains(objCase.Id) || objCase.IVD_Product_Identifier_Additional_Prod__c == true){
             
            updatepFApAEEvalRequiredOnVariousCondn(objOldCase,objCase); 
            validatepAEpFAOnClosedDuplicate(objOldCase,objCase);
             
        }
        
        checkpAEpFAAwarenessDateEvaluation(objOldCase,objCase);
        
    }
    /**
    * @description :Throw Error message for PAE PFA Evaluation Answer as No and All || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void checkpAEpFANoAndpAEpFAAllAnswer(Case objOldCase,Case objCase)
    {
        
        if(blnCheckValidation!= true && objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_NO && ((objOldCase.Answer_1__c != objCase.Answer_1__c && objCase.Answer_1__c != null) || (objOldCase.Answer_2__c != objCase.Answer_2__c && objCase.Answer_2__c != null) || (objOldCase.Answer_3__c != objCase.Answer_3__c && objCase.Answer_3__c != null) || (objOldCase.Answer_4__c != objCase.Answer_4__c && objCase.Answer_4__c != null) || (objOldCase.Answer_5__c != objCase.Answer_5__c && objCase.Answer_5__c != null))){
            objCase.addError(STRING_ERROR_MESSAGE_FOR_PAE_PFA_NO);
        }
        else if(blnCheckValidation!= true && objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_YES && (objCase.Answer_1__c == null || objCase.Answer_2__c == null ||  objCase.Answer_3__c == null ||  objCase.Answer_4__c == null || objCase.Answer_5__c == null))
        {
            objCase.addError(STRING_PAE_PFA_ANSWER_ALL);  
        }
        
    } 
    /**
    * @description :Update PAF and PAE evaluation required on various condition || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void updatepFApAEEvalRequired(Case objOldCase,Case objCase)
    {
        if(objCase.Answer_1__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_2__c == STRING_PAE_PFA_ANSWER_NO &&  objCase.Answer_3__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_4__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_5__c == STRING_PAE_PFA_ANSWER_NO)
        {
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_ANSWER_NO;
            blnCheckValidation= true; 
        }
        else if(objCase.Answer_1__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_2__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_3__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_4__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_5__c == STRING_PAE_PFA_ANSWER_YES)
        {
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_ANSWER_YES;
            blnCheckValidation= true; 
        }
        else if(objCase.Answer_1__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_2__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_3__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_4__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_5__c != STRING_PAE_PFA_ANSWER_YES && !((objCase.Answer_1__c == null && objCase.Answer_2__c == null &&  objCase.Answer_3__c == null &&  objCase.Answer_4__c == null && objCase.Answer_5__c == null) || (objCase.Answer_1__c != null && objCase.Answer_2__c != null &&  objCase.Answer_3__c != null &&  objCase.Answer_4__c != null && objCase.Answer_5__c != null))){
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_EVALUATION_STATUS;                      
        }
    }
   /**
    * @description : Update PAE PFA elevation Required field on case
    * @param objOldCase 
    * @param objCase 
    **/
    public void updatepFApAEEvalRequiredOnVariousCondn(Case objOldCase,Case objCase)
    {

        if(objCase.Answer_1__c == null || objCase.Answer_2__c == null ||  objCase.Answer_3__c == null ||  objCase.Answer_4__c == null || objCase.Answer_5__c == null)
        {   
            validateAndUpdatepAEpFAEvaluation(objOldCase,objCase);                      
        }
        else if(objCase.Answer_1__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_2__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_3__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_4__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_5__c == STRING_PAE_PFA_ANSWER_YES)
        {
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_ANSWER_YES;
        }
        else if(objCase.Answer_1__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_2__c == STRING_PAE_PFA_ANSWER_NO &&  objCase.Answer_3__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_4__c == STRING_PAE_PFA_ANSWER_NO && objCase.Answer_5__c == STRING_PAE_PFA_ANSWER_NO)
        {
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_ANSWER_NO;                      
        }
        else if(objCase.Answer_1__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_2__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_3__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_4__c != STRING_PAE_PFA_ANSWER_YES && objCase.Answer_5__c != STRING_PAE_PFA_ANSWER_YES && !((objCase.Answer_1__c == null && objCase.Answer_2__c == null &&  objCase.Answer_3__c == null &&  objCase.Answer_4__c == null && objCase.Answer_5__c == null) || (objCase.Answer_1__c != null && objCase.Answer_2__c != null &&  objCase.Answer_3__c != null &&  objCase.Answer_4__c != null && objCase.Answer_5__c != null))){
            
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_EVALUATION_STATUS;                      
        }
        
    }
    /**
    * @description :Throw Error message on various PAE PFA Evaluation condition and update the field || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void validateAndUpdatepAEpFAEvaluation(Case objOldCase,Case objCase)
    {
        //objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_EVALUATION_STATUS;
        if((objOldCase != null && objOldCase.PAE_PFA_Evaluation_Required__c != objCase.PAE_PFA_Evaluation_Required__c && objCase.PAE_PFA_Evaluation_Required__c != STRING_PAE_PFA_EVALUATION_STATUS) || (objOldCase == null && objCase.PAE_PFA_Evaluation_Required__c != STRING_PAE_PFA_EVALUATION_STATUS )){
                            
            objCase.addError(STRING_ERROR_MESSAGE_FOR_IVD_PRODUCT);
        }
        else if(objOldCase != null && objOldCase.PAE_PFA_Evaluation_Required__c == objCase.PAE_PFA_Evaluation_Required__c && objCase.PAE_PFA_Evaluation_Required__c != STRING_PAE_PFA_EVALUATION_STATUS){
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_EVALUATION_STATUS;
        }
        if(SET_COMPLETED_CASE_STATUSES.contains(objCase.Status)){
            
            objCase.addError(STRING_ERROR_MESSAGE_FOR_CASE_COMPLETION);
        } 
        
        if(objCase.Answer_1__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_2__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_3__c == STRING_PAE_PFA_ANSWER_YES ||  objCase.Answer_4__c == STRING_PAE_PFA_ANSWER_YES || objCase.Answer_5__c == STRING_PAE_PFA_ANSWER_YES)
        {
            objCase.PAE_PFA_Evaluation_Required__c = STRING_PAE_PFA_ANSWER_YES;
        }
    }
    /**
    * @description : Throw Error message on various PAE PFA Evaluation on closed duplicate status|| CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void validatepAEpFAOnClosedDuplicate(Case objOldCase,Case objCase)
    {
        //DCP-25229
        if(objOldCase!=null && objCase.Status != objOldCase.Status && objCase.Status ==STRING_CASE_STATUS_CLOSED_DUPLICATE ){
                
            if(objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_EVALUATION_STATUS){
                objCase.addError(STRING_ERROR_MESSAGE_FOR_CLOSE_DUPLICATE);
            }else if(objOldCase.Status != STRING_PENDING_QA_REVIEW){
                objCase.Status =STRING_PENDING_QA_REVIEW;
                //DCP-47530
                //adding this boolean to bypass the validation on editing case status field for TPSP user.
                bypassStatusEditValidationForTPSP = true;
            }
        } 
        //end of DCP-25229
    }
    /**
    * @description : Throw Error message on PAE PFA Evaluation and Awareness date condition || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void checkpAEpFAAwarenessDateEvaluation(Case objOldCase,Case objCase)
    {
        //Added Loop and 1st if condition to skip the record by Dhairya Shah for CMCM - 13337
        List<Case> caseObjList = new List<Case>{objCase};
        for(Case caseObjFor : caseObjList){
            if(
                caseObjFor.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE &&
                ((objOldCase.Status == System.label.CaseStatusReopenRequested && (caseObjFor.Status == System.label.CaseStatusCompleted || caseObjFor.Status == System.label.CaseStatusInProgress || caseObjFor.Status == System.label.CaseStatusClosed || caseObjFor.Status == System.label.CaseStatusPendingQAReview))
                    ||((objOldCase.Status == System.label.CaseStatusCompleted || objOldCase.Status == System.label.CaseStatusClosed) && (caseObjFor.Status == System.label.CaseStatusReopenRequested || caseObjFor.Status == System.label.CaseStatusPendingQAReview))
                    ||(objOldCase.Status == System.label.CaseStatusPendingQAReview && caseObjFor.Status == System.label.CaseStatusReopened)
                    ||(objOldCase.Status == System.label.CaseStatusReopenRequested && caseObjFor.Status == System.label.CaseStatusReopenRequested) //comments added in CMCM-13337
                    )
                )
            {
                bypasscheckpAEpFAAwarenessDateEvaluation= true;
                continue; // Skip this record, used continue instead of using boolean variables.
            }

            if(bypasscheckpAEpFAAwarenessDateEvaluation == false && objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_YES && ( objCase.pAE_pFA_Awareness_Date__c == null || String.isBlank(objCase.Explanation_for_pAE_pFA__c))) {
                objCase.addError(STRING_ERROR_MESSAGE1_FOR_AWARENESS_DATE);      
            }
        }

         //Updated condition for QA profile for DCP-25224
        if(objOldCase != null && objOldCase.pAE_pFA_Awareness_Date__c != null && objOldCase.pAE_pFA_Awareness_Date__c != objCase.pAE_pFA_Awareness_Date__c && objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_YES && UserInfo.getProfileId() != Label.ProfileIdQualityAssurance){                   
            objCase.addError(STRING_AWARENESS_DATE_CANNOT_BE_CHANGED);               
        }

        Boolean boolCheckFieldChange = false;
        if(objOldCase != null)
        {
            boolCheckFieldChange = objOldCase.QA_Review__c != objCase.QA_Review__c ||  objOldCase.Case_First_Reviewed__c != objCase.Case_First_Reviewed__c ||  objOldCase.Case_Last_Reviewed__c != objCase.Case_Last_Reviewed__c ||  objOldCase.Investigation_Summary_Comments__c != objCase.Investigation_Summary_Comments__c ||  objOldCase.QA_Product_Family__c != objCase.QA_Product_Family__c ||  objOldCase.QA_Sub_Product_Family__c != objCase.QA_Sub_Product_Family__c ||  objOldCase.QA_Reviewer__c != objCase.QA_Reviewer__c ||  objOldCase.QA_Reopen_Code_s__c != objCase.QA_Reopen_Code_s__c;
        }
        validateQAReviewAndInvistigationSummary(objOldCase,objCase,boolCheckFieldChange);
        validatepAEpFAEvaluationAndUpdateCaseStaus(objOldCase,objCase);
    }
    /**
    * @description :Throw Error message based on QA Review status and Investigation summary comment as part of PAE PFA Evaluation || CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    * @param boolCheckFieldChange 
    **/
    public void validateQAReviewAndInvistigationSummary(Case objOldCase,Case objCase,Boolean boolCheckFieldChange){ 
        //QACM-123 updating to check contains of the statuses values of SET_STATUS_FOR_QAREVIEW   
        if(boolCheckFieldChange && SET_STATUS_FOR_QAREVIEW.contains(objOldCase.Status)){
            
            objCase.addError(STRING_EDIT_QA_REVIEW_SECTION);                    
        }
        if((objCase.Investigation_Summary_Comments__c == '' || objCase.Investigation_Summary_Comments__c == null) && objCase.Status == Label.CaseStatusCompleted  && objOldCase.Status == Label.CaseStatusPendingQAReview){
            if(!(objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_NO && objCase.QA_Review__c == STRING_QA_REVIEW_NO_IVD_PRODUCT))
            {
                objCase.addError(STRING_INVESTIGATION_SUMMERY_ERROR_MESSAGE);  
            }          
        }
    }
    /**
    * @description :Throw Error message on PAE PFA Evaluation and update case status|| CodeScan Fix : DCP-53957
    * @param objOldCase 
    * @param objCase 
    **/
    public void validatepAEpFAEvaluationAndUpdateCaseStaus(Case objOldCase,Case objCase)
    {
        if(SET_COMPLETED_CASE_STATUSES.contains(objCase.Status) && (objCase.PAE_PFA_Evaluation_Required__c == null || objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_EVALUATION_STATUS)){
            objCase.addError(STRING_PAE_PFA_EVALUATION_REQUIRED);
        }

        //DCP-25290 bug 26006
        //for non logistics/QA review cases on Complete Case Business Issue sfm if user answers the pAE/pFA questions which makes 
        // PAE_PFA_Evaluation_Required__c field as yes then case status should go to Pending QA Review rather than completed
        if(objOldCase != null){
            if(objCase.Status != objOldCase.Status && objCase.Status ==STRING_COMPLETED && objOldCase.Status != Label.CaseStatusPendingLogisticsReview &&
            objOldCase.Status != STRING_PENDING_QA_REVIEW && objCase.Record_Updated_from_SFM__c == true && 
            objOldCase.PAE_PFA_Evaluation_Required__c != STRING_PAE_PFA_ANSWER_YES && 
            objCase.PAE_PFA_Evaluation_Required__c == STRING_PAE_PFA_ANSWER_YES){
                objCase.Status = STRING_PENDING_QA_REVIEW;
                //DCP-47530
                    //adding this boolean to bypass the validation on editing case status field for TPSP user.
                    bypassStatusEditValidationForTPSP = true;
            }
        }
    }
    
    
    
	/*
     * Description - getCaseIdWithAdditionalIVDProduct method
	 * return - void
     */
    public Set<Id> getCaseIdWithAdditionalIVDProduct(List<Case> lstNewCases){
        
        Set<Id> setNewCaseIds = new Set<Id>();
        Set<Id> setCasesWithIVDProducts = new Set<Id>();
        
        for(Case objCase : lstNewCases){
            if(objCase.Id!= null){
                setNewCaseIds.add(objCase.Id);
            }      
        }
        
        if(!setNewCaseIds.isEmpty()){
			CasesHelper.AssociatedProduct caseLinesQuery = new  CasesHelper.AssociatedProduct();
            caseLinesQuery.initMapAPidToAssociatedProductDetails(setNewCaseIds);
            if(mapAPidToAssociatedProductDetails != null && !mapAPidToAssociatedProductDetails.isEmpty()){
                for(Associated_Product__c objAssociatedProduct :  mapAPidToAssociatedProductDetails.values())//todo
                {   
                    if(objAssociatedProduct.IVD_Product_Identifier__c == true){
                        setCasesWithIVDProducts.add(objAssociatedProduct.Case__c);    
                    }       
                }
            }
        }
        
        return setCasesWithIVDProducts;
    }  

    /*
    *  @author Vignesh Sethuramalingam
    *  @description - Method to set "Is_Case_Eligible_For_Prediction__c" field on before insert for DCP-43946.
    *  @PARAM :  List<Case> lstNewCases
    *  @RETURN:  void
    */ 
    public static void populateCasesToPrediction(List<Sobject> records){
        if(UserInfo.getUserName().containsIgnoreCase('automatedcaseuser@illumina.com')){
            if (technicalSupportQueue == null || Feature.isOn(CASE_OPTIMIZATION)) {
                technicalSupportQueue = new GroupsSelector().getQueueIdbyDevName('Technical_Support' , 'QUEUE');
            }
            if(technicalSupportQueue.Id != Null){
                for(Case objCase : (List<Case>)records){  
                    if(objCase.ownerId == technicalSupportQueue.Id){
                        objCase.Is_Case_Eligible_For_Prediction__c = TRUE;
                    }
                }
            }
        }
    }

   /*
    *  @author Nishan Shetty [CMCP-23]
    *  @description - Method to update Partner Case Flag for Account associated to VAD Territory Type.
    *  @PARAM :  Map<Id,List<Case>mapAccountIdtoCases Map of account id to List of cases.
    *  @RETURN:  void
    */
    public static void updatePartnerCaseFlag(Map<Id,List<Case>> mapAccountIdtoCases) {
        Map<Id,String> mapAccountIdToTerritoryTypeCase=new Map<Id,String>();
        if(mapAccountIdtoCases!=null && !mapAccountIdtoCases.isEmpty()) {
            mapAccountIdToTerritoryTypeCase = TerritoryTypesService.getAccountToTerritoryTypeMap(mapAccountIdtoCases.keySet());

            for(Id accountId:mapAccountIdToTerritoryTypeCase.keySet()) {
                
                if(mapAccountIdToTerritoryTypeCase.get(accountId)==TerritoryTypesService.TYPE_TERRITORY_VAD_CP) {
                    for(Case objectCase:mapAccountIdtoCases.get(accountId)) {
                        if(!objectCase.Partner_Case__c) {
                            objectCase.Partner_Case__c=true;
                        } 
                    }
                }
            }
        }
    }
    //***********************functional methods for before insert event ends***********************************
    //***********************functional methods for before update event ends**************************************  
	/*
     * Description - caseFieldAssingmentsBeforeUpdate method
	 * return - void
     */
    public void caseFieldAssingmentsBeforeUpdate(List<Sobject> records, Map<Id, SObject> oldRecords) {
		CasesHelper.Profiles profilesQuery = new CasesHelper.Profiles();        
        profilesQuery.initLoggedInProfileName();
        List<Case> lstSpamErrorCases = new List<Case>(); 
        Map<Id,Case> caseIdsWithRecordTypeChangeBIToSR = new Map<Id,Case>(); //QACM-108
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('CasesAfterUpdate'); //QACM-108   
        for(Case objCase : (List<Case>)records) {
            
            Case objOldCase = oldRecords != null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null;    
            //DCP-44980
            if(reviewCheck(objCase)) {
                objCase.IVD_Product_Identifier_Additional_Prod__c = false;   
            }
            if(categorycheck(objCase,objOldCase)) {
                lstSpamErrorCases.add(objCase);
            }
            //QACM-108
            if(recordTypeCheck(objCase,objOldCase)) {
                caseIdsWithRecordTypeChangeBIToSR.put(objCase.Id,objCase);
                if(caseIdsWithRecordTypeChangeBIToSR != null && !caseIdsWithRecordTypeChangeBIToSR.keySet().isEmpty()) {
                    updateCaseRTChange(caseIdsWithRecordTypeChangeBIToSR,queueableThread);
                } //QCM-108 Ends
            }
            if(!queueableThread.lstQueueableJobs.isEmpty()) {
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
            }    
            updatesOnStatusChange(objCase, objOldCase);
            updatesOnCompletedCase(objCase, objOldCase);
            //DCP:53957
            updatesCaseRefactorWorkFlowLogic(objCase, objOldCase);
        }
        if(!lstSpamErrorCases.isEmpty()) {
            addErrorMessageForSpamAndNotificationCases(lstSpamErrorCases);  
        }           
    }
    private static boolean reviewCheck(Case objCase) {
        return objCase.QA_Review__c == STRING_QA_REVIEW_NO_IVD_PRODUCT && objCase.IVD_Product_Identifier_Additional_Prod__c;
    }
    private static boolean categorycheck(Case objCase, Case objOldCase) {
        return objCase.Category__c != objOldCase.Category__c && (objCase.Category__c == 'Notification' || objCase.Category__c == 'Spam') && (objCase.Record_Edit_Source__c == 'Close as Notification Quick Action' || objCase.Record_Edit_Source__c == 'Close as Spam Quick Action') && objCase.Status != objOldCase.Status && objCase.Status == STRING_CLOSED && objCase.Sub_Type__c == 'General';
    }
    private static boolean recordTypeCheck(Case objCase, Case objOldCase) {
        return objCase.RecordTypeId != objOldCase.RecordTypeId && objOldCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && objCase.RecordTypeId == SERVICE_REQUEST_CASE_RECORDTYPE;
    }
	/*
     * Description - updatesOnCompletedCase method
	 * return - void
     */
    public void updatesOnCompletedCase(Case objCase, Case objOldCase) {

        If(objCase.Status ==STRING_COMPLETED && objCase.Status != objOldCase.Status) {

            if(!system.isBatch()) {
              objCase.Case_Completed_By__c = UserInfo.getUserId();
            }
            //Added as part of DCP-43946
            objCase.Predicted_Category__c = objCase.Category__c;
            objCase.Predicted_Sub_Type__c = objCase.Sub_Type__c;          
            objCase.SVMXC__Actual_Resolution__c = System.now();
            Decimal timeDifference = 0;
            if(objCase.SVMXC__Actual_Resolution__c != null) {
                timeDifference = Decimal.valueOf(objCase.SVMXC__Actual_Resolution__c.getTime() - objCase.CreatedDate.getTime()) / 1000.0 / 60.0;
            }
            else {
                timeDifference = objCase.SVMXC__Time_to_Resolve__c;
            }
            objCase.SVMXC__Time_to_Resolve__c = timeDifference ;
            //End of Refactor WorkFlow - Case: Case First Reviewed Is Blank

            //Added by Shruti Karn for INC0197574
            if(objCase.Status != objOldCase.Status && objCase.Status ==STRING_COMPLETED && objOldCase.Status ==Label.CaseStatusPendingLogisticsReview && objCase.Record_Updated_from_SFM__c == false && (objCase.Work_Order_Status__c == 'Not Applicable' || objCase.Work_Order_Status__c == STRING_CLOSED)){
                objCase.Status =STRING_CLOSED;
                //DCP-47530
                //adding this boolean to bypass the validation on editing case status field for TPSP user.
                bypassStatusEditValidationForTPSP = true;
            }                
        }           
    }
    
	/*
     * Description - updatesOnStatusChange method
	 * return - void
     */
    public void updatesOnStatusChange(Case objCase, Case objOldCase) {
        
        if(objCase.Status != objOldCase.Status) {
            
            updateCaseOnStatusReopenedRequested(objCase,objOldCase);
            updateCaseOnStatuseClosedCompleted(objCase,objOldCase);

            if(caseStatusProgressInitialcheck(objCase,objOldCase)) {
                objCase.SVMXC__Actual_Initial_Response__c = System.now();
                objCase.SVMXC__Time_to_Initial_Response__c = Decimal.valueOf(objCase.SVMXC__Actual_Initial_Response__c.getTime() - objCase.CreatedDate.getTime()) / 1000.0 / 60.0;
 
                //process builder Status and owner Update DCP-27008 
                 if(string.valueOf(objCase.OwnerId).startsWith('00G')){
                  Id loggedInUserId = UserInfo.getUserId();
                  objCase.OwnerId = loggedInUserId;
                }
            }
            
            if(caseStatusawatingcheck(objCase,objOldCase)) {
                objCase.Awaiting_Response_Date__c = System.now();
            }     
            //INC0239763
            if(caseStatusawatingResponsecheck(objCase,objOldCase)) { 
                objCase.Awaiting_Response_Reason__c = null;
            }
             //POL-51
            if(caseStatusresponsed(objCase,objOldCase)) {
                objCase.Region__c=mapAccountIdToAccount.get(objCase.AccountId).Territory_Region__c;
            }
        }
    }
    private static boolean caseStatusProgressInitialcheck(Case objCase, Case objOldCase) {
        return objCase.Status == System.Label.CaseStatusInProgress && objOldCase.Status == System.Label.CaseStatusInitiated;
    }
    private static boolean caseStatusawatingcheck(Case objCase, Case objOldCase) {
        return (objCase.Status == STRING_AWAITING_RESPONSE_CUSTOMER || objCase.Status == STRING_AWAITING_RESPONSE_INTERNAL ) && objCase.Status != objOldCase.Status;
    }
    private static boolean caseStatusawatingResponsecheck(Case objCase, Case objOldCase) {
        return objCase.Status != objOldCase.Status && (objOldCase.Status == System.label.CaseStatusAwaitingResponseCustomer || objOldCase.Status == System.label.CaseStatusAwaitingResponseInternal ) && objCase.Status != System.label.CaseStatusAwaitingResponseCustomer && objCase.Status != System.label.CaseStatusAwaitingResponseInternal;
    }
    private static boolean caseStatusresponsed(Case objCase, Case objOldCase) {
        return (objCase.Status == System.label.CaseStatusReopened || (objOldCase.Status == System.label.CaseStatusReopenRequested && objCase.Status == System.label.CaseStatusInProgress)) && objCase.AccountId !=null && objCase.Region__c != null &&  !mapAccountIdToAccount.isEmpty() && mapAccountIdToAccount.ContainsKey(objCase.AccountId)  && mapAccountIdToAccount.get(objCase.AccountId).Territory_Region__c !=null && objCase.Region__c != mapAccountIdToAccount.get(objCase.AccountId).Territory_Region__c;
    }
 /**
    * @description :Update Case fields when status is updated to reopenrequested || code scan fix  : DCP-53957
    * @param objCase 
    * @param objOldCase 
    **/
    public void updateCaseOnStatusReopenedRequested(Case objCase, Case objOldCase)
    {
         //Case Update Owner With Reopen Requester DCP-27008 
         if(objOldCase.Status == System.label.CaseStatusReopenRequested && objCase.Status == objCase.Previous_Status__c && objOldCase.Status != objCase.Status){
            Id loggedInUserId = UserInfo.getUserId();
            if(objCase.Approver_Rejector__c != loggedInUserId){
                objCase.Approver_Rejector__c = loggedInUserId;
            } 
        } 
        
        if(objOldCase.Status != System.label.CaseStatusReopenRequested && objCase.Status == System.label.CaseStatusReopenRequested ){
                   
            if(loggedInUserProfileName == System.label.ProfileCustomerService && objCase.Reopen_Request_Receiver__c  != STRING_CUSTOMER_SERVICE){
                objCase.Reopen_Request_Receiver__c =  STRING_CUSTOMER_SERVICE;
            }
            else if(loggedInUserProfileName != System.label.ProfileCustomerService && objCase.Reopen_Request_Receiver__c  != STRING_TECHNICAL_SUPPORT){
                objCase.Reopen_Request_Receiver__c =  STRING_TECHNICAL_SUPPORT;            
            }
        }
    }
 
    /**
    * @description : Update Case fields when status is updated to closed or completed || code scan fix  : DCP-53957
    * @param objCase 
    * @param objOldCase 
    **/
    public void updateCaseOnStatuseClosedCompleted(Case objCase, Case objOldCase)
    {
        if(SET_COMPLETED_CASE_STATUS.contains(objCase.Status) && !SET_COMPLETED_CASE_STATUS.contains(objOldCase.Status) && objCase.Date_Time_Completed__c == null) 
        {
            objCase.Date_Time_Completed__c = System.now();
        }
        else if(!SET_COMPLETED_CASE_STATUS.contains(objCase.Status) && SET_COMPLETED_CASE_STATUS.contains(objOldCase.Status) && objCase.Date_Time_Completed__c != null) 
        {
            objCase.Date_Time_Completed__c = null;
        }
        if(objOldCase.status != STRING_COMPLETED && (objCase.Status == STRING_CLOSED || objCase.status == STRING_COMPLETED)){
            if(objCase.IVD_Product_Identifier__c || objCase.IVD_Product_Identifier_Additional_Prod__c){
                objCase.IVD_Identifier_at_Completion__c = true;
            }
            else{
                objCase.IVD_Identifier_at_Completion__c = false;
            }
        }
    }

    /**
    * @description :DCP-53957: codescan fix - Refactor Workflow to Update case fields 
    * @param objCase 
    * @param objOldCase 
    **/
    public void updatesCaseRefactorWorkFlowLogic(Case objCase, Case objOldCase){
            //Refactor WorkFlow - Case : Review Comments Updated
            if(objCase.Investigation_Summary_Comments__c != objOldCase.Investigation_Summary_Comments__c){
                objCase.Case_Last_Reviewed__c =System.now();       
            }

            //Refactor WorkFlow - Case: Case First Reviewed Is Blank
            if(objCase.QA_Review__c != objOldCase.QA_Review__c && objCase.Case_First_Reviewed__c == NULL){
                objCase.Case_First_Reviewed__c =System.now();       
            }
            //Case : Last Logistics Reviewed On Is Blank
            if(objCase.Logistics_Review__c != objOldCase.Logistics_Review__c || objCase.Logistics_Investigation_Summary_Comments__c != objOldCase.Logistics_Investigation_Summary_Comments__c || objCase.Carrier_Name__c != objOldCase.Carrier_Name__c || objCase.Shipping_Origin__c != objOldCase.Shipping_Origin__c || objCase.Ship_to_Country__c != objOldCase.Ship_to_Country__c || objCase.Shipment_Tracking_AWB_Number__c != objOldCase.Shipment_Tracking_AWB_Number__c || objCase.Logistics_Delivery_Number__c != objOldCase.Logistics_Delivery_Number__c){
                objCase.Last_Logistics_Reviewed_On__c =System.now();       

                //Case: Case First Logistics Reviewed On Is Blank
                if(objCase.First_Logistics_Reviewed_On__c == NULL){
                    objCase.First_Logistics_Reviewed_On__c =System.now();       
                }
            }
    }
    
    /*
     * Description - checkWorkOrderForCaseCompletion method
	 * return - void
     */
    public void checkWorkOrderForCaseCompletion(List<Sobject> records, Map<Id, SObject> oldRecords){
        set<Id> setCaseIds = new set<Id>(); 
        for(Case objCase : (List<Case>)records) {
            // Added if condition for CMCM-10026
            if (objCase.Status != ((Case)oldRecords.get(objCase.Id)).Status && 
                    (objCase.Status == STRING_COMPLETED || objCase.Status == STRING_CLOSED || 
                    objCase.Status == STRING_PENDING_QA_REVIEW || objCase.Status == Label.CaseStatusPendingLogisticsReview)) {
                setCaseIds.add(objCase.Id); 
            }
        }
        fetchmapCaseIdWorkOrders(setCaseIds);

        for(Case objCase : (List<Case>)records){
            If((objCase.Status ==STRING_COMPLETED || objCase.Status == STRING_CLOSED || objCase.Status == STRING_PENDING_QA_REVIEW || objCase.Status == Label.CaseStatusPendingLogisticsReview) && objCase.Status != ((Case)oldRecords.get(objCase.Id)).Status){
                If(!mapCaseIdWorkOrders.isEmpty() && mapCaseIdWorkOrders.containsKey(objCase.Id) && mapCaseIdWorkOrders.get(objCase.Id) != null && mapCaseIdWorkOrders.get(objCase.Id).size()>0){            
                  objCase.adderror(STRING_CASE_COMPLETION_ERROR_MESSAGE) ;
				  setErrMessages.add(STRING_CASE_COMPLETION_ERROR_MESSAGE);
                } 
            }
        }
    }

    private void fetchmapCaseIdWorkOrders(set<Id> setCaseIds){
        ilib_LogEvent.push(LOG_TITLE + '.fetchmapCaseIdWorkOrders()');
        if(!setCaseIds.isEmpty()){
			CasesHelper.WorkOrders workOrderQuery = new  CasesHelper.WorkOrders();
            workOrderQuery.initMapWOIdToWorkOrders(setCaseIds, false);
            if(!mapWOIdToWorkOrders?.isEmpty()){
                for(SVMXC__Service_Order__c objWO: mapWOIdToWorkOrders.values()){
                    ilib_LogEvent.message('===SVMXC__Service_Order__c:' + JSON.serializePretty(objWO));
                    if(objWO.Integration_Status__c != null && !SET_WO_INTEGRATION_STATUS_SUCCESS.contains(objWO.Integration_Status__c)){
                        if(!mapCaseIdWorkOrders.containsKey(objWO.SVMXC__Case__c)){
                            mapCaseIdWorkOrders.put(objWO.SVMXC__Case__c, new List<SVMXC__Service_Order__c>());
                        }
                        mapCaseIdWorkOrders.get(objWO.SVMXC__Case__c).add(objWO);
                    }
                }
            }
            ilib_LogEvent.message('===fetchmapCaseIdWorkOrders mapCaseIdWorkOrders:' + mapCaseIdWorkOrders);
            
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit(); 
    }
     
    
    /**DCP-28102
    *  @AUTHOR Digvijay Singh
    *  @DESCRIPTION - Restrict Cases Edit on Closed statuses./ code scan fix : DCP-53957 
    *  @RETURN : void
    **/
    public void checkCaseEdit(List<Case> records, Map<Id, SObject> oldRecords) {
        CasesHelper.Profiles profilesQuery = new CasesHelper.Profiles();
        profilesQuery.initLoggedInProfileName();
    
        List<String> lstClosedStatuses = new List<String>{
            Label.CaseStatusCompleted, Label.CaseStatusPendingQAReview,
            Label.CaseStatusPendingLogisticsReview, Label.CaseStatusClosed,
            Label.CaseStatusReopenRequested, Label.CaseStatusClosedDuplicate
        };
    
        List<String> lstOfProfiles = new List<String>{
            Label.ProfileSystemAdmin, Label.Integration_Service_SNAP_Profile,
            Label.Integration_SAP_Service
        };
    
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        // Added condition for CMCM-10026
        for(Case objCaseRec : records) {
            if (lstClosedStatuses.contains(objCaseRec.Status)) {
                mapFieldsToBeByPassed = mapFieldsToBeByPassed.isEmpty() ? initializeFieldMap() : mapFieldsToBeByPassed;
            }
        }

        Map<Id, Set<String>> mapRecordChangedFields = checkCaseEdithelper(records, oldRecords);
        for (Case objCase : records) {
            Case objOldCase = (Case)oldRecords.get(objCase.Id);
            handleCaseStatusChange(objCase, objOldCase, lstClosedStatuses, apexSetting);
            validateCaseOnClosedOrCompleted(objCase, objOldCase, apexSetting, lstOfProfiles, lstClosedStatuses, mapFieldsToBeByPassed, mapRecordChangedFields);
            objCase.Record_Updated_from_SFM__c = false;
        }
    }
    
    private Map<String, List<String>> initializeFieldMap() {
        Map<String, List<String>> mapFieldsToBeByPassed = new Map<String, List<String>>();
        for (Case_Validation_WhiteListed_Field__mdt obj : [SELECT Case_Status__c, Fields_to_be_By_Passed__c FROM Case_Validation_WhiteListed_Field__mdt LIMIT 1000]) {
            List<String> lstFieldsToBeByPassed = new List<String>();
            if (obj != null) {
                lstFieldsToBeByPassed.addAll(String.valueOf(obj.Fields_to_be_By_Passed__c).toLowercase().split(',')); 
            }
            mapFieldsToBeByPassed.put(obj.Case_Status__c, lstFieldsToBeByPassed);
        }
        return mapFieldsToBeByPassed;
    }
    
    private void handleCaseStatusChange(Case objCase, Case objOldCase, List<String> lstClosedStatuses, cs_Apex_Settings__c apexSetting) {
        if (objCase.Status != objOldCase.Status &&
            lstClosedStatuses.contains(objOldCase.Status) &&
            !apexSetting.Bypass_All_Validations__c && allowUpdateOnCase) {
            if ((objCase.Record_Updated_from_SFM__c && objCase.Status == STRING_COMPLETED && objOldCase.Status == STRING_CLOSED)) {
                objCase.addError(Label.CaseReopenedFromWebError);
            }
        }
    }
    
    private Map<Id, Set<String>> checkCaseEdithelper(List<Case> records, Map<Id, SObject> oldRecords) {
        Map<Id, Set<String>> mapRecordChangedFields = new Map<Id, Set<String>>();
        
        mapRecordChangedFields= fetchUpdatedFields(records,oldRecords);
        
        return mapRecordChangedFields;
    }
    
    
    /**
    * @description :Loop to fetch the modified Fields in current transaction 
    * @param records 
    * @param oldRecords 
    * @return Map<Id, Set<String>> 
    **/
    public Map<Id, Set<String>> fetchUpdatedFields(List<Case> records,Map<Id, SObject> oldRecords){
        Map<Id, Set<String>> mapRecordChangedFields = new Map<Id, Set<String>>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();        
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get('Case').getDescribe().fields.getMap();
      
        for(Case objCase:records){
            Case objOldCase = (Case)(oldRecords.get(objCase.Id));
            for(String fieldName : fieldMap.keyset()) {
                //Now check the old and new values of fields
                if(objCase.get(fieldName) != objOldCase.get(fieldName)) {
                    Set<String> changedFields = new Set<String>();
                    if(mapRecordChangedFields.get(objCase.id) == null) {
                        changedFields.add(fieldName);
                        mapRecordChangedFields.put(objCase.id, changedFields);
                    } else {
                        changedFields.addAll(mapRecordChangedFields.get(objCase.id));
                        changedFields.add(fieldName);
                        mapRecordChangedFields.put(objCase.id, changedFields);
                    }
                }
            }
        }
        return mapRecordChangedFields;
        
    }
    /**
    * @description : Validate on Case when status is closed / completed
    * @param objCase 
    * @param apexSetting 
    * @param lstOfProfiles 
    * @param lstClosedStatuses 
    * @param mapFieldsToBeByPassed 
    * @param mapRecordChangedFields 
    **/
    public void validateCaseOnClosedOrCompleted(Case objCase,Case objOldCase,cs_Apex_Settings__c apexSetting,list<string> lstOfProfiles,list<string> lstClosedStatuses, Map<String,List<String>> mapFieldsToBeByPassed,Map<Id, Set<String>> mapRecordChangedFields){
        

        //QACM-267, "Potentially Reportable" field cannot be edited when the Status is Completed/Closed.
        if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && (objCase.Status == STRING_COMPLETED || objCase.Status == Label.CaseStatusClosed || objCase.Status == Label.CaseStatusClosedDuplicate) && objCase.Potentially_Reportable__c != objOldCase.Potentially_Reportable__c && !apexSetting.Bypass_All_Validations__c  && allowUpdateOnCase) {
            objCase.addError(Label.CaseErrorMsgOnEdit);
        }

         // Added additional criteria for closed/completed by shruti Karn for INC0242857          
            //Below if block check's for conditions on which the edit need to be restricted on various case statuses.
            if(!lstOfProfiles.contains(loggedInUserProfileName) && lstClosedStatuses.contains(objCase.Status) && objCase.Status == objOldCase.Status  && (!objCase.Record_Updated_from_SFM__c ||(objCase.Record_Updated_from_SFM__c && (objCase.Status==STRING_COMPLETED || objCase.Status == STRING_CLOSED))) && allowUpdateOnCase  && apexSetting.Bypass_All_Validations__c!=true)
            {
                 // To allow owner Update when Unread Emails is True and  owner is changed from an individual user to a queue by automated user only
                if(!(objCase.ownerId != objOldCase.OwnerId && objCase.Unread_Emails__c && UserInfo.getFirstName() == Label.Automated_Process_User) && compareFieldList(mapFieldsToBeByPassed.get(objCase.Status),mapRecordChangedFields.get(objCase.id))) {
                    validateCaseOnEdit(objCase,objOldCase,apexSetting);                   
                }
            }
    }

    /**
    * @description : Display Error message on case based conditions
    * @param objCase 
    * @param apexSetting 
    **/
    public void validateCaseOnEdit(Case objCase,Case objOldCase,cs_Apex_Settings__c apexSetting){
     
            if(objCase.Status==Label.CaseStatusCompleted &&  UserInfo.getFirstName()!=Label.Automated_Process_User && !(objoldCase.Closed_with_Associated_Codes__c==false && objCase.Closed_with_Associated_Codes__c==true)){
               objCase.addError(Label.CaseErrorMsgOnEdit); 
            }  
             
            if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && objCase.Status==Label.CaseStatusPendingQAReview && !apexSetting.Bypass_QA_Validations__c){
            
                 objCase.addError(Label.CaseErrorMsgOnEdit); 
             
            }
            
            if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && objCase.Status==Label.CaseStatusPendingLogisticsReview && !apexSetting.Bypass_QA_Validations__c){
                objCase.addError(Label.CaseErrorMsgOnEdit); 
            }
            validateCaseOnStatus(objCase,apexSetting);   
    }

    /**
    * @description :Display error message based on below conditions
    * @param objCase 
    * @param apexSetting 
    **/
    public void validateCaseOnStatus(Case objCase,cs_Apex_Settings__c apexSetting){
        if(objCase.Status==Label.CaseStatusClosed && !apexSetting.Bypass_QA_Validations__c && UserInfo.getFirstName()!=Label.Automated_Process_User){
            objCase.addError(Label.CaseErrorMsgOnEdit); 
        }
        
        if(objCase.Status==Label.CaseStatusReopenRequested && !apexSetting.Bypass_QA_Validations__c ){
            objCase.addError(Label.CaseErrorMsgOnEdit); 
        }
        
        if(objCase.Status==Label.CaseStatusClosedDuplicate){
           objCase.addError(Label.CaseErrorMsgOnEdit); 
        } 
    }
    
    
    /**DCP-25243
    *  @AUTHOR Tapas Chakraborty
    *  @DESCRIPTION - Add error for spam and notification cases
    *  @RETURN : void
    **/
    private static void addErrorMessageForSpamAndNotificationCases(List<Case> lstNewCases)
    {
        for(Case objCase : lstNewCases)
        {
           if(objCase.RecordTypeId!=INQUIRY_CASE_RECORDTYPE){
                    objCase.addError(CHECK_CASE_TYPE_ON_NOTIFICATION_BUTTON);
					setErrMessages.add(CHECK_CASE_TYPE_ON_NOTIFICATION_BUTTON);
		   }
                else if(!LST_SERVICE_PROFILES.contains(objCase.Logged_In_User_Profile__c) && objCase.Logged_In_User_Profile__c!=System.Label.ProfileSystemadmin){
                    objCase.addError(CHECK_PROFILE_ON_NOTIFICATION_BUTTON);
					setErrMessages.add(CHECK_PROFILE_ON_NOTIFICATION_BUTTON);
				}
        }
    }
    
    /**DCP-28102
    *  @AUTHOR Digvijay Singh
    *  @DESCRIPTION - Compare List values. 
    *  @RETURN : Boolean
    **/
    public static Boolean compareFieldList(List<String> fieldsTobeSkippedforCompleted , Set<String> fieldsModified){
        Boolean isError=false;
        if(fieldsModified!=null && !fieldsModified.isEmpty()){
            for(String fieldName :fieldsModified ){
                if(!fieldsTobeSkippedforCompleted.Contains(fieldName.toLowerCase())){
                    isError=true;
                    break;
                }
            }       
        }
        return isError;   
    }

   /**
    *  @AUTHOR -Nishan Shetty [CMCP-22]
    *  @DESCRIPTION -Method to check Case Work Order Association Before Work Order Creation, so that no duplicate WO is created on Case.
    *  @PARAM List<Sobject> records  - List of Cases
    *  @PARAM Map<Id,Sobject> oldRecords   
    *  @RETURN : void
    **/
    public static void validateCaseWorkAssociationForGTS(List<Sobject> records, Map<Id,SObject> oldRecords) {
        
        for(Case objCase:(List<Case>) records) {
            Case oldCaseObj = (Case) oldRecords.get(objCase.Id);
            if(objCase.GTS_Status__c!=oldCaseObj.GTS_Status__c && objCase.GTS_Status__c==STRING_GTS_STATUS_REQUEST_INITIATED && objCase.Work_Order__c!=null) {
                objCase.addError(Label.WorkOrderCaseAssociationErrorMsg);
            }
        }

    }

        /*
    *  @DESCRIPTION = QACM-5 Whenever QA Profiles update QA Reopen Code(s) then populate Reason for Reopen Field
    *  @PARAM :  List<Sobject> -- List of new case records
                 Map<Id, sObject> --  Map of old cases 
    *  @RETURN: void
    *  @AUTHOR - Abhinav Gupta
    *  @DATE - 9th March 2022
    */
    public static void checkIfReopenCodesUpdated(List<sObject> records, Map<Id, sObject> oldRecords){
        ilib_LogEvent.push(LOG_TITLE + '.checkIfReopenCodesUpdated()');
        try{
            for(case objCase : (List<Case>) records){
                Case objOldCase = null;
                if(oldRecords != null){
                    objOldCase = (Case)oldRecords.get(objCase.id);
                }
                if(objOldCase.QA_Reopen_Code_s__c != objCase.QA_Reopen_Code_s__c){
                    objCase.Reason_for_Reopen__c = STRING_QA_REVIEW_REQUEST_UPDATE+objCase.QA_Reopen_Code_s__c;
                }
            }
        }
        catch(Exception e){
            System.debug(e.getmessage());
            ApexExceptions.emit('checkIfReopenCodesUpdated',e);
        }
        ilib_LogEvent.pop();
        
    }

    //***********************functional methods for before update event ends**************************************
    
    //***********************functional methods for after insert event starts**************************************	
    
	/*
    * Description: Breaking "createWorkOrder" Method to remove NPath Complexity.
    * Author: Chaitanya Karthik  25/7/2023
    *CMCM-196 ------ START -------
    */
    private void createWorkOrder(List<Sobject> records, Map<Id, Case> mapOldCaseRecs) {
        // Start DCP-46058
        CasesHelper.Profiles profilesQuery = new CasesHelper.Profiles();
        profilesQuery.initLoggedInProfileName();
        // End DCP-46058
    
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setCaseIdWithWO = new Set<Id>();
        boolean isBusinessIssueCase = false;
        List<SVMXC__Service_Order__c> lstWOsToInsert = new List<SVMXC__Service_Order__c>();
    
        if (!UserInfo.getName().containsIgnoreCase(STRING_PROACTIVE_INTEGRATION_USER)) {
            for (Case objCase : (List<Case>)records) {
                setCaseIds.add(objCase.Id);
    
                if (objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE) {
                    isBusinessIssueCase = true;
                }
            }
    
            if (!setCaseIds.isEmpty() && isBusinessIssueCase) {
                CasesHelper.WorkOrders workOrderQuery = new  CasesHelper.WorkOrders();
				workOrderQuery.initMapWOIdToWorkOrders(setCaseIds, false); 
            }
    
            setCaseIdWithWO = getCaseIdWithWorkOrder(mapWOIdToWorkOrders);
    
            for (Case objCase : (List<Case>)records) {
                Case objOldRec = mapOldCaseRecs != null ? mapOldCaseRecs.get(objCase.Id) : null;
    
                if (isBusinessIssueCase && (objOldRec == null || objCase.RecordTypeId != objOldRec.RecordTypeId)) {
                    if (!setCaseIdWithWO.contains(objCase.Id)) {
                        lstWOsToInsert.add(createWorkOrderForCase(objCase));
                    }
                }
            }
    
            if (!lstWOsToInsert.isEmpty()) { 
                insert lstWOsToInsert;
                workOrderList.addall(lstWOsToInsert);
            }
        }
    }
    
    private Set<Id> getCaseIdWithWorkOrder(Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrders) {
        Set<Id> caseIdsWithWO = new Set<Id>();
        if (mapWOIdToWorkOrders != null && !mapWOIdToWorkOrders.isEmpty()) {
            for (SVMXC__Service_Order__c objWO : mapWOIdToWorkOrders.values()) {
                caseIdsWithWO.add(objWO.SVMXC__Case__c);
            }
        }
        return caseIdsWithWO;
    }
    
    private SVMXC__Service_Order__c createWorkOrderForCase(Case objCase) {
        SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c();
    
        // Start DCP-46058
        if (loggedInUserProfileName == System.label.Field_Service || 
            loggedInUserProfileName == System.label.Profile_Channel_Partner_Sales_and_Service || 
            loggedInUserProfileName == System.label.ProfileChannelPartnerService) {
            
            objWO.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', STRING_WORK_ORDER_RT_FIELD_SERVICE);
            objWO.SVMXC__Order_Type__c = STRING_LABEL_SERVICE_ACTIVITIES;
            objWO.SVMXC__Order_Status__c = STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
        } else {
            objWO.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', STRING_WORK_ORDER_RT_REMOTE_SUPPORT);
            objWO.SVMXC__Order_Type__c = STRING_WORK_ORDER_RT_REMOTE_SUPPORT;
            objWO.SVMXC__Order_Status__c = STRING_IN_PROGRESS;
        }
        // End DCP-46058
        objWO.SVMXC__Case__c = objCase.Id;
        objWO.OwnerId = objCase.OwnerId;
        objWO.Send_Notification_To_Customer__c = false;
        objWO.SVMXC__Billing_Type__c = '';
        objWO.Is_Auto_Created__c = true; //To bypass validation for preventing manual creation of Work Order-DCP-14702
        objWO.SVMXC__Component__c = objCase.SVMXC__Component__c; // DCP-25645
        objWO.SVMXC__Contact__c = objCase.ContactId; // Refactor PB :: Work_Order_Update_Contact_Preferred_Language
        objWO.Subscription__c = objCase.Subscription__c; // DCP-52634
        objWO.SubscriptionID__c = objCase.SubscriptionID__c; // DCP-52634
    
        return objWO;
    }

    //CMCM-196 ------END--------
    
	/*
     * Description - asynchoronousMethodCallsAfterInsert method
	 * return - void
     */
    public static void asynchoronousMethodCallsAfterInsert(List<Sobject> records){
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('CasesAfterInsert');       
        Set<Id> setCaseIdsCodeCoverage = new Set<Id>();
        Set<Id> setCasesId = new Set<Id>();             
        for(Case objCase : (List<Case>)records) {

            if(objCase.Status != STRING_CLOSED){
              setCasesId.add(objCase.Id);     
            } 
            
            if(objCase.SVMXC__Component__c != null || objCase.SVMXC__Site__c != null || objCase.Subscription__c != null){
                setCaseIdsCodeCoverage.add(objCase.id);
            }

        }
                
        //process builder Status and owner Update DCP-27008        
        if(!setCasesId.isEmpty() && runTimeInStateCreationOnInsert){
            queueableThread.logandQueue(new CaseQueueable(STRING_CREATE_TIME_IN_STATE_RECORDS, setCasesId, 'CaseInserted', null, null),STRING_CASE_QUEUEABLE,STRING_CREATE_TIME_IN_STATE_RECORDS);
            runTimeInStateCreationOnInsert = false;            
        }        
                 
        //InsertEntitlementAndcheckContractCoverage  
        if(setCaseIdsCodeCoverage != null && !setCaseIdsCodeCoverage.isEmpty()){
            queueableThread.logandQueue(new CaseQueueable(INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE, setCaseIdsCodeCoverage, null, null, null),STRING_CASE_QUEUEABLE,INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE);
        } 
        
        if(!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
    }  
                
    //***********************functional methods for after insert event ends**************************************
    //***********************functional methods for after update event starts*************************************
    
    /*
    *  @AUTHOR:  Rishi Sharma
    *  @DESCRIPTION: DCP-47271 -Update Work Order field on Case after an old case has been reopened.
    *  @PARAM :  List<Sobject> -- List of new case records
                 Map<Id, SObject> --  mapOldCases map of old Case records.
    *  return : void
    */ 
    public void updateWOReopenedCase(List<Sobject> lstNewCases, Map<Id, Case> mapOldCases)
    {
        set<Id> setCaseIds = new set<Id>();

        for(Case objNewCase : (List<Case>)lstNewCases){
            Case objOldCase  = null;
            if(mapOldCases != null){
                objOldCase = mapOldCases.get(objNewCase.Id);
            }
            if(objNewCase.Work_Order__c == null && objOldCase.Status == Label.CaseStatusReopenRequested && (objNewCase.Status == Label.CaseStatusReopened || objNewCase.Status == Label.CaseStatusInProgress)){
                setCaseIds.add(objNewCase.Id);
            }
        }
        updateWOonCase(lstNewCases, setCaseIds);
    }
    
    /*
    *  @AUTHOR:  Rishi Sharma
    *  @DESCRIPTION: DCP-47271 -Update Work Order field on Case after an old case has been reopened.
    *  @PARAM :  List<Sobject> -- List of new case records
                 Set<id> --  set of cases for the WO.
    *  return : void
    */ 
    public void updateWOonCase(List<Sobject> lstNewCases, Set<id> setCaseIds) 
    {
        Map<id, id> mapCaseIdtoWorkOrder = new Map<id, id>();
        if((lstWorkOrders.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && setCaseIds != null && !setCaseIds.isEmpty()) {
            lstWorkOrders = new WorkOrdersSelector().selectWorkOrderIdOnCase(setCaseIds);
        }
        if(!lstWorkOrders.isEmpty()){
            for(SVMXC__Service_Order__c wo :lstWorkOrders){
                mapCaseIdtoWorkOrder.put(wo.SVMXC__Case__c, wo.id);
            }
        }
        for(Case objNewCase : (List<Case>)lstNewCases) {
				
            if(mapCaseIdtoWorkOrder.containsKey(objNewCase.id)){
                objNewCase.Work_Order__c = mapCaseIdtoWorkOrder.get(objNewCase.id);
            }
        }

    }
	
    /*
     * Description - insertAssociatedCodes method
	 * return - void
     */
    public void insertAssociatedCodes(){
        System.debug('lstAssociationCodesToInsert '+lstAssociationCodesToInsert);
        If(!lstAssociationCodesToInsert.isEmpty())
        {
            insert lstAssociationCodesToInsert;
            lstAssociationCodesToInsert.clear();
            mapAssociatedCodeIdsToAssociatedCodes = null;
            setAsynchoronousMethods.add(STRING_UNCHECKCLOSEDWITHASSOCIATEDCODES);
        }
    }
	
     /*
    * Description: Modifying "asynchoronousMethodCallsAfterupdate" Method to remove NPath Complexity.
    * Author: Chaitanya Karthik  25/7/2023
    *CMCM-196 ------ START -------
    */
    public void asynchoronousMethodCallsAfterupdate(List<Sobject> records, Map<Id, Case> mapOldCaseRecs) {
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('CasesAfterUpdate');
    
        processCases(records, mapOldCaseRecs, queueableThread);
    
        if (!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SERVICE);
        }
    }
    
    private void processCases(List<Sobject> records, Map<Id, Case> mapOldCaseRecs, ilib_Queueablethread queueableThread) {
        Map<Id, Case> idToCaseRecForUpdate = new Map<Id, Case>();//DCP-42922   
        Set<Id> caseIdsWithNewIPOrProduct = new Set<Id>();//DCP-42922   
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setQualtricsCaseIds = new Set<Id>(); //DCP-46141
        set<Id> setOwnerChangedCaseIds = new set<Id>();           
        Set<Id> setCaseIdsCodeCoverage = new Set<Id>();
        Set<Id> setCaseQualifyCompletion = new Set<Id>();
        Set<Id> setGTSRelocationCases = new Set<Id>();//CMCP-22
        Map<Id,Case> caseIdsWithRecordTypeChangeBIToSR = new Map<Id,Case>();//QACM-108
        Set<Id> setcaseIdForVeevaCallout = new Set<Id>();//DCP-51201
        for (Case objCase : (List<Case>) records) {
            Case objOldCase = mapOldCaseRecs != null && !mapOldCaseRecs.isEmpty() ? mapOldCaseRecs.get(objCase.Id) : null;
    
            setCaseIds.addAll(processCaseStatusChange(objCase, objOldCase));
            setOwnerChangedCaseIds.addAll(processCaseOwnerChange(objCase, objOldCase));
            caseIdsWithNewIPOrProduct.addAll(processNewIPOrProduct(objCase, objOldCase));
            caseIdsWithRecordTypeChangeBIToSR.putall(processRecordTypeChange(objCase, objOldCase));
            fetchCaseIdsForVeevaCallout(setcaseIdForVeevaCallout, objCase, objOldCase);
            fetchCaseQualtricsAndQC(objCase, objOldCase, setQualtricsCaseIds, setCaseQualifyCompletion);
            fetchCaseCodeCoverageAndGSTRelocation(objCase, objOldCase, setCaseIdsCodeCoverage, setGTSRelocationCases);
        }
    
       //QCM-108 starts
       if(caseIdsWithRecordTypeChangeBIToSR != null && !caseIdsWithRecordTypeChangeBIToSR.keySet().isEmpty()) {
        disAssociateCodeonRTChange(caseIdsWithRecordTypeChangeBIToSR,queueableThread);
        } 
       //QCM-108 Ends
        idToCaseRecForUpdate = checkWorkFlowConditonsAndAssignValues((List<Case>) records, mapOldCaseRecs);
        asyncCallForCalloutToVeeva(setcaseIdForVeevaCallout, queueableThread);
        asyncCallForCalloutToQualtricsAndCaseUpdate(setQualtricsCaseIds, setCaseIds, setOwnerChangedCaseIds,
                                                    idToCaseRecForUpdate, queueableThread);
        asyncCallForSAPCalloutANDCaseUpdate(caseIdsWithNewIPOrProduct, setCaseQualifyCompletion, setCaseIdsCodeCoverage,
                                             setGTSRelocationCases, queueableThread);
    }
    
    
    private static Set<Id> processCaseStatusChange(Case objCase, Case objOldCase) {
        Set<Id> setCaseIds = new Set<Id>();
        if (objCase.status != objOldCase.status && objCase.status != null) {
            setCaseIds.add(objCase.Id);
        }
        return setCaseIds;
    }
    
    private static set<Id> processCaseOwnerChange(Case objCase, Case objOldCase) {
        set<Id> setOwnerChangedCaseIds = new set<Id>(); 
        if (objCase.OwnerId != objOldCase.OwnerId && objCase.OwnerId != null) {
            setOwnerChangedCaseIds.add(objCase.id);
        }
        return setOwnerChangedCaseIds;
    }
    
    private static set<Id> processNewIPOrProduct(Case objCase, Case objOldCase) {
        Set<Id> caseIdsWithNewIPOrProduct = new Set<Id>();
        if (objCase.SVMXC__Component__c != objOldCase.SVMXC__Component__c || objCase.SVMXC__Product__c != objOldCase.SVMXC__Product__c) {
            caseIdsWithNewIPOrProduct.add(objCase.Id);
        }
        return caseIdsWithNewIPOrProduct;
    }
    
    private static Map<Id, Case> processRecordTypeChange(Case objCase, Case objOldCase) {
        Map<Id,Case> caseIdsWithRecordTypeChangeBIToSR = new Map<Id,Case>();
        if (objCase.RecordTypeId != objOldCase.RecordTypeId && objOldCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && objCase.RecordTypeId == SERVICE_REQUEST_CASE_RECORDTYPE) {
            caseIdsWithRecordTypeChangeBIToSR.put(objCase.Id, objCase);
        }
        return caseIdsWithRecordTypeChangeBIToSR;
    }
    

    //CMCM-196 -------END-------
    
    /**QACM-108
    * @description : To DisAssociateCodes on RT Change
    * @param objCase 
    * @param objOldCase 
    **/
    public void disAssociateCodeonRTChange(Map<Id, Case> mapCaseswithRTChange,ilib_Queueablethread  queueableThread) {
        if(mapCaseswithRTChange != null && !mapCaseswithRTChange.keySet().isEmpty()) {
            queueableThread.logandQueue(new CaseUpdateQueueable('updateCodeTitleonRTChange',mapCaseswithRTChange),STRING_CASE_QUEUEABLE,STRING_DISASSOCIATECODES_RECORDS);       
        }
    }
    /**QACM-108
    * @description : To update case fields on RT Change
    * @param objCase 
    * @param objOldCase 
    **/
    public void updateCaseRTChange(Map<Id, Case> mapCaseswithRTChange,ilib_Queueablethread queueableThread) {
        queueableThread.logandQueue(new CaseUpdateQueueable('updateCase',mapCaseswithRTChange),'CaseUpdateQueueable','CaseUpdateQueueable');       
    }

    
    /**
    * @description : To fetchCaseQualtricsAndQC
    * @param objCase 
    * @param objOldCase 
    * @param setQualtricsCaseIds 
    * @param setCaseQualifyCompletion 
    **/
    public void fetchCaseQualtricsAndQC(Case objCase,Case objOldCase,Set<Id> setQualtricsCaseIds,Set<Id> setCaseQualifyCompletion)
    {
        
            //DCP-46141 - if case origin = wechat AND Sent to Qualtrics = true AND Contact lookup is not blank
			if(objCase.Sent_to_Qualtrics__c != objOldCase.Sent_to_Qualtrics__c && objCase.Sent_to_Qualtrics__c 
            && objCase.Origin == STRING_CASE_ORIGIN_WECHAT
            && String.isNotBlank(objCase.ContactId))
            {
             setQualtricsCaseIds.add(objCase.Id);                
            }
         
            if (objCase.Has_BI_Case_Subject_Code__c !=objOldCase.Has_BI_Case_Subject_Code__c 
            ||objCase.Has_SR_Case_Subject_Code__c !=objOldCase.Has_SR_Case_Subject_Code__c
            ||objCase.OwnerId !=objOldCase.OwnerId
            ||objCase.Unread_Emails__c !=objOldCase.Unread_Emails__c
            ||objCase.PAE_PFA_Evaluation_Required__c != objOldCase.PAE_PFA_Evaluation_Required__c
                ) 
            {
                setCaseQualifyCompletion.add(objCase.Id);
            }    

    }
    /**
    * @description : To fetchCaseCodeCoverageAndGSTRelocation
    * @param objCase 
    * @param objOldCase 
    * @param setCaseIdsCodeCoverage 
    * @param setGTSRelocationCases 
    **/
    public void fetchCaseCodeCoverageAndGSTRelocation(Case objCase,Case objOldCase,Set<Id> setCaseIdsCodeCoverage,Set<Id> setGTSRelocationCases){
               
        //DCP-52634 - merge if conditions
        if(objOldCase.SVMXC__Component__c != objCase.SVMXC__Component__c
                || (objCase.SVMXC__Site__c != null && objOldCase.SVMXC__Site__c != objCase.SVMXC__Site__c) 
                || objOldCase.Subscription__c != objCase.Subscription__c) {
            setCaseIdsCodeCoverage.add(objCase.id)  ;
        }
        
        
        //move to updateCaseFields method            

        //START CMCP-22
        if(objCase.GTS_Status__c==STRING_GTS_STATUS_REQUEST_INITIATED && objCase.GTS_Status__c !=objOldCase.GTS_Status__c) {
            setGTSRelocationCases.add(objCase.Id);
        }
        //END CMCP-22
    }

    /**
    * @description :Async Call to update case fields and do callout to Qualtrics || DCP-53957 codescan fix
    * @param setQualtricsCaseIds 
    * @param setCaseIds 
    * @param setOwnerChangedCaseIds 
    * @param idToCaseRecForUpdate 
    **/
    public void asyncCallForCalloutToQualtricsAndCaseUpdate(Set<Id> setQualtricsCaseIds,Set<Id> setCaseIds,set<Id> setOwnerChangedCaseIds, Map<Id, Case> idToCaseRecForUpdate,ilib_Queueablethread  queueableThread){
        
        //DCP-46141 - moved it as first queueable as there could be some dmls happening before the callout which will error out.
        if(setQualtricsCaseIds != null && !setQualtricsCaseIds.isEmpty()){
			queueableThread.logandQueue(new CaseQueueable('doCalloutToQualtrics', setQualtricsCaseIds, null, null, null),STRING_CASE_QUEUEABLE,'doCalloutToQualtrics');   
		}

        //process builder Status and owner Update DCP-27008         
        if(!setCaseIds.isEmpty() && runTimeInStateCreationOnInsert && runTimeInStateUpdateStatusOnce){
            queueableThread.logandQueue(new CaseQueueable(STRING_CREATE_TIME_IN_STATE_RECORDS, setCaseIds, 'updateStatus', null, null),STRING_CASE_QUEUEABLE,STRING_CREATE_TIME_IN_STATE_RECORDS);
            runTimeInStateUpdateStatusOnce = false;
        }
        if(!setOwnerChangedCaseIds.isEmpty() && runTimeInStateCreationOnInsert &&  runTimeInStateCreationOnce){
            queueableThread.logandQueue(new CaseQueueable(STRING_CREATE_TIME_IN_STATE_RECORDS, setOwnerChangedCaseIds, 'updateOwner', null, null),STRING_CASE_QUEUEABLE,STRING_CREATE_TIME_IN_STATE_RECORDS);
            runTimeInStateCreationOnce = false;
        }
       
        //case Process builders and workflows refactoring DCP-42922
        if(idToCaseRecForUpdate != null && !idToCaseRecForUpdate.keySet().isEmpty()){
            queueableThread.logandQueue(new CaseQueueable('updateCaseFields', null, null, idToCaseRecForUpdate, null),STRING_CASE_QUEUEABLE,'updateCaseFields');        
        }
              
    }
    
    /**
    * @description : Async call to update case fields and send GST to SAP || CodeScan : DCP-53957
    * @param caseIdsWithNewIPOrProduct 
    * @param setCaseQualifyCompletion 
    * @param setCaseIdsCodeCoverage 
    * @param setGTSRelocationCases 
    **/
    public void asyncCallForSAPCalloutANDCaseUpdate(Set<Id> caseIdsWithNewIPOrProduct,Set<Id> setCaseQualifyCompletion,Set<Id> setCaseIdsCodeCoverage,Set<Id> setGTSRelocationCases,ilib_Queueablethread  queueableThread)
    {
        //case Process builders and workflows refactoring DCP-42922
        if(setCaseQualifyCompletion != null && !setCaseQualifyCompletion.isEmpty()){    
            queueableThread.logandQueue(new CaseQueueable('updateCaseQualifyCompletion', setCaseQualifyCompletion, null, null, null),STRING_CASE_QUEUEABLE,'updateCaseQualifyCompletion');    
        }
                 
        //InsertEntitlementAndcheckContractCoverage  
        if(setCaseIdsCodeCoverage != null && !setCaseIdsCodeCoverage.isEmpty()){
            queueableThread.logandQueue(new CaseQueueable(INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE, setCaseIdsCodeCoverage, null, null, null),STRING_CASE_QUEUEABLE,INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE);
        } 
			
        //START CMCP-22
        if(setGTSRelocationCases != null && !setGTSRelocationCases.isEmpty()){
			queueableThread.logandQueue(new CaseQueueable('sendGTSCaseToSAP', setGTSRelocationCases, null, null, null),STRING_CASE_QUEUEABLE,'sendGTSCaseToSAP');    
		}
        //END CMCP-22
        
       
    }


    //CodeScan fix:

    
   /*
     * Description - checkWorkFlowConditonsAndAssignValues method || CodeScan Fix : DCP-53957
	 * return - Map<Id, Case>
     */
    public Map<Id, Case> checkWorkFlowConditonsAndAssignValues(List<Case> lstNewCases, Map<Id, Case> mapOldCases){
        
        Map<Id, Case> caseIdToRec = new  Map<Id, Case>();
        Set<Id> setCasesWithIVDProducts = new Set<Id>();
        List<Case> lstCaseNonIVDProduct = new List<Case>();
		Map<String,String> mapMetadata = new Map<String,String>(); 
		
		for(Associated_Code_Mapping__mdt associateMdt : [Select MasterLabel,Category__c,Code_Title__c,Sub_Type__c from Associated_Code_Mapping__mdt LIMIT 1000]){
			mapMetadata.put(associateMdt.Sub_Type__c+'_'+associateMdt.Category__c, associateMdt.Code_Title__c);
		} 
        for(Case objNewCase : lstNewCases) {
            Case objOldCase  = null;
            if(mapOldCases != null){
                objOldCase = mapOldCases.get(objNewCase.Id);
            }
            //DCP-44980
            if(objNewCase.QA_Review__c != objOldCase.QA_Review__c && objOldCase.QA_Review__c == STRING_QA_REVIEW_NO_IVD_PRODUCT)
            {
                lstCaseNonIVDProduct.add(objNewCase); 
            }
        }

        if(!lstCaseNonIVDProduct.isEmpty())
        {
            setCasesWithIVDProducts = getCaseIdWithAdditionalIVDProduct(lstCaseNonIVDProduct); 
        }

        caseIdToRec=checkWorkFlowUpdateCaseFields(lstNewCases,mapOldCases,caseIdToRec,setCasesWithIVDProducts);

        return caseIdToRec;
    }

    /**
    * @description :Workflow functionality to update Case field || CodeScan Fix : DCP-53957
    * @param lstNewCases 
    * @param mapOldCases 
    * @param caseIdToRec 
    **/
    public Map<Id, Case> checkWorkFlowUpdateCaseFields(List<Case> lstNewCases, Map<Id, Case> mapOldCases, Map<Id, Case> caseIdToRec,Set<Id> setCasesWithIVDProducts)
    {  
         //DCP-42922
         set<string> setCompletedAndPendingCase = new set<string>{Label.CaseStatusCompleted, Label.CaseStatusPendingLogisticsReview, Label.CaseStatusPendingQAReview};
         
         //DCP-44980
        for(Case objNewCase : lstNewCases) {
            
            Case objOldCase  = null;
                if(mapOldCases != null){
                    objOldCase = mapOldCases.get(objNewCase.Id);
                }
                //Case : Notify Customer on Case Closure when logged in user is CS, Case : Notify Customer on Case Closure when logged in user is TS/FS 
                if(objNewCase.Status != objOldCase.Status && objOldCase.Status != System.Label.CaseStatusPendingLogisticsReview && objNewCase.Is_Case_Completed__c == true && objNewCase.Send_Case_Completion_Email__c == true ){

                    caseIdToRec.put(objNewCase.Id, new Case(Id = objNewCase.Id, Is_Case_Completed__c = false));
                }
            //Case : CloseCompletedCase
               
                checkWorkFlowUpdateStatusClosed(objNewCase,caseIdToRec);
			
                checkWorkFlowUpdateClosedAssciatedCode(objNewCase,objOldCase,caseIdToRec,setCompletedAndPendingCase);

                checkWorkFlowUpdateIVDProdIdentifier(objNewCase,objOldCase,caseIdToRec,setCasesWithIVDProducts);
        }

        return caseIdToRec;
    }

    /**
    * @description :Workflow functionality to update Case "Status" field to closed || CodeScan Fix : DCP-53957
    * @param objNewCase 
    * @param caseIdToRec 
    **/
    public void checkWorkFlowUpdateStatusClosed(Case objNewCase,Map<Id, Case> caseIdToRec){

        if((objNewCase.Work_Order_Status__c == 'Not Applicable' || objNewCase.Work_Order_Status__c == STRING_CLOSED) && objNewCase.Status == STRING_COMPLETED ){
            if(caseIdToRec != null && !caseIdToRec.isEmpty() && caseIdToRec.containsKey(objNewCase.Id)){
                caseIdToRec.get(objNewCase.Id).Status = STRING_CLOSED;   
                //DCP-47530
                //adding this boolean to bypass the validation on editing case status field for TPSP user.
                Cases.bypassStatusEditValidationForTPSP = true;
            }
            else{
                caseIdToRec.put(objNewCase.Id, new Case(Id = objNewCase.Id, Status = STRING_CLOSED));
            }

            isrecordupdatedfromSFM=true;
            caseIdToRec.get(objNewCase.Id).Record_Updated_from_SFM__c=true;
        }
    }
    /**
    * @description : Workflow functionality to update Case "Closed with Assciated Code" field || CodeScan Fix : DCP-53957
    * @param objNewCase 
    * @param objOldCase 
    * @param caseIdToRec 
    * @param setCompletedAndPendingCase 
    **/
    public void checkWorkFlowUpdateClosedAssciatedCode(Case objNewCase,Case objOldCase,Map<Id, Case> caseIdToRec,set<string> setCompletedAndPendingCase) {
        if(objNewCase.Status != objOldCase.Status && setCompletedAndPendingCase.contains(objNewCase.Status) && objNewCase.Closed_with_Associated_Codes__c){
                
            if(caseIdToRec != null && !caseIdToRec.isEmpty() && caseIdToRec.containsKey(objNewCase.Id)){
                caseIdToRec.get(objNewCase.Id).Closed_with_Associated_Codes__c = false;  

            }
            else{
                caseIdToRec.put(objNewCase.Id, new Case(Id = objNewCase.Id, Closed_with_Associated_Codes__c = false));
            }
                
            isrecordupdatedfromSFM=true;
            caseIdToRec.get(objNewCase.Id).Record_Updated_from_SFM__c=true;
        }
    }
    /**
    * @description : Workflow functionality to update Case IVD Product Identifier fields || CodeScan Fix : DCP-53957
    * @param objNewCase 
    * @param caseIdToRec 
    * @param setCasesWithIVDProducts 
    **/
    public void checkWorkFlowUpdateIVDProdIdentifier(Case objNewCase,Case objOldCase,Map<Id, Case> caseIdToRec,Set<Id> setCasesWithIVDProducts){
       
        //Case: Uncheck Update From SFM
        if(objNewCase.Record_Updated_from_SFM__c == true && !isrecordupdatedfromSFM){
            if(caseIdToRec != null && !caseIdToRec.isEmpty() && caseIdToRec.containsKey(objNewCase.Id)){
                caseIdToRec.get(objNewCase.Id).Record_Updated_from_SFM__c = false;  
            }
            else{
                caseIdToRec.put(objNewCase.Id, new Case(Id = objNewCase.Id, Record_Updated_from_SFM__c = false));
            }               
        }
        
        //DCP-44980, Non IVD Products & QA Review
        if(objNewCase.QA_Review__c != objOldCase.QA_Review__c && !setCasesWithIVDProducts.isEmpty())
        {
            Boolean boolProductIdentifierAdditionalProd = false;
            if(objNewCase.QA_Review__c != STRING_QA_REVIEW_NO_IVD_PRODUCT && setCasesWithIVDProducts.contains(objNewCase.Id))
            {
                boolProductIdentifierAdditionalProd = true;
            }
            if(caseIdToRec != null && !caseIdToRec.isEmpty() && caseIdToRec.containsKey(objNewCase.Id))
            {
                caseIdToRec.get(objNewCase.Id).IVD_Product_Identifier_Additional_Prod__c = boolProductIdentifierAdditionalProd;	
            }
            else
            {
                caseIdToRec.put(objNewCase.Id, new Case(Id = objNewCase.Id, IVD_Product_Identifier_Additional_Prod__c = boolProductIdentifierAdditionalProd));
            }  
        } 
    }
    /**
    *  @author Nitin Sood
    *  @description - DCP-42922
    *                 To update case with the values set 
    *  @PARAM :  
    *  @RETURN:  void
    */ 
    public static void updateCaseFields(Map<Id, Case> idToCaseRecForUpdate){

        if(idToCaseRecForUpdate != null && !idToCaseRecForUpdate.keyset().isEmpty()){
            Update idToCaseRecForUpdate.values();
        }
    }   
       
    /*
     * Description - updateCaseQualifyCompletion method
	 * return - void
     */
    public static void updateCaseQualifyCompletion(Set<Id> setCaseQualifyCompletion){
        Map<Id, SVMXC__Service_Order__c> mapIdsToWOsToUpdate = new Map<Id, SVMXC__Service_Order__c>();
        if(updateCaseQualifyCompletionWorkOrder.isEmpty() || Feature.isOn(CASE_OPTIMIZATION) && !setCaseQualifyCompletion.isEmpty()) {
            updateCaseQualifyCompletionWorkOrder = new WorkOrdersSelector().selectWorkOrderIdOnCase(setCaseQualifyCompletion);
        }
        if(!updateCaseQualifyCompletionWorkOrder.isEmpty()) {

            for(SVMXC__Service_Order__c objWo : updateCaseQualifyCompletionWorkOrder){
                if(objWo.SVMXC__Order_Status__c!=STRING_COMPLETED && objWo.SVMXC__Order_Status__c!=STRING_CLOSED && objWo.SVMXC__Order_Status__c!='Canceled' && objWo.SVMXC__Order_Status__c!=STRING_CASE_STATUS_CLOSED_DUPLICATE){  
                    SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c(id=objWo.Id,Case_Qualifies_Completion_Update__c=System.now());
                    mapIdsToWOsToUpdate.put(objWorkOrder.id, objWorkOrder);
                }
            }
            if(!mapIdsToWOsToUpdate.isEmpty()){
                update mapIdsToWOsToUpdate.values();
            }
        }               
        
    }
        
    /** @DESCRIPTION - DCP -  46141 - make callout to Qualtrics **/
    public static void doCalloutToQualtrics(set<Id> setCaseIds) {
        if ((qualtricsCase.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && setCaseIds != null && !setCaseIds.isEmpty()) {
            qualtricsCase = new CasesSelector().selectCasesByCaseIdSetForQualtrics(setCaseIds);
        }
        if (!qualtricsCase.isEmpty()) {
            for(Case caseObj : qualtricsCase){
                QualtricsAPISurveyLinkReader.initiateQualtricsCallout(caseObj); 
            }   
        } 
    } 


   /*
    *  @AUTHOR        Nishan Shetty [CMCP-22]
    *  @DESCRIPTION - Method is used to send callout to SAP for Work Order Creation for GTS Relocation.
    *  @PARAM :       set<Id> setCaseIds
    *  @RETURN : void
    **/
    public static void sendGTSCaseToSAP(set<Id> setCaseIds) {

        RelocationWODataSender workOrderCreationInterface = new RelocationWODataSender();
        if((sendGTSCase.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && setCaseIds != null && !setCaseIds.isEmpty()) {
            sendGTSCase = new CasesSelector().selectCases(setCaseIds);
        }
        if (!sendGTSCase.isEmpty()) {
            for(Case objCase: sendGTSCase) {
                if(!Test.isRunningTest()){workOrderCreationInterface.callout(objCase.Id);}
            }
        }
    }

                /*
    *  @DESCRIPTION = QACM-5 Create history tracking record
    *  @PARAM :  List<Sobject> -- List of new case records
                 Map<Id, sObject> --  Map of old cases 
    *  @RETURN: void
    *  @AUTHOR - Abhinav Gupta
    *  @DATE - 9th March 2022
    *  Modified - 23rd May 2022 QACM-434
    */
    public static void createHistoryRecord(List<sObject> records, Map<Id, sObject> oldRecords){
        ilib_LogEvent.push(LOG_TITLE + '.createHistoryRecord()');
        try{
            Map<Id, SObject> newRecords = new Map<Id, SObject>();
            for(SObject objCase : records){
                Case newCase = (Case)objCase;
                Case oldCase = (Case)oldRecords.get(newCase.Id);
                if(!string.isBlank(newCase.QA_Reopen_Code_s__c) && newCase.QA_Reopen_Code_s__c!=oldCase.QA_Reopen_Code_s__c){
                    newRecords.put(objCase.Id, objCase);
                }
                    
            }
            UtilsObject.createHistoryTracking(newRecords, oldRecords, CODEPARAMETERACRHISTORYTRACKINGFIELDS);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
        }
        
    }

    //**********************functional methods for after update event ends***************************************
    /**
     * Method Name: validateStatusEditForTPSPUser
     * Description: Restrict the TPSP users in editing the status manually.
     *              //if the logged in user == TPSP user
     *              //status is changed
     *             //bypass validation boolean == false
     * params: trigger.new, trigger.old
     */
    public static void validateStatusEditForTPSPUser(List<sObject> records, Map<Id, sObject> oldRecords){
        ilib_LogEvent.push(LOG_TITLE + '.validateStatusEditForTPSPUser()');
        if(loggedInUserProfileName != null && loggedInUserProfileName == Label.Field_Service_Third_Party && bypassStatusEditValidationForTPSP == FALSE){
            for(case objCase : (List<Case>) records){
                Case objOldCase = null;
                if(oldRecords != null){
                    objOldCase = (Case)oldRecords.get(objCase.id);
                }
                if(objOldCase.Status != objCase.Status){
                    //restrict the TPSP user in editing the status field if it is not a backgorund process that is modifying the status.
                    objCase.addError(STRING_STATUS_EDIT_ERROR_MESSAGE);
                }
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    *  @AUTHOR        Tapas
    *  @DESCRIPTION - Method is used to mark Has_SR_Case_Subject_Code__c field as true so that when code insert by insertSerReqCodeForInstallCases doesn't update case again, thus preventing a case trigger roundtrip
    **/
    private void markHasSRServiceRequestCodeTrue(List<sObject> records){
        if(createInstallServiceRequestCode){
            for(case objCase : (List<Case>) records){
                objCase.Has_SR_Case_Subject_Code__c = true;
            }
        }
    }


    /*
    *  @AUTHOR        Tapas
    *  @DESCRIPTION - Method is used to insert ser request install code on case created when apttus order lines are inserted/lins' qty increased
    **/
    private void insertSerReqCodeForInstallCases(List<sObject> records){
        if(createInstallServiceRequestCode){
            Set<String> setCodeTitles = new Set<String>();
            Code_Library__c objSrvcReqCode = new Code_Library__c();
            List<Associated_Codes__c> lstAssoCodes = new List<Associated_Codes__c>();

            setCodeTitles.add(STRING_SER_REQUEST_CODE);
			CasesHelper.CodeLibraries codeLibrariesQuery = new  CasesHelper.CodeLibraries();
            codeLibrariesQuery.initMapCodeLibraryIdsToRec(setCodeTitles);
            if(mapCodeLibraryIdsToRec == null || mapCodeLibraryIdsToRec.isEmpty())
            {
                return; 
            }
                
            for(Code_Library__c obj : mapCodeLibraryIdsToRec.values()){
                if(obj.Name == STRING_SER_REQUEST_CODE){
                    objSrvcReqCode = obj;
                }
                    
            }
            if(objSrvcReqCode.Id == null){
                return;
            }
                
                
            for(case objCase : (List<Case>) records){
                Associated_Codes__c objAssociatedCode = new Associated_Codes__c();
                objAssociatedCode.Code_Title__c = objSrvcReqCode.Id;
                objAssociatedCode.Case__c = objCase.Id;
                objAssociatedCode.Code_Type__c=objSrvcReqCode.Code_Type__c;
                objAssociatedCode.Case_Type__c=objSrvcReqCode.Case_Type__c;
                lstAssoCodes.add(objAssociatedCode);
            }
            createInstallServiceRequestCode = false;
            if(!lstAssoCodes.isEmpty()){
                insert lstAssoCodes;
            } 
                
        }
    }
    /*
    * Description: Breaking "checkShowOnCaseOnAP" Method to remove NPath Complexity.
    * Author: Chaitanya Karthik  25/7/2023
    *CMCM-196 ------ START -------
    */
    private static set<Id> checkShowOnCaseOnAPHelper(List<Case> records, Map<Id, SObject> oldRecords) {
        set<Id> setCaseIds = new set<Id>(); 
        for(Case objCase : (List<Case>)records) {
            if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE &&  objcase.Sub_Type__c == STRING_CASE_SUBTYPE_COMPLAINT
                && (objCase.Status == STRING_COMPLETED || objCase.Status == STRING_CLOSED || objCase.Status == STRING_PENDING_QA_REVIEW || objCase.Status == Label.CaseStatusPendingLogisticsReview) &&
                objCase.Status != ((Case)oldRecords.get(objCase.Id)).Status) { 
                setCaseIds.add(objCase.Id);
            }
        }
        return setCaseIds;
    }
    //CMCM-196 -------END--------
   
    /*
    *  @AUTHOR        Avina [QACM-8]
    *  @DESCRIPTION - populateQACompletionDate method is used to set "First_QA_Review_Completion_Date__c" and "Last_QA_Review_Completion_Date__c" field value on before update.
    *  @PARAM :       trigger.new,trigger.oldMap
    *  @RETURN :      void
    **/
    public static void populateQACompletionDate(List<SObject> records,Map<Id, SObject> oldRecords){
        ilib_LogEvent.push(LOG_TITLE + '.populateQACompletionDate()');
        Case objOldCase;
        try{
            for(Case objCase: (List<Case>)records){
                objOldCase = (Case)oldRecords.get(objCase.id);
                ilib_LogEvent.message('objOldCase: '+objOldCase);
                if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && (objCase.Status == STRING_CLOSED || objCase.Status == STRING_COMPLETED) && objOldCase.Status == STRING_PENDING_QA_REVIEW ) {
                    if(objCase.First_QA_Review_Completion_Date__c == null){
                        objCase.First_QA_Review_Completion_Date__c = DateTime.now();
                        objCase.Last_QA_Review_Completion_Date__c = DateTime.now();
                    }
                    else{
                        objCase.Last_QA_Review_Completion_Date__c = DateTime.now();
                    }
                }
            }
        }
        Catch(Exception e)
        {
            ApexExceptions.emit('Cases.populateQACompletionDate',e);
        }
        ilib_LogEvent.pop();
    }
    
    /*
    * Description: Modifying "validateProductUtilizationMode" Method to remove NPath Complexity.
    * Author: Chaitanya Karthik  25/7/2023
    *CMCM-196 ------ START -------
    */
    
  public static void validateProductUtilizationMode(List<Case> records,Map<Id, SObject> oldRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.validateProductUtilizationMode()');
        try {
            set<Id> setCaseIds = new set<Id>(); 
            Map<Id, List<Associated_product__c>> mapCaseIdIVDAssociatedProduct = new map<id, List<Associated_product__c>>(); 
            Integer ruoCount = 0;
            Boolean ruoProduct = false;
            setCaseIds =  shouldAddToCaseIdsSetForComplaintCase(records,oldRecords);   
            //Checking for AP
            mapCaseIdIVDAssociatedProduct = validateProductUtilizationModeAPHelper(setCaseIds);
            //Checking for RUO AP
            for(Case objCase : (List<Case>)records) {
                if(!setCaseIds.isEmpty() && setCaseIds.contains(objCase.id)) {
                    ruoCount = calculateIVDCountsAndFlags(mapCaseIdIVDAssociatedProduct,objCase,ruoCount);
                    //Checking for RUO Product
                    ruoProduct = isRUOProduct(mapCaseProductDetails, objCase);
                    //Updating to RUO if all the product are RUO or show error for IVD
                    if(mapCaseIdIVDAssociatedProduct.isEmpty()) {
                        objCase = updateCaseIfRUOProduct(ruoProduct,objCase);
                        if(!ruoProduct) {
                            handleIVDErrors(objCase);
                        }  
                        //QACM-580 included Logged_In_User_Profile__c cond in the check to skip for QA profile
                    }
                    //Updating to RUO if all the product and AP's are RUO or show error for IVD
                    else if(!mapCaseIdIVDAssociatedProduct.isEmpty() && mapCaseIdIVDAssociatedProduct.get(objCase.Id) != null) { 
                        objCase = updateToRUOProductUtilizationModeIfNeeded(mapCaseIdIVDAssociatedProduct,ruoCount,objCase,ruoProduct);
                        handleIVDErrorsForRUOProductUtilizationMode(objCase);        
                    }              
                }
            }
            ruoProduct    = false;
            isIVDAssociatedProd = false;
            ilib_LogEvent.pop();
        } catch(Exception e) {
            ApexExceptions.emit('Cases.validateProductUtilizationMode',e);
        }
    }

   private static set<Id> shouldAddToCaseIdsSetForComplaintCase(List<Case> records,Map<Id, SObject> oldRecords) {
       Set<Id> tempSetCaseIds = new Set<Id>();
       for(Case objCase : (List<Case>)records) {
    if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE &&  objcase.Sub_Type__c == STRING_CASE_SUBTYPE_COMPLAINT) { 
        //QACM-580 included Old Status != PendingQAReview cond in the check
        if(oldRecords!=null && !oldRecords.isEmpty() && objCase.Status != ((Case)oldRecords.get(objCase.Id)).Status && ((Case)oldRecords.get(objCase.Id)).Status != STRING_PENDING_QA_REVIEW && 
        (objCase.Status == STRING_COMPLETED || objCase.Status == STRING_CLOSED || objCase.Status == STRING_PENDING_QA_REVIEW || objCase.Status == Label.CaseStatusPendingLogisticsReview)) {
            tempSetCaseIds.add(objCase.Id);
        }
    } 
   }
    return tempSetCaseIds;
   }

    private static Map<Id, List<Associated_product__c>> validateProductUtilizationModeAPHelper(set<Id> setCaseIds) {
        //Checking for AP
        
        Map<Id, List<Associated_product__c>> mapCaseIdIVDAssociatedProduct = new map<id, List<Associated_product__c>>();
        if(!setCaseIds.isEmpty()) {
            CasesHelper.ValidateIVDAssociatedProducts caseLinesQuery = new  CasesHelper.ValidateIVDAssociatedProducts();
            caseLinesQuery.initMapIVDProductToCases(setCaseIds);
            if(mapIVDAssociatedProductIdToCases != null && !mapIVDAssociatedProductIdToCases.isEmpty()) {
                for(Associated_product__c objAP: mapIVDAssociatedProductIdToCases.values()) {
                    if(!mapCaseIdIVDAssociatedProduct.containsKey(objAP.Case__c)) {
                        mapCaseIdIVDAssociatedProduct.put(objAP.Case__c, new List<Associated_product__c>());
                    }
                    mapCaseIdIVDAssociatedProduct.get(objAP.Case__c).add(objAP);
                }
            }
        }
        return mapCaseIdIVDAssociatedProduct;
    }

    private static Integer calculateIVDCountsAndFlags(Map<Id, List<Associated_product__c>> mapCaseIdIVDAssociatedProduct, Case objCase, Integer ruoCount) {
        Integer tempRuoCount = ruoCount;
        if(!mapCaseIdIVDAssociatedProduct.isEmpty() && mapCaseIdIVDAssociatedProduct.containsKey(objCase.Id) && mapCaseIdIVDAssociatedProduct.get(objCase.Id)!=null && mapCaseIdIVDAssociatedProduct.get(objCase.Id).size() > 0) {
            for(Associated_product__c objIVDAP : mapCaseIdIVDAssociatedProduct.get(objCase.Id)) {
                if(objIVDAP.Product__r.Regulatory_Type__c == STRING_RUO) {
                    tempRuoCount = tempRuoCount +1;
                }
                if(objIVDAP.IVD_Product_Identifier__c == TRUE && isIVDAssociatedProd == FALSE) {
                    isIVDAssociatedProd = TRUE;
                }      
            }
        }
        return tempRuoCount; 
    }

    private static Boolean isRUOProduct(Map<Id, Case> mapCaseProductDetails, Case objCase) {
        return mapCaseProductDetails != null
                && !mapCaseProductDetails.isEmpty()
                && mapCaseProductDetails.get(objCase.Id).SVMXC__Product__r.Regulatory_Type__c == STRING_RUO;
    }

    private static Case updateCaseIfRUOProduct(Boolean ruoProduct,Case objCase){
        Case tempobjCase = objCase;
        if(ruoProduct == true) {
            tempobjCase.Product_Utilization_Mode__c = STRING_RUO;
        }
        return tempobjCase;
    }
    private static void handleIVDErrors(Case objCase){
         if(objCase.Logged_In_User_Profile__c != Label.ProfileQualityAssurance && String.isNotBlank(objCase.SVMXC__Product__c) && objCase.IVD_Product_Identifier__c == true && String.isBlank(objCase.Product_Utilization_Mode__c)) {
            objCase.adderror(STRING_PRD_UTILIZATION_MODE_ERROR_MESSAGE);
            setErrMessages.add(STRING_PRD_UTILIZATION_MODE_ERROR_MESSAGE);
        } 
    }

    private static Case updateToRUOProductUtilizationModeIfNeeded(Map<Id, List<Associated_product__c>> mapCaseIdIVDAssociatedProduct, Integer ruoCount, Case objCase,Boolean ruoProduct){
        Case tempCase = objCase;
        if((ruoCount == mapCaseIdIVDAssociatedProduct.get(objCase.Id).size() || mapCaseIdIVDAssociatedProduct.get(objCase.Id).size() == 0) && ruoProduct == true) {
            tempCase.Product_Utilization_Mode__c = STRING_RUO;
       } 

       return tempCase;
    }

    private static void handleIVDErrorsForRUOProductUtilizationMode(Case objCase){
        if((isIVDAssociatedProd == TRUE || (String.isNotBlank(objCase.SVMXC__Product__c) && objCase.IVD_Product_Identifier__c == true)) && (string.isBlank(objCase.Product_Utilization_Mode__c) && objCase.Logged_In_User_Profile__c != Label.ProfileQualityAssurance)) {
            //QACM-580 included Logged_In_User_Profile__c cond in the check to skip for QA profile
                objCase.adderror(STRING_PRD_UTILIZATION_MODE_ERROR_MESSAGE);
                setErrMessages.add(STRING_PRD_UTILIZATION_MODE_ERROR_MESSAGE);
        }  
    }

    //CMCM-196 ------END-----
    
    /**
    *  @Author Gladis 
    *  @Description - QACM-14/QACM-672 To validate and throw error when there are no QualityJuncRecords populated upon Case closure on Before Update. 
    *  @Param      : trigger.new,trigger.oldMap
    *  @Return     : void             
    **/
    public void validateNullQualityJuncRecords(List<SObject> records,Map<Id, SObject> oldRecords){

        ilib_LogEvent.push(LOG_TITLE + '.validateNullQualityJuncRecords()');
        Set<String> setCaseCompleteStatus = new Set<String>{STRING_COMPLETED, Label.CaseStatusClosed , Label.CaseStatusClosedDuplicate};
        Set<Id> setCaseIds = new Set<Id>();
        Map<Id, Case> mapCaseRec = new Map<Id, Case>();
        try {
            for(Case objCase : (List<Case>)records) {
                Case objOldCase = (Case)(oldRecords.get(objCase.Id));
                mapCaseRec.put(objCase.Id, objCase);
                if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE 
                   && objCase.Status != objOldCase.Status 
                   && setCaseCompleteStatus.contains(objCase.Status)
                   && (objCase.QA_Review__c == QA_REVIEW_REFER_EXISTING_OR_PRIOR_INVESTIGATION || objCase.QA_Review__c == QA_REVIEW_FURTHER_INVESTIGATION_REQUIRED)) {
                        setCaseIds.add(objCase.id);   
                }
            }
        if((caseWithNOQualityList.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && setCaseIds != null && !setCaseIds.isEmpty()) {
            caseWithNOQualityList = new CasesSelector().selectCasesWithNoQualityJunctionRecords(setCaseIds);
        }
        if(!caseWithNOQualityList.isEmpty()){//INC0433452
            for(Case objCaseRecord: caseWithNOQualityList) {
                if(objCaseRecord.Quality_Record_Junctions__r.size() == 0) {
                    Case actualRecord = mapCaseRec.get(objCaseRecord.Id);
                    actualRecord.addError(Label.NoQualityRecordLinks);
                }
            }
        }    
            
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
    }

         /*
    * Description: Update Is_Reopen_Approved__c to TRUE on WO whenever Is_Reopen_Approved__c on Case is set to TRUE.
    * Author: Nancy Al Kalach
    */
    public static void setIsReopenApproved(List<Case> records,Map<Id, SObject> oldRecords) {

        List<SVMXC__Service_Order__c> lstWOsToUpdate = new List<SVMXC__Service_Order__c>();
        Set<Id> filteredCaseIds = new Set<Id>();
        for (Case objCase : records) {
            Case objOldRec=oldRecords!=null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null;
            if(objOldRec.Is_Reopen_Approved__c != objCase.Is_Reopen_Approved__c && objCase.Is_Reopen_Approved__c == true){
                filteredCaseIds.add(objCase.Id);
            }
        }
        // Added ( && filteredCaseIds != null) condition for CMCM -10026
        if(lstWOsToUpdate.isEmpty() && filteredCaseIds != null && !filteredCaseIds.isEmpty()) {
            lstWOsToUpdate = new WorkOrdersSelector().selectWorkOrderIdOnCase(filteredCaseIds);
        }
        if (!lstWOsToUpdate.isEmpty()) { 
            for (SVMXC__Service_Order__c wo : lstWOsToUpdate) {
                wo.Is_Reopen_Approved__c = true;
            }
            try {
                WorkOrders.skipWOTrigger = true;
                WorkOrders.isPrimaryAPUpdate = false;
                WorkOrders.isReopenApproved = true;    

                update lstWOsToUpdate;
            } catch (DmlException e) {
                ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE + e.getMessage()); 
            }
        }
    }
     /* 
    * @AUTHOR       : Preetha [QACM-782]
    *  @DESCRIPTION  : Chatter Post on Product Utilization mode change
    *  @PARAM        : trigger.new,trigger.oldMap
    *  @RETURN       : void
    */
    public static void chatterPostNotification(List<Case> records,Map<Id, SObject> oldRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.chatterPostNotification()');
        try {
            for(Case objCase : (List<Case>)records) {
                if(objCase.Logged_In_User_Profile__c == Label.ProfileQualityAssurance) {
                    if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && objCase.Status == STRING_PENDING_QA_REVIEW) {
                        if(oldRecords!=null && !oldRecords.isEmpty() && objCase.Product_Utilization_Mode__c != null && objCase.Product_Utilization_Mode__c != ((Case)oldRecords.get(objCase.Id)).Product_Utilization_Mode__c) {
                            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
                            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                            // add the mention
                            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                            mentionSegment.id = objCase.OwnerId;
                            messageInput.messageSegments.add(mentionSegment);

                            // add the text that was passed
                            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                            textSegment.text = ' the Product Utilization Mode has been updated to '+objCase.Product_Utilization_Mode__c+' by the QA team. No further action required.';
                            messageInput.messageSegments.add(textSegment);

                            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
                            input.body = messageInput;
                            input.subjectId = objCase.id;
                            input.visibility = ConnectApi.FeedItemVisibilityType.AllUsers; 

                            // post it
                            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);                    
                        }
                    }
                }
            }
            ilib_LogEvent.pop();
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
    }

     
    
     /**
     * @description 
     * @author :Get all case Ids based on sertain conditions
     * @param setcaseIdForVeevaCallout 
     * @param objCase 
     * @param objOldCase 
     * @return Set<Id> 
     **/
    
     public void fetchCaseIdsForVeevaCallout(Set<Id> setcaseIdForVeevaCallout,Case objCase,Case objOldCase){

        if(objCase.Veeva_Integration_Status__c!= objOldCase.Veeva_Integration_Status__c && objCase.Veeva_Integration_Status__c==CASE_CREATION_INITIATED )
        {
            setcaseIdForVeevaCallout.add(objCase.Id);
        }
    }
     /**
     * @description :async call for sending case details to veeva :DCP-51201
     * @author : Sagar
     * @param setcaseIdForVeevaCallout 
     * @param queueableThread 
     **/
    public static void asyncCallForCalloutToVeeva(Set<Id> setcaseIdForVeevaCallout, ilib_Queueablethread queueableThread){
        if(!setcaseIdForVeevaCallout.isEmpty()){
            queueableThread.logandQueue(new CaseQueueable('sendCaseDetailsToVeeva', setcaseIdForVeevaCallout, null, null, null),STRING_CASE_QUEUEABLE,'sendCaseDetailsToVeeva');     
        }
    }
     
    /**
    * @description :Send case information to Medical Affairs: DCP-51201
    * @author :Sagar
    * @param setCaseIds 
    **/
    public static void sendCaseDetailsToVeeva(set<Id> setCaseIds) {
        if(setCaseIds!=null && !setCaseIds.IsEmpty()) {
            for(Id caseId:setCaseIds) {
                if(!Test.isRunningTest()){
                    new VeevaCreateCaseDataSender().callout(caseId);
                }
                    
            }
        }

    }

    /**
    * @description DCP-56388
    * @author Rohan Rathod | 20-12-2022 
    * @param records 
    * @param oldRecords 
    **/
    public static void checkSubTypeEditForOpenElevation(List<Case> records,Map<Id, SObject> oldRecords){
        try {        
            Map<Id,Case> mapCaseId = new Map<Id,Case>();         
            ilib_LogEvent.push(LOG_TITLE + '.checkSubTypeEditForOpenElevation()');
            for(Case objCase : (List<Case>)records){
                if(objCase.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && ((Case)oldRecords.get(objCase.Id)).Sub_Type__c == STRING_CASE_SUBTYPE_COMPLAINT
                    && objCase.Sub_Type__c == 'General Issue' && objCase.Sub_Type__c != ((Case)oldRecords.get(objCase.Id)).Sub_Type__c){ 
                    mapCaseId.put(objCase.Id,objCase);
                }
            }
            if((elevatedWOList.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) && mapCaseId.keySet() != null && !mapCaseId.keySet().isEmpty()) {
                elevatedWOList = new WorkOrdersSelector().selectElevatedWorkOrders(mapCaseId.keySet());
            }
            //Get the Elevated Workorder data
            if(!elevatedWOList.isEmpty()) {
                for(SVMXC__Service_Order__c objWorkOrder: elevatedWOList){
                    Case actualRecord = mapCaseId.get(objWorkOrder.SVMXC__Case__c);
                    actualRecord.adderror(Label.Elevated_Business_Issue_Error) ;                                      
                }
            }            
            ilib_LogEvent.pop();
        }
        catch(Exception e){            
            ApexExceptions.emit('Cases.checkSubTypeEditForOpenElevation',e);
        }
    }

	/**
    * @description : Method to fetch Sobject Records : POL-51
    * @param records 
    * @param oldRecords 
    **/
    public static void queryRecordsforExecution(List<Sobject> records, Map<Id, SObject> oldRecords) {
         
        Set<Id> setAccountIds =  new Set<Id>();
        for(Case objCase : (List<Case>)records){
            Case objOldCase=oldRecords!=null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null; 
            if(objOldCase!=null && objOldCase.status != objCase.status && (objCase.Status == System.label.CaseStatusReopened || (objOldCase.Status == System.label.CaseStatusReopenRequested && objCase.Status == System.label.CaseStatusInProgress)) && objCase.AccountId !=null && objCase.Region__c!=null)
            {
                setAccountIds.add(objCase.AccountId);
            }
        }
        if(!setAccountIds.isEmpty()){
            CasesHelper.Accounts accountQuery = new  CasesHelper.Accounts();		
            accountQuery.initMapAccountIdToAccount(setAccountIds);
        }
           
    }
    /**
    * @description Method to update Contains_Logistics_Analysis_Code__c Fields | CMCM-3533
    * @author Abhishek Yadav | 22-Sept-2023 
    * @param records
    **/
    public static void updateAnaysisCode(List<Sobject> records) {
        for(Case objCase : (List<Case>)records) {
            if(objCase.Sub_Type__c == Label.CaseSubTypeGeneralIssue && objCase.Category__c == Label.CaseCategoryLogistics) {
                objCase.Contains_Logistics_Analysis_Code__c = true;
            } else {
                objCase.Contains_Logistics_Analysis_Code__c = false;
            }
        }
    }
      
}
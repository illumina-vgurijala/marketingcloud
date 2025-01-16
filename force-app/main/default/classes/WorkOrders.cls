/***************************************************************************************************************************************
    * NAME   : WorkOrders
    * DESCRIPTION  : Domain class for WorkOrderTrigger.
    *    @Test Class for above 90% coverage.
    *    @Test Class for atleast 75% coverage.
         -TestWorkOrderQueueable
         -TestWorkOrderSelector
         -TestWorkOrderStatusChangeReason
         -TestWorkOrdersCustomerAbandonedService
         -TestWorkOrdersService      
    * @AUTHOR : Ritika Maheshwari
    * @DATE   : 20-May-2018  
    * 
    * MODIFICATION LOG: 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Ritika               20-May-2018          Initial Version. Added logic for DCP-326 to handle WO status change on case.
    * Debalina             04-June-2018         DCP-803 Send Email for Cancelled WO.
    * Veerendra            06-June-2018         DCP-817 Create Entitlement records when Work Order is created.
    * Sandeep Ram Ch.      11-June-2018         DCP-1050 Update technician based on loggedc in user
    * Debalina             14-June-2018         802/803 Code review Changes Account_to_Field_Support__c from Account_Technician_Role__c
    * Sandeep Ram Ch.      15-June-2018         DCP-1050 changed the query in the updateFieldSupportUser method
    * Debalina             21-June-2018         Bug DCP-5010 Send Email for Cancelled WO.
    * Veerendra            25-June-2018         DCP-824 Prevent from creating Work Order if Remote Support is not covered
    * Sandeep Ram Ch.      4-July-2018          DCP-575 set Email of primary FSA and FSE in cc email field
    * Shashank Singhal     7-July-2018          DCP-6315 set Order Status on Case for reparenting
    * Vaibhav Parashar     27-July-2018         DCP-8444 Work Order Synchronization from ServiceMax to SAP (NEW).
    * Shashank Singhal     24-Aug-2018          DCP-843 Check LOA document on Install Work Order Completion
    * Shashank Singhal     27-Aug-2018          DCP-10944 Create Related Product on Creation of Install WO
    * Soumya Ranjan Sahu   10-Sept-2018         DCP-11867 Added under onAfterUpdate sendEmailWhenLOASigned() method to send email when LOA is sigend.
    * Vignesh S            24-Sept-2019         DCP-28403 Triggering Email Notifications for Installtion Work Orders.
    * KD                   16-March-2021        DCP-43163 Update POL on IP update
    * Vignesh S            20-Jun-2021          DCP-46053 - Updated Logic to populate Product Lot NUmber/Product Serial Number field 
    * Gladis               05-May-2021          DCP-46837 To prefix "Abandoned" to Work Order subject when Abandoned Reason is selected from SFM
    * KD                   17-May-2021          DCP-45928: Create Estimate line on Estimate WO.
    * Adyasha              19-May-2021          DCP-46318: Service Permissions for Inititating Automated Quoting 
    * Deepika              17-May-2021          DCP-38815 Customer Abandoned Part 2 changes
    * Akshay Mohan         24-May-2021          DCP-39386: Remove extra loop
    * KD                   1-June-2021          DCP-38933 : By pass for SNAP integration user
    * KD                   4-June-2021          DCP-39952 :Send WO to SAP on Schedule date Time update
    * Adyasha Satapathy    07-Jun-2021          DCP-46317: Scheduled Date Time Update for Techncian Onsite WO Status
    * KD                   7-June-2021          DCP-45874 : Removed logic to update Owner as Estimate Queue for Estimate record type.
    * Gautam Arya          14-Jun-2021          DCP-39881 : Added logic to Verify DCIR form
    * Adyasha              04-Jun-2021          DCP-38810: Call method to prompt requoting only if work order is being set to complete
    * Gladis               26-June-2021         DCP-45743 To check validation on Before Update when record type is changed to Estimates
    * KD                   21-June-2021         DCP-45490 : CP Relocation WO should not be billable.
    * Adyasha              24-Jun-2021          DCP-45746 : Updated logic for creating CS Review Activity 
    * Akshay Mohan         28-June-2021         DCP-45793: Once PO Number is set Create Parts Order
    * Gladis               24-June-2021         DCP-38816 : Billable Work Order Customer Abandoned - Opportunity Updates
    * Nishan Shetty        9-Aug-2021           CMCP-23 : Added logic to identify work order as partner work order.    
    * Rishi Sharma         19-Aug-2021          DCP-47271 : Created method updateWOonCaseAfterUpdate to update Work Order on the case record related to the work order and added logic in updateCases method after insert.
    * Rishi                31-Aug-2021          DCP-49487 : PM Work Orders to not create Customer Care Reviews
    * Rucha Dalvi          26-Aug-2021          DCP-46273 : Created method populateConfirmOperabilityForRelatedWO, reCalculateConfirmOperabilityWO to populate confirmed operability 
                                                for Work Orders having Related WO to Confirm Operability of Relocation order type.    
    * Gladis               01-Sep-2021          CMCP-16 : Added method checkPartsOrderStatusChange to throw error if no shipment PartsOrders found and to capture the TimeInState
    * Gladis               02-Sep-2021          CMCP-16 : method to capture Time-in/Time-out of AwaitingParts status   
    * Shivani              08-Sep-2021          DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
    * Vignesh              16-Sep-2021          DCP-49744: Method to updated Installed Product Hiereachy for Materials Consumed.
    * Nishan Shetty        22-Sept-2021         CMCP-64 : Update Request Ownership Status to Completed. 
    * Pooja Shalwadi       17-Sept-2021         DCP-49916:Update Training required and Reason for no Training based on criteria
    * Shivani Jain         29-Nov-2021          DCP-42926 : Parts Order Lines Optimization
    * Pooja Shalwadi       06-Dec-2021          DCP-49644: POC Story: To display the values in document upload Tab and update Product family and Repair Protocol
    * Shivani Jain         08-Mar-2022          DCP-49679 : update Elevation Description
    * Rohan Rathod          23-Mar-2022         DCP-49682 : Remove Elevation 1.0 code
    * Nishan Shetty        25-Aug-2022          DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
    * Romi Taskar          31-Aug-2022          DCP-52923 - Changing the List of Location to Map of Location for simpler approach
    * Shivani Jain         15-Dec-2022          DCP-52634 - Populate Ssubscription fields
    * Nancy                08-Aug-2023          CMCM-507 - Optimised Onsite Response Date Calculation
    * Dhairya              13-03-2024           CMCM-9
    * Arquimidez Mora      12-Aug-2024          CMCM-9644 - Delete Order Line Items related
    * Nancy                26-Sep-2024          CMCM-10494 - Work Order Trigger Long Term Optimization - Part 2
    ****************************************************************************************************************************************/ 
    public with sharing class WorkOrders extends ilib_SObjectDomain {
        public static final String LOG_TITLE = 'WorkOrders';

        public static Boolean hasRunTaps = false;
        public static Boolean hasupdaterun = false;
        public static Boolean notificationSent = false;
        public static final String STRING_WORK_ORDER_STATUS_AWAITING_PARTS = 'Awaiting Parts'; //CMCP-16
        public static final String STRING_WORK_ORDER_STATUS_NOTAPPLICABLE = 'Not Applicable';
        public static final String STRING_WORK_ORDER_STATUS_INPROGRESS = 'In Progress';
        public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
        public static final String STRING_WORK_ORDER_STATUS_CLOSED = 'Closed';
        public static final String STRING_WORK_ORDER_STATUS_CANCELLED = 'Canceled';
        public static final String STRING_WORK_ORDER_STATUS_INITIATED = 'Initiated';
        public static final String STRING_WORK_ORDER_STATUS_SCHEDULED = 'Scheduled';
        public static final Set<String> SET_FSE_ROLES = new Set<String>{'Partner Primary Field Service Engineer','Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer','Primary Field Application Scientist','Field Service Manager', 'Secondary Field Application Scientist'};
        public static final String STRING_WORK_ORDER_STATUS_ASSIGNED = 'Assigned';
        public static final String STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED = 'Assignment Accepted';
        public static final String STRING_LABEL_PRIMARY_FSE = 'Primary Field Service Engineer';
        public static final String STRING_LABEL_PARTNER_PRIMARY_FSE = 'Partner Primary Field Service Engineer';
        public static final String STRING_LABEL_PARTNER_PRIMARY_FAS='Partner Primary Field Application Scientist';
        public static final String STRING_WORK_DETAIL_LINE_STATUS_CANCELED = 'Canceled'; //DCP-37747
        public static final String STRING_LABEL_SECONDARY_FSE = 'Secondary Field Service Engineer';
        public static final String STRING_LABEL_FSM = 'Field Service Manager';
        public static final string STRING_LABEL_PLANNED_MAINTENANCE = 'Planned Maintenance';    
        public static final string STRING_LABEL_BILLABLE = 'Billable';      
        public static final String STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT = 'Remote Support';
        public static final String STRING_SERVICE_CONTRACT_STATUS_ACTIVE = 'Active';
        public static final String STRING_CASE_RECORD_TYPE_BUSINESS_ISSUE = 'Business Issue';
        public static final String ERP_SUBMITTED_NOT_REQUESTED = 'Not Requested';
        public static final String ORDER_TYPE_RETURN = 'Return';
        public static final String ORDER_STATUS_ON_HOLD = 'On Hold';
        public static final String ORDER_STATUS_REQUESTED = 'Requested';
        public static final String STRING_EMAIL_PROACTIVE_TS = 'Email - ProActive - TS';
        public static final String STRING_COMPANY = 'SVMXC__Company__c';
        public static final String STRING_LABEL_SECONDARY_FAS = 'Secondary Field Application Scientist';    //DCP-46318
        public static final String STRING_WO_STATUS_TECHNICIAN_ONSITE = 'Technician Onsite'; //DCP-46317
        public static final String STRING_WORK_ORDER_DCIR_STATUS_OPEN = 'Open';
        public static final String STRING_WORK_ORDER_DCIR_STATUS_COMPLETED = 'Completed';
        public static final String STRING_OBJ_ACCOUNT_FIELD_SUPPORT_USER_ROLE = 'objAccToFieldSupport.User_Role__c';
		public static final Integer INTEGER_15 = 15;
		public static final String STRING_INSTALLED_WORK_ORDER = 'Installed_Work_order';
		public static final String STRING_PARTNER = 'Partner';
		public static final String STRING_UPDATE_IS_BILLING_ON_WD_BY_CS = 'updateIsBillaleOnWdByCS';
		public static final String STRING_AUTO_CLOSURE_OF_WO = 'autoClosureOfWorkOrders';
		public static final String STRING_AUTOMATED_PROCESS = 'Automated Process';
		public static final String STRING_OPEN_WO = 'OpenWO';
        public static final String STRING_WORK_ORDER_RTYPE_ESTIMATES = 'Estimates';
        public static final String STRING_WORK_ORDER_API_NAME = 'SVMXC__Service_Order__c';
        public static final String STRING_WORKORDER_API_NAME = 'Work_Order__c';
        public static final String STRING_SERVICE_CONTRACT_FIELD_API_NAME = 'Service_Contract__c';
        public static final String STRING_INSTALLED_PRODUCT_FIELD_API_NAME = 'SVMXC__Component__c';
        public static final String STRING_LOCATION_FIELD_API_NAME = 'SVMXC__Site__c';
        public static final String STRING_LABEL_PRIMARY_FAS='Primary Field Application Scientist';
        public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS = 'Parts';
        public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR = System.Label.Labor;
        public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tools';
        public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED = 'Material Consumed';
        public static final String STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION = System.Label.Work_Detail_Record_Type_Usage_Consumption;
        public static final string STRING_WOD_ACTIVITY_TYPE_IQ_OQ = 'IQ/OQ';
        public static final string STRING_WOD_ACTIVITY_TYPE_PQ = 'PQ';
        public static final String STRING_PARTS_ORDER_LINE_CONSUMABLE = 'Consumable';
        public static final String STRING_WD_NON_BILLABLE_REASON_CONSUMABLE = 'Consumable Warranty';
        public static final String STRING_USER_TYPE = 'PowerPartner';
        public static final String STRING_SNAP_INTEGRATION_USER = 'Integration';
        public static final String STRING_SYSTEM_ADMINISTRATOR = System.Label.ProfileSystemadmin;
        public static final String STRING_WORK_ORDER_RTYPE_FIELD_SERVICE = 'Field Service';
        public static final string STRING_LABEL_SERVICE_ACTIVITIES = 'Service Activities'; 
        public static final String STRING_WORK_ORDER_ORDER_TYPE_RELOCATION = 'Relocation';
        public static final String STRING_WD_ACTIVITY_FIELD_COMPLIANCE_REVIEW = System.Label.WorkDetailActivityFieldComplianceReview;
        public static final String STRING_WD_ACTIVITY_CUSTOMER_SERVICE_REVIEW = System.Label.WorkDetailActivityCustomerServiceReview;
        public static final String STRING_WD_ACTIVITY_QUALIFICATION_SERVICE_REVIEW = 'Qualification Service Review';
		public static final String STRING_WORK_ORDER_INTEGRATION_STATUS = 'Success'; // DCP-33467
        public static boolean stopIntegrationOnCostCenterChange = false;//DCP-42762
        public static final String STRING_HEALTH_CHECK_ACTIVITY_TYPE = 'System Health Check';//DCP-45746
        public static final String CHANNEL_PARTNER_SERVICE_PROFILE = 'Channel Partner Service';
        public static final String CHANNEL_PARTNER_SALES_SERVICE_PROFILE = 'Channel Partner Sales and Service';
        public static final String STRING_SNAP_SERVICE_INTEGRATION_USER = 'SNAP Service Integration';
        //DCP-28201
        public static final string STRING_WOD_ACTIVITY_TYPE_OQ = 'OQ';
        public static final string STRING_WO_ORDER_TYPE_PM = 'Preventative Maintenance';
        
        public static Map<Id, String> mapWorkOrderIdRejectionStatus = new Map<Id,String>();
        public static Boolean boolRerunWorkOrderTrigger = true;
        public static Boolean boolrerun = true;
        //DCP-8444 Work Order Synchronization from ServiceMax to SAP (NEW).
        public static integer stopRecurssivefutureCallout = 0; // counter to stop firing createWorkOrder callout twice.
        public static final String STRING_WORK_ORDER_STATUS_OPEN = System.Label.WorkDetailLineStatusOpen;
    
        //DCP-843 set of Acceptance codes
        public static set<string> setAcceptanceCode = new set<string>{'ACD: Acceptance Upon Delivery', 'ACI: Acceptance Upon Installation', 'ACP: Acceptance Upon Performance'};
        public static final string STRING_LABEL_INSTALLATION = 'Installation';
        //DCP-10944
        public static final string STRING_WORK_DETAIL_RECORDTYPE_NAME = 'Related Products';   
        public static final String STRING_ATTACHMENT_NAME = 'Letter_of_Acceptance';
        public static final String STRING_SIGNATURE_TYPE_WET_SIGN = 'Mobile Sign';
        public static final String STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE = 'Closed-Duplicate'; //DCP-16165
        public static final set<string> SET_WORK_ORDER_PRE_COMPLETION_STATUS = new set<string>{STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_STATUS_ASSIGNED , STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED, 'Scheduled', STRING_WORK_ORDER_STATUS_INPROGRESS, 'Technician Onsite'}; //DCP-16165
        public static final String STRING_CASE_BUSINESS_ISSUE_RECORD_TYPE = 'Business Issue';
        public static final String STRING_WORK_ORDER_INTEGRATION_STATUS_NOT_REQUIRED = 'Not Required'; //[DCP-37765]

        //DCP-17063
        public static final Id RELATED_PRODUCT_WORK_DETAIL_RECORDTYPE = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Related Products').getRecordTypeId();
        //DCP-24618
        public static final string STRING_WORK_ORDER_FIELD_STOCK_RECORDTYPE_NAME = 'Field Stock Management';
        //Refactor PB :: Work_Order_Assignment_for_Quote_Creation
        public static final string STRING_WORK_ORDER_ACCOUNT_REGION_AMR = 'AMR';
        // POL-18 AC9 keywords replaced from EMEA to EUR  
        public static final string STRING_WORK_ORDER_ACCOUNT_REGION_EUR = 'EUR'; 
        // POL-18 AC9 keywords replaced from APJ to AMEA
        public static final string STRING_WORK_ORDER_ACCOUNT_REGION_AMEA = 'AMEA'; 
        public static final string STRING_WORK_ORDER_ACCOUNT_REGION_CHINA = 'China';
        //DCP-25229
        public static final String STRING_WO_ORDER_STATUS_CLOSED_DUPP = 'Closed-Duplicate';
        public static final String STRING_WO_CONTACT_PREFERRED_LANGUAGE_ENGLISH ='English';
        //DCP-39750
        public static final String STRING_ACCOUNT_ACCOUNTGROUP_SOLDTO = 'Sold To';
        public static final String STRING_ACCOUNT_ACCOUNTGROUP_ULTIMATECONSIGNEE='Ultimate Consignee';
        public static boolean stopRecurssiveUpdateSoldToOnWO =false;
        public static final String METHOD_UPDATE_SOLD_TO_ON_WO ='updateSoldToOnWO';
        public static final String WORKORDER_QUEUEABLE = 'WorkOrderQueueable';
        public static final String WORKORDER_QUEUEABLE_NON_SHARING = 'WorkOrderQueueableNonSharing';
        public static final String STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED='Customer Owned';
        //public static final String STRING_BILLING_TYPE_EDIT_ERROR_MSG='Only Customer Service User can Update Billing Type field.';
        //POL-18 AC9 keywords replaced from APJ to AMEA and EMEA to EUR
        public static final set<string> SETQUEUENAMES = new Set<string>{'AMR_Work_Order_Estimates',
            'EUR_Work_Order_Estimates',
            'AMEA_Work_Order_Estimates',
            'GC_Work_Order_Estimates'};
        public static boolean hasactivityRuleran=false;
        Channel_Partner_Profile_Settings__c channelPartner = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileId());
        public static List<Case> lstCaserecords=new List<Case>();
        public static List<SVMXC__Installed_Product__c> lstInstalledProductrecords=new List<SVMXC__Installed_Product__c>();
        public static List<SVMXC__PM_Plan__c> lstpmplans=new List<SVMXC__PM_Plan__c>();
        public static List<User> lstUserRecords=new List<User>();
        public static List<SVMXC__Service_Group_Members__c> lstServiceGroupMembers=new List<SVMXC__Service_Group_Members__c>();
        public static List<SVMXC__Service_Order__c> lstWorkOrdersforanIP=new  List<SVMXC__Service_Order__c>();
        public static Map<Id,SVMXC__Site__c> mapLocationrecords = new Map<Id,SVMXC__Site__c>(); //DCP-52923 changed from List to Map
        public static List<SVMXC__Site__c> lstLocationrecordsbyCountries;
        public static Map<Id,Map<String,Account_to_Field_Support__c>> mapaccountIdToPFSERoles =new Map<Id,Map<String,Account_to_Field_Support__c>>();
        public static List<Account> lstAccountRecords=new List<Account>();
        public static List<AccountContactRelation> lstAccountContactRelRecords=new List<AccountContactRelation>();
        public static List<Contact> lstContactRecords=new List<Contact>();
        public static List<SVMXC__Service_Contract_Sites__c> lstCoveredLocations = new List<SVMXC__Service_Contract_Sites__c>();//initialize this as well
        public static Map<String,Profile> profileNameToProfile;
        public static List<SVMXC__RMA_Shipment_Order__c> lstpartsOrders=new List<SVMXC__RMA_Shipment_Order__c>();
        public static List<SVMXC__RMA_Shipment_Line__c> lstpartsOrderslines=new List<SVMXC__RMA_Shipment_Line__c>();
        public static List<SVMXC__Service_Order_Line__c> lstworkDetails=new List<SVMXC__Service_Order_Line__c>();
        public static List<ContentVersion> lstContentVersions=new List<ContentVersion>();
        public static List<ContentDocumentLink> lstContentDocLinks=new List<ContentDocumentLink>();
        public static List<Work_Order_Activity_Rules__c> lstWOActivityRules=new List<Work_Order_Activity_Rules__c>();
        public static List<Product2> lstProducts=new List<Product2>();
        public static List<Associated_Codes__c> lstAssociatedCodes=new List<Associated_Codes__c>();
        public static List<SVMXC__Service_Order__c> lstWorkOrders=new  List<SVMXC__Service_Order__c>();
        public static Set<Id> setStandAloneWOId=new Set<Id>(); //INC0417839
        
        public List<SVMXC__Work_Order_Resource__c>  lstWOResource=new List<SVMXC__Work_Order_Resource__c>();
        public List<SVMXC__PM_Schedule_Definition__c> listPMSchDef=new List<SVMXC__PM_Schedule_Definition__c>();
        public List<SVMXC__PM_Schedule__c> lstPMSchedule=new List<SVMXC__PM_Schedule__c>();
        public static List<SVMXC__Service_Order__c> lstChildWorkOrders = new List<SVMXC__Service_Order__c>(); //DCP-46273
        public static Set<Id> setChildWorkOrderIds = new Set<Id>(); //DCP-46273
        
        public List<SVMXC__Service_Order__c> lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber = new List<SVMXC__Service_Order__c>();

        public static Map<Id, SVMXC__Service_Contract__c> mapOfSubscription = new Map<Id, SVMXC__Service_Contract__c>(); // DCP-52634
        public static Map<String,Id> productCodeBYProductIdMap = new Map<String,Id>(); //DCP-52634
        //DCP-47459 
        public static final Integer INTEGER_ONE_MONTH = 30;
        public static final Integer INTEGER_ONE_YEAR = 365;
        public static final Integer INTEGER_ONE_LEAP_YEAR = 366;
        public static Date startDate;
        public static Date endDate;
        public static Date lastPMDate;

	    //DCP-45000
        public static Map<Id,Id> mapCaseIdToWOOwner= new Map<Id,Id>();
        public static Map<Id,String> mapCaseIdToCaseStatus= new Map<Id,String>();

        //DCP-49916 start
        public static final String NON_INSTALL_WO = 'Non-Install WO, not required';
        //DCP-49916 End

        //CMCM-5782
        public static final String ASSOCIATED_PRODUCT_FEATURE_FLAG = 'ServiceAssociatedProducts';

        //START CMCP-64
        public static final String STRING_REQUESTED ='Requested';
        public static final String STRING_COMPLETED ='Completed';
        //END CMCP-64

        //Maps/list to be used on insert/update in After Events
        public static Map<Id,case> mapCaseIdtoCaseObj=new Map<Id,Case>();
        public static Map<Id,SVMXC__Installed_Product__c> mapIPIdtoIPObj=new Map<Id,SVMXC__Installed_Product__c>();
        public static Map<Id,SVMXC__Service_Order_Line__c> mapWDIdtoWDObj=new Map<Id,SVMXC__Service_Order_Line__c>();
        public static List<SVMXC__Service_Order_Line__c> lstworkDetailsToInsert=new List<SVMXC__Service_Order_Line__c>();
        //public static final String SnapSalesIntegrationUserId = System.label.SNAPSalesIntegration;

        //Maps/list to be used on delete in before Events 
        public static List<Case> lstCaseToUpdate = new List<Case>(); 
        public static Map<id,case> idTocaseDeleteUpdate = new Map<id,case>();
        public static  Boolean  hasDMLonafterupdateran=false;
        public List<SVMXC__Service_Order_Line__c> lstWDsForCompletionWOs = new List<SVMXC__Service_Order_Line__c>();//DCP-43634
        public static List<SVMXC__Service_Order__c> updatedWOList = new List<SVMXC__Service_Order__c>(); //DCP-49679
        public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';//DCP-43634
        public static final String WD_APPROVALSTATUS_REJECTED = 'Rejected';

        private static Id idEstimatesRecordTypeId = ServiceUtilityCollection.getRecordTypeId(STRING_WORK_ORDER_API_NAME, STRING_WORK_ORDER_RTYPE_ESTIMATES);
        //DCP-45743
        private static Id idRemoteSupportRecordType = ServiceUtilityCollection.getRecordTypeId(STRING_WORK_ORDER_API_NAME, STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT);
        private static Id idFieldServiceRecordType = ServiceUtilityCollection.getRecordTypeId(STRING_WORK_ORDER_API_NAME, STRING_WORK_ORDER_RTYPE_FIELD_SERVICE);
        public static final String STRING_005 = '005';
        
		public static Boolean isCaseUpdated=false;
		public static Boolean isIPorProdUpdated =false;

        //DCP-45793
        public static Set<Id> setWOIdForAutoPOCreation = new Set<Id>();
        public static final String INSERT_WO_RESOURCE_RECORD = 'insertWOResourceRecord';
        
		//DCP-54492
		public static Set<Id> setWOForCaseOwnerSync = new Set<Id>();
		 
        //START CMCP-23 
        public static final String METHOD_UPDATE_PARTNER_WO_FLAG_FOR_VAD_ACCOUNT='updatePartnerWOFlagForVADAccount';
        public static boolean stopRecursiveUpdatePartnerWOFlagForVADAccount =false;
        //END CMCP-23

        //START DCP-47686
        public static final String STRING_OQ_REQUIRED='OQ Required';
        public static final String SEMICOLON=';';
        public static final String STRING_REQUIRED='Required';
        //END DCP-47686

        public static final set<string> SET_WORK_ORDER_COMPLETION_STATUS = new set<string>{ 'Completed','Closed' };//DCP-49744
        //POC: DCP-49644
        public static final String STRING_RP_NOT_APPLICABLE= 'Not applicable for this instrument';

        public static boolean skipWOTrigger = false;
        public static boolean isPrimaryAPUpdate = false;
        public static boolean isReopenApproved = false;
        public static boolean isWOUpdatefromCase = false; // INC0555781 - WOTrigger-RecursionCheckAddOnCaseUpdate
        public static boolean isWDUpserted = false; //CMCM-10494
        public static boolean isPartsOrderStatusUpdate = false; // CMCM-11598
        //PRB0050214 Added for Contract Sync issue fix
        public static Boolean isPMWOCancelled = false;
        //Added for CMCM-12852 soql 101 fix
        public static Boolean isWOUpdateFromEquipmentSync = false;

        //CMCM-5307 - Start
        public static List<Case> lstCases = new List<Case>();
        public static List<Product2> productsList = new List<Product2>();
        public static Map<Id,SVMXC__Service_Order__c> mapChildWorkOrders = new Map<Id,SVMXC__Service_Order__c>();
        //CMCM-5307 - End

        /*constructor. call to super class constructor
         */
         /*CMCM-9 -Start-> create public set of Account Id variable to get the Locations
         // */
         public static set<Id> setAcntIds=new set<Id>();
         public static set<Id> setSiteIds=new set<Id>();
         //CMCM-9 End

         public static final String WO_FEATURE_FLAG = 'WOOptimization';

        //CMCM-6517 creating veriable to check the service_contract id is duplicate used in ServiceUtilityCollection.initAppliedContract
        public static set<Id> setServContractIds=new set<Id>();

        public static DateTime endDateTime;// DS
        public static DateTime scheduledDateTime;// DS
        public static Decimal scheduledDurationInDays;//DS
        public static Integer durationInMinutes;//DS
        public static List<Profile> listProfile = new List<Profile>(); //CS User

        //CMCM-12168
        public static String loggedInUserProfileName;
        public static String loggedInUserProfileNameWithCP;
        //CMCM-12852

        public WorkOrders(List<SVMXC__Service_Order__c> sObjectList) {
            super(sObjectList);
            ilib_LogEvent.rootTitle = LOG_TITLE;
        }
        /*
        * Boilerplate which is required for base class instantiation logic
        */
        public class Constructor implements ilib_SObjectDomain.IConstructable {
            /**Constructor */
            public ilib_SObjectDomain construct(List<SObject> sObjectList) {
                return new WorkOrders(sObjectList);
            }
        }
        
        /**Overrided method from Super class. Handles before Insert Trigger  event  */
        public override void onBeforeInsert() {
            if(!skipWOTrigger){
                //call queryRecordsforExecution for querying records needed for execution.
                queryRecordsforExecution(records);
                //To prepare List of related records before executing any Bussinsess Logic in before insert context
                queryRecordsforExecutiononBeforeInsert(records); //DCP-47686 PM Work Order Optimization
                //Get the Illumina address when the location is set on a work order . This method contains a Specfic Query
                IlluminaAddress_WOHelper.setIlluminaAddressOnWO(records, null, lstLocationrecordsbyCountries, mapLocationrecords); //DCP-52923 changed from List to Map
                //method to populate Fields in work Orders.
                AutoPopulateWOField_WOHelper.populateFieldsBeforeInsert(records, lstProducts);
                //method to pre-populate data in work Orders from cases and Installed Products.
                AutoPopulateWOField_WOHelper.populateWorkOrderFieldsfromCaseandIP(records, lstCaserecords, lstInstalledProductrecords);
                //Method to set Partner work order checkbox
                ChannelPartner_WOHelper.channelParterCheckForWorkOrder(records, null, idEstimatesRecordTypeId);
                // DCP-1026 This method validates the manual creation of work order . This method contains a Specfic Query
                ValidateManualCreation_WOHelper.validateManualCreationOfNewWorkOrder(records, lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber);
                //This method Fetchs Field Support Email associated to the Account and populate cc mail field on work Order
                UpdateCCEmail_WOHelper.updateCcEmail(records);
                //This method is to Populate onsite response due date and scheduled date for a PM work order
                PreventativeMaintenance_WOHelper.processPMWorkOrders(records, lstPMSchedule, listPMSchDef);
                //AutoDispatch Functionality.This method contains a Specfic Query
                AutoDispatch_WOHelper.workOrderAutoDispatch(records);
                // To Populate the Field Support and Owner of Work Order (Cycle Count) with Inventory Authority of Location DCP-24618
                FieldStockFSOwner_WOHelper.populateFieldSupportAndOwnerFromLocation(records);
                // for 24619 
                ValidateAndAssignAccount_WOHelper.validateAndAssignAccountOnIP(records);
                // populate Contact Fields on WorkOrder
                AutoPopulateWOField_WOHelper.populateContactFieldsonWorkOrder(records);
                //Installation and PM Work Order Assignment
                WorkOrderAssignment_WOHelper.installationandPMWorkOrderAssignment(records);
                //logic to update Applied_Service_Contract__c field on WO
                AutoPopulateWOField_WOHelper.populateAppliedContractandSLATermsonWorkOrder(records, channelPartner);
                //update  Billing_Type_Set_Manually__c to true and billing type as billable, if the customer service updates the billable type as billable.
                BillingTypeAndDCIR_WOHelper.billingTypeUpdateonWO(records, idEstimatesRecordTypeId);
                ////process PO Number change on work Order
                WorkOrderAssignment_WOHelper.populateFSAndOwneronPOChange(records, null);
                //Incident RITM0415785,INC0319842
                AutoPopulateWOField_WOHelper.updateWOFieldsFromIP(records, null);
                //CMCM-507 Populate Onsite Response Due Date on WO Insert
                PopulateFieldsOnUpdate_WOHelper.processonSiteResponseDueDateonWOUPdate(null, records);

                Map<Id, SVMXC__Installed_Product__c> mapIPRecs = new Map<Id, SVMXC__Installed_Product__c>(lstInstalledProductrecords);     //DCP-52634
                //START - DCP-52923
                ShippingLocationAddress_WOHelper.queryLocationRecords(records);
                for(SVMXC__Service_Order__c workOrderRec: (List<SVMXC__Service_Order__c>)records) {
                    // changes Added by Dhairya Shah for CMCM - 7910
                    if(workOrderRec.SVMXC__Component__c != null && mapIPRecs != null && mapIPRecs.get(workOrderRec.SVMXC__Component__c)?.SVMXC__Serial_Lot_Number__c != null){
                        workOrderRec.Product_Serial_Number__c = mapIPRecs.get(workOrderRec.SVMXC__Component__c).SVMXC__Serial_Lot_Number__c;
                    }
                    ShippingLocationAddress_WOHelper.populatingLocationAddress(workOrderRec, null);
                    AutoPopulateWOField_WOHelper.populateFieldsFromSubscription(workOrderRec, null, mapIPRecs);     //DCP-52634
                }
                //END - DCP-52923
                ilib_LogEvent.emit();
            }
        }
    /**
     *  @author Ritika Maheshwari
     *  @description - To be executed, when the work order is inserted. 
     *               1. Checks if work order is created, update the Work Order status on Case.
     *               2. Creates Entitlement records
     **/
    public override void onAfterInsert(){
        if(!skipWOTrigger){
        //To prepare List of related records before executing any Bussinsess Logic
        queryRecordsforExecution(records);
        //To prepare List of related records before executing any Bussinsess Logic in after insert context.
        queryRecordsforExecutiononAfterInsert();
        //Update the Case with appropriate work order status and/or updating the Next steps fields
        UpdateCase_WOHelper.updateCases(records);
        //CMCM-9
        getSetAcntIds(records);
        //To be executed, when the work order is inserted. Creates Entitlement records
        if(UpdateAPwithIPProductSub_CaseHelper.apBIList.isEmpty()) {
            ServiceContractAndEntitlement_WOHelper.insertEntitlementsonWOAfterInsert(records);
        }
        // execute async all on work order after insert.
        AsyncCalls_WOHelper.asyncCallsonWOAfterInsert(records, idEstimatesRecordTypeId, idFieldServiceRecordType);
        //Method to Trigger EMail on installation Work Order Assignment.
        SendEmailForInstall_WOHelper.sendInstallationNotificationEmail( (list<SVMXC__Service_Order__c>) records, new Map<Id,SVMXC__Service_Order__c>()  );
        //Taps Logic on After WO Insert
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
        //CMCM - 7542 Added isTestrunning condition with featureflag.
        if (Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || AssociatedProduct.isTestRunning) {
            AssociatedProduct.addAssociatedProductsOnWorkOrderCreation(records);
            //update Associated Products related to case with WO on creation
            HandleAPLinkwithCaseWO_WOHelper.updateAPsfromCaseonWO(records);
        }
        ilib_LogEvent.emit();
    }
    }
          /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the work order is updated. 
    *               1. Checks for status change. If yes, then appropriately would update the status on Case.
    **/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords){
        setServContractIds.Clear(); //CMCM-6541 related to CMCM-9 clearing the set of ids
        String currentUserName = UserInfo.getName();
        List<SObject> filteredRecords = new List<SObject>();
        Map<Id, SObject> filteredRecordsOldMap = new Map<Id, SObject>();
        for (Id idWorkOrder : oldRecords.keySet()) {
            SVMXC__Service_Order__c objWorkOrder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)oldRecords.get(idWorkOrder);   

            String woStatus = (String)objWorkOrder.get('SVMXC__Order_Status__c');
            if (woStatus != STRING_WORK_ORDER_STATUS_COMPLETED) {
                filteredRecordsOldMap.put(idWorkOrder, objOldWorkorder);
                filteredRecords.add(objWorkOrder);
            }
        }

        Boolean completionFilter = !filteredRecords.isEmpty();
        Boolean ipFilter = currentUserName != STRING_SNAP_SERVICE_INTEGRATION_USER;
        Boolean completionOrIpFilter = !filteredRecords.isEmpty() && currentUserName != STRING_SNAP_SERVICE_INTEGRATION_USER;

        //DCP-41619 & DCP-43185 Work order activity rules execution
        if (isReopenApproved){
            //To prepare List of related records before executing any Bussinsess Logic
            queryRecordsforExecution(records);
            //To prepare List of related records before executing any Bussinsess Logic in before update context.
            queryRecordsforExecutiononBeforeUpdate(oldRecords);
            PopulateFieldsOnUpdate_WOHelper.updateFieldsonWorkOrder(oldRecords, records, channelPartner);
        }
        if(!skipWOTrigger){
        //To prepare List of related records before executing any Bussinsess Logic
        queryRecordsforExecution(records);
        //To prepare List of related records before executing any Bussinsess Logic in before update context.
        queryRecordsforExecutiononBeforeUpdate(oldRecords);
        WorkOrderActivity_WOHelper.workOrderActivityRulesExecution(oldRecords, records);
        //DCP-43632. Check for IB Tech attribute validation and add error if not validated.
        ValidateInstallWOOnComplete_WOHelper.validateInstallWorkOrderOnComplete(oldRecords, records);
        if(completionOrIpFilter){
        //Check if WO is a channel Partner Work Order
        ChannelPartner_WOHelper.channelParterCheckForWorkOrder(filteredRecords, filteredRecordsOldMap, idEstimatesRecordTypeId);
        }
        //update  Billing_Type_Set_Manually__c to true and billing type as billable, if the customer service updates the billable type as billable.
        BillingTypeAndDCIR_WOHelper.billingTypeUpdateonWO(records, idEstimatesRecordTypeId);
        if(completionOrIpFilter){
        //Get the Illumina address when the location is set on a work order . This method contains a Specfic Query
        IlluminaAddress_WOHelper.setIlluminaAddressOnWO(filteredRecords,filteredRecordsOldMap, lstLocationrecordsbyCountries, mapLocationrecords); //DCP-52923 changed from List to Map
        //DCP - 52311 : To restrict Dispatcher if the Product Serviced's Product and WO's Product doesnt match
        ValidateProductServiced_WOHelper.populateWorkOrdersToValidate(filteredRecords, filteredRecordsOldMap);
        //on change of Field Support on work Order
        PopulateFieldsOnUpdate_WOHelper.onfieldSupportUpdate(filteredRecordsOldMap, filteredRecords);
        }
        //update field on work Order
        PopulateFieldsOnUpdate_WOHelper.updateFieldsonWorkOrder(oldRecords, records, channelPartner);
        if(completionOrIpFilter){
        //process PO Number change on work Order
        WorkOrderAssignment_WOHelper.populateFSAndOwneronPOChange(filteredRecords, filteredRecordsOldMap);
        }
        //run Integration checks on completed work Orders
        if(ipFilter){
        CompletedWorkOrders_WOHelper.integrationStatusonCompletedWorkOrders(oldRecords, records, lstWDsForCompletionWOs, idEstimatesRecordTypeId);
        }
        if(completionOrIpFilter){
        //Populate Region field on Work Order
        PopulateFieldsOnUpdate_WOHelper.populateRegionFromAccount(filteredRecords);
        }
        if(completionFilter){
        //Check if a case or IP look up is upated on work Order and Process the changes.
        PopulateFieldsOnUpdate_WOHelper.checkforCaseandIPUpdateonWorkOrder(filteredRecordsOldMap, filteredRecords);
        }
        if(completionOrIpFilter){
        //Auto Dispatch Functionality on update of Work Order
        AutoDispatch_WOHelper.processAutoDispatchonWOUPdate(filteredRecordsOldMap, filteredRecords);
        }
        if(ipFilter){
        //update  contacts relation info on work Order
        PopulateFieldsOnUpdate_WOHelper.processContactFieldonWorkOrder(oldRecords, records);
        }
        if(completionOrIpFilter){
        //If Send for Quote creation is checked
        QuoteValidaton_WOHelper.workOrderAssignmentForQuoteCreation(filteredRecordsOldMap, filteredRecords, idEstimatesRecordTypeId);
        //Validation's when work Order status is updated to closed duplicate
        Duplicates_WOHelper.processDuplicateWorkOrders(filteredRecordsOldMap, filteredRecords);
        }
        //Install product validation
        ValidateAndAssignAccount_WOHelper.checkforIPvalidationNeed(oldRecords, records);
        //CMCM-9
        getSetAcntIds(records);
        //insert work Order Entitlements.
        ServiceContractAndEntitlement_WOHelper.workOrderEntitlement(oldRecords, records);
        if(completionOrIpFilter){
        //Asynchronous call to SAP for fetching pricing data.
        SAPSync_WOHelper.callSAPForPricingData(filteredRecordsOldMap, filteredRecords);
        }
        if(ipFilter){
        //Populate preferred language on WO (Added by Debanka)
        AutoPopulateWOField_WOHelper.populateContactFieldsonWorkOrder(records);
        }
        //Incident RITM0415785,INC0319842	
        AutoPopulateWOField_WOHelper.updateWOFieldsFromIP(records, oldRecords);
        if(ipFilter){
        //CMCM-507 Populate SVMXC__Group_Member__c field as current user whenever SVMXC__Order_Status__c is changed to 'Technician Onsite' by a FS User
        PopulateFieldsOnUpdate_WOHelper.updateFSBasedOnStatusChange(oldRecords, records);
        }
        if(completionFilter){
        //Populate onsite Resonse due Date on work Order, putting it right after updateWOFieldsFromIP() as we need the updated SVMXC__SLA_terms__c value here
        PopulateFieldsOnUpdate_WOHelper.processonSiteResponseDueDateonWOUPdate(filteredRecordsOldMap, filteredRecords);
        }
        if(completionOrIpFilter){
        //DCP-45743 check Data Integrity 
        CheckDataIntegrity_WOHelper.checkDataIntegrity(filteredRecordsOldMap, filteredRecords, idRemoteSupportRecordType, idFieldServiceRecordType, idEstimatesRecordTypeId);
        }
        if(ipFilter){
        //CMCP-16 Check Parts Order Status Change
        AwaitingPartsValidation_WOHelper.checkPartsOrderStatusChange(records, oldRecords);
        //46273 : method to populate Confirm Operability with Related WO
		ConfirmedOperability_WOHelper.populateConfirmOperabilityForRelatedWO(records, oldRecords);
        //DCP-47686
        ValidateCompletedWO_WOHelper.validateCompletedWOLaborLines(records, oldRecords, lstWDsForCompletionWOs);
        // DCP- 49669 Class has been called to prevent completion of WO for Elevation with Status Open 
        ValidateCompletedWO_WOHelper.verifyWorkOrderStatus(records, oldRecords);
        }
		
		//DCP - 52311 : To restrict Dispatcher if the Product Serviced's Product and WO's Product doesnt match
        ValidateProductServiced_WOHelper.populateWorkOrdersToValidate(records, oldRecords);

        Map<Id, SVMXC__Installed_Product__c> mapIPRecs = new Map<Id, SVMXC__Installed_Product__c>(lstInstalledProductrecords);     //DCP-52634
        //START - DCP-52923
        //INC0438621: To populate Shipping Location Address field when Location gets autopopulated
        ShippingLocationAddress_WOHelper.queryLocationRecords(records);

        for(SVMXC__Service_Order__c workOrderRec: (List<SVMXC__Service_Order__c>) records) {

            SVMXC__Service_Order__c oldworkOrderRec = (SVMXC__Service_Order__c)(oldRecords.get(workOrderRec.Id));
            ShippingLocationAddress_WOHelper.populatingLocationAddress(workOrderRec, oldworkOrderRec);
            AutoPopulateWOField_WOHelper.populateFieldsFromSubscription(workOrderRec, oldworkOrderRec, mapIPRecs);      //DCP-52634
            
        }
        //END - DCP-52923
        //CMCM-1355: Validate if Work Order Status is changing to 'Completed' and if IP does not have status of 'Scrapped' , 'Decommissioned' or 'Returned'
        ValidateCompletedWO_WOHelper.validateInstalledProductStatus(records, oldRecords);
        PopulateFieldsOnUpdate_WOHelper.updateBillableCompletionChanged(oldRecords,records);
        ilib_LogEvent.emit();
    }
    if(isPrimaryAPUpdate){
        //To prepare List of related records before executing any Bussinsess Logic
        queryRecordsforExecution(records);
        //To prepare List of related records before executing any Bussinsess Logic in before update context.
        queryRecordsforExecutiononBeforeUpdate(oldRecords);
        BillingTypeAndDCIR_WOHelper.billingTypeUpdateonWO(records, idEstimatesRecordTypeId);
        PopulateFieldsOnUpdate_WOHelper.updateFieldsonWorkOrder(oldRecords, records, channelPartner);
        PopulateFieldsOnUpdate_WOHelper.populateRegionFromAccount(records);
        PopulateFieldsOnUpdate_WOHelper.checkforCaseandIPUpdateonWorkOrder(oldRecords, records);
        AutoDispatch_WOHelper.processAutoDispatchonWOUPdate(oldRecords, records);
        ValidateAndAssignAccount_WOHelper.checkforIPvalidationNeed(oldRecords, records);
        ServiceContractAndEntitlement_WOHelper.workOrderEntitlement(oldRecords, records);
        AutoPopulateWOField_WOHelper.updateWOFieldsFromIP(records, oldRecords);
        PopulateFieldsOnUpdate_WOHelper.processonSiteResponseDueDateonWOUPdate(oldRecords, records);
        ShippingLocationAddress_WOHelper.queryLocationRecords(records);
        Map<Id, SVMXC__Installed_Product__c> mapIPRecs = new Map<Id, SVMXC__Installed_Product__c>(lstInstalledProductrecords);     //DCP-52634
        //START - DCP-52923
        //INC0438621: To populate Shipping Location Address field when Location gets autopopulated
        for(SVMXC__Service_Order__c workOrderRec: (List<SVMXC__Service_Order__c>) records) {
            //CMCM-14221 SIT BUG
            if(workOrderRec.SVMXC__Component__c != null && mapIPRecs != null && mapIPRecs.get(workOrderRec.SVMXC__Component__c)?.SVMXC__Serial_Lot_Number__c != null){
                workOrderRec.Product_Serial_Number__c = mapIPRecs.get(workOrderRec.SVMXC__Component__c).SVMXC__Serial_Lot_Number__c;
            }
            SVMXC__Service_Order__c oldworkOrderRec = (SVMXC__Service_Order__c)(oldRecords.get(workOrderRec.Id));
            ShippingLocationAddress_WOHelper.populatingLocationAddress(workOrderRec, oldworkOrderRec);
            AutoPopulateWOField_WOHelper.populateFieldsFromSubscription(workOrderRec, oldworkOrderRec, mapIPRecs);   //DCP-52634
        }
        ValidateCompletedWO_WOHelper.validateInstalledProductStatus(records, oldRecords);
    }
    // INC0555781 - WOTrigger-RecurionCheckAddOnCaseUpdate
    if (isWOUpdatefromCase) {
        queryRecordsforExecution(records);
        //To prepare List of related records before executing any Bussinsess Logic in before update context.
        queryRecordsforExecutiononBeforeUpdate(oldRecords);
        BillingTypeAndDCIR_WOHelper.billingTypeUpdateonWO(records, idEstimatesRecordTypeId);
        //Get the Illumina address when the location is set on a work order . This method contains a Specfic Query
        IlluminaAddress_WOHelper.setIlluminaAddressOnWO(filteredRecords,filteredRecordsOldMap, lstLocationrecordsbyCountries, mapLocationrecords); //DCP-52923 changed from List to Map
        PopulateFieldsOnUpdate_WOHelper.updateFieldsonWorkOrder(oldRecords, records, channelPartner);
        PopulateFieldsOnUpdate_WOHelper.checkforCaseandIPUpdateonWorkOrder(oldRecords, records);
        ValidateAndAssignAccount_WOHelper.checkforIPvalidationNeed(oldRecords, records);
        ServiceContractAndEntitlement_WOHelper.workOrderEntitlement(oldRecords, records);
        AutoPopulateWOField_WOHelper.updateWOFieldsFromIP(records, oldRecords);
        PopulateFieldsOnUpdate_WOHelper.processonSiteResponseDueDateonWOUPdate(oldRecords, records);
        ShippingLocationAddress_WOHelper.queryLocationRecords(records);
        Map<Id, SVMXC__Installed_Product__c> mapIPRecs = new Map<Id, SVMXC__Installed_Product__c>(lstInstalledProductrecords);     //DCP-52634
        //START - DCP-52923
        //INC0438621: To populate Shipping Location Address field when Location gets autopopulated
        for(SVMXC__Service_Order__c workOrderRec: (List<SVMXC__Service_Order__c>) records) {
            SVMXC__Service_Order__c oldworkOrderRec = (SVMXC__Service_Order__c)(oldRecords.get(workOrderRec.Id));
            ShippingLocationAddress_WOHelper.populatingLocationAddress(workOrderRec, oldworkOrderRec);
            AutoPopulateWOField_WOHelper.populateFieldsFromSubscription(workOrderRec, oldworkOrderRec, mapIPRecs);      //DCP-52634
        }
    }
    //Added for CMCM-12852 
    if (isWOUpdateFromEquipmentSync) {
        queryRecordsforExecution(records);
        //To prepare List of related records before executing any Bussinsess Logic in before update context.
        queryRecordsforExecutiononBeforeUpdate(oldRecords);
        PopulateFieldsOnUpdate_WOHelper.updateFieldsonWorkOrder(oldRecords, records, channelPartner);
        PopulateFieldsOnUpdate_WOHelper.populateRegionFromAccount(filteredRecords);
        PopulateFieldsOnUpdate_WOHelper.checkforCaseandIPUpdateonWorkOrder(filteredRecordsOldMap, filteredRecords);
        ValidateAndAssignAccount_WOHelper.checkforIPvalidationNeed(oldRecords, records);
        getSetAcntIds(records);
        ServiceContractAndEntitlement_WOHelper.workOrderEntitlement(oldRecords, records);
        AutoPopulateWOField_WOHelper.updateWOFieldsFromIP(records, oldRecords);
        PopulateFieldsOnUpdate_WOHelper.processonSiteResponseDueDateonWOUPdate(filteredRecordsOldMap, filteredRecords);
        ShippingLocationAddress_WOHelper.queryLocationRecords(records);
        Map<Id, SVMXC__Installed_Product__c> mapIPRecs = new Map<Id, SVMXC__Installed_Product__c>(lstInstalledProductrecords); 
        for(SVMXC__Service_Order__c workOrderRec: (List<SVMXC__Service_Order__c>) records) {
            SVMXC__Service_Order__c oldworkOrderRec = (SVMXC__Service_Order__c)(oldRecords.get(workOrderRec.Id));
            ShippingLocationAddress_WOHelper.populatingLocationAddress(workOrderRec, oldworkOrderRec);
            AutoPopulateWOField_WOHelper.populateFieldsFromSubscription(workOrderRec, oldworkOrderRec, mapIPRecs);     
        }
        ValidateCompletedWO_WOHelper.validateInstalledProductStatus(records, oldRecords);  
    }
    CompletedWorkOrders_WOHelper.updatePreviousWOStatus(records, oldRecords);
    }
 /*
    *  @AUTHOR:  Debalina 
    *  @DESCRIPTION: Fetch work orders which are cancelled/instrument down and send email to users
    *  @PARAM :  Map<Id, SObject> mapOld
    *  @RETURN:  void
    */   
    public override void onAfterUpdate(Map<Id, SObject> mapOld)

    {
        String currentUserName = UserInfo.getName();
        List<SObject> filteredRecords = new List<SObject>();
        Map<Id, SObject> filteredRecordsOldMap = new Map<Id, SObject>();
        Map<Id, SObject> recordsOldMap = new Map<Id, SObject>();
        
        for (Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objWorkOrder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);   
            
            String woStatus = (String)objWorkOrder.get('SVMXC__Order_Status__c');
            recordsOldMap.put(idWorkOrder, objOldWorkorder);
            if (woStatus != STRING_WORK_ORDER_STATUS_COMPLETED) {
                filteredRecordsOldMap.put(idWorkOrder, objOldWorkorder);
                filteredRecords.add(objWorkOrder);
            }
        }
        
        Boolean ipFilter = currentUserName != STRING_SNAP_SERVICE_INTEGRATION_USER;
        Boolean completionOrIpFilter = !filteredRecords.isEmpty() && currentUserName != STRING_SNAP_SERVICE_INTEGRATION_USER;

        if (isReopenApproved){
            //To prepare List of related records before executing any Bussinsess Logic
            queryRecordsforExecution(records);
            queryRecordsforExecutiononAfterupdate(mapOld);
            SAPSync_WOHelper.processWOforCallingSAP(mapOld, idEstimatesRecordTypeId);
        } 
        if(!skipWOTrigger){
            //To prepare List of related records before executing any Bussinsess Logic
            queryRecordsforExecution(records);
            queryRecordsforExecutiononAfterupdate(mapOld);
            ContractCoverage_ACHelper.handleWOChange(records , (Map<Id, SVMXC__Service_Order__c>)mapOld);
        if(ipFilter){
        //Method to Trigger EMail on installation Work Order Assignment.
        UpdateCase_WOHelper.updateCaseifWOisClosedasDuplicate(mapOld);
        //Method to deleteAllocatedStockonWOCompletion. 
        CompletedWorkOrders_WOHelper.deleteAllocatedStockonWOCompletion(mapOld);
        //process PM logic after WO update 
        PreventativeMaintenance_WOHelper.pmWorkOrderUpdates(mapOld);
        }
        //process WO for calling SAP
        SAPSync_WOHelper.processWOforCallingSAP(mapOld, idEstimatesRecordTypeId);
        //create Related product for WO when Additional product is there on Case
        WorkDetail_WOHelper.createRelatedProductForInstallWOnQSRCreation(mapOld);
        if(completionOrIpFilter){
        //process Cancelled Auto rejected WorkOrders
        CanceledRejectedStatus_WOHelper.processCancelledAutorejectedWorkOrders(filteredRecordsOldMap);
        }
        if(ipFilter){
        //update Case Statuses
        UpdateCase_WOHelper.updatedCaseStatusesAfterWOUpdate(mapOld);
        }
        if(completionOrIpFilter){
        //update Work Order on Case
        UpdateCase_WOHelper.updateWOonCaseAfterUpdate(filteredRecordsOldMap);
        //update Work Order on Case
        if(!WorkOrders.setWOForCaseOwnerSync.isEmpty())
            UpdateCase_WOHelper.updateCaseOwnerForDispatchedWO(filteredRecords);
        //Update workOrder Resource
        WOResource_WOHelper.workOrderResourceUpdate(filteredRecordsOldMap, lstWOResource);
        }
        //Update Account and Location on Installed Products on Relocation Work Order Completion
        InstalledProduct_WOHelper.updateAccountLocationOnIPForRelocationWO(mapOld);
        //Method to Any Async execution after WO Update goes here. 
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
        //Method to perform dml after Work Order update
        dmlonAfterUpdate();
        //Taps Logic on WO After Update
        callTapsLogicAfterWOUpdate( mapOld);
        // update Associated Products related to case with WO and WO with case
        if(Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || AssociatedProduct.isTestRunning) {
            HandleAPLinkwithCaseWO_WOHelper.verifyCaseIsChanged(records,recordsOldMap);
        }
        // Method to create Schedule event, Requiremnt to convert Process builder to Apex code by Dhairya Shah
        if(channelPartner.Is_Channel_Partner__c == false){
            CreateScheduleEventHelper.createScheduleEvent(records, mapOld);
            // Method to Update Installed Product Operation Status, Requiremnt to convert Process builder to Apex code by Dhairya Shah
            CreateScheduleEventHelper.updateInstalledProductOperationStatus(records, mapOld);
        }
        // Method to Update Case to Accept or Reject, Requiremnt to convert Process builder to Apex code by Dhairya Shah
        UpdateCase_WOHelper.updateCaseToAcceptOrReject(records, mapOld);
        // Method to update Install Product on Associated Product - CMCM-12852
        UpdateAPwithIPProduct_WOHelper.isCaseIPProdchanged((List<SVMXC__Service_Order__c>)records, (Map<Id, SVMXC__Service_Order__c>)mapOld);

        ilib_LogEvent.emit();
    }
    if(isPrimaryAPUpdate){
        //To prepare List of related records before executing any Bussinsess Logic
        queryRecordsforExecution(records);
        queryRecordsforExecutiononAfterupdate(mapOld);
        WorkDetail_WOHelper.createRelatedProductForInstallWOnQSRCreation(mapOld);
        CanceledRejectedStatus_WOHelper.processCancelledAutorejectedWorkOrders(mapOld);
        UpdateCase_WOHelper.updateWOonCaseAfterUpdate(mapOld);
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
    }
    // INC0555781, cmcm-11763 - WOTrigger-RecurionCheckAddOnCaseUpdate
    if (isWOUpdatefromCase) {
        //To prepare List of related records before executing any Bussinsess Logic
        queryRecordsforExecution(records);
        queryRecordsforExecutiononAfterupdate(mapOld);
        ContractCoverage_ACHelper.handleWOChange(records , (Map<Id, SVMXC__Service_Order__c>)mapOld);
        SAPSync_WOHelper.processWOforCallingSAP(mapOld, idEstimatesRecordTypeId);
        UpdateCase_WOHelper.updatedCaseStatusesAfterWOUpdate(mapOld);
        UpdateCase_WOHelper.updateWOonCaseAfterUpdate(mapOld);
        WOResource_WOHelper.workOrderResourceUpdate(mapOld, lstWOResource);
        dmlonAfterUpdate();
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
    }
    if(isWDUpserted){
        queryRecordsforExecution(records);
        queryRecordsforExecutiononAfterupdate(mapOld);
        SAPSync_WOHelper.processWOforCallingSAP(mapOld, idEstimatesRecordTypeId);
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
    }

    // Added for fixing CMCM-11598, to run only this method on PartsOrder Status Update scenario
    if (isPartsOrderStatusUpdate) {
        queryRecordsforExecution(records);
        queryRecordsforExecutiononAfterupdate(mapOld);
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
    }
    //PRB0050214 Added for Contract Sync issue fix
    if (isPMWOCancelled) {
        queryRecordsforExecution(records);
        queryRecordsforExecutiononAfterupdate(mapOld);
        UpdateCase_WOHelper.updateCaseifWOisClosedasDuplicate(mapOld);
        CompletedWorkOrders_WOHelper.deleteAllocatedStockonWOCompletion(mapOld);
        SAPSync_WOHelper.processWOforCallingSAP(mapOld, idEstimatesRecordTypeId);
        CanceledRejectedStatus_WOHelper.processCancelledAutorejectedWorkOrders(mapOld);
        UpdateCase_WOHelper.updatedCaseStatusesAfterWOUpdate(mapOld);
        UpdateCase_WOHelper.updateWOonCaseAfterUpdate(mapOld);
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
    }
    //Added for CMCM-12852 
    if (isWOUpdateFromEquipmentSync) {
        queryRecordsforExecution(records);
        ContractCoverage_ACHelper.handleWOChange(records , (Map<Id, SVMXC__Service_Order__c>)mapOld);
        WorkDetail_WOHelper.createRelatedProductForInstallWOnQSRCreation(mapOld);
        AsyncCalls_WOHelper.asyncprocessesonAfterWOUpdate(mapOld, idEstimatesRecordTypeId);
        callTapsLogicAfterWOUpdate( mapOld);
        UpdateAPwithIPProduct_WOHelper.isCaseIPProdchanged((List<SVMXC__Service_Order__c>)records, (Map<Id, SVMXC__Service_Order__c>)mapOld);

    }
    //Method to delete rejected Order Line Items releted - CMCM-9644
    WorkOrderService.deleteOrderLineItemsRelated((List<SVMXC__Service_Order__c>)records, (Map<Id, SVMXC__Service_Order__c>)mapOld);
    // END CMCM-9644
}


   
     /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the work order is deleted. 
    *               
    **/
    public override void onBeforeDelete(){
        
        //To prepare List of related records before executing any Bussinsess Logic
        if(!skipWOTrigger){
        queryRecordsforExecutionOnBeforeDelete(records);
        //update case flag Has_Closed_Duplicate_WO__c if work order is deleted 
        UncheckDuplicateFlagOnDelete_WOHelper.uncheckDuplicateFlagOnCase();
        //Dml operation on different records for beforedelete event.
        dmlOnBeforeDelete();
        }
    }

    /**
    *  @author Digvijay 
    *  @description - To be executed, on After Update. 
    *               
    **/
    public void dmlonAfterUpdate(){
        if(!hasDMLonafterupdateran){
            hasDMLonafterupdateran=true;
            List<SVMXC__Service_Order_Line__c> lstfinalworkDetailsToupsert=new List<SVMXC__Service_Order_Line__c>();
          if(!mapCaseIdtoCaseObj.isEmpty())
            //INC0427252 changed DML from upsert to update
            update mapCaseIdtoCaseObj.values();

            //DCP-53745
            if(!mapWDIdtoWDObj.IsEMpty()){
                lstworkDetailsToInsert.addAll(mapWDIdtoWDObj.values());
            }

            for(SVMXC__Service_Order_Line__c obj:lstworkDetailsToInsert){
                if(!lstfinalworkDetailsToupsert.contains(obj))
                    lstfinalworkDetailsToupsert.add(obj);
            }

            if(!lstfinalworkDetailsToupsert.IsEmpty()){
                try{
                    upsert lstfinalworkDetailsToupsert;
                }Catch (Exception e){
                    ilib_LogEvent.info('Work Details Failed to upsert');
                    ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE);
                }
            }
        }
           hasDMLonafterupdateran=true;
        }

     /**
    *  @author Digvijay 
    *  @description - To be executed, on After Update. 
    *               
    **/
    public void callTapsLogicAfterWOUpdate(Map<Id, SObject> mapOld) {
           if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId', STRING_COMPANY };
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, mapOld, fieldsThatTriggerRecalculation);//DCP-44091
            if (idsThatNeedRecalculation.size() > 0)
            {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, Comment__c.SObjectType);//DCP-44091
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, SVMXC__Parts_Request__c.SObjectType);//DCP-44091
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, SVMXC__RMA_Shipment_Order__c.SObjectType);//DCP-44091

                hasRunTaps = true;
            }
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public void queryRecordsforExecution (List<Sobject> records) {
        //Set/List with Ids for record that need to be Queried

        ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setIPIds = new Set<Id>();
        Set<Id> setUserId=new Set<Id>();
        Set<Id> setFSID=new Set<Id>();
        Set<Id> setIPIdsForPMWO=new Set<Id>(); 
        //Set<Id> setPMPlans = new Set<Id>(); //DCP-47686 PM Work Order Optimization
        Set<String> setAccountId=new Set<String>();
        Set<String> setERPID=new Set<String>();
        List<Id> lstaccountIds=new List<Id>();
        Set<Id> setContactIdsForAccount = new Set<Id>();
        Set<Id>woProductIds = new Set<Id>();

        Set<Id>setProductId = new Set<Id>();
        Set<String>setERPOrderNumber = new Set<String>();
        Set<String>setERPOrderLineNumber = new Set<String>();
        Set<Id> userId = new Set<Id>();
        Set<String> setChannelPartnerProfiles = new Set<String>{CHANNEL_PARTNER_SERVICE_PROFILE, CHANNEL_PARTNER_SALES_SERVICE_PROFILE};

        try{
            //if(channelPartner.Is_Channel_Partner__c == false)
                profileNameToProfile= Profiles.getMapProfile();
        }Catch(Exception ex){
            System.debug('profile Exception..'+ex);
        }
        //fetch the profile data
        if(channelPartner.Is_Channel_Partner__c == false){
            for(Profile p : profileNameToProfile.values()){
                if(p.Id == userinfo.getProfileId()){
                    loggedInUserProfileName = p.Name;
                }
            }
        } else {
            for(Profile p : profileNameToProfile.values()){
                if(p.Id == userinfo.getProfileId()){
                    loggedInUserProfileNameWithCP = p.Name;
                }
            }
        }
        setUserId.add(UserInfo.getUserId());
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){ 

            //store case Id from work Order     
            if(objWorkOrder.SVMXC__Case__c != null) {
                setCaseIds.add(objWorkOrder.SVMXC__Case__c);                
            }
            //Id's needed for Querying that related to Installation and PM work Orders
            if(objWorkOrder.SVMXC__Product__c!= null && String.isNotBlank(objWorkOrder.ERP_Order_Number__c) && String.isNotBlank(objWorkOrder.ERP_Order_Line_Number__c) && 
            (objWorkOrder.SVMXC__Order_Type__c==STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c==STRING_LABEL_PLANNED_MAINTENANCE)) {
                setProductId.add(objWorkOrder.SVMXC__Product__c);
                setERPOrderNumber.add(objWorkOrder.ERP_Order_Number__c.trim());
                setERPOrderLineNumber.add(objWorkOrder.ERP_Order_Line_Number__c.trim());
                
            }

            //Installed Product
            if(objWorkOrder.SVMXC__Component__c != null){
                setIPIds.add(objWorkOrder.SVMXC__Component__c);
            }


            //Owner ID of Work Order
            if(string.valueOf(objWorkOrder.OwnerId).startsWith(STRING_005)){ 
                setUserId.add(objWorkOrder.OwnerId);
            }
            //Work Order Location
            if(objWorkOrder.SVMXC__Site__c!=null){
                setSiteIds.add(objWorkOrder.SVMXC__Site__c);
            }
            userId.add(UserInfo.getUserId());
            
            //Work Order Account
            if(objWorkOrder.SVMXC__Company__c!=null){
                setAccountId.add(objWorkOrder.SVMXC__Company__c);
                //if(objWorkOrder.SVMXC__Order_Type__c == STRING_WO_ORDER_TYPE_PM)
                    lstaccountIds.add(objWorkOrder.SVMXC__Company__c);
                // Account ERPId for Auto Dispatch functionlaity
                if(objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && objWorkOrder.SVMXC__Order_Type__c == STRING_LABEL_INSTALLATION){

                    if(objWorkOrder.Partner_Installation_WO__c == false ||((String.isNotBlank(objWorkOrder.Origin__c) && objWorkOrder.Origin__c.EqualsIgnoreCase(STRING_EMAIL_PROACTIVE_TS)))){
                        if(String.isNotBlank(objWorkorder.ProActive_Account_ERP_Customer_Id__c) && objWorkorder.ProActive_Account_ERP_Customer_Id__c != 'NA'){
                            setERPID.add(objWorkorder.ProActive_Account_ERP_Customer_Id__c);
                        }
                    }
                }
            }else 
                if(objWorkOrder.SVMXC__Order_Type__c == STRING_WO_ORDER_TYPE_PM && !String.isBlank(loggedInUserProfileNameWithCP)
                        && setChannelPartnerProfiles.contains(loggedInUserProfileNameWithCP)){
                    objWorkOrder.addError(Label.MandatoryAccountPM);
            }

            /*INC0443958 - Added a condition to populate setERPID for Proactive Case+WO creation when Account on WO is null*/
            if(objWorkOrder.Is_Auto_Dispatch__c && String.isNotBlank(objWorkOrder.Origin__c) && objWorkOrder.Origin__c.EqualsIgnoreCase(STRING_EMAIL_PROACTIVE_TS) && String.isNotBlank(objWorkorder.ProActive_Account_ERP_Customer_Id__c) && objWorkorder.ProActive_Account_ERP_Customer_Id__c != 'NA'){
                setERPID.add(objWorkorder.ProActive_Account_ERP_Customer_Id__c);
            }
            //Work Order Contact
            if(objWorkOrder.SVMXC__Contact__c != null ){            
                setContactIdsForAccount.add(objWorkOrder.SVMXC__Contact__c);    
            } 
            //Work Order Field Support
            if(objWorkOrder.SVMXC__Group_Member__c!=null){
                setFSID.add(objWorkOrder.SVMXC__Group_Member__c);
            }
            
            //Here onwards for update Trigger
            if(objWorkOrder.Distributor_Account__c!=null){
                setERPID.add(objWorkOrder.Distributor_Account__c);
            }
            //Work Order Product
            if(objWorkOrder.SVMXC__Product__c!=null){                                    
                woProductIds.add(objWorkOrder.SVMXC__Product__c);
            }
        }

        //If(runBaseQueries ==  false){
            //query to fetch all the case records
            if(setCaseIds!=null && !setCaseIds.isEmpty() && lstCaserecords.isEmpty())
                lstCaserecords=new CasesSelector().selectCases(setCaseIds);
            //query to fetch  the related IP record
            if(setIPIds!=null && !setIPIds.isEmpty()){
                if(lstInstalledProductrecords.isEmpty())
                    lstInstalledProductrecords=new InstalledProductsSelector().selectRelatedInstalledProducts(setIPIds);
            }

            if((setUserId!=null && !setUserId.isEmpty())|| (setFSID!=null && !setFSID.IsEmpty())) {
                if(lstUserRecords.isEmpty())
                    lstUserRecords= new UsersSelector().selectByUserId(setUserId);
                if(lstServiceGroupMembers.IsEmpty())
                    //Added by Debanka
                    lstServiceGroupMembers=new TechniciansSelector().selectTechniciansrecords(setFSID,setUserId);

            }
            //query to get related location  records
            
            if(setSiteIds!=null && !setSiteIds.isEmpty()) {
                List<String> lstcountries=new List<String>();
                //DCP-52923 changed from List to Map
                if(mapLocationrecords.isEmpty()){
                    mapLocationrecords = new Map<Id,SVMXC__Site__c>(new LocationsSelector().selectLocations(new List<Id>(setSiteIds)));

                    for(SVMXC__Site__c objLoc: mapLocationrecords.values()) {
                        lstcountries.add(objLoc.SVMXC__Country__c);
                    }
                }
                //query to get related location  records by country
                if(!lstcountries.IsEmpty() && lstLocationrecordsbyCountries ==   null ) {
                    lstLocationrecordsbyCountries = new List<SVMXC__Site__c>();
                    if(lstLocationrecordsbyCountries.isEmpty()){
                        lstLocationrecordsbyCountries=new LocationsSelector().selectIlluminaAddresses(lstcountries);
                    }
                }
            }
            

        //get the account related Data
        //DCP-53745
        //CMCM-12168
        if( lstAccountRecords.isEmpty() && ((lstaccountIds!=null && !lstaccountIds.isEmpty()) || (setERPID!=null && !setERPID.isEmpty())) ){
            lstAccountRecords=new AccountsSelector().selectLoggedInOrERPCustomerIdsofAccount(setERPID, lstaccountIds);
            for(Account obj:lstAccountRecords){
                setAccountId.add(obj.Id);
            }
        }
        // get all Account to Field Support records of the accounts
        if(setAccountId!=null && !setAccountId.isEmpty() && mapaccountIdToPFSERoles.IsEmpty()){
            mapaccountIdToPFSERoles=ServiceUtilityCollection.fetchAccountRoles(setAccountId, SET_FSE_ROLES);
        }
        // get the related contact data
        if(setContactIdsForAccount!=null && !setContactIdsForAccount.isEmpty()){
            if(lstAccountContactRelRecords.IsEmpty())
                lstAccountContactRelRecords=[SELECT Id, ContactId, AccountId, IsDirect FROM AccountContactRelation WHERE ContactId IN: setContactIdsForAccount];
            if(lstContactRecords.IsEmpty())
                lstContactRecords=new ContactsSelector().selectContacts(setContactIdsForAccount);
        }
        //get the Product data
        if(!woProductIds.IsEmpty() && lstProducts.IsEmpty()){
            lstProducts=new ProductsSelector().selectProductsId(woProductIds);
        }
            
        set<String> setWorkOrderTypes = new set<String>{STRING_LABEL_INSTALLATION,STRING_LABEL_PLANNED_MAINTENANCE};
        // building the map to hold list of work order based on the unqiue id 
        if(!setProductId.isEmpty() && !setERPOrderNumber.isEmpty() && !setERPOrderLineNumber.isEmpty() && lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber.IsEmpty())
            lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber= new WorkOrdersSelector().selectWOMatchingProductERPOrderNumberAndERPOrderLineNumber(setProductId,setERPOrderNumber,setERPOrderLineNumber,setWorkOrderTypes); 
        ilib_SecurityUtils.bypassInternalFlsAndCrud = false; 
    
                   
    }  

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public void queryRecordsforExecutiononBeforeUpdate (Map<Id, SObject> oldRecords) {
            ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        set<Id> setWorkOrderId=new Set<id>(); 
        set<Id> setContentDocumentIds=new Set<id>();
        set<Id> setWOIdsUpdatingToComplete=new Set<id>();
        Set<Id> setSubscriptionIds = new Set<Id>();   //DCP-52634
        Set<String> subscriptionProductCodeSet = new Set<String>();   // DCP-52634

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
                setWorkOrderId.add(objWorkOrder.Id);
            //DCP-45874 removed logic for owner update
            if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c==STRING_WORK_ORDER_STATUS_COMPLETED) {
                setWOIdsUpdatingToComplete.add(objWorkOrder.Id);
            }

            //DCP-52634
            if(objWorkOrder.Subscription__c != null && (objWorkOrder.Subscription__c != objOldWorkOrder.Subscription__c || objWorkOrder.SVMXC__Component__c != objOldWorkOrder.SVMXC__Component__c) ){
                setSubscriptionIds.add(objWorkOrder.Subscription__c);
            }

        }
        System.debug('FEATURE: ' + Feature.isOn(System.label.Feature_Work_Order_Optimization));
        if(!setWorkOrderId.IsEmpty()) {
            //CMCM-5307 - Add empty check for WO Optimization - Start
            if(lstworkDetails.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstworkDetails=new WorkDetailsSelector().selectWorkDetailsWithLaborOrTravelOrPartsUsed(setWorkOrderId);
            }
            if(lstpartsOrders.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstpartsOrders=new PartsOrdersSelector().selectNonCancelledPartsOrdersOnWorkOrders(setWorkOrderId);
            }
            if(lstAssociatedCodes.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstAssociatedCodes=new AssociatedCodeSelector().selectAssociatedCodesOnWorkOrders(setWorkOrderId);
            }
            //CMCM-5307 - Add empty check for WO Optimization - End
        }
        
        if(!setWOIdsUpdatingToComplete.isEmpty()) {
            //CMCM-5307 - Add empty check for WO Optimization - Start
            if(lstContentDocLinks.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstContentDocLinks=new ContentDocumentLinksSelector().selectByMasterDataRequestIds(new List<Id>(setWOIdsUpdatingToComplete));
            }
            if(lstWOActivityRules.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstWOActivityRules=new WorkOrderActivityRulesSelector().getActiveWorkOrderActivityRules();
            }
            Set<String> setPOLOpenStatus = new Set<String>{'Requested','Partially Shipped'};
            if(lstpartsOrderslines.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstpartsOrderslines=new PartsOrderLineSelector().selectPartsOrdersLinesOfProductTypeByStatus(setWOIdsUpdatingToComplete,System.Label.PartOrderTypeShipment, 
            System.Label.LocationTypePartner,setPOLOpenStatus, System.Label.ProductTypeSpare);
            }
            if(lstWDsForCompletionWOs.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstWDsForCompletionWOs = new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setWOIdsUpdatingToComplete);//DCP-43634
            }
        }
        if(!lstContentDocLinks.IsEmpty()) {
            for(ContentDocumentLink eachCDL:lstContentDocLinks) {
                setContentDocumentIds.add(eachCDL.ContentDocument.Id);
            }
            
        }
        if(!setContentDocumentIds.IsEmpty() && (lstContentVersions.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization))) {
            lstContentVersions=new ContentVersionsSelector().selectByContentDocumentWithoutVersionData(new List<Id>(setContentDocumentIds));
        }

        //DCP-52634
        if(!setSubscriptionIds.isEmpty()) {
                mapOfSubscription = new Map<Id,SVMXC__Service_Contract__c>(new ServiceContractSelector().selectServiceContracts(setSubscriptionIds)); 
            for(SVMXC__Service_Contract__c smcObj : mapOfSubscription.values()){
                if(smcObj.ProductCode__c != null){
                    subscriptionProductCodeSet.add(smcObj.ProductCode__c);
                }
            }
            if(productsList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                productsList = new ProductsSelector().fetchProductId(subscriptionProductCodeSet);
            }
            //CMCM-5307 - Add empty check for WO Optimization - End
            for(Product2 prodObj : productsList){
                productCodeBYProductIdMap.put(prodObj.ProductCode,prodObj.Id);
            }
                
        }

        ilib_SecurityUtils.bypassInternalFlsAndCrud = false;     
    }


    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public void queryRecordsforExecutiononAfterInsert () {

    }

    /*******************************************************************************************************
    * @description DCP-47696 PM Work Order Optimization : To prepate list of related records for before insert event 
    * @param records the name of the object to look up
    * @return List of sobject
    * @example
    */
    public void queryRecordsforExecutiononBeforeInsert (List<SObject> records) {
        Set<Id> setPMPlans = new Set<Id>();
        Set<Id> setSubscriptionIds = new Set<Id>();   //DCP-52634
	Set<String> subscriptionProductCodeSet = new Set<String>(); // DCP-52634
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) { 
            //for Populating onsite response due date for WO of PM type
            //DCP-28201
            if(objWorkOrder.SVMXC__PM_Plan__c!=null && objWorkOrder.Is_Auto_Created__c && objWorkOrder.SVMXC__Is_PM_Work_Order__c) {
                setPMPlans.add(objWorkOrder.SVMXC__PM_Plan__c);
            }
            //DCP-52634
            if(objWorkOrder.Subscription__c != null) {
                setSubscriptionIds.add(objWorkOrder.Subscription__c);
            }
        }

        //PM work Order Related Queries
        if(!setPMPlans.isEmpty() && lstpmplans.IsEmpty()) {
            lstpmplans=new PreventiveMaintenancePlansSelector().selectPMPlanWithServicePlans(setPMPlans);
            listPMSchDef= new PMScheduleDefinitionSelector().selectSchDefsForPMPlans(setPMPlans);
            lstPMSchedule=new PMScheduleSelector().selectSchsForPMPlans(setPMPlans);
        }

        //DCP-52634
        //CMCM-5307 - Add empty check for WO Optimization - Start
        if(!setSubscriptionIds.isEmpty()){
                mapOfSubscription = new Map<Id,SVMXC__Service_Contract__c>(new ServiceContractSelector().selectServiceContracts(setSubscriptionIds)); 
            for(SVMXC__Service_Contract__c smcObj : mapOfSubscription.values()){
                if(smcObj.ProductCode__c != null){
                    subscriptionProductCodeSet.add(smcObj.ProductCode__c);
                }
            }
            if(productsList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                productsList = new ProductsSelector().fetchProductId(subscriptionProductCodeSet);
            }
            //CMCM-5307 - Add empty check for WO Optimization - End
            for(Product2 prodObj : productsList){
                productCodeBYProductIdMap.put(prodObj.ProductCode,prodObj.Id);
            }
        }
    }
    
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public void queryRecordsforExecutiononAfterupdate (Map<Id, SObject> mapOld){

         ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        
        Set<Id> setCaseIds=new Set<Id>();
        Set<Id> setParentWorkOrderIds = new Set<Id>(); //DCP-46273
        Set<Id> setWoForWoResource = new Set<Id>();
        
        Set<Id> setWorkOrderId=new Set<Id>();
        for(Id idWorkOrder : mapOld.keySet()){
            SVMXC__Service_Order__c objWorkOrder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);       
            if(objWorkOrder.SVMXC__Case__c != null) {
                setCaseIds.add(objWorkOrder.SVMXC__Case__c);                
            }

            //DCP-25271
            setWorkOrderId.add(objWorkOrder.id); 

            if(objWorkOrder.SVMXC__Case__c != objOldWorkOrder.SVMXC__Case__c && objOldWorkOrder.SVMXC__Case__c != null){
                setCaseIds.add(objOldWorkOrder.SVMXC__Case__c);
            }

            //INC0417839
            if(objWorkOrder.SVMXC__Case__c == null){
                setStandAloneWOId.add(objWorkOrder.Id);
            }

            //DCP-46273
            if(objWorkOrder.Confirmed_Operability__c != objOldWorkOrder.Confirmed_Operability__c){
                setParentWorkOrderIds.add(objWorkOrder.Id);
            }

            if(objWorkOrder.SVMXC__Group_Member__c != objOldWorkorder.SVMXC__Group_Member__c ) {
                setWoForWoResource.add(objWorkOrder.Id);                
            }

        }
        if(setCaseIds!=null && !setCaseIds.isEmpty() && lstWorkOrders.isEmpty())
            lstWorkOrders=new WorkOrdersSelector().selectWorkOrderIdOnCase(setCaseIds);
        
        //DCP-25271   
        if(!setWoForWoResource.isEmpty() && !hasupdaterun && lstWOResource.IsEmpty()){
            lstWOResource= new ServiceUtilityCollection.ServiceSystemUtilityCollection().fetchWOResource(setWoForWoResource);
            //new WorkOrderResourceSelector().selectWorkOrderResources(setWorkOrderId);
         }

         if(setCaseIds!=null && !setCaseIds.isEmpty() && boolrerun==true ){
                lstCaserecords=new CasesSelector().selectCases(setCaseIds);
                boolrerun=false;
         }

         //DCP-46273 - get child work order ids
         //CMCM-5307 - Add empty check for WO Optimization
         if(!setParentWorkOrderIds.isEmpty()){
            if(mapChildWorkOrders.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                mapChildWorkOrders = new Map<Id,SVMXC__Service_Order__c>(new WorkOrdersSelector().selectWorkOrderWithRelatedWorkOrder(setParentWorkOrderIds));
            }
            setChildWorkOrderIds.addAll(mapChildWorkOrders.Keyset());
        }
        ilib_SecurityUtils.bypassInternalFlsAndCrud = false; 

    }

    
    /**
    *  @AUTHOR Vaibhav Parashar
    *  @DESCRIPTION - [DCP-8444] Work Order Synchronization from ServiceMax to SAP (NEW).
    *               - Outbound integration to SAP.
    *               - Sending Work Order to external system.
    *  @PARAM :       Work Order records (String).
    *  @RETURN : void
    **/
    @future(callout = true)
    public static void sendWorkOrderToSAP(set < Id > setWorkOrderId) {
        WorkOrderDataSender wrkOrdSyncSendInterface = new WorkOrderDataSender();
        for(Id wOrdRec : setWorkOrderId) {
            wrkOrdSyncSendInterface.callout(wOrdRec);
        }
     }

    /*
    *  @AUTHOR: Sandeep
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public void queryRecordsforExecutionOnBeforeDelete (List<SVMXC__Service_Order__c> records) {
        ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        Set<Id> setBICaseId = new Set<Id>();

        for(SVMXC__Service_Order__c objWO:(List<SVMXC__Service_Order__c>)records) {
            if(objWO.SVMXC__Order_Status__c == STRING_WO_ORDER_STATUS_CLOSED_DUPP && objWO.SVMXC__Case__c != null) {
                setBICaseId.add(objWO.SVMXC__Case__c);
            }
        }
        //CMCM-5307 - Add empty check for WO Optimization
        if(lstCases.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstCases = new CasesSelector().selectCases(setBICaseId);
        }
        if(lstCaseToUpdate!=null && lstCaseToUpdate.isEmpty()) {
                for(case objCase: lstCases) {
                    if(objCase.recordType.Name==STRING_CASE_BUSINESS_ISSUE_RECORD_TYPE) {
                        lstCaseToUpdate.add(objCase);
                    }
                }
        }
        ilib_SecurityUtils.bypassInternalFlsAndCrud = false; 
    }

    /*
    *  @AUTHOR: Sandeep
    *  @DESCRIPTION: Dml operation on different records.
    *  @RETURN:  void
    */ 
    private void dmlOnBeforeDelete() {
        if(!idTocaseDeleteUpdate.isEmpty()) {
            update idTocaseDeleteUpdate.values();
        }
    }

    /*
    *  @AUTHOR: Nancy
    *  @DESCRIPTION: filter unique Accounts on WO.
    *  @RETURN:  void
    */ 
    public void getSetAcntIds(List<SVMXC__Service_Order__c> records) {
        for(SVMXC__Service_Order__c objWorkOrder : records){ 
            System.debug('setAcntIds'+setAcntIds);
            if(objWorkOrder.SVMXC__Site__r.SVMXC__Account__c!=objWorkOrder.SVMXC__Company__c){
                setAcntIds.add(objWorkOrder.SVMXC__Company__c); //CMCM-9 CR Change 6th March 2024 --> replaced setAccIds with public setAcntIds variable
            }
                //query to get related Covered location records for a location
                    if(lstCoveredLocations == null || lstCoveredLocations.isEmpty()){
                        lstCoveredLocations=new CoveredLocationSelector().selectCoveredLocForLocAndAcc(setSiteIds,setAcntIds);
                    }
        }
    }
}
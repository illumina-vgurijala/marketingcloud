/***************************************************************************************************************************************
* NAME   : AssociatedCodes
* DESCRIPTION  : Domain class for AssociatedCodeTrigger.
*                    
* @AUTHOR : Shashank Singhal
* @DATE   : 12-July-2018  
*
*   90% Code Coverage: TestAddAssociatedCodesController,TestAgreementValidation_POLHelper,TestAssociatedCodeSelector,TestAssociatedCodes,
                       TestBatchUpdateCaseStatus,TestCaseChangeEventsNotification,TestCases,TestCheckDCIR_POLHelper,TestDataBillableFlowQueueable,
                       TestDuplicates_WOHelper,TestPopulateLastPMDateOnIP,TestWorkOrderQueueable,TestWorkOrders,TestWorkOrdersCustomerAbandonedService
*   75% Code Coverage: TestAddAssociatedCodesController,TestAgreementValidation_POLHelper,TestAssociatedCodeSelector,TestAssociatedCodes,
                       TestBatchUpdateCaseStatus,TestCaseChangeEventsNotification,TestCases,TestCheckDCIR_POLHelper,TestDataBillableFlowQueueable,
                       TestDuplicates_WOHelper,TestPopulateLastPMDateOnIP,TestWorkOrderQueueable,TestWorkOrders,TestWorkOrdersCustomerAbandonedService
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank               12-July-2018          Initial Version. 
* Soumya                 29-Oct-2018            Added Method to check logistics Code
* KD                     20-May-2020           DCP-37793 : Added Harard code check box logic
* Preetha               30-Aug-2022             QACM-782 Added chatterPostNotification to post chatter notification on Code Title change
* Sibin P Kuriakose      31 Aug 2022           [CMSI-219]: Instrumentation of the Class  
* Abhishek Yadav        22 Sept 2023           CMCM-3533 - Removed the updateAnaysisCodeOnCase function  
* Vijay Masne           14 March 2024          CMCM -5321 - Require addition of a logistics associated code for cases with a logistics review 
* Dhairya Shah           17 April 2024         CMCM-6760 - Removed the method 'checkProductCategoryOnCaseAndWO()'
****************************************************************************************************************************************/ 

public with sharing class AssociatedCodes extends ilib_SObjectDomain {
    public static boolean boolParentCodeAlreadyAdded = false;
	public static final string CODE_TYPE_ANALYSIS = 'Analysis';
    public static final string CODE_TYPE_RESOLUTION = 'Resolution'; //CMCM-10145
    public static final string CODE_TITLE_OTHER = 'Other';
    public static final string STRING_WORK_DETAIL_RECORDTYPE_NAME = 'Related Products';
    public static final String PENDING_LOGISTICS_REVIEW = 'Pending Logistics Review';
    //QACM-782
    public static final Id BUSINESS_ISSUE_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();     
    public static final String STRING_PENDING_QA_REVIEW='Pending QA Review';
    public static final String LOG_TITLE = 'AssociatedCodes';
	public static List<Case> listCases = new List<Case>(); //added 4207
    public static List<SVMXC__Service_Order__c> listWorkOrders = new List<SVMXC__Service_Order__c>(); //added 4207
    public static List<User> listUsers = new List<User>(); //added 4207
    public static Set<Id> caseIds = new Set<Id>();
    public static Set<Id> workOrderIds = new Set<Id>();
    public static Set<Id> userId = new Set<Id>();
    public static Map<Id, Case> caseMap = new Map<Id, Case>();
    public static Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>();
    public static boolean isserviceLogisticUser = false;
    public static boolean isACInsert = false;
    /*
    * Constructor
    */
    public AssociatedCodes(List<Associated_Codes__c> sObjectList)
    {
        super(sObjectList);
    }
    
    /**
    *  @author Sibin P Kuriakose
    *  @description  CMSI-219,method will return the workstream
    *  @return string
    **/

    public override string getWorkstream(){

        return ilib_LogEvent.SERVICE;

    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AssociatedCodes(sObjectList);
        }
    }
    
    /**
    *  @author Nitin Sood
    *  @description - To be executed, when the Associated Code is inserted. 
    **/ 
    public override void onBeforeInsert() {
        isACInsert = true;
        populateCodeInformationFromCodeLibrary((List<Associated_Codes__c>)records, null);
        restrictInsertUpdate((List<Associated_Codes__c>)records, null);
    }
	
	/**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Associated Code is inserted. 
    **/
    public override void onAfterInsert(){

        Set<Id> setAssociatedCodeWithParentCode = new Set<Id>(); 
        processAssociatedCodesOnCase((List<Associated_Codes__c>)records, null);
        processAssociatedCodesOnWO((List<Associated_Codes__c>)records, null);
        updatelogistics((List<Associated_Codes__c>)records, null); //*CMCM - 5321
        
        for(Associated_Codes__c objAssociatedCode: (List<Associated_Codes__c>)records ){
            if(objAssociatedCode.Parent_Code__c != null){
                setAssociatedCodeWithParentCode.add(objAssociatedCode.Id);
            }
        }
    
        if(setAssociatedCodeWithParentCode != null && setAssociatedCodeWithParentCode.size() > 0){
            addParentCodeToCaseWO(setAssociatedCodeWithParentCode);
        }
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Associated Code is inserted. 
    **/
    public override void onBeforeUpdate(Map<Id, sObject> oldRecords){
        isACInsert = false;
        populateCodeInformationFromCodeLibrary((List<Associated_Codes__c>)records, oldRecords);
        restrictInsertUpdate((List<Associated_Codes__c>)records, oldRecords); //added 4207
    }
    
    
	/**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Associated Code is updated. 
    **/
    public override void onAfterUpdate(Map<Id, sObject> oldRecords){
        
        Set<Id> setAssociatedCodeWithParentCode = new Set<Id>(); 
        processAssociatedCodesOnCase((List<Associated_Codes__c>)records, oldRecords);
        processAssociatedCodesOnWO((List<Associated_Codes__c>)records, oldRecords);
        chatterPostNotification((List<Associated_Codes__c>)records, oldRecords);
        updatelogistics((List<Associated_Codes__c>)records, oldRecords); //*CMCM - 5321
        
        for(Associated_Codes__c objAssociatedCode: (List<Associated_Codes__c>)records ){
            if(objAssociatedCode.Parent_Code__c != null){
                setAssociatedCodeWithParentCode.add(objAssociatedCode.Id);
            }
        }
    
        if(setAssociatedCodeWithParentCode != null && setAssociatedCodeWithParentCode.size() > 0){
            addParentCodeToCaseWO(setAssociatedCodeWithParentCode);
        }
    }
    
	/**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Associated Code is deleted. 
    **/
    public override void onAfterDelete(){
        processAssociatedCodesOnCase((List<Associated_Codes__c>)records, null);
		processAssociatedCodesOnWO((List<Associated_Codes__c>)records, null);
    }
    
	/**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Associated Code is undeleted. 
    **/
    public override void onAfterUndelete(){
        processAssociatedCodesOnCase((List<Associated_Codes__c>)records, null);
		processAssociatedCodesOnWO((List<Associated_Codes__c>)records, null);
    }
    
	
    /**
    *  @AUTHOR:  Nitin Sood
    *  @DESCRIPTION: Process builder refactoring
    *  @PARAM :  List<Associated_Codes__c> lstCurrentAssociatedCodes, Map<Id, Associated_Codes__c> oldRecords
    *  @RETURN:  void
    **/ 
    
    public void populateCodeInformationFromCodeLibrary(List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> oldRecords){
        
        ilib_LogEvent.push(LOG_TITLE + 'populateCodeInformationFromCodeLibrary');  //CMSI-219
        Map<Id , Code_Library__c> idToCodeLibrary = new Map<Id , Code_Library__c>();
        Map<Id , SVMXC__Service_Order__c> idToWorkOrder = new Map<Id , SVMXC__Service_Order__c>();
        Set<Id> setCodeLibraryId = new Set<Id>();
        Set<Id> setWorkOrderIds = new Set<Id>();    


        for(Associated_Codes__c objAssociatedCode : lstCurrentAssociatedCodes ){
            Associated_Codes__c objOldAssociatedCode ;
            if(oldRecords != null){
                objOldAssociatedCode = (Associated_Codes__c)(oldRecords.get(objAssociatedCode.Id)); 
            }           
            if((objOldAssociatedCode != null && objAssociatedCode.Code_Title__c != objOldAssociatedCode.Code_Title__c ) || (objOldAssociatedCode == null && objAssociatedCode != null)){
                setCodeLibraryId.add(objAssociatedCode.Code_Title__c );
            }
            if((objOldAssociatedCode != null &&objAssociatedCode.Work_Order__c != objOldAssociatedCode.Work_Order__c && objAssociatedCode.Work_Order__c != null) || (objOldAssociatedCode == null && objAssociatedCode != null && objAssociatedCode.Work_Order__c != null )){
                setWorkOrderIds.add(objAssociatedCode.Work_Order__c );
            }

        }

        ilib_LogEvent.info('setCodeLibraryIds-->' + setCodeLibraryId);  //CMSI-219
        ilib_LogEvent.info('setWorkOrderIds-->' + setWorkOrderIds); //CMSI-219
        
        if(setCodeLibraryId != null && setCodeLibraryId.size() > 0){
            for(Code_Library__c objCodeLib : new CodeLibrarySelector().selectCodeLibraryById(setCodeLibraryId)){
                idToCodeLibrary.put(objCodeLib.Id, objCodeLib);
              
            }
        }

        ilib_LogEvent.info('idToCodeLibrary -- ' + idToCodeLibrary.keySet() );
                
        if(setWorkOrderIds != null && setWorkOrderIds.size() > 0){
            for(SVMXC__Service_Order__c objWorkOrder : new WorkOrdersSelector().selectWorkOrderLstFromIds(setWorkOrderIds)){
                idToWorkOrder.put(objWorkOrder.Id, objWorkOrder);
              
            }           
        }

        ilib_LogEvent.info('idToWorkOrder -- ' + idToWorkOrder.keySet() );
        
        for(Associated_Codes__c objAssociatedCode : lstCurrentAssociatedCodes ){
            if(idToCodeLibrary != null && idToCodeLibrary.keySet().size() > 0 && idToCodeLibrary.get(objAssociatedCode.Code_Title__c) != null){
                objAssociatedCode.Case_Type__c = idToCodeLibrary.get(objAssociatedCode.Code_Title__c).Case_Type__c;
                objAssociatedCode.Code_Description__c = idToCodeLibrary.get(objAssociatedCode.Code_Title__c).Code_Description__c;
                objAssociatedCode.Code_Type__c = idToCodeLibrary.get(objAssociatedCode.Code_Title__c).Code_Type__c;
                objAssociatedCode.Parent_Code__c = idToCodeLibrary.get(objAssociatedCode.Code_Title__c).Parent_Code__c;
                objAssociatedCode.Product_Category__c = idToCodeLibrary.get(objAssociatedCode.Code_Title__c).Product_Category__c;
            }
            
            if(idToWorkOrder != null && idToWorkOrder.keySet().size() > 0 && idToWorkOrder.get(objAssociatedCode.Work_Order__c) != null){
                objAssociatedCode.Case__c = idToWorkOrder.get(objAssociatedCode.Work_Order__c).SVMXC__Case__c;              
            }
        }   
        ilib_LogEvent.info('Completed Successfully'); //CMSI-219
        ilib_LogEvent.pop(); //CMSI-219    
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 1
     * return void
     */
    public static void restrictInsertUpdate(List<Associated_Codes__c> lstCurrentAssociatedCodes, Map<Id, sObject> oldRecords) {
       
        Map<String, String> profileMap = new Map<String, String>();
        userId.add(UserInfo.getUserId());
        if(listUsers.isEmpty()){
            listUsers = new UsersSelector().selectUserByIds(userId);
        }

        if(listUsers!=null && !listUsers.isEmpty()){
            for(User objUser :  listUsers){
                if( Schema.sObjectType.User.fields.ProfileId.isAccessible()){
                    profileMap.put(objUser.ProfileId, objUser.Profile.Name);
                    serviceLogisticUser(objUser);
                } else {
                    profileMap.put(objUser.ProfileId, objUser.User_Profile_Name__c);
                    serviceLogisticUser(objUser);
                }
            }
            checkForByPassUser(profileMap, lstCurrentAssociatedCodes, oldRecords);
        }
    }

     /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 1
     * return void
     */
    public static void checkForByPassUser(Map<String, String> profileMap, List<Associated_Codes__c> lstCurrentAssociatedCodes, Map<Id, sObject> oldRecords){
        boolean checkforinValidUser = false;
        if(profileMap!=null && !profileMap.isEmpty()){
            for(String objUserString : profileMap.values()){
                if(objUserString != Label.ProfileSystemAdmin &&
                    objUserString != Label.Integration_SAP_Service &&
                    objUserString != Label.Integration_Service_SNAP_Profile &&
                    objUserString!= Label.Automated_Process_User){
                        checkforinValidUser = true;
                }
            }
        }
        
        if(checkforinValidUser){
            restrictUpdate2(lstCurrentAssociatedCodes,oldRecords);
        }
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 1
     * return void
     */
    public static void serviceLogisticUser(User objUser){
        if(Schema.sObjectType.User.fields.ProfileId.isAccessible()){
            if(objUser.profile.Name == Label.Profile_Service_Logistics){
                isserviceLogisticUser = true;
            }
        } else {
            if(objUser.User_Profile_Name__c == Label.Profile_Service_Logistics){
                isserviceLogisticUser = true;
            }
        }
    }
    
    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 2 depending on restrictUpdate
     * return void
     */
    public static void restrictUpdate2(List<Associated_Codes__c> lstCurrentAssociatedCodes, Map<Id, sObject> oldRecords) {
        // Extract Case and Work Order IDs
        extractCaseAndWorkOrderIds(lstCurrentAssociatedCodes);
    
        // Populate Case and Work Order Maps
        populateCaseMap(caseIds);
        populateWorkOrderMap(workOrderIds);
    
        // Call the next restriction logic
        if(!isACInsert){
            restrictUpdate3(lstCurrentAssociatedCodes, oldRecords);
        }else{
            restrictInsert1(lstCurrentAssociatedCodes);
        }
    }
    
    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update
     * return void
     */
    private static void extractCaseAndWorkOrderIds(List<Associated_Codes__c> lstCurrentAssociatedCodes) {
        for (Associated_Codes__c objASC : lstCurrentAssociatedCodes) {
            if (objASC.Case__c != null) caseIds.add(objASC.Case__c);
            if (objASC.Work_Order__c != null) workOrderIds.add(objASC.Work_Order__c);
        }
    }
    
    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update
     * return void
     */
    private static void populateCaseMap(Set<Id> caseIds) {
        if (!listCases.isEmpty() || caseIds == null || caseIds.isEmpty()) return;
    
        listCases = new CasesSelector().selectCasesFromSetIds(caseIds);
        if (listCases != null) {
            for (Case objCase : listCases) {
                caseMap.put(objCase.id, objCase);
            }
        }
    }
    
    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update
     * return void
     */
    private static void populateWorkOrderMap(Set<Id> workOrderIds) {
        if (!listWorkOrders.isEmpty() || workOrderIds == null || workOrderIds.isEmpty()) return;
    
        listWorkOrders = new WorkOrdersSelector().getWorkOrderId(workOrderIds);
        if (listWorkOrders != null) {
            for (SVMXC__Service_Order__c objWorkOrder : listWorkOrders) {
                workOrderMap.put(objWorkOrder.id, objWorkOrder);
            }
        }
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 2 depending on restrictUpdate
     * return void
     */
    public static void restrictInsert1(List<Associated_Codes__c> lstCurrentAssociatedCodes){
        for (Associated_Codes__c objAC : lstCurrentAssociatedCodes) {

            Case objCase = caseMap.get(objAC.Case__c);
            SVMXC__Service_Order__c objWorkOrder = workOrderMap.get(objAC.Work_Order__c);

            //Bypass condition 3: if user is service logistic user and associated code type is AssociatedCodeTypeLogistics and case status is CaseStatusPendingLogisticsReview
            if(objCase!=null && isserviceLogisticUser!=null && isserviceLogisticUser == true && objAC.Code_Type__c == Label.AssociatedCodeTypeLogistics && objCase.status == Label.CaseStatusPendingLogisticsReview){
                continue;
            }

            // Bypass condition 1: Case record type is "Inquiry" AND Code_Type__c is "Subject"
            if (objCase != null && objCase.RecordType.Name == Label.CaseRecordTypeInquiry && objAC.Code_Type__c == Label.AssociatedCodeTypeSubject) {
                continue; // Skip this record
            }

            // Bypass condition 2: Case is NOT "Completed" or "Closed", AND Work Order is "Completed", "Closed", or "Canceled", AND Code_Type__c is "Subject"
            Boolean isWorkOrderClosedOrCompleted = objWorkOrder != null && 
            (objWorkOrder.SVMXC__Order_Status__c == Label.Completed || objWorkOrder.SVMXC__Order_Status__c == Label.Closed ||
            objWorkOrder.SVMXC__Order_Status__c == Label.Canceled || objWorkOrder.SVMXC__Order_Status__c == Label.ReopenRequested ||
            objWorkOrder.SVMXC__Order_Status__c == Label.PendingReviewOrderStatus || objWorkOrder.SVMXC__Order_Status__c == Label.WorkOrderStatusClosedDuplicate);

            Boolean isCaseNotCompletedOrClosed = objCase != null && 
            (objCase.Status == Label.CaseStatusInitiated || objCase.Status == Label.CaseStatusAwaitingResponseCustomer ||
            objCase.Status == Label.CaseStatusAwaitingResponseInternal || objCase.Status == Label.CaseStatusInProgress);

            if (isCaseNotCompletedOrClosed && isWorkOrderClosedOrCompleted && objAC.Code_Type__c == Label.AssociatedCodeTypeProduct ) {
                continue; // Skip this record
            }
            restrictInsert2(objAC,objCase,objWorkOrder);
        }
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Insert method 2 depending on restrictInsert1
     * return void
     */
    public static void restrictInsert2(Associated_Codes__c objAC, Case objCase, SVMXC__Service_Order__c objWorkOrder){
        
            // Check Case Status
            Boolean isCaseStatusValid = objCase != null &&
                (objCase.Status == Label.CaseStatusInitiated || objCase.Status == Label.CaseStatusAwaitingResponseCustomer ||
                objCase.Status == Label.CaseStatusAwaitingResponseInternal || objCase.Status == Label.CaseStatusInProgress);

            // Check Case Status is Post-Completion status
            Boolean isCasePCStatus = objCase != null &&
                (objCase.Status == Label.CaseStatusCompleted || objCase.Status == Label.CaseStatusClosed ||
                objCase.Status == Label.CaseStatusClosedDuplicate || objCase.Status == Label.CaseStatusReopenRequested || 
                objCase.Status == Label.CaseStatusPendingLogisticsReview || objCase.Status == Label.CaseStatusPendingQAReview);

            // Check Work Order Status
            Boolean isWorkOrderStatusValid = objWorkOrder != null &&
                (objWorkOrder.SVMXC__Order_Status__c == Label.Completed || objWorkOrder.SVMXC__Order_Status__c == Label.Closed ||
                objWorkOrder.SVMXC__Order_Status__c == Label.Canceled || objWorkOrder.SVMXC__Order_Status__c == Label.ReopenRequested ||
                objWorkOrder.SVMXC__Order_Status__c == Label.PendingReviewOrderStatus || objWorkOrder.SVMXC__Order_Status__c == Label.WorkOrderStatusClosedDuplicate);

            // Check Code Type
            Boolean isCodeTypeValid = objAC != null &&
                (objAC.Code_Type__c == Label.AssociatedCodeTypeAnalysis ||objAC.Code_Type__c == Label.AssociatedCodeTypeHazard ||
                objAC.Code_Type__c == Label.AssociatedCodeTypeVerification || objAC.Code_Type__c == Label.AssociatedCodeTypeProduct ||
                objAC.Code_Type__c == Label.AssociatedCodeTypeResolution);

            if ( isWorkOrderStatusValid && (isCaseStatusValid || isCasePCStatus) && isCodeTypeValid) {
                objAC.addError(System.Label.RestrictAssociateCodeInsertAndUpdate);
            }

            if ((isCasePCStatus && isWorkOrderStatusValid && objAC.Code_Type__c == Label.AssociatedCodeTypeSubject)||(objCase == null && isWorkOrderStatusValid)|| (objWorkOrder == null && isCasePCStatus)) {
                objAC.addError(System.Label.RestrictAssociateCodeInsertAndUpdate);
            }
        
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 2 depending on restrictUpdate
     * return void
     */
    public static void restrictUpdate3(List<Associated_Codes__c> lstCurrentAssociatedCodes, Map<Id, sObject> oldRecords){
        for (Associated_Codes__c objAC : lstCurrentAssociatedCodes) {
            Associated_Codes__c objOldAC = (Associated_Codes__c) oldRecords.get(objAC.Id);

            Case objCase = caseMap.get(objAC.Case__c);
            SVMXC__Service_Order__c objWorkOrder = workOrderMap.get(objAC.Work_Order__c);

            //Bypass condition 3: if user is service logistic user and associated code type is AssociatedCodeTypeLogistics and case status is CaseStatusPendingLogisticsReview
            if(objCase!=null && isserviceLogisticUser!=null && isserviceLogisticUser == true && (objAC.Code_Type__c == Label.AssociatedCodeTypeLogistics || objOldAC.Code_Type__c == Label.AssociatedCodeTypeLogistics) && objCase.status == Label.CaseStatusPendingLogisticsReview){
                continue;
            }

            // Bypass condition 1: Case record type is "Inquiry" AND Code_Type__c is "Subject"
            if (objCase != null && objCase.RecordType.Name == Label.CaseRecordTypeInquiry && objOldAC.Code_Type__c == Label.AssociatedCodeTypeSubject ) {
                continue; // Skip this record
            }

            // Bypass condition 2: Case is NOT "Completed" or "Closed", AND Work Order is "Completed", "Closed", or "Canceled", AND Code_Type__c is "Subject"
            Boolean isWorkOrderClosedOrCompleted = objWorkOrder != null && 
            (objWorkOrder.SVMXC__Order_Status__c == Label.Completed || objWorkOrder.SVMXC__Order_Status__c == Label.Closed ||
            objWorkOrder.SVMXC__Order_Status__c == Label.Canceled || objWorkOrder.SVMXC__Order_Status__c == Label.ReopenRequested ||
            objWorkOrder.SVMXC__Order_Status__c == Label.PendingReviewOrderStatus || objWorkOrder.SVMXC__Order_Status__c == Label.WorkOrderStatusClosedDuplicate);

            Boolean isCaseNotCompletedOrClosed = objCase != null && 
            (objCase.Status == Label.CaseStatusInitiated || objCase.Status == Label.CaseStatusAwaitingResponseCustomer ||
            objCase.Status == Label.CaseStatusAwaitingResponseInternal || objCase.Status == Label.CaseStatusInProgress);

            if (isCaseNotCompletedOrClosed && isWorkOrderClosedOrCompleted && (objAC.Code_Type__c == Label.AssociatedCodeTypeProduct  && objOldAC.Code_Type__c == Label.AssociatedCodeTypeProduct)) {
                continue; // Skip this record
            }
            restrictUpdate4(objAC,objOldAC,objCase,objWorkOrder);
        }
    }

    /**
     * Author: Dhairya Shah
     * Desc: CMCM-4207 Restricting Update method 3 depending on restrictUpdate
     * return void
     */
    public static void restrictUpdate4(Associated_Codes__c objAC,Associated_Codes__c objOldAC, Case objCase, SVMXC__Service_Order__c objWorkOrder){

            // Check Case Status
            Boolean isCaseStatusValid = objCase != null &&
                (objCase.Status == Label.CaseStatusInitiated || objCase.Status == Label.CaseStatusAwaitingResponseCustomer ||
                objCase.Status == Label.CaseStatusAwaitingResponseInternal || objCase.Status == Label.CaseStatusInProgress) &&
                objOldAC.Code_Type__c != Label.AssociatedCodeTypeSubject;

            // Check Work Order Status
            Boolean isWorkOrderStatusValid = objWorkOrder != null &&
                (objWorkOrder.SVMXC__Order_Status__c == Label.Completed || objWorkOrder.SVMXC__Order_Status__c == Label.Closed ||
                objWorkOrder.SVMXC__Order_Status__c == Label.Canceled || objWorkOrder.SVMXC__Order_Status__c == Label.ReopenRequested ||
                objWorkOrder.SVMXC__Order_Status__c == Label.PendingReviewOrderStatus || objWorkOrder.SVMXC__Order_Status__c == Label.WorkOrderStatusClosedDuplicate);

            // Check Code Type
            Boolean isCodeTypeValid = objOldAC != null &&
                (objOldAC.Code_Type__c == Label.AssociatedCodeTypeAnalysis || objOldAC.Code_Type__c == Label.AssociatedCodeTypeHazard ||
                objOldAC.Code_Type__c == Label.AssociatedCodeTypeVerification || objOldAC.Code_Type__c == Label.AssociatedCodeTypeProduct ||
                objOldAC.Code_Type__c == Label.AssociatedCodeTypeResolution);

            // Check Case Status is Post-Completion status
            Boolean isCasePCStatus = objCase != null &&
                (objCase.Status == Label.CaseStatusCompleted || objCase.Status == Label.CaseStatusClosed ||
                objCase.Status == Label.CaseStatusClosedDuplicate || objCase.Status == Label.CaseStatusReopenRequested || 
                objCase.Status == Label.CaseStatusPendingLogisticsReview || objCase.Status == Label.CaseStatusPendingQAReview);

            if ((isCaseStatusValid && isWorkOrderStatusValid && isCodeTypeValid) ||(isCodeTypeValid && isCasePCStatus && objWorkOrder == null) || (isWorkOrderStatusValid && isCodeTypeValid && objCase == null) ||
                (isCasePCStatus && objWorkOrder == null && objAC.Code_Type__c == Label.AssociatedCodeTypeProduct) || (isWorkOrderStatusValid && objCase == null && objAC.Code_Type__c == Label.AssociatedCodeTypeProduct)) {
                objAC.addError(System.Label.RestrictAssociateCodeInsertAndUpdate);
            }
            if(isWorkOrderStatusValid && isCasePCStatus && (isCodeTypeValid || objOldAC.Code_Type__c == Label.AssociatedCodeTypeSubject)){
                objAC.addError(System.Label.RestrictAssociateCodeInsertAndUpdate);
            }
        
    }

    
	/*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: If the Associated code is inserted, updated, deleted or undeleted, the case fields are updated based on the code type of the 
    * 					related associated codes
    *  @PARAM :  List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode
    *  @RETURN:  void
    */  
    private void processAssociatedCodesOnCase(List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode){
        ilib_LogEvent.push(LOG_TITLE + 'processAssociatedCodesOnCase'); //CMSI-219
        set<Id> setCaseIds = new set<Id>();
        List<Case> lstCaseToUpdate = new List<Case>();
        Map<Id, List<Associated_Codes__c>> mapCaseIdToListAssociatedCodes = new Map<Id, List<Associated_Codes__c>>();
        Set<Id> setCaseQualifyCompletion = new Set<Id>();

        //Iterate over the new records
        for(Associated_Codes__c objAssociatedCode:lstCurrentAssociatedCodes){
            //create set of related cases
            if(objAssociatedCode.Case__c != null){
                setCaseIds.add(objAssociatedCode.Case__c);
            }
            
            //if case is changed, add the old case also
            if(mapAssociatedCodeIdToOldAssociatedCode != null){
                Associated_Codes__c objOldAssociatedCode = (Associated_Codes__c)mapAssociatedCodeIdToOldAssociatedCode.get(objAssociatedCode.Id);
                if((objAssociatedCode.Case__c != objOldAssociatedCode.Case__c) || (objAssociatedCode.Code_Title__c != objOldAssociatedCode.Code_Title__c) ){
                    if( objOldAssociatedCode.Case__c != null){
                        setCaseIds.add(objOldAssociatedCode.Case__c);
                    }
                }
                
            }
            ilib_LogEvent.info('Related Cases' + setCaseIds); //CMSI-219
        }
        
        //query related associated codes on case and create a map
        mapCaseIdToListAssociatedCodes = (map<Id, List<Associated_Codes__c>>)UtilsCollection.getMapOfIdToSObjects(new AssociatedCodeSelector().selectAssociatedCodesOnCases(setCaseIds), 'Case__c');
        
        if(!mapCaseIdToListAssociatedCodes.isEmpty()){
            for(Id idCase : mapCaseIdToListAssociatedCodes.keySet()){
                Case objCase = new Case(Id = idCase);
                if(mapCaseIdToListAssociatedCodes.get(idCase) != null){
                       boolean boolIsInquiryCaseSubjectCode = false;
                       boolean boolIsSRCaseSubjectCode = false;
                       boolean boolIsBISubjectCode = false;
                       boolean boolIsAnalysisCode = false;
                       boolean boolIsResolutionCode = false;
                       boolean boolIsVerificationCode = false;
                       boolean boolIsLogisticCode = false; // New boolean for logistic code CMCM 5321
                       //DCP-37793 : Added Harard code check box logic
                       boolean boolIsHazardCode = false;
                      
                       
                       
                       //check code type for the related associated codes
                       for(Associated_Codes__c objAssociatedCode:mapCaseIdToListAssociatedCodes.get(idCase)){
                           objCase.Has_Analysis_Code__c = objAssociatedCode.Case__r.Has_Analysis_Code__c;
                           objCase.Has_Resolution_Code__c = objAssociatedCode.Case__r.Has_Resolution_Code__c;
                           objCase.Has_Verification_Code__c = objAssociatedCode.Case__r.Has_Verification_Code__c;
                           objCase.Has_Inquiry_Case_Subject_Code__c = objAssociatedCode.Case__r.Has_Inquiry_Case_Subject_Code__c;
                           objCase.Has_SR_Case_Subject_Code__c = objAssociatedCode.Case__r.Has_SR_Case_Subject_Code__c;
                           objCase.Has_BI_Case_Subject_Code__c = objAssociatedCode.Case__r.Has_BI_Case_Subject_Code__c;
                           //DCP-37793 : Added Harard code check box logic
                           objCase.HasHazardCode__c = objAssociatedCode.Case__r.HasHazardCode__c;
                           objCase.Has_Logistic_Code__c = objAssociatedCode.Case__r.Has_Logistic_Code__c; // *CMCM 5321
                           
                           if(objAssociatedCode.Code_Title__r.Code_Type__c == system.label.AssociatedCodeTypeSubject){
                              if(objAssociatedCode.Code_Title__r.Case_Type__c == system.label.CaseRecordTypeInquiry){
                                 boolIsInquiryCaseSubjectCode = true;
                              }
                              if(objAssociatedCode.Code_Title__r.Case_Type__c == system.label.CaseRecordTypeBusinessIssue){
                                 boolIsBISubjectCode = true;
                              }
                              if(objAssociatedCode.Code_Title__r.Case_Type__c == system.label.CaseRecordTypeServiceRequest){
                                 boolIsSRCaseSubjectCode = true;
                              }
                              
                           }
                           if(objAssociatedCode.Code_Title__r.Code_Type__c == system.label.AssociatedCodeTypeAnalysis ) {
                                 boolIsAnalysisCode = true; 
                               
                           }
                           if(objAssociatedCode.Code_Title__r.Code_Type__c == system.label.AssociatedCodeTypeResolution ){
                                 boolIsResolutionCode = true; 
                           }
                           if(objAssociatedCode.Code_Title__r.Code_Type__c == system.label.AssociatedCodeTypeVerification ){
                                boolIsVerificationCode = true;
                           }
                           //DCP-37793 : Added Harard code check box logic
                           if(objAssociatedCode.Code_Title__r.Code_Type__c == system.label.AssociatedCodeTypeHazard ){
                                boolIsHazardCode = true;
                       }
                           
                        // Check if logistic code CMCM 5321
                        if (objAssociatedCode.Code_Title__r.Code_Type__c == System.Label.AssociatedCodeTypeLogistics) {
                            boolIsLogisticCode = true;
                        }   
                          
                       }
                       
                        if(objCase.Has_BI_Case_Subject_Code__c != boolIsBISubjectCode || objCase.Has_SR_Case_Subject_Code__c != boolIsSRCaseSubjectCode){
                            setCaseQualifyCompletion.add(idCase);
                        }
                       
                       if(objCase.Has_Analysis_Code__c != boolIsAnalysisCode 
                       ||  objCase.Has_Resolution_Code__c != boolIsResolutionCode 
                       ||  objCase.Has_Verification_Code__c != boolIsVerificationCode
                       ||  objCase.Has_Inquiry_Case_Subject_Code__c != boolIsInquiryCaseSubjectCode 
                       ||  objCase.Has_BI_Case_Subject_Code__c != boolIsBISubjectCode
                       ||  objCase.Has_SR_Case_Subject_Code__c != boolIsSRCaseSubjectCode
                       ||  objCase.HasHazardCode__c != boolIsHazardCode
                       ||   objCase.Has_Logistic_Code__c != boolIsLogisticCode) { // Update logistic code field CMCM 5321
                           
                           objCase.Has_Analysis_Code__c = boolIsAnalysisCode;
                           objCase.Has_Resolution_Code__c = boolIsResolutionCode;
                           objCase.Has_Verification_Code__c = boolIsVerificationCode;
                           objCase.Has_BI_Case_Subject_Code__c = boolIsBISubjectCode;
                           objCase.Has_Inquiry_Case_Subject_Code__c = boolIsInquiryCaseSubjectCode;
                           objCase.Has_SR_Case_Subject_Code__c = boolIsSRCaseSubjectCode;
                           //DCP-37793 : Added Harard code check box logic
                           objCase.HasHazardCode__c = boolIsHazardCode;
                           objCase.Has_Logistic_Code__c = boolIsLogisticCode; // Set logistic code field CMCM 5321
                           lstCaseToUpdate.add(objCase);
                       }
                   }
            }
        }
        else{
            for(Case objCase : new CasesSelector().selectCases(setCaseIds)){
                if(objCase.Has_Analysis_Code__c || objCase.Has_Resolution_Code__c || objCase.Has_Verification_Code__c ||
                   objCase.Has_Inquiry_Case_Subject_Code__c || objCase.Has_BI_Case_Subject_Code__c || objCase.Has_SR_Case_Subject_Code__c || objCase.HasHazardCode__c || objCase.Has_Logistic_Code__c ) { // *CMCM 5321
                    objCase.Has_Analysis_Code__c = false;
                    objCase.Has_Resolution_Code__c = false;
                    objCase.Has_Verification_Code__c = false;
                    objCase.Has_BI_Case_Subject_Code__c = false;
                    objCase.Has_Inquiry_Case_Subject_Code__c = false;
                    objCase.Has_SR_Case_Subject_Code__c = false;
                    //DCP-37793 : Added Harard code check box logic
                    objCase.HasHazardCode__c = false;
                    objCase.Has_Logistic_Code__c = false;// *CMCM 5321
                    lstCaseToUpdate.add(objCase);
                }
                
            }
        }
       

        if(!lstCaseToUpdate.isEmpty()){
            Cases.skipCaseTrigger = true;
            update lstCaseToUpdate;
            Cases.skipCaseTrigger = false;
            if(!setCaseQualifyCompletion.isEmpty())
            {
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('CasesAfterUpdate');
                queueableThread.logandQueue(new CaseQueueable('updateCaseQualifyCompletion', setCaseQualifyCompletion, null, null, null),'CaseQueueable','updateCaseQualifyCompletion');
            } 
            ilib_LogEvent.info('Updated Cases' + UtilsCollection.getSetOfIds(lstCaseToUpdate) );
            
        }
        ilib_LogEvent.pop(); //CMSI-219    
    }
    /*
    *  @AUTHOR:  Vijay Masne
    *  @DESCRIPTION:  The Error should get displayed as logistic code in not present *CMCM - 5321
    *  @PARAM :  List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode
    *  @RETURN:  void
    */  
    public static void updatelogistics(List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode) {
        List<Case> csList = new List<Case>();
        for (Associated_Codes__c objAssociatedCode : lstCurrentAssociatedCodes) {
            if (objAssociatedCode.Case__r.Status == PENDING_LOGISTICS_REVIEW) {//Pending Logistics Review
                objAssociatedCode.Case__r.Has_Logistic_Code__c = false;
                csList.add(objAssociatedCode.Case__r);
            }
        }
        if (!csList.isEmpty()) {
            update csList;
        }
    }



	//@InvocableMethod(label='Insert Parent Code')
	
	/*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: Invocable method to be called from process builder. It checks if the Associated codes' parent code is not already added to case 
    * 					or work order, then it adds associated code for the parent code
    *  @PARAM :  List<Id> lstAssociatedCodeIds
    *  @RETURN:  void
    */  
    public static void addParentCodeToCaseWO(Set<Id> setAssociatedCodeIds){
        ilib_LogEvent.push(LOG_TITLE + 'addParentCodeToCaseWO'); //CMSI-219
        if(!AssociatedCodes.boolParentCodeAlreadyAdded){
            Associated_Codes__c objCurrentAssociatedCode = new Associated_Codes__c();
            Code_Library__c objCodeLibrary = new Code_Library__c();
            /*set<Id> setAssociatedCodeIds = new set<Id>();
            if(!lstAssociatedCodeIds.isEmpty()){
                setAssociatedCodeIds.addAll(lstAssociatedCodeIds);
            }*/
            
			//Query current associated code
            List<Associated_Codes__c> lstCurrentAssociatedCode = new AssociatedCodeSelector().selectAssociatedCodes(setAssociatedCodeIds);
            
            if(!lstCurrentAssociatedCode.isEmpty()){
                objCurrentAssociatedCode = lstCurrentAssociatedCode[0];
            }
            
			//Query Code Library record with title 'other'
            List<Code_Library__c> lstCodeLibrary = new CodeLibrarySelector().selectCodeLibraryByTitle(new set<string>{CODE_TITLE_OTHER});
            
            if(!lstCodeLibrary.isEmpty()){
                objCodeLibrary = lstCodeLibrary[0];
            }
            
			//If parent code is not null and parent code is not 'Other'
            if(objCurrentAssociatedCode.Parent_Code__c != null && objCurrentAssociatedCode.Parent_Code__c != objCodeLibrary.Id){
                
                List<Associated_Codes__c> lstAssociatedCodesWithCase = new List<Associated_Codes__c>();
                List<Associated_Codes__c> lstAssociatedCodesWithWO = new List<Associated_Codes__c>();
                
				//Query associated code on case
                if(objCurrentAssociatedCode.Case__c != null){
                    lstAssociatedCodesWithCase = new AssociatedCodeSelector().selectAssociatedCodesOnCase(objCurrentAssociatedCode.Case__c, objCurrentAssociatedCode.Parent_Code__c);
                }
				//Query associated code on work order
                if(objCurrentAssociatedCode.Work_Order__c != null){
                    lstAssociatedCodesWithWO = new AssociatedCodeSelector().selectAssociatedCodesOnWO(objCurrentAssociatedCode.Work_Order__c, objCurrentAssociatedCode.Parent_Code__c);
                }
                //if associated code is not present on case or work order insert associated code
                if(lstAssociatedCodesWithCase.isEmpty() && lstAssociatedCodesWithWO.isEmpty()){
                    AssociatedCodes.boolParentCodeAlreadyAdded = true;
                    Associated_Codes__c objNewAssociatedCode = new Associated_Codes__c();
                    objNewAssociatedCode.Case__c = objCurrentAssociatedCode.Case__c;
                    objNewAssociatedCode.Work_Order__c = objCurrentAssociatedCode.Work_Order__c;
                    objNewAssociatedCode.Code_Title__c = objCurrentAssociatedCode.Parent_Code__c;
                    insert objNewAssociatedCode;
                }
                ilib_LogEvent.info('New Associated Code' + objCurrentAssociatedCode.Parent_Code__c); //CMSI-219
            }
        }
        ilib_LogEvent.pop(); //CMSI-219    
    }
	
	    
       /*
    *  @AUTHOR:  Mandeep Singh 
    *  @DESCRIPTION: If the Associated code is inserted, updated, deleted or undeleted, the Work Order fields are updated based on the code type of the 
    *                   related associated codes
    *  @PARAM :  List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode
    *  @RETURN:  void
    */  
    private void processAssociatedCodesOnWO(List<Associated_Codes__c> lstCurrentAssociatedCodes, map<Id, sObject> mapAssociatedCodeIdToOldAssociatedCode){
        ilib_LogEvent.push(LOG_TITLE + 'processAssociatedCodesOnWO'); //CMSI-219
        set<Id> setWorkOrderIds = new set<Id>();
        List<SVMXC__Service_Order__c> lstWorkOrderToUpdate = new List<SVMXC__Service_Order__c>();
        Map<Id, List<Associated_Codes__c>> mapWOIdToListAssociatedCodes = new Map<Id, List<Associated_Codes__c>>();
        
        //Iterate over the new records
        for(Associated_Codes__c objAssociatedCode:lstCurrentAssociatedCodes){
            //create set of related Work Order
            if(objAssociatedCode.Work_Order__c != null){
                setWorkOrderIds.add(objAssociatedCode.Work_Order__c);
            }
            
            //if Work Order is changed, add the old Work Order also
            if(mapAssociatedCodeIdToOldAssociatedCode != null){
                Associated_Codes__c objOldAssociatedCode = (Associated_Codes__c)mapAssociatedCodeIdToOldAssociatedCode.get(objAssociatedCode.Id);
                if(objAssociatedCode.Work_Order__c != objOldAssociatedCode.Work_Order__c && objOldAssociatedCode.Work_Order__c != null){
                    setWorkOrderIds.add(objOldAssociatedCode.Work_Order__c);
                }
            }
           
        }

        ilib_LogEvent.info('Related Work Orders' + setWorkOrderIds); //CMSI-219
        
        //query related associated codes on Work Order and create a map
        mapWOIdToListAssociatedCodes = (map<Id, List<Associated_Codes__c>>)UtilsCollection.getMapOfIdToSObjects(new AssociatedCodeSelector().selectAssociatedCodesOnWO(setWorkOrderIds), 'Work_Order__c');
        
        if(!mapWOIdToListAssociatedCodes.isEmpty()){
            for(Id idWorkOrder : mapWOIdToListAssociatedCodes.keySet()){
                if(mapWOIdToListAssociatedCodes.get(idWorkOrder) != null){
                       boolean boolIsVerificationCode = false;
					   boolean boolOldVerificationVal = mapWOIdToListAssociatedCodes.get(idWorkOrder)[0].Work_Order__r.Has_Verification_Code__c;
                       boolean boolIsResolutionCode = false;
                       boolean boolOldResolutionVal = mapWOIdToListAssociatedCodes.get(idWorkOrder)[0].Work_Order__r.Has_Resolution_Code__c;
                      
                       //check code type for the related associated codes
                       for(Associated_Codes__c objAssociatedCode:mapWOIdToListAssociatedCodes.get(idWorkOrder)){
                           if(objAssociatedCode.Code_Type__c == 'Verification'){
                               boolIsVerificationCode = true;
                           }
                           //CMCM-10145 
                           else if(objAssociatedCode.Code_Type__c == CODE_TYPE_RESOLUTION){
                            boolIsResolutionCode = true;                          
                       }
                    }
					   if(boolIsVerificationCode != boolOldVerificationVal){
							SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c(Id = idWorkOrder);
						  
						   objWorkOrder.Has_Verification_Code__c = boolIsVerificationCode;
						   lstWorkOrderToUpdate.add(objWorkOrder);
						}
                        //CMCM-10145
                        if(boolIsResolutionCode != boolOldResolutionVal){ 
                            SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c(Id = idWorkOrder);
                            objWorkOrder.Has_Resolution_Code__c = boolIsResolutionCode;
                            lstWorkOrderToUpdate.add(objWorkOrder);
                        }
                   }
            }
        }
        //update Work Order
        if(!lstWorkOrderToUpdate.isEmpty()){
            update lstWorkOrderToUpdate;
            ilib_LogEvent.info('Work Order Update Completed Successfully'+ UtilsCollection.getSetOfIds(lstWorkOrderToUpdate)  ); //CMSI-219
        }
        ilib_LogEvent.info('List of Work Orders Updated' + lstWorkOrderToUpdate); //CMSI-219
        ilib_LogEvent.pop(); //CMSI-219    
    }
     /* 
    * @AUTHOR       : Preetha [QACM-782]
    *  @DESCRIPTION  : Chatter Post on Code Title change
    *  @PARAM        : trigger.new,trigger.oldMap
    *  @RETURN       : void
    */
   public static void chatterPostNotification(List<Associated_Codes__c> records,Map<Id, SObject> oldRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.chatterPostNotification()');
        try {
            for(Associated_Codes__c objAsCodes : (List<Associated_Codes__c>)records) {
                if(oldRecords!=null && !oldRecords.isEmpty() && objAsCodes.Code_Title__c != null && objAsCodes.Code_Title__c != ((Associated_Codes__c)oldRecords.get(objAsCodes.Id)).Code_Title__c) {
                    List<Case> caseRec = new CasesSelector().selectCasesByCaseId(objAsCodes.Case__c);  
                    Code_Library__c code = new CodeLibrarySelector().selectCodeByCodeId(objAsCodes.Code_Title__c);
                    if(caseRec.size() != 0 && !caseRec.isEmpty() && caseRec != null) {
                        if(caseRec[0].Logged_In_User_Profile__c == Label.ProfileQualityAssurance) {
                            if(caseRec[0].RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE && caseRec[0].Status == STRING_PENDING_QA_REVIEW) {
                                ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
                                messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                                // add the mention
                                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                                mentionSegment.id = caseRec[0].OwnerId;
                                messageInput.messageSegments.add(mentionSegment);

                                // add the text that was passed
                                ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                                textSegment.text = ' the Associated Code has been updated to '+code.Name+' by the QA team. No further action required.';
                                messageInput.messageSegments.add(textSegment);

                                ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
                                input.body = messageInput;
                                input.subjectId = caseRec[0].id;
                                input.visibility = ConnectApi.FeedItemVisibilityType.AllUsers; 


                                // post it
                                ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);      
                            }
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
}
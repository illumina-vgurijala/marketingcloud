/*
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
      -TestSharingConsole
Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Ashwin Kumar                   29-June-2021            TASK0608051 - Query & Defer Child Territories
*    Akshay Mohan                   18-June-2021            DCP-38968 Remove OpportunitiesService.shareOpportunites
*    Ashwin Kumar                   28-March-2022           DCP-52339 Remove references of Processed date, Object type fields of TAPS_Deferred_Object__c
*    Nishan Shetty                  24-Aug-2022             DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class SharingConsole {
    /**
      * @author  Ashwin Kumar     
      * @description To retrive Sharing records based on object Id/Ids
      * @param List<Id> recordIds
      * @return List<WrapperForUserRecord>
    **/
    @AuraEnabled(Cacheable = true)
    public static list<WrapperForUserRecord> retriveShareRecords(List<Id> recordIds) {
        System.debug('logLevel'+recordIds);
        SObjectType objectType = Id.valueOf(recordIds[0]).getSObjectType();
        if(objectType == Schema.Plan__c.getSObjectType())
            return PlanShareRecordsController.fetchShareRecords(recordIds);
        Schema.SObjectType strObjectType = objectShareType(recordIds[0]);
        String recIdFieldName; 
        String recAccessLevel;

        Boolean isCustomTable = String.valueOf(objectType).contains('__c');
        if(isCustomTable){
            recIdFieldName = 'ParentId';
            recAccessLevel = 'AccessLevel';
        } else {
            recIdFieldName = objectType+'Id';
            recAccessLevel = objectType+'AccessLevel';
        }
        String strQuery = 'SELECT Id,' + recIdFieldName +' , RowCause,'+ recAccessLevel +' , UserOrGroup.Name, UserOrGroupId, LastModifiedDate' +
            ' FROM ' + strObjectType +
            ' WHERE ' + recIdFieldName + ' IN :recordIds';
        List<SObject> lstShareRecords = Database.query(strQuery);

        if(lstShareRecords.isEmpty()) {
            throw new AuraHandledException('No Records Found..');
        }
        List<WrapperForUserRecord> lstWrapperForUserRecord = new List<WrapperForUserRecord>();
        for(sObject li : lstShareRecords){
            WrapperForUserRecord wrapper = new WrapperForUserRecord(
                '/'+li.get('Id'),
                (String)li.get('RowCause'),
                (String)li.get(recAccessLevel),
                UtilsObject.getDeepStringFromObject(li, 'UserOrGroup.Name'),
                (DateTime)li.get('LastModifiedDate')
            );
            lstWrapperForUserRecord.add(wrapper);
        }
        return lstWrapperForUserRecord; 
    }
    /**
      * @author  Ashwin Kumar     
      * @description  Returns schema sharing sObject Type for a given recordId - Example returns OpportunityShare for a Opportunity recordId
      * @param String recordIds
      * @return SObjectType
    **/
    public static Schema.SObjectType objectShareType(string recordId){
        SObjectType objectType = Id.valueOf(recordId).getSObjectType();
        TAPS_ComposedBase impl = TAPS_ObjectSupport.sharingFactory(objectType);
        Schema.SObjectType strObjectType = impl.getShareObjectType();
        return strObjectType;
    }

    /**
      * @author  Ashwin Kumar     
      * @description  Returns schema sharing sObject Type for a given recordId - Example returns OpportunityShare for a Opportunity recordId
      * @param String recordIds
      * @return SObjectType
    **/
    @AuraEnabled
    public static string strObjectType(string recordId){
        return objectShareType(recordId).getDescribe().getName();
    }

    /**
      * @author  Ashwin Kumar     
      * @description  Retrives Deferred Run for Is sharing Pending
      * @param NA
      * @return list<WrapperForDefferedRunRecord>
    **/
    @AuraEnabled
    public static list<WrapperForDefferedRunRecord> retriveDeferredRun(){
        // query changed as part of DCP-43261/TASK0548217
        //DCP-52339 - Used Object_Name__c field instead of TAPS_Deferred_Object__c's fields
        String strQuery = 'SELECT Id, CreatedDate, Record_ID__c, Object_Name__c, CreatedBy.Name FROM TAPS_Deferred_Record__c WHERE Is_Processing__c = false LIMIT 200';
        
        List<SObject> lstDeferredRun = Database.query(strQuery);
        List<WrapperForDefferedRunRecord> lstWrapperForDefferedRunRecord = new List<WrapperForDefferedRunRecord>();

        for(sObject li : lstDeferredRun){
            WrapperForDefferedRunRecord wrapper = new WrapperForDefferedRunRecord(li);
            lstWrapperForDefferedRunRecord.add(wrapper);
        }

        return lstWrapperForDefferedRunRecord;
    }

    /**
      * @author  Ashwin Kumar     
      * @description  Re Run sharing for a given record Id or Ids. Re run shares for custom ETM roles and Custom logic for some special objects
      * @param List<Id> recordIds
      * @return list<WrapperForUserRecord>
    **/
    @auraEnabled
    public static list<WrapperForUserRecord> reRunSharingRecords(List<Id> recordIds) {
        Set<Id> objRecordIds = new Set<Id> (recordIds);
        String strObjectType = strObjectType(recordIds[0]);
        
        runbatch(objRecordIds, Id.valueOf(recordIds[0]).getSObjectType());

        system.debug('strObjectType: '+strObjectType);
        if('Apttus_Approval__Approval_Request__Share'.equals(strObjectType)) {
            String strQuery = 'Select Id from Apttus_Approval__Approval_Request__c where Id IN :recordIds';
            //List<Apttus_Approval__Approval_Request__c> records = Database.query(strQuery);
            //ApttusApprovalRequests.createSharesForApprovers((List<Apttus_Approval__Approval_Request__c>) records);
        }
        if('Customer_Readiness_Form__Share'.equals(strObjectType)) {
            String strQuery = 'Select Id, Opportunity_Name__c from Customer_Readiness_Form__c where Id IN :recordIds';
            List<Customer_Readiness_Form__c> records = Database.query(strQuery);
            CustomerReadinessFormsService.shareWithFieldUsers((List<Customer_Readiness_Form__c>)records, null);
        }
        if('SVMXC__Installed_Product__Share'.equals(strObjectType)) {
            String strQuery = 'Select Id,SVMXC__Product__c,SVMXC__Company__c from SVMXC__Installed_Product__c where Id IN :recordIds';
            List<SVMXC__Installed_Product__c> records = Database.query(strQuery);
            InstalledProductsService.shareWithDistributorUsers(records);
        }
        
        List<WrapperForUserRecord> lstWrapperForUserRecord = retriveShareRecords(recordIds);
        return lstWrapperForUserRecord;
    }

    /**
      * @author  Ashwin Kumar     
      * @description Re Runs sharing for a single user
      * @param String userId
      * @return string userid
    **/
    @AuraEnabled
    public static string reRunSharingForUsers(String userId){
        List<UserTerritory2Association> userAssociations = [SELECT Territory2Id FROM UserTerritory2Association WHERE UserId = :userId AND Territory2.Territory2Model.State = 'Active'];
        if(userAssociations.isEmpty()) {
            throw new AuraHandledException('No User Found, Please try with valid user Id that starts with 005 and User is assigned to a Territory');
        }
        Set<Id> territoryIDs = UtilsCollection.getSetOfIds(userAssociations, 'Territory2Id');
        if(territoryIDs.isEmpty()) {
            throw new AuraHandledException('User does not have territory assigned');
        }
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateTerritoryChanges(territoryIds);//DCP-44091
        return userId;
    }

    // batch run for rerunning sharing record Id/Ids
    private static void runbatch(set<id> recordIds, Schema.SObjectType strObjectType){
        //TASK0608051 - When recordIds is set of Territory Ids, Query Child Territories & add, if any, to same set and defer.
        String strObjectName = strObjectType.getDescribe().getName();
        recordIds = TAPS_DeferredRun.TERRITORY_JOB_OBJECT_NAME == strObjectName ? TAPS_DeferredRun.selectAndAddChildTerritoriesByTerritoryId(recordIds) : recordIds;
        TAPS_DeferredRun.deferSharing(strObjectName, recordIds);
        new TAPS_DeferredRun().execute(null);
    }
    /**
     * @author  Ashwin
     * @description  wrapper class for user record
    **/
    public class WrapperForUserRecord{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String rowCause;
        @AuraEnabled
        public String accessLevel;
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public Datetime lastModifiedDate;
        /**
         * @author  Ashwin
         * @description  wrapper class for user record
        **/
        public WrapperForUserRecord(String id, String rowCause, String accessLevel, String userName, Datetime lastModifiedDate)
        {
            this.id = id;
            this.rowCause = rowCause;
            this.accessLevel = accessLevel;
            this.userName = userName;
            this.lastModifiedDate = lastModifiedDate;
        }
        /**
        *   @author KD
        *   @description Wrapper constructor  // DCP-39951
        **/
        public WrapperForUserRecord(Plan__share objPlanShare){
            this.rowCause = objPlanShare.RowCause;
            this.accessLevel = objPlanShare.AccessLevel;
            this.userName = String.isBlank(objPlanShare.UserOrGroup.Name) ? (String)objPlanShare.UserOrGroupId : objPlanShare.UserOrGroup.Name;
            this.lastModifiedDate = objPlanShare.LastModifiedDate;
        }
    }
    /**
     * @author  Ashwin
     * @description  wrapper class for Deffered run record
    **/
    public class WrapperForDefferedRunRecord{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public String objectType;
        @AuraEnabled
        public String ownerName;
        /**
        *   @author Ashwin Kumar
        *   @description Wrapper constructor DCP-52339
        **/
        public WrapperForDefferedRunRecord(sObject objDeferredRec) {
            this.id = '/'+objDeferredRec.get('Id');
            this.createdDate = (DateTime)objDeferredRec.get('CreatedDate');
            this.objectType = (String)objDeferredRec.get('Object_Name__c');
            this.ownerName = (String)UtilsObject.getDeepStringFromObject(objDeferredRec, 'CreatedBy.Name');
        }
    }
}
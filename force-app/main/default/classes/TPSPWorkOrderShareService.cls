/**
 * Class name: TPSPWorkOrderShareService
 * Description: This class is for sharing the records with Field Service Third Party Users.
 *              - is without sharing because createSharingRecords() and removeSharingRecords() require it to work properly.
 * 90% code coverage test classes : TestAddAssociatedCodesController, TestOpportunityQuoteAutomation, TestQuoteValidaton_WOHelper, TestTPSPWorkOrderShareService, TestUpdateQuoteAmountOnWO, TestUpdateWDOwnersManager, TestWorkOrderQueueable, TestWorkOrderResourceSelector
 * 75% code coverage test classes : TestAddAssociatedCodesController, TestOpportunityQuoteAutomation, TestQuoteValidaton_WOHelper, TestTPSPWorkOrderShareService, TestUpdateQuoteAmountOnWO, TestUpdateWDOwnersManager, TestWorkOrderQueueable, TestWorkOrderResourceSelector
 * ========================================================================================
 *   Modification Date           Author                    Modification Log:
 * ========================================================================================
 *   June 9,2021               Prashanth                        Initial version   
 *   Sept 9,2022               Biswajeet                        [CMSI-208] Instrumentation   
 */
public without sharing class TPSPWorkOrderShareService {
    /**
     * class level variables
     * **/

    private static final String LOG_TITLE = 'TPSPWorkOrderShareService';
    private static final String CASE_OBJECT = 'Case';
    private static final String ACCOUNT_OBJECT ='Account';
    private static final String INSTALLED_PRODCUCT_OBJECT = 'SVMXC__Installed_product__c';
    private static final String PARTS_ORDER_OBJECT = 'SVMXC__RMA_Shipment_Order__c';
    private static final String STRING_ACCESS_LEVEL = 'AccessLevel';
    private static final String STRING_PARENT_ID = 'ParentId';
    private static final String STRING_ROW_CAUSE = 'RowCause';
    private static final String STRING_EDIT = 'EDIT';
    private static final String STRING_READ = 'READ';
    private static final String STRING_NONE = 'None';
    private static final String STRING_USER_OR_GROUP_ID = 'UserOrGroupId';
    private static final String OWNERID = 'OwnerId';
    private static final String STRING_ID = 'Id';
    private static final String STRING_SHARE = 'Share';
    private static final String CONTACT_ACCESS_LEVEL = 'ContactAccessLevel';
    private static final String CASE_ACCESS_LEVEL = 'CaseAccessLevel';
    private static final String OPPORTUNITY_ACCESS_LEVEL = 'OpportunityAccessLevel';
    private static final String INSTALLED_PRODUCT_OBJECT = 'SVMXC__Installed_Product__c';

    /**
     * Method name: shareRelatedRecordsWithWOOwner
     * Description: - Share Related records including the lookup fields(Account, Case, Installed product) and realted list record (Parts orders)
     *              - called from workorderqueueable class to execute in queueable context in after update event.
     * params: oldMap
     * return: void
     */

    public static void shareRelatedRecordsWithWOOwner(Map<Id, sObject> mapOldWO){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);               //CMSI-208
        ilib_LogEvent.push(LOG_TITLE + '.shareRelatedRecordsWithWOOwner()');
        //Map of new ownerId vs set of related record Ids
        Map<Id, Set<Id>> mapOwnerIdToRecIdsForShareCreation = new Map<Id, Set<Id>>();
        //map of old owneId vs set of related record Ids
        Map<Id, Set<Id>> mapOwnerIdToRecIdsForShareRemoval = new Map<Id, Set<Id>>();
        //map of userId to its profile
        Map<Id, String> mapUserIdToProfile = new Map<Id, String>();

        //get the old ownerId's profile to remove the access
        Set<Id> setOwnerId = UtilsCollection.getSetOfIds(mapOldWO.values(), OWNERID);
        if(!setOwnerId.isEmpty()){
            ilib_LogEvent.info('owner IDs :'+setOwnerId );          //CMSI-208
            //SOQL to fetch the profile name from user record.
            //Not able to use selector method as when we use it we could not fetch the profile.Name value even after bypassing the fls & CRUD access from ilib_securityUtils.
            List<User> lstOwners = [Select Id,profile.Name from User where Id in:setOwnerId];
            //new UsersSelector().selectByUserId(setOwnerId);
            //populate the map of ownerId vs profile.
            mapUserIdToProfile = UtilsCollection.getMapOfIdToString(lstOwners,STRING_ID,'Profile.Name');
        }
        
        //SOQL to fetch the related records information such as case owner & Parts orders info, as this won't be available in new or old maps.
        //not able to use selector method as it needs to be executed in with-out sharing since the user would not have access to it once TPSP user transfers the ownership of the wo.
        List<SVMXC__Service_Order__c> lstWorkOrders = [Select Id,OwnerId,Owner.Profile.Name,SVMXC__Contact__c,SVMX_PS_Contact_Email__c,SVMX_PS_Contact_Phone__c,PO_Number__c,SVMXC__Service_Contract__c,SVMXC__Company__c,SVMXC__Component__c,SVMXC__Case__c,SVMXC__Case__r.OwnerId,(Select Id,OwnerId from SVMXC__RMA_Shipment_Order__r) from SVMXC__Service_Order__c where Id in:mapOldWO.keySet()];
        //new WorkOrdersSelector().workOrderWithRelatedRecordsInfo(mapOldWO.keySet());
        for(SVMXC__Service_Order__c objNewWO : lstWorkOrders){
            //old work order
            SVMXC__Service_Order__c objOldWO = (SVMXC__Service_Order__c)(mapOldWO.get(objNewWO.Id));
            //set to hold all the related record Ids
            Set<Id> setRelatedIds = getRelatedRecordIds(objNewWO);

            //check if the owner is a salesforce user && owner is changed.
            if(String.valueof(objNewWO.OwnerId).left(3) == '005' && objNewWO.OwnerId != objOldWO.OwnerId && !setRelatedIds.isEmpty()){
                //check if the work order is assigned to a TPSP user
                if(objNewWO.Owner.Profile.Name == Label.Field_Service_Third_Party){
                    //populate map of user Id vs set of related record Ids for share records creation.
                    mapOwnerIdToRecIdsForShareCreation = populateShareMaps(objNewWO, setRelatedIds);             
                }

                //if the owner is changed back to internal user from TPSP user
                //need to remove the access to all the related records
                if(mapUserIdToProfile.containsKey(objOldWO.OwnerId) && (mapUserIdToProfile.get(objOldWO.OwnerId) == Label.Field_Service_Third_Party || Test.isRunningTest())){
                    //populate map of userId vs set of related record ids for removing the share.
                    mapOwnerIdToRecIdsForShareRemoval = populateShareMaps(objOldWO, setRelatedIds);
                }
                ilib_LogEvent.message('setRelatedIds: '+setRelatedIds);
            }
        }

        ilib_LogEvent.info('mapOwnerIdToRecIdsForShareRemoval: '+(!mapOwnerIdToRecIdsForShareRemoval.isEmpty() ? String.valueOf(mapOwnerIdToRecIdsForShareRemoval.keySet()) : 'map is empty'));
        if(!mapOwnerIdToRecIdsForShareRemoval.isEmpty()){
            removeSharingRecords(mapOwnerIdToRecIdsForShareRemoval);
        }

        ilib_LogEvent.info('mapOwnerIdToRecIdsForShareCreation: '+mapOwnerIdToRecIdsForShareCreation);
        if(!mapOwnerIdToRecIdsForShareCreation.isEmpty()){
            createShareRecords(mapOwnerIdToRecIdsForShareCreation);
        }
            
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();            //CMSI-208
    }
    /**
     * method name: createShareRecords
     * Description: Create Share records for all the related records for a Work order
     * param: Map of ownerId vs set of related recordIds
     * return: void
     */
    public static void createShareRecords(Map<Id, Set<Id>> mapUserIdToRelatedRecId){
        ilib_LogEvent.push(LOG_TITLE + '.createShareRecords()');
        List<sObject> lstShareRecordsToInsert = new List<sObject>();
        for(Id userId : mapUserIdToRelatedRecId.keySet()){
            Set<Id> setRelatedRecords = mapUserIdToRelatedRecId.get(userId);
            for(Id parentId : setRelatedRecords){
                lstShareRecordsToInsert.add(createGenericShareRecord(parentId, userId, STRING_READ, 'FS_Third_Party__c'));
            }
        }
        ilib_LogEvent.info('lstShareRecordsToInsert: '+UtilsCollection.getSetOfIds(lstShareRecordsToInsert));  //CMSI-208
        if(!lstShareRecordsToInsert.isEmpty()){
            List<Database.SaveResult> allResults = Database.insert(lstShareRecordsToInsert, false);
            ApexExceptions.emitSaveErrors(allResults, LOG_TITLE);
        }
        ilib_LogEvent.pop();
    }
    /**
     * method name: createGenericShareRecord
     * Description: Genneric method for constructing the share object and it's record based on the custom & standard object.
     * Parans: parentId, userId, accessLevel, row level cause
     * return: sObject
     */
    public static sObject createGenericShareRecord(Id parentId, Id userOrGroup, String shareLevel, String cause) {
        //get the object api name from the parentId
        String objName = parentId.getSObjectType().getDescribe().getName();
        
        //initialize the share object
        sObject objshare;
        // create share record for custom objects (i,e Installed products, parts orders)
        if(objName.endsWithIgnoreCase('__c')) {
            String objectName = objName.replace('__c','__Share');
            objshare = Schema.getGlobalDescribe().get(objectName).newSObject();
            objshare.put(STRING_PARENT_ID, parentId);
            objshare.put(STRING_ROW_CAUSE, cause);
            if(INSTALLED_PRODUCT_OBJECT.equals(objName)){
                objshare.put(STRING_ACCESS_LEVEL, STRING_EDIT);
            }else{
                objshare.put(STRING_ACCESS_LEVEL, shareLevel);
            }
        }else{
            //create share records for standard objects (i,e cases & accounts, contacts)
            String objectName = objName + STRING_SHARE;
            objshare = Schema.getGlobalDescribe().get(objectName).newSObject();

            //giving edit access to cases as there are some fields on the case record which are in sync from the work order.
            if(objName == CASE_OBJECT){
                objshare.put(objName + STRING_ACCESS_LEVEL,STRING_EDIT);
            }else{
                objshare.put(objName + STRING_ACCESS_LEVEL,shareLevel);
            }
            
            objshare.put(objName + STRING_ID, parentId);

            // AccountShare object has additional properties
            if(objName.equalsIgnoreCase(ACCOUNT_OBJECT)) {
                // need to add access levels for Contacts, Opps and Cases to Account.
                // if we require EDIT for these child relationships, change here.
                objshare.put(CONTACT_ACCESS_LEVEL, STRING_READ);
                objshare.put(CASE_ACCESS_LEVEL, STRING_NONE);
                objshare.put(OPPORTUNITY_ACCESS_LEVEL, STRING_NONE);
            }
        }
        // general data
        objshare.put(STRING_USER_OR_GROUP_ID, userOrGroup);
        return objshare;
    }
    /**
     * method name: removeSharingRecords
     * Description: delete Apex sharing records from the record IDs to the user IDs
     * params: map of ownerId vs set of related recordIds
     * return: void
     */
    public static void removeSharingRecords(Map<Id, Set<Id>> userIdToRecordIds){
        ilib_LogEvent.push(LOG_TITLE + '.removeSharingRecords()');
        //list of share records to remove
        List<SObject> sharesToRemove = new List<SObject>();
        //set of related recordIds based on object
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setPOIds = new Set<Id>();
        Set<Id> setInstalledProducts = new Set<Id>();

        //segregate based on the sbject type
        //and populate different sets
        for(Id userId : userIdToRecordIds.keySet()){
            for(Id recId : userIdToRecordIds.get(userId)){
                String objName = recId.getSObjectType().getDescribe().getName();
                if(objName == CASE_OBJECT){
                    setCaseIds.add(recId);
                }else if(objName == ACCOUNT_OBJECT){
                    setAccountIds.add(recId);
                }else if(objName == PARTS_ORDER_OBJECT){
                    setPOIds.add(recId);
                }else if(objName == INSTALLED_PRODCUCT_OBJECT){
                    setInstalledProducts.add(recId);
                }
            }    
        }

        //query share records for different related objects based on the sets populated.
        //- need to execute these queries in without sharing class as TPSP user doesn't have API enabled access.
        sharesToRemove = processCusomShares(setInstalledProducts, setPOIds, userIdToRecordIds);
        if(!setCaseIds.isEmpty()){
            List<CaseShare> lstCaseShare = [Select Id,CaseId,userOrgroupId from CaseShare where userOrgroupId in: userIdToRecordIds.keySet() and CaseId in: setCaseIds];
            ilib_LogEvent.info('lstCaseShare: '+UtilsCollection.getSetOfIds(lstCaseShare));
            for(CaseShare cShare : lstCaseShare){
                //check if this record is mapped for the user in this execution and add it to the sharestoRemove list.
                if(userIdToRecordIds.containsKey(cShare.UserOrGroupId) && userIdToRecordIds.get(cShare.UserOrGroupId).contains(cShare.CaseId)){
                    sharesToRemove.add(cShare);
                }
            }
        }
        if(!setAccountIds.isEmpty()){
            List<AccountShare> lstAcountShare = [Select Id,AccountId,userOrgroupId from AccountShare where userOrgroupId in:userIdToRecordIds.keySet() and AccountId in: setAccountIds];
            ilib_LogEvent.info('lstAcountShare: '+UtilsCollection.getSetOfIds(lstAcountShare));   //CMSI-208
            for(AccountShare aShare : lstAcountShare){
                if(userIdToRecordIds.containsKey(aShare.UserOrGroupId) && userIdToRecordIds.get(aShare.UserOrGroupId).contains(aShare.AccountId)){
                    sharesToRemove.add(aShare);
                }
            }
        }
        
        ilib_LogEvent.info('sharesToRemove: '+UtilsCollection.getSetOfIds(sharesToRemove));
        //Delete all the existing share records for which we need to remove access
        List<Database.DeleteResult> allResults = Database.delete(sharesToRemove, false);
        ApexExceptions.emitDeleteErrors(allResults, LOG_TITLE);
        ilib_LogEvent.pop();
    }
    /**
     * method name: getRelatedRecordIds
     * Description: Get all related record Ids for a given work order
     * params: work order record
     * return: set<Id>
     */
    private static Set<Id> getRelatedRecordIds(SVMXC__Service_Order__c objNewWO){
        Set<Id> setRelatedIds = new Set<Id>();
        if(objNewWO.SVMXC__Company__c != null){
            setRelatedIds.add(objNewWO.SVMXC__Company__c);
        }
        if(objNewWO.SVMXC__Component__c != null){
            setRelatedIds.add(objNewWO.SVMXC__Component__c);
        }
        if(objNewWO.SVMXC__Contact__c != null){
            setRelatedIds.add(objNewWO.SVMXC__Contact__c);
        }
        // INC0490755
        if(objNewWO.SVMXC__Service_Contract__c != null){
            setRelatedIds.add(objNewWO.SVMXC__Service_Contract__c);
        }
        // make sure we do not create a share for our record owner.
        if(objNewWO.SVMXC__Case__c != null && objNewWO.SVMXC__Case__r.OwnerId != objNewWO.OwnerId){
           setRelatedIds.add(objNewWO.SVMXC__Case__c);
        }
        //get all the parts orders which are in the related list
        for(SVMXC__RMA_Shipment_Order__c po : objNewWO.SVMXC__RMA_Shipment_Order__r){
            if(po.OwnerId != objNewWO.OwnerId){
                setRelatedIds.add(po.Id);
            }
        }
        return setRelatedIds;
    }
    /**
     * method name: populateShareMaps
     * Description: populate the maps for creaing/removing the share records
     * params:work order, set of related Ids
     */
    private static Map<Id, Set<Id>> populateShareMaps(SVMXC__Service_Order__c objWorkOrder,Set<Id> setRelatedIds){
        Map<Id, Set<Id>> mapOwnerIdToRecIds = new Map<Id, Set<Id>>();
        if(!mapOwnerIdToRecIds.containsKey(objWorkOrder.OwnerId)){
            mapOwnerIdToRecIds.put(objWorkOrder.OwnerId, new Set<Id>());
        }
        mapOwnerIdToRecIds.get(objWorkOrder.OwnerId).addAll(setRelatedIds);
        return mapOwnerIdToRecIds;
    }
    /**
    * Method namme: processCustomShares
    * Description: This method processes the custom share records and add all the share records which needs to be removed to a list.
                    - It is created to resolved the codescan error 
    * params: set of Installed Product ids, set of Parts order Ids
    * return: List of share record
     */
    private static List<sObject> processCusomShares(Set<Id> setInstalledProducts, set<Id> setPOIds, Map<Id, Set<Id>> userIdToRecordIds){
        ilib_LogEvent.push(LOG_TITLE + '.processCusomShares()');
        List<sObject> lstCustomShare = new List<sObject>();
        List<sObject> sharesToRemove = new List<sObject>();
        if(!setInstalledProducts.isEmpty()){
            List<SVMXC__Installed_Product__Share> lstIPShare = [Select Id,ParentId,userOrgroupId from SVMXC__Installed_Product__Share where userOrGroupId in: userIdToRecordIds.keySet() and parentId in: setInstalledProducts And RowCause = :Schema.SVMXC__RMA_Shipment_Order__Share.RowCause.FS_Third_Party__c];
            ilib_LogEvent.message('lstIPShare: '+lstIPShare);
            lstCustomShare.addAll(lstIPShare);
            
        }
        ilib_LogEvent.info('setPOIds: '+setPOIds);
        if(!setPOIds.isEmpty()){
            List<SVMXC__RMA_Shipment_Order__Share> lstPOShare = [Select Id,ParentId,userOrgroupId from SVMXC__RMA_Shipment_Order__Share where userOrgroupId in:userIdToRecordIds.keySet() and parentId in: setPOIds And RowCause = :Schema.SVMXC__RMA_Shipment_Order__Share.RowCause.FS_Third_Party__c];
            lstCustomShare.addAll(lstPOShare);    
        }
        
        for(sObject share : lstCustomShare){
            if(userIdToRecordIds.containsKey((Id)share.get(STRING_USER_OR_GROUP_ID)) && userIdToRecordIds.get((Id)share.get(STRING_USER_OR_GROUP_ID)).contains((Id)share.get(STRING_PARENT_ID))){
                sharesToRemove.add(share);
            }
        }
        ilib_LogEvent.pop();
        return sharesToRemove;

    }
}
/**
 *    @author KD
 *    @date   9-Sept-2020
 *    @description : Service class to handle sharing of plan records
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Akshay Mohan                  17-Sep-2020            DCP-41644: Change overlay sharing logic
 *    Ashwin Kumar                  26-Aug-2021            TASK0586014 - changing class to without sharing context to enable users to perform DML
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public without sharing class PlanShareService {
    public static String idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Overlay_Plan').getRecordTypeId();
    public static Map<String,List<Plan__c>> mapTerritoryCodeToPlan = new Map<String,List<Plan__c>>();
    public static Map<Id,List<Plan__c>> mapOwnerIdToPlan = new Map<Id ,List<Plan__c>>();
    public static Map<Id,List<Plan__c>> mapTerritoryIdToPlan = new Map<Id,List<Plan__c>>();
    public static Map<Id,String> mapParentIdToLeafNodeCode = new Map<Id,String>();
    public static Map<Id, List<Plan__c>> mapUserIdToPlan = new Map<Id, List<Plan__c>>();
    public static Map<Id, Set<Id>> mapTerritoryIdToUser = new Map<Id, Set<Id>>();
    public static Map<Id,Set<Id>> mapParentIdToUser = new Map<Id,Set<Id>>();
    /**
     * @author KD
     * @date   6-Spt-2020
     * @description  DCP-39107 Share plan records
     * @param List of plan records to share
     */
    public static void sharePlanRecords(List<Plan__c> lstPlans){
        mapTerritoryIdToPlan = new Map<Id,List<Plan__c>>();
        mapParentIdToLeafNodeCode = new Map<Id,String>();
        mapOwnerIdToPlan = new Map<Id ,List<Plan__c>>();
        generateMapofPlans(lstPlans);
        System.debug('mapOwnerIdToPlan -->'+mapOwnerIdToPlan);
        if(!mapOwnerIdToPlan.isEmpty()){
            generateTerritoryMapWithPlans();        
        }
        System.debug('mapTerritoryIdToPlan-->'+mapTerritoryIdToPlan );
        generateParentTerritoryMap();
        System.debug('mapParentIdToLeafNodeCode--->'+mapParentIdToLeafNodeCode);
        Set<Id> setTerritoryId = new Set<Id>();
        setTerritoryId.addAll(mapParentIdToLeafNodeCode.keySet());
        setTerritoryId.addAll(mapTerritoryIdToPlan.keySet());
        createShareRecords(setTerritoryId);
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to create map of owner and territory code with List of plan.
     * @param List Plan
     */
    public static void generateMapofPlans(List<Plan__c> lstPlans){
        for(Plan__c objPlan : lstPlans){
            if(objPlan.RecordTypeId != idOverlayRecordType && String.isNotBlank(objPlan.Territory_Code__c)){
                if(!mapTerritoryCodeToPlan.containsKey(objPlan.Territory_Code__c))
                    mapTerritoryCodeToPlan.put(objPlan.Territory_Code__c,new List<Plan__c>());
                mapTerritoryCodeToPlan.get(objPlan.Territory_Code__c).add(objPlan);
                if(String.isNotBlank(objPlan.Channel_Partner_Territory_Code__c)){
                    if(!mapTerritoryCodeToPlan.containsKey(objPlan.Channel_Partner_Territory_Code__c))
                        mapTerritoryCodeToPlan.put(objPlan.Channel_Partner_Territory_Code__c,new List<Plan__c>());
                    mapTerritoryCodeToPlan.get(objPlan.Channel_Partner_Territory_Code__c).add(objPlan);
                }
            }
            else if(objPlan.RecordTypeId == idOverlayRecordType){
                if(!mapOwnerIdToPlan.containsKey(objPlan.OwnerId))
                    mapOwnerIdToPlan.put(objPlan.OwnerId,new List<Plan__c>());
                mapOwnerIdToPlan.get(objPlan.OwnerId).add(objPlan);
            }
        }
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to create map of Territory Id to List of plan; keyset will be used to fetch UTA
     * @param 
     */ 
    public static void generateTerritoryMapWithPlans(){//DCP-41644
        System.debug('UTA for user-->'+ new UserTerritory2AssociationSelector().selectOnlyDirectByUserId(mapOwnerIdToPlan.keySet()));
        for(UserTerritory2Association objUTA : new UserTerritory2AssociationSelector().selectOnlyDirectByUserId(mapOwnerIdToPlan.keySet())){
            if(!mapTerritoryIdToPlan.containsKey(objUTA.Territory2Id))
                mapTerritoryIdToPlan.put(objUTA.Territory2Id,new List<Plan__c>());
            mapTerritoryIdToPlan.get(objUTA.Territory2Id).addAll(mapOwnerIdToPlan.get(objUTA.UserId));
        }
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to create map of Parent Territory Id to leaf node code
     * @param 
     */
    public static void generateParentTerritoryMap(){
        List<Territory2> lstTerritories = new TerritoriesSelector().getByTerritoryCode(mapTerritoryCodeToPlan.keySet());
        for(Territory2 objTr : lstTerritories){
            mapParentIdToLeafNodeCode.put(objTr.id,objTr.Territory_Code__c);
            if(String.isNotBlank(objTr.ParentTerritory2Id))
                mapParentIdToLeafNodeCode.put(objTr.ParentTerritory2Id,objTr.Territory_Code__c);
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToLeafNodeCode.put(objTr.ParentTerritory2.ParentTerritory2Id,objTr.Territory_Code__c);
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToLeafNodeCode.put(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,objTr.Territory_Code__c);
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToLeafNodeCode.put(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,objTr.Territory_Code__c);
        }
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to Insert share records for created plan based on hierarchy
     * @param 
     */
    public static void createShareRecords(Set<Id> setTerritoryId){
        System.debug('--- List of territory to reshare--'+setTerritoryId);
        List<Plan__share> lstPlanShare = new List<Plan__share>();
        for(Group objGr : new GroupsSelector().getIdByRelatedBy(setTerritoryId)){
            if(objGr.Type == GroupsSelector.GROUP_TYPE_TERRITORY && mapParentIdToLeafNodeCode.containsKey(objGr.RelatedId)){
                for(Plan__c objPlan : mapTerritoryCodeToPlan.get(mapParentIdToLeafNodeCode.get(objGr.RelatedId))){
                    lstPlanShare.add(new Plan__Share(
                        UserOrGroupId = objGr.Id,
                        ParentId = objPlan.Id,
                        AccessLevel = 'Edit',
                        RowCause = Schema.Plan__Share.RowCause.Manual)
                    );
                }
            }
            else if(objGr.Type == GroupsSelector.GROUP_TYPE_TERRITORY_SUB && mapTerritoryIdToPlan.containsKey(objGr.RelatedId)){
                for(Plan__c objPlan : mapTerritoryIdToPlan.get(objGr.RelatedId)){
                    lstPlanShare.add(new Plan__Share(
                        UserOrGroupId = objGr.Id,
                        ParentId = objPlan.Id,
                        AccessLevel = 'Edit',
                        RowCause = Schema.Plan__Share.RowCause.Manual)
                    );
                }
            }
        }
        Database.SaveResult[] lstSaveResult = Database.insert(lstPlanShare,false);
        ApexExceptions.emitSaveErrors(lstSaveResult, 'PlanShareService');
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to reshare plan records if user is added or removed
     * @param List UserTerritory2Association added or removed
     */
    public static void reSharePlanRecords(List<UserTerritory2Association> lstDeletedRecords){
        Map<Id,Id> mapUserIdToTerritoryId = UtilsCollection.getMapOfIdToId(lstDeletedRecords,'UserId','Territory2Id');
        generateMapofPlansForDeletedUser(mapUserIdToTerritoryId);
        System.debug('mapTerritoryIdToUser--->'+mapTerritoryIdToUser);
        if(mapTerritoryIdToUser.isEmpty())
            return;
        generateParentTerritoryMapWithUser();
        for(UserTerritory2Association objUTA : new UserTerritory2AssociationSelector().selectByTerritoryId(mapParentIdToUser.keySet())){
            if(mapParentIdToUser.get(objUTA.Territory2Id).contains(objUTA.UserId))
                mapUserIdToPlan.remove(objUTA.UserId);
        }
        if(mapUserIdToPlan.isEmpty())
            return;
        List<Plan__c> lstPlanToShare = new List<Plan__c>();
        for(List<Plan__c> lstPlan :mapUserIdToPlan.values()){
            lstPlanToShare.addAll(lstPlan);
        }
        // Queueable interface was not used due to Mixed DML error
        System.enqueueJob(new PlanShareServiceHelper(lstPlanToShare));
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to generate map for plan owned by removed/added user
     * @param 
     */
    public static void generateMapofPlansForDeletedUser(Map<Id,Id> mapUserIdToTerritoryId){
        for(Plan__c objPlan : new PlanSelector().getAllPlanbyOwnerandRecordId(mapUserIdToTerritoryId.keySet(),idOverlayRecordType)){
            if(!mapUserIdToPlan.containsKey(objPlan.OwnerId))
                mapUserIdToPlan.put(objPlan.OwnerId,new List<Plan__c>());
            mapUserIdToPlan.get(objPlan.OwnerId).add(objPlan);
            if(!mapTerritoryIdToUser.containsKey(mapUserIdToTerritoryId.get(objPlan.OwnerId)))
                mapTerritoryIdToUser.put(mapUserIdToTerritoryId.get(objPlan.OwnerId),new Set<Id>());
            mapTerritoryIdToUser.get(mapUserIdToTerritoryId.get(objPlan.OwnerId)).add(objPlan.OwnerId);
        }
    }
    /**
     * @author KD
     * @date   6-Sept-2020
     * @description  DCP-39107 Logic to generate map for parent territory with Set of user id
     * @param 
     */
    public static void generateParentTerritoryMapWithUser(){
        for(Territory2 objTr : new TerritoriesSelector().getByTerritoryId(mapTerritoryIdToUser.keySet())){
            if(String.isNotBlank(objTr.ParentTerritory2Id))
                mapParentIdToUser.put(objTr.ParentTerritory2Id,new Set<Id>(mapTerritoryIdToUser.get(objTr.Id)));
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToUser.put(objTr.ParentTerritory2.ParentTerritory2Id,new Set<Id>(mapTerritoryIdToUser.get(objTr.Id)));
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToUser.put(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,new Set<Id>(mapTerritoryIdToUser.get(objTr.Id)));
            if(String.isNotBlank(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                mapParentIdToUser.put(objTr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,new Set<Id>(mapTerritoryIdToUser.get(objTr.Id)));
        }
    }
    /**
     * @author KD
     * @date   6-Spt-2020
     * @description  DCP-39107 Delete existing sharing for plna
     * @param List of plan share records to share
     */
    public static void deleteExistingSharing(List<Plan__Share> lstPlanshare){
        List<Database.DeleteResult> lstDeleteResult = Database.delete(lstPlanshare, false);
        ApexExceptions.emitDeleteErrors(lstDeleteResult,'PlanShareServiceHelper');
    }
}
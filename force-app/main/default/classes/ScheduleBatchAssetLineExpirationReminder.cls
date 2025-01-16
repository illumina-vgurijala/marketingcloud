/**
*    @author Ashwin Kumar
*    @date   2021-07-20
*    @description   TASK0587523 : Schedule Asset Line Item Expiration Reminder Emails
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*    Version    Developer               Date(YYYY-MM-DD)        Description
*    1.0        Ashwin                  2021-08-23              Initial Version
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ScheduleBatchAssetLineExpirationReminder extends ilib_ScheduleAndBatch {

    private static final String LOG_TITLE = 'ScheduleBatchAssetLineExpirationReminder';
    public static final String SALES_REP_CONTRACT_SPL_ROLE = 'Inside Sales Representative - Service Contract Specialists';

    /**
     * @author Ashwin
     * @description execute method of Scheduler
     **/
    public override void execute(SchedulableContext sc) {
        Database.executeBatch(new ScheduleBatchAssetLineExpirationReminder());
    }

    /**
     * @author Ashwin
     * @description start method of Batch
     **/
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        String strOppRTIndirectReOrder = Label.IndirectReOrder;
        String strOppRTDirectReOrder = Label.OpportunityRTDirectReOrder;
        String pendingRenewalStatus = 'Pending Renewal';
        String strQuery = 'SELECT Id, Apttus_Config2__AccountId__c, Days_Before_Expiry__c, Apttus_Config2__AssetStatus__c'
                         +' FROM Apttus_Config2__AssetLineItem__c'
                         +' WHERE Apttus_Config2__AccountId__c != null AND Days_Before_Expiry__c != null AND'
                         +' ((Days_Before_Expiry__c = 60 AND Apttus_Config2__AssetStatus__c != :pendingRenewalStatus AND Apttus_QPConfig__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName NOT IN (:strOppRTIndirectReOrder, :strOppRTDirectReOrder))'
                         +' OR (Days_Before_Expiry__c = 90 AND Apttus_Config2__AssetStatus__c != :pendingRenewalStatus AND Apttus_QPConfig__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName NOT IN (:strOppRTIndirectReOrder, :strOppRTDirectReOrder))'
                         +' OR Days_Before_Expiry__c = 120)';
        return Database.getQueryLocator(strQuery);
    }

    /**
     * @author Ashwin
     * @description execute method of Batch
     **/
    public override void execute(Database.BatchableContext bc,  List<SObject> scope) {
        try {
            if(scope.isEmpty()) {return;}
            ilib_LogEvent.push(LOG_TITLE + '.execute()');
            
            Map<Id, Id> mapAssetIdToAccId = new Map<Id, Id>();

            for(Apttus_Config2__AssetLineItem__c objALI : (List<Apttus_Config2__AssetLineItem__c>) scope) {
                mapAssetIdToAccId.put(objALI.Id, objALI.Apttus_Config2__AccountId__c);
            }
            ilib_LogEvent.message('Map Asset Id to Account Id - size: '+mapAssetIdToAccId.size());

            Map<Id, Id> mapAccIdToTerritory2Id = buildMapAccIdToTerritory2Id(mapAssetIdToAccId);
            Map<Id, List<Id>> mapTerritory2IdToUserIds = buildMapTerritory2IdToUserIds(mapAccIdToTerritory2Id);
            Map<Id, List<Id>> mapAssetIdToRecipientIds = buildMapAssetIdToRecipientIds(mapAssetIdToAccId, mapAccIdToTerritory2Id, mapTerritory2IdToUserIds);
            
            if(!mapAssetIdToRecipientIds.isEmpty()) {
                ilib_LogEvent.message('Map Asset Id to List of User IDs - size: '+mapAssetIdToRecipientIds.size());
                AssetExpirationReminderController.sendEmailOnRenewalExpiration(mapAssetIdToRecipientIds);
            }
            ilib_LogEvent.pop();
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE + '.execute()', ex);
        }
    }

    /**
     * @author Ashwin
     * @description finish method of Batch
     **/
    public override void finish(Database.BatchableContext bc) {}

    /**
     * @author Ashwin
     * @description method to prepare Account Id to Territory Id map
     **/
    public Map<Id, Id> buildMapAccIdToTerritory2Id(Map<Id, Id> mapAssetIdToAccId) {
        Map<Id, Id> mapAccIdToTerritory2Id = new Map<Id, Id>();
        List<ObjectTerritory2Association> lstObjectTerritory2Association = new ObjectTerritory2AssociationsSelector().selectOnlyDirectByAccountId(mapAssetIdToAccId.values());
        for(ObjectTerritory2Association eachObjTerritory2Assoc : lstObjectTerritory2Association) {
            mapAccIdToTerritory2Id.put(eachObjTerritory2Assoc.ObjectId, eachObjTerritory2Assoc.Territory2Id);   // 1 Account will have only 1 Direct Territory
        }
        return mapAccIdToTerritory2Id;
    }
    
    /**
     * @author Ashwin
     * @description method to prepare Territory2Id to List of UserIds map
     **/
    public Map<Id, List<Id>> buildMapTerritory2IdToUserIds(Map<Id, Id> mapAccIdToTerritory2Id) {
        Map<Id, List<Id>> mapTerritory2IdToUserIds = new Map<Id, List<Id>>();
        List<UserTerritory2Association> lstUserAssociations = new UserTerritory2AssociationSelector().selectUsersByTerritoriesAndRoles(new Set<Id>(mapAccIdToTerritory2Id.values()), new List<String> {SALES_REP_CONTRACT_SPL_ROLE} );
        for(UserTerritory2Association eachUserTerritory2Assoc : lstUserAssociations) {
            if(!mapTerritory2IdToUserIds.containsKey(eachUserTerritory2Assoc.Territory2Id)) {
                mapTerritory2IdToUserIds.put(eachUserTerritory2Assoc.Territory2Id, new List<Id>());
            }
            mapTerritory2IdToUserIds.get(eachUserTerritory2Assoc.Territory2Id).add(eachUserTerritory2Assoc.UserId);
        }
        return mapTerritory2IdToUserIds;
    }

    /**
     * @author Ashwin
     * @description method to prepare final map - Asset Id to list of email recipient Ids
     **/
    public Map<Id, List<Id>> buildMapAssetIdToRecipientIds(Map<Id, Id> mapAssetIdToAccId, Map<Id, Id> mapAccIdToTerritory2Id, Map<Id, List<Id>> mapTerritory2IdToUserIds) {
        Map<Id, List<Id>> mapAssetIdToRecipientIds = new Map<Id, List<Id>>();
        for(Id idALI : mapAssetIdToAccId.keySet()) {
            if(mapAccIdToTerritory2Id.containskey(mapAssetIdToAccId.get(idALI)) && 
                mapTerritory2IdToUserIds.containsKey(mapAccIdToTerritory2Id.get(mapAssetIdToAccId.get(idALI)))) {
                    mapAssetIdToRecipientIds.put(idALI, mapTerritory2IdToUserIds.get(mapAccIdToTerritory2Id.get(mapAssetIdToAccId.get(idALI))));
            }
        }
        return mapAssetIdToRecipientIds;
    }
}
/**
 *    @author KD
 *    @date   5-Nov-2020
 *    @description : Queueablee class to handle sharing off CP Quota records
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
  *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CPQuotaSharingQueueableService extends ilib_PartnerSharing{
    public static Boolean boolIsContactUpdate = false;
    public static Set<Id> setNewUserId = new Set<Id>();
    public List<Channel_Partner_Quota__Share> lstQuotaShare = new List<Channel_Partner_Quota__Share>();
    /*
    * Description : override method to return instance of class
    */
    public override ilib_PartnerSharing getInstance(){
        return new CPQuotaSharingQueueableService();
    }
    /*
    * Description : override method to return object type
    */
    public override SObjectType getShareObjectType(){
        return Channel_Partner_Quota__Share.sObjectType;
    }
    /*
    * Description : override method to return parent field on share object
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description business logic to share all CP QQuota with updated/New user
    */
    public override void runBusinessSharingLogic(){
        System.debug('runBusinessSharingLogic CPQuotaSharingQueueable');
        Map<Id,Id> mapUserIdtoAccountId = new Map<Id,Id>();
        for(User objUser : new UsersSelector().getActiveUsers(setPartnerUserId)){
            mapUserIdtoAccountId.put(objUser.id,objUser.AccountId);
        }
        List<Channel_Partner_Quota__c> lstCPQuota = new ChannelPartnerQuotaSelector().getQuotaByAccount(mapUserIdtoAccountId.values());
        Map<Id,List<Id>> mapAccountIdToCPid = new Map<Id,List<Id>>();
        for(Channel_Partner_Quota__c objCPQuota : lstCPQuota){
            if(!mapAccountIdToCPid.containsKey(objCPQuota.Account_Name__c))
                mapAccountIdToCPid.put(objCPQuota.Account_Name__c,new List<Id>());
            mapAccountIdToCPid.get(objCPQuota.Account_Name__c).add(objCPQuota.id);
        }
        for(Id objUserId : mapUserIdtoAccountId.keyset()){
            if(mapAccountIdToCPid.containsKey(mapUserIdtoAccountId.get(objUserId))){
                for(Id idQuotaId : mapAccountIdToCPid.get(mapUserIdtoAccountId.get(objUserId))){
                    lstQuotaShare.add(createShareRecords(objUserId,idQuotaId));
                }
            }
        }
        if(!lstQuotaShare.isEmpty())
            insert lstQuotaShare;  
    }
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description method to create Quota share records.
    */
    public Channel_Partner_Quota__Share createShareRecords(Id idUserId,Id idRecordId){
         return new Channel_Partner_Quota__Share(
                            UserOrGroupId = idUserId,
                            ParentId = idRecordId,
                            AccessLevel = 'Read',
                            RowCause = Schema.Plan__Share.RowCause.Manual);
    }
}
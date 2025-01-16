/**
 *    @author KD
 *    @date   5-Nov-2020
 *    @description : Handler class for ChannelPartnerQuotaTrigger
 *    @Test Class for above 90% coverage.
 *    -TestChannelPartnerQuotaAutomation
 *    @Test Class for atleast 75% coverage.
      -TestChannelPartnerQuotaAutomation
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Kd                             5-Nov-2020            Inital Version
 *    Himanshu                       29-Mar-2022           Code Scan Fixes 
 *    Koustubh M                  22-May-2022            TASK0748834 Added TAPS_Orchestrator.recalculateRecordChanges() for TAPS sharing
 *  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ChannelPartnerQuotas extends ilib_SObjectDomain {
    /** 
     * @description  Constructor
     * @param List of Channel_Partner_Quota__c
     */
    public ChannelPartnerQuotas(List<Channel_Partner_Quota__c> sObjectList)
    {
        super(sObjectList);
    }
    /** 
    * @description  implements ilib_SObjectDomain.IConstructable
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /** 
         * @description  construct method
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ChannelPartnerQuotas(sObjectList);
        }
    }
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description Method onAfterInsert of ChannelPartnerQuotas
    */
    public override void onAfterInsert(){
        Map<Id,List<Id>> mapAccountIdToCPid = new Map<Id,List<Id>>();
        for(Channel_Partner_Quota__c objCP : (List<Channel_Partner_Quota__c>)records){
            if(!mapAccountIdToCPid.containsKey(objCP.Account_Name__c))
                mapAccountIdToCPid.put(objCP.Account_Name__c,new List<Id>());
            mapAccountIdToCPid.get(objCP.Account_Name__c).add(objCP.id);
        }
        shareCPQuota(mapAccountIdToCPid);    
        //Added for TASK0748834
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());
    }
     /**
    * @author Kd
    * @description method to insert Channel_Partner_Quota__Share records that is called in onAfterInsert method
    * @params Map<Id,List<Id>> mapAccountIdToCPid
    * @return void
    */
    public void shareCPQuota(Map<Id,List<Id>> mapAccountIdToCPid){
        for(Account objAcc : new AccountsSelector().selectLoggedInAccountList(new List<Id>(mapAccountIdToCPid.keyset()))){
            System.Debug('-->1'+objAcc.IsPartner);
            if(!objAcc.IsPartner)
                mapAccountIdToCPid.remove(objAcc.Id);
        }
        System.Debug('-->'+mapAccountIdToCPid);
        if(!mapAccountIdToCPid.isEmpty()){
            List<Channel_Partner_Quota__Share> lstQuotaShare = new List<Channel_Partner_Quota__Share>();
            List<User> lstPartnerUser = new UsersSelector().getAssociatedPartnerUser(mapAccountIdToCPid.keyset());
            CPQuotaSharingQueueableService objCPQuotaSharingQueueable = new CPQuotaSharingQueueableService();
            for(User objUsr : lstPartnerUser){
                for(Id idQuotaId : mapAccountIdToCPid.get(objUsr.contact.AccountId)){
                    lstQuotaShare.add(objCPQuotaSharingQueueable.createShareRecords(objUsr.Id,idQuotaId));
                }
            }
            if(!lstQuotaShare.isEmpty())
                insert lstQuotaShare; 
        }    
    }
}
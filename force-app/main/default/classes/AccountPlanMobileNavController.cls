/*
 * Class for AccountPlanMobileNavController class
 */
public with sharing class AccountPlanMobileNavController {
    @AuraEnabled 
    /*
     * Check current session cache
     */
    public static void checkSessionCache(String recordId){
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.AccountPlanVariables');
        sessionPart.put('AccountPlanId',recordId,3600,Cache.Visibility.ALL, true);
    }
    @AuraEnabled 
    /*
     * Return current session cache
     */
    public static Account_Plan__c getSessionCache(){
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.AccountPlanVariables');
        if(sessionPart.contains('AccountPlanId')){
           String accountPlanId=(String)sessionPart.get('AccountPlanId');
            //return (String)sessionPart.get('AccountPlanId');
             List<Account_Plan__c>listAccPlan=new AccountPlanSelector().getAccountPlanByIds(new Set<ID>{accountPlanId});
           system.System.debug('see'+listAccPlan);
            return listAccPlan[0];
        }
        system.debug('Misses if');
        return null;
    }

}
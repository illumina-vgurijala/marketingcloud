/**
 *    @author Anisha
 *    @date   28-July-2020
 *    @description  class for ViewActivePlansTerritory Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
 *   
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class ViewActivePlansTerritoryController {
    /**
    *   @author KD
    *   @description method to fetch all active account plan
    *   @param plan id
    **/
    @AuraEnabled(cacheable = true)
    public static String initRecords(String recordId){
        try{
            List<AccountPlanWrapper> wrapAccountList = new List<AccountPlanWrapper>();
            List<Plan__c> territoryPlan = new PlanSelector().getTerritoryPlanbyId(recordId);
            String strTerritoryId=territoryPlan[0].Territory_Id__c;
    		set<Id> setRelatedAccount = new set<Id>();
            for(ObjectTerritory2Association objObjectTerritory2Association : new ObjectTerritory2AssociationsSelector().selectByTerritoryId(new set<Id>{(Id)strTerritoryId})  )
            {
                setRelatedAccount.add(objObjectTerritory2Association.objectId);
            }
    		List<Account_Plan__c> listActiveAccPlan = new AccountPlanSelector().getActiveAccountPlanByAccountIds(setRelatedAccount,'Active');
            for(Account_Plan__c lstActiveAccPlan : listActiveAccPlan)
            { 
                wrapAccountList.add(new AccountPlanWrapper(lstActiveAccPlan) );
            }
            Map<String,String> mapLabels = new Map<String,String>();
            mapLabels.put('UI_Label_Active_Account_Plan',Label.UI_Label_Active_Account_Plan);
            mapLabels.put('UI_Error_No_Active_Account_Plan',Label.UI_Error_No_Active_Account_Plan);
            mapLabels.put('UI_Agreement_Generate_Failed',Label.UI_Agreement_Generate_Failed);
            return '{"wrapAccountList": '+JSON.serialize(wrapAccountList)+','
                    +' "mapLabels": '+JSON.serialize(mapLabels)+'}';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *   @author KD
    *   @description Wrapper class for account plan
    **/
    public class AccountPlanWrapper{
        public string AccountPlanName ,AccountPlanId ,OwnerId , OwnerName ;
        public Decimal PlanTarget;
        /**
        *   @author KD
        *   @description Wrapper class Constructor
        **/
        public AccountPlanWrapper(Account_Plan__c acc){
            this.AccountPlanId = '/'+acc.Id;
            this.AccountPlanName = acc.Name;
            this.OwnerName = acc.Owner.Name;
            this.OwnerId  = '/'+acc.Owner;
            this.PlanTarget = acc.Plan_Target__c;
        }
}
}
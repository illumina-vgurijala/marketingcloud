/**
*    @author: Kushagra Desai
*    @date:   07-AUg-2019
*    @description:  Controller class for NewAccountPLan Component
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
              Kushagra Desai               8-Aug-2019            DCP-27437 - Query all active Account Plan (getActivePlans)
              Atit Kar                     9-Dec-2022            INC0442456 - Populate Territory_Region__c field on Account Plan Object
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class NewAccountPlanController {
    /**
    *  @author Kushagra Desai
    *  @description To get the Account Object Details for given Account Id
    *  @param AccountId- Id of Account
    *  @return Account
    **/
    @AuraEnabled
    public static String getAccountDetails(String accountId){
        Map<String, String> mapAccountData = new Map<String, String>(); //INC0442456-start
        Account acc = new AccountsSelector().selectLoggedInAccountForUser(accountId)[0];
        mapAccountData.put('AccountName', acc.Name);
        mapAccountData.put('TerritoryRegion', acc.Territory_Region__c);
        return JSON.Serialize(mapAccountData); //INC0442456-end
    }
    /**
    *  @author Kushagra Desai
    *  @description Check for any active plan
    *  @param AccountId- Id of Account
    *  @return Boolean check for active account plan
    **/
    @AuraEnabled
    public static Boolean getActiveplan(String accountId){
        List<Account_Plan__c> lstAcc = new AccountPlanSelector().getAccountPlan(accountId,'Active');
        return lstAcc.isempty();
    }

}
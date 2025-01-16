/**
 *    @author         : KD
 *    @date           :
 *    @description    : Test class to create data for Account Plan
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestDataAccountPlan {

    /**
     *  @author      : KD
     *  @description : Method to create Account Plan through the account record
     *  @param       : Account
     *  @return      : Account_Plan__c
    */
    public static Account_Plan__c getNewAccountPlan(Account a) {
        Account_Plan__c ap  = initAccoutPlan(a.Id);
        insert ap;
        return ap;
    }
    /**
     *  @author      : KD
     *  @description : Method to create Account Plan through the Id of the account record
     *  @param       : Id
     *  @return      : Account_Plan__c
    */
    public static Account_Plan__c initAccoutPlan(String accId){
        Account_Plan__c ap =  new Account_Plan__c();
        ap.Name = 'Test Account Plan';
        ap.Account_Name__c = accId;
        //ap.Plan_Creation_Level__c = 'Global';
        ap.Start_Date__c = system.today();
        return ap;
    }

    
}
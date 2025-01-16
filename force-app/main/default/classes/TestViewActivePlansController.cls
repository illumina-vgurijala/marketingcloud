/**
*    @author: Vaibhav Sirohi
*    @date:   13-AUg-2019
*    @description:  Test class for Controller class of ViewActivePlansController Component
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
            Joshith K                       26-sep-2019         coverage increased
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestViewActivePlansController {
     /**
     *  @author Vaibhav Sirohi
     *  @description  
     **/
    @isTest
    static void testGetActiveAccount()
    {
        Test.startTest();
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        List<UserTerritory2Association> lstUserterritory  = [SELECT id, Territory2.Name from UserTerritory2Association where Territory2Id !=null Limit 1];
        acc.Territory_Name__c = lstUserterritory[0].Territory2.Name;
        update acc;
        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(acc);
        Test.stopTest();
        ViewActivePlansController.initRecords('Account_Plan__c', 'Name,Account_Name__r.Name,Owner.Name,Start_Date__c,LastModifiedDate', ap.Id);
        System.assertEquals(5, ViewActivePlansController.initRecords('Account_Plan__c', 'Name,Account_Name__r.Name,Owner.Name,Start_Date__c', ap.Id).lstFields.size());
    }
}
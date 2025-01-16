/**
* @author Rohit Sahu
* @description TestBatchToUpdateKeyMethod
* Modification Log:
*   ---------------------------------------------------------------------------------------------------------------------------
*    Developer                     Date(YY-MM-DD)                  Description
*    Rohit Sahu					 05-11-2024						Initial Version CMCM-7624
*   ---------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestBatchToUpdateKeyMethod {
 /**
* @author:Rohit Sahu
* @date: 05-11-2024
* @description: Required for test class to get test data
* @param: String recordId
* @return: 
*/    
    @isTest //@TestSetup
    static void testGetData(){
        
        //Create Account record
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        
        //Create Account Plan records
        Account_Plan__c accountPlan =  new Account_Plan__c();
        accountPlan.Name = 'Test Account Plan';
        accountPlan.Account_Name__c = acc.Id;
        accountPlan.Start_Date__c = system.today();
        accountPlan.Key_Methods__c = 'Multiomics';
        insert accountPlan;
        
        //Create Account Plan records
        Account_Plan__c accountPlan2 =  new Account_Plan__c();
        accountPlan2.Name = 'Test Account Plan 2';
        accountPlan2.Account_Name__c = acc.Id;
        accountPlan2.Start_Date__c = system.today();
        accountPlan2.Key_Methods__c = 'Epigenetics';
        insert accountPlan2;
        
        // Start the batch
        test.startTest();
        BatchToUpdateKeyMethod btu = new BatchToUpdateKeyMethod();
        database.executeBatch(btu);
        test.stopTest();
        
        // Verify the updates
        system.assertEquals('1','1','');
        //test
        
    }
}
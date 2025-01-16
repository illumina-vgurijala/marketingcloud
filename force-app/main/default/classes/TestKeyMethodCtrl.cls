/**
*    @author: Rohit sahu
*    @date:   03-May-2024
*    @description:  Test class for Controller class of Component keyMethod
*    Modification Log:
*    -----------------------------------------------------------------------------------
*      Developer                      Date                Description
*     Rohit sahu                   03-May-2024          CMCM-7575 UI Update to remove key methods fields from Account Plan & add component link
*    ----------------------------------------------------------------------------------------
*                    
*/
@isTest
public class TestKeyMethodCtrl {
    /**
* @description:Test method for code cover insert new records.
* @param : String recordId
* @return : kList
*/
    @isTest
    static void testGetKeyMethod() {
        
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        
        // Insert the account plan record
        Account_Plan__c accPlan = TestDataAccountPlan.getNewAccountPlan(acc);
        
        Key_Method__c testKeyMethod = new Key_Method__c(
            Key_Method__c = 'NIPT',
            Estimated_Annual_Sample_Volume__c = 100,
            Account_Plan__c = accPlan.Id
        );
        insert testKeyMethod;
        
        // Call the method to be tested
        Test.startTest();
        List<Key_Method__c> result = KeyMethodCtrl.getKeyMethod(accPlan.Id);
        Test.stopTest();
        
        // Assert the result
        System.assertEquals(1, result.size(), 'Expected one key method record');
        Key_Method__c returnedKeyMethod = result[0];
        System.assertEquals(testKeyMethod.Id, returnedKeyMethod.Id, 'Key method ID should match');
        System.assertEquals(testKeyMethod.Key_Method__c, returnedKeyMethod.Key_Method__c, 'Key method field should match');
        System.assertEquals(testKeyMethod.Estimated_Annual_Sample_Volume__c, returnedKeyMethod.Estimated_Annual_Sample_Volume__c, 'Estimated annual sample volume should match');
        System.assertEquals(testKeyMethod.Account_Plan__c, returnedKeyMethod.Account_Plan__c, 'Account plan ID should match');
    }
    
    /**
* @description: Test method for code cover error record.
* @param : String recordId
* @return : kList
*/
    
    @isTest
    public static void testGetKeyMethodExc() {
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        Account_Plan__c accPlan = TestDataAccountPlan.getNewAccountPlan(acc);
        Test.startTest();
        List<Key_Method__c> result = KeyMethodCtrl.getKeyMethod(accPlan.Id);
        Test.stopTest();
       
        // Assert the result
        System.assertEquals(0, result.size(), 'Expected Zero record');
        
    }
    
}
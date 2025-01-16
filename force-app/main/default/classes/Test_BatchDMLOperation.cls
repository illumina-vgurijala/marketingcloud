/*
*    @author: Rajbabu Boopalan 
*    @description: Class used for batch create
*    Modification Log:
*   ----------------------------------------------------------------------------------------
*    Developer                      Date                    Description
*    Rajbabu Boopalan               2024-Mar-05             Initial Version
*    ---------------------------------------------------------------------------------------                  
*/
@isTest
private class Test_BatchDMLOperation {
    // Test method to cover batch execution
    @isTest
    static void testMethodBatchDMLOperation() {
       // Create test data - list of records to be processed
       List<Account> testAccounts = new List<Account>();
       for(Integer i = 0; i < 200; i++) {
           Account account1 = TestDataAccount.getCustomerAccount();
           account1.Name = '00'+i;
           testAccounts.add(account1);
        }
        
        // Create some accounts that will cause errors during insertion
        Account errorAccount1 = new Account(Name = 'ErrorAccount1');
        Account errorAccount2 = new Account(); 	// This will cause a required field missing error

        // Add the error accounts to the test data
        testAccounts.add(errorAccount1);
        testAccounts.add(errorAccount2);
        
        Test.startTest();
        // Instantiate the batch class with the test data
        BatchDMLOperation batchDMLOper = new BatchDMLOperation(testAccounts, BatchDMLService.dmlOperation.DML_INSERT);
        // Execute the batch
        Database.executeBatch(batchDMLOper, 500);
        //case-2 upsert
        BatchDMLOperation batchDMLOperUpsert = new BatchDMLOperation(testAccounts, BatchDMLService.dmlOperation.DML_UPSERT);
        Database.executeBatch(batchDMLOperUpsert, 500);
        Test.stopTest();
        
       // Check that the expected number of accounts (excluding the error accounts) are created
       List<Account> createdAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE '00%'];
       System.assertEquals(200, createdAccounts.size(), 'Expected number of accounts not created');
    }
}
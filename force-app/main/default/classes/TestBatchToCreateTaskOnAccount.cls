/*@ author       : Maruthi B
* @ date         : 17-02-2022
* @ Description  : PM-36: Test class for BatchToCreateTaskOnAccount
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Maruthi               17-02-2022                 Initial version
 */
@isTest
public with sharing class TestBatchToCreateTaskOnAccount {

    /**
    * @author Maruthi
    * @date   15-Feb-2022
    * @description  This method to cover BatchToCreateTaskOnAccount batch
    */
    @isTest
    public static void testupdateRQContactCompliant() {
      
        User testUser = TestDataUser.findUserInProfile('System Administrator');
        System.runAs(testUser)
        {
            //Create Account
            List<Account> listAccObj = new List<Account>();
            Account objAccount = TestDataAccount.getCustomerAccount();
            objAccount.R_Q_Contact_Compliant__c = 'Non Compliant';
            objAccount.OwnerId = testUser.Id;
            listAccObj.add(objAccount);
            Insert listAccObj;            
            
            List<SObject> sobjAcc = (List<SObject>)listAccObj;
            Test.startTest();                  	
                SchedulableContext ctx;
                BatchToCreateTaskOnAccount batchObj = new BatchToCreateTaskOnAccount();        
                batchObj.execute(ctx);
                Database.executeBatch(batchObj);
            	batchObj.execute(null,sobjAcc);
            	List<Task> tsk = [Select id from Task where WhatId =: listAccObj[0].Id];            	
                System.assertEquals(1,tsk.size(),'BatchAccountSetRQContactCompliant');  
            Test.stopTest();
        }
    }
        
}
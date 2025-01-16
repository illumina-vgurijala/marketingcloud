/**
 * @author Saurabh Brahmankar
 * @description Test BatchToUpdateAccountFieldsPFASandPFSE
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Saurabh Brahmankar			2024-03-07						Initial Version CMCM-5763
 *   ---------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestBatchToUpdateAccountPFASandPFSE {
  

    @IsTest //@TestSetup
    static void makeData(){
        
        //Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.Market_Segment__c = null;
        insert objAccount;
        
        SVMXC__Service_Group__c accST1 = New SVMXC__Service_Group__c();
        accST1.Name = 'Service Team 1';
        accST1.SVMXC__Active__c = true;
        accST1.SVMXC__Group_Type__c = 'Both';
        accST1.SVMXC__Phone__c = '(098) 765-4782';
        accST1.SVMXC__Email__c = 'qw@illumina.com';
        accST1.SVMXC__Street__c = 'mangalore';
        accST1.SVMXC__City__c = 'mangalore';
        accST1.SVMXC__State__c = 'Alabama';
        accST1.SVMXC__Country__c = 'United States';
        insert accST1;
        
        SVMXC__Service_Group_Members__c accFS1 = new SVMXC__Service_Group_Members__c();
        accFS1.Name ='Test User 1';
        accFS1.SVMXC__Active__c = true;
        accFS1.Preferred_Service_Report_Language__c = 'English';
        accFS1.SVMXC__Service_Group__c = accST1.Id;  
        insert accFS1; 
            
        Account_to_Field_Support__c accATFS1 = new Account_to_Field_Support__c();
        accATFS1.Account__c = objAccount.ID; 
        accATFS1.User_Role__c='Primary Field Application Scientist'; 
        accATFS1.user__c=accFS1.ID;
        insert accATFS1;
       
        SVMXC__Service_Group__c accST2 = New SVMXC__Service_Group__c();
        accST2.Name = 'Service Team 2';
        accST2.SVMXC__Active__c = true;
        accST2.SVMXC__Group_Type__c = 'Both';
        accST2.SVMXC__Phone__c = '(098) 765-4783';
        accST2.SVMXC__Email__c = 'qw2@illumina.com';
        accST2.SVMXC__Street__c = 'mangalore2';
        accST2.SVMXC__City__c = 'mangalore2';
        accST2.SVMXC__State__c = 'Alabama';
        accST2.SVMXC__Country__c = 'United States';
        insert accST2;        
        
        SVMXC__Service_Group_Members__c accFS2 =new SVMXC__Service_Group_Members__c();
        accFS2.Name ='Test User 2';
        accFS2.SVMXC__Active__c = true;
        accFS2.Preferred_Service_Report_Language__c = 'English';    
        accFS2.SVMXC__Service_Group__c = accST2.Id;     
        insert accFS2; 
            
        Account_to_Field_Support__c accATFS2=new Account_to_Field_Support__c();
        accATFS2.Account__c = objAccount.ID; 
        accATFS2.User_Role__c='Primary Field Service Engineer'; 
        accATFS2.user__c=accFS2.ID;
        insert accATFS2;
           
        // Start the batch
        Test.startTest();
        BatchToUpdateAccountFieldsPFASandPFSE batchClassInstance = new BatchToUpdateAccountFieldsPFASandPFSE();
        Database.executeBatch(batchClassInstance);
        Test.stopTest();

        // Verify the results
        objAccount = [SELECT Id, Primary_Field_Application_Scientist__c, Primary_Field_Service_Engineer__c FROM Account WHERE Id = :objAccount.Id];
        system.debug('objAccount is =>'+objAccount);
        System.assertEquals(accFS1.Name, objAccount.Primary_Field_Application_Scientist__c);
        System.assertEquals(accFS2.Name, objAccount.Primary_Field_Service_Engineer__c);
    }        
        
}
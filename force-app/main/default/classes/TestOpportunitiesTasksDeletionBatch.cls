/***
*    Name -TestOpportunitiesTasksDeletionBatch.
*    DESCRIPTION  : TestClass for OpportunitiesTasksDeletionBatch class.
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Balakrishna                    3rd August 2023              CMCM-1367
*   ------------------------------------------------------------------------------------------------
*/
@isTest(isparallel=false)
public class TestOpportunitiesTasksDeletionBatch {
    
     static testMethod void testBatch(){
        Account acc = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        Account accDistributor = TestDataAccount.getAccount('Distributor Partner');
        accDistributor.Account_Group__c = 'Distributor';
        insert new List<Account>{accDistributor};
            
        Contact con1 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con1 };
            
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        
        Task taskT1=new task();
        taskT1.whatid=opp.id;
        taskT1.subject='Update Opportunity: Complete all other stage-related exit criteria';
        taskT1.Priority='Normal';
        taskT1.ActivityDate=System.today()+10;
        taskT1.status='Completed';
        insert taskT1;
        
        Test.startTest();
         OpportunitiesTasksDeletionBatch obj =new OpportunitiesTasksDeletionBatch();
         Database.executeBatch(obj);
         Test.stopTest();
         List<Task> tsk =[SELECT id From Task WHERE Id=:taskT1.Id];
         system.assertEquals(0, tsk.size());
        
    }

}
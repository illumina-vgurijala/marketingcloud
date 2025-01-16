/***************************************************************************************************************************************
 * NAME   : TestBatchUpdateContactStatusForOpenOpp
 * DESCRIPTION  : TestClass for BatchUpdateContactStatusForOpenOpp
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 23-Oct-2018
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   23-Oct-2018         initial Development
 * Rishab                   17-Jan-2022         CodeScan Fixes
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  
  
@isTest(SeeAllData = false)
public class TestBatchUpdateContactStatusForOpenOpp{

static testMethod void testBatch(){

  //Account acc = TestDataAccount.getNewAccount();
  Account acc = TestDataMarketing.getAccount('test123');
  Contact con1 = TestDataPerson.getNewContact(acc.Id);
  Contact con2 = TestDataPerson.getNewContact(acc.Id);
 
  Opportunity sOpp = TestDataOpportunity.initOpportunity(acc);
  Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
  insert new List<Opportunity>{opp2,sOpp};
  
  OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, sOpp.Id);
  OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, opp2.Id);
  OpportunityContactRole ocr3 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, sOpp.Id);
   insert new List<OpportunityContactRole> { ocr1, ocr2,ocr3};
 
 
 
  
 Test.StartTest();
 BatchUpdateContactStatusForOpenOpp batch=new BatchUpdateContactStatusForOpenOpp();
 Database.executeBatch(new BatchUpdateContactStatusForOpenOpp());  
 String strSchedule = '0 0 10 * * ?'; // every 10 am job
 String jobId = System.schedule('TestBatchUpdateContactStatusForOpenOpp', strSchedule, batch);
 System.debug('jobId ' + jobId); 
 Test.StopTest();
 
 
 Contact confinal=[select id, Marketing_Contact_Status__c from contact where id=:con1.id];
 
 system.assertEquals('Open Opportunity',confinal.Marketing_Contact_Status__c);
}



}
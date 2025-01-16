/***************************************************************************************************************************************
 * NAME   : TestBatchHiveNineWaterfallUpdate
 * DESCRIPTION  : TestClass for BatchHiveNineWaterfallUpdate
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 23-Oct-2018
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   23-Oct-2018         initial Development
 * Rishab Wali              25-Aug-2022         DCP-55949 Waterfall Updates
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  
  
  @isTest(SeeAllData = false)
  public class TestBatchHiveNineWaterfallUpdate{
  
  static testMethod void testBatch(){

    //Account acc = TestDataAccount.getNewAccount();
    Account acc = TestDataMarketing.getAccount('test123');
    Contact con1 = TestDataPerson.getNewContact(acc.Id);
    Contact con2 = TestDataPerson.getNewContact(acc.Id);
    con1.Last_Responded_Campaign_Date__c=Datetime.Now();
    con1.Marketing_Contact_Status__c='Open Opportunity';
    con1.Waterfall_Stage__c = '';
    update con1;
    con2.Marketing_Contact_Status__c='Open Opportunity';
    con2.Waterfall_Stage__c = '';
    update con2;
    Opportunity sOpp = TestDataOpportunity.initOpportunity(acc);
    sOpp.LeadSource='Funnel Marketing';
    sOpp.StageName='Create';
    Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
    opp2.LeadSource='Funnel Marketing';
    opp2.StageName='Create';
    opp2.Type = 'Billable Services';
    opp2.Product_Interest__c = 'Services';
    insert new List<Opportunity>{opp2,sOpp};

    OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, sOpp.Id);
    OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, opp2.Id);
    OpportunityContactRole ocr3 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, sOpp.Id);
    insert new List<OpportunityContactRole> { ocr1, ocr2,ocr3};

    Test.StartTest();
    BatchHiveNineWaterfallUpdate batch=new BatchHiveNineWaterfallUpdate();
    Database.executeBatch(batch);  
    Test.StopTest();
    Contact objContact=[select id,Waterfall_Stage__c from contact where id=:con1.Id];
    system.assert(String.isNotBlank(objContact.Waterfall_Stage__c),'Stage Set Incorrectly');
  }
}
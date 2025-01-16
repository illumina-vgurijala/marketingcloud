/***************************************************************************************************************************************
 * NAME   : TestBatchUpdateContactStatusOppDissociation
 * DESCRIPTION  : TestClass for BatchUpdateContactStatusOppDissociation
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 28-Jan-2019
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                  28-Jan-2019         initial Development
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  
  
@isTest(SeeAllData = false)
public class TestBatchUpdateStatusOppDissociation{

static testMethod void testBatch(){

  Account acc = TestDataMarketing.getAccount('OppDiss');
  Contact con1 = TestDataPerson.getNewContact(acc.Id);
  Contact con2 = TestDataPerson.getNewContact(acc.Id);
  Contact con3 = TestDataPerson.getNewContact(acc.Id);
  con1.Marketing_Contact_Status__c='Open Opportunity';
  Con2.Marketing_Contact_Status__c='Open Opportunity';
  con3.Marketing_Contact_Status__c='Open Opportunity';

  list<Contact> lstCon=new list<Contact>{con1,con2,con3};
  update lstCon;
  
  Opportunity sOpp = TestDataOpportunity.initOpportunity(acc);
  Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
  Opportunity opp3 = TestDataOpportunity.initOpportunity(acc);
  insert new List<Opportunity>{opp2,sOpp,opp3};
  
  OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, sOpp.Id);
  OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, opp2.Id);
  OpportunityContactRole ocr3 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, sOpp.Id);
  OpportunityContactRole ocr4 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con3.Id, opp3.Id);
  insert new List<OpportunityContactRole> { ocr1, ocr2,ocr3,ocr4}; 

  Delete (new list<Opportunity>{sOpp,opp2});
  
 Test.StartTest();
 //BatchUpdateContactStatusForOpenOpp batch=new BatchUpdateContactStatusForOpenOpp();
 //Database.executeBatch(new BatchUpdateContactStatusForOpenOpp()); 
    
String sch = '0 0 23 * * ?';
 BatchUpdateContactStatusOppDissociation objbatch=new BatchUpdateContactStatusOppDissociation();
 Database.executeBatch(objbatch); 
 system.schedule('Test123'+system.now(), sch,objbatch);
 Test.StopTest();
 
 for(Contact objCon:[select id,Marketing_Contact_Status__c,Disposition_Code__c from contact]){
    if(objCon.id==con1.id || objCon.id==con2.id){
        system.assertEquals(objCon.Marketing_Contact_Status__c,BatchUpdateContactStatusOppDissociation.STRING_RECYCLED);
        system.assertEquals(objCon.Disposition_Code__c,BatchUpdateContactStatusOppDissociation.STRING_DISPOSITION_CODE);
    }
    
    
 }
 //Contact Confinal=[select id, region__C from contact where id=:Con.id];
 set<id> setOppIds=new set<id>();
 setOppIds.add(sOpp.id);
 set<String> setString=new set<string>();
 setString.add('Closed');
  List<OpportunityContactRole> lstOpportunityContactRole = new OpportunityContactRoleSelector().selectRoles(setOppIds);
  lstOpportunityContactRole = new OpportunityContactRoleSelector().selectAllOppContactIds(setOppIds,'Open Opportunity');
	lstOpportunityContactRole = new OpportunityContactRoleSelector().selectInvalidOppContactIds(setOppIds,setString,'Open Opportunity');
	
 //system.assertEquals(Confinal.region__C,'AMR');
}



}
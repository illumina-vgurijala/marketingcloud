/***************************************************************************************************************************************
 * NAME   : TestBatchLeadCountryRegionMapping
 * DESCRIPTION  : TestClass for BatchLeadCountryRegionMapping
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 23-Oct-2018
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   23-Oct-2018         initial Development
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  
  
@isTest(SeeAllData = false)
public class TestBatchLeadCountryRegionMapping{

static testMethod void testBatch(){

  Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
  Lead ld2=TestDataMarketing.createLead('testfirstname1','testlastname1','test1@gmail.com','Canada','testCompany1');
  ld.region__c='test';
  update ld;

  ilib_LogEvent.message('Lead Id -- ' + ld2.Id);
 
 Test.StartTest();
 BatchLeadCountryRegionMapping batch=new BatchLeadCountryRegionMapping();
 Database.executeBatch(batch);  
 //String strSchedule = '0 0 10 * * ?'; // every 10 am job
 //String jobId = System.schedule('TestBatchLeadCountryRegionMapping', strSchedule, batch); 
 Test.StopTest();
 
// Lead Leadfinal=[select id, region__C from contact where id=:Con.id];
 
 //system.assertEquals(Confinal.region__C,'AMR');
}

static testmethod void testscheduler(){
        Test.StartTest();
        SchedulerBatchLeadCountryRegion  bb=new SchedulerBatchLeadCountryRegion();
        BatchLeadCountryRegionMapping batch=new BatchLeadCountryRegionMapping();
        //bb.execute(null);
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test123', sch,bb);
		    system.schedule('Test123'+system.now(), sch,batch);	
        Test.StopTest();
        
}


}
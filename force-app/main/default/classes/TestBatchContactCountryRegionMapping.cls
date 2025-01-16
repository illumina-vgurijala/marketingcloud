/***************************************************************************************************************************************
 * NAME   : TestBatchContactCountryRegionMapping
 * DESCRIPTION  : TestClass for BatchContactCountryRegionMapping
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
public class TestBatchContactCountryRegionMapping{

static testMethod void testBatch(){

 Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
 con.MailingCountry='USA';
 con.region__c='test';
 update con;
 
 Test.StartTest();
 BatchContactCountryRegionMapping batch=new BatchContactCountryRegionMapping();
 Database.executeBatch(batch);  
 //String strSchedule = '0 0 10 * * ?'; // every 10 am job
 //String jobId = System.schedule('TestBatchContactCountryRegionMapping', strSchedule, batch); 
 Test.StopTest();
 
 Contact confinal=[select id, region__c from contact where id=:con.id];
 
 system.assertEquals('AMR',Confinal.region__c,'Region not set');
}

static testmethod void testscheduler(){
        Test.StartTest();
        SchedulerBatchContactCountryRegion  bb=new SchedulerBatchContactCountryRegion();
        BatchContactCountryRegionMapping batch=new BatchContactCountryRegionMapping();
        //bb.execute(null);
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test123', sch,bb); 
		    system.schedule('Test123'+system.now(), sch,batch);
        Test.StopTest();
        
}


}
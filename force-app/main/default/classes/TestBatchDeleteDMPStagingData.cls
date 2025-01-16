/**************************************************************************************************************
 * NAME   : TestBatchDeleteDMPStagingData
 * DESCRIPTION  : TestClass for BatchLeadStatusUpdate
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 20-Feb-2020 
 *
 * MODIFICATION LOG:  
 * -----------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   20-Feb-2020        initial Development
 * ------------------------------------------------------------------------------------------------------------
  *************************************************************************************************************/ 
@isTest(SeeAllData = false  isParallel=false)
public class TestBatchDeleteDMPStagingData{

    static testMethod void testBatch(){
        List<DMP_Staging__c> lststaging=new List<DMP_Staging__c>();
        List<DMP_Staging__c> lststagingnew=new List<DMP_Staging__c>();
        DMP_Staging__c obj1=new DMP_Staging__c();
        obj1.Hem__c='test1';
        obj1.segments__c='abc,def';
        
        DMP_Staging__c obj2=new DMP_Staging__c();
        obj2.Hem__c='test2';
        obj2.segments__c='abc,def';
        lststaging.add(obj1);
        lststaging.add(obj2);
        insert lststaging;
        Integer intdays=(Integer.ValueOf(Label.DMP_Staging_Rentention_Days))+1;
        obj1.Record_Processed__c=true;
        obj1.Record_Processed_Date__c=Datetime.now().addDays(-intdays);
        lststagingnew.add(obj1);
        obj2.Record_Processed__c=true;
        obj2.Record_Processed_Date__c=Datetime.now();
        lststagingnew.add(obj2);
        update lststagingnew;
        
        Test.startTest();
        String sch = '0 0 23 * * ?';
        BatchDeleteDMPStagingData b=new BatchDeleteDMPStagingData();
        system.schedule('Test112'+system.now(),sch,b); 
        Database.executebatch(new BatchDeleteDMPStagingData());
        
        Test.stopTest();
        
        List<DMP_Staging__c> lststagingfinal=[select id from DMP_Staging__c];
        system.assertequals(1,lststagingfinal.size());
    }

}
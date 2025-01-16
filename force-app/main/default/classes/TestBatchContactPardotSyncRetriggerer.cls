/***************************************************************************************************************************************
 * NAME   : TestBatchContactPardotSyncRetriggerer
 * DESCRIPTION  : TestClass for BatchContactPardotSyncRetriggerer
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 01-Feb-2019
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * 
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)
public class TestBatchContactPardotSyncRetriggerer{

    static testMethod void testBatch(){
        
      Contact con1=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com','US');
      Contact con2=TestDataMarketing.createContact('testfirstname','testlastname','test2@gmail.com','US');
      Datetime dtDate2=Datetime.now().addminutes(-40);
       con1.MailingCountry='USA';
       
       con1.Explicit_Opt_In__c='Yes';
       con1.IMPLICIT_OPT_IN__C='Yes';
       con2.Explicit_Opt_In__c='Yes';
       con2.IMPLICIT_OPT_IN__C='Yes';
       con2.MailingCountry='USA';
       con2.Pardot_Re_Trigger_Date__c=dtDate2;
       List<Contact> lstCon=new List<Contact>{con1,con2};
       update lstCon;
       
       Test.Starttest();
        BatchContactPardotSyncRetriggerer objbatch=new BatchContactPardotSyncRetriggerer();
        database.executebatch(objbatch);
        Test.stopTest();
       Contact objCon=[select id,Pardot_Re_Trigger_Date__c from contact where id=:Con2.id];
       System.assertNotEquals(dtDate2,objCon.Pardot_Re_Trigger_Date__c,'BatchContactPardotSyncRetriggerer failed');
    }
}
/***************************************************************************************************************************************
 * NAME   : TestLeads
 * DESCRIPTION  : TestClass for BatchLeadPardotSyncRetriggerer
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
public class TestBatchLeadPardotSyncRetriggerer{

    static testMethod void testBatch(){
        Lead objLead=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        Lead objLead2=TestDataMarketing.createLead('testfirstname2','testlastname2','test2@gmail.com','USA','testCompany');
        Datetime dtDate=Datetime.now();
        Datetime dtDate2=Datetime.now().addminutes(-40);
        
        objLead.Explicit_Opt_In__c='Yes';
        objLead.IMPLICIT_OPT_IN__C='Yes';
        
        objLead2.Explicit_Opt_In__c='Yes';
        objLead2.IMPLICIT_OPT_IN__C='Yes';      
        objLead2.Pardot_Re_Trigger_Date__c= dtDate2;
        
        List<Lead> lstLead=new List<Lead> {objLead,objLead2};
        update lstLead;
        system.debug('objLead2---'+objLead2.Pardot_Re_Trigger_Date__c);
        Test.Starttest();
        BatchLeadPardotSyncRetriggerer objbatch=new BatchLeadPardotSyncRetriggerer();
		String sch = '0 0 23 * * ?';
        system.schedule('Test111'+system.now(),sch,objbatch);
        database.executebatch(objbatch);
        Test.stopTest();
        Lead objLd=[select id,Pardot_Re_Trigger_Date__c from lead where id=:objLead2.id];
        System.assertNotEquals(dtDate2,objLd.Pardot_Re_Trigger_Date__c,'BatchLeadPardotSyncRetriggerer failed');
    }
 

}
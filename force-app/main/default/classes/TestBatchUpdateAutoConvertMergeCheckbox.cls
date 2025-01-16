/***************************************************************************************************************************************
 * NAME   : TestBatchUpdateAutoConvertMergeCheckbox
 * DESCRIPTION  : TestClass for BatchUpdateAutoConvertMergeCheckbox
 *                  
 *    
 * @AUTHOR : Monika Parihar
 * @DATE   : 29-Sept-2020
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 *                    29-Sept-2020         initial Development
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  
  
@isTest(SeeAllData = false)
public class TestBatchUpdateAutoConvertMergeCheckbox{

    static testMethod void testBatch(){
        Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        ld.Is_AutoMerge_In_Progress__c=True;
        ld.Is_AutoConversion_In_Progress__c=True;
        update ld;
        System.assert(ld.Is_AutoMerge_In_Progress__c != false);

        Lead ld1=TestDataMarketing.createLead('testfirstname1','testlastname1','test1@gmail.com','Canada','testCompany1');
        ld1.Is_AutoMerge_In_Progress__c=True;
        ld1.Is_AutoConversion_In_Progress__c=True;
        update ld1;
        System.assert(ld1.Is_AutoConversion_In_Progress__c != false);
        
        Test.StartTest();
            BatchUpdateAutoConvertMergeCheckbox batch=new BatchUpdateAutoConvertMergeCheckbox();
            Database.executeBatch(new BatchUpdateAutoConvertMergeCheckbox());  
        Test.StopTest();
    } 
	static testmethod void testscheduler(){
        Test.StartTest();
            BatchUpdateAutoConvertMergeCheckbox batch=new BatchUpdateAutoConvertMergeCheckbox();
            String sch = '0 0 23 * * ?'; 
            system.assert(sch != Null); 
			system.schedule('Test123'+system.now(), sch,batch);  
        Test.StopTest();
    }
}
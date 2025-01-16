/***************************************************************************************************************************************
* NAME   : TestPostRefreshActivities
* DESCRIPTION  : Test class to cover BatchBulkDeleteOperationalLogsData,BatchBulkEmailMaskUpdate and PostRefreshActivities classes
*
* @AUTHOR : Goutham Ramireddy (Release Team)
* @DATE   : 20-July-2021
*
* MODIFICATION LOG:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION
* --------------------------------------------------------------------------------------------------------------------------------------
* Goutham                 20th July 2021        Initial Version

****************************************************************************************************************************************/
@isTest
public class TestPostRefreshActivities{
    
    
    @isTest
    static void testSandboxPostCopyScript() 
    {    

	//Insert lead record
        lead objLead = new lead();
        objLead.LastName = 'Test';
        objLead.Company='Test';
        objLead.Status='New';
        objLead.CurrencyIsoCode = 'EUR';
        objLead.Email='test@deloitte.com';
        insert objLead;
        
	//Insert exception log record
        Exception_log__c objException = new Exception_log__c();
        objException.Source__c='test';
        insert objException;       
        
        Test.startTest();
        
        	PostRefreshActivities callMethod = new PostRefreshActivities();
        	callMethod.runapexclass(null);

        Test.stopTest();

    //Assert statements    
        lead objLeadUpdated=[select id,email from Lead limit 1];
        list<Exception_log__c> logList = new list<Exception_log__c>();
        logList = [SELECT id from Exception_log__c limit 1];
        System.assertEquals('test@deloitte.com.invalid', objLeadUpdated.Email,'Batch class failed to update the email id to invalid');
        System.assertEquals(0, logList.size(),'Batch class failed to delete the exception log record');
    
    }
    
}
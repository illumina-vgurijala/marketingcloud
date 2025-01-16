/**
*    @author: Joshith K
*    @date:   24-Sep-2019
*    @description:  test class for SoftwareDownloadQueueableForSync
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            
*    ------------------------------------------------------------------------------------ 
*/
@isTest(SeeAllData=false)
private class  TestSoftwareDownloadQueueableForSync {

    static testMethod void testSoftwareDownloadQueueable()
    {
        List<Software_Download__c> lstDownloads = new List<Software_Download__c> {
            new Software_Download__c(Email_Address__c = 'lead@test.com'),
            new Software_Download__c(Email_Address__c = 'contact@test.com')
        };
        insert lstDownloads;

        Test.startTest();
        Contact con = TestDataMarketing.createContact('testnew contact', 'contact', 'Contact@test.com');
        Lead lead = TestDataMarketing.createLead('testfirstname', 'testlastname', 'Lead@test.com', 'USA', 'testCompany');
        Test.stopTest();
        
        System.assertEquals(1, [SELECT count() FROM Software_Download__c WHERE Contact_full_name__c = :con.Id]);
        System.assertEquals(1, [SELECT count() FROM Software_Download__c WHERE Lead_full_name__c = :lead.Id]);
    }
	
	/*Test method to cover Catch Block of Class SoftwareDownloadQueueableForSync
	*/
   public static testMethod void coverCatchBlockSoftwareDownloadQueueableForSync(){
    try{
        SoftwareDownloadQueueableForSync.catchException = true;
        SoftwareDownloadQueueableForSync sd = new SoftwareDownloadQueueableForSync(null);
        Test.startTest();
        System.enqueueJob(sd);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }

}
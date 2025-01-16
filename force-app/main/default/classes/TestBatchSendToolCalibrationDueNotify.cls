/*
 * @author: Sravan
 * Description: To cover the class BatchSendToolCalibrationDueNotifications
 */
@isTest(SeeAllData = false)
public class TestBatchSendToolCalibrationDueNotify {
 /*
 * Description: To setup initial data
 */

 @testSetup
    public static void initializeTestData()
    {
      SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'TestTeam',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true,
            Region__c='AMR'
        );
        insert u;
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
            objLocation.SVMX_PS_Preferred_Technician__c=grpMembers.Id;
            insert objLocation;
        Product2 objProduct = new Product2(Name = 'testProduct',Service_Product_Type__c = 'Approved Tool- Calibrated', GFSL_FC_Hierarchy__c='Calibrated Tool');
        insert objProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('TestIP', 'USD', 'Calibrated');
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('TestIP1', 'USD', 'Calibrated');
        objInstalledProduct.SVMXC__Site__c =  objLocation.id;   
        objInstalledProduct1.SVMXC__Site__c =  objLocation.id;   
        objInstalledProduct.SVMXC__Product__c=objProduct.id;
        objInstalledProduct1.SVMXC__Product__c=objProduct.id;
        objInstalledProduct.Tool_Calibration_Due_Date__c = system.today();
        objInstalledProduct1.Tool_Calibration_Due_Date__c = system.today()+14;
        insert new List<SVMXC__Installed_Product__c>{objInstalledProduct, objInstalledProduct1};  
    }
/*
 * Description: To cover the class BatchSendToolCalibrationDueNotifications
 */
    
static testMethod void testSendNotifications(){ 
 Test.StartTest();
 BatchSendToolCalibrationDueNotifications batch = new BatchSendToolCalibrationDueNotifications('AMR');
 Database.executeBatch(batch);  
 String sch = '0 0 0 * * ?';
 System.schedule('TestBatchSendToolCalibrationDueNotify', sch, batch); 
 Test.StopTest();
 List<SVMXC__Service_Group_Members__c> listFS = new List<SVMXC__Service_Group_Members__c>([Select Name, (Select Subject,ActivityType from ActivityHistories) from SVMXC__Service_Group_Members__c Limit 1]);
 system.assert(listFS[0].ActivityHistories.size() > 0, 'TestBatchSendToolCalibrationDueNotify: Emails were not saved under activities');
}
}
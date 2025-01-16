/**
* @author Shivani Jain
* @date 17 March 2022
*
* @description DCP-51321 Test class for EnhancedFileListController
*/ 
@IsTest
private class TestEnhancedFileListController {

    /*******************************************************************************************************
    * @description test setup method
    */
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Name',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount('Test Account', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
               
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /*******************************************************************************************************
    * @description test method for GetFilesList
    */
    static testMethod void testGetFilesList() {
        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null,objCV.id);

        Case caseRec = [SELECT id FROM Case LIMIT 1];

        objCV =[SELECT id, ContentDocumentId FROM ContentVersion where Id =: objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, caseRec.Id,'V','AllUsers');
        insert objCDL;
        system.assertNotEquals(null,objCDL.id);

        EnhancedFileListController.ResultWrapper result = new EnhancedFileListController.ResultWrapper();
        Test.startTest();
        result = EnhancedFileListController.getFilesList(caseRec.Id, true, true);
        Test.stopTest();
        
        System.assert(result != NULL, 'GetFilesList method failed');
        

    }
}
/**
* @author Shivani Jain
* @date 17 March 2022
*
* @description DCP-51321 test Class for ContentDocumentLinksSelector
*/
@isTest
private class TestContentDocumentLinksSelector {
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
    * @description test method for selectContentDocumentLinksWithoutLogos
    */
    static testMethod void testSelectContentDocumentLinksWithoutLogos() {
        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null,objCV.id);

        Case caseRec = [SELECT id FROM Case LIMIT 1];

        objCV =[SELECT id, ContentDocumentId FROM ContentVersion where Id =: objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, caseRec.Id,'V','AllUsers');
        insert objCDL;
        system.assertNotEquals(null,objCDL.id);

        Test.startTest();
        ContentDocumentLinksSelector selector = new ContentDocumentLinksSelector();
        List<ContentDocumentLink> cdLst1 = selector.selectContentDocumentLinksWithoutLogos(new Set<Id>{caseRec.Id});
        System.assert(cdLst1 != NULL && !cdLst1.isEmpty(), 'selectContentDocumentLinksWithoutLogos method dint return any record');
        
        List<ContentDocumentLink> cdLst2 = selector.selectContentDocumentLinks(new Set<Id>{caseRec.Id});
        System.assert(cdLst2 != NULL && !cdLst2.isEmpty(), 'selectContentDocumentLinks method dint return any record');

        List<ContentDocumentLink> cdLst3 = selector.selectByEmailMessagesRecordIds(new Set<Id>{caseRec.Id});
        System.assert(cdLst3 != NULL && !cdLst3.isEmpty(), 'selectByEmailMessagesRecordIds method dint return any record');

        List<ContentDocumentLink> cdLst4 = selector.selectByMasterDataRequestIds(new List<Id>{caseRec.Id});
        System.assert(cdLst4 != NULL && !cdLst4.isEmpty(), 'selectByMasterDataRequestIds method dint return any record');

        List<ContentDocumentLink> cdLst5 = selector.selectByQuoteId(new Set<Id>{caseRec.Id});
        System.assert(cdLst5 != NULL && !cdLst5.isEmpty(), 'selectByQuoteId method dint return any record');

        List<ContentDocumentLink> cdLst6 = selector.selectByMasterDataRequestId(caseRec.Id);
        System.assert(cdLst6 != NULL && !cdLst6.isEmpty(), 'selectByMasterDataRequestId method dint return any record');
        
        List<ContentDocumentLink> cdLst7 = selector.selectByEmailMessagesIds(new Set<Id>{caseRec.Id});
        System.assert(cdLst7 != NULL && !cdLst7.isEmpty(), 'selectByEmailMessagesIds method dint return any record');

        Test.stopTest();
    }
}

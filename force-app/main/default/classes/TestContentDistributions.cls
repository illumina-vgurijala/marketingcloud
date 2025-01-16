/**
* @author Abhishek Yadav
* @date 16-Dec-2024
* @group ContentDistribution
* @description: This Test class is used to validate the functionality of trigger handler.
* Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*        Abhishek Yadav    16-Dec-2024       CMCM-12619, initial version
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestContentDistributions {
    @isTest
    static void testrecallFilesPublicLinkCreationThrowsError() {
        Boolean expectedExceptionThrown = false;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'jwick@gmail.com',
            Username = 'jwick@gmail.com' + System.currentTimeMillis(),
            CompanyName = 'Illumina',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        System.runAs(u) {
            try {
                 // Create and insert a ContentVersion record
                    ContentVersion contentVersion = new ContentVersion(
                        Title = 'Test File',
                        PathOnClient = 'TestFile.txt',
                        VersionData = Blob.valueOf('This is a test file'),
                        IsMajorVersion = true,
                        IsRecallRelated__c = true
                    );
                    insert contentVersion;

                // Insert a ContentDistribution record
                ContentDistribution contentDistribution = new ContentDistribution(
                    Name = 'Test Distribution',
                    ContentVersionId = contentVersion.Id
                );
                Test.startTest();
                insert contentDistribution;
                Test.stopTest();
            } catch(Exception e) {
                expectedExceptionThrown =  e.getMessage().contains(Label.preventRecallFileDelete) ? true : false;   
            }
            Assert.isTrue(expectedExceptionThrown == true,'expectedExceptionThrown should be true');
        }
    }
}
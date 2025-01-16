/***************************************************************************************************************************************
 * NAME   : TestKnowledge_kav
 * DESCRIPTION  : TestClass for Knowledge__kav: WFR After Insert and Update Flow
 * @AUTHOR : Dhairya Shah
 * @DATE   : 2-December-2024 
 *
 *****************************************************************************************************************************************/
@isTest(seeAllData = false)
public with sharing class TestKnowledge_kav {
    public static final string STRING_KNOWLEDGE_PRI_SEC_WORKFLOW = 'Clinical';
    public static final string STRING_KNOWLEDGE_REVVIEW_STATUS = 'Review Completed';


    static testMethod void testKnowledgekavMethod() {
         //Create User
         User fsUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id>());
         User adminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>());
         Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Manage_Knowledge' LIMIT 1][0].Id;
         System.runAs(adminUser) {
             insert new PermissionSetAssignment (
                 AssigneeId = fsUser.Id, PermissionSetId = permissionSetId);
         }
        System.runAs(fsUser){
            Knowledge__kav kav = TestDataFieldService.createKnowledgekav(STRING_KNOWLEDGE_PRI_SEC_WORKFLOW, STRING_KNOWLEDGE_REVVIEW_STATUS);
            kav.Publish_Article__c = true;
            kav.Title = 'Test Article ABC';
            kav.Summary = 'Test 123';
            kav.UrlName = 'Sample-Article-TOI';
            kav.Article_Body__c = 'Test 456';
            kav.Article_Version_Author__c = fsUser.id;
            kav.Date_of_Last_Annual_Review__c = null;
            
            insert kav;

            Test.startTest();
            kav.Review_Status__c = STRING_KNOWLEDGE_REVVIEW_STATUS;
            Update kav;
            Test.stopTest();

            Knowledge__kav kavRetrieved = [SELECT ValidationStatus, Publish_Article__c, Date_of_Last_Annual_Review__c FROM Knowledge__kav WHERE Id = :kav.Id];
            System.assertEquals('Approved', kavRetrieved.ValidationStatus,'Validation Status should be Approved');
            System.assertEquals(false, kavRetrieved.Publish_Article__c,'Publish article is false');
            System.assertEquals(system.today(), kavRetrieved.Date_of_Last_Annual_Review__c,'Date of last annual review is current date');
        }
    }

    static testMethod void testKnowledgeValidation() {

       User ssUser = [SELECT Id FROM User WHERE Id NOT IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'SS_Manage_Knowledge') AND IsActive = true LIMIT 1];
        System.runAs(ssUser){
            Knowledge__kav kav = TestDataFieldService.createKnowledgekav(STRING_KNOWLEDGE_PRI_SEC_WORKFLOW, STRING_KNOWLEDGE_REVVIEW_STATUS);
            kav.Publish_Article__c = true;
            kav.Title = 'Test Article ABC';
            kav.Summary = 'Test 123';
            kav.UrlName = 'Sample-Article-TOI';
            kav.Article_Body__c = 'Test 456';
            kav.Article_Version_Author__c = ssUser.id;
            kav.Date_of_Last_Annual_Review__c = null;
            
            Test.startTest();
            try {
                    insert kav;
                    Knowledge__kav kavRetrieved = [SELECT ValidationStatus, Publish_Article__c, Date_of_Last_Annual_Review__c FROM Knowledge__kav WHERE Id = :kav.Id];
                    System.assertEquals(null, kavRetrieved.Date_of_Last_Annual_Review__c,'It should be null or Thrown Error');
                } catch (DmlException ex) {
                    System.assert(ex.getMessage().contains(System.Label.Field_Permission_Denied_Error), 'Validation error message mismatch.');
                }
            Test.stopTest();
        }
    }
}
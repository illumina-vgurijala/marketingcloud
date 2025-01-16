/**
 *    @author Deepak
 *    @date   26-Nov-2020
 *    @description: Test class for Feedbacks   
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Deepak Kumar              25-Nov-2020           Original version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
@istest
public with sharing class TestFeedbacks {
    /**
    *  @description Test class for Feedbacks methods.
    * 
    **/

    public static final string  FEEDBACK_TITLE = 'fbtest';
    static testmethod void testInsertNewFeedback() {
        Test.StartTest();
    
        User systemAdmin = TestDataFieldService.createUser('System Administrator', true);
        systemAdmin.UserPermissionsKnowledgeUser = true;  // Ensure Knowledge User permission is enabled
        update systemAdmin;
    
        List<String> lstQueueName = new List<String>{'Feedback_Reviewers'};
        List<Group> groupObj = new GroupsSelector().getQueueIdbyDeveloperName(lstQueueName, 'Queue');
    
        system.runAs(systemAdmin){
            knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(FEEDBACK_TITLE, 'Instrumentation', 'Software');
            insert newArticle;  // Insert the new article
        
            Feedback__c newFeedback = new Feedback__c();
            newFeedback.Knowledge_Article_Link__c = newArticle.id;
            insert newFeedback;
        
            System.assert(newFeedback.Id != null, 'Feedback not inserted');
            Feedback__c fb = [SELECT OwnerID FROM Feedback__c WHERE ID = :newFeedback.Id LIMIT 1];
            System.assertEquals(groupObj[0].id, fb.OwnerID, 'Default Queue Error');
        
            fb.OwnerID = systemAdmin.id;
            update fb;
        
            Feedback__c newFb = [SELECT Id, OwnerID, CreatedById FROM Feedback__c WHERE ID = :newFeedback.Id LIMIT 1];
            System.assertEquals(systemAdmin.id, newFb.OwnerID, 'Updated Owner Error');
        }
        
    
        // End test context
        Test.StopTest();
    }
    

    @TestSetup
    static void createFeedback(){
        List <feedback__c> feedbackList = new List <feedback__c>();
        feedback__c feedbackObjIns = new feedback__c();
        feedbackObjIns.Feedback_Status__c ='Open';
        feedbackList.add(feedbackObjIns);
        insert feedbackList;
    }

    @isTest
    static void updateReopenReasonToNull() {
        List<Feedback__c> feedbackObj = [SELECT Id, Feedback_Disposition__c, Reopen_Reason__c FROM Feedback__c LIMIT 1];
        
        if (!feedbackObj.isEmpty()) {
            feedbackObj[0].Feedback_Disposition__c = 'In Progress';
            feedbackObj[0].Reopen_Reason__c = 'Test Reason';
    
            update feedbackObj;
    
            feedbackObj = [SELECT Id, Feedback_Disposition__c, Reopen_Reason__c FROM Feedback__c WHERE Id = :feedbackObj[0].Id LIMIT 1];
    
            System.assertEquals(null, feedbackObj[0].Reopen_Reason__c, 'Expected feedback reopen reason to be null');
        } else {
            System.debug('No feedback record found to test.');
        }
    }
    
    @isTest
    static void toPopulateFeedbackCloseDate() {
        // Create test data
        Feedback__c feedbackObj = new Feedback__c(Feedback_Status__c = 'Open');
        insert feedbackObj;

        // Update Feedback status to 'Closed' and check if the close date gets populated
        feedbackObj.Feedback_Status__c = 'Closed';
        update feedbackObj;

        // Query the feedback record again to verify the Feedback_Close_Date__c is set
        feedbackObj = [SELECT Id, Feedback_Status__c, Feedback_Close_Date__c FROM Feedback__c WHERE Id = :feedbackObj.Id LIMIT 1];

        // Validate that the close date is set to today
        System.assertEquals(System.today(), feedbackObj.Feedback_Close_Date__c.date(), 'Feedback close date should be updated to today');
    }

    @isTest
    static void updateAssignmentDate() {
        User manager = TestDataFieldService.createUser('System Administrator', true);
    
        List<Feedback__c> feedbackObj = [SELECT Id, Feedback_Status__c, Feedback_Assignment_Date__c 
                                           FROM Feedback__c 
                                           WHERE Feedback_Assignment_Date__c = null 
                                           LIMIT 1];
    
        if (!feedbackObj.isEmpty()) {
            feedbackObj[0].Feedback_Status__c = 'Open';
            feedbackObj[0].OwnerId = manager.Id;
    
            update feedbackObj;
    
            feedbackObj = [SELECT Id, Feedback_Status__c, Feedback_Assignment_Date__c 
                            FROM Feedback__c 
                            WHERE Id = :feedbackObj[0].Id LIMIT 1];
    
            System.assertEquals(System.today(), feedbackObj[0].Feedback_Assignment_Date__c, 'Assignment date should be updated to today');
        } else {
            System.debug('No feedback record found to test.');
        }
    }
    

    @isTest
    static void testassignmentDateChange(){
        
        User manager = TestDataFieldService.createUser('System Administrator', true);
        
        List<Feedback__c> feedbackObj = [SELECT Id, Feedback_Status__c, Feedback_Assignment_Date__c FROM Feedback__c LIMIT 1];
        
        feedbackObj[0].Feedback_Assignment_Date__c = System.today();
        feedbackObj[0].OwnerId = manager.Id;
        
        update feedbackObj;
        
        Feedback__c updatedFeedback = [SELECT Feedback_Assignment_Date__c FROM Feedback__c WHERE Id = :feedbackObj[0].Id LIMIT 1];
        
        System.assertEquals(System.today(), updatedFeedback.Feedback_Assignment_Date__c, 'Expected assignment date to be today');
    }
       

   
}
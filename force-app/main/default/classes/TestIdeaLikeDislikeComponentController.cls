/**
*    Description - Test class for IdeaLikeDislikeComponentController 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    29th Aug 2022               DCP-56319 Like Dislike Fucntionality 
*    -----------------------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false isParallel=false)
public class TestIdeaLikeDislikeComponentController {

        
    /*
    * Test method to LikeDisLikeIdea
    */
    @isTest
    public static void checkVoteLike() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
        
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();
        
        innohub__Innovation_Idea__c objIdea = new innohub__Innovation_Idea__c(Name='Test Innovate', innohub__Category__c='Other', innohub__Description__c='Test Description');
        objIdea.Category__c = 'Idea Exchange';
		objIdea.Sub_Category__c = 'Other';
		insert objIdea;
        innohub__Innovation_Idea_Vote__c ideaVote = new innohub__Innovation_Idea_Vote__c(innohub__Innovation_Idea__c=objIdea.id, innohub__Vote_Type__c=True);
        insert ideaVote;

        Test.startTest();                
            IdeaLikeDislikeComponentController.ideaLiked(objIdea.Id);
            IdeaLikeDislikeComponentController.updateVote(false,objIdea.Id);
            IdeaLikeDislikeComponentController.updateVote(true,objIdea.Id);
        Test.stopTest();        
        innohub__Innovation_Idea__c objInnohubIdea = [SELECT Id,Vote_Count__c FROM innohub__Innovation_Idea__c WHERE Id =: objIdea.Id];
        System.assertEquals(10,objInnohubIdea.Vote_Count__c,'Vote Count not updated correctly');
    }

    /*
    * Test method to LikeDisLikeIdea
    */
    @isTest
    public static void checkVoteUnlike() {

        innohub__Innovation_Idea__c objIdea = new innohub__Innovation_Idea__c(Name='Test Innovate', innohub__Category__c='Other', innohub__Description__c='Test Description');
        objIdea.Category__c = 'Idea Exchange';
		objIdea.Sub_Category__c = 'Other';
		insert objIdea;

        Test.startTest();                
            IdeaLikeDislikeComponentController.ideaLiked(objIdea.Id);
            IdeaLikeDislikeComponentController.updateVote(false,objIdea.Id);
        Test.stopTest();        
        innohub__Innovation_Idea__c objInnohubIdea = [SELECT Id,Vote_Count__c FROM innohub__Innovation_Idea__c WHERE Id =: objIdea.Id];
        System.assertEquals(0,objInnohubIdea.Vote_Count__c,'Vote Count not updated correctly');
    }
    
     private static void setThreshholdsToZero()
     {
         PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
         settings.Slow_Query_Threshold__c = 0.0;
         settings.Slow_Transaction_Threshold__c = 0.0;
         settings.Disable_All_Log_Persistence__c = false;
         settings.Disable_Slow_Query_Publish__c = false;
         settings.Disable_Slow_Transaction_Publish__c = false;

         ilib_LogSettings.unitTestSettingsRecord = settings;
     }
    
 }
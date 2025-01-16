/***************************************************************************************************************************************
 * NAME   : TestMoveCampaignMembersController
 * DESCRIPTION  : TestClass for MoveCampaignMembersController
 *                
 *    
 * @AUTHOR : Nishan Shetty
 * @DATE   : 23-Jun-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Nishan Shetty           23--Jun-2021         Initial Test Class 
 * Deep Diwakar            01-Jan-2023          POL-173: Updating campaign_region__c field value with new values
 * Deep Diwakar            June-18-2023         CMCM-1160: Updated test methods to use Campaign Subregion field
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
 @isTest(SeeAllData=false)
  public  class TestMoveCampaignMembersController {
    /*
    *@author: Nishan Shetty
    *@Desc: Test Setup method 
    */
     @testSetup 
     static void setupData() {
      Campaign objCampaign=new Campaign(name='testing3',Marketing_Segment__c = 'Platforms' , Marketing_Campaign__c = 'NIPT' , Program_Type__c = 'Awareness',type='Webinar',Campaign_Region__c='AMR',Campaign_Subregion__c='AMR Central',Channel__c='Live',Funnel__c='Top');
      insert objCampaign;
      Lead objLead=TestDataMarketing.createLead('FirstName3','LastName3','Test3@f.com','Bahrain','TestCompany3');
      TestDataMarketing.createCampaignMember(objLead.Id,objCampaign.Id,'No Attempt');
      Campaign objCampaignNew=new Campaign(name='testing4',Marketing_Segment__c = 'Forensics' , Marketing_Campaign__c = 'Library Prep' , Program_Type__c = 'Internal',type='Email',Campaign_Region__c='EUR',Campaign_Subregion__c='Germany',Channel__c='Drip Email',Funnel__c='Top');
      insert objCampaignNew;
      Contact objContact=TestDataMarketing.createContact('Test','Contact','test@testing.com','IN');
      TestDataMarketing.createCampaignMemberContact(objContact.Id,objCampaignNew.Id,'No Attempt');

   }
     /*
     *  @author Nishan Shetty
     *  @description Test method for getCampaignMembers Records.
     */
     @isTest
     static void testGetCampaignMembers() {
         
        Campaign objCampaign=[Select Id from Campaign where Name='testing3' Limit 1];
        
        Test.startTest();
        String strJSON = MoveCampaignMembersController.getCampaignMembers(objCampaign.Id);
        List<MoveCampaignMembersController.CampaignMemberWrapper> lstCampaignMembers = (List<MoveCampaignMembersController.CampaignMemberWrapper>)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            '{"lstCampaignMembers": ',
            ', "strOffsetSize": "'),
        List<MoveCampaignMembersController.CampaignMemberWrapper>.class);
        System.assertEquals(1,lstCampaignMembers.size(),'Campaign Member count not matching');
        Test.stopTest();

     }

      /*
     *  @author Nishan Shetty
     *  @description Test method for moveCampaignMembers.
     */
    @isTest
    static void testMoveCampaignMembers() {
        
       Campaign objCampaignOld=[Select Id from Campaign where Name='testing3' Limit 1];
       Campaign objCampaignNew=[Select Id from Campaign where Name='testing4' Limit 1];
       CampaignMember objCampaignMember=[Select Id from CampaignMember where CampaignId=:objCampaignOld.Id]; 
       Test.startTest();
       System.debug('objCampaignNew'+objCampaignNew);
       List<Id> lstCampaignMemberIds=new List<Id>{objCampaignMember.Id};
       String newCampaignId=String.valueOf(objCampaignNew.Id);
       String strCampaignMemberIds=JSON.serialize(lstCampaignMemberIds);
       String strmessage=MoveCampaignMembersController.moveCampaignMembers(strCampaignMemberIds,newCampaignId);
       System.assertEquals('SUCCESS',strmessage,'Error in moving campaign member');
       Test.stopTest();

    }

   /*
    *  @author Nishan Shetty
    *  @description Test method to cover catch block for moveCampaignMembers.
    */
    @isTest
    static void testMoveCampaignMembersCatchExeption() {
        
       Campaign objCampaignOld=[Select Id from Campaign where Name='testing3' Limit 1];
       Campaign objCampaignNew=[Select Id from Campaign where Name='testing4' Limit 1];
       CampaignMember objCampaignMember=[Select Id from CampaignMember where CampaignId=:objCampaignOld.Id]; 
       Test.startTest();
       List<Id> lstCampaignMemberIds=new List<Id>{objCampaignMember.Id};
       String newCampaignId=String.valueOf(objCampaignNew.Id);
       String strCampaignMemberIds=JSON.serialize(lstCampaignMemberIds);
       delete objCampaignNew;
       try {
         MoveCampaignMembersController.moveCampaignMembers(strCampaignMemberIds,newCampaignId);
       } catch (Exception e) {
         system.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error'); 
       }
       
       Test.stopTest();

    }


   /*
    *  @author Nishan Shetty
    *  @description Test method to cover catch block for getCampaignMembers.
    */
   @isTest
    static void testGetCampaignMembersCatchExeption() {
        
      Campaign objCampaign=[Select Id from Campaign where Name='testing3' Limit 1];
      Test.startTest();
      delete objCampaign;
      try {
         MoveCampaignMembersController.getCampaignMembers(objCampaign.Id);
      } catch(Exception e) {
         system.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error'); 
       }
    
      Test.stopTest();
    }



}
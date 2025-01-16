/***************************************************************************************************************************************
 * NAME   : TestCampaigns
 * DESCRIPTION  : TestClass for BatchToUpdateCampaignMemberStatus
 *                Updates Campaign member status from Registered to No Show if the campaign end date is passed
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 04-Oct-2018
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * 
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 




/*SeeAllData is set to true because the CamapignMemberStatus Values are available in Query only if SeeAlldata is true
All the required data is created in test class itself
*/
@isTest(SeeAllData = true)
public class TestBatchToUpdateCampaignMemberStatus{

    

 static testMethod void testBatchExecution(){
     Date dtDate=system.today();
        //Date dtEarlierDate=dtDate.addDays(-2);
        Date dtEarlierDate=dtDate.addDays(-1 * BatchToUpdateCampaignMemberStatus.INTEGER_NUMBER_OF_ELAPSED_DAYS_MIN);
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }
        system.runAs(u1){
            
            Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
            Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');
            
            Campaign objCampaign=new Campaign(name='testing',type='Webinar',EndDate=dtEarlierDate, Marketing_Segment__c = 'Cancer Research' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education' , Funnel__c='Top');
            insert objCampaign;
            
           //CampaignMember objCampaignMember=new CampaignMember(status='Registered');
           /*CampaignMember objCampaignMember=new CampaignMember(status=BatchToUpdateCampaignMemberStatus.STRING_CAMPAIGN_STATUS_REGISTERED);
           objCampaignMember.LeadId =objLead.id;
           objCampaignMember.CampaignId =objCampaign.id;
           insert objCampaignMember;*/
           CampaignMember objCampaignMember=TestDataMarketing.createCampaignMember(objLead.id,objCampaign.id,BatchToUpdateCampaignMemberStatus.STRING_CAMPAIGN_STATUS_REGISTERED);
           system.debug('i am --'+objCampaignMember);
            
            Test.startTest();
            BatchToUpdateCampaignMemberStatus bb=new BatchToUpdateCampaignMemberStatus();
            database.executebatch(bb);
			String sch = '0 0 23 * * ?';
            system.schedule('Test123'+system.now(), sch,bb);
            Test.stopTest();
            
            CampaignMember objCampaignMemberFinal=[select id,status from CampaignMember where campaignid=:objCampaign.id];
            system.assertEquals(objCampaignMemberFinal.Status,BatchToUpdateCampaignMemberStatus.STRING_CAMPAIGN_STATUS_NO_SHOW);
            
        }
     
 }

}
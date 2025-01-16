/***************************************************************************************************************************************
 * NAME   : TestCampaigns
 * DESCRIPTION  : TestClass for Campaign Trigger
 *                  Testing Create Member status Values
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 17-Sept-2018
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * 
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 



@isTest(SeeAllData=true)
/*SeeAllData is set to true because the CamapignMemberStatus Values are available in Query only if SeeAlldata is true*/

public class TestCampaigns{   
    
     static testMethod void testCampaignInsert(){
     Test.startTest();
     Id userId = userinfo.getUserId();
    User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
    if(u1.UserPermissionsMarketingUser==false){
        u1.UserPermissionsMarketingUser=true;
        update u1;
    }
    system.debug('user is='+u1.UserPermissionsMarketingUser);
        system.runAs(u1){
             Campaign objCampaign=new Campaign(name='testing',Type='Tele Prospecting / Sales Campaign');
            insert objCampaign;
            
            CampaignMemberStatus obj =new CampaignMemberStatus();
            obj.campaignid= objCampaign.id;
            obj.Label='New Reo';
            obj.IsDefault=false;
            obj.HasResponded=false;
            obj.SortOrder=13;
            insert obj;
                        
            objCampaign.Type='Test';
            objCampaign.Marketing_Segment__c = 'Microbiology';
            objCampaign.Marketing_Campaign__c = 'Brand';
            objCampaign.Program_Type__c = 'Education';
            update objCampaign;
            Campaign c=objCampaign.clone();
            insert c;
            Test.stopTest();
            campaign objcampain=[select id,type from campaign where id=:c.id];
            system.assertEquals('Test',objcampain.type);
        }
         
     }
}
/**
*    @author: Pankaj 
*    @date:   15-May-2019
*    @description:  Test Class for BatchCampaignStatusUpdate
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        15-May-2019        Initial Development   
*            Deep Diwakar                   Aug-13-2024        CMCM-9647: Added test method to validate exception block
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData=true)
/*SeeAllData is set to true because the CamapignMemberStatus Values are available in Query only if SeeAlldata is true
This is handled in Main class to prevent Real time data update*/
public class TestBatchCampaignStatusUpdate {
    static testMethod void testCampaignStatusUpdate(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }
        system.runAs(u1){
            Campaign objCampaign=new Campaign(name='TestCampaignBatch',Type='Tele Prospecting / Sales Campaign');
            objCampaign.StartDate=Date.today().AddDays(-2);
            objCampaign.EndDate=Date.today().AddDays(3);
            //objCampaign.IsActive=true;
            
            Campaign objCampaign2=new Campaign(name='TestCampaignBatch2',Type='Tele Prospecting / Sales Campaign');
            objCampaign2.StartDate=Date.today().AddDays(-32);
            objCampaign2.EndDate=Date.today().AddDays(-32);
            ObjCampaign2.IsActive=true;
            List<Campaign> lstCampaigns=new List<Campaign>{objCampaign,ObjCampaign2};
            insert lstCampaigns;
            Test.startTest();
            BatchCampaignStatusUpdate objBatch=new BatchCampaignStatusUpdate();
        	String sch='0 0 * * * ? *';
        	System.schedule('BatchCampaignStatusUpdatetest', sch , objBatch);
        	Database.executeBatch(new BatchCampaignStatusUpdate());
            Test.stopTest();
            Campaign objCmp1=[select id,name,isActive,status from campaign where id=:objCampaign.id];
            system.assertEquals('In Progress', objCmp1.status);
            Campaign objCmp2=[select id,isActive,name,status from campaign where id=:objCampaign2.id];
            system.assertEquals(false, objCmp2.isActive);
            system.assertEquals('Completed', objCmp2.status);
            
        }
    }

    @isTest
    static void testExceptionBlock() {

        Boolean isExceptionCaught = false;

        Campaign testWebinalCmp = new Campaign(name='TestCampaignBatch-Exception',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        testWebinalCmp.StartDate = Date.today().AddDays(-2);
        testWebinalCmp.EndDate = Date.today().AddDays(3);
        insert testWebinalCmp;

        // creating exception for testing

        try {
            Test.startTest();
            BatchCampaignStatusUpdate batchCmp = new BatchCampaignStatusUpdate();
            batchCmp.testExceptionBlock = true;
            Database.executeBatch(batchCmp);
            Test.stopTest();

        } catch(Exception ex) {
            System.debug('exception caught in test class');
            System.debug('exception message: ' + ex.getMessage());
            isExceptionCaught = ex.getMessage().contains('Test exception to test catch block');
        }

        Assert.isTrue(isExceptionCaught, 'Exception block for BatchCampaignStatusUpdate class did not work correctly');

    }
}
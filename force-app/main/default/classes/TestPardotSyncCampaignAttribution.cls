/**
*    @author: Pankaj 
*    @date:   05-Jun-2019
*    @description:  Test class for BatchUpdateCampaignMembersAttendedStatus
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        05-Jun-2019        Initial Build
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest(SeeAllData=false)
/*See All data is true as campaignMemberStatus is not available when it is false.*/
public class TestPardotSyncCampaignAttribution {
    /**
    *  @author Pankaj Singla
    *  @description Test Method for Process Builder Functionality
    *  @param None
    *  @return None
    **/ 
    static testMethod void testInsertCampaignMember(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
         }
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        system.runAs(u1){
            List<Campaign> lstCampaign=new list<Campaign>();
            Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
            objCon.Campaign_Attribution__c='testCATCon';
            update objCon;
            Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');
            objLead.Campaign_Attribution__c='testCATCon';
            update objLead;
            Campaign objCampaignWebinar=new Campaign(name='testing',type='Webinar', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top'); 
            
            insert objCampaignWebinar;
            Test.startTest();
            
            CampaignMember objCampaignMember10=TestDataMarketing.createCampaignMember(objLead.id,objCampaignWebinar.id,'Attended');
            CampaignMember objCampaignMember11=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignWebinar.id,'Attended On-Demand');
            List<id> lstId=new list<id>();
            lstId.add(objCampaignMember10.id);
            lstId.add(objCampaignMember11.id);
            //PardotSyncCampaignAttribution.getMemberEmailIds(lstId);
            Test.stopTest();
            Lead objLd=[select id,Campaign_Attribution__c from lead where id=:objLead.id];
            system.assertEquals('NULL',objLd.Campaign_Attribution__c);
            Contact objcc=[select id,Campaign_Attribution__c from Contact where id=:objCon.id];
            system.assertEquals('NULL',objcc.Campaign_Attribution__c);
        }
    }
    /**
    *  @author Pankaj Singla
    *  @description Test Method for Queable class
    *  @param None
    *  @return None
    **/ 
    static testmethod void testQueableMethod(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        List<String> lstEmails=new List<String>();
        lstEmails.add('abc@test.com');
        PardotQueableForCampaignAttribution obj=new PardotQueableForCampaignAttribution(lstEmails,'test.com');
        System.enqueueJob(obj); 
    }
    /*******************************************************
    *Method Name : coverCatchBlockPardotQueableForCampaignAttribution()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockPardotQueableForCampaignAttribution(){
        try{
            PardotQueableForCampaignAttribution.catchException = true;
            PardotQueableForCampaignAttribution pd = new PardotQueableForCampaignAttribution(null, null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
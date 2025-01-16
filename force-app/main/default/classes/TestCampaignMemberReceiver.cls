/**
 * @author Roopal Verma
 * @date   2020-01-17
 * @description    Campaign Member Synchronization to DCP
 * Modification Log:
 *       ------------------------------------------------------------------------------------
 *       Roopal Verma        17/01/2020            Original Version
 * */
 @isTest
public class TestCampaignMemberReceiver {

    /**Method - testData used for Test Data setup */
	@TestSetup
	public static void testData(){

		Product2 product = TestDataMaster.createProduct(false);
		product.Zuora_Product_ID__c = '123abc';
		insert product;

		Contact objContact = TestDataMarketing.createContactForMarketable('test','name1','abc@cde.com','US');
		objContact.PGUID__c = '111222';
		insert objContact;

		Lead objLead = TestDataMarketing.createLeadForMarketable('test','name2','aaa@bbb.com','USA','Illumina');
		objLead.PGUID__c = '333444';
		insert objLead;

		Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
         }
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
        objCampaign.Product__c = product.id;
        update objCampaign;			
      }
		
	}

	static testMethod void testCampMemberInsertWithContactHTTPPost(){

		FreeTrialCreateWrapper.CampaignMemberWrapper campMemberWrapper = new FreeTrialCreateWrapper.CampaignMemberWrapper();
		campMemberWrapper.Free_Trial_Start_Date = '2019-12-13';
		campMemberWrapper.Free_Trial_iCredit_Balance = '29988';
		campMemberWrapper.Free_Trial_End_Date = '2020-12-13';
		campMemberWrapper.Free_Trial_Subscription_ID = '111223344';
		campMemberWrapper.Zuora_Product_Id = '123abc';
		campMemberWrapper.PGUID = '111222';
        campMemberWrapper.Subscription_Status = 'status';

		String campMemberJSON = JSON.serialize(campMemberWrapper);
        system.debug('Quotes JSON : '+ campMemberWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/FreeTrialCreateInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(campMemberJSON);
        RestContext.request = req;
        RestContext.response= res;
        CampaignMemberDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode); 
	}

	static testMethod void testCampMemberInsertWithLeadHTTPPost(){

		FreeTrialCreateWrapper.CampaignMemberWrapper campMemberWrapper = new FreeTrialCreateWrapper.CampaignMemberWrapper();
		campMemberWrapper.Free_Trial_Start_Date = '2019-12-13';
		campMemberWrapper.Free_Trial_iCredit_Balance = '29988';
		campMemberWrapper.Free_Trial_End_Date = '2020-12-13';
		campMemberWrapper.Free_Trial_Subscription_ID = '111223344';
		campMemberWrapper.Zuora_Product_Id = '123abc';
		campMemberWrapper.PGUID = '333444';
        campMemberWrapper.Subscription_Status = 'status';

		String campMemberJSON = JSON.serialize(campMemberWrapper);
        system.debug('Quotes JSON : '+ campMemberWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/FreeTrialCreateInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(campMemberJSON);
        RestContext.request = req;
        RestContext.response= res;
        CampaignMemberDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode); 
	}

	static testMethod void testCampMemberRestErrorHTTPPost(){

		FreeTrialCreateWrapper.CampaignMemberWrapper campMemberWrapper = new FreeTrialCreateWrapper.CampaignMemberWrapper();
		campMemberWrapper.Free_Trial_Start_Date = null;
		campMemberWrapper.Free_Trial_iCredit_Balance = null;
		campMemberWrapper.Free_Trial_End_Date = null;
		campMemberWrapper.Free_Trial_Subscription_ID = null;
		campMemberWrapper.Zuora_Product_Id = null;
		campMemberWrapper.PGUID = null;
        campMemberWrapper.Subscription_Status = null;

		String campMemberJSON = JSON.serialize(campMemberWrapper);
        system.debug('Quotes JSON : '+ campMemberWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/FreeTrialCreateInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(campMemberJSON);
        RestContext.request = req;
        RestContext.response= res;
        CampaignMemberDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(412,res.statuscode); 
	}
}
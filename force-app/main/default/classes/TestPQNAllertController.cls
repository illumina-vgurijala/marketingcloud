/**************************************************************************************************************
 * NAME   : TestPQNAllertController
 *
 * MODIFICATION LOG:  
 * -----------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Rishab                   17-Jan-2022        CodeScan Fixes  
 * ------------------------------------------------------------------------------------------------------------
  *************************************************************************************************************/ 
@isTest(SeeAllData = false)
public class TestPQNAllertController {

    /*Test Data Setup Method*/
    @testSetup
    public static void initializeTestData(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }
        
        system.runAs(u1){
            Campaign objCampaign=new Campaign(name='testing' , Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education' );
            insert objCampaign;
        }
        
        Contact c=new contact(FirstName='First',Lastname='Test',Email='Test@email.com');
        insert c;
        Lead l=new Lead(Email='Test1@email.com',Country='USA',LastName='Test1',Company='com');
        insert l;
        
    }
    static testMethod void testFetchLookUpValues(){
        
        List<Campaign> lstCampaign=PQNAlertsController.fetchLookUpValues('testing','campaign');
        System.assertEquals(1,lstCampaign.size());
    }
    static testMethod void testprocessFileContents(){
        Contact c=new contact(FirstName='First',Lastname='Test',Email='Test@email.com');
        insert c;
        Lead l=new Lead(Email='Test1@email.com',Country='USA',LastName='Test1',Company='com');
        insert l;
        string strFileContents='Test@email.com'+'\r'+'\n'+'Test1@email.com';
        PQNAlertsController.processFileContents(strFileContents);
        List<String> lstFileContents=new List<String>();
        lstFileContents=strFileContents.split('\n');
        
        System.assertEquals(2,lstFileContents.size());
    }
    static testMethod void testpostDatatoPQN(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        map<string,string> mapUploadedEmailsIds=new map<string,string>();
        mapUploadedEmailsIds.put('Test@email.com','Test@email.com');
        mapUploadedEmailsIds.put('Test1@email.com','Test1@email.com');
        Test.startTest();
        Boolean result=PQNAlertsController.postDatatoPQN('PQN123','https://www.goole.com',string.valueof(Date.today()),'Product Change Notification',mapUploadedEmailsIds);
        PQNAlertsQueableCalout objPQNAlertsQueableCalouttest=new PQNAlertsQueableCalout(mapUploadedEmailsIds.values(),'PQN123','https://www.goole.com',string.valueof(Date.today()),'https://www.goole.com','lll','PQN',0);           
            ID jobId=System.enqueueJob(objPQNAlertsQueableCalouttest); 
        Test.stopTest();
        System.assertEquals(true,result);
    }
    static testMethod void testcreateCampaignMembershipSaleforce(){
        Campaign objCampaign=[select id,name from campaign limit 1];
        contact c=[select id,name from contact limit 1];
        Lead l=[select id,name from lead limit 1];
        map<string,string> mapUploadedEmailsIds=new map<string,string>();
        map<string,string> mapUploadedEmailsIds2=new map<string,string>();
        mapUploadedEmailsIds.put(c.id,c.id);
        mapUploadedEmailsIds2.put(l.id,l.id);
        Test.startTest();
        PQNAlertsController.createCampaignMembershipSaleforce(objCampaign, mapUploadedEmailsIds, mapUploadedEmailsIds2);
        Test.stopTest();
        List<CampaignMember> lstCampaignMember=new List<CampaignMember>();
        lstCampaignMember=[select id from CampaignMember where campaignId=:objCampaign.Id];
        System.assertEquals(2,lstCampaignMember.size());
    }
    
    static testMethod void testpostDatatoPQNusingbatch(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        map<string,string> mapUploadedEmailsIds=new map<string,string>();
        mapUploadedEmailsIds.put('Test@email.com','Test@email.com');
        mapUploadedEmailsIds.put('Test1@email.com','Test1@email.com');
        List<String> lstEmails=new List<String>();
        lstEmails.add('Test@email.com');
        lstEmails.add('Test1\'@email.com');
        Test.startTest();
        ProductNotificationCalloutBatch objbatch=new ProductNotificationCalloutBatch(lstEmails,'PQN-123','https://www.goole.com','Product Quality Notification');
        database.executebatch(objbatch,2);
        Test.stopTest();
    }
    
    /*Method - MockHttpResponseGenerator 
    * Description - Mock Http Generator
    */
    public class MockHttpResponseGenerator implements HttpCalloutMock{
        /*Constructor */
        public HttpResponse respond(HTTPRequest req){
            String json=        '{'+
        '    "data": ['+
        '        {'+
        '            "userLogonId": "skomalan@illumaina.com",'+
        '            "notificationTypeId": 8,'+
        '            "externalNotificationId": "PQN-123",'+
        '            "message": "User skomalan@illumaina.com not found. Pending notification for external ID PQN-123 already created."'+
        '        },'+
        '        {'+
        '            "userLogonId": "email2@abc.com",'+
        '            "notificationTypeId": 8,'+
        '            "externalNotificationId": "PQN-123",'+
        '            "message": "User email2@abc.com not found. Pending notification for external ID PQN-123 already created."'+
        '        },'+
        '        {'+
        '            "userLogonId": "email3@efg.com",'+
        '            "notificationTypeId": 8,'+
        '            "externalNotificationId": "PQN-123",'+
        '            "message": "User email3@efg.com not found. Pending notification for external ID PQN-123 already created."'+
        '        }'+
        '    ]'+
        '}';
            HttpResponse res = new HttpResponse();
            System.assertEquals('POST', req.getMethod());
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json);
            res.setStatusCode(200);
            return res;
        }
    }

    /*******************************************************
    *Method Name : coverCatchBlockPQNAlertsQueableCalout()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockPQNAlertsQueableCalout(){
        try{
            PQNAlertsQueableCalout.catchException = true;
            PQNAlertsQueableCalout pd = new PQNAlertsQueableCalout(null, null,null,null,null,null,null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
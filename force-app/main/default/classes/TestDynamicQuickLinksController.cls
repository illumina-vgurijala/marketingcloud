/*@ author       : Prakhar
* @ date         : 16-08-2019
* @ Description  : Test class for DynamicQuickLinksController
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Prakhar Kumar          16-08-2019                US-28546           Initial version
* Prakhar Kumar          22-08-2019                US-28546           Added RecordType=Slides
*/
@IsTest(SeeAllData=false)
global with sharing class TestDynamicQuickLinksController{

    @testSetup
	/* Test Data*/
    public static void initializeTestData()
    {
	
		Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Partner_Portal_Content__c; 
        Map<String,Schema.RecordTypeInfo> mapPPCRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 
        Id rtId = mapPPCRecordTypeInfo.get('Slides').getRecordTypeId();
        Id rtId1 = mapPPCRecordTypeInfo.get('help').getRecordTypeId();
	
        Partner_Portal_Content__c ppc = new Partner_Portal_Content__c ();
        ppc.Active__c = true;
		ppc.recordtypeid = rtId;
        ppc.Quick_Links_URL__c = 'https://www.google.com/';
        insert ppc;
        
        Partner_Portal_Content__c ppc1 = new Partner_Portal_Content__c ();
        ppc1.Active__c = true;
		ppc1.recordtypeid = rtId;
        ppc1.Quick_Links_URL__c = 'https://www.fb.com/';
        insert ppc1;
        
        Partner_Portal_Content__c ppc2 = new Partner_Portal_Content__c ();
        ppc2.Active__c = true;
		ppc2.recordtypeid = rtId;
        ppc2.Quick_Links_URL__c = '';
        ppc2.Video_URL__c ='https://www.youtube.com/embed/6an5U-Fpc5o';
        insert ppc2;

        Partner_Portal_Content__c ppc3 = new Partner_Portal_Content__c ();
        ppc3.Active__c = true;
        ppc3.recordtypeid = rtId1;
        ppc3.Button_Text__c = 'Hello 1';
        ppc3.Button_URL__c ='https://www.google.com';
        ppc3.Button_Visible__c = true;
        ppc3.Sort_Order__c = 10;   
    }

    @isTest
     /*
    * 
    * Test Methods
    *
    */
    Static void testmethodDynamicQuickLinksController(){  
     initializeTestData(); 
     Test.startTest();
         DynamicQuickLinksController.getDynamicQuickLinks();
         DynamicQuickLinksController.getActiveVideoLink();
         DynamicQuickLinksController.fetchMethod();
     Test.stopTest();
    List<Partner_Portal_Content__c>   ppcList = [select Active__c,Quick_Links_URL__c  from Partner_Portal_Content__c where Region__c = '' AND Active__c = TRUE];
    integer no = ppcList.size();
    System.assertEquals (6,no);

    }
    
 }
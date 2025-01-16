/***************************************************************************************************************************************
 * NAME         : TestPartnerPortalContentFetchSlides
 * DESCRIPTION  : TestClass for PartnerPortalContentFetchSlides
 * DCP-12261    : Fetch and allocate the slides to the logged in user on basis of Region
 *                
 *    
 * @AUTHOR : Prakhar
 * @DATE   : 16-Jun-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prakhar             16-Jun-2018            Initial Version
  ****************************************************************************************************************************************/ 

@IsTest(SeeAllData=true)
global with sharing class  TestPartnerPortalContentFetchSlides{
    
    static testMethod  void testCarousel (){
        List<Partner_Portal_Content__c> lstCarousel=TestDataPartnerPortal.getNewSlides(1);
        List<Partner_Portal_Content__c> lstSlides=TestDataPartnerPortal.getNewSlides(4);
        
           
        Id profileId = [select id from profile where name=: Label.Channel_Partner_Profile_Name].id;
       
        Account ac =TestDataAccount.initAccount();
        ac.Territory_Region__c='AMR';
        insert ac;
        Contact con =TestDataContact.getNewContact(ac);
       // insert con;  
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;   
        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
       
        insert user;
        
        System.debug('test data '+user.Contact + user.Contact.AccountId);
        
        Account objAccount=[SELECT Id,Territory_Region__c FROM Account WHERE Id = :ac.id LIMIT 1];          
        
        //perform the test
        Test.startTest();      
        System.runAs (user){
            PartnerPortalContentFetchSlides.loadCarousel();
            System.assertEquals(4,lstSlides.Size()); 
            System.assertEquals(1,lstCarousel.Size());   
            System.assertNotEquals('',objAccount.Territory_Region__c); 
        } 
        
          
        Profile p1 = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = uniqueName.substring(18, 23), email=uniqueName + '@test1' + orgId + '.org',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', username=uniqueName + '@test1' + orgId + '.org');

 
        System.runAs(u){
            PartnerPortalContentFetchSlides.loadCarousel();
            System.assertEquals(4,lstSlides.Size()); 
            System.assertEquals(1,lstCarousel.Size());    
        } 
        Test.stopTest(); 
    }
}
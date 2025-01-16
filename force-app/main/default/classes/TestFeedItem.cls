/**
 *    @author Anisha Bharti
 *    @date   19-Nov-2020
 *    @description  Test class of FeedItem
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *  
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestFeedItem {
    
    public static final String VALIDATIONSTATUS_PENDINGREVIEW = 'Pending Review';
    public static final String REVIEWSTATUS_PENDINGREVIEW = 'Pending Review - Review Not Started';
    public static final Id FAQ_RECORD_TYPE_ID = Schema.SObjectType.Knowledge__Kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
    public static final String REVIEWSTATUS_REVIEWCOMPLETE = 'Review Completed';
    
    /*
    *@author: Anisha Bharti
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData(){
        Knowledge__kav know = new Knowledge__kav();
        know.Article_Body__c = 'I am the Article body';
        know.Title = 'New "Article"';
        know.Summary = 'Test Article Summary';
        know.UrlName = 'New--Article';
        know.Primary_Workflow__c = 'Instrumentation';
		know.Secondary_Workflow__c = 'Instrumentation';
        know.Article_Version_Author__c = userinfo.getuserid();
        Know.RecordtypeId = FAQ_RECORD_TYPE_ID;
        insert know;
        
        Feedback__c feed = new Feedback__c();
        feed.Knowledge_Article_Link__c = know.id;
        feed.Feedback_Status__c = 'Open';
        feed.Feedback_Disposition__c = 'New';
        feed.Feedback_Reason__c = 'Sequencing';
        insert feed;        
    }
    
    /**
    *    @author Anisha Bharti
    *    @date   20-Nov-2020
    *    @test Method onafterinsert of FeedItem
    */
    @isTest
    static void testonafterinsert(){
        Feedback__c feed = [select id, name, ownerid from feedback__c LIMIT 100];
       
        Test.startTest();
            user newOwner = [Select id, name, email, isactive, profile.name, userrole.name, usertype from user where Profile.name = 'System Administrator' AND id != :userinfo.getUserId() AND IsActive = TRUE LIMIT 1];
                  
            Feedback__c objFB = new Feedback__c();   
            objFB.Id = feed.Id;
            objFB.OwnerId = newOwner.Id;
            update objFB;

            FeedItem fItem = new FeedItem();
            fItem.ParentId = feed.Id;
            fItem.Body = 'Tests';
            insert fItem;

            system.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    static String getRandomString() {
        String strHashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob bbHash = Crypto.generateDigest('MD5', Blob.valueOf(strHashString));
        String strHexDigest = EncodingUtil.convertToHex(bbHash);
        return strHexDigest;
    }

}
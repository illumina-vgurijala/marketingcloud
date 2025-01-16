/**
* @author Shivani Jain
* @date 4 April 2022
*
* @description DCP-49914 Test class for ToggleUnreadEmailController
*/ 
@IsTest
private class TestToggleUnreadEmailController {
 
    static final string TYPE_WECHAT = 'WeChat Comment';
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';
    /*******************************************************************************************************
    * @description initialize data for test class
    */
    @TestSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();

        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        System.assert(con.Id != NULL, 'Contact insertion failed');

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != NULL, 'Case insertion failed');

        Comment__c commentRec = new Comment__c();
        commentRec.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        commentRec.Name = 'Sent by Test User';
        commentRec.Case__c = cs.Id;
        commentRec.Comment__c = 'Test Comment';
        commentRec.Type__c = TYPE_WECHAT;
        insert commentRec;
        System.assert(commentRec.Id != NULL, 'Comment insertion failed');
    }

    /*******************************************************************************************************
    * @description test method for checkRelatedWeChatComments
    */
    static testmethod void checkRelatedWeChatCommentsTest() {
        Case caseRec = [SELECT id FROM Case LIMIT 1];

        Test.startTest();
        Boolean unreadEmailValue = ToggleUnreadEmailController.checkRelatedWeChatComments(caseRec.Id);
        Test.stopTest();
        System.assert(!unreadEmailValue, 'checkRelatedWeChatComments failed');

    }

    /**
    * @description: Test Method to test Catch block
    * @author Rohan Rathod | 09-27-2022 
    **/
    @isTest static void checkExceptionWeChatComments(){       
        Id profileId = [select id from profile where name='Channel Partner Sales Login'].id;
         
        Account ac =TestDataAccount.initAccount();
        ac.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
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
                timezonesidkey=STRING_TIMEZONE, username=uniqueName + '@test' + orgId + '.org');
       
        insert user;


        Case caseRec = [SELECT id FROM Case LIMIT 1];                   
        System.runAs(user)
        {  
            Test.startTest();
                try{
                    ToggleUnreadEmailController.checkRelatedWeChatComments(caseRec.Id);
                }
                catch(Exception ee){
                    System.assert(ee.getMessage().contains('Exception'),'Exception not verified');
                }                  
            Test.stopTest();
        }
    }

}
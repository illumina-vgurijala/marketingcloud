/***************************************************************************************************************************************
* NAME   : TestChatSessionFlow
* DESCRIPTION :  To test the  after  update/insert flow SC_Create a Inquiry case for session to map account and contact for the customer (WINP__Talk_Session__c)
*    
* @AUTHOR : Nitin Zagade
* @DATE   : 29- jul-2024  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

@IsTest
public class TestChatSessionFlow {
    
    /**
    * Method to test Post on QA Reopen Flow
    **/
    @IsTest
    public static void testUpdateCustomerContact() {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
		
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;    
       
        WINP__Messanger__c messager= new WINP__Messanger__c();
        messager.Name='KakaoTalk';
        messager.WINP__MappingKey__c='Phone';     
        insert messager;
    
        WINP__Channel__c channelTest= new WINP__Channel__c();
        channelTest.Name='Demo';
        channelTest.WINP__Messanger__c=messager.id;
        insert channelTest;
        System.assert(channelTest.ID != null, true);
    
        WINP__Talk_Customer__c customer= new WINP__Talk_Customer__c();
        customer.WINP__Channel__c=channelTest.Id;
        customer.WINP__UserKey__c='testUser';
		customer.WINP__Status__c='AutoResponse';
        insert customer;
        
        WINP__Talk_Session__c chatSession= new WINP__Talk_Session__c();
        chatSession.Name='Test';
        chatSession.WINP__Talk_Customer__c=customer.Id;
		chatSession.WINP__Status__c='AutoResponse';
        insert chatSession;
        
        
        List<WINP__Talk_Session__c>  chatSessionList=[Select WINP__Talk_Customer__c,WINP__Status__c,WINP__Case__c from WINP__Talk_Session__c limit 1];
        Case updatedCase = [Select ContactId,SuppliedName,Subject,Status,RecordTypeId,OwnerId,Origin,Description from Case where Id =: chatSessionList[0].WINP__Case__c limit 1];

        System.assertEquals(updatedCase.ID, chatSessionList[0].WINP__Case__c);
        System.assertEquals( 'Kakaotalk',updatedCase.Origin);
        System.assertEquals(updatedCase.RecordTypeId, recordTypeId);
        
        customer.WINP__PhoneNumber__c='1234567890';
        update customer;
        chatSession.WINP__Status__c='Chatting';
        update chatSession;
        Test.startTest();
        updatedCase = [Select ContactId,SuppliedName,Subject,Status,RecordTypeId,OwnerId,Origin,Description from Case where Id =: chatSessionList[0].WINP__Case__c limit 1];
        System.assertEquals(updatedCase.ContactId, con.ID);

        Test.stopTest();

           
    }

}
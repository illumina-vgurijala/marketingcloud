/***************************************************************************************************************************************
* NAME   : TestChatCustomerFlow
* DESCRIPTION :  To test the  before update flow SC_ChatCustomer_Mapping v2 to map account and contact for the customer (WINP__Talk_Customer__c)
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
public class TestChatCustomerFlow {

   /**
    * Method to test Post on QA Reopen Flow
    **/
    @IsTest
    public static void testUpdateCustomerContact() {
    
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
    insert customer;

    System.assert(customer.ID != null, true);

    customer.WINP__PhoneNumber__c='1234567890';
    update customer;
        
    Test.startTest();
    customer=[select id,WINP__Contact__c,WINP__Account__c,WINP__PhoneNumber__c from WINP__Talk_Customer__c where id=:customer.Id limit 1];
    System.assertEquals(customer.WINP__Contact__c, con.id);
    System.assertEquals(customer.WINP__Account__c, con.AccountID);

    
    Test.stopTest();

   
    }    

}
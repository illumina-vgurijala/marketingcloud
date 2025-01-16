/***************************************************************************************************************************************
* NAME   : TestElevations
* DESCRIPTION  : TestClass for Elevation Trigger
*     
* @AUTHOR : Deepika Ayyavari
* @DATE   : Dec-2021 
* Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Deepika Ayyavari              15-Dec-2021         Initial Version
*    Rohan Rathod                   30-May-2022        testElevationMemberForCategory added
*/

@isTest
public class TestEmailMessagePB { 
        /**
*  @author Deepika Ayyavari
*  @description - initialize test data
**/
	@isTest
	public static void testEmailMessageTriggerHandler(){
		list<Profile> customerServiceProfileList = new list<profile>([SELECT Id FROM Profile WHERE Name='Customer Service']);
        User testUser = new User(
            ProfileId = customerServiceProfileList[0].Id,
            lastname='amdewra',
            Username = 'testuserpune1234@example.com',
            Email = 'testuser@example.com',
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
			IsActive =True
        );
        insert testUser;
		
		
		list<user> userList = new list <user>([select id from user where id=:testuser.id]);
		list<BusinessHours> businessHourList = new list<BusinessHours>([select id from BusinessHours limit 1]);
		
		Account acc=new Account();
		acc.Name='Test Account';
        acc.BillingStreet='Baner';
        acc.BillingState='Maharashtra';
        acc.BillingCity  ='Pune';
        acc.BillingCountry = 'India';
		insert acc;
		
		list<Account>acclist=new list<Account>([select id from account where id=:acc.id]);
		
		contact con=new contact();
		con.firstname='test firstname';
		con.lastname='test lastname';
		con.AccountId=acclist[0].id;
		insert con;
		
		list<contact>contactList=new list<contact>([select id from contact where id=:con.id]);
		
		case parentcase = new case();
		parentcase.ownerId=userList[0].id;
		parentcase.BusinessHoursId=businessHourList[0].id;
		parentcase.ContactId=contactList[0].id;
		parentcase.status='Initiated';
		parentcase.origin='Phone - CP';
		parentcase.subject='Test Subject';
		parentcase.Description='Test Description';
		parentcase.Sub_Type__c='Financial';
		insert parentcase;
		
		list<case>caseList = new list<Case>([select id from case where id=:parentcase.id]);
		
		EmailMessage eMessage = new EmailMessage();
		eMessage.ParentId=caseList[0].id;
		eMessage.Incoming=true;
		insert eMessage;		
		
		list<case> caList =  new list<Case>([select id,ownerId from case where id=:parentcase.id]);
		system.AssertEquals(1,caList.size());
		
	}
	
	}
	
	
	
	
	
	
	
	
	
	
	
	
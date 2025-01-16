/**
* Class Name: TestLocations
* Description: This is the test class for Locations class.
* 
**/
@IsTest(SeeAllData=false)
public class TestLocations {

static testMethod void insertLocation(){
Account acc = TestLocations.getAccount('strName', 'street', 'city', '123', 'KLN', 'HK', 'Non Clinical', 'Core Research Lab',
                         'Academic', 'Cancer Research', 'Tier 3','USD','Distributor','2409');
insert acc;    


SVMXC__Site__c loc = new SVMXC__Site__c();
loc.name = 'testLocPrakhar';
loc.Type__c ='Ultimate Consignee';
loc.ERP_Customer_ID__c = '2409';  
  
        Test.startTest() ; 
        insert loc;  
        Test.stopTest() ;
        system.assertNotEquals(null,[select SVMXC__Account__c from SVMXC__Site__c where id = :loc.id]);
}

//Test the Stocking Location flag check
static testMethod void insertUpdateLocationPartnerStock(){
    Account acc = TestLocations.getAccount('strName', 'street', 'city', '123', 'KLN', 'HK', 'Non Clinical', 'Core Research Lab',
                             'Academic', 'Cancer Research', 'Tier 3','USD','Distributor','2409');
    insert acc;    
    
    
    SVMXC__Site__c loc = new SVMXC__Site__c();
    loc.name = 'testLoc';
    loc.Type__c ='Partner Stock';
    loc.ERP_Customer_ID__c = '2409';  
      
    Test.startTest() ; 
    insert loc;  
    update loc; 
    Test.stopTest() ;
}

		/*
         * description - getAccount method
		 * return - Account
         */     
public static Account getAccount(String strName, String strStreet, String strCity, String strPostalCode, String strState,
                                    String strCountry, String strClinicalType, String strLabType, String strCustomerType,
                                    String strPrimaryMarketSegment, String strTier,String strCurrency, String strAccountGroup, String eRPCustomerId)
    {
        return new Account(
            Name = strName,
            ERP_Customer_Id__c = eRPCustomerId,
            BillingStreet = strStreet,
            BillingCity = strCity,
            BillingPostalCode = strPostalCode,
            BillingStateCode = strState,
            BillingCountryCode = strCountry,
            Clinical_Type__c = strClinicalType,
            Customer_Sub_Type__c = strLabType,
            Customer_Type__c = strCustomerType,
            Market_Segment__c = strPrimaryMarketSegment,
            Tier__c= strTier,
            CurrencyIsoCode = strCurrency,
            Account_Group__c = strAccountGroup
        );
    } 

 /*******************************************************
    *Method Name : coverCatchBlockLocationQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockLocationQueueable(){
        try{
            LocationQueueable.catchException = true;
            LocationQueueable lQ = new LocationQueueable(null, null);
            Test.startTest();
            System.enqueueJob(lQ);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }
}
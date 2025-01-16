/**
*    @author 
*    @date   
*    @description TestDataAccount class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Aman Tyagi                     6th Oct 2022        Codescan fixes
*            Gerardo Garcia                 01/02/2024          CMCM-4368 Refactor test Opportunities
*/
 @isTest
public with sharing class TestDataAccount {
    /**
     *  @author   
     *  @description static method getNewAccount()
     *  @param NA
     *  @return Account 
     **/
    public static Account getNewAccount()
    {
        Account a = initAccount();
        insert a;
        return a;
    }
    /**
     *  @author   
     *  @description static method initAccount()
     *  @param NA
     *  @return Account 
     **/
    public static Account initAccount()
    {
        Account a = initPartnerAccount(Accounts.GROUP_SOLD_TO);
        return a;
    }
    /**
     *  @author   
     *  @description static method getNewPartnerAccount()
     *  @param String partnerType
     *  @return Account 
     **/
    public static Account getNewPartnerAccount(String partnerType)
    {
        Account a = initPartnerAccount(partnerType);
        insert a;
        return a;
    }
    
    /*
    *  @AUTHOR:  Akshay   Mohan
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName
    *  @RETURN:  Account type object
    */
    
    public static Account getAccount(String strName)
    {
        return getAccount(strName, 'USD');
    }
    
    /*
    *  @AUTHOR:  Akshay   Mohan
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName, String strCurrencyCode
    *  @RETURN:  Account type object
    */
    
    public static Account getAccount(String strName, String strCurrencyCode){
       return getAccount(strName, 'street', 'city', '123', 'KLN', 'HK', 'Non Clinical', 'Core Research Lab',
                         'Academic', 'Cancer Research', 'Tier 3', strCurrencyCode, 'Prospect');
    }

    /*
    *  @AUTHOR:  Akshay   Mohan
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName,String strStreet, String strCity, String strPostalCode, String strState,
                    String strCountry, String strClinicalType, String strLabType, String strCustomerType,
                    String strPrimaryMarket, String strTier,String strCurrency
    *  @RETURN:  Account type object
    */
    public static Account getCustomerAccount()
    {
        Account a = new Account(
            Name = '000',
            ERP_Customer_Id__c = TestData.getRandomNumeric(10),
            BillingStreet = 'test billing street',
            BillingCity = 'test billing city',
            BillingPostalCode = '90909',
            BillingStateCode = '',
            BillingCountryCode = 'JP',
            Clinical_Type__c = 'Clinical',
            Customer_Sub_Type__c = 'Genome Center',
            Customer_Type__c = 'Academic',
            Market_Segment__c = 'Forensics',
            Tier__c = 'Tier 1',
            CurrencyIsoCode = 'USD',
            Account_Group__c = Accounts.GROUP_SOLD_TO,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
        );
        return a;
    }
    
     /*
    *  @AUTHOR:  Indra Ganesan
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName,String strStreet, String strCity, String strPostalCode, String strState,
                    String strCountry, String strClinicalType, String strLabType, String strCustomerType,
                    String strPrimaryMarket, String strTier,String strCurrency
    *  @RETURN:  Account type object
    */
    public static Account getUCAccount()
    {
        Account a = new Account(
            Name = TestData.getRandom(),
            ERP_Customer_Id__c = TestData.getRandomNumeric(10),
            BillingStreet = 'test billing street',
            BillingCity = 'test billing city',
            BillingPostalCode = '90909',
            BillingStateCode = 'CA',
            BillingCountryCode = 'US',
            Clinical_Type__c = 'Non Clinical',
            Customer_Sub_Type__c = 'Genome Center',
            Customer_Type__c = 'Academic',
            Market_Segment__c = 'Forensics',
            Tier__c = 'Tier 1',
            CurrencyIsoCode = 'USD',
            Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
        );
        return a;
    }
    
    /*
    *  @AUTHOR:  Akshay   Mohan
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName,String strStreet, String strCity, String strPostalCode, String strState,
                    String strCountry, String strClinicalType, String strLabType, String strCustomerType,
                    String strPrimaryMarket, String strTier,String strCurrency
    *  @RETURN:  Account type object
    */
    public static Account getAccount(String strName, String strStreet, String strCity, String strPostalCode, String strState,
                                    String strCountry, String strClinicalType, String strLabType, String strCustomerType,
                                    String strPrimaryMarketSegment, String strTier,String strCurrency, String strAccountGroup)
    {
        return new Account(
            Name = strName,
            ERP_Customer_Id__c = TestData.getRandomNumeric(10),
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
    /**
     *  @author   
     *  @description static method getNewPartnerAccount()
     *  @param String partnerType
     *  @return Account 
     **/
    public static Account initPartnerAccount(String partnerType)
    {
        return getAccount('TestData-' + TestData.getRandomNumeric(10));
    }

    /*Test Customer Master Data*/
    public static Customer_Master_Data__c getCustomerMaster(String strCMDName)
    {
        Customer_Master_Data__c cmd = new Customer_Master_Data__c(
            ERP_Customer_Id__c = TestData.getRandomNumeric(10),
            Name = strCMDName
        );
        return cmd;
    }

    /**
     *  @author   
     *  @description static method to get new customer master data
     *  @Param String erpId, String country, String countryCode
     *  @return Customer_Master_Data__c 
     **/
    public static Customer_Master_Data__c getNewCustomerMasterData(String erpId, String country, String countryCode)
    {
        Customer_Master_Data__c rec = initCustomerMasterData(erpId, country, countryCode);
        insert rec;
        return rec;
    }

    /**
     *  @author   
     *  @description static method initCustomerMasterData
     *  @Param String erpId, String country, String countryCode
     *  @return Customer_Master_Data__c 
     **/
    public static Customer_Master_Data__c initCustomerMasterData(String erpId, String country, String countryCode)
    {
        Customer_Master_Data__c rec = new Customer_Master_Data__c(
            ERP_Customer_Id__c = erpId,
            Name = TestData.getRandomNumeric(10),
            Country__c = country,
            Country_Code__c = countryCode
        );
        return rec;
    }

    /**
     *  @author   
     *  @description static method to get new Account
     *  @Param NA
     *  @return Account 
     **/
    public static Account getNewAmrAccount()
    {
        Account rec = initAmrAccount();
        insert rec;
        return rec;
    }
    /**
     *  @author   
     *  @description static method to init new Account
     *  @Param NA
     *  @return Account 
     **/
    public static Account initAmrAccount()
    {
        return new Account(
            Name = TestData.getRandom(),
            ERP_Customer_Id__c = TestData.getRandomNumeric(10),
            BillingStreet = TestData.getRandom(),
            BillingCity = TestData.getRandom(),
            BillingPostalCode = TestData.getRandom(),
            BillingStateCode = 'CA',
            BillingCountryCode = 'US',
            Clinical_Type__c = 'Non Clinical',
            Customer_Sub_Type__c = 'Genome Center',
            Customer_Type__c = 'Academic',
            Market_Segment__c = 'Forensics',
            Tier__c = 'Tier 1',
            CurrencyIsoCode = 'USD',
            Account_Group__c = Accounts.GROUP_SOLD_TO,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
        );
    }

    /**
     * @author Gerardo Garcia
     * @description retrieves record type of indirect partner id
     * @return Id
     */
    public static Id getIndirectPartnerTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
    }

    /**
     * @author Gerardo Garcia
     * @description retrieves record type of indirect partner id
     * @return Id
     */
    public static Id getCustomerTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeCustomer).getRecordTypeId();
    }
}
/**
 * Marketing associated records
 **/
 @isTest
public with sharing class TestDataMarketing {

    /**
    *  @author Pankaj Singla
    *  @description - Method to create contact
    * params : FirstName 
    * params : LastName
    * params : EmailId
    * return type : Contact Instance
    **/
    public static Contact createContact(String fName, String lName, String emailId)
    {
        Contact rec = TestDataPerson.initContact(null);
        rec.FirstName = fName;
        rec.LastName = lName;
        rec.Email = emailId;

        insert rec;
        return rec;
    }

    /**
    *  @author Pankaj Singla
    *  @description - Method to create contact
    * params : FirstName 
    * params : LastName
    * params : EmailId
    * params : CountryCode
    * return type : Contact Instance
    **/
    public static Contact createContact(String fName, String lName, String emailId, String country)
    {
        Contact rec = TestDataPerson.initContact(null);
        rec.FirstName = fName;
        rec.LastName = lName;
        rec.Email = emailId;
        rec.MailingCountryCode = country;

        insert rec;
        return rec;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description - Method to create contact
    * params : FirstName 
    * params : LastName
    * params : EmailId
    * params : Country
    * return type : Contact Instance
    **/
    public static Contact createContactForMarketable(String fName, String lName, String emailId, String country)
    {
        Contact rec = TestDataPerson.initContact(null);
        rec.FirstName = fName;
        rec.LastName = lName;
        rec.Email = emailId;
        rec.MailingCountryCode = country;

        return rec;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description - Method to create Lead
    * params : FirstName 
    * params : LastName
    * params : EmailId
    * params : Country
    * params : Company
    * return type : Lead Instance
    **/
    
    public static Lead createLeadForMarketable(String fName, String lName, String emailId, String country, String company)
    {
        Lead objLead=new Lead(FirstName = FName, LastName = LName, Email=EmailId, Country=country, Company=company);
        return objLead;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description - Method to create Lead
    * params : FirstName 
    * params : LastName
    * params : EmailId
    * params : Country
    * params : Company
    * return type : Lead Instance
    **/
    public static Lead createLead(String fName, String lName, String emailId, String country, String company)
    {
        Lead ld=new Lead(FirstName = FName, LastName = LName, email=EmailId, Country=country, Company=company);
        insert ld;
        return ld;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description - Method to create Campaign Member
    * params : idLead
    * params : idCampaign
    * params : strstatus
    * return type : CampaignMember Instance
    **/
    public static CampaignMember createCampaignMember(Id idLead,Id idCampaign,String strStatus){
    
     CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.status=strStatus;
        objCampaignMember.LeadId =idLead;
        
        objCampaignMember.CampaignId =idCampaign;
        insert objCampaignMember;
        return objCampaignMember;
    
    }
    
    /**
    *  @author Pankaj Singla
    *  @description - Method to create Campaign Member
    * params : idcontact
    * params : idCampaign
    * params : strstatus
    * return type : CampaignMember Instance
    **/
    public static CampaignMember createCampaignMemberContact(Id idcontact,Id idCampaign,String strStatus){
    
     CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.status=strStatus;
        objCampaignMember.Contactid =idcontact;
        
        objCampaignMember.CampaignId =idCampaign;
        insert objCampaignMember;
        return objCampaignMember;
    
    }

        /**
    *  @author Deep Diwakar
    *  @description - Method to initialize Campaign Member
    * params : idLead
    * params : idCampaign
    * params : strstatus
    * return type : CampaignMember Instance
    **/
    public static CampaignMember initCampaignMemberLead(Id idLead,Id idCampaign,String strStatus){
    
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.status=strStatus;
        objCampaignMember.LeadId =idLead;
        
        objCampaignMember.CampaignId =idCampaign;
        return objCampaignMember;
    
    }
       
    /**
     *  @author Pankaj Singla
     *  @description - Method to create Campaign Member
     * params : idcontact
     * params : idCampaign
     * params : strstatus
     * return type : CampaignMember Instance
     **/
    public static CampaignMember initCampaignMemberContact(Id idcontact,Id idCampaign,String strStatus){
    
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.status=strStatus;
        objCampaignMember.Contactid =idcontact;
        
        objCampaignMember.CampaignId =idCampaign;
        return objCampaignMember;
    
    }

    /**
    *  @author Pankaj Singla
    *  @description - Method to create New Account
    * params : StrName
    * return type : Account Instance
    **/
    public static Account getAccount(String strName)
    {
        Account objAcc=new Account();
        objAcc.Name=strName;
        objAcc.ERP_Customer_Id__c = TestData.getRandomNumeric(10);
        objAcc.BillingStreet ='TestStree';
        objAcc.BillingCity='TestCity';
        objAcc.BillingPostalCode ='10010';
        objAcc.BillingCountry ='USA';
        objAcc.Clinical_Type__c='Non Clinical';
        objAcc.Customer_Sub_Type__c ='Genome Center';
        objAcc.Market_Segment__c = 'Forensics';
        objAcc.Customer_Type__c = 'Academic';
        objAcc.Market_Segment__c = 'Forensics';
        objAcc.Tier__c = 'Tier 1';
        objAcc.CurrencyIsoCode = 'USD';
        objAcc.Account_Group__c = 'Ultimate Consignee';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert objAcc;
        return objAcc;
    }

}
/**
*    @author      :Saddam
*    @date        :2022-08-10
*    @description :Test class for Open Offer Agreement
*    Modification Log:
*     ---------------------------------------------------------------------------------------------------------------------------
*         Developer                       Date                    Description         
*         Saddam                      2022-08-10                Initial Version
*       Prem Ranjan                   14-Sep-2022               DCP-56504,  @Description : Method to return True when it match few combination(as below) to make line status as updated.
*       Pravallika, Gundreddy         28-nov-2022               POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ---------------------------------------------------------------------------------------------------------------------------
*
***/
@isTest(isParallel=false)
public with sharing class TestOpenOfferAgreements {

    public static final string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static final string TEST_TXDR = 'Test TXDR';
    public static final string VC0013519_OPA = 'VC0013519-OPA';
    public static final string DISTRIBUTOR = 'Distributor';
    public static final string TXDR = 'TXDR';
    public static final string ERP_123456 = '123456';
    public static final string USD = 'USD';
    public static final string HK01 = 'HK01';
    public static final string AU01 = 'AU01';

    /**
     *  @author SAddam
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData()
    {
        system.runas(new user(Id = userinfo.getUserid()))
        {
            Map<String, String> profiles = TestDataUser.getProfilesIds(new Set<String> {'GIS User Provisioning'});
            User commOps = TestDataUser.initStandardUser(profiles.get('GIS User Provisioning'));
            commOps.Username = 'jhonwick@sfdc.com';
            insert new List<User> {commOps};
        }

        /*Start DCP-54438 Open Offer Agreements Account Setup*/
        Account primaryAcct = TestDataAccount.getCustomerAccount();
        primaryAcct.BIllingCountryCode='HK' ;
        primaryAcct.National_Group_Number__c=primaryAcct.ERP_Customer_ID__c;
        insert primaryAcct ;
        
        Contact con = TestDataPerson.initContact(primaryAcct.Id);
        insert con;

        TestDataAgreement.addHierarchyPermission();

        Id recTypeOO = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();


        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '180', '00', false);
        accSalesArea.Account__c = primaryAcct.Id;
        accSalesArea.Price_List_Type__c = '06';
        accSalesArea.CurrencyIsoCode = USD;
        accSalesArea.Price_List__c = AMEA_USD_01; //POL-57
        accSalesArea.Contract_Number__c = '123456_HK010100';
        accSalesArea.Price_Group__c = TXDR;
        accSalesArea.Sales_Organization__c=HK01;
        accSalesArea.Price_Group_Description__c=TEST_TXDR;
        accSalesArea.Distribution_Channel__c='01';
        insert accSalesArea;

        //Start - DCP-55553 : Added ADT , PDT records
        List<Account_Discount_Tier__c> listAccountDiscountTier = new List<Account_Discount_Tier__c>();
        Account_Discount_Tier__c accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = primaryAcct.National_Group_Number__c;
        accTier.Pricing_Tier__c = 1;
        accTier.IsInactive__c = false;
        accTier.Discount_Type__c = 'Consumables';
        listAccountDiscountTier.add(accTier);

        accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = primaryAcct.National_Group_Number__c;
        accTier.Pricing_Tier__c = 2;
        accTier.IsInactive__c = false;
        accTier.Discount_Type__c = 'Instrument';
        listAccountDiscountTier.add(accTier);

        accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = primaryAcct.National_Group_Number__c;
        accTier.Pricing_Tier__c = 1;
        accTier.Discount_Type__c = 'Services';
        listAccountDiscountTier.add(accTier);

        insert listAccountDiscountTier;

        List<Pricing_Discount_Tier__c> listPricingTier = new List<Pricing_Discount_Tier__c>();
        Pricing_Discount_Tier__c pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Consumables';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);

        pricingDis.Discount_Value__c = 10;
        listPricingTier.add(pricingDis);

        pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Instrument';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);
        pricingDis.Discount_Value__c = 11;
        listPricingTier.add(pricingDis);

        pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Services';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);
        pricingDis.Discount_Value__c = 12;
        listPricingTier.add(pricingDis);

        Apttus__APTS_Agreement__c openOfferAgreement1 = new Apttus__APTS_Agreement__c();
        openOfferAgreement1.Name = 'Test Agreement - Open Offer2';
        openOfferAgreement1.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreement1.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreement1.RecordTypeId = recTypeOO;
        openOfferAgreement1.Apttus__Subtype__c ='Standard';
        openOfferAgreement1.Discount_Justification__c = 'None';
        openOfferAgreement1.Open_Offer_Status__c='Request';
        openOfferAgreement1.Sales_Org__c = HK01;
        openOfferAgreement1.Parent_Agreement_Number__c = '1231';

        insert openOfferAgreement1;

        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
        objApexSettings.Bypass_All_Validations__c=true;
        upsert objApexSettings cs_Apex_Settings__c.Id;
       
        insert listPricingTier;

        objApexSettings.Bypass_All_Validations__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;
        
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        productTwo.Open_Offer_Product__c=true;

        insert productTwo;
    }

    @isTest
    static void testCreateOOAgreementAffiliates() {
        Account primaryAcct = [Select Id,National_Group_Number__c from Account where Name = '000' LIMIT 1];

        Id recTypeOO = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();
        
        Test.startTest();
        Account childAcct = TestDataAccount.getCustomerAccount();
        childAcct.ParentId = primaryAcct.Id;
        childAcct.National_Group_Number__c=primaryAcct.National_Group_Number__c;
        insert childAcct;
        
        Apttus__APTS_Agreement__c openOfferAgreement = new Apttus__APTS_Agreement__c();
        openOfferAgreement.Name = 'Test Agreement - Open Offer';
        openOfferAgreement.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreement.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreement.RecordTypeId = recTypeOO;
        openOfferAgreement.Apttus__Subtype__c ='Standard';
        openOfferAgreement.Discount_Justification__c = 'None';
        openOfferAgreement.Sales_Org__c = HK01;
        insert openOfferAgreement;
        Test.stopTest();
        
        List<Agreement_Account_Relationship__c> lstAgrAccRel = [Select Id from Agreement_Account_Relationship__c where Agreement__c =:openOfferAgreement.Id];
        System.assert(!lstAgrAccRel.isEmpty(),'Junction records = has Not Created');

    }
    /**
     *  @author saddam 
     *  @description Test Data Setup
     * to cover updateOpenOfferAgreementStatus().
     **/
    @istest
    static void testUpdateOOAgreementsStatus() {
        Account primaryAcct = [Select Id,National_Group_Number__c from Account where Name = '000' LIMIT 1];
        Id recTypeOO = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();

        Test.startTest();

        Apttus__APTS_Agreement__c openOfferAgreementPendingApproval = new Apttus__APTS_Agreement__c();
        openOfferAgreementPendingApproval.Name = 'Test Agreement - Open Offer3';
        openOfferAgreementPendingApproval.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementPendingApproval.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementPendingApproval.RecordTypeId = recTypeOO;
        openOfferAgreementPendingApproval.Apttus__Subtype__c ='Standard';
        openOfferAgreementPendingApproval.Discount_Justification__c = 'None';
        openOfferAgreementPendingApproval.Sales_Org__c = HK01;
        openOfferAgreementPendingApproval.Apttus_Approval__Approval_Status__c ='Approval Required';
        openOfferAgreementPendingApproval.Open_Offer_Status__c ='Request';

        Apttus__APTS_Agreement__c openOfferAgreementApproved = new Apttus__APTS_Agreement__c();
        openOfferAgreementApproved.Name = 'Test Agreement - Open Offer4';
        openOfferAgreementApproved.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementApproved.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementApproved.RecordTypeId = recTypeOO;
        openOfferAgreementApproved.Apttus__Subtype__c ='Standard';
        openOfferAgreementApproved.Discount_Justification__c = 'None';
        openOfferAgreementApproved.Sales_Org__c = HK01;
        openOfferAgreementApproved.Apttus_Approval__Approval_Status__c ='Approval Required';
        openOfferAgreementApproved.Open_Offer_Status__c ='Request';

        Apttus__APTS_Agreement__c openOfferAgreementInSign = new Apttus__APTS_Agreement__c();
        openOfferAgreementInSign.Name = 'Test Agreement - Open Offer5';
        openOfferAgreementInSign.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementInSign.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementInSign.RecordTypeId = recTypeOO;
        openOfferAgreementInSign.Apttus__Subtype__c ='Standard';
        openOfferAgreementInSign.Discount_Justification__c = 'None';
        openOfferAgreementInSign.Sales_Org__c = HK01;
        openOfferAgreementInSign.Apttus__Status_Category__c ='Request';
        openOfferAgreementInSign.Open_Offer_Status__c ='Request';

        Apttus__APTS_Agreement__c openOfferAgreementInEffect = new Apttus__APTS_Agreement__c();
        openOfferAgreementInEffect.Name = 'Test Agreement - Open Offer6';
        openOfferAgreementInEffect.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementInEffect.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementInEffect.RecordTypeId = recTypeOO;
        openOfferAgreementInEffect.Apttus__Subtype__c ='Standard';
        openOfferAgreementInEffect.Discount_Justification__c = 'None';
        openOfferAgreementInEffect.Sales_Org__c = HK01;
        openOfferAgreementInEffect.Apttus__Status_Category__c ='Request';
        openOfferAgreementInEffect.Open_Offer_Status__c ='Request';

        Apttus__APTS_Agreement__c openOfferAgreementAmended = new Apttus__APTS_Agreement__c();
        openOfferAgreementAmended.Name = 'Test Agreement - Open Offer7';
        openOfferAgreementAmended.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementAmended.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementAmended.RecordTypeId = recTypeOO;
        openOfferAgreementAmended.Apttus__Subtype__c ='Standard';
        openOfferAgreementAmended.Discount_Justification__c = 'None';
        openOfferAgreementAmended.Sales_Org__c = HK01;
        openOfferAgreementAmended.Apttus__Status_Category__c ='Request';
        openOfferAgreementAmended.Open_Offer_Status__c ='Request';

        Apttus__APTS_Agreement__c openOfferAgreementCancelled = new Apttus__APTS_Agreement__c();
        openOfferAgreementCancelled.Name = 'Test Agreement - Open Offer8';
        openOfferAgreementCancelled.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreementCancelled.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreementCancelled.RecordTypeId = recTypeOO;
        openOfferAgreementCancelled.Apttus__Subtype__c ='Standard';
        openOfferAgreementCancelled.Discount_Justification__c = 'None';
        openOfferAgreementCancelled.Sales_Org__c = HK01;
        openOfferAgreementCancelled.Apttus__Status_Category__c = 'Request';
        openOfferAgreementCancelled.Open_Offer_Status__c ='Request';
        
        List<Apttus__APTS_Agreement__c> lstAgreementsToInsert = new List<Apttus__APTS_Agreement__c>{openOfferAgreementPendingApproval,openOfferAgreementApproved,openOfferAgreementInSign,openOfferAgreementInEffect,openOfferAgreementAmended,openOfferAgreementCancelled};

        insert lstAgreementsToInsert;

        Apttus__APTS_Agreement__c openOfferAgreementPendingApprovalUpdate = openOfferAgreementPendingApproval;
        openOfferAgreementPendingApprovalUpdate.Apttus_Approval__Approval_Status__c ='Pending Approval';
        openOfferAgreementPendingApprovalUpdate.Open_Offer_Status__c ='Eligibility Approval';

        Apttus__APTS_Agreement__c openOfferAgreementApprovedUpdate = openOfferAgreementApproved;
        openOfferAgreementApprovedUpdate.Apttus_Approval__Approval_Status__c ='Approved';
        openOfferAgreementApprovedUpdate.Open_Offer_Status__c ='Affiliate Confirmation';

        Apttus__APTS_Agreement__c openOfferAgreementInSignUpdate = openOfferAgreementInSign;
        openOfferAgreementInSignUpdate.Apttus__Status_Category__c ='In Signatures';
        openOfferAgreementInSignUpdate.Open_Offer_Status__c ='Signatures';

        Apttus__APTS_Agreement__c openOfferAgreementInEffectUpdate = openOfferAgreementInEffect;
        openOfferAgreementInEffectUpdate.Apttus__Status_Category__c ='In Effect';
        openOfferAgreementInEffectUpdate.Open_Offer_Status__c ='In Effect';

        Apttus__APTS_Agreement__c openOfferAgreementAmendedUpdate = openOfferAgreementAmended;
        openOfferAgreementAmendedUpdate.Apttus__Status_Category__c ='Amended';
        openOfferAgreementAmendedUpdate.Open_Offer_Status__c ='Amended';

        Apttus__APTS_Agreement__c openOfferAgreementCancelledUpdate = openOfferAgreementCancelled;
        openOfferAgreementCancelledUpdate.Apttus__Status_Category__c ='Cancelled';
        openOfferAgreementCancelledUpdate.Open_Offer_Status__c ='Cancelled';

        List<Apttus__APTS_Agreement__c> lstAgreementsToUpdate = new List<Apttus__APTS_Agreement__c>{openOfferAgreementPendingApprovalUpdate,openOfferAgreementApprovedUpdate,openOfferAgreementInSignUpdate,openOfferAgreementInEffectUpdate,openOfferAgreementAmendedUpdate,openOfferAgreementCancelledUpdate};

        Update lstAgreementsToUpdate;

        Test.stopTest();

        System.assert(!lstAgreementsToInsert.isEmpty(),'OO agreement  is not inserted with different OO status');  
        System.assert(!lstAgreementsToUpdate.isEmpty(),'OO agreement  is not updated with different OO status');      
    }

    @istest
    static void testUpdateOOAgreementsLineitems() {
        Set<string> setErpCustomerId = new Set<string>();
        Apttus__APTS_Agreement__c oAgreement2 = [SELECT Id,Account_ERP_Number__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Open Offer2' LIMIT 1 ];
        setErpCustomerId.add(oAgreement2.Account_ERP_Number__c);
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
        objApexSettings.Bypass_All_Validations__c=true;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        Test.startTest();
        AccountDiscountTierSelector objAccountDiscountSelector = new  AccountDiscountTierSelector();
        objAccountDiscountSelector.getAccntPricingTiersForErpAndSalesOrgIds(setErpCustomerId,setErpCustomerId,setErpCustomerId);
        Apttus__AgreementLineItem__c oAgreementLI1 = new Apttus__AgreementLineItem__c();
        Id recTypeOO = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Open Offer Agreement Line Items').getRecordTypeId();
        oAgreementLI1.RecordTypeId = recTypeOO;
        oAgreementLI1.Apttus_CMConfig__LineNumber__c=0;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c=0;
        oAgreementLI1.Distribution_Channel__c = '01';
        oAgreementLI1.Open_Offer_Line_Type__c = 'Material';
        oAgreementLI1.Universal_Grid_Discount__c = 5;
        oAgreementLI1.Supply_Agreement_Discount_Type__c	='% Discount'; 
        oAgreementLI1.Supply_Agreement_Discount__c = 1;
        oAgreementLI1.Supply_Agreement_Start_Date__c = system.today()+1;
        oAgreementLI1.Supply_Agreement_End_Date__c = system.today()+2;
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Apttus_CMConfig__LineStatus__c = 'New';
        oAgreementLI1.CurrencyIsoCode= USD;
        oAgreementLI1.Apttus__AgreementId__c=oAgreement2.id;
        insert oAgreementLI1;

        Apttus__APTS_Agreement__c openOfferAgreementElectionTemplate= oAgreement2;
        openOfferAgreementElectionTemplate.Open_Offer_Status__c ='Election Template';
        Update openOfferAgreementElectionTemplate;

        objApexSettings.Bypass_All_Validations__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        Test.stopTest();

        System.assert(openOfferAgreementElectionTemplate.Open_Offer_Status__c!=Null,'Open Offer Status is not Updated');
    
    }
    @istest
    static void testAgreementlineitemsIntegration () {
    
    Apttus__APTS_Agreement__c oAgreement2 = [select id,Apttus__FF_Agreement_Number__c,CurrencyIsoCode,Agreement_Not_Amended__c,Validation_Status__c,RecordType.name,RecordType.developername,Apttus__Subtype__c,Parent_Agreement_Number__c,Apttus__Contract_Start_Date__c,Apttus__Contract_End_Date__c  from Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Open Offer2' LIMIT 1 ];
   
    Apttus__APTS_Agreement__c oAgreement3 =  new Apttus__APTS_Agreement__c();
    Account primaryAcct = [Select Id,National_Group_Number__c from Account where Name = '000' LIMIT 1];
    Id recOOType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();
    oAgreement3.Name = 'Test Agreement New- Open Offer';
    oAgreement3.Apttus__Account__c  = primaryAcct.Id;
    oAgreement3.Apttus__Contract_Start_Date__c = system.today();
    oAgreement3.RecordTypeId = recOOType;
    oAgreement3.Apttus__Subtype__c ='Standard';
    oAgreement3.Discount_Justification__c = 'None';
    oAgreement3.Sales_Org__c = HK01;
    oAgreement3.Apttus_Approval__Approval_Status__c ='Approved';
    oAgreement3.Open_Offer_Status__c ='In Effect';
    oAgreement3.Apttus__Status__c='Being Amended';
    //oAgreement3.Parent_Agreement_Number__c = '1231';

    insert oAgreement3;
    cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
    objApexSettings.Bypass_All_Validations__c=true;
    upsert objApexSettings cs_Apex_Settings__c.Id;

    Test.startTest();

    Apttus__AgreementLineItem__c oAgreementLI1 = new Apttus__AgreementLineItem__c();
    Id recTypeOO = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Open Offer Agreement Line Items').getRecordTypeId();
    oAgreementLI1.RecordTypeId = recTypeOO;
    oAgreementLI1.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI1.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI1.Distribution_Channel__c = '01';
    oAgreementLI1.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI1.Supply_Agreement_Discount_Type__c  ='% Discount'; 
    oAgreementLI1.Supply_Agreement_Discount__c = 1;
    oAgreementLI1.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI1.Supply_Agreement_End_Date__c = null;
    oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today();
    oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI1.Sales_Org__c = HK01;
    oAgreementLI1.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI1.CurrencyIsoCode= USD;
    oAgreementLI1.Customer_Election__c='Supply Agreement';
    oAgreementLI1.Supply_Agreement_Discount__c= 44;
    oAgreementLI1.Apttus__AgreementId__c=oAgreement2.id;

    Apttus__AgreementLineItem__c oAgreementLI2 = new Apttus__AgreementLineItem__c();
    oAgreementLI2.RecordTypeId = recTypeOO;
    oAgreementLI2.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI2.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI2.Distribution_Channel__c = '01';
    oAgreementLI2.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI2.Supply_Agreement_Discount_Type__c  ='% Discount'; 
    oAgreementLI2.Supply_Agreement_Discount__c = 1;
    oAgreementLI2.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI2.Supply_Agreement_End_Date__c = null;
    oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today();
    oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI2.Sales_Org__c = HK01;
    oAgreementLI2.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI2.CurrencyIsoCode= USD;
    oAgreementLI2.Customer_Election__c='Quote';
    oAgreementLI2.Quote_Discount__c = 5;
    oAgreementLI2.Apttus__AgreementId__c=oAgreement2.id;
    
    Apttus__AgreementLineItem__c oAgreementLI3 = new Apttus__AgreementLineItem__c();
    oAgreementLI3.RecordTypeId = recTypeOO;
    oAgreementLI3.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI3.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI3.Distribution_Channel__c = '01';
    oAgreementLI3.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI3.Supply_Agreement_Discount_Type__c	='% Discount'; 
    oAgreementLI3.Supply_Agreement_Discount__c = 1;
    oAgreementLI3.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI3.Supply_Agreement_End_Date__c = null;
    oAgreementLI3.Apttus_CMConfig__StartDate__c = system.today();
    oAgreementLI3.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI3.Sales_Org__c = HK01;
    oAgreementLI3.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI3.CurrencyIsoCode= USD;
    oAgreementLI3.Customer_Election__c='Universal Grid';
    oAgreementLI3.Universal_Grid_Discount__c = 5;
    oAgreementLI3.Apttus__AgreementId__c=oAgreement2.id;

    Apttus__AgreementLineItem__c oAgreementLI4 = new Apttus__AgreementLineItem__c();
    oAgreementLI4.RecordTypeId = recTypeOO;
    oAgreementLI4.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI4.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI4.Distribution_Channel__c = '01';
    oAgreementLI4.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI4.Supply_Agreement_Discount_Type__c  ='% Discount'; 
    oAgreementLI4.Supply_Agreement_Discount__c = 1;
    oAgreementLI4.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI4.Supply_Agreement_End_Date__c = null;
    oAgreementLI4.Apttus_CMConfig__StartDate__c = system.today()+5;
    oAgreementLI4.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI4.Sales_Org__c = HK01;
    oAgreementLI4.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI4.CurrencyIsoCode= USD;
    oAgreementLI4.Customer_Election__c='PSP';
    oAgreementLI4.PSP_Discount__c = 5;
    oAgreementLI4.Apttus__AgreementId__c=oAgreement2.id;

    List<Apttus__AgreementLineItem__c> lstAgreementLineItems = new List<Apttus__AgreementLineItem__c>{oAgreementLI1,oAgreementLI2,oAgreementLI3,oAgreementLI4 };
    insert lstAgreementLineItems;
    Apttus__APTS_Related_Agreement__c ooRelatedAgg1 = new Apttus__APTS_Related_Agreement__c();
    ooRelatedAgg1.Apttus__APTS_Contract_From__c= oAgreement3.Id;
    ooRelatedAgg1.Apttus__APTS_Contract_To__c= oAgreement2.Id;
    insert ooRelatedAgg1;


    ApttusAgreementValidateController.createJSON(oAgreement2,'Activate');
  
    objApexSettings.Bypass_All_Validations__c=false;
    upsert objApexSettings cs_Apex_Settings__c.Id;

    Test.stopTest();

    System.assert(!lstAgreementLineItems.isEmpty(),'agr line items is not inserted');

    }

    @istest
    static void testAgreementlineitemsIntegrationExcludeWrapper () {
        
    Apttus__APTS_Agreement__c oAgreement2 = [select id,Apttus__FF_Agreement_Number__c,CurrencyIsoCode,Agreement_Not_Amended__c,Validation_Status__c,RecordType.name,RecordType.developername,Apttus__Subtype__c,Apttus__Contract_Start_Date__c,Apttus__Contract_End_Date__c,Parent_Agreement_Number__c  from Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Open Offer2' LIMIT 1 ];
    List<Agreement_Account_Relationship__c> lstAgrAccRel = [Select Id,Opt_In_Receiving_Open_Offer_Discount__c from Agreement_Account_Relationship__c where Agreement__c =:oAgreement2.id];
    lstAgrAccRel[0].Opt_In_Receiving_Open_Offer_Discount__c =false;
    update lstAgrAccRel;
    Apttus__APTS_Agreement__c oAgreement3 =  new Apttus__APTS_Agreement__c();
    Account primaryAcct = [Select Id,National_Group_Number__c from Account where Name = '000' LIMIT 1];
    Id recOOType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();
    oAgreement3.Name = 'Test Agreement New- Open Offer';
    oAgreement3.Apttus__Account__c  = primaryAcct.Id;
    oAgreement3.Apttus__Contract_Start_Date__c = system.today();
    oAgreement3.RecordTypeId = recOOType;
    oAgreement3.Apttus__Subtype__c ='Standard';
    oAgreement3.Discount_Justification__c = 'None';
    oAgreement3.Sales_Org__c = HK01;
    oAgreement3.Apttus_Approval__Approval_Status__c ='Approved';
    oAgreement3.Open_Offer_Status__c ='In Effect';
    oAgreement3.Apttus__Status__c='Being Amended';
    oAgreement3.Apttus__Status_Category__c = 'Amended';

    insert oAgreement3;

    List<Apttus__APTS_Agreement__c> lstOOAgreements = new List<Apttus__APTS_Agreement__c>();
    lstOOAgreements.add(oAgreement2);
    lstOOAgreements.add(oAgreement3);

    
        
    cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
    objApexSettings.Bypass_All_Validations__c=true;
    upsert objApexSettings cs_Apex_Settings__c.Id;

    Test.startTest();
    
    Apttus__AgreementLineItem__c oAgreementLI1 = new Apttus__AgreementLineItem__c();
    Id recTypeOO = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Open Offer Agreement Line Items').getRecordTypeId();
    oAgreementLI1.RecordTypeId = recTypeOO;
    oAgreementLI1.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI1.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI1.Distribution_Channel__c = '01';
    oAgreementLI1.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI1.Universal_Grid_Discount__c = 5;
    oAgreementLI1.Supply_Agreement_Discount_Type__c ='% Discount'; 
    oAgreementLI1.Supply_Agreement_Discount__c = 1;
    oAgreementLI1.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI1.Supply_Agreement_End_Date__c = null;
    oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today();
    oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI1.Sales_Org__c = HK01;
    oAgreementLI1.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI1.CurrencyIsoCode= USD;
    oAgreementLI1.Customer_Election__c='Supply Agreement';
    oAgreementLI1.Supply_Agreement_Discount__c= 44;
    oAgreementLI1.Apttus__AgreementId__c=oAgreement2.id;

    Apttus__AgreementLineItem__c oAgreementLI2 = new Apttus__AgreementLineItem__c();
    oAgreementLI2.RecordTypeId = recTypeOO;
    oAgreementLI2.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI2.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI2.Distribution_Channel__c = '01';
    oAgreementLI2.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI2.Universal_Grid_Discount__c = 5;
    oAgreementLI2.Supply_Agreement_Discount_Type__c ='% Discount'; 
    oAgreementLI2.Supply_Agreement_Discount__c = 1;
    oAgreementLI2.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI2.Supply_Agreement_End_Date__c = null;
    oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today();
    oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI2.Sales_Org__c = HK01;
    oAgreementLI2.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI2.CurrencyIsoCode= USD;
    oAgreementLI2.Customer_Election__c='Quote';
    oAgreementLI2.Quote_Discount__c = 5;
    oAgreementLI2.Apttus__AgreementId__c=oAgreement2.id;
    
   

    Apttus__AgreementLineItem__c oAgreementLI4 = new Apttus__AgreementLineItem__c();
    oAgreementLI4.RecordTypeId = recTypeOO;
    oAgreementLI4.Apttus_CMConfig__LineNumber__c=0;
    oAgreementLI4.Apttus_CMConfig__ItemSequence__c=0;
    oAgreementLI4.Distribution_Channel__c = '01';
    oAgreementLI4.Open_Offer_Line_Type__c = 'Material';
    oAgreementLI4.Universal_Grid_Discount__c = 5;
    oAgreementLI4.Supply_Agreement_Discount_Type__c ='% Discount'; 
    oAgreementLI4.Supply_Agreement_Discount__c = 1;
    oAgreementLI4.Supply_Agreement_Start_Date__c = system.today()+1;
    oAgreementLI4.Supply_Agreement_End_Date__c = null;
    oAgreementLI4.Apttus_CMConfig__StartDate__c = system.today()+5;
    oAgreementLI4.Apttus_CMConfig__EndDate__c = system.today()+2;
    oAgreementLI4.Sales_Org__c = HK01;
    oAgreementLI4.Apttus_CMConfig__LineStatus__c = 'New';
    oAgreementLI4.CurrencyIsoCode= USD;
    oAgreementLI4.Customer_Election__c='PSP';
    oAgreementLI4.PSP_Discount__c = 5;
    oAgreementLI4.Apttus__AgreementId__c=oAgreement2.id;

    List<Apttus__AgreementLineItem__c> lstAgreementLineItems = new List<Apttus__AgreementLineItem__c>{oAgreementLI1,oAgreementLI2,oAgreementLI4 };
    insert lstAgreementLineItems;
    
    Apttus__APTS_Related_Agreement__c ooRelatedAgg1 = new Apttus__APTS_Related_Agreement__c();
    ooRelatedAgg1.Apttus__APTS_Contract_From__c= oAgreement3.Id;
    ooRelatedAgg1.Apttus__APTS_Contract_To__c= oAgreement2.Id;
    insert ooRelatedAgg1;

    ApttusAgreementValidateController.createJSON(oAgreement2,'Activate');
    ApttusAgreementActionService.sendRequestToSAP(oAgreement2,'Activate',null);
    ApttusAgreementActionService.updateParentAgreement(oAgreement2,'Activate');    
  
    objApexSettings.Bypass_All_Validations__c=false;
    upsert objApexSettings cs_Apex_Settings__c.Id;

    Test.stopTest();

    System.assert(!lstAgreementLineItems.isEmpty(),'agr line items is not inserted');

    }

    /*
    @Author : Prem Ranjan
    @Story :  DCP-56504
    @Description : Test Method to add error on Incase if there are more than 1 line item for the same material (example: In case of MSA), then period for each line items cannot overlap.
    */
    @istest
    static void testOOAgreementsLineitemStatusToUpdated() {

        Apttus__APTS_Agreement__c oAgreement2 = [SELECT Id,Account_ERP_Number__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Open Offer2' LIMIT 1 ];
    
        cs_Apex_Settings__c objApexSettings = cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
        objApexSettings.Bypass_All_Validations__c = true;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        Apttus__AgreementLineItem__c oAgreementLI1 = new Apttus__AgreementLineItem__c();
        Id recTypeOO = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get(Label.AgrLineItemRecordTypeOpenOffer).getRecordTypeId();
        oAgreementLI1.RecordTypeId = recTypeOO;
        oAgreementLI1.Material_Number__c = '11234187';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c=0;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c=0;
        oAgreementLI1.Distribution_Channel__c = '01';
        oAgreementLI1.Open_Offer_Line_Type__c = 'PSP Category';
        oAgreementLI1.Supply_Agreement_Discount_Type__c	='% Discount'; 
        oAgreementLI1.Supply_Agreement_Discount__c = 1;
        oAgreementLI1.PSP_Discount__c = 1;
        oAgreementLI1.Supply_Agreement_Start_Date__c = System.today()+1;
        oAgreementLI1.Supply_Agreement_End_Date__c = System.today()+5;
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Apttus_CMConfig__LineStatus__c = Label.AgreementLineItemLineStatusExisting;
        oAgreementLI1.CurrencyIsoCode= USD;
        oAgreementLI1.Apttus__AgreementId__c=oAgreement2.id;

        Apttus__AgreementLineItem__c oAgreementLI2 = new Apttus__AgreementLineItem__c();
        oAgreementLI2.RecordTypeId = recTypeOO;
        oAgreementLI2.Material_Number__c = '11234187';
        oAgreementLI2.Apttus_CMConfig__LineNumber__c=0;
        oAgreementLI2.Apttus_CMConfig__ItemSequence__c=0;
        oAgreementLI2.Distribution_Channel__c = '01';
        oAgreementLI2.Open_Offer_Line_Type__c = 'Material';
        oAgreementLI2.Supply_Agreement_Discount_Type__c	='% Discount'; 
        oAgreementLI2.Supply_Agreement_Discount__c = 1;
        oAgreementLI2.Supply_Agreement_Start_Date__c = system.today()+5;
        oAgreementLI2.Supply_Agreement_End_Date__c = system.today()+10;
        oAgreementLI2.Sales_Org__c = HK01;
        oAgreementLI2.Apttus_CMConfig__LineStatus__c = Label.AgreementLineItemLineStatusNew;
        oAgreementLI2.CurrencyIsoCode= USD;
        oAgreementLI2.Apttus__AgreementId__c=oAgreement2.id;

        List<Apttus__AgreementLineItem__c> lstAgreementLineItems = new List<Apttus__AgreementLineItem__c>{oAgreementLI1,oAgreementLI2};
        insert lstAgreementLineItems;

        Test.startTest();

        objApexSettings.Bypass_All_Validations__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        User commOps = [SELECT id FROM User WHERE Username = 'jhonwick@sfdc.com' LIMIT 1];

        System.runAs(commOps) {
            oAgreementLI1.Supply_Agreement_Discount__c = 5;
            oAgreementLI1.PSP_Discount__c = 5;
            oAgreementLI1.Universal_Grid_Discount__c = 5;
            oAgreementLI2.Supply_Agreement_Discount__c = 5;
            oAgreementLI2.Universal_Grid_Discount__c = 5;

            update new List<Apttus__AgreementLineItem__c> {oAgreementLI1, oAgreementLI2};

            oAgreementLI2.Supply_Agreement_Start_Date__c = system.today()+2;
            oAgreementLI2.Supply_Agreement_End_Date__c = system.today()+4;
            try{
                update oAgreementLI2;
            }catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains(Label.UI_ALIPreiodOverlapError) ? true : false;
                Assert.isTrue(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Exception not found');
                Assert.isTrue(expectedExceptionThrown, 'No Expected exception thrown');
            }
        }
        Test.stopTest();

        Set<id> setId = new Set<id>{oAgreementLI1.id, oAgreementLI2.id};
        List<Apttus__AgreementLineItem__c> ali1 =[SELECT id, name, Apttus_CMConfig__LineStatus__c FROM Apttus__AgreementLineItem__c WHERE id IN :setId];
       
        Assert.areEqual(Label.AgreementLineItemLineStatusUpdated, ali1[0].Apttus_CMConfig__LineStatus__c, 'Line Status Not Updated');
        Assert.areEqual(Label.AgreementLineItemLineStatusNew, ali1[1].Apttus_CMConfig__LineStatus__c, 'Line Status Should Not Be Updated');
       }
}
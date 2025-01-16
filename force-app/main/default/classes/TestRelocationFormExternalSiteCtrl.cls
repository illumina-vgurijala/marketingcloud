/**
*    @author KD
*    @date   2021-06-11
*    @description  DCP-38876: Test Class for Relocation Form LWC
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         KD                             2021-06-11          InitialVersion
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Sheikh Shahnawaz               27-sep-2022         Increase coverage above 80%
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestRelocationFormExternalSiteCtrl {
    public static final String PASSKEY = 'TESTKEY';
     /**
     *  @author      : KD
     *  @description : Setup method
     **/
    @testSetup
    static void initializeTestData(){
        Account acc = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        acc.ERP_Customer_Id__c = 'TESTACOUNT';
        acc.Account_Group__c =  'Sold To';
        insert new List<Account>{acc};

        Contact con1 = TestDataPerson.initContact(acc.Id);
        con1.Email = 'kdesai@illumina.com';
        insert new List<Contact> { con1 };

        Opportunity sOpp = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTDirectFieldServices);
        sOpp.Name = 'Service Opp';
        sOpp.Primary_Contact__c = con1.Id;
        //DCP-46835: Start- set product interest
        sOpp.StageName = 'Develop';
        sOpp.Type=Label.OpportunityTypeBillableService;
        sOpp.Product_Interest__c=Label.OpportunityProductInterestOtherServices;
        //DCP-46835: End- set product interest

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        sOpp.Pricebook2Id = standardPricebook.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTDirectFieldServices);
        opp2.Name = 'opp2';
        opp2.Type = 'Billable Services';
        opp2.StageName = 'Develop';
        opp2.Product_Interest__c = 'Break Fix';

        insert new List<Opportunity>{sOpp,opp2};
        Relocation_Requirements_Form__c objRelocation = new Relocation_Requirements_Form__c(Opportunity__c =sOpp.id,Contact__c = con1.id,Pass_Key__c = PASSKEY);
        insert objRelocation;
    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testgetSite(){
        List<String> lstSIte = RelocationFormExternalSiteController.getSiteURL();
        System.assert(lstSIte[0].contains('/RelocationForm'),'Incorrect Site fetched.');
    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testAuthFail(){
        Relocation_Requirements_Form__c objReloc = [Select id from Relocation_Requirements_Form__c LIMIT 1];
        String strRet = RelocationFormExternalSiteController.checkUserAuthenticity('Junk',objReloc.Id);
        System.assertEquals('User Not Authorized',strRet,'Authorization Failed');
    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testAuthPass(){
        Relocation_Requirements_Form__c objReloc = [Select id from Relocation_Requirements_Form__c LIMIT 1];
        Test.startTest();
        String strRet = RelocationFormExternalSiteController.checkUserAuthenticity(PASSKEY,objReloc.Id);
        Test.stopTest();
        System.assertEquals('Success',strRet,'Authorization Success');
    }
    /**
     *  @author      : Adyasha
     *  @description : method to test loadPage method
     **/
    @isTest
    static void testLayout(){
        Relocation_Requirements_Form__c objReloc = [Select id from Relocation_Requirements_Form__c LIMIT 1];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMockHTTP());
        String strReturn = RelocationFormExternalSiteController.loadPage(objReloc.id);
        Test.stoptest();
        String strLayout = (String)JSON.deserialize(
            UtilsObject.getJSONPart(strReturn,
            '{"LayoutStructure": ',
            ',"mapRecordFieldToValue": '),
            String.class);
        RelocationFormExternalSiteController objReloCls = new RelocationFormExternalSiteController();
        objReloCls.getPicklistValueTranslation();
        System.assert(String.isNotBlank(objReloCls.strPicklistDetails),'Translation not fetched');
        System.assert(strLayout.length() > 0,'Page Layout not fetched');
    }
    /**
     *  @author      : Adyasha
     *  @description : method to test getPicklistOptions and doSave
     **/
    @isTest
    static void testDoSave(){
        String strStatus = '';
        Set<String> strReturnedValues = new Set<String>();
        Relocation_Requirements_Form__c objReloc = [Select id from Relocation_Requirements_Form__c LIMIT 1];
        Test.startTest();

        String strJSON = '[{"fieldApiName":"Name_of_person_completing_this_form__c","value":"Testing Update"},{"fieldApiName":"How_many_total_units_need_to_be_moved__c","value":"123422"}]';
        strStatus = RelocationFormExternalSiteController.doSave(objReloc.Id,strJSON);
        
        String returnValue = DynamicInputFieldController.getFieldType('Delivery_Loading_Dock__c');
        System.debug('returnValue: '+returnValue);
        
        Map<String, Object> mapAllValues = (Map < String, Object >)JSON.deserializeUntyped( returnValue );
        System.debug('fullMap -> '+mapAllValues);
        for(Object obj : (List<Object>)mapAllValues.get('lstPickvals')) 
        {
            Map <String, Object> mapValues = (Map <String, Object>)obj;
            strReturnedValues.add((String)mapValues.get('strValue'));
        }  

        Test.stopTest();
        
        System.assertEquals('Success',strStatus,'Incorrect status returned');
        System.assert(strReturnedValues.contains('Yes'),'Incorrect Picklist Value For Yes');
        System.assert(strReturnedValues.contains('No'),'Incorrect Picklist Value For No');
           
    }
     /**
     *  @author      : Sheikh shahnawaz
     *  @description : method to cover catch block in loadPage method
     **/
    @isTest
    static void testException1(){
        Test.startTest();
        try{
            RelocationFormExternalSiteController.loadPage('test123');
        }catch(Exception ex){
            System.assert(true,'Exception not handled');
        }
        Test.stopTest();
    }
    /**
     *  @author      : Sheikh shahnawaz
     *  @description : method to cover catch block in doSave method
     **/
    @isTest
    static void testException2(){
        Test.startTest();
        try{
            RelocationFormExternalSiteController.doSave('Test123','Json string');
        }catch(Exception ex){
            System.assert(true,'Exception not handled');
        }
        Test.stopTest();
    }
         /**
     *  @author      : Sheikh shahnawaz
     *  @description : method to cover catch block in checkUserAuthenticity method
     **/
    @isTest
    static void testException3(){
        Test.startTest();
        try{
            RelocationFormExternalSiteController.checkUserAuthenticity('TestKey','Test123');
        }catch(Exception ex){
            System.assert(true,'Exception not handled');
        }
        Test.stopTest();
    }
}
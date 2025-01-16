/**
*    @author: Vignesh S
*    @date:   23-Jan-2020
*    @description:  Test class for AgreementOutputParametersForm Controller
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
              Vignesh S                   23-Jan-2020            Initial Version
              KD                           10-Feb-2020          SAP integration 
              KD                          3-March-2020          Generate Enhancement
              Arif,Dalali                 28-Nov-2022           POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestAgreementOutputParametersForm {
    
    @testSetup 
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';    
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
            
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
            
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        insert product;
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD';  //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Validation_Status__c = 'Validate In Progress';
        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;
        insert new List<Apttus__APTS_Agreement__c>{oAgreement1};
        
        
        Apttus__AgreementLineItem__c oAgreementLineItem = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLineItem.Material_Number__c = 'VC0013519-OPA';
        oAgreementLineItem.Line_Type__c = 'Material';
        oAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem.Discount_Type__c = '% Discount';
        oAgreementLineItem.Discount__c = 12;
        oAgreementLineItem.CurrencyIsoCode = 'USD';
        oAgreementLineItem.Distribution_Channel__c = '01';
        oAgreementLineItem.Customer_ERP_Number__c = '123456';
        oAgreementLineItem.Sales_Org__c = 'US01';
        insert oAgreementLineItem;

        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
       update oAgreement1;
            
        
    }
    
    /**
     *  @Author Vignesh S
     *  @Description : Method that passes agreement Id and gets agreement and selected Material group.
     **/
    @isTest
    static void testAgreementRecords(){
        AgreementOutputParametersForm.AgreementWrapper aggWarp = null;
        list<Apttus__APTS_Agreement__c> lstAgreement = [select Id from Apttus__APTS_Agreement__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',null,null));
        if(!lstAgreement.isEmpty()){
            aggWarp= AgreementOutputParametersForm.getAgreementWrapper(lstAgreement[0].Id);
        }
        System.debug('Agreement JSON-->>'+aggWarp.objAgreement.Name);
        System.assertEquals('Test Agreement - Price Group',aggWarp.objAgreement.Name,'Fetch Agreement is not correct');
        Test.stopTest();
    }
    /**
     *  @Author KD
     *  @Description : Test class for upload file
     **/
    @isTest
    static void testUploadCSV(){
        Test.startTest();
        ContentVersion objCV;
        objCV = TestDataFieldService.createDocVersion('TestDoc', 'test.csv', 'Excluded Item,Included Item\r\n123,abc\r\n456,def', true);
        insert objCV;
        ContentVersion contentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        String strRetCSV = AgreementOutputParametersForm.readCSVFile(contentVersion2.ContentDocumentId);
        Test.stopTest();
        System.assertEquals(documents[0].Id, contentVersion2.ContentDocumentId);
        System.assertEquals('{"excludeValue": ["123","456"],"includeValue": ["abc","def"]}',strRetCSV,'Return String is not correct');

    }
    /**
     *  @Author KD
     *  @Description : Test class for Generate success
     **/
    @isTest
    static void testAgreementGenerateSuccess(){
        list<Apttus__APTS_Agreement__c> lstAgreement = [select Id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c LIMIT 1];
        String strInputJSON = '{"IncludeAllMaterial":true,"includeAdditionalMaterials":"include","excludeAdditionalMaterials":"exclude","includeMaterialFile":"[\\"abc\\",\\"def\\"]","excludeMaterialFile":"[\\"123\\",\\"456\\"]","selectedMaterialGroup":"[{\\"Description\\":\\"TG MiSeq Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"AIM\\"},{\\"Description\\":\\"TG Misc Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"AIR\\"},{\\"Description\\":\\"AmpliSeq Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"ASQ\\"}]","pricingDate":"2021-02-13","language":"English","hideListPrice":true,"customerName":"10X Genomics;6000022795","customerERPNumber":"6000022795","salesOrg":"BE01","curr":"AUD"}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',lstAgreement[0].Apttus__FF_Agreement_Number__c,''));
        System.assertequals(Label.UI_Agreement_Generate_Success,AgreementOutputParametersForm.sendGenerateRequest(strInputJSON,lstAgreement[0].id));
        Test.stopTest();
    }
     /**
     *  @Author KD
     *  @Description : Test class for Generate failure
     **/
    @isTest
    static void testAgreementGenerateFailure(){
        list<Apttus__APTS_Agreement__c> lstAgreement = [select Id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c LIMIT 1];
        String strInputJSON = '{"IncludeAllMaterial":true,"includeAdditionalMaterials":"include","excludeAdditionalMaterials":"exclude","includeMaterialFile":"[\\"abc\\",\\"def\\"]","excludeMaterialFile":"[\\"123\\",\\"456\\"]","selectedMaterialGroup":"[{\\"Description\\":\\"TG MiSeq Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"AIM\\"},{\\"Description\\":\\"TG Misc Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"AIR\\"},{\\"Description\\":\\"AmpliSeq Consumables\\",\\"isSelected\\":false,\\"materialGroup\\":\\"ASQ\\"}]","pricingDate":"2021-02-13","language":"English","hideListPrice":true,"customerName":"10X Genomics;6000022795","customerERPNumber":"6000022795","salesOrg":"BE01","curr":"AUD"}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Fail',lstAgreement[0].Apttus__FF_Agreement_Number__c,''));
        String strReturn = AgreementOutputParametersForm.sendGenerateRequest(strInputJSON,lstAgreement[0].id);
        System.assertequals(true,strReturn.contains(Label.UI_Agreement_Generate_Failed),'Generate Error');
        Test.stopTest();
    }
}
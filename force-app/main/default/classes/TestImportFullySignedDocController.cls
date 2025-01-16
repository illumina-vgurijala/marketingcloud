/*
 * 
 * 
 * @Description : TestImportFullySignedDocController
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                        Description
* Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
* ---------------------------------------------------------------------------------------------------------------------------------------
* Arif,Dalali           28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*/
@isTest
public class TestImportFullySignedDocController{
    
    public static final string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static final string TEST_TXDR = 'Test TXDR';
    
    static testMethod void myUnitTest() 
    {  
        
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BIllingCountryCode='HK' ;
        insert new List<Account> { acc, acc2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        TestDataAgreement.addHierarchyPermission();

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea};

      
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        
       Apttus__APTS_Agreement__c agreement = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        agreement.Sales_Org__c ='HK01'; //adding reference sales org
        agreement.RecordTypeId = recTypeId;
        agreement.Apttus__Auto_Renewal__c=True;
        insert agreement;
     
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //Start Test
        Test.startTest();
        try{
            ImportFullySignedDocumentController.processDocument(null, null, null);
        }catch(Exception ex){
            ilib_LogEvent.message('Exception in TestImportFullySignedDocController, details : '+ex);
        }

        //execute processDocument method
        ImportFullySignedDocumentController.processDocument(agreement.Id, documents[0].id, null);
        
        //Stop Test
        Test.stopTest();
        
        //Query agreement record
        Apttus__APTS_Agreement__c agreementResult = [select Id, Apttus__Status_Category__c, Apttus__Status__c from Apttus__APTS_Agreement__c where Id = :agreement.Id];
        
        //Assert that the agreement is In Authoring status category and Author Contract status
        System.assertEquals(agreementResult.Apttus__Status_Category__c, Label.InSignatures );
        System.assertEquals(agreementResult.Apttus__Status__c, Label.AgreementStatusFullySigned );
    }
}
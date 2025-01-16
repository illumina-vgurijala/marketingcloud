/**
 *    @author Aditi Amit Joshi
 *    @date   17 Sep 2020
 *    @description    Class to handle Purchase condition Line Items added from X-Author.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Aditi Joshi                       17 Sep 2020              Initial Version - DCP-40043 : Create BeforeUpdate method for updating line items.
 *    Pravallika, Gundreddy             28-nov-2022              POL-57: Update APJ and EMEA References to AMEA and Europe respectively
 * ---------------------------------------------------------------------------------------
 */
 
@isTest
public class TestPurchaseConditionLineItems {
	 
	public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
	public static FINAL string MATERIAL_NUMBER = '11234187';
	public static FINAL string MATERIAL_GROUP = 'IMQ';
    
	 @testSetup
    static void setupData()
    {
		/*Set up data for Account,Contact,Product,Agreement,Purchase Condition and Customer Master data*/
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        insert acc;
		
        Contact con = TestDataPerson.initContact(acc.Id);
		insert con;

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
		insert acc1SalesArea;

        

       Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = MATERIAL_NUMBER;
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        Product2 productFour = TestDataMaster.createProduct(false);
        productFour.Material_Number__c = '20012860';
        Product2 productFive = TestDataMaster.createProduct(false);
        productFive.Old_Material_Number__c = 'WG-401-1002';
        insert new List < Product2 > {product,productTwo,productThree,productFour,productFive};

        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
  

        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement1.Sales_Org__c ='HK01';//adding reference sales org
        oAgreement1.RecordTypeId = recTypeChannelPartner;
        oAgreement1.Apttus__Auto_Renewal__c=True;

       
		insert oAgreement1;
       
		Purchase_Conditions__c objpCL = new Purchase_Conditions__c();
        objpCL.Agreement__c = oAgreement1.id;
		insert objpCL;
		
		
    }
	
	static testMethod void testInsertNewPurchaseLines() {
		
		List<Purchase_Conditions__c> lstpcl = [SELECT Id FROM Purchase_Conditions__c LIMIT 1];
		
		Test.startTest();
		
		Purchase_Condition_Line_Item__c pCLI = new Purchase_Condition_Line_Item__c();
		pCLI.Material_Number__c = MATERIAL_NUMBER;
		pCLI.Material_Group_1__c = MATERIAL_GROUP;
		pCLI.Type__c='Material';
		pCLI.Purchase_Condition__c = lstpcl[0].id;
		
		insert pCLI;
		Test.stopTest();
		System.assertEquals(MATERIAL_NUMBER, pCLI.Material_Number__c);
		
	}
	
	static testMethod void testUpdatePurchaseLines() {
		
		List < Purchase_Conditions__c > lstpcl = [SELECT Id, Name FROM Purchase_Conditions__c LIMIT 1];

        Test.startTest();

        /*Updating Material Group*/
        Purchase_Condition_Line_Item__c pCLI = new Purchase_Condition_Line_Item__c();
        pCLI.Material_Number__c = MATERIAL_NUMBER;
        pCLI.Material_Group_1__c = 'ICP';
        pCLI.Purchase_Condition__c = lstpcl[0].id;
        insert pCLI;
        pCLI.Material_Group_1__c = MATERIAL_GROUP;
        update pCLI;

        /*Updating Material Number*/
        Purchase_Condition_Line_Item__c pCLI2 = new Purchase_Condition_Line_Item__c();
        pCLI2.Material_Number__c = MATERIAL_NUMBER;
        pCLI2.Purchase_Condition__c = lstpcl[0].id;
        insert pCLI2;
        pCLI2.Material_Number__c = '20012860';
        update pCLI2;

        /*Updating Material Group to blank*/
        Purchase_Condition_Line_Item__c pCLI3 = new Purchase_Condition_Line_Item__c();
        pCLI3.Material_Number__c = MATERIAL_NUMBER;
        pCLI3.Material_Group_1__c = 'ICP';
        pCLI3.Purchase_Condition__c = lstpcl[0].id;
        insert pCLI3;
        pCLI3.Material_Group_1__c = '';
        update pCLI3;

        /*Update 'Material Number' to blank*/
        Purchase_Condition_Line_Item__c pCLI4 = new Purchase_Condition_Line_Item__c();
        pCLI4.Material_Number__c = MATERIAL_NUMBER;
        pCLI4.Purchase_Condition__c = lstpcl[0].id;
        insert pCLI4;
        pCLI4.Material_Number__c = '';
        update pCLI4;


        /*To check AddError Message for invalid Material Number*/
        Purchase_Condition_Line_Item__c pCLI5 = new Purchase_Condition_Line_Item__c();
        pCLI5.Material_Number__c = MATERIAL_NUMBER;
        pCLI5.Material_Group_1__c = 'ICP';
        pCLI5.Type__c = 'Material';
        pCLI5.Purchase_Condition__c = lstpcl[0].id;
        insert pCLI5;

        try {
            pCLI5.Material_Number__c = '123ABC';
            update pCLI5;
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Material number "123ABC" is not valid.'));
        }

        Test.stopTest();

        System.assertEquals(MATERIAL_GROUP, pCLI.Material_Group_1__c);
        System.assertEquals('20012860', pCLI2.Material_Number__c);
	}

}
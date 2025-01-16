/*
 * @author: Harsh Shukla
 * Description: To cover the class BatchToUpdateIPiSeq
 * * Date                           Name                                        Description
 * 19-09-2022                     Sheikh Shahnawaz                            Enhance code coverage above 80%
 */
@isTest(SeeAllData=false)
public class TestBatchToUpdateIPiSeq {
    public static final String NULL_OPERATION_STATUS = null;
    public static final Date NULL_ACCEPTANCE_DATE = null;
    public static final Date NULL_DATE_INSTALLED = null;
    public static final string STRING_CUSTOMER_INSTALLABLE_PRODUCT_CODE = '20040619';
    public static final string STRING_USD = 'USD';
    
    static testmethod void testIPiSeq() {
        
       //List<Territory2>listCPAccId = [SELECT Id FROM Territory2 WHERE Territory2Type.DeveloperName = 'Territory_Channel_Partner' AND Territory2Model.State = 'Active'];
        
        Account acc = TestDataAccount.getAccount('Test Acc', STRING_USD);
        Account objAcc = TestDataAccount.getAccount('Test Acc', STRING_USD);
        acc.Account_Group__c='Distributor';
        objAcc.Account_Group__c = 'Distributor';
        insert new List<Account>{acc, objAcc}; 
        
        //ObjectTerritory2Association objOTA = TestDataObjectTerritory2Association.getObjectAssociation(listCPAccId[0].Id,acc.Id);
        //insert objOTA;
        
		Product2 objProduct = new Product2(Name = 'testProduct',Service_Product_Type__c = 'Core');
        objProduct.ProductCode = STRING_CUSTOMER_INSTALLABLE_PRODUCT_CODE;
        insert objProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('TestIP', STRING_USD, 'Shipped');
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('TestIP', STRING_USD, 'Shipped');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct1.SVMXC__Company__c = objAcc.Id;
        objInstalledProduct.SVMXC__Product__c=objProduct.id;
        objInstalledProduct1.SVMXC__Product__c=objProduct.id;
        objInstalledProduct.SVMXC__Date_Shipped__c = Date.newInstance(2020, 11, 01);
        objInstalledProduct1.SVMXC__Date_Shipped__c = Date.newInstance(2020, 11, 30);
        objInstalledProduct.Operation_Status__c = NULL_OPERATION_STATUS;
        objInstalledProduct1.Operation_Status__c = NULL_OPERATION_STATUS;
		objInstalledProduct.Acceptance_Date__c = NULL_ACCEPTANCE_DATE;
        objInstalledProduct1.Acceptance_Date__c = NULL_ACCEPTANCE_DATE;
        objInstalledProduct.SVMXC__Date_Installed__c = NULL_DATE_INSTALLED;
        objInstalledProduct1.SVMXC__Date_Installed__c = NULL_DATE_INSTALLED;
		insert new List<SVMXC__Installed_Product__c>{objInstalledProduct, objInstalledProduct1}; 
        
        BatchToUpdateIPiSeq.boolIsTestRunning = false;
        Feature.setMockFeatureFlag('ServiceBatchErrorNotifications', true); // Enhance coverage
        Test.StartTest();
        Database.executeBatch(new BatchToUpdateIPiSeq());  
        String sch = '0 0 0 * * ?';
        System.schedule('BatchToUpdateIPiSeq', sch, new BatchToUpdateIPiSeq()); 
        Test.StopTest();
        
        List<SVMXC__Installed_Product__c> listIP = new List<SVMXC__Installed_Product__c>([Select Name, Operation_Status__c, SVMXC__Status__c from SVMXC__Installed_Product__c Where Id=:objInstalledProduct.id]);
        List<SVMXC__Installed_Product__c> objlistIP = new List<SVMXC__Installed_Product__c>([Select Name, Operation_Status__c, SVMXC__Status__c from SVMXC__Installed_Product__c Where Id=:objInstalledProduct1.id]);
        
        system.assertEquals('On',listIP[0].Operation_Status__c);
        system.assertEquals('On',objlistIP[0].Operation_Status__c);
        
      }
}
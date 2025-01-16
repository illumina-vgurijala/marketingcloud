/***************************************************************************************************************************************
 * NAME   : TestSmIbTechnicalAttributes 
 * DESCRIPTION  : TestClass for TestSmIbTechnicalAttributes   Trigger Class
 *           
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 04-Dec-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay         04-Dec-2019            Initial Version
 
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public with sharing class TestSmIbTechnicalAttributes  {
  
    
    
      /**
    *  @author Digvijay 
    *  @description - test the IB Technical Attrbute Update
    **/
    static testMethod void testIBTehnicalAttributeUpdateonIP(){
    
        IVD_Product_Criteria__mdt  mdtObj=[Select    Attribute_Type__c,  Attribute_Name__c , Attribute_Value__c , IVD_Product_Identifier__c from IVD_Product_Criteria__mdt where IVD_Product_Identifier__c=true Limit 1];
        
        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Family='Autoloader';
        insert objProduct;
        SVMXC__Installed_Product__c objInstalledProduct= TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'Installed');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct2= TestDataFieldService.createInstalledProduct('Test IP2', 'USD', 'Installed');
        objInstalledProduct2.SVMXC__Company__c = acc.Id;
        objInstalledProduct2.Operation_Status__c='Off';
        objInstalledProduct2.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct2;
        
        List<SVMXC__SM_IB_Technical_Attributes__c> lstattributes=new List<SVMXC__SM_IB_Technical_Attributes__c>();
        
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,mdtObj.Attribute_Name__c ,mdtObj.Attribute_Value__c);
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr2=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct2.id,mdtObj.Attribute_Name__c,'Autoloader IIx Upgrade');
        
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr3=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Day' ,'1');
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr4=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Month' ,'Jan');
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr5=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Year' ,'2019');
        
        lstattributes.add(objIBAttr3);
        lstattributes.add(objIBAttr4);
        lstattributes.add(objIBAttr5);
        lstattributes.add(objIBAttr);
        
        insert objIBAttr2;
        Test.StartTest();
        insert lstattributes;
        
        objIBAttr2.SVMXC__SM_Attr_Value__c=mdtObj.Attribute_Value__c;
        update objIBAttr2;
        
        Test.StopTest();
        
        SVMXC__Installed_Product__c objInstalledProductret=[Select id ,   Installed_Product_Upgrade_Type__c from SVMXC__Installed_Product__c where id=:objInstalledProduct.id];
         System.assertEquals('IVD',objInstalledProductret.Installed_Product_Upgrade_Type__c);
        
        
    }
    
  }
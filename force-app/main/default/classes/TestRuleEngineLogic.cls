/***************************************************************************************************************************************
* NAME   : TestRuleEngine
* DESCRIPTION  : TestClass for RuleEngine
*        DCP-40191
*    
* @AUTHOR : Digvijay Singh
* @DATE   : 09-18-2020
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@isTest(SeeAllData=true)
public with sharing class TestRuleEngineLogic {

    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
      public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';

    static SVMXC__Service_Order__c workOrder;
   
  

    static testMethod void testRuleEngineLogic(){
         // insert account
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        // list productss
        List<Product2> lstpro = new List<Product2>();
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS,
            Material_Class__c = 'Consumables');
        lstpro.add(objProduct);
        
        
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
         Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        lstpro.add(toolProduct2);
        lstpro.add(objProduct2);

        
        // insert product
        insert lstpro;
        
        Product2 insertedConsumableProduct = [Select id,Service_Product_Type__c from Product2 where Name = :STRING_PRODUCT_NAME][0];
       
        // installed product list creation
        List<SVMXC__Installed_Product__c> lstInstProducts = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct1);
        //insert installed products
        insert lstInstProducts;
        
        objInstalledProduct1=[Select id,SVMXC__Status__c from SVMXC__Installed_Product__c where SVMXC__Status__c= :STRING_INSTALLED_PRODUCT_STATUS][1];
        // create SMC
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        ObjServiceContract.Consumables_Included__c=true;//tc
        ObjServiceContract.Parts_Included__c = false;///tc
        ObjServiceContract.Labor_Included__c = true;///tc
        ObjServiceContract.ERP_Header_Contract_Number__c = '1234';///tc
        ObjServiceContract.ERP_Contract_Line_Number__c = '9898';///tc
        ObjServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert ObjServiceContract;
        SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: ObjServiceContract.Id];
       
        // create covered products.
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        ObjCoveredProduct.SVMXC__Service_Contract__c = ObjServiceContract.Id;
        insert ObjCoveredProduct;
        
    
        
        // create case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        // create case2
        Case objCase2 = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase2;
        
        Test.startTest();
        List<SVMXC__Service_Order__c> lstWO = new List<SVMXC__Service_Order__c>();
        // insert of work order
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        lstWO.add(workOrder);
        
        SVMXC__Service_Order__c workOrder2 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase2.Id, 'Initiated');
        workOrder2.Is_Service_Report_Generated__c=true;
        workOrder2.Record_Created_from_SFM__c=true;
        workOrder2.SVMXC__Component__c = objInstalledProduct.Id;
        lstWO.add(workOrder2);
        insert lstWO ;
         //create location
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc;
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder2.Id, ObjServiceContract.Id);
        insert objEntitlement;
        // create product stock 
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;
        // rule entry
        Rule_Entry__mdt reobj=new Rule_Entry__mdt ();
        reobj.Rule_Criteria_Object__c='SVMXC__Service_Contract__c';
        reobj.Rule_Criteria_Operator__c='IN';   
        reobj.Rule_Criteria_Field__c='ERP_Header_Contract_Number__c';
        reobj.Rule_Criteria_Field_Value__c='1234,val';
        reobj.Rule_InputData_Map__c='WorkDetailtoServiceContractMap';
        reobj.Key_InputData_Map__c='SVMXC__Service_Order__c';


        Map<String , Map<Id,Object>> mapofNeededSobjects =new Map<String , Map<Id,Object>>();
        Map<String,Rule_Entry__mdt > ruleidtoRuleObjectMap=new Map<String,Rule_Entry__mdt >();
        ruleidtoRuleObjectMap.put('ruleid',reobj);
        List<SVMXC__Service_Contract__c> clist=new List<SVMXC__Service_Contract__c>();
        clist.add(insertedServiceContract);

        Map<Id,Object> datamap=new Map<Id,Object>();
        datamap.put(workOrder2.id,insertedServiceContract);
        datamap.put(workOrder.id,clist);
        mapofNeededSobjects.put('WorkDetailtoServiceContractMap',datamap);
        
        
        // Test.startTest();
        // insert workOrder;
        //tcStart
        List<SVMXC__Service_Order_Line__c> lstWD = new List<SVMXC__Service_Order_Line__c>();
       //Billable work Details
        SVMXC__Service_Order_Line__c objOrderDetail1= new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Is_Billable__c = false;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Activity_Type__c = 'Training';
        objOrderDetail1.Non_Billable_Reason__c ='Goodwill';
         objOrderDetail1.SVMXC__Line_status__c='Canceled';
		 objOrderDetail1.Integration_Status__c ='Not Applicable';	
        lstWD.add(objOrderDetail1);
        // work detail  creation
          SVMXC__Service_Order_Line__c objOrderDetailpart= new SVMXC__Service_Order_Line__c();
        objOrderDetailpart.SVMXC__Is_Billable__c = false;
        objOrderDetailpart.SVMX_PS_VS_Consumed_Status__c = '2022-08-09 09:54:48 : Consumption Success : Part Consumption Successful';
        objOrderDetailpart.SVMXC__Line_Type__c = 'Parts';
        objOrderDetailpart.SVMXC__Service_Order__c = workOrder2.id;
        objOrderDetailpart.SVMXC__Activity_Type__c = 'Training';
        objOrderDetailpart.SVMXC__Product__c = toolProduct2.Id;
        objOrderDetailpart.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetailpart.Integration_Status__c ='Not Applicable';	
        lstWD.add(objOrderDetailpart);
         // work detail 5 creation
        SVMXC__Service_Order_Line__c objOrderDetail5= new SVMXC__Service_Order_Line__c();
        objOrderDetail5.SVMXC__Is_Billable__c = false;
        objOrderDetail5.SVMXC__Line_Type__c = 'Material Consumed';
        objOrderDetail5.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail5.SVMXC__Activity_Type__c = 'Training';
        lstWD.add(objOrderDetail5);
        
        
        
         // work detail 2 creation
        SVMXC__Service_Order_Line__c objOrderDetail2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Usage/Consumption');
        objOrderDetail2.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
        objOrderDetail2.Duration_in_hours__c = '1';
        objOrderDetail2.SVMXC__Line_Type__c = 'Labor';
        objOrderDetail2.Labor_Hours__c  = '1';
        lstWD.add(objOrderDetail2);
        // work detail 6 creation
        SVMXC__Service_Order_Line__c objOrderDetail6 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder2.Id,'Usage/Consumption');
        objOrderDetail6.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
        objOrderDetail6.Duration_in_hours__c = '1';
        objOrderDetail6.SVMXC__Line_Type__c = 'Labor';
        objOrderDetail6.Labor_Hours__c  = '1';
        lstWD.add(objOrderDetail6);
    
        SVMXC__Service_Order_Line__c objOrderDetail4 = TestDataFieldService.createMaterialsConsumedTypeWorkDetail(workOrder.Id,insertedConsumableProduct.Id);
        system.debug('@@@objOrderDetail4'+objOrderDetail4);
        lstWD.add(objOrderDetail4);
        
        insert lstWD;//tcEnd
        Test.stopTest();
        RuleEngineLogic.executeRule('SVMXC__Service_Order_Line__c',objOrderDetail5,ruleidtoRuleObjectMap,'ruleid',mapofNeededSobjects,false,'');
       try{
                  RuleEngineLogic.executeRule('SVMXC__Service_Order_Line__c',objOrderDetailpart,ruleidtoRuleObjectMap,'ruleid',mapofNeededSobjects,false,'');
                  RuleEngineCallable callobj=new RuleEngineCallable();
                  callobj.call(null,null);
       }Catch(Exception ex){
            System.debug(ex);
       }

        SVMXC__Service_Order_Line__c objwd=[select id,SVMXC__Line_status__c,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c  where id=: objOrderDetail1.id ];
       
        
        system.assertequals(false,objwd.SVMXC__Is_Billable__c);
        // Test.stopTest();
    }
        
}
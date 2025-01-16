/**
* Class Name: TestAppliedContracts
* Description: This is the test class for AppliedContracts class.
* 
**/
@IsTest
public class TestAppliedContracts {
public static final String STRING_TEST_ACCOUNT_NAME = 'Test Acc';
    static testmethod void testUpdateWD(){
        //insert account
        Account objAccount = TestDataAccount.getAccount(STRING_TEST_ACCOUNT_NAME, 'USD');
        objAccount.Clinical_Type__c = 'Clinical';
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        System.debug('objAccount1--:'+objAccount);
        //insert contact
        Contact con  = TestDataPerson.getNewContact(objAccount.Id);

        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
		
		SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;
        insert objServiceLevel; 

       //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        //insert installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;

        //insert covered product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        objCoveredProduct.SVMXC__Service_Contract__r = objServiceContract;
        objCoveredProduct.SVMXC__Start_Date__c = system.today();
        objCoveredProduct.SVMXC__End_Date__c = system.today().adddays(1);
        insert objCoveredProduct;

        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation('Test Location1','Test Street1','Ireland','1234567','USD');
        insert objLocation1;
        
        //insert coveredLocation
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = objLocation1.Id,SVMXC__Service_Contract__c=objServiceContract.Id,
            SVMXC__Service_Contract__r = objServiceContract
        );
        insert coveredLocation;

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        //insert work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;

        //insert work detail
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToInsert = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Usage/Consumption');
        objWorkDetail.SVMXC__Activity_Type__c = 'Repair';
        objWorkDetail.Duration_in_hours__c = '1';
        objWorkDetail.SVMXC__Line_Type__c = 'Labor';
        lstWorkDetailsToInsert.add(objWorkDetail);

        Test.startTest();
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = workOrder.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
		workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id;
        workDetail1.SVMXC__Is_Billable__c = false;
		workDetail1.SVMXC__Actual_Quantity2__c = 1;
        lstWorkDetailsToInsert.add(workDetail1);

        SVMXC__Service_Order_Line__c workDetail2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Usage/Consumption');
        workDetail2.SVMXC__Line_Type__c='Material Consumed';
        workDetail2.SVMXC__Product__c = toolProduct2.Id;
        workDetail2.SVMXC__Actual_Quantity2__c = 1;
        lstWorkDetailsToInsert.add(workDetail2);

        //insert work details
        insert lstWorkDetailsToInsert;

        AppliedContracts.isSLATermBlank = true;
        //insert applied contracts
        Applied_contract__c contract = new Applied_contract__c();
        contract.work_order__c = workOrder.Id;
        contract.Service_Contract__c = objServiceContract.id;
        List<Applied_contract__c> lstAppliedContracts = new List<Applied_contract__c>{contract/*,contract1*/};
        insert lstAppliedContracts;
        Test.stopTest();
    }

    @Istest(seeAllData = true)
    static void testUpdatePOL(){
        //insert account
        Account objAccount = TestDataAccount.getAccount(STRING_TEST_ACCOUNT_NAME, 'USD');
        objAccount.Account_Group__c='Distributor';
        objAccount.Clinical_Type__c='Clinical'; //changes value by dhairya 17th april 
        insert objAccount;
        //insert contact
        Contact con  = TestDataPerson.getNewContact(objAccount.Id);
        //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        //objServiceContract.SVMXC__Service_Plan__c = TestServicePlan.id;
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        insert objServiceContract;

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        //insert work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Cost_Center__c = 23451;
        insert workOrder;
		system.assert(workOrder.Id != null);

        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct('Test 123','');
        objProduct.Material_Group__c  = '41';
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);

        //start
        Product2 objProduct1 = TestDataMaster.initProduct('Test 1234','Consumables');
        objProduct1.Service_Product_Type__c = 'Consumable';
        lstProducts.add(objProduct1);
        //end

        insert lstProducts;

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');

        List < SVMXC__Site__c > locList = new List < SVMXC__Site__c > ();
        locList.add(toLocation);
        locList.add(objLocationRec);
        insert locList;
        Test.startTest();
        //insert partsorder.
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', cs.Id, 'Open');
            //Parts Order creation in SAP (Inbound to SAP from SVMX)
            partOrder.ERP_Sales_Order_Number__c = '123451';//changes value by dhairya 17th april 
            partOrder.SVMXC__Service_Order__c = workOrder.id;
            partOrder.Contact_Name__c = 'Test';
            partOrder.Contact_Phone__c = 'Test';
            partOrder.SVMXC__Order_Type__c = 'Shipment';
            partOrder.SVMXC__Destination_Location__c = locList[0].Id;
            partOrder.Shipping_Location__c = locList[1].Id;
            partOrder.Requested_Delivery_Date__c = date.today() + 2;
        insert partOrder;

        list < SVMXC__RMA_Shipment_Line__c > poLineList = new list < SVMXC__RMA_Shipment_Line__c > ();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[1].Id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.Reason__c = 'Consumable Warranty';//changes value by dhairya 17th april. 
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        poLineList.add(objPartsOrderLine);

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = TestDataFieldService.createPartsOrderLines(partOrder.Id);
            objPartsOrderLine2.SVMXC__Product__c = lstProducts[0].Id;
            objPartsOrderLine2.Requested_Delivery_Date__c = date.today() + 2;
            poLineList.add(objPartsOrderLine2);
            insert poLineList;
        
        //insert applied contracts
        Applied_contract__c contract = new Applied_contract__c();
        contract.work_order__c = workOrder.Id;
        contract.Service_Contract__c = objServiceContract.id;
        List<Applied_contract__c> lstAppliedContracts = new List<Applied_contract__c>{contract};
        insert lstAppliedContracts;
        Test.stopTest();
    }
    @isTest
    static void testInsertNDeleteIPAppliedContract() {
        //insert account
        Account objAccount = TestDataAccount.getAccount(STRING_TEST_ACCOUNT_NAME, 'USD');
        objAccount.Clinical_Type__c = 'Clinical';
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        System.debug('objAccount1--:'+objAccount);
        //insert contact
        Contact con  = TestDataPerson.getNewContact(objAccount.Id);

        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
		
		SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;
        insert objServiceLevel; 

       //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        //insert installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;

        //insert covered product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        objCoveredProduct.SVMXC__Service_Contract__r = objServiceContract;
        objCoveredProduct.SVMXC__Start_Date__c = system.today();
        objCoveredProduct.SVMXC__End_Date__c = system.today().adddays(1);
        insert objCoveredProduct;
        

        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.Id;
        AssociatedProduct.isTestRunning = true;
        insert cs;
        case objCse = [SELECT Id, SVMXC__Is_Service_Covered__c FROM Case WHERE Id =: cs.Id];
        Assert.areEqual(true, objCse.SVMXC__Is_Service_Covered__c);
        List<Applied_Contract__c> apList = [SELECT Id FROM Applied_Contract__c WHERE Case_Number__c =:cs.Id];
        delete apList;
        case objCase = [SELECT Id, SVMXC__Is_Service_Covered__c FROM Case WHERE Id =: cs.Id];
        Assert.areEqual(false, objCase.SVMXC__Is_Service_Covered__c);
    }
    @isTest
    static void testInsertLocationAppliedContract() {
        //insert account
        Account objAccount = TestDataAccount.getAccount(STRING_TEST_ACCOUNT_NAME, 'USD');
        objAccount.Clinical_Type__c = 'Clinical';
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        System.debug('objAccount1--:'+objAccount);
        //insert contact
        Contact con  = TestDataPerson.getNewContact(objAccount.Id);

        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
		
		SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;
        insert objServiceLevel; 

       //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location1','Test Street1','Ireland','1234567','USD');
        objLocation.SVMXC__Account__c = objAccount.Id;
        insert objLocation;
        
        //insert coveredLocation
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = objLocation.Id,SVMXC__Service_Contract__c=objServiceContract.Id,
            SVMXC__Service_Contract__r = objServiceContract
        );
        insert coveredLocation;

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        //insert work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Company__c = objAccount.Id;
        workOrder.SVMXC__Site__c = objLocation.Id;
        insert workOrder;

         case objCs = [SELECT Id, SVMXC__Is_Service_Covered__c FROM Case WHERE Id =: cs.Id];
         Assert.areEqual(true, objCs.SVMXC__Is_Service_Covered__c);
    }
    @isTest
    static void testLinkCaseOnWO() {
        //insert account
        Account objAccount = TestDataAccount.getAccount(STRING_TEST_ACCOUNT_NAME, 'USD');
        objAccount.Clinical_Type__c = 'Clinical';
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        System.debug('objAccount1--:'+objAccount);
        //insert contact
        Contact con  = TestDataPerson.getNewContact(objAccount.Id);

        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);

		SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;
        insert objServiceLevel; 

       //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location1','Test Street1','Ireland','1234567','USD');
        objLocation.SVMXC__Account__c = objAccount.Id;
        insert objLocation;

        //insert coveredLocation
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = objLocation.Id,SVMXC__Service_Contract__c=objServiceContract.Id,
            SVMXC__Service_Contract__r = objServiceContract
        );
        insert coveredLocation;

        Case cs = TestDataCase.initServiceRequestCase(con);
        Cases.skipCaseTrigger = true;
        insert cs;

        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;

        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        insert objGrpMember;

        //insert work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');

        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Group_Member__c= objGrpMember.id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Site__c = objLocation.Id;
        WorkOrders.skipWOTrigger = true;
        insert workOrder;
        WorkOrders.skipWOTrigger = false;
        workOrder.SVMXC__Case__c = cs.Id;
        update workOrder;
        case objCs = [SELECT Id, SVMXC__Is_Service_Covered__c FROM Case WHERE Id =: cs.Id];
        Assert.areEqual(true, objCs.SVMXC__Is_Service_Covered__c);
    }
}
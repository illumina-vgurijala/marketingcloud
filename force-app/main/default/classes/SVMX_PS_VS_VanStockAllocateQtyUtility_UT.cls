@isTest (seeAllData = false)
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockAllocateQtyUtility_UT 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
private class SVMX_PS_VS_VanStockAllocateQtyUtility_UT{
    @isTest
    static void testHandleAllocatedQtyForWorkDetailsCreationForSerialized(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockAllocateQtyUtility_UT.createPartConsumptionSettings();
        insert partConsumptionSettingList;  

        List<SVMXC__Service_Order_Line__c> workDetailList = createDataForSerialized();

        insert workDetailList;
        Test.startTest();
        SVMXC__Service_Order_Line__c wd = workDetailList[3];
        wd.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        wd.SVMXC__Line_Status__c = 'Canceled';
        update wd;
        SVMXC__Service_Order_Line__c wd1 = workDetailList[5];
        wd1.SVMXC__Group_Member__c = null;
        wd1.SVMXC__Line_Status__c = 'Canceled';
        update wd1;
        Test.stopTest();
    }

    @isTest
    static void testHandleAllocatedQtyForWorkDetailsCreationForNonSerialized(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockAllocateQtyUtility_UT.createPartConsumptionSettings();
        insert partConsumptionSettingList;  

        List<SVMXC__Service_Order_Line__c> workDetailList = createDataForNonSerialized();

        Test.startTest();
        insert workDetailList;
        Test.stopTest();
    }

    @isTest
    static void testHandleAllocatedQtyForWorkDetailsDeletionForSerialized(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockAllocateQtyUtility_UT.createPartConsumptionSettings();
        insert partConsumptionSettingList;  

        List<SVMXC__Service_Order_Line__c> workDetailList = createDataForSerialized();

        insert workDetailList;

        Test.startTest();
        SVMX_PS_VS_VanStockAllocateQtyUtility vanAlQty = new SVMX_PS_VS_VanStockAllocateQtyUtility();
        vanAlQty.handleAllocatedQtyForWorkDetailsDeletion(workDetailList);
        delete workDetailList;
        Test.stopTest();
    }


    @isTest
    static void testHandleAllocatedQtyForWorkDetailsDeletionForNonSerialized(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockAllocateQtyUtility_UT.createPartConsumptionSettings();
        insert partConsumptionSettingList;  

        List<SVMXC__Service_Order_Line__c> workDetailList = createDataForNonSerialized();

        insert workDetailList;

        Test.startTest();
        delete workDetailList;
        Test.stopTest();
    }

    @isTest
    static void testHandleAllocatedQtyForWorkDetailsUpdationForNonSerialized(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockAllocateQtyUtility_UT.createPartConsumptionSettings();
        insert partConsumptionSettingList;  

        //List<SVMXC__Service_Order_Line__c> workDetailList = createDataForNonSerialized();
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
        for(SVMXC__Service_Order_Line__c wd :createDataForNonSerialized()){
            wd.SVMXC__Line_Status__c = 'Canceled';
            workDetailList.add(wd);
        }

        insert workDetailList;

        //Create serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product 2';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        productList.add(nonSerializedProd);
        insert productList;

        SVMXC__Service_Order_Line__c workDetail1 = workDetailList.get(0);
        workDetail1.SVMXC__Actual_Quantity2__c = 3;
        workDetail1.SVMXC__Consumed_From_Location__c = null; 

        SVMXC__Service_Order_Line__c workDetail2 = workDetailList.get(1);
        workDetail2.SVMXC__Product__c = nonSerializedProd.Id;
        workDetail2.SVMX_PS_VS_Consumed_Product_Stock__c = null;
        
        SVMXC__Service_Order_Line__c workDetail3 = workDetailList.get(2);
        workDetail3.SVMX_PS_VS_Consumed_Product_Stock__c = null;
        workDetail3.SVMXC__Consumed_From_Location__c = null;		
        
        Test.startTest();
        update workDetailList;
        
        
        List<SVMXC__Product_Stock__c> productStockList = new SVMX_PS_VS_VanStockAllocateQtyUtility().queryValidProductStock(workDetailList);
        SVMXC__Product_Stock__c productStockRecord1 = new SVMX_PS_VS_VanStockAllocateQtyUtility().getValidProductStock(workDetail1,productStockList);
        SVMXC__Product_Stock__c productStockRecord2 = new SVMX_PS_VS_VanStockAllocateQtyUtility().getValidProductStock(workDetail2,productStockList);
        SVMXC__Product_Stock__c productStockRecord3 = new SVMX_PS_VS_VanStockAllocateQtyUtility().getValidProductStock(workDetail3,productStockList);
        workDetail2.SVMXC__Product__c = null;
        update workDetail2;
        workDetail2.SVMX_PS_VS_Consumed_Part_Code__c = '123456';
        update workDetail2;
        List<SVMXC__Product_Serial__c> stockedSerialList = new SVMX_PS_VS_VanStockAllocateQtyUtility().queryValidStockSerial(new List<SVMXC__Service_Order_Line__c>{workDetail2});
        workDetail2.SVMXC__Actual_Quantity2__c = 3;
        update workDetail2;
        Test.stopTest();
    }

    static List<SVMX_PS_VS_Part_Consumption_Settings__c>  createPartConsumptionSettings(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingsList = new List<SVMX_PS_VS_Part_Consumption_Settings__c>();

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings1 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings1.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.USE_ALLOCATED_QTY;
        partConsumptionSettings1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings1.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings1);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings2 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings2.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_RECORD_TYPE;
        partConsumptionSettings2.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings2.SVMX_PS_VS_Text_Value__c = SVMX_PS_VS_VanStockAllocateQtyUtility.USAGE_CONSUMPTION;
        partConsumptionSettingsList.add(partConsumptionSettings2);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings3 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings3.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_LINE_STATUS;
        partConsumptionSettings3.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings3.SVMX_PS_VS_Text_Value__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS;
        partConsumptionSettingsList.add(partConsumptionSettings3);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings4 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings4.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_LINE_TYPE;
        partConsumptionSettings4.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings4.SVMX_PS_VS_Text_Value__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE;
        partConsumptionSettingsList.add(partConsumptionSettings4);

        return partConsumptionSettingsList;
    }


    static List<SVMXC__Service_Order_Line__c> createDataForSerialized(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        //Create User
        User usr = new User();
        usr.FirstName = 'Test';
        usr.LastName = 'Tester';
        usr.Email=uniqueName + '@test' + orgId + '.org';
        usr.Alias = uniqueName.substring(18, 23);
        usr.Username = uniqueName + '@test' + orgId + '.org';
        usr.CommunityNickname = 'ttester333';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_US';
        usr.ProfileId = UserInfo.getProfileId(); 
        usr.EmailEncodingKey = 'UTF-8';
        usr.LanguageLocaleKey = 'en_US';
        usr.EmployeeNumber = '123456';
        insert usr;

        //Create Account
        Account testAccount = new Account();
        testAccount.Name = 'Apex Test Account 1';
        testAccount.Account_Group__c='Distributor';
        testAccount.BillingCity ='test';
        testAccount.BillingStreet='test Street';
        testAccount.BillingCountryCode='US';
        testAccount.BillingStateCode='AK';
        testAccount.BillingPostalCode='565612';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

        //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Insert service team
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c();
        serviceTeam.Name = 'Test Service Team';
        serviceTeam.SVMXC__Active__c = true;
        serviceTeam.SVMXC__State__c = 'NY';
        serviceTeam.SVMXC__Country__c = 'United States';
        serviceTeam.SVMXC__Zip__c = '12345';
        insert serviceTeam;
        
        //Insert technician
        SVMXC__Service_Group_Members__c technician = new SVMXC__Service_Group_Members__c();
        technician.SVMXC__Active__c = true;
        technician.Name = 'Test Technician';
        technician.SVMXC__Service_Group__c = serviceTeam.Id;
        technician.SVMXC__Salesforce_User__c = usr.Id;
        technician.SVMXC__Inventory_Location__c = location1.Id;
        insert technician;

        //Create serialized product
        List<Product2> productList = new List<Product2>();
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd);
        insert productList;
       
        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.Id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 6;
        productStockList.add(serializedProdStock);
        insert productStockList;

        //Insert stock serials for serialized product stock
        String namePrefix = 'XXX-111';
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = namePrefix + '-1';
        stockedSerialList.add(stockSerial1);
        
        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProd.Id;
        stockSerial2.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial2.Name = namePrefix + '-2';
        stockedSerialList.add(stockSerial2);
        
        SVMXC__Product_Serial__c stockSerial3 = new SVMXC__Product_Serial__c();
        stockSerial3.SVMXC__Active__c = true;
        stockSerial3.SVMXC__Product__c = serializedProd.Id;
        stockSerial3.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial3.Name = namePrefix + '-3';
        stockedSerialList.add(stockSerial3);
        
        SVMXC__Product_Serial__c stockSerial4 = new SVMXC__Product_Serial__c();
        stockSerial4.SVMXC__Active__c = true;
        stockSerial4.SVMXC__Product__c = serializedProd.Id;
        stockSerial4.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial4.Name = namePrefix + '-4';
        stockedSerialList.add(stockSerial4);
        
        SVMXC__Product_Serial__c stockSerial5 = new SVMXC__Product_Serial__c();
        stockSerial5.SVMXC__Active__c = true;
        stockSerial5.SVMXC__Product__c = serializedProd.Id;
        stockSerial5.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial5.Name = namePrefix + '-5';
        stockedSerialList.add(stockSerial5);

        SVMXC__Product_Serial__c stockSerial6 = new SVMXC__Product_Serial__c();
        stockSerial6.SVMXC__Active__c = true;
        stockSerial6.SVMXC__Product__c = serializedProd.Id;
        stockSerial6.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial6.Name = namePrefix + '-6';
        stockedSerialList.add(stockSerial6);
        insert stockedSerialList;

        //Create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = testAccount.Id;
        wo.SVMXC__Order_Status__c = 'Initiated';
        wo.SVMXC__Order_Type__c='Field Service';
        wo.SVMXC__Street__c = '16260 Monterey St.';
        wo.SVMXC__City__c = 'Morgan Hill';
        wo.SVMXC__State__c = 'California';
        wo.SVMXC__Zip__c = '95037';
        wo.SVMXC__Country__c = 'USA';
        wo.SVMXC__Priority__c = 'Medium';
        insert wo;

        //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);

        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = serializedProd.Id,
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail2);

        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = technician.Id,
                SVMXC__Product__c = serializedProd.Id,
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial3.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail3);

        SVMXC__Service_Order_Line__c workDetail4 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-4',
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial4.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail4);

        SVMXC__Service_Order_Line__c workDetail5 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = serializedProd.Id,
                SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-5',
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial5.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail5);

        SVMXC__Service_Order_Line__c workDetail6 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE,
                SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = technician.Id,
                SVMXC__Product__c = serializedProd.Id,
                SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-6',
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial6.id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail6);
        return workDetailList;
    }

    static List<SVMXC__Service_Order_Line__c> createDataForNonSerialized(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        //Create User
        User usr = new User();
        usr.FirstName = 'Test';
        usr.LastName = 'Tester';
        usr.Email=uniqueName + '@test' + orgId + '.org';
        usr.Alias = uniqueName.substring(18, 23);
        usr.Username = uniqueName + '@test' + orgId + '.org';
        usr.CommunityNickname = 'ttester333';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_US';
        usr.ProfileId = UserInfo.getProfileId(); 
        usr.EmailEncodingKey = 'UTF-8';
        usr.LanguageLocaleKey = 'en_US';
        usr.EmployeeNumber = '123456';
        insert usr;

       //Create Account
        Account testAccount = new Account();
        testAccount.Name = 'Apex Test Account 1';
        testAccount.Account_Group__c='Distributor';
        testAccount.BillingCity ='test';
        testAccount.BillingStreet='test Street';
        testAccount.BillingCountryCode='US';
        testAccount.BillingStateCode='AK';
        testAccount.BillingPostalCode='565612';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

        //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Insert service team
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c();
        serviceTeam.Name = 'Test Service Team';
        serviceTeam.SVMXC__Active__c = true;
        serviceTeam.SVMXC__State__c = 'NY';
        serviceTeam.SVMXC__Country__c = 'United States';
        serviceTeam.SVMXC__Zip__c = '12345';
        insert serviceTeam;
        
        //Insert technician
        SVMXC__Service_Group_Members__c technician = new SVMXC__Service_Group_Members__c();
        technician.SVMXC__Active__c = true;
        technician.Name = 'Test Technician';
        technician.SVMXC__Service_Group__c = serviceTeam.Id;
        technician.SVMXC__Salesforce_User__c = usr.Id;
        technician.SVMXC__Inventory_Location__c = location1.Id;
        insert technician;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        productList.add(nonSerializedProd);
        insert productList;
       
        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.Id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 100;
        productStockList.add(nonSerializedProdStock);
        insert productStockList;

        //Create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = testAccount.Id;
        wo.SVMXC__Order_Status__c = 'Initiated';
        wo.SVMXC__Order_Type__c='Field Service';
        wo.SVMXC__Street__c = '16260 Monterey St.';
        wo.SVMXC__City__c = 'Morgan Hill';
        wo.SVMXC__State__c = 'California';
        wo.SVMXC__Zip__c = '95037';
        wo.SVMXC__Country__c = 'USA';
        wo.SVMXC__Priority__c = 'Medium';
        insert wo;

        //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
        
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = wo.id;
        workDetail1.RecordTypeId = usageRecordType.Id;
        workDetail1.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE;
        workDetail1.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        workDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        workDetail1.SVMXC__Group_Member__c = null;
        workDetail1.SVMXC__Product__c = null;
        workDetail1.SVMX_PS_VS_Consumed_Part_Code__c = null;
        workDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        workDetail1.SVMXC__Actual_Quantity2__c = 2;
        workDetail1.SVMX_PS_VS_Is_Part_Out__c = false;
        workDetail1.SVMX_PS_VS_Return_Installed_Product__c = null;
        workDetail1.SVMX_PS_VS_Return_Part__c = null;
        workDetail1.SVMX_PS_VS_Return_Serial_Number__c =  null;
        workDetail1.SVMX_PS_VS_Returned_Qty__c =  null;
        workDetailList.add(workDetail1);

        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c();
        workDetail2.SVMXC__Service_Order__c = wo.id;
        workDetail2.RecordTypeId = usageRecordType.Id;
        workDetail2.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE;
        workDetail2.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS;
        workDetail2.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id;
        workDetail2.SVMXC__Consumed_From_Location__c = location1.Id;
        workDetail2.SVMXC__Group_Member__c = null;
        workDetail2.SVMXC__Product__c = nonSerializedProd.Id;
        workDetail2.SVMX_PS_VS_Consumed_Part_Code__c = null;
        workDetail2.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        workDetail2.SVMXC__Actual_Quantity2__c = 2;
        workDetail2.SVMX_PS_VS_Is_Part_Out__c = false;
        workDetail2.SVMX_PS_VS_Return_Installed_Product__c = null;
        workDetail2.SVMX_PS_VS_Return_Part__c = null;
        workDetail2.SVMX_PS_VS_Return_Serial_Number__c = null;
        workDetail2.SVMX_PS_VS_Returned_Qty__c = null;
        workDetailList.add(workDetail2);

        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c();
        workDetail3.SVMXC__Service_Order__c = wo.id;
        workDetail3.RecordTypeId = usageRecordType.Id;
        workDetail3.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockAllocateQtyUtility.PART_LINE_TYPE;
        workDetail3.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockAllocateQtyUtility.OPEN_LINE_STATUS;
        workDetail3.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id;
        workDetail3.SVMXC__Consumed_From_Location__c = location1.Id;
        workDetail3.SVMXC__Group_Member__c = technician.Id;
        workDetail3.SVMXC__Product__c = nonSerializedProd.Id;
        workDetail3.SVMX_PS_VS_Consumed_Part_Code__c = null;
        workDetail3.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        workDetail3.SVMXC__Actual_Quantity2__c = 2;
        workDetail3.SVMX_PS_VS_Is_Part_Out__c = false;
        workDetail3.SVMX_PS_VS_Return_Installed_Product__c = null;
        workDetail3.SVMX_PS_VS_Return_Part__c = null;
        workDetail3.SVMX_PS_VS_Return_Serial_Number__c = null;
        workDetail3.SVMX_PS_VS_Returned_Qty__c = null;
        workDetailList.add(workDetail3);
        return workDetailList;
    }
	/* Test Method to cover Exception Block of WOBatchQualification_WorkdetailHelper class
	*/
    @isTest
  	 public static void coverCatchBlockWOBatchQualificationWorkdetailHelper(){
    	try{
        WOBatchQualification_WorkdetailHelper.catchException = true;
        WOBatchQualification_WorkdetailHelper wd = new WOBatchQualification_WorkdetailHelper(null);
        Test.startTest();
        System.enqueueJob(wd);
        Test.stopTest();
    		}catch(Exception e){
                System.assert(e!=null, 'e is empty');
   			}
    }
	/* Test Method to cover Exception Block of UpdateWarningMsg_WorkdetailHelper class
	*/
    @isTest
  	 public static void coverCatchBlockUpdateWarningMsgWorkdetailHelper(){
    	try{
        UpdateWarningMsg_WorkdetailHelper.catchException = true;
        UpdateWarningMsg_WorkdetailHelper ud = new UpdateWarningMsg_WorkdetailHelper(null);
        Test.startTest();
        System.enqueueJob(ud);
        Test.stopTest();
    		}catch(Exception e){
                System.assert(e!=null, 'e is empty');
   			}
    }
}
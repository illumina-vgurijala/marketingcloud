/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-09-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest (seeAllData = false)
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockUtility_UT 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
private class SVMX_PS_VS_VanStockUtility_UT  {   
    /*
     * This method tests that if custom setting for part consumption functionality is not active,
     * no transctions to happen
     */
     
    static testmethod void testMethod1(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

        Test.startTest();
        SVMXC__Service_Order__c workOrder = createDataForSerialized();

        //Test.startTest();
        workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        workOrder.PO_Number__c='123';
        Test.stopTest();
        update workOrder;
        //Test.stopTest();
    }

    /*
    * This method tests Serialized Consumption Sucess Case.
    * This will generate 6 Work Details and try to consume them.
    */
    static testmethod void testMethod2(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

        Test.startTest();
        SVMXC__Service_Order__c workOrder = createDataForSerialized();

        //Test.startTest();
        workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update workOrder;
        //Test.stopTest();
    }

    /*
    * This method tests Non-Serialized Consumption Sucess Case.
    * This will generate 3 Work Details and try to consume them.
    */
    static testmethod void testMethod3(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

        Test.startTest();
        SVMXC__Service_Order__c workOrder = createDataForNonSerialized();

        //Test.startTest();
        workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update workOrder;
        //Test.stopTest();
    }

    /*
    * This method tests Serialized Consumption Sucess Case.
    * This will generate 6 Work Details and try to consume them.
    */
    static testmethod void testMethod4(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.CREATE_IP_FROM_SERIALIZED)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

        Test.startTest();
        SVMXC__Service_Order__c workOrder = createDataForSerialized();

        //Test.startTest();
        workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update workOrder;
        //Test.stopTest();
    }

    /*
    * This method tests Non-Serialized Consumption Case.
    * In this method, the technician does not have an inventory location
    * Hence, this will fail with error
    */
    static testmethod void testMethod5(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd);

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
        
        //DCP-33467: Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        // DCP-33467
        //Insert Product Stock DCP-33467
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        productStockList.add(nonSerializedProdStock);
        
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 1;        
        productStockList.add(serializedProdStock);
        insert productStockList;
        
        //DCP-33467 Insert stock serials for serialized product stock
        String namePrefix = 'XXX-111';
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = namePrefix + '-1';
        stockedSerialList.add(stockSerial1);
        insert stockedSerialList;
		// DCP-33467        
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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
		// DCP-33467 nonSerializedProdStock.id,location1.id
         SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
           // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '111',
            SVMXC__Consumed_From_Location__c = location1.id,
            SVMXC__Group_Member__c = technician.Id,
            SVMXC__Product__c = nonSerializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 2,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);
		//DCP-33467 serializedProdStock.id,location1.id,stockSerial1.id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '112',
            SVMXC__Consumed_From_Location__c = location1.id,
            SVMXC__Group_Member__c = technician.Id,
            SVMXC__Product__c = serializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.id,
            SVMXC__Actual_Quantity2__c = 1,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail2);
        Test.startTest();
        insert workDetailList;

        //Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update wo;
		SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper  vanstockUtilObj=new SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper(new SVMXC__Service_Order_Line__c(), null, null, null,new SVMXC__Installed_Product__c(),false);
       // SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper  vanstockUtilObj2=new SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper(new SVMXC__Service_Order_Line__c(), null, null, null,null,new SVMXC__Installed_Product__c(),false,false,null);

        vanstockUtilObj.getIsCreateConsumedProductStock();
        vanstockUtilObj.compareStockConsumptionWrapper(new SVMXC__Service_Order_Line__c());
        vanstockUtilObj.getIsCreateInstalledProduct();
        vanstockUtilObj.setInstalledProduct(new SVMXC__Installed_Product__c());
		
        //Test.stopTest();
    }

    /*
    * This method tests all other scenarios
    *  a. Outside Inventory
    *  c. No Data provided
    *  d. For Non-Serialzed, no Qty Provided
    *  e. No Product Stock Available
    */
    static testmethod void testMethod6(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd);

        Product2 nonSerializedProd2 = new Product2();
        nonSerializedProd2.Name = 'Test Non-Serialized Product2';
        nonSerializedProd2.IsActive = true;
        nonSerializedProd2.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd2.SVMXC__Stockable__c = true;
        nonSerializedProd2.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd2.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd2);
        insert productList;

        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.Id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 6;
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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        //This is outside inventory
        //DCP-33467 location1.Id,nonSerializedProdStock.id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '113',
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = nonSerializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 2,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);

        //This is no data
        //DCP-33467 nonSerializedProdStock.id, location1.Id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '115',
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 2,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail2);

        //This is Non-Serialzed, no Qty Provided
        ////DCP-33467 nonSerializedProdStock.id
        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
           // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '116',
            SVMXC__Product__c = nonSerializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = null,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail3);

        //No Product Stock Provided
        //DCP-33467 nonSerializedProdStock.id
        SVMXC__Service_Order_Line__c workDetail5 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '117',
            SVMXC__Product__c = nonSerializedProd2.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 3,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail5);
        Test.startTest();
        insert workDetailList;

        //Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update wo;
        //Test.stopTest();
    }

    /*
    * This method tests all scenarios with no Stock Serials
    *  a. No Stock Serials available for Product Stock
    *  c. Stock Serials available for Product Stock but no data given
    *  d. Stock Serials available for Product Stock but does not match data given
    */
    static testmethod void testMethod7(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }

            SVMX_PS_VS_Part_Consumption_Settings__c batchSize = new SVMX_PS_VS_Part_Consumption_Settings__c();
            batchSize.Name = SVMX_PS_VS_VanStockUtility.DEFAULT_BATCH_SIZE;
            batchSize.SVMX_PS_VS_Text_Value__c = '50';
            partConsumptionSettingList.add(batchSize);
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 serializedProd1 = new Product2();
        serializedProd1.Name = 'Test Non-Serialized Product';
        serializedProd1.IsActive = true;
        serializedProd1.SVMXC__Tracking__c = 'Serialized';
        serializedProd1.SVMXC__Stockable__c = true;
        serializedProd1.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd1.Serial_Number_Profile__c = 'IL01';
        serializedProd1.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd1);

        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL03';
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
        //DCP-33467
        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProd.Id;
        stockSerial2.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial2.Name = namePrefix + '-2';
        stockedSerialList.add(stockSerial2);
        //DCP-33467
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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        //This case is Stock Serials available for Product Stock but no data given
        //DCP-33467 serializedProdStock.Id, stockSerial1.id, location1.Id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '118',
            SVMXC__Product__c = serializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 1,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);

        //This case is Stock Serials available for Product Stock but does not match data given
        //DCP-33467 stockSerial2.id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
           // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '119',
            SVMX_PS_VS_Consumed_Part_Code__c = 'YYYY-1234',
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 1,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail2);

        //This case is No Stock Serials available for Product Stock
        //DCP-33467 serializedProdStock.Id
        SVMXC__Service_Order_Line__c workDetail4 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '120',
            SVMXC__Product__c = serializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-1',
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 1,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail4);

       //This case is No Stock Serials available for Product Stock
       //DCP-33467 serializedProdStock.Id
        SVMXC__Service_Order_Line__c workDetail5 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '121',
            SVMXC__Product__c = serializedProd1.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111',
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 1,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail5);
        Test.startTest();
        insert workDetailList;

        //Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update wo;
        //Test.stopTest();
    }

    /*
    * This method tests all success scenarios for Part Out Process
    */
    static testmethod void testMethod8(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_ORDER_STATUS)){
                    setting.SVMX_PS_VS_Text_Value__c = 'Technician Onsite';
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);

        SVMXC__Site__c location2 = new SVMXC__Site__c();
        location2.Name = 'Test Location 1';
        location2.SVMXC__Account__c = testAccount.Id;
        location2.SVMXC__Stocking_Location__c = true;
        locationList.add(location2);
        insert locationList;
        
        SVMXC__Installed_Product__c instprod1;
        Product2 serializedProd2;
        SVMXC__Service_Group_Members__c technician;
        Product2 nonSerializedProd;
        SVMXC__Service_Order__c wo;
        
        
       // system.runAs(new User(Id=UserInfo.getUserId())){
            //Insert service team
            SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c();
            serviceTeam.Name = 'Test Service Team';
            serviceTeam.SVMXC__Active__c = true;
            serviceTeam.SVMXC__State__c = 'NY';
            serviceTeam.SVMXC__Country__c = 'United States';
            serviceTeam.SVMXC__Zip__c = '12345';
            insert serviceTeam;
            
            //Insert technician
            technician = new SVMXC__Service_Group_Members__c();
            technician.SVMXC__Active__c = true;
            technician.Name = 'Test Technician';
            technician.SVMXC__Service_Group__c = serviceTeam.Id;
            technician.SVMXC__Salesforce_User__c = usr.Id;
            technician.SVMXC__Inventory_Location__c = location2.Id;
            insert technician;
    
            //Create non-serialized product
            List<Product2> productList = new List<Product2>();
            nonSerializedProd = new Product2();
            nonSerializedProd.Name = 'Test Non-Serialized Product';
            nonSerializedProd.IsActive = true;
            nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
            nonSerializedProd.SVMXC__Stockable__c = true;
            nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
      nonSerializedProd.FRU_Eligible__c = 'FRU use only';
            productList.add(nonSerializedProd);
    
            Product2 serializedProd = new Product2();
            serializedProd.Name = 'Test Serialized Product';
            serializedProd.IsActive = true;
            serializedProd.SVMXC__Tracking__c = 'Serialized';
            serializedProd.SVMXC__Stockable__c = true;
            serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
            serializedProd.Serial_Number_Profile__c = 'IL01';
          serializedProd.FRU_Eligible__c = 'FRU use only';
            productList.add(serializedProd);
    
            serializedProd2 = new Product2();
            serializedProd2.Name = 'Test Serialized Product 2';
            serializedProd2.IsActive = true;
            serializedProd2.SVMXC__Tracking__c = 'Serialized';
            serializedProd2.SVMXC__Stockable__c = true;
            serializedProd2.SVMXC__Enable_Serialized_Tracking__c = true;
            serializedProd2.Serial_Number_Profile__c = 'IL01';
          serializedProd2.FRU_Eligible__c = 'FRU use only';
            productList.add(serializedProd2);
            insert productList;
    
            //Insert Product Stock
            List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
            SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
            serializedProdStock.SVMXC__Location__c = location1.Id;
            serializedProdStock.SVMXC__Product__c = serializedProd.Id;
            serializedProdStock.SVMXC__Status__c = 'Available';
            serializedProdStock.SVMXC__Quantity2__c = 6;
            productStockList.add(serializedProdStock);
        
        	SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
            nonSerializedProdStock.SVMXC__Location__c = location1.Id;
            nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
            nonSerializedProdStock.SVMXC__Status__c = 'Available';
            nonSerializedProdStock.SVMXC__Quantity2__c = 6;
            productStockList.add(nonSerializedProdStock);
            insert productStockList;
        
        //DCP-33467 Insert stock serials for serialized product stock
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
        insert stockedSerialList;
        // DCP-33467
    
            List<SVMXC__Installed_Product__c> installedProductList = new List<SVMXC__Installed_Product__c>();
            instprod1 =  new SVMXC__Installed_Product__c (
                                                Name='IB1',
                                                SVMXC__Serial_Lot_Number__c='IBs1',
                                                SVMXC__Product__c=serializedProd.id ,
                                                SVMXC__Status__c='Installed');
            installedProductList.add(instprod1);
    
            SVMXC__Installed_Product__c instprod2 =  new SVMXC__Installed_Product__c (
                                                Name='IB2',
                                                SVMXC__Serial_Lot_Number__c='IBs2',
                                                SVMXC__Product__c=serializedProd2.id ,
                                                SVMXC__Status__c='Installed');
            installedProductList.add(instprod2);
            insert installedProductList;
      //  }
        
     //   system.runAs(new User(Id=UserInfo.getUserId())){
             //Create Work Order
            wo = new SVMXC__Service_Order__c();
            wo.SVMXC__Company__c = testAccount.Id;
            wo.SVMXC__Order_Status__c = 'Initiated';
            wo.SVMXC__Order_Type__c='Field Service';
            wo.SVMXC__Street__c = '16260 Monterey St.';
            wo.SVMXC__City__c = 'Morgan Hill';
            wo.SVMXC__State__c = 'California';
            wo.SVMXC__Zip__c = '95037';
            wo.SVMXC__Country__c = 'USA';
            wo.SVMXC__Priority__c = 'Medium';
            wo.PO_Number__c='123';
            //wo.SVMX_PS_VS_Consumption_Lines__c;
            insert wo;
             
             //Insert work details
            RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
            List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
    
            //This case is Serialzed IP is given
            //DCP-33467 serializedProdStock.id,location1.Id,stockSerial1
            SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '122',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.id,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = instprod1.Id,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail1);
    
            //This case is Serialzed Product and associated serial no is given
            //DCP-33467 serializedProdStock.id,location1.Id,stockSerial2.id
            SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '123',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.id,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = serializedProd2.id,
                SVMX_PS_VS_Return_Serial_Number__c =  'IBs2',
                SVMX_PS_VS_Returned_Qty__c =  null,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail2);
    
            //This case is Non-Serialzed IP is given where Technician is given and not to location
            //DCP-33467 nonSerializedProdStock.id,location1.Id
            SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = technician.Id,
                SVMXC__Product__c = null,
               Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '124',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = nonSerializedProd.Id,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  2,
                SVMXC__Requested_Location__c = null);
            workDetailList.add(workDetail3);
    
            //This case is Non-Serialzed IP is given where To Location is given
            ////DCP-33467 nonSerializedProdStock.id,location1.Id
            SVMXC__Service_Order_Line__c workDetail4 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '125',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = nonSerializedProd.Id,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  2,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail4);
            insert workDetailList;
      //  }
        Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Technician Onsite';
        update wo;
        Database.executeBatch(new SVMX_PS_VS_VanStockUtility(), 1);
        SVMX_PS_VS_VanStockUtility vSUtility= new SVMX_PS_VS_VanStockUtility();
        List<SVMXC__Service_Order__c> lstWOs =  new List<SVMXC__Service_Order__c>();
        lstWOs.add(wo);
        Database.BatchableContext bc;
        //SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings = new SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'ELIGIBLE_WORK_ORDER_STATUS', SVMX_PS_VS_Text_Value__c = 'Technician Onsite');
        //insert partConsumptionSettings;
        SVMXC__Service_Order__c objWO=[SELECT Id, SVMX_PS_VS_Consumption_Lines__c FROM SVMXC__Service_Order__c WHERE ID =: lstWOs[0].Id];
        System.debug('!!!!!!!!!!!!!!!!!!!!objWO!!!!!!!!!!!!!'+objWO.SVMX_PS_VS_Consumption_Lines__c);
        vSUtility.execute(bc , lstWOs);
        vSUtility.performVanStockManagement(lstWOs);
        Test.stopTest();
    }

    /*
    * This method tests all failure scenarios for Part Out Process
    *  a. No Stock Serial info given when product is serialzed
    *  b. No Qty given when when product is non-serialzed
    *  c. NO Data is provided for restocking
    */
    static testmethod void testMethod9(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_ORDER_STATUS)){
                    setting.SVMX_PS_VS_Text_Value__c = 'Technician Onsite';
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd);

        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd);

        Product2 serializedProd2 = new Product2();
        serializedProd2.Name = 'Test Serialized Product 2';
        serializedProd2.IsActive = true;
        serializedProd2.SVMXC__Tracking__c = 'Serialized';
        serializedProd2.SVMXC__Stockable__c = true;
        serializedProd2.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd2.Serial_Number_Profile__c = 'IL01';
        serializedProd2.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd2);
        insert productList;

        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.Id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 6;
        productStockList.add(serializedProdStock);
        //DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.Id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 6;
        productStockList.add(nonSerializedProdStock);
        //DCP-33467
        insert productStockList;
        
        //DCP-33467 Insert stock serials for serialized product stock
        String namePrefix = 'XXX-11111';
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
        insert stockedSerialList;
        // DCP-33467

        List<SVMXC__Installed_Product__c> installedProductList = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c instprod1 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        installedProductList.add(instprod1);

        SVMXC__Installed_Product__c instprod2 =  new SVMXC__Installed_Product__c (
                                            Name='IB2',
                                            SVMXC__Serial_Lot_Number__c='IBs2',
                                            SVMXC__Product__c=serializedProd2.id ,
                                            SVMXC__Status__c='Installed');
        installedProductList.add(instprod2);
        insert installedProductList;

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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        // No Data provided for stock out
        // DCP-33467 location1.id,stockSerial1.id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
           // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.id,
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '126',
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.id,
            SVMXC__Actual_Quantity2__c = 0,
            SVMX_PS_VS_Is_Part_Out__c = true,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null,
            SVMXC__Requested_Location__c = location1.Id);
        workDetailList.add(workDetail1);

        //No Stock Serial info given when product is serialzed
        // DCP-33467 location1.id,stockSerial2.id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.id,
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '127',
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.id,
            SVMXC__Actual_Quantity2__c = 0,
            SVMX_PS_VS_Is_Part_Out__c = true,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = serializedProd2.id,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null,
            SVMXC__Requested_Location__c = location1.Id);
        workDetailList.add(workDetail2);

        //This case is Serialzed Product and associated serial no is given but no ip exists
        // DCP-33467 location1.id,stockSerial3.id
        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '128',
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial3.id,
            SVMXC__Actual_Quantity2__c = 0,
            SVMX_PS_VS_Is_Part_Out__c = true,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = serializedProd2.id,
            SVMX_PS_VS_Return_Serial_Number__c =  'XXX123YYY1234',
            SVMX_PS_VS_Returned_Qty__c =  null,
            SVMXC__Requested_Location__c = location1.Id);
        workDetailList.add(workDetail3);

        //This case is Non-Serialzed IP is given but Qty not given
        SVMXC__Service_Order_Line__c workDetail6 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '129',
            SVMXC__Product__c = null,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 0,
            SVMX_PS_VS_Is_Part_Out__c = true,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = nonSerializedProd.Id,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null,
            SVMXC__Requested_Location__c = location1.Id);
        workDetailList.add(workDetail6);
        insert workDetailList;

        Test.startTest();
        wo.Integration_Status__c = 'Success';       
        wo.SVMXC__Order_Status__c = 'Canceled';
        update wo;
        Test.stopTest();
    }

    /*
    * This test Non Serialized Error Scenarios:-
    *    a. the qty consumed on work detail greater than on Product Stock Record found
    *    b. the Product Stock Record found has quantity less than zero
    */
    static testmethod void testMethod10(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Serialized';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd);

        Product2 nonSerializedProd2 = new Product2();
        nonSerializedProd2.Name = 'Test Non-Serialized Product';
        nonSerializedProd2.IsActive = true;
        nonSerializedProd2.SVMXC__Tracking__c = 'Non-Serialized';
        nonSerializedProd2.SVMXC__Stockable__c = true;
        nonSerializedProd2.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd2.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd2);
        insert productList;

        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c(
            SVMXC__Location__c = location1.Id,
            SVMXC__Product__c = nonSerializedProd.Id,
            SVMXC__Status__c = 'Available',
            SVMXC__Quantity2__c = 2);
        productStockList.add(nonSerializedProdStock);

        SVMXC__Product_Stock__c nonSerializedProdStock1 = new SVMXC__Product_Stock__c(
            SVMXC__Location__c = location1.Id,
            SVMXC__Product__c = nonSerializedProd2.Id,
            SVMXC__Status__c = 'Available',
            SVMXC__Quantity2__c = 0);
        productStockList.add(nonSerializedProdStock1);
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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        //This case is Stock Serials available for Product Stock but no data given
        //DCP-33467 nonSerializedProdStock1.Id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
           // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock1.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '130',
            SVMXC__Product__c = nonSerializedProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 4,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);

        //This case is Stock Serials available for Product Stock but does not match data given
        //DCP-33467 location1.Id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock1.Id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            SVMXC__Product__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '131',
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
            SVMXC__Actual_Quantity2__c = 3,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail2);
        Test.startTest();
        insert workDetailList;

        //Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update wo;
        //Test.stopTest();
    }


    /*
    * This test Lot/Batch success scenarios
    */
    static testmethod void testMethod11(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;
        
  String  strProfileName = Label.ProfileFieldCompliance;
  Id profileId = [SELECT Id FROM Profile WHERE Name =:strProfileName].Id;
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
        usr.ProfileId = profileId; 
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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

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
        technician.SVMXC__Inventory_Location__c = null;
        insert technician;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);
        insert locationList;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 lotBatchProd = new Product2();
        lotBatchProd.Name = 'Test Non-Serialized Product';
        lotBatchProd.IsActive = true;
        lotBatchProd.SVMXC__Tracking__c = 'Lot/Batch Tracked';
        lotBatchProd.SVMXC__Stockable__c = true;
        lotBatchProd.SVMXC__Enable_Serialized_Tracking__c = false;
    lotBatchProd.FRU_Eligible__c = 'FRU use only';
        productList.add(lotBatchProd);
        insert productList;

        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c lotBatchProdStock = new SVMXC__Product_Stock__c(
            SVMXC__Location__c = location1.Id,
            SVMXC__Product__c = lotBatchProd.Id,
            SVMXC__Status__c = 'Available',
            SVMXC__Quantity2__c = 5);
        productStockList.add(lotBatchProdStock);
        insert productStockList;

        String namePrefix = 'XXX-111';
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = lotBatchProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = lotBatchProdStock.Id;
        stockSerial1.Name = namePrefix + '-1';
        stockedSerialList.add(stockSerial1);
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
        wo.PO_Number__c='123';
        insert wo;

         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        //This case is Stock Serials available for Product Stock but no data given
        //DCP-33467 lotBatchProdStock.id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            RecordTypeId = usageRecordType.Id,
            SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
            //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
            SVMX_PS_VS_Consumed_Product_Stock__c = lotBatchProdStock.id,
            SVMXC__Consumed_From_Location__c = location1.Id,
            SVMXC__Group_Member__c = null,
            Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '132',
            SVMXC__Product__c = lotBatchProd.Id,
            SVMX_PS_VS_Consumed_Part_Code__c = null,
            SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id,
            SVMXC__Actual_Quantity2__c = 0,
            SVMX_PS_VS_Is_Part_Out__c = false,
            SVMX_PS_VS_Return_Installed_Product__c = null,
            SVMX_PS_VS_Return_Part__c = null,
            SVMX_PS_VS_Return_Serial_Number__c =  null,
            SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);
        Test.startTest();
        insert workDetailList;

        //Test.startTest();
        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update wo;
        //Test.stopTest();
    }

    /*
    * This method tests Non-Serialized Consumption Sucess Case.
    * This will generate 3 Work Details and try to consume them.
    * This will be called thru batch and IP's are created
    */
    static testmethod void testMethod12(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.CREATE_IP_FROM_NON_SERIALIZED)){
                    setting.SVMX_PS_VS_Setting_Value__c = true;
                }
            }
        }
        insert partConsumptionSettingList;
        Test.startTest();
        SVMXC__Service_Order__c workOrder = createDataForNonSerialized();

        //Test.startTest();
        workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        Test.stopTest();
        update workOrder;
        //Test.stopTest();
    }

     /*
    * This method tests Part Out Process without restocking
    */
    static testmethod void testMethod14(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.RESTOCKING_OF_PART_OUT)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }
            }
        }
        insert partConsumptionSettingList;

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
        testAccount.BillingPostalCode='5656';
        testAccount.ERP_Customer_Id__c='testERP';
        insert testAccount;

         //Create Location1
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = testAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        locationList.add(location1);

        SVMXC__Site__c location2 = new SVMXC__Site__c();
        location2.Name = 'Test Location 1';
        location2.SVMXC__Account__c = testAccount.Id;
        location2.SVMXC__Stocking_Location__c = true;
        locationList.add(location2);
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
        technician.SVMXC__Inventory_Location__c = location2.Id;
        insert technician;

        //Create non-serialized product
        List<Product2> productList = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    nonSerializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(nonSerializedProd);

        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd);

        Product2 serializedProd2 = new Product2();
        serializedProd2.Name = 'Test Serialized Product 2';
        serializedProd2.IsActive = true;
        serializedProd2.SVMXC__Tracking__c = 'Serialized';
        serializedProd2.SVMXC__Stockable__c = true;
        serializedProd2.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd2.Serial_Number_Profile__c = 'IL01';
        serializedProd2.FRU_Eligible__c = 'FRU use only';
        productList.add(serializedProd2);
        insert productList;

        //Insert Product Stock
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.Id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 6;
        productStockList.add(serializedProdStock);
        // DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.Id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 6;
        productStockList.add(nonSerializedProdStock);        
        insert productStockList;
        // DCP-33467 -->
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
        insert stockedSerialList;
        //  DCP-33467<----

        Test.startTest();
        List<SVMXC__Installed_Product__c> installedProductList = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c instprod1 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed',SVMXC__Company__c=testAccount.id);
        installedProductList.add(instprod1);

        SVMXC__Installed_Product__c instprod2 =  new SVMXC__Installed_Product__c (
                                            Name='IB2',
                                            SVMXC__Serial_Lot_Number__c='IBs2',
                                            SVMXC__Product__c=serializedProd2.id ,
                                            SVMXC__Status__c='Installed',SVMXC__Company__c=testAccount.id);
        installedProductList.add(instprod2);
        insert installedProductList;
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        
            //Create Work Order
            wo.SVMXC__Company__c = testAccount.Id;
            wo.SVMXC__Order_Status__c = 'Initiated';
            wo.SVMXC__Order_Type__c='Field Service';
            wo.SVMXC__Street__c = '16260 Monterey St.';
            wo.SVMXC__City__c = 'Morgan Hill';
            wo.SVMXC__State__c = 'California';
            wo.SVMXC__Zip__c = '95037';
            wo.SVMXC__Country__c = 'USA';
            wo.SVMXC__Priority__c = 'Medium';
            wo.PO_Number__c='123';
            insert wo;
        
             //Insert work details
            RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
            List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
    
            //This case is Serialzed IP is given
            //DCP-33467 serializedProdStock.id,location1.Id,stockSerial1.id
            SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '133',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.id,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = instprod1.Id,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail1);
    
            //This case is Serialzed Product and associated serial no is given
            //DCP-33467 serializedProdStock.id,location1.Id,stockSerial2.id
            SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '134',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.id,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = serializedProd2.id,
                SVMX_PS_VS_Return_Serial_Number__c =  'IBs2',
                SVMX_PS_VS_Returned_Qty__c =  null,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail2);
    
            //This case is Non-Serialzed IP is given where Technician is given and not to location
            //DCP-33467 nonSerializedProdStock.id,location1.Id
            SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.id,
                SVMXC__Group_Member__c = technician.Id,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
                SVMX_PS_External_ID__c = '135',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = nonSerializedProd.Id,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  2,
                SVMXC__Requested_Location__c = null);
            workDetailList.add(workDetail3);
    
            //This case is Non-Serialzed IP is given where To Location is given
            //DCP-33467 nonSerializedProdStock.id,location1.Id
            SVMXC__Service_Order_Line__c workDetail4 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '136',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = null,
                SVMXC__Actual_Quantity2__c = 0,
                SVMX_PS_VS_Is_Part_Out__c = true,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = nonSerializedProd.Id,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  2,
                SVMXC__Requested_Location__c = location1.Id);
            workDetailList.add(workDetail4);
            insert workDetailList;

        wo.Integration_Status__c = 'Success';
        wo.SVMXC__Order_Status__c = 'Closed';
        wo.Service_Report_Generation__c = true;
        Test.stopTest();
        update wo;
    }

    /*
    * This method calls test batch process methods
    */
    static testmethod void testMethod15(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.PERFORM_STOCK_MANAGEMENT_USING_BATCH)){
                    setting.SVMX_PS_VS_Setting_Value__c = true;
                }
            }
        }
        insert partConsumptionSettingList;

        SVMXC__Service_Order__c workOrder = createDataForNonSerialized();

        Test.startTest();
    workOrder.Integration_Status__c = 'Success';
        workOrder.SVMXC__Order_Status__c = 'Closed';
        workOrder.Is_Set_From_Lightning_Component__c = false;
        workOrder.SVMXC__Order_Status__c = 'Initiated';
        update workOrder;
        Datetime dt = Datetime.now().addMinutes(1);
        String strCRONEXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.schedule('Rapid_VanStockFunctionality__XX', strCRONEXP, new SVMX_PS_VS_VanStockUtility() );
        Test.stopTest();
    }
    
    
    

    /*
    * This method calls test schedulelable job
    */
    static testmethod void testMethod16(){
        WorkDetails.boolVanStockTestInProgress  = true;
        List<SVMX_PS_Services_Register__c> serviceRegisterSettingList = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(serviceRegisterSettingList != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSettingList){
                if(serviceRegister.Name.equals(SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSettingList;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = SVMX_PS_VS_VanStockUtility.PART_CONSUMPTION_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockUtility_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY)){
                    setting.SVMX_PS_VS_Setting_Value__c = false;
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockUtility.PERFORM_STOCK_MANAGEMENT_USING_BATCH)){
                    setting.SVMX_PS_VS_Setting_Value__c = true;
                }
            }

            SVMX_PS_VS_Part_Consumption_Settings__c batchSize = new SVMX_PS_VS_Part_Consumption_Settings__c();
            batchSize.Name = SVMX_PS_VS_VanStockUtility.DEFAULT_BATCH_SIZE;
            batchSize.SVMX_PS_VS_Field_Type__c = 'Text';
            batchSize.SVMX_PS_VS_Text_Value__c = '50';
            partConsumptionSettingList.add(batchSize);
        }
        insert partConsumptionSettingList;

        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String strCRONEXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.schedule('Rapid_VanStockFunctionality__XX', strCRONEXP, new SVMX_PS_VS_VanStockUtility() );
        Test.stopTest();
    }

    /*
     * This method tests startBackLogScheduler method
     */
    static testMethod void testMethod17() {
        WorkDetails.boolVanStockTestInProgress  = true;
        SVMX_PS_VS_VanStockUtility.startBackLogScheduler();
    }

    static List<SVMX_PS_VS_Part_Consumption_Settings__c>  createPartConsumptionSettings(){
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingsList = new List<SVMX_PS_VS_Part_Consumption_Settings__c>();
        
        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings1 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings1.Name = SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_ORDER_STATUS;
        partConsumptionSettings1.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings1.SVMX_PS_VS_Text_Value__c = 'Closed';
        partConsumptionSettingsList.add(partConsumptionSettings1);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings2 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings2.Name = SVMX_PS_VS_VanStockUtility.CONSIDER_LOT_BATCH_TRACKING;
        partConsumptionSettings2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings2.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings2);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings3 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings3.Name = SVMX_PS_VS_VanStockUtility.CONSIDER_SERIALIZED_TRACKING;
        partConsumptionSettings3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings3.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings3);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings4 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings4.Name = SVMX_PS_VS_VanStockUtility.CONSIDER_NON_SERIALIZED_TRACKING;
        partConsumptionSettings4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings4.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings4);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings5 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings5.Name = SVMX_PS_VS_VanStockUtility.IS_PRODUCT_STOCK_DECREMENT_ALLOWED;
        partConsumptionSettings5.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings5.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings5);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings6 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings6.Name = SVMX_PS_VS_VanStockUtility.MAINTAIN_STOCK_HISTORY;
        partConsumptionSettings6.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings6.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings6);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings7 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings7.Name = SVMX_PS_VS_VanStockUtility.CREATE_IP_FROM_LOT_BATCH;
        partConsumptionSettings7.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings7.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings7);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings8 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings8.Name = SVMX_PS_VS_VanStockUtility.CREATE_IP_FROM_NON_SERIALIZED;
        partConsumptionSettings8.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings8.SVMX_PS_VS_Setting_Value__c = False;
        partConsumptionSettingsList.add(partConsumptionSettings8);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings9 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings9.Name = SVMX_PS_VS_VanStockUtility.CREATE_IP_FROM_SERIALIZED;
        partConsumptionSettings9.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings9.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings9);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings10 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings10.Name = SVMX_PS_VS_VanStockUtility.OUTSIDE_INVENTORY_ALLOWED;
        partConsumptionSettings10.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings10.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings10);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings11 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings11.Name = SVMX_PS_VS_VanStockUtility.RESTOCKING_OF_PART_OUT;
        partConsumptionSettings11.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings11.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings11);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings12 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings12.Name = SVMX_PS_VS_VanStockUtility.PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        partConsumptionSettings12.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings12.SVMX_PS_VS_Setting_Value__c = False;
        partConsumptionSettingsList.add(partConsumptionSettings12);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings14 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings14.Name = SVMX_PS_VS_VanStockUtility.USE_ALLOCATED_QTY;
        partConsumptionSettings14.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings14.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings14);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings15 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings15.Name = SVMX_PS_VS_VanStockUtility.REMOVED_IP_STATUS;
        partConsumptionSettings15.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings15.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings15);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings16 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings16.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_RECORD_TYPE;
        partConsumptionSettings16.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings16.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings16);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings17 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings17.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_LINE_STATUS;
        partConsumptionSettings17.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings17.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings17);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings18 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings18.Name = SVMX_PS_VS_VanStockAllocateQtyUtility.ELIGIBLE_WORK_DETAIL_LINE_TYPE;
        partConsumptionSettings18.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings18.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings18);

        return partConsumptionSettingsList;
    }

    static SVMXC__Service_Order__c createDataForSerialized(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        //Create User
        User usr = new User();
        usr.FirstName = 'Test';
        usr.LastName = 'Tester';
        usr.Email=uniqueName + '@test' + orgId + '.org';
        usr.Alias = 'ttester3';
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
        testAccount.BillingPostalCode='5656';
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
        wo.PO_Number__c='123';
        insert wo;

        //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
		// DCP-33467 - Location1.id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '137',
                SVMX_PS_VS_Consumed_Part_Code__c = null,
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail1);
		// DCP-33467 serializedProdStock.id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
               // SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '138',
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
		// DCP-33467 - serializedProdStock.id, location1.Id
        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = technician.Id,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '139',
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
		// DCP-33467 Location1.id,serializedProdStock.id
        SVMXC__Service_Order_Line__c workDetail4 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
              //  SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                SVMXC__Product__c = null,
                Consumption_Confirmed__c = true,
            SVMX_PS_External_ID__c = '140',
                SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-4',
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial4.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail4);
		// DCP-33467 serializedProdStock.id, stockSerial5.Id
        SVMXC__Service_Order_Line__c workDetail5 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = null,
                Consumption_Confirmed__c = true,
                SVMX_PS_External_ID__c = '141',
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
		//DCP-33467: serializedProdStock.id,location1.Id,stockSerial6.Id
        SVMXC__Service_Order_Line__c workDetail6 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.id,
                RecordTypeId = usageRecordType.Id,
                SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
                //SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
                SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.id,
                SVMXC__Consumed_From_Location__c = location1.Id,
                SVMXC__Group_Member__c = technician.Id,
                Consumption_Confirmed__c = true,
                SVMX_PS_External_ID__c = '142',
                SVMXC__Product__c = serializedProd.Id,
                SVMX_PS_VS_Consumed_Part_Code__c = 'XXX-111-6',
                SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial6.Id,
                SVMXC__Actual_Quantity2__c = 1,
                SVMX_PS_VS_Is_Part_Out__c = false,
                SVMX_PS_VS_Return_Installed_Product__c = null,
                SVMX_PS_VS_Return_Part__c = null,
                SVMX_PS_VS_Return_Serial_Number__c =  null,
                SVMX_PS_VS_Returned_Qty__c =  null);
        workDetailList.add(workDetail6);
        insert workDetailList;

        return wo;
    }
    
    
    

    static SVMXC__Service_Order__c createDataForNonSerialized(){
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
        testAccount.BillingPostalCode='5656';
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
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        productStockList.add(nonSerializedProdStock);

        SVMXC__Product_Stock__c nonSerializedConsumedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedConsumedProdStock.SVMXC__Location__c = location1.Id;
        nonSerializedConsumedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedConsumedProdStock.SVMXC__Status__c = 'Consumed';
        nonSerializedConsumedProdStock.SVMXC__Quantity2__c = 0;
        productStockList.add(nonSerializedConsumedProdStock);
        insert productStockList;

        //Create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = testAccount.Id;
        wo.SVMXC__Order_Status__c ='Initiated';
        wo.SVMXC__Order_Type__c='Field Service';
        wo.SVMXC__Street__c = '16260 Monterey St.';
        wo.SVMXC__City__c = 'Morgan Hill';
        wo.SVMXC__State__c = 'California';
        wo.SVMXC__Zip__c = '95037';
        wo.SVMXC__Country__c = 'USA';
        wo.SVMXC__Priority__c = 'Medium';
        wo.PO_Number__c='123';
        insert wo;

        //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' And SObjectType = 'SVMXC__Service_Order_Line__c'];
        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();
        // DCP-33467 location1.Id
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = wo.id;
        workDetail1.RecordTypeId = usageRecordType.Id;
        workDetail1.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE;
       // workDetail1.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS;
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
		// DCP-33467 nonSerializedProdStock.Id
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c();
        workDetail2.SVMXC__Service_Order__c = wo.id;
        workDetail2.RecordTypeId = usageRecordType.Id;
        workDetail2.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE;
       // workDetail2.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS;
        workDetail2.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
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
		// DCP-33467 nonSerializedProdStock.Id, location1.Id
        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c();
        workDetail3.SVMXC__Service_Order__c = wo.id;
        workDetail3.RecordTypeId = usageRecordType.Id;
        workDetail3.SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE;
       // workDetail3.SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS;
        workDetail3.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467
        workDetail3.SVMXC__Consumed_From_Location__c = location1.Id; // DCP-33467
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
        insert workDetailList;

        return wo;
    }
   
    
    
}

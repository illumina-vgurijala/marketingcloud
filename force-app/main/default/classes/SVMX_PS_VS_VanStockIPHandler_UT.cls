@isTest (seeAllData = false)
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockIPHandler_UT 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
private class SVMX_PS_VS_VanStockIPHandler_UT
{
    @isTest
    static void testMethod1(){

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

        RecordType svmxObjectMappingProcessRecordType = [Select Id from RecordType 
                            where DeveloperName = 'Object_Mapping' And SObjectType = 'SVMXC__ServiceMax_Processes__c'];
        RecordType svmxConfigDataRecordType = [Select Id from RecordType 
                            where DeveloperName = 'Field_Mapping' And SObjectType = 'SVMXC__ServiceMax_Config_Data__c'];

        List<SVMXC__ServiceMax_Processes__c> processList = new List<SVMXC__ServiceMax_Processes__c>();
        //Work Order Mapping
        SVMXC__ServiceMax_Processes__c svmxWOProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultWorkOrderToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultWorkOrderToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Service_Order__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxWOProcess);

        //Work Detail Mapping
        SVMXC__ServiceMax_Processes__c svmxWDProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultWorkDetailToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultWorkDetailToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Service_Order_Line__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxWDProcess);

        //Product Stock Mapping
        SVMXC__ServiceMax_Processes__c svmxProductStockProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultProductStockToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultProductStockToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Product_Stock__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxProductStockProcess);

        //IP Mapping
        SVMXC__ServiceMax_Processes__c svmxIPProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultIPToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultIPToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxIPProcess);

        //Location Mapping
        SVMXC__ServiceMax_Processes__c svmxLocationProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultLocationToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultLocationToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Site__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxLocationProcess);

        //Product Mapping
        SVMXC__ServiceMax_Processes__c svmxProductProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultProductToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultProductToIPMap',
            SVMXC__Source_Object_Name__c = 'Product2',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxProductProcess);

        //Product Product Serial Mapping
        SVMXC__ServiceMax_Processes__c svmxProductSerialProcess = new SVMXC__ServiceMax_Processes__c(
            SVMXC__MapID__c = 'XXXXXXXX-DefaultProductSerialToIPMap',
            SVMXC__Name__c ='XXXXXXXX-DefaultProductSerialToIPMap',
            SVMXC__Source_Object_Name__c = 'SVMXC__Product_Serial__c',
            SVMXC__Target_Object_Name__c = 'SVMXC__Installed_Product__c',
            SVMXC__Active__c = true,
            RecordTypeId = svmxObjectMappingProcessRecordType.Id);
        processList.add(svmxProductSerialProcess);
        insert processList;

        List<SVMXC__ServiceMax_Config_Data__c> configDataList = new List<SVMXC__ServiceMax_Config_Data__c>();
        SVMXC__ServiceMax_Config_Data__c svmxWOConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxWOProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Company__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Company__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxWOConfigData);

         SVMXC__ServiceMax_Config_Data__c svmxWOConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxWOProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Status__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = 'Installed',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxWOConfigData2);

        SVMXC__ServiceMax_Config_Data__c svmxWDConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxWDProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Billable_Quantity__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Longitude__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxWDConfigData);

        SVMXC__ServiceMax_Config_Data__c svmxWDConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxWDProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Status__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = 'Installed',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxWDConfigData2);

        SVMXC__ServiceMax_Config_Data__c svmxProductStockConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductStockProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Location__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Site__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductStockConfigData);

        SVMXC__ServiceMax_Config_Data__c svmxProductStockConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductStockProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Status__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = 'Installed',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductStockConfigData2);

        SVMXC__ServiceMax_Config_Data__c svmxProductSerialConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductSerialProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Product__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Product__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductSerialConfigData);

        SVMXC__ServiceMax_Config_Data__c svmxProductSerialConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductSerialProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Status__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = 'Installed',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductSerialConfigData2);

        SVMXC__ServiceMax_Config_Data__c svmxProductConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'Name',
            SVMXC__Target_Field_Name__c = 'Name',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductConfigData);

        SVMXC__ServiceMax_Config_Data__c svmxProductConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Status__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = 'Installed',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxProductConfigData2);

       /* SVMXC__ServiceMax_Config_Data__c svmxLocationConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__City__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__City__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxLocationConfigData);*/

        SVMXC__ServiceMax_Config_Data__c svmxLocationConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxProductProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Zip__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = '12345',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxLocationConfigData2);

        /*SVMXC__ServiceMax_Config_Data__c svmxIPConfigData = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxIPProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__City__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__City__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxIPConfigData);*/

        SVMXC__ServiceMax_Config_Data__c svmxIPConfigData2 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxIPProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Product__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Zip__c',
            SVMXC__Parameter_Type__c = 'Field Value',
            SVMXC__Display_Value__c = '12345',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxIPConfigData2);
        
        
        SVMXC__ServiceMax_Config_Data__c svmxIPConfigData4 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxIPProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = null,
            SVMXC__Target_Field_Name__c = 'SVMXC__Zip__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = '12345',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxIPConfigData4);
        
        SVMXC__ServiceMax_Config_Data__c svmxIPConfigData5 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxIPProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'SVMXC__Parent__c',
            SVMXC__Target_Field_Name__c = 'SVMXC__Zip__c',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = '12345',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxIPConfigData5);
        
        SVMXC__ServiceMax_Config_Data__c svmxIPConfigData6 = new SVMXC__ServiceMax_Config_Data__c(
            SVMXC__MapID__c = svmxLocationProcess.Id,
            RecordTypeId = svmxConfigDataRecordType.Id,
            SVMXC__Active__c = true,
            SVMXC__Source_Field_Name__c = 'Name',
            SVMXC__Target_Field_Name__c = 'Name',
            SVMXC__Parameter_Type__c = 'Value',
            SVMXC__Display_Value__c = '12345',
            SVMXC__Configuration_Type__c = 'Field Mapping');
        configDataList.add(svmxIPConfigData6);

        insert configDataList;

        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingList = SVMX_PS_VS_Part_Consumption_Settings__c.getall().values();
        if(partConsumptionSettingList != null){
            delete partConsumptionSettingList;
        }
        partConsumptionSettingList = SVMX_PS_VS_VanStockIPHandler_UT.createPartConsumptionSettings();
        if(partConsumptionSettingList != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c setting : partConsumptionSettingList){
                if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_LOCATION_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultLocationToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_STOCK_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultProductStockToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_SERIAL_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultProductSerialToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_WORK_DETAIL_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultWorkDetailToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_WORK_ORDER_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultWorkOrderToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultProductToIPMap';
                }else if(setting.Name.equals(SVMX_PS_VS_VanStockIPHandler.MAPPING_IP_TO_IP)){
                    setting.SVMX_PS_VS_Text_Value__c = 'XXXXXXXX-DefaultIPToIPMap';
                }
            }
        }
        insert partConsumptionSettingList;
        
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

        List<Product2> productList = new List<Product2>();
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
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

        SVMXC__Installed_Product__c instprod1 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        insert instprod1;
        
        //added by prashanth(DCP-26892)
         SVMXC__Installed_Product__c instprod2 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        instprod2.SVMXC__Parent__c = instprod1.Id;
        instprod2.SVMX_PS_VS_Cloned_From_IP__c = instprod1.Id;
        
         SVMXC__Installed_Product__c instprod3 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        instprod3.SVMX_PS_VS_Cloned_From_IP__c = instprod1.Id;
        instprod3.SVMXC__Top_Level__c = instprod1.Id;
        
        SVMXC__Installed_Product__c instprod4 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        instprod4.SVMXC__Parent__c = instprod1.Id;
        instprod4.SVMX_PS_VS_Cloned_From_IP__c = instprod1.Id;
        
         SVMXC__Installed_Product__c instprod5 =  new SVMXC__Installed_Product__c (
                                            Name='IB1',
                                            SVMXC__Serial_Lot_Number__c='IBs1',
                                            SVMXC__Product__c=serializedProd.id ,
                                            SVMXC__Status__c='Installed');
        instprod5.SVMX_PS_VS_Cloned_From_IP__c = instprod1.Id;
        instprod5.SVMXC__Top_Level__c = instprod1.Id;
        List<SVMXC__Installed_Product__c> lstInstalledProducts = new List<SVMXC__Installed_Product__c>{instprod2,instprod3,instprod4,instprod5};


         //Insert work details
        RecordType usageRecordType = [Select Id from RecordType where DeveloperName = 'UsageConsumption' 
        And SObjectType = 'SVMXC__Service_Order_Line__c'];
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c(
        SVMXC__Service_Order__c = wo.id,
        RecordTypeId = usageRecordType.Id,
        SVMXC__Line_Type__c = SVMX_PS_VS_VanStockUtility.PART_LINE_TYPE,
        SVMXC__Line_Status__c = SVMX_PS_VS_VanStockUtility.OPEN_LINE_STATUS,
        SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id,
        SVMXC__Consumed_From_Location__c = null,
        SVMXC__Product__c = null,
        SVMX_PS_VS_Consumed_Part_Code__c = null,
        SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id,
        SVMXC__Actual_Quantity2__c = 2,
        SVMX_PS_VS_Is_Part_Out__c = false,
        SVMX_PS_VS_Return_Installed_Product__c = instprod1.Id,
        SVMX_PS_VS_Return_Part__c = null,
        SVMX_PS_VS_Return_Serial_Number__c =  null,
        SVMX_PS_VS_Returned_Qty__c =  null,
        SVMXC__Billable_Quantity__c = 2);
        insert workDetail1;

        SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapper =
                new SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper(workDetail1, serializedProdStock, null,
                                                                            stockSerial1, null, true, true, false, null);
        wrapper.setInstalledProduct(instprod1);
        
        List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> wrapperList = 
                new List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper>();
        wrapperList.add(wrapper);
        
        insert lstInstalledProducts;

        Test.startTest();
        SVMX_PS_VS_VanStockIPHandler ipHandler = new SVMX_PS_VS_VanStockIPHandler();
        ipHandler.createInstalledProduct(wrapperList);
        Test.stopTest();
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
        partConsumptionSettings16.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_LOCATION_TO_IP;
        partConsumptionSettings16.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings16.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings16);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings17 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings17.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_STOCK_TO_IP;
        partConsumptionSettings17.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings17.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings17);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings18 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings18.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_TO_IP;
        partConsumptionSettings18.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings18.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings18);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings19 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings19.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_WORK_DETAIL_TO_IP;
        partConsumptionSettings19.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings19.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings19);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings20 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings20.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_WORK_ORDER_TO_IP;
        partConsumptionSettings20.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings20.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings20);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings22 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings22.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_IP_TO_IP;
        partConsumptionSettings22.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings22.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings22);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings23 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings23.Name = SVMX_PS_VS_VanStockIPHandler.MAPPING_PRODUCT_SERIAL_TO_IP;
        partConsumptionSettings23.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings23.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings23);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings24 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings24.Name = SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_DETAIL_RECORD_TYPE;
        partConsumptionSettings24.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings24.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings24);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings25 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings25.Name = SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_DETAIL_LINE_STATUS;
        partConsumptionSettings25.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings25.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings25);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings26 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings26.Name = SVMX_PS_VS_VanStockUtility.ELIGIBLE_WORK_DETAIL_LINE_TYPE;
        partConsumptionSettings26.SVMX_PS_VS_Field_Type__c = 'Text';
        partConsumptionSettings26.SVMX_PS_VS_Text_Value__c = '';
        partConsumptionSettingsList.add(partConsumptionSettings26);

        SVMX_PS_VS_Part_Consumption_Settings__c partConsumptionSettings27 = new SVMX_PS_VS_Part_Consumption_Settings__c();
        partConsumptionSettings27.Name = SVMX_PS_VS_VanStockIPHandler.IS_REPARENTING_ALLOWED;
        partConsumptionSettings27.SVMX_PS_VS_Field_Type__c = 'Boolean';
        partConsumptionSettings27.SVMX_PS_VS_Setting_Value__c = True;
        partConsumptionSettingsList.add(partConsumptionSettings27);

        return partConsumptionSettingsList;
    }
}
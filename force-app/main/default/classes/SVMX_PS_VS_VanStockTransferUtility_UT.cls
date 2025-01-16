/**
 * @description       : Test class to verify the functionality of vanStockTransferUtility
 * @group             : 
 * @last modified on  : 01-09-2023
**/
@isTest
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockTransferUtility_UT 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
private class SVMX_PS_VS_VanStockTransferUtility_UT {
    //These constants are used to retrieve the custom settings. These are the names of custom settings
    private static final String STOCK_TRANSFER_REPORT_FUNCT = 'Stock Transfer Functionality';
    private static final String PERFORM_STOCK_MANAGEMENT_USING_BATCH = 'Perform Stock Transfer using Batch';
    private static final String DEFAULT_BATCH_SIZE = 'Batch Size';
    private static final String CONSIDER_SERIALIZED_TRACKING = 'Consider Serialized Stock Transfer';
    private static final String CONSIDER_NON_SERIALIZED_TRACKING = 'Consider Non-Serialized Stock Transfer';
    private static final String MAINTAIN_STOCK_HISTORY = 'Maintain Stock History';

    //In this test, the functionality is disabled. Hence no stock transfers to happen
    static testMethod void testMethod0(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        Test.StartTest();
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.StopTest();
    }

    //In this test, the functionality is enabled but converted to batch. Here called using trigger, 
    //Hence no stock transfers to happen
    static testMethod void testMethod1(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        Test.StartTest();
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.StopTest();
    }

    //In this test, the functionality is enabled, not using batch
    //Proper Stock Transfer should happen for all stock transfer lines
    static testMethod void testMethod2(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = false;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        Test.StartTest();
        SVMX_PS_VS_VanStockTransferUtility.isStockTransferAlreadyPerformed = false;
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.StopTest();
    }

    //In this test, the functionality is enabled, not using batch
    //a New Stock Transfer line with no reference to Product Stock is added
    //This should fail stock transfer with error
    static testMethod void testMethod3(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = false;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();

        SVMXC__Stock_Transfer_Line__c line8 = new SVMXC__Stock_Transfer_Line__c();
        line8.SVMXC__Posted_To_Inventory__c = false;
        line8.SVMXC__Product__c = null;
        line8.SVMX_PS_VS_Product_Stock__c = null;
        line8.SVMXC__Quantity_Transferred2__c = 4;
        line8.SVMX_PS_VS_Serial_Number__c = null;
        line8.SVMX_PS_VS_Stocked_Serial__c = null;
        line8.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        insert line8;
        
        Test.StartTest();
        boolean isErrorOccurred = false;
        try{
            SVMX_PS_VS_VanStockTransferUtility.isStockTransferAlreadyPerformed = false;
            stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
            update stockTransfer;
        }catch(Exception exceptionRecord){
            System.debug('Error found ' + exceptionRecord);
            isErrorOccurred = true;
        }
        System.assertEquals(true, isErrorOccurred);
        Test.StopTest();
    }

    //In this test, the functionality is enabled but converted to batch. Here called using batch, 
    //Hence stock transfers to happen
    static testMethod void testMethod4(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        
        Test.StartTest();
        SVMX_PS_VS_VanStockTransferUtility stockTransferUtility = new SVMX_PS_VS_VanStockTransferUtility();
        Database.executebatch(stockTransferUtility, 100);
        Test.StopTest();
    }

    //In this test, the functionality is enabled but converted to batch. Here called using scheduled job, 
    //Hence stock transfers to happen
    static testMethod void testMethod5(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String strCRONEXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.schedule('Rapid_StockTransferFunctionality__XX', strCRONEXP, new SVMX_PS_VS_VanStockTransferUtility() );
        Test.stopTest();
    }

    //In this test, erroe conditions for Serialzed Stock Transfer
    static testMethod void testMethod6(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = false;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

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

        //Create Source Location
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = 'source location';
        sourceLocation.SVMXC__Account__c = testAccount.Id;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(sourceLocation);

        //Create Destination Location
        SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
        destinationLocation.Name = 'destination Location';
        destinationLocation.SVMXC__Account__c = testAccount.Id;
        destinationLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(destinationLocation);
        insert locationList;

        //Create serialized product
        List<Product2> productList = new List<Product2>();
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        productList.add(serializedProd);

        Product2 serializedProd2 = new Product2();
        serializedProd2.Name = 'Test Serialized Product 1';
        serializedProd2.IsActive = true;
        serializedProd2.SVMXC__Tracking__c = 'Serialized';
        serializedProd2.SVMXC__Stockable__c = true;
        serializedProd2.SVMXC__Enable_Serialized_Tracking__c = true;
        productList.add(serializedProd2);
        insert productList;
       
        //Insert Product Stock for source location
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c sourceSerializedProdStock = new SVMXC__Product_Stock__c();
        sourceSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        sourceSerializedProdStock.SVMXC__Product__c = serializedProd.Id;
        sourceSerializedProdStock.SVMXC__Status__c = 'Available';
        sourceSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockList.add(sourceSerializedProdStock);

        SVMXC__Product_Stock__c onlySourceSerializedProdStock = new SVMXC__Product_Stock__c();
        onlySourceSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        onlySourceSerializedProdStock.SVMXC__Product__c = serializedProd2.Id;
        onlySourceSerializedProdStock.SVMXC__Status__c = 'Available';
        onlySourceSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockList.add(onlySourceSerializedProdStock);
        
        //Insert Product Stock for destination location
        SVMXC__Product_Stock__c destinationSerializedProdStock = new SVMXC__Product_Stock__c();
        destinationSerializedProdStock.SVMXC__Location__c = destinationLocation.Id;
        destinationSerializedProdStock.SVMXC__Product__c = serializedProd.Id; //was serializedprod before
        destinationSerializedProdStock.SVMXC__Status__c = 'Available';
        destinationSerializedProdStock.SVMXC__Quantity2__c = 1;
        productStockList.add(destinationSerializedProdStock);
        insert productStockList;

        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.Name = '123456';
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.id;
        stockSerial1.SVMXC__Product_Stock__c = sourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial1);

        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.Name = '567890';
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProd.id;
        stockSerial2.SVMXC__Product_Stock__c = sourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial2);

        SVMXC__Product_Serial__c stockSerial3 = new SVMXC__Product_Serial__c();
        stockSerial3.Name = '234567';
        stockSerial3.SVMXC__Active__c = true;
        stockSerial3.SVMXC__Product__c = serializedProd.id;
        stockSerial3.SVMXC__Product_Stock__c = destinationSerializedProdStock.id;
        stockedSerialList.add(stockSerial3);
        insert stockedSerialList;

        //Insert Stock Transfer
        SVMXC__Stock_Transfer__c stockTransfer = new SVMXC__Stock_Transfer__c();
        stockTransfer.SVMXC__Destination_Location__c = destinationLocation.Id;
        stockTransfer.SVMXC__Source_Location__c = sourceLocation.Id;
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = false;
        insert stockTransfer;

        //Create Stock Transfer lines
        List<SVMXC__Stock_Transfer_Line__c> stockedTransferLineList = new List<SVMXC__Stock_Transfer_Line__c>();
        SVMXC__Stock_Transfer_Line__c line1 = new SVMXC__Stock_Transfer_Line__c();
        line1.SVMXC__Posted_To_Inventory__c = false;
        line1.SVMXC__Product__c = serializedProd.Id;
        line1.SVMX_PS_VS_Product_Stock__c = null;
        line1.SVMXC__Quantity_Transferred2__c = 1;
        line1.SVMX_PS_VS_Serial_Number__c = null;
        line1.SVMX_PS_VS_Stocked_Serial__c = null;
        line1.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line1);

        SVMXC__Stock_Transfer_Line__c line2 = new SVMXC__Stock_Transfer_Line__c();
        line2.SVMXC__Posted_To_Inventory__c = false;
        line2.SVMXC__Product__c = null;
        line2.SVMX_PS_VS_Product_Stock__c = sourceSerializedProdStock.Id;
        line2.SVMXC__Quantity_Transferred2__c = 1;
        line2.SVMX_PS_VS_Serial_Number__c = null;
        line2.SVMX_PS_VS_Stocked_Serial__c = stockSerial3.Id;
        line2.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line2);

        SVMXC__Stock_Transfer_Line__c line3 = new SVMXC__Stock_Transfer_Line__c();
        line3.SVMXC__Posted_To_Inventory__c = false;
        line3.SVMXC__Product__c = null;
        line3.SVMX_PS_VS_Product_Stock__c = onlySourceSerializedProdStock.Id;
        line3.SVMXC__Quantity_Transferred2__c = 1;
        line3.SVMX_PS_VS_Serial_Number__c = '125690';
        line3.SVMX_PS_VS_Stocked_Serial__c = null;
        line3.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line3);
        insert stockedTransferLineList;
        
        Test.startTest();
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.stopTest();
    }

    /*
     * This method tests startBackLogScheduler method
     */
    static testMethod void testMethod7() {
        SVMX_PS_VS_VanStockTransferUtility.startBackLogScheduler();
    }


    //Start - Created by Bharath
    static testMethod void testMethod8(){
        List<SVMX_PS_Services_Register__c> transferSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;   
        if(transferSetting != null){
            for(SVMX_PS_Services_Register__c record : transferSetting){
                if(record.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
                    record.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update transferSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = STOCK_TRANSFER_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSetting = SVMX_PS_VS_Stock_Transfer_Settings__c.getall().values();
        if(stockTransferSetting != null){
            delete stockTransferSetting;
        }

        stockTransferSetting = new List<SVMX_PS_VS_Stock_Transfer_Settings__c> ();
        
        SVMX_PS_VS_Stock_Transfer_Settings__c setting1 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting1.Name = PERFORM_STOCK_MANAGEMENT_USING_BATCH;
        setting1.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting1.SVMX_PS_VS_Value__c = false;
        stockTransferSetting.add(setting1);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting2 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting2.Name = MAINTAIN_STOCK_HISTORY;
        setting2.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting2.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting2);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting3 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting3.Name = CONSIDER_SERIALIZED_TRACKING;
        setting3.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting3.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting3);

        SVMX_PS_VS_Stock_Transfer_Settings__c setting4 = new SVMX_PS_VS_Stock_Transfer_Settings__c();
        setting4.Name = CONSIDER_NON_SERIALIZED_TRACKING;
        setting4.SVMX_PS_VS_Field_Type__c = 'Boolean';
        setting4.SVMX_PS_VS_Value__c = true;
        stockTransferSetting.add(setting4);
        insert stockTransferSetting;

        SVMXC__Stock_Transfer__c stockTransfer = SVMX_PS_VS_VanStockTransferUtility_UT.createData();
        
        Test.StartTest();
        SVMX_PS_VS_VanStockTransferUtility.isStockTransferAlreadyPerformed = false;
        //stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c
        //stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.StopTest();
    }
    //End- Created by Bharath

    static SVMXC__Stock_Transfer__c createData(){
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

        //Create Source Location
        List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = 'source location';
        sourceLocation.SVMXC__Account__c = testAccount.Id;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(sourceLocation);

        //Create Destination Location
        SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
        destinationLocation.Name = 'destination Location';
        destinationLocation.SVMXC__Account__c = testAccount.Id;
        destinationLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(destinationLocation);

        insert locationList;

        //Create serialized product
        List<Product2> productList = new List<Product2>();
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        productList.add(serializedProd);

        Product2 serializedProd2 = new Product2();
        serializedProd2.Name = 'Test Serialized Product 1';
        serializedProd2.IsActive = true;
        serializedProd2.SVMXC__Tracking__c = 'Serialized';
        serializedProd2.SVMXC__Stockable__c = true;
        serializedProd2.SVMXC__Enable_Serialized_Tracking__c = true;
        productList.add(serializedProd2);
        
        Product2 serializedProd3 = new Product2();
        serializedProd3.Name = 'Test Serialized Product 2';
        serializedProd3.IsActive = true;
        serializedProd3.SVMXC__Tracking__c = 'Lot/Batch Tracked';
        serializedProd3.SVMXC__Stockable__c = true;
        serializedProd3.SVMXC__Enable_Serialized_Tracking__c = true;
        productList.add(serializedProd3);
        
        //Create non-serialized product
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = 'Test Non-Serialized Product';
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd.SVMXC__Stockable__c = true;
        productList.add(nonSerializedProd);

        Product2 nonSerializedProd2 = new Product2();
        nonSerializedProd2.Name = 'Test Non-Serialized Product 1';
        nonSerializedProd2.IsActive = true;
        nonSerializedProd2.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProd2.SVMXC__Stockable__c = true;
        productList.add(nonSerializedProd2);

        insert productList;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        update serializedProd;
        
        //Insert Product Stock for source location
        List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c sourceSerializedProdStock = new SVMXC__Product_Stock__c();
        sourceSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        sourceSerializedProdStock.SVMXC__Product__c = serializedProd.Id;
        sourceSerializedProdStock.SVMXC__Status__c = 'Available';
        sourceSerializedProdStock.SVMXC__Quantity2__c = 5; //was 2 earlier
        productStockList.add(sourceSerializedProdStock);

        SVMXC__Product_Stock__c sourceNonSerializedProdStock = new SVMXC__Product_Stock__c();
        sourceNonSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        sourceNonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        sourceNonSerializedProdStock.SVMXC__Status__c = 'Available';
        sourceNonSerializedProdStock.SVMXC__Quantity2__c = 10;
        productStockList.add(sourceNonSerializedProdStock);

        SVMXC__Product_Stock__c onlySourceSerializedProdStock = new SVMXC__Product_Stock__c();
        onlySourceSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        onlySourceSerializedProdStock.SVMXC__Product__c = serializedProd2.Id;
        onlySourceSerializedProdStock.SVMXC__Status__c = 'Available';
        onlySourceSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockList.add(onlySourceSerializedProdStock);

        SVMXC__Product_Stock__c onlySourceNonSerializedProdStock = new SVMXC__Product_Stock__c();
        onlySourceNonSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        onlySourceNonSerializedProdStock.SVMXC__Product__c = nonSerializedProd2.Id;
        onlySourceNonSerializedProdStock.SVMXC__Status__c = 'Available';
        onlySourceNonSerializedProdStock.SVMXC__Quantity2__c = 10;
        productStockList.add(onlySourceNonSerializedProdStock);
        
        //Insert Product Stock for destination location
        SVMXC__Product_Stock__c destinationSerializedProdStock = new SVMXC__Product_Stock__c();
        destinationSerializedProdStock.SVMXC__Location__c = destinationLocation.Id;
        destinationSerializedProdStock.SVMXC__Product__c = serializedProd3.Id;//was serializedProd before
        destinationSerializedProdStock.SVMXC__Status__c = 'Available';
        destinationSerializedProdStock.SVMXC__Quantity2__c = 1;
        productStockList.add(destinationSerializedProdStock);

        SVMXC__Product_Stock__c destinationNonSerializedProdStock = new SVMXC__Product_Stock__c();
        destinationNonSerializedProdStock.SVMXC__Location__c = destinationLocation.Id;
        destinationNonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        destinationNonSerializedProdStock.SVMXC__Status__c = 'Available';
        destinationNonSerializedProdStock.SVMXC__Quantity2__c = 5;
        productStockList.add(destinationNonSerializedProdStock);
        insert productStockList;

        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.Name = '123456';
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.id;
        stockSerial1.SVMXC__Product_Stock__c = sourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial1);

        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.Name = '567890';
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProd.id;
        stockSerial2.SVMXC__Product_Stock__c = sourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial2);

        SVMXC__Product_Serial__c stockSerial3 = new SVMXC__Product_Serial__c();
        stockSerial3.Name = '234567';
        stockSerial3.SVMXC__Active__c = true;
        stockSerial3.SVMXC__Product__c = serializedProd.id;
        stockSerial3.SVMXC__Product_Stock__c = destinationSerializedProdStock.id;
        stockedSerialList.add(stockSerial3);

        SVMXC__Product_Serial__c stockSerial4 = new SVMXC__Product_Serial__c();
        stockSerial4.Name = '678123';
        stockSerial4.SVMXC__Active__c = true;
        stockSerial4.SVMXC__Product__c = serializedProd2.id;
        stockSerial4.SVMXC__Product_Stock__c = onlySourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial4);
        
        SVMXC__Product_Serial__c stockSerial5 = new SVMXC__Product_Serial__c();
        stockSerial5.Name = '125690';
        stockSerial5.SVMXC__Active__c = true;
        stockSerial5.SVMXC__Product__c = serializedProd2.id;
        stockSerial5.SVMXC__Product_Stock__c = onlySourceSerializedProdStock.id;
        stockedSerialList.add(stockSerial5);
        insert stockedSerialList;

        //Insert Stock Transfer
        SVMXC__Stock_Transfer__c stockTransfer = new SVMXC__Stock_Transfer__c();
        stockTransfer.SVMXC__Destination_Location__c = destinationLocation.Id;
        stockTransfer.SVMXC__Source_Location__c = sourceLocation.Id;
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = false;
        insert stockTransfer;

        //Create Stock Transfer lines
        List<SVMXC__Stock_Transfer_Line__c> stockedTransferLineList = new List<SVMXC__Stock_Transfer_Line__c>();
        SVMXC__Stock_Transfer_Line__c line1 = new SVMXC__Stock_Transfer_Line__c();
        line1.SVMXC__Posted_To_Inventory__c = false;
        line1.SVMXC__Product__c = serializedProd.Id;
        line1.SVMX_PS_VS_Product_Stock__c = null;
        line1.SVMXC__Quantity_Transferred2__c = 1;
        line1.SVMX_PS_VS_Serial_Number__c = '123456';
        line1.SVMX_PS_VS_Stocked_Serial__c = null;
        line1.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line1);

        SVMXC__Stock_Transfer_Line__c line2 = new SVMXC__Stock_Transfer_Line__c();
        line2.SVMXC__Posted_To_Inventory__c = false;
        line2.SVMXC__Product__c = null;
        line2.SVMX_PS_VS_Product_Stock__c = sourceSerializedProdStock.Id;
        line2.SVMXC__Quantity_Transferred2__c = 1;
        line2.SVMX_PS_VS_Serial_Number__c = null;
        line2.SVMX_PS_VS_Stocked_Serial__c = stockSerial2.Id;
        line2.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line2);

        SVMXC__Stock_Transfer_Line__c line3 = new SVMXC__Stock_Transfer_Line__c();
        line3.SVMXC__Posted_To_Inventory__c = false;
        line3.SVMXC__Product__c = null;
        line3.SVMX_PS_VS_Product_Stock__c = onlySourceSerializedProdStock.Id;
        line3.SVMXC__Quantity_Transferred2__c = 1;
        line3.SVMX_PS_VS_Serial_Number__c = null;
        line3.SVMX_PS_VS_Stocked_Serial__c = stockSerial4.Id;
        line3.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line3);

        SVMXC__Stock_Transfer_Line__c line4 = new SVMXC__Stock_Transfer_Line__c();
        line4.SVMXC__Posted_To_Inventory__c = false;
        line4.SVMXC__Product__c = serializedProd2.Id;
        line4.SVMX_PS_VS_Product_Stock__c = null;
        line4.SVMXC__Quantity_Transferred2__c = 1;
        line4.SVMX_PS_VS_Serial_Number__c = '125690';
        line4.SVMX_PS_VS_Stocked_Serial__c = null;
        line4.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line4);

        SVMXC__Stock_Transfer_Line__c line5 = new SVMXC__Stock_Transfer_Line__c();
        line5.SVMXC__Posted_To_Inventory__c = false;
        line5.SVMXC__Product__c = nonSerializedProd.Id;
        line5.SVMX_PS_VS_Product_Stock__c = null;
        line5.SVMXC__Quantity_Transferred2__c = 4;
        line5.SVMX_PS_VS_Serial_Number__c = null;
        line5.SVMX_PS_VS_Stocked_Serial__c = null;
        line5.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line5);

        SVMXC__Stock_Transfer_Line__c line6 = new SVMXC__Stock_Transfer_Line__c();
        line6.SVMXC__Posted_To_Inventory__c = false;
        line6.SVMXC__Product__c = null;
        line6.SVMX_PS_VS_Product_Stock__c = sourceNonSerializedProdStock.Id;
        line6.SVMXC__Quantity_Transferred2__c = 4;
        line6.SVMX_PS_VS_Serial_Number__c = null;
        line6.SVMX_PS_VS_Stocked_Serial__c = null;
        line6.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line6);

        SVMXC__Stock_Transfer_Line__c line7 = new SVMXC__Stock_Transfer_Line__c();
        line7.SVMXC__Posted_To_Inventory__c = false;
        line7.SVMXC__Product__c = null;
        line7.SVMX_PS_VS_Product_Stock__c = onlySourceNonSerializedProdStock.Id;
        line7.SVMXC__Quantity_Transferred2__c = 4;
        line7.SVMX_PS_VS_Serial_Number__c = null;
        line7.SVMX_PS_VS_Stocked_Serial__c = null;
        line7.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line7);

        SVMXC__Stock_Transfer_Line__c line8 = new SVMXC__Stock_Transfer_Line__c();
        line8.SVMXC__Posted_To_Inventory__c = false;
        line8.SVMXC__Product__c = nonSerializedProd2.Id;
        line8.SVMX_PS_VS_Product_Stock__c = null;
        line8.SVMXC__Quantity_Transferred2__c = 4;
        line8.SVMX_PS_VS_Serial_Number__c = null;
        line8.SVMX_PS_VS_Stocked_Serial__c = null;
        line8.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line8);
        
        //Start - added to increase coverage
        SVMXC__Stock_Transfer_Line__c line9 = new SVMXC__Stock_Transfer_Line__c();
        line9.SVMXC__Posted_To_Inventory__c = false;
        line9.SVMXC__Product__c = serializedProd.Id;
        line9.SVMX_PS_VS_Product_Stock__c = destinationSerializedProdStock.Id;// was sourceSerializedProdStock
        line9.SVMXC__Quantity_Transferred2__c = 1;
        line9.SVMX_PS_VS_Serial_Number__c = '123456';
        line9.SVMX_PS_VS_Stocked_Serial__c = stockSerial3.id;//was null before
        line9.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        stockedTransferLineList.add(line9);
        //End - added to increase coverage
        insert stockedTransferLineList;

        return stockTransfer;
    }
}
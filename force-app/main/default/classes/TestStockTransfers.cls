@isTest
/***************************************************************************************************************************************
* NAME   : TestStockTransfers 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public class TestStockTransfers {
    //These constants are used to retrieve the custom settings. These are the names of custom settings
    private static final String STOCK_TRANSFER_REPORT_FUNCT = 'Stock Transfer Functionality';
    private static final String PERFORM_STOCK_MANAGEMENT_USING_BATCH = 'Perform Stock Transfer using Batch';
    private static final String DEFAULT_BATCH_SIZE = 'Batch Size';
    private static final String CONSIDER_SERIALIZED_TRACKING = 'Consider Serialized Stock Transfer';
    private static final String CONSIDER_NON_SERIALIZED_TRACKING = 'Consider Non-Serialized Stock Transfer';
    private static final String MAINTAIN_STOCK_HISTORY = 'Maintain Stock History';

    //In this test, the functionality is enabled, not using batch
    //Proper Stock Transfer should happen for all stock transfer lines
    static testMethod void testStockTransfer(){
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
            system.assertNotEquals(null,newSetting.id);
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
        system.assertNotEquals(0,stockTransferSetting.size());
        insert stockTransferSetting;
        system.assertNotEquals(null,stockTransferSetting[0].id);

        SVMXC__Stock_Transfer__c stockTransfer = TestStockTransfers.createData();
        
        Test.StartTest();
        SVMX_PS_VS_VanStockTransferUtility.isStockTransferAlreadyPerformed = false;
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        update stockTransfer;
        Test.getEventBus().deliver();
        Test.StopTest();
    }

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
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        insert serializedProd;
        system.assertNotEquals(null,serializedProd.id);
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        update serializedProd;
        system.debug('product query: '+[select Id,Name,IsActive,SVMXC__Tracking__c,SVMXC__Stockable__c,SVMXC__Enable_Serialized_Tracking__c from Product2 where id=:serializedProd.id]);
       
        //Insert Product Stock for source location
        SVMXC__Product_Stock__c sourceSerializedProdStock = new SVMXC__Product_Stock__c();
        sourceSerializedProdStock.SVMXC__Location__c = sourceLocation.Id;
        sourceSerializedProdStock.SVMXC__Product__c = serializedProd.Id;
        sourceSerializedProdStock.SVMXC__Status__c = 'Available';
        sourceSerializedProdStock.SVMXC__Quantity2__c = 2;
        insert sourceSerializedProdStock;
        system.assertNotEquals(null,sourceSerializedProdStock.id);

        //Insert stock serials for serialized product stock
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.Name = '123456';
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.id;
        stockSerial1.SVMXC__Product_Stock__c = sourceSerializedProdStock.id;
        insert stockSerial1;
        system.assertNotEquals(null,stockSerial1.id);

        //Insert Stock Transfer
        SVMXC__Stock_Transfer__c stockTransfer = new SVMXC__Stock_Transfer__c();
        stockTransfer.SVMXC__Destination_Location__c = destinationLocation.Id;
        stockTransfer.SVMXC__Source_Location__c = sourceLocation.Id;
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        insert stockTransfer;
        system.assertNotEquals(null,stockTransfer.id);
        
        //Create Stock Transfer lines
        SVMXC__Stock_Transfer_Line__c line1 = new SVMXC__Stock_Transfer_Line__c();
        line1.SVMXC__Posted_To_Inventory__c = false;
        line1.SVMXC__Product__c = serializedProd.Id;
        line1.SVMX_PS_VS_Product_Stock__c = sourceSerializedProdStock.id;
        line1.SVMXC__Quantity_Transferred2__c = 1;
        line1.SVMX_PS_VS_Serial_Number__c = '123456';
        line1.SVMX_PS_VS_Stocked_Serial__c = null;
        line1.SVMXC__Stock_Transfer__c = stockTransfer.Id;
        insert line1;
        system.assertNotEquals(null,line1.id);
        
        return stockTransfer;
    }
}
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockTransferUtility 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
global with sharing class SVMX_PS_VS_VanStockTransferUtility implements Schedulable, Database.Batchable<SVMXC__Stock_Transfer__c>, Database.AllowsCallouts, Database.Stateful {
  //These constants are used to retrieve the custom settings. These are the names of custom settings
  private static final String STOCK_TRANSFER_REPORT_FUNCT = 'Stock Transfer Functionality';
  private static final String PERFORM_STOCK_MANAGEMENT_USING_BATCH = 'Perform Stock Transfer using Batch';
  private static final String DEFAULT_BATCH_SIZE = 'Batch Size';
  private static final String CONSIDER_SERIALIZED_TRACKING = 'Consider Serialized Stock Transfer';
  private static final String CONSIDER_NON_SERIALIZED_TRACKING = 'Consider Non-Serialized Stock Transfer';
  private static final String MAINTAIN_STOCK_HISTORY = 'Maintain Stock History';

  private static final String NEED_STOCK_SERIAL_ERROR_MSG = ' has Serialized Product. Hence, For Stock Transfer, need a Stock Serial or Serial Number';
  private static final String NEED_PRODUCT_STOCK_ERROR_MSG = 'For Stock Transfer, need a Product Stock or Product reference';
  private static final String NEED_LOCATION_ERROR_MSG = 'For Stock Transfer, need Source and Destination Location';
  private static final String NO_SOURCE_PRODUCT_STOCK_FOUND_ERROR_MSG = 'While Performing Stock Transfer, could not locate correct Source Product Stock Record';
  private static final String NO_SOURCE_STOCK_SERIAL_FOUND_ERROR_MSG = 'While Performing Stock Transfer, could not locate correct Source Stock Serial Record';
  private static final String NO_ENOUGH_QTY_FOUND_ERROR_MSG = 'While Performing Stock Transfer, Source Product Stock Does not have enough quantity for transfer';

  //Boolean to stop recursive loop
  @Testvisible private static boolean isStockTransferAlreadyPerformed = false;
  //Variable to store the record type "Stock History"
  private static Id stockHistoryRecordTypeId;
  //Variable to store the record type "Serial History"
  private static Id serialHistoryRecordTypeId;
  //Boolean to check if the stock management using batch or not
  public boolean isPerformStockTransferUsingBatch;
  //Boolean to store if Part Consumption Service is active or not
  public boolean isStockTransferActive;
  //Boolean to indicate if Serialzed Stock Transfers allowed
  private boolean isSerialzedStockTransferAllowed;
  //Boolean to indicate if Non-Serialzed Stock Transfers allowed
  private boolean isNonSerialzedStockTransferAllowed;
  //Boolean to store if need to Maintain Stock History
  private boolean isMaintainStockHistoryAllowed;

  /*****************************************************************************************************************************************
  *  Constructor Name  : RAPID_SVMXC_VanStockTransferUtility
  *  Parameter         : --
  *  Returns           : --
  *  Description       : First Check the ServiceMax Service Register and make sure that Stock Transfer is Active or not.  
  *                      If Active, then retrieve the custom settings associated with Stock Transfer
  *******************************************************************************************************************************************/
  public SVMX_PS_VS_VanStockTransferUtility() {
  //Check if the functionality is active or not
    if(!checkIfStockTransferFunctionalityIsActive()){
        System.debug('VanStockTransferUtility: Stock Transfer Service is not active. Hence Ignore');
        System.debug('VanStockTransferUtility: Please go to Service Register Custom Settings and Activate the Stock Transfer Functionality');
        isStockTransferActive = false;
    }else{
        System.debug('VanStockTransferUtility: Part Consumption is active. Hence continue');
        isStockTransferActive = true;

        Schema.DescribeSObjectResult stockHistoryObj = Schema.SObjectType.SVMXC__Stock_History__c;
        Map<String,Schema.RecordTypeInfo> stockHistoryRecordTypeMap = stockHistoryObj.getRecordTypeInfosByName();
        stockHistoryRecordTypeId = stockHistoryRecordTypeMap.get('Stock History').getRecordTypeId();
        serialHistoryRecordTypeId = stockHistoryRecordTypeMap.get('Serial History').getRecordTypeId();

        //Read all Custom Settings and store it for use
        System.debug('VanStockTransferUtility: Read All Custom Settings');
        retrieveStockTransferSetting();
        System.debug('VanStockTransferUtility: All Custom Settings set');
    } 
  }

  /*****************************************************************************************************************************************
  *  Method Name : start
  *  Parameter   : Database.BatchableContext BC
  *  Returns     : Iterable<SVMXC__Stock_Transfer__c> -- List of Stock Transfers for which transfer needs to be performed
  *  Description : This represents the start of batch when batching is used. This does query stock transfers 
  *                with “Perform Stock Transfer” set to True and where Not Posted Item  are more than 1. 
  *                It then sends such stock transfers for processing
  *******************************************************************************************************************************************/
  global Iterable<SVMXC__Stock_Transfer__c> start(Database.BatchableContext bc){
    System.debug('VanStockTransferUtility: Batch started');

    List<SVMXC__Stock_Transfer__c> stockTransferList = new List<SVMXC__Stock_Transfer__c>();

    //Check if part consumption service is active or not
    if(isStockTransferActive){
      String query = 'SELECT ID, Name, SVMX_PS_VS_Perform_Stock_Transfer__c, SVMXC__Destination_Location__c, SVMXC__Source_Location__c, ' + 
                    'SVMXC__Not_Posted_Item_Count__c FROM SVMXC__Stock_Transfer__c ' +
                    'WHERE SVMX_PS_VS_Perform_Stock_Transfer__c = TRUE AND ' +
                    'SVMXC__Not_Posted_Item_Count__c > 0';
      if(Test.isRunningTest()){
        query += ' ORDER BY CreatedDate DESC LIMIT 5';
      }
      System.debug('VanStockUtility: Batch Query :' + query);

      stockTransferList = Database.query(query);
    }else{
       System.debug('VanStockTransferUtility: Stock Transfer Service is not Active. Hence do not proceed further');
    }

    System.debug('VanStockTransferUtility: Batch start finished');
    return stockTransferList;
  }
  
  /*****************************************************************************************************************************************
  *  Method Name : execute
  *  Parameter   : Database.BatchableContext BC
  *                List<SVMXC__Stock_Transfer__c> stockTransferList  -- List of Stock Transfers for which transfer needs to be performed
  *  Returns     : ---
  *  Description : This method actually executes all stock transfers
  *******************************************************************************************************************************************/  
  global void execute(Database.BatchableContext bc, List<SVMXC__Stock_Transfer__c> stockTransferList){
    System.debug('VanStockTransferUtility: Batch execution started');
    if(stockTransferList != null && stockTransferList.size() > 0){
        System.debug('VanStockTransferUtility: Processing Stock Consumption');
        performStockTransfer(stockTransferList);
        System.debug('VanStockTransferUtility: Processing Stock Consumption finished');
    }else{
        System.debug('VanStockTransferUtility: No Stock Transfers to process');
    }  
    System.debug('VanStockTransferUtility: Batch execution finished');    
  }

  /*****************************************************************************************************************************************
  *  Method Name : finish
  *  Parameter   : Database.BatchableContext BC
  *  Returns     : ---
  *  Description : This method actually executes is called when all batch processed are completed
  *******************************************************************************************************************************************/  
  global void finish(Database.BatchableContext bc){
    System.debug('VanStockTransferUtility: Batch execution finished');
  }

  /*****************************************************************************************************************************************
  *  Method Name : execute
  *  Parameter   : SchedulableContext SC
  *  Returns     : ---
  *  Description : This method actually called when a scheduled job is executed
  *                This method calls invokes the batch process for doing stock transfer code
  *******************************************************************************************************************************************/  
  global void execute(SchedulableContext sc) {
    System.debug('VanStockTransferUtility: Schedule Batch execution started');
  
    String batchSize = null;

    List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSettingsList = SVMX_PS_VS_Stock_Transfer_Settings__c.getAll().values();
    if(stockTransferSettingsList != null){
        for(SVMX_PS_VS_Stock_Transfer_Settings__c stockTransferSetting : stockTransferSettingsList){
          if(stockTransferSetting.Name.equals(DEFAULT_BATCH_SIZE)){
              batchSize = stockTransferSetting.SVMX_PS_VS_Text_Value__c;
              break;
          }
        }
    }

    Integer intBatchSize = 0;
    if(batchSize != null && !batchSize.trim().equals('')){
        intBatchSize = Integer.valueOf(batchSize);
    }

    if(intBatchSize <= 0){
        intBatchSize = 50;
    }

    SVMX_PS_VS_VanStockTransferUtility vanStockTransferUtility = new SVMX_PS_VS_VanStockTransferUtility();
    Database.executebatch(vanStockTransferUtility, intBatchSize);
    System.debug('VanStockTransferUtility : Schedule Batch execution done');
  }

  /*****************************************************************************************************************************************
  *  Method Name : startBackLogScheduler
  *  Parameter   : ---
  *  Returns     : ---
  *  Description : This method schedules Van Stock Transfer code every 1 hour.
  *                You can use the following code to schedule jobs using developer console
  *                -----------------------------------------
  *                  SVMX_PS_VS_VanStockTransferUtility.startBackLogScheduler();
  *                -----------------------------------------
  *******************************************************************************************************************************************/  
  global static void startBackLogScheduler() {
    SVMX_PS_VS_VanStockTransferUtility vanStockTransferUtility = new SVMX_PS_VS_VanStockTransferUtility();
    String schedule00 = '0 0 * * * ?';
    if (!Test.isRunningTest()){
        system.schedule('Van Stock Transfer Handler Job 00', schedule00, vanStockTransferUtility);
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : performStockTransfer
  *  Parameter   : List<SVMXC__Stock_Transfer__c> stockTransferList - list of stock transfers to be processed.
  *  Returns     : --
  *  Description : This method performs stock transfer. This is called from trigger or from batch process.
  *                This method performs a recursive check and avoids recursive call
  *                Also checks if the Stock Transfer Functionality is active or not.
  *                Then checks if Stock Transfer is valid for processing.
  *                For this, it used two checks:-
  *                   a. Flag "Perform Stock Transfer" should be checked
  *                   b. Field "Not Posted Item Count" should be more than zero.
  *                If found valid, then starts processing line and performs stock transfer
  *******************************************************************************************************************************************/  
  public void performStockTransfer(List<SVMXC__Stock_Transfer__c> stockTransferList){
    if(!isStockTransferAlreadyPerformed){
      isStockTransferAlreadyPerformed = true;
      System.debug('VanStockTransferUtility : Start Stock Transfer Processing');

      //Check if stock transfer service is active or not
      if(isStockTransferActive){
        //List to store valid work orders
        List<SVMXC__Stock_Transfer__c> validStockTransferList = new List<SVMXC__Stock_Transfer__c>();

        if(stockTransferList != null && stockTransferList.size() > 0){
            for(SVMXC__Stock_Transfer__c stockTransfer : stockTransferList){
              //Check if the stock transfer is eligible for part consumption. 
              //Field "SVMX_Perform_Stock_Transfer" should checked and 
              //Not Posted Item Count should be more than 0
              if(stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c && stockTransfer.SVMXC__Not_Posted_Item_Count__c > 0){
                validStockTransferList.add(stockTransfer);
              }
            }

            if(validStockTransferList.size() > 0){
              //Get Stock Trasnfer Lines associated with the Valid Stock Transfer Lines
              Map<Id, List<SVMXC__Stock_Transfer_Line__c>> stockTransferIdStockLineMap
                                     = queryStockTransferLines(validStockTransferList);
              
              //start processing stock transfers
              if(stockTransferIdStockLineMap != null && stockTransferIdStockLineMap.size() > 0){
                handleStockTransfer(stockTransferIdStockLineMap,validStockTransferList);
              }else{
                  System.debug('VanStockTransferUtility : No Stock Transfer Lines Valid for Processing');
              }
            }else{
              System.debug('VanStockTransferUtility : No Stock Transfers Valid for Processing');
            }
        }else{
            System.debug('VanStockTransferUtility : No Stock Transfers Found for Processing');
        }
      }else{
        System.debug('VanStockTransferUtility: Stock Transfer Service is not active. Hence Ignore');
      }
      System.debug('VanStockTransferUtility : End Stock Transfer Processing');
    }else{
      System.debug('VanStockTransferUtility : This is recursive loop. Already performed once Stock Transfer');
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryStockTransferLines
  *  Parameter   : List<SVMXC__Stock_Transfer__c> stockTransferList - List of Stock Transfers to be used for Stock Transfer
  *  Returns     : Map<Id, List<SVMXC__Stock_Transfer_Line__c>> - Map containing Stock Transfer Id as key and List of Stock Transfer line
  *                                                               which will be used for Stock Transfer
  *  Description : This method queries the Stock Transfer Lines Record.
  *******************************************************************************************************************************************/  
  @TestVisible private Map<Id, List<SVMXC__Stock_Transfer_Line__c>> queryStockTransferLines(List<SVMXC__Stock_Transfer__c> stockTransferList){
    List<SVMXC__Stock_Transfer_Line__c>  stockTransferLineList = null;
    Map<Id, List<SVMXC__Stock_Transfer_Line__c>> stockTransferIdStockLineMap = new Map<Id, List<SVMXC__Stock_Transfer_Line__c>>();
    
    if(stockTransferList != null){
        stockTransferLineList = [SELECT Id, Name, SVMXC__Posted_To_Inventory__c, SVMXC__Product__c, SVMX_PS_VS_Product_Stock__c,
                        SVMXC__Quantity_Transferred2__c, SVMX_PS_VS_Serial_Number__c, SVMX_PS_VS_Stocked_Serial__c,
                        SVMXC__Stock_Transfer__c , SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c,
                        SVMXC__Product__r.SVMXC__Stockable__c, SVMXC__Product__r.SVMXC__Tracking__c,
                        SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Stockable__c,
                        SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c,
                        SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Tracking__c 
                           FROM SVMXC__Stock_Transfer_Line__c  
                           WHERE SVMXC__Stock_Transfer__c IN :stockTransferList
                              AND SVMXC__Posted_To_Inventory__c = False];

          if(stockTransferLineList != null && stockTransferLineList.size() > 0){
            for(SVMXC__Stock_Transfer_Line__c stockTransferLine : stockTransferLineList){
              List<SVMXC__Stock_Transfer_Line__c> stockLineList = stockTransferIdStockLineMap.get(stockTransferLine.SVMXC__Stock_Transfer__c);

              if(stockLineList == null){
                stockLineList = new List<SVMXC__Stock_Transfer_Line__c>();
                stockTransferIdStockLineMap.put(stockTransferLine.SVMXC__Stock_Transfer__c,stockLineList);
              }
              stockLineList.add(stockTransferLine);
            }
          }
    }else{
        System.debug('VanStockTransferUtility : No Stock Transfer found for querying Stock Transfer Lines');
    }

    return stockTransferIdStockLineMap;
  }

 /*****************************************************************************************************************************************
  *  Method Name : handleStockTransfer
  *  Parameter   : Map<Id, List<SVMXC__Stock_Transfer_Line__c>> stockTransferIdStockLineMap - Map of Stock Transfer Id as key and associated 
  *                                                                   list of all stock transfer lines as values
  *                List<SVMXC__Stock_Transfer__c> stockTransferList - list of all stock transfers which need to be processed
  *  Returns     : --
  *  Description : This method actually performs Stock Transfers
  *                First this checks if Source and Destination Locations are avaialable or not
  *                Then anaylzes each stock transfer line by using following algorithm:
  *                 a. Finds all Product Stock either at Source or Destination location. For this, data is provided on stock
  *                    Transfer Line. Either field "Product Stock" is populated or "Product" is given. Using Source or Destination
  *                    Location, we can find the correct product stock. Preference is given to "Product Stock" field in case both 
  *                    "Product Stock" & "Product" are populated. Product Stock with Status "Available" is only selected.
  *                 b. Finds all Stock Serials .For this, data is provided on stock Transfer Line. Either field "Stock Serial" is populated 
  *                    or "Serial Number" is given. Preference is given to "Stock Serial" field in case both "Stock Serial" & "Serial Number" 
  *                    are populated.
  *                 c. Now for each Stock Transfer Line, source product stock and destination product stock is found. If Source product
  *                    Stock is not found, error is sent. For Destination Product stock if not found, a new one is created
  *                 d. If Product Stock is Serialzed, then stock serial is found and transferred between source and destionation product stock
  *                    Quantity at Source is reduced by 1 and at destination increased by 1. If Source qty becomes 0, 
  *                    status is changed to "consumed"
  *                 e. If Product Stock is Non-Serialzed, then Quantity at Source is reduced by transferred qty and at destination increased 
  *                    by transferred qty. If Source qty becomes less than 0, error is raised.If Source qty becomes 0, 
  *                    status is changed to "consumed"
  *                 f. Stock Serial Line is updated to have field "Post to Inventory" to true.
  *                 g. Stock History records are created for source and destination product stocks.
  *                 h. finally all data is committed to database.
  *                 Following Messages are given for error conditions:-
  *                ------------------------------------------------------------------------------------------------------------------------
  *                       ERROR CONDITION                               |      MESSAGE
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When Stock Transfer Line has product stock serialzed | Line XXXXX has Serialized Product. Hence, For Stock Transfer,
  *                and no stock serial info provided                    | need a Stock Serial or Serial Number
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When no product stock info is provided               | For Stock Transfer, need a Product Stock or Product reference
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When Source or Destination Locations are not provided| For Stock Transfer, need Source and Destination Location
  *                on Stock Transfer                                    |
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When unable to find Source Product Stock using info  | While Performing Stock Transfer, could not locate correct 
  *                provided                                             | Source Product Stock Record
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When unable to find Source Stock Serial using info   | While Performing Stock Transfer, could not locate correct 
  *                provided                                             | Source Stock Serial Record
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When Qty at Source Product Stock is not enough to    | While Performing Stock Transfer, Source Product Stock Does not 
  *                to perform stock transfer                            | have enough quantity for transfer
  *                ------------------------------------------------------------------------------------------------------------------------
  *******************************************************************************************************************************************/  
  @TestVisible private void handleStockTransfer(Map<Id, List<SVMXC__Stock_Transfer_Line__c>> stockTransferIdStockLineMap,
                      List<SVMXC__Stock_Transfer__c> stockTransferList){
    //Set for storing Id of product stock which need to be queried
    Set<Id> productStockSet = new Set<Id>();
    //Set for storing Id of product which need to be queried
    Set<Id> productIdSet = new Set<Id>();
    //Set for storing Id of stock serial which need to be queried
    Set<Id> stockSerialSet = new Set<Id>();
    //Set for storing Id of serial number which need to be queried
    Set<String> serialNumberSet = new Set<String>();
    //Set for storing Id of location which need to be queried
    Set<Id> locationIdSet = new Set<Id>();
    //Variable to flag if there is an error in case of stock transfer
    boolean isErrorFound = false;

    for(SVMXC__Stock_Transfer__c stockTransfer : stockTransferList){
      if(stockTransfer.SVMXC__Source_Location__c != null && stockTransfer.SVMXC__Destination_Location__c != null){
        List<SVMXC__Stock_Transfer_Line__c> stockTransferLinesList = stockTransferIdStockLineMap.get(stockTransfer.Id);
        
        //Set Source and Destination Location Ids
        locationIdSet.add(stockTransfer.SVMXC__Source_Location__c);
        locationIdSet.add(stockTransfer.SVMXC__Destination_Location__c);

        if(stockTransferLinesList != null && stockTransferLinesList.size() > 0){
          for(SVMXC__Stock_Transfer_Line__c stockTransferLine : stockTransferLinesList){
            //check if product stock is given
            if(stockTransferLine.SVMX_PS_VS_Product_Stock__c != null){
              //check if the prouduct is serialized or non-serailzed
              if(stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ||
                  stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized') || 
                  stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                if(stockTransferLine.SVMX_PS_VS_Serial_Number__c != null){
                  productStockSet.add(stockTransferLine.SVMX_PS_VS_Product_Stock__c);
                  serialNumberSet.add(stockTransferLine.SVMX_PS_VS_Serial_Number__c);
                }else if(stockTransferLine.SVMX_PS_VS_Stocked_Serial__c != null){
                  productStockSet.add(stockTransferLine.SVMX_PS_VS_Product_Stock__c);
                  stockSerialSet.add(stockTransferLine.SVMX_PS_VS_Stocked_Serial__c);
                }else{
                  stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NEED_STOCK_SERIAL_ERROR_MSG);
                  System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NEED_STOCK_SERIAL_ERROR_MSG);
                  isErrorFound = true;
                }
              //this is non-serialzed. Handle this case
              } else {
                productStockSet.add(stockTransferLine.SVMX_PS_VS_Product_Stock__c);
              }
            //check if the product is given
            }else if(stockTransferLine.SVMXC__Product__c != null){
              //check if the prouduct is serialized or non-serailzed
              if(stockTransferLine.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ||
                  stockTransferLine.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized') || 
                  stockTransferLine.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                if(stockTransferLine.SVMX_PS_VS_Stocked_Serial__c != null){
                  productIdSet.add(stockTransferLine.SVMXC__Product__c);
                  stockSerialSet.add(stockTransferLine.SVMX_PS_VS_Stocked_Serial__c);
                }else if(stockTransferLine.SVMX_PS_VS_Serial_Number__c != null){
                  productIdSet.add(stockTransferLine.SVMXC__Product__c);
                  serialNumberSet.add(stockTransferLine.SVMX_PS_VS_Serial_Number__c);
                }else{
                  stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NEED_STOCK_SERIAL_ERROR_MSG);
                  System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NEED_STOCK_SERIAL_ERROR_MSG);
                  isErrorFound = true;
                }
              //this is non-serialzed. Handle this case
              } else {
                productIdSet.add(stockTransferLine.SVMXC__Product__c);
              }
            }else{
              stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NEED_PRODUCT_STOCK_ERROR_MSG);
              System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NEED_PRODUCT_STOCK_ERROR_MSG);
              isErrorFound = true;
            }
          }
        }else{
          System.debug('VanStockTransferUtility : No Stock Transfer Lines found for ' + stockTransfer.Name);
        }
      }else{
        stockTransfer.addError(NEED_LOCATION_ERROR_MSG);
        System.debug('VanStockTransferUtility :' + NEED_LOCATION_ERROR_MSG);
        isErrorFound = true;
      }
    }

    if(!isErrorFound){
      //Map to store the Stock Serials found
      Map<Id, List<SVMXC__Product_Serial__c>> productStockIdStockSerialListMap = null;
      //Map to store the Product Stock found
      Map<String, SVMXC__Product_Stock__c> productStockUniqueStringRecordMap = null;
      //Map to store the unique Key of Product Stock and Stock Serial in case of Product Stock is newly created
      Map<String, SVMXC__Product_Serial__c> productStockIdStockSerialMap = new Map<String, SVMXC__Product_Serial__c> ();
      //Map to store the unique Key of Product Stock and Stock History in case of Product Stock is newly created
      Map<String, SVMXC__Stock_History__c> productStockIdStockHistoryMap = new Map<String, SVMXC__Stock_History__c> ();

      //Map of Product Stock Id and Product Stock rec. This is used to commit to database as a unique record
      Map<Id,SVMXC__Product_Stock__c> finalProductStockMap = new Map<Id,SVMXC__Product_Stock__c> ();
      //List of store product stock updated/created
      Set<SVMXC__Product_Stock__c> finalCreatedProductStockSet = new Set<SVMXC__Product_Stock__c> ();
      //List of store stock serials to be updated
      Set<SVMXC__Product_Serial__c> finalStockSerialSet = new Set<SVMXC__Product_Serial__c>();
      //List of stock history to be created
      Set<SVMXC__Stock_History__c> finalStockHistorySet = new Set<SVMXC__Stock_History__c>();
      //List of Stock Transfer Lines
      Set<SVMXC__Stock_Transfer_Line__c> finalStockTransferLinesSet = new Set<SVMXC__Stock_Transfer_Line__c>();

      //Get all Product Stock
      List<SVMXC__Product_Stock__c> productStockList = getProductStock(productStockSet, productIdSet, locationIdSet);
      
      //If all product Stock found, get proper stock serials
      if(productStockList != null && productStockList.size() > 0){
        productStockUniqueStringRecordMap = new Map<String, SVMXC__Product_Stock__c>();

        //Get all Stocked Serials
        productStockIdStockSerialListMap = getStockSerials(stockSerialSet, serialNumberSet);

        for(SVMXC__Product_Stock__c productStock : productStockList){
          productStockUniqueStringRecordMap.put(productStock.Id, productStock);
          String uniqueString = productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c;
          productStockUniqueStringRecordMap.put(uniqueString, productStock);
        }

        //Start actual processing stock Transfer Lines
        for(SVMXC__Stock_Transfer__c stockTransfer : stockTransferList){
          System.debug('VanStockTransferUtility : Start working on Stock Transfer - ' + stockTransfer.Id);

          List<SVMXC__Stock_Transfer_Line__c> stockTransferLinesList = stockTransferIdStockLineMap.get(stockTransfer.Id);
          
          if(stockTransferLinesList != null && stockTransferLinesList.size() > 0){
            for(SVMXC__Stock_Transfer_Line__c stockTransferLine : stockTransferLinesList){

              System.debug('VanStockTransferUtility : Start working on Stock Transfer Line - ' + stockTransferLine.Name);

              //Variable to store the source product stock record in processing
              SVMXC__Product_Stock__c sourceProductStockRecord = null;
              //Variable to store the destination product stock record in processing
              SVMXC__Product_Stock__c destinationProductStockRecord = null;
              //Variable to store the stock serial record if any in processing
              SVMXC__Product_Serial__c sourceStockSerialRecord = null;
              //Variable to flag if Product Stock is serialzed or not
              boolean isSerialzedProductStock = false;
              //Variable to store if destination product stock is created or not
              boolean isDestinationProductStockCreated = false;
              //Variable to store unique string to get appropriate Product Stock
              String destinationUniqueString = null;
            
              //First find the source product stock
              //check if product stock is given
              if(stockTransferLine.SVMX_PS_VS_Product_Stock__c != null){
                sourceProductStockRecord = productStockUniqueStringRecordMap.get(stockTransferLine.SVMX_PS_VS_Product_Stock__c);

                if(stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ||
                    stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized') || 
                    stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                  isSerialzedProductStock = true;
                }

                destinationUniqueString = stockTransfer.SVMXC__Destination_Location__c + '-' 
                                          + stockTransferLine.SVMX_PS_VS_Product_Stock__r.SVMXC__Product__c;

              //check if the product is given
              }else if(stockTransferLine.SVMXC__Product__c != null){
                String uniqueString = stockTransfer.SVMXC__Source_Location__c + '-' + stockTransferLine.SVMXC__Product__c;
                sourceProductStockRecord = productStockUniqueStringRecordMap.get(uniqueString);

                if(stockTransferLine.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ||
                    stockTransferLine.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized') || 
                    stockTransferLine.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                   isSerialzedProductStock = true;
                }

                destinationUniqueString = stockTransfer.SVMXC__Destination_Location__c + '-' + stockTransferLine.SVMXC__Product__c;
              }

              //check if source product stock found or not
              if(sourceProductStockRecord != null){
                System.debug('Found Source Product Stock - ' + sourceProductStockRecord.Id);

                //get Destination Product Stock
                destinationProductStockRecord = productStockUniqueStringRecordMap.get(destinationUniqueString);
                if(destinationProductStockRecord != null){
                  System.debug('Found Destination Product Stock - ' + destinationProductStockRecord.Id);
                }else{
                  System.debug('No Destination Product Stock found');
                }

                if(isSerialzedProductStock){
                  System.debug('Source Product Stock is serialzed');

                  //find the stock serials
                  List<SVMXC__Product_Serial__c> stockSerialList = productStockIdStockSerialListMap.get(sourceProductStockRecord.Id);

                  if(stockSerialList != null && stockSerialList.size() > 0){
                    for(SVMXC__Product_Serial__c stockSerialRecord : stockSerialList){
                      if(stockTransferLine.SVMX_PS_VS_Stocked_Serial__c != null 
                            && stockSerialRecord.Id == stockTransferLine.SVMX_PS_VS_Stocked_Serial__c){
                        sourceStockSerialRecord = stockSerialRecord;
                      }else if(stockTransferLine.SVMX_PS_VS_Serial_Number__c != null
                            && stockSerialRecord.Name == stockTransferLine.SVMX_PS_VS_Serial_Number__c){
                        sourceStockSerialRecord = stockSerialRecord;
                      }
                    }

                    if(sourceStockSerialRecord != null){
                      //store the stock serial for commiting to db
                      finalStockSerialSet.add(sourceStockSerialRecord);

                      //reduce the source product qty by 1
                      sourceProductStockRecord.SVMXC__Quantity2__c = sourceProductStockRecord.SVMXC__Quantity2__c - 1;
                      if(sourceProductStockRecord.SVMXC__Quantity2__c <= 0){
                        sourceProductStockRecord.SVMXC__Quantity2__c = 0;
                        sourceProductStockRecord.SVMXC__Status__c = 'Consumed';
                      }
                      finalProductStockMap.put(sourceProductStockRecord.Id,sourceProductStockRecord);

                      //increase the destination product qty by 1
                      if(destinationProductStockRecord != null){
                        destinationProductStockRecord.SVMXC__Quantity2__c = destinationProductStockRecord.SVMXC__Quantity2__c + 1;
                        sourceStockSerialRecord.SVMXC__Product_Stock__c = destinationProductStockRecord.Id;
                        finalProductStockMap.put(destinationProductStockRecord.Id,destinationProductStockRecord);
                        isDestinationProductStockCreated = false;
                      }else{
                        destinationProductStockRecord = new SVMXC__Product_Stock__c();
                        destinationProductStockRecord.SVMXC__Location__c = stockTransfer.SVMXC__Destination_Location__c;
                        destinationProductStockRecord.SVMXC__Product__c  = sourceProductStockRecord.SVMXC__Product__c;
                        destinationProductStockRecord.SVMXC__Quantity2__c = 1;
                        destinationProductStockRecord.SVMXC__Status__c = 'Available';
                        finalCreatedProductStockSet.add(destinationProductStockRecord);
                        isDestinationProductStockCreated = true;

                        String uniqueKey = destinationProductStockRecord.SVMXC__Location__c + '-' + destinationProductStockRecord.SVMXC__Product__c;
                        productStockIdStockSerialMap.put(uniqueKey,sourceStockSerialRecord);
                      }

                      //create stock history
                      List<SVMXC__Stock_History__c> stockHistoryList = createStockHistoryRecords(sourceProductStockRecord.Id, destinationProductStockRecord.Id, 
                                                                           sourceStockSerialRecord.Id, sourceProductStockRecord.SVMXC__Product__c, 
                                                                           stockTransfer.Id, stockTransferLine.Id,
                                                                           sourceProductStockRecord.SVMXC__Quantity2__c + 1.0, 
                                                                           sourceProductStockRecord.SVMXC__Quantity2__c,
                                                                           destinationProductStockRecord.SVMXC__Quantity2__c - 1.0, 
                                                                           destinationProductStockRecord.SVMXC__Quantity2__c,1.0);
                      if(stockHistoryList != null && stockHistoryList.size() > 0){
                        finalStockHistorySet.addAll(stockHistoryList);

                        if(isDestinationProductStockCreated){
                          String uniqueKey = destinationProductStockRecord.SVMXC__Location__c + '-' + destinationProductStockRecord.SVMXC__Product__c;
                          productStockIdStockHistoryMap.put(uniqueKey,stockHistoryList.get(1));
                        }
                      }

                      //update Stock Transfer Line
                      stockTransferLine.SVMXC__Posted_To_Inventory__c = True;
                      finalStockTransferLinesSet.add(stockTransferLine);

                    }else{
                      stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_STOCK_SERIAL_FOUND_ERROR_MSG);
                      System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_STOCK_SERIAL_FOUND_ERROR_MSG);
                    }
                  }else{
                    stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_STOCK_SERIAL_FOUND_ERROR_MSG);
                    System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_STOCK_SERIAL_FOUND_ERROR_MSG);
                  }
                //Perform Non-Serialzed Stock Transfer
                }else{
                  sourceProductStockRecord.SVMXC__Quantity2__c = sourceProductStockRecord.SVMXC__Quantity2__c - stockTransferLine.SVMXC__Quantity_Transferred2__c;
                  //check if sufficent qty available for stock transfer.
                  if(sourceProductStockRecord.SVMXC__Quantity2__c >= 0){
                    finalProductStockMap.put(sourceProductStockRecord.Id,sourceProductStockRecord);

                    //update the destination product stock
                    if(destinationProductStockRecord != null){
                      destinationProductStockRecord.SVMXC__Quantity2__c = destinationProductStockRecord.SVMXC__Quantity2__c + stockTransferLine.SVMXC__Quantity_Transferred2__c;
                      isDestinationProductStockCreated = false;
                      finalProductStockMap.put(destinationProductStockRecord.Id,destinationProductStockRecord);
                    }else{
                      destinationProductStockRecord = new SVMXC__Product_Stock__c();
                      destinationProductStockRecord.SVMXC__Location__c = stockTransfer.SVMXC__Destination_Location__c;
                      destinationProductStockRecord.SVMXC__Product__c  = sourceProductStockRecord.SVMXC__Product__c;
                      destinationProductStockRecord.SVMXC__Quantity2__c = stockTransferLine.SVMXC__Quantity_Transferred2__c;
                      destinationProductStockRecord.SVMXC__Status__c = 'Available';
                      isDestinationProductStockCreated = true;
                      finalCreatedProductStockSet.add(destinationProductStockRecord);
                    }

                    //Create Stock History Record
                    List<SVMXC__Stock_History__c> stockHistoryList = createStockHistoryRecords(sourceProductStockRecord.Id, destinationProductStockRecord.Id, 
                                                                       null, sourceProductStockRecord.SVMXC__Product__c, stockTransfer.Id, stockTransferLine.Id,
                                                                       sourceProductStockRecord.SVMXC__Quantity2__c + stockTransferLine.SVMXC__Quantity_Transferred2__c, 
                                                                       sourceProductStockRecord.SVMXC__Quantity2__c,
                                                                       destinationProductStockRecord.SVMXC__Quantity2__c -stockTransferLine.SVMXC__Quantity_Transferred2__c, 
                                                                       destinationProductStockRecord.SVMXC__Quantity2__c,
                                                                       stockTransferLine.SVMXC__Quantity_Transferred2__c);
                    if(stockHistoryList != null && stockHistoryList.size() > 0){
                      finalStockHistorySet.addAll(stockHistoryList);
                      if(isDestinationProductStockCreated){
                        String uniqueKey = destinationProductStockRecord.SVMXC__Location__c + '-' + destinationProductStockRecord.SVMXC__Product__c;
                        productStockIdStockHistoryMap.put(uniqueKey,stockHistoryList.get(1));
                      }
                    }

                    //Update Stock Transfer Line
                    stockTransferLine.SVMXC__Posted_To_Inventory__c = True;
                    finalStockTransferLinesSet.add(stockTransferLine);

                  }else{
                    stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NO_ENOUGH_QTY_FOUND_ERROR_MSG);
                    System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NO_ENOUGH_QTY_FOUND_ERROR_MSG);
                  }
                }
              }else{
                stockTransfer.addError('Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_PRODUCT_STOCK_FOUND_ERROR_MSG);
                System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' - ' + NO_SOURCE_PRODUCT_STOCK_FOUND_ERROR_MSG);
              }

              System.debug('VanStockTransferUtility : Line ' + stockTransferLine.Name + ' finished processing');
            }

            System.debug('VanStockTransferUtility : Finished processing stock transfer lines'); 
          }else{
            System.debug('VanStockTransferUtility : No Stock Transfer Lines found for processing');
          }

          System.debug('VanStockTransferUtility : Line ' + stockTransfer.Id + ' finished processing');
        }

        //Commit Changes to Database
        Savepoint savePointRec = Database.setSavepoint();

        try{
          List<SVMXC__Product_Stock__c> createdProductStockList = new List<SVMXC__Product_Stock__c> ();
          if(finalCreatedProductStockSet != null && finalCreatedProductStockSet.size() > 0){
            System.debug('VanStockTransferUtility: Creating new Product Stock');
            createdProductStockList.addAll(finalCreatedProductStockSet);
            Database.insert(createdProductStockList, true);
            System.debug('VanStockTransferUtility: Done with Creation of new Product Stock');
          }

          for(SVMXC__Product_Stock__c productStockRecord : createdProductStockList){
            String uniqueKey = productStockRecord.SVMXC__Location__c + '-' + productStockRecord.SVMXC__Product__c;

            SVMXC__Product_Serial__c sourceStockSerialRecord = productStockIdStockSerialMap.get(uniqueKey);
            if(sourceStockSerialRecord != null){
              sourceStockSerialRecord.SVMXC__Product_Stock__c = productStockRecord.Id;
            }

            SVMXC__Stock_History__c stockHistoryRec = productStockIdStockHistoryMap.get(uniqueKey);
            stockHistoryRec.SVMXC__Product_Stock__c = productStockRecord.Id;
          }
          
          List<sObject> allObjectsList = new List<sObject>();

          if(finalProductStockMap != null && finalProductStockMap.size() > 0){
            List<sObject> sobjectList = (List<sObject>) finalProductStockMap.values();
            allObjectsList.addAll(sobjectList);
          }else{
            System.debug('VanStockTransferUtility: No Product Stock to be updated');
          }

          if(finalStockTransferLinesSet != null && finalStockTransferLinesSet.size() > 0){
            List<SVMXC__Stock_Transfer_Line__c> updatedStockTransferList = new List<SVMXC__Stock_Transfer_Line__c> ();
            updatedStockTransferList.addAll(finalStockTransferLinesSet);
            List<sObject> sobjectList = (List<sObject>) updatedStockTransferList;
            allObjectsList.addAll(sobjectList);
          }else{
            System.debug('VanStockTransferUtility: No Stock Transfer Lines to be updated');
          }

          if(finalStockSerialSet != null && finalStockSerialSet.size() > 0){
            List<SVMXC__Product_Serial__c> stockSerialList = new List<SVMXC__Product_Serial__c> ();
            stockSerialList.addAll(finalStockSerialSet);
            List<sObject> sobjectList = (List<sObject>) stockSerialList;
            allObjectsList.addAll(sobjectList);
          }else{
            System.debug('VanStockTransferUtility: No Stock Serials to be updated');
          }

          if(allObjectsList.size() > 0){
            System.debug('VanStockTransferUtility: Updating Product Stock, Stock Serial and Stock Transfer Lines');
            Database.update(allObjectsList, true);
            System.debug('VanStockTransferUtility: Done with Updation for Product Stock and Stock Transfer Lines');
          }

          if(finalStockHistorySet != null && finalStockHistorySet.size() > 0){
            System.debug('VanStockTransferUtility: Create Stock History');
            List<SVMXC__Stock_History__c> stockHistoryList = new List<SVMXC__Stock_History__c> ();
            stockHistoryList.addAll(finalStockHistorySet);
            Database.insert(stockHistoryList, true);
            System.debug('VanStockTransferUtility: Done with Creation of Stock History');
          }else{
            System.debug('VanStockTransferUtility: No Stock History Lines to be created');
          }
        }catch(Exception exceptionRecord){
          System.debug('VanStockTransferUtility: Problem while commiting of records - ' + exceptionRecord.getMessage());
          Database.rollback(savePointRec);
          throw exceptionRecord;
        }
      }else{
        System.debug('VanStockTransferUtility : No Product Stock found by query');
      }
    }else{
      System.debug('VanStockTransferUtility : Error found while processing stock transfer. Please do not continue');
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : getProductStock
  *  Parameter   : Set<Id> productStockSet - Set for Ids of Product Stock which need to be queried
  *                Set<Id> productIdSet - Set for Ids of Product which will be used for querying product stock
  *                Set<Id> locationIdSet - Set for Ids of Locations which will be used for querying product stock
  *  Returns     : List<SVMXC__Product_Stock__c> - list of Product Stock queried
  *  Description : This method queries product stock based on Id's given or combination of product and location given.
  *                This method then returns the queries records
  *******************************************************************************************************************************************/  
  @TestVisible private List<SVMXC__Product_Stock__c> getProductStock(Set<Id> productStockSet, Set<Id> productIdSet, Set<Id> locationIdSet){
    //List of Product Stock Queried
    List<SVMXC__Product_Stock__c> productStockList = null;

    //Create Query String for all Product Stock Id's available
    String productStockIdString = null;
    if(productStockSet != null && productStockSet.size() > 0){
      productStockIdString = createQueryStringUsingList('Id', productStockSet);
    }

    //Create Query String for all Product Id's available
    String productIdString = null;
    if(productIdSet != null && productIdSet.size() > 0){
      productIdString = createQueryStringUsingList('SVMXC__Product__c', productIdSet);
    }

    //Create Query String for all Locations Id's available
    String locationIdString = null;
    if(locationIdSet != null && locationIdSet.size() > 0){
      locationIdString = createQueryStringUsingList('SVMXC__Location__c',locationIdSet);
    }

    //Create Product Stock Query
    String productStockQueryString = 'SELECT Id,Name,SVMXC__Allocated_Qty__c,SVMXC__Available_Qty__c,' +
                                      'SVMXC__Location__c,SVMXC__Product__c,SVMXC__Quantity2__c,'+ 
                                      'SVMXC__Product__r.SVMXC__Stockable__c,SVMXC__Product__r.SVMXC__Tracking__c,'+ 
                                      'SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c,SVMXC__Status__c ' +
                                      'FROM SVMXC__Product_Stock__c WHERE SVMXC__Status__c = \'Available\'';

    if(productStockIdString != null){
      productStockQueryString += ' AND (' + productStockIdString;

      if(productIdString != null && locationIdString != null){
        productStockQueryString += ' OR (' + productIdString + ' AND ' + locationIdString + ')';
      }

      productStockQueryString += ')';
    }else if(productIdString != null && locationIdString != null){
       productStockQueryString += ' AND ' + productIdString + ' AND ' + locationIdString;
    }else{
      productStockQueryString = null;
    }

    if(productStockQueryString != null){
      try{
        System.debug('VanStockTransferUtility : Product Stock Query String - ' + productStockQueryString);
        productStockList =Database.query(productStockQueryString);
      }catch(Exception exceptionRecord){ 
       System.debug('VanStockUtility : Could not query Product Stock - ' + exceptionRecord.getMessage());
      }
    }else{
      System.debug('VanStockUtility : No data available to query Product Stock');
    }
    
    return productStockList;
  }

  /*****************************************************************************************************************************************
  *  Method Name : getStockSerials
  *  Parameter   : Set<Id> stockSerialSet - Set for Ids of Stock Serial which need to be queried
  *                Set<String> serialNumberSet - Set for Names of Stock Serial which need to be queried 
  *  Returns     : Map<Id, List<SVMXC__Product_Serial__c>> - returns a map of Product Stock Id as key and related stock serials as Value
  *  Description : Based on the given Stock Serial Id and/or Stock Serial Names, this method queries all Stock Serials.
  *******************************************************************************************************************************************/  
  @TestVisible private Map<Id, List<SVMXC__Product_Serial__c>> getStockSerials(Set<Id> stockSerialSet, Set<String> serialNumberSet){
      System.debug('VanStockTransferUtility : Start Query Stock Serial Process');

      //Map to store Product Stock Id as key and related stock serials as Value
      Map<Id, List<SVMXC__Product_Serial__c>> productStockIdStockSerialListMap = new Map<Id, List<SVMXC__Product_Serial__c>>();

      //Create Query String for all Stock Serial Id's available
      String stockSerialIdString = null;
      if(stockSerialSet != null && stockSerialSet.size() > 0){
        stockSerialIdString = createQueryStringUsingList('Id', stockSerialSet);
      }

      //Create Query String for all Stock Serial Names available
      String stockSerialNameString = null;
      if(serialNumberSet != null && serialNumberSet.size() > 0){
        stockSerialNameString = 'Name IN (';
        for(String stockSerialName : serialNumberSet){
          stockSerialNameString += '\'' + stockSerialName + '\',';
        }
        stockSerialNameString = stockSerialNameString.substring(0,stockSerialNameString.length()-1);
        stockSerialNameString += ')';
      }

      //Create Product Stock Query
      String stockSerialQueryString = 'SELECT Id,Name,SVMXC__Active__c,SVMXC__Product__c,SVMXC__Product_Stock__c ' +
                                        'FROM SVMXC__Product_Serial__c WHERE SVMXC__Active__c = TRUE ';

      if(stockSerialIdString != null){
        stockSerialQueryString += ' AND (' + stockSerialIdString;
        if(stockSerialNameString != null){
          stockSerialQueryString += ' OR ' + stockSerialNameString;
        }
        stockSerialQueryString += ')';
      }else if(stockSerialNameString != null){
        stockSerialQueryString += ' AND ' + stockSerialNameString;
      }else{
        stockSerialQueryString = null;
        System.debug('VanStockTransferUtility : No Stock Serials for query');
      }

      try{
        if(stockSerialQueryString != null){
          System.debug('VanStockTransferUtility : Stock Serial Query String - ' + stockSerialQueryString);
          //Perform query
          List<SVMXC__Product_Serial__c> stockSeriallList =Database.query(stockSerialQueryString);

          //Create Map of Product Stock Id as key and list of Stock Serials as Value
          if(stockSeriallList != null && stockSeriallList.size() > 0){
            for(SVMXC__Product_Serial__c stockSerial : stockSeriallList){
              List<SVMXC__Product_Serial__c> productSerialList = productStockIdStockSerialListMap.get(stockSerial.SVMXC__Product_Stock__c);
              if(productSerialList == null){
                productSerialList = new List<SVMXC__Product_Serial__c>();
                productStockIdStockSerialListMap.put(stockSerial.SVMXC__Product_Stock__c,productSerialList);
              }
              productSerialList.add(stockSerial);
            }
          }
        }else{
          System.debug('VanStockTransferUtility : Do not query Stock Serials');
        }
      }catch(Exception exceptionRecord){ 
       System.debug('VanStockTransferUtility : Could not query Stock Serials - ' + exceptionRecord.getMessage());
      }

      return productStockIdStockSerialListMap;
  }

  /*****************************************************************************************************************************************
  *  Method Name : createStockHistoryRecords
  *  Parameter   : Id sourceProductStockRecord - Id of the Product Stock from which stock transfer happened
  *                Id destinationProductStockRecord - Id of the Product Stock to which stock transfer happened
                   Id stockSerialRecord - Id of the Stock Serial for which stock transfer happened
                   Id productId - Id of Product which is a part of Stock Transfer
                   Id stockTransferRec - Id of the Stock Transfer Record
                   Id stockTransferLineRec - Id of the Stock Transfer Line Record
                   Decimal srcQtyBeforeChange - Qty before change at source product stock
                   Decimal srcQtyAfterChange - Qty after change at source product stock
                   Decimal destQtyBeforeChange - Qty before change at destination product stock
                   Decimal destQtyAfterChange - Qty after change at destination product stock
                   Decimal transactionQty - No of Quantities used in transaction
  *  Returns     : List<SVMXC__Stock_History__c> - list of stock history records created
  *  Description : This method creates the 2 Stock History Records - one for Source Product Stock and another for destination 
  *                Product Stock. It uses data passed as parameter. This method does not commit record. 
  *******************************************************************************************************************************************/  
  @TestVisible private List<SVMXC__Stock_History__c> createStockHistoryRecords(Id sourceProductStockRecord, Id destinationProductStockRecord, 
                                      Id stockSerialRecord, Id productId, Id stockTransferRec, Id stockTransferLineRec, Decimal srcQtyBeforeChange, 
                                      Decimal srcQtyAfterChange, Decimal destQtyBeforeChange, Decimal destQtyAfterChange, Decimal transactionQty){
    
    List<SVMXC__Stock_History__c> stockHistoryList = null;
    SVMXC__Stock_History__c sourceProductStockHistory = null;
    SVMXC__Stock_History__c destinationProductStockHistory = null;

    if(isMaintainStockHistoryAllowed){
      //Create Source Stock history record
      sourceProductStockHistory = new SVMXC__Stock_History__c();
      sourceProductStockHistory.SVMXC__Change_Type__c = 'Decrease';
      sourceProductStockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
      sourceProductStockHistory.SVMXC__Date_Changed__c = System.Now();
      sourceProductStockHistory.SVMXC__Product_Stock__c = sourceProductStockRecord;
      sourceProductStockHistory.SVMXC__Product__c = productId;
      sourceProductStockHistory.SVMXC__Quantity_before_change2__c = srcQtyBeforeChange;
      sourceProductStockHistory.SVMXC__Quantity_after_change2__c = srcQtyAfterChange;
      sourceProductStockHistory.SVMXC__Status__c = 'Consumed'; 
      sourceProductStockHistory.SVMXC__Transaction_Type__c = 'Stock Transfer';
      sourceProductStockHistory.SVMXC__Stock_Transfer__c = stockTransferRec;
      sourceProductStockHistory.SVMXC__Product_Serial__c = stockSerialRecord;
      sourceProductStockHistory.SVMXC__Stock_Transfer_Line__c = stockTransferLineRec;
      sourceProductStockHistory.SVMXC__Transaction_Quantity2__c = transactionQty;
      sourceProductStockHistory.RecordTypeId = stockHistoryRecordTypeId;

      //Create Destination Stock history record
      destinationProductStockHistory = new SVMXC__Stock_History__c();
      destinationProductStockHistory.SVMXC__Change_Type__c = 'Increase';
      destinationProductStockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
      destinationProductStockHistory.SVMXC__Date_Changed__c = System.Now();
      destinationProductStockHistory.SVMXC__Product_Stock__c = destinationProductStockRecord;
      destinationProductStockHistory.SVMXC__Product__c = productId;
      destinationProductStockHistory.SVMXC__Quantity_before_change2__c = destQtyBeforeChange;
      destinationProductStockHistory.SVMXC__Quantity_after_change2__c = destQtyAfterChange;
      destinationProductStockHistory.SVMXC__Status__c = 'Available'; 
      destinationProductStockHistory.SVMXC__Transaction_Type__c = 'Stock Transfer';
      destinationProductStockHistory.SVMXC__Stock_Transfer__c = stockTransferRec;
      destinationProductStockHistory.SVMXC__Product_Serial__c = stockSerialRecord;
      destinationProductStockHistory.SVMXC__Stock_Transfer_Line__c = stockTransferLineRec;
      destinationProductStockHistory.SVMXC__Transaction_Quantity2__c = transactionQty;
      destinationProductStockHistory.RecordTypeId = stockHistoryRecordTypeId;

      stockHistoryList = new List<SVMXC__Stock_History__c>();
      stockHistoryList.add(sourceProductStockHistory);
      stockHistoryList.add(destinationProductStockHistory);
    }else{
      System.debug('VanStockUtility : Do not maintain Stock History');
    }

    return stockHistoryList;
  }

  /*****************************************************************************************************************************************
  *  Method Name : createQueryStringUsingList
  *  Parameter   : String fieldApiName - 
  *                Set<Id> idSet - Set of all technicians Ids for whom Inventory Location need to be found
  *  Returns     : Map<Id,Id> -- Map of Technician Id as key and Inventory Location Id as Value
  *  Description : This is an internal utility method
  *                It takes field name and set of Ids to create a part of SOQL Where clause
  *                For Example:-
  *                If fieldApiName is 'SVMXC__Product_Stock__c' and idSet has values as123, as124, as125
  *                Output String will be : SVMXC__Product_Stock__c IN ('as123','as124','as125')
  *******************************************************************************************************************************************/  
  @TestVisible private String createQueryStringUsingList(String fieldApiName, Set<Id> idSet){
    String queryString = null;
    if(idSet != null && idSet.size() > 0 && fieldApiName != null){
      queryString = fieldApiName + ' IN (';
      for(Id recordId : idSet){
        queryString += '\'' + recordId + '\',';
      }
      queryString = queryString.substring(0,queryString.length()-1);
      queryString += ')';
    }else{
      System.debug('VanStockTransferUtility : Either the fieldApiName or idSet is null. Hence could not create String');
    }
    return queryString;
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkIfStockTransferFunctionalityIsActive
  *  Parameter   : --
  *  Returns     : boolean -- true if Part Consumption is active else false
  *  Description : Check the ServiceMax Service Register and make sure that Stock Transfer is Active or not.
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkIfStockTransferFunctionalityIsActive(){
    boolean isActive = false;
    List<SVMX_PS_Services_Register__c> serviceRegistryList = SVMX_PS_Services_Register__c.getAll().values();
    if(serviceRegistryList != null && serviceRegistryList.size()>0){
        for(SVMX_PS_Services_Register__c item : serviceRegistryList){
          if(item.Name.equals(STOCK_TRANSFER_REPORT_FUNCT)){
              isActive = item.SVMX_PS_Is_Active__c;
              break;
          }
        }
    }
    return isActive;
  }

  /*****************************************************************************************************************************************
  *  Method Name : retrieveStockTransferSetting
  *  Parameter   : --
  *  Returns     : --
  *  Description : Get All Stock Transfer Settings which control the van stock transfer functionality and store it in variables
  *******************************************************************************************************************************************/  
  @TestVisible private void retrieveStockTransferSetting(){
    List<SVMX_PS_VS_Stock_Transfer_Settings__c> stockTransferSettingsList = SVMX_PS_VS_Stock_Transfer_Settings__c.getAll().values();
    if(stockTransferSettingsList != null){
      for(SVMX_PS_VS_Stock_Transfer_Settings__c stockTransferSettings : stockTransferSettingsList){
        if(stockTransferSettings.Name.equals(PERFORM_STOCK_MANAGEMENT_USING_BATCH)){
          isPerformStockTransferUsingBatch = stockTransferSettings.SVMX_PS_VS_Value__c;
        }else if(stockTransferSettings.Name.equals(CONSIDER_SERIALIZED_TRACKING)){
          isSerialzedStockTransferAllowed = stockTransferSettings.SVMX_PS_VS_Value__c;
        }else if(stockTransferSettings.Name.equals(CONSIDER_NON_SERIALIZED_TRACKING)){
          isNonSerialzedStockTransferAllowed = stockTransferSettings.SVMX_PS_VS_Value__c;
        }else if(stockTransferSettings.Name.equals(MAINTAIN_STOCK_HISTORY)){
          isMaintainStockHistoryAllowed = stockTransferSettings.SVMX_PS_VS_Value__c;
        }
      }
    }
  }
}
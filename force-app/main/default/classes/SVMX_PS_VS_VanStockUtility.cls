/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockUtility 
* --------------------------------------------------------------------------------------------------------------------------------------
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Avina                    16-Jun-2022         CMSI-68,Added Instrumentation
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
global with sharing class SVMX_PS_VS_VanStockUtility implements Schedulable, Database.Batchable<SVMXC__Service_Order__c>, Database.AllowsCallouts, Database.Stateful {
  //These constants are used to retrieve the custom settings. These are the names of custom settings
  private static final String LOG_TITLE = 'SVMX_PS_VS_VanStockUtility'; //CMCP-69
  @TestVisible private static final String PART_CONSUMPTION_REPORT_FUNCT = 'Part Consumption';
  @TestVisible private static final String ELIGIBLE_WORK_ORDER_STATUS =  'Eligible Work Order Status';
  @TestVisible private static final String CONSIDER_LOT_BATCH_TRACKING = 'Consider Lot/Batch Tracking';
  @TestVisible private static final String CONSIDER_SERIALIZED_TRACKING = 'Consider Serialized Tracking';
  @TestVisible private static final String CONSIDER_NON_SERIALIZED_TRACKING = 'Consider Non-Serialized Tracking';
  @TestVisible private static final String IS_PRODUCT_STOCK_DECREMENT_ALLOWED = 'Is Product Stock Decrement Allowed';
  @TestVisible private static final String MAINTAIN_STOCK_HISTORY = 'Maintain Stock History';
  @TestVisible private static final String CREATE_IP_FROM_LOT_BATCH = 'Create IP From Lot/Batch Part';
  @TestVisible private static final String CREATE_IP_FROM_NON_SERIALIZED = 'Create IP From Non-Serialized Part';
  @TestVisible private static final String CREATE_IP_FROM_SERIALIZED = 'Create IP From Serialized Part';
  @TestVisible private static final String OUTSIDE_INVENTORY_ALLOWED = 'Outside Inventory Allowed';
  @TestVisible private static final String RESTOCKING_OF_PART_OUT = 'Is Re-Stocking of Out Part Allowed';
  @TestVisible private static final String PERFORM_STOCK_MANAGEMENT_USING_BATCH = 'Perform Stock Management using Batch';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_RECORD_TYPE = 'Eligible Work Detail Record Type';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_LINE_TYPE = 'Eligible Work Detail Line Type';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_LINE_STATUS = 'Eligible Work Detail Line Status';
  @TestVisible private static final String USE_ALLOCATED_QTY= 'Use Allocated Qty';
  @TestVisible private static final String DEFAULT_BATCH_SIZE = 'Batch Size';
  @TestVisible private static final String REMOVED_IP_STATUS = 'Removed IP Status';
  @TestVisible private static final String USAGE_CONSUMPTION = 'UsageConsumption';
  @TestVisible private static final String PART_LINE_TYPE = 'Parts';
  @TestVisible private static final String OPEN_LINE_STATUS = 'Open';
  @TestVisible private static final String AVAILABLE_STATUS = 'Available';
  @TestVisible private static final String COMPLETED_STATUS = 'Completed';
  @TestVisible private static final String CONSUMED_STATUS = 'Consumed';

  //These are the error messages for Part In 
  private static final String ERROR_MSG_FOR_NO_DATA = ' : Consumption Failure : Please provide either Product Stock/Consumed From Location & Part/Technician & Part for consumption to happen';
  private static final String ERROR_MSG_FOR_NO_INVT_LOC_FOR_TECH = ' : Consumption Failure : Technician has no Inventory Location associated with it.';
  private static final String ERROR_MSG_FOR_NO_PRODUCT_STOCK = ' : Consumption Failure : Unable to locate proper Product Stock Record.';
  private static final String ERROR_MSG_FOR_NO_QTY_PROVIDED= ' : Consumption Failure : Line Quantity has not been provided';
  private static final String ERROR_MSG_FOR_NO_STOCK_SERIAL = ' : Consumption Failure : Product Stock is Serialzed. Hence need Stock Serial for Consumption';
  private static final String ERROR_MSG_FOR_NO_STOCK_SERIAL_FOUND = ' : Consumption Failure : Product Stock is Serialzed. No Stock Serial Found Consumption';
  private static final String ERROR_MSG_FOR_QTY_LESS_THAN_ZERO = ' : Consumption Failure : Product Stock has available Qty less than Zero';
  private static final String ERROR_MSG_FOR_QTY_LESS = ' : Consumption Failure : Qty consumed on Work Detail is more than available Qty at Product Stock';
  private static final String SUCCESS_MSG_FOR_PART_CONSUMPTION = ' : Consumption Success : Part Consumption Successful';
  private static final String SUCCESS_MSG_FOR_OUTSIDE_INVENTORY = ' : Consumption Success : Outside Inventory Consumption is successful';
  //These are the error messages for Part Out 
  private static final String ERROR_MSG_NO_IP_FOUND = ' : Consumption Failure : Installed Product supplied is not valid for Part Out Process';
  private static final String ERROR_MSG_NEED_SERIAL_NO = ' : Consumption Failure : Need Serial Number for Part Out Process as Product is Serialized';
  private static final String ERROR_MSG_NO_DATA_PROVIDED_FOR_PART_OUT = ' : Consumption Failure : No data provided for Part Out Process';
  private static final String ERROR_MSG_NO_DATA_PROVIDED_FOR_RESTOCKING = ' : Consumption Failure : No data provided for Restocking in Part Out Process';
  private static final String ERROR_MSG_NEED_RETURN_QTY = ' : Consumption Failure : Return Qty is needed';
  private static final String ERROR_MSG_COULD_NOT_FIND_RESTOCKING_LOC = ' : Consumption Failure : Could not find Restocking Location in Part Out Process';
  private static final String ERROR_MSG_NO_DATA_FOUND_FOR_RESTOCKING = ' : Consumption Failure : Could not find Data for Restocking in Part Out Process';
  private static final String SUCCESS_PART_OUT_PROCESS_NO_RESTOCKING = ' : Consumption Success : Part Out Successful. No Restocking done';
  private static final String SUCCESS_PART_OUT_PROCESS = ' : Consumption Success : Part Out Successful. Restocking done';
 
  //Boolean to check if the stock management using batch or not
  public boolean isPerformStockUsingBatch;
  //Boolean to store if Part Consumption Service is active or not
  public boolean isPartConsumptionActive;
  //Variable to store the record type "Stock History"
  private static Id stockHistoryRecordTypeId;
  //Variable to store the record type "Serial History"
  private static Id serialHistoryRecordTypeId;
  //Boolean to stop recursive loop
  private boolean isPartConsumptionAlreadyPerformed = false;
  //Boolean to store if outside Inventory Allowed
  private boolean isOutsideInventoryAllowed;
  //Boolean to store if Lot/Batch Tracking Allowed
  private boolean isLotBatchTrackedAllowed;
  //Boolean to store if Serialized Tracking Allowed
  private boolean isSerializedTrackingAllowed;
  //Boolean to store if Non-Serialized Tracking Allowed
  private boolean isNonSerializedTrackingAllowed;
  //Boolean to store if Product Stock Decrement Allowed
  private boolean isProductStockDecrementAllowed;
  //Boolean to store if need to Maintain Stock History
  private boolean isMaintainStockHistoryAllowed;
  //Boolean to store if need to create ip from serialized product stock
  private boolean isCreateIPFromSerialized;
  //Boolean to store if need to create ip from non-serialized product stock
  private boolean isCreateIPFromNonSerialized;
  //Boolean to store if need to create ip from lot/batch product stock
  private boolean isCreateIPFromLotBatch;
  //Boolean to store if restocking of out part allowed
  private boolean isRestockingOfPartOut;
  //Boolean to store if allocated Qty is being used or not.
  private boolean isAllocatedQtyDecrementAllowed;
  //List to store the eligible Work Order Status which if set, kicks the part consumption code
  private List<String> eligibleWorkOrderStatusList; 
  //List to store the eligible Work Detail Record Type which need to used for the part consumption code
  private List<String> eligibleRecordTypeList;
  //List to store the eligible Work Detail Line Type which need to used for the part consumption code
  private List<String> eligibleLineTypeList;
  //List to store the eligible Work Detail Line Status which need to used for the part consumption code
  private List<String> eligibleLineStatusList;
  //String to store the value to be set to IP's Status when IP is removed
  private String removedIPStatus;
  //Map of Technician Id as key and Inventory Location Id as Value
  private Map<Id,Id> technicianIdInvntLocIdMap = null;
  

  /*****************************************************************************************************************************************
  *  Constructor Name  : SVMX_PS_VS_VanStockUtility
  *  Parameter         : --
  *  Returns           : --
  *  Description       : First Check the ServiceMax Service Register and make sure that Part Consumption is Active or not.
  *                      If Active, then retrieve the custom settings associated with Part Consumption
  *******************************************************************************************************************************************/  
  public SVMX_PS_VS_VanStockUtility() {
    //Check if the functionality is active or not
    if(!checkIfPartConsumptionFunctionalityIsActive()){
      ilib_LogEvent.info('VanStockUtility: Part Consumption is not active. Hence Ignore');//CMSI-69
      ilib_LogEvent.info('VanStockUtility: Please go to Service Register Custom Settings and Activate the Part Consumption Functionality');//CMSI-69
      isPartConsumptionActive = false;
    }else{
      ilib_LogEvent.info('VanStockUtility: Part Consumption is active. Hence continue');//CMSI-69
      isPartConsumptionActive = true;

      /*Schema.DescribeSObjectResult stockHistoryObj = Schema.SObjectType.SVMXC__Stock_History__c;
      Map<String,Schema.RecordTypeInfo> stockHistoryRecordTypeMap = stockHistoryObj.getRecordTypeInfosByName();
      stockHistoryRecordTypeId = stockHistoryRecordTypeMap.get('Stock History').getRecordTypeId();
      serialHistoryRecordTypeId = stockHistoryRecordTypeMap.get('Serial History').getRecordTypeId();
       */
       
	   //DCP-50636 [removing SOQL for RecordType] 
      /*stockHistoryRecordTypeId = getRecordtypeIdbyDevName('SVMXC__Stock_History__c','Stock_History');
      serialHistoryRecordTypeId = getRecordtypeIdbyDevName('SVMXC__Stock_History__c','Serial_History');*/
	  stockHistoryRecordTypeId = Schema.SObjectType.SVMXC__Stock_History__c.getRecordTypeInfosByDeveloperName().get('Stock_History').getRecordTypeId();
	  serialHistoryRecordTypeId = Schema.SObjectType.SVMXC__Stock_History__c.getRecordTypeInfosByDeveloperName().get('Serial_History').getRecordTypeId();

      //Read all Custom Settings and store it for use
      ilib_LogEvent.info('VanStockUtility: Read All Custom Settings');//CMSI-69
      retrievePartConsumptionSetting();
      ilib_LogEvent.info('VanStockUtility: All Custom Settings set');//CMSI-69
    } 
  }

  //DCP-50636 [removing SOQL for RecordType] 
 /*Public String getRecordtypeIdbyDevName(String Objname,String DevName){
      Recordtype RtypeId =new Recordtype();
	  Objname = String.escapeSingleQuotes(Objname) ;
      DevName = String.escapeSingleQuotes(DevName) ;
      String query = 'SELECT id,name,sobjecttype,developername FROM recordtype WHERE sobjecttype ='+'\''+String.escapeSingleQuotes(Objname)+'\''+' AND developername ='+'\''+String.escapeSingleQuotes(DevName)+'\''+' limit 1';

      System.debug('VanStockUtility: Recordtype Query :' + query);

      RtypeId = Database.query(query);
      return RtypeId.id;
  }*/

  /*****************************************************************************************************************************************
  *  Method Name : start
  *  Parameter   : Database.BatchableContext bc
  *  Returns     : Iterable<SVMXC__Service_Order__c> -- List of Work Orders for which Van Stock Code needs to be performed
  *  Description : This represents the start of batch when batching is used. This does query work orders with status mentioned 
  *                in custom settings and where no of consumption lines are more than 1. It then sends such work orders for processing
  *******************************************************************************************************************************************/
  global Iterable<SVMXC__Service_Order__c> start(Database.BatchableContext bc){

    ilib_LogEvent.push(LOG_TITLE + '.start()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility: Batch started');//CMSI-69
    List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
    
    //Check if part consumption service is active or not
    if(isPartConsumptionActive){
      String orderStatusString = ' ';
      for(String eligibleOrderStatus : eligibleWorkOrderStatusList){
        orderStatusString += '\'' + eligibleOrderStatus + '\',';
      }
      orderStatusString = orderStatusString.substring(0, orderStatusString.length()-1);

      String query = 'SELECT ID, Name, SVMXC__Order_Status__c,SVMX_PS_VS_Consumption_Lines__c, Partner_Work_Order__c,Integration_Status__c,Parts_Consumed_By_SAP__c FROM SVMXC__Service_Order__c ' +
                      'WHERE SVMXC__Order_Status__c IN (' + orderStatusString + ') AND SVMX_PS_VS_Consumption_Lines__c > 0';
     
      if(Test.isRunningTest()){
		Integer intBatchSize = 0;
		String batchSize = null;
		List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettings = SVMX_PS_VS_Part_Consumption_Settings__c.getAll().values();
		ilib_LogEvent.info('partConsumptionSettings-->: '+UtilsCollection.getSetOfIds(partConsumptionSettings));//CMSI-69
    if(partConsumptionSettings != null){
			for(SVMX_PS_VS_Part_Consumption_Settings__c partConsumption : partConsumptionSettings){
				if(partConsumption.Name.equals(DEFAULT_BATCH_SIZE)){
				  batchSize = partConsumption.SVMX_PS_VS_Text_Value__c;
				  break;
				}
			}
		}
		if(batchSize != null && !batchSize.trim().equals('')){
		  intBatchSize = Integer.valueOf(batchSize);
		}
		if(intBatchSize <= 0){
		  intBatchSize = 50;
		}	
        Id userId = userInfo.getuserId();
        query += 'And CreatedBYId =: userId ORDER BY CreatedDate DESC Limit '+ intBatchSize;
      }
      ilib_LogEvent.info(LOG_TITLE+': Batch Query :' + query);

      workOrderList = Database.query(query);
    }else{
      ilib_LogEvent.info(LOG_TITLE+': Part Consumption Service is not Active. Hence do not proceed further');
    }
      
    ilib_LogEvent.info(LOG_TITLE+': Batch start finished');
    ilib_LogEvent.pop();//CMSI-69
    return workOrderList;
  }
    
  /*****************************************************************************************************************************************
  *  Method Name : execute
  *  Parameter   : Database.BatchableContext bc
  *                List<SVMXC__Service_Order__c> workOrderList  -- List of Work Orders which need to be processed
  *  Returns     : ---
  *  Description : This method actually executes all van stock code
  *******************************************************************************************************************************************/  
  global void execute(Database.BatchableContext bc, List<SVMXC__Service_Order__c> workOrderList){
    ilib_LogEvent.setTitle(LOG_TITLE);//CMSI-69
    ilib_LogEvent.push(LOG_TITLE + '.execute()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility: Batch execution started');
     if(workOrderList != null && workOrderList.size() > 0){
      ilib_LogEvent.info('VanStockUtility: Processing Stock Consumption');
      performVanStockManagement(workOrderList);
      ilib_LogEvent.info('VanStockUtility: Processing Stock Consumption finished');
     }else{
      ilib_LogEvent.info('VanStockUtility: No Work Orders to process');
     }  
     ilib_LogEvent.info('VanStockUtility: Batch execution finished');   
     ilib_LogEvent.pop();//CMSI-69 
     ilib_LogEvent.emit();//CMSI-69
  }

  /*****************************************************************************************************************************************
  *  Method Name : finish
  *  Parameter   : Database.BatchableContext bc
  *  Returns     : ---
  *  Description : This method actually executes is called when all batch processed are completed
  *******************************************************************************************************************************************/  
  global void finish(Database.BatchableContext bc){
    ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);//CMSI-69
    ilib_LogEvent.push(LOG_TITLE + '.finish()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility: Batch execution finished');//CMSI-69
    ilib_LogEvent.pop();//CMSI-69
  }
  
  /*****************************************************************************************************************************************
  *  Method Name : execute
  *  Parameter   : SchedulableContext sc
  *  Returns     : ---
  *  Description : This method actually called when a scheduled job is executed
  *                This method calls invokes the batch process for doing van stock code
  *******************************************************************************************************************************************/  
  global void execute(SchedulableContext sc) {
    ilib_LogEvent.push(LOG_TITLE + '.execute()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility: Schedule Batch execution started');
    
    String batchSize = null;

    List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettings = SVMX_PS_VS_Part_Consumption_Settings__c.getAll().values();
    ilib_LogEvent.info('partConsumptionSettings-->: '+UtilsCollection.getSetOfIds(partConsumptionSettings));//CMSI-69
    if(partConsumptionSettings != null){
      for(SVMX_PS_VS_Part_Consumption_Settings__c partConsumption : partConsumptionSettings){
        if(partConsumption.Name.equals(DEFAULT_BATCH_SIZE)){
          batchSize = partConsumption.SVMX_PS_VS_Text_Value__c;
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

    SVMX_PS_VS_VanStockUtility vanStockUtility = new SVMX_PS_VS_VanStockUtility();
    Database.executebatch(vanStockUtility, intBatchSize);
    ilib_LogEvent.info('VanStockUtility : Schedule Batch execution done');//CMSI-69 
    ilib_LogEvent.pop();//CMSI-69 
  }

  /*****************************************************************************************************************************************
  *  Method Name : startBackLogScheduler
  *  Parameter   : ---
  *  Returns     : ---
  *  Description : This method schedules Van Stock Management code every 1 hour.
  *                You can use the following code to schedule jobs using developer console
  *                -----------------------------------------
  *                  SVMX_PS_VS_VanStockUtility.startBackLogScheduler();
  *                -----------------------------------------
  *******************************************************************************************************************************************/  
  global static void startBackLogScheduler() {
    ilib_LogEvent.push(LOG_TITLE + '.startBackLogScheduler()');//CMSI-69
    SVMX_PS_VS_VanStockUtility vanStockUtility = new SVMX_PS_VS_VanStockUtility();
    String schedule00 = '0 0 * * * ?';
    if (!Test.isRunningTest()){
      system.schedule('Van Stock Handler Job 00', schedule00, vanStockUtility);
    }
    ilib_LogEvent.pop();//CMSI-69   
  }

  /*****************************************************************************************************************************************
  *  Method Name : performVanStockManagement
  *  Parameter   : List<SVMXC__Service_Order__c> newWorkOrderList - list of newly updated work Orders (example : trigger.new)
  *                Map<Id,SVMXC__Service_Order__c> oldWorkOrderMap - Map of Id and old work Orders (example : trigger.oldMap)
  *  Returns     : --
  *  Description : This method is called from trigger and performs Van Stock Management Process
  *                It does following things:-
  *                  a. Performs Part Consumption/Part In Process
  *                  b. Performs Creation of Installed base if required
  *                  c. Performs Part Out Process
  *                This method will be used when Consumption is happening thru Batch Process
  *******************************************************************************************************************************************/  
  public void performVanStockManagement(List<SVMXC__Service_Order__c> newWorkOrderList){
    ilib_LogEvent.push(LOG_TITLE + '.performVanStockManagement()');//CMSI-69
    ilib_LogEvent.info('newWorkOrderList-->: '+UtilsCollection.getSetOfIds(newWorkOrderList));//CMSI-69
    if(!isPartConsumptionAlreadyPerformed){
      isPartConsumptionAlreadyPerformed = true;
      ilib_LogEvent.info('VanStockUtility : Start Van Stock Processing');

      //Check if part consumption service is active or not
      if(isPartConsumptionActive){
        //List to store valid work orders
        List<SVMXC__Service_Order__c> validWorkOrderList = new List<SVMXC__Service_Order__c>();

        if(newWorkOrderList != null && newWorkOrderList.size() > 0){
          for(SVMXC__Service_Order__c workOrder : newWorkOrderList){
            //Check if the work order is eligible for part consumption. 
            //For detail see method #checkEligibleWorkOrderStatus
            //In addition, work order field "Consumption Lines #" should be more than 0
            //And also Integration Status is 'Success'
            //Added Parts_Consumed_By_SAP__c for DCP-37399
            //Added Partner_Work_Order__c for INC0424978
            if((checkEligibleWorkOrderStatus(workOrder.SVMXC__Order_Status__c) && workOrder.Integration_Status__c == 'Success' && workOrder.SVMX_PS_VS_Consumption_Lines__c > 0) || workOrder.Parts_Consumed_By_SAP__c || workOrder.Partner_Work_Order__c){
              validWorkOrderList.add(workOrder);
            }
          }

          if(validWorkOrderList.size() > 0){
            
            //Get Work Details associated with the Valid Work Orders 
            List<SVMXC__Service_Order_Line__c> workOrderLineList = queryWorkDetails(validWorkOrderList);
            ilib_LogEvent.info('workOrderLineList-->: '+UtilsCollection.getSetOfIds(workOrderLineList));//CMSI-69
            //Perform Part Consumption
            if(workOrderLineList != null && workOrderLineList.size() > 0){
              //Perform Part-In Process
              ilib_LogEvent.info('VanStockUtility : Start Part Consumption - Part In Process');
              Set<StockConsumptionWrapper> stockConsumptionWrapperSet = handleStockConsumption(workOrderLineList);
              ilib_LogEvent.info('stockConsumptionWrapperSet-->: '+stockConsumptionWrapperSet);//CMSI-69
              ilib_LogEvent.info('VanStockUtility : End Part In Process');
              
              //Perform Part-Out Process
              ilib_LogEvent.info('VanStockUtility : Start Part Out Process');
              List<StockConsumptionWrapper> stockOutConsumptionWrapperList = handleStockOutProcess(workOrderLineList);
              ilib_LogEvent.info('VanStockUtility : End Part Out Process');

              //Creation of IP
              if(stockConsumptionWrapperSet.size() > 0){
                ilib_LogEvent.info('VanStockUtility : Create IP');

                List<StockConsumptionWrapper> stockConsumptionWrapperList = new List<StockConsumptionWrapper>();
              
                for(StockConsumptionWrapper wrapper : stockConsumptionWrapperSet){
                  if(wrapper.getWorkDetail().SVMX_PS_VS_Is_Part_Out__c){
                    for(StockConsumptionWrapper stockOutWrapper : stockOutConsumptionWrapperList){
                      if(stockOutWrapper.compareStockConsumptionWrapper(wrapper.getWorkDetail())){
                        wrapper.setInstalledProduct(stockOutWrapper.getInstalledProduct());
                      }
                    }
                  }
                }

                stockConsumptionWrapperList.addAll(stockConsumptionWrapperSet);
                SVMX_PS_VS_VanStockIPHandler rapidInstalledBaseHandler = new SVMX_PS_VS_VanStockIPHandler();
                rapidInstalledBaseHandler.createInstalledProduct(stockConsumptionWrapperList);
                ilib_LogEvent.info('VanStockUtility : Create IP Done'); 
              }
            }else{
              ilib_LogEvent.info('VanStockUtility : No Work Details Valid for Processing');
            }
          }else{
            ilib_LogEvent.info('VanStockUtility : No Work Orders Valid for Processing');
          }
        }else{
          ilib_LogEvent.info('VanStockUtility : No Work Orders Found for Processing');
        }
      }else{
        ilib_LogEvent.info('VanStockUtility: Part Consumption is not active. Hence Ignore');
      }
      ilib_LogEvent.info('VanStockUtility : End Van Stock Processing');
    }else{
      ilib_LogEvent.info('VanStockUtility : This is recursive loop. Already performed once Part Consumption');
    }
    ilib_LogEvent.pop();//CMSI-69  
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkEligibleWorkOrderStatus
  *  Parameter   : String orderStatus -- Order Status of Work Order
  *  Returns     : boolean -- true if order status is eligible for Part Consumption else false
  *  Description :  This method checks if the Order Status of Work Order is eligible for Part Consumption
  *                 Order Status of Work Order are mentioned in "Eligible Work Order Status" record in "Part Consumption Settings Detail".
  *                 This is used when Consumption is happening thru Batch Process
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkEligibleWorkOrderStatus(String orderStatus){
    ilib_LogEvent.message('orderStatus-->: '+orderStatus);//CMSI-69
    boolean isEligible = false;

    //Check if attachment name is null
    if(orderStatus != null && !orderStatus.trim().equals('')){
      //Checks if the Order Status of Work Order is eligible for Part Consumption
      if(eligibleWorkOrderStatusList != null && eligibleWorkOrderStatusList.size() > 0){
        for(String eligibleOrderStatus : eligibleWorkOrderStatusList){
          //Check current work order status
          if(orderStatus.equalsIgnoreCase(eligibleOrderStatus)){
            ilib_LogEvent.fine('VanStockUtility: New Status - ' + orderStatus);
            isEligible = true;
            break;
          }
        }
      }else{
        ilib_LogEvent.message('VanStockUtility:  No Order Status is registered. Hence ignore Work Order');
      }
    }else{
      ilib_LogEvent.message('VanStockUtility: Order Status is null. Hence ignore Work Order');
    }
    return isEligible;
  }

  /*****************************************************************************************************************************************
  *  Method Name : performVanStockManagement
  *  Parameter   : List<SVMXC__Service_Order__c> newWorkOrderList - list of newly updated work Orders (example : trigger.new)
  *                Map<Id,SVMXC__Service_Order__c> oldWorkOrderMap - Map of Id and old work Orders (example : trigger.oldMap)
  *  Returns     : --
  *  Description : This method is called from trigger and performs Van Stock Management Process
  *                It does following things:-
  *                  a. Performs Part Consumption/Part In Process
  *                  b. Performs Creation of Installed base if required
  *                  c. Performs Part Out Process
  *******************************************************************************************************************************************/  
  public void performVanStockManagement(List<SVMXC__Service_Order__c> newWorkOrderList, Map<Id,SVMXC__Service_Order__c> oldWorkOrderMap){
    ilib_LogEvent.push(LOG_TITLE + '.performVanStockManagement()');//CMSI-69

    if(!isPartConsumptionAlreadyPerformed){
      isPartConsumptionAlreadyPerformed = true;
      ilib_LogEvent.info('VanStockUtility : Start Van Stock Processing');

      //Check if part consumption service is active or not
      if(isPartConsumptionActive){
        //List to store valid work orders
        List<SVMXC__Service_Order__c> validWorkOrderList = new List<SVMXC__Service_Order__c>();

        if(newWorkOrderList != null && newWorkOrderList.size() > 0){
          for(SVMXC__Service_Order__c workOrder : newWorkOrderList){
            SVMXC__Service_Order__c oldWorkOrder = oldWorkOrderMap.get(workOrder.Id);
            //Check if the work order is eligible for part consumption. For detail see method #checkEligibleWorkOrderStatus
            //In addition, work order field "Consumption Lines #" should be more than 0
			      //And also Integration Status is 'Success'
            //DCP-37399 - Added Parts_Consumed_By_SAP__c field.
            if(oldWorkOrder != null &&
              (checkEligibleWorkOrderStatus(workOrder.SVMXC__Order_Status__c, oldWorkOrder.SVMXC__Order_Status__c) && workOrder.Integration_Status__c == 'Success' && workOrder.SVMX_PS_VS_Consumption_Lines__c > 0) || workOrder.Parts_Consumed_By_SAP__c){
                 validWorkOrderList.add(workOrder);
            }
          }
          if(validWorkOrderList.size() > 0){
            //Get Work Details associated with the Valid Work Orders 
            List<SVMXC__Service_Order_Line__c> workOrderLineList = queryWorkDetails(validWorkOrderList);
            //Perform Part Consumption
            if(workOrderLineList != null && workOrderLineList.size() > 0){
              //Perform Part-In Process
              ilib_LogEvent.info('VanStockUtility : Start Part Consumption - Part In Process');
              Set<StockConsumptionWrapper> stockConsumptionWrapperSet = handleStockConsumption(workOrderLineList);
              ilib_LogEvent.info('workOrderLineList-->: '+stockConsumptionWrapperSet);//CMSI-69
              ilib_LogEvent.info('VanStockUtility : End Part In Process');
              
              //Perform Part-Out Process
              ilib_LogEvent.info('VanStockUtility : Start Part Out Process');
              List<StockConsumptionWrapper> stockOutConsumptionWrapperList = handleStockOutProcess(workOrderLineList);
              ilib_LogEvent.info('workOrderLineList-->: '+stockConsumptionWrapperSet);//CMSI-69
              ilib_LogEvent.info('VanStockUtility : End Part Out Process');

              //Creation of IP
              if(stockConsumptionWrapperSet.size() > 0){
                ilib_LogEvent.info('VanStockUtility : Create IP');

                List<StockConsumptionWrapper> stockConsumptionWrapperList = new List<StockConsumptionWrapper>();
              
                for(StockConsumptionWrapper wrapper : stockConsumptionWrapperSet){
                  if(wrapper.getWorkDetail().SVMX_PS_VS_Is_Part_Out__c){
                    for(StockConsumptionWrapper stockOutWrapper : stockOutConsumptionWrapperList){
                      if(stockOutWrapper.compareStockConsumptionWrapper(wrapper.getWorkDetail())){
                        if(stockOutWrapper.getInstalledProduct() != null){	
                                  wrapper.setInstalledProduct(stockOutWrapper.getInstalledProduct());
						  }else{
							  wrapper.setInstalledProduct(new SVMXC__Installed_Product__c(Id=wrapper.getWorkDetail().SVMXC__Service_Order__r.SVMXC__Component__c));
						  }
                      }
                    }
                  }
                }

                stockConsumptionWrapperList.addAll(stockConsumptionWrapperSet);
                SVMX_PS_VS_VanStockIPHandler rapidInstalledBaseHandler = new SVMX_PS_VS_VanStockIPHandler();
                rapidInstalledBaseHandler.createInstalledProduct(stockConsumptionWrapperList);
                ilib_LogEvent.info('VanStockUtility : Create IP Done');
              }
            }else{
              ilib_LogEvent.info('VanStockUtility : No Work Details Valid for Processing');
            }
          }else{
            ilib_LogEvent.info('VanStockUtility : No Work Orders Valid for Processing');
          }
        }else{
          ilib_LogEvent.info('VanStockUtility : No Work Orders Found for Processing');
        }
      }else{
        ilib_LogEvent.info('VanStockUtility: Part Consumption is not active. Hence Ignore');
      }
      ilib_LogEvent.info('VanStockUtility : End Van Stock Processing');
    }else{
      ilib_LogEvent.info('VanStockUtility : This is recursive loop. Already performed once Part Consumption');
    }
    ilib_LogEvent.pop();//CMSI-69 
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkEligibleWorkOrderStatus
  *  Parameter   : String orderStatus -- Order Status of Work Order
  *                String oldOrderStatus -- Previous Order Status of Work Order
  *  Returns     : boolean -- true if order status is eligible for Part Consumption else false
  *  Description :  This method checks if the Order Status of Work Order is eligible for Part Consumption
  *                 Order Status of Work Order are mentioned in "Eligible Work Order Status" record in "Part Consumption Settings Detail".
  *                 Also checks if the Previous Order Status is not the same as the New
  *                 This method is called from trigger
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkEligibleWorkOrderStatus(String orderStatus, String oldOrderStatus){
  
    boolean isEligible = false;

    //Check if attachment name is null
    if(orderStatus != null && !orderStatus.trim().equals('')){
      //Checks if the Order Status of Work Order is eligible for Part Consumption
      if(eligibleWorkOrderStatusList != null && eligibleWorkOrderStatusList.size() > 0){
        for(String eligibleOrderStatus : eligibleWorkOrderStatusList){
          //Check current work order status
          if(orderStatus.equalsIgnoreCase(eligibleOrderStatus)){
            ilib_LogEvent.fine('VanStockUtility: New Status - ' + orderStatus + ',Old Status - ' + oldOrderStatus);
            //Check previoud work order status
            if(oldOrderStatus != null && !orderStatus.equalsIgnoreCase(oldOrderStatus)){
              isEligible = true;
              break;
            }else if(orderStatus == 'Completed'){
            isEligible = true;
            break;  
            }else{
              ilib_LogEvent.fine('VanStockUtility:  Old Order Status same as New. Hence ignore Work Order');
            }
          }
        }
      }else{
        ilib_LogEvent.message('VanStockUtility:  No Order Status is registered. Hence ignore Work Order');
      }
    }else{
      ilib_LogEvent.message('VanStockUtility: Order Status is null. Hence ignore Work Order');
    } 
    return isEligible;
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryWorkDetails
  *  Parameter   : List<SVMXC__Service_Order__c> workOrderList - List of Work Orders to find work details to be used for consumption
  *  Returns     : List<SVMXC__Service_Order_Line__c> - List of Work Details line which will be used for Part Consumption
  *  Description : This method queries the Work Detail Record using Closed/Eligible Work Orders
  *******************************************************************************************************************************************/  
  @TestVisible private List<SVMXC__Service_Order_Line__c> queryWorkDetails(List<SVMXC__Service_Order__c> workOrderList){
    ilib_LogEvent.push(LOG_TITLE + '.updateRQContactCompliant()');//CMSI-69
    List<SVMXC__Service_Order_Line__c>  workDetailList = null;
    if(workOrderList != null){
      workDetailList = [SELECT Id, Name, SVMXC__Actual_Quantity2__c, SVMXC__Service_Order__c, RecordType.Name, SVMXC__Line_Type__c,
                               SVMX_PS_VS_Consumed_Product_Stock__c, SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Location__c, 
                               SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c, SVMXC__Consumed_From_Location__c, SVMXC__Group_Member__c, 
							   SVMXC__Service_Order__r.SVMXC__Component__c,SVMXC__Consumed_From_Location__r.Type__c,
                               SVMXC__Service_Order__r.SVMXC__Group_Member__c, SVMXC__Product__c, SVMXC__Product__r.Name, 
                               SVMX_PS_VS_Consumed_Stocked_Serial__c, SVMX_PS_VS_Consumed_Part_Code__c, SVMX_PS_VS_Consumed_Status__c,
                               SVMX_PS_VS_Is_Part_Out__c, SVMX_PS_VS_Return_Installed_Product__c, SVMX_PS_VS_Return_Part__c, 
                               SVMX_PS_VS_Return_Serial_Number__c, SVMX_PS_VS_Returned_Qty__c, SVMXC__Requested_Location__c, 
                               SVMX_PS_VS_Return_Part__r.SVMXC__Stockable__c, SVMX_PS_VS_Return_Part__r.SVMXC__Tracking__c, 
                               SVMX_PS_VS_Return_Part__r.SVMXC__Enable_Serialized_Tracking__c, SVMXC__Posted_To_Inventory__c, 
                               SVMXC__Line_Status__c,/*DCP-37399*/ Consumption_Confirmed__c,SVMX_PS_External_ID__c, SVMX_PS_VS_Part_Out_Status__c, SVMX_PS_VS_Is_Create_Install_Product__c, 
                               Batch_Lookup__c, Batch_Number__c 
                  FROM SVMXC__Service_Order_Line__c 
                  WHERE SVMXC__Service_Order__c IN :workOrderList
                        AND RecordType.DeveloperName IN :eligibleRecordTypeList  
                        AND SVMXC__Line_Type__c IN :eligibleLineTypeList 
                        AND Consumption_Confirmed__c = true
                        AND ((SVMXC__Consumed_From_Location__r.Type__c = 'Partner Stock' AND SVMX_PS_External_ID__c = null) OR (SVMXC__Consumed_From_Location__r.Type__c != 'Partner Stock' AND SVMX_PS_External_ID__c != null))
                        AND SVMXC__Line_Status__c IN :eligibleLineStatusList];
          
    }else{
      ilib_LogEvent.info('VanStockUtility: No Work Order found for querying Work Details');
    }
    ilib_LogEvent.info('workDetailList-->: '+UtilsCollection.getSetOfIds(workDetailList));//CMSI-69
    ilib_LogEvent.pop();//CMSI-69  
    return workDetailList;
  }

   /*****************************************************************************************************************************************
  *  Method Name : handleStockConsumption
  *  Parameter   : List<SVMXC__Service_Order_Line__c> workDetailList - List of Work Details to be used for Part Consumption
  *  Returns     : Set<StockConsumptionWrapper> - Set of Wrapper Object containing details of consumption
  *  Description : This method actually performs Stock Consumption.
  *                First of all Product Stock needs to be found form which consumption needs to happen
  *                For Finding the product stock for part consumption, following is the sequence
  *                  a. See if the field "Consumed Part" is populated
  *                  b. If not, check if the "Consumed From Location" and "Part" is populated
  *                  c. If not, check if the "Technician" and "Part" is populated
  *                  d. If not, error is provided
  *                For #a, we get product stock directly
  *                For #b, using "Consumed From Location" and "Part", we can get product stock
  *                For #c, we find "Inventory Location's" of Tech, Using "Inventory Location's" of Tech and Part, we can get product stock
  *                Here, we are using Technician field of Work Detail.
  *                It does following activites
  *                  a. If the Product Stock is Serialzed, calls method "handleSerializedProductStockConsumption"
  *                  b. If the Product Stock is Non-Serialzed, calls method "handleNonSerializedProductStockConsumption"
  *                  c. If errors, gives error message
  *                  d. Commits all changes to Database
  *                 Following Messages are given for error conditions:-
  *                ------------------------------------------------------------------------------------------------------------------------
  *                       ERROR CONDITION                              |      MESSAGE
  *                ------------------------------------------------------------------------------------------------------------------------
  *                a. When the case is #c and Given Technician has no  | Technician has no Inventory Location associated with it
  *                   Inventory Location                               |
  *                ------------------------------------------------------------------------------------------------------------------------
  *                b. When Product Stock could not be determined using | Please provide either Product Stock/Consumed From 
  *                   any combinations mentioned in #a, #b and #c      | Location/Technician for consumption to happen                                                      
  *                ------------------------------------------------------------------------------------------------------------------------  
  *                c. When in case of #b and #c, unable to find proper | Unable to locate proper Product Stock Record       
  *                   Product Stock record                             |
  *                ------------------------------------------------------------------------------------------------------------------------  
  *                d. When Product Stock is Non-Serialzed and Line Qty | Line Quantity has not been provided
  *                   is not provided                                  |
  *                ------------------------------------------------------------------------------------------------------------------------ 
  *******************************************************************************************************************************************/  
  @TestVisible Set<StockConsumptionWrapper> handleStockConsumption(List<SVMXC__Service_Order_Line__c> workDetailList){
    //Map to store the work detail id and unique string for storing if part consumption was performed 
    //and successful. This will be used in part out process to handle the Post To Inventory field
    ilib_LogEvent.push(LOG_TITLE + '.handleStockConsumption()');//CMSI-69
    ilib_LogEvent.info('workDetailList-->: '+UtilsCollection.getSetOfIds(workDetailList));//CMSI-69
    Map<Id, String> workDetailIdStatusStringMap = new Map<Id, String>();
    //Map to store product stock and related stock serials
    Map<Id,List<SVMXC__Product_Serial__c>> productStockIdAllStockSerialMap = new Map<Id,List<SVMXC__Product_Serial__c>> ();
    //Set of Work Details to be updated
    Set<SVMXC__Service_Order_Line__c> updatedWorkDetailLinesSet = new Set<SVMXC__Service_Order_Line__c> ();
    //Map of Product Stock to be updated
    Map<Id,SVMXC__Product_Stock__c> updatedProductStockLinesMap = new Map<Id,SVMXC__Product_Stock__c> ();
    //Set of Stock Serial to be updated
    //Set<SVMXC__Product_Serial__c> updatedStockSerialLinesSet = new Set<SVMXC__Product_Serial__c> ();
    Map<Id,SVMXC__Product_Serial__c> mapStockSerialToBeUpdated = new Map<Id,SVMXC__Product_Serial__c>();
    //Set of Stock Serial to be updated
    Map<String,SVMXC__Product_Serial__c> mapTobeCreatedStockSerialLines = new Map<String,SVMXC__Product_Serial__c> ();
    //Set of Stock History to be created
    Set<SVMXC__Stock_History__c> createdStockHistoryLinesSet = new Set<SVMXC__Stock_History__c> ();
    //Set of StockConsumptionWrapper which will be used to create Installed Product
    Set<StockConsumptionWrapper> stockConsumptionWrapperSet = new Set<StockConsumptionWrapper> ();
    //List of work details to be processed for allocation qty updation
    List<SVMXC__Service_Order_Line__c> allocatedQtyHandlerWorkDetailList = new List<SVMXC__Service_Order_Line__c>();
    //Map for product stock string (string of product-location) and list of stock serials
    //This will be used to update the product stock id once product stock record is created
    //This happens only when consumed product stock is created.
    Map<String,List<SVMXC__Product_Serial__c>> productStockStringStockSerialMap = new Map<String,List<SVMXC__Product_Serial__c>>();
    ///Map for product stock string (string of product-location) as key and newly created Consumed Product Stock as value
    Map<String,SVMXC__Product_Stock__c> tobeCreatedProductStockMap = new Map<String,SVMXC__Product_Stock__c>();

    if(workDetailList != null && workDetailList.size() > 0){
      ilib_LogEvent.info('VanStockUtility : Start of Part Consumption Process');

      //Get the Product Stock and will populate map for Technician and Inventory Location
      List<SVMXC__Product_Stock__c> allProductStockList = queryValidProductStock(workDetailList);
      List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>();
      List<SVMXC__Product_Stock__c> consumedProductStockList = new List<SVMXC__Product_Stock__c>();
	  
      //Consumed Product stock vs list of batched stocked serials
      Map<Id,List<SVMXC__Product_Serial__c>> consumedProductStockBatchSerialMap = new Map<Id,List<SVMXC__Product_Serial__c>>();
    
      //seperate consumed product stock list and available product stock list.
      if(allProductStockList != null && allProductStockList.size() > 0){
        for(SVMXC__Product_Stock__c productStock : allProductStockList){
          if(productStock.SVMXC__Status__c == AVAILABLE_STATUS){
            productStockList.add(productStock);
          }else if(productStock.SVMXC__Status__c == CONSUMED_STATUS){
            consumedProductStockList.add(productStock);
            if(productStock.SVMXC__Product__r.SVMXC__Tracking__c == 'Lot/Batch Tracked'){
              consumedProductStockBatchSerialMap.put(productStock.Id, new List<SVMXC__Product_Serial__c>());
            }
          }
        }
        
        ilib_LogEvent.info('productStockList-->: '+UtilsCollection.getSetOfIds(productStockList));//CMSI-69 
        ilib_LogEvent.info('consumedProductStockList-->: '+UtilsCollection.getSetOfIds(consumedProductStockList));//CMSI-69 
        ilib_LogEvent.info('consumedProductStockBatchSerialMap' +  consumedProductStockBatchSerialMap);//CMSI-69
       
      }

      //Get the Stocked Serial
      List<SVMXC__Product_Serial__c> stockedSerialList = queryValidStockSerial(workDetailList, consumedProductStockBatchSerialMap.keySet());
      //Group all Stock Serials based on Product Stock
      if(stockedSerialList != null){
        for(SVMXC__Product_Serial__c stockedSerial : stockedSerialList){
          List<SVMXC__Product_Serial__c> stockSerialList = productStockIdAllStockSerialMap.get(stockedSerial.SVMXC__Product_Stock__c);
          if(stockSerialList == null){
            stockSerialList = new List<SVMXC__Product_Serial__c>();
            productStockIdAllStockSerialMap.put(stockedSerial.SVMXC__Product_Stock__c,stockSerialList);
          }
          stockSerialList.add(stockedSerial);
            if(consumedProductStockBatchSerialMap.containsKey(stockedSerial.SVMXC__Product_Stock__c)){
                consumedProductStockBatchSerialMap.get(stockedSerial.SVMXC__Product_Stock__c).add(stockedSerial);
            }
            ilib_LogEvent.message('stockSerialList-->: '+stockedSerial.Id);//CMSI-69
        }
       
      }
      ilib_LogEvent.info('productStockIdAllStockSerialMap' +  productStockIdAllStockSerialMap);//CMSI-69
            
      for(SVMXC__Service_Order_Line__c workDetailLine : workDetailList){
        ilib_LogEvent.message('VanStockUtility : Performing Van Stock Consumption : ' + workDetailLine.Name);
        if(workDetailLine.SVMX_PS_VS_Consumed_Status__c == null || !workDetailLine.SVMX_PS_VS_Consumed_Status__c.contains('Consumption Success')){
          SVMXC__Product_Stock__c correctProductStockRec = null;
          boolean isDataValid = false;

          //We have Product Stock Supplied. Consume using Product Stock
          if(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c != null){
            isDataValid = true;
            ilib_LogEvent.message('VanStockUtility : Given Product Stock Directly');
            for(SVMXC__Product_Stock__c productStock : productStockList){
              if(productStock.Id == workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c){
                correctProductStockRec = productStock;
                break;
              }
            }
          //We have Consumed Location and Part Supplied. Consume using Location
          }else if (workDetailLine.SVMXC__Consumed_From_Location__c != null
               && workDetailLine.SVMXC__Product__c != null){
            isDataValid = true;
            ilib_LogEvent.message('VanStockUtility : Given Consumed Location and Part');
            for(SVMXC__Product_Stock__c productStock : productStockList){
              if(productStock.SVMXC__Location__c == workDetailLine.SVMXC__Consumed_From_Location__c &&
                  productStock.SVMXC__Product__c == workDetailLine.SVMXC__Product__c &&
                  productStock.SVMXC__Status__c == 'Available'){
                correctProductStockRec = productStock;
                break;
              }
            }
          //We have Technician and Part Supplied. Consume using Technician
          }else if(workDetailLine.SVMXC__Group_Member__c != null && workDetailLine.SVMXC__Product__c != null){
            ilib_LogEvent.message('VanStockUtility : Given Technician and Part');
            isDataValid = true;
            if( technicianIdInvntLocIdMap != null && technicianIdInvntLocIdMap.size() > 0){
              Id locationId = technicianIdInvntLocIdMap.get(workDetailLine.SVMXC__Group_Member__c);
              if(locationId != null){
                for(SVMXC__Product_Stock__c productStock : productStockList){
                  if(productStock.SVMXC__Location__c == locationId &&
                      productStock.SVMXC__Product__c == workDetailLine.SVMXC__Product__c &&
                      productStock.SVMXC__Status__c == 'Available'){
                    correctProductStockRec = productStock;
                    break;
                  }
                }
              }else{
                isDataValid = false;
                //cannot found location id.so cannot proceed
                ilib_LogEvent.message('VanStockUtility : No Inventory Location found');
                workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_INVT_LOC_FOR_TECH;
                workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                updatedWorkDetailLinesSet.add(workDetailLine);
              }
            }else{
              isDataValid = false;
              //map has no inventory location.so cannot proceed
              ilib_LogEvent.message('VanStockUtility : No Inventory Location found');
              workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_INVT_LOC_FOR_TECH;
              workDetailLine.SVMXC__Posted_To_Inventory__c = false;
              updatedWorkDetailLinesSet.add(workDetailLine);
            }
          }else if(workDetailLine.SVMXC__Product__c != null && isOutsideInventoryAllowed){
            ilib_LogEvent.message('VanStockUtility : This is Outside Inventory');
            isDataValid = false;
            //could not product stock but outside inventory allowed. Hence consume
            workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + SUCCESS_MSG_FOR_OUTSIDE_INVENTORY;
            workDetailLine.SVMXC__Posted_To_Inventory__c = true;
            workDetailLine.SVMXC__Line_Status__c = 'Closed';
            updatedWorkDetailLinesSet.add(workDetailLine);
          }else if(workDetailLine.SVMX_PS_VS_Is_Part_Out__c){
            //there is only Part Out provided. Hence perform part out process
            isDataValid = false;
            ilib_LogEvent.message('VanStockUtility : Line has only Part Out.');
          }else{
            //No Proper Details for Part Consumption Given
            ilib_LogEvent.message('VanStockUtility : No Proper Data found for consumption');
            isDataValid = false;
            workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_DATA;
            workDetailLine.SVMXC__Posted_To_Inventory__c = false;
            updatedWorkDetailLinesSet.add(workDetailLine);
          }

          if(isDataValid && correctProductStockRec != null){
            SVMXC__Product_Stock__c consumedProductStockRec = null;
            boolean performSerializedConsumption = false;
            boolean performNonSerializedConsumption = false;
            boolean isCreateInstalledProduct = false;
            SVMXC__Product_Serial__c consumedBatchStockRec = null;

            //try to find consumed product stock
            for(SVMXC__Product_Stock__c consumedProductStock : consumedProductStockList){
              if(consumedProductStock.SVMXC__Location__c == correctProductStockRec.SVMXC__Location__c &&
                  consumedProductStock.SVMXC__Product__c == correctProductStockRec.SVMXC__Product__c){
                  ilib_LogEvent.fine('VanStockUtility : Found Consumed Product Stock : ' + consumedProductStock.Id 
                          + ' for Product Stock - ' + correctProductStockRec.Id);
                consumedProductStockRec = consumedProductStock;
                if(consumedProductStockBatchSerialMap.containskey(consumedProductStock.Id)){
                  for(SVMXC__Product_Serial__c consumedBatchStock : consumedProductStockBatchSerialMap.get(consumedProductStock.Id))
                  {
                    if(consumedBatchStock.Batch_Number__c == workDetailLine.Batch_Number__c && 
                       consumedProductStock.SVMXC__Product__c == workDetailLine.SVMXC__Product__c){
                           consumedBatchStockRec = consumedBatchStock;
                           break;
                       }
                  }
                }
                break;
              }
            }
			      
            if(consumedProductStockRec == null && tobeCreatedProductStockMap.size() > 0){
              String uniqueKey = correctProductStockRec.SVMXC__Location__c + '-' + correctProductStockRec.SVMXC__Product__c;
              consumedProductStockRec = tobeCreatedProductStockMap.get(uniqueKey);
            }
            
            //Check if the Product Stock is Serialized or Lot/Batch Tracked
            if((correctProductStockRec.SVMXC__Product__r.SVMXC__Tracking__c != null && 
                correctProductStockRec.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized')) ||
                correctProductStockRec.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ) {
              if(isSerializedTrackingAllowed){
                performSerializedConsumption = true;
                if(isCreateIPFromSerialized){
                  isCreateInstalledProduct = true;
                }
              }else{
                ilib_LogEvent.message('VanStockUtility : Performing Serialized Part Consumption is not allowed');
              }
            }
            //Check if the Product Stock is Lot/Batch Tracked
            else if(correctProductStockRec.SVMXC__Product__r.SVMXC__Tracking__c != null && 
                    correctProductStockRec.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
              if(isLotBatchTrackedAllowed){
                performSerializedConsumption = true;
                if(isCreateIPFromLotBatch){
                  isCreateInstalledProduct = true;
                }
              }else{
                ilib_LogEvent.message('VanStockUtility : Performing Lot/Batch Part Consumption is not allowed');
              }
            //Now Product Stock is Non-Serialzed
            } else {
              if(isNonSerializedTrackingAllowed){
                if(workDetailLine.SVMXC__Actual_Quantity2__c != null && workDetailLine.SVMXC__Actual_Quantity2__c > 0){
                  performNonSerializedConsumption = true;
                }else{
                  //map has no inventory location.so cannot proceed
                  workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_QTY_PROVIDED;
                  workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                  updatedWorkDetailLinesSet.add(workDetailLine);
                }
              }else{
                ilib_LogEvent.message('VanStockUtility : Performing Non-Serialzed Part Consumption is not allowed');
              }
            }

            //Perform Serialzed Part Consumption
            if(performSerializedConsumption){
              ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                  + ',Perform Serialized Part Consumption');
               
              List<SVMXC__Product_Serial__c> stockSerialList = productStockIdAllStockSerialMap.get(correctProductStockRec.Id);
              StockConsumptionWrapper stockConsumptionWrapperRec = handleSerializedProductStockConsumption
                                                                      (workDetailLine,correctProductStockRec,consumedProductStockRec,
                                                                        stockSerialList,isCreateInstalledProduct,consumedBatchStockRec,mapStockSerialToBeUpdated);                                                        
              if(stockConsumptionWrapperRec != null){
                if(stockConsumptionWrapperRec.getWorkDetail() != null){
                  updatedWorkDetailLinesSet.add(stockConsumptionWrapperRec.getWorkDetail());

                  if(stockConsumptionWrapperRec.getIsPartConsumptionProcessSuccess()){
                    allocatedQtyHandlerWorkDetailList.add(stockConsumptionWrapperRec.getWorkDetail());
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Work Detail to be updated');
                }

                if(stockConsumptionWrapperRec.getProductStock() != null){
                  SVMXC__Product_Stock__c productStockRecord = stockConsumptionWrapperRec.getProductStock();
                  updatedProductStockLinesMap.put(productStockRecord.Id,productStockRecord);
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Product Stock to be updated');
                }

                SVMXC__Product_Stock__c consumedProductStock = null;
                if(stockConsumptionWrapperRec.getConsumedProductStock() != null){
                  consumedProductStock = stockConsumptionWrapperRec.getConsumedProductStock();
                  if(stockConsumptionWrapperRec.isCreateConsumedProductStock){
                    String uniqueKey = consumedProductStock.SVMXC__Location__c + '-' 
                                                + consumedProductStock.SVMXC__Product__c;
                    tobeCreatedProductStockMap.put(uniqueKey,consumedProductStock);
                  }else{
                    updatedProductStockLinesMap.put(consumedProductStock.Id,consumedProductStock);
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Consumed Product Stock to be created');
                }

                if(stockConsumptionWrapperRec.getProductSerial() != null){
                  SVMXC__Product_Serial__c stockSerial = stockConsumptionWrapperRec.getProductSerial();
				    // Added Id null check by Shruti Karn to fix orphan record issue for stock serial records
                  if((stockConsumptionWrapperRec.isCreateConsumedProductStock || (consumedProductStock!= null && consumedProductStock.Id==null)) && workDetailLine.Batch_Number__c == null){
                    String keyValue = consumedProductStock.SVMXC__Location__c + '-' 
                                                + consumedProductStock.SVMXC__Product__c;
                    List<SVMXC__Product_Serial__c> updatedStockSerialList = 
                                        productStockStringStockSerialMap.get(keyValue);  
                    if(updatedStockSerialList == null){            
                      updatedStockSerialList = new List<SVMXC__Product_Serial__c>();
                      productStockStringStockSerialMap.put(keyValue,updatedStockSerialList);
                    }
                    updatedStockSerialList.add(stockSerial);
                  }else{
                      mapStockSerialToBeUpdated.put(stockSerial.Id,stockSerial);
                    //updatedStockSerialLinesSet.add(stockSerial);
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Stock Serials to be updated');
                }
                if(stockConsumptionWrapperRec.getProductSerial() != null && stockConsumptionWrapperRec.getConsumedbatchStockSerial() != null){
                  SVMXC__Product_Serial__c consumedBatchStock = stockConsumptionWrapperRec.getConsumedbatchStockSerial();
                  // Added Id null check by Shruti Karn to fix orphan record issue for batch serial records
				  if(stockConsumptionWrapperRec.isCreateConsumedProductStock || (consumedProductStock!= null && consumedProductStock.Id==null)){
                    String keyValue = consumedProductStock.SVMXC__Location__c + '-' 
                                                + consumedProductStock.SVMXC__Product__c;
                    List<SVMXC__Product_Serial__c> updatedStockSerialList = 
                                        productStockStringStockSerialMap.get(keyValue); 
                    if(updatedStockSerialList == null){            
                      updatedStockSerialList = new List<SVMXC__Product_Serial__c>();
                      productStockStringStockSerialMap.put(keyValue,updatedStockSerialList);
                    }
                    updatedStockSerialList.add(consumedBatchStock);
                  }else if(consumedBatchStock.Id == null){
                      mapTobeCreatedStockSerialLines.put(consumedBatchStock.SVMX_PS_External_ID__c,consumedBatchStock);
                  }else{
                    //updatedStockSerialLinesSet.add(consumedBatchStock);
                    mapStockSerialToBeUpdated.put(consumedBatchStock.Id,consumedBatchStock);
                  }
                }
				        if(stockConsumptionWrapperRec.getStockHistory() != null){
                  createdStockHistoryLinesSet.add(stockConsumptionWrapperRec.getStockHistory());
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Stock History to be created');
                }

                if(stockConsumptionWrapperRec.getInstalledIP() != null){
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ',IP to be updated');
                  stockConsumptionWrapperSet.add(stockConsumptionWrapperRec);
                }else if(stockConsumptionWrapperRec.isCreateInstalledProduct){
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', New IP to be created');
                  stockConsumptionWrapperSet.add(stockConsumptionWrapperRec);
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No new IP to be created');
                }

              }else{
                ilib_LogEvent.message('VanStockUtility : No Data received after Part Consumption');
              }

              ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ',Serialized Part Consumption is completed');
            //Perform Non-Serialzed Part Consumption
            }else if(performNonSerializedConsumption){
              ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ',Perform Non-Serialized Part Consumption');
               
               StockConsumptionWrapper stockConsumptionWrapperRec = handleNonSerializedProductStockConsumption
                                                                        (workDetailLine,correctProductStockRec,consumedProductStockRec);
              if(stockConsumptionWrapperRec != null){
                if(stockConsumptionWrapperRec.getWorkDetail() != null){
                  updatedWorkDetailLinesSet.add(stockConsumptionWrapperRec.getWorkDetail());

                  if(stockConsumptionWrapperRec.getIsPartConsumptionProcessSuccess()){
                    allocatedQtyHandlerWorkDetailList.add(stockConsumptionWrapperRec.getWorkDetail());
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Work Detail to be updated');
                }

                if(stockConsumptionWrapperRec.getProductStock() != null){
                  SVMXC__Product_Stock__c productStockRecord = stockConsumptionWrapperRec.getProductStock();
                  updatedProductStockLinesMap.put(productStockRecord.Id,productStockRecord);
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Product Stock to be updated');
                }

                SVMXC__Product_Stock__c consumedProductStock = null;
                if(stockConsumptionWrapperRec.getConsumedProductStock() != null){
                  consumedProductStock = stockConsumptionWrapperRec.getConsumedProductStock();
                  if(stockConsumptionWrapperRec.isCreateConsumedProductStock){
                    String uniqueKey = consumedProductStock.SVMXC__Location__c + '-' 
                                                + consumedProductStock.SVMXC__Product__c;
                    tobeCreatedProductStockMap.put(uniqueKey,consumedProductStock);
                  }else{
                    updatedProductStockLinesMap.put(consumedProductStock.Id,consumedProductStock);
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Consumed Product Stock to be created');
                }

                if(stockConsumptionWrapperRec.getStockHistory() != null){
                  createdStockHistoryLinesSet.add(stockConsumptionWrapperRec.getStockHistory());
                  ilib_LogEvent.message('setOfAccIds-->: '+createdStockHistoryLinesSet);//CMSI-69
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No Stock History to be created');
                }

                if(stockConsumptionWrapperRec.isCreateInstalledProduct){
                  stockConsumptionWrapperSet.add(stockConsumptionWrapperRec);
                }else{
                  ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name
                                                      + ', No new IP to be created');
                }

              }else{
                ilib_LogEvent.message('VanStockUtility : No Data received after Part Consumption');
              }

              ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ', Non-Serialized Part Consumption is completed');
            }
          }else if(isDataValid){
            //No Proper Details for Part Consumption Given
            ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ', Cannot find Product Stock');
            workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_PRODUCT_STOCK;
            workDetailLine.SVMXC__Posted_To_Inventory__c = false;
            workDetailIdStatusStringMap.put(workDetailLine.Id,'True-False');
            updatedWorkDetailLinesSet.add(workDetailLine);
           
          }else{
            //No Proper Details for Part Consumption Given
            ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ', Data is not valid');
          }
        }else{
          //No Proper Details for Part Consumption Given
          ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name 
                                                  + ', Consumption has already happened');
        }
      }

      //Commit Changes to Database
      Savepoint savePointRec = Database.setSavepoint();

      try{
        List<sObject> allObjectsList = new List<sObject>();

        if(tobeCreatedProductStockMap != null && tobeCreatedProductStockMap.size() > 0){
          ilib_LogEvent.info('Creating Consumed Product Stock records');
           Database.SaveResult[] results = Database.insert(tobeCreatedProductStockMap.values(), true);
		      ApexExceptions.emitSaveErrors(results, 'VanstockUtility_Productstock_Create');
          ilib_LogEvent.info('VanStockUtility : Done with Consumed Product Stock records');

          for(SVMXC__Product_Stock__c  consumedProductStock : tobeCreatedProductStockMap.values()){
            String keyValue = consumedProductStock.SVMXC__Location__c + '-' 
                                                + consumedProductStock.SVMXC__Product__c;
            List<SVMXC__Product_Serial__c> updatedStockSerialList = productStockStringStockSerialMap.get(keyValue);
            if(updatedStockSerialList != null && updatedStockSerialList.size() > 0){
              for(SVMXC__Product_Serial__c stockSerial : updatedStockSerialList){
                stockSerial.SVMXC__Product_Stock__c = consumedProductStock.Id;
                if(stockSerial.Id == null){
                      mapTobeCreatedStockSerialLines.put(stockSerial.SVMX_PS_External_ID__c,stockSerial);
                }else{
                  //updatedStockSerialLinesSet.add(stockSerial);
                  mapStockSerialToBeUpdated.put(stockSerial.Id,stockSerial);
                }
              }
            }
          }
        }
        List<SVMXC__Service_Order_Line__c> orderLineList = new List<SVMXC__Service_Order_Line__c> ();
        if(updatedWorkDetailLinesSet != null && updatedWorkDetailLinesSet.size() > 0){
          
          orderLineList.addAll(updatedWorkDetailLinesSet);
          List<sObject> sobjectList = (List<sObject>) orderLineList;
          allObjectsList.addAll(sobjectList);
        }else{
          ilib_LogEvent.info('VanStockUtility : No Work Details to be updated');
        }

        if(updatedProductStockLinesMap != null && updatedProductStockLinesMap.size() > 0){
          List<sObject> sobjectList = (List<sObject>) updatedProductStockLinesMap.values();
          allObjectsList.addAll(sobjectList);
        }else{
          ilib_LogEvent.info('VanStockUtility : No Product Stock to be updated');
        }

        if(mapStockSerialToBeUpdated != null && mapStockSerialToBeUpdated.size() > 0){
          List<SVMXC__Product_Serial__c> stockSerialList = new List<SVMXC__Product_Serial__c> ();
          stockSerialList.addAll(mapStockSerialToBeUpdated.values());
          List<sObject> sobjectList = (List<sObject>) stockSerialList;
          allObjectsList.addAll(sobjectList);
        }else{
          ilib_LogEvent.info('VanStockUtility : No Stock Serial to be updated');
        }

        if(allObjectsList.size() > 0){
          ilib_LogEvent.info('VanStockUtility : Updating Work Details, Product Stock and Stocked Serial ');
          
          for(SVMXC__Service_Order_Line__c ll: [select SVMXC__Service_Order__r.SVMXC__Order_Status__c from SVMXC__Service_Order_Line__c
          where Id in: orderLineList]){
            ilib_LogEvent.info('>>>>>>>>>>>>>>>>>>>>>>>>'+ll.SVMXC__Service_Order__r.SVMXC__Order_Status__c);
          }
          Database.SaveResult[] updateResults = Database.update(allObjectsList, false);
		      ApexExceptions.emitUpdateErrorsWithRelatedRecord(updateResults, 'VanstockUtility_Update',allObjectsList);
          ilib_LogEvent.info('VanStockUtility : Done with Updation for Work Details, Product Stock and Stocked Serial');
        }

        if(createdStockHistoryLinesSet != null && createdStockHistoryLinesSet.size() > 0){
          ilib_LogEvent.info('Creating Stock History record');
          List<SVMXC__Stock_History__c> stockHistoryList = new List<SVMXC__Stock_History__c> ();
          stockHistoryList.addAll(createdStockHistoryLinesSet);
          Database.SaveResult[] results = Database.insert(stockHistoryList, true);
		      ApexExceptions.emitSaveErrors(results, 'VanstockUtility_StockHistory_Create');
          ilib_LogEvent.info('VanStockUtility : Done with Creation of Stock History record');
        }else{
          ilib_LogEvent.info('VanStockUtility : No Stock History to be created');
        }
        if(mapTobeCreatedStockSerialLines != null && mapTobeCreatedStockSerialLines.size()>0){
            Database.SaveResult[] results = Database.insert(mapTobeCreatedStockSerialLines.values(),true);
			  ApexExceptions.emitSaveErrors(results, 'VanstockUtility_StockedSerials_Create');
        }
      }catch(Exception exceptionRecord){
        ilib_LogEvent.info('VanStockUtility :Problem while updation of records - ' + exceptionRecord.getMessage());
        Database.rollback(savePointRec);
        throw exceptionRecord;
      }

      if(isAllocatedQtyDecrementAllowed){
        try{
          SVMX_PS_VS_VanStockAllocateQtyUtility allocatedQtyHandler = new SVMX_PS_VS_VanStockAllocateQtyUtility();
          allocatedQtyHandler.handleAllocatedQtyForWorkDetailsDeletion(allocatedQtyHandlerWorkDetailList);
        }catch(Exception exceptionRecord){
          ilib_LogEvent.info('VanStockUtility : Problem with Allocated Qty : ' + exceptionRecord.getMessage());
        }
      }else{ 
        ilib_LogEvent.info('VanStockUtility : Currently Allocated Stock is not in used');
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : No Work Details for Part Consumption Process');
    }

    ilib_LogEvent.info('VanStockUtility : End of Part Consumption Process');
    
    ilib_LogEvent.info('updatedWorkDetailLinesSet-->: '+updatedWorkDetailLinesSet);//CMSI-69
    ilib_LogEvent.info('stockConsumptionWrapperSet-->: '+stockConsumptionWrapperSet);//CMSI-69
    ilib_LogEvent.info('createdStockHistoryLinesSet-->: '+createdStockHistoryLinesSet);//CMSI-69
    ilib_LogEvent.info('updatedProductStockLinesMap' +  updatedProductStockLinesMap);//CMSI-69	
    ilib_LogEvent.info('tobeCreatedProductStockMap' +  tobeCreatedProductStockMap);//CMSI-69	
    ilib_LogEvent.info('productStockStringStockSerialMap' + productStockStringStockSerialMap);//CMSI-69	
    ilib_LogEvent.info('mapStockSerialToBeUpdated' + mapStockSerialToBeUpdated);//CMSI-69	
    ilib_LogEvent.info('mapTobeCreatedStockSerialLines' +  mapTobeCreatedStockSerialLines);//CMSI-69
    
    ilib_LogEvent.pop();//CMSI-69
    

    return stockConsumptionWrapperSet;
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryValidProductStock
  *  Parameter   : List<SVMXC__Service_Order_Line__c> validWorkDetailList -- Work Details using which we need to query Product Stock
  *  Returns     : List<SVMXC__Product_Stock__c> -- List of all Product Stock queried
  *  Description : This method finds all relevant product stock which is needed for consumption
  *                We currently could have following data:-
  *                 a. The Product Stock is given directly
  *                 b. The Consumed From Location and Consumed Part is given which can give relevant Product Stock
  *                 c. The Technician and Consumed Part is given - in this case, find the relevant Inventory Location 
  *                    and then follow logic as per #b
  *******************************************************************************************************************************************/  
  @TestVisible private List<SVMXC__Product_Stock__c> queryValidProductStock(List<SVMXC__Service_Order_Line__c> validWorkDetailList){
    ilib_LogEvent.push(LOG_TITLE + '.queryValidProductStock()');//CMSI-69
    
    ilib_LogEvent.info('VanStockUtility : Start Query Product Stock Process');
    
    //List of Product Stock found
    List<SVMXC__Product_Stock__c> productStockList = null;

    if(validWorkDetailList != null && validWorkDetailList.size() > 0){
      //Get Valid Product Stock
      //We currently have following data:-
      //  a. Either the Product Stock is given
      //  b. OR the Consumed From Location is given
      //  c. OR the Technician is given
      //In case of #b and #c, find the relevant product stock by using SOQL Query

      //Set to store  location ids for which we need to find product stock
      Set<Id> locationIdsSetToBeQueried = new Set<Id>();
      //Set to store  technican ids for which we need to find inventory location's product stock
      Set<Id> techIdsSetToBeQueried = new Set<Id>();
      //Set to store the Products
      Set<Id> productIdsSetToBeQueried = new Set<Id>();
      //Set to store the Product Stock
      Set<Id> productStockIdSetToBeQueried = new Set<Id>();

      for(SVMXC__Service_Order_Line__c workDetailLine : validWorkDetailList){
        //We have Product Stock Supplied. Consume using Product Stock
        if(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c != null){
          productStockIdSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c);
          locationIdsSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Location__c);
          productIdsSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c);
        //We have Consumed Location and Part Supplied. Consume using Location
        }else if (workDetailLine.SVMXC__Consumed_From_Location__c != null
             && workDetailLine.SVMXC__Product__c != null){
          locationIdsSetToBeQueried.add(workDetailLine.SVMXC__Consumed_From_Location__c);
          productIdsSetToBeQueried.add(workDetailLine.SVMXC__Product__c);
        //We have Technician and Part Supplied. Consume using Technician
        }else if(workDetailLine.SVMXC__Group_Member__c != null
           && workDetailLine.SVMXC__Product__c != null){
          techIdsSetToBeQueried.add(workDetailLine.SVMXC__Group_Member__c);
          productIdsSetToBeQueried.add(workDetailLine.SVMXC__Product__c);
        }else{
          ilib_LogEvent.message('VanStockUtility : This Work Detail Line is not valid for consumption - ' 
                      + workDetailLine.Id);
        }
      }
      ilib_LogEvent.info('productStockIdSetToBeQueried-->: '+productStockIdSetToBeQueried);//CMSI-69
      ilib_LogEvent.info('productIdsSetToBeQueried-->: '+productIdsSetToBeQueried);//CMSI-69
      ilib_LogEvent.info('techIdsSetToBeQueried-->: '+techIdsSetToBeQueried);//CMSI-69

      //Check if data provided to query product stock is proper.
      if(productStockIdSetToBeQueried != null || 
          (locationIdsSetToBeQueried != null && productIdsSetToBeQueried != null) || 
          (techIdsSetToBeQueried != null && productIdsSetToBeQueried != null)){
        //If any technicians find their inventory location so that associated product stock can be found
        if(techIdsSetToBeQueried != null && techIdsSetToBeQueried.size() > 0){
          technicianIdInvntLocIdMap = queryInventoryLocations(techIdsSetToBeQueried);

          if(technicianIdInvntLocIdMap != null && technicianIdInvntLocIdMap.size() > 0){
            locationIdsSetToBeQueried.addAll(technicianIdInvntLocIdMap.values());
            ilib_LogEvent.info('locationIdsSetToBeQueried-->: '+locationIdsSetToBeQueried);//CMSI-69
          }
        }

        //Create Query String for all Product Stock Id's available
        String productStockIdString = null;
        if(productStockIdSetToBeQueried != null && productStockIdSetToBeQueried.size() > 0){
          productStockIdString = createQueryStringUsingList('Id', productStockIdSetToBeQueried);
        }

        //Create Query String for all Product Id's available
        String productIdString = null;
        if(productIdsSetToBeQueried != null && productIdsSetToBeQueried.size() > 0){
          productIdString = createQueryStringUsingList('SVMXC__Product__c', productIdsSetToBeQueried);
        }

        //Create Query String for all Locations Id's available
        String locationIdString = null;
        if(locationIdsSetToBeQueried != null && locationIdsSetToBeQueried.size() > 0){
          locationIdString = createQueryStringUsingList('SVMXC__Location__c',locationIdsSetToBeQueried);
        }

        //Create Product Stock Query
        String productStockQueryString = 'SELECT Id,Name,SVMXC__Allocated_Qty__c,SVMXC__Available_Qty__c,' +
                                          'SVMXC__Location__c,SVMXC__Product__c,SVMXC__Quantity2__c,'+ 
                                          'SVMXC__Product__r.SVMXC__Stockable__c,SVMXC__Product__r.SVMXC__Tracking__c,'+ 
                                          'SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c,SVMXC__Status__c ' +
                                          'FROM SVMXC__Product_Stock__c WHERE SVMXC__Status__c IN (\'Available\',\'Consumed\')';

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
            ilib_LogEvent.info('Product Stock Query String - ' + productStockQueryString);
            productStockList =Database.query(productStockQueryString);
          }catch(Exception exceptionRecord){ 
            ilib_LogEvent.info('VanStockUtility : Could not query Product Stock - ' + exceptionRecord.getMessage());
          }
        }else{
          ilib_LogEvent.info('VanStockUtility : No data available to query Product Stock');
        }
      }else{
        ilib_LogEvent.info('VanStockUtility : No Data provided for Part Consumption Process.');
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : No Work Details for Part Consumption Process');
    }
    ilib_LogEvent.info('VanStockUtility : End Query Product Stock Process');
    ilib_LogEvent.info('productStockList-->: '+UtilsCollection.getSetOfIds(productStockList));//CMSI-69
    ilib_LogEvent.pop();
    return productStockList;
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryValidStockSerial
  *  Parameter   : List<SVMXC__Service_Order_Line__c> validWorkDetailList -- Work Details using which we need to query Stock Serial
  *  Returns     : List<SVMXC__Product_Serial__c> -- List of all Stock Serial queried
  *  Description : This method finds all relevant stock serials which is needed for consumption
  *                We currently could have following data:-
  *                 a. The Stock Serial is given directly
  *                 b. The Consumed Part Code is given which can give relevant Stock Serial
  *******************************************************************************************************************************************/  
  @TestVisible private List<SVMXC__Product_Serial__c> queryValidStockSerial(List<SVMXC__Service_Order_Line__c> validWorkDetailList, Set<Id> consumedProductStockIdsList){
    ilib_LogEvent.push(LOG_TITLE + '.queryValidStockSerial()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility : Start Query Stock Serial Process');
    ilib_LogEvent.info('consumedProductStockIdsList-->: '+consumedProductStockIdsList);//CMSI-69
    
    //List of Stock Serials found
    List<SVMXC__Product_Serial__c> stockSeriallList = null;

    if(validWorkDetailList != null && validWorkDetailList.size() > 0){
      //Set to store stock serial ids 
      Set<Id> stockSerialIdsSetToBeQueried = new Set<Id>();
      //Set to store names of stock serials 
      Set<String> stockSerialNameSetToBeQueried = new Set<String>();

      for(SVMXC__Service_Order_Line__c workDetailLine : validWorkDetailList){
        //We have Stock Serial Supplied.
        if(workDetailLine.SVMX_PS_VS_Consumed_Stocked_Serial__c != null){
            stockSerialIdsSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Stocked_Serial__c);
        }else if(workDetailLine.Batch_Lookup__c != null){
            stockSerialIdsSetToBeQueried.add(workDetailLine.Batch_Lookup__c);
        //We have Stock Serial Name.
        }else if (workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c != null){
          stockSerialNameSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c);
        }else{
          ilib_LogEvent.message('VanStockUtility : This Work Detail Line is not valid for stock serial query - ' 
                      + workDetailLine.Id);
        }
      }
      ilib_LogEvent.info('stockSerialIdsSetToBeQueried-->: '+stockSerialIdsSetToBeQueried);//CMSI-69

      //Check if data provided to query stock serial is proper.
      if(stockSerialNameSetToBeQueried != null || stockSerialIdsSetToBeQueried != null){
        //Create Query String for all Stock Serial Id's available
        String stockSerialIdString = null;
        if(stockSerialIdsSetToBeQueried != null && stockSerialIdsSetToBeQueried.size() > 0){
          stockSerialIdString = createQueryStringUsingList('Id', stockSerialIdsSetToBeQueried);
          ilib_LogEvent.info('stockSerialIdString-->: ' +stockSerialIdString );//CMSI-69
        }
	
        //Create Query String for all Stock Serial Names available
        String stockSerialNameString = null;
        if(stockSerialNameSetToBeQueried != null && stockSerialNameSetToBeQueried.size() > 0){
          stockSerialNameString = 'Name IN (';
          for(String stockSerialName : stockSerialNameSetToBeQueried){
            stockSerialNameString += '\'' + stockSerialName + '\',';
          }
          stockSerialNameString = stockSerialNameString.substring(0,stockSerialNameString.length()-1);
          stockSerialNameString += ')';
        }
		
         String consumedProductStockIdString = null;
         if(consumedProductStockIdsList != null && consumedProductStockIdsList.size() > 0){
         	consumedProductStockIdString = createQueryStringUsingList('SVMXC__Product_Stock__c', consumedProductStockIdsList);
         }
        
        //Create Product Stock Query
        String stockSerialQueryString = 'SELECT Id,Name,SVMXC__Active__c,SVMXC__Product__c,SVMXC__Product_Stock__c,SVMX_PS_VS_Linked_Installed_Product__c,Quantity__c,Batch_Number__c,SVMX_PS_External_ID__c  ' +
                                          'FROM SVMXC__Product_Serial__c WHERE SVMXC__Active__c = TRUE ';

        if(stockSerialIdString != null){
          stockSerialQueryString += ' AND (' + stockSerialIdString;
          if(stockSerialNameString != null){
            stockSerialQueryString += ' OR ' + stockSerialNameString;
          }
          if(consumedProductStockIdString != null && stockSerialQueryString != null){
          	stockSerialQueryString += ' OR ' + consumedProductStockIdString;
          }
        
          stockSerialQueryString += ')';
        }else if(stockSerialNameString != null){
          stockSerialQueryString += ' AND ' + stockSerialNameString;
        }else{
          stockSerialQueryString = null;
        }
        if(stockSerialQueryString != null){
          try{
            ilib_LogEvent.info('Stock Serial Query String - ' + stockSerialQueryString);
            stockSeriallList =Database.query(stockSerialQueryString);
          }catch(Exception exceptionRecord){ 
            ilib_LogEvent.info('VanStockUtility : Could not query Stock Serials - ' + exceptionRecord.getMessage());
          }
        }else{
          ilib_LogEvent.info('VanStockUtility : No data available to query Stock Serial');
        }
      }else{
        ilib_LogEvent.info('VanStockUtility : No Data provided for Stock Serial Query Process.');
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : No Work Details for Stock Serial Query Process');
    }

    ilib_LogEvent.info('VanStockUtility : End Query Stock Serial Process');
    ilib_LogEvent.info('stockSeriallList-->: '+UtilsCollection.getSetOfIds(stockSeriallList));//CMSI-69
    ilib_LogEvent.pop();//CMSI-69   
    
    return stockSeriallList;
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
    ilib_LogEvent.push(LOG_TITLE + '.createQueryStringUsingList()');//CMSI-69
    ilib_LogEvent.info('fieldApiName-->: '+fieldApiName);//CMSI-69
    ilib_LogEvent.info('idSet-->: '+idSet);//CMSI-69
    String queryString = null;
    if(idSet != null && idSet.size() > 0 && fieldApiName != null){
      queryString = fieldApiName + ' IN (';
      for(Id recordId : idSet){
        queryString += '\'' + recordId + '\',';
      }
      queryString = queryString.substring(0,queryString.length()-1);
      queryString += ')';
    }else{
      ilib_LogEvent.info('VanStockUtility : Either the fieldApiName or idSet is null. Hence could not create String');
    }
    ilib_LogEvent.info('queryString-->: '+queryString);//CMSI-69
    ilib_LogEvent.pop();//CMSI-69 
    return queryString;
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleSerializedProductStockConsumption
  *  Parameter   : SVMXC__Service_Order_Line__c workDetailLine -- Work Details from which consumption needs to happen
  *                SVMXC__Product_Stock__c productStockRecord -- Product Stock Reorod from which consumption needs to happen
  *                List<SVMXC__Product_Serial__c> stockSerialList -- List of Stock Serials associated with the Product Stock
  *                boolean isCreateInstalledProduct - to indicate if Installed Product needs to be created or not
  *  Returns     : StockConsumptionWrapper -- Wrapper class giving part consumption variables
  *  Description : This method performs Serialized Product Stock Consumption
  *                If the given work details, product stock and stock serial are good, then it will perform following:-
  *                  a. Update Product Stock --> Reduce Qty by 1
  *                  b. Update Stock Serial --> Remove reference of Product Stock and change Active Status to false
  *                  c. Update Work Detail --> Add Consumed Status as "Success", Mark Post to Inventory to True and Status to Completed
  *                  d. Create Stock History Record referring Work Detail, Product Stock and Stock Serial 
  *                Following Messages are given for error conditions:-
  *                ------------------------------------------------------------------------------------------------------------------------
  *                       ERROR CONDITION                              |      MESSAGE
  *                ------------------------------------------------------------------------------------------------------------------------
  *                a. Either No Stock Serial exists with Product Stock | Product Stock is Serialzed. No Stock Serial Found Consumption
  *                   Or Stock Serial data provided in work detail line|
  *                   does not match the Stock Serial record associated|
  *                   Product Stock                                    |       
  *                ------------------------------------------------------------------------------------------------------------------------
  *                b. Work Detail Line is not provided with either     | Product Stock is Serialzed. Hence need Stock Serial for Consumption
  *                   Consumed Serial or Consumed Part Code and the    |
  *                   Product Stock is Serialzed                       |                     
  *                ------------------------------------------------------------------------------------------------------------------------                      
  *******************************************************************************************************************************************/  
  @TestVisible private StockConsumptionWrapper handleSerializedProductStockConsumption(SVMXC__Service_Order_Line__c workDetailLine,
                                          SVMXC__Product_Stock__c productStockRecord, SVMXC__Product_Stock__c consumedProductStock,
                                          List<SVMXC__Product_Serial__c> stockSerialList,boolean isCreateInstalledProduct,
                                          SVMXC__Product_Serial__c consumedBatchStockRec, Map<Id,SVMXC__Product_Serial__c> mapStockSerialToBeUpdated){
    ilib_LogEvent.push(LOG_TITLE + '.handleSerializedProductStockConsumption()');//CMSI-69
    ilib_LogEvent.info('workDetailLine-->: '+workDetailLine);//CMSI-69
    ilib_LogEvent.info('productStockRecord-->: '+productStockRecord);//CMSI-69
    ilib_LogEvent.info('consumedProductStock-->: '+consumedProductStock);//CMSI-69
    ilib_LogEvent.info('stockSerialList-->: '+stockSerialList);//CMSI-69
    ilib_LogEvent.info('isCreateInstalledProduct-->: '+isCreateInstalledProduct);//CMSI-69
    ilib_LogEvent.info('consumedBatchStockRec-->: '+consumedBatchStockRec);//CMSI-69
    ilib_LogEvent.info('mapStockSerialToBeUpdated-->: '+mapStockSerialToBeUpdated);//CMSI-69
    StockConsumptionWrapper stockConsumptionWrapperRec = null;
    boolean isCreateConsumedProductStock = false;
    
    //Check if the stock serial record exists or not
    if(stockSerialList != null && stockSerialList.size() > 0){
      SVMXC__Product_Serial__c stockSerialRecord = null;
      
      //search for the stock serial record provided
      if(workDetailLine.SVMX_PS_VS_Consumed_Stocked_Serial__c != null ||
          workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c != null ||
          workDetailLine.Batch_Lookup__c != null){
		    
        //Get the required Stock Serial
        for(SVMXC__Product_Serial__c stockSerial : stockSerialList){
          if(stockSerial.Id == workDetailLine.SVMX_PS_VS_Consumed_Stocked_Serial__c){
            stockSerialRecord = stockSerial;
            break;
          }else if(stockSerial.Id == workDetailLine.Batch_Lookup__c){
            stockSerialRecord = stockSerial;
            break;
          }else if(stockSerial.Name.equals(workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c)){
            stockSerialRecord = stockSerial;
            break;
         }
        }

        //Stock Serial Record Found, Now Consume Stock Serial and Product Stock
        if(stockSerialRecord != null){
          //consume batch stock record
          if(productStockRecord.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
            if(mapStockSerialToBeUpdated.containskey(stockSerialRecord.Id)){
              stockSerialRecord = mapStockSerialToBeUpdated.get(stockSerialRecord.Id);
            }
		  	    stockSerialRecord.Quantity__c = stockSerialRecord.Quantity__c == null ? workDetailLine.SVMXC__Actual_Quantity2__c : stockSerialRecord.Quantity__c - workDetailLine.SVMXC__Actual_Quantity2__c;
		      }else{
            //consume stock serial
            stockSerialRecord.SVMXC__Product_Stock__c = null;
            stockSerialRecord.SVMXC__Active__c = false;
          }
          //Create consumed product stock if not found
          if(consumedProductStock == null){
            consumedProductStock = new SVMXC__Product_Stock__c();
            consumedProductStock.SVMXC__Product__c = productStockRecord.SVMXC__Product__c;
            consumedProductStock.SVMXC__Location__c = productStockRecord.SVMXC__Location__c;
            consumedProductStock.SVMXC__Status__c = CONSUMED_STATUS;
            consumedProductStock.SVMXC__Quantity2__c = 0;
            isCreateConsumedProductStock = true;
            if(stockSerialRecord.Batch_Number__c != null){
              consumedBatchStockRec = stockSerialRecord.clone();
              consumedBatchStockRec.Quantity__c = workDetailLine.SVMXC__Actual_Quantity2__c;
              consumedBatchStockRec.SVMX_PS_External_ID__c = stockSerialRecord.SVMX_PS_External_ID__c + 'Consumed';
            }
          }else if(stockSerialRecord.Batch_Number__c != null && consumedBatchStockRec != null){
              consumedBatchStockRec.Quantity__c = consumedBatchStockRec.Quantity__c == null ? workDetailLine.SVMXC__Actual_Quantity2__c : consumedBatchStockRec.Quantity__c + workDetailLine.SVMXC__Actual_Quantity2__c;
          }else if(stockSerialRecord.Batch_Number__c != null && consumedBatchStockRec == null){
              consumedBatchStockRec = stockSerialRecord.clone();
              consumedBatchStockRec.Quantity__c = workDetailLine.SVMXC__Actual_Quantity2__c;
              consumedBatchStockRec.SVMXC__Product_Stock__c = consumedProductStock.Id;
              consumedBatchStockRec.SVMX_PS_External_ID__c = stockSerialRecord.SVMX_PS_External_ID__c + 'Consumed';
          }else if(stockSerialRecord.Batch_Number__c == null){
            stockSerialRecord.SVMXC__Product_Stock__c = consumedProductStock.Id;
          } 
			    
          //Decrement the product stock
          if(isProductStockDecrementAllowed && productStockRecord.SVMXC__Quantity2__c != null){
            productStockRecord.SVMXC__Quantity2__c -= workDetailLine.SVMXC__Actual_Quantity2__c;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not decrement Product Stock');
          }

          //Adjust the consumed product stock record
          if(isProductStockDecrementAllowed && consumedProductStock.SVMXC__Quantity2__c != null){
            consumedProductStock.SVMXC__Quantity2__c += workDetailLine.SVMXC__Actual_Quantity2__c;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not decrement Product Stock');
          }

          ilib_LogEvent.info('VanStockUtility : Consumption Successful'); 
          workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + SUCCESS_MSG_FOR_PART_CONSUMPTION;
          workDetailLine.SVMXC__Posted_To_Inventory__c = True;
          workDetailLine.SVMXC__Line_Status__c = 'Closed';

          SVMXC__Stock_History__c stockHistory = null;
          if(isMaintainStockHistoryAllowed){
            //Create Stock history record
            stockHistory = new SVMXC__Stock_History__c();
            stockHistory.SVMXC__Change_Type__c = 'Decrease';
            stockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
            stockHistory.SVMXC__Date_Changed__c = System.Now();
            stockHistory.SVMXC__Product__c = productStockRecord.SVMXC__Product__c;
            stockHistory.SVMXC__Product_Stock__c = productStockRecord.Id;
            stockHistory.SVMXC__From_Product_Stock__c = productStockRecord.Id;
            stockHistory.SVMXC__To_Product_Stock__c = consumedProductStock.Id;
            stockHistory.SVMXC__Location__c = productStockRecord.SVMXC__Location__c;
            if(productStockRecord.SVMXC__Quantity2__c != null){
              stockHistory.SVMXC__Quantity_before_change2__c = productStockRecord.SVMXC__Quantity2__c + 1;
              stockHistory.SVMXC__Quantity_after_change2__c = productStockRecord.SVMXC__Quantity2__c;
            }else{
              stockHistory.SVMXC__Quantity_before_change2__c = 0;
              stockHistory.SVMXC__Quantity_after_change2__c = 0;
            }
            stockHistory.SVMXC__Status__c = 'Consumed'; 
            stockHistory.SVMXC__Transaction_Type__c = 'SVO Usage';
            stockHistory.SVMXC__Service_Order_Line__c = workDetailLine.Id;
            stockHistory.SVMXC__Service_Order__c = workDetailLine.SVMXC__Service_Order__c;
            stockHistory.SVMXC__Product_Serial__c = stockSerialRecord.Id;
            stockHistory.SVMXC__Transaction_Quantity2__c = 1;
            stockHistory.RecordTypeId = stockHistoryRecordTypeId;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not maintain Stock History');
          }

          //ADDED BY SMAX - NOV-15-2018 - TO SUPPORT STOCK SERIAL INSTALL PRODUCT LINK
          ilib_LogEvent.info(' Stock Serial ' + stockSerialRecord.SVMX_PS_VS_Linked_Installed_Product__c);
          if(stockSerialRecord.SVMX_PS_VS_Linked_Installed_Product__c != null){
            ilib_LogEvent.info('VanStockUtility : IP to be updated');
            SVMXC__Installed_Product__c linkedIP = new SVMXC__Installed_Product__c();
            linkedIP.Id = stockSerialRecord.SVMX_PS_VS_Linked_Installed_Product__c;
            
            stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,productStockRecord,consumedProductStock,stockSerialRecord,stockHistory,linkedIP,true,isCreateConsumedProductStock,consumedBatchStockRec);
            stockSerialRecord.SVMX_PS_VS_Linked_Installed_Product__c = null;  
          }else if(isCreateInstalledProduct && workDetailLine.SVMX_PS_VS_Is_Create_Install_Product__c){
            ilib_LogEvent.info('VanStockUtility : IP to be created');
            stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,productStockRecord,consumedProductStock,stockSerialRecord,stockHistory,true,true,isCreateConsumedProductStock,consumedBatchStockRec);
          }else{
            ilib_LogEvent.info('VanStockUtility : No IP to be created');
            stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,productStockRecord,consumedProductStock,stockSerialRecord,stockHistory,false,true,isCreateConsumedProductStock,consumedBatchStockRec);
          }

        }else{
          //No Stock Serial found. Hence could not proceed consumption
          ilib_LogEvent.info('VanStockUtility : After looping thru list, Stock Serial cannot be found');
          workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_STOCK_SERIAL_FOUND;
          workDetailLine.SVMXC__Posted_To_Inventory__c = false;
          stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,null,null,null,null,false,false,false,null);
        } 
      }else{
        //No Stock Serial found. Hence could not proceed consumption
        ilib_LogEvent.info('VanStockUtility : ' + ERROR_MSG_FOR_NO_STOCK_SERIAL);
        workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_STOCK_SERIAL;
        workDetailLine.SVMXC__Posted_To_Inventory__c = false;
        stockConsumptionWrapperRec = new StockConsumptionWrapper(
             workDetailLine,null,null,null,null,false,false,false,null);
      }
    }else{
      //No Stock Serial found. Hence could not proceed consumption
      ilib_LogEvent.info('VanStockUtility : Stock Serial List is Empty');
      workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_NO_STOCK_SERIAL_FOUND;
      workDetailLine.SVMXC__Posted_To_Inventory__c = false;
      stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,null,null,null,null,false,false,false,null);
    }
    ilib_LogEvent.info('stockConsumptionWrapperRec-->: '+stockConsumptionWrapperRec);//CMSI-69
    ilib_LogEvent.pop();//CMSI-69   
    return stockConsumptionWrapperRec;
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleNonSerializedProductStockConsumption
  *  Parameter   : SVMXC__Service_Order_Line__c workDetailLine -- Work Details from which consumption needs to happen
  *                SVMXC__Product_Stock__c productStockRecord -- Product Stock Reorod from which consumption needs to happen
  *  Returns     : StockConsumptionWrapper -- Wrapper class giving part consumption variables
  *  Description : This method performs Serialized Product Stock Consumption
  *                If the given work details, product stock and stock serial are good, then it will perform following:-
  *                  a. Update Product Stock --> Reduce Qty by Qty Cosnumed
  *                  b. Update Work Detail --> Add Consumed Status as "Success", Mark Post to Inventory to True and Status to Completed
  *                  c. Create Stock History Record referring Work Detail and Product Stock
  *                Following Messages are given for error conditions:-
  *                ------------------------------------------------------------------------------------------------------------------------
  *                       ERROR CONDITION                              |      MESSAGE
  *                ------------------------------------------------------------------------------------------------------------------------
  *                a. When Product Stock Qty is less than Zero         | Product Stock has available Qty less than Zero     
  *                ------------------------------------------------------------------------------------------------------------------------
  *                b. When Qty consumed on work detail greater than    | Qty consumed on Work Detail is more than available Qty at 
  *                   on Product Stock Record found                    | Product Stock                                                                
  *                ------------------------------------------------------------------------------------------------------------------------                      
  *******************************************************************************************************************************************/  
  @TestVisible private StockConsumptionWrapper handleNonSerializedProductStockConsumption(SVMXC__Service_Order_Line__c workDetailLine,
                                          SVMXC__Product_Stock__c productStockRecord, SVMXC__Product_Stock__c consumedProductStock){
    ilib_LogEvent.push(LOG_TITLE + '.handleNonSerializedProductStockConsumption()');//CMSI-69
    ilib_LogEvent.info('setOfAccIds-->: '+workDetailLine);//CMSI-69
    ilib_LogEvent.info('setOfAccIds-->: '+productStockRecord);//CMSI-69
    ilib_LogEvent.info('setOfAccIds-->: '+consumedProductStock);//CMSI-69
    StockConsumptionWrapper stockConsumptionWrapperRec = null;
    boolean isCreateConsumedProductStock = false;

    //Check if the Product Stock Record found has quantity less than zero
    if(productStockRecord != null && productStockRecord.SVMXC__Quantity2__c != null && 
              productStockRecord.SVMXC__Quantity2__c > 0){
        //Check if the qty consumed on work detail is avaialble on Product Stock Record found 
        if(workDetailLine.SVMXC__Actual_Quantity2__c <= productStockRecord.SVMXC__Quantity2__c ){
          Double beforeChangeQty = productStockRecord.SVMXC__Quantity2__c;


          //Create consumed product stock if not found
          if(consumedProductStock == null){
            consumedProductStock = new SVMXC__Product_Stock__c();
            consumedProductStock.SVMXC__Product__c = productStockRecord.SVMXC__Product__c;
            consumedProductStock.SVMXC__Location__c = productStockRecord.SVMXC__Location__c;
            consumedProductStock.SVMXC__Status__c = CONSUMED_STATUS;
            consumedProductStock.SVMXC__Quantity2__c = 0;
            isCreateConsumedProductStock = true;
          }

          //Decrease the Product Stock
          if(isProductStockDecrementAllowed){
            productStockRecord.SVMXC__Quantity2__c -= workDetailLine.SVMXC__Actual_Quantity2__c;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not decrement Product Stock');
          }

           //Adjust the consumed product stock record
          if(isProductStockDecrementAllowed && consumedProductStock.SVMXC__Quantity2__c != null){
            consumedProductStock.SVMXC__Quantity2__c += workDetailLine.SVMXC__Actual_Quantity2__c;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not decrement Product Stock');
          }

          ilib_LogEvent.info('VanStockUtility : Consumption Successful');
          workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + SUCCESS_MSG_FOR_PART_CONSUMPTION;
          workDetailLine.SVMXC__Posted_To_Inventory__c = True;
          workDetailLine.SVMXC__Line_Status__c = 'Closed';

          SVMXC__Stock_History__c stockHistory = null;
          if(isMaintainStockHistoryAllowed){
            //Create Stock history record
            stockHistory = new SVMXC__Stock_History__c();
            stockHistory.SVMXC__Change_Type__c = 'Decrease';
            stockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
            stockHistory.SVMXC__Date_Changed__c = System.Now();
            stockHistory.SVMXC__Product__c = productStockRecord.SVMXC__Product__c;
            stockHistory.SVMXC__Product_Stock__c = productStockRecord.Id;
            stockHistory.SVMXC__From_Product_Stock__c = productStockRecord.Id;
            stockHistory.SVMXC__To_Product_Stock__c = consumedProductStock.Id;
            stockHistory.SVMXC__Location__c = productStockRecord.SVMXC__Location__c;
            stockHistory.SVMXC__Quantity_before_change2__c = beforeChangeQty;
            stockHistory.SVMXC__Status__c = 'Consumed'; 
            stockHistory.SVMXC__Transaction_Type__c = 'SVO Usage';
            stockHistory.SVMXC__Service_Order_Line__c = workDetailLine.Id;
            stockHistory.SVMXC__Service_Order__c = workDetailLine.SVMXC__Service_Order__c;
            stockHistory.SVMXC__Product_Serial__c = null;
            stockHistory.SVMXC__Transaction_Quantity2__c = workDetailLine.SVMXC__Actual_Quantity2__c;
            stockHistory.SVMXC__Quantity_after_change2__c = productStockRecord.SVMXC__Quantity2__c;
            stockHistory.RecordTypeId = stockHistoryRecordTypeId;
          }else{
            ilib_LogEvent.info('VanStockUtility : Do not maintain Stock History');
          }

          if(isCreateIPFromNonSerialized && workDetailLine.SVMX_PS_VS_Is_Create_Install_Product__c){
            ilib_LogEvent.info('VanStockUtility : IP to be created');
            stockConsumptionWrapperRec = new StockConsumptionWrapper(
                workDetailLine,productStockRecord,consumedProductStock,null,stockHistory,
                      true,true,isCreateConsumedProductStock,null);
          }else{ 
            ilib_LogEvent.info('VanStockUtility : No IP to be created');
            stockConsumptionWrapperRec = new StockConsumptionWrapper(
                workDetailLine,productStockRecord,consumedProductStock,null,stockHistory,
                      false,true,isCreateConsumedProductStock,null);
          }
          
        }else{
          //the qty consumed on work detail greater than on Product Stock Record found. Hence could not proceed consumption 
          ilib_LogEvent.info('VanStockUtility : ' + ERROR_MSG_FOR_QTY_LESS);
          workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_QTY_LESS;
          workDetailLine.SVMXC__Posted_To_Inventory__c = false;
          stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,null,null,null,null,false,false,false,null);
        }
      }else{
        //the Product Stock Record found has quantity less than zero. Hence could not proceed consumption
        ilib_LogEvent.info('VanStockUtility : ' + ERROR_MSG_FOR_QTY_LESS_THAN_ZERO);
        workDetailLine.SVMX_PS_VS_Consumed_Status__c = System.Now() + ERROR_MSG_FOR_QTY_LESS_THAN_ZERO;
        workDetailLine.SVMXC__Posted_To_Inventory__c = false;
        stockConsumptionWrapperRec = new StockConsumptionWrapper(
              workDetailLine,null,null,null,null,false,false,false,null);
      }
      ilib_LogEvent.info('stockConsumptionWrapperRec-->: '+stockConsumptionWrapperRec);//CMSI-69
      ilib_LogEvent.pop();//CMSI-69  
    return stockConsumptionWrapperRec;
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleStockOutProcess
  *  Parameter   : SVMXC__Service_Order_Line__c workDetailLine -- Work Details from which part out needs to happen
  *  Returns     : --
  *  Description : This method handles the Part Out Process
  *                Following is the sequence of activities:-
  *                 a. Check if data is provided for Part Out Process. The field "Is Part Out" needs to be checked
  *                    Two ways to provide data are:-
  *                    i. "Return Installed Product" field populated or 
  *                   ii. "Return Part", "Return Serial Number"(if Serialzed)/"Returned Qty"(if Non-Serialzed)
  *                 b. For #1, we get the IP immediately, For #2, use "Return Part" and "Return Serial Number to get IP
  *                 c. If Restocking allowed, check the location for restocking
  *                 d. This could be provided directly using field "To Location" or Specifying Technician
  *                    Code will find the Technician's Inventory Location
  *                 e. Now, we have the all data for Restocking 
  *                     Return Part, Return Serial Number/Return Qty, Return Location(To Location)
  *                 f. Now check if Product Stock exists for that Return Part at the Return Location
  *                 g. If yes, then update that Product Stock and create a new Stock Serial (this would only be if serialzed)
  *                 h. If no, then create a new Product Stock and create a new Stock Serial (this would only be if serialzed)
  *                 i. Create a Stock History record
  *                 Following Messages are given for error conditions:-
  *                ------------------------------------------------------------------------------------------------------------------------
  *                       ERROR CONDITION                              |      MESSAGE
  *                ------------------------------------------------------------------------------------------------------------------------
  *                Could not locate the Installed Product Record which | Installed Product supplied is not valid for Part Out Process
  *                is provided in "Return Installed Product" field     |
  *                ------------------------------------------------------------------------------------------------------------------------
  *                Data provided is only Return Part but as product is | Need Serial Number for Part Out Process as Product is Serialized
  *                Serialzed, we need Serial Number also               |
  *                ------------------------------------------------------------------------------------------------------------------------
  *                No fields are populated with data so that Part Out  | No data provided for Part Out Process
  *                Process can be performed
  *                ------------------------------------------------------------------------------------------------------------------------
  *                No field are populated with data so that Restocking | No data provided for Restocking in Part Out Process
  *                can be done                                         |
  *                ------------------------------------------------------------------------------------------------------------------------
  *                When Part is non-serialzed and Return Qty is null or| Return Qty is needed
  *                less than zero
  *                ------------------------------------------------------------------------------------------------------------------------
  *                Unable to locate the Restocking loction using the   | Could not find Restocking Location in Part Out Process
  *                data provided
  *                ------------------------------------------------------------------------------------------------------------------------
  *                Unable to find the Return Part Id, Return Serial    | No Could not find Data for Restocking in Part Out Process
  *                Number (if serialzed)/Return Qty(if non-Serliazed)  |
  *                ------------------------------------------------------------------------------------------------------------------------
  *******************************************************************************************************************************************/  
  @TestVisible private List<StockConsumptionWrapper> handleStockOutProcess(List<SVMXC__Service_Order_Line__c> workDetailList){
    ilib_LogEvent.push(LOG_TITLE + '.handleStockOutProcess()');//CMSI-69
    ilib_LogEvent.info('VanStockUtility : Starting Stock Out Process');
    //List of Valid Work Details for Stock Out Process
    List<SVMXC__Service_Order_Line__c> validWorkOrderLineList = new List<SVMXC__Service_Order_Line__c>();
    //Set to store Installed Product Id's
    Set<Id> installedProductIdSet = new Set<Id>();
    //Set to store Product Id's to be used to query associated Installed Product
    Set<Id> productIdSet = new Set<Id>();
    //Set to store Serial No's to be used to query associated Installed Product
    Set<String> serialNoIdSet = new Set<String>();
    //Set to store To Locations Id
    Set<Id> toLocationIdSet = new Set<Id>();
     //Set to store To Locations Id
    Set<Id> technicianIdSet = new Set<Id>();
    //Map of Installed Products queried where Id of IP as Key and IP record as value
    Map<Id,SVMXC__Installed_Product__c> idinstalledProductRecMap = null;
    //Map of Technician Id and Location Id 
    Map<Id,Id> technicianLocationMap = new Map<Id,Id>();
    //Map of Location Id and List of Product Stock
    Map<Id,List<SVMXC__Product_Stock__c>> locationProductStockMap = new Map<Id,List<SVMXC__Product_Stock__c>>();
    //List to store the stock consumption wrapper for commiting changes
    List<StockConsumptionWrapper> stockConsumptionWrapperList = new List<StockConsumptionWrapper>();

    if(workDetailList != null && workDetailList.size() > 0){
      //Capture data to find out associated IP's and Product Stocks
      for(SVMXC__Service_Order_Line__c workDetailLine : workDetailList){
        if(workDetailLine.SVMX_PS_VS_Is_Part_Out__c) {
          ilib_LogEvent.message('VanStockUtility : Line ' + workDetailLine.Name +' is valid for Stock Out');
          validWorkOrderLineList.add(workDetailLine);

          if(workDetailLine.SVMX_PS_VS_Return_Installed_Product__c != null){
            installedProductIdSet.add(workDetailLine.SVMX_PS_VS_Return_Installed_Product__c);
          }

          if(workDetailLine.SVMX_PS_VS_Return_Part__c != null){
            productIdSet.add(workDetailLine.SVMX_PS_VS_Return_Part__c);
          }
          
          if(workDetailLine.SVMX_PS_VS_Return_Serial_Number__c != null){
            serialNoIdSet.add( workDetailLine.SVMX_PS_VS_Return_Serial_Number__c);
          }

          if(isRestockingOfPartOut){
            if(workDetailLine.SVMXC__Requested_Location__c != null){
              toLocationIdSet.add(workDetailLine.SVMXC__Requested_Location__c);
            }else if(workDetailLine.SVMXC__Group_Member__c != null){
              technicianIdSet.add(workDetailLine.SVMXC__Group_Member__c);
            }
          }
        }
      }
      ilib_LogEvent.info('validWorkOrderLineList-->: '+UtilsCollection.getSetOfIds(validWorkOrderLineList));//CMSI-69
      ilib_LogEvent.info('installedProductIdSet-->: '+installedProductIdSet);//CMSI-69
      ilib_LogEvent.info('serialNoIdSet-->: '+serialNoIdSet);//CMSI-69
      ilib_LogEvent.info('technicianIdSet-->: '+technicianIdSet);//CMSI-69
      //Find all associated IP's and update Set of Product Ids. This set will be used to query product stock
      if(installedProductIdSet.size() > 0) {
        idinstalledProductRecMap = queryInstalledProduct(installedProductIdSet, productIdSet, serialNoIdSet);

        if(idinstalledProductRecMap != null && idinstalledProductRecMap.size() > 0){
          for(SVMXC__Installed_Product__c ip : idinstalledProductRecMap.values()){
            productIdSet.add(ip.SVMXC__Product__c);
          }
          ilib_LogEvent.info('productIdSet-->: '+productIdSet);//CMSI-69
        }
      }

      //find inventory locations of Technicians and update our set of ToLocations.
      if(technicianIdSet != null && technicianIdSet.size() > 0){
        technicianLocationMap = queryInventoryLocations(technicianIdSet);

        if(technicianLocationMap != null && technicianLocationMap.size() > 0){
          for(Id locationId : technicianLocationMap.values()){
            toLocationIdSet.add(locationId);
          }
        }
        ilib_LogEvent.info('toLocationIdSet-->: '+toLocationIdSet);//CMSI-69
      }

      if(toLocationIdSet.size() > 0 && productIdSet.size() > 0){
        List<SVMXC__Product_Stock__c> productStockList = [SELECT Id,Name,SVMXC__Allocated_Qty__c,SVMXC__Available_Qty__c,
                                                              SVMXC__Location__c,SVMXC__Product__c,SVMXC__Quantity2__c,
                                                              SVMXC__Product__r.SVMXC__Stockable__c,SVMXC__Product__r.SVMXC__Tracking__c, 
                                                              SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c 
                                                          FROM SVMXC__Product_Stock__c WHERE SVMXC__Location__c IN :toLocationIdSet
                                                          AND SVMXC__Product__c IN: productIdSet 
                                                          AND SVMXC__Status__c = :AVAILABLE_STATUS];
        
        ilib_LogEvent.info('productStockList-->: '+UtilsCollection.getSetOfIds(productStockList));//CMSI-69
        if(productStockList != null && productStockList.size() > 0){
          for(SVMXC__Product_Stock__c productStock : productStockList){
            List<SVMXC__Product_Stock__c> locationProductStockList = locationProductStockMap.get(productStock.SVMXC__Location__c);
            if(locationProductStockList == null){
              locationProductStockList = new List<SVMXC__Product_Stock__c>();
              locationProductStockMap.put(productStock.SVMXC__Location__c,locationProductStockList);
            }
            locationProductStockList.add(productStock);
            ilib_LogEvent.message('locationProductStockList-->: '+productStock.Id);//CMSI-69
          }
         
        }else{
          ilib_LogEvent.info('VanStockUtility : No Product Stock Found while Part Out Process');
        }
      }else{
        ilib_LogEvent.info('VanStockUtility : Unable to locate any Product Stock while Part Out Process ' + 
                              'as no location or product info provided');
      }

      for(SVMXC__Service_Order_Line__c workDetailLine : validWorkOrderLineList){
        if(workDetailLine.SVMX_PS_VS_Part_Out_Status__c == null || !workDetailLine.SVMX_PS_VS_Part_Out_Status__c.contains('Consumption Success : Part Out Successful')){
          if(workDetailLine.SVMX_PS_VS_Is_Part_Out__c){
            ilib_LogEvent.message('VanStockUtility : Start Part Out Process -' + workDetailLine.Name);
            
            Id returnedPartId = null;
            String returnedSerialNumber = null;
            Double returnedQty = null;
            SVMXC__Installed_Product__c returnedIP = null;
            Id returnLocationId = null;
            boolean isErrorFound = false;

            if(workDetailLine.SVMX_PS_VS_Return_Installed_Product__c != null){
              ilib_LogEvent.message('VanStockUtility : Given for return is Installed Product -' + 
                  workDetailLine.SVMX_PS_VS_Return_Installed_Product__c);
              
              SVMXC__Installed_Product__c queriedIP = null;
              
              if(idinstalledProductRecMap != null && idinstalledProductRecMap.size() > 0){
               queriedIP = idinstalledProductRecMap.get(workDetailLine.SVMX_PS_VS_Return_Installed_Product__c);
              }else{
                ilib_LogEvent.message('VanStockUtility : No IP found');
              }
              
              if(queriedIP != null){
                returnedPartId = queriedIP.SVMXC__Product__c;
                returnedSerialNumber = queriedIP.SVMXC__Serial_Lot_Number__c;
                returnedIP = queriedIP;
                returnedQty = null;
              }else{
                isErrorFound = true;
                workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + ERROR_MSG_NO_IP_FOUND;
                workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                workDetailLine.SVMXC__Line_Status__c = OPEN_LINE_STATUS;
                StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,null,false);
                stockConsumptionWrapperList.add(stockConsumptionWrapper);
                ilib_LogEvent.message('VanStockUtility : ' + ERROR_MSG_NO_IP_FOUND);
              }

            }else if(workDetailLine.SVMX_PS_VS_Return_Part__c != null){
              ilib_LogEvent.message('VanStockUtility : Given for return is Product -' + workDetailLine.SVMX_PS_VS_Return_Part__c);

              //Check if the product is serialized/lot tracked and serial number is provided
              if(workDetailLine.SVMX_PS_VS_Return_Part__r.SVMXC__Tracking__c.equals('Serialized') ||
                  workDetailLine.SVMX_PS_VS_Return_Part__r.SVMXC__Enable_Serialized_Tracking__c ||
                  workDetailLine.SVMX_PS_VS_Return_Part__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                  
                    ilib_LogEvent.message('VanStockUtility : Given for return is Serialized Product');
                  
                  if(workDetailLine.SVMX_PS_VS_Return_Serial_Number__c != null){
                    returnedPartId = workDetailLine.SVMX_PS_VS_Return_Part__c;
                    returnedSerialNumber = workDetailLine.SVMX_PS_VS_Return_Serial_Number__c;
                    returnedQty = null;

                    if(idinstalledProductRecMap != null && idinstalledProductRecMap.size() > 0){
                      for(SVMXC__Installed_Product__c installedProduct : idinstalledProductRecMap.values()){
                        if(installedProduct.SVMXC__Product__c == workDetailLine.SVMX_PS_VS_Return_Part__c &&
                          installedProduct.SVMXC__Serial_Lot_Number__c == workDetailLine.SVMX_PS_VS_Return_Serial_Number__c){
                          returnedIP = installedProduct;
                        }
                      }
                    }
                  }else{
                    isErrorFound = true;
                    workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + ERROR_MSG_NEED_SERIAL_NO;
                    workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                    workDetailLine.SVMXC__Line_Status__c = OPEN_LINE_STATUS;
                    StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,null,false);
                    stockConsumptionWrapperList.add(stockConsumptionWrapper);
                    ilib_LogEvent.message('VanStockUtility : ' + ERROR_MSG_NEED_SERIAL_NO);
                  }
              }else{
                //This is Non-Serialzed Part
                ilib_LogEvent.message('VanStockUtility : Given for return is Non-Serialized Product');

                if(workDetailLine.SVMX_PS_VS_Returned_Qty__c > 0){
                  ilib_LogEvent.message('VanStockUtility : Given for return Qty for Non-Serialized Product'
                             + workDetailLine.SVMX_PS_VS_Returned_Qty__c );

                  returnedPartId = workDetailLine.SVMX_PS_VS_Return_Part__c;
                  returnedQty = workDetailLine.SVMX_PS_VS_Returned_Qty__c;
                  returnedSerialNumber = null;
                }else{
                  isErrorFound = true;
                  workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + ERROR_MSG_NEED_RETURN_QTY;
                  workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                  workDetailLine.SVMXC__Line_Status__c = OPEN_LINE_STATUS;
                  StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,null,false);
                  stockConsumptionWrapperList.add(stockConsumptionWrapper);
                  ilib_LogEvent.message('VanStockUtility : ' + ERROR_MSG_NEED_RETURN_QTY);
                }
              }
            }else{
              isErrorFound = true;
              workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + ERROR_MSG_NO_DATA_PROVIDED_FOR_PART_OUT;
              workDetailLine.SVMXC__Posted_To_Inventory__c = false;
              workDetailLine.SVMXC__Line_Status__c = 'Closed';
              StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,null,false);
              stockConsumptionWrapperList.add(stockConsumptionWrapper);
              ilib_LogEvent.message('VanStockUtility : ' + ERROR_MSG_NO_DATA_PROVIDED_FOR_PART_OUT);
            }

            //Handle Return Re-Stocking
            if(!isErrorFound){
              if(isRestockingOfPartOut){
                if(returnedPartId != null && (returnedSerialNumber != null || returnedQty != null)){
                  //Find the returned location
                  //This could be provided directly or could be Technician's Inventory Location
                  if(workDetailLine.SVMXC__Requested_Location__c != null){
                    returnlocationId = workDetailLine.SVMXC__Requested_Location__c;
                  }else if(workDetailLine.SVMXC__Group_Member__c != null){
                    if(technicianLocationMap != null && technicianLocationMap.size() > 0 &&
                      technicianLocationMap.containsKey(workDetailLine.SVMXC__Group_Member__c)){
                      returnLocationId = technicianLocationMap.get(workDetailLine.SVMXC__Group_Member__c);
                    }else{
                      ilib_LogEvent.message('VanStockUtility : No Inventory Location associated with Technician');
                    }
                  }else{
                    workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + ERROR_MSG_COULD_NOT_FIND_RESTOCKING_LOC;
                    workDetailLine.SVMXC__Posted_To_Inventory__c = false;
                    workDetailLine.SVMXC__Line_Status__c = OPEN_LINE_STATUS;
                    StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,null,false);
                    stockConsumptionWrapperList.add(stockConsumptionWrapper);
                    ilib_LogEvent.message('VanStockUtility :' + ERROR_MSG_COULD_NOT_FIND_RESTOCKING_LOC);
                  }

                  if(returnLocationId != null){
                    SVMXC__Product_Stock__c tobeUpdatedProductStock = null;
                    //Find the product stock associated with the returned location
                    List<SVMXC__Product_Stock__c> productStockList = locationProductStockMap.get(returnLocationId);
                    if(productStockList != null && productStockList.size() > 0){
                      for(SVMXC__Product_Stock__c productStock : productStockList){
                        if(productStock.SVMXC__Product__c != null &&
                            productStock.SVMXC__Product__c == returnedPartId){
                          tobeUpdatedProductStock = productStock;
                          break;
                        }
                      }
                    }else{
                      ilib_LogEvent.message('VanStockUtility : No Product Stock Found. Create new one');
                    }

                    workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + SUCCESS_PART_OUT_PROCESS;
                    ilib_LogEvent.message('VanStockUtility :' + SUCCESS_PART_OUT_PROCESS);

                    if(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c != null || 
                      ((workDetailLine.SVMXC__Consumed_From_Location__c != null || workDetailLine.SVMXC__Group_Member__c != null)
                      && workDetailLine.SVMXC__Product__c != null)){
                        ilib_LogEvent.message('VanStockUtility : Do not update post to inventory flag as this ' + 
                                      'has been updated by Part Consumption');
                    }else{
                      ilib_LogEvent.message('VanStockUtility : Update post to inventory flag as this is ' + 
                                      'Part out line only');
                      workDetailLine.SVMXC__Posted_To_Inventory__c = true;
                      workDetailLine.SVMXC__Line_Status__c = 'Closed';
                    }
                    
                    StockConsumptionWrapper stockConsumptionWrapper = handleRestocking(tobeUpdatedProductStock,returnedPartId,
                                                                              returnedSerialNumber,returnedQty,workDetailLine,
                                                                              returnedIP,returnLocationId);

                    if(stockConsumptionWrapper != null){
                      stockConsumptionWrapperList.add(stockConsumptionWrapper);
                    }
                  }else{
                    ilib_LogEvent.message('VanStockUtility : Unable to located return location');
                  }
                }else{
                  ilib_LogEvent.message('VanStockUtility : ' + ERROR_MSG_NO_DATA_PROVIDED_FOR_PART_OUT);
                }
              }else{
                //No Restocking required.
                ilib_LogEvent.message('VanStockUtility : No Restocking requried');
                workDetailLine.SVMX_PS_VS_Part_Out_Status__c = System.Now() + SUCCESS_PART_OUT_PROCESS_NO_RESTOCKING;

                if(returnedIP != null){
                  returnedIP.SVMXC__Status__c = removedIPStatus;
                  SVMXC__Installed_Product__c updatedIP = SVMX_PS_VS_VanStockHookHandler.hookForReturnedIPUpdate(returnedIP);

                  if(updatedIP != null){
                    returnedIP = updatedIP;
                  }
                }
                
                StockConsumptionWrapper stockConsumptionWrapper = new StockConsumptionWrapper(workDetailLine,null,null,null,returnedIP,false);
                stockConsumptionWrapperList.add(stockConsumptionWrapper);
                ilib_LogEvent.message('VanStockUtility : ' + SUCCESS_PART_OUT_PROCESS_NO_RESTOCKING);
              }
            }else{
              ilib_LogEvent.message('VanStockUtility : Error Detected earlier. Hence no success');
            }
          }else{
            ilib_LogEvent.message('VanStockUtility : No Part is out. Hence ignore Work Detail ' + workDetailLine.Name);
          }
        }else{
          //Part Out Process is already done
          ilib_LogEvent.message('VanStockUtility : For Work Detail Line ' + workDetailLine.Name + ', Part Out has already happened');
        }
        ilib_LogEvent.message('VanStockUtility : End of Part Out Process -' + workDetailLine.Name);
      }
      //End of For Loop of Work Details
      ilib_LogEvent.info('stockConsumptionWrapperList-->: '+stockConsumptionWrapperList);//CMSI-69
      //Store List to call
      if(stockConsumptionWrapperList.size() > 0){
        List<SVMXC__Installed_Product__c> ipList = new List<SVMXC__Installed_Product__c>();
        Map<Id,StockConsumptionWrapper> ipIdStockConsumptionWrapperMap = new Map<Id,StockConsumptionWrapper> ();
        for(StockConsumptionWrapper stockConsumptionWrapper : stockConsumptionWrapperList){
          if(stockConsumptionWrapper.getInstalledProduct() != null){
            ipList.add(stockConsumptionWrapper.getInstalledProduct());
            ipIdStockConsumptionWrapperMap.put(stockConsumptionWrapper.getInstalledProduct().Id,stockConsumptionWrapper);
          }
        }

        ipList = null;
        ipList = SVMX_PS_VS_VanStockHookHandler.hookForReturnedIPListUpdate(ipList);
        ilib_LogEvent.info('ipList-->: '+UtilsCollection.getSetOfIds(ipList));//CMSI-69
        if(ipList != null){
          for(SVMXC__Installed_Product__c installedProduct : ipList){
            StockConsumptionWrapper stockConsumptionWrapper = ipIdStockConsumptionWrapperMap.get(installedProduct.Id);
            if(stockConsumptionWrapper != null){
              stockConsumptionWrapper.setInstalledProduct(installedProduct);
            }
          }
        }
      }

      ilib_LogEvent.info('VanStockUtility : Commit changes to Database for Part Out');
      partOutProcessCommitChanges(stockConsumptionWrapperList);
      ilib_LogEvent.info('VanStockUtility : Committed changes to Database for Part Out');
    }else{
      ilib_LogEvent.info('VanStockUtility : No Work Details for Part Stock Out Process');
    }

    ilib_LogEvent.info('VanStockUtility : End Part Out Process');
    ilib_LogEvent.pop();//CMSI-69
    return stockConsumptionWrapperList;
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryInstalledProduct
  *  Parameter   : Set<Id> installedProductIdSet -- Set of Installed Product Id's which are needed for part out process
  *                Set<Id> productIdSet -- Set of Returned Part Id's which are needed for part out process
  *                Set<String> serialNoIdSet  -- Set of Returned Serial Numbers which are needed for part out process
  *  Returns     : Map<Id,SVMXC__Installed_Product__c> -- Map of Installed Product Id as key and Record as value of all Queried IP's
  *  Description : This method finds all relevant Installed Products which is needed for part out process
  *                We currently could have following data:-
  *                 a. The Installed Produc Id is given directly
  *                 b. The Returned Part and Returned Serial Number is given which can give relevant Installed Product
  *******************************************************************************************************************************************/  
  @TestVisible private Map<Id,SVMXC__Installed_Product__c> queryInstalledProduct (Set<Id> installedProductIdSet,
                                                            Set<Id> productIdSet, Set<String> serialNoIdSet){
    ilib_LogEvent.push(LOG_TITLE + '.queryInstalledProduct()');//CMSI-69      
    ilib_LogEvent.info('installedProductIdSet-->: '+installedProductIdSet);//CMSI-69
    ilib_LogEvent.info('productIdSet-->: '+productIdSet);//CMSI-69
    ilib_LogEvent.info('serialNoIdSet-->: '+serialNoIdSet);//CMSI-69                                                    
    ilib_LogEvent.info('VanStockUtility : Start Query Installed Product Process');

    //Map of Installed Products found
    Map<Id,SVMXC__Installed_Product__c> idInstalledProductRecMap = new Map<Id,SVMXC__Installed_Product__c> ();
    
    //Create Query String for all Installed Product Id's available
    String ipIdString = null;
    if(installedProductIdSet != null || installedProductIdSet != null){
      ipIdString = createQueryStringUsingList('Id', installedProductIdSet);
    }

    //Create Query String for all Product Id available
    String productIdString = null;
    if(productIdSet != null && productIdSet.size() > 0){
      productIdString = createQueryStringUsingList('SVMXC__Product__c', productIdSet);
    }

    //Create Query String for all Serial No's Id available
    String serialNoIdString = null;
    if(serialNoIdSet != null && serialNoIdSet.size() > 0){
      serialNoIdString = 'SVMXC__Serial_Lot_Number__c IN (';
      for(String serialName : serialNoIdSet){
        serialNoIdString += '\'' + serialName + '\',';
      }
      serialNoIdString = serialNoIdString.substring(0,serialNoIdString.length()-1);
      serialNoIdString += ')';
    }

    //Create Installed Product Query
    String installedProductQueryString = 'SELECT Id, Name, SVMXC__Company__c, SVMXC__City__c, SVMXC__Country__c, '+ 
                                        'SVMXC__Site__c, SVMXC__Product__c, SVMXC__Serial_Lot_Number__c, '+ 
                                        'SVMXC__State__c, SVMXC__Status__c, SVMXC__Street__c, SVMXC__Zip__c '+ 
                                        'FROM SVMXC__Installed_Product__c ';
    if(ipIdString != null){
      installedProductQueryString += ' WHERE ' + ipIdString;

      if(productIdString != null && serialNoIdString != null){
        installedProductQueryString += ' OR (' + productIdString + ' AND ' + serialNoIdString + ')';
      }
    }else if(productIdString != null && serialNoIdString != null){
      installedProductQueryString += ' WHERE ' + productIdString + ' AND ' + serialNoIdString;
    }

    try{
      List<SVMXC__Installed_Product__c> installedProductList =Database.query(installedProductQueryString);

      if(installedProductList != null && installedProductList.size() > 0){
        for(SVMXC__Installed_Product__c installedProduct : installedProductList){
          idInstalledProductRecMap.put(installedProduct.Id, installedProduct);
        }
        ilib_LogEvent.info('idInstalledProductRecMap' +  idInstalledProductRecMap);//CMSI-69
      }
    }catch(Exception exceptionRecord){ 
      ilib_LogEvent.info('VanStockUtility : Could not query Installed Products - ' + exceptionRecord.getMessage());
    }

    ilib_LogEvent.info('VanStockUtility : End Query Installed Product Process');
    ilib_LogEvent.pop();//CMSI-69
    return idInstalledProductRecMap;
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleRestocking
  *  Parameter   : SVMXC__Product_Stock__c> tobeUpdatedProductStock - Product Stock if found and needs to be updated else null
  *                Id returnedPart - Id of the Product which needs to be restocked
  *                String serialNumber- If serialzed product, then serial number else null
  *                Double returnedQty - If non-serialzed product, then returned qty else null
  *                SVMXC__Service_Order_Line__c workDetailLine -  Work Details from which restocking needs to happen
  *                SVMXC__Installed_Product__c returnedIP - Installed Product Record which needs to be restocked as Product Stock
  *                Id returnedLocation = Id of the Location to which product needs to be restocked
  *  Returns     : StockConsumptionWrapper - Wrapper which stores updated/created Product Stock, created Stock Serial, 
  *                                          to be created Stock History record and updated Installed Product record
  *  Description : This method performs Restocking of Part Out
  *                Already determination of which Product Stock needs to be updated is done
  *                In this method, following tasks are performed
  *                  a. If Product Stock Found and is Serialzed, update Qty by 1 and create new Stock Serial
  *                  b. If Product Stock Found and is Non-Serialzed, update Qty by returned Qty 
  *                  c. Then, create Stock History record    
  *                  d. If any IP provided, then update the IP Status as "De-Installed" and call hook to update fields          
  *******************************************************************************************************************************************/  
  @TestVisible private StockConsumptionWrapper handleRestocking(SVMXC__Product_Stock__c tobeUpdatedProductStock, Id returnedPart, String serialNumber,
                                                Double returnedQty, SVMXC__Service_Order_Line__c workDetailLine, SVMXC__Installed_Product__c returnedIP,
                                                Id returnedLocation){
    ilib_LogEvent.push(LOG_TITLE + '.handleRestocking()');//CMSI-69
    ilib_LogEvent.info('tobeUpdatedProductStock-->: '+tobeUpdatedProductStock);//CMSI-69
    ilib_LogEvent.info('returnedPart-->: '+returnedPart);//CMSI-69
    ilib_LogEvent.info('serialNumber-->: '+serialNumber);//CMSI-69
    ilib_LogEvent.info('returnedQty-->: '+returnedQty);//CMSI-69
    ilib_LogEvent.info('workDetailLine-->: '+workDetailLine);//CMSI-69
    ilib_LogEvent.info('returnedIP-->: '+returnedIP);//CMSI-69
    ilib_LogEvent.info('returnedLocation-->: '+returnedLocation);//CMSI-69

    boolean isCreateProductStock = false;
    SVMXC__Product_Serial__c tobeCreatedStockSerial = null;
    SVMXC__Stock_History__c stockHistory = null;

    if(tobeUpdatedProductStock == null){
      tobeUpdatedProductStock = new SVMXC__Product_Stock__c();
      tobeUpdatedProductStock.SVMXC__Product__c = returnedPart;
      tobeUpdatedProductStock.SVMXC__Location__c = returnedLocation;
      tobeUpdatedProductStock.SVMXC__Status__c = AVAILABLE_STATUS;
      isCreateProductStock = true;
    }else{
      ilib_LogEvent.info('VanStockUtility : No New Product Stock to be created');
    }

    if(serialNumber != null){
      if(tobeUpdatedProductStock.SVMXC__Quantity2__c != null){
        tobeUpdatedProductStock.SVMXC__Quantity2__c += 1;
      }else{
        tobeUpdatedProductStock.SVMXC__Quantity2__c = 1;
      }
      
      //Create new Stock Serial record
      if(tobeUpdatedProductStock.Id != null){
        tobeCreatedStockSerial = new SVMXC__Product_Serial__c();
        tobeCreatedStockSerial.SVMXC__Product_Stock__c = tobeUpdatedProductStock.Id;
        tobeCreatedStockSerial.SVMXC__Product__c = tobeUpdatedProductStock.SVMXC__Product__c;
        tobeCreatedStockSerial.SVMXC__Active__c = True;
        tobeCreatedStockSerial.Name = serialNumber;
        //ADDED BY SMAX - NOV-15-2018 - TO SUPPORT STOCK SERIAL INSTALL PRODUCT LINK
        tobeCreatedStockSerial.SVMX_PS_VS_Linked_Installed_Product__c = returnedIP.Id;
      }
    }else if(returnedQty != null){
      if(tobeUpdatedProductStock.SVMXC__Quantity2__c != null){
        tobeUpdatedProductStock.SVMXC__Quantity2__c += returnedQty;
      }else{
        tobeUpdatedProductStock.SVMXC__Quantity2__c = returnedQty;
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : No Proper data provided for restocking');
    }

    if(isMaintainStockHistoryAllowed){
      //Create Stock history record
      stockHistory = new SVMXC__Stock_History__c();
      stockHistory.SVMXC__Change_Type__c = 'Increase';
      stockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
      stockHistory.SVMXC__Date_Changed__c = System.Now();
      stockHistory.SVMXC__Product__c = tobeUpdatedProductStock.SVMXC__Product__c;
      stockHistory.SVMXC__Status__c = 'Available'; 
      stockHistory.SVMXC__Transaction_Type__c = 'Stock Adjustment';
      stockHistory.SVMXC__Service_Order_Line__c = workDetailLine.Id;
      stockHistory.SVMXC__Service_Order__c = workDetailLine.SVMXC__Service_Order__c;
      stockHistory.SVMXC__Quantity_after_change2__c = tobeUpdatedProductStock.SVMXC__Quantity2__c;
      stockHistory.RecordTypeId = stockHistoryRecordTypeId;

      if(tobeUpdatedProductStock != null){
        stockHistory.SVMXC__Product_Stock__c = tobeUpdatedProductStock.Id;
      }

      if(tobeCreatedStockSerial != null){
        stockHistory.SVMXC__Product_Serial__c = tobeCreatedStockSerial.Id;
      }

      if(serialNumber != null){
        stockHistory.SVMXC__Quantity_before_change2__c = tobeUpdatedProductStock.SVMXC__Quantity2__c - 1;
        stockHistory.SVMXC__Transaction_Quantity2__c = 1;
      }else{
        stockHistory.SVMXC__Quantity_before_change2__c = tobeUpdatedProductStock.SVMXC__Quantity2__c - returnedQty;
        stockHistory.SVMXC__Transaction_Quantity2__c = returnedQty;
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : Do not maintain Stock History');
    }

    if(returnedIP != null){
      returnedIP.SVMXC__Status__c = removedIPStatus;
	  /*****Shashank: Code Added to remove the deinstalled IP from the Config hierarchy*****/
	  returnedIP.SVMXC__Parent__c = null;
	  returnedIP.SVMXC__Top_Level__c = null;
	  /*************************************************************************************/
      SVMXC__Installed_Product__c updatedIP = SVMX_PS_VS_VanStockHookHandler.hookForReturnedIPUpdate(returnedIP);

      if(updatedIP != null){
        returnedIP = updatedIP;
      }
    }
    ilib_LogEvent.pop();//CMSI-69   
    return new StockConsumptionWrapper(workDetailLine,tobeUpdatedProductStock,tobeCreatedStockSerial,stockHistory,returnedIP,isCreateProductStock);
  }

  /*****************************************************************************************************************************************
  *  Method Name : partOutProcessCommitChanges
  *  Parameter   : List<StockConsumptionWrapper> stockConsumptionWrapperList -- List storing wrapper object with all details to be committed
  *                                                                             to database
  *  Returns     : --
  *  Description : This method commits all changes in database during Part Out Process                                 
  *******************************************************************************************************************************************/  
 
  @TestVisible private void partOutProcessCommitChanges(List<StockConsumptionWrapper> stockConsumptionWrapperList){
    ilib_LogEvent.push(LOG_TITLE + '.partOutProcessCommitChanges()');//CMSI-69
    //List of Installed Products to be updated
    List<SVMXC__Installed_Product__c> installedProductToBeUpdated = new List<SVMXC__Installed_Product__c>();
    //List of Work Details to be updated
    List<SVMXC__Service_Order_Line__c> updatedWorkDetailLinesList = new List<SVMXC__Service_Order_Line__c> ();
    //List of Product Stock to be updated
    Map<Id,SVMXC__Product_Stock__c> updatedProductStockLinesMap = new Map<Id,SVMXC__Product_Stock__c> ();
    //List of Product Stock to be created
    List<SVMXC__Product_Stock__c> createProductStockLinesList = new List<SVMXC__Product_Stock__c> ();
      //List of Stock Serial to be updated
    List<SVMXC__Product_Serial__c> createdStockSerialLinesList = new List<SVMXC__Product_Serial__c> ();
    //List of Stock History to be created
    List<SVMXC__Stock_History__c> createdStockHistoryLinesList = new List<SVMXC__Stock_History__c> ();
    //Map for product stock string (string of product-location) and stock serials
    //This will be used to update the product stock id once product stock record is created
    Map<String,SVMXC__Product_Serial__c> productStockStringStockSerialMap = new Map<String,SVMXC__Product_Serial__c>();
    //Map for product stock string (string of product-location) and  stock history
    //This will be used to update the product stock id & stock serial id once product stock record & stock serial reacord is created
    Map<String,SVMXC__Stock_History__c> productStockStringStockHistoryMap = new Map<String,SVMXC__Stock_History__c>();


    for(StockConsumptionWrapper wrapper : stockConsumptionWrapperList){
      if(wrapper.getInstalledProduct() != null){
        installedProductToBeUpdated.add(wrapper.getInstalledProduct());
      }
      if(wrapper.getProductStock() != null){
        if(wrapper.getIsCreateProductStock()){
          createProductStockLinesList.add(wrapper.getProductStock());
        }else{
          updatedProductStockLinesMap.put(wrapper.getProductStock().Id,wrapper.getProductStock());
        }

        SVMXC__Product_Stock__c productStock = wrapper.getProductStock();
        String keyValue = productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c;
      
        //This is to keep link between created stock serial and product stock
        if(wrapper.getProductSerial() != null){
          createdStockSerialLinesList.add(wrapper.getProductSerial());
          productStockStringStockSerialMap.put(keyValue,wrapper.getProductSerial());
        }

         //This is to keep link between created stock history and product stock
        if(wrapper.getStockHistory() != null){
          productStockStringStockHistoryMap.put(keyValue,wrapper.getStockHistory());
          createdStockHistoryLinesList.add(wrapper.getStockHistory());
        }
      }

      if(wrapper.getWorkDetail() != null){
        updatedWorkDetailLinesList.add(wrapper.getWorkDetail());
      }
    }
    ilib_LogEvent.info('installedProductToBeUpdated-->: '+UtilsCollection.getSetOfIds(installedProductToBeUpdated));//CMSI-69
    ilib_LogEvent.info('createProductStockLinesList-->: '+UtilsCollection.getSetOfIds(createProductStockLinesList));//CMSI-69
    ilib_LogEvent.info('updatedProductStockLinesMap' + updatedProductStockLinesMap);//CMSI-69
    ilib_LogEvent.info('createdStockSerialLinesList-->: '+UtilsCollection.getSetOfIds(createdStockSerialLinesList));//CMSI-69
    ilib_LogEvent.info('createdStockHistoryLinesList-->: '+UtilsCollection.getSetOfIds(createdStockHistoryLinesList));//CMSI-69
    ilib_LogEvent.info('productStockStringStockSerialMap' + productStockStringStockSerialMap);//CMSI-69	
    ilib_LogEvent.info('productStockStringStockHistoryMap' + productStockStringStockHistoryMap);//CMSI-69
    ilib_LogEvent.info('updatedWorkDetailLinesList-->: '+UtilsCollection.getSetOfIds(updatedWorkDetailLinesList));//CMSI-69
    //Commit Changes to Database
    Savepoint savePointRec = Database.setSavepoint();

    try{
      if(createProductStockLinesList != null && createProductStockLinesList.size() > 0){
        ilib_LogEvent.info('VanStockUtility: Create new Product Stock');
        insert(createProductStockLinesList);
        ilib_LogEvent.info('VanStockUtility: Done with Create new Product Stock');

        for(SVMXC__Product_Stock__c productStock : createProductStockLinesList){
          String keyValue = productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c;
          SVMXC__Product_Serial__c stockserial = productStockStringStockSerialMap.get(keyValue);
          if(stockserial != null){
            stockserial.SVMXC__Product_Stock__c = productStock.Id;
          }
        } 
      }else{
        ilib_LogEvent.info('VanStockUtility: No New product stock created');
      }

      if(createdStockSerialLinesList != null && createdStockSerialLinesList.size() > 0){
        ilib_LogEvent.info('VanStockUtility: Create new Stock Serials');
        insert(createdStockSerialLinesList);
        ilib_LogEvent.info('VanStockUtility: Done with Create new Stock Serials');
      }

      for(SVMXC__Product_Stock__c productStock : createProductStockLinesList){
        Id stockSerialId =  null;
        
        for(SVMXC__Product_Serial__c stockSerialRecord : createdStockSerialLinesList){
          if(stockSerialRecord.SVMXC__Product_Stock__c == productStock.Id){
            stockSerialId = stockSerialRecord.Id;
            break;
          }
        }

        String keyValue = productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c;
        SVMXC__Stock_History__c stockHistory = productStockStringStockHistoryMap.get(keyValue);

        if(stockHistory != null){
          stockHistory.SVMXC__Product_Stock__c  = productStock.Id;
          stockHistory.SVMXC__Product_Serial__c  = stockSerialId;
        }
      }

      List<sObject> allObjectsList = new List<sObject>();

      if(updatedWorkDetailLinesList != null && updatedWorkDetailLinesList.size() > 0){
        List<sObject> sobjectList = (List<sObject>) updatedWorkDetailLinesList;
        allObjectsList.addAll(sobjectList);
      }else{
        ilib_LogEvent.info('VanStockUtility: No Work Details to be updated');
      }

      if(updatedProductStockLinesMap != null && updatedProductStockLinesMap.size() > 0){
        List<sObject> sobjectList = (List<sObject>) updatedProductStockLinesMap.values();
        allObjectsList.addAll(sobjectList);
      }else{
        ilib_LogEvent.info('VanStockUtility: No Product Stock to be updated');
      }

      if(installedProductToBeUpdated != null && installedProductToBeUpdated.size() > 0){
        List<sObject> sobjectList = (List<sObject>) installedProductToBeUpdated;
        allObjectsList.addAll(sobjectList);
      }else{
        ilib_LogEvent.info('VanStockUtility: No Installed Product to be updated');
      }
      if(allObjectsList.size() > 0){
        ilib_LogEvent.info('VanStockUtility: Updating Work Details, Product Stock, Stocked Serial and IP');
        Database.SaveResult[] updateResults = Database.update(allObjectsList, true);
		    ApexExceptions.emitUpdateErrorsWithRelatedRecord(updateResults, 'VanstockUtility_Update',allObjectsList);
        ilib_LogEvent.info('VanStockUtility: Done with Updation for Work Details, Product Stock, Stocked Serial and IP');
      }

      if(createdStockHistoryLinesList != null && createdStockHistoryLinesList.size() > 0){
        ilib_LogEvent.info('VanStockUtility: Creating Stock History record');
        Database.SaveResult[] results = Database.insert(createdStockHistoryLinesList, true);
		    ApexExceptions.emitSaveErrors(results, 'VanstockUtility_StockHistory_Create_partOut');
        ilib_LogEvent.info('VanStockUtility: Done with Creation of Stock History record');
      }else{
        ilib_LogEvent.info('VanStockUtility: No Stock History to be created');
      }
    }catch(Exception exceptionRecord){
      ilib_LogEvent.info('VanStockUtility: Problem while updation of records - ' + exceptionRecord.getMessage());
      Database.rollback(savePointRec);
      throw exceptionRecord;
    }
    ilib_LogEvent.pop();//CMSI-69  
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryInventoryLocations
  *  Parameter   : Set<Id> technicianList - Set of all technicians Ids for whom Inventory Location need to be found
  *  Returns     : Map<Id,Id> -- Map of Technician Id as key and Inventory Location Id as Value
  *  Description : Query and find out all Inventory Locations for Technicians whose Id is given
  *******************************************************************************************************************************************/  
  @TestVisible private Map<Id,Id> queryInventoryLocations(Set<Id> technicianList){
    ilib_LogEvent.push(LOG_TITLE + '.queryInventoryLocations()');//CMSI-69
    ilib_LogEvent.info('technicianList-->: '+technicianList);//CMSI-69
    Map<Id,Id> technicianIdInvntLocIdMap = null;
    if(technicianList != null && technicianList.size() > 0){

      technicianIdInvntLocIdMap = new Map<Id,Id> ();

      for(SVMXC__Service_Group_Members__c tech : [SELECT Id, SVMXC__Inventory_Location__c 
                                                        FROM SVMXC__Service_Group_Members__c 
                                                        WHERE Id in :technicianList]) {
          technicianIdInvntLocIdMap.put(tech.id, tech.SVMXC__Inventory_Location__c);
          ilib_LogEvent.info('VanStockUtility: Technician '+ tech.id + ' has Inventory Location - ' 
                                    + tech.SVMXC__Inventory_Location__c);
      }
    }else{
      ilib_LogEvent.info('VanStockUtility : No Technicians listed for finding Inventory Locations');
    }
    ilib_LogEvent.info('technicianIdInvntLocIdMap' +  technicianIdInvntLocIdMap);//CMSI-69
    ilib_LogEvent.pop();//CMSI-69 
    return technicianIdInvntLocIdMap;
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkIfPartConsumptionFunctionalityIsActive
  *  Parameter   : --
  *  Returns     : boolean -- true if Part Consumption is active else false
  *  Description : Check the ServiceMax Service Register and make sure that Part Consumption is Active or not.
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkIfPartConsumptionFunctionalityIsActive(){
    ilib_LogEvent.push(LOG_TITLE + '.checkIfPartConsumptionFunctionalityIsActive()');//CMSI-69
    boolean isActive = false;
    List<SVMX_PS_Services_Register__c> serviceRegistryList = SVMX_PS_Services_Register__c.getAll().values();
    if(serviceRegistryList != null && serviceRegistryList.size()>0){
      for(SVMX_PS_Services_Register__c item : serviceRegistryList){
        if(item.Name.equals(PART_CONSUMPTION_REPORT_FUNCT)){
            isActive = item.SVMX_PS_Is_Active__c;
            break;
        }
      }
    }
    ilib_LogEvent.info('isActive-->: '+isActive);//CMSI-69
    ilib_LogEvent.pop();//CMSI-69 
    return isActive;
  }

  /*****************************************************************************************************************************************
  *  Method Name : retrievePartConsumptionSetting
  *  Parameter   : --
  *  Returns     : --
  *  Description : Get All Part Consumption Settings which control the van stock functionality and store it in variables
  *******************************************************************************************************************************************/  
  @TestVisible private void retrievePartConsumptionSetting(){
    ilib_LogEvent.push(LOG_TITLE + '.retrievePartConsumptionSetting()');//CMSI-69
    List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettings = SVMX_PS_VS_Part_Consumption_Settings__c.getAll().values();
    if(partConsumptionSettings != null){
      for(SVMX_PS_VS_Part_Consumption_Settings__c partConsumption : partConsumptionSettings){
        if(partConsumption.Name.equals(CONSIDER_LOT_BATCH_TRACKING)){
          isLotBatchTrackedAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(CONSIDER_SERIALIZED_TRACKING)){
          isSerializedTrackingAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(CONSIDER_NON_SERIALIZED_TRACKING)){
          isNonSerializedTrackingAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(IS_PRODUCT_STOCK_DECREMENT_ALLOWED)){
          isProductStockDecrementAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(MAINTAIN_STOCK_HISTORY)){
          isMaintainStockHistoryAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(OUTSIDE_INVENTORY_ALLOWED)){
          isOutsideInventoryAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(CREATE_IP_FROM_LOT_BATCH)){
          isCreateIPFromLotBatch = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(CREATE_IP_FROM_NON_SERIALIZED)){
          isCreateIPFromNonSerialized = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(CREATE_IP_FROM_SERIALIZED)){
          isCreateIPFromSerialized = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(RESTOCKING_OF_PART_OUT)){
          isRestockingOfPartOut = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_ORDER_STATUS)){
          String eligibleOrderStatus = partConsumption.SVMX_PS_VS_Text_Value__c;
          ilib_LogEvent.message('VanStockUtility: Eligible Order Status  -' + eligibleOrderStatus);
          eligibleWorkOrderStatusList = getCommaSeperatedValues(eligibleOrderStatus);
        }else if(partConsumption.Name.equals(PERFORM_STOCK_MANAGEMENT_USING_BATCH)){
          isPerformStockUsingBatch = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(USE_ALLOCATED_QTY)){
          isAllocatedQtyDecrementAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(REMOVED_IP_STATUS)){
          removedIPStatus = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(removedIPStatus == null || removedIPStatus.trim().equals('')){
            removedIPStatus = 'De-Installed';
          }
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_RECORD_TYPE)){
          String eligibleRecordType = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleRecordType != null && !eligibleRecordType.trim().equals('')){
            ilib_LogEvent.message('VanStockUtility: Eligible Record Type  -' + eligibleRecordType);
            eligibleRecordTypeList = getCommaSeperatedValues(eligibleRecordType);
          }else{
            ilib_LogEvent.message('VanStockUtility: Eligible Record Type  - ' + USAGE_CONSUMPTION);
            eligibleRecordTypeList = new List<String>();
            eligibleRecordTypeList.add(USAGE_CONSUMPTION);
          }
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_LINE_TYPE)){
          String eligibleLineType = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleLineType != null && !eligibleLineType.trim().equals('')){
            ilib_LogEvent.message('VanStockUtility: Eligible Line Type  -' + eligibleLineType);
            eligibleLineTypeList = getCommaSeperatedValues(eligibleLineType);
          }else{
            ilib_LogEvent.message('VanStockUtility: Eligible Line Type  - ' + PART_LINE_TYPE);
            eligibleLineTypeList = new List<String>();
            eligibleLineTypeList.add(PART_LINE_TYPE);
          }
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_LINE_STATUS)){
          String eligibleLineStatus = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleLineStatus != null && !eligibleLineStatus.trim().equals('')){
            ilib_LogEvent.message('VanStockUtility: Eligible Line Status  -' + eligibleLineStatus);
            eligibleLineStatusList = getCommaSeperatedValues(eligibleLineStatus);
          }else{
            ilib_LogEvent.message('VanStockUtility: Eligible Line Status  - ' + OPEN_LINE_STATUS);
            eligibleLineStatusList = new List<String>();
            eligibleLineStatusList.add(OPEN_LINE_STATUS);
          }
        }
      }
      ilib_LogEvent.info('eligibleLineTypeList-->: '+eligibleLineTypeList);//CMSI-69
      ilib_LogEvent.info('eligibleLineStatusList-->: '+eligibleLineStatusList);//CMSI-69
    }
    ilib_LogEvent.pop();//CMSI-69  
  }

  /*****************************************************************************************************************************************
  *  Method Name : getCommaSeperatedValues
  *  Parameter   : String valueString -- value string to be processed
  *  Returns     : --
  *  Description : Processes the valueString passed, splits the string by comma and returns the list of all strings which are seperated by comma
  *******************************************************************************************************************************************/
  @TestVisible private List<String> getCommaSeperatedValues(String valueString){
    ilib_LogEvent.push(LOG_TITLE + '.getCommaSeperatedValues()');//CMSI-69
    ilib_LogEvent.info('valueString-->: '+valueString);//CMSI-69
    List<String> valueStringList = new List<String>();
    if(valueString != null && !valueString.trim().equals('')){
      valueStringList = valueString.split(',');
    }
  
    if(valueStringList.size() <= 0){
      valueStringList.add(valueString);
    }
  
    ilib_LogEvent.info('After seperating commas, Names found :' + valueStringList.size());
    ilib_LogEvent.info('After seperating commas, Names are :' + valueStringList);
    ilib_LogEvent.pop();//CMSI-69
    return valueStringList;
  }

  /*****************************************************************************************************************************************
  *  InnerClass Name : StockConsumptionWrapper
  *  Description : Class to hold stock consumption variables. 
  *******************************************************************************************************************************************/  
  @TestVisible public class StockConsumptionWrapper {
  
    //Variable to store the work detail record
    private SVMXC__Service_Order_Line__c workDetail;
    //Variable to store the product stock record
    private SVMXC__Product_Stock__c productStockRecord;
     //Variable to store the product stock record
    private SVMXC__Product_Stock__c consumedProductStockRecord;
    //Variable to store the stock serial record
    private SVMXC__Product_Serial__c stockSerial;
    //Variable to store the stock history record
    private SVMXC__Stock_History__c stockHistory;
    //Variable to store the removed IP record
    private SVMXC__Installed_Product__c installedProduct;
     //Variable to store the installedIP record
    private SVMXC__Installed_Product__c installedIP;
    //Variable to indicate that Installed Product needs to be created
    private boolean isCreateInstalledProduct;
    //Variable to indicate that if Product Stock is created or updated
    private boolean isCreateProductStock;
    //Variable to store if Part Consumption process is successful or not
    private boolean isPartConsumptionProcessSuccess;
    //Variable to store if Consumed Product Stock needs to be created or not
    private boolean isCreateConsumedProductStock;
    //Variable to store the batch serial record in consumed product stock
    private SVMXC__Product_Serial__c consumedbatchStockSerial;
    
    
     //Constructor for initiliazation of variables
    @TestVisible StockConsumptionWrapper(SVMXC__Service_Order_Line__c workDetail,
                             SVMXC__Product_Stock__c productStockRecord,
                             SVMXC__Product_Stock__c consumedProductStockRecord,
                             SVMXC__Product_Serial__c stockSerial,
                             SVMXC__Stock_History__c stockHistory,
                             SVMXC__Installed_Product__c installedIP,
                             boolean isPartConsumptionProcessSuccess,
                             boolean isCreateConsumedProductStock,
                             SVMXC__Product_Serial__c consumedbatchStockSerial){
      this.workDetail = workDetail;
      this.productStockRecord = productStockRecord;
      this.consumedProductStockRecord = consumedProductStockRecord;
      this.stockSerial = stockSerial;
      this.stockHistory = stockHistory;
      this.installedIP = installedIP;
      this.isCreateInstalledProduct = isCreateInstalledProduct;
      this.isPartConsumptionProcessSuccess = isPartConsumptionProcessSuccess;
      this.isCreateConsumedProductStock = isCreateConsumedProductStock;
      this.consumedbatchStockSerial = consumedbatchStockSerial;
    }

    //Constructor for initiliazation of variabled
    @TestVisible StockConsumptionWrapper(SVMXC__Service_Order_Line__c workDetail,
                             SVMXC__Product_Stock__c productStockRecord,
                             SVMXC__Product_Stock__c consumedProductStockRecord,
                             SVMXC__Product_Serial__c stockSerial,
                             SVMXC__Stock_History__c stockHistory,
                             boolean isCreateInstalledProduct,
                             boolean isPartConsumptionProcessSuccess,
                             boolean isCreateConsumedProductStock,
                             SVMXC__Product_Serial__c consumedbatchStockSerial){
      this.workDetail = workDetail;
      this.productStockRecord = productStockRecord;
      this.consumedProductStockRecord = consumedProductStockRecord;
      this.stockSerial = stockSerial;
      this.stockHistory = stockHistory;
      this.isCreateInstalledProduct = isCreateInstalledProduct;
      this.isPartConsumptionProcessSuccess = isPartConsumptionProcessSuccess;
      this.isCreateConsumedProductStock = isCreateConsumedProductStock;
      this.consumedbatchStockSerial = consumedbatchStockSerial;
    }

    @TestVisible StockConsumptionWrapper(SVMXC__Service_Order_Line__c workDetail,
                             SVMXC__Product_Stock__c productStockRecord,
                             SVMXC__Product_Serial__c stockSerial,
                             SVMXC__Stock_History__c stockHistory,
                             SVMXC__Installed_Product__c installedProduct,
                             boolean isCreateProductStock){
      this.workDetail = workDetail;
      this.productStockRecord = productStockRecord;
      this.stockSerial = stockSerial;
      this.stockHistory = stockHistory;
      this.installedProduct = installedProduct;
      this.isCreateProductStock = isCreateProductStock;
    }

    /*method to get work detail*/
    public SVMXC__Service_Order_Line__c getWorkDetail(){
      return this.workDetail;
    }

    /*method to get product stock*/
    public SVMXC__Product_Stock__c getProductStock(){
      return this.productStockRecord;
    }

    /*method to get consumed product stock*/
    public SVMXC__Product_Stock__c getConsumedProductStock(){
      return this.consumedProductStockRecord;
    }

    /*method to get stock serial*/
    public SVMXC__Product_Serial__c getProductSerial(){
      return this.stockSerial;
    }

    /*method to get stock history*/
    public SVMXC__Stock_History__c getStockHistory(){
      return this.stockHistory;
    }

    /*method to get Installed Product*/
    public SVMXC__Installed_Product__c getInstalledProduct(){
      return this.installedProduct;
    }

    /*method to set Installed Product*/
    public void setInstalledProduct(SVMXC__Installed_Product__c installedProduct){
     this.installedProduct = installedProduct;
    }
     
     /*method to get Installed Product*/
    public SVMXC__Installed_Product__c getInstalledIP(){
      return this.installedIP;
    }


    /*method to get if Installed Product needs to be Created*/
    public boolean getIsCreateInstalledProduct(){
      return this.isCreateInstalledProduct;
    }

    /*method to get if Product Stock needs to be Created*/
    public boolean getIsCreateProductStock(){
      return this.isCreateProductStock;
    }

    /*method to get if Part Consumption was successful */
    /*so that allocated qty can be decreased*/
    public boolean getIsPartConsumptionProcessSuccess(){
      return this.isPartConsumptionProcessSuccess;
    }

    /*method to get if Consumed Product Stock needs */
    /*to be created or not*/
    public boolean getIsCreateConsumedProductStock(){
      return this.isCreateConsumedProductStock;
    }
      
    /*method to get the batch stock serial from Consumed Product Stock*/
    public SVMXC__Product_Serial__c getConsumedbatchStockSerial(){
      return this.consumedbatchStockSerial;
    }

    /*method to check if the same object is for same work detail*/
    public boolean compareStockConsumptionWrapper(SVMXC__Service_Order_Line__c workDetail){
      return (this.workDetail.Id == workDetail.Id);
    }
  }
 
}
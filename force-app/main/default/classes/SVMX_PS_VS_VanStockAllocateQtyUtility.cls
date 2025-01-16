/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockAllocateQtyUtility 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public with sharing class SVMX_PS_VS_VanStockAllocateQtyUtility {
  //These constants are used to retrieve the custom settings. These are the names of custom settings
  @TestVisible private static final String USE_ALLOCATED_QTY= 'Use Allocated Qty';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_RECORD_TYPE = 'Eligible Work Detail Record Type';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_LINE_TYPE = 'Eligible Work Detail Line Type';
  @TestVisible private static final String ELIGIBLE_WORK_DETAIL_LINE_STATUS = 'Eligible Work Detail Line Status';
  @TestVisible private static final String USAGE_CONSUMPTION = 'UsageConsumption';
  @TestVisible private static final String PART_LINE_TYPE = 'Parts';
  @TestVisible private static final String OPEN_LINE_STATUS = 'Open';

  //Boolean to store if allocated Qty is being used or not.
  private boolean isAllocatedQtyDecrementAllowed = false;
  //List to store the eligible Work Detail Record Type which need to used for the part consumption code
  private List<String> eligibleRecordTypeList;
  //List to store the eligible Work Detail Record Type Id which need to used for the part consumption code
  private List<String> eligibleRecordTypeIdList;
  //List to store the eligible Work Detail Line Type which need to used for the part consumption code
  private List<String> eligibleLineTypeList;
  //List to store the eligible Work Detail Line Status which need to used for the part consumption code
  private List<String> eligibleLineStatusList;
  //Id for Usage/Consumption Record Type on Work Detail
  private Id usageRecordTypeId = null;
  //Map of Technician Id as key and Inventory Location Id as Value
  private Map<Id,Id> technicianIdInvntLocIdMap = null;

  /*****************************************************************************************************************************************
  *  Constructor Name  : SVMX_PS_VS_VanStockAllocateQtyUtility
  *  Parameter         : --
  *  Returns           : --
  *  Description       : Retrieve the Allocated Qty Settings from Part Consumption Custom Settings
  *******************************************************************************************************************************************/  
  public SVMX_PS_VS_VanStockAllocateQtyUtility() {
    //retrieve the settings to be used for allocated qty
    retrievePartConsumptionSetting();
     
    //Get the Id for Usage/Consumption Record Type on Work Detail
    List<RecordType> usageRecordTypeList = [Select Id,DeveloperName From RecordType Where SObjectType = 'SVMXC__Service_Order_Line__c'];
    Map<String,Id> recordTypeList = new Map<String,Id>();
    if(usageRecordTypeList != null && !usageRecordTypeList.isEmpty()){
      for(RecordType recordTypeRec : usageRecordTypeList){
        recordTypeList.put(recordTypeRec.DeveloperName, recordTypeRec.Id);
      }
    }

    //Find out the Record Type Ids
    if(eligibleRecordTypeList != null && !eligibleRecordTypeList.isEmpty()){
      eligibleRecordTypeIdList = new List<String>();
      for(String recordTypeName : eligibleRecordTypeList){
        Id recordTypeId = recordTypeList.get(recordTypeName);
        eligibleRecordTypeIdList.add(recordTypeId);
      }
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleAllocatedQtyForWorkDetailsCreation
  *  Parameter   : List<SVMXC__Service_Order_Line__c> workDetailLine - work detail line which are created
  *  Returns     : --
  *  Description : This method is called in After Insert Event of the Work Detail
  *                This method finds a product stock which is provided in work detail and updates it allocated
  *                Qty based on type of Product. 
  *                If Serialzed/Lot_Batch, then it increments by 1
  *                If Non-Serialzed, then it increments by qty mentioned on work detail 
  *                For this, it used new object Allocated Stock.
  *******************************************************************************************************************************************/  
  public void handleAllocatedQtyForWorkDetailsCreation(List<SVMXC__Service_Order_Line__c> workDetailList){
    if(isAllocatedQtyDecrementAllowed){
      if(workDetailList != null && workDetailList.size() > 0){
        //list to store valid work details which will be used for allocated qty calculation
        List<SVMXC__Service_Order_Line__c> validWorkDetailList = new List<SVMXC__Service_Order_Line__c>();
        //Map to store product stock and related stock serials
        Map<Id,List<SVMXC__Product_Serial__c>> productStockIdAllStockSerialMap = new Map<Id,List<SVMXC__Product_Serial__c>> ();
        //List of Allocated Stock recors to be created
        List<SVMXC__Allocated_Stock__c> allocatedStockList = new List<SVMXC__Allocated_Stock__c> ();
        //List ot stock serials to be updated with flag 
        List<SVMXC__Product_Serial__c> updatedStockSerialList = new List<SVMXC__Product_Serial__c> ();

        //check the validity of work detail line
        //line should be of usage/consumption record type, in open status and of type parts.
        for(SVMXC__Service_Order_Line__c workDetail : workDetailList){
          if(checkRecordTypeValidity(workDetail.RecordTypeId) &&
              checkLineTypeValidity(workDetail.SVMXC__Line_Type__c) && 
              checkLineStatusValidity(workDetail.SVMXC__Line_Status__c)){
              validWorkDetailList.add(workDetail);
          }
        }

        if(validWorkDetailList != null && validWorkDetailList.size() > 0){
  
          List<SVMXC__Product_Stock__c> productStockList = queryValidProductStock(workDetailList);

          List<SVMXC__Product_Serial__c> stockedSerialList = queryValidStockSerial(workDetailList);

          //Group all Stock Serials based on Product Stock
          if(stockedSerialList != null){
            for(SVMXC__Product_Serial__c stockedSerial : stockedSerialList){
              List<SVMXC__Product_Serial__c> stockSerialList = productStockIdAllStockSerialMap.get(stockedSerial.SVMXC__Product_Stock__c);
              if(stockSerialList == null){
                stockSerialList = new List<SVMXC__Product_Serial__c>();
                productStockIdAllStockSerialMap.put(stockedSerial.SVMXC__Product_Stock__c,stockSerialList);
              }
              stockSerialList.add(stockedSerial);
            }
          }

          for(SVMXC__Service_Order_Line__c workDetail : workDetailList){
            //get the correct product stock
            SVMXC__Product_Stock__c productStockRecord = getValidProductStock(workDetail,productStockList);

            if(productStockRecord != null){
              //Now Product Stock is Serialzed, Increment qty by 1
              if(productStockRecord.SVMXC__Product__r.SVMXC__Tracking__c.equals('Serialized') ||
                  productStockRecord.SVMXC__Product__r.SVMXC__Enable_Serialized_Tracking__c ||
                  productStockRecord.SVMXC__Product__r.SVMXC__Tracking__c.equals('Lot/Batch Tracked')){
                
                SVMXC__Product_Serial__c stockSerialRecord = null;

                List<SVMXC__Product_Serial__c> stockSerialList = productStockIdAllStockSerialMap.get(productStockRecord.Id);

                if(stockSerialList != null && stockSerialList.size() > 0){
                  //search for the stock serial record provided
                  if(workDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != null || workDetail.SVMX_PS_VS_Consumed_Part_Code__c != null){
                    //Get the required Stock Serial
                    for(SVMXC__Product_Serial__c stockSerial : stockSerialList){
                      if(stockSerial.Id == workDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c){
                        stockSerialRecord = stockSerial;
                        break;
                      }else if(stockSerial.Name.equals(workDetail.SVMX_PS_VS_Consumed_Part_Code__c)){
                        stockSerialRecord = stockSerial;
                        break;
                      }
                    }

                    if(stockSerialRecord != null){
                      System.debug('VanStockAllocatedQtyHandler : Created Allocated Stock found for work detail '
                                 + workDetail.Name);
                      SVMXC__Allocated_Stock__c allocatedStock = new SVMXC__Allocated_Stock__c();
                      allocatedStock.SVMXC__Allocated_Qty__c = 1;
                      allocatedStock.SVMXC__Product_Stock__c = productStockRecord.Id;
                      allocatedStock.SVMX_PS_VS_Stocked_Serial__c = stockSerialRecord.Id;
                      allocatedStock.SVMX_PS_VS_Work_Detail__c = workDetail.Id;
                      allocatedStockList.add(allocatedStock);

                      stockSerialRecord.SVMX_PS_VS_Is_Allocated__c = true;
                      updatedStockSerialList.add(stockSerialRecord);
                    }else{
                      System.debug('VanStockAllocatedQtyHandler : No Stock Serial Found. Hence cannot work on Allocated Qty');
                    }
                  }else{
                    System.debug('VanStockAllocatedQtyHandler : No Stock Serial Data found but needed as Product is Serialzed.' +
                      'Hence cannot work on Allocated Qty');
                  }
                }else{
                  System.debug('VanStockAllocatedQtyHandler : No Stock Serial Data found' +
                    'Hence cannot work on Allocated Qty');
                }
              //Now Product Stock is Non-Serialzed, Increment qty by put on work detail
              } else {
                System.debug('VanStockAllocatedQtyHandler : Created Allocated Stock found for work detail '
                                 + workDetail.Name);
                SVMXC__Allocated_Stock__c allocatedStock = new SVMXC__Allocated_Stock__c();
                allocatedStock.SVMXC__Allocated_Qty__c = workDetail.SVMXC__Actual_Quantity2__c;
                allocatedStock.SVMXC__Product_Stock__c = productStockRecord.Id;
                allocatedStock.SVMX_PS_VS_Stocked_Serial__c = null;
                allocatedStock.SVMX_PS_VS_Work_Detail__c = workDetail.Id;
                allocatedStockList.add(allocatedStock);
              }
            }else{
              System.debug('VanStockAllocatedQtyHandler : No Product Stock found for work detail '
                            + workDetail.Name);
            }
          }

          //commit allocated stocks to db
          Savepoint savePointRec = Database.setSavepoint();

          try{
            if(allocatedStockList.size() > 0){
              System.debug('VanStockAllocatedQtyHandler : Create Allocated Stock');
              Database.insert(allocatedStockList, true);
              System.debug('VanStockAllocatedQtyHandler : Done with Creation of Allocated Stock');

              if(updatedStockSerialList.size() > 0){
                System.debug('VanStockAllocatedQtyHandler : Update Stock Serials Record');
                Database.update(updatedStockSerialList, true);
                System.debug('VanStockAllocatedQtyHandler : Done with Updation Stock Serials Record');
              }
            }
          }catch(Exception exceptionRecord){
            System.debug('VanStockAllocatedQtyHandler : Problem while creation of records - ' + exceptionRecord.getMessage());
            Database.rollback(savePointRec);
          }
        }else{
          System.debug('VanStockAllocatedQtyHandler : Currently, No Work Details are Valid for Allocted Qty Updation');
        }
      }else{
        System.debug('VanStockAllocatedQtyHandler : Currently, No Work Details to process. Hence Ignore');
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler : Currently, we are not using Allocated Qty. Hence Ignore');
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleAllocatedQtyForWorkDetailsUpdation
  *  Parameter   : List<SVMXC__Service_Order_Line__c> workDetailLine - work detail line which are updated
  *                Map<Id,SVMXC__Service_Order_Line__c> oldWorkDetailMap - map of id of work detail and work detail record which represents
  *                                                                        previous state (typically trigger.oldMap)
  *  Returns     : --
  *  Description : This method is called in After Update Event of the Work Detail
  *                This method checks if any change is done for part consumption.
  *                This is determined if any of following fields are changed:-
  *                   a. SVMX_PS_VS_Consumed_Product_Stock__c
  *                   b. SVMXC__Consumed_From_Location__c 
  *                   c. SVMXC__Product__c 
  *                   d. SVMXC__Group_Member__c 
  *                   e. SVMX_PS_VS_Consumed_Stocked_Serial__c 
  *                   f. SVMX_PS_VS_Consumed_Part_Code__c 
  *                   g. SVMXC__Actual_Quantity2__c
  *                 If changed, then it deletes any allocated stock associated with the work detail and creates a new
  *******************************************************************************************************************************************/  
  public void handleAllocatedQtyForWorkDetailsUpdation(List<SVMXC__Service_Order_Line__c> workDetailList,
                                                        Map<Id,SVMXC__Service_Order_Line__c> oldWorkDetailMap){
    if(isAllocatedQtyDecrementAllowed){
      System.debug('VanStockAllocatedQtyHandler : Handle Allocated Stock while updation');
      if(workDetailList != null && workDetailList.size() > 0){
        //list to store valid work details which will be used for allocated qty calculation
        List<SVMXC__Service_Order_Line__c> validWorkDetailList = new List<SVMXC__Service_Order_Line__c>();

        for(SVMXC__Service_Order_Line__c workDetail : workDetailList){
          SVMXC__Service_Order_Line__c oldWorkDetail = oldWorkDetailMap.get(workDetail.Id);
          if(oldWorkDetail != null &&
              (oldWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != workDetail.SVMX_PS_VS_Consumed_Product_Stock__c ||
               oldWorkDetail.SVMXC__Consumed_From_Location__c != workDetail.SVMXC__Consumed_From_Location__c ||
               oldWorkDetail.SVMXC__Product__c != workDetail.SVMXC__Product__c ||
               oldWorkDetail.SVMXC__Group_Member__c != workDetail.SVMXC__Group_Member__c ||
               oldWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != workDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c ||
               oldWorkDetail.SVMX_PS_VS_Consumed_Part_Code__c != workDetail.SVMX_PS_VS_Consumed_Part_Code__c ||
               oldWorkDetail.SVMXC__Actual_Quantity2__c != workDetail.SVMXC__Actual_Quantity2__c)){
            validWorkDetailList.add(workDetail);
            System.debug('VanStockAllocatedQtyHandler : For Line ' + workDetail.Name + ',Data is changed. ' + 
                      'Hence recalculate Allocated Qty');
          }else{
            System.debug('VanStockAllocatedQtyHandler : Currently, No Data is changed. ' + 
                      'Hence no need to recalculate Allocated Qty');
          }
        }

        if(validWorkDetailList.size() > 0){
          //delete old allocated stock
          handleAllocatedQtyForWorkDetailsDeletion(validWorkDetailList);
          //create new allocated stock
          handleAllocatedQtyForWorkDetailsCreation(validWorkDetailList);
        }else{
          System.debug('VanStockAllocatedQtyHandler : Currently, No Lines for updation ' + 
                      'Hence no need to recalculate Allocated Qty');
        }
      }else{
        System.debug('VanStockAllocatedQtyHandler : Currently, No Work Details to process. Hence Ignore');
      }                                                       
    }else{
      System.debug('VanStockAllocatedQtyHandler : Currently, we are not using Allocated Qty. Hence Ignore');
    }
    System.debug('VanStockAllocatedQtyHandler : Done with Allocated Stock while updation');
  }

  /*****************************************************************************************************************************************
  *  Method Name : handleAllocatedQtyForWorkDetailsDeletion
  *  Parameter   : List<SVMXC__Service_Order_Line__c> workDetailLine - work detail line which are deleted
  *  Returns     : --
  *  Description : This method is called in Before Delete Event of the Work Detail
  *                This method finds allocated qty record linked with work detail and deletes it
  *******************************************************************************************************************************************/  
  public void handleAllocatedQtyForWorkDetailsDeletion(List<SVMXC__Service_Order_Line__c> workDetailList){
    if(isAllocatedQtyDecrementAllowed){
      System.debug('VanStockAllocatedQtyHandler : Handle Allocated Stock while deletion');
      if(workDetailList != null && workDetailList.size() > 0){
        List<SVMXC__Product_Serial__c> stockSerialList = new List<SVMXC__Product_Serial__c>();

        //list to store valid work details which will be used for allocated qty calculation
        Set<Id> workDetailIdSet = new Set<Id>();

        for(SVMXC__Service_Order_Line__c workOrderLine : workDetailList){
          workDetailIdSet.add(workOrderLine.Id);
        }
        
        List<SVMXC__Allocated_Stock__c> allocatedStockList = [SELECT ID,SVMX_PS_VS_Stocked_Serial__c FROM SVMXC__Allocated_Stock__c 
                                                                WHERE SVMX_PS_VS_Work_Detail__c IN :workDetailIdSet];

        if(allocatedStockList.size() > 0){
          for(SVMXC__Allocated_Stock__c allocatedStock : allocatedStockList){
            if(allocatedStock.SVMX_PS_VS_Stocked_Serial__c != null){
              SVMXC__Product_Serial__c stockSerial = new SVMXC__Product_Serial__c();
              stockSerial.Id = allocatedStock.SVMX_PS_VS_Stocked_Serial__c;
              stockSerial.SVMX_PS_VS_Is_Allocated__c = false;
              stockSerialList.add(stockSerial);
            }else{
              System.debug('VanStockAllocatedQtyHandler : No Stock Serial associated with - ' 
                  + allocatedStock.Id);
            }
          }
        }

        //commit allocated stocks to db
        Savepoint savePointRec = Database.setSavepoint();

        try{
          if(allocatedStockList.size() > 0){
            System.debug('VanStockAllocatedQtyHandler : Delete Allocated Stock');
            Database.delete(allocatedStockList, true);
            System.debug('VanStockAllocatedQtyHandler : Done with Deletion of Allocated Stock');

            if(stockSerialList.size() > 0){
              System.debug('VanStockAllocatedQtyHandler : Update Stock Serials Record');
              Database.update(stockSerialList, true);
              System.debug('VanStockAllocatedQtyHandler : Done with Updation Stock Serials Record');
            }
          }
        }catch(Exception exceptionRecord){
          System.debug('VanStockAllocatedQtyHandler : Problem while deletion of records - ' + exceptionRecord.getMessage());
          Database.rollback(savePointRec);
        } 
      }else{
        System.debug('VanStockAllocatedQtyHandler : Currently, No Work Details to process. Hence Ignore');
      }                                                       
    }else{
        System.debug('VanStockAllocatedQtyHandler : Currently, we are not using Allocated Qty. Hence Ignore');
    }
    System.debug('VanStockAllocatedQtyHandler : Done with Allocated Stock while deletion');
  }

  /*****************************************************************************************************************************************
  *  Method Name : getValidProductStock
  *  Parameter   : SVMXC__Service_Order_Line__c workDetailLine - work detail line for which the allocated qty needs updation
  *                List<SVMXC__Product_Stock__c> -- List of all Product Stock queried
  *  Returns     : SVMXC__Product_Stock__c - Returns the correct Product Stock associated with Work Detail Line
  *  Description : First of all Product Stock needs to be found form which allocated qty needs to be updated
  *                For Finding the product stock, following is the sequence
  *                  a. See if the field "Consumed Part" is populated
  *                  b. If not, check if the "Consumed From Location" and "Part" is populated
  *                  c. If not, check if the "Technician" and "Part" is populated
  *                  d. If not, ignore this line
  *                For #a, we get product stock directly
  *                For #b, using "Consumed From Location" and "Part", we can get product stock
  *                For #c, we find "Inventory Location's" of Tech, Using "Inventory Location's" of Tech and Part, we can get product stock
  *                Here, we are using Technician field of Work Detail.
  *                Once found, return the correct Product Stock Record
  *******************************************************************************************************************************************/  
  @TestVisible private SVMXC__Product_Stock__c getValidProductStock(SVMXC__Service_Order_Line__c workDetailLine, List<SVMXC__Product_Stock__c> productStockList){
    System.debug('VanStockAllocatedQtyHandler : Get Product Stock for : ' + workDetailLine.Name);

    SVMXC__Product_Stock__c correctProductStockRec = null;

    if(workDetailLine.SVMX_PS_VS_Consumed_Status__c == null || 
        !workDetailLine.SVMX_PS_VS_Consumed_Status__c.contains('Consumption Success')){
      //We have Product Stock Supplied. Consume using Product Stock
      if(workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c != null){
        System.debug('VanStockAllocatedQtyHandler : Given Product Stock Directly');
        for(SVMXC__Product_Stock__c productStock : productStockList){
          if(productStock.Id == workDetailLine.SVMX_PS_VS_Consumed_Product_Stock__c){
            correctProductStockRec = productStock;
            break;
          }
        }
      //We have Consumed Location and Part Supplied. Consume using Location
      }else if (workDetailLine.SVMXC__Consumed_From_Location__c != null && workDetailLine.SVMXC__Product__c != null){
        System.debug('VanStockAllocatedQtyHandler : Given Consumed Location and Part');
        for(SVMXC__Product_Stock__c productStock : productStockList){
          if(productStock.SVMXC__Location__c == workDetailLine.SVMXC__Consumed_From_Location__c && productStock.SVMXC__Product__c == workDetailLine.SVMXC__Product__c && productStock.SVMXC__Status__c == 'Available'){
            correctProductStockRec = productStock;
            break;
          }
        }
      //We have Technician and Part Supplied. Consume using Technician
      }else if(workDetailLine.SVMXC__Group_Member__c != null && workDetailLine.SVMXC__Product__c != null){
        System.debug('VanStockAllocatedQtyHandler : Given Technician and Part');
        if( technicianIdInvntLocIdMap != null && technicianIdInvntLocIdMap.size() > 0){
          Id locationId = technicianIdInvntLocIdMap.get(workDetailLine.SVMXC__Group_Member__c);
          
          if(locationId != null){
            for(SVMXC__Product_Stock__c productStock : productStockList){
              if(productStock.SVMXC__Location__c == locationId && productStock.SVMXC__Product__c == workDetailLine.SVMXC__Product__c && productStock.SVMXC__Status__c == 'Available'){
                correctProductStockRec = productStock;
                break;
              }
            }
          }else{
            //cannot found location id.so cannot proceed
            System.debug('VanStockAllocatedQtyHandler : No Inventory Location found');
          }
        }else{
          //map has no inventory location.so cannot proceed
          System.debug('VanStockAllocatedQtyHandler : No Inventory Location found');    
        }
      }else{
        //No Proper Details for Part Consumption Given
        System.debug('VanStockAllocatedQtyHandler : No Proper Data found for consumption'); 
      }
    }
    return correctProductStockRec;
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
    System.debug('VanStockAllocatedQtyHandler : Start Query Product Stock Process');

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
          System.debug('VanStockAllocatedQtyHandler : This Work Detail Line is not valid for consumption - ' 
                      + workDetailLine.Id);
        }
      }

      //Check if data provided to query product stock is proper.
      if(productStockIdSetToBeQueried != null || 
          (locationIdsSetToBeQueried != null && productIdsSetToBeQueried != null) || 
          (techIdsSetToBeQueried != null && productIdsSetToBeQueried != null)){
        //If any technicians find their inventory location so that associated product stock can be found
        if(techIdsSetToBeQueried != null && techIdsSetToBeQueried.size() > 0){
          technicianIdInvntLocIdMap = queryInventoryLocations(techIdsSetToBeQueried);

          if(technicianIdInvntLocIdMap != null && technicianIdInvntLocIdMap.size() > 0){
            locationIdsSetToBeQueried.addAll(technicianIdInvntLocIdMap.values());
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
            System.debug('Product Stock Query String - ' + productStockQueryString);
            productStockList =Database.query(productStockQueryString);
          }catch(Exception exceptionRecord){ 
           System.debug('VanStockAllocatedQtyHandler : Could not query Product Stock - ' + exceptionRecord.getMessage());
          }
        }else{
          System.debug('VanStockAllocatedQtyHandler : No data available to query Product Stock');
        }
      }else{
         System.debug('VanStockAllocatedQtyHandler : No Data provided for Part Consumption Process.');
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler : No Work Details for Part Consumption Process');
    }
    System.debug('VanStockAllocatedQtyHandler : End Query Product Stock Process');

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
  @TestVisible private List<SVMXC__Product_Serial__c> queryValidStockSerial(List<SVMXC__Service_Order_Line__c> validWorkDetailList){
    System.debug('VanStockAllocatedQtyHandler : Start Query Stock Serial Process');

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
        //We have Stock Serial Name.
        }else if(workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c != null){
          stockSerialNameSetToBeQueried.add(workDetailLine.SVMX_PS_VS_Consumed_Part_Code__c);
        }else{
          System.debug('VanStockAllocatedQtyHandler : This Work Detail Line is not valid for stock serial query - ' 
                      + workDetailLine.Id);
        }
      }

      //Check if data provided to query stock serial is proper.
      if(stockSerialNameSetToBeQueried != null || stockSerialIdsSetToBeQueried != null){
        //Create Query String for all Stock Serial Id's available
        String stockSerialIdString = null;
        if(stockSerialIdsSetToBeQueried != null && stockSerialIdsSetToBeQueried.size() > 0){
          stockSerialIdString = createQueryStringUsingList('Id', stockSerialIdsSetToBeQueried);
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

        //Create Product Stock Query
        String stockSerialQueryString = 'SELECT Id,Name,SVMXC__Active__c,SVMXC__Product__c,SVMXC__Product_Stock__c,' +
                                          'SVMX_PS_VS_Is_Allocated__c FROM SVMXC__Product_Serial__c ';

        if(stockSerialIdString != null){
          stockSerialQueryString += ' WHERE ' + stockSerialIdString;

          if(stockSerialNameString != null){
            stockSerialQueryString += ' OR ' + stockSerialNameString;
          }
        }else if(stockSerialNameString != null){
          stockSerialQueryString += ' WHERE ' + stockSerialNameString;
        }else{
          stockSerialQueryString = null;
        }

        if(stockSerialQueryString != null){
          try{
            System.debug('Stock Serial Query String - ' + stockSerialQueryString);
            stockSeriallList =Database.query(stockSerialQueryString);
          }catch(Exception exceptionRecord){ 
           System.debug('VanStockAllocatedQtyHandler : Could not query Stock Serials - ' + exceptionRecord.getMessage());
          }
        }else{
          System.debug('VanStockAllocatedQtyHandler : No data available to query Stock Serial');
        }
      }else{
         System.debug('VanStockAllocatedQtyHandler : No Data provided for Stock Serial Query Process.');
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler : No Work Details for Stock Serial Query Process');
    }

    System.debug('VanStockAllocatedQtyHandler : End Query Stock Serial Process');
    return stockSeriallList;
  }

  /*****************************************************************************************************************************************
  *  Method Name : queryInventoryLocations
  *  Parameter   : Set<Id> technicianList - Set of all technicians Ids for whom Inventory Location need to be found
  *  Returns     : Map<Id,Id> -- Map of Technician Id as key and Inventory Location Id as Value
  *  Description : Query and find out all Inventory Locations for Technicians whose Id is given
  *******************************************************************************************************************************************/  
  @TestVisible private Map<Id,Id> queryInventoryLocations(Set<Id> technicianList){
    Map<Id,Id> technicianIdInvntLocIdMap = null;
    if(technicianList != null && technicianList.size() > 0){
      technicianIdInvntLocIdMap = new Map<Id,Id> ();

      for(SVMXC__Service_Group_Members__c tech : [SELECT Id, SVMXC__Inventory_Location__c FROM SVMXC__Service_Group_Members__c 
                                                    WHERE Id in :technicianList]) {
        technicianIdInvntLocIdMap.put(tech.id, tech.SVMXC__Inventory_Location__c);
        System.debug('VanStockAllocatedQtyHandler: Technician '+ tech.id + ' has Inventory Location - ' 
                                + tech.SVMXC__Inventory_Location__c);
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler : No Technicians listed for finding Inventory Locations');
    }
    return technicianIdInvntLocIdMap;
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
      System.debug('VanStockAllocatedQtyHandler : Either the fieldApiName or idSet is null. Hence could not create String');
    }
    return queryString;
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkLineTypeValidity
  *  Parameter   : String lineTypeValue -- Line Type of Work Detail
  *  Returns     : boolean -- true if Line Type is valid else false
  *  Description :  This method checks if the line type is valid or name
  *                 Checks if the Line Type is supported or not. 
  *                 Line Types supported are mentioned in "" record in "Part Consumption Setting".
  *                 If all found good, returns true.
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkLineTypeValidity(String lineTypeValue){
    boolean isLineTypeValid = false;

    //Check if line type valye is null
    if(lineTypeValue != null && !lineTypeValue.trim().equals('')){
      //Check if line type is part of part consumption settings
      for(String supportedLineType : eligibleLineTypeList){
        if(lineTypeValue.contains(supportedLineType)){
          isLineTypeValid = true;
          break;
        }
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler: Line Type is null. Hence ignore work detail');
    }

    return isLineTypeValid;
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkLineStatusValidity
  *  Parameter   : String linStatusValue -- Line Status of Work Detail
  *  Returns     : boolean -- true if Line Status is valid else false
  *  Description :  This method checks if the Line Status is valid or name
  *                 Checks if the Line Status is supported or not. 
  *                 Line Status supported are mentioned in "" record in "Part Consumption Setting".
  *                 If all found good, returns true.
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkLineStatusValidity(String lineStatusValue){
    boolean isLineStatusValid = false;

    //Check if line type valye is null
    if(lineStatusValue != null && !lineStatusValue.trim().equals('')){
      //Check if line type is part of part consumption settings
      for(String supportedLineStatus : eligibleLineStatusList){
        if(lineStatusValue.contains(supportedLineStatus)){
          isLineStatusValid = true;
          break;
        }
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler: Line Status is null. Hence ignore work detail');
    }

    return isLineStatusValid;
  }

  /*****************************************************************************************************************************************
  *  Method Name : checkRecordTypeValidity
  *  Parameter   : String recordTypeValue -- Record Type of Work Detail
  *  Returns     : boolean -- true if Line Type is valid else false
  *  Description :  This method checks if the Record Type is valid or name
  *                 Checks if the Record Type is supported or not. 
  *                 Record Types supported are mentioned in "Eligible Work Detail Record Type" record in "Part Consumption Setting".
  *                 If all found good, returns true.
  *******************************************************************************************************************************************/  
  @TestVisible private boolean checkRecordTypeValidity(String recordTypeValue){
    boolean isRecordTypeValid = false;

    //Check if line type valye is null
    if(recordTypeValue != null && !recordTypeValue.trim().equals('')){
      //Check if line type is part of part consumption settings
      for(String supportedRecordType : eligibleRecordTypeIdList){
        if(recordTypeValue.contains(supportedRecordType)){
          isRecordTypeValid = true;
          break;
        }
      }
    }else{
      System.debug('VanStockAllocatedQtyHandler: Record Type is null. Hence ignore work detail');
    }

    return isRecordTypeValid;
  }

  /*****************************************************************************************************************************************
  *  Method Name : retrievePartConsumptionSetting
  *  Parameter   : --
  *  Returns     : --
  *  Description : Get All Part Consumption Settings which control the van stock functionality and store it in variables
  *******************************************************************************************************************************************/  
  @TestVisible private void retrievePartConsumptionSetting(){
  List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettingsList = SVMX_PS_VS_Part_Consumption_Settings__c.getAll().values();
  if(partConsumptionSettingsList != null){
      for(SVMX_PS_VS_Part_Consumption_Settings__c partConsumption : partConsumptionSettingsList){
        if(partConsumption.Name.equals(USE_ALLOCATED_QTY)){
            isAllocatedQtyDecrementAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_RECORD_TYPE)){
          String eligibleRecordType = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleRecordType != null && !eligibleRecordType.trim().equals('')){
            System.debug('VanStockUtility: Eligible Record Type  -' + eligibleRecordType);
            eligibleRecordTypeList = getCommaSeperatedValues(eligibleRecordType);
          }else{
            System.debug('VanStockUtility: Eligible Record Type  - ' + USAGE_CONSUMPTION);
            eligibleRecordTypeList = new List<String>();
            eligibleRecordTypeList.add(USAGE_CONSUMPTION);
          }
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_LINE_TYPE)){
          String eligibleLineType = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleLineType != null && !eligibleLineType.trim().equals('')){
            System.debug('VanStockUtility: Eligible Line Type  -' + eligibleLineType);
            eligibleLineTypeList = getCommaSeperatedValues(eligibleLineType);
          }else{
            System.debug('VanStockUtility: Eligible Line Type  - ' + PART_LINE_TYPE);
            eligibleLineTypeList = new List<String>();
            eligibleLineTypeList.add(PART_LINE_TYPE);
          }
        }else if(partConsumption.Name.equals(ELIGIBLE_WORK_DETAIL_LINE_STATUS)){
          String eligibleLineStatus = partConsumption.SVMX_PS_VS_Text_Value__c;
          if(eligibleLineStatus != null && !eligibleLineStatus.trim().equals('')){
            System.debug('VanStockUtility: Eligible Line Status  -' + eligibleLineStatus);
            eligibleLineStatusList = getCommaSeperatedValues(eligibleLineStatus);
          }else{
            System.debug('VanStockUtility: Eligible Line Status  - ' + OPEN_LINE_STATUS);
            eligibleLineStatusList = new List<String>();
            eligibleLineStatusList.add(OPEN_LINE_STATUS);
          }
        }
      } 
    }
  }

  /*****************************************************************************************************************************************
  *  Method Name : getCommaSeperatedValues
  *  Parameter   : String valueString -- value string to be processed
  *  Returns     : --
  *  Description : Processes the valueString passed, splits the string by comma and returns the list of all strings which are seperated by comma
  *******************************************************************************************************************************************/
  @TestVisible private List<String> getCommaSeperatedValues(String valueString){
    List<String> valueStringList = new List<String>();
    if(valueString != null && !valueString.trim().equals('')){
      valueStringList = valueString.split(',');
    }
  
    if(valueStringList.size() <= 0){
      valueStringList.add(valueString);
    }
  
    System.debug('After seperating commas, Names found :' + valueStringList.size());
    System.debug('After seperating commas, Names are :' + valueStringList);
    return valueStringList;
  }
}
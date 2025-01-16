/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockIPHandler 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public with sharing class SVMX_PS_VS_VanStockIPHandler{
    //Names of Mappings in Custom Settings
    @TestVisible private static final String MAPPING_LOCATION_TO_IP = 'Mapping from Location To IP';
    @TestVisible private static final String MAPPING_PRODUCT_TO_IP = 'Mapping from Product To IP';
    @TestVisible private static final String MAPPING_PRODUCT_STOCK_TO_IP = 'Mapping from Product Stock To IP';
    @TestVisible private static final String MAPPING_PRODUCT_SERIAL_TO_IP = 'Mapping from Product Serial To IP';
    @TestVisible private static final String MAPPING_WORK_DETAIL_TO_IP = 'Mapping from Work Detail To IP';
    @TestVisible private static final String MAPPING_WORK_ORDER_TO_IP = 'Mapping from Work Order To IP';
    @TestVisible private static final String MAPPING_IP_TO_IP = 'Mapping from IP To IP';
    @TestVisible private static final String IS_REPARENTING_ALLOWED = 'Is Reparenting Allowed';

    //Sets Servicemax Mapping Layout values
    private String locationToIPValue='';
    private String productStockToIPValue='';
    private String productToIPValue='';
    private String productSerialToIPValue='';
    private String workDetailToIPValue='';
    private String workOrderToIPValue='';
    private String ipToIPValue='';
    private boolean isReparentingAllowed=false;

    //Map of stock consumption to wrapper type
    private Map<Id, SVMXC__Product_Stock__c> productStockMap = new Map<Id, SVMXC__Product_Stock__c>();
    private Map<Id, SVMXC__Product_Serial__c> productSerialMap = new Map<Id, SVMXC__Product_Serial__c>();
    private Map<Id, Product2> productMap = new Map<Id, Product2>();
    private Map<Id, SVMXC__Service_Order_Line__c> workDetailMap = new Map<Id, SVMXC__Service_Order_Line__c>();
    private Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>();
    private Map<Id, SVMXC__Site__c> locationMap = new Map<Id, SVMXC__Site__c>();
    private Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>();

    /*************************************************************************************************
    *
    *  Constructor Initializes Mappings
    *
    **************************************************************************************************/
    public SVMX_PS_VS_VanStockIPHandler(){
            retrievePartConsumptionSetting();
    }

    /*****************************************************************************************************************************************
    *  Method Name : createInstalledProduct
    *  Parameter   : List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> - List of all Stock Consumption items from Vanstock Utility
    *  Returns     : --
    *  Description : To evaluate all wrapper items to Installed products and insert into database. Finds all field mappings. Inserts all Newly created IP into database
    *******************************************************************************************************************************************/
    public void createInstalledProduct(List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> stockConsumptionWrapperList){
        //List of all Stock Consumption records that need to have an Installed Product Created
        List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> validWrapperList = new List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper>();
        boolean isMappingSuccess = true;
        if(stockConsumptionWrapperList != NULL && stockConsumptionWrapperList.size()>0){
            for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : stockConsumptionWrapperList){
                //Only Items that need to have IP created are evaluated
                if(wrapperItem.getInstalledIP() != null || wrapperItem.getIsCreateInstalledProduct()){
                    validWrapperList.add(wrapperItem);
                }
            }
            
            if(validWrapperList.size() > 0){
                //Creates all field maps that will be used to create the IP
                //Then finds all records that are needed to create an IP
                SVMXC__ServiceMax_Config_Data__c[] fieldMapWorkDetail = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapWorkOrder = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapProductStock = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapProductSerial = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapLocation = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapProduct = NULL;
                SVMXC__ServiceMax_Config_Data__c[] fieldMapIP = NULL;

                if(productStockToIPValue != NULL){
                    fieldMapProductStock = getFieldMapping(productStockToIPValue);
                    isMappingSuccess = getMappingRecords(productStockToIPValue, validWrapperList, fieldMapProductStock);
                }else{
                    System.debug('VanStockHandler - ProductStockToIPValue is NULL');
                }
                
                if(productToIPValue != NULL){
                    fieldMapProduct = getFieldMapping(productToIPValue);
                    isMappingSuccess = getMappingRecords(productToIPValue, validWrapperList, fieldMapProduct);
                }else{
                    System.debug('VanStockHandler - ProductToIPValue is NULL');
                }

                if(productSerialToIPValue != NULL){
                    fieldMapProductSerial = getFieldMapping(productSerialToIPValue);
                    isMappingSuccess = getMappingRecords(productSerialToIPValue, validWrapperList, fieldMapProductSerial);
                }else{
                    System.debug('VanStockHandler - ProductSerialToIPValue is NULL');
                }

                if(workDetailToIPValue != NULL){
                    fieldMapWorkDetail = getFieldMapping(workDetailToIPValue);
                    isMappingSuccess = getMappingRecords(workDetailToIPValue, validWrapperList, fieldMapWorkDetail);
                }else{
                    System.debug('VanStockHandler - WorkDetailToIPValue is NULL');
                }

                if(workOrderToIPValue != NULL){
                    fieldMapWorkOrder = getFieldMapping(workOrderToIPValue);
                    isMappingSuccess = getMappingRecords(workOrderToIPValue, validWrapperList, fieldMapWorkOrder);
                }else{
                    System.debug('VanStockHandler - WorkOrderToIPValue is NULL');
                } 

                if(locationToIPValue != NULL){
                    fieldMapLocation = getFieldMapping(locationToIPValue);
                    isMappingSuccess = getMappingRecords(locationToIPValue, validWrapperList, fieldMapLocation);
                }else{
                    System.debug('VanStockHandler - LocationToIPValue is NULL');
                }

                if(ipToIPValue != NULL){
                    fieldMapIP = getFieldMapping(ipToIPValue);
                    isMappingSuccess = getMappingRecords(ipToIPValue, validWrapperList, fieldMapIP);
                }else{
                    System.debug('VanStockHandler - IpToIPValue is NULL');
                }

                if(isMappingSuccess){
                    System.debug('VanStockHandler - Installed Product Creation Initiated');
                    List<SVMXC__Installed_Product__c> installedProductRecList = createUpdateIp(validWrapperList,fieldMapWorkDetail, fieldMapWorkOrder,
                                                                                                    fieldMapProductStock, fieldMapProductSerial, fieldMapLocation,
                                                                                                    fieldMapProduct, fieldMapIP);
                    //Add new IP List to Database
                    if(installedProductRecList != NULL && installedProductRecList.size() > 0){
                        
                        //Commit Changes to Database
                        Savepoint savePointRec = Database.setSavepoint();

                        try{
                            System.debug('VanStockHandler - Committing Created Installed Products');
                            upsert installedProductRecList;
                            System.debug('VanStockHandler - Committed Installed Products');

                            //handle reparenting of all child IP's belonging to the old IP to this newly created IP
                            handleReparenting(installedProductRecList);
                        }catch(Exception exceptionValue){
                            System.debug('VanStockHandler - Could not create installed products ' + exceptionValue.getMessage());
                            Database.rollback(savePointRec);
                            throw exceptionValue;
                        }
                    }else{
                        System.debug('VanStockHandler - No installed product found for creation');
                    }
                }else{
                    System.debug('VanStockHandler - Mapping could not be located hence do not proceed');
                }
                
            }else{
                System.debug('VanStockHandler - validWrapperList is empty, No IP to create');
            }
        }else{
            System.debug('VanStockHandler - Passed stockConsumptionWrapperList is empty');
        }
    }


    /*****************************************************************************************************************************************
    *  Method Name : getFieldMapping
    *  Parameter   : String mapping - Determins which Object you are mapping to IP
    *  Returns     : field Mapping
    *  Description : Searches all fields required for mapping, Queries database for the following fields and adds records to a MAP
    *******************************************************************************************************************************************/
    private SVMXC__ServiceMax_Config_Data__c[] getFieldMapping(String mapping){ 
        SVMXC__ServiceMax_Config_Data__c[] fieldMap = null;
        // Holds the field mapping for a given map ID
        if(mapping != null && !mapping.trim().equals('')){
            System.debug('VanStockHandler - Field Mapping Name - ' + mapping);
            fieldMap = [SELECT SVMXC__Target_Field_Name__c, SVMXC__Source_Field_Name__c, SVMXC__Parameter_Type__c,
                                SVMXC__Display_Value__c, SVMXC__MapID__r.SVMXC__MapID__c, SVMXC__MapID__c, SVMXC__Active__c 
                                FROM SVMXC__ServiceMax_Config_Data__c WHERE SVMXC__MapID__r.SVMXC__MapID__c = :mapping  
                                AND SVMXC__Active__c = TRUE AND recordType.Name = 'Field Mapping'];
        }
        return fieldMap;
    }
    
    /*****************************************************************************************************************************************
    *  Method Name : getMappingRecords
    *  Parameter   : String mapping - Determins which Object you are mapping to IP
    *  Returns     : Boolean
    *  Description : Searches all fields required for mapping, Queries database for the following fields and adds records to a MAP.
    *******************************************************************************************************************************************/
    private boolean getMappingRecords(String mapping, List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> validWrapperList, 
                            SVMXC__ServiceMax_Config_Data__c[] fieldMap){
        boolean isSuccess = true;
        if(mapping != NULL && !mapping.trim().equals('')){
            // Field Query string used to search the database.
            String fieldQuery = 'Select Id';
            
            //List of records obtained after query
            List<SVMXC__Product_Stock__c> recordProductStockList = new List<SVMXC__Product_Stock__c>();
            List<SVMXC__Product_Serial__c> recordProductSerialList = new List<SVMXC__Product_Serial__c>();
            List<SVMXC__Service_Order_Line__c> recordWorkDetailList = new List<SVMXC__Service_Order_Line__c>();
            List<SVMXC__Service_Order__c> recordWorkOrderList = new List<SVMXC__Service_Order__c>();
            List<Product2> recordProductList = new List<Product2>();
            List<SVMXC__Site__c> recordLocationList = new List<SVMXC__Site__c>();
            List<SVMXC__Installed_Product__c> recordIPList = new List<SVMXC__Installed_Product__c>();
            
            //Checks to see which Mappings need to be added into IP records when creating IP
            if(fieldMap != NULL && fieldMap.size() > 0){
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMap){
                    //Adds Field Names to Query String
                    if(fld.SVMXC__Source_Field_Name__c != NULL){
                        fieldQuery = fieldQuery + ', ' + fld.SVMXC__Source_Field_Name__c;
                    }else{
                        System.debug('VanStockHandler - Field Source Filed is Null.');
                    }
                }
            }else{
                System.debug('VanStockHandler - fieldMap is empty.');
            }

            //Depending on the Mapping type, Searches Database for records and adds then to a Map<Id, Object>
            if(mapping == productStockToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> productStockIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    productStockIdSet.add(wrapperItem.getProductStock().Id);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', productStockIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Product_Stock__c WHERE '+ whereClause;
                //Get all Product Stock Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordProductStockList = database.query(fieldQuery);
                    if(recordProductStockList != NULL && recordProductStockList.size() > 0){
                        productStockMap.putAll(recordProductStockList);
                    }else{
                        System.debug('VanStockHandler - recordProductStockList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }
            }else if(mapping == productSerialToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> productSerialIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    productSerialIdSet.add(wrapperItem.getProductSerial().Id);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', productSerialIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Product_Serial__c WHERE '+ whereClause;

                //Get all Work Product Serial with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordProductSerialList = database.query(fieldQuery);
                    if(recordProductSerialList != NULL && recordProductSerialList.size() > 0){
                        productSerialMap.putAll(recordProductSerialList);
                    }else{
                        System.debug('VanStockHandler - recordProductSerialList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }  
            }else if(mapping==workDetailToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> workDetailIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    workDetailIdSet.add(wrapperItem.getWorkDetail().Id);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', workDetailIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Service_Order_Line__c WHERE '+ whereClause;

                //Get all Work Detail Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordWorkDetailList = database.query(fieldQuery);
                    if(recordWorkDetailList != NULL && recordWorkDetailList.size() > 0){
                        workDetailMap.putAll(recordWorkDetailList);
                    }else{
                        System.debug('VanStockHandler - recordWorkDetailList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }
            }else if(mapping==workOrderToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> workOrderIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    workOrderIdSet.add(wrapperItem.getWorkDetail().SVMXC__Service_Order__c);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', workOrderIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Service_Order__c WHERE '+ whereClause;

                //Get all Work Order Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordWorkOrderList = database.query(fieldQuery);
                    if(recordWorkOrderList != NULL && recordWorkOrderList.size() > 0){
                        workOrderMap.putAll(recordWorkOrderList);
                    }else{
                        System.debug('VanStockHandler - recordWorkOrderList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                } 
            }else if(mapping==productToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> productIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    productIdSet.add(wrapperItem.getProductStock().SVMXC__Product__c);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', productIdSet);
                fieldQuery = fieldQuery + ' From Product2 WHERE '+ whereClause;

                //Get all Work Order Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordProductList = database.query(fieldQuery);
                    if(recordProductList != NULL && recordProductList.size() > 0){
                        productMap.putAll(recordProductList);
                    }else{
                        System.debug('VanStockHandler - recordProductList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }
            }else if(mapping==locationToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> locationIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    locationIdSet.add(wrapperItem.getProductStock().SVMXC__Location__c);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', locationIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Site__c WHERE '+ whereClause;

                //Get all Work Order Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordLocationList = database.query(fieldQuery);
                    if(recordLocationList != NULL && recordLocationList.size() > 0){
                        locationMap.putAll(recordLocationList);
                    }else{
                        System.debug('VanStockHandler - recordLocationList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }
            }else if(mapping==ipToIPValue){
                //List of all Ids that need to be used to create IP
                Set<Id> ipIdSet = new Set<Id>();
                for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper wrapperItem : validWrapperList){
                    if(wrapperItem.getInstalledProduct() != null)
                    ipIdSet.add(wrapperItem.getInstalledProduct().Id);
                }
                //Create Query String to search Database
                String whereClause = createQueryStringUsingList('ID', ipIdSet);
                fieldQuery = fieldQuery + ' From SVMXC__Installed_Product__c WHERE '+ whereClause;

                //Get all Work Order Records with the fields add them to list
                try{
                    //Query database with formulated string, add all the records to a Map
                    recordIPList = database.query(fieldQuery);
                    if(recordIPList != NULL && recordIPList.size() > 0){
                        ipMap.putAll(recordIPList);
                    }else{
                        System.debug('VanStockHandler - recordIPList is empty, query returned empty results');
                    }
                }catch(Exception e){
                    isSuccess = false;
                    System.debug('VanStockHandler - Database query error, Check Query String: ' + fieldQuery);
                }
            }else{
                System.debug('VanStockHandler -  Mapping set is not a valid Mapping');
            }
        }else{
            System.debug('VanStockHandler -  Recieved Mapping was empty');
        }
        return isSuccess;
    }
    
    /*****************************************************************************************************************************************
    *  Method Name : createUpdateIp
    *  Parameter   : --
    *  Returns     : --
    *  Description : Creates a new Installed Product record, adds all the fields and values from the multiple Mapped objects and adds to the list of Installed Products that will be inserted into server.
    *******************************************************************************************************************************************/
    private List<SVMXC__Installed_Product__c> createUpdateIp(List<SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper> validWrapperList, 
            SVMXC__ServiceMax_Config_Data__c[] fieldMapWorkDetail, SVMXC__ServiceMax_Config_Data__c[] fieldMapWorkOrder,
            SVMXC__ServiceMax_Config_Data__c[] fieldMapProductStock, SVMXC__ServiceMax_Config_Data__c[] fieldMapProductSerial, 
            SVMXC__ServiceMax_Config_Data__c[] fieldMapLocation, SVMXC__ServiceMax_Config_Data__c[] fieldMapProduct, 
            SVMXC__ServiceMax_Config_Data__c[] fieldMapIP){
        //Instaled Product List that is inserted at the end of evaluation
        List<SVMXC__Installed_Product__c> installedProductRecList = new List<SVMXC__Installed_Product__c>();
        
        //For Each stock Consumption Item that needs to be turned into an IP
        //Create a New IP record, Check if Mapping values from Object is required.
        //Check if Mapped Field has a Field Value or a Value, and add the field to the new IP record
        //Add IP record to List to be inserted and move to next item
        for(SVMX_PS_VS_VanStockUtility.StockConsumptionWrapper item : validWrapperList){
            SVMXC__Installed_Product__c newInstalledProduct = new SVMXC__Installed_Product__c();
            
            if(item.getInstalledIP() != null){
                newInstalledProduct = item.getInstalledIP();
            }
            
            System.debug('VanStockHandler -  Creating New Installed Product');
            if(productStockMap != NULL && productStockMap.size() > 0 && fieldMapProductStock != NULL && fieldMapProductStock.size() > 0){
                SVMXC__Product_Stock__c productStockRecord = productStockMap.get(item.getProductStock().Id);
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapProductStock){
                //Iterate through field mapping to populate IP fields
                String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Product Stock Record field value
                        Object sourceFldVal = productStockRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                            newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Product Stock Map is Null or empty');
            }
            
            if(productSerialMap != NULL && productSerialMap.size() > 0 && fieldMapProductSerial != NULL && fieldMapProductSerial.size() > 0){
                SVMXC__Product_Serial__c productSerialRecord = productSerialMap.get(item.getProductSerial().Id);
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapProductSerial){
                    String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                    String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    //Iterate through field mapping to populate IP fields
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Product Serial Record field value
                        Object sourceFldVal = productSerialRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                                 newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Product Serial Map is Null or empty');
            }

            if(workDetailMap != NULL && workDetailMap.size() > 0 && fieldMapWorkDetail != NULL && fieldMapWorkDetail.size() > 0){
                SVMXC__Service_Order_Line__c workDetailRecord = workDetailMap.get(item.getWorkDetail().Id);
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapWorkDetail){
                    String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                    String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    //Iterate through field mapping to populate IP fields
            
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Work Detail Record field value
                        Object sourceFldVal = workDetailRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }

                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                            newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Work Detail Map is Null or empty');
            }

            if(workOrderMap != NULL && workOrderMap.size() > 0 && fieldMapWorkOrder != NULL && fieldMapWorkOrder.size() > 0){
                SVMXC__Service_Order__c workOrderRecord = workOrderMap.get(item.getWorkDetail().SVMXC__Service_Order__c);
                    for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapWorkOrder){
                    String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                    String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    //Iterate through field mapping to populate IP fields
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Work Order Record field value
                        Object sourceFldVal = workOrderRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT a Field Value');
                    }
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                                 newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Work Order Map is Null or empty');
            }

            if(locationMap != NULL && locationMap.size() > 0 && fieldMapLocation != NULL && fieldMapLocation.size() > 0){
                SVMXC__Site__c locationRecord = locationMap.get(item.getProductStock().SVMXC__Location__c);
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapLocation){
                //Iterate through field mapping to populate IP fields
                String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Product Stock Record field value
                        Object sourceFldVal = locationRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                            newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Location Map is Null or empty');
            }

            if(productMap != NULL && productMap.size() > 0 && fieldMapProduct != NULL && fieldMapProduct.size() > 0){
                Product2 productRecord = productMap.get(item.getProductStock().SVMXC__Product__c);
                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapProduct){
                //Iterate through field mapping to populate IP fields
                String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Product Stock Record field value
                        Object sourceFldVal = productRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                            newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  Product Map is Null or empty');
            }

            if(ipMap != NULL && ipMap.size() > 0 && fieldMapIP != NULL && fieldMapIP.size() > 0){
                SVMXC__Installed_Product__c ipRecord = ipMap.get(item.getInstalledProduct().Id);

                //Update field "Cloned from IP" to keep reference of old IP
                newInstalledProduct.SVMX_PS_VS_Cloned_From_IP__c = ipRecord.Id;

                for (SVMXC__ServiceMax_Config_Data__c fld : fieldMapIP){
                //Iterate through field mapping to populate IP fields
                String targetFieldName = fld.SVMXC__Target_Field_Name__c;
                String sourceFieldName = fld.SVMXC__Source_Field_Name__c;
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Field Value')){
                        //Obtain Product Stock Record field value
                        Object sourceFldVal = ipRecord.get(sourceFieldName);
                        //Verify value is not null
                        if (sourceFldVal != null){
                            //Populate Installed Product field with build field value
                            newInstalledProduct.put(targetFieldName, sourceFldVal);
                        }else{
                            if(sourceFieldName == 'SVMXC__Top_Level__c' || sourceFieldName == 'SVMXC__Parent__c'){
                                newInstalledProduct.put(targetFieldName, ipRecord.id);
                                newInstalledProduct.SVMX_PS_VS_Cloned_From_IP__c = null;
                            }
                            System.debug('VanStockHandler -  field value for field: ' + sourceFieldName + ' is null');
                        }
                    }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                    }
                    
                    if(fld.SVMXC__Parameter_Type__c != null && fld.SVMXC__Parameter_Type__c.equals('Value')){
                        if(fld.SVMXC__Display_Value__c != null && !fld.SVMXC__Display_Value__c.equals('')){
                            newInstalledProduct.put(targetFieldName, fld.SVMXC__Display_Value__c);
                        }else{
                            System.debug('VanStockHandler - field display value is Null or empty ');
                        }
                    }else{
                        System.debug('VanStockHandler -  field type is NOT Value');
                    }
                }
            }else{
                System.debug('VanStockHandler -  IP Map is Null or empty');
            }

            //add Installed Product Record to list
            installedProductRecList.add(newInstalledProduct);
        }
        return installedProductRecList;
    }

    /*****************************************************************************************************************************************
    *  Method Name : retrievePartConsumptionSetting
    *  Parameter   : --
    *  Returns     : --
    *  Description : Get All Part Consumption Settings which control the van stock functionality and store it in variables
    *******************************************************************************************************************************************/  
    @TestVisible private void retrievePartConsumptionSetting(){
        //gets all custom settings
        List<SVMX_PS_VS_Part_Consumption_Settings__c> partConsumptionSettings = SVMX_PS_VS_Part_Consumption_Settings__c.getAll().values();
        if(partConsumptionSettings != null){
            for(SVMX_PS_VS_Part_Consumption_Settings__c partConsumption : partConsumptionSettings){
                System.debug('VanStockHandler - Found Mapping :' + partConsumption.Name);
                if(partConsumption.Name.equals(MAPPING_LOCATION_TO_IP)){
                    locationToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Location Mapping :' + locationToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_PRODUCT_STOCK_TO_IP)){
                    productStockToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Product Stock Mapping :' + productStockToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_PRODUCT_TO_IP)){
                    productToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Product Mapping :' + productToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_PRODUCT_SERIAL_TO_IP)){
                    productSerialToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Product Serial Mapping :' + productSerialToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_WORK_DETAIL_TO_IP)){
                    workDetailToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Work Detail Mapping :' + workDetailToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_WORK_ORDER_TO_IP)){
                    workOrderToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Work Order Mapping :' + workOrderToIPValue);
                } else if(partConsumption.Name.equals(MAPPING_IP_TO_IP)){
                    ipToIPValue = partConsumption.SVMX_PS_VS_Text_Value__c;
                    System.debug('VanStockHandler - Found Installed Product Mapping :' + ipToIPValue);
                } else if(partConsumption.Name.equals(IS_REPARENTING_ALLOWED)){
                    isReparentingAllowed = partConsumption.SVMX_PS_VS_Setting_Value__c;
                    System.debug('VanStockHandler - Is Reparenting Allowed :' + isReparentingAllowed);
                }
            }
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : createQueryStringUsingList
    *  Parameter   : String fieldApiName - 
    *                Set<Id> idSet - Set of all technicians Ids for whom Inventory Location need to be found
    *  Returns     : String -- string that has a list of ids formatted to use in a SOQL query
    *  Description : This is an internal utility method
    *                It takes field name and set of Ids to create a part of SOQL Where clause
    *                For Example:-
    *                If fieldApiName is 'SVMXC__Product_Stock__c' and idSet has values as123, as124, as125
    *                Output String will be : SVMXC__Product_Stock__c IN ('as123','as124','as125')
    *******************************************************************************************************************************************/  
     @TestVisible private String createQueryStringUsingList(String fieldApiName, Set<Id> idSet){
        String queryString = null;
        //concatnates all given IDs to a string and adds quotes around them and comma after them.
        if(idSet != null && idSet.size() > 0 && fieldApiName != null){
            queryString = fieldApiName + ' IN (';
            for(Id recordId : idSet){
                queryString += '\'' + recordId + '\',';
            }
            queryString = queryString.substring(0,queryString.length()-1);
            queryString += ')';
        }else{
            System.debug('VanStockHandler - Either the fieldApiName or idSet is null. Hence could not create String');
        }
        return queryString;
    }

    /*****************************************************************************************************************************************
    *  Method Name : handleReparenting
    *  Parameter   : List<SVMXC__Installed_Product__c> installedProductList - List of all newly created IPs with reference to Old IP in field 
    *                                                                         "Cloned From IP"
    *  Returns     : N/A
    *  Description : This method does the reparenting of all child IP's if any to a newly created IP.
    *                For this,we are using two fields "Top-Level" and "Parent".
    *                While reparenting, we will be checking for both fields and bothe fields will be updated.
    *                This will can be controlled by Setting "Is Reparenting Allowed"
    *******************************************************************************************************************************************/  
    @TestVisible private void handleReparenting(List<SVMXC__Installed_Product__c> installedProductList){
        if(isReparentingAllowed){
            if(installedProductList != null && !installedProductList.isEmpty()){
                //Set to store Ids of IP which are de-installed
                Set<Id> oldIPSet = new Set<Id>();
                //Map of child IPs IDs as key and same record as Value which are reparented and needs to be commited to DB
                Map<Id,SVMXC__Installed_Product__c> updatedIPMap = new Map<Id,SVMXC__Installed_Product__c>();
                //List of all Parent IP as key and Child IP List as Value
                Map<Id, List<SVMXC__Installed_Product__c>> parentIpVsChildIpMap = new Map<Id, List<SVMXC__Installed_Product__c>>();
                //List of all Top-Level IP as key and Child IP List as Value
                Map<Id, List<SVMXC__Installed_Product__c>> topIpVsChildIpMap = new Map<Id, List<SVMXC__Installed_Product__c>>();

                for(SVMXC__Installed_Product__c ip : installedProductList){
					// Added null check for PRB0044930
					if(ip.SVMX_PS_VS_Cloned_From_IP__c != null)
						oldIPSet.add(ip.SVMX_PS_VS_Cloned_From_IP__c);
                }


                if(oldIPSet.size() > 0){
                    //For all the Installed Products whose parents have been cloned, create a map of parent vs its list of child records
                    //Also created map of Top-Level and its child IPs
                    for(SVMXC__Installed_Product__c childIp : [SELECT Id, Name, SVMXC__Parent__c,SVMXC__Product__c,SVMXC__Top_Level__c
                                                                FROM SVMXC__Installed_Product__c 
                                                                WHERE SVMXC__Status__c = 'Installed' AND (SVMXC__Top_Level__c IN :oldIPSet
                                                                OR SVMXC__Parent__c in :oldIPSet)]){
                        
                        if(childIp.SVMXC__Parent__c != null){
                            if(!parentIpVsChildIpMap.containskey(childIp.SVMXC__Parent__c)){
                                parentIpVsChildIpMap.put(childIp.SVMXC__Parent__c, new List<SVMXC__Installed_Product__c>());
                            }
                            parentIpVsChildIpMap.get(childIp.SVMXC__Parent__c).add(childIp);
                        }else if(childIp.SVMXC__Top_Level__c != null){
                            if(!topIpVsChildIpMap.containskey(childIp.SVMXC__Top_Level__c)){
                                topIpVsChildIpMap.put(childIp.SVMXC__Top_Level__c, new List<SVMXC__Installed_Product__c>());
                            }
                            topIpVsChildIpMap.get(childIp.SVMXC__Top_Level__c).add(childIp);
                        }else {
                            System.debug('VanStockHandler - ' + childIp.Name + ' - No Data present for representing Hiearchy');
                        }         
                    }

                    if(!parentIpVsChildIpMap.isEmpty() || !topIpVsChildIpMap.isEmpty()){
                        for(SVMXC__Installed_Product__c ip : installedProductList){
                            if(ip.SVMX_PS_VS_Cloned_From_IP__c != null){
                                List<SVMXC__Installed_Product__c> childIPforParentFieldList 
                                                    = parentIpVsChildIpMap.containskey(ip.SVMX_PS_VS_Cloned_From_IP__c)?parentIpVsChildIpMap.get(ip.SVMX_PS_VS_Cloned_From_IP__c):new List<SVMXC__Installed_Product__c>();

                                for(SVMXC__Installed_Product__c childIP : childIPforParentFieldList){
                                    childIP.SVMXC__Parent__c = ip.id;
                                    updatedIPMap.put(childIP.Id, childIP);
                                }

                                 List<SVMXC__Installed_Product__c> childIPforTopLevelFieldList 
                                                    =  topIpVsChildIpMap.containskey(ip.SVMX_PS_VS_Cloned_From_IP__c)?topIpVsChildIpMap.get(ip.SVMX_PS_VS_Cloned_From_IP__c):new List<SVMXC__Installed_Product__c>();

                                for(SVMXC__Installed_Product__c childIP : childIPforTopLevelFieldList){
                                    if(updatedIPMap.containsKey(childIP.Id)){
                                        childIP = updatedIPMap.get(childIP.Id);
                                        childIP.SVMXC__Top_Level__c = ip.id;
                                    }else{
                                        childIP.SVMXC__Top_Level__c = ip.id;
                                        updatedIPMap.put(childIP.Id, childIP);
                                    }
                                }
                            }
                        }
                    }else{
                        System.debug('VanStockHandler - No Data to reparent');
                    }

                    //Commit Reparented Record to Database
                    if(updatedIPMap != NULL && updatedIPMap.size() > 0){
                        
                        //Commit Changes to Database
                        Savepoint savePointRec = Database.setSavepoint();

                        try{
                            System.debug('VanStockHandler - Committing Reparented Installed Products');
                            update updatedIPMap.values();
                            System.debug('VanStockHandler - Committed Reparented Installed Products');
                        }catch(Exception exceptionValue){
                            System.debug('VanStockHandler - Could not reparent installed products ' + exceptionValue.getMessage());
                            Database.rollback(savePointRec);
                            throw exceptionValue;
                        }
                    }else{
                        System.debug('VanStockHandler - No installed product found for reparenting');
                    }
                }else{
                    System.debug('VanStockHandler - No IPs to reparent');
                }
            }else{
                System.debug('VanStockHandler - While Reparenting, No IP found to reparent');
            }
        }else{
            System.debug('VanStockHandler - No Reparenting Allowed. Hence ignore reparenting');
        }
    }
}
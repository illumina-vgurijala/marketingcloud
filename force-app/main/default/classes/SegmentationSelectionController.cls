/**
 * @author Akshay Mohan 
 * @date   12-Oct-2018
 * @description    Controller class for custom component which let's user select Segmentation fields
 * Test Class Coverage For 75% coverage: TestSegmentationSelectionController
 * Test Class Coverage For 90% coverage: TestSegmentationSelectionController
 * Modification Log:
*  ------------------------------------------------------------------------------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Akshay Mohan             12-Oct-2018         Original
*   Kushagra Desai           27-Aug-2019         DCP-28584 : Updating Account plan
*   Kushagra Desai           20-Nov-2019         INC0240834 : Update all Account Plan related to Account only if records are updated
*   Vignesh S                12-Feb-2019         DCP-31443 : Adding logic - Variable for Segmentation Validation Bypass.
*   Rahul Bishnoi            04-Feb-2021         INC0306304
*   Aman Tyagi               30-Mar-2022         CodeScan Fixes
*   Nesar Mohan              18-May-2022         DCP-53342: Added checks for ISR inclusion
*   Satya Swain              19-May-2022         DCP-53342: Refactored the methods
*   Adyasha                  01-Jun-2022         DCP-53375: Splitting of DML Transactions as added Validation in Market Segment Trigger
*   Iram Malik               14-Jul-2022         Codescan Fixes
*   Himanshu                 24-Aug-2022         DCP-56003 Added field Eligible To Estimate Consumable
*  -----------------------------------------------------------------------------------          
*   Satya Swain              30-Aug-2022         INC0420918 : Modified scenarios in checkIfReadOnlyForOpenOfferFields, getTerritoryRestrictionsForOpenOffer
*   Adyasha                  15-Sep-2022         DCP-56397: Added field Sequencing_Liquid_Bx_Cancer_Screening__c
*   Gopinath Reddy           21-Mar-2023         DCP-58180 : Added the logic on loadPage method to check country to poplulate the segmention label
 -------------------------------------------------------------------------------------------------------------------------------------------------------------          
*/
public with sharing class SegmentationSelectionController {

    // DCP-28584
    public static Boolean hasUpdate = false;
    private static final String LOG_TITLE = 'SegmentationSelectionController';
    public static final String MARKET_SEGMENT_OBJECT_NAME = 'Market_Segment__c';
    public static final String ACCOUNT_OBJECT_NAME = 'Account'; //DCP-50649
	public static final String ACCOUNT_BILLING_COUNTRY_US = 'US'; //DCP-58180
    public static final String MARKET_SEGMENT_PICKLIST_NAME = 'Market_Segment__c';
    public static final String MARKET_SUB_SEGMENT_PICKLIST_NAME = 'Market_Sub_Segment__c';
    public static final String CLINICAL_TYPE_PICKLIST_NAME = 'Clinical_Type__c';
    public static final String CUSTOMER_TYPE_PICKLIST_NAME = 'Customer_Type__c';
    public static final String CUSTOMER_SUB_TYPE_PICKLIST_NAME = 'Customer_Sub_Type__c';
    public static final String FOR_PROFIT_COMPANY_PICKLIST_NAME = 'For_Profit_Company__c'; //DCP-50649
    public static final String PURCHASESPRODUCTSSHIPPINGTOUS = 'Purchases_Products_Shipping_to_U_S__c'; //DCP-50649
    public static final String CLINICAL_ONCOLOGY_SCREENING_DX_TESTING_PICKLIST_NAME = 'Clinical_Oncology_Screening_Dx_Testing__c'; //DCP-50649
    public static final String ONCOLOGY_LAB_MANUFACTURER_COMPARISON = 'Oncology_Lab_Manufacturer_Comparison__c'; //DCP-51002
    public static final String SEQUENCING_LIQUID_BX_CANCER_SCREENING = 'Sequencing_Liquid_Bx_Cancer_Screening__c'; //DCP-56397
    public static final Set<String> SET_PROFILES_ALLOWED_TO_SUBMIT_ERP = new Set<String>{Label.SalesRepProfileName,Label.Profile_Marketing_Lead_Qualification};
    public static final Set<String> SET_SUPER_USER_PROFILES = new Set<String>{Label.ProfileSystemAdmin,Label.ProfileDataSteward,Label.Profile_Release_Manager};
    
    /* Enum to track type of Transaction as part of DCP-53375*/
    public Enum DML_TRANSACTION { IS_INSERT, IS_UPDATE, IS_DELETE, IS_DELETE_INSERT, IS_DELETE_UPDATE, IS_INSERT_UPDATE, IS_DELETE_INSERT_UPDATE }
    
    
    /*
    * Author : Akshay Mohan 
    * @Description : Wrapper class to store market segment details
    * @param: NA
    * @return: NA
    */
    public class MarketSegmentWrapper {
        String strRecordId;
        String strMarketSegment;
        List<String> lstSubSegments = new List<String>();
        Decimal decAllocation;
        Boolean booDelete=false;
        /*
        * @Author: Akshay Mohan 
        * @Description : constructor of MarketSegmentWrapper class
        * @param: NA
        * @return:NA
        */
        public MarketSegmentWrapper() { }

        /*
        * @Description : parameterized constructor of MarketSegmentWrapper class
        * @param: Market_Segment__c obj  
        */
        public MarketSegmentWrapper(Market_Segment__c obj) {
            strRecordId = obj.Id;
            strMarketSegment = obj.Market_Segment__c;
            decAllocation = obj.Percent_Allocation__c;

            if (String.isNotBlank(obj.Market_Sub_Segment__c)) {
                lstSubSegments.addAll(obj.Market_Sub_Segment__c.split(';'));                
            }
        }

        /*
        * @Description : method to get the sObject based on id
        * @param: Id idAccount
        * @return: Market_Segment__c
        */
        public Market_Segment__c getSObject(Id idAccount) {
            Market_Segment__c objSeg = getSObject();
            objSeg.Account__c = idAccount;
            return objSeg;
        }

        /*
        * @Description : method to get the sObject
        * @param: none
        * @return: Market_Segment__c
        */
        public Market_Segment__c getSObject() {
            Market_Segment__c objSeg = new Market_Segment__c(Id=strRecordId, Market_Segment__c = strMarketSegment,
                                                            Percent_Allocation__c = decAllocation);
            objSeg.Market_Sub_Segment__c ='';
            for (String strVal : lstSubSegments) {
                objSeg.Market_Sub_Segment__c+=strVal+';';
            }
            return objSeg;
        }
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To Initialize the component
    *  @param        : String strAccountId
    *  @return       : String JSON
    */
    @AuraEnabled
    public static String loadPage(String strAccountId) {   
        ilib_LogEvent.setTitle(LOG_TITLE + '.loadPage()');
                    
        try {
            ilib_LogEvent.push(LOG_TITLE + 'reloadRecords()');
            ilib_LogEvent.message('strAccountId ::: '+strAccountId);                 
            List<MarketSegmentWrapper> lstMarketSegments = loadMarketSegments(strAccountId);            
            Map<String,Object> mapStringToPicklistValues = getMapOfStringToPicklistValues();
                    
            //load labels
            Map<String,String> labelToValue = getMapOfLabels();        
        
            Boolean booObjectHasEditPermission = Schema.sObjectType.Market_Segment__c.isUpdateable();                        
            ilib_LogEvent.message('booObjectHasEditPermission--> '+ booObjectHasEditPermission);
            

            //Only users with permission set can edit this field
            Boolean booHasEditPermission = Schema.sObjectType.Account.fields.Population_Genomics__c.isUpdateable();
            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1][0].IsSandbox;
            String submitRequestLabel=Label.Submit_Segmentation_Request;
			String submitSegReqLabel = Label.Submit_Segment_Request; //DCP-58180
            Account objAccount = new AccountsSelector().selectLoggedInAccountForUser(strAccountId)[0];
            Boolean booDisplaySubmitButton = String.isBlank(objAccount.ERP_Customer_Id__c) ? false : true;
            if(isSandbox) {
                submitRequestLabel=Label.Submit_Segmentation_Request_Sandbox;
            }
			if(objAccount.BillingCountryCode == ACCOUNT_BILLING_COUNTRY_US){ //DCP-58180
                submitSegReqLabel = Label.Submit_Segment_Request_US;
            }
            
            Map<String,Boolean> mapAccessbilityBooleanOptions = new Map<String,Boolean>();
            
            setAccessibilityRulesForOpenOfferSection(objAccount, mapAccessbilityBooleanOptions);
        
            labelToValue.put('SegmentSubmitURL',submitRequestLabel);
            labelToValue.put('Submit',submitSegReqLabel);    //DCP-58180
			
            ilib_LogEvent.pop();

        return '{"lstMarketSegments" : '+JSON.serialize(lstMarketSegments)
            + ',"lstMarketSegmentPicklistValues" : '+JSON.serialize(mapStringToPicklistValues.get('lstMarketSegmentPicklistValues'))
            + ',"marketSegmentToSubSegment" : '+JSON.serialize(mapStringToPicklistValues.get('marketSegmentToSubSegment'))
            + ',"lstClinicalTypePicklistValues" : '+JSON.serialize(mapStringToPicklistValues.get('lstClinicalTypePicklistValues'))
            + ',"lstCustomerTypePicklistValues" : '+JSON.serialize(mapStringToPicklistValues.get('lstCustomerTypePicklistValues'))
            + ',"customerTypeToSubType" : '+JSON.serialize(mapStringToPicklistValues.get('customerTypeToSubType'))
            + ',"dummyMarketSegment" : '+JSON.serialize(new MarketSegmentWrapper())
            + ',"booHasEditPermission" : '+booHasEditPermission
            + ',"booObjectHasEditPermission" : '+booObjectHasEditPermission
            + ',"mapLabels" : '+JSON.serialize(labelToValue)
            + ',"lstPurchasesProductsShippingToUS" :'+JSON.serialize(mapStringToPicklistValues.get('lstPurchasesProductsShippingToUS'))
            + ',"lstForProfitCompany" :'+JSON.serialize(mapStringToPicklistValues.get('lstForProfitCompany'))
            + ',"lstClinicalOncologyScreeningDxTesting" :'+JSON.serialize(mapStringToPicklistValues.get('lstClinicalOncologyScreeningDxTesting'))
            + ',"lstSequencingLiquidBxCancerScreening" :'+JSON.serialize(mapStringToPicklistValues.get('lstSequencingLiquidBxCancerScreening'))//DCP-56397
            + ',"mapClinicalOncologyToSequencingLiquidBx" :'+JSON.serialize(mapStringToPicklistValues.get('mapClinicalOncologyToSequencingLiquidBx'))//DCP-56397
            + ',"lstOncologyLabManufacturerComparison" :'+JSON.serialize(mapStringToPicklistValues.get('lstOncologyLabManufacturerComparison'))
            + ',"CustomerERPID": '+objAccount.ERP_Customer_Id__c 
            + ',"objAccount": '+JSON.serialize(objAccount) 
            + ',"DisplaySubmitButton": '+booDisplaySubmitButton            
            + ',"boolComparisonCustomerFieldsFLS": '+mapAccessbilityBooleanOptions.get('boolComparisonCustomerFieldsFLS')
            + ',"conditionalReadOnlyAccessForOO": '+mapAccessbilityBooleanOptions.get('conditionalReadOnlyAccessForOO')
            + '}';

        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE +'.loadPage()', strAccountId, e);
            throw new AuraHandledException(e.getMessage()); 
        } finally {
            ilib_LogEvent.emit();
        }
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To reload existing records
    *  @param        : String strAccountId
    *  @return       : String JSON
    */    
    public static String reloadRecords(String strAccountId) {
        ilib_LogEvent.push(LOG_TITLE + 'reloadRecords()');
        ilib_LogEvent.message('strAccountId ::: '+strAccountId);
        
        List<MarketSegmentWrapper> lstMarketSegments = loadMarketSegments(strAccountId);

        ilib_LogEvent.pop();
        return '{"lstMarketSegments" : ' + JSON.serialize(lstMarketSegments)+'}';
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To load Market Segments for an account
    *  @param        : String strAccountId
    *  @return       : List<MarketSegmentWrapper> wrapper records of market segments
    */
    private static List<MarketSegmentWrapper> loadMarketSegments(Id idAccount) {
        ilib_LogEvent.setTitle(LOG_TITLE + '.loadMarketSegments()');
        ilib_LogEvent.push(LOG_TITLE + 'loadMarketSegments()');
        List<MarketSegmentWrapper> lstMarketSegments = new List<MarketSegmentWrapper>();
        for (Market_Segment__c objSeg : new MarketSegmentSelector().selectByAccountId(idAccount)) {
            lstMarketSegments.add(new MarketSegmentWrapper(objSeg));
        }        

        ilib_LogEvent.message('lstMarketSegments ::: '+lstMarketSegments);    
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
        return lstMarketSegments;
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To save Market Segments for an account
    *  @param        : strAccount Id of the Account
    *  @param        : String strJSON
    *  @return       : List<MarketSegmentWrapper> wrapper records of market segments
    */
    @AuraEnabled
    public static String saveMarketSegments(String strAccount,String strJSON) {
        ilib_LogEvent.setTitle(LOG_TITLE + '.saveMarketSegments()');
        ilib_LogEvent.push(LOG_TITLE + '.saveMarketSegments()');
        
        ilib_LogEvent.message('strAccount ::: '+strAccount);
        ilib_LogEvent.message('strJSON: '+strJSON);
        DML_TRANSACTION objTransaction = null;
        try {
            List<MarketSegmentWrapper> lstMarketSegments = (List<MarketSegmentWrapper>)JSON.deserialize(strJSON,List<MarketSegmentWrapper>.class);
            ilib_LogEvent.message('lstMarketSegments: '+lstMarketSegments);

            List<Market_Segment__c> lstMarketSegmentsToUpdate = new List<Market_Segment__c>();
            List<Market_Segment__c> lstMarketSegmentsToInsert = new List<Market_Segment__c>();
            List<Market_Segment__c> lstMarketSegmentsToDelete = new List<Market_Segment__c>();

            for (MarketSegmentWrapper wrapSeg : lstMarketSegments) {
                if (String.isBlank(wrapSeg.strRecordId)) {                                       
                    lstMarketSegmentsToInsert.add(wrapSeg.getSObject(strAccount));
                } else if (wrapSeg.booDelete) {
                    lstMarketSegmentsToDelete.add(wrapSeg.getSObject());
                } else {
                    lstMarketSegmentsToUpdate.add(wrapSeg.getSObject());
                }
            }

            objTransaction = prepareTransactionEnum(lstMarketSegmentsToInsert,lstMarketSegmentsToUpdate,lstMarketSegmentsToDelete,objTransaction);         
            performDMLForMarketSegments(lstMarketSegmentsToInsert,lstMarketSegmentsToUpdate,lstMarketSegmentsToDelete,objTransaction);

            // DCP-28584 : Update all Account Plan related to Account only if records are updated
            hasUpdate = true;
            
            ilib_LogEvent.pop();

            return reloadRecords(strAccount);   

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        } finally {
            ilib_LogEvent.emit();
        }
    }
    /*
    *  @author       : Adyasha
    *  @description  : prepare DML_TRANSACTION enum based on type of DML eligibility
    *  @param        : List<Market_Segment__c> lstMarketSegmentsToInsert,List<Market_Segment__c> lstMarketSegmentsToUpdate
    *  @param        : List<Market_Segment__c> lstMarketSegmentsToDelete,DML_TRANSACTION objTransaction
    *  @return       : DML_TRANSACTION
    */
    private static DML_TRANSACTION prepareTransactionEnum(List<Market_Segment__c> lstMarketSegmentsToInsert,List<Market_Segment__c> lstMarketSegmentsToUpdate, List<Market_Segment__c> lstMarketSegmentsToDelete,DML_TRANSACTION objDMLTransaction) {
        Boolean boolDeletionListEmpty = lstMarketSegmentsToDelete.isEmpty();
        Boolean boolUpdationListEmpty = lstMarketSegmentsToUpdate.isEmpty();
        Boolean boolInsertionListEmpty = lstMarketSegmentsToInsert.isEmpty();
        DML_TRANSACTION objTransaction = objDMLTransaction; 

        if(boolDeletionListEmpty) {
            if(!boolInsertionListEmpty && boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_INSERT; }
            else if(boolInsertionListEmpty && !boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_UPDATE; }
            else if(!boolInsertionListEmpty && !boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_INSERT_UPDATE; }
        } else {
            if(!boolInsertionListEmpty && !boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_DELETE_INSERT_UPDATE; }
            else if(!boolInsertionListEmpty && boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_DELETE_INSERT; }
            else if(boolInsertionListEmpty && !boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_DELETE_UPDATE; }
            else if(boolInsertionListEmpty && boolUpdationListEmpty) { objTransaction = DML_TRANSACTION.IS_DELETE; }
        }
        return objTransaction;
    }

    /*
    *  @author       : Adyasha
    *  @description  : perform DMLs for Market Segment based on Enum Values
    *  @param        : List<Market_Segment__c> lstMarketSegmentsToInsert,List<Market_Segment__c> lstMarketSegmentsToUpdate
    *  @param        : List<Market_Segment__c> lstMarketSegmentsToDelete,DML_TRANSACTION objTransaction
    *  @return       : void
    */
    private static void performDMLForMarketSegments(List<Market_Segment__c> lstMarketSegmentsToInsert,List<Market_Segment__c> lstMarketSegmentsToUpdate, List<Market_Segment__c> lstMarketSegmentsToDelete,DML_TRANSACTION objTransaction) {
        switch on objTransaction {
            when IS_DELETE_INSERT_UPDATE {
                ilib_LogEvent.message('delete, update and insert ::: ');
                MarketSegments.setFlagForAllocationEvaluation(false);
                delete lstMarketSegmentsToDelete;
                insert lstMarketSegmentsToInsert;
                MarketSegments.setFlagForAllocationEvaluation(true);
                update lstMarketSegmentsToUpdate;
            }
            when IS_DELETE_INSERT {
                ilib_LogEvent.message('delete, insert ::: ');
                MarketSegments.setFlagForAllocationEvaluation(false);
                delete lstMarketSegmentsToDelete;
                MarketSegments.setFlagForAllocationEvaluation(true);
                insert lstMarketSegmentsToInsert;
            }
            when IS_DELETE_UPDATE {
                ilib_LogEvent.message('delete, update ::: ');
                MarketSegments.setFlagForAllocationEvaluation(false);
                delete lstMarketSegmentsToDelete;
                MarketSegments.setFlagForAllocationEvaluation(true);
                update lstMarketSegmentsToUpdate;
            }
            when IS_INSERT {
                ilib_LogEvent.message('simple insert ::: ');
                MarketSegments.setFlagForAllocationEvaluation(true);
                insert lstMarketSegmentsToInsert;
            }
            when IS_UPDATE {
                ilib_LogEvent.message('simple update ::: ');
                MarketSegments.setFlagForAllocationEvaluation(true);
                update lstMarketSegmentsToUpdate;
            }
            when IS_DELETE {
                ilib_LogEvent.message('simple delete ::: ');
                MarketSegments.setFlagForAllocationEvaluation(true);
                delete lstMarketSegmentsToDelete;
            }
            when IS_INSERT_UPDATE {
                ilib_LogEvent.message('insert and update ::: ');
                MarketSegments.setFlagForAllocationEvaluation(false);
                insert lstMarketSegmentsToInsert;
                MarketSegments.setFlagForAllocationEvaluation(true);
                update lstMarketSegmentsToUpdate;
            }                
        }
        MarketSegments.setFlagForAllocationEvaluation(false);
    }
    /*
    *  @author       : Satya Swain
    *  @description  : get picklist values list for Account Picklist fields
    *  @param        : none
    *  @return       : Map<String,Object> mapStringToPicklistValues
    */
    private static Map<String,Object> getMapOfStringToPicklistValues() {
        Map<String,Object> mapStringToPicklistValues = new Map<String,Object>();
        Map<String, SObjectField> mapFields = UtilsObject.getSObjectFields(MARKET_SEGMENT_OBJECT_NAME);
        //get market segment picklist
        List<PickListValueWrapper> lstMarketSegmentPicklistValues = 
            UtilsObject.getPicklistValuesWrapper(mapFields,MARKET_SEGMENT_PICKLIST_NAME,Label.UI_Label_Segmentation_Selection_Select_Market_Segment);
        //get sub segment picklist
        Map<String, List<PickListValueWrapper>> marketSegmentToSubSegment = 
            UtilsObject.getDependentPicklistValues(mapFields,MARKET_SEGMENT_PICKLIST_NAME,MARKET_SUB_SEGMENT_PICKLIST_NAME,Label.UI_Label_Segmentation_Selection_Select_Market_Sub_Segment);

        // DCP-50649 Developer: Dushyant Srivastava
        mapFields = UtilsObject.getSObjectFields(ACCOUNT_OBJECT_NAME);
       //get clinical type
        List<PickListValueWrapper> lstClinicalTypePicklistValues = 
            UtilsObject.getPicklistValuesWrapper(mapFields,CLINICAL_TYPE_PICKLIST_NAME,Label.UI_Label_Segmentation_Selection_Select_Clinical_Type);
        //get customer Type
        List<PickListValueWrapper> lstCustomerTypePicklistValues = 
            UtilsObject.getPicklistValuesWrapper(mapFields,CUSTOMER_TYPE_PICKLIST_NAME,Label.UI_Label_Segmentation_Selection_Select_Customer_Type);
        //get customer sub Type
        Map<String, List<PickListValueWrapper>> customerTypeToSubType = 
            UtilsObject.getDependentPicklistValues(mapFields,CUSTOMER_TYPE_PICKLIST_NAME,CUSTOMER_SUB_TYPE_PICKLIST_NAME,Label.UI_Label_Segmentation_Selection_Select_Customer_Sub_Type);
        //get Purchases Products Shipping to U.S.
        List<PickListValueWrapper> lstPurchasesProductsShippingToUS = 
            UtilsObject.getPicklistValuesWrapper(mapFields,PURCHASESPRODUCTSSHIPPINGTOUS,Label.UI_Label_Comparison_Customer_Information);
        //get For-Profit Company
        List<PickListValueWrapper> lstForProfitCompany = 
            UtilsObject.getPicklistValuesWrapper(mapFields,FOR_PROFIT_COMPANY_PICKLIST_NAME,Label.UI_Label_Comparison_Customer_Information);
        //get Clinical Oncology Screening/Dx Testing
        List<PickListValueWrapper> lstClinicalOncologyScreeningDxTesting = 
            UtilsObject.getPicklistValuesWrapper(mapFields,CLINICAL_ONCOLOGY_SCREENING_DX_TESTING_PICKLIST_NAME,Label.UI_Label_Comparison_Customer_Information);
        //get Oncology Lab/Manufacturer Comparison	
        List<PickListValueWrapper> lstOncologyLabManufacturerComparison = 
            UtilsObject.getPicklistValuesWrapper(mapFields,ONCOLOGY_LAB_MANUFACTURER_COMPARISON,Label.UI_Label_Comparison_Customer_Information); 
        //get Sequencing Liquid Bx Cancer Screening --> DCP-56397
        List<PickListValueWrapper> lstSequencingLiquidBxCancerScreening = 
            UtilsObject.getPicklistValuesWrapper(mapFields,SEQUENCING_LIQUID_BX_CANCER_SCREENING,Label.UI_Label_Comparison_Customer_Information); 
        Map<String, List<PickListValueWrapper>> mapClinicalOncologyToSequencingLiquidBx = 
        UtilsObject.getDependentPicklistValues(mapFields,CLINICAL_ONCOLOGY_SCREENING_DX_TESTING_PICKLIST_NAME,SEQUENCING_LIQUID_BX_CANCER_SCREENING,Label.UI_Label_Comparison_Customer_Information);

    
        mapStringToPicklistValues.put('lstMarketSegmentPicklistValues',lstMarketSegmentPicklistValues);
        mapStringToPicklistValues.put('marketSegmentToSubSegment',marketSegmentToSubSegment);
        mapStringToPicklistValues.put('lstClinicalTypePicklistValues',lstClinicalTypePicklistValues);
        mapStringToPicklistValues.put('lstCustomerTypePicklistValues',lstCustomerTypePicklistValues);
        mapStringToPicklistValues.put('customerTypeToSubType',customerTypeToSubType);
        mapStringToPicklistValues.put('lstPurchasesProductsShippingToUS',lstPurchasesProductsShippingToUS);
        mapStringToPicklistValues.put('lstForProfitCompany',lstForProfitCompany);
        mapStringToPicklistValues.put('lstClinicalOncologyScreeningDxTesting',lstClinicalOncologyScreeningDxTesting);
        mapStringToPicklistValues.put('lstOncologyLabManufacturerComparison',lstOncologyLabManufacturerComparison);
        //DCP-56397
        mapStringToPicklistValues.put('lstSequencingLiquidBxCancerScreening',lstSequencingLiquidBxCancerScreening);
        mapStringToPicklistValues.put('mapClinicalOncologyToSequencingLiquidBx',mapClinicalOncologyToSequencingLiquidBx);
        // End of DCP-56397

        return mapStringToPicklistValues;
    }
    
    /*
    *  @author       : Satya Swain
    *  @description  : get map of all labels to be used in LWC
    *  @param        : none
    *  @return       : Map<String,String>
    */
    private static Map<String,String> getMapOfLabels() {
        Map<String,String> labelToValue = new Map<String,String>();
        labelToValue.put('UI_Label_Segmentation_Selection_Heading',Label.UI_Label_Segmentation_Selection_Heading);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Market_Segment',Label.UI_Label_Segmentation_Selection_Field_Market_Segment);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Market_Sub_Segment',Label.UI_Label_Segmentation_Selection_Field_Market_Sub_Segment);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Allocation',Label.UI_Label_Segmentation_Selection_Field_Allocation);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Clinical_Type',Label.UI_Label_Segmentation_Selection_Field_Clinical_Type);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Customer_Type',Label.UI_Label_Segmentation_Selection_Field_Customer_Type);
        labelToValue.put('UI_Label_Segmentation_Selection_Field_Customer_Sub_Type',Label.UI_Label_Segmentation_Selection_Field_Customer_Sub_Type);
        labelToValue.put('UI_Label_Segmentation_Selection_Market_Segment_Disclaimer',Label.UI_Label_Segmentation_Selection_Market_Segment_Disclaimer);
        labelToValue.put('Cancel',Label.Cancel);
        labelToValue.put('Save',Label.Save);
        labelToValue.put('UI_Error_Message_Segmentation_Selection_Allocation_Total',Label.UI_Error_Message_Segmentation_Selection_Allocation_Total);
        labelToValue.put('UI_Label_Segmentation_Selection_Additional_Heading',Label.UI_Label_Segmentation_Selection_Additional_Heading);
        labelToValue.put('UI_Button_Segmentation_Selection_Even_Split',Label.UI_Button_Segmentation_Selection_Even_Split);
        labelToValue.put('UI_Error_Message_Segmentation_Selection_Complete_Required_fields',Label.UI_Error_Message_Segmentation_Selection_Complete_Required_fields);
        labelToValue.put('UI_Error_Message_Segmentation_Selection_Submit_Error',Label.UI_Error_Message_Segmentation_Selection_Submit_Error);
        labelToValue.put('UI_Error_Message_Segmentation_Selection_Account_Locked',Label.UI_Error_Message_Segmentation_Selection_Account_Locked);
        labelToValue.put('UI_Error_Message_Segmentation_Selection_Market_Segment_Locked',Label.UI_Error_Message_Segmentation_Selection_Market_Segment_Locked);
        labelToValue.put('UI_Error_Message_ERP_Submit_Error',Label.UI_Error_Message_ERP_Submit_Error); //DCP-50649
        labelToValue.put('UI_Label_Purchases_Products_Shipping_to_U_S',Label.UI_Label_Purchases_Products_Shipping_to_U_S);
        labelToValue.put('UI_Label_Comparison_Customer_Information_US_Accounts_Only',Label.UI_Label_Comparison_Customer_Information_US_Accounts_Only);
        labelToValue.put('UI_Label_For_Profit_Company',Label.UI_Label_For_Profit_Company);
        labelToValue.put('UI_Label_Clinical_Oncology_Screening_Dx_Testing',Label.UI_Label_Clinical_Oncology_Screening_Dx_Testing);
        labelToValue.put('UI_Label_Oncology_Lab_Manufacturer_Comparison',Label.UI_Label_Oncology_Lab_Manufacturer_Comparison);
        labelToValue.put('Help_Text_Purchases_Products_Shipping_to_U_S',Account.Purchases_Products_Shipping_to_U_S__c.getDescribe().getInlineHelpText());
        labelToValue.put('Help_Text_For_Profit_Company',Account.For_Profit_Company__c.getDescribe().getInlineHelpText());
        labelToValue.put('Help_Text_Clinical_Oncology_Screening_Dx_Testing',Account.Clinical_Oncology_Screening_Dx_Testing__c.getDescribe().getInlineHelpText());
        labelToValue.put('Help_Text_Oncology_Lab_Manufacturer_Comparison',Account.Oncology_Lab_Manufacturer_Comparison__c.getDescribe().getInlineHelpText());
        labelToValue.put('UI_Error_Message_Comparison_Customer_Information_Field_Access_Error',Label.UI_Error_Message_Comparison_Customer_Information_Field_Access_Error);
        labelToValue.put('US',Label.US);
        labelToValue.put('UI_Label_Segmentation_Selection_Select_Clinical_Type',Label.UI_Label_Segmentation_Selection_Select_Clinical_Type);
        labelToValue.put('UI_Label_Segmentation_Selection_Select_Customer_Type',Label.UI_Label_Segmentation_Selection_Select_Customer_Type);
        labelToValue.put('UI_Label_Segmentation_Selection_Select_Customer_Sub_Type',Label.UI_Label_Segmentation_Selection_Select_Customer_Sub_Type);
        labelToValue.put('UI_Label_Comparison_Customer_Information',Label.UI_Label_Comparison_Customer_Information);
        labelToValue.put('AccountProspect',Label.AccountProspect);
        labelToValue.put('AccountRecordTypeDeveloperNameChannelPartnerProspect',Label.AccountRecordTypeDeveloperNameChannelPartnerProspect);
        labelToValue.put('Help_Signed_Open_Offer',Account.Signed_Open_Offer__c.getDescribe().getInlineHelpText());
        labelToValue.put('Help_Open_Offer_Comparison_Customer',Account.Open_Offer_Comparison_Customer__c.getDescribe().getInlineHelpText());
        labelToValue.put('Help_Oncology_Lab_Manufacturer_Comparison',Account.Oncology_Lab_Manufacturer_Comparison__c.getDescribe().getInlineHelpText());
        labelToValue.put('UI_Label_Open_Offer_Comparison_Customer',Label.UI_Label_Open_Offer_Comparison_Customer);
        labelToValue.put('UI_Label_Signed_Open_Offer',Label.UI_Label_Signed_Open_Offer);
        labelToValue.put('UI_Message_Segmentation_Change_Guidance',Label.UI_Message_Segmentation_Change_Guidance);
		labelToValue.put('UI_Message_Segmentation_Change_Guidance_US',Label.UI_Message_Segmentation_Change_Guidance_US);
        labelToValue.put('UI_Label_Segmentation_Add_Row',Label.UI_Label_Segmentation_Add_Row);
        labelToValue.put('UI_Label_Segmentation_Delete_Row',Label.UI_Label_Segmentation_Delete_Row);
        labelToValue.put('Help_Eligible_To_Estimate_Consumable_Spend',Account.Eligible_To_Estimate_Consumable_Spend__c.getDescribe().getInlineHelpText());
        labelToValue.put('UI_Label_Eligible_To_Estimate_Consumable_Spend',Label.UI_Label_Eligible_To_Estimate_Consumable_Spend);
        labelToValue.put('UI_Label_Segmentation_Selection_Insufficient_Access_Error',Label.UI_Label_Segmentation_Selection_Insufficient_Access_Error);
        labelToValue.put('UI_Label_Yes',Label.UI_Label_Yes); //DCP-56397
        labelToValue.put('UI_Label_Sequencing_Liquid_Bx_Cancer_Screening',Label.UI_Label_Sequencing_Liquid_Bx_Cancer_Screening); //DCP-56397
        labelToValue.put('Help_Sequencing_Liquid_Bx_Cancer_Screening',Account.Sequencing_Liquid_Bx_Cancer_Screening__c.getDescribe().getInlineHelpText()); //DCP-56397
        labelToValue.put('UI_Error_Message_Sequencing_Liquid_Bx_Cancer_Screening_Required',Label.UI_Error_Message_Sequencing_Liquid_Bx_Cancer_Screening_Required); //DCP-56397
        return labelToValue;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : calculate accessibility logic for Open Offer section 
    *  @param        : none
    *  @return       : void
    */
    private static void setAccessibilityRulesForOpenOfferSection(Account objAccount, Map<String,Boolean> mapAccessbilityBooleanOptions) {
        Boolean boolComparisonCustomerFieldsFLS = false;
        Boolean conditionalReadOnlyAccessForOO = true;        
        
        List<String> accountComparisonCustomerFields = Label.Account_Comparison_Customer_Information_Fields.split(',');
        Map<String,Schema.SObjectField> mapAccountSchema = Schema.SObjectType.Account.fields.getMap();
        for (String fieldToCheck : accountComparisonCustomerFields) {
            if (!mapAccountSchema.get(fieldToCheck).getDescribe().isCreateable() && !mapAccountSchema.get(fieldToCheck).getDescribe().isUpdateable()) {
                boolComparisonCustomerFieldsFLS = true;
            }
        }

        Profile objCurrentUserProfile = new ProfilesSelector().getProfilesById(new Set<Id>{UserInfo.getProfileId()})[0];
        
        conditionalReadOnlyAccessForOO = !SET_SUPER_USER_PROFILES.contains(objCurrentUserProfile.Name);
        
        if(conditionalReadOnlyAccessForOO) {
            boolComparisonCustomerFieldsFLS = getTerritoryRestrictionsForOpenOffer(objAccount,objCurrentUserProfile, boolComparisonCustomerFieldsFLS);   
        }
                         
        mapAccessbilityBooleanOptions.put('boolComparisonCustomerFieldsFLS',boolComparisonCustomerFieldsFLS);
        mapAccessbilityBooleanOptions.put('conditionalReadOnlyAccessForOO',conditionalReadOnlyAccessForOO);       
    }

    /*
    *  @author       : Satya Swain
    *  @description  : calculate accessibility logic for Open Offer section 
    *  @param        : Account objAccount, Boolean boolComparisonCustomerFieldsFLS
    *  @return       : Boolean
    */
    public static Boolean getTerritoryRestrictionsForOpenOffer(Account objAccount, Profile objUserProfile, Boolean boolComparisonCustomerFieldsFLS) {
        
        ilib_LogEvent.setTitle(LOG_TITLE + '.getTerritoryRestrictionsForOpenOffer()');
        ilib_LogEvent.push(LOG_TITLE + '.getTerritoryRestrictionsForOpenOffer()');
        
        Map<String, Boolean> mapStringToOpenOfferFieldChecks = new Map<String, Boolean>();
        List<UserTerritory2Association> lstUTAForAllAccountHierarchyTerritories = new List<UserTerritory2Association>();
        Set<Id> setISRUserIds = new Set<Id>();
        Set<Id> setTerritoryUserIds = new Set<Id>();        
        
        Boolean boolHasRecordEditAccess = new UserRecordAccessSelector().selectUserRecordAccessByUserAndRecordId(UserInfo.getUserId(),objAccount.Id)[0]?.HasEditAccess;
        List<ObjectTerritory2Association> lstObjectTerritory2Association = new ObjectTerritory2AssociationsSelector().selectByAccountIds(new Set<Id>{objAccount.Id});
        Set<Id> setTerritoryIds = UtilsCollection.getSetOfIds(lstObjectTerritory2Association,'Territory2Id');
        
        Set<Id> setTerritoryIncludingParents = new TerritoriesSelector().getTerritoryIdsIncludingParents(setTerritoryIds);
        
        if(setTerritoryIncludingParents != null && !setTerritoryIncludingParents.isEmpty()) {
            lstUTAForAllAccountHierarchyTerritories = new UserTerritory2AssociationSelector().selectByTerritoryId(setTerritoryIncludingParents);
        }

        if(lstUTAForAllAccountHierarchyTerritories != null && !lstUTAForAllAccountHierarchyTerritories.isEmpty()) {            
            for(UserTerritory2Association objUserTerritory2Association : lstUTAForAllAccountHierarchyTerritories) {
                setTerritoryUserIds.add(objUserTerritory2Association.UserId);            
                if(String.isNotBlank(objUserTerritory2Association.RoleInTerritory2) && Label.ISRRolesETM.contains(objUserTerritory2Association.RoleInTerritory2)) {
                    setISRUserIds.add(objUserTerritory2Association.UserId);
                }
            }
        }

        Boolean boolLoggedInUserIsNotOwner = objAccount.OwnerId != UserInfo.getUserId();
        Boolean boolAccountIsProspectValidation = checkIfAccountIsVerified(objAccount);
        Boolean boolUserInCurrentTerritory = !setTerritoryUserIds.isEmpty() && setTerritoryUserIds.contains(UserInfo.getUserId()) ? true : false;
        Boolean boolUserIsISR = !setISRUserIds.isEmpty() && setISRUserIds.contains(UserInfo.getUserId()) ? true : false;               
        Boolean boolUserProfileEligibleForEdits = SET_PROFILES_ALLOWED_TO_SUBMIT_ERP.contains(objUserProfile.Name);
        Boolean boolTerritoryAssigned = lstObjectTerritory2Association != null && !lstObjectTerritory2Association.isEmpty();
        
        mapStringToOpenOfferFieldChecks.put('boolUserInCurrentTerritory',boolUserInCurrentTerritory);
        mapStringToOpenOfferFieldChecks.put('boolLoggedInUserIsNotOwner',boolLoggedInUserIsNotOwner);
        mapStringToOpenOfferFieldChecks.put('boolUserIsISR',boolUserIsISR);
        mapStringToOpenOfferFieldChecks.put('boolAccountIsProspectValidation',boolAccountIsProspectValidation);
        mapStringToOpenOfferFieldChecks.put('boolCCFieldsFLS',boolComparisonCustomerFieldsFLS);
        mapStringToOpenOfferFieldChecks.put('boolHasRecordEditAccess',boolHasRecordEditAccess);
        mapStringToOpenOfferFieldChecks.put('boolUserProfileEligibleForEdits',boolUserProfileEligibleForEdits);
        mapStringToOpenOfferFieldChecks.put('boolTerritoryAssigned',boolTerritoryAssigned);
        
        ilib_LogEvent.message('mapStringToOpenOfferFieldChecks ::: '+mapStringToOpenOfferFieldChecks);
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return checkIfReadOnlyForOpenOfferFields(mapStringToOpenOfferFieldChecks);
    }

    /*
    *  @author       : Satya Swain
    *  @description  : check if account is verified 
    *  @param        : Account objAccount
    *  @return       : Boolean
    */
    private static Boolean checkIfAccountIsVerified(Account objAccount) {
        return objAccount.Account_Status__c == Label.Account_Account_Status_Prospect_Validation || String.isNotBlank(objAccount.ERP_Customer_Id__c);
    }   

    /*
    *  @author       : Satya Swain
    *  @description  : calculate accessibility logic for Open Offer section fields 
    *  @param        : Map<String, Boolean> mapStringToOpenOfferFieldChecks
    *  @return       : Boolean
    */
    private static Boolean checkIfReadOnlyForOpenOfferFields(Map<String, Boolean> mapStringToOpenOfferFieldChecks) {
        ilib_LogEvent.push(LOG_TITLE + '.checkIfReadOnlyForOpenOfferFields()');        
        Boolean boolUserInCurrentTerritory = mapStringToOpenOfferFieldChecks.get('boolUserInCurrentTerritory');
        Boolean boolLoggedInUserIsNotOwner = mapStringToOpenOfferFieldChecks.get('boolLoggedInUserIsNotOwner');
        Boolean boolUserIsISR = mapStringToOpenOfferFieldChecks.get('boolUserIsISR');
        Boolean boolAccountIsProspectValidation = mapStringToOpenOfferFieldChecks.get('boolAccountIsProspectValidation');
        Boolean boolComparisonCustomerFieldsFLS = mapStringToOpenOfferFieldChecks.get('boolCCFieldsFLS');
        Boolean boolHasRecordEditAccess = mapStringToOpenOfferFieldChecks.get('boolHasRecordEditAccess');
        Boolean boolUserProfileEligibleForEdits = mapStringToOpenOfferFieldChecks.get('boolUserProfileEligibleForEdits');
        Boolean boolTerritoryAssigned = mapStringToOpenOfferFieldChecks.get('boolTerritoryAssigned');
        Boolean boolUserIsSameTerritoryISR = boolLoggedInUserIsNotOwner && boolUserInCurrentTerritory && boolUserIsISR;

        ilib_LogEvent.info('boolUserInCurrentTerritory ::: '+boolUserInCurrentTerritory);
        ilib_LogEvent.info('boolLoggedInUserIsNotOwner ::: '+boolLoggedInUserIsNotOwner);
        ilib_LogEvent.info('boolUserIsISR ::: '+boolUserIsISR);
        ilib_LogEvent.info('boolAccountIsProspectValidation ::: '+boolAccountIsProspectValidation);
        ilib_LogEvent.info('boolHasRecordEditAccess ::: '+boolHasRecordEditAccess);
        ilib_LogEvent.info('boolUserProfileEligibleForEdits ::: '+boolUserProfileEligibleForEdits);
        ilib_LogEvent.info('boolUserIsSameTerritoryISR ::: '+boolUserIsSameTerritoryISR);
        
        
        if(!boolHasRecordEditAccess) {
            boolComparisonCustomerFieldsFLS = true;
        }

        if(boolTerritoryAssigned) {
            if(boolLoggedInUserIsNotOwner && !boolUserInCurrentTerritory) {
                boolComparisonCustomerFieldsFLS = true;
            } else if(boolLoggedInUserIsNotOwner && boolUserInCurrentTerritory && (boolUserIsISR || boolUserProfileEligibleForEdits)) {
                boolComparisonCustomerFieldsFLS = false;
            } else if(!boolLoggedInUserIsNotOwner && (boolUserIsISR || boolUserProfileEligibleForEdits)) {
                boolComparisonCustomerFieldsFLS = false;
            }
        } else {
            if(!boolLoggedInUserIsNotOwner && boolUserProfileEligibleForEdits) {
                boolComparisonCustomerFieldsFLS = false;
            } else if(boolLoggedInUserIsNotOwner) {
                boolComparisonCustomerFieldsFLS = true;
            }
        }

        if(boolAccountIsProspectValidation) {
            boolComparisonCustomerFieldsFLS = true;
        }
        
        ilib_LogEvent.info('exiting checkIfReadOnlyForOpenOfferFields boolComparisonCustomerFieldsFLS ::: '+boolComparisonCustomerFieldsFLS);
        ilib_LogEvent.pop();
        return boolComparisonCustomerFieldsFLS;
    }
}

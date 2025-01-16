/**
*    @author Abhishek yadav
*    @date   27 Oct 2023
*    @description    Class to get the Associated Product records based on different conditions
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*      Developer                      Date                Description
*      Abhishek                       27 Oct 2023        Initial Version
*      Siddartha Reddy Kalam          28-Nov-2023        CMCM-3980 Added LWC Related Selectors
*.     Dhairya Shah					  15-Feb-2024	.    CMCM3591
*      Abhishek                       20-Feb-2024        CMCM-269
*      Abhishek                       04-March-2024      CMCM-273
*      Pritam Yadav                   27-Mar-2024        cmcm-6411
*      Abhishek                       26-April-2024      CMCM-7245
    ------------------------------------------------------------------------------------ 
*/
public with sharing class AssociatedProductSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'AssociatedProductSelector';
    private static final String FIELD_NAME = 'Name';
    private static final String FIELD_IS_PRIMARY = 'Is_Primary__c';
    private static final String FIELD_PRODUCT_NAME = 'Product__r.Name';
    private static final String FIELD_PRODUCT = 'Product__c';
    private static final String FIELD_PRODUCT_LOT_NUMBER = 'Product_Lot_Number__c';
    private static final String FIELD_EXPIRED_DATE = 'Expired_Date__c';
    private static final String FIELD_IS_EXPIRED = 'Is_Expired__c';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String FIELD_INST_PROD_NAME = 'Installed_Product__r.Name';
    private static final String FIELD_PROD_SERIAL_NUM = 'Product_Serial_Number__c';
    private static final String FIELD_SUBSCRIBER_NAME = 'Subscription__r.Name';
    private static final String FIELD_INST_PROD_SERIAL_NUM = 'Installed_Product_Serial_Number__c';
    private static final String FIELD_SOFT_VER = 'Software_Version__c';
    private static final String FIELD_IVD_PROD_IDEN = 'IVD_Product_Identifier__c';
    private static final String FIELD_WORK_ORDER = 'Work_Order__c';
    private static final String FIELD_CASE = 'Case__c';
    private static final String WORK_ORDER_STATUS = 'Work_Order__r.SVMXC__Order_Status__c';
    private static final String CASE_STATUS = 'Case__r.Status';
    private static final String FIELD_INSTALL_PROD = 'Installed_Product__c';
    private static final String FIELD_SUBSCRIPTION = 'Subscription__c';
    private static final String FIELD_LOCATION = 'Location__c';
    private static final String FIELD_INST_LOT_NUMBER = 'Installed_Product__r.SVMXC__Serial_Lot_Number__c';//CMCM - 6411 
    private static final String FIELD_INSTALL_PROD_UPGRADE_TYPE = 'Installed_Product_Upgrade_Type__c';
/**  
*  @author Abhishek 
*  @description  
*  @return SObjectType The Schema.SObjectType of the proposal
**/
    public Schema.SObjectType getSObjectType() {
        return Associated_Product__c.sObjectType;
    }
/**
*  @author  Abhishek 
*  @description Retrieve list of fields for Associated_Product__c sObject 
*  @return sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList() {  
        return new List<Schema.SObjectField> {
            Associated_Product__c.Id, 
                Associated_Product__c.Case__c,
                Associated_Product__c.Installed_Product__c,
                Associated_Product__c.Product__c,
                Associated_Product__c.Expired_Date__c,
                Associated_Product__c.Proactive_Run_Detail__c
                };
    } 
/**
*  @author Abhishek
*  @description associated Product with the Proactive Run Detail Record
*  @param prdIds
*  @return List of Associated Products
**/
    public List<Associated_Product__c > associatedProductRecords(Set<Id> prdIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.associatedProductRecords', UtilsCollection.serializeIds(prdIds));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory().selectField('Id')
            .selectField('Proactive_Run_Detail__c')
            .setCondition('Proactive_Run_Detail__c IN : prdIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using Case attribute which holds associated data
    * @author Siddartha Reddy Kalam
    * @param recordId attribute which holds caseid used to filter data
    * @return List<Associated_Product__c>
    */
    public List<Associated_Product__c> selectAssocProdsWithCase(String recordId) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssocProdsWithCase');
        } 

        ilib_QueryFactory assocProdQuery = newQueryFactory();
        assocProdQuery.selectField('Id');
        assocProdQuery.selectField(FIELD_NAME);
        assocProdQuery.selectField(FIELD_IS_PRIMARY);
        assocProdQuery.selectField(FIELD_INSTALL_PROD);
        assocProdQuery.selectField(FIELD_PRODUCT);
        assocProdQuery.selectField(FIELD_INST_PROD_Name);
        assocProdQuery.selectField(FIELD_PRODUCT_NAME);
        assocProdQuery.selectField(FIELD_SUBSCRIPTION);
        assocProdQuery.selectField(FIELD_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_SUBSCRIBER_NAME);
        assocProdQuery.selectField(FIELD_PRODUCT_LOT_NUMBER);
        assocProdQuery.selectField(FIELD_EXPIRED_DATE);
        assocProdQuery.selectField(FIELD_IS_EXPIRED);
        assocProdQuery.selectField(FIELD_INST_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_SOFT_VER);
        assocProdQuery.selectField(FIELD_IVD_PROD_IDEN);
        assocProdQuery.selectField(CASE_STATUS);
        assocProdQuery.selectField(FIELD_WORK_ORDER);
        assocProdQuery.selectField(WORK_ORDER_STATUS);
        assocProdQuery.setCondition('Case__c =: recordId');

        List<Associated_Product__c> res = (List<Associated_Product__c>) Database.query(
            assocProdQuery
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
     /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using WorkOrder attribute which holds associated data
    * @author Siddartha Reddy Kalam
    * @param recordId attribute which holds workorderid used to filter data
    * @return List<Associated_Product__c>
    */
    public List<Associated_Product__c> selectAssocProdsWithWorkOrder(String recordId) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssocProdsWithWorkOrder');
        } 

        ilib_QueryFactory assocProdQuery = newQueryFactory();
        assocProdQuery.selectField('Id');
        assocProdQuery.selectField(FIELD_NAME);
        assocProdQuery.selectField(FIELD_IS_PRIMARY);
        assocProdQuery.selectField(FIELD_PRODUCT);
        assocProdQuery.selectField(FIELD_INSTALL_PROD);
        assocProdQuery.selectField(FIELD_INST_PROD_Name);
        assocProdQuery.selectField(FIELD_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_PRODUCT_NAME);
        assocProdQuery.selectField(FIELD_SUBSCRIPTION);
        assocProdQuery.selectField(FIELD_SUBSCRIBER_NAME);
        assocProdQuery.selectField(FIELD_EXPIRED_DATE);
        assocProdQuery.selectField(FIELD_IS_EXPIRED);
        assocProdQuery.selectField(FIELD_INST_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_PRODUCT_LOT_NUMBER);
        assocProdQuery.selectField(FIELD_SOFT_VER);
        assocProdQuery.selectField(FIELD_IVD_PROD_IDEN);
        assocProdQuery.selectField(FIELD_CASE);
        assocProdQuery.selectField(CASE_STATUS);
        assocProdQuery.selectField(WORK_ORDER_STATUS);
        assocProdQuery.setCondition('Work_Order__c =: recordId');

        List<Associated_Product__c> res = (List<Associated_Product__c>) Database.query(
            assocProdQuery
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
    *  @author Abhishek
    *  @description associated Product with the Case Id Record
    *  @param caseIds
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithCase(Set<Id> caseIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithCase', UtilsCollection.serializeIds(caseIds));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_WORK_ORDER)
            .selectField(FIELD_IS_PRIMARY)
        	.selectField(FIELD_CASE)
            .selectField('IVD_Product_Identifier__c')
        	.selectField(FIELD_IVD_PROD_IDEN)
            .selectField('Product__r.Regulatory_Type__c')
            .setCondition('Case__c IN : caseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
    /**
    *  @author Abhishek
    *  @description associated Product with the work Order Record Id
    *  @param workOrderId
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithWorkOrder(Set<Id> workOrderId) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithWorkOrder', UtilsCollection.serializeIds(workOrderId));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_WORK_ORDER)
            .selectField(FIELD_IS_PRIMARY)
        	.selectField(FIELD_CASE)
            .setCondition('Work_Order__c IN : workOrderId').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
    
    /**
    *  @author Nidhi
    *  @description associated Product with the work Order Record Id
    *  @param workOrderId
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectPrimaryProductwithWorkOrder(Set<Id> workOrderId) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPrimaryProductwithWorkOrder', UtilsCollection.serializeIds(workOrderId));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_NAME)
        	.selectField(FIELD_IS_PRIMARY)
            .selectField(FIELD_PRODUCT_LOT_NUMBER)
            .selectField(FIELD_PRODUCT)
            .selectField(FIELD_PRODUCT_NAME)
            .selectField(FIELD_PROD_SERIAL_NUM)
            .selectField(FIELD_EXPIRED_DATE)
            .selectField(FIELD_IS_EXPIRED)
            .selectField('Product_Code__c')
            .setCondition('Is_Primary__c = true AND Work_Order__c IN : workOrderId')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
    /**
    *  @author Nidhi
    *  @description associated Product with the Case Record Id
    *  @param caseId
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectPrimaryProductwithCase(Set<Id> caseId) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPrimaryProductwithCase', UtilsCollection.serializeIds(caseId));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory().selectField('Id')
            .selectField(FIELD_NAME)
        	.selectField(FIELD_IS_PRIMARY)
            .selectField(FIELD_PRODUCT_LOT_NUMBER)
            .selectField(FIELD_PRODUCT)
            .selectField(FIELD_PRODUCT_NAME)
            .selectField(FIELD_PROD_SERIAL_NUM)
            .selectField(FIELD_EXPIRED_DATE)
            .selectField(FIELD_IS_EXPIRED)
            .selectField('Product_Code__c')
            .setCondition('Is_Primary__c = true AND Case__c IN : caseId')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-3591 LWC Fetches data using Case attribute which holds associated data
    *  @author Dhairya Shah
    * @param Id recordId attribute which holds associated product id
    * @return List<Associated_Product__c>
    */
    public List<Associated_Product__c> selectAssocProdsWithAPId(List<Id> recordId) {
        //List<Id> AssociatedProductID = new List<Id>();
        //AssociatedProductID.add(recordId);
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssocProdsWithCase');
        } 

        ilib_QueryFactory assocProdQuery = newQueryFactory();
        assocProdQuery.selectField('Id');
        assocProdQuery.selectField(FIELD_NAME);
        assocProdQuery.selectField(FIELD_IS_PRIMARY);
        assocProdQuery.selectField(FIELD_INST_PROD_Name);
        assocProdQuery.selectField(FIELD_PRODUCT_NAME);
        assocProdQuery.selectField(FIELD_SUBSCRIBER_NAME);
        assocProdQuery.selectField(FIELD_PRODUCT_LOT_NUMBER);
        assocProdQuery.selectField(FIELD_EXPIRED_DATE);
        assocProdQuery.selectField(FIELD_IS_EXPIRED);
        assocProdQuery.selectField(FIELD_INST_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_SOFT_VER);
        assocProdQuery.selectField(FIELD_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_IVD_PROD_IDEN);
        assocProdQuery.selectField(FIELD_CASE);
        assocProdQuery.selectField(CASE_STATUS);
        assocProdQuery.selectField(WORK_ORDER_STATUS);
        assocProdQuery.selectField('Work_Order__r.Case_Status__c');
        assocProdQuery.selectField(FIELD_WORK_ORDER);
        assocProdQuery.selectField('Serial_Number__c');
        assocProdQuery.setCondition('ID IN: recordId');

        List<Associated_Product__c> res = (List<Associated_Product__c>) Database.query(
            assocProdQuery
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-3591 LWC Fetches data using Case attribute which holds associated data
    *  @author Dhairya Shah
    * @param Id recordId attribute which holds associated product id
    * @return List<Associated_Product__c>
    */
    public List<Associated_Product__c> selectAssocProdsforDelete(List<Id> recordId) {
        //List<Id> AssociatedProductID = new List<Id>();
        //AssociatedProductID.add(recordId);
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssocProdsforDelete');
        } 

        ilib_QueryFactory assocProdQuery = newQueryFactory();
        assocProdQuery.selectField('Id');
        assocProdQuery.selectField(FIELD_NAME);
        assocProdQuery.selectField(FIELD_IS_PRIMARY);
        assocProdQuery.selectField(FIELD_INST_PROD_Name);
        assocProdQuery.selectField(FIELD_PRODUCT_NAME);
        assocProdQuery.selectField(FIELD_SUBSCRIBER_NAME);
        assocProdQuery.selectField(FIELD_PRODUCT_LOT_NUMBER);
        assocProdQuery.selectField(FIELD_EXPIRED_DATE);
        assocProdQuery.selectField(FIELD_IS_EXPIRED);
        assocProdQuery.selectField(FIELD_INST_PROD_SERIAL_NUM);
        assocProdQuery.selectField(FIELD_SOFT_VER);
        assocProdQuery.selectField(FIELD_IVD_PROD_IDEN);
        assocProdQuery.selectField(FIELD_CASE);
	    assocProdQuery.selectField(FIELD_PROD_SERIAL_NUM);
        assocProdQuery.selectField(CASE_STATUS);
        assocProdQuery.selectField(WORK_ORDER_STATUS);
        assocProdQuery.selectField('Work_Order__r.Case_Status__c');
        assocProdQuery.selectField(FIELD_WORK_ORDER);
        assocProdQuery.selectField('Serial_Number__c');
        assocProdQuery.setCondition('Id=:recordId AND IsDeleted = true');

        List<Associated_Product__c> res = (List<Associated_Product__c>) Database.query(
            assocProdQuery
            .toSOQL()+' ALL ROWS'
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
    *  @author Abhishek
    *  @description get associated Product with the Record Id
    *  @param associatedProductId
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithIds(Set<Id> associatedProductId) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithIds', UtilsCollection.serializeIds(associatedProductId));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_WORK_ORDER)
        	.selectField(FIELD_CASE)
            .selectField(FIELD_INSTALL_PROD)
            .selectField(FIELD_SUBSCRIPTION)
            .selectField(FIELD_LOCATION)
            .selectField('Subscription__r.Status__c')
            .setCondition('Id IN : associatedProductId').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
    *  @author Abhishek
    *  @description get associated Product with the Record Id
    *  @param caseIds , workOrderIds
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithCaseWOIds(Set<Id> caseIds , Set<Id> workOrderIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithCaseWOIds', UtilsCollection.serializeIds(caseIds)  + '|' + UtilsCollection.serializeIds(workOrderIds));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_WORK_ORDER)
        	.selectField(FIELD_CASE)
        	.selectField('Material_Class__c')
        	.selectField(FIELD_PRODUCT_LOT_NUMBER)
        	.selectField(FIELD_EXPIRED_DATE)
        	.selectField(FIELD_IS_EXPIRED)
            .setCondition('Case__c IN: caseIds OR  Work_Order__c IN: workOrderIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
    //CMCM-6411 - START
    /**
    *  @author Pritam
    *  @description get associated Product with the Record Id
    *  @param Associated_Product Id
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithIP(Set<Id> associatedProductIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithIP', UtilsCollection.serializeIds(associatedProductIds));
        }
        
        List<Associated_Product__c> res = (List<Associated_Product__c >) Database.query(
            newQueryFactory().selectField('Id')
            .selectField(FIELD_INST_LOT_NUMBER)
            .setCondition('Id IN: associatedProductIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
	//CMCM-6411 - END
    /**
    *  @author Abhishek
    *  @description get associated Product with the InstallProduct Id
    *  @param Install Product Ids
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPwithInstallProduct(Set<Id> installProduct) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPwithInstallProduct', UtilsCollection.serializeIds(installProduct));
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory(false,false,true).selectField('Id')
            .selectField(FIELD_INSTALL_PROD)
        	.selectField(FIELD_INSTALL_PROD_UPGRADE_TYPE)
        	.selectField('Case__r.status')
            .setCondition('Installed_Product__c IN: installProduct').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
    
     /**
    *  @author Vishal
    *  @description get associated Product where last modified user is SNAP service integration
    *  @param Work Order Ids
    *  @return List of Associated Products
    **/
    public List<Associated_Product__c> selectAPonWO(Set<Id> woIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAPonWO');
        }
        
        List<Associated_Product__c > res = (List<Associated_Product__c >) Database.query(
            newQueryFactory().selectField('Id')
            .selectField(FIELD_INSTALL_PROD)
            .selectField(FIELD_PRODUCT)
            .selectField(FIELD_SUBSCRIPTION)
            .selectField('CreatedBy.Name')
            .selectField('Work_Order__c')
            .setCondition('CreatedBy.Name = \'SNAP Sales Integration\' AND Work_Order__c =: woIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }
}
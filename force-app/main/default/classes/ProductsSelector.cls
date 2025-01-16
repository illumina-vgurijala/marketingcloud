/**
*    @author Indra Ganesan
*    @date   2018-05-25
*    @description    DCP-1010,598: product Selector class
*    @TestClasses:  TestProductsSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Indra Ganesan              25 May 2018            Product2 Selector Class
*    Vivek Verma                2018-07-30             Added changes for ProductOptionGroupsSelector Class
*    Joshith k                  2018-11-05             DCP 11324 Change Added Method selectProductsNotBundleChannel Which Returns List Of Product
*    Arnab Modak                2019-09-06             DCP 28284 Querying for MaterialClassType of FixedBundle SKU and Components
*    Rishab Wali                16 March 2020          DCP 34078 Adding Method to get Products from Product Codes 
*    B Kamini                   20 Jan 2020            DCP-31442 Validations
*    Roopal Verma               15 May 2020            DCP-29812 Added product specific terms
*    Roopal Verma               02 Sept 2020           DCP-40115 Added Material_Group_1_Code__c
*    KD                         31 May 2021            DCP-38933 Added Auto_Create_Billable_Work_Order__c
*    Sagar Madkaikar            02 Sep 2021            CMCP-232/CMCP-14 Added Service_Product_Type__c field in selectProductsForMaterialNumber() method.
*                                                               Added Query Instrumentation on selectProductsForMaterialNumber() method
*    Khushbu Vasani             22 Jun 2022            DCP-53200 : Added method to get product based on material class and open offer
*    Gladis                     22-Sep-2022            Added Query Instrumentation
*    Siddartha Reddy Kalam      28-Nov-2023            CMCM-3980 Added LWC Related Selectors
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProductsSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'ProductsSelector';//CMCP-232/CMCP-14
    private static final  String SERVICE_QUERY_LOGS = 'ServiceQueryLogs';//CMCP-232/CMCP-14
    private static final  String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    /*
    *   @author Indra Ganesan
    *   @description  Describe the object
    */
    public Schema.SObjectType getSObjectType()
    {
        return Product2.sObjectType;
    }
    
    /**
     *  @author  Indra Ganesan 
     *  @description Retrieve list of fields for Product2 sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Product2.Id,
           Product2.Material_Class__c,
           Product2.Name,
           Product2.ProductCode,
           Product2.Apttus_Config2__EffectiveDate__c,
           Product2.Apttus_Config2__ExpirationDate__c,
           Product2.Description,
           Product2.Bundle_Segment__c,
           Product2.Bundle_Channel__c,
           Product2.IsActive,
           Product2.Bundle_Id__c,
           Product2.Bundle_Name__c,
           Product2.Bundle_Description__c,
           Product2.ProductCode,
           Product2.Apttus_Config2__ConfigurationType__c,
           Product2.Product_Send_To_AEM_Status__c,
           Product2.Product_Group__c,
           Product2.LastModifiedById,           
           Product2.Regulatory_Type__c,
           Product2.Auto_Create_IQ_OQ__c,
           Product2.Auto_Create_PQ__c,
           Product2.Service_Product_Type__c,
           Product2.Service_Level__c,
           Product2.Custom_Product__c,
           Product2.Line_Of_Business_Code__c,
           Product2.Material_Number__c,
		   Product2.Old_Material_Number__c, //Added as part of DCP-31442
           Product2.Discount_Grid_Group__c, // DGP-103 : To get Discount Grid Group
           Product2.Open_Offer_Product_Category__c, // DGP-908
           Product2.End_Of_Sale_Date__c,
           Product2.End_Of_Service_Date__c,
           Product2.Material_Class_Type__c, //Added as part of DCP-28284
           Product2.Product_Specific_Terms__c,  //Added as part of DCP-29812
           Product2.Material_Group_1_Code__c, // Added as part of DCP-40115
           Product2.Dangerous_Goods__c, //Added for DCP-42724
           Product2.Condition_Type__c,//Added for DCP-51210
           Product2.Serial_Number_Profile__c, //Added for DCP-51210
           Product2.Auto_Create_Billable_Work_Order__c, // DCP-38933
           Product2.Auto_Create_Installation_Workflow__c, // CMCM-1662
           Product2.Material_Type__c, // CMCM-11325
           Product2.Product_Level_Indicator__c // CMCM-11325
       };
    }
    /**
     *  @description fetch the Products on basis of productId's
     *  @param Set of Material numbers setMaterialNumbers
     *  @return Product2 List
    **/
    public List<Product2> selectProducts(Set<Id> productIds)
    {
        return (List<Product2>)selectSObjectsById(productIds);
    }
    
//    public List<Product2> selectAllProducts()
//    {
//        return (List<Product2>) Database.query(
//            newQueryFactory().toSOQL()
//        );
//    }
    
    /**
     *  @author Nitin Sood
     *  @description fetch the Products on basis of Material numbers
     *  @param Set of Material numbers setMaterialNumbers
     *  @return Product2 List
    **/
    public List<Product2> selectProductsForMaterialNumber(Set<String> setMaterialNumbers)
    {
        //CMCP-232/CMCP-14: Added Query Instrumentation
        ilib_LogQuery logger=null;
        if (Feature.isOn(SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProductsForMaterialNumber',
            UtilsCollection.serializeIds(setMaterialNumbers)
        );
        
        String strQuery = newQueryFactory()
                        .selectField('Material_Number__c')
                        .selectField('Service_Product_Type__c')//CMCP-232/CMCP-14
                        .setCondition('Material_Number__c IN :setMaterialNumbers')
                        .toSOQL();

        List<Product2> res = (List<Product2>) Database.query(strQuery);
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;                

             
    }
    /**
     *  @description fetch the Products on basis of productId's
     *  @param Set<String> setproductIds
     *  @return Product2 List
    **/
    public List<Product2> fetchProductId(Set<String> setproductIds)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.fetchProductId', UtilsCollection.serializeIds(setproductIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory()
            .setCondition('ProductCode IN :setproductIds')
            .toSOQL()
        );

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res; 
    }
    
    /**
     *  @author Debanka chakraborty
     *  @description Fetch the Product2 with Mate
     *  @param product2Ids Set of product Ids
     *  @return product2List
     **/
    public List<Product2> selectProductsWithServiceProductType(Set<Id> productIds, String strServiceProductType)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsWithServiceProductType', UtilsCollection.serializeIds(productIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory()
            .setCondition('Id IN :productIds AND Service_Product_Type__c = :strServiceProductType')
            .toSOQL()
        );

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;
    }

    /**
     *  @author Ritika M
     *  @description Fetch the Products which have Service Product Type as Instrument and Auto Work Order creation as true
     *  @return product2List
     **/
    public List<Product2> selectInstrumentProductsForAutoWOCreation(Set<Id> productIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstrumentProductsForAutoWOCreation', UtilsCollection.serializeIds(productIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory()
           .setCondition('Service_Product_Type__c=\'Instrument\' AND  Id IN :productIds') // CMCM-1662
            .toSOQL()
        );

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;
    }
    
    /**
     *  @author Govind Dubey
     *  @description Select Products where Process_For_Batch__c is true so that category association batch can run
     *  @return product2List
     **/
    public List<Product2> selectProductsForBatch() 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsForBatch');
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('Process_For_Batch__c')
            .setCondition('Process_For_Batch__c = TRUE')
            .toSOQL()
        );

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;
    }
	
	
	 /**
     *  @author Vaibhav
     *  @description Fetch the Products which have Auto Work Order creation as true
     *  @return product2List
     **/
    public List<Product2> selectAutoWOCreationProducts(Set<Id> productIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAutoWOCreationProducts', UtilsCollection.serializeIds(productIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory()
            .setCondition('Auto_Create_Installation_Workflow__c = \'Auto Create Install Work Order and Service Request Case\' AND Id IN :productIds') //CMCM-1662
            .toSOQL()
        );

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;
    }
	
	 /**
     *  @author Sandeep
     *  @description fetch the Id on basis productcode
     *  @param Set of set<String>
     *  @return Product2 List
    **/
    public List<Product2> selectProductFromProdCode(Set<String> setProductCode)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductFromProdCode', UtilsCollection.serializeIds(setProductCode));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('ProductCode')
             .setCondition('ProductCode = : setProductCode').toSOQL());

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;     
    }
/*
    //For now the ProductSelect(method:selectByIdWithOptionGroups) returns the below query:
        SELECT
       Id,
       Material_Class__c,
       Name,
       (SELECT Id, Name FROM Apttus_Config2__OptionGroups__r)
    FROM
       Product2
    WHERE
       Id IN :idSet
 */
 
    /**
     *  @author Nancy Kalach
     *  @description fetch the Products on productcode and Service Level
     *  @param Set of set<String>
     *  @return Product2 List
    **/
    public List<Product2> selectProductWithServLevel(Set<String> setProductCode, String serviceLevel)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductFromProdCode', UtilsCollection.serializeIds(setProductCode));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('ProductCode')
             .setCondition('ProductCode = :setProductCode AND Service_Level__c = :serviceLevel').toSOQL());

        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;     
    }
    
	/**
    *  @author Rishab Wali
    *  @description fetch the Products on basis of Material Id (DCP - 34078)
    *  @param Set of Material Id
    *  @return Product2 List
    **/
    public List<Product2> selectProductsFromMaterialId(Set<Id> setMaterialId)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsFromMaterialId', UtilsCollection.serializeIds(setMaterialId));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('ProductCode')
            .setCondition('Id IN : setMaterialId').toSOQL());
        
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;      
    }
 /**
     *  @author B Kamini
     *  @description fetch the Products on basis of Material numbers
     *  @param set of Material numbers selectProductsForMaterialNumberOld
     *  @return Product2 List
    **/
    public List<Product2> selectProductsForMaterialNumberOld(Set<String> setMateraialNumbers)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsForMaterialNumberOld', UtilsCollection.serializeIds(setMateraialNumbers));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().setCondition('Material_Number__c IN :setMateraialNumbers OR Old_Material_Number__c IN :setMateraialNumbers').toSOQL());
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;    
    }

    /**
     *  @author Roopal
     *  @description fetch the Products on basis of Id
     *  @param set of product Ids
     *  @return Product2 List
    **/
    public List<Product2> selectProductsId(Set<Id> productIds)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsId', UtilsCollection.serializeIds(productIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('Family').setCondition('Id IN :productIds').toSOQL());
        
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;     
    }
	
	/**
     *  @author Sravan
     *  @description DCP-29459: fetch the IVD Products based on Ids
     *  @param set of product Ids
     *  @return Product2 List
    **/
    public List<Product2> selectIVDProducts(Set<Id> productIds)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIVDProducts', UtilsCollection.serializeIds(productIds));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().setCondition('Id IN :productIds AND (Regulatory_Type__c LIKE \'%DX%\' OR Regulatory_Type__c = \'IUO\')').toSOQL());
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;     
    }

    /**
    *  @author Vaibhav
    *  @description fetch the Products based on family
    *  @param Set of Product Family Name
    *  @return Product2 List
    **/
    public List<Product2> selectProductsFromFamily(set < String > setProductFamiliesForCertification)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsFromFamily', UtilsCollection.serializeIds(setProductFamiliesForCertification));
        }
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('Family')
            .setCondition('Family IN : setProductFamiliesForCertification').toSOQL());
        if (Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size()); 
        }
        return res;    
    }
 
     /**
    *  @author Khushbu Vasani
    *  @description fetch the Products based on material class
    *  @param List of products
    *  @return Product2 List
    **/
    public List<Product2> selectProductsForMaterialClassType(Set<Id> setProductIds, Set<string> setMaterialClassType) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getPricingTierBasedOnTier',UtilsCollection.serializeIds(setProductIds));
        }

       /* List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('Open_Offer_Product_Category__c')
            .setCondition('Id IN :setProductIds AND Open_Offer_Product__c = true AND Material_Class__c IN:setMaterialClassType')
            .toSOQL()
        );*/
        List<Product2> res = (List<Product2>) Database.query(
            newQueryFactory().selectField('Open_Offer_Product_Category__c')
            .setCondition('Id IN :setProductIds AND Open_Offer_Product_Category__c !=null AND Material_Class__c IN:setMaterialClassType')
            .toSOQL()
        );
         
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /*******************************************************************************************************
    * @description CMCM-10540 LWC Fetches data using Key attribute which holds search data
    *  @author Abhishek Yadav
    * @param key attribute which holds search data
    * @return List<Product2>
    */
    public List<Product2> selectProductsWithSearchSOSL(String key) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductsWithSearchSOSL');
        } 

        List<List<SObject>> searchResults = [FIND :(key) 
        IN ALL FIELDS 
        RETURNING Product2 (
            Id, 
            Name, 
            ProductCode, 
            Family,
            Source_System__c,
            Product_Line_ilmn__c
        ) 
        LIMIT 50];
        
        List<Product2> res = (List<Product2>) searchResults[0];

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
}
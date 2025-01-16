/***************************************************************************************************************************************
* NAME         : ProductHierarchyWhereUsedWrapper
* DESCRIPTION  : DCP-31056 - Wrapper class to transform the JSON response for where used request.
*                    
* @AUTHOR      : 
* @DATE        : 17-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Avina                   28/9/2022           QACM-78 Created EX_product_delivery wrapper class
****************************************************************************************************************************************/
public class ProductHierarchyWhereUsedWrapper {

  @AuraEnabled public String sfdcToSAPCalloutStatus; //stores the callout error/success message made from sfdc to sap.  
  @AuraEnabled public String Message; //stores an error message for SFDC to SAP callout

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for Products
     **/
  public class Ex_Product_Return {
    @AuraEnabled public List < Results > results;
  }

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - wrapper for Where Used
     **/
  public class Ex_Where_Used {
    @AuraEnabled public List < Results_Z > results;
  }
  /**
     *  @AUTHOR 
     *  @QACM-78 DESCRIPTION - Wrapper for BOM
     **/
    public class EX_ProductDelivery {
      @AuraEnabled public List < Results > results;
    }
     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for Product
     **/
  public class d {
    @AuraEnabled public String Material;
    @AuraEnabled public String Serial_Number;
    @AuraEnabled public String Batch_Number;
    @AuraEnabled public String Valid_From;
    @AuraEnabled public String Valid_To;
    @AuraEnabled public String Integration_Sys;
    @AuraEnabled public String Multi_Level;
    @AuraEnabled public String BOM_Level;
    @AuraEnabled public String BOM_Usage;
    @AuraEnabled public String Plant;
    @AuraEnabled public String BOM_Used_In;
    @AuraEnabled public String Message;
    @AuraEnabled public Ex_Product_Return Ex_Product_Return;
    @AuraEnabled public Ex_Where_Used Ex_Where_Used;
    @AuraEnabled public EX_ProductDelivery EX_ProductDelivery;
  }

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for Product results
     **/
  public class Results {
    @AuraEnabled public String Material;
    @AuraEnabled public String Serial_Number;
    @AuraEnabled public String Batch_Number;
    @AuraEnabled public String Status;
    @AuraEnabled public String Regulatory_Type;
    @AuraEnabled public String System_Blocks;
    @AuraEnabled public String Material_Desc;
    @AuraEnabled public String Batch;
    @AuraEnabled public String BatchExpiry;
  }

  @AuraEnabled public d d;

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for Products results
     **/
  public class Results_Z {
    @AuraEnabled public String Material;
    @AuraEnabled public String Material_Desc;
    @AuraEnabled public String Serial_Number;
    @AuraEnabled public String Batch_Number;
    @AuraEnabled public String Status;
    @AuraEnabled public String Regulatory_Type;
    @AuraEnabled public String System_Blocks;
    @AuraEnabled public String BOM_Level;
    @AuraEnabled public String BOM_Usage;
    @AuraEnabled public String BOM_Item;
    @AuraEnabled public String BOM_Quantity;
    @AuraEnabled public String Unit_of_measure;
    @AuraEnabled public String BOM_Number;
    @AuraEnabled public String Alt_BOM;
    @AuraEnabled public String Plant;
    @AuraEnabled public String Item_Category;
    @AuraEnabled public String Valid_From;
    @AuraEnabled public String Valid_To;
    @AuraEnabled public String Deletion_Ind;
    @AuraEnabled public String Created_On;
    @AuraEnabled public String Created_By;
    @AuraEnabled public String Changed_On;
    @AuraEnabled public String Changed_By;
    @AuraEnabled public String Change_Number;
    @AuraEnabled public String ProdRelevance;
    @AuraEnabled public String PlantMianRelevance;
    @AuraEnabled public String CostingRelevance;
    @AuraEnabled public String EngineeringRelevance;
    @AuraEnabled public String ExplosionType;
    @AuraEnabled public String BOM_Status;
  }

  /**
   *  @author Vaibhav
   *  @description method to parse the incoming JSON.
   *  @param None
   *  @return ProductHierarchyWhereUsedWrapper
   **/
  public static ProductHierarchyWhereUsedWrapper parseWhereUsedResponse(String json) {
    return (ProductHierarchyWhereUsedWrapper) System.JSON.deserialize(json, ProductHierarchyWhereUsedWrapper.class);
  }


}
/***************************************************************************************************************************************
* NAME         : ProductHierarchyBOMWrapper
* DESCRIPTION  : DCP-31056 - Wrapper class to transform the JSON response for bom explosion request.
*                    
* @AUTHOR      : 
* @DATE        : 17-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Avina                   28/9/2022           QACM-78 Created EX_product_delivery and BatchResults wrapper class
****************************************************************************************************************************************/
public class ProductHierarchyBOMWrapper {

  @AuraEnabled public String sfdcToSAPCalloutStatus; //stores the callout error/success message made from sfdc to sap.  
  @AuraEnabled public String Message; //stores an error message for SFDC to SAP callout
  @AuraEnabled public String Others; //stores an error message for SFDC to SAP callout

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for products 
     **/
  public class Ex_Product_Return {
    @AuraEnabled public List < Results_Z > results;
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
    @AuraEnabled public String Integration_Sys;
    @AuraEnabled public String Multi_Level;
    @AuraEnabled public String BOM_Level;
    @AuraEnabled public String BOM_Usage;
    @AuraEnabled public String Plant;
    @AuraEnabled public String Application;
    @AuraEnabled public String Limit_explosion;
    @AuraEnabled public String Engineering;
    @AuraEnabled public String Production;
    @AuraEnabled public String Plant_maint;
    @AuraEnabled public String Bulk_material;
    @AuraEnabled public String PM_Assembly;
    @AuraEnabled public String Message;
    @AuraEnabled public Ex_BOM_Explosion Ex_BOM_Explosion;
    @AuraEnabled public Ex_Product_Return Ex_Product_Return;
    @AuraEnabled public EX_ProductDelivery EX_ProductDelivery;
  }

     /**
     *  @AUTHOR 
     *  @DESCRIPTION -Wrapper for Product
     **/
  public class Results {
    @AuraEnabled public Integer Comp_Index;
    @AuraEnabled public Integer Parent_Index;
    @AuraEnabled public String BOM_Level;
    @AuraEnabled public String Path_Pred;
    @AuraEnabled public String BOM_Item;
    @AuraEnabled public String Material;
    @AuraEnabled public String Material_Desc;
    @AuraEnabled public String Serial_Number;
    @AuraEnabled public String Batch_Number;
    @AuraEnabled public String Status;
    @AuraEnabled public String Regulatory_Type;
    @AuraEnabled public String System_Blocks;
    @AuraEnabled public String Integration_flag;
    @AuraEnabled public String BOM_Usage;
    @AuraEnabled public String BOM_Quantity;
    @AuraEnabled public String Unit_of_Measure;
    @AuraEnabled public String BOM_Number;
    @AuraEnabled public String Alt_BOM;
    @AuraEnabled public String Plant;
    @AuraEnabled public String BOM_Category;
    @AuraEnabled public String Valid_from;
    @AuraEnabled public String Valid_To;
    @AuraEnabled public String Deletion_Ind;
    @AuraEnabled public String Created_On;
    @AuraEnabled public String Changed_On;
    @AuraEnabled public String Material_type;
    @AuraEnabled public String Material_Grp;
    @AuraEnabled public String Spl_Proc;
    @AuraEnabled public String Batch;
    @AuraEnabled public String BatchExpiry;
    @AuraEnabled public List<BatchResults> BatchResults;
    
    @AuraEnabled public String sfdcToSAPCalloutStatus; //stores the callout error/success message made from sfdc to sap.  
    @AuraEnabled public String Message; //stores an error message for SFDC to SAP callout
    @AuraEnabled public String Others; //stores an error message for SFDC to SAP callout
  
  }

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for BOM
     **/
  public class Ex_BOM_Explosion {
    @AuraEnabled public List < Results > results;
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
     *  @QACM-79 DESCRIPTION -Wrapper for Product
     **/
    public class BatchResults {
      @AuraEnabled public String Batch;
      @AuraEnabled public String BatchExpiry;
    }

  @AuraEnabled public d d;

     /**
     *  @AUTHOR 
     *  @DESCRIPTION - Wrapper for Product results
     **/
  public class Results_Z {
    @AuraEnabled public String Material;
    @AuraEnabled public String Material_Desc;
    @AuraEnabled public String Serial_Number;
    @AuraEnabled public String Batch_Number;
    @AuraEnabled public String Status;
    @AuraEnabled public String Regulatory_Type;
    @AuraEnabled public String System_Blocks;
  }

  /**
   *  @author Vaibhav
   *  @description method to parse the incoming JSON.
   *  @param None
   *  @return ProductHierarchyBOMWrapper
   **/
  public static ProductHierarchyBOMWrapper parseBOMExplosionResponse(String json) {
    return (ProductHierarchyBOMWrapper) System.JSON.deserialize(json, ProductHierarchyBOMWrapper.class);
  }


}
/***************************************************************************************************************************************
* NAME         : TreeGrid
* DESCRIPTION  : builiding hierarchy.
*                    
* @AUTHOR      : 
* @DATE        : 15-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
    Avina                 07/09/2022           QACM-79 Updated field mappings in buildHierarchyStructure() method
  Avina                   27/08/2022            QACM-78 Added expiry date and batch number to HierarchyWrapper class        
****************************************************************************************************************************************/
public with sharing class TreeGrid {
    //members used in multiple methods
    //Map from Product Hierarchy Data sender class
    public static Map <Integer, List <ProductHierarchyBOMWrapper.Results>> parentIndexToLstChildIndex;  
    // Map to hold productcode as key and product Id as value.  
    public static Map<String,Id> prodcodeToProId= new Map<String,Id>(); 
    // Integer codes to refer to top level and Message from SAP
    public static final Integer TopLevel =1001;
    public static final Integer Message =10101;
    public static final String MaterialNotAvailable='Material not available in SFDC';
    //Integration status 
    public final static String SUCCESS_STRING = 'Success';
    public final static String FAILURE_STRING = 'Fail';
    // button varient to highlight the product searched for.
    public final static String HighlightProductBrand='brand';
    public final static String HighlightProductBase='base';
    // product searched in initial search.
    public static String searchedProd='';
    public static String NoResponseSAP='No Response from SAP';
    
    /**
   *  @author: Sandeep 
   *  @description :build productcode to product Id map .
   *  @param : list<string> 
   *  @return : Map<String,Id>
   **/
     @AuraEnabled
    public static Map<String,Id> getProductID(List<String> lstProductCodes){
        if(lstProductCodes != null && !lstProductCodes.isEmpty()){
            for(String key: lstProductCodes){
                prodcodeToProId.put(key,null);
                
            }
            for(Product2 product :new ProductsSelector().selectProductFromProdCode(prodcodeToProId.keyset())){
                if(prodcodeToProId.containskey(product.productcode)){
                    prodcodeToProId.put(product.productcode,product.Id);
                }
            }
            
            return prodcodeToProId;
        }     
        return null;
    }
    
     /**
   *  @author: Sandeep 
   *  @description : buliding the entire wrapper structure.
   *  @param : string 
   *  @return : List<HierarchyWrapper>
   **/
    @AuraEnabled
     public static List<HierarchyWrapper> getTreeGridData(String selectedProduct,String searchedProduct){
      //get the response 2.
      // start of wrapper building logic 
      system.debug('searchedProduct'+searchedProduct);
      //product searched in intial search.
      searchedProd=searchedProduct;
         List<HierarchyWrapper> lstHierarchyWrapper = new List<HierarchyWrapper>();
         List<String> lstProductCodes  = new List<String>();
          HierarchyWrapper hw = new HierarchyWrapper();
         List<Items> lstChild = new List<Items>();
         if(string.isNotBlank(selectedProduct)){
                //map from product hierarchy data sender class.
                parentIndexToLstChildIndex=ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(selectedProduct);
                //system.debug('--->'+json.serializePretty(parentIndexToLstChildIndex));
        }
        boolean isParIdxToLstChdIdxEmpty=parentIndexToLstChildIndex.isEmpty();
        boolean isMessageInParIdxMap=(!isParIdxToLstChdIdxEmpty)&& parentIndexToLstChildIndex.containsKey(Message)&& parentIndexToLstChildIndex.get(Message)!=null;
        boolean isSfdcCallOutSuccess=isMessageInParIdxMap && parentIndexToLstChildIndex.get(Message)[0].sfdcToSAPCalloutStatus.equalsIgnoreCase(SUCCESS_STRING);
        system.debug('isParIdxToLstChdIdxEmpty'+isParIdxToLstChdIdxEmpty);
        system.debug('isMessageInParIdxMap'+isMessageInParIdxMap);
        system.debug('isSfdcCallOutSuccess'+isSfdcCallOutSuccess);
        
            //chekc if map from product hierarchy data sender class is empty..
        if(!isParIdxToLstChdIdxEmpty){
                system.debug('--->'+json.serializePretty(parentIndexToLstChildIndex));
            }
        else{
                  // set static text if map from product hierarchy data sender class is empty..
                  hw.ErrorMessage=NoResponseSAP;
            }
            
         // check if the status of integration is success or failure.
        if(isMessageInParIdxMap && parentIndexToLstChildIndex.get(Message)[0].sfdcToSAPCalloutStatus.equalsIgnoreCase(FAILURE_STRING)){
                hw.ErrorMessage=parentIndexToLstChildIndex.get(Message)[0].Message;
        }
        else if(isSfdcCallOutSuccess){
                hw.Message=parentIndexToLstChildIndex.get(Message)[0].Message;
        }
        // get all the product code in the map
        if(isSfdcCallOutSuccess){
            for(Integer intKey:parentIndexToLstChildIndex.keySet()){
                if(intKey!=Message && parentIndexToLstChildIndex.containskey(intKey)&&(parentIndexToLstChildIndex.get(intKey)!=null)){
                    for(ProductHierarchyBOMWrapper.Results bomResult:parentIndexToLstChildIndex.get(intKey)){
                            lstProductCodes.add(bomResult.Material);
                    }
                }
                
            }
            // call the method to get the product id for the given product code.
            if(!lstProductCodes.isEmpty()){
                getProductID(lstProductCodes);
            }
            system.debug('map prodcodeToProId'+prodcodeToProId.size());
        }
        // Wrapper building code begin.
        if((!isParIdxToLstChdIdxEmpty)&&parentIndexToLstChildIndex.containsKey(TopLevel)&&(parentIndexToLstChildIndex.get(TopLevel)!=null)){
            // setting the top level from map to the Hierarchywrapper
            system.debug('top level'+parentIndexToLstChildIndex.get(TopLevel)[0].Material);
            String TopLevelProductCode =parentIndexToLstChildIndex.get(TopLevel)[0].Material;
            hw.Material=TopLevelProductCode;
            hw.showProductComponent=true;
            // highlight the product if it is matching with serached product 
                if(TopLevelProductCode.equalsIgnoreCase(searchedProd)){
                    hw.ButtonHighlight=HighlightProductBrand;
                }
                else{
                    hw.ButtonHighlight=HighlightProductBase;    
                }
            // popoulate the values of top level product if the product is found in sfdc.
                if(prodcodeToProId.containskey(TopLevelProductCode)&&prodcodeToProId.get(TopLevelProductCode)!=null){
                    hw.Material_Desc=parentIndexToLstChildIndex.get(TopLevel)[0].Material_Desc;
                    hw.Status=parentIndexToLstChildIndex.get(TopLevel)[0].Status;
                    hw.System_Blocks=parentIndexToLstChildIndex.get(TopLevel)[0].System_Blocks;
                    hw.Regulatory_Type=parentIndexToLstChildIndex.get(TopLevel)[0].Regulatory_Type;
                    hw.recId =prodcodeToProId.get(TopLevelProductCode);
                    hw.disable=false;
                    hw.BomLevel=parentIndexToLstChildIndex.get(TopLevel)[0].BOM_Level;
                    hw.CompIndex=String.valueOf(parentIndexToLstChildIndex.get(TopLevel)[0].Comp_Index);
                    hw.ParentIndex=String.valueOf(parentIndexToLstChildIndex.get(TopLevel)[0].Parent_Index); 
                        
                }else{
                    // popoulate the  desc values of top level product if the product is not found in sfdc.
                    hw.Material_Desc=MaterialNotAvailable;
                    hw.Status='';
                    hw.System_Blocks='';
                    hw.Regulatory_Type='';
                    hw.recId ='';
                    hw.disable=true;
                    hw.BomLevel=parentIndexToLstChildIndex.get(TopLevel)[0].BOM_Level;
                    hw.CompIndex=String.valueOf(parentIndexToLstChildIndex.get(TopLevel)[0].Comp_Index);
                    hw.ParentIndex=String.valueOf(parentIndexToLstChildIndex.get(TopLevel)[0].Parent_Index);
                }
               //QACM-78 Starts
               Set<BatchResults> batchRecordList = new Set<BatchResults>();
               if(parentIndexToLstChildIndex.get(TopLevel)[0].BatchResults!=null && !parentIndexToLstChildIndex.get(TopLevel)[0].BatchResults.isEmpty()) {
                  // hw.BatchResults.addAll(parentIndexToLstChildIndex.get(TopLevel)[0].BatchResults);
                  for(ProductHierarchyBOMWrapper.BatchResults batchNumber : parentIndexToLstChildIndex.get(TopLevel)[0].BatchResults) {
                       BatchResults batchRecord = new BatchResults();
                       batchRecord.Batch = batchNumber.Batch;
                       batchRecord.BatchExpiry = batchNumber.BatchExpiry;
                       batchRecordList.add(batchRecord);
                  }
                   hw.BatchResults = batchRecordList;
                   hw.batchDisable = false;
               } else {
                   hw.batchDisable = true;
               }
               //QACM-78 End


                // send the child associated with the top level into buildHierarchyStructure method.
                if(parentIndexToLstChildIndex.get(parentIndexToLstChildIndex.get(TopLevel)[0].Comp_Index) != null){
                    for(ProductHierarchyBOMWrapper.Results p : parentIndexToLstChildIndex.get(parentIndexToLstChildIndex.get(TopLevel)[0].Comp_Index)){
                        lstchild.add(buildHierarchyStructure(p));
                        }
                    hw.items=lstchild;
                }
            
        }else{
            // hide the component if there is only message set.
            hw.showProductComponent=false;
            }
        //add the wrapper built to the list.
         lstHierarchyWrapper.add(hw);
         system.debug('????'+json.serializePretty(lstHierarchyWrapper));
         return lstHierarchyWrapper ; 
    }           
            
     
    /**
   *  @author: Sandeep 
   *  @description : recursive method.
   *  @param : ProductHierarchyBOMWrapper.Results 
   *  @return : Items
   **/
  
    
  public static Items buildHierarchyStructure(ProductHierarchyBOMWrapper.Results ph){
         // creating instance of Item
         Items parent = new Items();
         list <Items> lstItems= new list<Items>();
           parent.Material=ph.Material;
           // highlight the product if it is matching with serached product 
           if((ph.Material).equalsIgnoreCase(searchedProd)){
                parent.ButtonHighlight=HighlightProductBrand;
            }
            else{
                parent.ButtonHighlight=HighlightProductBase;    
            }
             //QACM-78 Starts
             if(ph.BatchResults!=null) {
                parent.batchDisable = false;
            } else {
                parent.batchDisable = true;
            }
            //QACM-78 End

           System.debug('inside recursion material--:'+ph.Material+'ph.Comp_Index'+ph.Comp_Index+'ph.Parent_Index'+ph.Parent_Index);
           // popoulate the values of product if the product is found in sfdc.
         if(prodcodeToProId.containskey(ph.Material)&&prodcodeToProId.get(ph.Material)!=null){
              parent.Material_Desc=ph.Material_Desc;
              parent.Status=ph.Status;
              parent.System_Blocks=ph.System_Blocks;
              parent.Regulatory_Type=ph.Regulatory_Type;
              parent.recId =prodcodeToProId.get(ph.Material);
              parent.disable=false;
              parent.BomLevel=ph.BOM_Level;
              parent.CompIndex=String.valueOf(ph.Comp_Index);
              parent.ParentIndex=String.valueOf(ph.Parent_Index);
            }
            else{
                // popoulate the desc values of product if the product is not found in sfdc.
              parent.Material_Desc=ph.Material_Desc;//QACM-79
              parent.Status=MaterialNotAvailable;//QACM-79
              parent.System_Blocks='';
              parent.Regulatory_Type=ph.Regulatory_Type;//QACM-79
              parent.recId='';
              parent.disable=true;
              parent.BomLevel=ph.BOM_Level;
              parent.CompIndex=String.valueOf(ph.Comp_Index);
              parent.ParentIndex=String.valueOf(ph.Parent_Index);
          }
      
             if(parentIndexToLstChildIndex.containskey(ph.Comp_Index)&&(parentIndexToLstChildIndex.get(ph.Comp_Index)!=null)){
                for(ProductHierarchyBOMWrapper.Results p : parentIndexToLstChildIndex.get(ph.Comp_Index)){
                    // call the recursive method if there are childs to the parent.
                    lstItems.add(buildHierarchyStructure(p));
                }
                parent.Items=lstItems;
            }
    
     return parent;
 
    } 
 
  /**
   *  @author: Prashanth
   *  @description : to get the current App on which the user is on. Default it to service max if the user is community user so that product would open in new tab.
   *  @return : String.
   **/
    @AuraEnabled
    public static String getCurrentApp(){
        Profile p = [Select Id,Name from Profile where Id =: UserInfo.getProfileId()];
        if(!p.name.containsIgnoreCase('Channel Partner')){
            // to get the current app.
            UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition Where DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
            System.debug('app--:'+appDefinition.Label);
            return appDefinition.Label;

        }else{
            return 'Service Max';
        }
    }
    /*Inner class to build the Hierarchy structure*/
   public Class HierarchyWrapper{
       // top level 
       @AuraEnabled
         public String ErrorMessage {get;set;}
         @AuraEnabled
         public String Message {get;set;}
         @AuraEnabled
         public boolean showProductComponent {get;set;}
          @AuraEnabled
         public String Material {get;set;}
         @AuraEnabled
         public String Material_Desc {get;set;}
        @AuraEnabled
         public String  Status {get;set;}
         @AuraEnabled
         public String System_Blocks {get;set;}
         @AuraEnabled
         public String Regulatory_Type{get;set;}
         @AuraEnabled
         public String recId{get;set;}
        @AuraEnabled
         public boolean disable{get;set;}
         @AuraEnabled
         public String ButtonHighlight{get;set;}
        @AuraEnabled
         public string BomLevel{get;set;}
          @AuraEnabled
         public String CompIndex{get;set;}
         @AuraEnabled
         public String ParentIndex{get;set;}
         @AuraEnabled
         public List<Items> items {get;set;}
         @AuraEnabled
         public Set<BatchResults> BatchResults {get;set;}
         @AuraEnabled//QACM-78
         public boolean batchDisable {get;set;}
     }
	 
    /*
    * Wrapper Class
    */		 
     public Class Items{
         // child structure
         @AuraEnabled
         public String Material {get;set;}
         @AuraEnabled
         public String Material_Desc {get;set;}
         @AuraEnabled
         public String  Status {get;set;}
         @AuraEnabled
         public String System_Blocks {get;set;}
         @AuraEnabled
         public String Regulatory_Type{get;set;}
         @AuraEnabled
         public String recId{get;set;}
         @AuraEnabled
         public boolean disable{get;set;}
         @AuraEnabled
         public String ButtonHighlight{get;set;}
          @AuraEnabled
         public string BomLevel{get;set;}
          @AuraEnabled
         public String CompIndex{get;set;}
         @AuraEnabled
         public String ParentIndex{get;set;}
         @AuraEnabled
         public List<Items> items {get;set;}
         @AuraEnabled//QACM-78
         public boolean batchDisable {get;set;}
         @AuraEnabled
         public Set<BatchResults> BatchResults {get;set;}
     }
     /*QACM-78 Wrapper class to hold the Batch and BatchExpiry date 
     */
     public class BatchResults {
        @AuraEnabled public String Batch;
        @AuraEnabled public String BatchExpiry;
      }
 }
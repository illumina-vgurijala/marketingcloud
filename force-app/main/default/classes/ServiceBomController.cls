/***************************************************************************************************************************************
* NAME         : ServiceBomController
* DESCRIPTION  : building service bom.
* @AUTHOR      : Sandeep
* @DATE        : 15-Nov-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
  Sandeep                  15-Nov-2020         version 1
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class ServiceBomController{
  
  public static List<Case> caseList = new List<Case>();  
  public static List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
  public static List<SVMXC__Installed_Product__c> listIPRecs;
  public static Map<Id, Case> mapToUpdateCase = new Map<Id, Case> ();// Added by Dhairya Shah
  public static Map<Id, SVMXC__Service_Order__c> mapToUpdateWO = new Map<Id, SVMXC__Service_Order__c> (); // Added by Dhairya Shah
  public static string closeVarStr = Label.ClosedStatus;// Added by Dhairya Shah
  
  /**
 *  @author: Sandeep 
 *  @description :get Ip Details .
 *  @param : String name
 *  @return : ProductReturnedWrapper
 **/
@AuraEnabled
public static ProductReturnedWrapper getIpDetails(String name){
   try{
      system.debug('Name'+Name);
      ProductReturnedWrapper prw = new ProductReturnedWrapper();
      InstalledProductsSelector ips = new InstalledProductsSelector();
      List<SVMXC__Installed_Product__c> installedProducts = ips.selectInstalledProductsByName(name);

      if (!installedProducts.isEmpty()) {
          SVMXC__Installed_Product__c objIp = installedProducts.get(0);
          prw.ip = objIp.Id;
          prw.material = objIp.SVMXC__Product__r.ProductCode;
          prw.sbom = objIp.Service_Bill_Of_Materials__c;
          prw.materialName = objIp.SVMXC__Product__r.Service_Product_Type__c;
          prw.productId = objIp.SVMXC__Product__r.Name;
      }
    system.debug('prw'+prw);
    return prw;
    }
        catch(Exception e){ throw new AuraHandledException(e.getMessage());}
   }
  /**
 *  @author: Sandeep 
 *  @description :get WO Details .
 *  @param : string strWoId
 *  @return : List<SVMXC__Service_Order__c>
 **/
@AuraEnabled
public static List<SVMXC__Service_Order__c> getWODetails(string strWoId){
   try{
   system.debug('strWoId'+strWoId);
   return new WorkOrdersSelector().selectWorkOrders(new set<Id>{strWoId});
   }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
}
 /**
 *  @author: Sandeep 
 *  @description :get Product Details .
 *  @param : string strProdCode
 *  @return : List<Product2>
 **/
@AuraEnabled
public static List<Product2> getProDetails(string strProdCode){
   try{
   system.debug('strProdCode'+strProdCode);
   return new ProductsSelector().selectProductFromProdCode(new set<String>{strProdCode});
   }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
}
 /**
 *  @author: Sandeep 
 *  @description :get Case Details .
 *  @param : string strCaseId
 *  @return : List<case>
 **/
@AuraEnabled
public static List<case> getCaseDetails(string strCaseId){
   try{
   system.debug('strCaseId'+strCaseId);
   return new CasesSelector().selectCases(new set<Id>{strCaseId});
   }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
}
/**
 *  @author: Sandeep 
 *  @description :get PO Details .
 *  @param : Id sbomId
 *  @return : List<SVMXC__RMA_Shipment_Order__c>
 **/
@AuraEnabled
public static List<SVMXC__RMA_Shipment_Order__c> getPODetails(string strPoId){
   try{
   system.debug('strPoId'+strPoId);
   return new PartsOrdersSelector().selectPartsOrders(new set<Id>{strPoId});
   }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
}
/**
 *  @author: Sandeep 
 *  @description :get Fru List .
 *  @param : Id sbomId,string filter
 *  @return : List<ServiceBomWrapper>
 **/
   @AuraEnabled
   public static List<ServiceBomWrapper> getFruList(Id sbomId,string filter){
      try{
    system.debug('insdie getFruList'+sbomId+filter);
    if(string.isBlank(filter)){
      filter='';
    }
      List<ServiceBomWrapper> lstSBOM = new List<ServiceBomWrapper>();
       for(FRU_List__c objFru : new FRUListSelector().selectFRUListForSBOM(new set<Id>{sbomId},filter)){
           ServiceBomWrapper sbomWrapper = new ServiceBomWrapper();
           sbomWrapper.material= objFru.Product_Code__c;
           sbomWrapper.materialName=objFru.ERP_Product__r.Name;
           sbomWrapper.type=objFru.Type__c;
           sbomWrapper.status= objFru.ERP_Product__r.IsActive ? 'Active': '';
           sbomWrapper.systemBlocks =objFru.ERP_Product__r.SFDC_Block__c;
           sbomWrapper.productRecId=objFru.ERP_Product__c;
           sbomWrapper.fruRecId = objFru.Id;
           system.debug('@@'+objFru.ERP_Product__r.Name);
          if(objFru.ERP_Product__r.Product_Image__c==null){
              system.debug('@@'+objFru.ERP_Product__r.Product_Image__c);
              sbomWrapper.disable = true; 
          }
          else{
              system.debug('**'+objFru.ERP_Product__r.Name);
              sbomWrapper.disable = false; 
               
          }
           lstSBOM.add(sbomWrapper);
       }
       system.debug('lstSBOM'+lstSBOM);
       return lstSBOM;
       }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
   }
   /**
 *  @author: Sandeep 
 *  @description :get Product details into Product Returned table .
 *  @param : Id idIP
 *  @return : List<ServiceBomWrapper>
 **/
   @AuraEnabled
   public static List<ProductReturnedWrapper> getProductReturned(Id idIP){
      try{
      system.debug('insdie getProductReturned'+idIP);
      List<ProductReturnedWrapper> lstPRW = new List<ProductReturnedWrapper>();
       for( SVMXC__Installed_Product__c objIp: new InstalledProductsSelector().selectRelatedInstalledProducts(new set<Id>{idIP})){
          ProductReturnedWrapper prWrapper = new ProductReturnedWrapper();
          prWrapper.material= objIp.SVMXC__Product__r.ProductCode;
          prWrapper.materialName=objIp.SVMXC__Product__r.Name;
          prWrapper.sbom=objIp.Service_Bill_Of_Materials__r.Name;
          prWrapper.productId=objIp.SVMXC__Product__c;
          prWrapper.ip=objIp.Name;
          lstPRW.add(prWrapper);
      }
      system.debug('lstPRW'+lstPRW);
      return lstPRW;
      }
      catch(Exception e){ throw new AuraHandledException(e.getMessage());}
   }
/**
 *  @author: Nidhi 
 *  @description :getAssociatedProduct (CMCM-3200)
 **/
@AuraEnabled
public static List<Associated_Product__c> getAssociatedProduct(String caseOrWorkOrderId) {
  //List<Associated_Product__c> associatedProd = new List<Associated_Product__c>();
  try {
  if (caseOrWorkOrderId.startsWith('500')) {
      return new AssociatedProductSelector().selectPrimaryProductwithCase(new Set<Id> {caseOrWorkOrderId});
  } else {
      return new AssociatedProductSelector().selectPrimaryProductwithWorkOrder(new Set<Id> {caseOrWorkOrderId});
    } 
   
  } catch (exception e) {
    throw new AuraHandledException('An error occurred while fetching the getAssociatedProduct: ' + e.getMessage());
  }
}
/**
 *  @author: Priya 
 *  @description :saveAssociatedProducts (CMCM-3200)
 **/
@AuraEnabled
public static String saveAssociatedProducts(String product, String sObjectRecordId) {
    try {
        List<String> closeVar = closeVarStr.split(',');// Added by Dhairya Shah
        List<Associated_Product__c> apToInsert = new List<Associated_Product__c>();
        List<Associated_Product__c> apToInsertFinal = new List<Associated_Product__c>();
        Set<Id> productIds = new Set<Id>();
        Map<String, String> mapOfIP = new Map<String, String>();

        List<Object> userAP = (List<Object>)JSON.deserializeUntyped(product);
        if (sObjectRecordId.startsWith('500')) {
          caseList = new CasesSelector().selectCasesByCaseId(sObjectRecordId);
        } else {
          workOrderList = new WorkOrdersSelector().selectWorkOrderLstFromIds(sObjectRecordId);
        }
        for(Object usrAP : userAP) {
            Associated_Product__c ap = parseAssociatedProduct(usrAP, sObjectRecordId);
            if (shouldAddProduct(ap)) {
              apToInsert.add(ap);
            }
        }

        if(apToInsert!=null && !apToInsert.isEmpty()) {
           upsert apToInsert;
           
            //Added by dhairya shah to add Product when AP is created from BOM search
            mapToUpdateCase = new Map<Id, Case> (AssociatedProduct.updateCaseForAP(apToInsert,closeVar,null));
            mapToUpdateWO =  new Map<Id, SVMXC__Service_Order__c> (AssociatedProduct.updateWOForAP(apToInsert,closeVar,null));
            AssociatedProduct.caseWoDML(mapToUpdateCase, mapToUpdateWO);
        }
        return 'Success';
    } catch(Exception e) {
        throw new AuraHandledException('Error saving associated products: ' + e.getLineNumber()+''+e.getMessage());
    }
}
/**
 *  @author: Priya 
 *  @description :parseAssociatedProduct (CMCM-3200)
 **/
private static Associated_Product__c parseAssociatedProduct(Object usrAP, String sObjectRecordId) {
    Map<String, Object> pd = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(usrAP));
    Associated_Product__c ap = new Associated_Product__c();
    ap.Product_Serial_Number__c = String.isNotBlank((String)pd.get('serialnumber')) ? (String)pd.get('serialnumber') : null;
    ap.Product_Lot_Number__c = String.isNotBlank((String)pd.get('lotNumber')) ? (String)pd.get('lotNumber') : null;
    ap.Expired_Date__c = pd.get('ExpiredDate') != null ? Date.valueOf((String)pd.get('ExpiredDate')) : null;
    ap.Is_Expired__c = pd.get('isExpire') != null ? Boolean.valueOf(String.valueOf(pd.get('isExpire'))) : false;
    ap.Is_Primary__c = pd.get('isPrimary') != null ? Boolean.valueOf(String.valueOf(pd.get('isPrimary'))) : false;
    ap.Product__c = getIdFromMap(pd, 'recId');
    ap.Id = getIdFromMap(pd, 'id');
    setLookup(ap, sObjectRecordId);
    return ap;
}

/**
 *  @author: Priya 
 *  @description :setRecordType (CMCM-3200)
 **/
private static void setLookup(Associated_Product__c ap, String sObjectRecordId) {
    if (sObjectRecordId.startsWith('500')) {
        ap.Case__c = sObjectRecordId;
        if(caseList[0].Work_Order__c != null) {
            ap.work_order__c = caseList[0].Work_Order__c;
        }
    } else {
        ap.work_order__c = sObjectRecordId;
        if(workOrderList[0].SVMXC__Case__c != null) {
            ap.Case__c = workOrderList[0].SVMXC__Case__c;
        }
    }
}
/**
 *  @author: Priya 
 *  @description :shouldAddProduct (CMCM-3200)
 **/
private static Boolean shouldAddProduct(Associated_Product__c ap) {
    return ap.Product__c != null || ap.Id != null;
}
/**
 *  @author: Priya 
 *  @description :getIdFromMap (CMCM-3200)
 **/
private static Id getIdFromMap(Map<String, Object> pd, String key) {
  return pd.get(key) != null ? (Id)pd.get(key) : null;
}
  /**
  /**
 *  @author: Sandeep 
 *  @description :build SBOM wrapper .
 **/
public class ServiceBomWrapper {
       @AuraEnabled
       public String errorMessage {get;set;}
       @AuraEnabled
       public String message {get;set;}
       @AuraEnabled
       public String material {get;set;}
       @AuraEnabled
       public String materialName {get;set;}
       @AuraEnabled
       public String  status {get;set;}
       @AuraEnabled
       public String systemBlocks {get;set;}
       @AuraEnabled
       public String type{get;set;}
       @AuraEnabled
       public String fruRecId{get;set;}
       @AuraEnabled
       public String productRecId{get;set;}
       @AuraEnabled
       public boolean disable{get;set;}
}
/**
 *  @author: Sandeep 
 *  @description :build SBOM wrapper .
 **/
public class ProductReturnedWrapper {
  @AuraEnabled
  public String material {get;set;}
  @AuraEnabled
  public String materialName {get;set;}
  @AuraEnabled
  public String sbom {get;set;}
  @AuraEnabled
  public String ip {get;set;}
  @AuraEnabled
  public String productId {get;set;}
}
}
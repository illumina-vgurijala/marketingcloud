/**
*    @author: Govind Dubey
*    @date:   22th Aug 2018
*    @description:  Lock Quantity for Professional Services & Service Contracts Products for DCP-1063
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey               22th Aug 2018          Add Price list items for Locking Quantity of Professional Services & Service Contracts Products
*             Anish Pathak               20th Aug 2019          Enable users to modify Informatics Software product quantity - DCP 25208
*             Arnab Modak                25th Sept 2019         DCP-29853 - Making FixedBundleSKU quantity read-only
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class PriceListItemsService {
public static Boolean boolQuantityUpdated =false;
public static final String PRODUCTCODEPARAMETER = 'Informatics_Software_Product_Codes';
    /*
    * @author Govind Dubey
    * @date   22th Aug 2018 
    * @description    Update the default section of Price List Item
    * @param List of Price List Item and Map of Product Id to List of Price List Item
    */
    public static Map<Id,Apttus_Config2__PriceListItem__c> updatePLIDefaults(List<Product2> lstProduct, Map<Id,List<Apttus_Config2__PriceListItem__c>> productIdToPriceListItems){
        Set<String> setProductDetailByDeveloperName = new Set<String>{PRODUCTCODEPARAMETER};
        List<Product_Detail__mdt> productCodeList = new ProductDetailsSelector().selectProductDetailByDeveloperName(setProductDetailByDeveloperName);
		Map<Id,Apttus_Config2__PriceListItem__c> idToPriceListItem = new Map<Id,Apttus_Config2__PriceListItem__c>();
        for(Product2 objProduct : lstProduct){
            if(productIdToPriceListItems.containsKey(objProduct.Id)){
                for(Apttus_Config2__PriceListItem__c objPriceListItem : productIdToPriceListItems.get(objProduct.Id)){
                    //For recurring Service/Software Products Quantity should be Read Only
                    if((objProduct.Material_Class__c == Label.ProductMaterialClassServices || objProduct.Material_Class__c == Label.ProductMaterialClassInformaticsSoftware)){
                        if(objPriceListItem.Apttus_Config2__PriceType__c == Label.PriceListItemPriceTypeRecurring){
                            if(objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c==false){
                                objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c = true;
                                idToPriceListItem.Put(objPriceListItem.Id,objPriceListItem);
                            }
                        }else{
                            if(objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c==true){
                                objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c = false;
                                idToPriceListItem.Put(objPriceListItem.Id,objPriceListItem);
                            }
                        }
                    }else if(objProduct.Product_Group__c != null){
                        //For Professional Services Products Quantity should be Read Only
                        if(objProduct.Product_Group__c.contains(Label.ProductGroupProfessionalService)){
                            if(objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c==false){
                                objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c = true;
                                idToPriceListItem.Put(objPriceListItem.Id,objPriceListItem);
                            }
                        }
                    }
					//Anish - For DCP-25208 - Quantity Increase for Informatics
                    if(!productCodeList.isEmpty() && productCodeList[0].Product_Code__c.contains(objProduct.ProductCode)){
                        if(objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c==true){
                                objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c = false;
                                idToPriceListItem.Put(objPriceListItem.Id,objPriceListItem);
                            }
                    }


                    //DCP-29853 - Making FixedBundleSKU quantity read-only
                    if(objProduct.Material_Class_Type__c == Label.FixedBundleMatClassType){
                        if(objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c==false){
                                objPriceListItem.Apttus_Config2__IsQuantityReadOnly__c = true;
                                idToPriceListItem.Put(objPriceListItem.Id,objPriceListItem);
                        }
                    }
                }
            }
        }
        return idToPriceListItem;
    }
}
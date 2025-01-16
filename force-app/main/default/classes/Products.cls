/**
 *    @author Rohan Chandarana
 *    @date   2018-06-22
 *    @description    DCP-4568: Material Association with Category,Group and Line
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *          Govind Dubey                    22-Aug-2018           onAfterUpdate and updatePriceListItem to make Quantity as Read only for DCP-1063
 *          Joshith K                       05-Nov-2018           DCP 11324-senting inactive bundle details to AEM,inactivate bundle if any product in the bundle is inactive.
 *          Vaibhav Parashar                1-April-2019          DCP-24624: Product Service Attributes should autopopulate.
 *          Saswati                         6th August 2019       DCP - 25216 : Change Category association from Material Class to Material Class Type
 *          Anish                           26th August 2019      DCP - 25208 : Quantity Increase for Informatics. 
 *          Shivani                         11th August 2021      DCP - 46929 : Cart Improvements: Show Product Details in Catalog
 *          Nishan Shetty                   22-April-2022         CodeScan Fix :Avoid Literals in If condition
 *          Aman Tyagi                      31st March 2022       Codesan fixes
 *          Shivani Jain                    22nd August 2022      DCP-50068 Add a new field for handling more products for Missing products Functionality
 *          Prem Ranjan                     20th Feb 2023         Codesan fixes (APEX) Variable Naming Conventions
 *          Priya Mukherjee                 30-Apr-2024           CMCM-2846 Modify implementation related to Missing product functionality
 *   -----------------------------------------------------------------------------------
 **/
public with sharing class Products extends ilib_SObjectDomain {

    public static final String CATEGORY_GROUP_SAP_RENEWABLE_CODE = 'ZSCO';

    public static final String REG_TYPE_ALL = 'All';
    public static final String REG_TYPE_RUO = 'RUO';
    public static final String PRODUCT_GROUP_LIMS = 'LIMS Service Contract';
    public static final String PRODUCT_GROUP_HISCAN = 'HiScan System';

    public static final String FIELD_SEPARATOR = '~';
    public static final String PRODUCT_TYPE_OPTION = 'Option';
    public static final String SFDC_SALES_BLOCK= 'SFDC_SALES_BLOCK';


    //[DCP-24624 ]
    public static final String TRACKING_SERIALIZED = 'Serialized';
    public static final String TRACKING_NON_TRACKED = 'Non-Tracked';
    public static final String TRACKING_LOT_BATCH_TRAKCED = 'Lot/Batch Tracked';
	public static final Boolean ENABLE_SERIALIZED_TRACKING = true;
    public static final Boolean ENABLE_STOCKABLE = true;
    public static Missing_Products__c missingProdsSetting = Missing_Products__c.getOrgDefaults();
    public static final String UPDATE_POLS_IPS_WITH_MISSING_PRODS = 'updatePOLsIPsWithMissingProds';

    public static Set<String> setProductFeildsToCheckForProdType = new Set<String>();
    public static List<Service_Product_Type_Mapping__mdt> lstServiceProductMetadata = new List<Service_Product_Type_Mapping__mdt>();

    //START CodeScan Fix [Avoid Literals in If condition]
    private static final String STRING_OFFLINE = 'offline';
    private static final Integer INTEGER_ONE = 1;
    //END CodeScan Fix

    /*
    * @Author: Govind Dubey
    * @Description : parameterized constructor of class Products and instantiating Product2
    * @param :List < Product2 > sObjectList
    */
    public Products(List < Product2 > sObjectList) {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new Products(sObjectList);
        }
    }

    /**
     *  @author  Vaibhav Parashar
     *  @description Before Insert Logic a.) DCP-24624
     **/
    public override void onBeforeInsert() {
        //Ritika : changes for product family update
        Set<String> setProdCode = new Set<String>();
        Set<String> setProdGroup = new Set<String>();
        List<Product2> lstProductFamilyToBeUpdated = new List<Product2>();
        
        //Fetch the Metadata table for Service Product Type Changes
        fetchServiceProductTypeMetadata();
            
        for (Product2 objProduct: (List < Product2 > ) records) {
			
			 //DCP-31054
            //INC0271291-removed batch management checkbox from the criteria
            updateProductTracking(objProduct);

            //Update Service Product Type based on different mappings in Service_Product_Type_Mapping__mdt table
            updateServiceProductType(objProduct);
            
			if(objProduct.ProductCode != null){
                setProdCode.add(objProduct.ProductCode);
                lstProductFamilyToBeUpdated.add(objProduct);
            }
            if(objProduct.Product_Group__c != null){
                setProdGroup.add(objProduct.Product_Group__c);
                lstProductFamilyToBeUpdated.add(objProduct);
            }
            //[DCP-24624] : Start                                                    
            updateTrackingAndStockableInfo(objProduct);
            //[DCP-24624] : End   
            //INC0206147: For Scheduled Product Job
            objProduct.Process_For_Batch__c = true; 
          //DCP-46929
            populateProductInfo(objProduct);
        }
        if(!lstProductFamilyToBeUpdated.isEmpty()){
            updateProductFamily(setProdCode, setProdGroup,lstProductFamilyToBeUpdated);
        }

    }

    /**
     *  @author  Rohan Chandarana
     *  @description After Insert Logic (e.g. associate product to category)
     *  Modified - CMCM-2846 - added logic to replace custom settings Missing_Products__c with custom object Missing_Product__c
     **/
    public override void onAfterInsert() {
        system.debug('Inside onAfterInsert');
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('ProductAfterInsert'); // DCP-42718
        Map<Id, Product2> idToProductWithNewCategory = new Map<Id, Product2>();
        Set<Id> setProductIdForProductServiced = new Set<Id>(); // DCP-42718
        Set<String> productExtIds = new Set<String>();
        // Fetching all Missing_Product__c records to collect the product external IDs
        
        for (Product2 p : (List<Product2>)records) {
            productExtIds.add(p.ProductCode);
        }
        
        Set<String> setMissingProdExtIds = new Set<String>();
        system.debug('productExtIds=='+ productExtIds);
        for (Missing_Product__c missingProd : [SELECT Product_External_Id__c FROM Missing_Product__c  where Product_External_Id__c in : productExtIds]) {
            system.debug('missingProd=='+ missingProd);
            setMissingProdExtIds.add(missingProd.Product_External_Id__c);
            system.debug('setMissingProdExtIds=='+ setMissingProdExtIds);
        }
    
        List<Admin_Operation__e> lstProductsToUpdateOnPOLs = new List<Admin_Operation__e>();
        for (Product2 p : (List<Product2>)records) {
            // Check if Product needs to be associated with product hierarchy or serviced
            if (String.isNotBlank(p.Family) && (p.Service_Product_Type__c == 'Instrument' || p.Service_Product_Type__c == 'Core')) {
                setProductIdForProductServiced.add(p.Id);
            }
            if (p.Apttus_Config2__ConfigurationType__c != PRODUCT_TYPE_OPTION) {
                Boolean boolProductCatAssociationNeeded = (String.isNotBlank(p.Product_Category__c) && String.isNotBlank(p.Product_Line_ilmn__c) && String.isNotBlank(p.Product_Group__c)) || String.isNotBlank(p.Material_Class_Type__c); // DCP-25216 : saswati added material_class_type
                if (boolProductCatAssociationNeeded) {
                    idToProductWithNewCategory.put(p.id, p);
                }
            }
            
            // Check if product code matches any missing product IDs
            if (setMissingProdExtIds.contains(p.ProductCode)) {
                lstProductsToUpdateOnPOLs.add(new Admin_Operation__e(Related_Record__c = p.Id, Name__c = 'UpdateProductOnPOLsIPs'));
            }
            system.debug('lstProductsToUpdateOnPOLs=='+ lstProductsToUpdateOnPOLs);
        }
    
        if (!idToProductWithNewCategory.isEmpty()) {
            associateProductToHierarchy(idToProductWithNewCategory, null);
        }
    
        // Update POLs with missing products
        if (!lstProductsToUpdateOnPOLs.isEmpty() && Feature.isOn(UPDATE_POLS_IPS_WITH_MISSING_PRODS)) {
            EventBus.publish(lstProductsToUpdateOnPOLs);
        }
    
        if (!setProductIdForProductServiced.isEmpty()) {
            queueableThread.logandQueue(new ProductQueueable('createProductServicedForDCPProducts', setProductIdForProductServiced), 'ProductQueueable', 'createProductServicedForDCPProducts');
        }
    
        if (!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SERVICE);
        }
    }
    
    /**
     *  @author  Joshith k
     *  @description Before Update Logic (e.g.change Product_Send_To_AEM_Status of bundle product as Deactivating when a bundle product is getting deactivated)
     **/
     public override void onBeforeUpdate(Map<Id, SObject> mapOld)
    {
        Map<Id, Product2> mapOldProducts = (Map<Id, Product2>)mapOld;
        //Ritika : changes for product family
        Set<String> setProdCode = new Set<String>();
        Set<String> setProdGroup = new Set<String>();
        List<Product2> lstProductFamilyToBeUpdated = new List<Product2>();
        
        //Fetch the Metadata table for Service Product Type Changes
        fetchServiceProductTypeMetadata();

        for (Product2 objNewProduct : (List<Product2>)records)
        {
            Product2 objOldProduct = mapOldProducts.get(objNewProduct.Id);
			
			//DCP-31054
            //INC0271291-removed batch management checkbox from the criteria
            updateProductTracking(objNewProduct);

            //Update Service Product Type based on different mappings in Service_Product_Type_Mapping__mdt table
            Boolean runServiceProductTypeLogic = false;
            for(String prodField : setProductFeildsToCheckForProdType){
                if(objOldProduct.get(prodField) != objNewProduct.get(prodField)){
                    runServiceProductTypeLogic = true;
                    break;
                }
            }
            //if any of the fields have changed then run the logic
            if(runServiceProductTypeLogic){updateServiceProductType(objNewProduct);}
            
            if(objNewProduct.ProductCode != null && objNewProduct.ProductCode != objOldProduct.ProductCode){
                setProdCode.add(objNewProduct.ProductCode);
                lstProductFamilyToBeUpdated.add(objNewProduct);
            }
            if(objNewProduct.Product_Group__c != null && objNewProduct.Product_Group__c != objOldProduct.Product_Group__c){
                setProdGroup.add(objNewProduct.Product_Group__c);
                lstProductFamilyToBeUpdated.add(objNewProduct);
            }
            if(objNewProduct.Run_Product_Family_Mapping__c){
                setProdGroup.add(objNewProduct.Product_Group__c);
                setProdCode.add(objNewProduct.ProductCode);
                lstProductFamilyToBeUpdated.add(objNewProduct);
                objNewProduct.Run_Product_Family_Mapping__c = false;
            }
            //[DCP-24624] : Start
            if((objOldProduct.Serial_Number_Profile__c != objNewProduct.Serial_Number_Profile__c) || (objOldProduct.FRU_Eligible__c != objNewProduct.FRU_Eligible__c))
            updateTrackingAndStockableInfo(objNewProduct);
            //[DCP-24624] : End

            if (objOldProduct.isActive == true && objNewProduct.isActive  == false && objNewProduct.Apttus_Config2__ConfigurationType__c == 'Bundle')
            {
                objNewProduct.Product_Send_To_AEM_Status__c = Label.DeactivatingBundle;
            }

            Boolean boolProductCatReassociationNeeded = (
                (
                    (String.isNotBlank(objNewProduct.Product_Category__c) && String.isNotBlank(objNewProduct.Product_Line_ilmn__c) && String.isNotBlank(objNewProduct.Product_Group__c))
                    || String.isNotBlank(objNewProduct.Material_Class_Type__c) //DCP-25216
                )
                && productCategoryFieldsChanged(objOldProduct, objNewProduct)
            );
            if (boolProductCatReassociationNeeded)
                objNewProduct.Process_For_Batch__c = true;
               //DCP-46929
            populateProductInfo(objNewProduct);
        }
        if(!lstProductFamilyToBeUpdated.isEmpty()){
            updateProductFamily(setProdCode, setProdGroup,lstProductFamilyToBeUpdated);
        }
    }

    /**
     *  @author  Rohan Chandarana
     *  @description After Update Logic (e.g. associate product to category or remove product category association)
     **/
    public override void onAfterUpdate(Map < Id, SObject > mapOld) {
        Map < Id, Product2 > idToProductWithNewCategory = new Map < Id, Product2 > ();
        Map < Id, Product2 > idToProductWithOldCategory = new Map < Id, Product2 > ();
        List < Product2 > lstProductForReadOnlyQuantity = new List < Product2 > ();
        Map < Id, Product2 > mapNewProducts = new Map < Id, Product2 > ((List < Product2 > ) records);
        Set < Id > productIds = new Set < Id > ();

        for (Product2 objOldProduct: (List < Product2 > ) mapOld.values())
        {
            Product2 objNewProduct = (Product2) Trigger.newMap.get(objOldProduct.Id);

            //Anish: DCP - 25208 : Removed  if (objOldProduct.Material_Class_Type__c != objNewProduct.Material_Class_Type__c || objOldProduct.Product_Group__c != objNewProduct.Product_Group__c) {
            // ADD Product_Code__c and Material_Class__c to IF  (can double-check PriceListItemsService to see if I missed any)
            //INC0259826
            List<PermissionSetAssignment> perms = new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('SS_Edit_Product_Image');
            if(perms.isEmpty()){
                lstProductForReadOnlyQuantity.add(objNewProduct);
            }
                

            if (objOldProduct.Apttus_Config2__ConfigurationType__c != PRODUCT_TYPE_OPTION) {
                if (productCategoryFieldsChanged(objOldProduct, objNewProduct)) {
                    idToProductWithOldCategory.put(objOldProduct.id, objOldProduct);
                    idToProductWithNewCategory.put(objNewProduct.id, objNewProduct);
                }
            }

            // Joshith k -- to sent inactive bundle details to AEM
            if ((objOldProduct.isactive) &&
                (mapNewProducts.get(objOldProduct.id).isActive == false) &&
                (objOldProduct.Apttus_Config2__ConfigurationType__c == 'Bundle') &&
                (objOldProduct.Bundle_Channel__c != 'offline')) {
                Interface_Call__e ii = new Interface_Call__e(Name__c = 'FlexBundleDataSender', Related_Record__c = objOldProduct.Id);
                EventBus.publish(ii);
            } else if ((objOldProduct.isactive == true) &&
                (mapNewProducts.get(objOldProduct.id).isactive == false) &&
                (objOldProduct.Apttus_Config2__ConfigurationType__c != 'Bundle')
            ) {
                productIds.add(objOldProduct.id);
            }
        }

        if (lstProductForReadOnlyQuantity.size() > 0) updatePriceListItem(lstProductForReadOnlyQuantity);
        if (idToProductWithOldCategory.size() > 0) removeProductHierarchyAssociation(idToProductWithOldCategory, idToProductWithNewCategory);
        if (idToProductWithNewCategory.size() > 0) associateProductToHierarchy(idToProductWithNewCategory, idToProductWithOldCategory);

        // the rest of the trigger logic relies on this object being accessible
        if (!isOptionComponentObjectAccessible())
            return;

        // Joshith k -- to inactivate a bundle which is not offline if any product in the bundle is inactive and remove inactive product from offline bundle
        List < Apttus_Config2__ProductOptionComponent__c > productOptionComponents = (List < Apttus_Config2__ProductOptionComponent__c > ) new ProductOptionComponentSelector().selectProductOptionComponentforproductid(productids);

        Set < Id > masterProductId = new Set < Id > ();
        Map < Id, Apttus_Config2__ProductOptionComponent__c > productOptionMap = new Map < Id, Apttus_Config2__ProductOptionComponent__c > ();

        for (Apttus_Config2__ProductOptionComponent__c poc: productOptionComponents) {
            masterProductId.add(poc.Apttus_Config2__ParentProductId__c);
            productOptionMap.put(poc.Apttus_Config2__ParentProductId__c, poc);
        }

        List < Product2 > parentProductlst = (List < Product2 > ) new ProductsSelector().selectProducts(masterProductId);
        List < Apttus_Config2__ProductOptionComponent__c > lstToupdate = new List < Apttus_Config2__ProductOptionComponent__c > ();
        List < Product2 > lstToinactivate = new List < Product2 > ();
        Set < Id > lstRemovedproductsids = new Set < Id > ();

        for (Product2 prod: parentProductlst) {
            if (prod.Bundle_Channel__c == STRING_OFFLINE) {
                Apttus_Config2__ProductOptionComponent__c poComp = productOptionMap.get(prod.id);
                lstRemovedproductsids.add(productOptionMap.get(prod.id).Apttus_Config2__ComponentProductId__c);
                poComp.Apttus_Config2__ProductOptionGroupId__c = null;
                lstToupdate.add(poComp);
                System.debug('removed product id ' + productOptionMap.get(prod.id).Apttus_Config2__ComponentProductId__c);
            } else {
                prod.isActive = false;
                lstToinactivate.add(prod);
            }
        }

        if (!lstToinactivate.isEmpty())
            update lstToinactivate;

        if (!lstToupdate.isEmpty())
            update lstToupdate;

        if (lstRemovedproductsids.size() > 0) {
            System.debug('Removed product ids size' + lstRemovedproductsids.size());
            List < Product2 > removedProductlst = (List < Product2 > ) new ProductsSelector().selectProducts(lstRemovedproductsids);
            sendEmailToPricingTeam(removedProductlst);
        }
    }
     /**
     *  @author  Rohan Chandarana
     *  @description Product Category Changed
     **/
    private Boolean productCategoryFieldsChanged(Product2 objOldProduct, Product2 objNewProduct) {
        return (objNewProduct.Product_Category__c != objOldProduct.Product_Category__c ||
            objNewProduct.Product_Line_ilmn__c != objOldProduct.Product_Line_ilmn__c ||
            objNewProduct.Product_Group__c != objOldProduct.Product_Group__c ||
            objNewProduct.Material_Class_Type__c != objOldProduct.Material_Class_Type__c);//DCP-25216
    }

    private static Boolean optionComponentObjectAccessible = false;
    private static Boolean optionComponentObjectAccessibleQueryDone = false;
    private Boolean isOptionComponentObjectAccessible() {
        if (optionComponentObjectAccessibleQueryDone)
            return optionComponentObjectAccessible;

        optionComponentObjectAccessibleQueryDone = true;

        try {
            optionComponentObjectAccessible = Apttus_Config2__ProductOptionComponent__c.sObjectType.getDescribe().isAccessible();
        } catch (Exception e) {
            /* no worries */
			System.debug('Inside Products the exception is '+e.getMessage());
			ApexExceptions.emit('Products',e);
        }

        return optionComponentObjectAccessible;
    }

    /**
     *  @author Govind Dubey
     *  @description update respective Price List Item to make Quantity as Read Only for DCP-1063
     *  @param lstProductId List of Product Id
     **/
    private void updatePriceListItem(List < Product2 > lstProductForReadOnlyQuantity) {
        Set < Id > setProductIds = new Set < Id > ();
        Map < Id, Apttus_Config2__PriceListItem__c > idToPriceListItem = new Map < Id, Apttus_Config2__PriceListItem__c > ();
        for (Product2 objProduct: lstProductForReadOnlyQuantity) {
            setProductIds.add(objProduct.Id);
        }

        List < Apttus_Config2__PriceListItem__c > lstPriceListItem = new PriceListItemsSelector().selectByProductIds(setProductIds);
        Map < Id, List < Apttus_Config2__PriceListItem__c >> productIdToPriceListItems = UtilsCollection.getMapOfIdToSObjects(lstPriceListItem, 'Apttus_Config2__ProductId__c');

        if (!productIdToPriceListItems.isEmpty()) {
            idToPriceListItem = PriceListItemsService.updatePLIDefaults(lstProductForReadOnlyQuantity, productIdToPriceListItems);
        }

        if (!idToPriceListItem.isEmpty())
            update idToPriceListItem.values();
    }

    /**
     *  @author Rohan Chandarana
     *  @description Associate Product To Category Hierarchy
     *  @param idToNewProduct Map of Product Id To new version Product Record 
     *  @param idToOldProduct Map of Product Id To old version Product Record 
     **/
    private void associateProductToHierarchy(Map < Id, Product2 > idToNewProduct, Map < Id, Product2 > idToOldProduct) {
        List < Apttus_Config2__ClassificationHierarchy__c > lstCategoryHierarchy = new ApttusCategoryHierarchiesSelector().selectLeaf();

        //prepare the map of leaf category (e.g. category~level!group, leafId)
        Map < String, Id > catHierarchyNameToId = new Map < String, Id > ();
        Map < String, Id > categoryNameToId = new Map < String, Id > ();

        for (Apttus_Config2__ClassificationHierarchy__c h: lstCategoryHierarchy) {
            catHierarchyNameToId.put(h.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name + FIELD_SEPARATOR + h.Apttus_Config2__AncestorId__r.Name + FIELD_SEPARATOR + h.Name, h.id);
             if(h.Apttus_Config2__Level__c==INTEGER_ONE) //DCP-25216
            categoryNameToId.put(h.Name, h.id);

        }
        System.debug('categoryNameToId::::' + categoryNameToId);
        List < Apttus_Config2__ProductClassification__c > lstProductClassificationToInsert = new List < Apttus_Config2__ProductClassification__c > ();

        for (Product2 p: idToNewProduct.values()) {
            //prepare the category key e.g. category~level!group
            if (String.isNotBlank(p.Product_Category__c) && String.isNotBlank(p.Product_Line_ilmn__c) && String.isNotBlank(p.Product_Group__c) &&
                (idToOldProduct == null ||
                    (idToOldProduct != null && (p.Product_Category__c != idToOldProduct.get(p.id).Product_Category__c || p.Product_Line_ilmn__c != idToOldProduct.get(p.id).Product_Line_ilmn__c ||
                        p.Product_Group__c != idToOldProduct.get(p.id).Product_Group__c)))) {
                String strNewKey = p.Product_Category__c + FIELD_SEPARATOR + p.Product_Line_ilmn__c + FIELD_SEPARATOR + p.Product_Group__c;
                if (catHierarchyNameToId.containsKey(strNewKey)) {
                    Apttus_Config2__ProductClassification__c productClassification = new Apttus_Config2__ProductClassification__c(
                        Apttus_Config2__ClassificationId__c = catHierarchyNameToId.get(strNewKey),
                        Apttus_Config2__ProductId__c = p.id
                    );
                    lstProductClassificationToInsert.add(productClassification);
                }
            }
            System.debug('categoryNameToId.get(p.Material_Class_Type__c::::' + categoryNameToId.get(p.Material_Class_Type__c)); //DCP-25216
            System.debug('p.Material_Class_Type__c::::' + p.Material_Class_Type__c); //DCP-25216
            System.debug('idToOldProduct::::' + idToOldProduct);
            System.debug('categoryNameToId::::' + categoryNameToId);
            if (String.isNotBlank(p.Material_Class_Type__c) && (idToOldProduct == null || (idToOldProduct != null && p.Material_Class_Type__c != idToOldProduct.get(p.id).Material_Class_Type__c)) &&
                categoryNameToId.containskey(p.Material_Class_Type__c)) { //DCP-25216
                Apttus_Config2__ProductClassification__c productClassification = new Apttus_Config2__ProductClassification__c(
                    Apttus_Config2__ClassificationId__c = categoryNameToId.get(p.Material_Class_Type__c), 
                    Apttus_Config2__ProductId__c = p.id
                ); //DCP-25216
                lstProductClassificationToInsert.add(productClassification);
            }
        }

        if (lstProductClassificationToInsert.size() > 0) {
            System.debug('lstProductClassificationToInsert::::' + lstProductClassificationToInsert);
            insert lstProductClassificationToInsert;
        }
    }

    /**
     *  @author Rohan Chandarana
     *  @description Remove Product and Category Hierarchy Association using the Product Group
     *  @param idToOldProduct Map of Product Id To Product Record
     **/
    private void removeProductHierarchyAssociation(Map < Id, Product2 > idToOldProduct, Map < Id, Product2 > idToNewProduct) {
        //prepare the map of product category (e.g. classificationName~productId, classificaiton Id)
        Map < String, Id > categoryProdNameToClassificationId = new Map < String, Id > ();
        Map < String, Id > categoryNameToId = new Map < String, Id > ();

        List < Apttus_Config2__ProductClassification__c > lstProductClassification = new ApttusProductClassificationSelector().findByProductIds(idToOldProduct.keySet());
        for (Apttus_Config2__ProductClassification__c pc: lstProductClassification) {
            categoryProdNameToClassificationId.put(pc.Apttus_Config2__ClassificationId__r.Name + FIELD_SEPARATOR + pc.Apttus_Config2__ProductId__c, pc.id);
            categoryNameToId.put(pc.Apttus_Config2__ClassificationId__r.Name, pc.id);
        }
        System.debug('categoryNameToId::::' + categoryNameToId);

        Map < Id, Apttus_Config2__ProductClassification__c > idToProductClassificationToDelete = new Map < Id, Apttus_Config2__ProductClassification__c > ();
        for (Product2 objProduct: idToOldProduct.values()) {
            if (objProduct.Product_Category__c != idToNewProduct.get(objProduct.id).Product_Category__c || objProduct.Product_Line_ilmn__c != idToNewProduct.get(objProduct.id).Product_Line_ilmn__c ||
                objProduct.Product_Group__c != idToNewProduct.get(objProduct.id).Product_Group__c) {
                String strProductGroup = objProduct.Product_Group__c;
                //prepare the key e.g. productCategoryName~productId
                String strCategoryProdName = strProductGroup + FIELD_SEPARATOR + objProduct.id;
                if (categoryProdNameToClassificationId.containsKey(strCategoryProdName)) {
                    idToProductClassificationToDelete.put(
                        categoryProdNameToClassificationId.get(strCategoryProdName), new Apttus_Config2__ProductClassification__c(id = categoryProdNameToClassificationId.get(strCategoryProdName))
                    );
                }
            }
            System.debug('categoryNameToId.get(objProduct.Material_Class_Type__c)::::' + categoryNameToId.get(objProduct.Material_Class_Type__c));//DCP-25216
            if (String.isNotBlank(objProduct.Material_Class_Type__c) && objProduct.Material_Class_Type__c != idToNewProduct.get(objProduct.id).Material_Class_Type__c &&
                categoryNameToId.containskey(objProduct.Material_Class_Type__c)) {
                idToProductClassificationToDelete.put(
                    categoryNameToId.get(objProduct.Material_Class_Type__c), new Apttus_Config2__ProductClassification__c(id = categoryNameToId.get(objProduct.Material_Class_Type__c))
                );//DCP-25216
            }
        }

        if (!idToProductClassificationToDelete.isEmpty()) delete idToProductClassificationToDelete.values();
    }

    /**
     *  @author Vaibhav Parashar
     *  @description [DCP-24624] : Product Service Attributes should autopopulate.
     *                             a.) (If) Serial Number Profile is != Blank then populate Tracking = Serialized and Enabled Serialized Tracking of Stock = True
                                       (else) Tracking = Non-Tracked and Enabled Serialized Tracking of Stock = False.
                                   b.) (If) Fru Eligible = "FRU use only" OR "MFG and FRU use" then Stockable = true (else) false.
     *  @param product record instance
     **/
    private void updateTrackingAndStockableInfo(Product2 product) {
    
        product.SVMXC__Enable_Serialized_Tracking__c = String.IsNotBlank(product.Serial_Number_Profile__c) ? ENABLE_SERIALIZED_TRACKING : !ENABLE_SERIALIZED_TRACKING;
        product.SVMXC__Stockable__c = String.IsNotBlank(product.FRU_Eligible__c) && (product.FRU_Eligible__c.equalsIgnoreCase('FRU use only') || product.FRU_Eligible__c.equalsIgnoreCase('MFG and FRU use')) ? ENABLE_STOCKABLE : !ENABLE_STOCKABLE;
       
    }

    /**
     *  @author Joshith K
     *  @description Sent Email to Pricing Team when a producer is removed from an offline bundle
     *  @param  Removedproducts list of removed Product 
     **/
    @TestVisible
    private void sendEmailToPricingTeam(List < Product2 > removedProducts) {
        String devName = 'Email_To_PricingTeam';
        List < Code_Parameter__mdt > codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: devname];
        System.debug('inside emailer');

        if (codeParameter.size() > 0) {
            sendTheEmails(codeParameter[0].Value__c, removedProducts);
        }
    }
     /**
     *  @author Joshith K
     *  @description Sent Email to Pricing Team when a producer is removed from an offline bundle
     *  @param  Removedproducts list of removed Product 
     **/
    @TestVisible
    private void sendTheEmails(String paramValue, List < Product2 > removedProducts) {
        // split out for test coverage
        System.debug('inside codeparameter');
        List < String > toAddress = new List < String > ();
        toAddress.addall(paramValue.split(','));

        List < Messaging.SingleEmailMessage > lstMails = new List < Messaging.SingleEmailMessage > ();

        for (Product2 pro: removedProducts) {
            System.debug('inside product for loop');
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.settoaddresses(toAddress);
            mail.setSubject('Bundle Discontinued');
            String mailBody = pro.Bundle_Id__c;
            mail.setplaintextbody(mailBody);
            lstMails.add(mail);
        }

        Messaging.sendEmail(lstMails);
    }

    /**
     *  @author Ritika R
     *  @description update the product family for the product based on prduct code, product group
     *  @param  setProdCode set of product codes to be matched for product family
     *  @param  setProdGroup set of product group to be matched for product family
     *  @param  lstFamilyMappingCheck list of product for which product family needs o be updated
     **/
    private void updateProductFamily(Set<String> setProdCode, Set<String> setProdGroup, List<Product2> lstFamilyMappingCheck){
        Map<String,Product_Family_Mapping__mdt> prodCodeToFamilyMetadataMap = new Map<String,Product_Family_Mapping__mdt>();
        Map<String,Product_Family_Mapping__mdt> prodGroupToFamilyMetadataMap = new Map<String,Product_Family_Mapping__mdt>();
        //Fetch metadata matching prod code
        for(Product_Family_Mapping__mdt prodFamilyMetadata : [Select Product_Code__c,Product_Group__c, Product_Family__c,Check_For_DX__c
                                                            FROM Product_Family_Mapping__mdt 
                                                            where Product_Code__c IN : setProdCode])
        {
            prodCodeToFamilyMetadataMap.put(prodFamilyMetadata.Product_Code__c,prodFamilyMetadata);
        } 
        //Fetch metadata matching product group
        for(Product_Family_Mapping__mdt prodFamilyMetadata : [Select Product_Code__c,Product_Group__c, Product_Family__c,Check_For_DX__c
                                                            FROM Product_Family_Mapping__mdt 
                                                            where Product_Group__c IN : setProdGroup])
        {
            prodGroupToFamilyMetadataMap.put(prodFamilyMetadata.Product_Group__c,prodFamilyMetadata);
        }
        for(Product2 prod : lstFamilyMappingCheck){ 
            Product_Family_Mapping__mdt prodFamilyMetadata;
            if(prod.ProductCode != null && prodCodeToFamilyMetadataMap.containsKey(prod.ProductCode)){
                prodFamilyMetadata = prodCodeToFamilyMetadataMap.get(prod.ProductCode);
            }else if(prod.Product_Group__c != null && prodGroupToFamilyMetadataMap.containsKey(prod.Product_Group__c)){
                prodFamilyMetadata = prodGroupToFamilyMetadataMap.get(prod.Product_Group__c);
            }
            
            if(prodFamilyMetadata != null){
                prod.Family = prodFamilyMetadata.Product_Family__c;
                if(prodFamilyMetadata.Check_For_DX__c){
                    prod.Family = prodFamilyMetadata.Product_Family__c + ' DX';
                }
            }
        }
    }

    /**
     *  @author Ritika R
     *  @description update the service product type for the product based on mapping defined in metadata Service_Product_Type_Mapping__mdt
     *  @param   objProduct product record for which service prod type is to be set
     **/
    private void updateServiceProductType(Product2 objProduct){
        for(Service_Product_Type_Mapping__mdt serviceProductTypeMetadata : lstServiceProductMetadata){
            if(objProduct.get(serviceProductTypeMetadata.Product_Field_Name__c) == serviceProductTypeMetadata.Product_Field_Value__c)
            {
                objProduct.Service_Product_Type__c = serviceProductTypeMetadata.Service_Product_Type__c;
                return;
            }
        }
        objProduct.Service_Product_Type__c = 'Core';
    }

    /**
     *  @author Ritika R
     *  @description fetch all the records from metadata Service_Product_Type_Mapping__mdt
     **/
    private void fetchServiceProductTypeMetadata(){
        for(Service_Product_Type_Mapping__mdt serviceProductMetadata: [Select Sequence__c,Product_Field_Value__c,Product_Field_Name__c, Service_Product_Type__c
                                                            FROM Service_Product_Type_Mapping__mdt
                                                            ORDER BY Sequence__c])
        {
            lstServiceProductMetadata.add(serviceProductMetadata);
            setProductFeildsToCheckForProdType.add(serviceProductMetadata.Product_Field_Name__c);
        }
    }

    private void updateProductTracking(Product2 objProduct){
        if(String.isNotBlank(objProduct.Serial_Number_Profile__c)){
            objProduct.SVMXC__Tracking__c = TRACKING_SERIALIZED;
        }else if(objProduct.Batch_Management__c){
            objProduct.SVMXC__Tracking__c = TRACKING_LOT_BATCH_TRAKCED;
        }else{ 
            objProduct.SVMXC__Tracking__c = TRACKING_NON_TRACKED;
        }
    }

     //DCP-42718
    /*
    * @Author: Anish
    * @Description : method for creating productserviced for DCPProducts based on Id
    * @param :set<Id> setProductIdForProductServiced
    * @return: void 
    */
    public static void createProductServicedForDCPProducts(set<Id> setProductIdForProductServiced){
    LMSCertificationDataReceiver.createProductServicedForDCPProducts(setProductIdForProductServiced);
    }

      /**
     *  @author Shivani Jain
     *  @description DCP-46929 populate the Product Information field
     *  @param  objProduct Product record
    **/
    private void populateProductInfo(Product2 objProduct) {
        final List<String> SALES_BLOCK_STATUSES = new List<String>{'Block for Sales', 'Sales Block', 'Blocked for Shipment'};
        final List<String> Y1TOY4_STATUS= new List<String>{'Y1','Y2','Y3','Y4'};
        final List<String> Y5Y6_STATUS= new List<String>{'Y5','Y6'};
        List<String> errorMsgs = new List<String>();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalform();
        String warningIcon = '<img src="' + baseUrl + '/resource/Image_Warning" width="18" height="18"></img>';
        String redCrossIcon = '<img src="' + baseUrl + '/resource/Image_Error" width="18" height="18"></img>';
        String infoIcon = '<img src="'+ baseUrl + '/resource/Image_Information" width="18" height="18"></img>';
        
        if (objProduct.End_Of_Sale_Date__c != null) {
            List<String> params = new List<String>{warningIcon, String.valueOf(objProduct.End_Of_Sale_Date__c)};
            errorMsgs.add(String.format(Label.ProductInfo_EndOfSaleDate, params));
        }
        if (objProduct.End_Of_Service_Date__c != null) {
            List<String> params = new List<String>{warningIcon, String.valueOf(objProduct.End_Of_Service_Date__c)};
            errorMsgs.add(String.format(Label.ProductInfo_EndOfServiceDate, params));
        }
        if (Y1TOY4_STATUS.contains(objProduct.Cross_Plant_Material_Status__c)) {
            List<String> params = new List<String>{warningIcon, objProduct.Cross_Plant_Material_Status_Description__c,
                objProduct.Cross_Plant_Material_Status__c};
            errorMsgs.add(String.format(Label.ProductInfo_y1Toy4StatusMsg, params));
        }
        if (Y5Y6_STATUS.contains(objProduct.Cross_Plant_Material_Status__c)) {
            List<String> params = new List<String>{warningIcon, objProduct.Cross_Plant_Material_Status_Description__c,
                objProduct.Cross_Plant_Material_Status__c};
            errorMsgs.add(String.format(Label.ProductInfo_y5y6StatusMsg, params));
        }
        if (SALES_BLOCK_STATUSES.contains(objProduct.Cross_Distribution_Chain_Status__c) || 
            SFDC_SALES_BLOCK.equals(objProduct.SFDC_Block__c)) {
            List<String> params = new List<String>{redCrossIcon, objProduct.Cross_Plant_Material_Status_Description__c};
            errorMsgs.add(String.format(Label.ProductInfo_SalesBlock, params));
        }
        if (String.isNotBlank(objProduct.Product_Level_Indicator__c) && !Label.Product_Level_Indicator.equals(objProduct.Product_Level_Indicator__c)) {
            List<String> params = new List<String>{infoIcon, objProduct.Product_Level_Indicator__c};
            errorMsgs.add(String.format(Label.ProductInfo_COM_PROD, params));
        }

        String finalError = '';
        if(!errorMsgs.isEmpty()) {          
            for(String error : errorMsgs) {
                finalError += error;
            }           
        }
        objProduct.Product_Information__c = finalError;
    }
}
/***************************************************************************************************************************************
* NAME         : EquipmentMasterDataReceiver
* DESCRIPTION  : DCP-904:Equipment Master Synchronization to DCP(ServiceMax) (INT_C-370-001)
*              :This class accepts the JSON sent from Snaplogic and make upsert operation based on the EquipmentId given.
*              :JSON structure holds a parent Installed product with an array of child Installed products. Please refer to
*              :a sample JSON attached at the end of this class for more clarity.   
* @AUTHOR      : 
* @DATE        : 28-June-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Vaibhav Parashar         30 Aug 2018         Added changes related to Work Order Debrief. 
*                                              A new list of child arrays will be sent along with the parent Installed products.
*                                              Updates made to handle the new JSON structure.
* Sagar Madkaikar          02 Sep 2021         CMCP-232/CMCP-14 : When new Child IPs are inserted and if Top Level IP is Shipped and Product Serviced Type=Instrument
*                                                         Populate all Chil IP's Company Field with Parent IP's Company
* Rucha Dalvi              02 Mar 2023         INC0444601 - Changed logic to set status as Shipped
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@RestResource(urlMapping = '/EquipmentMasterSyncInterface/*')
global with sharing class EquipmentMasterDataReceiver extends ilib_RestReceiver {


  private Set < String > topLevelExtIdSet = new Set < String > ();
  private Map < String, String > topLevelExtIdToTopLevel = new Map < String, String > ();
  private Map < String, String > toplevelExtIdToInsPrdId = new Map < String, String > ();
  private Set < String > parentExtIdSet = new Set < String > ();
  private Map < String, String > parentExtIdToParent = new Map < String, String > ();
  private Map < String, String > parentExtIdToInsPrdId = new Map < String, String > ();
  private Set < String > newInstalledProductsExtIdSet = new Set < String > ();
  private Map < String, SVMXC__Installed_Product__c > extIdToInsPrd = new Map < String, SVMXC__Installed_Product__c > ();

  //CMCP-232/CMCP-14
  private Map < String, String > productCodeToProductType = new Map < String, String > ();
  private static final String STRING_INSTRUMENT = 'Instrument';
  //private Map < String, String > topLevelExtIdToProductCode = new Map < String, String > ();
  private Map < String, String > topLevelExtIdToCompanyId = new Map < String, String > ();
  
/**
 * ReceivedData Class
 */
  private class ReceivedData extends ilib_ReceivedData {
    List < EquipmentMasterDataReceiverWrapper.InstalledProducts > installedProducts;

    /**
 * ReceivedData Constructor
 */
    public ReceivedData(List < EquipmentMasterDataReceiverWrapper.InstalledProducts > installedProducts) {
      this.installedProducts = installedProducts;
    }
  }

  private ReceivedData data {
    get {
      return (ReceivedData) idata;
    }
  }

  ///////////////////////////////////////////////
  //  entry point
  ///////////////////////////////////////////////
  /**
   * upsertIncomingValues
   */
  @Httppost
  global static void upsertIncomingValues() {
    ilib_RestReceiver instantiated = new EquipmentMasterDataReceiver();
    instantiated.receive();
  }

  /**
   * deserializeJson
   */
  protected override ilib_ReceivedData deserializeJson(String jsonInput) {
    List < EquipmentMasterDataReceiverWrapper.InstalledProducts > serialized = (List < EquipmentMasterDataReceiverWrapper.InstalledProducts > ) System.JSON.deserialize(jsonInput, List < EquipmentMasterDataReceiverWrapper.InstalledProducts > .class);
    ReceivedData data = new ReceivedData(serialized);
    return data;
  }

  /**
   * buildUnitOfWork
   */
  protected override ilib_SObjectUnitOfWork buildUnitOfWork() {
    ilib_SObjectUnitOfWork objUnitOfWork = new ilib_SObjectUnitOfWork(new List < Schema.SObjectType > {
      SVMXC__Installed_Product__c.SObjectType
    });

    addInstalledProductLookups();

    addSObjectsToUOW(objUnitOfWork);

    return objUnitOfWork;
  }

  private void addInstalledProductLookups() {



    //Map AccountCustomerId to AccountId
    Map < String, String > accountCustomerIdTOActId = new Map < String, String > ();

    //Map ServiceBOMExtId to ServiceBOMId
    Map < String, String > serviceBOMExtIdTOServiceBOMId = new Map < String, String > ();

    //Map LocationExtId to LocationId
    Map < String, String > locationExtIdTOLocId = new Map < String, String > ();



    //Map ProductMaterialId to PrdId
    Map < String, String > productMaterialIdToPrdId = new Map < String, String > ();

    //AccountExtIdSet       
    Set < String > acExtIdSet = new Set < String > ();

    //ServiceBOMExtIdSet       
    Set < String > serviceBOMExtIdSet = new Set < String > ();

    //LocationExtIdSet       
    Set < String > locExtIdSet = new Set < String > ();

    //ProductExtIdSet       
    Set < String > productExtIdSet = new Set < String > ();
    //ProductExtIdSet to check for missing Product
    //Set < String > productExtIdSetForMissingProds = new Set < String > ();
    //Map < String, String > productExtIdToProduct = new Map < String, String > ();


    for (EquipmentMasterDataReceiverWrapper.InstalledProducts wrapPrd: data.installedProducts) {

      //GetAccountExtIdS
      acExtIdSet.add(wrapPrd.SVMXC_Company);

      //GetServiceBOMExtIdS
      serviceBOMExtIdSet.add(wrapPrd.Service_BOM);

      //Get locExtIdSet
      locExtIdSet.add(wrapPrd.SVMXC_Location);

      //GetToplevelExtId
      if (String.isNotBlank(wrapPrd.SVMXC_Top_Level)) {
        topLevelExtIdSet.add(wrapPrd.SVMXC_Top_Level);
        topLevelExtIdToTopLevel.put(wrapPrd.ERP_Equipment_Id, wrapPrd.SVMXC_Top_Level);
      }

      //GetParentExtId
      if (String.isNotBlank(wrapPrd.SVMXC_Parent)) {
        parentExtIdSet.add(wrapPrd.SVMXC_Parent);
        parentExtIdToParent.put(wrapPrd.ERP_Equipment_Id, wrapPrd.SVMXC_Parent);
      }

      //GetProductExtId
      if (String.isNotBlank(wrapPrd.SVMXC_Product)){
        productExtIdSet.add(wrapPrd.SVMXC_Product);
        /*
        if(String.isNotBlank(wrapPrd.ERP_Equipment_Id)){
          productExtIdSetForMissingProds.add(wrapPrd.SVMXC_Product);
        }
        */
        //CMCP-232
        //topLevelExtIdToProductCode.put(wrapPrd.ERP_Equipment_Id, wrapPrd.SVMXC_Product);
      }

      //Iterate over child array list and store toplevel,parent and product values in a set created for parent.
      for (EquipmentMasterDataReceiverWrapper.InstallBase wrapPrdChild: wrapPrd.InstallBase) {
        //GetToplevelExtId
        if (String.isNotBlank(wrapPrdChild.SVMXC_Top_Level)) {
          topLevelExtIdSet.add(wrapPrdChild.SVMXC_Top_Level);
          topLevelExtIdToTopLevel.put(wrapPrdChild.ERP_Equipment_Id, wrapPrdChild.SVMXC_Top_Level);
        }

        //GetParentExtId
        if (String.isNotBlank(wrapPrdChild.SVMXC_Parent)) {
          parentExtIdSet.add(wrapPrdChild.SVMXC_Parent);
          parentExtIdToParent.put(wrapPrdChild.ERP_Equipment_Id, wrapPrdChild.SVMXC_Parent);
        }

        //GetProductExtId
        if (String.isNotBlank(wrapPrdChild.SVMXC_Product)){
          productExtIdSet.add(wrapPrdChild.SVMXC_Product);
          /*
          if(String.isNotBlank(wrapPrdChild.ERP_Equipment_Id)){
            productExtIdSetForMissingProds.add(wrapPrdChild.SVMXC_Product);
          }
          */
        }

      }

    }


    //Map AccountCustomerId to AccountId
    for (Account ac: new AccountsSelector().selectAccountsForERPCustomerIds(acExtIdSet)) {
      accountCustomerIdTOActId.put(ac.ERP_Customer_Id__c, ac.id);
    }

    //Map ServiceBOMExtId to ServiceBOMId
    for (Service_Bill_Of_Materials__c serviceBOM: new ServiceBOMsSelector().selectServiceBOMsByERPServiceBOMNumber(serviceBOMExtIdSet)) {
      serviceBOMExtIdTOServiceBOMId.put(serviceBOM.ERP_Service_BOM_Number__c, serviceBOM.id);
    }

    //Map LocationExtId to LocationId
    for (SVMXC__Site__c loc: new LocationsSelector().selectLocationsForExternalId(locExtIdSet)) {
      locationExtIdTOLocId.put(loc.SVMX_PS_External_ID__c, loc.id);
    }

    //Map ToplevelExtId to InsPrdId
    //Modified for Defect-DCP[9512]
    for (SVMXC__Installed_Product__c tInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(topLevelExtIdSet)) {
      toplevelExtIdToInsPrdId.put(tInsprd.ERP_Equipment_ID__c, tInsprd.id);
    }
    
     //Modified for Defect-DCP[9512]
    //Map ParentExtId to InsPrdId 
    for (SVMXC__Installed_Product__c pInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(parentExtIdSet)) {
      parentExtIdToInsPrdId.put(pInsprd.ERP_Equipment_ID__c, pInsprd.id);
    }
    
    //Map ProductMaterialId to PrdId  r.Material_Number__c productExtIdSet
    for (Product2 prdM: new ProductsSelector().selectProductsForMaterialNumber(productExtIdSet)) {
      productMaterialIdToPrdId.put(prdM.Material_Number__c, prdM.id);
      //productExtIdSetForMissingProds.remove(prdM.Material_Number__c);
      //CMCP-232 : Add product Material Number and Product type to a map if Service_Product_Type__c=='Instrument'
      if(prdM.Service_Product_Type__c==STRING_INSTRUMENT)
        productCodeToProductType.put(prdM.Material_Number__c, prdM.Service_Product_Type__c);
    }

    /*
    if(!productExtIdSetForMissingProds.isEmpty()){
      if(Feature.isOn('MissingProductNotificationsToGFSL')){				
        ServiceUtilityCollection.sendEmailToGFSLAndStoreProdExtId(productExtIdSetForMissingProds);
      }
    }
    */

    for (EquipmentMasterDataReceiverWrapper.InstalledProducts wrapPrd: data.installedProducts) {

      wrapPrd.SVMXC_Company_SFDC_Id = accountCustomerIdTOActId.containsKey(wrapPrd.SVMXC_Company) ? accountCustomerIdTOActId.get(wrapPrd.SVMXC_Company) : null;
      wrapPrd.SVMXC_Product_SFDC_Id = productMaterialIdToPrdId.containsKey(wrapPrd.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapPrd.SVMXC_Product) : null;
      wrapPrd.SVMXC_Top_Level_SFDC_Id = toplevelExtIdToInsPrdId.containsKey(wrapPrd.SVMXC_Top_Level) ? toplevelExtIdToInsPrdId.get(wrapPrd.SVMXC_Top_Level) : null;
      wrapPrd.SVMXC_Parent_SFDC_Id = parentExtIdToInsPrdId.containsKey(wrapPrd.SVMXC_Parent) ? parentExtIdToInsPrdId.get(wrapPrd.SVMXC_Parent) : null;
      wrapPrd.SVMXC_Site_SFDC_Id = locationExtIdTOLocId.containsKey(wrapPrd.SVMXC_Location) ? locationExtIdTOLocId.get(wrapPrd.SVMXC_Location) : null;
      wrapPrd.Service_BOM_SFDC_Id = serviceBOMExtIdTOServiceBOMId.containsKey(wrapPrd.Service_BOM) ? serviceBOMExtIdTOServiceBOMId.get(wrapPrd.Service_BOM) : null;


      for (EquipmentMasterDataReceiverWrapper.InstallBase wrapPrdChild: wrapPrd.InstallBase) {
        
        wrapPrdChild.SVMXC_Product_SFDC_Id = productMaterialIdToPrdId.containsKey(wrapPrdChild.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapPrdChild.SVMXC_Product) : null;
        wrapPrdChild.SVMXC_Top_Level_SFDC_Id = toplevelExtIdToInsPrdId.containsKey(wrapPrdChild.SVMXC_Top_Level) ? toplevelExtIdToInsPrdId.get(wrapPrdChild.SVMXC_Top_Level) : null;
        wrapPrdChild.SVMXC_Parent_SFDC_Id = parentExtIdToInsPrdId.containsKey(wrapPrdChild.SVMXC_Parent) ? parentExtIdToInsPrdId.get(wrapPrdChild.SVMXC_Parent) : null;

      }

    }


  }

/**
   * addSObjectsToUOW
   */
  private void addSObjectsToUOW(ilib_SObjectUnitOfWork objUnitOfWork) {

    ilib_UpsertHelpers.InsPrdUnitofWorkHelper insProdWork = new ilib_UpsertHelpers.InsPrdUnitofWorkHelper();
    objUnitOfWork.registerWork(insProdWork);
	
	  Map < String, String > extIdToInsPrdStatus = new Map < String, String > ();
    Map < String, String > installedProductToInsPrdStatus = new Map < String, String > ();
	//Added by Shruti Karn -INC0298442
    Map < String, String > installedProductToLocation = new Map < String, String > ();

    for (EquipmentMasterDataReceiverWrapper.InstalledProducts wrapPrd: data.installedProducts) {

      SVMXC__Installed_Product__c installedPrd = new SVMXC__Installed_Product__c();
      installedPrd = wrapPrd.getSObject();

      //store only the values where erp id is not blank
      //Added for Status change
      if (String.isNotBlank(installedPrd.ERP_Equipment_Id__c)) {
        extIdToInsPrd.put(installedPrd.ERP_Equipment_Id__c, installedPrd);
        extIdToInsPrdStatus.put(installedPrd.ERP_Equipment_Id__c, wrapPrd.SVMXC_Status);
		//Added by Shruti Karn -INC0298442
        installedProductToLocation.put(installedPrd.ERP_Equipment_Id__c,wrapPrd.SVMXC_Location);
        //CMCP-232/CMCP-14 : If Status is Shipped & Product Type is Instrument only then add (TopLevelErpId,ToLevelAccountId) to topLevelExtIdToCompanyId map.
        checkShippedInstrument(wrapPrd,installedPrd);
        //if(wrapPrd.SVMXC_Status!='ESTO' && String.isBlank(wrapPrd.SVMXC_Top_Level) && productCodeToProductType.containsKey(wrapPrd.SVMXC_Product))
          //topLevelExtIdToCompanyId.put(installedPrd.ERP_Equipment_Id__c, installedPrd.SVMXC__Company__c);
      }

      for (EquipmentMasterDataReceiverWrapper.InstallBase wrapPrdChild: wrapPrd.InstallBase) {

        //Child Installed product get populated.
        SVMXC__Installed_Product__c childInstalledPrd = new SVMXC__Installed_Product__c();
        childInstalledPrd = wrapPrdChild.getSObject();


        if (!extIdToInsPrd.containsKey(childInstalledPrd.ERP_Equipment_Id__c) && String.isNotBlank(childInstalledPrd.ERP_Equipment_Id__c))
          extIdToInsPrd.put(childInstalledPrd.ERP_Equipment_Id__c, childInstalledPrd);
      }

    }

    //loop to populate Id column of InstalledProduct objects based on ExternalId
    for (SVMXC__Installed_Product__c insPrdObj: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(extIdToInsPrd.keyset())) {
      extIdToInsPrd.get(insPrdObj.ERP_Equipment_Id__c).Id = insPrdObj.id;
      //Added for Status change
      installedProductToInsPrdStatus.put(insPrdObj.ERP_Equipment_Id__c, insPrdObj.SVMXC__Status__c);
    }
    
    
    
    //loop to register Sobjects for insertion or update.
    for (String insPrdExternalId: extIdToInsPrd.keyset()) {
        
      if (String.IsBlank(extIdToInsPrd.get(insPrdExternalId).Id)) {
        //create new Installed Product records if not present in the database already.
        objUnitOfWork.registerNew(extIdToInsPrd.get(insPrdExternalId));
        //store the external Id of newly inserted installed product records.
        newInstalledProductsExtIdSet.add(insPrdExternalId);
      } else {
        //update the status only when the existinginstalled product status is not equal to installed.
        //Added for Status change
        if (String.isNotBlank(installedProductToInsPrdStatus.get(insPrdExternalId)) && extIdToInsPrdStatus.get(insPrdExternalId) == 'ESTO'){
        	extIdToInsPrd.get(insPrdExternalId).SVMXC__Status__c = 'Returned';
			    //Added by Shruti Karn -INC0298442 - On REturn, if the Location sent is null, update the same on installed product
          if(String.isBlank(installedProductToLocation.get(insPrdExternalId))) {
            extIdToInsPrd.get(insPrdExternalId).SVMXC__Site__c =null;
          }      
        }else if((String.isBlank(installedProductToInsPrdStatus.get(insPrdExternalId)) || installedProductToInsPrdStatus.get(insPrdExternalId) == 'Returned') && extIdToInsPrdStatus.get(insPrdExternalId) == 'ECUS') {
          extIdToInsPrd.get(insPrdExternalId).SVMXC__Status__c = 'Shipped';
        }//changed else to else if condition as part of INC0444601
        insProdWork.registerUpsert(extIdToInsPrd.get(insPrdExternalId));
      }
    }


  }

  /**
   * doBusinessLogic
   */
  public override void doBusinessLogic() {

    Map < String, String > newInstalledProductExtIdToInsPrdId = new Map < String, String > ();
    List < SVMXC__Installed_Product__c > newInstalledProdList = new List < SVMXC__Installed_Product__c > ();
    Map < String, String > newInstalledProductSalesOrdNumToInsPrdId = new Map < String, String > ();
    Map < String, SVMXC__Service_Order__c > workOrderERPOrderLineToWorkOrderId = new Map < String, SVMXC__Service_Order__c > ();

    //Map ToplevelExtId to InsPrdId
    //Modified for Defect-DCP[9512]
    for (SVMXC__Installed_Product__c tInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(topLevelExtIdSet)) {
      toplevelExtIdToInsPrdId.put(tInsprd.ERP_Equipment_ID__c, tInsprd.id);
    }

    //Modified for Defect-DCP[9512]
    //Map ParentExtId to InsPrdId
    for (SVMXC__Installed_Product__c pInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(parentExtIdSet)) {
      parentExtIdToInsPrdId.put(pInsprd.ERP_Equipment_ID__c, pInsprd.id);
    }

    /***** Logic to create hierarchy after insert *****/
    System.debug('newInstalledProductsExtIdSet ===> ' + newInstalledProductsExtIdSet);
    if (newInstalledProductsExtIdSet != null && !newInstalledProductsExtIdSet.isEmpty()) {
      //get the salesforce record Id
      for (SVMXC__Installed_Product__c pInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(newInstalledProductsExtIdSet)) {
        newInstalledProductExtIdToInsPrdId.put(pInsprd.ERP_Equipment_ID__c, pInsprd.id);
      }

      //populate the latest inserted inst prods with top level and parent
      for (String newInsPrdRec: newInstalledProductExtIdToInsPrdId.keyset()) {
        SVMXC__Installed_Product__c newInstalledPrd = new SVMXC__Installed_Product__c();
        newInstalledPrd.Id = newInstalledProductExtIdToInsPrdId.get(newInsPrdRec);

        newInstalledPrd.SVMXC__Top_Level__c = toplevelExtIdToInsPrdId.containsKey(topLevelExtIdToTopLevel.get(newInsPrdRec)) ? toplevelExtIdToInsPrdId.get(topLevelExtIdToTopLevel.get(newInsPrdRec)) : null;
        newInstalledPrd.SVMXC__Parent__c = parentExtIdToInsPrdId.containsKey(parentExtIdToParent.get(newInsPrdRec)) ? parentExtIdToInsPrdId.get(parentExtIdToParent.get(newInsPrdRec)) : null;
        
        //Start:CMCP-232/CMCP-14: Populate Child IP's Company field with Top Level IP's Company
        if(newInstalledPrd.SVMXC__Top_Level__c!=null)// && productCodeToProductType.containsKey(topLevelExtIdToProductCode.get(topLevelExtIdToTopLevel.get(newInsPrdRec))))
        {
          if(topLevelExtIdToCompanyId.containsKey(topLevelExtIdToTopLevel.get(newInsPrdRec)))
            newInstalledPrd.SVMXC__Company__c = topLevelExtIdToCompanyId.get(topLevelExtIdToTopLevel.get(newInsPrdRec));
        }
        //End:CMCP-232/CMCP-14: Populate Child IP's Company field with Top Level IP's Company
        
        system.debug('newInstalledPrd ===> ' + newInstalledPrd);
        newInstalledProdList.add(newInstalledPrd);
      }
      //CMCP-14: Regression Bug fix. Setting hasRunPartnerSharing of InstalledProducts trigger class to false to run the partner sharing on update trigger
      InstalledProducts.hasRunPartnerSharing = false;
      if (newInstalledProdList != null && !newInstalledProdList.isEmpty())
        update newInstalledProdList;
    }


    /***** Logic to update Work Order *****/

    /* 1.) Populate the Installed Product Lookup on WO
       2.) Match Sales Order Number On Installed Product with ERP Order Line Number on WO and 
           then populate the Installed Product lookup field on WO.
        */

    for (SVMXC__Installed_Product__c pInsprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(extIdToInsPrd.keyset())) {
      String salesOrderNumber = '';
      salesOrderNumber = String.isNotBlank(pInsprd.SVMXC__Sales_Order_Number__c) && pInsprd.SVMXC__Sales_Order_Number__c.contains('.') ? pInsprd.SVMXC__Sales_Order_Number__c.replace('.', '_') : pInsprd.SVMXC__Sales_Order_Number__c;
      System.debug('salesOrderNumber ===> ' + salesOrderNumber);
      if (String.isNotBlank(pInsprd.SVMXC__Sales_Order_Number__c)) {
        newInstalledProductSalesOrdNumToInsPrdId.put(salesOrderNumber, pInsprd.id);
      }
    }

    //Select all Work Orders    
    system.debug('newInstalledProductSalesOrdNumToInsPrdId ' + newInstalledProductSalesOrdNumToInsPrdId);
    for (SVMXC__Service_Order__c workOrders: new WorkOrdersSelector().selectWorkOrdersForOrderLineNumberWithBlankIP(newInstalledProductSalesOrdNumToInsPrdId.keySet())) {
      workOrderERPOrderLineToWorkOrderId.put(workOrders.Id, workOrders);
    }

    system.debug('workOrderERPOrderLineToWorkOrderId ' + workOrderERPOrderLineToWorkOrderId);

    for (String workOrderERPLineNumber: workOrderERPOrderLineToWorkOrderId.keySet()) {
      if (String.isBlank(workOrderERPOrderLineToWorkOrderId.get(workOrderERPLineNumber).SVMXC__Component__c))
        workOrderERPOrderLineToWorkOrderId.get(workOrderERPLineNumber).SVMXC__Component__c = newInstalledProductSalesOrdNumToInsPrdId.get(workOrderERPOrderLineToWorkOrderId.get(workOrderERPLineNumber).ERP_Order_Line_Number__c);
    }

    if (workOrderERPOrderLineToWorkOrderId.values() != null && !workOrderERPOrderLineToWorkOrderId.values().isEmpty()){
     //Added for CMCM-12852
      WorkOrders.skipWOTrigger = true; 
      WorkOrders.isWOUpdateFromEquipmentSync = true;
      update workOrderERPOrderLineToWorkOrderId.values();
    }


  }
  
  /**
   * //find the single record ID
   */
  protected override Id findSingleRecordId() {
  if (data.installedProducts.size() == 1 && extIdToInsPrd.containsKey(data.installedProducts.get(0).getSObject().ERP_Equipment_Id__c))
      return extIdToInsPrd.get(data.installedProducts.get(0).getSObject().ERP_Equipment_Id__c).Id;
    else
      return null;
  }
  /** checkShippedInstrument
    * @author Sagar Madkaikar
    * @date   28-Oct-2021
    * @description: //CMCP-232/CMCP-14 CodeScan Fix : If Status is Shipped & Product Type is Instrument only then add (TopLevelErpId,ToLevelAccountId) to topLevelExtIdToCompanyId map.
    * @params : EquipmentMasterDataReceiverWrapper.InstalledProducts wrapPrd
    * @return : void
    */
  private void checkShippedInstrument(EquipmentMasterDataReceiverWrapper.InstalledProducts wrapPrd,SVMXC__Installed_Product__c installedPrd) {
    if(wrapPrd.SVMXC_Status!='ESTO' && String.isBlank(wrapPrd.SVMXC_Top_Level) && productCodeToProductType.containsKey(wrapPrd.SVMXC_Product))
        topLevelExtIdToCompanyId.put(installedPrd.ERP_Equipment_Id__c, installedPrd.SVMXC__Company__c);
  }


}


/*
SAMPLE INPUT RECIEVED

[{
    "ERP_Equipment_Id": "47631",
    "SVMXC_Serial_Lot_Number": "200131",
    "Asset_Type": "INTERNAL",
    "SVMXC_Sales_Order_Number": "?",
    "SVMXC_Company": "6000000293",
	"SVMXC_Location": "TS100214",
    "SVMXC_Product": "47631",
    "SVMXC_Top_Level": "",
    "SVMXC_Parent": "",
    "Service_BOM": "",
    "SVMXC_Date_Ordered": "2018-10-18",
    "SVMXC_Date_Shipped": "2018-10-18",
    "Cost_Center": "3044100",
    "Country_of_Origin": "?",
    "Plant_of_Origin": "3310",
    "Previous_Equipment_Number": "12344",
    "Next_Equipment_Number": "1233445",
    "SVMXC_Status": "Shipped",
    "InstallBase": [{
            "ERP_Equipment_Id": "47632",
            "SVMXC_Serial_Lot_Number": "200132",
            "SVMXC_Product": "47632",
            "SVMXC_Top_Level": "47631",
            "SVMXC_Parent": "47631"
        },
        {
            "ERP_Equipment_Id": "47633",
            "SVMXC_Serial_Lot_Number": "200133",
            "SVMXC_Product": "47633",
            "SVMXC_Top_Level": "47631",
            "SVMXC_Parent": "47632"
        }
    ]
}]


*/
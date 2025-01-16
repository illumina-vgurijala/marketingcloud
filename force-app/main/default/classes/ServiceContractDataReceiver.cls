/***************************************************************************************************************************************
* NAME         : ServiceContractDataReceiver
* DESCRIPTION  : Service Contract Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 14-Oct-2018
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Gopinath Reddy           8-Jan-2019          DCP - 30474 Loigic : Replacing Registration contact(PGUID) with Contact id.
* Gopinath Reddy           29-Jan-2019         DCP - 32166 Loigic : Calling the Queueable Job for Case Creation
* Dhairya Shah             29-Feb-2024         CMCM-9
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@RestResource(urlMapping = '/ServiceContractSyncInterface/*')
global with sharing class ServiceContractDataReceiver extends ilib_RestReceiver {

	private SVMXC__Service_Contract__c oneContract;	
  //Varibales for CMCM-9 start
  public static String shipTo='Ship To';
  public static String soldTo='Sold To';
  public static String ultimateConsignee='Ultimate Consignee';
  public static String z3='Z3';
  public static String wE='WE';//CMCM-9 CR Change 7th March 2024
  public static String aG='AG';//CMCM-9 CR Change 7th March 2024
  public static Set<String> strType = new Set<String>{'Ship To','Sold To','Ultimate Consignee'};
  public static Map < String, String >  siteLocationIdToSVMXCsite = new Map < String, String > ();

  //CMCM-9 END

  /*
  * @description: This class holds data related to sercice contract
  */
  private class ReceivedData extends ilib_ReceivedData {
    List < ServiceContractDataReceiverWrapper.serviceContracts > serviceContracts;

    /*
    * @description: constructor used to assign data related to sercice contract to a list
    */
    public ReceivedData(List < ServiceContractDataReceiverWrapper.serviceContracts > serviceContracts) {
      this.serviceContracts = serviceContracts;
    }
  }

  /*
  * @description: return the type casted fetched data
  */	
  private ReceivedData data {
    get {
      return (ReceivedData) idata;
    }
  }

  ///////////////////////////////////////////////
  //  entry point
  ///////////////////////////////////////////////

  
  /**
  * @description To create variable for ilib_RestReceiver
  * @author  
  **/
  @Httppost
  global static void upsertIncomingValues() {
    ilib_RestReceiver instantiated = new ServiceContractDataReceiver();
    instantiated.receive();
  }

  /*
  * @description: override ilib_ReceivedData - This method is used to deserialize Json
  */
  protected override ilib_ReceivedData deserializeJson(String jsonInput) {
    List < ServiceContractDataReceiverWrapper.serviceContracts > serialized = (List < ServiceContractDataReceiverWrapper.serviceContracts > ) System.JSON.deserialize(jsonInput, List < ServiceContractDataReceiverWrapper.serviceContracts > .class);
    ReceivedData data = new ReceivedData(serialized);
    return data;
  }

  /*
   *  @author Service thread
   *  @description - buildUnitOfWork instance which is eventually passed into a queuableHelper class.
   *  @PARAM :  N/A
   *  @RETURN:  ilib_SObjectUnitOfWork
   */
  protected override ilib_SObjectUnitOfWork buildUnitOfWork() {

    ilib_SObjectUnitOfWork objUnitOfWork = new ilib_SObjectUnitOfWork(new List < Schema.SObjectType > {
      SVMXC__Service_Contract__c.SObjectType,
      SVMXC__Service_Contract_Products__c.SObjectType,
      SVMXC__Service_Contract_Sites__c.SObjectType
    });

    addServiceContractLookups(); //populate lookup fields.

    addSObjectsToUOW(objUnitOfWork); //prepare the uow method.

    return objUnitOfWork;
  }

  /*
   *  @author Service thread
   *  @description - This method populates the lookup field invlved in this interface.
   *  @PARAM :  N/A
   *  @RETURN:  void
   */
  private void addServiceContractLookups() {

    /* STORE ALL LOOKUP VARIABLES HERE */

    //AccountExtIdSet - Company
    Set < String > acExtIdSet = new Set < String > ();
    //Map AccountCustomerId to AccountId
    Map < String, String > accountCustomerIdTOActId = new Map < String, String > ();

    //installedProductExtIdSet  - Installed Product    
    Set < String > installedProductExtIdSet = new Set < String > ();

    //erpCustomerIdSet --- SVMXC site IDs  CMCM-9
    Set < String > siteIdSet = new Set < String > ();

    //servicePlanExtIdSet - Service Plan
    Set < String > servicePlanExtIdSet = new Set < String > ();
    //Map servicePlanExtIdToServicePlanId
    Map < String, String > servicePlanExtIdToServicePlanId = new Map < String, String > ();

    // DCP-33359
    Set < String > orderlineExternalId = new Set < String > ();
    Map < String, Apttus_Config2__OrderLineItem__c > maporderlineExternalIdToOLI = new Map < String, Apttus_Config2__OrderLineItem__c > ();

    //Map installedProductExtIdToInsPrdId   
    Map < String, String > installedProductExtIdToInsPrdId = new Map < String, String > ();
    Set < String > setERPHeaderContractNumber = new Set < String > ();
    
    // DCP-30474 Logic: Creating map and set to replace PGUID(Registratin Contract) with contact id.
    Set < String > setRegContactId = new Set < String > ();
    Map < String, Id > mapRegContactIdToContactId = new Map < String, Id > ();


    /** POPULATE LOOKUP VARIABLES **/
    //iterate over parent records.
    for (ServiceContractDataReceiverWrapper.serviceContracts wrapServContract: data.serviceContracts) {
      setERPHeaderContractNumber.add(wrapServContract.ERP_Header_Contract_Number);
      //populate company at header level.
      acExtIdSet.add(wrapServContract.SVMXC_Company);
      //populate service plan
      if (String.IsNotBlank(wrapServContract.SVMXC_Service_Plan))
        servicePlanExtIdSet.add(wrapServContract.SVMXC_Service_Plan);

      //DCP-33359
      if (String.isNotBlank(wrapServContract.ERP_Header_Contract_Number) && String.isNotBlank(wrapServContract.ERP_Contract_Line_Number)) {
        orderlineExternalId.add(wrapServContract.ERP_Header_Contract_Number + '_' + wrapServContract.ERP_Contract_Line_Number);
      }

      /* ITERATE OVER CHILD RECORDS */
      for (ServiceContractDataReceiverWrapper.CoveredProducts wrapCoveredProducts: wrapServContract.CoveredProducts) {
        installedProductExtIdSet.add(wrapCoveredProducts.ERP_Equipment_Id);
      }

      /*ITERATE OVER COVERED LOCATION CHILD RECORDS CMCM-9*/
      for (ServiceContractDataReceiverWrapper.CoveredLocations wrapCoveredLocations: wrapServContract.CoveredLocations) {
        if(wrapCoveredLocations.SiteType == z3 || wrapCoveredLocations.SiteType == aG || wrapCoveredLocations.SiteType == wE){
          siteIdSet.add(wrapCoveredLocations.SVMXC_Site);
        }
      }


      //DCP-30474 Logic: Adding Registration Contact Ids to Set
      if (!(String.isBlank(wrapServContract.Registration_Contact))) {
        setRegContactId.add(wrapServContract.Registration_Contact);
      }

    }

    //Map AccountCustomerId to AccountId 
    for (Account ac: new AccountsSelector().selectAccountsForERPCustomerIds(acExtIdSet)) {
      accountCustomerIdTOActId.put(ac.ERP_Customer_Id__c, ac.id);
    }

    //Map ERPExtId to InstalledProductId 
    for (SVMXC__Installed_Product__c insprd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(installedProductExtIdSet)) {
      installedProductExtIdToInsPrdId.put(insprd.ERP_Equipment_ID__c, insprd.id);
    }

    for (SVMXC__Service_Plan__c servicePlan: new ServicePlanSelector().selectServicePlanForItemNumber(servicePlanExtIdSet)) {
      servicePlanExtIdToServicePlanId.put(servicePlan.Item_Number__c, servicePlan.id);

    }
    //Map SVMXC site to LocationId CMCM-9 
    for (SVMXC__Site__c siteLoc: new LocationsSelector().selectLocationsFromErpCusIds(siteIdSet,strType)) {
      if(siteLoc.Type__c ==shipTo || siteLoc.Type__c ==soldTo || siteLoc.Type__c == ultimateConsignee){ //CMCM-9 CR Change 7th March 2024 added all the else if in one cond.
        siteLocationIdToSVMXCsite.put(siteLoc.ERP_Customer_ID__c, siteLoc.id);
      }

    }

    //DCP - 30474 Logic : Mapping Registration Contact(PGUID ID) with contact ID.
    if (!setRegContactId.isEmpty()) {
      for (Contact contacts: new ContactsSelector().selectContactIdsforPGUIDId(setRegContactId)) {
        mapRegContactIdToContactId.put(contacts.PGUID__c, contacts.id);
      }
    }

    //DCP - 33359
    System.debug('orderlineExternalId --> ' + orderlineExternalId);
    for (Apttus_Config2__OrderLineItem__c oli: new ApttusOrderLineItemsSelector().selectOLIbyERPHeaderContract(orderlineExternalId)) {
      maporderlineExternalIdToOLI.put(oli.ERP_Line_Number_Id__c, oli);
    }

    //Iterate over Parent Object
    for (ServiceContractDataReceiverWrapper.serviceContracts wrapServContract: data.serviceContracts) {

      wrapServContract.SVMXC_Company_SFDC_Id = accountCustomerIdTOActId.containsKey(wrapServContract.SVMXC_Company) ? accountCustomerIdTOActId.get(wrapServContract.SVMXC_Company) : null;
      wrapServContract.SVMXC_Service_Plan_SFDC_Id = String.IsNotBlank(wrapServContract.SVMXC_Service_Plan) && servicePlanExtIdToServicePlanId.containsKey(wrapServContract.SVMXC_Service_Plan) ? servicePlanExtIdToServicePlanId.get(wrapServContract.SVMXC_Service_Plan) : null;

      //DCP-30474 LOgic : Giving contact id in Registration Contact based on PGUID ID.
      if (!mapRegContactIdToContactId.isEmpty()) {
        wrapServContract.Registration_Contact_SFDC_Id = mapRegContactIdToContactId.containsKey(wrapServContract.Registration_Contact) ? mapRegContactIdToContactId.get(wrapServContract.Registration_Contact) : null;
      }

      // DCP - 33359 Order Line Item Lookup Created
      System.debug('maporderlineExternalIdToOLI --> ' + maporderlineExternalIdToOLI);
      String strOrderLineExtId = wrapServContract.ERP_Header_Contract_Number + '_' + wrapServContract.ERP_Contract_Line_Number;
      if (!maporderlineExternalIdToOLI.isEmpty() && maporderlineExternalIdToOLI.containsKey(strOrderLineExtId)) {
        wrapServContract.SVMXC_Order_Line_Item_SFDC_Id = maporderlineExternalIdToOLI.get(strOrderLineExtId).id;
      }

      /* ITERATE OVER CHILD RECORDS */
      for (ServiceContractDataReceiverWrapper.CoveredProducts wrapCoveredProducts: wrapServContract.CoveredProducts) {
        /** lookup fields **/
        wrapCoveredProducts.ERP_Equipment_SFDC_Id = installedProductExtIdToInsPrdId.containsKey(wrapCoveredProducts.ERP_Equipment_Id) ? installedProductExtIdToInsPrdId.get(wrapCoveredProducts.ERP_Equipment_Id) : null;

      }

    }

  }

  /*
   *  @author Service thread
   *  @description - This method populates final list to be upserted.
   *  @PARAM :  N/A
   *  @RETURN:  void
   */
  private void addSObjectsToUOW(ilib_SObjectUnitOfWork objUnitOfWork) {

    /* REGISTER HELPERS : MANDATORY STEP */

    // Register custom helpers: This is a mandatory step.
    ilib_UpsertHelpers.ServContrUnitofWorkHelper servContractWork = new ilib_UpsertHelpers.ServContrUnitofWorkHelper();
    ilib_UpsertHelpers.CoveredPrdUnitOfWorkHelper conLineItemWork = new ilib_UpsertHelpers.CoveredPrdUnitOfWorkHelper();
    ilib_UpsertHelpers.CoveredLocationUnitOfWorkHelper coveredLocationWork = new ilib_UpsertHelpers.CoveredLocationUnitOfWorkHelper();
    /* END */

    /* REGISTER OBJECTS : GENERIC STATEMENT */
    objUnitOfWork.registerWork(servContractWork);
    objUnitOfWork.registerWork(conLineItemWork);
    objUnitOfWork.registerWork(coveredLocationWork);
    /* / REGISTER OBJECTS : GENERIC STATEMENT */

    //Iterate over Parent Object
    for (ServiceContractDataReceiverWrapper.serviceContracts wrapServContract: data.serviceContracts) {

      SVMXC__Service_Contract__c servContractObj = wrapServContract.getServiceContractObj();
      oneContract = servContractObj;
     //INC0200579 
      if (servContractObj.Status__c == 'Canceled' && String.isNotBlank(wrapServContract.SVMXC_End_Date) && Date.valueOf(wrapServContract.SVMXC_End_Date) > System.today()) {
        servContractObj.Pending_Cancellation__c = true;
        servContractObj.Status__c = 'Active'; //47708
      }
      servContractWork.registerUpsert(servContractObj);


      /* ITERATE OVER CHILD RECORDS */
      for (ServiceContractDataReceiverWrapper.CoveredProducts wrapCoveredProducts: wrapServContract.CoveredProducts) {
        //instantiate child object.
        SVMXC__Service_Contract_Products__c coveredProd = new SVMXC__Service_Contract_Products__c();

        //It has all the fields information which will be updated.
        coveredProd = wrapCoveredProducts.getCoveredProductsObj();
        coveredProd.External_ID__c = wrapServContract.ERP_Header_Contract_Number + wrapServContract.ERP_Contract_Line_Number;

        /** Date Fields **/
        if (String.isNotBlank(wrapServContract.SVMXC_Start_Date)) {
          coveredProd.SVMXC__Start_Date__c = date.valueOf(wrapServContract.SVMXC_Start_Date);
        }

        if (String.isNotBlank(wrapServContract.SVMXC_End_Date)) {
          coveredProd.SVMXC__End_Date__c = date.valueOf(wrapServContract.SVMXC_End_Date);
        }

        /* Upsert */
        objUnitOfWork.registerRelationship(coveredProd, SVMXC__Service_Contract_Products__c.SVMXC__Service_Contract__c, servContractObj);
        conLineItemWork.registerUpsert(coveredProd);
      }

      /* ITERATE OVER COVERED LOCATIONS CHILD RECORDS CMCM-9*/
      if(servContractObj.SVMXC__Service_Plan__c !=null && wrapServContract.SVMXC_Service_Plan !=null){
        upsertCoveredLocations(objUnitOfWork,servContractObj,wrapServContract,coveredLocationWork);//CMCM-9 CR Change 7th March 2024 to resolve the codescan error
      }
    }
  }
  /*
   *  @author Dhairya Shah
   *  @description - CMCM-9 CR Change 7th March 2024 to resolve the codescan error
   *  @PARAM :  ilib_SObjectUnitOfWork, SVMXC__Service_Contract__c,ServiceContractDataReceiverWrapper.serviceContracts,ilib_UpsertHelpers.CoveredLocationUnitOfWorkHelper
   *  @RETURN:  void
   */
  private void upsertCoveredLocations(ilib_SObjectUnitOfWork objUnitOfWork,SVMXC__Service_Contract__c servContractObj,ServiceContractDataReceiverWrapper.serviceContracts wrapServContract, ilib_UpsertHelpers.CoveredLocationUnitOfWorkHelper coveredLocationWork){
    Set<String> setProductCode = new Set<String>{wrapServContract.SVMXC_Service_Plan};
    String serviceLevel = 'DEDICATE';
    List<Product2> pdList = new ProductsSelector().selectProductWithServLevel(setProductCode,serviceLevel);
    if(pdList!=null && !pdList.isEmpty() && wrapServContract.CoveredLocations!=null){
      Set<String> checkDuplicateSite = new Set<String>();
      for (ServiceContractDataReceiverWrapper.CoveredLocations wrapCoveredLocations: wrapServContract.CoveredLocations) {
        //instantiate child object.
        if(siteLocationIdToSVMXCsite.containsKey(wrapCoveredLocations.SVMXC_Site)){
            checkDuplicateMethod(checkDuplicateSite, objUnitOfWork, wrapCoveredLocations, servContractObj, coveredLocationWork);
        }
      }
    }
  }


 /*
   *  @author Dhairya Shah
   *  @description - CMCM-9 CR Change 7th March 2024 to resolve the codescan error
   *  @PARAM :  checkDuplicateSite, objUnitOfWork,ServiceContractDataReceiverWrapper,SVMXC__Service_Contract__c, coveredLocationWork
   *  @RETURN:  void
   */
 public static void checkDuplicateMethod(Set<String> checkDuplicateSite, ilib_SObjectUnitOfWork objUnitOfWork, ServiceContractDataReceiverWrapper.CoveredLocations wrapCoveredLocations, SVMXC__Service_Contract__c servContractObj, ilib_UpsertHelpers.CoveredLocationUnitOfWorkHelper coveredLocationWork){
    if(!checkDuplicateSite.contains(wrapCoveredLocations.SVMXC_Site)){
      SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c();
      checkDuplicateSite.add(wrapCoveredLocations.SVMXC_Site);
      //It has all the fields information which will be updated.
      coveredLocation = wrapCoveredLocations.getCoveredLocationObj();
      coveredLocation.SVMXC__Site__c = siteLocationIdToSVMXCsite.get(wrapCoveredLocations.SVMXC_Site);
      /* Upsert */
      objUnitOfWork.registerRelationship(coveredLocation, SVMXC__Service_Contract_Sites__c.SVMXC__Service_Contract__c, servContractObj);
      coveredLocationWork.registerUpsert(coveredLocation);
    }
 }

  /*find the single record ID*/
  protected override Id findSingleRecordId() {
    if (data.serviceContracts.size() == 1 && oneContract != null)
      return oneContract.Id;
    else
      return null;
  }


}


/* Sample JSON as part of DCP-30474

URI:/services/apexrest/ServiceContractSyncInterface/

[{
    "SVMX_PS_External_ID": "12344",
    "Name": "Test_new Description",
    "Status": "Blocked",
    "ERP_Header_Contract_Number": "0045001002",
    "SVMXC_Company": "6000006999",
    "ERP_Contract_Line_Number": "000012",
    "ERP_Contract_Type": "Illmna Base Warranty",
    "SVMXC_Cancelation_Notes": "Z1",
    "SVMXC_Start_Date": "2018-08-21",
    "SVMXC_Service_Plan": "",
    "SVMXC_End_Date": "2019-08-20",
    "Custom_License_Flag":true,
    "Domain_ID":"ABCD",
    "Domain_URL_Pattern":"ABCD",
    "Field_Installation":true,
    "Instance_Region":"ABCD",
    "Dragen_Connectivity":"Online",
    "Registration_Contact_Email":"ABCD",
    "Workgroup_ID":"ABCD",
    "Workgroup_Name":"ABCD",
    "Zuora_Subscription_ID":"ABCD",
    "CoveredProducts": [{
        "ERP_Equipment_Id": "1000704958"
    }],
    "CoveredLocations": [{
        "ERP_Covered_Location": "6000000293",
        "SVMXC_Site": "6000000293"

    }]

}]




*/
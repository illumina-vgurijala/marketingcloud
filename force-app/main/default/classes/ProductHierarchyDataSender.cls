/***************************************************************************************************************************************
* NAME         : ProductHierarchyDataSender
* DESCRIPTION  : Sending the Product information to SAP and creating a product hierarchy back in SFDC.
*                    
* @AUTHOR      : 
* @DATE        : 15-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION
* Anand Palla           26-Apr-2022        CodeScan Fix-Avoid Literals in If condition 
* Avina                 27-Sep-2022        QACM-78 Updated returnParentChildResponse
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class ProductHierarchyDataSender {

  //request 1 endpoints - where_used
  public static final String WHERE_USED_INTERFACE_NAME_HEAD_AND_POST = 'Outgoing_ProdHeirarchy_WhereUsed'; //"Head" and "Post" endpoints are same.

  //request 2 endpoints - bom_explosion
  public static final String BOM_EXPLOSION_INTERFACE_NAME_HEAD_AND_POST = 'Outgoing_ProdHeirarchy_Bom';

  public final static String SUCCESS_STRING = 'Success';
  public final static String FAILURE_STRING = 'Fail';
  public final static String DIRECTION = 'Inbound';
  public final static String INTERFACE_NAME = 'Product Hierarchy Inbound';
  public final static String STRING_CONTENT_TYPE = 'application/json';
  public final static String STRING_XCRF_TOKEN = 'x-csrf-token';
  
  //Start CodeScan Fix [Avoid Literals in If condition]
  private static final Integer STATUS_CODE = 200;
  //End CodeScan Fix
  public static final String PRODUCT_2 = 'Product2';

  public static HttpResponse authResponse;
  public static HttpResponse response;

  public static ProductHierarchyWhereUsedWrapper ProductHierarchyWhereUsedWrapperObj;
  public static ProductHierarchyBOMWrapper productHierarchyBOMWrapperObj;
  public static Map < Integer, List < ProductHierarchyBOMWrapper.Results >> productHierarchyBOMWrapperObjMap;

   /**
   *  @author 
   *  @description Http method enum
   **/
  public enum HttpMethod {
    HEAD,
    POST
  } //hold http actions.


  /**
   *  @author Vaibhav
   *  @description makes a callout to send product information given from the LWC component.
   *  @param None
   *  @return String
   **/
  @AuraEnabled
  public static ProductHierarchyWhereUsedWrapper getProductsWithTopLevelProductsFromSAP(string jsonString) {

    system.debug('jsonString == ' + jsonString);

    //check if the input string is not blank
    if (String.isNotBlank(jsonString)) {

      //authenticate the connection first
      authResponse = authenticate('whereUsed');

      //if the authResponse is "200", proceed ahead to extract the information.
      if (authResponse.getStatuscode() == STATUS_CODE) {

        //store the access token in the header for the next callout.
        Map < String, String > headerKeyToValue = setHeaderToKeyValue(authResponse);

        //make a callout with json body
        response = executeCallout(jsonString, WHERE_USED_INTERFACE_NAME_HEAD_AND_POST, HttpMethod.POST.name(), headerKeyToValue);

        //success
        if ((response.getStatusCode() == 201 || response.getStatusCode() == 200) && !response.getBody().toLowerCase().contains('error')) {

          //parse the sap response into a wrapper class.
          ProductHierarchyWhereUsedWrapperObj = ProductHierarchyWhereUsedWrapper.parseWhereUsedResponse(response.getBody());
          ProductHierarchyWhereUsedWrapperObj.sfdcToSAPCalloutStatus = SUCCESS_STRING;
          ProductHierarchyWhereUsedWrapperObj.Message = SUCCESS_STRING;
          system.debug('whereUsedResponse-->'+response.getBody());
          system.debug('whereUsedResponseProductHierarchyWhereUsedWrapperObj'+ProductHierarchyWhereUsedWrapperObj);
          //log finalize method called (successful case)
          ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), SUCCESS_STRING, response.getBody(), null, response);

        } else {

          //parse the sap response into a wrapper class.
          ProductHierarchyWhereUsedWrapperObj = new ProductHierarchyWhereUsedWrapper();
          ProductHierarchyWhereUsedWrapperObj.sfdcToSAPCalloutStatus = FAILURE_STRING;
          ProductHierarchyWhereUsedWrapperObj.Message = response.getBody();

          //log finalize method called (failed case)
          ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), FAILURE_STRING, response.getBody(), null, response);

        }


      } else {

        ProductHierarchyWhereUsedWrapperObj = new ProductHierarchyWhereUsedWrapper();
        ProductHierarchyWhereUsedWrapperObj.sfdcToSAPCalloutStatus = FAILURE_STRING;
        ProductHierarchyWhereUsedWrapperObj.Message = authResponse.getBody();

        //log finalize method called (failed case)
        ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), FAILURE_STRING, authResponse.getBody(), null, authResponse);

      }


    }

    return ProductHierarchyWhereUsedWrapperObj;
  }


  /**
   *  @author Vaibhav
   *  @description makes a callout to send product information given from the LWC component.
   *  @param None
   *  @return String
   **/
  @AuraEnabled
  public static Map < Integer, List < ProductHierarchyBOMWrapper.Results >> getProductComponentsForTopLevelProductsFromSAP(string jsonString) {

    //check if the input string is not blank
    if (String.isNotBlank(jsonString)) {

      //authenticate the connection first
      authResponse = authenticate('bom');

      //if the authResponse is "200", proceed ahead to extract the information.
      if (authResponse.getStatuscode() == STATUS_CODE) {

        Map < String, String > headerKeyToValue = setHeaderToKeyValue(authResponse);

        response = executeCallout(jsonString, BOM_EXPLOSION_INTERFACE_NAME_HEAD_AND_POST, HttpMethod.POST.name(), headerKeyToValue);

        if ((response.getStatusCode() == 201 || response.getStatusCode() == 200) && !response.getBody().toLowerCase().contains('error')) {

          //parse the sap response into a wrapper class.
          productHierarchyBOMWrapperObj = ProductHierarchyBOMWrapper.parseBOMExplosionResponse(response.getBody());
          productHierarchyBOMWrapperObj.sfdcToSAPCalloutStatus = SUCCESS_STRING;
          productHierarchyBOMWrapperObj.Message = String.isNotBlank(productHierarchyBOMWrapperObj.d.Message) ? productHierarchyBOMWrapperObj.d.Message : SUCCESS_STRING;
          productHierarchyBOMWrapperObjMap = returnParentChildResponse(productHierarchyBOMWrapperObj);
          system.debug('BOMResponse-->'+response.getBody());
          system.debug('BOMResponseproductHierarchyBOMWrapperObj'+productHierarchyBOMWrapperObj);
          system.debug('BOMResponseproductHierarchyBOMWrapperObj'+productHierarchyBOMWrapperObjMap);

          //log finalize method called (successful case)
          ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), SUCCESS_STRING, response.getBody(), null, response);

        } else {

          //parse the sap response into a wrapper class.
          productHierarchyBOMWrapperObj = new ProductHierarchyBOMWrapper();
          productHierarchyBOMWrapperObj.sfdcToSAPCalloutStatus = FAILURE_STRING;
          productHierarchyBOMWrapperObj.Message = response.getBody();
          productHierarchyBOMWrapperObjMap = returnParentChildResponse(productHierarchyBOMWrapperObj);

          //log finalize method called (failed case)
          ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), FAILURE_STRING, response.getBody(), null, response);

        }


      } else {

        productHierarchyBOMWrapperObj = new ProductHierarchyBOMWrapper();
        productHierarchyBOMWrapperObj.sfdcToSAPCalloutStatus = FAILURE_STRING;
        productHierarchyBOMWrapperObj.Message = authResponse.getBody();
        productHierarchyBOMWrapperObjMap = returnParentChildResponse(productHierarchyBOMWrapperObj);

        //log finalize method called (failed case)
        ilib_LogInterface.finalizeLog(getInterfaceLog(jsonString, INTERFACE_NAME, DIRECTION, PRODUCT_2), FAILURE_STRING, authResponse.getBody(), null, authResponse);



      }

    }
    system.debug('productHierarchyBOMWrapperObjMap == ' + productHierarchyBOMWrapperObjMap);
    return productHierarchyBOMWrapperObjMap;
  }


  /**
   *  @AUTHOR Vaibhav 
   *  @DESCRIPTION - Get the access token from the SAP endpoint first.
   *  @PARAM : 
   *  @RETURN : void
   **/
  private static HttpResponse authenticate(string authenticatingFor) {
    Map < String, String > headerKeyToValue = new Map < String, String > {
      'content-type' => STRING_CONTENT_TYPE,
      STRING_XCRF_TOKEN => 'Fetch',
      'accept' => STRING_CONTENT_TYPE
    };

    HttpRequest request = UtilsRest.createHttpRequest(authenticatingFor == 'bom' ? BOM_EXPLOSION_INTERFACE_NAME_HEAD_AND_POST : WHERE_USED_INTERFACE_NAME_HEAD_AND_POST, HttpMethod.HEAD.name(), headerKeyToValue);
    request.setTimeout(120000);
    return UtilsRest.send(request);

  }

  /**
   *  @AUTHOR Vaibhav 
   *  @DESCRIPTION - Initiate log object record.
   *  @PARAM : string jsonString, string interfaceName, string direction, string objectName
   *  @RETURN : ilib_LogInterface.LogDetails
   **/
  private static ilib_LogInterface.LogDetails getInterfaceLog(string jsonString, string interfaceName, string direction, string objectName) {

    //Interface Log
    ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(interfaceName, direction, objectName);
    ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails, jsonString);
    ilib_LogInterface.addJsonToLog(log, jsonString);
    return log;

  }


  /**
   *  @AUTHOR Vaibhav 
   *  @DESCRIPTION - returns the map key value with the access token.
   *  @PARAM : HttpResponse authResponse
   *  @RETURN : Map < String, String >
   **/
  private static Map < String, String > setHeaderToKeyValue(HttpResponse authResponse) {

    //extract the csrf token from the header.
    String csrfToken = authResponse.getHeader(STRING_XCRF_TOKEN);

    //set cookies.
    String cookie = authResponse.getHeader('set-cookie');
    if (Test.isRunningTest()) {
      cookie = 'SAP_SESSIONID_GPD_100=mO8EaMo-Pau05qhnxumQ1BBwJENk4RHpgOgAUFa3Pfw%3d; path=/;sap-usercontext=sap-client=100; path=/';
    }
    if (cookie.indexOf(';') > -1) cookie = cookie.substring(0, cookie.indexOf(';'));
    Map < String, String > headerKeyToValue = new Map < String, String > {
      STRING_XCRF_TOKEN => csrfToken,
      'content-type' => STRING_CONTENT_TYPE,
      'cookie' => cookie,
      'accept' => STRING_CONTENT_TYPE
    };

    if (Test.isRunningTest()) {
      headerKeyToValue.put(STRING_XCRF_TOKEN, 'XRTSGD');
      headerKeyToValue.put('cookie', 'SAP_SESSIONID_GPD_100=mO8EaMo-Pau05qhnxumQ1BBwJENk4RHpgOgAUFa3Pfw%3d; path=/;sap-usercontext=sap-client=100; path=/');
    }

    return headerKeyToValue;

  }

  /**
   *  @AUTHOR Vaibhav 
   *  @DESCRIPTION - returns the map key value with the access token.
   *  @PARAM : HttpResponse authResponse
   *  @RETURN : Map < String, String >
   **/
  private static HttpResponse executeCallout(String body, String strIntegrationName, String strMethod, Map < String, String > headerKeyToValue) {

    //make final request with token in header.
    HttpRequest request = UtilsRest.createHttpRequest(strIntegrationName, strMethod, headerKeyToValue);

    //set time of the callout to 120000
    request.setTimeout(2 * 60 * 1000);

    //set the body to the json created.
    request.setBody(body);

    //send the request and capture the response.
    response = UtilsRest.send(request);

    system.debug('response body ==== ' + response.getBody());

    return response;

  }

  /**
   *  @AUTHOR Vaibhav 
   *  @DESCRIPTION - returns the map key value with the key as parent_index and value as list child records..
   *  @PARAM : ProductHierarchyBOMWrapper prodHie
   *  @RETURN : Map < String, List < ProductHierarchyBOMWrapper.d.Ex_BOM_Explosion.results >>
   **/
  private static Map < Integer, List < ProductHierarchyBOMWrapper.Results >> returnParentChildResponse(ProductHierarchyBOMWrapper prodHie) {

    Map < Integer, List < ProductHierarchyBOMWrapper.Results >> parentIndexToLstChildIndex = new Map < Integer, List < ProductHierarchyBOMWrapper.Results >> ();
    Map<String,List<ProductHierarchyBOMWrapper.BatchResults>> batchResultWrapperMap = new Map<String,List<ProductHierarchyBOMWrapper.BatchResults>>();

    ProductHierarchyBOMWrapper.Results proExo = new ProductHierarchyBOMWrapper.Results();
    proExo.others = prodHie.others;
    proExo.sfdcToSAPCalloutStatus = prodHie.sfdcToSAPCalloutStatus; //any sfdc to sap callout error.
    proExo.Message = prodHie.Message; //success if no message was received from SAP else the message variable received in response.

    //added a unique key "10101" which will be used exclusively to read the error messages to be displayed on the UI.
    parentIndexToLstChildIndex.put(10101, new List < ProductHierarchyBOMWrapper.Results > ());
    parentIndexToLstChildIndex.get(10101).add(proExo);
    //QACM-78 Starts
    if (string.isNotBlank(prodHie.Message) && prodHie.d != null && !prodHie.Message.toLowerCase().contains('error') && prodHie.d.EX_ProductDelivery != null && prodHie.d.EX_ProductDelivery.results != null && !prodHie.d.EX_ProductDelivery.results.isEmpty()) {
    
      for(ProductHierarchyBOMWrapper.Results exProductDelivery : prodHie.d.EX_ProductDelivery.results) {
        ProductHierarchyBOMWrapper.BatchResults batchResultWrapper = new ProductHierarchyBOMWrapper.BatchResults();
        if(exProductDelivery.Batch != null && exProductDelivery.Batch != '') {
        batchResultWrapper.Batch = exProductDelivery.Batch;
       // batchResultWrapper.BatchExpiry = exProductDelivery.BatchExpiry;
        }
        if(exProductDelivery.BatchExpiry != null) {
          string dstr = exProductDelivery.BatchExpiry;
          string secs = dstr.split('\\(')[1].split('\\)')[0]; 
          system.debug(secs);
          Datetime dt = Datetime.newInstance(Long.valueOf(secs));
          String currentDateFormat = DateTime.newInstance(dt.yearGmt(),dt.monthGmt(),dt.dayGmt()).format('MM-dd-YYYY');
          String[] currentDateArray = currentDateFormat.split('-');
          String currentDate = currentDateArray[0]+'/'+currentDateArray[1].toUpperCase()+'/'+currentDateArray[2];
          batchResultWrapper.BatchExpiry = currentDate;
        }
        if((exProductDelivery.Batch != null && exProductDelivery.Batch != '') || (exProductDelivery.BatchExpiry != null && exProductDelivery.BatchExpiry != '')) {
          if(!batchResultWrapperMap.containsKey(exProductDelivery.Material)) {
            batchResultWrapperMap.put(exProductDelivery.Material, new List<ProductHierarchyBOMWrapper.BatchResults>());
          }
            batchResultWrapperMap.get(exProductDelivery.Material).add(batchResultWrapper);
          }
        }
        
      }
      //QACM-78 END
    if (string.isNotBlank(prodHie.Message) && prodHie.d != null && !prodHie.Message.toLowerCase().contains('error') && prodHie.d.Ex_BOM_Explosion != null && prodHie.d.Ex_BOM_Explosion.results != null && !prodHie.d.Ex_BOM_Explosion.results.isEmpty()) {
    
      for (ProductHierarchyBOMWrapper.Results exBomExplosion: prodHie.d.Ex_BOM_Explosion.results) {
        if(batchResultWrapperMap.containsKey(exBomExplosion.Material)) {
          exBomExplosion.BatchResults = batchResultWrapperMap.get(exBomExplosion.Material);
        }
        if (parentIndexToLstChildIndex.containsKey(exBomExplosion.Parent_Index)) {
          parentIndexToLstChildIndex.get(exBomExplosion.Parent_Index).add(exBomExplosion);
        } else {
          //added a unique key "1001" which will be used exclusively to tag the top most level of the hierarchy.
          parentIndexToLstChildIndex.put((exBomExplosion.Parent_Index == 0 && exBomExplosion.Comp_Index == 0) ? 1001 : exBomExplosion.Parent_Index, new List < ProductHierarchyBOMWrapper.Results > ());
          parentIndexToLstChildIndex.get((exBomExplosion.Parent_Index == 0 && exBomExplosion.Comp_Index == 0) ? 1001 : exBomExplosion.Parent_Index).add(exBomExplosion);
        }

      }

    }

    return parentIndexToLstChildIndex;

  }

}
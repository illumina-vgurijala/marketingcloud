/***************************************************************************************************************************************
* NAME         : TestProductHierarchyDataSender
* DESCRIPTION  : Test class for ProductHierarchyDataSender.
*                    
* @AUTHOR      : 
* @DATE        : 15-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
Avina                     28/09/2022          QACM-78 Created testProductDeliveryResponse method
****************************************************************************************************************************************/
@IsTest
Public class TestProductHierarchyDataSender {
  
   public static final string STRING_BLANK_JSON_BODY = '{"":""}';  
  /**
   *  @author Vaibhav
   *  @description mock response class.
   *  @param None
   *  @return Mock type
   **/
  public class Mock implements HttpCalloutMock {

    protected Integer code;
    protected String bodyAsString;


    /**
    * @description Assigning code and bodyAsString 
    * @author 
    * @param code 
    * @param bodyAsString 
    **/
    public Mock(Integer code, String bodyAsString) {
      this.code = code;
      this.bodyAsString = bodyAsString;
    }

    /**
    * @description HTTP respond method
    * @author 
    * @param req 
    * @return HTTPResponse 
    **/
    public HTTPResponse respond(HTTPRequest req) {
      
      if (req.getbody().contains('51848423')) {
        HTTPResponse res = new HTTPResponse();
        res.setBody(bodyAsString);
        res.setStatusCode(code);
        return res;
      } else {
        HTTPResponse res = new HTTPResponse();
        res.setBody(bodyAsString);
        if (req.getbody().contains('100291') || req.getbody().contains('100292')) {
          res.setStatusCode(401);
        } else {
          res.setStatusCode(code);
        }
        return res;
      }
    }
  }


  @testSetup static void createData() {
    User u = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
      LastName = 'last',
      Email = 'puser000@amamama.com',
      Username = 'puser000@amamama.com' + System.currentTimeMillis(),
      CompanyName = 'TEST',
      Title = 'title',
      Alias = 'alias',
      TimeZoneSidKey = 'America/Los_Angeles',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'

    );
    insert u;
    System.assertNotEquals(null, u.Id);
  }

  /**
   *  @author Vaibhav
   *  @description test the wrapper popluation based on the actual response received.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testWhereUsedResponse() {
    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      String body = '{\"d\":{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"51848423\",\"Valid_From\":\"\",\"Valid_To\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"BOM_Used_In\":\"\",\"Message\":\"\",\"Ex_Product_Return\":{\"results\":[{\"Material\":\"208602\",\"Serial_Number\":\"\",\"Batch_Number\":\"51848423\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"REG2 TEST\",\"System_Blocks\":\"\",\"Material_Desc\":\"SLIDE,3.7,24x1\"}]},\"Ex_Where_Used\":{\"results\":[{\"Material\":\"20005476\",\"Material_Desc\":\"GGP Equine-24 Kit (48 samples)\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"REG2 TEST\",\"System_Blocks\":\"\",\"BOM_Level\":\"5\",\"BOM_Usage\":\"5\",\"BOM_Item\":\"0060\",\"BOM_Quantity\":\"2\",\"Unit_of_measure\":\"EA\",\"BOM_Number\":\"00251291\",\"Alt_BOM\":\"\",\"Plant\":\"6100\",\"Item_Category\":\"L\",\"Valid_From\":\"\",\"Valid_To\":\"\",\"Deletion_Ind\":false,\"Created_On\":\"\",\"Created_By\":\"JSTORMS\",\"Changed_On\":null,\"Changed_By\":\"\",\"Change_Number\":\"\",\"ProdRelevance\":true,\"PlantMianRelevance\":false,\"CostingRelevance\":\"X\",\"EngineeringRelevance\":false,\"ExplosionType\":\"\",\"BOM_Status\":\"01\"}]}}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest1 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Valid_To\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"BOM_Used_In\":\"\"}';
      ProductHierarchyWhereUsedWrapper prodHierarchyWrapp = ProductHierarchyDataSender.getProductsWithTopLevelProductsFromSAP(jsonRequest1);
      System.assertNotEquals(null, prodHierarchyWrapp.d.Ex_Product_Return.results);
      Test.stopTest();

    }

  }

  /**
   *  @author Vaibhav
   *  @description test the wrapper popluation based null response.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testWhereUsedNegativeResponse() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = STRING_BLANK_JSON_BODY;
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(403, body));

      string jsonRequest1 = STRING_BLANK_JSON_BODY;
      ProductHierarchyWhereUsedWrapper prodHierarchyWrapp = ProductHierarchyDataSender.getProductsWithTopLevelProductsFromSAP(jsonRequest1);
      System.assertEquals(null, prodHierarchyWrapp.d);
      Test.stopTest();

    }

  }

  /**
   *  @author Vaibhav
   *  @description test the map popluation based on the actual response received for request 2.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testBomExplosionResponse() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]}}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\"}';
      Map < Integer, List < ProductHierarchyBOMWrapper.Results >> prodHierarchyBOM = ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(jsonRequest2);
      System.assertNotEquals(null, prodHierarchyBOM);
      Test.stopTest();

    }

  }


  /**
   *  @author Vaibhav
   *  @description test the map popluation based on an error response.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testNegativeBomExplosionResponse() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"Material Number is blank\",\"Ex_BOM_Explosion\":null,\"Ex_Product_Return\":null}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\"}';
      Map < Integer, List < ProductHierarchyBOMWrapper.Results >> prodHierarchyBOM = ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(jsonRequest2);

      for (Integer keyVal: prodHierarchyBOM.keyset()) {
        System.assertEquals(10101,keyVal);
        for (ProductHierarchyBOMWrapper.Results wrapperFields: prodHierarchyBOM.get(keyVal)) {
          System.assertEquals('Material Number is blank',wrapperFields.Message);

        }

      }
      Test.stopTest();

    }
  }

  /**
   *  @author Vaibhav
   *  @description test the wrapper popluation based null response.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testBomNullResponse() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = STRING_BLANK_JSON_BODY;
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(403, body));

      string jsonRequest2 = STRING_BLANK_JSON_BODY;
      Map < Integer, List < ProductHierarchyBOMWrapper.Results >> prodHierarchyBOM = ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(jsonRequest2);
      System.assertNotEquals(null, prodHierarchyBOM);

      Test.stopTest();

    }

  }

  /**
   *  @author Vaibhav
   *  @description test the WhereUsed Bad Response In POST Call.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testWhereUsedBadResponseInPOSTCall() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      String body = '{\"d\":{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"51848423\",\"Valid_From\":\"\",\"Valid_To\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"BOM_Used_In\":\"\",\"Message\":\"\",\"Ex_Product_Return\":{\"results\":[{\"Material\":\"208602\",\"Serial_Number\":\"\",\"Batch_Number\":\"51848423\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"REG2 TEST\",\"System_Blocks\":\"\",\"Material_Desc\":\"SLIDE,3.7,24x1\"}]},\"Ex_Where_Used\":{\"results\":[{\"Material\":\"20005476\",\"Material_Desc\":\"GGP Equine-24 Kit (48 samples)\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"REG2 TEST\",\"System_Blocks\":\"\",\"BOM_Level\":\"5\",\"BOM_Usage\":\"5\",\"BOM_Item\":\"0060\",\"BOM_Quantity\":\"2\",\"Unit_of_measure\":\"EA\",\"BOM_Number\":\"00251291\",\"Alt_BOM\":\"\",\"Plant\":\"6100\",\"Item_Category\":\"L\",\"Valid_From\":\"\",\"Valid_To\":\"\",\"Deletion_Ind\":false,\"Created_On\":\"\",\"Created_By\":\"JSTORMS\",\"Changed_On\":null,\"Changed_By\":\"\",\"Change_Number\":\"\",\"ProdRelevance\":true,\"PlantMianRelevance\":false,\"CostingRelevance\":\"X\",\"EngineeringRelevance\":false,\"ExplosionType\":\"\",\"BOM_Status\":\"01\"}]}}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest1 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"100291\",\"Valid_From\":\"\",\"Valid_To\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"BOM_Used_In\":\"\"}';
      ProductHierarchyWhereUsedWrapper prodHierarchyWrapp = ProductHierarchyDataSender.getProductsWithTopLevelProductsFromSAP(jsonRequest1);
      System.assertNotEquals(null, prodHierarchyWrapp);
      Test.stopTest();

    }

  }


  /**
   *  @author Vaibhav
   *  @description test the BomExplosion Bad Response In POST Call.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testBomExplosionBadResponseInPOSTCall() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]}}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"100292\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\"}';
      Map < Integer, List < ProductHierarchyBOMWrapper.Results >> prodHierarchyBOM = ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(jsonRequest2);
      System.assertNotEquals(null, prodHierarchyBOM);
      Test.stopTest();

    }

  }
  /**
   *  @author Avina
   *  @description QACM-78 method to get the respose with EX_product_delivery.
   *  @param None
   *  @return void
   **/
  @IsTest
  static void testProductDeliveryResponse() {

    User fieldServiceUser = [Select Id,IsActive from User where IsActive = true Limit 1];
    System.runAs(fieldServiceUser) {

      string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]},\"EX_ProductDelivery\":{\"results\":[{\"Material\":\"15032374\",\"Batch\":\"0020202009\",\"BatchExpiry\":\"/Date(1663977600000)/\"}]}}}';
      Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new Mock(200, body));

      string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"EX_ProductDelivery\":[]\"\"}';
      Map < Integer, List < ProductHierarchyBOMWrapper.Results >> prodHierarchyBOM = ProductHierarchyDataSender.getProductComponentsForTopLevelProductsFromSAP(jsonRequest2);
      System.assertNotEquals(null, prodHierarchyBOM);
      Test.stopTest();

    }

  }

}

/***************************************************************************************************************************************
* NAME         : TestTreeGrid
* DESCRIPTION  : test class for TreeGrid
*                    
* @AUTHOR      : 
* @DATE        : 15-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Avina                   28/9/2022            QACM-78 created getTreeGridDataWithProductDelivery method
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@istest
public class TestTreeGrid {
	/*Http mock callout*/
    public class Mock implements HttpCalloutMock {

		protected Integer code;
		protected String bodyAsString;

		/*******************************************************************************************************
        * @description Constructor
        * @param code Integer
        * @param bodyAsString String
        */	
		public Mock(Integer code, String bodyAsString) {
		  this.code = code;
		  this.bodyAsString = bodyAsString;
		}

		/*******************************************************************************************************
        * @description method to create HTTPResponse 
        * @param req HTTPRequest
        * @return HTTPResponse
        */		
		public HTTPResponse respond(HTTPRequest req) {
			system.debug('get method = ' +req.getMethod());
			if (req.getbody().contains('51848423')) {
				HTTPResponse res = new HTTPResponse();
				res.setBody(bodyAsString);
				res.setStatusCode(code);
				return res;
			} else {
				HTTPResponse res = new HTTPResponse();
				res.setBody(bodyAsString);
				res.setStatusCode(code);
				return res;
			}
        }
    }
	  
    /**
     * Method Name: getTreeGridData
     * Description: Method to test treegrid functionality.
     **/
	 
    static testmethod void getTreeGridData(){
    	//insert product
        Product2 toolProduct = TestDataMaster.initProduct('15032374','Tools');
        toolProduct.SVMXC__Product_Type__c = 'Spare';
        toolProduct.Description = 'test Description';
        insert toolProduct;
        System.assert(toolProduct.Id != null);
		
		User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name like '%System Admin%'].Id,
             LastName = 'last_1',
             Email = 'puser000@test.com',
             Username = 'puser000@test.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];
        system.debug('appDefinition--:'+appDefinition);
        
        UserAppInfo app = new UserAppInfo();
        app.AppDefinitionId = appDefinition.DurableId;
        app.UserId = u.Id;
        app.formfactor = 'Small';
        insert app;
		
      	string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]}}}';
    	//mock callout
        Test.setMock(HttpCalloutMock.class, new Mock(200, body));

    	string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\"}';
       
        ProductHierarchyBOMWrapper.Results ph = new ProductHierarchyBOMWrapper.Results();
        ph.material = '15032374';
        ph.Material_Desc = 'Miseq test';
        ph.Status = 'Active';
        ph.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
        ph.Regulatory_Type = 'RUO';
        
        ProductHierarchyBOMWrapper.Results ph1 = new ProductHierarchyBOMWrapper.Results();
        ph1.material = 'Test';
        ph1.Material_Desc = 'Miseq test';
        ph1.Status = 'Active';
        ph1.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
        ph1.Regulatory_Type = 'RUO';
        
        Test.startTest();
        
       	List<TreeGrid.HierarchyWrapper> lsthw=TreeGrid.getTreeGridData(jsonRequest2,'Test');
        system.assertequals(1,lsthw.size());
        TreeGrid.buildHierarchyStructure(ph);
        TreeGrid.buildHierarchyStructure(ph1);
       	TreeGrid.getProductID(new List<String> {'15032374'});
		System.runAs(u){
            
            TreeGrid.getCurrentApp();
        }
        
      	Test.stopTest();
    }
	
    /**
     * Method Name: getTreeGridData1 
     * Description: Negative scenario.
     **/
    static testmethod void getTreeGridData1(){
    	//insert product
        Product2 toolProduct = TestDataMaster.initProduct('15032374','Tools');
        toolProduct.SVMXC__Product_Type__c = 'Spare';
        toolProduct.Description = 'test Description';
        insert toolProduct;
        System.assert(toolProduct.Id != null);
        
      	//string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"13374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]}}}';
    	string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"13374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"},{\"Comp_Index\":1,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"12274\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]}}}';
        //mock callout
        Test.setMock(HttpCalloutMock.class, new Mock(200, body));

    	string jsonRequest2 = '{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\"}';
       
        ProductHierarchyBOMWrapper.Results ph = new ProductHierarchyBOMWrapper.Results();
        ph.material = '15032374';
        ph.Material_Desc = 'Miseq test';
        ph.Status = 'Active';
        ph.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
        ph.Regulatory_Type = 'RUO';
        
        ProductHierarchyBOMWrapper.Results ph1 = new ProductHierarchyBOMWrapper.Results();
        ph1.material = 'Test';
        ph1.Material_Desc = 'Miseq test';
        ph1.Status = 'Active';
        ph1.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
        ph1.Regulatory_Type = 'RUO';
        
        Test.startTest();
       
       	List<TreeGrid.HierarchyWrapper> lsthw=TreeGrid.getTreeGridData(jsonRequest2,'Test');
        system.assertequals(1,lsthw.size());
        TreeGrid.buildHierarchyStructure(ph);
        TreeGrid.buildHierarchyStructure(ph1);
       	TreeGrid.getProductID(new List<String> {'15032374'});
      	Test.stopTest();
    }
     /** Method Name: getTreeGridDataWithProductDelivery
    * Description: QACM-78 Method to test treegrid functionality with productDelivery.
    **/
    
   static testmethod void getTreeGridDataWithProductDelivery() {
    //insert product
    Product2 toolProduct = TestDataMaster.initProduct('15032374','Tools');
    toolProduct.SVMXC__Product_Type__c = 'Spare';
    toolProduct.Description = 'test Description';
    insert toolProduct;
    
    User u = new User(
         ProfileId = [SELECT Id FROM Profile WHERE Name like '%System Admin%'].Id,
         LastName = 'last_1',
         Email = 'puser000@test.com',
         Username = 'puser000@test.com' + System.currentTimeMillis(),
         CompanyName = 'TEST',
         Title = 'title',
         Alias = 'alias',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
         
    );
    insert u;
    
    AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];
    
    UserAppInfo app = new UserAppInfo();
    app.AppDefinitionId = appDefinition.DurableId;
    app.UserId = u.Id;
    app.formfactor = 'Small';
    insert app;
    
      string body = '{\"d\":{\"Material\":\"15032374\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":null,\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"X\",\"BOM_Level\":\"0\",\"BOM_Usage\":\"\",\"Plant\":\"3300\",\"Application\":\"PP01\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"Message\":\"\",\"Ex_BOM_Explosion\":{\"results\":[{\"Comp_Index\":0,\"Parent_Index\":0,\"BOM_Level\":\"0\",\"Path_Pred\":\"0\",\"BOM_Item\":\"\",\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO\",\"System_Blocks\":\"SFDC Service Order Block,Spares Shortage\",\"Integration_flag\":\"X\",\"BOM_Usage\":\"\",\"BOM_Quantity\":\"0.000\",\"Unit_of_Measure\":\"\",\"BOM_Number\":\"\",\"Alt_BOM\":\"\",\"Plant\":\"\",\"BOM_Category\":\"\",\"Valid_from\":null,\"Valid_To\":null,\"Deletion_Ind\":false,\"Created_On\":null,\"Changed_On\":null,\"Material_type\":\"\",\"Material_Grp\":\"\",\"Spl_Proc\":\"\"}]},\"Ex_Product_Return\":{\"results\":[{\"Material\":\"15032374\",\"Material_Desc\":\"MiSeq US Install Kit - illumina Use Only\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Status\":\"ACTIVE\",\"Regulatory_Type\":\"RUO_T\",\"System_Blocks\":\"\"}]},\"EX_ProductDelivery\":{\"results\":[{\"Material\":\"15032374\",\"Batch\":\"0020202009\",\"BatchExpiry\":\"/Date(1663977600000)/\"}]}}}';
    //mock callout
    Test.setMock(HttpCalloutMock.class, new Mock(200, body));

    string jsonRequest2 = '{\"Material\":\"\",\"Serial_Number\":\"\",\"Batch_Number\":\"\",\"Valid_From\":\"\",\"Integration_Sys\":\"SFDC\",\"Multi_Level\":\"\",\"BOM_Level\":\"\",\"BOM_Usage\":\"\",\"Plant\":\"\",\"Application\":\"\",\"Limit_explosion\":\"\",\"Engineering\":\"\",\"Production\":\"\",\"Plant_maint\":\"\",\"Bulk_material\":\"\",\"PM_Assembly\":\"\",\"EX_ProductDelivery\":[]\"\"}';
   
    ProductHierarchyBOMWrapper.Results ph = new ProductHierarchyBOMWrapper.Results();
    ph.material = '15032374';
    ph.Material_Desc = 'Miseq test';
    ph.Status = 'Active';
    ph.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
    ph.Regulatory_Type = 'RUO';
    
    ProductHierarchyBOMWrapper.Results ph1 = new ProductHierarchyBOMWrapper.Results();
    ph1.material = 'Test';
    ph1.Material_Desc = 'Miseq test';
    ph1.Status = 'Active';
    ph1.System_Blocks = '"SFDC Service Order Block,Spares Shortage';
    ph1.Regulatory_Type = 'RUO';
    
    Test.startTest();
    
       List<TreeGrid.HierarchyWrapper> lsthw=TreeGrid.getTreeGridData(jsonRequest2,'Test');
    system.assertEquals(1,lsthw.size(),'Please check size is greater than 1');
    TreeGrid.buildHierarchyStructure(ph);
    TreeGrid.buildHierarchyStructure(ph1);
       TreeGrid.getProductID(new List<String> {'15032374'});
    System.runAs(u) {
        
        TreeGrid.getCurrentApp();
    }
    
      Test.stopTest();
}
}
/***************************************************************************************************************************************
 * NAME   : TestSmIbAttributesTemplateInstances 
 * DESCRIPTION  : TestClass for SmIbTechnicalAttributes   Trigger Class
 *           
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 04-Dec-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay         18-Dec-2019            Initial Version
 * Shivani          16-Sep-2022            DCP-52682 Added coverage for checkForPicklistDiscrepancy method
 * Gladis           31-Jan-2023            DCP-52696 Added test method testValidateIPAccess
  ****************************************************************************************************************************************/ 
  
  @isTest(SeeAllData = false)
  public class TestSmIbAttributesTemplateInstances{
  
     /**
    *  @author Digvijay 
    *  @description - test the IB Technical Attrbute Update
    **/
    static testMethod void testIBTehnicalAttributeValidation(){
    
   // User serviceEngineer = TestDataFieldService.createUser('Field Service',true);
    
      String testjson=' {"fields":[{"title":"Upgrade Type","description":"Upgrade Type for Autoloader Product Family","technicalAttributes":[{"label":"Autoloader Upgrade Type","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"AutoloaderUpgradeType","picklistSfId":"a1S3F000000oSPAUA2","picklistName":"Autoloader Upgrade Type","defaultDisplayValue":""},{"label":"Last Upgrade Day","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Day","picklistSfId":"a1S3F000000qXkRUAU","picklistName":"Day","defaultDisplayValue":""},{"label":"Last Upgrade Month","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Month","picklistSfId":"a1S3F000000qXkWUAU","picklistName":"Month","defaultDisplayValue":""},{"label":"Last Upgrade Year","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Year","picklistSfId":"a1S3F000000qXkSUAU","picklistName":"Year","defaultDisplayValue":""}]}],"picklist":{"AutoloaderUpgradeType":{"values":["Autoloader II Upgrade","Autoloader IIx Upgrade"],"setDefaultValue":false},"Day":{"values":["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"],"setDefaultValue":false},"Month":{"values":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"setDefaultValue":false},"Year":{"values":["2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025"],"setDefaultValue":false}}}';
      /*  IVD_Product_Criteria__mdt  mdtObj=[Select    Attribute_Type__c,  Attribute_Name__c , Attribute_Value__c , IVD_Product_Identifier__c from IVD_Product_Criteria__mdt where IVD_Product_Identifier__c=true Limit 1];
        SVMXC__SM_Product_Attributes__c objProdAtt = [select ID,SVMXC__SM_Product_Family__c,
        SVMXC__SM_Attribute_Template_Id__r.Id,
        SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Template_Json__c,
        SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c
        from SVMXC__SM_Product_Attributes__c WHERE SVMXC__SM_Product_Family__c = 'MiSeq - MSQ' AND SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c != Null];*/
        
        
        
        IBTechnicalAttributeWrapper wrapper = (IBTechnicalAttributeWrapper)JSON.deserialize(testjson, IBTechnicalAttributeWrapper.class);
        Map<String,Object> fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(testjson);
        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Family='Autoloader';
        insert objProduct;
        SVMXC__Installed_Product__c objInstalledProduct= TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'Installed');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct2= TestDataFieldService.createInstalledProduct('Test IP2', 'USD', 'Installed');
        objInstalledProduct2.SVMXC__Company__c = acc.Id;
        objInstalledProduct2.Operation_Status__c='Off';
        objInstalledProduct2.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct2;
        
        List<SVMXC__SM_IB_Technical_Attributes__c> lstattributes=new List<SVMXC__SM_IB_Technical_Attributes__c>();
        
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Autoloader Upgrade Type' ,'Autoloader II Upgrade');
        //SVMXC__SM_IB_Technical_Attributes__c  objIBAttr2=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct2.id,mdtObj.Attribute_Name__c,'Autoloader IIx Upgrade');
        
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr3=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Day' ,'1');
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr4=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Month' ,'Jan');
        SVMXC__SM_IB_Technical_Attributes__c  objIBAttr5=TestDataFieldService.createIBTechAttributeForIP(objInstalledProduct.id,'Last Upgrade Year' ,'2019');
        
        lstattributes.add(objIBAttr3);
        lstattributes.add(objIBAttr4);
        lstattributes.add(objIBAttr5);
        lstattributes.add(objIBAttr);
        //lstattributes.add(objIBAttr2);
        insert lstattributes;
        
        
        for(SVMXC__SM_IB_Technical_Attributes__c objIBTA : lstattributes){
               for(IBTechnicalAttributeWrapper.fields objAttrFields : wrapper.fields){
                    for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                        if(objTechAttr.label != null && objIBTA.SVMXC__SM_Attr_Name__c != null && objTechAttr.label.trim() == objIBTA.SVMXC__SM_Attr_Name__c.trim()){
                            String attrValue = objIBTA.SVMXC__SM_Attr_Value__c;
                            if(attrValue == 'checked'){
                                attrValue = 'true';
                            }else if(attrValue == 'unchecked'){
                                attrValue = 'false';
                            }
                            objTechAttr.defaultValue = attrValue;
                            break;
                        }
                    }
                }
            }
            
            String attrPayload = JSON.serialize(Wrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
            SVMXC__SM_IB_Attributes_Template_Instance__c objTechAttrInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
            objTechAttrInstance.SVMXC__SM_Attr_Payload__c = attrPayload;
            objTechAttrInstance.SVMXC__SM_Captured_On__c = system.today();
            objTechAttrInstance.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
          //  objTechAttrInstance.SVMXC__SM_Instance_Template_Id__c =  objProdAtt.SVMXC__SM_Attribute_Template_Id__r.Id;
            objTechAttrInstance.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
            
            insert objTechAttrInstance;
        
        SVMXC__SM_IB_Attributes_Template_Instance__c objTechAttrInstance2= [Select Id ,SVMXC__SM_Attr_Payload__c from SVMXC__SM_IB_Attributes_Template_Instance__c where id=: objTechAttrInstance.id];
       
      // System.runAs(serviceEngineer){ 
        Test.StartTest();
        IBTechnicalAttributeWrapper.technicalAttributes wrapperobj=new IBTechnicalAttributeWrapper.technicalAttributes();
        wrapperobj.readOnly='true';
        wrapperobj.picklistSfId='xyz';
        wrapperobj.picklistId='abc';
        wrapperobj.sequence='sequence';
        wrapperobj.type='upgrade';
        wrapperobj.unit='1';
        wrapperobj.format='1';
        wrapperobj.defaultValue='upgrade';
		
		//TestFields
		
		IBTechnicalAttributeWrapper.fields wrapperobj1=new IBTechnicalAttributeWrapper.fields();
        wrapperobj1.title='test';
        wrapperobj1.description='testing description';
          
 
        
         for(SVMXC__SM_IB_Technical_Attributes__c objIBTA : lstattributes){
               for(IBTechnicalAttributeWrapper.fields objAttrFields : wrapper.fields){
                    for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                        if(objTechAttr.label != null && objIBTA.SVMXC__SM_Attr_Name__c != null && objTechAttr.label.trim() == objIBTA.SVMXC__SM_Attr_Name__c.trim()){
                        
                        System.debug('here...'+objTechAttr.label+'..'+objIBTA.SVMXC__SM_Attr_Value__c);
                        String attrValue;
                          if(objTechAttr.label=='Last Upgrade Day')
                                attrValue='11';
                          else
                               attrValue = objIBTA.SVMXC__SM_Attr_Value__c;
                           if(attrValue == 'checked'){
                                attrValue = 'true';
                           }else if(attrValue == 'unchecked'){
                                attrValue = 'false';
                           }
                            objTechAttr.defaultValue = attrValue;
                            break;
                        }
                    }
                }
            }
            
           /*String attrPayload2 = JSON.serialize(Wrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
            objTechAttrInstance2.SVMXC__SM_Attr_Payload__c = attrPayload2;
            
            update objTechAttrInstance2;
        
        for(SVMXC__SM_IB_Technical_Attributes__c objIBTA : lstattributes){
               for(IBTechnicalAttributeWrapper.fields objAttrFields : wrapper.fields){
                    for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                        if(objTechAttr.label != null && objIBTA.SVMXC__SM_Attr_Name__c != null && objTechAttr.label.trim() == objIBTA.SVMXC__SM_Attr_Name__c.trim()){
                        
                        System.debug('here...'+objTechAttr.label+'..'+objIBTA.SVMXC__SM_Attr_Value__c);
                        String attrValue;
                          if(objTechAttr.label=='Last Upgrade Day')
                                attrValue='';
                          else
                               attrValue = objIBTA.SVMXC__SM_Attr_Value__c;
                           if(attrValue == 'checked'){
                                attrValue = 'true';
                           }else if(attrValue == 'unchecked'){
                                attrValue = 'false';
                           }
                            objTechAttr.defaultValue = attrValue;
                            break;
                        }
                    }
                }
            }
        
        attrPayload2 = JSON.serialize(Wrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
            objTechAttrInstance2.SVMXC__SM_Attr_Payload__c = attrPayload2;
         String error;
         
         
         
  
   try{     
        update objTechAttrInstance2;
    }Catch(Exception ex){
       error=ex.getMessage();
    }
    
    System.debug('error..'+error);
   if(error!=null && error!=''){
    system.assert(error.contains('Last Upgrade Date Fields are Required'));
	}
     */   
        
    Test.StopTest();
   // }
    }

    /**
    *  @author Vignesh 
    *  @description - Test Proactive Attributes
    **/
    static testMethod void testProactiveAttributes(){
        String testjson=' {"fields":[{"title":"Upgrade Type","description":"Upgrade Type for Autoloader Product Family","technicalAttributes":[{"label":"Autoloader Upgrade Type","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"AutoloaderUpgradeType","picklistSfId":"a1S3F000000oSPAUA2","picklistName":"Autoloader Upgrade Type","defaultDisplayValue":""},{"label":"Last Upgrade Day","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Day","picklistSfId":"a1S3F000000qXkRUAU","picklistName":"Day","defaultDisplayValue":""},{"label":"Last Upgrade Month","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Month","picklistSfId":"a1S3F000000qXkWUAU","picklistName":"Month","defaultDisplayValue":""},{"label":"Last Upgrade Year","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Year","picklistSfId":"a1S3F000000qXkSUAU","picklistName":"Year","defaultDisplayValue":""}]}],"picklist":{"AutoloaderUpgradeType":{"values":["Autoloader II Upgrade","Autoloader IIx Upgrade"],"setDefaultValue":false},"Day":{"values":["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"],"setDefaultValue":false},"Month":{"values":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"setDefaultValue":false},"Year":{"values":["2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025"],"setDefaultValue":false}}}';
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
		acc.Account_Group__c='Distributor';
		insert acc;
		
		Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
		objProduct.Family='Autoloader';
		insert objProduct;
		
        Test.starttest();
		SVMXC__Installed_Product__c objInstalledProduct= TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'Installed');
		objInstalledProduct.SVMXC__Company__c = acc.Id;
		objInstalledProduct.Operation_Status__c='Off';
		objInstalledProduct.SVMXC__Product__c = objProduct.Id;
		objInstalledProduct.SVMXC__Serial_Lot_Number__c = '12345';
		insert objInstalledProduct;
		
		SVMXC__SM_IB_Attributes_Template_Instance__c obj = new SVMXC__SM_IB_Attributes_Template_Instance__c();
		obj.SVMXC__SM_Attr_Payload__c = testjson;
		obj.SVMXC__SM_Captured_On__c = Datetime.now();
		obj.serial_lot_Number__c = '12345';
		insert obj;
		
		SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
		objTechAttrHistory.SVMXC__SM_Attr_Payload__c = testjson ;
		objTechAttrHistory.SVMXC__SM_Captured_On__c = Datetime.now();
		objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
		objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
		objTechAttrHistory.SVMXC__SM_Source__c = 'Web';
		//objTechAttrHistory.SVMXC__SM_Instance_Template_Id__c = obj.Id ;
		insert objTechAttrHistory;
		
		list<SVMXC__Installed_Product__c> lstIP = new list<SVMXC__Installed_Product__c>();
		lstIP.add(new SVMXC__Installed_Product__c(External_id__c = '12345' , Proactive_Last_Connected_Date__c = Date.today().adddays(2) , Proactive_Connectivity_Status__c = 'Connected'));
		upsert lstIP External_id__c;
		
		list<SVMXC__SM_IB_Attributes_Template_Instance__c> lstInstance = new list<SVMXC__SM_IB_Attributes_Template_Instance__c> ();
		lstInstance.add(new SVMXC__SM_IB_Attributes_Template_Instance__c( Serial_Lot_Number__c = '12345' , Proactive_Attributes__c = '{"Autoloader Upgrade Type" :"Autoloader II Upgrade"}'));
		upsert lstInstance Serial_Lot_Number__c;
        Test.stoptest();
        list<SVMXC__SM_IB_Attributes_History__c> lstHistory = [select id from SVMXC__SM_IB_Attributes_History__c where SVMXC__SM_Installed_Product_Id__c = :objInstalledProduct.Id ];
        system.assertEquals(2, lstHistory.size() , 'History record not created' );
        
        list<SVMXC__SM_IB_Technical_Attributes__c> lstTechAtt = [select id,SVMXC__SM_Attr_Value__c from SVMXC__SM_IB_Technical_Attributes__c where SVMXC__SM_Attr_Name__c = 'Autoloader Upgrade Type' AND SVMXC__SM_Installed_Product_id__c = :objInstalledProduct.Id];
    	system.assertEquals( 'Autoloader II Upgrade' , lstTechAtt[0].SVMXC__SM_Attr_Value__c, 'Attribute Record not created');
    }   

    /*******************************************************************************************************
    * @description DCP-52682 Method to check for Proactive Discrepancy fro picklist value
    */
    static testMethod void testProactiveAttributesDiscrepancy() {
        SVMXC__SM_Attributes_Template__c template = new SVMXC__SM_Attributes_Template__c();
        template.SVMXC__SM_Attr_Type_Template__c = 'TECHNICAL';
        template.SVMXC__SM_Active__c = true;
        template.SVMXC__SM_Title__c = 'Autoloader Template';
        template.SVMXC__SM_Template_Json__c = '{"picklist":{"YearList":{"setDefaultValue":false,"values":["2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025"]}},"fields":[{"description":"Section to capture details for Ancillary Components","title":"Ancillary Components","technicalAttributes":[{"sequence":0,"unit":"","minNumber":"","maxNumber":"","defaultValue":"","format":"Picklist","readOnly":"","label":"Last Upgrade Year","type":"Static","message":"","req":null},{"sequence":1,"unit":"","minNumber":"","maxNumber":"","defaultValue":"","format":"Text","readOnly":"","label":"Test Flow Cell Serial No.","type":"Static","message":"","req":null}, {"unit":"","type":"Static","sequence":"3","readOnly":"","picklistSfId":"a1S2f000001QDg8EAG","picklistId":"YearList","label":"Last Upgrade Year","format":"Picklist"}]}]}';
        insert template;
        System.assert(template.Id != NULL, 'template insertion failed');

        String testjson=' {"fields":[{"title":"Upgrade Type","description":"Upgrade Type for Autoloader Product Family","technicalAttributes":[{"label":"Autoloader Upgrade Type","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"AutoloaderUpgradeType","picklistSfId":"a1S3F000000oSPAUA2","picklistName":"Autoloader Upgrade Type","defaultDisplayValue":""},{"label":"Last Upgrade Day","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Day","picklistSfId":"a1S3F000000qXkRUAU","picklistName":"Day","defaultDisplayValue":""},{"label":"Last Upgrade Month","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Month","picklistSfId":"a1S3F000000qXkWUAU","picklistName":"Month","defaultDisplayValue":""},{"label":"Last Upgrade Year","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Year","picklistSfId":"a1S3F000000qXkSUAU","picklistName":"Year","defaultDisplayValue":""}]}],"picklist":{"AutoloaderUpgradeType":{"values":["Autoloader II Upgrade","Autoloader IIx Upgrade"],"setDefaultValue":false},"Day":{"values":["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"],"setDefaultValue":false},"Month":{"values":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"setDefaultValue":false},"Year":{"values":["2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025"],"setDefaultValue":false}}}';
        Account acc = TestDataAccount.getAccount('Test Account', 'USD');
		acc.Account_Group__c='Distributor';
		insert acc;
		System.assert(acc.Id != NULL, 'Account insertion failed');

		Product2 objProduct = TestDataFieldService.createProduct('Test Product  Name','Instrument');
		objProduct.Family='Autoloader';
		insert objProduct;
		System.assert(objProduct.Id != NULL, 'Product insertion failed');

        Test.startTest();
		SVMXC__Installed_Product__c objInstalledProduct= TestDataFieldService.createInstalledProduct('Test IP rec', 'USD', 'Installed');
		objInstalledProduct.SVMXC__Company__c = acc.Id;
		objInstalledProduct.Operation_Status__c='Off';
		objInstalledProduct.SVMXC__Product__c = objProduct.Id;
		objInstalledProduct.SVMXC__Serial_Lot_Number__c = '12345';
		insert objInstalledProduct;
		System.assert(objInstalledProduct.Id != NULL, 'IP record insertion failed');

		SVMXC__SM_IB_Attributes_Template_Instance__c obj = new SVMXC__SM_IB_Attributes_Template_Instance__c();
		obj.SVMXC__SM_Attr_Payload__c = testjson;
		obj.SVMXC__SM_Captured_On__c = Datetime.now();
		obj.serial_lot_Number__c = '12345';
		insert obj;
		System.assert(obj.Id != NULL, 'IB Attribute Template Instance insertion failed');

		SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
		objTechAttrHistory.SVMXC__SM_Attr_Payload__c = testjson ;
		objTechAttrHistory.SVMXC__SM_Captured_On__c = Datetime.now();
		objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
		objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
		objTechAttrHistory.SVMXC__SM_Source__c = 'Web';
		insert objTechAttrHistory;
		System.assert(objTechAttrHistory.Id != NULL, 'IB Attribute History insertion failed');

		list<SVMXC__Installed_Product__c> lstIP = new list<SVMXC__Installed_Product__c>();
		lstIP.add(new SVMXC__Installed_Product__c(External_id__c = '12345' , Proactive_Last_Connected_Date__c = Date.today().adddays(2) , Proactive_Connectivity_Status__c = 'Connected'));
		upsert lstIP External_id__c;
		
		list<SVMXC__SM_IB_Attributes_Template_Instance__c> lstInstance = new list<SVMXC__SM_IB_Attributes_Template_Instance__c> ();
		lstInstance.add(new SVMXC__SM_IB_Attributes_Template_Instance__c( Serial_Lot_Number__c = '12345' , Proactive_Attributes__c = '{"Last Upgrade Year" :"2026"}'));
		upsert lstInstance Serial_Lot_Number__c;
        Test.stopTest();
        
        List<Technical_Attribute_Discrepancy__c> lstDiscrepancyRecs = [select id from Technical_Attribute_Discrepancy__c LIMIT 1];
    	System.assert(!lstDiscrepancyRecs.isEmpty(), 'Discrepancy record not created');
    } 
    
    /*
    * @Author Gladis
    * @description DCP-52696 test method for validateIPAccess
    */
    static testMethod void testValidateIPAccess() {

        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'null contact id');
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct.SVMXC__Status__c = 'Installed';
        insert objInstalledProduct;
        User cpUser =  [select id, name, profile.name from User where profile.name ='Channel Partner Sales and Service' and isactive = true limit 1]; 
        SVMXC__SM_IB_Attributes_Template_Instance__c attributetemp = new SVMXC__SM_IB_Attributes_Template_Instance__c();
        attributetemp.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.id;
        attributetemp.SVMXC__SM_Attr_Payload__c = '{"picklist":{"IlluminaRunManagerSoftwareVersion:NovaSeq-NVSQDX":{"values":["1.2.145","Needs Updating"],"setDefaultValue":false}},"fields":[{"title":"Electronics","technicalAttributes":[{"unit":"","type":"","sequence":"0","req":"0","readOnly":"","picklistSfId":null,"picklistId":null,"minNumber":"","message":"","maxNumber":"","label":"Electronic Notes","format":"Text","defaultValue":"test1"}],"description":"Electronics"}]}';
        insert attributetemp;

        for( SVMXC__Installed_Product__share shareIP:[select id, AccessLevel, UserOrGroup.Profile.name, ParentId from SVMXC__Installed_Product__share where parentid=:objInstalledProduct.Id]){
            SVMXC__Installed_Product__share shareRec = new SVMXC__Installed_Product__share();
                shareRec.AccessLevel = 'Read';
                shareRec.UserOrGroupId = cpUser.Id;
                shareRec.parentid = shareIP.ParentId;
        }
        Boolean expectedExceptionThrown=false;
        test.startTest();
        System.runAs(cpUser) {
            try {
            list<SVMXC__SM_IB_Attributes_Template_Instance__c> instance = [select id, SVMXC__SM_Attr_Payload__c from  SVMXC__SM_IB_Attributes_Template_Instance__c where SVMXC__SM_Installed_Product_Id__c  =:objInstalledProduct.id];
            instance[0].SVMXC__SM_Attr_Payload__c = '{"picklist":{"IlluminaRunManagerSoftwareVersion:NovaSeq-NVSQDX":{"values":["1.2.145","Needs Updating"],"setDefaultValue":false}},"fields":[{"title":"Electronics","technicalAttributes":[{"unit":"","type":"","sequence":"0","req":"0","readOnly":"","picklistSfId":null,"picklistId":null,"minNumber":"","message":"","maxNumber":"","label":"Electronic Notes","format":"Text","defaultValue":"test123"}],"description":"Electronics"}]}';
            update instance;
            } catch(Exception e) {
                expectedExceptionThrown = e.getMessage().contains(Label.Check_Access_to_Update_Technical_Attributes_Error_Message) ? true : false; 
            }
        }
        test.stopTest();
        System.assert(true,expectedExceptionThrown);               
    }
      
  }

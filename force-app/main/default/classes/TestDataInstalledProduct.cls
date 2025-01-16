/**
* Installed Products and associated records
**/
@isTest

public with sharing class TestDataInstalledProduct {

/*
*  @AUTHOR:  Mandeep Singh
*  @DESCRIPTION:This method creates Installed Product
*  @PARAM :  String strRecordTypeName, String strStatus
*  @RETURN:  Installed Product type object
*/
    public static SVMXC__Installed_Product__c createInstalledProduct(Date acceptanceDate, Date installedDate)
    {       
        Account  testAccount = TestDataAccount.getAccount('Test Account1');
        testAccount.ERP_Customer_Id__c='897';
        insert testAccount;
         
       
        SVMXC__Installed_Product__c instProd= new SVMXC__Installed_Product__c(
        ERP_Equipment_Id__c = '1234',
        SVMXC__Company__c = testAccount.Id,
        Acceptance_Date__c = acceptanceDate,
        SVMXC__Date_Installed__c = installedDate
        
        );
        insert instProd;
        return instProd;
    }
    
    	/*
         * description - getNewInstalledProduct method
		 * return - SVMXC__Installed_Product__c
         */ 
    public static SVMXC__Installed_Product__c getNewInstalledProduct(Id accountId)
    {
        SVMXC__Installed_Product__c rec = initInstalledProduct(accountId);
        insert rec;
        return rec;
    }
	
		/*
         * description - initInstalledProduct method
		 * return - SVMXC__Installed_Product__c
         */ 	
    public static SVMXC__Installed_Product__c initInstalledProduct(Id accountId)
    {
        SVMXC__Installed_Product__c rec = new SVMXC__Installed_Product__c(
                SVMXC__Company__c = accountId,
                ERP_Equipment_Id__c = TestData.getRandomNumeric(4),
                Acceptance_Date__c = Date.today(),
                SVMXC__Date_Installed__c = Date.today()
        );
        return rec;
    }

		/*
         * description - getNewAttributesHistory method
		 * return - SVMXC__SM_IB_Attributes_History__c
         */ 
    public static SVMXC__SM_IB_Attributes_History__c getNewAttributesHistory(Id ipId)
    {
        SVMXC__SM_IB_Attributes_History__c rec = initAttributesHistory(ipId);
        insert rec;
        return rec;
    }

		/*
         * description - initAttributesHistory method
		 * return - SVMXC__SM_IB_Attributes_History__c
         */ 	
    public static SVMXC__SM_IB_Attributes_History__c initAttributesHistory(Id ipId)
    {
        SVMXC__SM_IB_Attributes_History__c rec = new SVMXC__SM_IB_Attributes_History__c(
            SVMXC__SM_Installed_Product_Id__c = ipId
        );
        return rec;
    }

		/*
         * description - getNewTechnicalAttributes method
		 * return - SVMXC__SM_IB_Technical_Attributes__c
         */ 
    public static SVMXC__SM_IB_Technical_Attributes__c getNewTechnicalAttributes(Id ipId)
    {
        SVMXC__SM_IB_Technical_Attributes__c rec = initTechnicalAttributes(ipId);
        insert rec;
        return rec;
    }
	
		/*
         * description - initTechnicalAttributes method
		 * return - SVMXC__SM_IB_Technical_Attributes__c
         */ 	
    public static SVMXC__SM_IB_Technical_Attributes__c initTechnicalAttributes(Id ipId)
    {
        SVMXC__SM_IB_Technical_Attributes__c rec = new SVMXC__SM_IB_Technical_Attributes__c(
            SVMXC__SM_Installed_Product_Id__c = ipId,
            SVMXC__SM_Attr_Name__c = 'FPGA Version',
            SVMXC__SM_Attr_Value__c = '9.5.12',
            SVMXC__SM_Created_Date__c = System.now()
        );
        return rec;
    }

		/*
         * description - getNewAttributesTemplateInstance method
		 * return - SVMXC__SM_IB_Attributes_Template_Instance__c
         */ 
    public static SVMXC__SM_IB_Attributes_Template_Instance__c getNewAttributesTemplateInstance(Id ipId)
    {
        SVMXC__SM_IB_Attributes_Template_Instance__c rec = initAttributesTemplateInstance(ipId);
        insert rec;
        return rec;
    }
	
		/*
         * description - initAttributesTemplateInstance method
		 * return - SVMXC__SM_IB_Attributes_Template_Instance__c
         */ 	
    public static SVMXC__SM_IB_Attributes_Template_Instance__c initAttributesTemplateInstance(Id ipId)
    {
        SVMXC__SM_Attributes_Template__c attributeTemplate = getNewAttributesTemplate();

        TechnicalAttributeTemplateWrapper wrapper = (TechnicalAttributeTemplateWrapper)JSON.deserialize(attributeTemplate.SVMXC__SM_Template_Json__c, TechnicalAttributeTemplateWrapper.class);
        Map<String,Object> fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(attributeTemplate.SVMXC__SM_Template_Json__c);
        String attrPayload = JSON.serialize(wrapper).substringBeforeLast('}') + ',"piklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';

        SVMXC__SM_IB_Attributes_Template_Instance__c rec = new SVMXC__SM_IB_Attributes_Template_Instance__c(
            SVMXC__SM_Installed_Product_Id__c = ipId,
            SVMXC__SM_Attr_Payload__c = attrPayload,
            SVMXC__SM_Captured_On__c = System.today(),
            SVMXC__SM_Instance_Template_Id__c = attributeTemplate.Id,
            SVMXC__SM_Attr_Type__c = 'TECHNICAL'
        );
        return rec;
    }


		/*
         * description - getNewAttributesTemplate method
		 * return - SVMXC__SM_Attributes_Template__c
         */ 
    public static SVMXC__SM_Attributes_Template__c getNewAttributesTemplate()
    {
        String template = '{' +
            '"fields": [{' +
            '"title": "Fluidics",' +
            '"description": "to capture the details of Software - Local Run Manager Installations (Dx drive only)",' +
            '"technicalAttributes": [{' +
            '"label": "Chemistry valve type ",' +
            '"type": "Static",' +
            '"sequence": 0,' +
            '"defaultValue": "",' +
            '"unit": "",' +
            '"readOnly": "",' +
            '"format": "Picklist",' +
            '"picklistId": "Chemistryvalvetype:MiSeq-MSQ",' +
            '"picklistSfId": "a1S1D0000005EX6UAM",' +
            '"picklistName": "Chemistry valve type : MiSeq - MSQ",' +
            '"defaultDisplayValue": ""' +
            '}]' +
            '}' +
            '],' +
            '"picklist": {' +
            '"Chemistryvalvetype:MiSeq-MSQ": {' +
            '"values": ["24-Port Valve v1", "25-Port Valve v2", "25-Port Valve v3"],' +
            '"setDefaultValue": false' +
            '}' +
            '}' +
            '}';
        SVMXC__SM_Attributes_Template__c rec = new SVMXC__SM_Attributes_Template__c(
            SVMXC__SM_Title__c = 'MiSeq - MSQ - Dx Template',
            SVMXC__SM_Template_Json__c = template
        );
        insert rec;
        return rec;
    }

   /*
    * @Description- Wrapper Object
    */ 
    public class TechnicalAttributeTemplateWrapper
    {
        List<TechnicalAttributeFields> fields { get; set; }
    }

   /*
    * @Description- Wrapper Object
    */ 
    private class TechnicalAttributeFields
    {
        String title { get; set; }
        String description { get; set; }
        List<TechnicalAttributes> technicalAttributes { get; set; }
    }

		/*
         * description - TechnicalAttributes class
         */ 
    private class TechnicalAttributes
    {
        String label { get; set; }
        String type { get; set; }
        String sequence { get; set; }
        String defaultValue { get; set; }
        String unit { get; set; }
        String readOnly { get; set; }
        String format { get; set; }
    }

}
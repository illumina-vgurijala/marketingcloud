/*
 *    @author : Romi Taskar
 *    @date   : 28-May-2021
 *    @description : Test Class for BatchUpdateNovaSeqAttribute.
 */
@isTest
public class TestBatchUpdateNovaSeqAttribute {
    
    public static final string PRODUCT_FAMILY  = 'NovaSeq-NVSQ';
    
    /* 
     * @description : test method for BatchUpdateNovaSeqAttribute
     */
    static testmethod void batchdataremediation()
    {

        Account testAccount = TestDataAccount.initAccount();
        Account testAccount2 = TestDataAccount.initAccount();
        insert new List<Account> { testAccount, testAccount2 };

        SVMXC__Installed_Product__c instProd = TestDataInstalledProduct.getNewInstalledProduct(testAccount.Id);
        
        SVMXC__SM_IB_Attributes_Template_Instance__c attributetemp = new SVMXC__SM_IB_Attributes_Template_Instance__c();
        attributetemp.SVMXC__SM_Installed_Product_Id__c = instProd.id;
        attributetemp.SVMXC__SM_Attr_Payload__c = '{"fields":[{"title":"testField","technicalAttributes":[{"unit":"","type":"Static","sequence":"1","readOnly":"","label":"testLabel","format":"Text","defaultValue":""}],"description":"testDescription"},{"title":"testField","technicalAttributes":[{"unit":"","type":"Static","sequence":"1","readOnly":"","label":"PC Image version","format":"Text","defaultValue":""}],"description":"testDescription"}]}';
        insert attributetemp;
        
        SVMXC__SM_Attributes_Template__c attrTemplate = new SVMXC__SM_Attributes_Template__c();
        attrTemplate.SVMXC__SM_Template_Json__c = '{"fields":[{"title":"Electronics","description":"to capture the details of Software - Local Run Manager Installations (Dx drive only)\\n","technicalAttributes":[{"label":"Electronic Notes","type":"Static","sequence":0,"defaultValue":"test","unit":"test","readOnly":"true","format":"Text"}]},{"title":"Mechanical","description":"to capture the details of Mechanical\\n","technicalAttributes":[{"label":"Mechanical Systems Notes","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Text"}]},{"title":"Optical Systems","description":"to capture the details of Optical Systems\\n","technicalAttributes":[{"label":"Optical Systems Notes","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Text"}]},{"title":"Fluidics","description":"to capture the details of Fluidics\\n","technicalAttributes":[{"label":"Fluidics Notes","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Text"},{"label":"Chemistry valve type ","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Chemistryvalvetype","picklistSfId":"a1S1D0000005AxkUAE","picklistName":"Chemistry valve type","defaultDisplayValue":""}]},{"title":"PC","description":"to capture the details of PC\\n","technicalAttributes":[{"label":"Hard Drive Type","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"HardDriveType","picklistSfId":"a1S1D0000005AxoUAE","picklistName":"Hard Drive Type","defaultDisplayValue":""},{"label":"SBC Image Version","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"SBCImageVersion","picklistSfId":"a1S1D0000005AxfUAE","picklistName":"SBC Image Version","defaultDisplayValue":""},{"label":"SBC Notes","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Text"}]},{"title":"Firmware","description":"to capture the details of Firmware\\n","technicalAttributes":[{"label":"FPGA Version","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"FPGAVersion","picklistSfId":"a1S1D0000005AxeUAE","picklistName":"FPGA Version","defaultDisplayValue":""}]},{"title":"Software - MiSeq Reporter Installations (RUO drive only)","description":"to capture the details of Software - MiSeq Reporter Installations (RUO drive only)\\n","technicalAttributes":[{"label":"MFCS (RUO)","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MFCS(RUO)","picklistSfId":"a1S1D0000005AxlUAE","picklistName":"MFCS (RUO)","defaultDisplayValue":""},{"label":"MCS (RUO)","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MCS(RUO)","picklistSfId":"a1S1D0000005AxaUAE","picklistName":"MCS (RUO)","defaultDisplayValue":""},{"label":"MTS (RUO)","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MTS(RUO-MSR)","picklistSfId":"a1S1D0000005AxWUAU","picklistName":"MTS (RUO-MSR)","defaultDisplayValue":""},{"label":"MSR (RUO)","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MSR(RUO)","picklistSfId":"a1S1D0000005AxZUAU","picklistName":"MSR (RUO)","defaultDisplayValue":""},{"label":"RTA version (RUO) ","type":"Static","sequence":4,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"RTAversion(RUO)","picklistSfId":"a1S1D0000005AxhUAE","picklistName":"RTA version (RUO)","defaultDisplayValue":""},{"label":"Recipe Fragment Version (RUO)","type":"Static","sequence":5,"defaultValue":"","unit":"","readOnly":"","format":"Text"},{"label":"MSR Genomes (RUO)","type":"Static","sequence":6,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MSRGenomes(RUO)","picklistSfId":"a1S1D0000005AxnUAE","picklistName":"MSR Genomes (RUO)","defaultDisplayValue":""},{"label":"BaseSpace Broker (RUO)","type":"Static","sequence":7,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"BaseSpaceBroker(RUO)","picklistSfId":"a1S1D0000005AxgUAE","picklistName":"BaseSpace Broker (RUO)","defaultDisplayValue":""},{"label":"MTS (RUO-LRM)","type":"Static","sequence":8,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MTS(RUO-LRM)","picklistSfId":"a1S1D0000005AxiUAE","picklistName":"MTS (RUO-LRM)","defaultDisplayValue":""}]},{"title":"Software - MiSeq Reporter Installations (Dx drive only)","description":"to capture the details of Software - MiSeq Reporter Installations (Dx drive only)\\n","technicalAttributes":[{"label":"MSR Not Applicable (Dx)","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Boolean"},{"label":"MOS (Dx) ","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MOS(Dx)","picklistSfId":"a1S1D0000005AxXUAU","picklistName":"MOS (Dx)","defaultDisplayValue":""},{"label":"MTS (Dx-MSR)","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MTS(Dx-MSR)","picklistSfId":"a1S1D0000005AxbUAE","picklistName":"MTS (Dx-MSR)","defaultDisplayValue":""},{"label":"MSR (Dx) ","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MSR(Dx)","picklistSfId":"a1S1D0000005AxVUAU","picklistName":"MSR (Dx)","defaultDisplayValue":""},{"label":"RTA Version (Dx)","type":"Static","sequence":4,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"RTAVersion(Dx)","picklistSfId":"a1S1D0000005AxjUAE","picklistName":"RTA Version (Dx)","defaultDisplayValue":""},{"label":"Recipe Fragment Version (Dx) ","type":"Static","sequence":5,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"RecipeFragmentVersion(Dx)","picklistSfId":"a1S1D0000005AxYUAU","picklistName":"Recipe Fragment Version (Dx)","defaultDisplayValue":""},{"label":"MSR Genomes (Dx)","type":"Static","sequence":6,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"MSRGenomes(Dx)","picklistSfId":"a1S1D0000005AxcUAE","picklistName":"MSR Genomes (Dx)","defaultDisplayValue":""},{"label":"BaseSpace Broker (Dx)","type":"Static","sequence":7,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"BaseSpaceBroker(Dx)","picklistSfId":"a1S1D0000005AxmUAE","picklistName":"BaseSpace Broker (Dx)","defaultDisplayValue":""},{"label":"MSR Not Applicable (RUO)","type":"Static","sequence":8,"defaultValue":"","unit":"","readOnly":"","format":"Boolean"}]},{"title":"Software - Local Run Manager Installations (Dx drive only)","description":"to capture the details of Software - Local Run Manager Installations (Dx drive only)\\n","technicalAttributes":[{"label":"LRM Not Applicable","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Boolean"},{"label":"LRM Not Applicable (RUO)","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Boolean"},{"label":"Image Version (Dx) ","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"ImageVersion(Dx)","picklistSfId":"a1S1D0000005AxdUAE","picklistName":"Image Version (Dx)","defaultDisplayValue":""}]},{"title":"Software/Firmware Verification Date","description":"to capture the details of Software/Firmware Verification Date\\n","technicalAttributes":[{"label":"Last SW Config Date","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Text"}]}],"picklist":{"Chemistryvalvetype":{"values":["24-Port Valve v1","25-Port Valve v2","25-Port Valve v3"],"setDefaultValue":false},"HardDriveType":{"values":["Dual Boot","Enterprise","Standard"],"setDefaultValue":false},"SBCBiosVersion":{"values":["R1.00.W6a","R1.00.W1","E2.01"],"setDefaultValue":false},"FPGAVersion":{"values":["9.5.12"],"setDefaultValue":false},"MFCS(RUO)":{"values":["0.9","1.0.5","1.0.15","N/A"],"setDefaultValue":false},"MTS(RUO-MSR)":{"values":["0.0.10","0.0.17","0.0.18","0.0.19","0.0.37","1.0.4","1.0.7.0","1.0.4.0","N/A"],"setDefaultValue":false},"MSR(RUO)":{"values":["1.0.25","1.0.27","1.1","1.1.1","1.1.6","1.3.17","2.0.0","2.1","2.0.26","2.2","2.3","2.4","2.2.30.2","2.2.30.8","2.2.31.1","2.5","2.6","2.6.3","2.6.2.3","2.6.3.2","2.5.1.3","2.3.32","2.4.60.8","N/A"],"setDefaultValue":false},"RTAversion(RUO)":{"values":["1.10.36","1.10.36.0","1.11.24","1.12","1.13.46","1.13.5","1.13.56","1.14.23","1.16","1.16.18","1.17","1.17.28","1.18.42","1.18.52","1.18.54","1.6.96.22","1.7","1.7.","1.7.45","1.7.45.0","1.7.47","1.7.48","1.7.48.1","3.0.32","3.6.31.2","3.36.33.2","3.6.96.10","3.6.96.22","1.18.54.0","N/A"],"setDefaultValue":false},"MSRGenomes(RUO)":{"values":["1.0.0","1.1.0.0","N/A"],"setDefaultValue":false},"BaseSpaceBroker(RUO)":{"values":["1.0.0","1.1.6.1","2.0","2.0.12195.16151","2.1","2.1.0.1","2.5","2.5.3.1","N/A"],"setDefaultValue":false},"MOS(Dx)":{"values":["1.0.27","1.0.37","1.0.40","1.1.7.0","2.1.3.34","2.2.2.0","2.2.4.3"],"setDefaultValue":false},"MTS(Dx-MSR)":{"values":["1.0.7.0","N/A"],"setDefaultValue":false},"MSR(Dx)":{"values":["2.2.30.2","2.2.30.8","2.2.31.1","2.6.2.3"],"setDefaultValue":false},"RTAVersion(Dx)":{"values":["1.18.54.3; 1.16.18.2","1.16.18.0"],"setDefaultValue":false},"RecipeFragmentVersion(Dx)":{"values":["1.0.0","3.0.0","3.1.0.0"],"setDefaultValue":false},"MSRGenomes(Dx)":{"values":["1.0.0","1.0.0.4","1.1.0.0"],"setDefaultValue":false},"BaseSpaceBroker(Dx)":{"values":["2.0.12195.16151","2.9.1.2"],"setDefaultValue":false},"MCS(RUO)":{"values":["75.1.1.0","0.9","1.0.0","1.0.5","1.0.15.0","1.1.1.0","1.2.3","2.0","2.1","2.2","2.3","2.3.0","2.4","2.4.1.3","2.5","2.5.0.5","2.6.2","2.6.1.1","2.6.2.1","N/A"],"setDefaultValue":false},"MTS(RUO-LRM)":{"values":["N/A","1.0.7.0"],"setDefaultValue":false},"ImageVersion(Dx)":{"values":["4.0.C34.20170413"],"setDefaultValue":false}}}';
        attrTemplate.SVMXC__SM_Title__c = 'NovaSeq-NVSQ Template';
        insert attrTemplate;
        
        SVMXC__SM_Product_Attributes__c objPA = new SVMXC__SM_Product_Attributes__c();
        objPA.SVMXC__SM_Attribute_Template_Id__c = attrTemplate.id;
        objPA.SVMXC__SM_Product_Family__c = PRODUCT_FAMILY;
        insert objPA ;
        
        List<SVMXC__SM_IB_Technical_Attributes__c> lstIBAttr = new List<SVMXC__SM_IB_Technical_Attributes__c>();
        SVMXC__SM_IB_Technical_Attributes__c objIBAttr = new SVMXC__SM_IB_Technical_Attributes__c();
        objIBAttr.SVMXC__SM_Attr_Name__c = 'FPGA Version';
        objIBAttr.SVMXC__SM_Attr_Value__c = String.ValueOf(Math.random());
        objIBAttr.SVMXC__SM_Created_Date__c = System.now();
        objIBAttr.SVMXC__SM_Installed_Product_id__c = instProd.Id;
        lstIBAttr.add(objIBAttr) ;
        
		SVMXC__SM_IB_Technical_Attributes__c objIBAttr2 = new SVMXC__SM_IB_Technical_Attributes__c();
        objIBAttr2.SVMXC__SM_Attr_Name__c = 'SBC Model';
        objIBAttr2.SVMXC__SM_Attr_Value__c = 'Test SBC Model';
        objIBAttr2.SVMXC__SM_Created_Date__c = System.now();
        objIBAttr2.SVMXC__SM_Installed_Product_id__c = instProd.Id;
        lstIBAttr.add(objIBAttr2) ;
        
        SVMXC__SM_IB_Technical_Attributes__c objIBAttr3 = new SVMXC__SM_IB_Technical_Attributes__c();
        objIBAttr3.SVMXC__SM_Attr_Name__c = 'SBC Notes';
        objIBAttr3.SVMXC__SM_Attr_Value__c = 'test SBC Notes';
        objIBAttr3.SVMXC__SM_Created_Date__c = System.now();
        objIBAttr3.SVMXC__SM_Installed_Product_id__c = instProd.Id;
        lstIBAttr.add(objIBAttr3) ;
        insert lstIBAttr;

        Product2 objProd = TestDataMaster.getNewProduct('Test Prod1', 'Instrument');
        objProd.family = PRODUCT_FAMILY;
        update objProd;
        
        instProd.SVMXC__Product__c = objProd.Id;
        update instProd;
        
        SVMXC__SM_IB_Technical_Attributes__c objTA = new SVMXC__SM_IB_Technical_Attributes__c();
        objTA.SVMXC__SM_Installed_Product_id__c = instProd.Id;
        objTA.SVMXC__SM_Attr_Value__c = 'Electronic Notes';
        objTA.SVMXC__SM_Attr_Name__c = 'Upgrade Type';
        insert objTA;
        
        BatchUpdateNovaSeqAttribute.TechnicalAttributes  attribute = new  BatchUpdateNovaSeqAttribute.TechnicalAttributes();
        attribute.sequence = '1';
        attribute.unit = 'test';
        attribute.readOnly = 'test';
        attribute.format = 'test';
        attribute.defaultValue = 'test';
        attribute.label = 'test';
        attribute.type = 'test';
        
        
         Test.startTest();
        {
            Database.executeBatch(new BatchUpdateNovaSeqAttribute(),10);
        }
        Test.stopTest();
        
        List<SVMXC__SM_IB_Technical_Attributes__c> lstIBAttribute=[Select id from SVMXC__SM_IB_Technical_Attributes__c where SVMXC__SM_Installed_Product_id__c=:instProd.id];
        System.assert(lstIBAttribute.size() > 0);
    }
}
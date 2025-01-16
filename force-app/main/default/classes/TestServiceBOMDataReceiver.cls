/**
 * @description       : TestServiceBOMDataReceiver
 * @group             : 
 * @last modified on  : 10-12-2022
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pooja                    23-09-2022          CodeScan Fixes
**/
@isTest
/***************************************************************************************************************************************
* NAME   : TestServiceBOMDataReceiver 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public class TestServiceBOMDataReceiver {

    @testSetup static void dataSetup() {
    
      //create product with a material number.
        Product2 product = TestDataFieldService.createProduct('Test Product', '');
        product.Material_Number__c = '12344';
        insert product;
        
        //create a service bom with ERP number. This will get attached to a FRU List
        Service_Bill_Of_Materials__c serviceBOM = new Service_Bill_Of_Materials__c(Name = 'Test Service BOM', ERP_Service_BoM_Number__c = '100291');
        insert serviceBOM;  
        
        //create a FRU List
        FRU_List__c fruList = new FRU_List__c(SVMX_PS_External_ID__c = '1091');
        insert fruList;
          
    }
    
    static ServiceBOMDataReceiverWrapper.ServiceBOM getServiceBOMJson(String name,String strERPServiceBOMNumber,String active,String product, String strSvmxPSExternalID, String type, String parentProduct, String serviceBillOfMaterial){
        
        /****** POPULATE THE WRAPPER WITH DATA **************/
        
        //create a product group.
        ServiceBOMDataReceiverWrapper.Product_Group productGroupRecords = new ServiceBOMDataReceiverWrapper.Product_Group ();
        productGroupRecords.Product = product;
        
        //create FRU List for ServiceBOM JSON.
        ServiceBOMDataReceiverWrapper.FRUList fruListRecords = new ServiceBOMDataReceiverWrapper.FRUList();
        fruListRecords.SVMX_PS_External_ID = strSvmxPSExternalID;
        fruListRecords.Parent_Product = parentProduct;
        fruListRecords.Product_Group.add(productGroupRecords);
        
        //create header for Service BOM JSON.
        ServiceBOMDataReceiverWrapper.ServiceBOM serviceBOMRecords = new ServiceBOMDataReceiverWrapper.ServiceBOM();
        serviceBOMRecords.Name = name;
        serviceBOMRecords.ERP_Service_BOM_Number = strERPServiceBOMNumber;
        serviceBOMRecords.Active = active;
        serviceBOMRecords.FRUList.add(fruListRecords); 
        
        //return the wrapper object.
        return serviceBOMRecords; 
    }

    static testMethod void testServiceBOMInsertHTTPPost(){
        
        //holds the wrapper records in list.
        List<ServiceBOMDataReceiverWrapper.ServiceBOM> lstServiceBOMRecords = new List<ServiceBOMDataReceiverWrapper.ServiceBOM> ();
        
        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ServiceBOMDataReceiverWrapper.ServiceBOM serviceBOMRecords  = getServiceBOMJson('SAP Service BOM','29161','true','123441','54311','','123441','1002911');
        
        //pass it over to a list.  
        lstServiceBOMRecords.add(serviceBOMRecords);  
        
        //convert the apex list into a Json structure.
        String serviceBOMJSON = JSON.serialize(lstServiceBOMRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/ServiceBOMsyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(serviceBOMJSON);
            RestContext.request = req;
            RestContext.response= res;
            ServiceBOMDataReceiver.upsertIncomingValues(); 
            
        Test.stopTest();
        
        //make sure the status is success.
        System.assertequals(200,res.statuscode);
        
    }

    
    static testMethod void testServiceBOMUpdateHTTPPost(){
        
        //holds the wrapper records in list.
        List<ServiceBOMDataReceiverWrapper.ServiceBOM> lstServiceBOMRecords = new List<ServiceBOMDataReceiverWrapper.ServiceBOM> ();
        
        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ServiceBOMDataReceiverWrapper.ServiceBOM serviceBOMRecords  = getServiceBOMJson('SAP Service BOM','100291','true','12344','1091','','12344','100291');
        
        //pass it over to a list.  
        lstServiceBOMRecords.add(serviceBOMRecords);  
        
        //convert the apex list into a Json structure.
        String serviceBOMJSON = JSON.serialize(lstServiceBOMRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/ServiceBOMsyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(serviceBOMJSON);
            RestContext.request = req;
            RestContext.response= res;
            ServiceBOMDataReceiver.upsertIncomingValues(); 
            
        Test.stopTest();
        
        //make sure the status is success.
        System.assertequals(200,res.statuscode);
        
    }

}
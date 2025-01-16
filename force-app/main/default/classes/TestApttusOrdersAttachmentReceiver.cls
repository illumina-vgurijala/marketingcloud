/*
 * @Author : Sravan Panchangam
 * @Description : Test Class for ApttusOrdersAttachmentReceiver-DCP 9865
*/
@isTest(SeeAllData=false)
public class TestApttusOrdersAttachmentReceiver {
   
   @testSetup
    static void initializeTestData()
    {
        Account acc =TestDataAccount.getAccount('TestApttusOrdersAttachmentREceiver');
        acc.ERP_Customer_Id__c='123456';
        insert acc;
        System.debug('Acc From Attachment:'+acc.Id);
        
       Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;
        //System.assertNotEquals(null, pricebookId);
        System.debug('From Attachment pricebookId'+pricebookId);
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        System.debug('From Attachment opp before'+opp.Id);
        opp.Pricebook2Id = pricebookId;
        update opp;
        
        System.debug('From Attachment Opp'+opp.Id);
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        System.debug('From Attachment PriceList'+priceList);
        
        Apttus_Proposal__Proposal__c proposalInsert = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposalInsert;
        System.debug('Apttus Proposal:'+proposalInsert);
        
        
       }
    
    static testMethod void testApttusOrdersAttachmentInsertHTTPPost(){
        System.debug('From testApttusOrdersAttachmentInsertHTTPPost');
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c='83744421';
        orders.Sales_Order_Number_Unique__c='83744421';
        orders.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        orders.Ultimate_Consignee_ERP_Id__c='123456';
        orders.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        //orders.Payment_Terms_Code__c='TestPaymentCode';
        Apttus_Proposal__Proposal__c erpQuoteNumber=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        system.debug('From Proposal: Id:-'+erpQuoteNumber.Id+'Quotation:-'+erpQuoteNumber.Name);
        orders.ERP_Quote_Number__c=erpQuoteNumber.Name;
        insert orders;
        System.debug('Orders:'+orders);
        
        List<ApttusOrdersAttachmentWrapper.RequestBodyJson> requestBodyJson=new List<ApttusOrdersAttachmentWrapper.RequestBodyJson>();
        List<ApttusOrdersAttachmentWrapper.RelatedAttachments> relatedAttachmentsFromJson=new List<ApttusOrdersAttachmentWrapper.RelatedAttachments>();
        System.debug('After Order******************************** ');
        ApttusOrdersAttachmentWrapper.RelatedAttachments attachment1=new ApttusOrdersAttachmentWrapper.RelatedAttachments();
        attachment1.AttachmentFileName='Attachment1';
        attachment1.AttachmentVersionData='d29yZCBmcm9tIHRoZSBleGFtcGxl';
        relatedAttachmentsFromJson.add(attachment1);
        
        System.debug('After Order******************************** attachment1'+attachment1);
        
        ApttusOrdersAttachmentWrapper.RelatedAttachments attachment2=new ApttusOrdersAttachmentWrapper.RelatedAttachments();
        attachment2.AttachmentFileName='Attachment2';
        attachment2.AttachmentVersionData='d29yZCBmcm9tIHRoZSBleGFtcGxl';
        relatedAttachmentsFromJson.add(attachment2);
        System.debug('After Order******************************** attachment2'+attachment2);
        
        ApttusOrdersAttachmentWrapper.RequestBodyJson requestedAttachment=new ApttusOrdersAttachmentWrapper.RequestBodyJson();
        SYstem.debug('requestedAttachment'+requestedAttachment);
        requestedAttachment.Sales_Order_Number_Unique='83744421';
        System.debug('requestedAttachment.ASOP_Number'+requestedAttachment.Sales_Order_Number_Unique);
        requestedAttachment.relatedAttachments=new List<ApttusOrdersAttachmentWrapper.RelatedAttachments>();
        requestedAttachment.relatedAttachments.addAll(relatedAttachmentsFromJson);
       
        
        System.debug('Request Json'+requestedAttachment);
        requestBodyJson.add(requestedAttachment);
        String requestJSON = JSON.serialize(requestBodyJson);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ApttusOrdersAttachmentReceiver';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrdersAttachmentReceiver.insertAttachment();
        
        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode);
    }
    
    static testMethod void testApttusOrdersAttachmentRestError(){
        System.debug('From testApttusOrdersAttachmentInsertHTTPPost');
               
        
        List<ApttusOrdersAttachmentWrapper.RelatedAttachments> relatedAttachmentsFromJson=new List<ApttusOrdersAttachmentWrapper.RelatedAttachments>();
        
        ApttusOrdersAttachmentWrapper.RelatedAttachments attachment1=new ApttusOrdersAttachmentWrapper.RelatedAttachments();
        attachment1.AttachmentFileName='Attachment1';
        attachment1.AttachmentVersionData='d29yZCBmcm9tIHRoZSBleGFtcGxl';
        relatedAttachmentsFromJson.add(attachment1);
        
        
        
        ApttusOrdersAttachmentWrapper.RelatedAttachments attachment2=new ApttusOrdersAttachmentWrapper.RelatedAttachments();
        attachment2.AttachmentFileName='Attachment2';
        attachment2.AttachmentVersionData='d29yZCBmcm9tIHRoZSBleGFtcGxl';
        relatedAttachmentsFromJson.add(attachment2);
        
        
        ApttusOrdersAttachmentWrapper.RequestBodyJson requestedAttachment=new ApttusOrdersAttachmentWrapper.RequestBodyJson();
        requestedAttachment.Sales_Order_Number_Unique='83744421';        
        requestedAttachment.relatedAttachments=new List<ApttusOrdersAttachmentWrapper.RelatedAttachments>();
        requestedAttachment.relatedAttachments.addAll(relatedAttachmentsFromJson);
        
       
        String requestJSON = JSON.serialize(relatedAttachmentsFromJson);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ApttusOrdersAttachmentReceiver';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrdersAttachmentReceiver.insertAttachment();
        
        Test.stopTest();
		System.assert(res.statuscode != 200,'Response is successful');
       
    }

}
/**
*    @author: Pankaj 
*    @date:   04-Dec-2019
*    @description:  Class to set mock for S3 callout in DMPSegmentationDataRefresh
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        04-Dec-2019        Initial Development

     
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
global class DMPSegmentReceiverHTTPMock implements HttpCalloutMock{
    
    /*
    * @author Pankaj Singla
    * @date   04-Dec-2019 
    * @description: Test method to prepare mock JSON Input
    * @params :HTTPRequest request
    * @return:HTTPResponse
    * 
    */
     global HTTPResponse respond(HTTPRequest request){      
        List<DMPSegmentationDataRefresh.MetadataWrapper> lstMetadata=new List<DMPSegmentationDataRefresh.MetadataWrapper>();    
        List<DMPSegmentationDataRefresh.MetadataWrapper> lstWrapper=new List<DMPSegmentationDataRefresh.MetadataWrapper>();
        for(DMP_Priority_Segment__mdt mdt:[SELECT Id,Priority__c,SegmentId_Long__c,SegmentId__c,Category__c,Description__c,IsActive__c,Name__c, SubCategory__c,Type__c FROM DMP_Priority_Segment__mdt where isActive__c=true  order by Priority__c ASC limit 15]){
            DMPSegmentationDataRefresh.MetadataWrapper obj=new DMPSegmentationDataRefresh.MetadataWrapper();
            obj.category=mdt.Category__c;
            obj.description=mdt.Description__c;
            obj.is_active=String.ValueOf(mdt.IsActive__c);
            obj.last_compute_time='2019-11-25T12:03:19';
            obj.name=mdt.Name__c;
            obj.segment_type=mdt.Type__c;
            obj.segment_uuid=mdt.SegmentId__c;
            obj.segment_uuid_long=mdt.SegmentId_Long__c;
            obj.sub_category=mdt.SubCategory__c;
            lstMetadata.add(obj);
        }
        
         String myJSON = JSON.serialize(lstMetadata);
         HttpResponse response = new HttpResponse();
         response.setHeader('Content-Type', 'application/json');
         response.setBody(myJSON);
         response.setStatusCode(200);
         return response; 

     }
    
}
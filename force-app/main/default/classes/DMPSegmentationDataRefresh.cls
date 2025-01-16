/**
*    @author: Pankaj 
*    @date:   03-Dec-2019
*    @description:  Class to make callout to S3 to get priority segments and update custom metadata
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        03-Dec-2019        Initial Development

      DMPSegmentationDataRefresh.updateMetadata();
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class DMPSegmentationDataRefresh implements Metadata.DeployCallback,Schedulable{
    
    public static final String STRING_INTERFACENAME='DMPSegmentationS3';
    
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method which is called when deployed is completed
    * @params :Metadata.DeployResult result of deployment
    * @params:Metadata.DeployCallbackContext Deployment Context
    * 
    */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        FeedItem post = new FeedItem();
        post.ParentId = UserInfo.getUSerID();
        if (result.status == Metadata.DeployStatus.Succeeded) {            
            post.Body = 'Custom Metadata Refresh Success on ' + result.completedDate+'.The details are '+result.details;
            
        } else {            
            
            post.Body = 'Custom Metadata Refresh failed. Error message ' + result.errorMessage;
            
        }
        insert post;
    }
    
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method to call the updateMetadata method when the class is called from scheduled method
    * @params :SchedulableContext
    * @return: None
    * 
    */
    public void execute(SchedulableContext sc){
        updateMetadata();
    }
    
    
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method to Make callout to S3 and update the metadata records
    * @params :None
    * @return: None
    * 
    */
    @Future(callout=true)
    public static void updateMetadata(){
        /*List of input JSON List*/
        List<DMPSegmentationDataRefresh.MetadataWrapper> lstJson=new List<DMPSegmentationDataRefresh.MetadataWrapper>();
        /*map of segment id to input json data */
        map<string,DMPSegmentationDataRefresh.MetadataWrapper> mapSegmentIdToWrapper=new map<string,DMPSegmentationDataRefresh.MetadataWrapper>();
        /*Map of segment Id to existing metadata records*/
        map<string,DMP_Priority_Segment__mdt> mapSegmentIdToMetadata=new map<string,DMP_Priority_Segment__mdt>();       
        Map<String, String> strTostrconfig;
        strTostrconfig=UtilsRest.getIntegrationEndpoint(STRING_INTERFACENAME);
        String strNamedCred=strTostrconfig.get('NamedCredentials');
        /*Make a callout to S3 to get the segmentation data*/
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+strNamedCred);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        lstJson  =  (List<DMPSegmentationDataRefresh.MetadataWrapper>)JSON.deserialize(res.getBody(),List<DMPSegmentationDataRefresh.MetadataWrapper>.class);
        /*for the map of input JSON*/
        mapSegmentIdToWrapper=processInputMetadata(lstJson);
            
        mapSegmentIdToMetadata=retrieveExistingMetadataRecords();
        map<string,DMP_Priority_Segment__mdt> mapSegmentIdToMetadataDuplicate=new map<string,DMP_Priority_Segment__mdt>(mapSegmentIdToMetadata);
        
        /*Create a new Deployment container for deploying metadata*/
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        
        for(String segmentuid:mapSegmentIdToWrapper.keyset()){
            
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            /*If the metadata record is already present in system, update the existing record*/
            if(mapSegmentIdToMetadata.containsKey(segmentuid)){
                DMP_Priority_Segment__mdt mdtRecord=mapSegmentIdToMetadata.get(segmentuid);
                
                customMetadata.fullName = 'DMP_Priority_Segment.'+mdtRecord.developerName;
                customMetadata.label = mdtRecord.Label;
                
                /*This is used to de-activate the existing records which are invalid*/
                if(mapSegmentIdToMetadataDuplicate.containsKey(segmentuid)){
                    mapSegmentIdToMetadataDuplicate.remove(segmentuid);
                }
                
                
            }
            /*Create a new metadata record*/
            else {
                customMetadata.fullName = 'DMP_Priority_Segment.'+segmentuid;
                customMetadata.label = mapSegmentIdToWrapper.get(segmentuid).segment_uuid;
                
            }
                /*Set the Custom Metadata fields*/
                
                Metadata.CustomMetadataValue customFieldCategory = new Metadata.CustomMetadataValue();
                customFieldCategory.field = 'Category__c';
                customFieldCategory.value = mapSegmentIdToWrapper.get(segmentuid).category; 
                customMetadata.values.add(customFieldCategory);
                
                Metadata.CustomMetadataValue customFieldDescription = new Metadata.CustomMetadataValue();
                customFieldDescription.field = 'Description__c';
                customFieldDescription.value = mapSegmentIdToWrapper.get(segmentuid).description; 
                customMetadata.values.add(customFieldDescription);
                
                Metadata.CustomMetadataValue customFieldIsActive = new Metadata.CustomMetadataValue();
                customFieldIsActive.field = 'IsActive__c';
                customFieldIsActive.value = Boolean.ValueOf(mapSegmentIdToWrapper.get(segmentuid).is_active); 
                customMetadata.values.add(customFieldIsActive);
                

                Metadata.CustomMetadataValue customFieldLastComputeTime = new Metadata.CustomMetadataValue();
                customFieldLastComputeTime.field = 'Last_Compute_Time__c';
                customFieldLastComputeTime.value = formatInputDate(mapSegmentIdToWrapper.get(segmentuid).last_compute_time);
                customMetadata.values.add(customFieldLastComputeTime);
                    
                
                Metadata.CustomMetadataValue customFieldName = new Metadata.CustomMetadataValue();
                customFieldName.field = 'Name__c';
                customFieldName.value = mapSegmentIdToWrapper.get(segmentuid).Name; 
                customMetadata.values.add(customFieldName);
                
                
                Metadata.CustomMetadataValue customFieldSegmentType = new Metadata.CustomMetadataValue();
                customFieldSegmentType.field = 'Type__c';
                customFieldSegmentType.value = mapSegmentIdToWrapper.get(segmentuid).type; 
                customMetadata.values.add(customFieldSegmentType);
                
                Metadata.CustomMetadataValue customFieldSegmentId = new Metadata.CustomMetadataValue();
                customFieldSegmentId.field = 'SegmentId__c';
                customFieldSegmentId.value = mapSegmentIdToWrapper.get(segmentuid).segment_uuid; 
                customMetadata.values.add(customFieldSegmentId);
                
                
                Metadata.CustomMetadataValue customFieldSegmentIdLong = new Metadata.CustomMetadataValue();
                customFieldSegmentIdLong.field = 'SegmentId_Long__c';
                customFieldSegmentIdLong.value = mapSegmentIdToWrapper.get(segmentuid).segment_uuid_long; 
                customMetadata.values.add(customFieldSegmentIdLong);
                
                Metadata.CustomMetadataValue customFieldSubcategory = new Metadata.CustomMetadataValue();
                customFieldSubcategory.field = 'SubCategory__c';
                customFieldSubcategory.value = mapSegmentIdToWrapper.get(segmentuid).sub_category; 
                customMetadata.values.add(customFieldSubcategory);
                
                
                
                mdContainer.addMetadata(customMetadata);
                                
                
            }
            /*For the existing Custom Metadata set isActive as false if they are not present in input JSON*/
            for(String segmentId:mapSegmentIdToMetadataDuplicate.keyset()){
                
                Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
                DMP_Priority_Segment__mdt mdtRecord=mapSegmentIdToMetadataDuplicate.get(segmentId);             
                
                customMetadata.fullName = 'DMP_Priority_Segment.'+mdtRecord.developerName;
                customMetadata.label = mdtRecord.Label;
                
                Metadata.CustomMetadataValue customFieldIsActive = new Metadata.CustomMetadataValue();
                customFieldIsActive.field = 'IsActive__c';
                customFieldIsActive.value = false; 
                customMetadata.values.add(customFieldIsActive);
                
                mdContainer.addMetadata(customMetadata);
                
            }
             
    
        /*Enque the deployment job. Since Metadata cannot be deployed in test class execution, 
        so added an additional check !Test.isRunningTest()*/
        if(mdContainer!=null && !Test.isRunningTest()){
            system.debug('mdContainer---'+mdContainer);
            DMPSegmentationDataRefresh  callback = new DMPSegmentationDataRefresh ();
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
        
        
    }
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method to form map of input records of metadata to be configured
    * @params :List<DMPSegmentationDataRefresh.MetadataWrapper> the list of wrapper input
    * @return: map<string,DMPSegmentationDataRefresh.MetadataWrapper> map of segment id to wrapper object
    * 
    */
    public static map<string,DMPSegmentationDataRefresh.MetadataWrapper> processInputMetadata(List<DMPSegmentationDataRefresh.MetadataWrapper> lstInputMetaData){
        map<string,DMPSegmentationDataRefresh.MetadataWrapper> mapSegmentIdToWrapper=new map<string,DMPSegmentationDataRefresh.MetadataWrapper>();
        for(DMPSegmentationDataRefresh.MetadataWrapper wrap:lstInputMetaData){
            if(wrap.is_active!=null && wrap.is_active=='true'){
                mapSegmentIdToWrapper.put(wrap.segment_uuid_long,wrap);
            }
        }
        
        return mapSegmentIdToWrapper;
    }
    
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method to form map of existing custom metadata records
    * @params :None
    * @return: map<string,DMP_Priority_Segment__mdt> map of segment id to metadata records.
    * 
    */
    
    public static map<string,DMP_Priority_Segment__mdt> retrieveExistingMetadataRecords(){
        List<String> componentNameList = new List<String>();
        map<string,DMP_Priority_Segment__mdt> mapSegmentIdTometadata=new map<string,DMP_Priority_Segment__mdt>();       
        for(DMP_Priority_Segment__mdt mdt:[select id,DeveloperName,label,Category__c,SubCategory__c,Name__c,SegmentId__c,                                   SegmentId_Long__c from DMP_Priority_Segment__mdt where IsActive__c  =true]){
            
            mapSegmentIdTometadata.put(mdt.SegmentId_Long__c,mdt);
            
        }
            
        return mapSegmentIdTometadata;
    }
    
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Method to format DateTime as per Salesforce format for 
    * @params :strDatetime the input date. Eg-2019-11-25T12:03:19
    * @return: DateTime value 
    * 
    */
    public static DateTime formatInputDate(String strDatetime){
        List<String> lstSplitInitial=strDatetime.split('T');
        Integer intyear=0,intMonth=0,intDay=0,inthour=0,intminute=0,intsec=0;
        if(lstSplitInitial.size()==2){
            String strdateVal=lstSplitInitial[0];
            List<String> lstdate=strdateVal.split('-');
            if(lstdate.size()==3){
                intyear=integer.valueof(lstdate[0]);
                intMonth=integer.valueof(lstdate[1]);
                intDay=integer.valueof(lstdate[2]);
                
            }
            
            String strTimeVal=lstSplitInitial[1];
            List<String> lsttime=strTimeVal.split(':');
            if(lsttime.size()==3){
                inthour=integer.valueof(lsttime[0]);
                intminute=integer.valueof(lsttime[1]);
                intsec=integer.valueof(lsttime[2]);
            }
            
        }
        
        Return (DateTime.newinstance(intyear,intmonth,intday,inthour,intminute,intsec));
        
        
    }
        
    /*
    * @author Pankaj Singla
    * @date   03-Dec-2019 
    * @description: Wrapper class to parse the input JSON received from S3   
    * 
    */
    
    public class MetadataWrapper {
        public String category;
        public String description;
        public String is_active;
        public String last_compute_time;
        public String name;
        public String segment_type;
        public String segment_uuid;
        public String segment_uuid_long;
        public String sub_category;
        public String type;
        
    }

}
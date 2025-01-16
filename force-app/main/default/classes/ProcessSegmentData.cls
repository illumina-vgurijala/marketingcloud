/**
*    @author: Pankaj Singla
*    @date:   25-Nov-2019
*    @description:  Batch class to check Priority Segments
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              25 Nov 2019           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/ 
public without sharing class ProcessSegmentData extends ilib_ScheduleAndBatch {
   
    public static final string SUFFIXC = '__c';

     /*
    *  Description: Query method start() created
    */
     public override Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('select id,Hem__c,segments__c,Record_Processed__c,Record_Processed_Date__c from DMP_Staging__c'+ 
                                        ' where Record_Processed__c=false and Record_Processed_Date__c= null');
     }
    
    
    
    /*
    * @author Pankaj Singla
    * @date   26-Nov-2019 
    * @description: Execute method of the batch job
    * params :Database.BatchableContext,scope
    * return None
    */
   public override void execute(Database.BatchableContext info, List<sObject> scope) {
       
       set<String> setHashedEmails=new set<string>();
       map<string,Contact> mapHashedIdToContact=new map<string,Contact>();
       map<string,Lead> mapHashedIdToLead=new map<string,Lead>();
       map<string,string> mapHashedEmailToSegments=new map<string,string>();
       map<string,DMP_Priority_Segment__mdt> mapSegmentIdToMdt=new map<string,DMP_Priority_Segment__mdt>();
       list<DMP_Staging__c> lstDMPStagingScope=(List<DMP_Staging__c>)scope;
       list<DMP_Staging__c> lstDMPStagingProcessed=new list<DMP_Staging__c>();
       DMP_Staging__c objDMPStage;
       for(DMP_Priority_Segment__mdt mdtRec:[select IsActive__c,Category__c,Description__c,SegmentId__c,SegmentId_Long__c,Priority__c,Name__c from DMP_Priority_Segment__mdt where IsActive__c=true]){
           mapSegmentIdToMdt.put(mdtRec.SegmentId__c,mdtRec);
       }
       
       for(DMP_Staging__c objDMPStaging:lstDMPStagingScope){
           if(objDMPStaging.Hem__c!=null){
               List<String> lstMultipleHEMs=objDMPStaging.Hem__c.split(',');
               system.debug('lstMultipleHEMs---'+lstMultipleHEMs);
               for(String strHem:lstMultipleHEMs){
                  mapHashedEmailToSegments.put(strHem,objDMPStaging.segments__c);
                  setHashedEmails.add(strHem);
               }
           }
           system.debug('setHashedEmails---'+setHashedEmails);
		   objDMPStage=new DMP_Staging__c(id=objDMPStaging.id);
		   objDMPStage.Record_Processed__c=true;
           objDMPStage.Record_Processed_Date__c=DateTime.now();
           lstDMPStagingProcessed.add(objDMPStage);  
           
       }
       if(!setHashedEmails.isEmpty()){
           for(Contact objCon:[select id,Hashed_Email_Id__c,email from contact where Hashed_Email_Id__c in:setHashedEmails]){
               mapHashedIdToContact.put(objCon.Hashed_Email_Id__c,objCon);
           }
           
           for(Lead objLead:[select id,Hashed_Email_Id__c,email from Lead where Hashed_Email_Id__c in:setHashedEmails and isconverted=false]){
               mapHashedIdToLead.put(objLead.Hashed_Email_Id__c,objLead);
           }
           List<Contact> lstContact=new List<Contact>();
           List<Lead> lstLead=new List<Lead>();
           
           /*Loop over all the contacts matching the input JSON based on Hashed Email Id*/
           for(String strHashKey:mapHashedIdToContact.keyset()){
               Contact objContact=new Contact(id=mapHashedIdToContact.get(strHashKey).id);
               objContact=(Contact)updateSegmentationData(mapHashedEmailToSegments,mapSegmentIdToMdt,objContact,strHashKey);
               lstContact.add(objContact);
           }
           /*Loop over all the Leads matching the input JSON based on Hashed Email Id*/
           for(String strHashKey:mapHashedIdToLead.keyset()){
               Lead objLead=new Lead(id=mapHashedIdToLead.get(strHashKey).id);
               objLead=(Lead) updateSegmentationData(mapHashedEmailToSegments,mapSegmentIdToMdt,objLead,strHashKey);
               lstLead.add(objLead);
           }

          if(!lstContact.isEmpty()) {   
              List<Database.SaveResult> lstResults = Database.update(lstContact, false);
          } 
          if(!lstLead.isEmpty()) {
              List<Database.SaveResult> lstResults = Database.update(lstLead, false);
          }          
          if(!lstDMPStagingProcessed.isEmpty()) {
              List<Database.SaveResult> lstResults = Database.update(lstDMPStagingProcessed, false);
          }
       }
    }
    /*
    * @author Pankaj Singla
    * @date   26-Nov-2019 
    * @description: Method to check priority segment and stamp the required fields
    * @params :mapHashedEmailToSegments- Map of Hashed email ids to Segments
    * @params:mapSegmentIdToMdt - Map of segment Id to Segment Metatada
    * @params:SObject- Object for processing
    * @params:strHashKey- HashEmail Id
    * @return SObject- Object with fields stamped
    */
    private static sObject updateSegmentationData(map<string,string> mapHashedEmailToSegments,map<string,DMP_Priority_Segment__mdt> mapSegmentIdToMdt,SObject ojRecord,String strHashKey){
    /*The segments are separated by , so split those and get into a list*/
    List<String> lstSegments=mapHashedEmailToSegments.get(strHashKey).split(',');
    /*Create a duplicate copy of segments list. This list would modified to remove the segments matching the metadata*/
    List<String> lstSegmentCopy=new List<String>(lstSegments);
    /*Form a list of wrapper class. This is to sort the segments based on priority value*/
    List<segmentationData> lstsegmentationData=new List<segmentationData>();
    Integer intSegmentsInput=lstSegments.size();
    Integer intMaxPriortitySegmentSize=Integer.ValueOf(Label.DMPMaxSegmentSize);
    if(lstSegments!=null){
        for(Integer i=1;i<=lstSegments.size();i++){
            if(mapSegmentIdToMdt.containsKey(lstSegments[i-1])){
                Integer intIndex=lstSegmentCopy.indexOf(lstSegments[i-1]);
                SegmentationData sg=new SegmentationData();
                DMP_Priority_Segment__mdt objMetadataRec=mapSegmentIdToMdt.get(lstSegments[i-1]);
                sg.intPriority=Integer.ValueOf(objMetadataRec.Priority__c);
                sg.strSegmentIdFinal=(objMetadataRec.SegmentId_Long__c+'~'+objMetadataRec.Name__c).abbreviate(255);
                lstsegmentationData.add(sg);
                lstSegmentCopy.remove(intIndex);
            }
        }
        lstsegmentationData.sort();
        
        Integer intCounter=1;
        
        for(Integer intJ=1;intJ<=intMaxPriortitySegmentSize;intJ++) {
            String fieldApiName=((intJ==10)?('DMP_CRM_Segment_'+intJ+SUFFIXC):'DMP_CRM_Segment_0'+intJ+SUFFIXC);
             ojRecord.put(fieldApiName,'');
        }
        
        for(segmentationData sg:lstsegmentationData) {
            String fieldApiName=((intCounter==10)?('DMP_CRM_Segment_'+intCounter+SUFFIXC):'DMP_CRM_Segment_0'+intCounter+SUFFIXC);
            if(intCounter<=intMaxPriortitySegmentSize){
                ojRecord.put(fieldApiName,sg.strSegmentIdFinal);
                intCounter++;
            }
            
        }
    }
    
    return ojRecord;
    }
     /*
    *  Description:  Method finish() created
    */
     public override void finish(Database.BatchableContext info) {
        /*No Finish Logic */  
    }

}
/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  Campaign Member status creation
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 10 Sept 2018        Class to create campaign member status values
*             Roopal Verma                  17 Jan 2020         DCP-33510 Added condition to fix test class error
*             Rishab Wali                   19 Sep 2022         [DCP-56317] Update Campaign Member Status Logic to Type and Channel
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class Campaigns extends ilib_SObjectDomain {
    /*
    * Description: Constructor Campaigns created
    */
    
    public Campaigns(List<Campaign> sObjectList){
    
        super(sObjectList);
    }
    
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable

    {
        /*
        * Method Description: ilib_SObjectDomain created
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Campaigns(sObjectList);
        }
    }
    
    /*
    * @author Pankaj
    * @date   10-Sept-2018
    * Description- Create record for CampaignMemberstatus object for each campaign. 
                    These records are displayed as picklist values in Campaign Member Status.
    * 
    * After Insert trigger method
    */
    public override void onAfterInsert()
    {
        //map to hold the metadata records, with key as Campaign Type and value as list of records
        map<string,list<Campaign_Member_Status__mdt>> campaignTypeToCampaignMetadata=new map<string,list<Campaign_Member_Status__mdt>>();
        
        // map to hold the existing campaign member status values, key- campaign id, value- list of campaign member status records
        map<id,list<CampaignMemberStatus>> mapCampaignIdToCampaignMemberStatus=new map<id,list<CampaignMemberStatus>>();
        // list of records to upsert
        list<CampaignMemberStatus> lstCampaignMemberStatusUpsert=new list<CampaignMemberStatus>();
        // list of new campaign member status values to be inserted
        list<CampaignMemberStatus> lstCampaignMemberStatusinsert=new list<CampaignMemberStatus>();
        
        // list of records to be deleted
        list<CampaignMemberStatus> lstCampaignMemberStatusDelete=new list<CampaignMemberStatus>();
        
        // populate the metadata map 
        for(Campaign_Member_Status__mdt campMdtRec:new CampaignMemberStatusMetaDataSelector().selectCampaignMemberMetaRecords()){
            String strKeyTypeAndChannel = campMdtRec.Campaign_Type__c+'_'+campMdtRec.Campaign_Channel__c;
            if(campaignTypeToCampaignMetadata.containsKey(strKeyTypeAndChannel)) {
                campaignTypeToCampaignMetadata.get(strKeyTypeAndChannel).add(campMdtRec);
            }
            else{
                campaignTypeToCampaignMetadata.put(strKeyTypeAndChannel,new list<Campaign_Member_Status__mdt>{campMdtRec});
            }
        }
        // populate the campaign member status map
        for(CampaignMemberStatus objCampaignMemberStatus:new CampaignMemberStatusSelector().selectCampaignMemberStatus(Trigger.New)){
    
                if(mapCampaignIdToCampaignMemberStatus.containsKey(objCampaignMemberStatus.CampaignId)) {   
                    mapCampaignIdToCampaignMemberStatus.get(objCampaignMemberStatus.CampaignId).add(objCampaignMemberStatus);
                }
                else {
                    mapCampaignIdToCampaignMemberStatus.put(objCampaignMemberStatus.CampaignId,
                    new list<CampaignMemberStatus>{objCampaignMemberStatus});   
                }
      }
        list<Campaign> lstCampaign=(list<Campaign>)trigger.new;
        for(Campaign objCampaign : lstCampaign){
            string campaignTypeAndChannel = objCampaign.Type + '_' + objCampaign.Channel__c;
            if( mapCampaignIdToCampaignMemberStatus.containsKey(objCampaign.Id) &&                                           //DCP-33510 Added condition to fix test class error
                !campaignTypeToCampaignMetadata.isEmpty() && campaignTypeToCampaignMetadata.containsKey(campaignTypeAndChannel) ){
                list<CampaignMemberStatus> lstCampaignMemberStatus=mapCampaignIdToCampaignMemberStatus.get(objCampaign.id);
                list<Campaign_Member_Status__mdt> lstCampaignMemberMetaData=campaignTypeToCampaignMetadata.get(campaignTypeAndChannel);
                Integer j=0;
                
                // if existing campaign member status values are less than the values to be configured
                if(lstCampaignMemberStatus.size()<=lstCampaignMemberMetaData.size()){
                    // update the existing records with the values from metadata records
                    for(Integer i=0;i<lstCampaignMemberStatus.size();i++){
                        j=j+1;
                        lstCampaignMemberStatus[i].Label=lstCampaignMemberMetaData[i].Campaign_Member_Status_Label__c;
                        lstCampaignMemberStatus[i].IsDefault=lstCampaignMemberMetaData[i].IsDefault__c;
                        lstCampaignMemberStatus[i].HasResponded=lstCampaignMemberMetaData[i].HasResponded__c;
                        lstCampaignMemberStatus[i].SortOrder=Integer.ValueOf(lstCampaignMemberMetaData[i].Sort_Order__c);
                        
                        lstCampaignMemberStatusUpsert.add(lstCampaignMemberStatus[i]);
                    }
                    for(Integer k=j;k<lstCampaignMemberMetaData.size();k++){
                        // create new campaign member records
                        CampaignMemberStatus objCampaignMemberStatus=new CampaignMemberStatus(campaignid=objCampaign.id);
                        objCampaignMemberStatus.Label=lstCampaignMemberMetaData[k].Campaign_Member_Status_Label__c;
                        objCampaignMemberStatus.IsDefault=lstCampaignMemberMetaData[k].IsDefault__c;
                        objCampaignMemberStatus.HasResponded=lstCampaignMemberMetaData[k].HasResponded__c;
                        objCampaignMemberStatus.SortOrder=Integer.ValueOf(lstCampaignMemberMetaData[k].Sort_Order__c);
                        lstCampaignMemberStatusinsert.add(objCampaignMemberStatus);
                    }
                }
                
                else if(lstCampaignMemberStatus.size()>lstCampaignMemberMetaData.size()){
                    // if the existing records are more than the required, copy the values in existing records and delete the extra records
                    for(Integer i=0;i<lstCampaignMemberMetaData.size();i++){
                        lstCampaignMemberStatus[i].Label=lstCampaignMemberMetaData[i].Campaign_Member_Status_Label__c;
                        lstCampaignMemberStatus[i].IsDefault=lstCampaignMemberMetaData[i].IsDefault__c;
                        lstCampaignMemberStatus[i].HasResponded=lstCampaignMemberMetaData[i].HasResponded__c;
                        lstCampaignMemberStatus[i].SortOrder=Integer.ValueOf(lstCampaignMemberMetaData[i].Sort_Order__c);
                        lstCampaignMemberStatusUpsert.add(lstCampaignMemberStatus[i]);
                    }
                    
                    for(Integer i=lstCampaignMemberMetaData.size();i<lstCampaignMemberStatus.size();i++){
                        lstCampaignMemberStatusDelete.add(lstCampaignMemberStatus[i]);
                    }   
                }               
          }
        }
        
        if(!lstCampaignMemberStatusUpsert.isEmpty()){
            //upsert lstCampaignMemberStatusUpsert;
             lstCampaignMemberStatusinsert.addAll(lstCampaignMemberStatusUpsert);
        }
        if(!lstCampaignMemberStatusinsert.isEmpty()){
            //lstCampaignMemberStatusinsert.addAll(lstCampaignMemberStatusinsert);
             upsert lstCampaignMemberStatusinsert;       
        }
        
        if(!lstCampaignMemberStatusDelete.isEmpty()){
            delete lstCampaignMemberStatusDelete;
        }   
    }
}
/**
*    @author: Rishab Wali
*    @description:  Helper Class for Leads trigger class 
*    @Test Class : TestLeads, TestAreaOfWorkLeadDecorator
*    Modification Log:
*    --------------------------------------------------------------------------------------------
*         Developer           Date             Description
*         Rishab Wali         08-Dec-2021      [DCP-49756] Update Most Recent Activity Date Field
*         Deep Diwakar        Nov-27-2023      CMCM-4510: Added method to return Area of Interest to Area of Work mapping
*    --------------------------------------------------------------------------------------------
*/
public with sharing class LeadsHelper {

    /*
        Method - [DCP-49756] To update the  most recent activity field on the lead record.
        Parameter - lead record
    */
    public static void updateMostRecentActivityDate(List<Lead> lstLead, Boolean changeTrigerredFromCampaignTrigger)
    {
        if(!changeTrigerredFromCampaignTrigger)
        {
            for(Lead objNewLead : lstLead)
            {
                if(trigger.isInsert || objNewLead.Most_Recent_Activity_Date__c == null)
                {
                    objNewLead.Most_Recent_Activity_Date__c = objNewLead.CreatedDate;
                }

                if(objNewLead.Last_Responded_Campaign_Date__c > objNewLead.Most_Recent_Activity_Date__c)
                {
                    objNewLead.Most_Recent_Activity_Date__c = objNewLead.Last_Responded_Campaign_Date__c;
                }

                if(objNewLead.pi__last_activity__c >= objNewLead.Most_Recent_Activity_Date__c)
                {
                    objNewLead.Most_Recent_Activity_Date__c = objNewLead.pi__last_activity__c;
                }
                
                if(objNewLead.Date_Of_Last_Score_Change__c >= objNewLead.Most_Recent_Activity_Date__c && objNewLead.Marketing_Score__c > 0)
                {
                    objNewLead.Most_Recent_Activity_Date__c = objNewLead.Date_Of_Last_Score_Change__c;
                }
            }
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: This method creates mapping for Area of Interest to Area of Work
     * @param: none
     * @return: Map of Area of Interest to Area of Work
     */
    public static Map<String, String> getAoIToAowMapping() {

        Map<String, String> mapAoIToAoW = new Map<String, String>();

        // get AoI to AoW mapping from CMT
        List<AreaOfInterest_To_AreaOfWork_Mapping__mdt> lstMappingRecords = [SELECT Id, AreaOfInterest__c, AreaOfWork__c
                                                                            FROM AreaOfInterest_To_AreaOfWork_Mapping__mdt
                                                                            LIMIT 1000];

        for (AreaOfInterest_To_AreaOfWork_Mapping__mdt mappingRecord: lstMappingRecords) {
            mapAoIToAoW.put(mappingRecord.AreaOfInterest__c, mappingRecord.AreaOfWork__c);
        }

        return mapAoIToAoW;
    }

}

/***************************************************************************************************************************************
* NAME   : TAPS_ChannelPartnerQuotas 
* DESCRIPTION: Created for TASK0748834
*
* Modification Log:
* Developer     Date            Description
* Koustubh M    22-May-2022     TASK0748834 Added Channel_Partner_Quota__c
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_ChannelPartnerQuotas extends TAPS_ComposedBase implements TAPS_IObjectsDirect {

    /* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getObjectType() {
        return Channel_Partner_Quota__c.sObjectType;
    }

	/* 
    * @description: To return Field API Name
    * @return: SObjectType
    */
    public override String getLookupFieldName() {
        return 'Account_Name__c';
    }

	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getShareObjectType() {
        return Channel_Partner_Quota__Share.sObjectType;
    }

	/* 
    * @description: To return Field API Name
    * @return: SObjectType
    */	
    public override String getShareParentFieldName() {
        return 'ParentId';
    }

	/* 
    * @description: Create Sharing Record
    * @Param: Id, Id
    * @return: SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new Channel_Partner_Quota__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Edit',
                RowCause = Schema.Channel_Partner_Quota__Share.RowCause.Manual
        );
    }

}
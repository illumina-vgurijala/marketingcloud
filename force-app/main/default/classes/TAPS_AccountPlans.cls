  /*
    * @Author: Todd Newman
    * @Date: 
    * @Description : 
    * -------------------------------------------------------------------------------------------------------
    *        Developer               Date                Description
    *        Todd Newman                                Initial Version
    *        Aman Tyagi             2022-03-30          CodeScan Fixes
    * -------------------------------------------------------------------------------------------------------
    */
public without sharing class TAPS_AccountPlans extends TAPS_ComposedBase implements TAPS_IObjectsDirect
{
   /*
    * @Author:Todd Newman
    * @Description : method to get the sObject type of Account_Plan object
    * @param: none
    * @return: sObjectType
    */
    public override SObjectType getObjectType()
    {
        return Account_Plan__c.sObjectType;
    }

    /*
    * @Author:Todd Newman
    * @Description : method to get the lookup field name
    * @param: none
    * @return: String
    */
    public override String getLookupFieldName()
    {
        return 'Account_Name__c';
    }

    /*
    * @Author:Todd Newman
    * @Description : method to get the share Object type
    * @param: none
    * @return: sObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return Account_Plan__Share.sObjectType;
    }

    /*
    * @Author:Todd Newman
    * @Description : method to get the shareparent field name
    * @param: none
    * @return: String
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /*
    * @Author:Todd Newman
    * @Description : method to create the sharing record based on the userId and record id
    * @param: Id recordId, Id userId
    * @return: sObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Account_Plan__Share share = new Account_Plan__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Account_Plan__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    /*
    * @Author:Todd Newman
    * @Description :method to create account to Field support Sharing override base class method to make read sharing
    * @param: Id recordId, Id userId
    * @return: sObject
    */
    public override SObject createATFSSharingRecord(Id recordId, Id userId)
    {
        Account_Plan__Share share = new Account_Plan__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Account_Plan__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    /*
    * @Author:Todd Newman
    * @Description :method to override the base class method
    * @param: none
    * @return: boolean
    */
    public override Boolean needToShareToATFS()
    {
        return true;
    }

}
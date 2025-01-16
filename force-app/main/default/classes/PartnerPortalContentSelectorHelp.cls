/**
*    @author Prakhar Kumar
*    @date   2019-08-14
*    @description    DCP-28546: Partner PortalContent Selector
*    ------------------------------------------------------------- 
* Modification Log:
* ---------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------
* Prakhar Kumar          22-08-2019               DCP-28546            Added RecordType.Name = Slides
* 
*                    
*/
public with sharing class PartnerPortalContentSelectorHelp extends ilib_SObjectSelector {

    /*
     * Constructor
     */
public PartnerPortalContentSelectorHelp()
{
    super(false, false, false, false);
}


/*
* @description: This method returns the objectAPIName of an SObjectType
* @return: Schema.SObjectType 
*/
public Schema.SObjectType getSObjectType()
{
    return Partner_Portal_Content__c.sObjectType;
}
 /*
* @author Prakhar Kumar
* @date   14-08-2018
* @description  Retrieve list of urls for quicklinks
* @return sObjectFieldList list of Schema.SObjectField
*/
public List<Schema.SObjectField> getSObjectFieldList()
{
    return new List<Schema.SObjectField> {
        Partner_Portal_Content__c.Active__c,
        Partner_Portal_Content__c.Button_Text__c,
        Partner_Portal_Content__c.Button_URL__c,
        Partner_Portal_Content__c.Home_Page_Text__c,
        Partner_Portal_Content__c.Image_URL__c,
        Partner_Portal_Content__c.Quick_Links_URL__c,
        Partner_Portal_Content__c.Region__c,
        Partner_Portal_Content__c.Slide_Name__c,
        Partner_Portal_Content__c.Slide_Subtitle__c,
        Partner_Portal_Content__c.Slide_Title__c,
        Partner_Portal_Content__c.Terms_of_Use_Version__c,
        Partner_Portal_Content__c.Video_URL__c,
        Partner_Portal_Content__c.ImageCSS__c,
        Partner_Portal_Content__c.Quick_Links_Label__c,
        Partner_Portal_Content__c.Button_Visible__c,
        Partner_Portal_Content__c.Sort_Order__c 
    };
}




 /**
*  @author Prakhar Kumar
*  @description Override Default name Ordering
*  
*  @return String for Ordering  
**/
private Boolean removeDefaultOrderBy=false;

    /*
    * @description: This method returns sorting field and direction based on when the default ordering is removed
    * @return: String
    */	
public override String getOrderBy() {
    if(removeDefaultOrderBy){
        return 'Sort_Order__c ASC';
    }else{
        return super.getOrderBy();
    }
    
}   



/*
* @author Vinay S Reddy
* @description Fetch hyperlinks of the Help from Partner portal Content SObject
*
*/
 
public List<Partner_Portal_Content__c> selectActiveHelpLinks() 
{   
    removeDefaultOrderBy=TRUE;     
    return (List<Partner_Portal_Content__c>) Database.query(
    newQueryFactory()
    .setCondition('Region__c = \'\' AND Active__c = true AND recordtype.Name=\'help\' AND Button_Visible__c=True AND Button_Text__c !=\'\' AND Button_URL__c != \'\' AND Sort_Order__c !=null')
    .toSOQL());
    
} 


}
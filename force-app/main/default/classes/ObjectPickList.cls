/**
*    @author Akshay Mohan
*    @date   2020-08-26
*    @description   Logic to show all objects of org
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
global virtual without sharing class ObjectPickList extends VisualEditor.DynamicPickList{
    public static final String RECORD_PAGE = 'RecordPage';
    protected String strPageType;
    protected VisualEditor.DynamicPickListRows rows;

    protected Schema.DescribeSobjectResult objectInfo;
    
    /**
    * @description Constuctor with page type and object name
    */
    global ObjectPickList(String strPageType, String strObjectName) {
        this.strPageType = strPageType;
        rows = new VisualEditor.DynamicPickListRows();
        if(isRecordPage()){
            setObjectInfo(strObjectName);
        }
            
    }

    /**
    * @description Constuctor with VisualEditor.DesignTimePageContext
    */
    global ObjectPickList(VisualEditor.DesignTimePageContext context) {this(context.pageType, context.entityName);}

    /**
    * @owner Akshay Mohan
    * @description Set the record page object info
    */
    private void setObjectInfo(String strObjectName){
        objectInfo = Schema.describeSObjects(new List<String>{ strObjectName })[0];
    }

    /**
    * @owner Akshay Mohan
    * @description Set the default value
    */
    global override virtual VisualEditor.DataRow getDefaultValue() {
        if(isRecordPage())
            return getCurrentObjectRow(objectInfo);
        else 
            return null;
    }

    /**
    * @owner Akshay Mohan
    * @description Set the picklist
    */
    global override virtual VisualEditor.DynamicPickListRows getValues() {
        if(isRecordPage())
            rows.addRow(getCurrentObjectRow(objectInfo));
        else{
            for(Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()){
                rows.addRow(getCurrentObjectRow(sObjType.getDescribe()));
            }
        }
        return this.rows;
    }

    /**
    * @owner Akshay Mohan
    * @description Check if configured in record page
    */
    protected Boolean isRecordPage(){
        return RECORD_PAGE.equals(strPageType);
    }

    /**
    * @owner Akshay Mohan
    * @description get Picklist entry based on object detail passed
    */
    private VisualEditor.DataRow getCurrentObjectRow(Schema.DescribeSobjectResult obj){
        return new VisualEditor.DataRow(obj.getLabel()+'('+obj.getName()+')', obj.getName());
    }

}
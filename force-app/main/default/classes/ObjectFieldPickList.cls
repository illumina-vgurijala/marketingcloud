/**
*    @author Akshay Mohan
*    @date   2020-08-26
*    @description   Logic to show an object's field in the org
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
global without sharing class ObjectFieldPickList extends ObjectPickList {
    
    /**
    * @description Constuctor with page type and object name
    */
    global ObjectFieldPickList(String strPageType, String strObjectName) {
        super(strPageType, strObjectName);
        setRows();
    }
    
    /**
    * @description Constuctor with VisualEditor.DesignTimePageContext
    */
    global ObjectFieldPickList(VisualEditor.DesignTimePageContext context) {this(context.pageType, context.entityName);}

    /**
    * @owner Akshay Mohan
    * @description Set the rows
    */
    private void setRows() {
        if (isRecordPage()) {
            Map<String, Schema.SObjectField> fields = objectInfo.fields.getMap();
            for (String fieldName : fields.keySet()) {
                Schema.SObjectField field = fields.get(fieldName);
                Schema.DescribeFieldResult fieldInfo = field.getDescribe();
                this.rows.addRow(new VisualEditor.DataRow(fieldInfo.getLabel()+'('+fieldInfo.getName()+')', fieldInfo.getName()));
            }
        }
    }

    /**
    * @owner Akshay Mohan
    * @description Set the default value
    */
    global override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    /**
    * @owner Akshay Mohan
    * @description Set the picklist
    */
    global override VisualEditor.DynamicPickListRows getValues() {
        return this.rows;
    }
}
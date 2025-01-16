/**
*    @date   18-Jan-20 
*    @description    Wrapper Class for Data Tables
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Akshay                         18-Jan-20           Initial build
*    ------------------------------------------------------------------------------------
*
*/
public class DataTableWrapper {
    public String label,fieldName, type, target='_blank';
    public Boolean sortable=false;
    public Attributes tooltip, typeAttributes;

    /*
     * Constructor
     */
    public class Attributes{
        public String fieldName,iconName,variant,disabled,title,name,label;
    }

    /*
     * Constructor
     */
    public DataTableWrapper(Schema.DescribeFieldResult field){
        label =field.getLabel();
        fieldName = field.getName().removeEnd('__c');
        //type = field.getType();
        tooltip = new Attributes();
        typeAttributes = new Attributes();
    }
}
/**
*    @author Akshay Mohan
*    @date   2020-08-26
*    @description   Logic to show all objects of org
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Jitesh Lakhwani               9-Jan-2023          Code scan fix
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestObjectPickList{
    
    /**
     *  @author Akshay Mohan
     *  @description checkObjectPiclist Test class 
     **/
    @isTest
    public static void checkObjectPiclist(){
        ObjectPickList obj = new ObjectPickList(ObjectPickList.RECORD_PAGE,'Account');
        Test.startTest();
        VisualEditor.DataRow defaultValue = obj.getDefaultValue();
        System.assertEquals('Account',defaultValue.getValue(),'Incorrect object set');
        VisualEditor.DynamicPickListRows rows=obj.getValues();
        System.assertEquals(1,rows.getDataRows().size(),'Incorrect object list returned');
        
        obj = new ObjectPickList('Other','Account');
        defaultValue = obj.getDefaultValue();
        System.assertEquals(null,defaultValue,'Default set when not expected');
        rows=obj.getValues();
        Test.stopTest();
        System.assert(Schema.getGlobalDescribe().values().size() != rows.getDataRows().size(),'All objects not returned');
    }

    /**
     *  @author Akshay Mohan
     *  @description checkFieldPiclist Test class 
     **/
    @isTest
    public static void checkFieldPiclist(){
        ObjectFieldPickList obj = new ObjectFieldPickList(ObjectPickList.RECORD_PAGE,'Account');
        Test.startTest();
        VisualEditor.DataRow defaultValue = obj.getDefaultValue();
        System.assertEquals(null,defaultValue,'Default value set when not expected');
        VisualEditor.DynamicPickListRows rows=obj.getValues();
        Test.stopTest();
        System.assertEquals(Schema.describeSObjects(new List<String>{ 'Account' })[0].fields.getMap().keySet().size(),rows.getDataRows().size(),'All fields not returned');
    }
}
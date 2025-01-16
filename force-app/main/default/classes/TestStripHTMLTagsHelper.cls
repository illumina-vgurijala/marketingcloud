/**
* @author Shivani Jain
* @date 6 April 2022
*
* @description DCP-49914 Test class for Comments
*/ 
@IsTest
private class TestStripHTMLTagsHelper {

    /*******************************************************************************************************
    * @description test method for stripHTMLTags
    */
    static testmethod void stripHTMLTagsTest() {
        StripHTMLTagsHelper.StringWrapper richTextWrapper = new  StripHTMLTagsHelper.StringWrapper();
        richTextWrapper.textVar = '<p><p>This is sample Rich Text</p><br>Inserting a line break</p>';

        Test.startTest();
        List<StripHTMLTagsHelper.StringWrapper> plainTextWrapper = new  List<StripHTMLTagsHelper.StringWrapper>();
        plainTextWrapper = StripHTMLTagsHelper.stripHTMLTags(new List<StripHTMLTagsHelper.StringWrapper>{richTextWrapper});
        Test.stopTest();

        String expectedOutput = 'This is sample Rich Text<p>&nbsp;</p>Inserting a line break';
        System.assert(!plainTextWrapper.isEmpty() && plainTextWrapper[0].textvar == expectedOutput, 'stripHTMLTags failed');
    }
}
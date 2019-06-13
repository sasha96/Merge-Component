/**
*  JIRA        :   https://silverline.jira.com/browse/LIB-636
*  Class name  :   SL_ctrl_MergeAnything_Test
*  Created by  :   Alex Zhurylo
*  Created on  :   4/25/2019
*  Description :   Test class for SL_ctrl_MergeAnything.cls
**/
@isTest
public class SL_ctrl_MergeAnything_Test {
    
    /* 
	* 1) Create Opportunity with name 'OpportunitySpecMerge';
    * 2) Create clone Opportunity with name 'OpportunitySpecMerge clone';
    * 3) Create FeedItem with parentId = Opportunity Clone;
    * 4) Create FeedComment with parentId = Opportunity Clone and FeedItemId with id from step 4;
    * 5) Return Profile Chatter Free User;
    * 6) Create User with returned profile;
    * 7) Create pse__Issue__c with pse__Opportunity__c = oppClone;
	*/
    @TestSetup
    static void setup(){
        
        Opportunity opp = (Opportunity) SL_TestDataFactory.createSObject(new Opportunity(), 'SL_TestDataFactory.OpportunityWithoutPlanDefaults');
            opp.Name = 'OpportunitySpecMerge';
            opp.LastChatterDate__c = DateTime.newInstance(1996, 3, 29, 6, 45, 00);
        insert opp;

        Opportunity oppClone = (Opportunity) SL_TestDataFactory.createSObject(new Opportunity(), 'SL_TestDataFactory.OpportunityWithoutPlanDefaults');
            oppClone.Name = 'OpportunitySpecMerge clone';
        insert oppClone;

        FeedItem itemFeed = (FeedItem) SL_TestDataFactory.createSObject(new FeedItem(), 'SL_TestDataFactory.FeedItemDefaults'); 
            itemFeed.parentId = oppClone.Id;
        insert itemFeed;

        FeedComment commFeed = new FeedComment();
            commFeed.CommentBody = 'comments body';
            commFeed.FeedItemId = itemFeed.Id;
        insert commFeed;

        Profile prof = [SELECT id from profile where name = 'Chatter Free User'];

        User usr = (User) SL_TestDataFactory.createSObject(new User(), 'SL_TestDataFactory.UserDefaults');
            usr.Username = 'testMergeAnything@gmail.com';
            usr.ProfileId = prof.Id;
            usr.Email = 'testMergeAnything@gmail.com';
        insert usr;

        pse__Issue__c issue = new pse__Issue__c();
            issue.pse__Opportunity__c = oppClone.Id;
            issue.pse__Issue_Name__c = 'testIssue';
        insert issue;
    }

    /* 
    * Verify findObjectName method
	* 1) Return Opportunity with Name = 'OpportunitySpecMerge'; 
    * 2) Call findObjectName and pass Opportunity Id;
    * 3) Expected result returned string equals wrapper ListObjectTypeAndIsChatterEnableWrapper 
         that contains Object api name and chatter enable option;
    * 4) Return User with restricted profile;
    * 5) Call findObjectName and pass Opportunity Id for this User;
    * 6) Expected result returned string equals ERROR;
	*/
    @isTest
    static void test_findObjectName() {
        
        Opportunity opp = [SELECT id FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];
        
        String expectedResult = opp.Id.getSObjectType().getDescribe().getName();

        String returnedResult = SL_ctrl_MergeAnything.findObjectName(opp.Id);

        SL_TestDataFactory.softAssertEquals(JSON.serialize(new SL_ctrl_MergeAnything.ListObjectTypeAndIsChatterEnableWrapper(
                                            expectedResult, opp.Id.getSObjectType().getDescribe().isFeedEnabled())), returnedResult);
        
        User usr = [SELECT Id FROM User WHERE Username =: 'testMergeAnything@gmail.com' LIMIT 1];

        System.runAs(usr){
            String expectedResultError = 'ERROR';
            String returnedResultError = SL_ctrl_MergeAnything.findObjectName(opp.Id);
            SL_TestDataFactory.softAssertEquals(expectedResultError, JSON.deserialize(returnedResultError, String.Class));
        } 

        SL_TestDataFactory.hardAssertAllResults();
    }

    /* 
    * Verify getAllValuesFromFieldSet method
	* 1) Return Opportunity with Name = 'OpportunitySpecMerge';
    * 2) Find Opportunity object Api Name;
    * 3) Find List_FieldSet_And_Object__mdt metadate and iterate thougth 
         looking fieldSet that suitable for our api name object;
    * 4) Call getAllValuesFromFieldSet with params(objApiName);
    * 5) Expected result returned String equals serialize string in step 3;
    * 6) Call getAllValuesFromFieldSet with params(null);
    * 7) Expected result returned String equals null;
	*/
    @isTest
    static void test_getAllValuesFromFieldSet(){
        
        Opportunity opp = [SELECT id FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        String fieldSetName = '';
        List_FieldSet_And_Object__mdt[] threatMappings =  [SELECT MasterLabel, QualifiedApiName FROM List_FieldSet_And_Object__mdt];
        for(integer i = 0 ; i < threatMappings.size() ; i++){
            if(objApiName == threatMappings[i].MasterLabel){
                fieldSetName = String.valueOf(threatMappings[i].QualifiedApiName);
            }
        }
        String expectedResult = '';
        if(fieldSetName != ''){
            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objApiName);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
            expectedResult = Json.serialize(fieldSetObj.getFields());
        }

        String returnedResult = SL_ctrl_MergeAnything.getAllValuesFromFieldSet(objApiName);

        SL_TestDataFactory.softAssertEquals(expectedResult, returnedResult);
        
        String returnedResultNull = SL_ctrl_MergeAnything.getAllValuesFromFieldSet('');

        SL_TestDataFactory.softAssertEquals(returnedResultNull, null);

        SL_TestDataFactory.hardAssertAllResults();
    }

    /* 
    * Verify returnObjectsByDefaultName method
	* 1) Return Opportunity with Name = 'OpportunitySpecMerge';
    * 2) Find Opportunity object Api Name;
    * 3) Find all list Opportunity FieldSet and take first one;
    * 4) Iterate througth this field set and find all fieldPath;
    * 5) Search all object that contains Name as returned Opportunity and take their id ;
    * 6) Return List<sObject> with all fields that we find in step 4 and ids from step 5;
    * 7) Iterate througth this list and add every element as ListSerachWrapper;
    * 8) Create expectedResult wrapper add pass List<ListSerachWrapper> from step 7;
    * 9) Call returnObjectsByDefaultName and pass(objApiName, list<String> from step 4, opp.Id);
    * 10) Expected result serialize(list<MainObjNameAndSearchedListWrapper> from step 8) equals string returned from step 9;
	*/
    @isTest
    static void test_returnObjectsByDefaultName(){
        
        Opportunity opp = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objApiName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
		Map<String, Schema.FieldSet> mapFieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
        List<Schema.FieldSetMember> lstFieldSet;
        for (String fieldSetName : mapFieldSetObj.keySet()) {
            lstFieldSet = mapFieldSetObj.get(fieldSetName).getFields();
            break;
        }

        List<String> searchFields = new List<String>();
        for (Integer i = 0; i < lstFieldSet.size(); i++) {
            searchFields.add(lstFieldSet[i].fieldPath);
        }

        String strSosl = 'SELECT Id FROM ' + String.escapeSingleQuotes( objApiName ) + ' WHERE Name LIKE \'%'+ opp.Name  +'%\' LIMIT 20';
        List<sObject> lstSearchResultsAfterSOSL = Database.query(strSosl);

        List<Id> listIds = new List<Id>();
        for (Integer i = 0; i < lstSearchResultsAfterSOSL.size(); i++) {
            listIds.add(lstSearchResultsAfterSOSL[i].Id);
        }

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }
        String oppId = opp.Id;
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objApiName +' WHERE Id IN :listIds AND Id <>:oppId' ;
        
        List<sObject> lstObject = Database.query(soql);
        
        List<SL_ctrl_MergeAnything.ListSerachWrapper> lstWrappers = new List<SL_ctrl_MergeAnything.ListSerachWrapper>();
        for (Integer i = 0; i < lstObject.size(); i++) {
            lstWrappers.add(new SL_ctrl_MergeAnything.ListSerachWrapper(lstObject[i])); 
        }

        String serializeExpectedResult = Json.serialize(lstWrappers);

        String returnedResult = SL_ctrl_MergeAnything.returnObjectsByDefaultName(objApiName, searchFields, opp.Id);

        SL_TestDataFactory.softAssertEquals(serializeExpectedResult, returnedResult);
        SL_TestDataFactory.hardAssertAllResults();
    }

    /* 
    * Verify getListObjectThrougthSearch method
	* 1) Return Opportunity with Name = 'OpportunitySpecMerge';
    * 2) Find Opportunity object Api Name;
    * 3) Find all list Opportunity FieldSet and take first one;
    * 4) Iterate througth this field set and find all fieldPath;
    * 5) Search all object that contains Name as returned Opportunity and take their id ;
    * 6) Return List<sObject> with all fields that we find in step 4 and id from step 5;
    * 7) Iterate througth this list and add every element as ListSerachWrapper;
    * 8) Serialize list from step 7;
    * 9) Call getListObjectThrougthSearch and pass(opp.Name, objApiName, list<String> from step 4, opp.Id);
    * 10) Expected result string from step 7 equals string returned from step 9;
	*/
    @isTest
    static void test_getListObjectThrougthSearch(){

        Opportunity opp = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objApiName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
		Map<String, Schema.FieldSet> mapFieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
        List<Schema.FieldSetMember> lstFieldSet;
        for (String fieldSetName : mapFieldSetObj.keySet()) {
            lstFieldSet = mapFieldSetObj.get(fieldSetName).getFields();
            break;
        }

        List<String> searchFields = new List<String>();
        for (Integer i = 0; i < lstFieldSet.size(); i++) {
            searchFields.add(lstFieldSet[i].fieldPath);
        }

        String strSosl = 'SELECT Id FROM ' + String.escapeSingleQuotes( objApiName ) + ' WHERE Name LIKE \'%'+ opp.Name +'%\' LIMIT 20';
        List<sObject> lstSearchResultsAfterSOSL = Database.query(strSosl);

        List<Id> listIds = new List<Id>();
        for (Integer i = 0; i < lstSearchResultsAfterSOSL.size(); i++) {
            listIds.add(lstSearchResultsAfterSOSL[i].Id);
        }

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }
        String oppId = opp.Id;
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objApiName +' WHERE Id IN :listIds AND Id <>:oppId' ;
        
        List<sObject> lstObject = Database.query(soql);
        
        List<SL_ctrl_MergeAnything.ListSerachWrapper> lstWrappers = new List<SL_ctrl_MergeAnything.ListSerachWrapper>();
        for (Integer i = 0; i < lstObject.size(); i++) {
            lstWrappers.add(new SL_ctrl_MergeAnything.ListSerachWrapper(lstObject[i])); 
        }

        String serializeExpectedResult = Json.serialize(lstWrappers);

        String returnedResult = SL_ctrl_MergeAnything.getListObjectThrougthSearch(opp.Name, objApiName, searchFields, opp.Id);

        SL_TestDataFactory.softAssertEquals(serializeExpectedResult, returnedResult);
        SL_TestDataFactory.hardAssertAllResults();
    }

    /* 
    * Verify findAllValuesForSelectedObjects method
	* 1) Return Opportunities with Name = 'OpportunitySpecMerge' and 'OpportunitySpecMerge clone';
    * 2) Find Opportunity object Api Name;
    * 3) Find all list Opportunity FieldSet and take first one;
    * 4) Prepare 3 query for select all fields FROM main object, main object without relationship fields, and selected objects;
    * 5) Create list<SL_ctrl_MergeAnything.RowWrapper> and iterate in all fields find where field type = REFERENCE,
            find all apiname and labels for mapFieldsLabelAndApiNew ;
    * 6) Create SL_ctrl_MergeAnything.AllFieldsAndValuesWrapper  and add (mapFieldsLabelAndApiNew, lstMainObjWithValuesWithoutRelationship, lstRows, lstObjectNames);
    * 7) Serialize wrapper from step 6;
    * 8) Call findAllValuesForSelectedObjects and pass(list ids, object Api Name, opportunity id);
    * 9) Expected result String from step 7 equals String from step 8;
	*/
    @isTest
    static void test_findAllValuesForSelectedObjects(){

        Opportunity opp = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];
        Opportunity oppClone = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge clone' LIMIT 1];

        List<Id> lstIds = new List<Id>();
        lstIds.add(opp.Id);
        lstIds.add(oppClone.Id);

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        Map<String, Schema.SObjectField> mapAllobjectFields = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();

        Map<String, String> mapFieldsLabelAndApi  = new  Map<String, String>();

        String query = 'SELECT ';
        String queryWithoutRelationShip = 'SELECT ';

        for(String s : mapAllobjectFields.keySet()) {
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable()){
                query += ' ' + s + ',';
                queryWithoutRelationShip += ' ' + s + ',';
                
                Schema.DisplayType dType = mapAllobjectFields.get(s).getDescribe().getType();
                if(dType == Schema.DisplayType.REFERENCE) {
                    query += ' ' + mapAllobjectFields.get(s).getDescribe().getRelationshipName() + '.Name , ';
                }

                mapFieldsLabelAndApi.put(s, mapAllobjectFields.get(s).getDescribe().getLabel());
            }
        }

        if (query.subString(query.Length()-1,query.Length()) == ','){
            query = query.subString(0,query.Length()-1);
        }

        if (queryWithoutRelationShip.subString(queryWithoutRelationShip.Length()-1,queryWithoutRelationShip.Length()) == ','){
            queryWithoutRelationShip = queryWithoutRelationShip.subString(0,queryWithoutRelationShip.Length()-1);
        }
        
        String recordId = opp.Id;
        String queryForMain = query;
        queryForMain += ' FROM ' + objApiName + ' WHERE Id =: recordId';
        queryWithoutRelationShip += ' FROM ' + objApiName + ' WHERE Id =: recordId';
        query += ' FROM ' + objApiName + ' WHERE Id IN :lstIds';

        List<sObject> lstMainObjWithValues = database.query(queryForMain);
        List<sObject> lstMainObjWithValuesWithoutRelationship = database.query(queryWithoutRelationShip);
        List<sObject> lstObjWithothoutMainValues  = database.query(query);
        
        List<sObject> lstObjWithValues = new  List<sObject> ();
        lstObjWithValues.add(lstMainObjWithValues[0]);
        for (Integer i = 0; i < lstObjWithothoutMainValues.size(); i++) {
            lstObjWithValues.add(lstObjWithothoutMainValues[i]);
        }

        List<Object> lstObjectNames = new List<Object>();
        for (Integer i = 0; i < lstObjWithValues.size(); i++) {
            sObject sob = lstObjWithValues[i];
            lstObjectNames.add(sob.get('Name'));
        }  

        Map<String, String> mapFieldsLabelAndApiNew  = new  Map<String, String>();
        
        list<SL_ctrl_MergeAnything.RowWrapper> lstRows = new list<SL_ctrl_MergeAnything.RowWrapper>();
        SL_ctrl_MergeAnything.RowWrapper row;
        list<SL_ctrl_MergeAnything.FieldWrapper> fieldWrapper;
        for(String s : mapAllobjectFields.keySet()) {
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable()){
                Integer isAllValueEmpty = 0;
                for (Integer i = 0; i < lstObjWithValues.size(); i++) {
                    sObject sob = lstObjWithValues[i];
                    if(sob.get(s) == null){
                        isAllValueEmpty++;
                    }
                }
                if(isAllValueEmpty != lstObjWithValues.size()){
                    Schema.DisplayType dType = mapAllobjectFields.get(s).getDescribe().getType();
                    
                    row = new SL_ctrl_MergeAnything.RowWrapper();
                    row.title = mapAllobjectFields.get(s).getDescribe().getLabel();
                    
                    fieldWrapper = new list<SL_ctrl_MergeAnything.FieldWrapper>();

                    for (Integer i = 0; i < lstObjWithValues.size(); i++) {
                        sObject sob = lstObjWithValues[i];
                        Object recordIdChildren = sob.get(s);
                        String childName = null;
                        if(dType == Schema.DisplayType.REFERENCE && recordIdChildren != null) {
                            childName = String.valueOf(sob.getSobject(mapAllobjectFields.get(s).getDescribe().getRelationshipName()).get('Name'));
                        }else if(dType == Schema.DisplayType.DATETIME){
                            childName = 'DATETIME';
                        }

                        fieldWrapper.add(new SL_ctrl_MergeAnything.FieldWrapper(String.valueOf(mapAllobjectFields.get(s)), sob.get(s), false,
                                                    String.valueOf(mapAllobjectFields.get(s).getDescribe().getType()), sob.Id, childName ));   

                        mapFieldsLabelAndApiNew.put(s, mapFieldsLabelAndApi.get(s));
                    }

                    row.lstFields = fieldWrapper;
                    lstRows.add(row);
                }
            }
        }
        SL_ctrl_MergeAnything.AllFieldsAndValuesWrapper wrapper = new SL_ctrl_MergeAnything.AllFieldsAndValuesWrapper( mapFieldsLabelAndApiNew, lstMainObjWithValuesWithoutRelationship, lstRows, lstObjectNames);

        String serializeExpectedResult = Json.serialize(wrapper);

        String returnedResult = SL_ctrl_MergeAnything.findAllValuesForSelectedObjects(lstIds, objApiName, opp.Id);

        SL_TestDataFactory.softAssertEquals(serializeExpectedResult, returnedResult);

        SL_TestDataFactory.hardAssertAllResults();
    }

    /* 
    * Verify getSurvivedObjectValuesAndLabels method
	* 1) Return Opportunity with Name = 'OpportunitySpecMerge';
    * 2) Find Opportunity object Api Name;
    * 3) Find list<fields> of opportunity;
    * 4) Select everything from opporunity;
    * 5) Create List<ApiNameAndValueWrapperForThirdPage> and add value of main object and label of fields;
    * 6) Call getSurvivedObjectValuesAndLabels and pass Opportunity obj from step 1 and map of fields and api from step 4, and object api name;
    * 7) Expected result deserialized List<ApiNameAndValueWrapperForThirdPage> from step 6 equals to list from step 6l
	*/
    @isTest
    static void test_getSurvivedObjectValuesAndLabels(){

        Opportunity opp = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        list<String> searchFields = new List<String>();

        Map<String, Schema.SObjectField> mapAllobjectFields = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();

        List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage> lstApiNameAndFields = new List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage>();
        for(String s : mapAllobjectFields.keySet()) {
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable()){
                lstApiNameAndFields.add(new SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage(mapAllobjectFields.get(s).getDescribe().getLabel(), s));
                searchFields.add(s);
            }
        }

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }

        String oppId = opp.Id;
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objApiName +' WHERE Id =: oppId' ;
        
        List<sObject> lstObject = Database.query(soql);

        List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage> lstLabelsAndValuesSurviedObject = new List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage>();

        for (Integer i = 0; i < lstApiNameAndFields.size(); i++) {
            lstLabelsAndValuesSurviedObject.add(new SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage(
                String.valueOf(lstObject[0].get(lstApiNameAndFields[i].key)),lstApiNameAndFields[i].value, objApiName)
            );
        }

        String returnedResult =  SL_ctrl_MergeAnything.getSurvivedObjectValuesAndLabels(JSON.serialize(lstObject), JSON.serialize(lstApiNameAndFields), objApiName );
        
        List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage> returnedResultDeserialize = 
            (List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage>)System.JSON.deserialize(returnedResult, List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage>.class);  

        SL_TestDataFactory.softAssertEquals(lstLabelsAndValuesSurviedObject.size(), returnedResultDeserialize.size());

        SL_TestDataFactory.hardAssertAllResults();
    }
    
    /* 
    * Verify mergeObjectAndChildrenObjects method
	* 1) Return Opportunities with Name = 'OpportunitySpecMerge' and 'OpportunitySpecMerge clone';
    * 2) Find Opportunity object Api Name;
    * 3) Return pse__Issue__c with pse__Opportunity__c = oppClone;
    * 4) Check that list From step 3 != null; 
    * 5) Prepare data and select All fields From Opportunity;
    * 6) Return all FeedItems and FeedComments where parentID OpportunitySpecMerge Clone;
    * 7) Expected result every list equals 1;
    * 8) Call mergeObjectAndChildrenObjects and pass Opportunity Id, Opportunity api name list that contains Opportunity Clone id, 
            true => merge children records, and object with all fields and values from step 5;
    * 9) Return list Opportunity with name OpportunitySpecMerge clone;
    * 10) Expected result list.size() == 0;
    * 11) Return pse__Issue__c that changed owner. New pse__Opportunity__c must be the same as Opportunity.Id;
    * 12) Return all FeedItems and FeedComments where parentID OpportunitySpecMerge Clone. Expected result 0;
    * 13) Return all FeedItems and FeedComments where parentID OpportunitySpecMerge. Expected result 1;       
	*/
    @isTest
    static void test_mergeObjectAndChildrenObjects(){

        Opportunity opp = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge' LIMIT 1];

        String objApiName = opp.Id.getSObjectType().getDescribe().getName();

        Opportunity oppClone = [SELECT id, Name FROM Opportunity WHERE Name = 'OpportunitySpecMerge clone' LIMIT 1];

        pse__Issue__c issue = [SELECT id, pse__Opportunity__c FROM pse__Issue__c WHERE pse__Opportunity__c =: oppClone.Id LIMIT 1];
        SL_TestDataFactory.softAssertNotEquals(null, issue);
        SL_TestDataFactory.softAssertEquals(oppClone.Id, issue.pse__Opportunity__c);

        List<String> lstAllObjIdsWithoutMain = new List<String>();
        lstAllObjIdsWithoutMain.add(oppClone.Id);

        list<String> searchFields = new List<String>();

        Map<String, Schema.SObjectField> mapAllobjectFields = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();

        List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage> lstApiNameAndFields = new List<SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage>();
        for(String s : mapAllobjectFields.keySet()) {
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable()){
                lstApiNameAndFields.add(new SL_ctrl_MergeAnything.ApiNameAndValueWrapperForThirdPage(mapAllobjectFields.get(s).getDescribe().getLabel(), s));
                searchFields.add(s);
            }
        }

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }

        String oppId = opp.Id;
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objApiName +' WHERE Id =: oppId' ;
        
        List<sObject> lstObject = Database.query(soql);
        
        List<FeedItem> lstFeedItems = [SELECT Id, body FROM FeedItem 
                                        WHERE ParentId =: oppClone.Id ];
        List<FeedComment> lstFeedCommets = [SELECT Id, CommentBody, FeedItemId, parentId 
                                            FROM FeedComment WHERE ParentId =: oppClone.Id ];
        SL_TestDataFactory.softAssertEquals(lstFeedItems.size(), 1);
        SL_TestDataFactory.softAssertEquals(lstFeedCommets.size(), 1);

        Test.startTest();
        
        SL_ctrl_MergeAnything.mergeObjectAndChildrenObjects(opp.Id, objApiName, lstAllObjIdsWithoutMain, true, JSON.serialize(lstObject), true);

        List<Opportunity> lstOppClone = [SELECT id FROM Opportunity WHERE Name = 'OpportunitySpecMerge clone' ];
        SL_TestDataFactory.softAssertEquals(lstOppClone.size(), 0);

        issue = [SELECT id, pse__Opportunity__c FROM pse__Issue__c WHERE pse__Opportunity__c =: opp.Id LIMIT 1];
        SL_TestDataFactory.softAssertEquals(opp.Id, issue.pse__Opportunity__c);
        
        Test.stopTest();
        
        lstFeedItems = [SELECT Id, body FROM FeedItem 
                                        WHERE ParentId =: oppClone.Id ];
        lstFeedCommets = [SELECT Id, CommentBody, FeedItemId, parentId 
                                            FROM FeedComment WHERE ParentId =: oppClone.Id ];
        SL_TestDataFactory.softAssertEquals(lstFeedItems.size(), 0);
        SL_TestDataFactory.softAssertEquals(lstFeedCommets.size(), 0);


        lstFeedItems = [SELECT Id, body FROM FeedItem 
                                        WHERE ParentId =: opp.Id ];
        lstFeedCommets = [SELECT Id, CommentBody, FeedItemId, parentId 
                                            FROM FeedComment WHERE ParentId =: opp.Id ];
        SL_TestDataFactory.softAssertEquals(lstFeedItems.size(), 1);
        SL_TestDataFactory.softAssertEquals(lstFeedCommets.size(), 1);

        SL_TestDataFactory.hardAssertAllResults();
    }
}
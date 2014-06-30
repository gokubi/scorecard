@IsTest
public class TEST_Scorecard {

 static testMethod void TestFillPreviousScores() {
        Scorecard_Entry__c topLevel1 = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric__c = 'Top Level Metric',
            Metric_Type__c = 'Test',
            Scorecard_SORT_ORDER__c = 1
        );
        insert topLevel1;
        Scorecard_Entry__c topLevel2 = new Scorecard_Entry__c(
            Name = 'Top Level 2',
            Metric__c = 'Top Level 2',
            Metric_Type__c = 'Test',
            Scorecard_SORT_ORDER__c = 2 
        );
        insert topLevel2;
        Scorecard_Entry__c secondLevel1m10 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Amount__c = 1.23,
            Scorecard_Date__c = system.today().addMonths(-10),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1m10;
        Scorecard_Entry__c secondLevel1m20 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today().addMonths(-20),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1m20;
        Scorecard_Entry__c secondLevel2m14 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Number__c = 12345,
            Scorecard_Date__c = system.today().addMonths(-14),
            Scorecard_SORT_ORDER__c = 4     
        );
        insert secondLevel2m14;
        Scorecard_Entry__c secondLevel1m2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Bogus',   // should not matter
            Parent__c = topLevel1.id,
            Actual_Amount__c = 123456,
            Scorecard_Date__c = system.today().addMonths(-2),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1m2;
        Scorecard_Entry__c secondLevel2m2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Number__c = 123,
            Scorecard_Date__c = system.today().addMonths(-2),
            Scorecard_SORT_ORDER__c = 4     
        );
        insert secondLevel2m2;
        Scorecard_Entry__c secondLevel1 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Amount__c = 1,
            Scorecard_Date__c = system.today().addMonths(-1),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1;
        Scorecard_Entry__c secondLevel2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Number__c = 1234567,
            Scorecard_Date__c = system.today().addMonths(-1),
            Scorecard_SORT_ORDER__c = 4     
        );
        insert secondLevel2;
        Scorecard_Entry__c thirdLevelm2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Third Level Metric for Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = secondLevel1m2.id,
            Actual_Amount__c = 12,
            Scorecard_Date__c = system.today().addMonths(-2),
            Scorecard_SORT_ORDER__c = 5     
        );
        insert thirdLevelm2;
        Scorecard_Entry__c thirdLevel = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Third Level Metric for Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = secondLevel1.id,
            Actual_Amount__c = 12345678,
            Scorecard_Date__c = system.today().addMonths(-1),
            Scorecard_SORT_ORDER__c = 5     
        );
        insert thirdLevel;
        
        // need to query for the keys
        list<Scorecard_Entry__c> seList = 
            [select id, Scorecard_Date__c, Metric_Unique_Key__c, Previous_Values_JSON__c,
                Previous_Amount__c, Previous_Number__c, Previous_Percent__c
                from Scorecard_Entry__c where id 
                in : (new set<id> { 
                    topLevel1.id, topLevel2.id, secondLevel1m10.id, secondLevel1m20.id, secondLevel2m14.id, 
                    secondLevel1m2.id, secondLevel2m2.id, secondLevel1.id, secondLevel2.id, thirdLevel.id }) 
            ];
        
        // run the utility method to fill previous values
        ScorecardUtil util = new ScorecardUtil();
        util.fillPreviousMetricValues( seList );

        map<id, Scorecard_Entry__c> seMap = new map<id, Scorecard_Entry__c>( seList );

        // did it work?
        system.assertEquals( null, seMap.get(topLevel1.id).Previous_Values_JSON__c );
        system.assertEquals( null, seMap.get(topLevel2.id).Previous_Values_JSON__c );
        system.assertEquals( null, seMap.get(secondLevel1m20.id).Previous_Values_JSON__c );
        system.assertEquals( null, seMap.get(secondLevel2m14.id).Previous_Values_JSON__c );
        system.assertEquals( 1234, seMap.get(secondLevel1m10.id).Previous_Amount__c );
        system.assertEquals( 1.23, seMap.get(secondLevel1m2.id).Previous_Amount__c );
        system.assertEquals( 12345, seMap.get(secondLevel2m2.id).Previous_Number__c );
        system.assertEquals( 123456, seMap.get(secondLevel1.id).Previous_Amount__c );
        system.assertEquals( 123, seMap.get(secondLevel2.id).Previous_Number__c );
        system.assertEquals( 12, seMap.get(thirdLevel.id).Previous_Amount__c );

        // JSON should have two entries
        system.debug(logginglevel.WARN, secondLevel1.Previous_Values_JSON__c);
        system.assert( seMap.get(secondLevel1.id).Previous_Values_JSON__c.contains(secondLevel1m10.Id) );
        system.assert( seMap.get(secondLevel1.id).Previous_Values_JSON__c.contains(secondLevel1m2.Id) );
    }

    static testMethod void TestBatch() {
        Scorecard_Entry__c topLevel1 = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric__c = 'Top Level',
            Metric_Type__c = 'Test',
            Scorecard_SORT_ORDER__c = 1
        );
        insert topLevel1;
        Scorecard_Entry__c secondLevel1m2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Bogus',   // should not matter
            Actual_Amount__c = 123456,
            Parent__c = topLevel1.id,
            Scorecard_Date__c = system.today().addMonths(-2),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1m2;
        Scorecard_Entry__c secondLevel1 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Test',
            Actual_Amount__c = 1,
            Scorecard_Date__c = system.today().addMonths(-1),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1;

        // name and amount will be wrong after this
        secondLevel1.Parent__c = topLevel1.id;
        update secondLevel1; 
        topLevel1.Metric__c = 'Top Level Metric';
        update topLevel1;

        Scorecard_Entry__c[] check1 = [select id, name, Previous_Amount__c from Scorecard_Entry__c where id = : secondLevel1.id];
        system.assert( !check1[0].name.startsWith('Top Level Metric - Child Metric 1 - ' ));
        system.assertEquals( null, check1[0].Previous_Amount__c );

        Test.startTest();
        ScorecardUtil.fixAllData();
        Test.stopTest();

        Scorecard_Entry__c[] check2 = [select id, name, Previous_Amount__c from Scorecard_Entry__c where id = : secondLevel1.id];
        system.assert( check2[0].name.startsWith('Top Level Metric - Child Metric 1 - ' ));
        system.assertEquals( 123456, check2[0].Previous_Amount__c );
    }
    /*
     static testMethod void RemoteUpdate(){
        Scorecard_Entry__c entry = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric_Type__c = 'Test'
        );
        insert entry;
        
        entry.Scorecard_Date__c = system.today();
        entry.Actual_Amount__c = 123;
//      String js = JSON.serialize( entry );
        saveEntry( entry );

        Scorecard_Entry__c[] se = [select id, name, Scorecard_Date__c from Scorecard_Entry__c 
            where id = : entry.id];
        system.assertEquals(system.today(), se[0].Scorecard_Date__c);       
    }
    */

    static testMethod void Naming(){
        Scorecard_Entry__c parent = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric_Type__c = 'Test'
        );
        insert parent;
        Scorecard_Entry__c childActive = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Test1',
            Metric_Type__c = 'Test',
            Parent__c = parent.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today().addMonths(-7)
        );
        insert childActive;
        Scorecard_Entry__c childActive2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Test2',
            Metric_Type__c = 'Test',
            Parent__c = childActive.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today().addMonths(-7)        
        );
        insert childActive2;

        Scorecard_Entry__c[] se = [select id, name from Scorecard_Entry__c 
            where id = :parent.id or id=:childActive.id or id=:childActive2.id order by createddate];
        system.assertEquals('Parent Entry', se[0].name);
        system.assert(se[1].name.startsWith('Parent Entry - Test1'));
        system.debug(loggingLevel.WARN, se[2].name);
        system.assert(se[2].name.startsWith('Parent Entry - Test1 - Test2'));
    }   
    
    static testMethod void BuildThoseRows(){
        Scorecard_Entry__c parent = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric__c = 'Big Metric',
            Metric_Type__c = 'Test' 
        );
        insert parent;
        Scorecard_Entry__c childActive = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Big Child Metric',
            Metric_Type__c = 'Test',
            Parent__c = parent.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today()      
        );
        insert childActive;
        Scorecard_Entry__c childActive2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Big Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = parent.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today()      
        );
        insert childActive2;
        Scorecard_Entry__c parent2 = new Scorecard_Entry__c(
            Name = 'Parent Entry 2',
            Scorecard_Date__c = system.today().addmonths(-3)        
        );
        insert parent2;
        Scorecard_Entry__c childActive3 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Big Child Metric for Parent 2',
            Metric_Type__c = 'Test',
            Parent__c = parent2.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today().addmonths(-3)        
        );
        insert childActive3;
        Scorecard_Entry__c childActive4 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Big Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = parent2.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today()
        );
        insert childActive4;
        childActive.Parent__c = parent2.id;
        update ChildActive;
        FeedItem fitem = new FeedItem(
            body = 'this is an #update',
            parentID = parent.id
        );
        insert fitem;
        
        list<Profile> profiles = [select id from Profile where name = 'System Administrator'];
        id myProfileID = profiles[0].id;
        
        User myUser;
        User adminUser = [select id from user where profileid = : myProfileID and isActive = true limit 1];
        system.runAs(adminUser){
            myUser = new User(
                username = 'testuser@salesforcefoundation.org.tests',
                email = 'testuser@salesforcefoundation.org.tests',
                firstname = 'Testy',
                lastname = 'McTester',
                profileID = myProfileID,
                alias = 'tifbs',
                emailencodingkey='UTF-8',
                languagelocalekey='en_US',
                localesidkey='en_US',
                timezonesidkey='America/Los_Angeles');
            insert myUser;
        }
        
        system.runAs(myUser){
            System.currentPageReference().getParameters().put('filter', 'Test');
            ScorecardController controller = new ScorecardController();
            system.debug(controller.entryMap);
            system.assertEquals(5, controller.allRows.size());
            system.assertEquals(2, controller.rowMap.get(parent2.id).childRows.size());
            system.assertEquals(1, controller.rowMap.get(parent.id).childRows.size());
            system.assertEquals('this is an #update', controller.rowMap.get(parent.id).post.body);
           // system.assertEquals(URL.getSalesforceBaseUrl().toExternalForm(), controller.baseURL);
            system.assertEquals('Test', controller.filter);

            String d = string.valueOf(system.today().addmonths(-3).month()) + '-' + string.valueOf(system.today().addmonths(-3).year());
            System.currentPageReference().getParameters().put('timeframe', d);
            controller = new ScorecardController();
            system.assertEquals(3, controller.allRows.size());

            System.currentPageReference().getParameters().put('timeframe', 'bogus');
            controller = new ScorecardController();
            system.assertEquals(5, controller.allRows.size());

            childActive.Scorecard_Date__c = system.today().addmonths(-3);       
            update ChildActive;

            controller = new ScorecardController();
            system.assertEquals(4, controller.allRows.size());
        }       
    }

    static testMethod void ThirdLevelChild(){
        Scorecard_Entry__c topLevel1 = new Scorecard_Entry__c(
            Name = 'Parent Entry',
            Metric__c = 'Top Level Metric',
            Metric_Type__c = 'Test',
            Scorecard_SORT_ORDER__c = 1
        );
        insert topLevel1;
        Scorecard_Entry__c topLevel2 = new Scorecard_Entry__c(
            Name = 'Top Level 2',
            Metric__c = 'Top Level 2',
            Metric_Type__c = 'Test',
            Scorecard_SORT_ORDER__c = 2 
        );
        insert topLevel2;
        Scorecard_Entry__c secondLevel1 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today(),
            Scorecard_SORT_ORDER__c = 3     
        );
        insert secondLevel1;
        Scorecard_Entry__c secondLevel2 = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Child Metric 2',
            Metric_Type__c = 'Test',
            Parent__c = topLevel1.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today(),
            Scorecard_SORT_ORDER__c = 4     
        );
        insert secondLevel2;
        Scorecard_Entry__c thirdLevel = new Scorecard_Entry__c(
            Name = 'Child Entry',
            Metric__c = 'Third Level Metric for Child Metric 1',
            Metric_Type__c = 'Test',
            Parent__c = secondLevel1.id,
            Actual_Amount__c = 1234,
            Scorecard_Date__c = system.today(),
            Scorecard_SORT_ORDER__c = 5     
        );
        insert thirdLevel;
        
        list<Profile> profiles = [select id from Profile where name = 'System Administrator'];
        id myProfileID = profiles[0].id;
        
        User myUser;
        User adminUser = [select id from user where profileid = : myProfileID and isActive = true limit 1];
        system.runAs(adminUser){
            myUser = new User(
                username = 'testuser@salesforcefoundation.org.tests',
                email = 'testuser@salesforcefoundation.org.tests',
                firstname = 'Testy',
                lastname = 'McTester',
                profileID = myProfileID,
                alias = 'tifbs',
                emailencodingkey='UTF-8',
                languagelocalekey='en_US',
                localesidkey='en_US',
                timezonesidkey='America/Los_Angeles');
            insert myUser;
        }
        
        system.runAs(myUser){
            System.currentPageReference().getParameters().put('filter', 'Test');
            ScorecardController controller = new ScorecardController();
            system.debug(controller.entryMap);
            system.assertEquals(5, controller.allRows.size());
            system.assertEquals(2, controller.rowMap.get(topLevel1.id).childRows.size());
            system.assertEquals(0, controller.rowMap.get(topLevel2.id).childRows.size());
            system.assertEquals(1, controller.rowMap.get(secondLevel1.id).childRows.size());
            system.assertEquals(0, controller.rowMap.get(secondLevel2.id).childRows.size());
            system.assertEquals(topLevel1.metric__c, controller.allRows[0].entry.metric__c);
            system.assertEquals(secondLevel1.metric__c, controller.allRows[1].entry.metric__c);
            system.assertEquals(thirdLevel.metric__c, controller.allRows[2].entry.metric__c);
            system.assertEquals(secondLevel2.metric__c, controller.allRows[3].entry.metric__c);
            system.assertEquals(topLevel2.metric__c, controller.allRows[4].entry.metric__c);
        }
    }
    
   }
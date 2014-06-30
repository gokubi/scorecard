public without sharing class ScorecardController {
/*
** VF Controller for the Metrics Scorecard page
** Displays and edits a hierarchical list of performance metrics, along with associated chatter posts
**
** Written by Nick Bailey and Evan Callahan
** Copyright (c) 2012 Salesforce.com Foundation
**
*/  

    public class parentEntry{}  // apex will not let me delete this line!

    public class ScorecardRow {
        public Scorecard_Entry__c entry {get;set;}
        public list<ScorecardRow> childRows {get;private set;}
        public Integer level {get;private set;}
        public FeedItem post {get;set;}
        public User postUser {get;set;}
        public String entryType {get;set;}
        public String category {get;set;}
        public Boolean isKey {get;set;}

        public ScorecardRow(ScorecardController psc, Scorecard_Entry__c se, Integer lvl, String cat, Boolean key) {
            entry = se;
            level = lvl;
            category = cat;
            isKey = key;
            childRows = new list<ScorecardRow>();
            if (se.Child_Entries__r != null ) {
                for (Scorecard_Entry__c child : se.Child_Entries__r) {
                    if (psc.entryMap.containsKey( child.Id )) {
                        ScorecardRow row = new ScorecardRow( psc, psc.entryMap.get( child.Id ), level + 1, category, isKey );
                        childRows.add( row );
                        psc.rowMap.put( child.Id, row );
                    }
                }
            }
            entryType = 
                (se.Forecast_Percent__c != null || se.Actual_Percent__c != null) ? 'percent' :
                (se.Forecast_Amount__c != null || se.Actual_Amount__c != null) ? 'currency' :
                'number';           
        }
    }

    // these are for internal use while setting up
    private list<Scorecard_Entry__c> entries = new list<Scorecard_Entry__c>();
    public map<id, Scorecard_Entry__c> entryMap = new map<id, Scorecard_Entry__c>();
    public map<id, ScorecardRow> rowMap = new map<id, ScorecardRow>();
    public set<String> filterSet = new set<String>();
    private boolean weHaveKeyMetrics = false;

    // these get used on the page
    public list<ScorecardRow> allRows {get;set;}
    public Boolean userCanEdit {get; private set;}  
    public list<SelectOption> filterOptions {get; private set;}   // UNDONE: change from selectoption
    public list<SelectOption> monthOptions {get; private set;}   // UNDONE: change from selectoption
    public String filter {get;set;}
    public String timeframe {get;set;}
    private Date startDate;

    public static String baseURL {get{return URL.getSalesforceBaseUrl().toExternalForm();}}
    
    public ScorecardController() {
        try {
            fillTimeframeList();        
            getAllData();
            createScorecardRows();
            arrangeEntries();
            getChatter();
            fillFilterList();
        } catch(exception e) { 
        Apexpages.addMessage( new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + '\n' + e.getStackTraceString()) ); 
        }
    }
    
    public void fillTimeframeList() {
        // get the timeframe parameter, if any
        String tfParam = ApexPages.CurrentPage().getParameters().get('timeframe');

        // query for all available dates
        monthOptions = new list<SelectOption>();
        for (sObject agg : [select calendar_year(Scorecard_Date__c) yr, calendar_month(Scorecard_Date__c) mth 
                from Scorecard_Entry__c group by calendar_year(Scorecard_Date__c), calendar_month(Scorecard_Date__c) 
                having calendar_year(Scorecard_Date__c) > : (system.today().year() - 3) 
                order by calendar_year(Scorecard_Date__c) desc, calendar_month(Scorecard_Date__c) desc]) {

            Integer y = (integer)(agg.get('yr'));
            Integer m = (integer)(agg.get('mth'));
            Datetime d = Datetime.NewInstance(y, m, 1, 0, 0, 0);
            String k = String.valueOf(m) + '-' + String.valueOf(y);
            String v = d.format('MMMM yyyy');
            monthOptions.add(new SelectOption(k, v));

            // select this option in the timeframe box if it was in the URL or is the first of this month
            if ( tfParam == k || (startDate == null && d < system.now()) ) {
                startDate = Date.NewInstance(y, m, 1);       
                timeframe = k;
            }
       }
    }

    public void getAllData(){

        // start date should already be set
        Date endDate = startDate.addMonths(1);

        // first get all the parent ids so we can be sure not to filter them out
        set<id> parentIds = new set<id>();
        list<Scorecard_Entry__c> seList =   
            [select Id, Parent__c, 
                    Parent__r.Parent__c, 
                    Parent__r.Parent__r.Parent__c,
                    Parent__r.Parent__r.Parent__r.Parent__c,
                    Parent__r.Parent__r.Parent__r.Parent__r.Parent__c
                from Scorecard_Entry__c                 
                where (Omit_from_Scorecard__c = False AND ((Scorecard_Date__c = Null AND Parent__c = Null) OR 
                    (Scorecard_Date__c >= : startDate AND Scorecard_Date__c < : endDate))) LIMIT 1000];

        for (Scorecard_Entry__c se : seList) {
            parentIds.add(se.Parent__c);
            parentIds.add(se.Parent__r.Parent__c);
            parentIds.add(se.Parent__r.Parent__r.Parent__c);
            parentIds.add(se.Parent__r.Parent__r.Parent__r.Parent__c);
            parentIds.add(se.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c);
        }

        entries =
            [select Id, OwnerId, Name, CurrencyIsoCode, Scorecard_Date__c, Metric_Type__c, Entry_Color__c, 
                Forecast_Percent__c, Actual_Percent__c, Forecast_Number__c, Actual_Number__c, Forecast_Amount__c, 
                Actual_Amount__c, Goal_Type__c, Source__c, Source_Link__c, Metric__c, Description__c,
                Previous_Percent__c, Previous_Number__c, Previous_Amount__c, Change_Indicator__c, Key_Metric__c,
                Change_from_Previous__c, Percent_Change__c, Percent_of_Goal__c, Previous_Values_JSON__c,
                Parent__c, (select id from Child_Entries__r order by Scorecard_SORT_ORDER__c ASC NULLS LAST, 
                    Scorecard_Date__c ASC NULLS LAST, createdDate) 
                from Scorecard_Entry__c                 
                where (Omit_from_Scorecard__c = False AND ((Scorecard_Date__c = Null AND Parent__c = Null) OR 
                    (Scorecard_Date__c >= : startDate AND Scorecard_Date__c < : endDate))) OR Id in :parentIds
                order by Scorecard_SORT_ORDER__c ASC NULLS LAST, Scorecard_Date__c ASC NULLS LAST, createdDate LIMIT 1000];

        // system.debug(loggingLevel.WARN,entries);
        if (entries.size() > 0) {
            entryMap.putAll( entries );
        }
    }
    
    public void createScorecardRows(){
        // add all the top level entries, which recursively adds the lower level ones
        for (Scorecard_Entry__c entry : entries) {
            if (entry.parent__c == null) {
                ScorecardRow thisRow = new ScorecardRow(this, entry, 0, entry.Metric_Type__c, entry.Key_Metric__c);
                //system.debug(loggingLevel.warn, thisRow.entry.name);              
                rowMap.put(entry.id, thisRow);
                if (entry.Key_Metric__c) 
                    weHaveKeyMetrics = true;
            }
            // create filter lists
            if (entry.Metric_Type__c != null) 
                filterSet.add(entry.Metric_Type__c);
        }
        //system.debug(loggingLevel.WARN, rowMap);
    }

    public void arrangeEntries(){
        // now put them all into the list in the proper order
        allRows = new list<ScorecardRow>();
        for (Scorecard_Entry__c entry : entries) {
            if (entry.Parent__c == null) {
                ScorecardRow parentRow = rowMap.get(entry.id);
                allRows.add(parentRow);
                //system.debug(loggingLevel.WARN, 'adding ' + parentRow.entry.Metric__c);
                arrangeChildEntries(parentRow);
            }
        }
        //system.debug(loggingLevel.WARN, allRows);
    }
    
    public void arrangeChildEntries(ScorecardRow parentRow){

        for (ScorecardRow row : parentRow.childRows) {
            allRows.add(row);
            //system.debug(loggingLevel.WARN, 'adding ' + row.entry.Metric__c);
            arrangeChildEntries(row);       
        }
    }
    
    public void fillFilterList(){
        // get the filter parameter, if any
        String fParam = ApexPages.CurrentPage().getParameters().get('filter');

        list<String> filterList = new list<String>(filterSet);
        filterList.sort();
        if (weHaveKeyMetrics) 
            filterList.add(0, 'Key');
        filterList.add('All');

        filterOptions = new list<SelectOption>();
        for (String s : filterList) {
            filterOptions.add(new SelectOption(s, s));
            if (fParam == s)
                filter = s;
        }
        if (filter == null)
            filter = filterOptions[0].getValue();
    }

    public void getChatter(){

        map<id, FeedItem> postMap = new map<id, FeedItem>();
        list<id> allUserIDs = new list<id>();

        for(FeedItem c : 
                [select id, body, parentID, createdDate, createdBy.Id from FeedItem 
                    where ParentID =:entryMap.keyset() ORDER BY CreatedDate DESC LIMIT 500]){

            if(!postMap.containsKey(c.parentId) && c.body != null && !c.body.contains('#noscore')){
                allUserIDs.add(c.createdBy.Id);
                postMap.put(c.parentId, c);
            }
        }

        map<id, User> userMap = new map<id, User>(
            [select id, firstName, lastName, SmallPhotoUrl from User where id = :allUserIDs]);

        for ( ScorecardRow row : allRows ) {
            row.post = postMap.get( row.entry.Id );
            row.postUser = userMap.get( row.post.createdBy.Id );
        }
    }

    // @RemoteAction
    // public static Database.SaveResult updateEntry( String entryJson ) {  
    //  Scorecard_Entry__c entry = ((Scorecard_Entry__c)(JSON.deserialize(entryJson, Scorecard_Entry__c.class)));

    //  //system.debug(loggingLevel.WARN, 'entry deserialized:');
    //  //system.debug(loggingLevel.WARN, entry);

    //  return (Database.update( entry, true ));
    // }

    @RemoteAction
    public static Database.SaveResult saveEntry( Scorecard_Entry__c entry ) {  
        //Scorecard_Entry__c entry = ((Scorecard_Entry__c)(JSON.deserialize(entryJson, Scorecard_Entry__c.class)));

        //system.debug(loggingLevel.WARN, 'entry deserialized:');
        //system.debug(loggingLevel.WARN, entry);
        if (entry.id == null)
            return (Database.insert( entry, true ));
        else
            return (Database.update( entry, true ));
    }

   
}
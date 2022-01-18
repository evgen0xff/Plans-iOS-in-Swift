//
//  CountryHandler.m
//  TimeToEnjoy
//  Created by Plans Collective LLC on 20/02/16.
//  Copyright © 2016 PlansCollective. All rights reserved.

#import "CountryHandler.h"

@implementation CountryHandler

static sqlite3 *db      = nil; // Pointer to Database from which data is retrived
sqlite3_stmt *statment  = nil; // Statment used in fetching data from database

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self prepareDataBase];
    }
    return self;
}

-(void)prepareDataBase
{
    NSString *dbPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:TTELocationDB_NAME];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL filePresent = [manager fileExistsAtPath:dbPath];
    if (filePresent && db == nil) {
        
        int retval = sqlite3_open([dbPath UTF8String], &db);
        if (retval == SQLITE_OK) {
        }else{
            
        }
    }else{
        
    }
}

- (NSMutableArray *)fetchCityListData:(NSString *)queryString {
	NSMutableArray *getListArray = [[NSMutableArray alloc]init];
    if(sqlite3_prepare_v2(db,[queryString UTF8String],-1, &statment, NULL) == SQLITE_OK)
    {
        while(sqlite3_step(statment) <= SQLITE_ROW)
        {
            NSMutableDictionary *oneRecord = [[NSMutableDictionary alloc]init];
            
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 0)]forKey:@"Id"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 1)]forKey:@"City"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 2)]forKey:@"Region"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 3)]forKey:@"Country"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 4)]forKey:@"Latitude"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 5)]forKey:@"Longitude"];
            [getListArray addObject:oneRecord];
            //[oneRecord release];
        }
        sqlite3_finalize(statment);
    }
	return getListArray ;
}

- (NSMutableArray *)fetchCityStateCountryZipListData:(NSString *)queryString {
	
	NSMutableArray *getListArray = [[NSMutableArray alloc]init];
	
    
    if(sqlite3_prepare_v2(db,[queryString UTF8String],-1, &statment, NULL) == SQLITE_OK)
    {
        while(sqlite3_step(statment) <= SQLITE_ROW)
        {
            NSMutableDictionary *oneRecord = [[NSMutableDictionary alloc]init];
            
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 0)]forKey:@"Id"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 1)]forKey:@"City"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 2)]forKey:@"Region"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 3)]forKey:@"Country"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 4)]forKey:@"Latitude"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 5)]forKey:@"Longitude"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 6)]forKey:@"Zip"];
            [getListArray addObject:oneRecord];
            //[oneRecord release];
        }
        sqlite3_finalize(statment);
    }
	return getListArray ;
}

- (NSMutableArray *)FetchCountry
{
    NSMutableArray *countryArray = [[NSMutableArray alloc] init];
    NSString *queryString = @"SELECT * from country";
    if (sqlite3_prepare_v2(db, [queryString UTF8String], -1, &statment, NULL) == SQLITE_OK) {
        while (sqlite3_step(statment) <= SQLITE_ROW) {
            NSMutableDictionary *oneRecord = [[NSMutableDictionary alloc]init];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 0)]forKey:@"CountryID"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 1)]forKey:@"CountryEnglishName"];
            if((char *)sqlite3_column_text(statment, 2)!=(NULL))
            {
                [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 2)]forKey:@"CountryLocalName"];
            }
      
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 3)]forKey:@"ISOCode"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 4)]forKey:@"CountryCode"];
            [oneRecord setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statment, 5)]forKey:@"CountryExitCode"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 6)]forKey:@"Min_NSN"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 7)]forKey:@"Max_NSN"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 8)]forKey:@"TrunkCode"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 9)]forKey:@"GoogleStore"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 10)]forKey:@"AppleStore"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 11)]forKey:@"UNRank"];
            [oneRecord setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, 13)]forKey:@"SortIndex"];
            [countryArray addObject:oneRecord];
        }
        sqlite3_finalize(statment);
    }
    return countryArray ;
}

@end

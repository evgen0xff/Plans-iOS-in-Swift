//
//  CountryHandler.h
//  TimeToEnjoy
//  Created by Plans Collective LLC on 20/02/16.
//  Copyright © 2016 PlansCollective. All rights reserved.

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define TTELocationDB_NAME @"CountryList.sqlite" // Name of databse

@interface CountryHandler : NSObject

-(void)prepareDataBase;
- (NSMutableArray *)fetchCityListData:(NSString *)queryString;
- (NSMutableArray *)FetchCountry;
- (NSMutableArray *)fetchCityStateCountryZipListData:(NSString *)queryString;

@end

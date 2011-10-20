//
//  OTUpload.m
//  opentracker
//
//  Created by Pavitra on 9/8/11.
//  Copyright 2011 Opentracker. All rights reserved.
//

#import "OTFileUtils.h"
#include "zlib.h"

@implementation OTFileUtils

- (id)init 
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//returns YES, if file is created or already present, else NO
+(void) makeFile : (NSString*) filename {
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    // File we want to create in the documents directory 
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename];
    return ;
    //testing svn 
}

+(void) writeFile: (NSString*) filename withString: (NSString*) str{
    // For error information
    NSError *error;
    
    // Create file manager
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    // File we want to create in the documents directory 
    // Result is: /Documents/file1.txt
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename];
    
    // String to write
    //NSString *str = @"test data to be erased. This should not be shown.";
    
    // Write the file
    [str writeToFile:filePath atomically:YES 
            encoding:NSUTF8StringEncoding error:&error];
    
    // Show contents of Documents directory
    NSLog(@"Documents directory: %@",
          [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
    NSLog(@"File path:%@", filePath);
    
    
    
}

+(void) removeFile: (NSString*) filename {
    NSError *error;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename];
    
    // Attempt to delete the file at filePath
    if ([fileMgr removeItemAtPath:filePath error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    
    // Show contents of Documents directory
    NSLog(@"Documents directory: %@",
          [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}

+(NSString*) readFile : (NSString*) filename {
    NSError *error;
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename ];
    NSString *myFileContents = [NSString stringWithContentsOfFile:filePath
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
    NSLog(@"File contents : %@",myFileContents);
    return myFileContents;
}



//see how to append string to file : http://www.iphonedevsdk.com/forum/iphone-sdk-development/50269-using-writetofile-can-i-add-records-file.html
+(void) appendToFile:(NSString *)filename writeString:(NSString *) writeString {
    NSLog(@"appendToFile()");
    
    writeString =[NSString stringWithFormat:@"%@\n", writeString];
    
    // NSFileHandle won't create the file for us, so we need to check to make sure it exists
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    // File we want to create in the documents directory 
    // Result is: /Documents/file1.txt
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename];
    
    if (![fileMgr fileExistsAtPath:filePath]) {
        
        // the file doesn't exist yet, so we can just write out the text using the 
        // NSString convenience method
        
        NSError *error = noErr;
        BOOL success = [writeString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!success) {
            // handle the error
            NSLog(@"%@", error);
        }
        
    } else { // the file already exists, so we should append the text to the end
        // get a handle to the file
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];		
        // move to the end of the file
        [fileHandle seekToEndOfFile];		
        // convert the string to an NSData object
        NSData *textData = [writeString dataUsingEncoding:NSUTF8StringEncoding];
        // write the data to the end of the file
        [fileHandle writeData:textData];
        // clean up
        [fileHandle closeFile];
    }
}

+(NSString*) compressFile : (NSString*) filename {
    NSLog(@"compressFile : %@", filename);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    // File we want to create in the documents directory 
    // Result is: /Documents/file1.txt
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:filename];

	FILE *fin = nil;
	gzFile *fout = nil;
    
	fin = fopen([filePath UTF8String], "rb");
	if (fin == nil) {
		[NSException raise:@"File open error" format:@"could not open file %@ for reading.", filePath];
	}
	fout = gzopen([[filePath stringByAppendingString:@".gz"] UTF8String], "w");
	if (fout == nil) {
		fclose(fin);
		[NSException raise:@"File open error" format:@"could not open file %@ for writing.", [filePath stringByAppendingString:@".gz"]];
	}
	char buf[255];
	int len = 0;
	while (!feof(fin) && (len = fread(buf, 1, sizeof(buf), fin)) && len > 0) {
		if (gzwrite(fout, buf, len) <= 0) {
			fclose(fin);
			gzclose(fout);
			[NSException raise:@"Gzip file failure" format:@"could not write to file %@.", [filename stringByAppendingString:@".gz"]];
		}
	}
	gzclose(fout);
	fclose(fin);
	NSLog(@"Gzipped %@ to %@", filename, [filename stringByAppendingString:@".gz"]);
	return [filename stringByAppendingString:@".gz"];
}

@end

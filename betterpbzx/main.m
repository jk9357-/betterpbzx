//
//  main.m
//  betterpbzx
//
//  Created by REAL KJC GANGMEMBER on 9/16/18.
//  Copyright © 2018 REAL KJC GANGMEMBER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/mman.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        if(argc<2){
            printf("Usage: %s <path to payload.000> [-concat]\n",argv[0]);
            return 0;
        }
        NSURL *firstPartURL=[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
        
        // don't write each file to a .xz and concatenate the first one instead
        BOOL concatenate=argc==3&&!strcmp(argv[2], "-concat");
        int outfd=open([firstPartURL URLByAppendingPathExtension:@"xz"].path.UTF8String, O_RDWR|O_CREAT,0644);

        for (int i=0; access(firstPartURL.path.UTF8String, F_OK) != -1; i++) {
            printf("Reading file %03d\n",i);
            int fd=open(firstPartURL.path.UTF8String, O_RDONLY);
            assert(fd!=-1);
            off_t len=lseek(fd, 0, SEEK_END);
            assert(len!=-1);
            char *part=mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, 0);
            assert(part!=MAP_FAILED);
            if(memcmp(part, "pbzx", 4)){
                printf("Didn't find pbzx magic\n");
                return -1;
            }
            
            /*
             
             Option 1: | "pbzx"     | 0x800000 | <length> | <reserved> | data.xz
             Option 2: | "pbzx"     | 0x800000 | 0x800000 | <length>   | part.xz |
                       | 0x800000   | <length> | part.xz  |
                       | 0x800000 ...
                       | <reserved> | <length> | part.xz  | EOF
             
             */
            
            off_t offset=4; // "pbzx"
            char r=0; // 0 = didn't read header yet, 1 = option 1, 2 = option 2
            int xzfd=concatenate ? outfd : open([firstPartURL URLByAppendingPathExtension:@"xz"].path.UTF8String, O_RDWR|O_CREAT,0644);

            while (offset<len) {
                uint64_t flags=CFSwapInt64(*(uint64_t *)(part+offset));
                uint64_t reserved=CFSwapInt64(*(uint64_t *)(part+offset+(r==2 ? 0x10 : 8)));
                uint64_t partLength=CFSwapInt64(*(uint64_t *)(part+offset+(r==2 ? 8 : 0x10)));
                
                if(r==2)
                    printf("Flags: 0x%llx, length: 0x%llx\n",flags,partLength);
                else
                    printf("Flags: 0x%llx, length: 0x%llx, reserved: 0x%llx\n",flags,partLength,reserved);

                /*
                 Failure reason 1: part.xz | 0x25f286 | 0x25f286 | <variable length data> | part.xz | EOF
                 */
                
                if(flags!=0x800000&&flags==partLength){
                    printf("Skipping what appears to be non xz chunk without apparent length, searching for next xz chunk\n");
                    char *xz=memmem(part+offset, len-offset, "\xfd\x37zXZ", 6);
                    if(xz)
                        write(fd, xz, len-(xz-part));
                    break;
                }
                
                /*
                 Failure reason 2: part.xz | 0x800000 | 0x800000 | <0x800000 bytes of data> | ...
                 */
                
                if(partLength==0x800000&&memcmp(part+offset+(r==2 ? 0x10 : 0x18), "\xfd\x37zXZ", 6)){
                    printf("Skipping what appears to be non xz chunk\n");
                    goto keep_going;
                }
                
                // check for xz header and footer
                assert(!memcmp(part+offset+(r==2 ? 0x10 : 0x18), "\xfd\x37zXZ", 6));
                assert(*(uint16_t *)(part+offset+(r==2 ? 0x10 : 0x18)+partLength-2)==0x5a59);
                
                write(xzfd, part+offset+(r==2 ? 0x10 : 0x18), partLength);
            keep_going:
                offset+=partLength+(r==2 ? 0x10 : 0x18);
                
                if(!r)
                    r=(char)(reserved==0x800000)+1;
            }
            if(!concatenate)
            close(xzfd);
            
            munmap(part, len);
            close(fd);
            
            firstPartURL=[[firstPartURL URLByDeletingPathExtension]URLByAppendingPathExtension:[NSString stringWithFormat:@"%03d",i+1]];
        }
    }
    return 0;
}

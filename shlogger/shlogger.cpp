/**
 * @file shlogger.cpp Shell logging tool.  This tool will write it's input to an
 * output logfile, rotating as required.
 *
 * Copyright 2019 John Scott
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "shlogrot.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <sysexits.h>
#include <typeinfo>
#include <unistd.h>


/**
 * ShLogger program entry point
 * 
 */
int main(int argc, char *argv[])
{
    int opt;
    int rc = EX_OK;
    std::string logFile("");
    int logCount = ShLogRotator::DEF_COUNT;
    long logSize = ShLogRotator::DEF_SIZE;
    bool tee = false;
    pid_t pid = getpid();
    std::string scriptName("");


    try {
        // Still interactive, so no timestamp prefix yet...

        // Check for no arguments, or -?
        if(1 == argc || std::string("-?") == argv[1]) {
            std::cerr << "Usage: shlogger [-c FileCount] [-n ScriptName] [-p ProcessID] [-s FileSize] [-t] LogFileName" << std::endl;
            return(EX_OK);
        }

        // Parse command line arguments.
        while(EX_OK == rc && (opt = getopt(argc, argv, "c:n:p:s:t")) != -1) {
            switch(opt) {
            case 'c':
                if(NULL == optarg) {
                    std::cerr << "Option -c requires a numeric argument." << std::endl;
                    rc = EX_USAGE;
                } else if(std::strspn(optarg, "0123456789") != std::strlen(optarg)) {
                    std::cerr << "Option -c argument '" << optarg << "' not numeric." << std::endl;
                    rc = EX_USAGE;
                } else {
                    logCount = atoi(optarg);

                    if(logCount < 1) {
                        std::cerr << "Invalid log file count " << logCount << "." << std::endl;
                        rc = EX_USAGE;
                    }
                }
                break;

            case 'n':
                if(NULL == optarg) {
                    std::cerr << "Option -n requires a string argument." << std::endl;
                } else {
                    scriptName = optarg;
                }
                break;

            case 'p':   // Specify process ID to distinguish log entries.
                if(NULL == optarg) {
                    std::cerr << "Option -p requires a numeric argument." << std::endl;
                    rc = EX_USAGE;
                } else if(std::strspn(optarg, "0123456789") != std::strlen(optarg)) {
                    std::cerr << "Option -p argument '" << optarg << "' not numeric." << std::endl;
                    rc = EX_USAGE;
                } else {
                    pid = atoi(optarg);
                }
                break;

            case 's':   // Specify the size of each log file.
                if(NULL == optarg) {
                    std::cerr << "Option -s requires a numeric argument." << std::endl;
                    rc = EX_USAGE;
                } else if(std::strspn(optarg, "0123456789") != std::strlen(optarg)) {
                    std::cerr << "Option -s argument '" << optarg << "' not numeric." << std::endl;
                    rc = EX_USAGE;
                } else {
                    logSize = atol(optarg);

                    if(logSize < ShLogRotator::DEF_SIZE) {
                        std::cerr << "Minimum log file size " << ShLogRotator::DEF_SIZE << " not " << logSize << "." << std::endl;
                        rc = EX_USAGE;
                    }
                }
                break;

            case 't':   // Specify that the output is to be tee'd to the log file and standard out.
                tee = true;
                break;

            default:    // Eh? Unexpected parameter.
                std::cerr << "Unexpected option -" << (char)opt << std::endl;
                rc = EX_USAGE;
                break;
            }
        }

        if(EX_OK == rc && optind >= argc) {
            std::cerr << "No log file name specified." << std::endl;
            rc = EX_USAGE;
        } else if (EX_OK == rc && optind != argc - 1) {
            std::cerr << "Too many log file names specified." << std::endl;
            rc = EX_USAGE;
        } else if (EX_OK == rc) {
            logFile = argv[optind];

            if(!tee) {
                std::freopen("/dev/null", "w", stdout);
                std::freopen("/dev/null", "w", stderr);
            }
        }

        // Now create the log rotator and feed it std input...
        if(EX_OK == rc) {
            ShLogRotator log(logFile, logCount, logSize, pid, scriptName);

            std::string line;
            while(std::getline(std::cin, line)) {
                log.write(line);

                if(tee) {
                    std::clog << line << std::endl;
                }
            }

            if(std::cin.fail() && !std::cin.eof()) {
                std::cerr << "ShLogger failed reading standard input." << std::endl;
                rc = EX_IOERR;
            }
        }
    } catch(std::exception &ex) {
        std::cerr << "ShLogger ended with a standard "
                  << typeid(ex).name() << " exception. "
                  << ex.what()
                  << std::endl;
        rc = EX_SOFTWARE;
    } catch(...) {
        std::cerr << "ShLogger ended with a non-standard exception."
                  << std::endl;
        rc = EX_SOFTWARE;
    }

    return(rc);
}

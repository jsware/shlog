/**
 * @file shlogrot.cpp ShLogRotator class implementation. This file contains the
 * implementation of the ShLogRotator component.
 *
 * Copyright 2018 John Scott
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
#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <limits.h>
#include <sstream>
#include <stdexcept>
#include <stdlib.h>
#include <string>
#include <typeinfo>
#include <unistd.h>

#ifndef HOST_NAME_MAX
    #ifdef _POSIX_HOST_NAME_MAX
        #define HOST_NAME_MAX _POSIX_HOST_NAME_MAX
    #else
        #ifdef MAXHOSTNAMELEN
            #define HOST_NAME_MAX MAXHOSTNAMELEN
        #endif
    #endif
#endif /* HOST_NAME_MAX */

/**
 * Implementation for the ShLogRotator class.  This class provides a pimpl
 * idiom impementation for the ShLogRotator class.  It hides implementation
 * details from the ShLogRotator component header file, reducing coupling
 * between the ShLogRotator component and its uses.
 */
class ShLogRotatorImpl
{
public:
    // ENUMERATIONS & CONSTANTS...
    static const std::ios::openmode OPEN_MODE;  ///< The log file open mode.

public:
    // CREATORS...
    ShLogRotatorImpl(const std::string &logFile, int logCount, long logSize, int pid, const std::string &scriptName);

    /// Destroy the ShLogRotatorImpl, releasing any resources.
    inline ~ShLogRotatorImpl() {
        try {
            if(out_.is_open()) {
                out_.close();
            }
        } catch(std::exception &ex) {
            std::cerr << "Unexpected standard exception "
                      << typeid(ex).name() << " occurred during ShLogRotatorImpl destructor. "
                      << ex.what() << std::endl;
            // Absorb destructor errors
        } catch(...) {
            std::cerr << "Unexpected non-standard exception occurred during ShLogRotatorImpl destructor." << std::endl;
            // Absorb destructor errors
        }
    }

public:
    // MANIPULATORS...

    /// Rotate the log file through it's archive name.
    void rotate();

    /**
     * Write a line of text to the specified output stream, prefixing it
     * with the current date/time.
     *
     * @param line  The line of text to write.
     */
    void write(const std::string &line);

public:
    // ACCESSORS...
 
private:
    // NOT IMPLEMENTED...
 
    /// Copying ShLogRotatorImpl objects is not supported.
    ShLogRotatorImpl(const ShLogRotatorImpl &cpy);

    /// Assignment of ShLogRotatorImpl objects is not supported.
    ShLogRotatorImpl &operator=(const ShLogRotatorImpl &rhs);

public:
    // IMPLEMENTATION...
    std::string logFile_;   ///< The log file to write to.
    int logCount_;          ///< The number of files to keep in rotation.
    long logSize_;          ///< The maximum size each file can become before rotation.
    int pid_;               ///< The process Id to record in the log.
    std::string scriptName_;///< The name of the script we're logging.

    std::string hostname_;
    std::string username_;

    std::ofstream out_;     ///< The output file stream currently being written to.
};


// Open mode for logging file.
const std::ios::openmode ShLogRotatorImpl::OPEN_MODE = std::ios::out | std::ios::app | std::ios::ate;


//
// ShLogRotator constructor.
//
ShLogRotator::
ShLogRotator(const std::string &logFile, int logCount, long logSize, int pid, const std::string &scriptName)
: pimpl_(new ShLogRotatorImpl(logFile, logCount, logSize, pid, scriptName))
{
    // NOP
}


//
// Constructor for Log Rotator implementation.
//
ShLogRotatorImpl::
ShLogRotatorImpl(const std::string &logFile, int logCount, long logSize, int pid, const std::string &scriptName)
: logFile_(logFile)
, logCount_(logCount)
, logSize_(logSize)
, pid_(pid)
, scriptName_(scriptName)
, hostname_("unknown")
, username_(getenv("LOGNAME"))
{
    char hostname[HOST_NAME_MAX + 1];

    if(logFile_ == "") {
        throw std::runtime_error("Invalid log file name ''");
    }

    if(logCount_ < 1) {
        std::stringstream e;
        e << "Invalid log file count " << logCount_ << ".";
        throw std::out_of_range(e.str());
    }

    if(logSize_ < ShLogRotator::DEF_SIZE) {
        std::stringstream e;
        e << "Invalid log file size " << logSize_ << ".";
        throw std::out_of_range(e.str());
    }

    if(0 != gethostname(hostname, HOST_NAME_MAX)) {
        std::strcpy(hostname, "?: ");
        perror(hostname + 3);
    }
    hostname_ = hostname;
}


//
// ShLogRotator destructor.
//
ShLogRotator::
~ShLogRotator()
{
    try {
        delete pimpl_;
    } catch(std::exception &ex) {
        std::cerr << "Unexpected standard exception "
                  << typeid(ex).name() << " occurred during ShLogRotator destructor. "
                  << ex.what() << std::endl;
        // Absorb destructor errors
    } catch(...) {
        std::cerr << "Unexpected non-standard exception occurred during ShLogRotator destructor." << std::endl;
        // Absorb destructor errors
    }
}


//
// Write line to Log and rotate if necessary.
//
void ShLogRotator::
write(const std::string &line)
{
    // Automatically open the file if it is not open.
    if(!pimpl_->out_.is_open()) {
        pimpl_->out_.open(pimpl_->logFile_.c_str(), ShLogRotatorImpl::OPEN_MODE);
    } else {
        // We're already open so seek to end of file in case another logger has
        // written some lines.  If we're past the max file size then re-open
        // the file to ensure the other logger hasn't rotated.
        pimpl_->out_.seekp(0, std::ios::end);
        if(pimpl_->out_.tellp() > pimpl_->logSize_) {
            pimpl_->out_.close();
            pimpl_->out_.open(pimpl_->logFile_.c_str(), ShLogRotatorImpl::OPEN_MODE);
        }
    }

    // Check to see if we need to rotate first.
    if(pimpl_->out_.tellp() > pimpl_->logSize_) {
        pimpl_->rotate();
    }

    // Automatically open the file again if it was closed by rotation.
    if(!pimpl_->out_.is_open()) {
        pimpl_->out_.open(pimpl_->logFile_.c_str(), ShLogRotatorImpl::OPEN_MODE);
    }

    pimpl_->write(line);
}


//
// Write line to specified output stream, prefixing with current date/time.
//
void ShLogRotatorImpl::
write(const std::string &line)
{
    time_t now = time(NULL);
    struct tm *t = gmtime(&now);
    char nowText[30];
    std::string prefix("INFO");

    if(0 == std::strncmp(line.c_str(), "->", 2)) {
        prefix = "ENTER";
    } else if (0 == std::strncmp(line.c_str(), "<-", 2)) {
        prefix = "LEAVE";
    }

    // Get rid of the trailing \n character.
    strftime(nowText, sizeof(nowText), "%a %b %e %T UTC %Y", t);
    out_    << nowText
            << '\t' << hostname_
            << '\t' << username_;
            
    if(scriptName_ != "" ) {
        out_ << '\t' << scriptName_;
    }
    
    out_    << '\t' << pid_
            << '\t' << prefix
            << '\t' << line
            << std::endl;
}


//
// Rotate the log files
//
void ShLogRotatorImpl::
rotate()
{
    std::stringstream oldName;
    std::stringstream olderName;

    out_.close();

    // Delete the last file if it exists.
    oldName << logFile_ << "." << logCount_ - 1;
    std::remove(oldName.str().c_str());

    // Move each file down 1 sequence no (file.log.0 -> file.log.1 etc.)
    for(int i = logCount_ - 1; i > 0; --i) {
        olderName.str(oldName.str());
        oldName.str("");
        oldName << logFile_ << "." << i - 1;

        std::rename(oldName.str().c_str(), olderName.str().c_str());
    }

    std::rename(logFile_.c_str(), oldName.str().c_str());
}

/**
 * @file shlogrot.h ShLogRotator Declarations.  This file declares the log
 * rotator class, ShLogRotator.  The ShLogRotator class rotates log files, making
 * progressively older log files get higher sequence numbers.
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
#ifndef SHLOGROT_H_INCLUDED
#define SHLOGROT_H_INCLUDED

#include <string>

/**
 * Write log entries to a rotating set of log files.  The class rotates log
 * files when they reach a specified size, deleting the oldest log file and
 * renames the rest when a new file is required.
 */
class ShLogRotator
{
public:
    // ENUMERATIONS & CONSTANTS...
    enum {
        DEF_COUNT = 10,     ///< Default number of files to rotate.
        DEF_SIZE =  1048576 ///< Default size of each file.
    };

public:
    // CREATORS...

    /**
     * Construct a log rotator with the specified pattern name, count and size.
     *
     * @param fileName  The pattern name for the log files. The %d is used to
     *                  indicate the location of the log file sequence number.
     * @param fileCount The number of files to rotate.
     * @param fileSize  The size of each file to be created, before the files
     *                  are rotated.
     * @param pid       An id for the task which is executing.  This is output
     *                  in the log to allow separation when multiple tasks
     *                  write to the same log.
     */
    ShLogRotator(const std::string &logName, int logCount, long logSize, int pid, const std::string &scriptName);

    /// Destroy the LogRotator, releasing any resources.
    virtual ~ShLogRotator();

public:
    // MANIPULATORS...

    /**
     * Write a line of text to the current log file, rotating if necessary.
     *
     * @param line  The line of text to write.
     */
    void write(const std::string &line);

public:
    // ACCESSORS...

private:
    // NOT IMPLEMENTED...

    /// Copying LogRotator objects is not supported.
    ShLogRotator(const ShLogRotator &cpy);

    /// Assignment of LogRotator objects is not supported.
    ShLogRotator &operator=(const ShLogRotator &rhs);

private:
    // IMPLEMENTATION...
    class ShLogRotatorImpl *pimpl_;
};

#endif  /* INCLUDED_SLROTATE_H */

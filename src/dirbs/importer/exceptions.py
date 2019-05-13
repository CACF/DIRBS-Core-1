"""
Exception types for various types of import failures.

Copyright (c) 2019 Qualcomm Technologies, Inc.

 All rights reserved.



 Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the
 limitations in the disclaimer below) provided that the following conditions are met:


 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
 disclaimer in the documentation and/or other materials provided with the distribution.

 * Neither the name of Qualcomm Technologies, Inc. nor the names of its contributors may be used to endorse or promote
 products derived from this software without specific prior written permission.

 NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY
 THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
"""


class ImportLockException(Exception):
    """Indicates that the required lock for the type of data import being done could not be acquired."""

    pass


class ImportCheckException(Exception):
    """Base class for all import check failures."""

    def __init__(self, msg, statsd, metrics_failures_root):
        """Constructor."""
        super().__init__(msg)
        self.message = msg
        metrics_key = '{0}{1}'.format(metrics_failures_root, self.metric_failure_key)
        statsd.gauge(metrics_key, 1, delta=True)

    @property
    def metric_failure_key(self):
        """The leaf component of the metric failure key."""
        raise NotImplementedError('Should be implemented')


class ZipFileCheckException(ImportCheckException):
    """Exception thrown if there is a problem with the .zip file input to an import."""

    @property
    def metric_failure_key(self):
        """Overrides AbstractImporter.metric_failure_key."""
        return 'zipfile'


class FilenameCheckException(ImportCheckException):
    """Exception thrown if there is a problem with the filename for an extracted data file."""

    @property
    def metric_failure_key(self):
        """Overrides AbstractImporter.metric_failure_key."""
        return 'filename'


class PreprocessorCheckException(ImportCheckException):
    """Exception thrown if there is a problem with the data found during pre-processing."""

    @property
    def metric_failure_key(self):
        """Overrides AbstractImporter.metric_failure_key."""
        return 'preprocess'


class PrevalidationCheckException(ImportCheckException):
    """Exception thrown if there is a problem found during pre-validation."""

    @property
    def metric_failure_key(self):
        """Overrides AbstractImporter.metric_failure_key."""
        return 'prevalidation'


class ValidationCheckException(ImportCheckException):
    """Exception thrown if a binary validation check fails."""

    def __init__(self, *args, metric_key, **kwargs):
        """Constructor."""
        self._metric_failure_key = metric_key
        super().__init__(*args, **kwargs)

    @property
    def metric_failure_key(self):
        """Overrides AbstractImporter.metric_failure_key."""
        return self._metric_failure_key


class PrevalidationCheckRawException(Exception):
    """Exception thrown if pre-validator returns false result."""

    pass


class FilenameCheckRawException(Exception):
    """Exception thrown if there is a problem with the filename for an extracted data file."""

    pass

#!/usr/bin/env python3
"""Export CUPS metrics to prometheus
"""

import argparse
import time

import cups
from prometheus_client import start_http_server
from prometheus_client.core import (REGISTRY, CounterMetricFamily,
                                    GaugeMetricFamily)

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument(
    "--cups-host", help="The cups host to connect to", default="localhost")
parser.add_argument("--cups-port", type=int,
                    help="The cups port to use", default=631)
parser.add_argument(
    "--cups-user", help="The user to connect with", default="default")
parser.add_argument("--listen-port", type=int,
                    help="The port the exporter will listen on", default=9329)
args = parser.parse_args()


class CUPSCollector:
    """CUPSCollector collects status data about
    currently configured printers in cups
    """

    def __init__(self, host, port, user):
        """Set cups connection parameters

        Arguments:
            host {str} -- Cups Hostname
            port {int} -- Cups Port
            user {str} -- Cups username
        """
        self._prometheus_metrics = {}

        self.host = host
        self.port = port
        self.user = user


    def collect(self):
        """Collects the metrics from cups
        """
        start = time.time()

        self._setup_empty_prometheus_metrics()

        cups.setServer(self.host)
        cups.setPort(self.port)
        cups.setUser(self.user)

        try:
            conn = cups.Connection()

            printers = conn.getPrinters()
            self._prometheus_metrics['printersNum'].add_metric(
                [],
                len(printers))

            self._getPrinterStatus(printers)
            self._getJobData(conn)

            self._prometheus_metrics['cupsUp'].add_metric([], 1)
        except Exception as e:
            self._prometheus_metrics['cupsUp'].add_metric([], 0)
            print(e)

        duration = time.time() - start
        self._prometheus_metrics['scrape_duration_seconds'].add_metric(
            [], duration)

        for metric in self._prometheus_metrics.values():
            yield metric

    def _setup_empty_prometheus_metrics(self):
        """
        The metrics we want to export.
        """
        self._prometheus_metrics = {
            'printJobsNum':
                GaugeMetricFamily('cups_print_jobs_active',
                                  'Number of current print jobs'),
            'printJobsTotal':
                CounterMetricFamily('cups_print_jobs_total',
                                    'Total number of print jobs'),
            'printersNum':
                GaugeMetricFamily('cups_printers',
                                  'Number of printers'),
            'printerStatus':
                GaugeMetricFamily('cups_printer_status_info',
                                  'Status about printer alerts',
                                  labels=['printer', 'model', 'status']),
            'cupsUp':
                GaugeMetricFamily('cups_up',
                                  'CUPS status'),
            'scrape_duration_seconds':
                GaugeMetricFamily('cups_scrape_duration_seconds',
                                  'Amount of time each scrape takes',
                                  labels=[])
        }

    def _getJobData(self, conn):
        """Collects data about cups
        """
        lastjobID = None
        jobs = conn.getJobs(which_jobs="all")
        if len(jobs) == 0:
            self._prometheus_metrics['printJobsTotal'].add_metric([], 0)
        else:
            lastjobID = list(jobs.keys())[-1]


        # We have to fetch by jobAttributes, because getJobAttributes lies a bunch
        # and doesn't return what it should
        if lastjobID is not None:
            potentialLastJob = lastjobID
            while True:
                try:
                    job_attr = conn.getJobAttributes(lastjobID)
                    lastjobID += 1
                except cups.IPPError:
                    lastjobID -= 1
                    break

            self._prometheus_metrics['printJobsTotal'].add_metric(
                [], lastjobID)

        jobs = conn.getJobs()
        if len(jobs) == 0:
            self._prometheus_metrics['printJobsNum'].add_metric([], 0)
        else:
            self._prometheus_metrics['printJobsNum'].add_metric(
                [],
                len(jobs))

    def _getPrinterStatus(self, printers):
        """Gathers printer status data

        Arguments:
            printers {dict} -- dict of printers
        """
        for key, value in printers.items():
            if value['printer-state-reasons'][0] != 'none':
                self._prometheus_metrics['printerStatus'].add_metric([
                    key,
                    value['printer-make-and-model'],
                    value['printer-state-reasons'][0]],
                    0)
            else:
                self._prometheus_metrics['printerStatus'].add_metric([
                    key,
                    value['printer-make-and-model'],
                    'happy'],
                    1)


if __name__ == '__main__':
    # Start up the server to expose the metrics.
    REGISTRY.register(CUPSCollector(
        args.cups_host,
        args.cups_port,
        args.cups_user))
    start_http_server(args.listen_port)
    while True:
        time.sleep(1)


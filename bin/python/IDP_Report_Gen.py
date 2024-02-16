from datetime import datetime
from sys import argv
from pathlib import Path
from typing import List
import csv

class IDP_Report_Gen:
    """
    class IDP_Report_Gen:
        This class is used to transform a normal csv file into an IDP accecpted format, which is pipe-delimited,
        specific header and trailer formatting. As well sa special character requirements.
    """

    def __init__(self, bus_dt: str, input_file: str, output_location: str, input_delimiter: str, filename: str,
                 flag: str):
        self.bus_dt = bus_dt
        self.input_file = input_file
        self.output_path = output_location
        self.input_delim = input_delimiter
        self.filename = filename
        self.delimiter = "|"
        self.padding = ""
        self.monthly_flag = flag
        self.date_column = None
        self.transform_date = False
        self.dateformat = ""

        def update_monthly_flag(monthly_flag: str) -> str:
            if monthly_flag.upper() == "M":
                return "MONTHLY"
            else:
                return "DAILY"

        self.monthly_flag = update_monthly_flag(self.monthly_flag)

    def find_date_col(self, headers: List[str]) -> None:
        self.date_column = headers.index("BUS_DT")

    def detect_dateformat(self, date_string: str) -> str:
        date_patterns = ["%Y%m%d", "%Y-%m-%d", "%Y/%m/%d"]
        date_strings = [date_string[:10],  date_string[:8]]
        # if not empty
        if date_string != "":
            for pattern in date_patterns:
                for date_str in date_strings:
                    try:
                        datetime.strptime(date_str, pattern)
                        self.dateformat = pattern

                    except:
                        pass
        if self.dateformat == "":
            raise Exception(f"Failed to read input Date Format: {date_string}")

    def transform_busdate(self, date_string: str) -> str:
        if date_string == "":
            return date_string
        elif self.dateformat == "%Y%m%d":
            return date_string[:8]
        else:
            return datetime.strptime(date_string[:10], self.dateformat).strftime("%Y%m%d")

    def output_filename(self) -> str:
        return f"CMRODS.IDP.FULL.{self.filename}.{self.monthly_flag}.{self.bus_dt}.csv"

    def create_first_header(self) -> str:
        run_date = datetime.today().strftime('%Y%m%d:') + datetime.today().strftime('%H:%M:%S')
        header_content = ['HDR1', self.filename, self.bus_dt, "00000", "CMR_ODS", run_date]
        header_line = self.delimiter.join(header_content)
        return header_line

    def create_trailer(self, record_count: int) -> str:
        trailer_contenet = ["TRL", self.bus_dt, str(record_count)]
        trailer_line = self.delimiter.join(trailer_contenet)
        return trailer_line

    def write_report(self):
        contemt_count = 0

        output_file = self.output_filename()
        output_file = Path(self.output_path) / output_file

        try:
            print(f"Creating {self.filename} Report")
            with open(self.input_file, mode='r') as in_file:
                with open(output_file, mode='w') as out_file:
                    hdr1 = self.create_first_header()
                    out_file.write(hdr1 + "\n")

                    this_file = csv.reader(in_file, delimiter=self.input_delim, quotechar='"')

                    for this_line in this_file:
                        # write second header
                        if contemt_count == 0:
                            self.find_date_col(this_line)
                            this_line = ["HDR2"] + this_line
                            this_line = self.delimiter.join(this_line)
                            out_file.write(this_line + "\n")

                        else:
                            if self.dateformat == "":
                                self.detect_dateformat(this_line[self.date_column])

                            this_line[self.date_column] = self.transform_busdate(this_line[self.date_column])
                            # Core requirement of report is to go from "Legal | Name" to Legal \| Name
                            for indx, element in enumerate(this_line):
                                if "|" in element:
                                    element = element.replace("|", "\\|").replace('"', "")
                                    this_line[indx] = element

                            this_line = self.delimiter.join(this_line)
                            out_file.write(this_line + "\n")

                        contemt_count += 1

                    # Write trailer
                    trl = self.create_trailer(contemt_count - 1)
                    out_file.write(trl)

            print(f"Finished Writing {self.filename} Report")

        except Exception as e:
            raise e

if __name__ == '__main__':
    IDP_Report_Gen(bus_dt=argv[1], input_file=argv[2], output_location=argv[3], input_delimiter=argv[4],
                   filename=argv[5], flag=argv[6]).write_report()
    # IDP_Report_Gen("20221231", "C:\\Users\\imalek\\Downloads\\SACCR_derivative_exposure_report.csv",
    #               "C:\\Users\\imalek\\Downloads\\", ",", "IBGC_EXPOSURE", "D").write_report()

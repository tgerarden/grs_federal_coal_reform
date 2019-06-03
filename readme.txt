This directory contains materials for replication of: Gerarden, Reeder, and Stock "Federal Coal Program Reform, the Clean Power Plan, and the Interaction of Upstream and Downstream Climate Policies"

All inputs for the analysis are contained in input/GRS_data.xlsx.

Replicating the analysis only requires execution of code/run_code.do in Stata. You may need to modify the cd command in code/run_code.do (below the comment "set directory") to include an absolute path to the parent directory that contains this readme.

When run_code.do executes, it will call three other .do files. Intermediate outputs in Stata dataset format are saved in the intermediate_data subdirectory. All final output is stored in the output subdirectory, with the following subdirectories:

	output/figures:	all figures from the manuscript except figure 3
	output/logs:	timestamped logs from each execution of run_code.do
	output/tables:	.dta files with each table in matrix format and the workbook Tables.xlsx with formatted versions of the final tables used in the manuscript

One log is available in output/logs to facilitate debugging.
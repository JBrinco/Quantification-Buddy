# Quantification-Buddy

Quantification using traditional calibration and internal standards in the command line

## What am I

A simple R script that performs a calibration with external standardization (solutions of known concentration Vs obtained signal). It can also perform calculations with internal standards (for chromatography).

## Development

- [x] Basic functionality with one csv input of calibration and another of sample signal values. Outputs results to CSV.
- [x] Outputs good looking calibration curves with formulas to pdf.
- [x] Can process multiple calibrations at once, and one single sample signal file with values for all calibrations.
- [x] Can read columns and decide if internal standard was used or not. (two different scripts).
- [ ] Finds rows in which samples have the same name and calculates the median and standard deviation.
- [ ] Fancy hackable output with Rmarkdown.

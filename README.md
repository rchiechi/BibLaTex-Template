BibLaTex-Template defines a class and provides example files for writing scientific manuscripts.

# rcclab.cls

A LaTeX class for writing articles.
Customize with `\documentclass[key=value]{rcclab}`
rcclab class keys:
- bibstyle (*e.g.,* chem-acs)
- articletitle (bool) show article titles in bibliography
- articledoi (bool) show DOIs in bibliography
- articleurl (bool) show URLs in bibliography
- maxauthors (int) how many authors to list before truncating with et al.
- numberedsubsections (bool) numbered sections
- stixfont (bool) use the [stix font](https://www.stixfonts.org/) instead of computer modern

#### Macros Defined:

Colors:

- \red{ ... }
- \blue{ ... }
- \green{ ... }

Latin abbreviations:

- \ie{ ... } _i.e.,_
- \eg{ ... } _e.g.,_
- \et{ ... } _et al._

Template-stripped surfaces:

- \ts{ Metal } _Metal<sup>TS</sup>_
- \mica{ Metal } _Metal<sup>Mica</sup>_
- \afp{ Metal } _Metal<sup>AFM</sup>_
- \cp{ Metal } _Metal<sup>AFM</sup>_

Constants:

- $\fermi$ _E<sub>f</sub>_
- $\egap$ _E<sub>g</sub>_
- \Mn _M<sub>n</sub>_
- \Mw _M<sub>w</sub>_

Units:

- $\Junits$ _A cm<sup>-2</sup>_
- \logJ _log|J|_
- \logI _log|I|_
- \vtrans _V<sub>trans</sub>_
- \vtransp{ +/- } _V<sub>trans</sub><sup>+/-</sup>_
- $\vtransmm$ _V<sub>trans</sub>__
- \degC{ ... } _...°C_

SI Units:

- \si{\molar} _mol dm<sup>-3</sup>_
- \si{\Molar} _M_
- \si{\torr} _torr_
- \si{\calorie} _cal_
- \si{\debye} _D_

References:

- \citenum{} _Write out the number of a reference in normal case._

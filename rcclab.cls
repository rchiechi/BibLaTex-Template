%% Class rcclab
%% A class for writing chemistry manuscripts
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{rcclab}[2025/09/12 v2.0]
\typeout{A class for writing RCCLab manuscripts}
\typeout{Written by Ryan Chiechi}
\typeout{ }

\LoadClass[12pt]{article}

% Modern geometry package instead of fullpage (deprecated)
\RequirePackage[margin=1in]{geometry}

% Core packages
\RequirePackage{setspace}
\RequirePackage{graphicx}
\RequirePackage{float}
\RequirePackage[version=4]{mhchem}  % Chemistry formulas
\RequirePackage{xcolor}

% Modern SI units package configuration
\RequirePackage{siunitx}
\sisetup{
    mode = match,
    propagate-math-font = true,
    reset-text-family = false,
    reset-text-series = false,
    reset-text-shape = false,
    uncertainty-mode = separate,
    range-units = single,
    separate-uncertainty = true
}
\DeclareSIPrefix\micro{\text{\textmu}}{-6}

% Font encoding
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{textcomp}  % Additional text symbols

% Modern subcaption instead of subfig (deprecated)
\RequirePackage{subcaption}

% Cross-references and hyperlinks
\RequirePackage{xr-hyper}  % Better than xr for hyperref compatibility
\RequirePackage{bookmark}  % Better PDF bookmarks

% Tables
\RequirePackage{booktabs}
\RequirePackage{array}
\RequirePackage{tabularx}

% Modern caption setup
\RequirePackage[
    justification=justified,
    font={small,singlespacing},
    labelfont=bf,
    skip=6pt
]{caption}

% Better reference management
\RequirePackage[capitalize,noabbrev]{cleveref}

% Class options using kvoptions
\RequirePackage{kvoptions}
\SetupKeyvalOptions{
    family=rcclab,
    prefix=rcclab@
}

% Bibliography options - these are critical for journal submission
\DeclareStringOption[chem-acs]{bibstyle}[chem-acs]
\DeclareBoolOption[false]{noarticletitle}
\DeclareStringOption[false]{articledoi}[false]  % Many journals forbid DOIs
\DeclareStringOption[false]{articleurl}[false]   % URLs often forbidden too
\DeclareStringOption[100]{maxauthors}[100]
\DeclareBoolOption[false]{suppinfo}
\DeclareBoolOption[false]{numberedsubsections}
\DeclareBoolOption[false]{stixfont}  % For proper scientific typography

\ProcessKeyvalOptions{rcclab}

% STIX font for scientific symbols
\ifrcclab@stixfont
    \RequirePackage{stix2}
\fi

% etoolbox for patching commands
\RequirePackage{etoolbox}

% Modern bibliography management with biber
\PassOptionsToPackage{style=\rcclab@bibstyle,
doi=\rcclab@articledoi,
url=\rcclab@articleurl,
maxbibnames=\rcclab@maxauthors,
articletitle=\ifbool{rcclab@noarticletitle}{false}{true}}{biblatex}

\RequirePackage[backend=biber,sorting=none,giveninits=true]{biblatex}

% Hyperref should be loaded late
\RequirePackage{hyperref}

% Spacing parameters
\setlength{\parindent}{0.39in}
\renewcommand{\spacing}[1]{\renewcommand{\baselinestretch}{#1}\large\normalsize}

% Conditional spacing and numbering based on document type
\ifrcclab@suppinfo
    \spacing{1}  % Single spacing for SI
    \setlength{\parskip}{12pt}
    % SI-specific numbering
    \def\thepage{S-\arabic{page}}
    \renewcommand*\thefigure{S\@arabic\c@figure}
    \renewcommand*\thetable{S\@arabic\c@table}
    \renewcommand*\thesection{S\@arabic\c@section}
    \renewcommand{\theequation}{S\arabic{equation}}
    \newcommand{\@siprefix}{Supporting Information for: }
\else
    \spacing{2}  % Double spacing for main document
    \setlength{\parskip}{18pt}
    \newcommand{\@siprefix}{}
\fi

% Title formatting
\def\@maketitle{%
    \newpage\spacing{1}\setlength{\parskip}{12pt}%
    {\Large\bfseries\noindent\sloppy \@siprefix \textsf{\@title} \par}%
    {\noindent\sloppy \@author}%
}

% Affiliations environment - keep original working syntax
\newenvironment{affiliations}{%
    \renewcommand{\baselinestretch}{1}
    \setcounter{enumi}{1}%
    \setlength{\parindent}{0in}%
    \normalfont\sloppy
    \begin{list}{\upshape$^{\arabic{enumi}}$}{%
        \usecounter{enumi}%
        \setlength{\leftmargin}{0in}%
        \setlength{\topsep}{0in}%
        \setlength{\labelsep}{0in}%
        \setlength{\labelwidth}{0in}%
        \setlength{\listparindent}{0in}%
        \setlength{\itemsep}{0ex}%
        \setlength{\parsep}{0in}%
        }%
    }{\end{list}\par\vspace{12pt}}

% Outline environment for drafting
\newenvironment{outline}{%
    \renewcommand{\baselinestretch}{1}
    \setlength{\parindent}{0in}%
    \normalfont%
    \begin{itemize}{}{}%
    }{\end{itemize}}

% Abstract environment
\renewenvironment{abstract}{%
    \renewcommand{\baselinestretch}{1}%
    \textbf{Abstract}%
    \setlength{\parindent}{0in}%
    \setlength{\parskip}{0in}%
    \centering%
}{\par\vspace{-6pt}}

% TOC Graphic environment - caption without "Figure" label or separator
\newenvironment{tocgraphic}{%
    \begin{figure}%
    \captionsetup{labelformat=empty,labelsep=none}%
}{%
    \end{figure}%
}

% Non-floating TOC graphic environment  
\newenvironment{tocgraphic*}{%
    \begin{figure}[H]%  % H from float package forces "here"
    \captionsetup{labelformat=empty,labelsep=none}%
}{%
    \end{figure}%
}

% Section formatting
\ifrcclab@suppinfo
    % Don't redefine sections for SI
\else
    % Redefine the section command for main document
    \renewcommand{\section}{\@startsection{section}{1}{0pt}%
        {-6pt}{1pt}%
        {\bfseries}%
    }
    \ifrcclab@numberedsubsections
        \renewcommand{\subsection}{\@startsection{subsection}{2}{0pt}%
            {-0pt}{-0.5em}%
            {\bfseries}%
        }
    \else
        \renewcommand{\subsection}{\@startsection{subsection}{2}{0pt}%
            {-0pt}{-0.5em}%
            {\bfseries}*%
        }
    \fi
\fi

% Methods environment
\newenvironment{methods}{%
    \section*{Methods}%
    \setlength{\parskip}{12pt}%
}{}

% Experimental environment
\newenvironment{experimental}{%
    \section*{Experimental}%
    \setlength{\parskip}{12pt}%
}{}

% Chemistry-specific SI units
\DeclareSIUnit\molar{\mole\per\cubic\deci\metre}
\DeclareSIUnit\Molar{\textsc{m}}
\DeclareSIUnit\torr{torr}
\DeclareSIUnit\calorie{cal}
\DeclareSIUnit\debye{D}
\DeclareSIUnit\angstrom{\text{Å}}
\DeclareSIUnit\wavenumber{\per\centi\metre}
\DeclareSIUnit\dalton{Da}

% Citation commands
\DeclareCiteCommand{\citenum}
    {}
    {\printfield{labelnumber}}
    {}
    {}

% Dispersity symbol
\ProvideTextCommand{\Dbar}{OT1}{\raisebox{0.25ex}{-}\kern-0.4em D}

% Color commands for collaborative editing
\newcommand{\red}[1]{\textcolor{red}{#1}}
\newcommand{\blue}[1]{\textcolor{blue}{#1}}
\newcommand{\green}[1]{\textcolor{green}{#1}}

% Latin abbreviations with proper spacing
\RequirePackage{xspace}
\newcommand*{\ie}{\textit{i.e.}\@\xspace}
\newcommand*{\eg}{\textit{e.g.}\@\xspace}
\newcommand*{\etal}{\textit{et al.}\@\xspace}
\newcommand*{\viz}{\textit{viz.}\@\xspace}
\newcommand*{\cf}{\textit{cf.}\@\xspace}
\newcommand*{\vide}{\textit{vide}\@\xspace}
\newcommand*{\circa}{\textit{ca.}\@\xspace}

% Surface chemistry macros
\newcommand*{\ts}[1]{\ensuremath{\mathrm{#1}^{\mathrm{TS}}}}
\newcommand*{\mica}[1]{\ensuremath{\mathrm{#1}^{\mathrm{Mica}}}}
\newcommand*{\afm}[1]{\ensuremath{\mathrm{#1}^{\mathrm{AFM}}}}
\newcommand*{\cp}[1]{\ensuremath{\mathrm{#1}^{\mathrm{CP}}}}

% Polymer chemistry
\newcommand*{\Mn}{\ensuremath{M_\mathrm{n}}}
\newcommand*{\Mw}{\ensuremath{M_\mathrm{w}}}
\newcommand*{\PDI}{\ensuremath{\mathrm{PDI}}}
\newcommand*{\DP}{\ensuremath{\mathrm{DP}}}
\newcommand*{\Tg}{\ensuremath{T_\mathrm{g}}}
\newcommand*{\Tm}{\ensuremath{T_\mathrm{m}}}
\newcommand*{\Tc}{\ensuremath{T_\mathrm{c}}}

% Electronic structure and molecular electronics
\newcommand*{\fermi}{\ensuremath{E_\mathrm{F}}}
\newcommand*{\egap}{\ensuremath{E_\mathrm{g}}}
\newcommand*{\homo}{\ensuremath{E_\mathrm{HOMO}}}
\newcommand*{\lumo}{\ensuremath{E_\mathrm{LUMO}}}
\newcommand*{\Junits}{\si{\ampere\per\centi\metre\squared}}
\newcommand*{\logJ}{\ensuremath{\log|J|}}
\newcommand*{\logI}{\ensuremath{\log|I|}}
\newcommand*{\logG}{\ensuremath{\log|G|}}
\newcommand*{\logR}{\ensuremath{\log|R|}}
\newcommand*{\vtrans}{\ensuremath{V_{\mathrm{trans}}}}
\newcommand*{\vtransp}[1]{\ensuremath{V_{\mathrm{trans}}^{(#1)}}}
\newcommand*{\vtransmm}[1]{\ensuremath{V_{\mathrm{trans}(#1)}}}

% Temperature macros using siunitx
\newcommand*{\degC}[1]{\SI{#1}{\celsius}}
\newcommand*{\degK}[1]{\SI{#1}{\kelvin}}

% Convenient reference macros
\newcommand*{\Fig}[1]{Figure~\ref{#1}}
\newcommand*{\Tab}[1]{Table~\ref{#1}}
\newcommand*{\Eq}[1]{Equation~\eqref{#1}}
\newcommand*{\Sec}[1]{Section~\ref{#1}}
\newcommand*{\Scheme}[1]{Scheme~\ref{#1}}

% Chemical yield
\newcommand*{\yield}[1]{\SI{#1}{\percent}~yield}

\endinput